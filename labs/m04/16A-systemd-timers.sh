#!/bin/bash
# labs/m04/16A-systemd-timers.sh
# Lab: Systemd Timers for Scheduled Tasks
# Difficulty: Intermediate
# RHCSA Objective: 16.2 - Scheduling tasks with systemd timers

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Systemd Timers for Scheduled Tasks"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="45-60 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create lab directory for scripts
    mkdir -p /opt/lab-timers
    
    # Create a backup script to be scheduled
    cat > /opt/lab-timers/backup-logs.sh << 'SCRIPT'
#!/bin/bash
# Simple log backup script
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/var/backups/lab-logs"
mkdir -p "$BACKUP_DIR"

# Simulate backup
echo "[$TIMESTAMP] Log backup started" >> /var/log/lab-backup.log
tar -czf "$BACKUP_DIR/logs-$TIMESTAMP.tar.gz" /var/log/*.log 2>/dev/null
echo "[$TIMESTAMP] Log backup completed" >> /var/log/lab-backup.log
SCRIPT
    chmod +x /opt/lab-timers/backup-logs.sh
    
    # Create a monitoring script
    cat > /opt/lab-timers/disk-monitor.sh << 'SCRIPT'
#!/bin/bash
# Disk space monitoring script
TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
echo "[$TIMESTAMP] Disk usage check:" >> /var/log/lab-disk-monitor.log
df -h / | tail -1 >> /var/log/lab-disk-monitor.log
SCRIPT
    chmod +x /opt/lab-timers/disk-monitor.sh
    
    # Create a cleanup script
    cat > /opt/lab-timers/temp-cleanup.sh << 'SCRIPT'
#!/bin/bash
# Temporary file cleanup script
TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
echo "[$TIMESTAMP] Cleaning temporary files" >> /var/log/lab-cleanup.log
# Simulate cleanup
find /tmp -type f -name "lab-temp-*" -mtime +1 -delete 2>/dev/null
echo "[$TIMESTAMP] Cleanup completed" >> /var/log/lab-cleanup.log
SCRIPT
    chmod +x /opt/lab-timers/temp-cleanup.sh
    
    # Clean up any previous lab attempts
    systemctl stop lab-backup.timer 2>/dev/null || true
    systemctl disable lab-backup.timer 2>/dev/null || true
    systemctl stop lab-backup.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-backup.timer 2>/dev/null || true
    rm -f /etc/systemd/system/lab-backup.service 2>/dev/null || true
    
    systemctl stop lab-disk-monitor.timer 2>/dev/null || true
    systemctl disable lab-disk-monitor.timer 2>/dev/null || true
    systemctl stop lab-disk-monitor.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-disk-monitor.timer 2>/dev/null || true
    rm -f /etc/systemd/system/lab-disk-monitor.service 2>/dev/null || true
    
    systemctl stop lab-cleanup.timer 2>/dev/null || true
    systemctl disable lab-cleanup.timer 2>/dev/null || true
    systemctl stop lab-cleanup.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-cleanup.timer 2>/dev/null || true
    rm -f /etc/systemd/system/lab-cleanup.service 2>/dev/null || true
    
    # Clean up log files
    rm -f /var/log/lab-backup.log 2>/dev/null || true
    rm -f /var/log/lab-disk-monitor.log 2>/dev/null || true
    rm -f /var/log/lab-cleanup.log 2>/dev/null || true
    rm -rf /var/backups/lab-logs 2>/dev/null || true
    
    systemctl daemon-reload
    
    echo "  ✓ Lab scripts created in /opt/lab-timers"
    echo "  ✓ Previous lab attempts cleaned up"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of systemd services and units
  • Familiarity with systemctl commands
  • Basic knowledge of shell scripts
  • Understanding of system scheduling concepts

Commands You'll Use:
  • systemctl list-timers - List active timers
  • systemctl start/stop/enable TIMER - Manage timer units
  • systemctl status TIMER - Check timer status
  • systemctl cat TIMER - View timer configuration
  • journalctl -u SERVICE - View service execution logs
  • systemd-analyze calendar - Test OnCalendar expressions

Files You'll Interact With:
  • /etc/systemd/system/*.timer - Timer unit files
  • /etc/systemd/system/*.service - Service unit files (paired with timers)
  • /var/log/* - Log files showing scheduled task execution

Key Concepts:
  • Timers are paired with services (timer + service with same name)
  • Enable and start the TIMER, not the service
  • OnCalendar uses specific time format syntax
  • Timers are the modern replacement for cron in RHEL

Reference Material:
  • man 5 systemd.timer - Timer unit configuration
  • man 7 systemd.time - Time and date specification
  • man systemd-analyze - Calendar expression testing
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're managing a RHEL 10 server that requires automated maintenance tasks.
The company has standardized on systemd timers for all scheduled tasks instead
of cron. You need to create timers for log backups, disk monitoring, and
temporary file cleanup with specific schedules.

BACKGROUND:
Systemd timers are the preferred method for scheduling recurring tasks in RHEL 10.
They offer advantages over cron including better logging, dependency management,
and integration with systemd. Each timer is paired with a service unit that
defines what to run. The RHCSA exam expects you to create and manage timers.

OBJECTIVES:
  1. Explore existing systemd timers on the system
     • List all active timers
     • Examine an existing timer configuration
     • Understand timer/service pairing
     • View timer execution logs
     • Learn the OnCalendar syntax
     
  2. Create a daily backup timer
     • Service name: lab-backup.service
     • Service script: /opt/lab-timers/backup-logs.sh
     • Timer name: lab-backup.timer
     • Schedule: Daily at 2:00 AM (OnCalendar=*-*-* 02:00:00)
     • Must be enabled to start at boot
     • Verify timer is scheduled correctly
     
  3. Create a frequent monitoring timer
     • Service name: lab-disk-monitor.service
     • Service script: /opt/lab-timers/disk-monitor.sh
     • Timer name: lab-disk-monitor.timer
     • Schedule: Every 10 minutes (OnCalendar=*:00/10)
     • Enable and start the timer
     • Manually trigger execution and verify logs
     
  4. Create a weekly cleanup timer with boot delay
     • Service name: lab-cleanup.service
     • Service script: /opt/lab-timers/temp-cleanup.sh
     • Timer name: lab-cleanup.timer
     • Schedule: Weekly on Sunday at 3:00 AM (OnCalendar=Sun *-*-* 03:00:00)
     • Also run 15 minutes after boot (OnBootSec=15min)
     • Enable the timer
     • Test the OnCalendar expression before implementing

HINTS:
  • Always create the service unit BEFORE the timer unit
  • Enable/start the TIMER, not the service
  • Use systemd-analyze calendar to test time expressions
  • systemctl list-timers shows when timer will next trigger
  • journalctl -u SERVICE shows execution history
  • Don't forget systemctl daemon-reload after creating units

SUCCESS CRITERIA:
  • All three timer/service pairs are created correctly
  • Timers are enabled and will start at boot
  • OnCalendar schedules match requirements exactly
  • Can verify timer schedules with systemctl list-timers
  • Services execute successfully when triggered
  • Logs show successful execution
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore existing timers and understand timer/service pairing
  ☐ 2. Create daily backup timer (2:00 AM daily)
  ☐ 3. Create monitoring timer (every 10 minutes)
  ☐ 4. Create weekly cleanup timer (Sunday 3:00 AM + boot delay)
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
You're configuring systemd timers for automated maintenance tasks on a RHEL 10
server. You'll create timers for backups, monitoring, and cleanup with different
schedules using the OnCalendar syntax.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore existing systemd timers and understand how they work

Before creating timers, understand how systemd manages scheduled tasks
and how timers pair with services.

Requirements:
  • List all active timers on the system
  • View the configuration of an existing timer
  • Understand the timer/service relationship
  • Test OnCalendar time expressions
  • View timer execution logs

Questions to explore:
  • What timers are currently active on the system?
  • How do timers and services work together?
  • What is the OnCalendar syntax format?
  • How can you test time expressions before using them?

Key commands to use:
  systemctl list-timers
  systemctl list-timers --all
  systemctl cat systemd-tmpfiles-clean.timer
  systemd-analyze calendar "daily"
  systemd-analyze calendar "*:00/10"
  journalctl -u systemd-tmpfiles-clean.service

Understanding timers is essential before creating your own.
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  List timers: systemctl list-timers"
    echo "  View timer: systemctl cat TIMER"
    echo "  Test schedule: systemd-analyze calendar 'EXPRESSION'"
    echo "  View logs: journalctl -u SERVICE"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
List active timers:
  systemctl list-timers

Output shows:
  NEXT                         LEFT          LAST                         PASSED  UNIT
  Mon 2026-02-03 00:00:00 EST  1h 23min left Sun 2026-02-02 00:00:00 EST  22h ago systemd-tmpfiles-clean.timer

List all timers (including inactive):
  systemctl list-timers --all

Examine an existing timer:
  systemctl cat systemd-tmpfiles-clean.timer

Shows:
  [Unit]
  Description=Daily Cleanup of Temporary Directories
  
  [Timer]
  OnBootSec=15min
  OnUnitActiveSec=1d

View the paired service:
  systemctl cat systemd-tmpfiles-clean.service

Test OnCalendar expressions:
  systemd-analyze calendar "daily"
  # Shows: *-*-* 00:00:00

  systemd-analyze calendar "*:00/10"
  # Shows: *-*-* *:00/10:00 (every 10 minutes)

  systemd-analyze calendar "Mon *-*-* 09:00:00"
  # Shows: Mon *-*-* 09:00:00 (Mondays at 9 AM)

  systemd-analyze calendar "Sun *-*-* 03:00:00"
  # Shows: Sun *-*-* 03:00:00 (Sundays at 3 AM)

View when a timer last ran:
  journalctl -u systemd-tmpfiles-clean.service -n 5

Understanding timer/service pairing:

Timer Unit (.timer):
  • Defines WHEN to run
  • Contains scheduling directives
  • Names must match service name
  • Example: backup.timer activates backup.service

Service Unit (.service):
  • Defines WHAT to run
  • Contains ExecStart and execution details
  • Triggered by the timer
  • Example: backup.service runs the backup script

Critical relationship:
  backup.timer (WHEN) → activates → backup.service (WHAT)

You enable/start the TIMER:
  systemctl enable --now backup.timer

The service is activated by the timer automatically.

OnCalendar syntax basics:

Format: DayOfWeek Year-Month-Day Hour:Minute:Second

Examples:
  *-*-* 02:00:00          Daily at 2 AM
  *:00/10                 Every 10 minutes
  Mon *-*-* 09:00:00      Mondays at 9 AM
  *-*-01 00:00:00         First day of month at midnight
  Sun *-*-* 03:00:00      Sundays at 3 AM

Wildcards and ranges:
  *        Any value
  /N       Every N units (e.g., /10 = every 10)
  X,Y,Z    Multiple values (e.g., 1,15 = 1st and 15th)
  X..Y     Range (e.g., 1..5 = 1 through 5)

Special shortcuts:
  minutely    = *-*-* *:*:00
  hourly      = *-*-* *:00:00
  daily       = *-*-* 00:00:00
  weekly      = Mon *-*-* 00:00:00
  monthly     = *-*-01 00:00:00
  yearly      = *-01-01 00:00:00

Other timer options:

OnBootSec=15min
  Run 15 minutes after system boot

OnUnitActiveSec=1d
  Run 1 day after last activation

OnStartupSec=10min
  Run 10 minutes after systemd started

AccuracySec=1min
  Accuracy window (default is 1 minute)

Persistent=true
  Catch up on missed runs after downtime

Why use timers over cron:
  1. Better logging (journald integration)
  2. Dependency management (can require other units)
  3. Resource control (cgroups, limits)
  4. Consistent with systemd ecosystem
  5. More precise control over execution

EOF
}

hint_step_2() {
    echo "  Create service first: /etc/systemd/system/lab-backup.service"
    echo "  Then timer: /etc/systemd/system/lab-backup.timer"
    echo "  Schedule: OnCalendar=*-*-* 02:00:00"
    echo "  Enable timer: systemctl enable --now lab-backup.timer"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create a daily backup timer scheduled for 2:00 AM

Create your first timer/service pair for daily log backups.

Requirements:
  • Service file: /etc/systemd/system/lab-backup.service
    - Description: Lab Log Backup Service
    - Type: oneshot
    - ExecStart: /opt/lab-timers/backup-logs.sh
  
  • Timer file: /etc/systemd/system/lab-backup.timer
    - Description: Lab Log Backup Timer
    - OnCalendar: *-*-* 02:00:00 (2:00 AM daily)
    - WantedBy: timers.target
  
  • Enable and start the timer
  • Verify it appears in timer list
  • Manually trigger the service to test it works

Important notes:
  • Create the SERVICE first, then the TIMER
  • Use Type=oneshot for scripts that complete
  • Enable/start the TIMER, not the service
  • Timer name must match service name (lab-backup)

The script is already created at /opt/lab-timers/backup-logs.sh
EOF
}

validate_step_2() {
    local failures=0
    
    # Check service exists
    if [ ! -f /etc/systemd/system/lab-backup.service ]; then
        echo ""
        print_color "$RED" "✗ lab-backup.service not found"
        ((failures++))
    else
        # Check service has correct ExecStart
        if ! grep -q "ExecStart=/opt/lab-timers/backup-logs.sh" /etc/systemd/system/lab-backup.service; then
            echo ""
            print_color "$RED" "✗ Service ExecStart incorrect"
            ((failures++))
        fi
        
        # Check Type=oneshot
        if ! grep -q "Type=oneshot" /etc/systemd/system/lab-backup.service; then
            echo ""
            print_color "$RED" "✗ Service should use Type=oneshot"
            ((failures++))
        fi
    fi
    
    # Check timer exists
    if [ ! -f /etc/systemd/system/lab-backup.timer ]; then
        echo ""
        print_color "$RED" "✗ lab-backup.timer not found"
        ((failures++))
    else
        # Check OnCalendar schedule
        if ! grep -q "OnCalendar=\*-\*-\* 02:00:00" /etc/systemd/system/lab-backup.timer; then
            echo ""
            print_color "$RED" "✗ Timer OnCalendar schedule incorrect"
            echo "  Expected: OnCalendar=*-*-* 02:00:00"
            ((failures++))
        fi
    fi
    
    # Check timer is enabled
    if ! systemctl is-enabled lab-backup.timer >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Timer not enabled"
        ((failures++))
    fi
    
    # Check timer is active
    if ! systemctl is-active lab-backup.timer >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Timer not started"
        ((failures++))
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
Step 1: Create the service unit
────────────────────────────────
sudo vi /etc/systemd/system/lab-backup.service

[Unit]
Description=Lab Log Backup Service
Documentation=man:systemd.timer(5)

[Service]
Type=oneshot
ExecStart=/opt/lab-timers/backup-logs.sh

Step 2: Create the timer unit
──────────────────────────────
sudo vi /etc/systemd/system/lab-backup.timer

[Unit]
Description=Lab Log Backup Timer
Documentation=man:systemd.timer(5)

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target

Step 3: Reload, enable, and start
──────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable --now lab-backup.timer

Step 4: Verify the timer
────────────────────────
systemctl list-timers lab-backup.timer
systemctl status lab-backup.timer

Step 5: Test the service manually
──────────────────────────────────
sudo systemctl start lab-backup.service
journalctl -u lab-backup.service -n 10

Check the log:
  tail /var/log/lab-backup.log

Check backup files:
  ls -lh /var/backups/lab-logs/

Understanding the configuration:

Service unit [Unit] section:
  Description: Human-readable description
  Documentation: Reference to man pages

Service unit [Service] section:
  Type=oneshot:
    - Service completes and exits
    - Perfect for backup scripts
    - Systemd waits for completion
    - Different from Type=simple

  ExecStart:
    - Command to execute
    - Must be absolute path
    - Script must be executable

Timer unit [Timer] section:
  OnCalendar=*-*-* 02:00:00:
    - Schedule format: Year-Month-Day Hour:Minute:Second
    - *-*-* means every day
    - 02:00:00 means 2 AM
    - Runs daily at 2:00 AM

  Persistent=true:
    - If system was off at scheduled time
    - Timer runs when system comes back up
    - Catches up on missed executions
    - Good for backups

Timer unit [Install] section:
  WantedBy=timers.target:
    - Makes timer start at boot
    - timers.target is the standard target
    - Creates symlink when enabled

Why Type=oneshot for backup scripts:
  • Script runs to completion
  • Systemd knows when it's done
  • Can depend on completion
  • Proper for batch jobs

Testing OnCalendar expression:
  systemd-analyze calendar "*-*-* 02:00:00"
  # Output shows: *-*-* 02:00:00
  # Next elapse: [next 2 AM]

Viewing timer details:
  systemctl cat lab-backup.timer
  systemctl show lab-backup.timer
  systemctl list-timers --all

Manual execution for testing:
  sudo systemctl start lab-backup.service
  # Runs immediately, doesn't affect timer schedule

EOF
}

hint_step_3() {
    echo "  Schedule every 10 min: OnCalendar=*:00/10"
    echo "  Create service first, then timer"
    echo "  Test manually: systemctl start lab-disk-monitor.service"
    echo "  Check logs: journalctl -u lab-disk-monitor.service"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create a monitoring timer that runs every 10 minutes

Create a frequent timer for disk space monitoring.

Requirements:
  • Service file: /etc/systemd/system/lab-disk-monitor.service
    - Description: Lab Disk Monitor Service
    - Type: oneshot
    - ExecStart: /opt/lab-timers/disk-monitor.sh
  
  • Timer file: /etc/systemd/system/lab-disk-monitor.timer
    - Description: Lab Disk Monitor Timer
    - OnCalendar: *:00/10 (every 10 minutes)
    - AccuracySec: 1s (for more precise timing)
    - WantedBy: timers.target
  
  • Enable and start the timer
  • Verify it's scheduled correctly
  • Manually trigger execution to test
  • Check logs to confirm it works

The timer should run at:
  00:00, 00:10, 00:20, 00:30, 00:40, 00:50
  01:00, 01:10, 01:20, etc.

Test the schedule expression before implementing:
  systemd-analyze calendar "*:00/10"
EOF
}

validate_step_3() {
    local failures=0
    
    # Check service exists
    if [ ! -f /etc/systemd/system/lab-disk-monitor.service ]; then
        echo ""
        print_color "$RED" "✗ lab-disk-monitor.service not found"
        ((failures++))
    fi
    
    # Check timer exists
    if [ ! -f /etc/systemd/system/lab-disk-monitor.timer ]; then
        echo ""
        print_color "$RED" "✗ lab-disk-monitor.timer not found"
        ((failures++))
    else
        # Check OnCalendar schedule - accept multiple valid formats
        # Valid: *:00/10, *:0/10, *-*-* *:00/10, *-*-* *:0/10:00
        if grep -qE "OnCalendar=(\*-\*-\* )?\*:0{0,2}/10(:00)?" /etc/systemd/system/lab-disk-monitor.timer; then
            # Valid schedule found, no error
            :
        else
            echo ""
            print_color "$RED" "✗ Timer OnCalendar schedule incorrect"
            echo "  Expected: OnCalendar=*:00/10 (or similar valid format)"
            echo "  Your timer contains:"
            grep "OnCalendar=" /etc/systemd/system/lab-disk-monitor.timer
            ((failures++))
        fi
    fi
    
    # Check timer is enabled
    if ! systemctl is-enabled lab-disk-monitor.timer >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Timer not enabled"
        ((failures++))
    fi
    
    # Check timer is active
    if ! systemctl is-active lab-disk-monitor.timer >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Timer not started"
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
Step 1: Test the time expression
─────────────────────────────────
systemd-analyze calendar "*:00/10"

Output shows:
  Original form: *:00/10
  Normalized form: *-*-* *:00/10:00
  Next elapse: [next 10-minute mark]

Step 2: Create the service
───────────────────────────
sudo vi /etc/systemd/system/lab-disk-monitor.service

[Unit]
Description=Lab Disk Monitor Service

[Service]
Type=oneshot
ExecStart=/opt/lab-timers/disk-monitor.sh

Step 3: Create the timer
────────────────────────
sudo vi /etc/systemd/system/lab-disk-monitor.timer

[Unit]
Description=Lab Disk Monitor Timer

[Timer]
OnCalendar=*:00/10
AccuracySec=1s

[Install]
WantedBy=timers.target

Step 4: Reload and enable
─────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable --now lab-disk-monitor.timer

Step 5: Verify the timer
────────────────────────
systemctl list-timers lab-disk-monitor.timer
systemctl status lab-disk-monitor.timer

Step 6: Test immediately
────────────────────────
sudo systemctl start lab-disk-monitor.service
journalctl -u lab-disk-monitor.service -n 5
tail /var/log/lab-disk-monitor.log

Understanding the schedule:

OnCalendar=*:00/10 explained:
  *:00/10 means:
    - Every hour (*)
    - Starting at minute 00
    - Every 10 minutes (/10)
  
  Expands to: *-*-* *:00/10:00
  
  Runs at:
    00:00, 00:10, 00:20, 00:30, 00:40, 00:50
    01:00, 01:10, 01:20, 01:30, 01:40, 01:50
    etc.

Alternative formats (equivalent):
  *-*-* *:00/10:00    Full format
  *:00/10             Short format
  *:0/10              Even shorter

AccuracySec=1s:
  • Controls timing precision
  • Default is 1 minute
  • Setting to 1s makes it more precise
  • Timer fires within 1 second of scheduled time
  • More precise = more resources

Frequent timers considerations:
  • Every 10 minutes is common for monitoring
  • Consider system load
  • Make scripts efficient
  • Use oneshot type for completion tracking

Viewing next execution:
  systemctl list-timers lab-disk-monitor.timer
  Shows: NEXT column with next scheduled run

Viewing execution history:
  journalctl -u lab-disk-monitor.service --since today
  Shows all executions today

Common interval patterns:
  Every 5 minutes:   *:00/5
  Every 15 minutes:  *:00/15
  Every 30 minutes:  *:00/30
  Every hour:        *:00:00 or hourly

EOF
}

hint_step_4() {
    echo "  Schedule: OnCalendar=Sun *-*-* 03:00:00"
    echo "  Also add: OnBootSec=15min"
    echo "  Test first: systemd-analyze calendar 'Sun *-*-* 03:00:00'"
    echo "  Use Persistent=true for missed runs"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Create a weekly cleanup timer with boot delay

Create a timer with multiple triggers: weekly schedule AND boot delay.

Requirements:
  • Service file: /etc/systemd/system/lab-cleanup.service
    - Description: Lab Temp Cleanup Service
    - Type: oneshot
    - ExecStart: /opt/lab-timers/temp-cleanup.sh
  
  • Timer file: /etc/systemd/system/lab-cleanup.timer
    - Description: Lab Temp Cleanup Timer
    - OnCalendar: Sun *-*-* 03:00:00 (Sunday 3:00 AM)
    - OnBootSec: 15min (also run 15 min after boot)
    - Persistent: true (catch up on missed runs)
    - WantedBy: timers.target
  
  • Test the OnCalendar expression BEFORE creating files
  • Enable and start the timer
  • Verify the schedule is correct

This timer has TWO triggers:
  1. Every Sunday at 3:00 AM
  2. 15 minutes after system boot

Test both schedules:
  systemd-analyze calendar "Sun *-*-* 03:00:00"
  # Should show Sunday 3 AM

The timer will run at whichever comes first.
EOF
}

validate_step_4() {
    local failures=0
    
    # Check service exists
    if [ ! -f /etc/systemd/system/lab-cleanup.service ]; then
        echo ""
        print_color "$RED" "✗ lab-cleanup.service not found"
        ((failures++))
    fi
    
    # Check timer exists
    if [ ! -f /etc/systemd/system/lab-cleanup.timer ]; then
        echo ""
        print_color "$RED" "✗ lab-cleanup.timer not found"
        ((failures++))
    else
        # Check OnCalendar schedule for Sunday
        if ! grep -q "OnCalendar=Sun \*-\*-\* 03:00:00" /etc/systemd/system/lab-cleanup.timer; then
            echo ""
            print_color "$RED" "✗ Timer OnCalendar schedule incorrect"
            echo "  Expected: OnCalendar=Sun *-*-* 03:00:00"
            ((failures++))
        fi
        
        # Check OnBootSec
        if ! grep -q "OnBootSec=15min" /etc/systemd/system/lab-cleanup.timer; then
            echo ""
            print_color "$RED" "✗ Timer missing OnBootSec=15min"
            ((failures++))
        fi
    fi
    
    # Check timer is enabled
    if ! systemctl is-enabled lab-cleanup.timer >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Timer not enabled"
        ((failures++))
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Test the weekly schedule
─────────────────────────────────
systemd-analyze calendar "Sun *-*-* 03:00:00"

Output shows:
  Original form: Sun *-*-* 03:00:00
  Normalized form: Sun *-*-* 03:00:00
  Next elapse: Sun 2026-02-08 03:00:00 EST
  From now: [days until Sunday]

Step 2: Create the service
───────────────────────────
sudo vi /etc/systemd/system/lab-cleanup.service

[Unit]
Description=Lab Temp Cleanup Service

[Service]
Type=oneshot
ExecStart=/opt/lab-timers/temp-cleanup.sh

Step 3: Create the timer
────────────────────────
sudo vi /etc/systemd/system/lab-cleanup.timer

[Unit]
Description=Lab Temp Cleanup Timer

[Timer]
OnCalendar=Sun *-*-* 03:00:00
OnBootSec=15min
Persistent=true

[Install]
WantedBy=timers.target

Step 4: Reload and enable
─────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable --now lab-cleanup.timer

Step 5: Verify the timer
────────────────────────
systemctl list-timers lab-cleanup.timer
systemctl status lab-cleanup.timer

Understanding multiple triggers:

This timer has TWO activation triggers:

1. OnCalendar=Sun *-*-* 03:00:00
   - Runs every Sunday at 3:00 AM
   - Weekly scheduled cleanup

2. OnBootSec=15min
   - Runs 15 minutes after system boot
   - Ensures cleanup runs even if system was off Sunday

Timer behavior:
  • Whichever trigger comes first activates the timer
  • Both triggers remain active
  • After execution, waits for next trigger
  • Independent triggers

OnCalendar day of week syntax:
  Sun     Sunday
  Mon     Monday
  Tue     Tuesday
  Wed     Wednesday
  Thu     Thursday
  Fri     Friday
  Sat     Saturday

  Can also use numbers: 0 or 7 = Sunday, 1 = Monday, etc.

Examples:
  Mon *-*-* 09:00:00          Monday 9 AM
  Fri *-*-* 17:00:00          Friday 5 PM
  Mon,Wed,Fri *-*-* 12:00:00  MWF at noon
  Mon..Fri *-*-* 08:00:00     Weekdays 8 AM

OnBootSec usage:
  OnBootSec=15min:
    - Waits 15 minutes after boot
    - Then runs service once
    - Good for startup tasks
    - Doesn't repeat (OnCalendar handles recurring)

  Common OnBootSec values:
    OnBootSec=5min      Quick startup task
    OnBootSec=15min     Standard delay
    OnBootSec=1h        After system stabilizes

Persistent=true explained:
  Without Persistent:
    - If system off at scheduled time
    - Missed execution is skipped
    - Waits for next schedule

  With Persistent=true:
    - If system off at scheduled time
    - Timer runs when system comes back
    - Catches up on missed runs
    - Good for critical tasks

Example scenario:
  Sunday 3 AM scheduled
  System was off all weekend
  System boots Monday 9 AM
  
  Without Persistent:
    - Skips Sunday run
    - Waits until next Sunday
  
  With Persistent=true:
    - Runs shortly after Monday boot
    - Catches up on Sunday's missed run

Combining boot and calendar triggers:

Use case 1: Critical maintenance
  OnCalendar=daily
  OnBootSec=30min
  Persistent=true
  → Ensures daily run + startup run + catch-up

Use case 2: Weekly backup
  OnCalendar=Sun *-*-* 02:00:00
  OnBootSec=1h
  Persistent=true
  → Sunday backup + boot backup + catch-up

Use case 3: Monitoring
  OnCalendar=*:00/5
  OnBootSec=2min
  → Every 5 min + quick start after boot

Viewing timer status:
  systemctl list-timers lab-cleanup.timer

Shows:
  NEXT    When timer triggers next
  LEFT    Time until next trigger
  LAST    Last time it triggered
  PASSED  Time since last trigger

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=9
    
    echo "Checking your systemd timer configuration..."
    echo ""
    
    # CHECK 1: Backup service exists
    print_color "$CYAN" "[1/$total] Checking lab-backup.service..."
    if [ -f /etc/systemd/system/lab-backup.service ]; then
        if grep -q "ExecStart=/opt/lab-timers/backup-logs.sh" /etc/systemd/system/lab-backup.service && \
           grep -q "Type=oneshot" /etc/systemd/system/lab-backup.service; then
            print_color "$GREEN" "  ✓ Backup service correctly configured"
            ((score++))
        else
            print_color "$RED" "  ✗ Backup service exists but misconfigured"
        fi
    else
        print_color "$RED" "  ✗ lab-backup.service not found"
    fi
    echo ""
    
    # CHECK 2: Backup timer exists and configured
    print_color "$CYAN" "[2/$total] Checking lab-backup.timer..."
    if [ -f /etc/systemd/system/lab-backup.timer ]; then
        if grep -q "OnCalendar=\*-\*-\* 02:00:00" /etc/systemd/system/lab-backup.timer; then
            print_color "$GREEN" "  ✓ Backup timer schedule correct (2:00 AM daily)"
            ((score++))
        else
            print_color "$RED" "  ✗ Backup timer schedule incorrect"
            print_color "$YELLOW" "  Expected: OnCalendar=*-*-* 02:00:00"
        fi
    else
        print_color "$RED" "  ✗ lab-backup.timer not found"
    fi
    echo ""
    
    # CHECK 3: Backup timer enabled
    print_color "$CYAN" "[3/$total] Checking lab-backup.timer status..."
    if systemctl is-enabled lab-backup.timer >/dev/null 2>&1 && \
       systemctl is-active lab-backup.timer >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Backup timer enabled and active"
        ((score++))
    else
        print_color "$RED" "  ✗ Backup timer not enabled or not active"
    fi
    echo ""
    
    # CHECK 4: Disk monitor service exists
    print_color "$CYAN" "[4/$total] Checking lab-disk-monitor.service..."
    if [ -f /etc/systemd/system/lab-disk-monitor.service ]; then
        if grep -q "ExecStart=/opt/lab-timers/disk-monitor.sh" /etc/systemd/system/lab-disk-monitor.service; then
            print_color "$GREEN" "  ✓ Disk monitor service configured"
            ((score++))
        else
            print_color "$RED" "  ✗ Disk monitor service misconfigured"
        fi
    else
        print_color "$RED" "  ✗ lab-disk-monitor.service not found"
    fi
    echo ""
    
    # CHECK 5: Disk monitor timer schedule
    print_color "$CYAN" "[5/$total] Checking lab-disk-monitor.timer..."
    if [ -f /etc/systemd/system/lab-disk-monitor.timer ]; then
        # Accept multiple valid formats for every 10 minutes
        if grep -qE "OnCalendar=(\*-\*-\* )?\*:0{0,2}/10(:00)?" /etc/systemd/system/lab-disk-monitor.timer; then
            print_color "$GREEN" "  ✓ Monitor timer schedule correct (every 10 minutes)"
            ((score++))
        else
            print_color "$RED" "  ✗ Monitor timer schedule incorrect"
            print_color "$YELLOW" "  Expected: OnCalendar=*:00/10 (or similar)"
            echo "  Your timer contains:"
            grep "OnCalendar=" /etc/systemd/system/lab-disk-monitor.timer || echo "  No OnCalendar found"
        fi
    else
        print_color "$RED" "  ✗ lab-disk-monitor.timer not found"
    fi
    echo ""
    
    # CHECK 6: Disk monitor timer enabled
    print_color "$CYAN" "[6/$total] Checking lab-disk-monitor.timer status..."
    if systemctl is-enabled lab-disk-monitor.timer >/dev/null 2>&1 && \
       systemctl is-active lab-disk-monitor.timer >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Monitor timer enabled and active"
        ((score++))
    else
        print_color "$RED" "  ✗ Monitor timer not enabled or not active"
    fi
    echo ""
    
    # CHECK 7: Cleanup service exists
    print_color "$CYAN" "[7/$total] Checking lab-cleanup.service..."
    if [ -f /etc/systemd/system/lab-cleanup.service ]; then
        if grep -q "ExecStart=/opt/lab-timers/temp-cleanup.sh" /etc/systemd/system/lab-cleanup.service; then
            print_color "$GREEN" "  ✓ Cleanup service configured"
            ((score++))
        else
            print_color "$RED" "  ✗ Cleanup service misconfigured"
        fi
    else
        print_color "$RED" "  ✗ lab-cleanup.service not found"
    fi
    echo ""
    
    # CHECK 8: Cleanup timer schedule
    print_color "$CYAN" "[8/$total] Checking lab-cleanup.timer..."
    if [ -f /etc/systemd/system/lab-cleanup.timer ]; then
        local has_calendar=false
        local has_boot=false
        
        if grep -q "OnCalendar=Sun \*-\*-\* 03:00:00" /etc/systemd/system/lab-cleanup.timer; then
            has_calendar=true
        fi
        
        if grep -q "OnBootSec=15min" /etc/systemd/system/lab-cleanup.timer; then
            has_boot=true
        fi
        
        if [ "$has_calendar" = true ] && [ "$has_boot" = true ]; then
            print_color "$GREEN" "  ✓ Cleanup timer has both schedules (Sunday 3 AM + boot)"
            ((score++))
        else
            print_color "$RED" "  ✗ Cleanup timer missing schedule(s)"
            [ "$has_calendar" = false ] && print_color "$YELLOW" "  Missing: OnCalendar=Sun *-*-* 03:00:00"
            [ "$has_boot" = false ] && print_color "$YELLOW" "  Missing: OnBootSec=15min"
        fi
    else
        print_color "$RED" "  ✗ lab-cleanup.timer not found"
    fi
    echo ""
    
    # CHECK 9: Cleanup timer enabled
    print_color "$CYAN" "[9/$total] Checking lab-cleanup.timer status..."
    if systemctl is-enabled lab-cleanup.timer >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Cleanup timer enabled"
        ((score++))
    else
        print_color "$RED" "  ✗ Cleanup timer not enabled"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've mastered systemd timers:"
        echo "  • Creating timer/service pairs"
        echo "  • Using OnCalendar syntax for scheduling"
        echo "  • Multiple trigger types (calendar and boot)"
        echo "  • Testing schedules with systemd-analyze"
        echo "  • Managing timer lifecycle"
        echo ""
        echo "You're ready for RHCSA timer questions!"
    elif [ $score -ge 7 ]; then
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
    
    [ $score -ge 7 ]
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

1. Always create service BEFORE timer
2. Enable/start the TIMER, not the service
3. Use Type=oneshot for scripts that complete
4. Test OnCalendar with: systemd-analyze calendar "expression"
5. Verify timers with: systemctl list-timers
6. Check logs with: journalctl -u SERVICE

Common OnCalendar patterns for exam:
  Daily at 2 AM:      *-*-* 02:00:00
  Every 10 minutes:   *:00/10
  Mondays at 9 AM:    Mon *-*-* 09:00:00
  Weekly (Sunday):    Sun *-*-* 00:00:00

Remember:
  • Timer name must match service name
  • WantedBy=timers.target in timer [Install]
  • Persistent=true to catch missed runs
  • AccuracySec controls timing precision

Quick verification:
  systemctl list-timers --all
  systemctl status TIMER
  journalctl -u SERVICE

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Stop and disable timers
    systemctl stop lab-backup.timer 2>/dev/null || true
    systemctl disable lab-backup.timer 2>/dev/null || true
    systemctl stop lab-disk-monitor.timer 2>/dev/null || true
    systemctl disable lab-disk-monitor.timer 2>/dev/null || true
    systemctl stop lab-cleanup.timer 2>/dev/null || true
    systemctl disable lab-cleanup.timer 2>/dev/null || true
    
    # Remove unit files
    rm -f /etc/systemd/system/lab-backup.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-backup.timer 2>/dev/null || true
    rm -f /etc/systemd/system/lab-disk-monitor.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-disk-monitor.timer 2>/dev/null || true
    rm -f /etc/systemd/system/lab-cleanup.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-cleanup.timer 2>/dev/null || true
    
    # Remove scripts and logs
    rm -rf /opt/lab-timers 2>/dev/null || true
    rm -f /var/log/lab-backup.log 2>/dev/null || true
    rm -f /var/log/lab-disk-monitor.log 2>/dev/null || true
    rm -f /var/log/lab-cleanup.log 2>/dev/null || true
    rm -rf /var/backups/lab-logs 2>/dev/null || true
    
    systemctl daemon-reload
    
    echo "  ✓ All timers stopped and disabled"
    echo "  ✓ Unit files removed"
    echo "  ✓ Scripts and logs removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
