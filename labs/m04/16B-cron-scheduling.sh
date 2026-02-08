#!/bin/bash
# labs/m04/17A-journald-basics.sh
# Lab: Working with systemd-journald
# Difficulty: Beginner
# RHCSA Objective: 17.2, 17.3 - Using and configuring systemd-journald

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Working with systemd-journald"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="40-50 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure journald is running
    systemctl is-active systemd-journald >/dev/null 2>&1 || systemctl start systemd-journald
    
    # Remove persistent journal if it exists from previous attempts
    if [ -d /var/log/journal ]; then
        systemctl stop systemd-journald 2>/dev/null || true
        rm -rf /var/log/journal 2>/dev/null || true
        systemctl start systemd-journald 2>/dev/null || true
    fi
    
    # Remove any custom journald configuration
    rm -rf /etc/systemd/journald.conf.d/ 2>/dev/null || true
    
    # Ensure we start with volatile journal
    systemctl restart systemd-journald 2>/dev/null || true
    
    # Create some test log entries for exploration
    logger -p user.info "Lab 17A: Test INFO message from setup"
    logger -p user.notice "Lab 17A: Test NOTICE message"
    logger -p user.warning "Lab 17A: Test WARNING message"
    logger -p user.err "Lab 17A: Test ERROR message"
    logger -p user.crit "Lab 17A: Test CRITICAL message"
    
    # Generate some service activity
    systemctl restart sshd 2>/dev/null || true
    systemctl restart crond 2>/dev/null || true
    
    # Create a broken service for troubleshooting practice
    cat > /etc/systemd/system/lab-broken.service << 'EOF'
[Unit]
Description=Lab Broken Service for Testing
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/nonexistent-command
Restart=no

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl start lab-broken.service 2>/dev/null || true
    
    echo "  ✓ systemd-journald service verified"
    echo "  ✓ Persistent journal removed (starting with volatile)"
    echo "  ✓ Custom configurations removed"
    echo "  ✓ Test log entries created"
    echo "  ✓ Service activity generated"
    echo "  ✓ Broken service created for troubleshooting practice"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of systemd
  • Familiarity with log files and logging concepts
  • Understanding of file permissions
  • Ability to read man pages

Commands You'll Use:
  • journalctl - Query and display journal logs
  • systemctl - Manage systemd services
  • logger - Generate test log messages
  • mkdir - Create directories
  • ls, stat - Examine files and directories

Files You'll Interact With:
  • /run/log/journal/ - Volatile journal storage (default)
  • /var/log/journal/ - Persistent journal storage (you'll create)
  • /etc/systemd/journald.conf.d/ - Journal configuration drop-ins

Key Concepts:
  • systemd-journald collects logs from kernel, services, and applications
  • Journal is non-persistent by default (stored in RAM)
  • Persistent storage requires /var/log/journal directory
  • Journal can be filtered by priority, unit, time, and boot
  • Storage settings control where and how logs are kept
  • Journal must be flushed after creating persistent storage

Reference Material:
  • man journalctl - Query the journal
  • man journald.conf - Journal configuration
  • man systemd-journald - Journal service
  • man systemd.directives - All systemd directives
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator managing a RHEL 10 server. Your team needs
to investigate service failures, analyze security events, and review
historical logs across reboots. Currently, the systemd journal only keeps
logs in memory, which means they're lost on reboot. You need to master
journal querying and configure persistent storage.

BACKGROUND:
The systemd journal (journald) is the centralized logging system in modern
RHEL. Unlike traditional syslog which writes plain text files, journald
stores structured binary logs that can be efficiently queried and filtered.
Understanding journalctl and journal persistence is essential for the RHCSA
exam and real-world troubleshooting.

OBJECTIVES:
  1. Master journalctl filtering and querying capabilities
     • Explore different ways to filter log entries
     • Understand priority levels and their meanings
     • Filter by service units and time periods
     • Examine boot logs and kernel messages
     • Determine current journal storage mode
     
  2. Configure persistent journal storage across reboots
     • Determine current storage location and mode
     • Create necessary directory structure
     • Set appropriate ownership and permissions
     • Force journal to switch to persistent storage
     • Verify journal files are being written to disk
     
  3. Configure journal size limits and retention policies
     • Understand default journal size behavior
     • Learn about configuration file locations
     • Configure maximum disk usage limits
     • Set retention time for old logs
     • Understand rotation triggers
     
  4. Use journal for practical troubleshooting scenarios
     • Investigate service startup failures
     • Correlate events across multiple services
     • Find authentication failures and security events
     • Use structured fields for precise filtering
     • Extract useful information from verbose output

HINTS:
  • Start by reading man journalctl to understand all options
  • Priority levels range from 0 (emerg) to 7 (debug)
  • Lower numbers are MORE severe, not less
  • Creating /var/log/journal alone isn't enough
  • You must flush the journal after creating the directory
  • Journal configuration uses drop-in files, not editing service
  • Boot logs require persistent storage to view historical boots

SUCCESS CRITERIA:
  • Can query journal logs with multiple filter types
  • Understand difference between volatile and persistent storage
  • /var/log/journal directory exists with correct permissions
  • Journal files are actively being written to persistent storage
  • Understand how to limit journal disk usage
  • Can investigate real service failures using the journal
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Master journalctl filtering (priority, unit, time, boot)
  ☐ 2. Configure persistent journal storage
  ☐ 3. Configure journal size and retention limits
  ☐ 4. Troubleshoot service failures using journal
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "4"
}

scenario_context() {
    cat << 'EOF'
You're learning to manage systemd journal logs, including querying,
filtering, persistence, and using logs for real troubleshooting.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Master journalctl filtering and querying capabilities

Learn to effectively query the systemd journal using various filters.
Do NOT just run commands - understand the filtering concepts.

Requirements:
  • View recent journal entries (all logs)
  • Filter logs by priority level:
    - Only error messages and higher severity
    - Only warning messages and higher severity
    - Understand the priority number scale (0-7)
  
  • Filter logs by specific service units:
    - View SSH daemon logs only
    - View logs for the journald service itself
    - Combine multiple units in one query
  
  • Filter logs by time periods:
    - Show only logs from the last hour
    - Show only today's logs
    - Show logs between specific timestamps
  
  • View boot-specific logs:
    - Show only logs from current boot
    - Understand why historical boots aren't available yet
  
  • Follow logs in real-time (like tail -f)
  
  • Determine current journal storage mode:
    - Find out if journal is volatile or persistent
    - Identify where journal files are currently stored

Priority levels to understand:
  0 - emerg (Emergency) - System unusable
  1 - alert (Alert) - Immediate action required
  2 - crit (Critical) - Critical conditions
  3 - err (Error) - Error conditions
  4 - warning (Warning) - Warning conditions
  5 - notice (Notice) - Normal but significant
  6 - info (Informational) - Informational messages
  7 - debug (Debug) - Debug messages

When you filter by priority, you get that level AND everything
more severe (lower numbers).

Exploration strategy:
  1. Read man journalctl to understand options
  2. Try viewing all logs first
  3. Experiment with different filter combinations
  4. Check where current journal files are stored
  5. Generate test logs with logger command to see filtering

Questions to answer:
  • Where are the current journal files stored?
  • Is the journal volatile or persistent?
  • How many log entries are there from sshd?
  • What errors occurred in the last hour?
  • Can you see logs from previous boots?
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  Read options: man journalctl"
    echo "  View all: journalctl (no options)"
    echo "  Filter priority: -p option with level name or number"
    echo "  Filter service: -u option with unit name"
    echo "  Filter time: --since and --until options"
    echo "  Current boot: -b option"
    echo "  Follow mode: -f option"
    echo "  Storage check: Look at first line of journalctl output"
    echo "  Or check: ls /run/log/journal/ and ls /var/log/journal/"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────

Understanding journalctl basics:

Read the manual first:
  man journalctl

Look for sections on:
  - Filtering options
  - Priority levels
  - Time specifications
  - Output formats

View all journal entries:
  journalctl

This shows entire journal. Use:
  - Space to page down
  - 'q' to quit
  - '/' to search

Filter by priority:

Show errors and higher (err, crit, alert, emerg):
  journalctl -p err

Or using number:
  journalctl -p 3

Show warnings and higher:
  journalctl -p warning
  journalctl -p 4

Remember: Lower numbers = MORE severe
  -p err gives you priorities 0-3
  -p warning gives you priorities 0-4

Filter by service unit:

Show SSH daemon logs:
  journalctl -u sshd.service

Show journald's own logs:
  journalctl -u systemd-journald.service

Multiple units:
  journalctl -u sshd.service -u crond.service

Filter by time:

Last hour:
  journalctl --since "1 hour ago"
  journalctl --since "-1 hours"

Today only:
  journalctl --since today

Yesterday:
  journalctl --since yesterday --until today

Specific time range:
  journalctl --since "2026-02-08 00:00:00" --until "2026-02-08 12:00:00"

Current boot only:
  journalctl -b

This limits to logs since the most recent boot.

Previous boots (requires persistent journal):
  journalctl --list-boots

If journal is volatile, you'll only see current boot.

Follow mode (real-time):
  journalctl -f

Shows new entries as they appear.
Press Ctrl+C to stop.

Combining filters:

SSH errors from last hour:
  journalctl -u sshd.service -p err --since "1 hour ago"

All warnings since boot:
  journalctl -p warning -b

Checking storage mode:

Method 1 - Look at journal output:
  journalctl | head -1

Shows something like:
  "-- Journal begins at [date], ends at [date]. --"

Or might explicitly say "Runtime Journal" (volatile).

Method 2 - Check file locations:
  ls /run/log/journal/

This should show directories (volatile storage).

  ls /var/log/journal/

If this fails with "No such file or directory", then
journal is volatile-only.

Method 3 - Check with grep:
  journalctl | grep -E 'Runtime|System' | head -1

Generating test logs:

Create test entries:
  logger -p user.info "Test info message"
  logger -p user.err "Test error message"

Then filter to find them:
  journalctl -p info --since "1 minute ago"

Understanding the output:

Default output format:
  Feb 08 10:30:15 hostname service[1234]: Message text

Fields:
  - Timestamp
  - Hostname
  - Service name and PID
  - Log message

Verbose output (shows all metadata):
  journalctl -o verbose

Shows structured data like:
  MESSAGE=
  PRIORITY=
  _SYSTEMD_UNIT=
  _PID=
  _HOSTNAME=

Useful filtering patterns:

Kernel messages only:
  journalctl -k

Same as:
  journalctl -b -u kernel

Last 20 entries:
  journalctl -n 20

Reverse order (newest first):
  journalctl -r

With explanation text:
  journalctl -x

Jump to end:
  journalctl -e

Common troubleshooting queries:

Recent errors across all services:
  journalctl -p err --since "1 hour ago"

Service startup issues:
  journalctl -u servicename.service -b

Authentication failures:
  journalctl -u sshd.service -p warning

Boot messages:
  journalctl -b -p warning

Key takeaway:

The journal is queryable like a database. You can combine
multiple filters to narrow down exactly what you need.

Priority levels are critical to understand:
  - emerg(0) through debug(7)
  - Lower number = MORE severe
  - Filtering by a level includes all more severe levels

EOF
}

hint_step_2() {
    echo "  Check current location: ls /run/log/journal/"
    echo "  Create directory: mkdir command for /var/log/journal"
    echo "  Set permissions: Use systemd-tmpfiles or chown/chmod"
    echo "  Restart service: systemctl restart systemd-journald"
    echo "  CRITICAL: Run journalctl --flush to write to new location"
    echo "  Verify: ls /var/log/journal/"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Configure persistent journal storage across reboots

Make the journal survive reboots by enabling persistent storage.

Current situation:
  Journal is stored in /run/log/journal/ which is a tmpfs
  (RAM-based filesystem). All logs are lost on reboot.

Your goal:
  Configure journal to store logs in /var/log/journal/
  so they persist across reboots.

Requirements:
  • Verify current storage location (should be /run)
  
  • Create the persistent journal directory
    - Location: /var/log/journal
    - Appropriate ownership
    - Appropriate permissions
  
  • Restart the systemd-journald service
  
  • CRITICAL STEP: Force journal to flush to new location
    There's a specific journalctl command that forces
    the journal to write from /run to /var
  
  • Verify journal files exist in /var/log/journal
  
  • Verify new log entries are being written there

Important concepts to understand:
  • Simply creating /var/log/journal isn't enough
  • Journal needs to be told to switch locations
  • There's a --flush option for journalctl
  • Proper permissions are critical for journald to write

Testing your work:
  • Generate a test log entry after configuration
  • Verify it appears in /var/log/journal files
  • Check that future boots will have this directory

Why persistence matters:
  • View logs from previous boots
  • Investigate issues that caused crashes
  • Security auditing and compliance
  • Historical troubleshooting

Read the following before starting:
  man journalctl (look for --flush)
  man journald.conf (understand Storage= option)
  man systemd-tmpfiles (for permission handling)
EOF
}

validate_step_2() {
    local failures=0
    
    # Check if /var/log/journal exists
    if [ ! -d /var/log/journal ]; then
        echo ""
        print_color "$RED" "✗ /var/log/journal directory not found"
        echo "  Create this directory to enable persistent storage"
        ((failures++))
        return 1
    fi
    
    # Give journald a moment to write
    sleep 2
    
    # Check if journal files exist in /var/log/journal
    if ! ls /var/log/journal/*/system.journal >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ No journal files found in /var/log/journal"
        echo "  Did you run journalctl --flush after creating the directory?"
        echo "  The journal needs to be flushed to switch from /run to /var"
        ((failures++))
    fi
    
    # Check ownership
    if [ -d /var/log/journal ]; then
        local owner=$(stat -c '%U' /var/log/journal)
        if [ "$owner" != "root" ]; then
            echo ""
            print_color "$YELLOW" "⚠ Directory owner is $owner (expected root)"
        fi
    fi
    
    # Generate a test entry and see if it appears in persistent storage
    logger "Lab 17A validation test entry - $(date)"
    sleep 1
    
    if journalctl --since "10 seconds ago" | grep -q "Lab 17A validation test"; then
        if ls /var/log/journal/*/system.journal >/dev/null 2>&1; then
            print_color "$GREEN" "  ✓ New entries are being written to persistent storage"
        fi
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────

Step 1: Check current storage location
───────────────────────────────────────
Verify journal is currently volatile:
  ls /run/log/journal/

You should see a directory with machine ID.

Check for persistent storage:
  ls /var/log/journal/

Should fail with "No such file or directory".

Step 2: Create persistent journal directory
────────────────────────────────────────────
Create the directory:
  sudo mkdir /var/log/journal

Step 3: Set correct permissions
────────────────────────────────
Method 1 - Using systemd-tmpfiles (recommended):
  sudo systemd-tmpfiles --create --prefix /var/log/journal

This automatically sets correct ownership and permissions.

Method 2 - Manual permissions:
  sudo chown root:systemd-journal /var/log/journal
  sudo chmod 2755 /var/log/journal

The 2755 includes setgid bit (2) so new files inherit group.

Verify:
  ls -ld /var/log/journal

Should show:
  drwxr-sr-x. 2 root systemd-journal 4096 Feb 08 10:30 /var/log/journal

Step 4: Restart systemd-journald
─────────────────────────────────
Restart the service:
  sudo systemctl restart systemd-journald

Step 5: CRITICAL - Flush the journal
─────────────────────────────────────
Force journal to write to persistent storage:
  sudo journalctl --flush

This is the key step most people miss!

What --flush does:
  - Tells journald to write volatile journal to persistent
  - Moves logs from /run/log/journal to /var/log/journal
  - Signals journald to start using persistent storage

Without this step:
  - Journal files won't appear in /var/log/journal
  - Journald continues using /run even though /var exists
  - Persistence won't work

Step 6: Verify persistent storage
──────────────────────────────────
Check for journal files:
  ls -lh /var/log/journal/

Should show a machine ID directory.

Inside that directory:
  ls -lh /var/log/journal/*/

Should show:
  system.journal      - Current journal file
  user-1000.journal   - User journals (if any)

Verify new entries go to persistent storage:
  logger "Test persistent journal entry"
  
Check it's there:
  journalctl -n 5

The entry should be visible.

Check file was updated:
  ls -lh /var/log/journal/*/system.journal

Timestamp should be recent.

Understanding what happened:

Before:
  Logs: /run/log/journal/MACHINE-ID/system.journal (RAM)
  Status: Volatile

After:
  Logs: /var/log/journal/MACHINE-ID/system.journal (Disk)
  Status: Persistent
  
Both locations still exist:
  - /run for early boot messages (before /var mounts)
  - /var for main persistent storage

The flush command bridges the gap:
  - Copies volatile logs to persistent
  - Switches active logging to persistent
  - Essential after creating /var/log/journal

Why persistent storage matters:

Historical analysis:
  journalctl --list-boots
  
Shows all boots (only with persistent journal):
  -2 abc123... Fri 2026-02-06 08:00:00 EST - Fri 2026-02-06 18:00:00 EST
  -1 def456... Sat 2026-02-07 09:00:00 EST - Sat 2026-02-07 22:00:00 EST
   0 ghi789... Sun 2026-02-08 07:00:00 EST - Sun 2026-02-08 10:30:00 EST

View previous boot:
  journalctl -b -1

This only works with persistent journal!

Troubleshooting boot issues:
  journalctl -b -1 -p err

See what errors caused last reboot.

Security auditing:
  journalctl -u sshd.service --since "2026-02-01"

Review authentication over time.

Configuration note:

You don't need to edit configuration files!

The default setting in journald.conf is:
  Storage=auto

This means:
  - If /var/log/journal exists → use it (persistent)
  - If /var/log/journal missing → use /run (volatile)

So creating the directory is enough, but you MUST
flush the journal to activate it.

Alternative: Explicit configuration

If you want to be explicit, create:
  sudo mkdir -p /etc/systemd/journald.conf.d/

Create a drop-in file:
  sudo vi /etc/systemd/journald.conf.d/persistent.conf

Add:
  [Journal]
  Storage=persistent

This ensures journald always uses persistent storage.

Restart:
  sudo systemctl restart systemd-journald

Then flush:
  sudo journalctl --flush

Common mistakes:

Mistake 1: Forgetting --flush
  Created directory but journal still in /run
  Solution: journalctl --flush

Mistake 2: Wrong permissions
  Journal can't write to directory
  Solution: Use systemd-tmpfiles or fix manually

Mistake 3: Not restarting journald
  Service doesn't notice new directory
  Solution: systemctl restart systemd-journald

Mistake 4: Expecting immediate persistence
  Directory created but logs still volatile
  Solution: Always flush after creating directory

Disk space warning:

Persistent journals use disk space!
Default limits prevent unbounded growth:
  - Max 10% of filesystem
  - Keep 15% filesystem free
  - Monthly rotation

Monitor usage:
  journalctl --disk-usage

EOF
}

hint_step_3() {
    echo "  Config location: /etc/systemd/journald.conf.d/"
    echo "  Create drop-in file: mkdir -p then create .conf file"
    echo "  Key settings: SystemMaxUse, SystemKeepFree, MaxRetentionSec"
    echo "  Check usage: journalctl --disk-usage"
    echo "  Read: man journald.conf for all options"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Configure journal size limits and retention policies

Learn how to control journal disk usage and retention time.

The challenge:
  Persistent journals can grow large and fill disk space.
  You need to configure limits to prevent unbounded growth.

Requirements:
  • Understand where journal configuration goes
    (Hint: It's NOT editing the service file directly)
  
  • Create a configuration drop-in file
    - Location: /etc/systemd/journald.conf.d/
    - Create a .conf file with appropriate settings
  
  • Configure the following limits:
    - Maximum total journal size: 1G
    - Minimum free space to keep: 500M
    - Maximum retention time: 30 days
  
  • Apply the configuration
  
  • Check current journal disk usage
  
  • Understand how rotation and cleanup work

Configuration concepts to learn:
  • journald uses drop-in configuration files
  • Settings go in /etc/systemd/journald.conf.d/*.conf
  • Each setting controls different aspects of storage
  • Changes require restarting systemd-journald

Key settings to understand:
  SystemMaxUse=       Max total disk space for journal
  SystemKeepFree=     Min free space to preserve on filesystem  
  SystemMaxFileSize=  Max size of individual journal file
  MaxRetentionSec=    Max time to keep journal entries
  MaxFileSec=         Force rotation after this time

Research before starting:
  man journald.conf (read the entire man page)
  Look for the [Journal] section format
  Understand size units (K, M, G)
  Understand time units (s, m, h, d, month, year)

Default behavior (if not configured):
  - Uses up to 10% of filesystem size
  - Keeps at least 15% free
  - Rotates monthly
  - No time-based deletion

Your task:
  Override these defaults with more conservative limits
  to prevent journal from consuming too much disk space.

After configuration:
  • Verify settings took effect
  • Check current journal disk usage
  • Understand when rotation/cleanup occurs
EOF
}

validate_step_3() {
    local failures=0
    
    # Check if configuration directory exists
    if [ ! -d /etc/systemd/journald.conf.d ]; then
        echo ""
        print_color "$RED" "✗ /etc/systemd/journald.conf.d/ directory not found"
        echo "  Create this directory for drop-in configuration files"
        ((failures++))
        return 1
    fi
    
    # Check if there's a configuration file
    if ! ls /etc/systemd/journald.conf.d/*.conf >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ No .conf files found in /etc/systemd/journald.conf.d/"
        echo "  Create a drop-in configuration file (e.g., size-limits.conf)"
        ((failures++))
        return 1
    fi
    
    # Check for required settings in any .conf file
    local has_maxuse=false
    local has_keepfree=false
    local has_retention=false
    
    for conf in /etc/systemd/journald.conf.d/*.conf; do
        if grep -q "^SystemMaxUse=" "$conf" 2>/dev/null; then
            has_maxuse=true
        fi
        if grep -q "^SystemKeepFree=" "$conf" 2>/dev/null; then
            has_keepfree=true
        fi
        if grep -q "^MaxRetentionSec=" "$conf" 2>/dev/null; then
            has_retention=true
        fi
    done
    
    if ! $has_maxuse; then
        echo ""
        print_color "$RED" "✗ SystemMaxUse not configured"
        ((failures++))
    fi
    
    if ! $has_keepfree; then
        echo ""
        print_color "$RED" "✗ SystemKeepFree not configured"
        ((failures++))
    fi
    
    if ! $has_retention; then
        echo ""
        print_color "$RED" "✗ MaxRetentionSec not configured"
        ((failures++))
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────

Understanding journal configuration:

Journal configuration uses drop-in files, similar to other
systemd components.

DO NOT edit /usr/lib/systemd/journald.conf
DO NOT edit the service file

Instead, create drop-in files in:
  /etc/systemd/journald.conf.d/

Step 1: Create configuration directory
───────────────────────────────────────
Create the drop-in directory:
  sudo mkdir -p /etc/systemd/journald.conf.d/

Step 2: Create configuration file
──────────────────────────────────
Create a new drop-in file:
  sudo vi /etc/systemd/journald.conf.d/size-limits.conf

Add the following content:
  [Journal]
  SystemMaxUse=1G
  SystemKeepFree=500M
  MaxRetentionSec=30d

Save and exit.

Step 3: Verify configuration syntax
────────────────────────────────────
Check your file:
  cat /etc/systemd/journald.conf.d/size-limits.conf

Ensure:
  - [Journal] section header is present
  - No spaces around = signs
  - Proper units (G for gigabytes, M for megabytes, d for days)

Step 4: Restart systemd-journald
─────────────────────────────────
Apply the configuration:
  sudo systemctl restart systemd-journald

Check service started successfully:
  systemctl status systemd-journald

Step 5: Verify settings took effect
────────────────────────────────────
Check current journal disk usage:
  journalctl --disk-usage

Example output:
  Archived and active journals take up 256.0M in the file system.

This should be under your 1G limit.

Understanding the settings:

SystemMaxUse=1G:
  Maximum total space journal can consume
  Once this limit is reached, oldest files are deleted
  
  Example on 100GB /var filesystem:
    Default: 10% = 10GB
    Our setting: 1GB (much more conservative)

SystemKeepFree=500M:
  Minimum free space to maintain on filesystem
  Journal stops growing when free space drops to this
  
  Example scenario:
    Filesystem has 600M free
    Journal tries to write 200M
    Would leave only 400M free (< 500M limit)
    Journal rotation triggered instead

MaxRetentionSec=30d:
  Maximum time to keep journal entries
  Entries older than 30 days are deleted
  
  Time units:
    s = seconds
    m = minutes
    h = hours
    d = days
    month = months
    year = years

The most restrictive limit wins:

If you set:
  SystemMaxUse=1G
  MaxRetentionSec=30d

Journal is limited by whichever triggers first:
  - Size reaches 1G → cleanup triggered
  - Entries reach 30 days old → cleanup triggered

Additional useful settings:

SystemMaxFileSize=100M:
  Maximum size of individual journal file
  When reached, rotation occurs
  Default: 1/8 of SystemMaxUse
  
  Example:
    SystemMaxFileSize=100M

SystemMaxFiles=20:
  Maximum number of archived journal files
  Oldest deleted when limit exceeded
  Default: 100
  
  Example:
    SystemMaxFiles=10

MaxFileSec=1week:
  Force rotation after this time period
  Even if file size limit not reached
  Default: 1month
  
  Example:
    MaxFileSec=1week

RuntimeMaxUse=100M:
  Maximum size for volatile journal in /run
  Separate from SystemMaxUse
  
  Example:
    RuntimeMaxUse=100M

Creating a comprehensive configuration:

Example /etc/systemd/journald.conf.d/limits.conf:

  [Journal]
  # Storage limits
  SystemMaxUse=1G
  SystemKeepFree=500M
  SystemMaxFileSize=100M
  SystemMaxFiles=20
  
  # Time-based retention
  MaxRetentionSec=30d
  MaxFileSec=1week
  
  # Volatile journal limits (in /run)
  RuntimeMaxUse=100M
  RuntimeKeepFree=200M

Understanding rotation:

Rotation triggers:
  1. File size limit reached (SystemMaxFileSize)
  2. Time limit reached (MaxFileSec)
  3. Manual rotation requested

When rotation occurs:
  - Current journal renamed with timestamp
  - New journal file created
  - Old files deleted if limits exceeded

Manual rotation:
  sudo journalctl --rotate

Manual cleanup:

Vacuum by size:
  sudo journalctl --vacuum-size=500M

Reduce journal to 500M total.

Vacuum by time:
  sudo journalctl --vacuum-time=7d

Keep only last 7 days.

Vacuum by file count:
  sudo journalctl --vacuum-files=5

Keep only 5 most recent archive files.

Checking configuration:

View active settings:
  systemd-analyze cat-config systemd/journald.conf

Shows merged configuration from all sources.

View current journal status:
  journalctl --header

Shows journal file metadata.

Verify journal integrity:
  journalctl --verify

Checks for corruption.

Best practices for different scenarios:

Desktop/laptop (limited disk):
  SystemMaxUse=500M
  MaxRetentionSec=7d

Development server (frequent changes):
  SystemMaxUse=2G
  MaxRetentionSec=14d

Production server (audit requirements):
  SystemMaxUse=10G
  MaxRetentionSec=90d

Minimal system (embedded):
  SystemMaxUse=100M
  MaxRetentionSec=3d

Common mistakes:

Mistake 1: Spaces around equals
  Wrong: SystemMaxUse = 1G
  Right: SystemMaxUse=1G

Mistake 2: Missing [Journal] section
  Configuration ignored without section header

Mistake 3: Wrong file location
  Putting config in wrong directory
  Must be in /etc/systemd/journald.conf.d/

Mistake 4: Not restarting journald
  Configuration doesn't take effect
  Always restart after changes

Mistake 5: Conflicting settings
  Multiple .conf files with different values
  Last one read wins (alphabetical order)

Monitoring journal size:

Regular monitoring:
  journalctl --disk-usage

Set up monitoring alert if size exceeds threshold.

Automated cleanup:
  Journal handles this automatically based on
  configured limits. No cron job needed.

EOF
}

hint_step_4() {
    echo "  Check broken service: systemctl status lab-broken.service"
    echo "  View its logs: journalctl -u lab-broken.service"
    echo "  Verbose output: journalctl -o verbose -u lab-broken.service"
    echo "  Find auth failures: journalctl -u sshd.service | grep -i fail"
    echo "  Correlate events: Use multiple -u flags"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Use journal for practical troubleshooting scenarios

Apply your journal skills to real troubleshooting situations.

Scenario 1: Service Failure Investigation
  A service called "lab-broken.service" was created during setup.
  It failed to start. Use the journal to:
  
  • Determine WHY the service failed
  • Find the exact error message
  • Identify what command it tried to execute
  • Determine when the failure occurred
  
  Research strategy:
    - Check service status first
    - View journal entries for that specific unit
    - Look at priority levels (errors)
    - Use verbose output to see all fields

Scenario 2: Authentication Analysis
  Examine SSH authentication events:
  
  • Find all SSH-related log entries
  • Identify any failed authentication attempts
  • Determine which users attempted to connect
  • Find successful login events
  
  Techniques to use:
    - Filter by sshd service unit
    - Look for "Failed" or "Accepted" keywords
    - Use time filtering if needed
    - Combine with grep for specific patterns

Scenario 3: Event Correlation
  Correlate events across multiple services:
  
  • View logs from multiple units simultaneously
  • Find events that happened at the same time
  • Understand sequence of events during system startup
  
  Skills to practice:
    - Multiple -u flags in one command
    - Time-based filtering
    - Following logs in real-time

Scenario 4: Structured Field Filtering
  Use journal's structured fields for precise filtering:
  
  • View all available field names
  • Filter by specific PID
  • Filter by specific executable
  • Filter by specific message ID
  
  Advanced filtering:
    - Use -N to list all field names
    - Use FIELD=VALUE syntax for exact matches
    - Use -o verbose to see all fields
    - Combine with other filters

Questions to answer by end of this step:
  1. Why did lab-broken.service fail?
  2. What command was it trying to run?
  3. Have there been any SSH authentication failures?
  4. What services started during last boot?
  5. Can you find all entries from a specific PID?

Tools at your disposal:
  • journalctl with various filters
  • grep for text searching within journal output
  • Verbose output to see structured data
  • Time filtering to narrow results
  • Priority filtering to focus on errors

This step tests your ability to use journald for
REAL troubleshooting, not just viewing logs.
EOF
}

validate_step_4() {
    # Practical/exploratory step, always pass
    # The goal is learning to troubleshoot
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────

Scenario 1: Service Failure Investigation
───────────────────────────────────────────

Check service status:
  systemctl status lab-broken.service

Shows:
  ● lab-broken.service - Lab Broken Service for Testing
       Loaded: loaded
       Active: failed
       
View service logs:
  journalctl -u lab-broken.service

Look for error messages.

View with error priority only:
  journalctl -u lab-broken.service -p err

Find the specific failure:
  journalctl -u lab-broken.service -n 20

Shows last 20 entries for this service.

Use verbose output to see all fields:
  journalctl -u lab-broken.service -o verbose

Shows structured data:
  _SYSTEMD_UNIT=lab-broken.service
  MESSAGE=Failed to start Lab Broken Service
  _COMM=systemd
  
The error will show:
  "Failed to execute /usr/bin/nonexistent-command: No such file or directory"

This tells you:
  - Service tried to run /usr/bin/nonexistent-command
  - The command doesn't exist
  - Service failed because executable is missing

Root cause analysis:
  cat /etc/systemd/system/lab-broken.service

Shows ExecStart points to nonexistent command.

How to fix (for reference):
  1. Update ExecStart to valid command
  2. systemctl daemon-reload
  3. systemctl restart lab-broken.service

Scenario 2: Authentication Analysis
────────────────────────────────────

View all SSH logs:
  journalctl -u sshd.service

Find failed authentication attempts:
  journalctl -u sshd.service | grep -i failed

Or:
  journalctl -u sshd.service | grep -i "Failed password"

Find successful logins:
  journalctl -u sshd.service | grep -i accepted

Show recent SSH activity:
  journalctl -u sshd.service --since "1 hour ago"

Find specific user activity:
  journalctl -u sshd.service | grep "user root"

Warning and error level SSH events:
  journalctl -u sshd.service -p warning

Real-time SSH monitoring:
  journalctl -u sshd.service -f

This follows new entries as they happen.

Find authentication failures for security review:
  journalctl -u sshd.service | grep -E "(Failed|Invalid|Illegal)"

Scenario 3: Event Correlation
──────────────────────────────

View multiple services simultaneously:
  journalctl -u sshd.service -u crond.service

Shows interleaved logs from both services,
sorted by timestamp.

View multiple services from boot:
  journalctl -b -u sshd.service -u systemd-journald.service

Find what services started during boot:
  journalctl -b | grep -i "Started"

Or more specifically:
  journalctl -b -p info | grep "Started"

Find services that failed during boot:
  journalctl -b -p err

Correlate events by time:
  journalctl --since "10:00:00" --until "10:05:00"

Shows all events in 5-minute window.

Find what happened around a specific event:
  journalctl --since "10:30:00" --until "10:30:10"

Narrow 10-second window around an incident.

Scenario 4: Structured Field Filtering
───────────────────────────────────────

List all field names in journal:
  journalctl -N

Shows fields like:
  _PID
  _UID
  _SYSTEMD_UNIT
  MESSAGE
  PRIORITY
  _HOSTNAME
  _COMM

Filter by specific field:
  journalctl _SYSTEMD_UNIT=sshd.service

This is equivalent to:
  journalctl -u sshd.service

Filter by specific PID:
  journalctl _PID=1234

Shows only entries from process 1234.

Filter by executable name:
  journalctl _COMM=sshd

Shows entries from sshd process.

Filter by user ID:
  journalctl _UID=1000

Shows entries from user with UID 1000.

Combine multiple field filters:
  journalctl _SYSTEMD_UNIT=sshd.service PRIORITY=3

Shows only error-level entries from sshd.

View all fields for an entry:
  journalctl -o verbose -n 1

Shows one entry with all fields expanded.

Find entries with specific message ID:
  journalctl MESSAGE_ID=xyz...

Useful for finding specific event types.

Advanced filtering examples:

All errors from specific user:
  journalctl _UID=1000 PRIORITY=3

All kernel messages:
  journalctl _TRANSPORT=kernel

All messages from specific boot:
  journalctl _BOOT_ID=abc123...

Messages from specific hostname:
  journalctl _HOSTNAME=server01

Practical troubleshooting workflow:

Step 1: Identify the problem scope
  - Which service?
  - When did it occur?
  - How severe is it?

Step 2: Narrow down with filters
  journalctl -u service.service -p err --since "1 hour ago"

Step 3: Get detailed view
  journalctl -u service.service -o verbose

Step 4: Correlate with other events
  journalctl --since "TIME" --until "TIME"

Step 5: Extract specific information
  journalctl _PID=1234 _COMM=program

Tips for effective troubleshooting:

1. Start broad, then narrow:
   journalctl -b              # All boot logs
   journalctl -b -p err       # Just errors
   journalctl -b -p err -u sshd.service  # SSH errors

2. Use time windows:
   --since and --until to focus on incident timeframe

3. Follow logs during reproduction:
   journalctl -f -u service.service
   Then trigger the issue

4. Check before and after:
   Look at logs immediately before the problem
   to find root cause

5. Combine tools:
   journalctl | grep | awk | sort | uniq -c
   Use Unix tools to analyze journal output

Common troubleshooting patterns:

Service won't start:
  systemctl status service.service
  journalctl -u service.service -xe

System slow/unresponsive:
  journalctl -b -p warning

Authentication issues:
  journalctl -u sshd.service | grep -i fail

Network problems:
  journalctl -u NetworkManager.service

Boot problems:
  journalctl -b -p err

Recurring issues:
  journalctl --since "7 days ago" | grep "ERROR_PATTERN"

Real-world example:

Problem: Web server won't start

Investigation:
  systemctl status httpd.service
  # Shows "failed"

  journalctl -u httpd.service -xe
  # Shows "Address already in use"

  journalctl | grep ":80"
  # Find what's using port 80

  journalctl _PID=1234
  # Check logs from that process

Resolution:
  # Stop conflicting service or change port

This demonstrates using journal for complete
troubleshooting workflow.

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your journald configuration..."
    echo ""
    
    # CHECK 1: systemd-journald is active
    print_color "$CYAN" "[1/$total] Checking systemd-journald service..."
    if systemctl is-active systemd-journald >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ systemd-journald is running"
        ((score++))
    else
        print_color "$RED" "  ✗ systemd-journald is not running"
    fi
    echo ""
    
    # CHECK 2: Persistent journal directory exists and is in use
    print_color "$CYAN" "[2/$total] Checking persistent journal storage..."
    if [ -d /var/log/journal ]; then
        if ls /var/log/journal/*/system.journal >/dev/null 2>&1; then
            print_color "$GREEN" "  ✓ Persistent journal configured and actively in use"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ /var/log/journal exists but no journal files found"
            echo "  Did you run: journalctl --flush ?"
        fi
    else
        print_color "$RED" "  ✗ /var/log/journal directory not found"
        echo "  Create persistent storage with:"
        echo "    sudo mkdir /var/log/journal"
        echo "    sudo systemctl restart systemd-journald"
        echo "    sudo journalctl --flush"
    fi
    echo ""
    
    # CHECK 3: Journal size configuration exists
    print_color "$CYAN" "[3/$total] Checking journal size configuration..."
    if [ -d /etc/systemd/journald.conf.d ]; then
        if ls /etc/systemd/journald.conf.d/*.conf >/dev/null 2>&1; then
            local has_config=false
            for conf in /etc/systemd/journald.conf.d/*.conf; do
                if grep -q "^SystemMaxUse=" "$conf" 2>/dev/null || \
                   grep -q "^MaxRetentionSec=" "$conf" 2>/dev/null; then
                    has_config=true
                    break
                fi
            done
            
            if $has_config; then
                print_color "$GREEN" "  ✓ Journal size limits configured"
                ((score++))
            else
                print_color "$YELLOW" "  ⚠ Configuration files exist but missing key settings"
                echo "  Add SystemMaxUse, SystemKeepFree, or MaxRetentionSec"
            fi
        else
            print_color "$RED" "  ✗ No .conf files in /etc/systemd/journald.conf.d/"
        fi
    else
        print_color "$RED" "  ✗ /etc/systemd/journald.conf.d/ directory not found"
        echo "  Create configuration drop-in directory"
    fi
    echo ""
    
    # CHECK 4: Understanding of troubleshooting (based on lab-broken service)
    print_color "$CYAN" "[4/$total] Checking troubleshooting capabilities..."
    if systemctl status lab-broken.service 2>&1 | grep -q "failed"; then
        print_color "$GREEN" "  ✓ lab-broken.service available for troubleshooting practice"
        ((score++))
    else
        print_color "$YELLOW" "  ⚠ lab-broken.service not in expected state"
    fi
    echo ""
    
    # Additional information
    if [ -d /var/log/journal ]; then
        echo "Journal information:"
        local usage=$(journalctl --disk-usage 2>/dev/null | grep -oP '\d+\.\d+[KMGT]' | head -1)
        if [ -n "$usage" ]; then
            echo "  Current disk usage: $usage"
        fi
        
        local boots=$(journalctl --list-boots 2>/dev/null | wc -l)
        echo "  Boots recorded: $boots"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've mastered systemd-journald:"
        echo "  • Querying and filtering journal logs effectively"
        echo "  • Configuring persistent journal storage"
        echo "  • Setting journal size and retention limits"
        echo "  • Using journal for real troubleshooting"
        echo ""
        echo "You're ready for RHCSA journald questions!"
    elif [ $score -ge 3 ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED (Good Understanding)"
        echo ""
        echo "Good work! Review the missing pieces to strengthen your knowledge."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback and try again."
        echo "Use --interactive mode for step-by-step guidance."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -ge 3 ]
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

See detailed solutions in each step's solution output above.

EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical commands for RHCSA:

Querying:
  journalctl                  # All logs
  journalctl -p err           # Errors only
  journalctl -u sshd.service  # Specific service
  journalctl -b               # Current boot
  journalctl --since "1 hour ago"
  journalctl -f               # Follow mode

Making persistent:
  mkdir /var/log/journal
  systemctl restart systemd-journald
  journalctl --flush          # CRITICAL STEP!

Configuring limits:
  mkdir -p /etc/systemd/journald.conf.d/
  vi /etc/systemd/journald.conf.d/limits.conf
  # Add: SystemMaxUse=1G, MaxRetentionSec=30d
  systemctl restart systemd-journald

Checking status:
  journalctl --disk-usage
  journalctl --list-boots
  journalctl --verify

Priority levels (remember):
  0=emerg 1=alert 2=crit 3=err 4=warning 5=notice 6=info 7=debug
  Lower number = MORE severe

Critical facts:
  • Journal is volatile by default (/run/log/journal)
  • Creating /var/log/journal makes it persistent
  • MUST run journalctl --flush after creating directory
  • Configuration goes in /etc/systemd/journald.conf.d/*.conf
  • Always restart journald after config changes
  • -p err shows errors AND higher severity (crit, alert, emerg)

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove broken test service
    systemctl stop lab-broken.service 2>/dev/null || true
    systemctl disable lab-broken.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-broken.service
    systemctl daemon-reload
    
    echo "  ✓ Test services removed"
    echo "  ✓ Lab cleanup complete"
    echo ""
    echo "Note: Persistent journal and configuration were left in place."
    echo "This is the recommended configuration for production systems."
    echo ""
    echo "To remove persistent journal:"
    echo "  sudo systemctl stop systemd-journald"
    echo "  sudo rm -rf /var/log/journal"
    echo "  sudo systemctl start systemd-journald"
    echo ""
    echo "To remove size configuration:"
    echo "  sudo rm -rf /etc/systemd/journald.conf.d/"
    echo "  sudo systemctl restart systemd-journald"
}

# Execute the main framework
main "$@"
