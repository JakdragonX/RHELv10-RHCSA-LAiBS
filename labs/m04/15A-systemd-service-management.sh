#!/bin/bash
# labs/m04/15A-systemd-service-management.sh
# Lab: Managing systemd services
# Difficulty: Beginner
# RHCSA Objective: 15.1, 15.2, 15.3 - Understanding and managing systemd services

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing systemd services"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="30-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Install httpd if not present (common service to practice with)
    if ! rpm -q httpd >/dev/null 2>&1; then
        dnf install -y httpd >/dev/null 2>&1
    fi
    
    # Stop and disable httpd to start fresh
    systemctl stop httpd 2>/dev/null || true
    systemctl disable httpd 2>/dev/null || true
    
    # Install chronyd if not present (another service to work with)
    if ! rpm -q chronyd >/dev/null 2>&1; then
        dnf install -y chrony >/dev/null 2>&1
    fi
    
    # Stop and disable chronyd
    systemctl stop chronyd 2>/dev/null || true
    systemctl disable chronyd 2>/dev/null || true
    
    echo "  ✓ Test services installed"
    echo "  ✓ Services stopped and disabled"
    echo "  ✓ Lab environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of services and daemons
  • Familiarity with process management
  • Understanding of system boot process

Commands You'll Use:
  • systemctl - Systemd control utility
  • systemctl status - Check service status
  • systemctl start - Start a service
  • systemctl stop - Stop a service
  • systemctl enable - Enable service at boot
  • systemctl disable - Disable service at boot
  • systemctl restart - Restart a service
  • systemctl list-units - List active units
  • systemctl list-unit-files - List all unit files

Files You'll Interact With:
  • /usr/lib/systemd/system/ - System unit files
  • /etc/systemd/system/ - Custom/override unit files
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You are a system administrator who needs to manage services on a RHEL server.
The server runs a web server (httpd) and needs time synchronization (chronyd).
You must ensure services are properly configured, running, and set to start
automatically at boot.

BACKGROUND:
Systemd is the init system and service manager for RHEL. Understanding how to
start, stop, enable, and troubleshoot services is fundamental to system
administration and critical for the RHCSA exam.

OBJECTIVES:
  1. Explore systemd units and understand unit types
     • List all active units
     • View different unit types available
     • Examine a service unit configuration
     • Understand what systemd manages

  2. Check service status and understand the output
     • Check httpd service status
     • Interpret the status output
     • Understand Active, Loaded, and enabled states
     • View recent service logs

  3. Start and stop services
     • Start the httpd service
     • Verify it is running
     • Stop the httpd service
     • Confirm it stopped

  4. Enable services for automatic startup
     • Enable httpd to start at boot
     • Verify the enablement
     • Start httpd in one command while enabling
     • Understand the difference between start and enable

  5. Manage a second service and practice workflow
     • Work with chronyd service
     • Enable and start chronyd in one command
     • Verify both services are running and enabled
     • Restart a service to apply changes

HINTS:
  • systemctl status shows current state and recent logs
  • enabled means starts at boot, active means running now
  • --now flag combines enable with start
  • Tab completion works with systemctl

SUCCESS CRITERIA:
  • Both httpd and chronyd services are running
  • Both services are enabled to start at boot
  • You understand service states and management
  • Can verify service status independently
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore systemd units and unit types
  ☐ 2. Check and understand service status
  ☐ 3. Start and stop services
  ☐ 4. Enable services for automatic startup
  ☐ 5. Manage multiple services efficiently
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "5"
}

scenario_context() {
    cat << 'EOF'
You are managing systemd services on a RHEL server.
You'll work with httpd and chronyd services to master service management.

This is the foundation of systemd administration.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore systemd units and understand what systemd manages

Before managing services, understand what systemd controls and the types
of units it manages.

Requirements:
  • List all currently active units
  • View available unit types
  • Examine the httpd service unit file
  • Understand systemd's role

Questions to explore:
  • What types of units does systemd manage?
  • How many units are currently active?
  • What does a service unit file contain?
  • Where are unit files located?

Systemd manages services, sockets, timers, mounts, and more.
Everything systemd controls is called a "unit."
EOF
}

validate_step_1() {
    # This step is exploratory, always pass
    return 0
}

hint_step_1() {
    echo "  List units: systemctl list-units"
    echo "  Unit types: systemctl -t help"
    echo "  View unit: systemctl cat httpd"
    echo "  Status: systemctl status httpd"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
List active units:
  systemctl list-units

View available unit types:
  systemctl -t help

View httpd unit file:
  systemctl cat httpd.service

Check httpd status:
  systemctl status httpd

List all unit files:
  systemctl list-unit-files | head -20

Understanding:
  Systemd manages multiple unit types:
  - service: Daemon processes
  - socket: Network listeners
  - timer: Scheduled tasks
  - mount: Filesystem mounts
  - target: Group of units
  - path: Filesystem triggers

Unit file locations:
  /usr/lib/systemd/system/ - System defaults
  /etc/systemd/system/ - Customizations

Unit states:
  loaded: Configuration loaded
  active: Currently running
  enabled: Starts at boot
  disabled: Does not start at boot

EOF
}

hint_step_2() {
    echo "  Check status: systemctl status httpd"
    echo "  Look for: Active, Loaded, Enabled lines"
    echo "  Recent logs shown at bottom"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Check service status and understand the output

Learn to read systemctl status output to understand service state.

Requirements:
  • Check the httpd service status
  • Identify if it's running or stopped
  • Check if it's enabled or disabled
  • View recent log entries

Key information in status output:
  • Loaded line: Shows if enabled/disabled
  • Active line: Shows if running/stopped
  • Process info: Shows PID if running
  • Recent logs: Last few journal entries

Understanding status is critical for troubleshooting.
EOF
}

validate_step_2() {
    # Exploratory step, always pass
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Check httpd status:
  systemctl status httpd

Reading the output:
  Loaded: Shows unit file location and enabled status
    - enabled: Will start at boot
    - disabled: Will not start at boot
  
  Active: Shows current running state
    - active (running): Service is running
    - inactive (dead): Service is stopped
    - failed: Service crashed or failed to start
  
  Process: Shows PID if running
  
  Recent logs: Last several journal entries

Example output interpretation:
  Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled)
  Active: inactive (dead)
  
  This means:
  - Unit file exists and is loaded
  - Service will NOT start at boot (disabled)
  - Service is currently stopped (inactive/dead)

EOF
}

hint_step_3() {
    echo "  Start service: systemctl start httpd"
    echo "  Check it's running: systemctl status httpd"
    echo "  Stop service: systemctl stop httpd"
    echo "  Verify stopped: systemctl is-active httpd"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Start and stop services

Practice the most common service management operations: starting and stopping.

Requirements:
  • Start the httpd service
  • Verify it is running
  • Stop the httpd service  
  • Confirm it stopped successfully

Operations to perform:
  1. Start httpd
  2. Check status to confirm running
  3. Stop httpd
  4. Verify it stopped

Note: Starting a service does NOT enable it for boot.
These are separate operations.
EOF
}

validate_step_3() {
    # We don't validate if they stopped it - we'll check final state in step 4
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Start httpd:
  sudo systemctl start httpd

Verify it's running:
  systemctl status httpd
  systemctl is-active httpd
  # Should show: active

Stop httpd:
  sudo systemctl stop httpd

Verify it stopped:
  systemctl status httpd
  systemctl is-active httpd
  # Should show: inactive

Understanding:
  start: Starts the service immediately
  stop: Stops the service immediately
  
  These affect CURRENT state only
  They do NOT change boot behavior
  
  Quick checks:
  is-active: Returns active or inactive
  is-enabled: Returns enabled or disabled

EOF
}

hint_step_4() {
    echo "  Enable: systemctl enable httpd"
    echo "  Enable and start: systemctl enable --now httpd"
    echo "  Check enabled: systemctl is-enabled httpd"
    echo "  Check running: systemctl is-active httpd"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Enable services for automatic startup at boot

Configure httpd to start automatically when the system boots.

Requirements:
  • Enable httpd for automatic startup
  • Start httpd immediately
  • Verify both enabled AND active states
  • Understand the --now flag

Two approaches:
  1. Enable, then start separately
  2. Enable and start together with --now

The --now flag is efficient and commonly used.
EOF
}

validate_step_4() {
    if ! systemctl is-enabled httpd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ httpd is not enabled"
        echo "  Enable it to start at boot"
        return 1
    fi
    
    if ! systemctl is-active httpd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ httpd is not running"
        echo "  Start the service"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Option 1 - Enable then start:
  sudo systemctl enable httpd
  sudo systemctl start httpd

Option 2 - Enable and start together:
  sudo systemctl enable --now httpd

Verify enabled:
  systemctl is-enabled httpd
  # Should show: enabled

Verify running:
  systemctl is-active httpd
  # Should show: active

Check full status:
  systemctl status httpd
  # Should show both enabled and active

Understanding:
  enable: Creates symlinks for automatic startup
  --now: Combines enable with start
  
  enabled = starts at boot
  active = running now
  
  You need BOTH for a production service:
  - enabled: Survives reboots
  - active: Running right now

What happens when you enable:
  Symlinks created in /etc/systemd/system/
  Points to unit file in /usr/lib/systemd/system/

EOF
}

hint_step_5() {
    echo "  Enable and start: systemctl enable --now chronyd"
    echo "  Restart service: systemctl restart SERVICE"
    echo "  Check multiple: systemctl is-active httpd chronyd"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Manage multiple services and practice common operations

Apply what you learned to a second service and practice efficient workflows.

Requirements:
  • Enable and start chronyd in one command
  • Verify both httpd and chronyd are running
  • Verify both are enabled for boot
  • Practice restarting a service

Common operations to know:
  • restart: Stop then start (picks up config changes)
  • reload: Reload config without full restart
  • enable --now: Enable and start together

This simulates real-world service management.
EOF
}

validate_step_5() {
    local failures=0
    
    # Check httpd
    if ! systemctl is-enabled httpd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ httpd not enabled"
        ((failures++))
    fi
    
    if ! systemctl is-active httpd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ httpd not running"
        ((failures++))
    fi
    
    # Check chronyd
    if ! systemctl is-enabled chronyd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ chronyd not enabled"
        ((failures++))
    fi
    
    if ! systemctl is-active chronyd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ chronyd not running"
        ((failures++))
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Enable and start chronyd:
  sudo systemctl enable --now chronyd

Verify both services:
  systemctl is-active httpd chronyd
  systemctl is-enabled httpd chronyd

Check status of both:
  systemctl status httpd chronyd

Restart a service:
  sudo systemctl restart httpd

Reload configuration (if supported):
  sudo systemctl reload httpd

Understanding restart vs reload:
  restart: Stops completely, then starts
  - Drops all connections
  - Reads config files
  - Use after config changes
  
  reload: Reloads config without stopping
  - Keeps connections alive
  - Not all services support this
  - Graceful configuration update

Common workflow:
  1. Edit configuration file
  2. systemctl restart SERVICE
  3. systemctl status SERVICE (verify)

Checking multiple services:
  systemctl is-active service1 service2 service3
  systemctl status service1 service2 service3

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your systemd service management..."
    echo ""
    
    # CHECK 1: httpd enabled
    print_color "$CYAN" "[1/$total] Checking httpd enabled status..."
    if systemctl is-enabled httpd >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ httpd is enabled for boot"
        ((score++))
    else
        print_color "$RED" "  ✗ httpd is not enabled"
        print_color "$YELLOW" "  Fix: systemctl enable httpd"
    fi
    echo ""
    
    # CHECK 2: httpd active
    print_color "$CYAN" "[2/$total] Checking httpd running status..."
    if systemctl is-active httpd >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ httpd is running"
        ((score++))
    else
        print_color "$RED" "  ✗ httpd is not running"
        print_color "$YELLOW" "  Fix: systemctl start httpd"
    fi
    echo ""
    
    # CHECK 3: chronyd enabled
    print_color "$CYAN" "[3/$total] Checking chronyd enabled status..."
    if systemctl is-enabled chronyd >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ chronyd is enabled for boot"
        ((score++))
    else
        print_color "$RED" "  ✗ chronyd is not enabled"
        print_color "$YELLOW" "  Fix: systemctl enable chronyd"
    fi
    echo ""
    
    # CHECK 4: chronyd active
    print_color "$CYAN" "[4/$total] Checking chronyd running status..."
    if systemctl is-active chronyd >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ chronyd is running"
        ((score++))
    else
        print_color "$RED" "  ✗ chronyd is not running"
        print_color "$YELLOW" "  Fix: systemctl start chronyd"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You have mastered basic systemd service management:"
        echo "  • Understanding systemd units and types"
        echo "  • Checking service status"
        echo "  • Starting and stopping services"
        echo "  • Enabling services for automatic startup"
        echo "  • Managing multiple services efficiently"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Explore systemd units
─────────────────────────────────────────────────────────────────
systemctl list-units
systemctl -t help
systemctl cat httpd.service
systemctl status httpd


STEP 2: Understand service status
─────────────────────────────────────────────────────────────────
systemctl status httpd

Reading status output:
  Loaded: enabled/disabled (boot behavior)
  Active: active/inactive (current state)


STEP 3: Start and stop services
─────────────────────────────────────────────────────────────────
sudo systemctl start httpd
systemctl is-active httpd
sudo systemctl stop httpd
systemctl is-active httpd


STEP 4: Enable for boot and start
─────────────────────────────────────────────────────────────────
sudo systemctl enable --now httpd
systemctl is-enabled httpd
systemctl is-active httpd


STEP 5: Manage second service
─────────────────────────────────────────────────────────────────
sudo systemctl enable --now chronyd
systemctl is-active httpd chronyd
systemctl is-enabled httpd chronyd


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Systemd fundamentals:
  Init system (PID 1) and service manager
  Manages services, sockets, timers, mounts, etc.
  Everything managed is a "unit"

Service states:
  enabled: Starts automatically at boot
  disabled: Does not start at boot
  active: Currently running
  inactive: Currently stopped
  failed: Crashed or failed to start

Critical commands:
  start: Run service now
  stop: Stop service now
  enable: Configure to start at boot
  disable: Prevent starting at boot
  restart: Stop then start
  reload: Reload config without restart
  status: Show current state
  is-active: Check if running
  is-enabled: Check if enabled

Unit file locations:
  /usr/lib/systemd/system/ - System defaults
  /etc/systemd/system/ - Overrides and custom

The --now flag:
  Combines enable with start
  Very common in practice
  Example: systemctl enable --now httpd


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Confusing enable with start
  enable: Boot behavior only
  start: Current state only
  Need BOTH for production service

Mistake 2: Forgetting sudo
  Most systemctl commands need root
  Viewing status does not need sudo

Mistake 3: Not verifying changes
  Always check with status or is-active
  Failed commands may not show errors

Mistake 4: Using wrong service name
  Use tab completion
  Service names often end in .service
  Can omit .service suffix


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Essential commands for RHCSA:
1. systemctl enable --now SERVICE
2. systemctl status SERVICE
3. systemctl restart SERVICE
4. systemctl is-active SERVICE
5. systemctl is-enabled SERVICE

Quick verification:
  systemctl is-active SERVICE
  systemctl is-enabled SERVICE

Time savers:
  Use --now with enable
  Use tab completion
  Check multiple services at once

Boot behavior:
  enabled = starts at boot
  disabled = does not start at boot
  Verify with: systemctl is-enabled

Current state:
  active = running now
  inactive = stopped now
  Verify with: systemctl is-active

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Stop and disable services
    systemctl stop httpd chronyd 2>/dev/null || true
    systemctl disable httpd chronyd 2>/dev/null || true
    
    echo "  ✓ Services stopped and disabled"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
