#!/bin/bash
# labs/m04/17C-logrotate-configuration.sh
# Lab: Managing Log Rotation with logrotate
# Difficulty: Intermediate
# RHCSA Objective: 17.5 - Configuring log rotation

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing Log Rotation with logrotate"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure logrotate is installed
    if ! rpm -q logrotate >/dev/null 2>&1; then
        dnf install -y logrotate >/dev/null 2>&1
    fi
    
    # Create test application and log directory
    mkdir -p /var/log/lab-app
    
    # Create test log files with some content
    for i in {1..100}; do
        echo "$(date) - Application log entry $i" >> /var/log/lab-app/application.log
    done
    
    for i in {1..50}; do
        echo "$(date) - Access log entry $i" >> /var/log/lab-app/access.log
    done
    
    for i in {1..30}; do
        echo "$(date) - Error log entry $i" >> /var/log/lab-app/error.log
    done
    
    # Clean up any previous lab logrotate configs
    rm -f /etc/logrotate.d/lab-* 2>/dev/null || true
    
    # Remove any rotated logs from previous runs
    rm -f /var/log/lab-app/*.log.[0-9]* 2>/dev/null || true
    rm -f /var/log/lab-app/*.log-* 2>/dev/null || true
    rm -f /var/log/lab-app/*.gz 2>/dev/null || true
    rm -f /var/log/lab-app/last-rotated 2>/dev/null || true
    
    echo "  ✓ logrotate package installed"
    echo "  ✓ Test application logs created"
    echo "  ✓ Previous lab configurations removed"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of log files and their growth
  • Basic file permissions and ownership
  • Familiarity with systemd timers

Commands You'll Use:
  • logrotate - Rotate log files
  • ls, cat, tail - View files and logs
  • systemctl - Check logrotate timer

Files You'll Interact With:
  • /etc/logrotate.conf - Main logrotate configuration
  • /etc/logrotate.d/ - Drop-in configuration directory
  • /var/lib/logrotate/logrotate.status - Rotation status file

Key Concepts:
  • Log rotation prevents disk space exhaustion
  • Old logs are renamed and compressed
  • Rotation can be based on size or time
  • logrotate runs via systemd timer (daily by default)

Reference Material:
  • man logrotate
  • man logrotate.conf
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're managing a RHEL 10 server that runs a custom application generating
significant log data. Without log rotation, these logs will fill the disk.
You need to configure logrotate to manage these logs automatically.

OBJECTIVES:
  1. Explore logrotate configuration structure
     • View main config and drop-in directory
     • Check how logrotate is scheduled
     • Understand rotation status tracking
     
  2. Create basic log rotation configuration
     • Configure rotation for /var/log/lab-app/*.log
     • Rotate weekly, keep 4 rotations
     • Compress rotated logs
     • Handle missing files gracefully
     • Create new logs with permissions 0640
     
  3. Add advanced features
     • Configure size-based rotation (minsize 1M)
     • Add postrotate script to touch /var/log/lab-app/last-rotated
     • Use sharedscripts for efficiency
     
  4. Test and verify
     • Force rotation manually
     • Verify files are rotated and compressed
     • Confirm new logs created correctly
     • Check postrotate script executed

HINTS:
  • Main config: /etc/logrotate.conf
  • Drop-in configs: /etc/logrotate.d/
  • Test without changes: logrotate -d <config>
  • Force rotation: logrotate -f <config>
  • Status file: /var/lib/logrotate/logrotate.status

SUCCESS CRITERIA:
  • Configuration file created in /etc/logrotate.d/
  • Logs rotate when forced
  • Old logs are compressed
  • New log files created with correct permissions
  • Postrotate script executes successfully
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore logrotate configuration and scheduling
  ☐ 2. Create basic log rotation configuration
  ☐ 3. Add advanced features (size-based, postrotate)
  ☐ 4. Test and verify rotation behavior
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
You're configuring logrotate to manage application logs, preventing
disk space exhaustion while maintaining log history for troubleshooting.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore logrotate configuration and scheduling

Familiarize yourself with logrotate's structure and how it runs.

Requirements:
  • Examine /etc/logrotate.conf
  • Browse configurations in /etc/logrotate.d/
  • Check logrotate.timer status
  • View rotation status file

Questions to answer:
  • What are the default global settings?
  • How often does logrotate run?
  • Where is rotation status tracked?

Commands to explore:
  cat /etc/logrotate.conf
  ls /etc/logrotate.d/
  cat /etc/logrotate.d/syslog
  systemctl status logrotate.timer
  cat /var/lib/logrotate/logrotate.status
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  View config: cat /etc/logrotate.conf"
    echo "  Check timer: systemctl status logrotate.timer"
    echo "  Status file: cat /var/lib/logrotate/logrotate.status"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────

1. View main configuration
───────────────────────────
  cat /etc/logrotate.conf

Key global directives:
  weekly          - Rotate logs weekly
  rotate 4        - Keep 4 rotations
  create          - Create new log after rotation
  dateext         - Use date as suffix (file-20260208)
  include /etc/logrotate.d  - Include drop-in configs

2. Explore drop-in configs
──────────────────────────
  ls -l /etc/logrotate.d/
  cat /etc/logrotate.d/syslog

Basic config structure:
  /var/log/messages
  /var/log/secure
  {
      missingok
      sharedscripts
      postrotate
          /usr/bin/systemctl reload rsyslog >/dev/null 2>&1 || true
      endscript
  }

3. Check scheduling
───────────────────
  systemctl status logrotate.timer
  systemctl list-timers logrotate.timer

Shows when logrotate runs (usually daily at 00:00).

4. View rotation status
───────────────────────
  cat /var/lib/logrotate/logrotate.status

Tracks which logs were rotated and when.

Essential directives:
  daily/weekly/monthly     - Rotation frequency
  rotate N                 - Keep N rotations
  size/minsize SIZE        - Size-based rotation
  compress/delaycompress   - Compression settings
  create MODE USER GROUP   - New file permissions
  missingok                - Don't error if missing
  notifempty               - Don't rotate empty logs
  postrotate...endscript   - Script after rotation
  sharedscripts            - Run postrotate once for all files

Testing commands:
  logrotate -d <config>    - Dry-run (shows what would happen)
  logrotate -f <config>    - Force rotation
  logrotate -v <config>    - Verbose output

EOF
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create basic log rotation configuration

Configure logrotate to manage the application logs in /var/log/lab-app/.

Requirements:
  • Create /etc/logrotate.d/lab-app
  • Manage /var/log/lab-app/*.log
  • Rotate weekly
  • Keep 4 rotations
  • Compress rotated logs
  • Use delaycompress
  • Don't error if logs are missing (missingok)
  • Don't rotate empty logs (notifempty)
  • Create new logs with permissions 0640, owner root, group root

Configuration format:
  /path/to/logfile {
      directive1
      directive2
  }

After creating, test with:
  logrotate -d /etc/logrotate.d/lab-app  # Dry-run
  logrotate -f /etc/logrotate.d/lab-app  # Force rotation
EOF
}

validate_step_2() {
    local failures=0
    
    if [ ! -f /etc/logrotate.d/lab-app ]; then
        echo ""
        print_color "$RED" "✗ /etc/logrotate.d/lab-app not found"
        echo "  Create logrotate configuration for lab-app logs"
        ((failures++))
        return 1
    fi
    
    if ! grep -q "/var/log/lab-app" /etc/logrotate.d/lab-app; then
        echo ""
        print_color "$RED" "✗ Configuration doesn't reference /var/log/lab-app"
        ((failures++))
    fi
    
    if logrotate -d /etc/logrotate.d/lab-app >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Configuration syntax valid"
    else
        echo ""
        print_color "$RED" "✗ Configuration has syntax errors"
        echo "  Run: logrotate -d /etc/logrotate.d/lab-app"
        ((failures++))
        return 1
    fi
    
    logrotate -f /etc/logrotate.d/lab-app >/dev/null 2>&1
    sleep 1
    
    if ls /var/log/lab-app/*.log-* >/dev/null 2>&1 || \
       ls /var/log/lab-app/*.log.[0-9] >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Log rotation working (rotated files found)"
    else
        echo ""
        print_color "$RED" "✗ No rotated log files found"
        ((failures++))
    fi
    
    [ $failures -eq 0 ]
}

hint_step_2() {
    echo "  Create: /etc/logrotate.d/lab-app"
    echo "  Format: /path/to/log { directives }"
    echo "  Test: logrotate -d /etc/logrotate.d/lab-app"
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────

1. Create configuration file
─────────────────────────────
  sudo vi /etc/logrotate.d/lab-app

Content:
  /var/log/lab-app/*.log {
      weekly
      rotate 4
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root root
  }

Save and exit.

Explanation:
  weekly          - Rotate once per week
  rotate 4        - Keep 4 old rotations before deleting
  compress        - Compress old logs with gzip
  delaycompress   - Don't compress the most recent rotation yet
  missingok       - Don't error if log file doesn't exist
  notifempty      - Don't rotate if log file is empty
  create 0640 root root - New file perms and ownership

2. Test configuration
─────────────────────
  sudo logrotate -d /etc/logrotate.d/lab-app

Should show "rotating pattern" and no errors.

3. Force test rotation
──────────────────────
  sudo logrotate -vf /etc/logrotate.d/lab-app

4. Verify rotation
──────────────────
  ls -lh /var/log/lab-app/

Should see:
  application.log              (new empty file)
  application.log-20260211     (rotated, not compressed yet due to delaycompress)
  access.log
  access.log-20260211
  error.log
  error.log-20260211

5. Check file permissions
─────────────────────────
  ls -l /var/log/lab-app/application.log

Should show: -rw-r----- (0640 permissions)

EOF
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Add advanced features

Enhance your configuration with size-based rotation and postrotate scripts.

Requirements:
  • Add size-based rotation
    - Use: minsize 1M (rotate if weekly AND >1M)
  
  • Add postrotate script
    - Touch /var/log/lab-app/last-rotated after rotation
    - Use sharedscripts so it runs once for all logs
  
  • Keep all other directives from step 2

Configuration structure:
  /var/log/lab-app/*.log {
      weekly
      minsize 1M
      rotate 4
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root root
      sharedscripts
      postrotate
          /usr/bin/touch /var/log/lab-app/last-rotated
      endscript
  }

Test after creating:
  logrotate -d /etc/logrotate.d/lab-app
  logrotate -f /etc/logrotate.d/lab-app
  ls -l /var/log/lab-app/last-rotated
EOF
}

validate_step_3() {
    if grep -q "size\|minsize" /etc/logrotate.d/lab-app 2>/dev/null; then
        print_color "$GREEN" "  ✓ Size-based rotation configured"
    else
        echo ""
        print_color "$YELLOW" "  ⚠ No size-based rotation found"
    fi
    
    if grep -q "postrotate" /etc/logrotate.d/lab-app 2>/dev/null; then
        print_color "$GREEN" "  ✓ Postrotate script configured"
    else
        echo ""
        print_color "$YELLOW" "  ⚠ No postrotate script found"
    fi
    
    logrotate -f /etc/logrotate.d/lab-app >/dev/null 2>&1
    
    if [ -f /var/log/lab-app/last-rotated ]; then
        print_color "$GREEN" "  ✓ Postrotate script executed successfully"
    else
        echo ""
        print_color "$YELLOW" "  ⚠ Postrotate script may not have executed"
    fi
    
    return 0
}

hint_step_3() {
    echo "  Size: minsize 1M"
    echo "  Postrotate: postrotate...endscript block"
    echo "  Shared: sharedscripts"
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────

1. Update configuration
────────────────────────
  sudo vi /etc/logrotate.d/lab-app

Updated content:
  /var/log/lab-app/*.log {
      weekly
      minsize 1M
      rotate 4
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root root
      sharedscripts
      postrotate
          /usr/bin/touch /var/log/lab-app/last-rotated
      endscript
  }

Save and exit.

New directives explained:
  minsize 1M      - Rotate if BOTH weekly time passed AND file >1M
                    (Prevents rotating tiny logs, ensures large logs rotate)
  
  sharedscripts   - Run postrotate once for all logs, not per file
  
  postrotate      - Script to run after rotation completes
  endscript       - Marks end of postrotate block

2. Test configuration
─────────────────────
  sudo logrotate -d /etc/logrotate.d/lab-app

Should show no errors.

3. Force rotation
─────────────────
  sudo logrotate -f /etc/logrotate.d/lab-app

4. Verify postrotate ran
────────────────────────
  ls -l /var/log/lab-app/last-rotated
  stat /var/log/lab-app/last-rotated

File should exist with recent timestamp.

Common postrotate uses:
  • Reload services: systemctl reload myapp
  • Send notifications
  • Clean up temporary files
  • Update monitoring systems

Example - reload service:
  postrotate
      /usr/bin/systemctl reload httpd >/dev/null 2>&1 || true
  endscript

The || true prevents errors from failing the rotation.

EOF
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Test and verify rotation behavior

Thoroughly test your logrotate configuration.

Requirements:
  • Force multiple rotations (at least 3)
  • Verify rotated files have date suffixes
  • Confirm compression works (older files should be .gz)
  • Check delaycompress (most recent rotation not compressed)
  • Verify new logs created with correct permissions
  • Test writing to new logs
  • Confirm postrotate marker file updated

Testing procedure:
  1. Force rotation #1
  2. Check files created
  3. Force rotation #2
  4. Verify older logs now compressed
  5. Force rotation #3
  6. Observe compression pattern
  7. Write to new log
  8. Verify everything works

Commands to use:
  logrotate -f /etc/logrotate.d/lab-app
  ls -lh /var/log/lab-app/
  echo "test" >> /var/log/lab-app/application.log
  tail /var/log/lab-app/application.log
  zcat /var/log/lab-app/*.gz | tail
EOF
}

validate_step_4() {
    logrotate -f /etc/logrotate.d/lab-app >/dev/null 2>&1
    sleep 1
    logrotate -f /etc/logrotate.d/lab-app >/dev/null 2>&1
    sleep 1
    
    local score=0
    local total=3
    
    if ls /var/log/lab-app/*.log-* >/dev/null 2>&1 || \
       ls /var/log/lab-app/*.log.[0-9] >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Rotated log files exist"
        ((score++))
    else
        print_color "$RED" "  ✗ No rotated log files found"
    fi
    
    if ls /var/log/lab-app/*.gz >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Log compression working"
        ((score++))
    else
        print_color "$YELLOW" "  ⚠ No compressed logs (may need more rotations)"
    fi
    
    if [ -f /var/log/lab-app/application.log ] && \
       [ -f /var/log/lab-app/access.log ] && \
       [ -f /var/log/lab-app/error.log ]; then
        print_color "$GREEN" "  ✓ New log files created after rotation"
        ((score++))
    else
        print_color "$RED" "  ✗ New log files not created properly"
    fi
    
    echo ""
    echo "Testing score: $score/$total"
    
    [ $score -ge 2 ]
}

hint_step_4() {
    echo "  Force rotation: logrotate -f /etc/logrotate.d/lab-app"
    echo "  List files: ls -lh /var/log/lab-app/"
    echo "  View compressed: zcat /var/log/lab-app/*.gz | tail"
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────

1. Force first rotation
────────────────────────
  sudo logrotate -vf /etc/logrotate.d/lab-app
  ls -lh /var/log/lab-app/

Expected:
  application.log (new, empty)
  application.log-20260211 (rotated, not compressed)
  access.log (new)
  access.log-20260211 (rotated, not compressed)

Note: No compression yet due to delaycompress.

2. Force second rotation
────────────────────────
  sudo logrotate -vf /etc/logrotate.d/lab-app
  ls -lh /var/log/lab-app/

Expected:
  application.log (new, empty)
  application.log-20260211 (newest rotation, not compressed)
  application.log-20260211.1.gz (older rotation, NOW compressed)

Pattern with delaycompress:
  • Current log: never compressed
  • Most recent rotation: not compressed
  • Older rotations: compressed

3. Force third rotation
───────────────────────
  sudo logrotate -vf /etc/logrotate.d/lab-app
  ls -lh /var/log/lab-app/

Should have multiple rotations now.

4. View compressed logs
───────────────────────
  zcat /var/log/lab-app/application.log-*.gz | tail

Shows contents of compressed logs.

5. Check permissions
────────────────────
  ls -l /var/log/lab-app/application.log

Should show: -rw-r----- (0640)

6. Test writing to new log
──────────────────────────
  sudo bash -c 'echo "Test entry after rotation" >> /var/log/lab-app/application.log'
  tail /var/log/lab-app/application.log

Should show the test entry.

7. Check postrotate marker
──────────────────────────
  ls -l /var/log/lab-app/last-rotated
  date -r /var/log/lab-app/last-rotated

Timestamp should match most recent rotation.

8. Verify status file
─────────────────────
  grep lab-app /var/lib/logrotate/logrotate.status

Shows when logs were last rotated.

Rotation naming pattern (with dateext):
  First:   application.log → application.log-20260211
  Second:  application.log → application.log-20260218
  Third:   application.log → application.log-20260225

With rotate 4, oldest gets deleted when 5th rotation occurs.

Understanding the process:
  1. logrotate checks status file for last rotation
  2. Checks if criteria met (time + size if minsize)
  3. Runs prerotate script (if configured)
  4. Renames current log (adds date suffix)
  5. Creates new empty log with specified permissions
  6. Runs postrotate script (if configured)
  7. Compresses old rotations (except most recent if delaycompress)
  8. Removes rotations beyond retention limit
  9. Updates status file

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: Config file exists
    print_color "$CYAN" "[1/$total] Checking configuration file..."
    if [ -f /etc/logrotate.d/lab-app ]; then
        print_color "$GREEN" "  ✓ Configuration file exists"
        ((score++))
    else
        print_color "$RED" "  ✗ /etc/logrotate.d/lab-app not found"
        print_color "$YELLOW" "  Fix: Create configuration file"
    fi
    echo ""
    
    # CHECK 2: Valid syntax
    print_color "$CYAN" "[2/$total] Checking configuration syntax..."
    if [ -f /etc/logrotate.d/lab-app ] && logrotate -d /etc/logrotate.d/lab-app >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Configuration syntax valid"
        ((score++))
    else
        print_color "$RED" "  ✗ Configuration has syntax errors or doesn't exist"
        print_color "$YELLOW" "  Fix: Test with: logrotate -d /etc/logrotate.d/lab-app"
    fi
    echo ""
    
    # CHECK 3: Rotation works
    print_color "$CYAN" "[3/$total] Testing log rotation..."
    if [ -f /etc/logrotate.d/lab-app ]; then
        logrotate -f /etc/logrotate.d/lab-app >/dev/null 2>&1
        sleep 1
        if ls /var/log/lab-app/*.log-* >/dev/null 2>&1 || \
           ls /var/log/lab-app/*.log.[0-9] >/dev/null 2>&1; then
            print_color "$GREEN" "  ✓ Log rotation working"
            ((score++))
        else
            print_color "$RED" "  ✗ Logs not rotating properly"
            print_color "$YELLOW" "  Fix: Check configuration directives"
        fi
    else
        print_color "$RED" "  ✗ Cannot test - configuration file missing"
    fi
    echo ""
    
    # CHECK 4: Postrotate script
    print_color "$CYAN" "[4/$total] Checking postrotate script..."
    if [ -f /var/log/lab-app/last-rotated ]; then
        print_color "$GREEN" "  ✓ Postrotate script executed"
        ((score++))
    else
        print_color "$YELLOW" "  ⚠ Postrotate marker file not found"
        echo "  (This is optional but recommended for the lab)"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've successfully configured logrotate."
    elif [ $score -ge 3 ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED (with minor issues)"
        echo ""
        echo "Good job! Core functionality working."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total

    [ $score -ge 3 ]
}

#############################################################################
# SOLUTION (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Explore logrotate configuration
─────────────────────────────────────────────────────────────────
View main configuration:
  cat /etc/logrotate.conf

View drop-in configs:
  ls /etc/logrotate.d/
  cat /etc/logrotate.d/syslog

Check scheduling:
  systemctl status logrotate.timer
  systemctl list-timers logrotate.timer

View rotation status:
  cat /var/lib/logrotate/logrotate.status


STEP 2: Create basic configuration
─────────────────────────────────────────────────────────────────
Create configuration file:
  sudo vi /etc/logrotate.d/lab-app

Content:
  /var/log/lab-app/*.log {
      weekly
      rotate 4
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root root
  }

Test configuration:
  sudo logrotate -d /etc/logrotate.d/lab-app

Force test rotation:
  sudo logrotate -vf /etc/logrotate.d/lab-app

Verify:
  ls -lh /var/log/lab-app/


STEP 3: Add advanced features
─────────────────────────────────────────────────────────────────
Update configuration:
  sudo vi /etc/logrotate.d/lab-app

Updated content:
  /var/log/lab-app/*.log {
      weekly
      minsize 1M
      rotate 4
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root root
      sharedscripts
      postrotate
          /usr/bin/touch /var/log/lab-app/last-rotated
      endscript
  }

Test:
  sudo logrotate -f /etc/logrotate.d/lab-app
  ls -l /var/log/lab-app/last-rotated


STEP 4: Test thoroughly
─────────────────────────────────────────────────────────────────
Force multiple rotations:
  sudo logrotate -vf /etc/logrotate.d/lab-app
  ls -lh /var/log/lab-app/
  
  sudo logrotate -vf /etc/logrotate.d/lab-app
  ls -lh /var/log/lab-app/

View compressed logs:
  zcat /var/log/lab-app/*.gz | tail

Test writing to new log:
  sudo bash -c 'echo "Test" >> /var/log/lab-app/application.log'
  tail /var/log/lab-app/application.log


KEY CONCEPTS FOR RHCSA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration Structure:
  • Main config: /etc/logrotate.conf (global settings)
  • Drop-ins: /etc/logrotate.d/ (per-application configs)
  • Status file: /var/lib/logrotate/logrotate.status

Scheduling:
  • Runs via systemd timer: logrotate.timer
  • Default: Daily at 00:00
  • Check: systemctl list-timers logrotate.timer

Essential Directives:
  • Frequency: daily, weekly, monthly
  • Retention: rotate N (keep N rotations)
  • Size: size/minsize SIZE
  • Compression: compress, delaycompress
  • File creation: create MODE OWNER GROUP
  • Error handling: missingok, notifempty
  • Scripts: postrotate...endscript, sharedscripts

Testing Commands:
  • Dry-run: logrotate -d <config>
  • Force: logrotate -f <config>
  • Verbose: logrotate -v <config>

Rotation Process:
  1. Check if rotation needed (time/size criteria)
  2. Rename current log (add date suffix)
  3. Create new empty log
  4. Run postrotate script (if configured)
  5. Compress old rotations (except newest if delaycompress)
  6. Remove rotations beyond retention limit
  7. Update status file


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ALWAYS test with -d flag first to catch syntax errors
2. Use -f to verify rotation actually works
3. Remember: delaycompress keeps most recent rotation uncompressed
4. create directive is essential - logs won't be recreated without it
5. postrotate scripts need sharedscripts if they reload services
6. Common mistake: Forgetting to use || true in postrotate scripts
7. Verify: Check ls -lh output and look for date-suffixed files

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    rm -f /etc/logrotate.d/lab-app 2>/dev/null || true
    rm -rf /var/log/lab-app 2>/dev/null || true
    sed -i '/lab-app/d' /var/lib/logrotate/logrotate.status 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
