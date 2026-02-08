#!/bin/bash
# labs/m04/16B-cron-scheduling.sh
# Lab: Scheduling Tasks with Cron
# Difficulty: Intermediate
# RHCSA Objective: 16.3 - Scheduling tasks with cron

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Scheduling Tasks with Cron"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="40-50 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure crond is installed and running
    if ! rpm -q cronie >/dev/null 2>&1; then
        dnf install -y cronie >/dev/null 2>&1
    fi
    
    # Ensure crond is enabled and running
    systemctl enable --now crond >/dev/null 2>&1
    
    # Create lab directory for scripts
    mkdir -p /opt/lab-cron
    
    # Create a database backup script
    cat > /opt/lab-cron/db-backup.sh << 'SCRIPT'
#!/bin/bash
# Database backup script
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="/var/log/lab-cron-backup.log"
echo "[$TIMESTAMP] Database backup executed" >> "$LOG_FILE"
# Simulate backup
echo "[$TIMESTAMP] Backup completed successfully" >> "$LOG_FILE"
SCRIPT
    chmod +x /opt/lab-cron/db-backup.sh
    
    # Create a system health check script
    cat > /opt/lab-cron/health-check.sh << 'SCRIPT'
#!/bin/bash
# System health monitoring script
TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
LOG_FILE="/var/log/lab-health-check.log"
echo "[$TIMESTAMP] Health check started" >> "$LOG_FILE"
uptime >> "$LOG_FILE"
df -h / | tail -1 >> "$LOG_FILE"
echo "[$TIMESTAMP] Health check completed" >> "$LOG_FILE"
SCRIPT
    chmod +x /opt/lab-cron/health-check.sh
    
    # Create a report generation script
    cat > /opt/lab-cron/generate-report.sh << 'SCRIPT'
#!/bin/bash
# Weekly report generation
TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
LOG_FILE="/var/log/lab-weekly-report.log"
echo "[$TIMESTAMP] Generating weekly report" >> "$LOG_FILE"
echo "System uptime: $(uptime -p)" >> "$LOG_FILE"
echo "[$TIMESTAMP] Report generation completed" >> "$LOG_FILE"
SCRIPT
    chmod +x /opt/lab-cron/generate-report.sh
    
    # Create test users for cron access control
    useradd -m cronuser1 2>/dev/null || true
    useradd -m cronuser2 2>/dev/null || true
    useradd -m cronuser3 2>/dev/null || true
    
    # Set passwords for test users
    echo "cronuser1:password" | chpasswd 2>/dev/null
    echo "cronuser2:password" | chpasswd 2>/dev/null
    echo "cronuser3:password" | chpasswd 2>/dev/null
    
    # Clean up any previous lab cron jobs
    crontab -u cronuser1 -r 2>/dev/null || true
    crontab -u cronuser2 -r 2>/dev/null || true
    crontab -u cronuser3 -r 2>/dev/null || true
    crontab -u root -r 2>/dev/null || true
    
    # Clean up previous cron.allow/deny configurations
    rm -f /etc/cron.allow 2>/dev/null || true
    rm -f /etc/cron.deny 2>/dev/null || true
    
    # Clean up previous drop-in cron jobs
    rm -f /etc/cron.d/lab-* 2>/dev/null || true
    
    # Clean up log files
    rm -f /var/log/lab-cron-backup.log 2>/dev/null || true
    rm -f /var/log/lab-health-check.log 2>/dev/null || true
    rm -f /var/log/lab-weekly-report.log 2>/dev/null || true
    
    echo "  ✓ Cron service enabled and running"
    echo "  ✓ Lab scripts created in /opt/lab-cron"
    echo "  ✓ Test users created (cronuser1, cronuser2, cronuser3)"
    echo "  ✓ Previous lab attempts cleaned up"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of Linux scheduling concepts
  • Familiarity with cron time syntax
  • Basic shell scripting knowledge
  • Understanding of user permissions

Commands You'll Use:
  • crontab -e - Edit user's crontab
  • crontab -l - List user's crontab entries
  • crontab -r - Remove user's crontab
  • crontab -u USER - Operate on another user's crontab (root only)
  • systemctl status crond - Check cron daemon status

Files You'll Interact With:
  • /etc/crontab - System-wide crontab (view only, don't edit)
  • /etc/cron.d/ - Drop-in directory for system cron jobs
  • /etc/cron.allow - Users allowed to use cron
  • /etc/cron.deny - Users denied from using cron
  • /var/spool/cron/ - User crontab storage (managed by crontab command)
  • /var/log/cron - Cron execution log

Key Concepts:
  • Cron runs as the crond service
  • Each user can have their own crontab
  • System cron jobs go in /etc/cron.d/
  • Cron time format: minute hour day month weekday command
  • Scripts must be executable and use absolute paths

Reference Material:
  • man 5 crontab - Crontab file format
  • man 1 crontab - Crontab command
  • man 8 cron - Cron daemon
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator managing a RHEL server that needs scheduled
maintenance tasks. While the company is moving to systemd timers, some legacy
applications and scripts still use cron. You need to configure user cron jobs,
system-wide cron jobs, and manage cron access control.

BACKGROUND:
Cron is the traditional Unix/Linux job scheduler. While systemd timers are
preferred for new tasks in RHEL 10, cron is still widely used and fully
supported. Understanding cron is essential for managing legacy systems and
is tested on the RHCSA exam.

OBJECTIVES:
  1. Explore cron configuration and understand the time format
     • Check that crond service is running
     • View the system crontab (/etc/crontab) for examples
     • Understand cron time field format
     • View existing cron logs
     • Learn about cron directories
     
  2. Create user crontab entries for scheduled backups
     • Create crontab for root user
     • Schedule database backup: daily at 1:30 AM
       Command: /opt/lab-cron/db-backup.sh
     • Schedule health checks: every 6 hours
       Command: /opt/lab-cron/health-check.sh
     • Verify crontab entries are saved
     • Check cron logs for execution
     
  3. Create system-wide cron job in /etc/cron.d/
     • Create file: /etc/cron.d/lab-reports
     • Schedule weekly report: Every Sunday at 11:00 PM
       User: root
       Command: /opt/lab-cron/generate-report.sh
     • Include proper format with username field
     • Verify cron picks up the job
     
  4. Manage cron access control
     • Create /etc/cron.allow
     • Add only cronuser1 and cronuser2 to cron.allow
     • User cronuser3 should be denied (by omission)
     • Verify allowed users can create crontabs
     • Confirm that cronuser3 is denied access

HINTS:
  • Cron format: minute hour day month weekday command
  • Use * for "any" value
  • Use */N for "every N" intervals
  • User crontabs: crontab -e
  • System cron: /etc/cron.d/ with username field
  • View logs: tail /var/log/cron
  • If cron.allow exists, cron.deny is ignored
  • Root can always manage crontabs with -u, but access control affects
    whether users can run crontab commands themselves

SUCCESS CRITERIA:
  • Root user has crontab with two scheduled jobs
  • System cron job exists in /etc/cron.d/
  • Cron access control properly configured
  • Only cronuser1 and cronuser2 are in cron.allow
  • cronuser3 is NOT in cron.allow (denied by omission)
  • All scripts are executable
  • Cron logs show job execution attempts
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore cron configuration and time format
  ☐ 2. Create user crontab for root with two jobs
  ☐ 3. Create system cron job in /etc/cron.d/
  ☐ 4. Configure cron access control with cron.allow
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
You're configuring cron jobs for automated maintenance on a RHEL server.
You'll create user crontabs, system-wide cron jobs, and manage access control.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore cron configuration and understand the time format

Before creating cron jobs, understand how cron works and its time format.

Requirements:
  • Verify crond service is running
  • View /etc/crontab for format examples
  • Understand the five time fields
  • Check existing cron logs
  • Explore cron directories

Questions to explore:
  • Is the crond service running?
  • What is the format of cron time specifications?
  • Where are user crontabs stored?
  • Where are system cron jobs located?
  • How do you view cron execution logs?

Key commands to use:
  systemctl status crond
  cat /etc/crontab
  ls -la /etc/cron.d/
  ls -la /var/spool/cron/
  tail /var/log/cron

Cron time format:
  minute (0-59)
  hour (0-23)
  day of month (1-31)
  month (1-12)
  day of week (0-7, 0 and 7 are Sunday)
  command to execute
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  Check service: systemctl status crond"
    echo "  View examples: cat /etc/crontab"
    echo "  Check logs: tail /var/log/cron"
    echo "  Format: minute hour day month weekday command"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Check crond service status:
  systemctl status crond

Should show: active (running)

View system crontab for examples:
  cat /etc/crontab

Output shows format:
  # Example of job definition:
  # .---------------- minute (0 - 59)
  # |  .------------- hour (0 - 23)
  # |  |  .---------- day of month (1 - 31)
  # |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
  # |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
  # |  |  |  |  |
  # *  *  *  *  * user-name  command to be executed

View cron directories:
  ls -l /etc/cron.d/
  ls -l /etc/cron.daily/
  ls -l /etc/cron.hourly/
  ls -l /etc/cron.weekly/
  ls -l /etc/cron.monthly/

View user crontab storage:
  ls -l /var/spool/cron/

Check cron logs:
  tail -20 /var/log/cron

Understanding cron time format:

Field positions:
  1. Minute (0-59)
  2. Hour (0-23)
  3. Day of month (1-31)
  4. Month (1-12 or names: jan, feb, etc.)
  5. Day of week (0-7 or names: sun, mon, etc.)
     Note: 0 and 7 both represent Sunday

Special characters:
  *        Any value (matches all)
  */N      Every N units (e.g., */5 = every 5 minutes)
  X-Y      Range (e.g., 1-5 = Monday through Friday)
  X,Y,Z    List (e.g., 1,3,5 = Monday, Wednesday, Friday)

Common examples:

Daily at 1:30 AM:
  30 1 * * * command
  - Minute: 30
  - Hour: 1 (1 AM)
  - Day: * (every day)
  - Month: * (every month)
  - Weekday: * (every day of week)

Every 6 hours:
  0 */6 * * * command
  - Runs at: 00:00, 06:00, 12:00, 18:00

Every 15 minutes:
  */15 * * * * command
  - Runs at: :00, :15, :30, :45 of every hour

Weekdays at 9 AM:
  0 9 * * 1-5 command
  - Monday through Friday at 9:00 AM

Sunday at 11 PM:
  0 23 * * 0 command
  - Or: 0 23 * * sun command

First day of month at midnight:
  0 0 1 * * command

Every Monday and Wednesday at 2:30 PM:
  30 14 * * 1,3 command

Cron directories explained:

/etc/cron.d/:
  - Drop-in directory for system cron jobs
  - Files here are read by cron
  - Must include username field
  - Good for package-provided jobs

/etc/cron.hourly/:
  - Scripts run every hour
  - Managed by anacron
  - Scripts must be executable
  - No .sh extension needed

/etc/cron.daily/:
  - Scripts run once daily
  - Managed by anacron
  - Good for maintenance tasks

/etc/cron.weekly/:
  - Scripts run once weekly
  - Sunday by default

/etc/cron.monthly/:
  - Scripts run once monthly
  - First day of month

/var/spool/cron/:
  - User crontab storage
  - Don't edit directly!
  - Use crontab command instead

Cron log format:
  tail /var/log/cron

Shows:
  - When cron jobs start
  - Exit status
  - Any errors
  - User who ran the job

Example log entry:
  Feb  3 01:30:01 localhost CROND[12345]: (root) CMD (/opt/lab-cron/db-backup.sh)

Key differences: User crontab vs System crontab

User crontab (crontab -e):
  Format: minute hour day month weekday command
  Runs as: The user who owns the crontab
  Location: /var/spool/cron/username
  Edit with: crontab -e

System crontab (/etc/cron.d/):
  Format: minute hour day month weekday user command
  Runs as: Specified user
  Location: /etc/cron.d/filename
  Edit with: vi or text editor

EOF
}

hint_step_2() {
    echo "  Edit crontab: crontab -e"
    echo "  Daily 1:30 AM: 30 1 * * * /opt/lab-cron/db-backup.sh"
    echo "  Every 6 hours: 0 */6 * * * /opt/lab-cron/health-check.sh"
    echo "  List entries: crontab -l"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create user crontab entries for scheduled maintenance

Create cron jobs in the root user's crontab for backups and monitoring.

Requirements:
  • Edit root's crontab (as root user)
  • Add job 1: Database backup daily at 1:30 AM
    Command: /opt/lab-cron/db-backup.sh
  
  • Add job 2: Health check every 6 hours
    Command: /opt/lab-cron/health-check.sh
  
  • Save and verify the crontab
  • List the crontab to confirm entries
  • Check cron logs for activity

Cron time specifications:
  Daily at 1:30 AM:    30 1 * * *
  Every 6 hours:       0 */6 * * *

Important notes:
  • Use absolute paths for commands
  • Don't include username in user crontabs
  • Scripts must be executable
  • Cron runs jobs even if user not logged in

Commands you'll use:
  crontab -e          Edit current user's crontab
  crontab -l          List current user's crontab
  crontab -r          Remove current user's crontab
EOF
}

validate_step_2() {
    local failures=0
    
    # Check if root has a crontab
    if ! crontab -u root -l >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Root user has no crontab"
        echo "  Create with: crontab -e"
        ((failures++))
        return 1
    fi
    
    # Get root's crontab content
    local crontab_content=$(crontab -u root -l 2>/dev/null)
    
    # Check for daily backup job at 1:30 AM
    if echo "$crontab_content" | grep -q "30 1 \* \* \*.*db-backup.sh"; then
        # Found the job
        :
    else
        echo ""
        print_color "$RED" "✗ Daily backup job not found or incorrect"
        echo "  Expected: 30 1 * * * /opt/lab-cron/db-backup.sh"
        ((failures++))
    fi
    
    # Check for health check every 6 hours
    if echo "$crontab_content" | grep -qE "0 \*/6 \* \* \*.*health-check.sh"; then
        # Found the job
        :
    else
        echo ""
        print_color "$RED" "✗ Health check job not found or incorrect"
        echo "  Expected: 0 */6 * * * /opt/lab-cron/health-check.sh"
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
Step 1: Edit root's crontab
────────────────────────────
crontab -e

This opens the default editor (usually vi).

Step 2: Add the cron entries
─────────────────────────────
Add these lines:

# Database backup - daily at 1:30 AM
30 1 * * * /opt/lab-cron/db-backup.sh

# System health check - every 6 hours
0 */6 * * * /opt/lab-cron/health-check.sh

Step 3: Save and exit
─────────────────────
In vi: Press ESC, then :wq

Step 4: Verify the crontab
──────────────────────────
crontab -l

Should show your two entries.

Step 5: Check cron logs
───────────────────────
tail -f /var/log/cron

Wait and watch for cron execution messages.

Understanding the entries:

Entry 1: Daily backup at 1:30 AM
  30 1 * * * /opt/lab-cron/db-backup.sh
  
  30    - Minute: 30
  1     - Hour: 1 (1:00 AM)
  *     - Day: every day
  *     - Month: every month
  *     - Weekday: every day of week
  
  Runs: 01:30:00 every day

Entry 2: Health check every 6 hours
  0 */6 * * * /opt/lab-cron/health-check.sh
  
  0     - Minute: 0 (on the hour)
  */6   - Hour: every 6 hours (0, 6, 12, 18)
  *     - Day: every day
  *     - Month: every month
  *     - Weekday: every day of week
  
  Runs: 00:00, 06:00, 12:00, 18:00 daily

Important crontab commands:

Edit crontab:
  crontab -e
  Opens editor for current user

List crontab:
  crontab -l
  Shows current user's cron jobs

Remove crontab:
  crontab -r
  Deletes all cron jobs for current user

Edit another user's crontab (root only):
  crontab -u username -e
  crontab -u username -l
  crontab -u username -r

Common mistakes to avoid:

Mistake 1: Forgetting absolute paths
  Wrong: 30 1 * * * db-backup.sh
  Right: 30 1 * * * /opt/lab-cron/db-backup.sh
  
  Cron doesn't use your PATH variable

Mistake 2: Script not executable
  chmod +x /opt/lab-cron/db-backup.sh
  Scripts must have execute permission

Mistake 3: Including username in user crontab
  Wrong: 30 1 * * * root /opt/lab-cron/db-backup.sh
  Right: 30 1 * * * /opt/lab-cron/db-backup.sh
  
  Username is NOT used in user crontabs

Mistake 4: Wrong time format
  Wrong: 1:30 * * * /opt/lab-cron/db-backup.sh
  Right: 30 1 * * * /opt/lab-cron/db-backup.sh
  
  Format is minute-hour, not hour:minute

Testing cron jobs:

Method 1: Wait for scheduled time
  crontab -l
  # Note the schedule
  tail -f /var/log/cron
  # Watch for execution

Method 2: Test script manually first
  /opt/lab-cron/db-backup.sh
  # Verify script works

Method 3: Temporary test schedule
  # Change to run in 2 minutes
  */2 * * * * /opt/lab-cron/db-backup.sh
  # Watch /var/log/cron
  # Change back to real schedule

Checking if jobs executed:
  tail /var/log/cron
  tail /var/log/lab-cron-backup.log
  tail /var/log/lab-health-check.log

Cron environment:

Limited environment:
  - Minimal PATH
  - No interactive shell
  - No terminal
  - Limited variables

Good practices:
  - Use absolute paths
  - Set PATH in script if needed
  - Redirect output: >> /var/log/script.log 2>&1
  - Test scripts independently first

EOF
}

hint_step_3() {
    echo "  Create: /etc/cron.d/lab-reports"
    echo "  Format: minute hour day month weekday USER command"
    echo "  Sunday 11 PM: 0 23 * * 0 root /opt/lab-cron/generate-report.sh"
    echo "  Must include username (root) in system cron"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create system-wide cron job in /etc/cron.d/

Create a system cron job for weekly report generation.

Requirements:
  • Create file: /etc/cron.d/lab-reports
  • Schedule: Every Sunday at 11:00 PM (23:00)
  • User: root
  • Command: /opt/lab-cron/generate-report.sh
  • Use proper system cron format with username
  • Add comment describing the job

System cron format (different from user crontab):
  minute hour day month weekday USERNAME command

Key differences:
  • System cron files include USERNAME field
  • Located in /etc/cron.d/
  • Can specify different users for different jobs
  • Don't use crontab command to edit

Schedule for Sunday at 11 PM:
  0 23 * * 0 root /opt/lab-cron/generate-report.sh

Alternative for Sunday:
  0 23 * * sun root /opt/lab-cron/generate-report.sh
EOF
}

validate_step_3() {
    local failures=0
    
    # Check if file exists
    if [ ! -f /etc/cron.d/lab-reports ]; then
        echo ""
        print_color "$RED" "✗ /etc/cron.d/lab-reports not found"
        ((failures++))
        return 1
    fi
    
    # Check for correct entry (Sunday at 11 PM with root user)
    # Accept both "0" and "sun" for Sunday
    if grep -qE "0 23 \* \* (0|sun) root.*generate-report.sh" /etc/cron.d/lab-reports; then
        # Found valid entry
        :
    else
        echo ""
        print_color "$RED" "✗ Cron job not found or incorrect in /etc/cron.d/lab-reports"
        echo "  Expected: 0 23 * * 0 root /opt/lab-cron/generate-report.sh"
        echo "  Your file contains:"
        cat /etc/cron.d/lab-reports
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
Step 1: Create the system cron file
────────────────────────────────────
sudo vi /etc/cron.d/lab-reports

Step 2: Add the cron entry
───────────────────────────
Add this content:

# Weekly report generation - Sundays at 11 PM
0 23 * * 0 root /opt/lab-cron/generate-report.sh

Step 3: Save the file
─────────────────────
ESC, then :wq

Step 4: Verify permissions
───────────────────────────
ls -l /etc/cron.d/lab-reports

Should be: -rw-r--r-- (644 permissions are fine)

Step 5: Check cron picks it up
───────────────────────────────
No daemon reload needed - cron reads /etc/cron.d/ automatically

Check logs:
  tail -f /var/log/cron

Understanding system cron format:

Complete format:
  minute hour day month weekday USERNAME command

Example breakdown:
  0 23 * * 0 root /opt/lab-cron/generate-report.sh
  
  0       - Minute: 0 (on the hour)
  23      - Hour: 23 (11 PM)
  *       - Day: every day
  *       - Month: every month
  0       - Weekday: Sunday (0 = Sunday, can also use "sun")
  root    - Run as root user
  command - Script to execute

Key differences: User vs System cron

User crontab (crontab -e):
  ┌──────────────────────────────────────────┐
  │ 30 1 * * * /opt/lab-cron/db-backup.sh   │
  │ └┬┘ └──────────────┬─────────────────┘  │
  │  │                  └─ Command           │
  │  └─ Time (5 fields)                      │
  │                                           │
  │ NO USERNAME FIELD                        │
  │ Runs as crontab owner                    │
  └──────────────────────────────────────────┘

System cron (/etc/cron.d/):
  ┌──────────────────────────────────────────────────┐
  │ 0 23 * * 0 root /opt/lab-cron/generate-report.sh │
  │ └┬┘         └┬┘  └──────────┬──────────────────┘│
  │  │           │               └─ Command          │
  │  │           └─ Username (REQUIRED)              │
  │  └─ Time (5 fields)                              │
  │                                                   │
  │ MUST INCLUDE USERNAME                            │
  │ Can run as any user                              │
  └──────────────────────────────────────────────────┘

Day of week values:

Numeric:
  0 or 7  = Sunday
  1       = Monday
  2       = Tuesday
  3       = Wednesday
  4       = Thursday
  5       = Friday
  6       = Saturday

Name-based:
  sun, mon, tue, wed, thu, fri, sat

Both are valid:
  0 23 * * 0 root command          # Numeric Sunday
  0 23 * * sun root command        # Name Sunday

Why use /etc/cron.d/:

Advantages:
  1. Package management friendly
     - RPM packages can drop in cron jobs
     - Won't conflict with user crontabs
  
  2. Multiple users
     - Different jobs can run as different users
     - All in one file or separate files
  
  3. Organized
     - Separate file per application
     - Easy to enable/disable (rename file)
  
  4. Version control
     - Files can be tracked in git
     - Easy to backup/restore

When to use each:

Use user crontab (crontab -e):
  - Personal jobs for a specific user
  - Simple single-user tasks
  - Quick temporary jobs

Use system cron (/etc/cron.d/):
  - Application or service jobs
  - Jobs that need specific users
  - Jobs managed by packages
  - Production deployments

Example system cron file:

/etc/cron.d/application-jobs:
  # Backup job - runs as appuser
  0 2 * * * appuser /opt/app/backup.sh
  
  # Cleanup job - runs as root
  0 3 * * * root /opt/app/cleanup.sh
  
  # Report job - runs as reports user
  0 23 * * 0 reports /opt/app/weekly-report.sh

File naming conventions:

Good names:
  - lab-reports
  - myapp-backup
  - database-maintenance

Avoid:
  - Names with spaces
  - Names with special characters
  - .sh extension (not needed)

Permissions:

/etc/cron.d/ files should be:
  - Owned by root:root
  - Permission 644 (-rw-r--r--)
  - Not executable (don't need +x)

Check:
  ls -l /etc/cron.d/lab-reports

Troubleshooting:

If job doesn't run:

1. Check file exists:
   ls -l /etc/cron.d/lab-reports

2. Check format:
   cat /etc/cron.d/lab-reports
   # Must have username field

3. Check script:
   ls -l /opt/lab-cron/generate-report.sh
   # Must be executable

4. Check logs:
   tail /var/log/cron
   # Look for errors

5. Test script manually:
   /opt/lab-cron/generate-report.sh

EOF
}

hint_step_4() {
    echo "  Create: /etc/cron.allow"
    echo "  Add: cronuser1 and cronuser2 (one per line)"
    echo "  Do NOT add cronuser3 (denied by omission)"
    echo "  Note: Root can always use 'crontab -u USER' regardless"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Configure cron access control with cron.allow

Control which users can create cron jobs using cron.allow.

Requirements:
  • Create file: /etc/cron.allow
  • Add users: cronuser1 and cronuser2 (one per line)
  • Do NOT add cronuser3 (denied by omission)
  • Verify the file is created correctly

Access control rules:
  • If cron.allow exists, only users in it can use cron
  • If cron.allow exists, cron.deny is ignored
  • Root can always use cron (and manage others' crontabs)

Important understanding:
  Root can ALWAYS run "crontab -u USERNAME" commands regardless of
  cron.allow/cron.deny. The access control only affects whether the
  user themselves can run crontab commands.
  
  What we're testing: Whether cronuser1 and cronuser2 are allowed
  while cronuser3 is denied (by not being in the file).

The test users (cronuser1, cronuser2, cronuser3) were created
during lab setup.
EOF
}

validate_step_4() {
    local failures=0
    
    # Check if cron.allow exists
    if [ ! -f /etc/cron.allow ]; then
        echo ""
        print_color "$RED" "✗ /etc/cron.allow not found"
        echo "  Create this file to control cron access"
        ((failures++))
        return 1
    fi
    
    # Check if cronuser1 is in cron.allow
    if ! grep -q "^cronuser1$" /etc/cron.allow; then
        echo ""
        print_color "$RED" "✗ cronuser1 not found in /etc/cron.allow"
        ((failures++))
    fi
    
    # Check if cronuser2 is in cron.allow
    if ! grep -q "^cronuser2$" /etc/cron.allow; then
        echo ""
        print_color "$RED" "✗ cronuser2 not found in /etc/cron.allow"
        ((failures++))
    fi
    
    # Check that cronuser3 is NOT in cron.allow (should be denied by omission)
    if grep -q "^cronuser3$" /etc/cron.allow; then
        echo ""
        print_color "$RED" "✗ cronuser3 should NOT be in /etc/cron.allow"
        echo "  cronuser3 should be denied by omission (not in the file)"
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
Step 1: Create cron.allow file
───────────────────────────────
sudo vi /etc/cron.allow

Step 2: Add allowed users
──────────────────────────
Add these lines (one username per line):

cronuser1
cronuser2

Do NOT add cronuser3 - it should be denied by omission.

Step 3: Save the file
─────────────────────
ESC, then :wq

Step 4: Verify the file
───────────────────────
cat /etc/cron.allow

Should show:
  cronuser1
  cronuser2

Check permissions:
  ls -l /etc/cron.allow

Should be: -rw-r--r-- (644) owned by root

Understanding how this works:

When cron.allow exists:
  • ONLY users listed in /etc/cron.allow can use cron
  • All other users are denied (by omission)
  • /etc/cron.deny is completely ignored
  • Root can always use cron

In this configuration:
  ✓ cronuser1 - Listed in cron.allow (ALLOWED)
  ✓ cronuser2 - Listed in cron.allow (ALLOWED)
  ✗ cronuser3 - NOT in cron.allow (DENIED by omission)
  ✓ root      - Always allowed (special exception)

Important distinction - Root's special privilege:

Root can always run these commands:
  crontab -u cronuser1 -e    ✓ Works (root can manage any crontab)
  crontab -u cronuser2 -e    ✓ Works (root can manage any crontab)
  crontab -u cronuser3 -e    ✓ Works (root can manage any crontab)

But if cronuser3 tries directly:
  su - cronuser3
  crontab -e                 ✗ Denied by cron.allow

This is correct behavior - root has administrative privilege
to manage crontabs, but cronuser3 cannot use cron themselves.

Understanding cron access control:

Access control files:
  /etc/cron.allow   - Whitelist of allowed users
  /etc/cron.deny    - Blacklist of denied users

Logic flow:
  ┌─────────────────────────────────────┐
  │ Does /etc/cron.allow exist?         │
  └──────────┬─────────────┬────────────┘
             Yes           No
             │             │
             ▼             ▼
  ┌──────────────────┐  ┌──────────────────┐
  │ Is user in       │  │ Does cron.deny   │
  │ cron.allow?      │  │ exist?           │
  └──┬──────────┬────┘  └──┬──────────┬────┘
    Yes        No          Yes        No
     │          │           │          │
     ▼          ▼           ▼          ▼
  Allow      Deny    ┌─────────┐   Allow
                     │ Is user │   all
                     │ in deny?│
                     └──┬───┬──┘
                       Yes No
                        │   │
                        ▼   ▼
                      Deny Allow

Rule priority:
  1. If cron.allow exists:
     - ONLY users in cron.allow can use cron
     - cron.deny is completely ignored
     - Empty cron.allow = nobody can use cron (except root)
  
  2. If cron.allow doesn't exist but cron.deny exists:
     - Users in cron.deny cannot use cron
     - All other users can use cron
     - Empty cron.deny = everyone can use cron
  
  3. If neither file exists:
     - All users can use cron

Root exception:
  - Root can ALWAYS use cron
  - Root can ALWAYS manage other users' crontabs
  - Even if not in cron.allow
  - Cannot be blocked by cron.deny

Example scenarios:

Scenario 1: Whitelist approach (what we're using)
  Create /etc/cron.allow with:
    user1
    user2
    appuser
  
  Result:
    - Only user1, user2, appuser can use cron
    - All other users denied by omission
    - Root can still manage all crontabs

Scenario 2: Blacklist approach
  Create /etc/cron.deny with:
    baduser
    testuser
  
  Remove /etc/cron.allow if it exists
  
  Result:
    - baduser and testuser cannot use cron
    - All other users can use cron

Scenario 3: Deny everyone except root
  Create empty /etc/cron.allow
  (No usernames in file)
  
  Result:
    - Only root can use cron
    - All regular users denied

Best practices:

Security approach:
  - Use cron.allow (whitelist) for better control
  - Only list users who need scheduled jobs
  - Review allowed users periodically
  - Don't mix cron.allow and cron.deny (cron.allow wins)

File format:
  - One username per line
  - No comments allowed
  - No extra whitespace
  - Just the username

Example /etc/cron.allow:
  appuser
  backup
  monitoring
  admin

Common mistakes:

Mistake 1: Putting comments in file
  Wrong:
    # Application user
    appuser
  
  Right:
    appuser

Mistake 2: Wrong permissions
  File should be:
    -rw-r--r-- (644)
    Owned by root:root

Mistake 3: Expecting cron.deny to work when cron.allow exists
  If /etc/cron.allow exists:
    - cron.deny is COMPLETELY IGNORED
    - Remove cron.allow to use cron.deny

Mistake 4: Adding root to cron.allow
  Not necessary - root always has cron access
  Doesn't hurt, but it's redundant

Why validation checks file content only:

The validation checks:
  1. /etc/cron.allow exists
  2. cronuser1 is in the file
  3. cronuser2 is in the file
  4. cronuser3 is NOT in the file

This is correct because:
  - The file determines who is allowed
  - Having cronuser1 and cronuser2 in the file means they're allowed
  - NOT having cronuser3 in the file means they're denied
  - Root can always manage crontabs (separate privilege)

Troubleshooting:

If allowed user can't access cron:

1. Check file exists:
   ls -l /etc/cron.allow

2. Check username is in file:
   grep username /etc/cron.allow

3. Check spelling:
   # Must match exactly
   getent passwd username

4. Check file permissions:
   ls -l /etc/cron.allow
   # Should be readable

5. Check for extra whitespace:
   cat -A /etc/cron.allow
   # Should show clean lines

If denied user can access cron:

1. Check cron.allow doesn't include them:
   grep username /etc/cron.allow

2. Check if cron.allow exists:
   ls -l /etc/cron.allow

3. If using cron.deny:
   # Remove cron.allow if it exists
   # Only then will cron.deny work

Viewing access control status:

Check which method in use:
  ls -l /etc/cron.allow /etc/cron.deny

Results interpretation:
  Only cron.allow exists → Whitelist mode (most secure)
  Only cron.deny exists  → Blacklist mode
  Neither exists         → All users allowed
  Both exist             → Only cron.allow matters (deny ignored)

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=7
    
    echo "Checking your cron configuration..."
    echo ""
    
    # CHECK 1: crond service is running
    print_color "$CYAN" "[1/$total] Checking crond service..."
    if systemctl is-active crond >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ crond service is running"
        ((score++))
    else
        print_color "$RED" "  ✗ crond service is not running"
        print_color "$YELLOW" "  Fix: systemctl start crond"
    fi
    echo ""
    
    # CHECK 2: Root has crontab with backup job
    print_color "$CYAN" "[2/$total] Checking root crontab - backup job..."
    if crontab -u root -l 2>/dev/null | grep -q "30 1 \* \* \*.*db-backup.sh"; then
        print_color "$GREEN" "  ✓ Daily backup job configured (1:30 AM)"
        ((score++))
    else
        print_color "$RED" "  ✗ Backup job not found or incorrect"
        print_color "$YELLOW" "  Expected: 30 1 * * * /opt/lab-cron/db-backup.sh"
    fi
    echo ""
    
    # CHECK 3: Root has crontab with health check job
    print_color "$CYAN" "[3/$total] Checking root crontab - health check job..."
    if crontab -u root -l 2>/dev/null | grep -qE "0 \*/6 \* \* \*.*health-check.sh"; then
        print_color "$GREEN" "  ✓ Health check job configured (every 6 hours)"
        ((score++))
    else
        print_color "$RED" "  ✗ Health check job not found or incorrect"
        print_color "$YELLOW" "  Expected: 0 */6 * * * /opt/lab-cron/health-check.sh"
    fi
    echo ""
    
    # CHECK 4: System cron job exists
    print_color "$CYAN" "[4/$total] Checking system cron job..."
    if [ -f /etc/cron.d/lab-reports ]; then
        if grep -qE "0 23 \* \* (0|sun) root.*generate-report.sh" /etc/cron.d/lab-reports; then
            print_color "$GREEN" "  ✓ System cron job configured (Sunday 11 PM)"
            ((score++))
        else
            print_color "$RED" "  ✗ System cron job exists but incorrect format"
            print_color "$YELLOW" "  Expected: 0 23 * * 0 root /opt/lab-cron/generate-report.sh"
        fi
    else
        print_color "$RED" "  ✗ /etc/cron.d/lab-reports not found"
    fi
    echo ""
    
    # CHECK 5: cron.allow exists with correct users
    print_color "$CYAN" "[5/$total] Checking cron.allow file..."
    if [ -f /etc/cron.allow ]; then
        print_color "$GREEN" "  ✓ /etc/cron.allow exists"
        ((score++))
    else
        print_color "$RED" "  ✗ /etc/cron.allow not found"
    fi
    echo ""
    
    # CHECK 6: cron.allow contains correct users
    print_color "$CYAN" "[6/$total] Checking cron.allow contents..."
    if [ -f /etc/cron.allow ]; then
        local allow_ok=true
        if ! grep -q "^cronuser1$" /etc/cron.allow; then
            print_color "$RED" "  ✗ cronuser1 not in /etc/cron.allow"
            allow_ok=false
        fi
        if ! grep -q "^cronuser2$" /etc/cron.allow; then
            print_color "$RED" "  ✗ cronuser2 not in /etc/cron.allow"
            allow_ok=false
        fi
        if grep -q "^cronuser3$" /etc/cron.allow; then
            print_color "$RED" "  ✗ cronuser3 should NOT be in /etc/cron.allow"
            allow_ok=false
        fi
        
        if [ "$allow_ok" = true ]; then
            print_color "$GREEN" "  ✓ cron.allow properly configured (cronuser1, cronuser2 only)"
            ((score++))
        fi
    else
        print_color "$RED" "  ✗ Cannot check contents - /etc/cron.allow not found"
    fi
    echo ""
    
    # CHECK 7: Verify access control is working as expected
    print_color "$CYAN" "[7/$total] Verifying access control behavior..."
    if [ -f /etc/cron.allow ]; then
        # Just verify the file contains what we expect
        # Root can always manage crontabs with -u, so we check file content only
        if grep -q "^cronuser1$" /etc/cron.allow && \
           grep -q "^cronuser2$" /etc/cron.allow && \
           ! grep -q "^cronuser3$" /etc/cron.allow; then
            print_color "$GREEN" "  ✓ Access control configured correctly"
            echo "    (cronuser1 and cronuser2 allowed, cronuser3 denied by omission)"
            ((score++))
        else
            print_color "$RED" "  ✗ Access control not configured correctly"
        fi
    else
        print_color "$RED" "  ✗ Cannot verify - /etc/cron.allow not found"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've mastered cron scheduling:"
        echo "  • Creating user crontab entries"
        echo "  • Understanding cron time format"
        echo "  • Creating system-wide cron jobs"
        echo "  • Managing cron access control"
        echo "  • Using cron.allow for security"
        echo ""
        echo "You're ready for RHCSA cron questions!"
    elif [ $score -ge 5 ]; then
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
    
    [ $score -ge 5 ]
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

1. Cron time format: minute hour day month weekday
2. User crontab: crontab -e (no username in entry)
3. System cron: /etc/cron.d/ (must include username)
4. Use absolute paths for all commands
5. cron.allow takes precedence over cron.deny
6. Check logs: tail /var/log/cron

Common time patterns:
  Daily 1:30 AM:    30 1 * * *
  Every 6 hours:    0 */6 * * *
  Sunday 11 PM:     0 23 * * 0
  Weekdays 9 AM:    0 9 * * 1-5
  Every 15 min:     */15 * * * *

Quick reference:
  Edit:      crontab -e
  List:      crontab -l
  Remove:    crontab -r
  For user:  crontab -u USER -e
  System:    vi /etc/cron.d/filename

Access control:
  Allow users:  /etc/cron.allow (whitelist)
  Deny users:   /etc/cron.deny (blacklist)
  If cron.allow exists, cron.deny is ignored
  Root can always manage crontabs

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove user crontabs
    crontab -u root -r 2>/dev/null || true
    crontab -u cronuser1 -r 2>/dev/null || true
    crontab -u cronuser2 -r 2>/dev/null || true
    crontab -u cronuser3 -r 2>/dev/null || true
    
    # Remove system cron jobs
    rm -f /etc/cron.d/lab-reports 2>/dev/null || true
    
    # Remove access control files
    rm -f /etc/cron.allow 2>/dev/null || true
    rm -f /etc/cron.deny 2>/dev/null || true
    
    # Remove test users
    userdel -r cronuser1 2>/dev/null || true
    userdel -r cronuser2 2>/dev/null || true
    userdel -r cronuser3 2>/dev/null || true
    
    # Remove scripts and logs
    rm -rf /opt/lab-cron 2>/dev/null || true
    rm -f /var/log/lab-cron-backup.log 2>/dev/null || true
    rm -f /var/log/lab-health-check.log 2>/dev/null || true
    rm -f /var/log/lab-weekly-report.log 2>/dev/null || true
    
    echo "  ✓ All crontabs removed"
    echo "  ✓ System cron jobs removed"
    echo "  ✓ Access control files removed"
    echo "  ✓ Test users removed"
    echo "  ✓ Scripts and logs removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
