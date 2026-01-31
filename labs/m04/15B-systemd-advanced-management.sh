#!/bin/bash
# labs/m04/15B-systemd-advanced-management.sh
# Lab: Advanced systemd Unit Management and Troubleshooting
# Difficulty: Intermediate
# RHCSA Objective: 15.4, 15.5, 15.6 - Modifying units, dependencies, and masking

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Advanced systemd Unit Management and Troubleshooting"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="45-60 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create a simple script that our custom service will run
    mkdir -p /opt/lab-services
    cat > /opt/lab-services/webapp-monitor.sh << 'SCRIPT'
#!/bin/bash
# Simple monitoring script
echo "WebApp Monitor started at $(date)"
while true; do
    echo "$(date): Checking application health..."
    sleep 30
done
SCRIPT
    chmod +x /opt/lab-services/webapp-monitor.sh
    
    # Create a deliberately broken service for troubleshooting
    cat > /opt/lab-services/broken-service.sh << 'SCRIPT'
#!/bin/bash
# This script has an intentional error
echo "Starting broken service..."
sleep 2
/usr/bin/nonexistent-command
SCRIPT
    chmod +x /opt/lab-services/broken-service.sh
    
    # Install httpd for dependency work
    if ! rpm -q httpd >/dev/null 2>&1; then
        dnf install -y httpd >/dev/null 2>&1
    fi
    
    # Clean up any previous lab attempts
    systemctl stop webapp-monitor.service 2>/dev/null || true
    systemctl disable webapp-monitor.service 2>/dev/null || true
    rm -f /etc/systemd/system/webapp-monitor.service 2>/dev/null || true
    
    systemctl stop broken.service 2>/dev/null || true
    systemctl disable broken.service 2>/dev/null || true
    rm -f /etc/systemd/system/broken.service 2>/dev/null || true
    
    systemctl stop httpd 2>/dev/null || true
    systemctl disable httpd 2>/dev/null || true
    rm -rf /etc/systemd/system/httpd.service.d 2>/dev/null || true
    
    systemctl unmask httpd 2>/dev/null || true
    
    systemctl daemon-reload 2>/dev/null || true
    
    echo "  ✓ Lab scripts created in /opt/lab-services"
    echo "  ✓ Previous lab attempts cleaned up"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of basic systemd service management
  • Familiarity with systemctl commands
  • Understanding of service states (active, enabled, etc.)
  • Basic knowledge of unit file structure

Commands You'll Use:
  • systemctl edit - Create drop-in unit overrides
  • systemctl daemon-reload - Reload systemd configuration
  • systemctl mask/unmask - Prevent service from starting
  • systemctl list-dependencies - View unit dependencies
  • systemctl cat - View complete unit configuration
  • journalctl -u - View service-specific logs
  • systemctl show - Display unit properties

Files You'll Interact With:
  • /etc/systemd/system/*.service - Custom unit files
  • /etc/systemd/system/*.service.d/ - Drop-in override directories
  • /usr/lib/systemd/system/ - System-provided unit files

Reference Material:
  • man 5 systemd.unit - Unit file format
  • man 5 systemd.service - Service unit configuration
  • man 5 systemd.exec - Execution environment configuration
  • man systemd.directives - All available directives
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator managing a production web server. The development
team has created a custom monitoring application that needs to run as a systemd
service. Additionally, you need to modify existing services, manage dependencies,
and troubleshoot service failures - all common real-world tasks.

BACKGROUND:
While basic service management (start/stop/enable) covers routine operations,
the RHCSA exam tests your ability to create custom units, modify service
behavior, understand dependencies, and troubleshoot failures. These skills
are critical when vendor-provided units don't meet your requirements.

OBJECTIVES:
  1. Create a custom systemd service unit from scratch
     • Service name: webapp-monitor.service
     • Must run the script: /opt/lab-services/webapp-monitor.sh
     • Type: simple
     • Should restart on failure
     • Must start after network.target
     • Enable the service to start at boot
     
  2. Modify the custom service using a drop-in override
     • Add a restart delay of 10 seconds (RestartSec=10s)
     • Set a maximum of 5 restart attempts (StartLimitBurst=5)
     • Add a description that includes your name
     • Use systemctl edit to create the override
     • Do NOT edit the original unit file
     
  3. Work with service dependencies
     • View the dependencies of your webapp-monitor service
     • Understand what must start before your service
     • Create a Wants= dependency on httpd.service
     • Verify httpd starts when webapp-monitor starts
     
  4. Use systemd masking appropriately
     • Mask the httpd service (prevent it from starting)
     • Verify that even direct start attempts fail
     • Unmask the httpd service
     • Understand when masking is appropriate vs disable
     
  5. Troubleshoot a failing service
     • A broken.service unit file has been created but won't start
     • Examine why it's failing using systemctl status
     • View detailed logs with journalctl
     • Identify the root cause of the failure
     • Fix the service so it starts successfully

HINTS:
  • systemctl daemon-reload is required after creating/editing units
  • Drop-in files go in /etc/systemd/system/SERVICE.service.d/
  • Use systemctl cat to see the merged configuration
  • journalctl -u SERVICE -n 50 shows last 50 log entries
  • Masked services are symlinked to /dev/null

SUCCESS CRITERIA:
  • webapp-monitor.service exists and is running
  • Service has proper restart configuration via override
  • Dependencies are correctly configured
  • You can explain the difference between mask and disable
  • You successfully diagnosed and fixed the broken service
  • All services start correctly after a daemon-reload
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create custom webapp-monitor.service unit file
  ☐ 2. Add drop-in override for restart configuration
  ☐ 3. Configure service dependencies with Wants=
  ☐ 4. Practice masking and unmasking services
  ☐ 5. Troubleshoot and fix broken.service failure
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
You're managing systemd services in a production environment.
You'll create custom units, modify configurations, manage dependencies,
and troubleshoot failures - all critical exam skills.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Create a custom systemd service unit from scratch

The development team needs their monitoring script to run as a service.
You must create the unit file with proper configuration.

Requirements:
  • Unit file location: /etc/systemd/system/webapp-monitor.service
  • Script to run: /opt/lab-services/webapp-monitor.sh
  • Service Type: simple
  • Restart behavior: Restart=on-failure
  • Dependency: Must start After=network.target
  • Enable for automatic boot startup
  • Don't forget daemon-reload after creating the file!

Unit file structure reminder:
  [Unit]
    Description, After, Wants, Requires, etc.
  [Service]
    Type, ExecStart, Restart, etc.
  [Install]
    WantedBy, RequiredBy, etc.

The script is already created and executable at:
  /opt/lab-services/webapp-monitor.sh
EOF
}

validate_step_1() {
    if [ ! -f /etc/systemd/system/webapp-monitor.service ]; then
        echo ""
        print_color "$RED" "✗ Unit file not found: /etc/systemd/system/webapp-monitor.service"
        echo "  Create the service unit file in the correct location"
        return 1
    fi
    
    if ! grep -q "ExecStart=/opt/lab-services/webapp-monitor.sh" /etc/systemd/system/webapp-monitor.service; then
        echo ""
        print_color "$RED" "✗ ExecStart does not point to correct script"
        echo "  ExecStart should be: /opt/lab-services/webapp-monitor.sh"
        return 1
    fi
    
    if ! grep -q "Type=simple" /etc/systemd/system/webapp-monitor.service; then
        echo ""
        print_color "$RED" "✗ Service Type not set to 'simple'"
        echo "  Add: Type=simple in [Service] section"
        return 1
    fi
    
    if ! grep -q "Restart=on-failure" /etc/systemd/system/webapp-monitor.service; then
        echo ""
        print_color "$RED" "✗ Restart policy not configured"
        echo "  Add: Restart=on-failure in [Service] section"
        return 1
    fi
    
    if ! systemctl is-enabled webapp-monitor.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Service is not enabled"
        echo "  Run: systemctl enable webapp-monitor.service"
        return 1
    fi
    
    if ! systemctl is-active webapp-monitor.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Service is not running"
        echo "  Run: systemctl start webapp-monitor.service"
        return 1
    fi
    
    return 0
}

hint_step_1() {
    echo "  Create file: /etc/systemd/system/webapp-monitor.service"
    echo "  Include: [Unit], [Service], and [Install] sections"
    echo "  After creating: systemctl daemon-reload"
    echo "  Then: systemctl enable --now webapp-monitor.service"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Create the unit file:
  sudo vi /etc/systemd/system/webapp-monitor.service

Unit file contents:
[Unit]
Description=WebApp Health Monitor Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/lab-services/webapp-monitor.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target

Explanation of each section:

[Unit] section:
  • Description: Human-readable name for the service
  • After=network.target: Wait for network to be available
    - Ensures network is up before starting
    - Common dependency for network-dependent services

[Service] section:
  • Type=simple: Service runs as main process
    - Default type, process doesn't fork
    - systemd considers it started immediately
  • ExecStart: Absolute path to executable
    - MUST be absolute path (not relative)
    - This is the main command to run
  • Restart=on-failure: Auto-restart on non-zero exit
    - Won't restart on clean exit (exit code 0)
    - Prevents restart loops from intentional stops

[Install] section:
  • WantedBy=multi-user.target: When to start at boot
    - multi-user.target is standard for services
    - Equivalent to old runlevel 3
    - Creates symlink in multi-user.target.wants/

Enable and reload systemd configuration:
  sudo systemctl daemon-reload
  sudo systemctl enable --now webapp-monitor.service

Verify it's running:
  systemctl status webapp-monitor.service
  systemctl is-active webapp-monitor.service
  systemctl is-enabled webapp-monitor.service

View the running process:
  ps aux | grep webapp-monitor

Check service logs:
  journalctl -u webapp-monitor.service -n 20

Why daemon-reload is required:
  systemd caches unit file contents in memory
  daemon-reload forces systemd to re-read all unit files
  Required after creating or modifying any unit file
  Without it, systemd won't see your changes

EOF
}

hint_step_2() {
    echo "  Use: systemctl edit webapp-monitor.service"
    echo "  This creates a drop-in file automatically"
    echo "  Add: RestartSec=10s and StartLimitBurst=5"
    echo "  Verify with: systemctl cat webapp-monitor.service"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Modify service configuration using drop-in overrides

Rather than editing the original unit file, you should use drop-in
files to override or extend configuration. This is the preferred method.

Requirements:
  • Use: systemctl edit webapp-monitor.service
  • Add restart delay: RestartSec=10s
  • Limit restart attempts: StartLimitBurst=5
  • Update description to include your name
  • Do NOT edit /etc/systemd/system/webapp-monitor.service directly

Drop-in override benefits:
  • Preserves original configuration
  • Clearly shows customizations
  • Survives package updates
  • Can be version controlled separately

The systemctl edit command:
  • Creates /etc/systemd/system/SERVICE.service.d/override.conf
  • Opens editor automatically
  • Runs daemon-reload for you when you save

What to put in the override:
  Only the sections and directives you want to change
  You don't need to copy the entire original file
EOF
}

validate_step_2() {
    if [ ! -d /etc/systemd/system/webapp-monitor.service.d ]; then
        echo ""
        print_color "$RED" "✗ Drop-in directory doesn't exist"
        echo "  Use: systemctl edit webapp-monitor.service"
        return 1
    fi
    
    local override_file=$(find /etc/systemd/system/webapp-monitor.service.d -name "*.conf" -type f | head -1)
    if [ -z "$override_file" ]; then
        echo ""
        print_color "$RED" "✗ No override file found in drop-in directory"
        echo "  Use: systemctl edit webapp-monitor.service"
        return 1
    fi
    
    if ! grep -q "RestartSec=10" "$override_file" && ! grep -q "RestartSec=10s" "$override_file"; then
        echo ""
        print_color "$RED" "✗ RestartSec not set to 10s in override"
        echo "  Add: RestartSec=10s in [Service] section"
        return 1
    fi
    
    if ! grep -q "StartLimitBurst=5" "$override_file"; then
        echo ""
        print_color "$RED" "✗ StartLimitBurst not set to 5"
        echo "  Add: StartLimitBurst=5 in [Service] section"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Create drop-in override:
  sudo systemctl edit webapp-monitor.service

This opens an editor. Add these lines:

[Service]
RestartSec=10s
StartLimitBurst=5

[Unit]
Description=WebApp Health Monitor Service - Managed by <YourName>

Save and exit (in vi: :wq)

systemctl edit automatically:
  1. Creates /etc/systemd/system/webapp-monitor.service.d/
  2. Creates override.conf in that directory
  3. Runs daemon-reload when you save

Verify the merged configuration:
  systemctl cat webapp-monitor.service

You should see:
  # Original file contents
  # /etc/systemd/system/webapp-monitor.service
  [Unit]
  Description=...
  
  # Drop-in override
  # /etc/systemd/system/webapp-monitor.service.d/override.conf
  [Service]
  RestartSec=10s
  StartLimitBurst=5

Check specific properties:
  systemctl show webapp-monitor.service -p RestartSec
  systemctl show webapp-monitor.service -p StartLimitBurst

Understanding the directives:

RestartSec=10s:
  • Waits 10 seconds before attempting restart
  • Prevents rapid restart loops
  • Gives time for dependencies to stabilize
  • Default is 100ms (very fast)

StartLimitBurst=5:
  • Maximum restart attempts within time window
  • Default time window is 10 seconds
  • After 5 failures in 10 seconds, gives up
  • Prevents infinite restart loops
  • Service enters failed state after limit

Why use drop-in overrides:
  1. Separation of concerns:
     - Original file: vendor defaults
     - Override file: local customizations
  
  2. Update safety:
     - Package updates won't overwrite your changes
     - Original file can be replaced safely
  
  3. Clarity:
     - Easy to see what you've customized
     - systemctl cat shows both clearly
  
  4. Modularity:
     - Multiple override files possible
     - Can organize by purpose (10-restart.conf, 20-limits.conf)

Alternative manual method:
  sudo mkdir -p /etc/systemd/system/webapp-monitor.service.d
  sudo vi /etc/systemd/system/webapp-monitor.service.d/override.conf
  sudo systemctl daemon-reload

EOF
}

hint_step_3() {
    echo "  View dependencies: systemctl list-dependencies webapp-monitor"
    echo "  Edit service: Add Wants=httpd.service in [Unit] section"
    echo "  After changes: systemctl daemon-reload"
    echo "  Test: systemctl restart webapp-monitor"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Configure service dependencies

Your monitoring service should start httpd if it's not already running,
but shouldn't fail if httpd fails to start.

Requirements:
  • View current dependencies of webapp-monitor.service
  • Add Wants=httpd.service to webapp-monitor
  • Verify httpd starts when webapp-monitor starts
  • Understand why Wants is better than Requires here

Dependency types in systemd:
  • Requires=: Hard dependency, both must start
  • Wants=: Soft dependency, attempts to start but continues if it fails
  • After=: Ordering, doesn't imply dependency
  • Before=: Reverse ordering

For this task:
  • We want httpd to start with our service
  • But our service should continue even if httpd fails
  • This is what Wants= provides

You can add the dependency in either:
  1. The original service file, OR
  2. A drop-in override (recommended)
EOF
}

validate_step_3() {
    # Check if Wants=httpd is configured (in original file or override)
    local has_wants=false
    if systemctl cat webapp-monitor.service | grep -q "Wants=.*httpd"; then
        has_wants=true
    fi
    
    if [ "$has_wants" = false ]; then
        echo ""
        print_color "$RED" "✗ Wants=httpd.service not configured"
        echo "  Add to [Unit] section in service or override"
        return 1
    fi
    
    # Check that the dependency is actually working
    systemctl stop httpd 2>/dev/null || true
    systemctl stop webapp-monitor 2>/dev/null || true
    sleep 1
    systemctl start webapp-monitor 2>/dev/null
    sleep 2
    
    if ! systemctl is-active httpd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ httpd did not start with webapp-monitor"
        echo "  Check that Wants= is configured correctly"
        echo "  Run: systemctl daemon-reload after changes"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
First, view current dependencies:
  systemctl list-dependencies webapp-monitor.service

This shows what starts before/with your service.

Add the dependency using drop-in override:
  sudo systemctl edit webapp-monitor.service

Add to the file:
[Unit]
Wants=httpd.service

Or edit the original file:
  sudo vi /etc/systemd/system/webapp-monitor.service

Add in [Unit] section:
Wants=httpd.service

Reload systemd:
  sudo systemctl daemon-reload

Test the dependency:
  sudo systemctl stop httpd
  sudo systemctl stop webapp-monitor
  sudo systemctl start webapp-monitor
  
Check if both are running:
  systemctl is-active webapp-monitor httpd

View complete dependencies again:
  systemctl list-dependencies webapp-monitor.service
  # You should now see httpd.service in the list

Understanding dependency types:

Requires= (Hard dependency):
  • If dependency fails, this unit fails
  • Use when service absolutely needs the dependency
  • Example: Database service requires storage mount
  Syntax: Requires=mariadb.service

Wants= (Soft dependency):
  • Attempts to start dependency
  • If dependency fails, this unit continues
  • Use when dependency is helpful but not critical
  • Example: Web service wants monitoring but doesn't need it
  Syntax: Wants=httpd.service

After= (Ordering only):
  • Controls startup order
  • Does NOT automatically start the dependency
  • Must combine with Requires= or Wants=
  • Example: Start after network is available
  Syntax: After=network.target

Before= (Reverse ordering):
  • This unit starts before the specified unit
  • Use to ensure proper shutdown order
  Syntax: Before=application.service

Combining directives:
[Unit]
Wants=httpd.service
After=httpd.service

This means:
  1. Try to start httpd (Wants)
  2. Wait for httpd to finish starting (After)
  3. Then start this service
  4. But if httpd fails, still start this service

Real-world example:
  A monitoring service might want to monitor httpd
  But it can still run and monitor other things if httpd fails
  This is perfect for Wants= rather than Requires=

Common patterns:
  Database application:
    Requires=mariadb.service
    After=mariadb.service

  Web service with optional cache:
    Wants=redis.service
    After=redis.service

  Service needing network:
    After=network.target
    (Note: network.target doesn't need Wants/Requires)

View all dependencies visually:
  systemctl list-dependencies webapp-monitor.service --all

Check reverse dependencies (what depends on httpd):
  systemctl list-dependencies httpd.service --reverse

EOF
}

hint_step_4() {
    echo "  Mask: systemctl mask httpd"
    echo "  Try starting: systemctl start httpd (should fail)"
    echo "  Unmask: systemctl unmask httpd"
    echo "  Difference: mask prevents ANY start, disable prevents boot start"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Use systemd masking to prevent service startup

Masking is different from disabling. Learn when and why to use it.

Requirements:
  • Mask the httpd service
  • Attempt to start it and observe the failure
  • Verify it's linked to /dev/null
  • Unmask the httpd service
  • Explain when masking is appropriate

Understanding mask vs disable:

disable:
  • Removes from boot startup
  • Can still be started manually
  • Can still be started by dependencies
  
mask:
  • Completely prevents starting
  • Manual start attempts fail
  • Dependencies cannot start it
  • Creates symlink to /dev/null

When to use masking:
  • Conflicting services (only one should run)
  • Security: prevent accidental start of dangerous service
  • Maintenance: temporarily prevent service during changes
  • Compliance: ensure service never runs

Real-world example:
  Some systems have both firewalld and iptables
  You should mask the one you're not using
EOF
}

validate_step_4() {
    # For this step, we just need to verify they understand the concept
    # We'll check that httpd is NOT masked (they should unmask it)
    if systemctl is-masked httpd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ httpd is still masked"
        echo "  Don't forget to unmask it: systemctl unmask httpd"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Mask the httpd service:
  sudo systemctl mask httpd

Verify it's masked:
  systemctl status httpd
  # Should show: Loaded: masked (Reason: Unit httpd.service is masked.)

Try to start it (this should fail):
  sudo systemctl start httpd
  # Error: Failed to start httpd.service: Unit httpd.service is masked.

Check what masking actually does:
  ls -l /etc/systemd/system/httpd.service
  # Shows: lrwxrwxrwx ... /etc/systemd/system/httpd.service -> /dev/null

Unmask the service:
  sudo systemctl unmask httpd

Verify it's unmasked:
  systemctl status httpd
  # Should no longer show "masked"

Now it can be started again:
  sudo systemctl start httpd
  # Should succeed

Understanding masking in depth:

What mask does:
  1. Creates symlink: /etc/systemd/system/SERVICE -> /dev/null
  2. Prevents ALL attempts to start the service
  3. Even dependencies cannot start it
  4. Manual start attempts fail

Comparison table:
┌────────────────┬──────────┬──────────┬─────────┐
│ Can be...      │ enabled  │ disabled │ masked  │
├────────────────┼──────────┼──────────┼─────────┤
│ Started at boot│ Yes      │ No       │ No      │
│ Started manual │ Yes      │ Yes      │ No      │
│ Started by dep │ Yes      │ Yes      │ No      │
└────────────────┴──────────┴──────────┴─────────┘

When to use mask:
  1. Conflicting services:
     - firewalld vs iptables
     - NetworkManager vs network
     - httpd vs nginx (different web servers)
  
  2. Security hardening:
     - Mask services that should never run
     - Compliance requirements
     - Prevent accidental exposure
  
  3. Maintenance:
     - Temporarily prevent start during system changes
     - Ensure service stays down during troubleshooting
  
  4. Preventing dependencies:
     - Stop other services from starting this one
     - Break unwanted dependency chains

When NOT to use mask:
  - Normal service management (use disable instead)
  - Temporary stops (use stop instead)
  - Services you might need later (disable is safer)

Practical examples:

Example 1 - Prevent old init scripts:
  sudo systemctl mask rc-local.service
  # Ensures old SysV init scripts don't run

Example 2 - Security hardening:
  sudo systemctl mask debug-shell.service
  # Prevents emergency debug shell access

Example 3 - Choosing between conflicting services:
  sudo systemctl mask iptables
  sudo systemctl enable firewalld
  # Ensures only firewalld is used, never iptables

Checking masked services system-wide:
  systemctl list-unit-files | grep masked

Checking if specific service is masked:
  systemctl is-masked httpd
  # Returns: masked or not-found (if not masked returns no output/exit 1)

EOF
}

hint_step_5() {
    echo "  Check status: systemctl status broken.service"
    echo "  View logs: journalctl -u broken.service -n 30"
    echo "  Look for: What command failed? Why?"
    echo "  Fix: Edit the script or unit file as needed"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Troubleshoot and fix a failing service

A service called broken.service has been created but won't start.
Use systemd tools to diagnose and fix the problem.

Requirements:
  • Examine why broken.service fails to start
  • Use systemctl status to see the immediate error
  • Use journalctl to see detailed logs
  • Identify the root cause
  • Fix the service so it starts successfully

Troubleshooting workflow:
  1. Check status: systemctl status SERVICE
     - Look at Active line (failed, inactive, etc.)
     - Read the last few log lines shown
     - Note the exit code
  
  2. Check detailed logs: journalctl -u SERVICE
     - See full output from the service
     - Look for error messages
     - Identify what failed
  
  3. Check configuration: systemctl cat SERVICE
     - Is ExecStart correct?
     - Are paths valid?
     - Is the script executable?
  
  4. Check the executable:
     - Does the file exist?
     - Is it executable?
     - Can you run it manually?

The broken.service unit file has already been created for you.
You need to find and fix what's wrong.
EOF
}

validate_step_5() {
    # Create the broken service if it doesn't exist
    if [ ! -f /etc/systemd/system/broken.service ]; then
        cat > /etc/systemd/system/broken.service << 'UNIT'
[Unit]
Description=Intentionally Broken Service for Troubleshooting

[Service]
Type=simple
ExecStart=/opt/lab-services/broken-service.sh

[Install]
WantedBy=multi-user.target
UNIT
        systemctl daemon-reload
    fi
    
    # The service should be startable and running
    if ! systemctl is-active broken.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ broken.service is not running"
        echo "  Diagnose with: systemctl status broken.service"
        echo "  Check logs: journalctl -u broken.service -n 30"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Try to start the service and see it fail
  sudo systemctl start broken.service

Step 2: Check the status
  systemctl status broken.service

Output shows:
  Active: failed (Result: exit-code)
  Process: ... ExecStart=/opt/lab-services/broken-service.sh (code=exited, status=127)
  
The status=127 means "command not found"

Step 3: Check detailed logs
  journalctl -u broken.service -n 30

You'll see:
  /opt/lab-services/broken-service.sh: line X: /usr/bin/nonexistent-command: No such file or directory

Step 4: Look at the script
  cat /opt/lab-services/broken-service.sh

You'll see it tries to run: /usr/bin/nonexistent-command

Step 5: Fix the script
  sudo vi /opt/lab-services/broken-service.sh

Replace the nonexistent command with something valid, like:
  #!/bin/bash
  echo "Starting broken service..."
  sleep 2
  echo "Service running successfully"
  # Keep running
  while true; do
      sleep 30
  done

Step 6: Start the service again
  sudo systemctl start broken.service

Step 7: Verify it's working
  systemctl status broken.service
  # Should show: Active: active (running)

Understanding troubleshooting:

Exit codes and their meanings:
  0   - Success
  1   - General error
  2   - Misuse of shell command
  126 - Command cannot execute (permissions)
  127 - Command not found
  128+N - Fatal error signal N
  130 - Terminated by Ctrl+C
  137 - Killed (SIGKILL)
  143 - Terminated (SIGTERM)

Common service failures:

1. Command not found (exit 127):
   - Path is wrong in ExecStart
   - Command doesn't exist
   - Missing package
   Fix: Verify command exists and path is correct

2. Permission denied (exit 126):
   - Script not executable
   - No execute permission on file
   Fix: chmod +x /path/to/script

3. Configuration error (exit 1):
   - Missing config file
   - Invalid configuration
   - Wrong parameters
   Fix: Check application logs, verify config

4. Dependency failure:
   - Required service not running
   - Resource not available
   Fix: Check dependencies, ensure they're running

Troubleshooting commands:

Quick status check:
  systemctl status SERVICE
  # Shows: state, recent logs, process info

Detailed logs:
  journalctl -u SERVICE
  journalctl -u SERVICE --since today
  journalctl -u SERVICE -n 50
  journalctl -u SERVICE -f  # Follow mode

Check configuration:
  systemctl cat SERVICE
  systemctl show SERVICE

Verify files and permissions:
  ls -l /path/to/executable
  file /path/to/executable
  /path/to/executable  # Try running it directly

Check dependencies:
  systemctl list-dependencies SERVICE
  systemctl list-dependencies SERVICE --reverse

Reload after changes:
  sudo systemctl daemon-reload
  sudo systemctl restart SERVICE

Advanced debugging:
  # Increase log verbosity
  systemctl -l status SERVICE
  
  # Show properties
  systemctl show SERVICE
  
  # Verify unit file syntax
  systemd-analyze verify SERVICE.service

Common mistakes and fixes:

Issue: Service won't start
Check: 
  - Is executable path correct?
  - Is file executable? (chmod +x)
  - Does command exist?
  - Are dependencies running?

Issue: Service starts but immediately stops
Check:
  - Is it Type=simple but process exits quickly?
  - Does it need Type=forking instead?
  - Is it crashing? Check logs.

Issue: Service fails during boot but starts manually
Check:
  - Are dependencies correct?
  - Does it need After=network.target?
  - Is ordering wrong?

Preventive measures:
  1. Always test services manually before enabling
  2. Check logs after every change
  3. Use systemctl daemon-reload after edits
  4. Verify with systemctl status immediately
  5. Test dependencies work as expected

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=7
    
    echo "Checking your advanced systemd configuration..."
    echo ""
    
    # CHECK 1: Custom service exists and is structured correctly
    print_color "$CYAN" "[1/$total] Checking webapp-monitor.service unit file..."
    if [ -f /etc/systemd/system/webapp-monitor.service ]; then
        if grep -q "ExecStart=/opt/lab-services/webapp-monitor.sh" /etc/systemd/system/webapp-monitor.service && \
           grep -q "Type=simple" /etc/systemd/system/webapp-monitor.service && \
           grep -q "Restart=on-failure" /etc/systemd/system/webapp-monitor.service; then
            print_color "$GREEN" "  ✓ Unit file exists with correct configuration"
            ((score++))
        else
            print_color "$RED" "  ✗ Unit file exists but missing required directives"
            print_color "$YELLOW" "  Check: ExecStart, Type, and Restart directives"
        fi
    else
        print_color "$RED" "  ✗ Unit file not found at /etc/systemd/system/webapp-monitor.service"
    fi
    echo ""
    
    # CHECK 2: Service is enabled and running
    print_color "$CYAN" "[2/$total] Checking webapp-monitor service status..."
    local service_ok=true
    if ! systemctl is-enabled webapp-monitor.service >/dev/null 2>&1; then
        print_color "$RED" "  ✗ Service not enabled for boot"
        service_ok=false
    fi
    if ! systemctl is-active webapp-monitor.service >/dev/null 2>&1; then
        print_color "$RED" "  ✗ Service not running"
        service_ok=false
    fi
    if [ "$service_ok" = true ]; then
        print_color "$GREEN" "  ✓ Service is enabled and running"
        ((score++))
    fi
    echo ""
    
    # CHECK 3: Drop-in override exists with correct settings
    print_color "$CYAN" "[3/$total] Checking drop-in override configuration..."
    if [ -d /etc/systemd/system/webapp-monitor.service.d ]; then
        local override_file=$(find /etc/systemd/system/webapp-monitor.service.d -name "*.conf" -type f | head -1)
        if [ -n "$override_file" ]; then
            if grep -q "RestartSec=10" "$override_file" && grep -q "StartLimitBurst=5" "$override_file"; then
                print_color "$GREEN" "  ✓ Drop-in override configured correctly"
                ((score++))
            else
                print_color "$RED" "  ✗ Drop-in exists but missing RestartSec or StartLimitBurst"
            fi
        else
            print_color "$RED" "  ✗ No override file in drop-in directory"
        fi
    else
        print_color "$RED" "  ✗ Drop-in directory not found"
        print_color "$YELLOW" "  Use: systemctl edit webapp-monitor.service"
    fi
    echo ""
    
    # CHECK 4: Dependencies configured
    print_color "$CYAN" "[4/$total] Checking service dependencies..."
    if systemctl cat webapp-monitor.service | grep -q "Wants=.*httpd"; then
        print_color "$GREEN" "  ✓ Dependency on httpd configured with Wants="
        ((score++))
    else
        print_color "$RED" "  ✗ Wants=httpd.service not found in configuration"
        print_color "$YELLOW" "  Add to [Unit] section in service or override"
    fi
    echo ""
    
    # CHECK 5: httpd not masked
    print_color "$CYAN" "[5/$total] Checking httpd mask status..."
    if ! systemctl is-masked httpd >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ httpd is not masked (correctly unmasked)"
        ((score++))
    else
        print_color "$RED" "  ✗ httpd is still masked"
        print_color "$YELLOW" "  Run: systemctl unmask httpd"
    fi
    echo ""
    
    # CHECK 6: Dependencies working (httpd starts with webapp-monitor)
    print_color "$CYAN" "[6/$total] Testing dependency functionality..."
    systemctl stop httpd 2>/dev/null || true
    systemctl stop webapp-monitor 2>/dev/null || true
    sleep 1
    systemctl start webapp-monitor 2>/dev/null
    sleep 2
    if systemctl is-active httpd >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Dependency working (httpd started with webapp-monitor)"
        ((score++))
    else
        print_color "$RED" "  ✗ httpd did not start when webapp-monitor started"
        print_color "$YELLOW" "  Verify Wants= is configured and daemon-reload was run"
    fi
    echo ""
    
    # CHECK 7: Broken service fixed
    print_color "$CYAN" "[7/$total] Checking if broken.service was fixed..."
    # Create the broken service if not exists
    if [ ! -f /etc/systemd/system/broken.service ]; then
        cat > /etc/systemd/system/broken.service << 'UNIT'
[Unit]
Description=Intentionally Broken Service for Troubleshooting

[Service]
Type=simple
ExecStart=/opt/lab-services/broken-service.sh

[Install]
WantedBy=multi-user.target
UNIT
        systemctl daemon-reload
    fi
    
    if systemctl is-active broken.service >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ broken.service is now running successfully"
        ((score++))
    else
        print_color "$RED" "  ✗ broken.service is not running"
        print_color "$YELLOW" "  Check status and logs, then fix the script"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Outstanding work! You've mastered advanced systemd management:"
        echo "  • Creating custom service units from scratch"
        echo "  • Using drop-in overrides for configuration"
        echo "  • Managing service dependencies with Wants/Requires"
        echo "  • Understanding and using service masking"
        echo "  • Troubleshooting service failures with systemctl and journalctl"
        echo ""
        echo "These skills are critical for the RHCSA exam and real-world administration."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and work through the remaining objectives."
        echo "This is challenging material - use --interactive mode for step-by-step guidance."
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

STEP 1: Create custom service unit
─────────────────────────────────────────────────────────────────
sudo vi /etc/systemd/system/webapp-monitor.service

[Unit]
Description=WebApp Health Monitor Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/lab-services/webapp-monitor.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable --now webapp-monitor.service
systemctl status webapp-monitor.service


STEP 2: Add drop-in override
─────────────────────────────────────────────────────────────────
sudo systemctl edit webapp-monitor.service

Add these lines:
[Service]
RestartSec=10s
StartLimitBurst=5

[Unit]
Description=WebApp Health Monitor Service - Managed by Admin

Save and exit. Verify:
systemctl cat webapp-monitor.service


STEP 3: Configure dependencies
─────────────────────────────────────────────────────────────────
sudo systemctl edit webapp-monitor.service

Add to existing override:
[Unit]
Wants=httpd.service

Or edit original service file and add to [Unit] section.

sudo systemctl daemon-reload
sudo systemctl restart webapp-monitor.service
systemctl list-dependencies webapp-monitor.service


STEP 4: Practice masking
─────────────────────────────────────────────────────────────────
sudo systemctl mask httpd
systemctl status httpd
sudo systemctl start httpd  # This will fail
ls -l /etc/systemd/system/httpd.service  # Shows link to /dev/null

sudo systemctl unmask httpd
systemctl status httpd


STEP 5: Troubleshoot broken service
─────────────────────────────────────────────────────────────────
systemctl status broken.service
journalctl -u broken.service -n 30
cat /opt/lab-services/broken-service.sh

Fix the script:
sudo vi /opt/lab-services/broken-service.sh

Replace with:
#!/bin/bash
echo "Starting service..."
sleep 2
echo "Service running"
while true; do sleep 30; done

sudo systemctl start broken.service
systemctl status broken.service


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Custom Unit Files:
  Location: /etc/systemd/system/
  Structure: [Unit], [Service], [Install] sections
  Always use absolute paths in ExecStart
  daemon-reload required after creation/modification

Drop-in Overrides:
  Location: /etc/systemd/system/SERVICE.service.d/
  Purpose: Extend/override vendor defaults
  Created with: systemctl edit SERVICE
  Merged with original configuration
  Survives package updates

Service Dependencies:
  Requires=: Hard dependency (both must start)
  Wants=: Soft dependency (try to start, continue if fails)
  After=: Ordering (wait for other to start first)
  Before=: Reverse ordering
  Can combine: Wants= + After=

Masking vs Disabling:
  disable: Prevents boot start, allows manual start
  mask: Prevents ALL starts (symlink to /dev/null)
  Use mask for conflicting services or security

Troubleshooting:
  systemctl status: Quick overview and recent logs
  journalctl -u: Detailed service logs
  systemctl cat: View merged configuration
  Exit codes indicate failure type


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always daemon-reload after unit file changes
2. Use systemctl edit for overrides (creates drop-in automatically)
3. Understand Wants vs Requires for dependencies
4. Check both systemctl status AND journalctl for failures
5. Remember: enabled=boot, active=running (you need both)
6. Use absolute paths in ExecStart directives
7. Verify changes immediately with systemctl status
8. Know when to use mask vs disable

Common exam tasks:
  • Create custom service unit
  • Enable service to start at boot
  • Configure service dependencies
  • Troubleshoot failed services
  • Modify service restart behavior

Quick reference:
  Create unit: vi /etc/systemd/system/name.service
  Override: systemctl edit name.service
  Reload: systemctl daemon-reload
  Enable & start: systemctl enable --now name
  Check: systemctl status name
  Logs: journalctl -u name

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Stop and disable services
    systemctl stop webapp-monitor.service broken.service httpd 2>/dev/null || true
    systemctl disable webapp-monitor.service broken.service httpd 2>/dev/null || true
    
    # Remove unit files
    rm -f /etc/systemd/system/webapp-monitor.service 2>/dev/null || true
    rm -f /etc/systemd/system/broken.service 2>/dev/null || true
    rm -rf /etc/systemd/system/webapp-monitor.service.d 2>/dev/null || true
    rm -rf /etc/systemd/system/httpd.service.d 2>/dev/null || true
    
    # Remove lab scripts
    rm -rf /opt/lab-services 2>/dev/null || true
    
    # Unmask httpd if it was masked
    systemctl unmask httpd 2>/dev/null || true
    
    # Reload systemd
    systemctl daemon-reload
    
    echo "  ✓ All services stopped and disabled"
    echo "  ✓ Custom unit files removed"
    echo "  ✓ Lab scripts removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
