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
LAB_TIME_ESTIMATE="30-40 minutes"

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
    
    # Restore default journal configuration
    if [ -f /etc/systemd/journald.conf.backup ]; then
        cp /etc/systemd/journald.conf.backup /etc/systemd/journald.conf
        rm -f /etc/systemd/journald.conf.backup
        systemctl restart systemd-journald
    fi
    
    # Create some test log entries for exploration
    logger -p user.info "Lab 17A: Test INFO message"
    logger -p user.warning "Lab 17A: Test WARNING message"
    logger -p user.err "Lab 17A: Test ERROR message"
    
    # Generate some sshd activity for filtering practice
    systemctl restart sshd 2>/dev/null || true
    
    echo "  ✓ systemd-journald service verified"
    echo "  ✓ Persistent journal removed (starting fresh)"
    echo "  ✓ Default configuration restored"
    echo "  ✓ Test log entries created"
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

Commands You'll Use:
  • journalctl - Query and display journal logs
  • systemctl - Manage systemd services
  • logger - Generate test log messages
  • mkdir - Create directories
  • systemd-tmpfiles - Manage temporary files/directories

Files You'll Interact With:
  • /etc/systemd/journald.conf - Journal configuration file
  • /var/log/journal/ - Persistent journal storage (created in lab)
  • /run/log/journal/ - Volatile journal storage (default)

Key Concepts:
  • systemd-journald collects logs from kernel, services, and applications
  • Journal is non-persistent by default (stored in RAM)
  • Persistent storage requires /var/log/journal directory
  • Journal can be filtered by priority, unit, time, and boot
  • Storage settings control where and how logs are kept

Reference Material:
  • man journalctl - Query the journal
  • man journald.conf - Journal configuration
  • man systemd-journald - Journal service
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator managing a RHEL 10 server. Your team needs
to investigate service issues and review historical logs. Currently, the
systemd journal only keeps logs in memory, which means they're lost on
reboot. You need to learn how to effectively query logs and configure
persistent journal storage.

BACKGROUND:
The systemd journal (journald) is the centralized logging system in modern
RHEL. Unlike traditional syslog which writes plain text files, journald
stores structured binary logs that can be efficiently queried and filtered.
Understanding journalctl and journal persistence is essential for the RHCSA
exam and real-world troubleshooting.

OBJECTIVES:
  1. Explore journalctl basics and log filtering
     • View recent journal entries
     • Filter logs by priority (error, warning, info)
     • Filter logs by specific service units
     • View logs from specific time periods
     • Check current boot logs
     • Understand journal storage location
     
  2. Make the journal persistent across reboots
     • Check current journal storage mode
     • Create /var/log/journal directory
     • Set appropriate permissions
     • Verify journal switches to persistent storage
     • Understand Storage= configuration options
     
  3. Configure journal size and retention settings
     • Examine /etc/systemd/journald.conf
     • Understand SystemMaxUse and SystemKeepFree
     • Check current journal disk usage
     • Understand journal rotation triggers
     • Know how to limit journal growth

HINTS:
  • journalctl with no options shows entire journal
  • Use -p to filter by priority (0-7 or name)
  • Use -u to filter by systemd unit
  • Use --since and --until for time ranges
  • Journal storage mode shown in journalctl output header
  • Creating /var/log/journal triggers persistent storage
  • Always restart systemd-journald after config changes

SUCCESS CRITERIA:
  • Can query journal logs with various filters
  • Understand difference between volatile and persistent storage
  • /var/log/journal directory exists with correct permissions
  • Journal is using persistent storage
  • Understand journal size configuration options
  • Can verify journal storage location and size
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore journalctl filtering and querying
  ☐ 2. Make journal persistent by creating /var/log/journal
  ☐ 3. Understand journal size and retention configuration
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "3"
}

scenario_context() {
    cat << 'EOF'
You're learning to manage systemd journal logs, including querying,
filtering, and configuring persistent storage for historical analysis.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore journalctl basics and log filtering

Learn how to effectively query the systemd journal with various filters.

Requirements:
  • View recent journal entries
  • Filter by priority:
    - Show only error messages and higher (err, crit, alert, emerg)
    - Show only warning and higher
  • Filter by service unit:
    - View sshd.service logs
    - View systemd-journald.service logs
  • Filter by time:
    - Show logs from last hour
    - Show logs since system boot
  • Check journal storage mode:
    - Determine if using volatile or persistent storage
    - Find where journal files are stored

Key commands to explore:
  journalctl                    # View all logs
  journalctl -p err             # Priority error and higher
  journalctl -p warning         # Priority warning and higher
  journalctl -u sshd.service    # Specific service logs
  journalctl --since "1 hour ago"
  journalctl -b                 # Current boot only
  journalctl -n 20              # Last 20 entries
  journalctl -f                 # Follow mode (like tail -f)

Understanding priority levels (lowest to highest):
  7 - debug
  6 - info
  5 - notice
  4 - warning
  3 - err
  2 - crit
  1 - alert
  0 - emerg

When you specify -p err, you get err AND everything higher
(crit, alert, emerg).

Check current storage:
  journalctl | head -1
  # Look for "Runtime Journal" (volatile) or "System Journal" (persistent)
  
  ls /run/log/journal/     # Volatile storage
  ls /var/log/journal/     # Persistent storage (may not exist yet)
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  View all: journalctl"
    echo "  Filter priority: journalctl -p err"
    echo "  Filter service: journalctl -u sshd.service"
    echo "  Check storage: journalctl | head -1"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
View recent journal entries:
  journalctl

Shows entire journal. Use Space to page, 'q' to quit.

View last 20 entries:
  journalctl -n 20

Filter by priority - errors only:
  journalctl -p err

This shows priority 3 (err) and higher: err, crit, alert, emerg

Filter by priority - warnings and higher:
  journalctl -p warning

This shows: warning, err, crit, alert, emerg

Filter by service unit:
  journalctl -u sshd.service

Shows only logs from SSH daemon.

Multiple units:
  journalctl -u sshd.service -u systemd-journald.service

Filter by time - last hour:
  journalctl --since "1 hour ago"

Or:
  journalctl --since "-1 hours"

Filter by time - since today:
  journalctl --since today

Time range:
  journalctl --since "2026-02-08 00:00:00" --until "2026-02-08 12:00:00"

Current boot only:
  journalctl -b

This shows logs since the system last booted.

With explanations:
  journalctl -xb

Adds helpful explanation text.

Follow mode (live updates):
  journalctl -f

Like tail -f, shows new entries as they appear.
Press Ctrl+C to exit.

Combine filters:
  journalctl -u sshd.service -p err --since "1 hour ago"

Shows SSH errors from last hour.

Check storage mode:
  journalctl | head -1

Output shows:
  "-- Journal begins at..." 
  
  Runtime Journal = volatile (in /run/log/journal/)
  System Journal = persistent (in /var/log/journal/)

List volatile journal files:
  ls -lh /run/log/journal/

Check if persistent exists:
  ls -lh /var/log/journal/

If this doesn't exist, journal is volatile only.

Understanding journalctl output:

Default output format:
  Feb 08 10:30:15 hostname sshd[1234]: Accepted password for user

Breaking down the fields:
  Feb 08 10:30:15    - Timestamp
  hostname           - System hostname
  sshd[1234]         - Process name and PID
  Accepted...        - Log message

Verbose output (shows all fields):
  journalctl -o verbose

Shows structured data:
  _HOSTNAME=
  _TRANSPORT=
  PRIORITY=
  MESSAGE=
  _PID=
  _SYSTEMD_UNIT=

Other useful options:

Show only kernel messages:
  journalctl -k

Same as:
  journalctl -u kernel

Show messages with explanation:
  journalctl -x

Reverse order (newest first):
  journalctl -r

JSON format:
  journalctl -o json

Export format (for backup):
  journalctl -o export > journal-backup.export

Priority levels explained:

0 - emerg (Emergency):
    System is unusable
    Example: Kernel panic

1 - alert (Alert):
    Action must be taken immediately
    Example: Database corruption

2 - crit (Critical):
    Critical conditions
    Example: Hardware failure

3 - err (Error):
    Error conditions
    Example: Service failed to start

4 - warning (Warning):
    Warning conditions
    Example: Disk 90% full

5 - notice (Notice):
    Normal but significant
    Example: Service started

6 - info (Informational):
    Informational messages
    Example: User logged in

7 - debug (Debug):
    Debug messages
    Example: Detailed execution trace

When filtering:
  -p err shows: err, crit, alert, emerg (3-0)
  -p warning shows: warning, err, crit, alert, emerg (4-0)
  -p info shows: everything (6-0)

Common filtering patterns:

Service troubleshooting:
  journalctl -u service-name.service -p err

Recent issues:
  journalctl -p err --since "1 hour ago"

Boot problems:
  journalctl -b -p warning

Service activity today:
  journalctl -u httpd.service --since today

Follow service logs:
  journalctl -u myapp.service -f

Understanding journal structure:

Each entry has metadata:
  - Timestamp
  - Hostname
  - Process/service
  - PID
  - Priority
  - Message
  - Many other fields

This structured approach allows powerful filtering
that plain text logs cannot provide.

EOF
}

hint_step_2() {
    echo "  Create: mkdir /var/log/journal"
    echo "  Permissions: systemd-tmpfiles --create --prefix /var/log/journal"
    echo "  Restart: systemctl restart systemd-journald"
    echo "  Verify: journalctl | head -1"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Make the journal persistent across reboots

Configure journald to store logs on disk so they survive reboots.

Requirements:
  • Check current storage mode (should be Runtime/volatile)
  • Create /var/log/journal directory
  • Set correct ownership and permissions
  • Restart systemd-journald service
  • Verify journal switched to persistent storage
  • Understand Storage= configuration options

Current situation:
  By default, journald stores logs in /run/log/journal/
  This is a tmpfs (RAM-based) filesystem
  All logs are lost when system reboots

To make persistent:
  Simply creating /var/log/journal is enough!
  With Storage=auto (default), journald automatically
  uses /var/log/journal if it exists.

Steps:
  1. Check current mode:
     journalctl | head -1
     # Should show "Runtime Journal"
  
  2. Create persistent directory:
     sudo mkdir /var/log/journal
  
  3. Set permissions (optional, but recommended):
     sudo systemd-tmpfiles --create --prefix /var/log/journal
     
     Or manually:
     sudo chown root:systemd-journal /var/log/journal
     sudo chmod 2755 /var/log/journal
  
  4. Restart journald:
     sudo systemctl restart systemd-journald
  
  5. Verify persistent storage:
     journalctl | head -1
     # Should now show "System Journal"
     
     ls -lh /var/log/journal/
     # Should show journal files

Understanding Storage= options:
  auto       - Use /var/log/journal if exists, else /run/log/journal
  persistent - Always use /var/log/journal (create if missing)
  volatile   - Always use /run/log/journal (RAM only)
  none       - Don't store journal at all

Default is "auto" in /etc/systemd/journald.conf
EOF
}

validate_step_2() {
    local failures=0
    
    # Check if /var/log/journal exists
    if [ ! -d /var/log/journal ]; then
        echo ""
        print_color "$RED" "✗ /var/log/journal directory not found"
        echo "  Create with: mkdir /var/log/journal"
        ((failures++))
        return 1
    fi
    
    # Check if journald is using persistent storage
    # Give it a moment to write to new location
    sleep 2
    
    # Check if journal files exist in /var/log/journal
    if ! ls /var/log/journal/*/system.journal >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ No journal files found in /var/log/journal"
        echo "  systemd-journald may not have switched to persistent storage"
        echo "  Try: systemctl restart systemd-journald"
        ((failures++))
    fi
    
    # Check ownership (should be root:systemd-journal or root:root)
    if [ -d /var/log/journal ]; then
        local owner=$(stat -c '%U' /var/log/journal)
        if [ "$owner" != "root" ]; then
            echo ""
            print_color "$YELLOW" "⚠ Directory owner is $owner (expected root)"
            echo "  This may work but root is recommended"
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
Step 1: Check current storage mode
───────────────────────────────────
journalctl | head -1

Output should show:
  -- Journal begins at [date], ends at [date]. --
  
Or might show "Runtime Journal" indicating volatile storage.

Check where journal files currently are:
  ls /run/log/journal/

This is the volatile (RAM-based) location.

Check if persistent directory exists:
  ls /var/log/journal/

Should get "No such file or directory" initially.

Step 2: Create persistent journal directory
────────────────────────────────────────────
sudo mkdir /var/log/journal

Step 3: Set correct permissions
────────────────────────────────
Method 1: Using systemd-tmpfiles (recommended):
  sudo systemd-tmpfiles --create --prefix /var/log/journal

This automatically sets correct ownership and permissions.

Method 2: Manual permissions:
  sudo chown root:systemd-journal /var/log/journal
  sudo chmod 2755 /var/log/journal

The 2755 includes setgid bit (2) so new files inherit group.

Verify permissions:
  ls -ld /var/log/journal

Should show:
  drwxr-sr-x. 2 root systemd-journal 4096 Feb 08 10:30 /var/log/journal

The 's' in group permissions is the setgid bit.

Step 4: Restart systemd-journald
─────────────────────────────────
sudo systemctl restart systemd-journald

This tells journald to check for /var/log/journal and switch to it.

Step 5: Verify persistent storage
──────────────────────────────────
Check journal header:
  journalctl | head -1

Now should reference "System Journal" if working correctly.

List journal files:
  ls -lh /var/log/journal/

Should show a subdirectory with machine ID:
  /var/log/journal/a1b2c3d4e5f6.../

Inside that directory:
  ls -lh /var/log/journal/*/

Should show:
  system.journal      - Current journal file
  system@*.journal    - Rotated journal files

Generate a test log entry:
  logger "Test persistent journal entry"

Verify it's stored:
  journalctl -n 5

Should see your test message.

Understanding what happened:

Before:
  /run/log/journal/MACHINE-ID/system.journal  (volatile)
  
After:
  /var/log/journal/MACHINE-ID/system.journal  (persistent)
  /run/log/journal/MACHINE-ID/system.journal  (still exists)

Both locations can coexist. Journal in /var is persistent,
journal in /run is for early boot messages before /var mounts.

Storage configuration in journald.conf:

View configuration:
  grep "^Storage=" /etc/systemd/journald.conf || echo "Using default: auto"

Default is "auto" (commented out in config file).

Storage= options explained:

auto (default):
  - If /var/log/journal exists → use it (persistent)
  - If /var/log/journal missing → use /run/log/journal (volatile)
  - Most flexible option

persistent:
  - Always use /var/log/journal
  - Create directory if missing
  - Fail if can't create/write

volatile:
  - Always use /run/log/journal
  - Never persist across reboots
  - Useful for minimal systems

none:
  - Don't store journal at all
  - Still forwards to rsyslog if configured
  - Rarely used

To explicitly set persistent storage:

Edit /etc/systemd/journald.conf:
  sudo vi /etc/systemd/journald.conf

Uncomment and set:
  Storage=persistent

Restart:
  sudo systemctl restart systemd-journald

Benefits of persistent journal:

1. Historical analysis:
   - View logs from previous boots
   - Track issues over time
   - Audit user actions

2. Boot troubleshooting:
   - See why system crashed
   - Check boot errors
   - Analyze kernel panics

3. Security:
   - Retain authentication logs
   - Track unauthorized access
   - Maintain audit trail

View previous boots (persistent only):
  journalctl --list-boots

Shows:
  -2 a1b2c3d4... Fri 2026-02-06 08:00:00 EST - Fri 2026-02-06 18:00:00 EST
  -1 e5f6a7b8... Sat 2026-02-07 09:00:00 EST - Sat 2026-02-07 22:00:00 EST
   0 c9d0e1f2... Sun 2026-02-08 07:00:00 EST - Sun 2026-02-08 10:30:00 EST

View logs from previous boot:
  journalctl -b -1

View logs from specific boot:
  journalctl -b a1b2c3d4...

Disk space considerations:

Persistent journal uses disk space.
Default limits prevent unbounded growth:
  - Max 10% of filesystem size
  - Keep 15% filesystem free
  - Monthly rotation

Check journal disk usage:
  journalctl --disk-usage

Shows:
  Archived and active journals take up 512.0M in the file system.

This is important to monitor on systems with limited disk.

EOF
}

hint_step_3() {
    echo "  View config: cat /etc/systemd/journald.conf"
    echo "  Check usage: journalctl --disk-usage"
    echo "  Key settings: SystemMaxUse, SystemKeepFree, SystemMaxFileSize"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Understand journal size and retention configuration

Learn how to configure journal storage limits and rotation.

Requirements:
  • Examine /etc/systemd/journald.conf
  • Understand key size settings
  • Check current journal disk usage
  • Know how journal rotation works
  • Understand retention options

Key configuration file:
  /etc/systemd/journald.conf

Important settings to understand:
  SystemMaxUse=      - Max total journal size on disk
  SystemKeepFree=    - Min free space to keep on filesystem
  SystemMaxFileSize= - Max size of single journal file
  SystemMaxFiles=    - Max number of journal files to keep
  MaxRetentionSec=   - Max time to keep journal entries
  
Default behavior (when commented out):
  - Use up to 10% of filesystem size
  - Keep at least 15% free space
  - Rotate monthly
  - Keep files up to configured limits

Commands to use:
  cat /etc/systemd/journald.conf
  journalctl --disk-usage
  journalctl --verify
  du -sh /var/log/journal/

Understanding the defaults:

If /var/log/journal is on a 100GB filesystem:
  - Max journal size: 10GB (10% of 100GB)
  - Must keep 15GB free (15% of 100GB)
  - Actual max: whichever is more restrictive

Manual cleanup (if needed):
  journalctl --vacuum-size=500M  # Reduce to 500M
  journalctl --vacuum-time=30d   # Keep only last 30 days
  journalctl --vacuum-files=5    # Keep only 5 files

Note: You don't need to modify journald.conf for this step,
just understand what the settings mean and how they work.
EOF
}

validate_step_3() {
    # Understanding step, always pass if config file exists
    if [ ! -f /etc/systemd/journald.conf ]; then
        echo ""
        print_color "$RED" "✗ /etc/systemd/journald.conf not found"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
View journal configuration:
  cat /etc/systemd/journald.conf

Or just the uncommented lines:
  grep -v "^#" /etc/systemd/journald.conf | grep -v "^$"

Default configuration has everything commented out,
using built-in defaults.

Key storage settings explained:

SystemMaxUse=
  Maximum disk space journal can use
  Default: 10% of filesystem size
  Example: SystemMaxUse=2G

SystemKeepFree=
  Minimum free space to keep on filesystem
  Default: 15% of filesystem size
  Example: SystemKeepFree=1G

SystemMaxFileSize=
  Maximum size of individual journal file
  When reached, journal rotates
  Default: 1/8 of SystemMaxUse
  Example: SystemMaxFileSize=128M

SystemMaxFiles=
  Maximum number of rotated journal files
  Default: 100
  Oldest files deleted when limit reached
  Example: SystemMaxFiles=10

MaxRetentionSec=
  Maximum time to retain journal entries
  Format: seconds, or use suffixes (d, h, m, s)
  Default: Not set (size-based only)
  Example: MaxRetentionSec=30d

MaxFileSec=
  Force rotation after this time
  Default: 1month
  Example: MaxFileSec=1week

Understanding default behavior:

On a 100GB /var filesystem:
  SystemMaxUse: 10% = 10GB maximum
  SystemKeepFree: 15% = Must keep 15GB free
  
  If filesystem has only 20GB free:
    Journal limited to: 20GB - 15GB = 5GB
    (Can't use full 10GB because of KeepFree)

The more restrictive limit wins.

Check current journal disk usage:
  journalctl --disk-usage

Example output:
  Archived and active journals take up 512.0M in the file system.

View detailed usage:
  du -sh /var/log/journal/*

Shows size per machine ID directory.

List journal files:
  ls -lh /var/log/journal/*/

Shows:
  system.journal           - Active journal
  system@abc123.journal    - Rotated journals
  user-1000.journal        - User journal (if exists)

Verify journal integrity:
  journalctl --verify

Checks for corruption. Output shows:
  PASS: /var/log/journal/.../system.journal

Journal rotation:

Rotation happens when:
  1. SystemMaxFileSize reached
  2. MaxFileSec time elapsed (default 1 month)
  3. Manual rotation requested

Manual rotation:
  sudo systemctl kill --kill-who=main --signal=SIGUSR2 systemd-journald

Or use journalctl:
  sudo journalctl --rotate

Cleanup operations:

Reduce journal to 500M:
  sudo journalctl --vacuum-size=500M

Remove entries older than 30 days:
  sudo journalctl --vacuum-time=30d

Keep only 5 most recent files:
  sudo journalctl --vacuum-files=5

These are immediate actions, not configuration.

Example configuration for limited disk:

Edit /etc/systemd/journald.conf:
  sudo vi /etc/systemd/journald.conf

Set conservative limits:
  [Journal]
  SystemMaxUse=500M
  SystemKeepFree=1G
  SystemMaxFileSize=50M
  SystemMaxFiles=10
  MaxRetentionSec=30d

Restart journald:
  sudo systemctl restart systemd-journald

Verify new limits:
  journalctl --disk-usage

Example configuration for maximum retention:

For systems with plenty of disk space:
  [Journal]
  SystemMaxUse=5G
  SystemKeepFree=2G
  MaxRetentionSec=90d

This keeps 3 months of history.

Runtime (volatile) settings:

Similar settings for /run/log/journal:
  RuntimeMaxUse=      - Default: 10% of /run size
  RuntimeKeepFree=    - Default: 15% of /run free
  RuntimeMaxFileSize= - Max file size in /run
  RuntimeMaxFiles=    - Max files in /run

These apply to volatile journal in RAM.

Important notes:

1. Changes require restart:
   sudo systemctl restart systemd-journald

2. Invalid settings are ignored:
   Check logs for errors:
   journalctl -u systemd-journald

3. Size suffixes supported:
   K, M, G, T (1024-based)
   Example: 512M, 2G

4. Time suffixes:
   s (seconds)
   m (minutes)  
   h (hours)
   d (days)
   month, year

5. Setting to 0:
   Disables that particular limit

Best practices:

Development/test systems:
  - Smaller journals (500M - 1G)
  - Shorter retention (7-30 days)
  - Frequent rotation

Production servers:
  - Larger journals (2G - 10G)
  - Longer retention (60-90 days)
  - Balance with disk space

Monitoring systems:
  - Very large journals (10G+)
  - Extended retention (6-12 months)
  - Regular archival to external storage

Desktop systems:
  - Medium journals (1G - 2G)
  - Moderate retention (30 days)
  - Automatic cleanup

Troubleshooting journal issues:

Journal too large:
  journalctl --disk-usage
  journalctl --vacuum-size=1G

Can't write to journal:
  ls -ld /var/log/journal/
  # Check permissions

Journal corrupted:
  journalctl --verify
  # May need to remove corrupt files

Journal not persisting:
  ls /var/log/journal/
  # Ensure directory exists
  systemctl status systemd-journald
  # Ensure service running

Related commands:

Show journal statistics:
  journalctl --header

Rotate journals now:
  journalctl --rotate

Force cleanup:
  journalctl --flush

Sync journal to disk:
  journalctl --sync

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=3
    
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
    
    # CHECK 2: Persistent journal directory exists
    print_color "$CYAN" "[2/$total] Checking persistent journal storage..."
    if [ -d /var/log/journal ]; then
        # Check if journal files exist
        if ls /var/log/journal/*/system.journal >/dev/null 2>&1; then
            print_color "$GREEN" "  ✓ Persistent journal configured and in use"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ /var/log/journal exists but no journal files yet"
            echo "  Restart journald: systemctl restart systemd-journald"
        fi
    else
        print_color "$RED" "  ✗ /var/log/journal directory not found"
        echo "  Create with: mkdir /var/log/journal"
        echo "  Then restart: systemctl restart systemd-journald"
    fi
    echo ""
    
    # CHECK 3: Understanding of configuration
    print_color "$CYAN" "[3/$total] Checking journal configuration understanding..."
    if [ -f /etc/systemd/journald.conf ]; then
        print_color "$GREEN" "  ✓ journald.conf exists and can be reviewed"
        ((score++))
    else
        print_color "$RED" "  ✗ /etc/systemd/journald.conf not found"
    fi
    echo ""
    
    # Additional information
    if [ -d /var/log/journal ]; then
        echo "Journal information:"
        local usage=$(journalctl --disk-usage 2>/dev/null | grep -oP '\d+\.\d+[KMGT]' | head -1)
        if [ -n "$usage" ]; then
            echo "  Current disk usage: $usage"
        fi
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've mastered journald basics:"
        echo "  • Querying and filtering journal logs"
        echo "  • Making journal persistent across reboots"
        echo "  • Understanding journal configuration options"
        echo ""
        echo "You're ready for RHCSA journald questions!"
    elif [ $score -ge 2 ]; then
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
    
    [ $score -ge 2 ]
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

Critical skills for RHCSA:

1. Query journal: journalctl with filters
2. Make persistent: mkdir /var/log/journal && systemctl restart systemd-journald
3. Filter by priority: journalctl -p err
4. Filter by unit: journalctl -u service.service
5. Filter by time: journalctl --since "1 hour ago"
6. Current boot: journalctl -b
7. Check storage: journalctl | head -1 or journalctl --disk-usage

Quick reference:
  View logs:     journalctl
  Filter:        journalctl -p err -u sshd.service --since today
  Make persistent: mkdir /var/log/journal; systemctl restart systemd-journald
  Check usage:   journalctl --disk-usage
  Previous boot: journalctl -b -1
  Follow:        journalctl -f

Remember:
  • Journal is volatile by default
  • Creating /var/log/journal makes it persistent
  • Priority levels: debug(7) info(6) notice(5) warning(4) err(3) crit(2) alert(1) emerg(0)
  • Lower number = higher severity
  • Always restart journald after config changes

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Optionally restore volatile-only journal
    # Uncomment if you want to return to default state
    # if [ -d /var/log/journal ]; then
    #     systemctl stop systemd-journald
    #     rm -rf /var/log/journal
    #     systemctl start systemd-journald
    # fi
    
    echo "  ✓ Lab cleanup complete"
    echo ""
    echo "Note: Persistent journal (/var/log/journal) was left in place."
    echo "This is the recommended configuration for production systems."
    echo "To return to volatile-only journal:"
    echo "  sudo systemctl stop systemd-journald"
    echo "  sudo rm -rf /var/log/journal"
    echo "  sudo systemctl start systemd-journald"
}

# Execute the main framework
main "$@"
