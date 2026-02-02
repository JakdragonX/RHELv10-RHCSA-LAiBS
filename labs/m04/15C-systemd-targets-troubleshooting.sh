#!/bin/bash
# labs/m04/15C-systemd-targets-troubleshooting.sh
# Lab: Systemd Targets and Advanced Troubleshooting
# Difficulty: Advanced
# RHCSA Objective: 15.1, 15.5 - Understanding targets, dependencies, and troubleshooting

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Systemd Targets and Advanced Troubleshooting"
LAB_DIFFICULTY="Advanced"
LAB_TIME_ESTIMATE="60-75 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create lab directory
    mkdir -p /opt/lab-targets
    
    # Create a service that depends on network
    cat > /opt/lab-targets/network-dependent.sh << 'SCRIPT'
#!/bin/bash
echo "Network-dependent service started at $(date)"
# Simulate checking network connectivity
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "Network is available"
else
    echo "WARNING: Network might not be ready"
fi
while true; do
    sleep 60
done
SCRIPT
    chmod +x /opt/lab-targets/network-dependent.sh
    
    # Create a database simulator service
    cat > /opt/lab-targets/database-sim.sh << 'SCRIPT'
#!/bin/bash
echo "Database service starting at $(date)"
mkdir -p /var/lib/lab-db
echo "Database initialized" > /var/lib/lab-db/status
echo "Database ready for connections"
while true; do
    sleep 30
done
SCRIPT
    chmod +x /opt/lab-targets/database-sim.sh
    
    # Create an application service that requires the database
    cat > /opt/lab-targets/application.sh << 'SCRIPT'
#!/bin/bash
echo "Application starting at $(date)"
if [ -f /var/lib/lab-db/status ]; then
    echo "Database connection verified"
    echo "Application ready to serve requests"
else
    echo "ERROR: Database not available!"
    exit 1
fi
while true; do
    sleep 30
done
SCRIPT
    chmod +x /opt/lab-targets/application.sh
    
    # Create service with circular dependency (for troubleshooting)
    cat > /opt/lab-targets/circular-test.sh << 'SCRIPT'
#!/bin/bash
echo "Circular test service running"
while true; do
    sleep 30
done
SCRIPT
    chmod +x /opt/lab-targets/circular-test.sh
    
    # Create a slow-starting service
    cat > /opt/lab-targets/slow-starter.sh << 'SCRIPT'
#!/bin/bash
echo "Slow service starting..."
sleep 35  # Will exceed default timeout
echo "Slow service finally ready"
while true; do
    sleep 30
done
SCRIPT
    chmod +x /opt/lab-targets/slow-starter.sh
    
    # Clean up any previous lab attempts
    systemctl stop lab-network-dependent.service 2>/dev/null || true
    systemctl disable lab-network-dependent.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-network-dependent.service 2>/dev/null || true
    
    systemctl stop lab-database.service 2>/dev/null || true
    systemctl disable lab-database.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-database.service 2>/dev/null || true
    
    systemctl stop lab-application.service 2>/dev/null || true
    systemctl disable lab-application.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-application.service 2>/dev/null || true
    
    systemctl stop lab-circular-A.service 2>/dev/null || true
    systemctl disable lab-circular-A.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-circular-A.service 2>/dev/null || true
    
    systemctl stop lab-circular-B.service 2>/dev/null || true
    systemctl disable lab-circular-B.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-circular-B.service 2>/dev/null || true
    
    systemctl stop lab-slow-starter.service 2>/dev/null || true
    systemctl disable lab-slow-starter.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-slow-starter.service 2>/dev/null || true
    
    rm -rf /etc/systemd/system/lab-custom.target 2>/dev/null || true
    rm -rf /etc/systemd/system/lab-custom.target.wants 2>/dev/null || true
    
    rm -rf /var/lib/lab-db 2>/dev/null || true
    
    systemctl daemon-reload
    
    echo "  ✓ Lab scripts created in /opt/lab-targets"
    echo "  ✓ Previous lab attempts cleaned up"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Solid understanding of systemd service management
  • Familiarity with unit dependencies (Requires, Wants, After, Before)
  • Understanding of service states and troubleshooting
  • Basic knowledge of systemd boot process

Commands You'll Use:
  • systemctl get-default - View default target
  • systemctl set-default - Change default target
  • systemctl isolate - Switch to a different target
  • systemctl list-dependencies - View target/service dependencies
  • systemctl list-units --type=target - List all targets
  • systemd-analyze - Analyze boot performance and dependencies
  • systemd-analyze verify - Check unit file syntax
  • systemd-analyze critical-chain - Show boot time critical path
  • journalctl -b - View logs since boot
  • systemctl --failed - List failed units

Files You'll Interact With:
  • /etc/systemd/system/default.target - Symlink to default target
  • /etc/systemd/system/*.target - Custom target files
  • /usr/lib/systemd/system/*.target - System-provided targets

Key Concepts:
  • Targets are synchronization points in the boot process
  • Targets can depend on other targets and services
  • Targets group units together
  • Similar to old SysV runlevels but more flexible

Reference Material:
  • man 5 systemd.target - Target unit configuration
  • man 7 bootup - Boot process overview
  • man systemd-analyze - Boot analysis tools
  • man 7 systemd.special - Special systemd units
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're the lead system administrator for a company deploying a multi-tier
application stack. The application requires specific startup ordering,
has complex dependencies, and occasionally has timing issues. You need to
understand systemd targets, create custom targets, analyze the boot process,
and troubleshoot dependency problems.

BACKGROUND:
Systemd targets are the modern replacement for SysV runlevels. They provide
synchronization points during boot and allow grouping of services. Understanding
targets is critical for:
  • Controlling what services start at boot
  • Creating custom service groups
  • Troubleshooting boot issues
  • Managing system states (rescue, multi-user, graphical)

This lab simulates real-world scenarios you'll encounter managing production
systems and represents advanced concepts tested on the RHCSA exam.

OBJECTIVES:
  1. Explore and understand systemd targets
     • View the current default target
     • List all available targets on the system
     • Examine the multi-user.target dependencies
     • View the complete boot dependency chain
     • Understand the relationship between targets
     
  2. Change system targets
     • Switch to rescue.target (without rebooting)
     • Return to multi-user.target
     • Change the default boot target to graphical.target
     • Verify the change persists
     • Understand when to use isolate vs set-default
     
  3. Create a custom target with service dependencies
     • Create a custom target: lab-custom.target
     • Create three services with proper dependencies:
       a. lab-database.service (foundation service)
       b. lab-application.service (requires database)
       c. lab-network-dependent.service (needs network)
     • Configure services to be part of lab-custom.target
     • Ensure proper startup order: database → application
     • Test that stopping database stops application too
     
  4. Analyze boot performance and dependencies
     • Use systemd-analyze time to see boot duration
     • Use systemd-analyze blame to find slow services
     • Use systemd-analyze critical-chain for critical path
     • Identify what causes your custom services to start
     • Understand the boot sequence
     
  5. Troubleshoot complex dependency issues
     • Diagnose a service with circular dependencies
     • Fix a service that times out during startup
     • Identify why a service fails due to missing dependency
     • Use systemd-analyze verify to check unit files
     • Resolve all issues so services start successfully

HINTS:
  • Targets are just special unit types (like services)
  • Use systemctl list-dependencies to visualize relationships
  • The critical-chain shows what blocked what during boot
  • Circular dependencies are detected by systemd automatically
  • TimeoutStartSec can be increased for slow-starting services
  • Requires= creates hard dependencies, Wants= creates soft ones

SUCCESS CRITERIA:
  • You can explain what targets are and how they differ from services
  • You successfully created a custom target with working services
  • All services start in the correct order
  • You diagnosed and fixed all troubleshooting scenarios
  • You understand the boot process and can analyze it
  • You can change targets both temporarily and permanently
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore systemd targets and view dependencies
  ☐ 2. Change targets (rescue, multi-user, graphical)
  ☐ 3. Create custom target with three interdependent services
  ☐ 4. Analyze boot performance with systemd-analyze
  ☐ 5. Troubleshoot circular dependencies and timeouts
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
You're managing a complex multi-tier application that requires careful
orchestration of service startup. You'll master systemd targets and
troubleshooting to ensure reliable system operation.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore systemd targets and understand the boot process

Before creating custom targets, you need to understand how systemd
organizes targets and what they control.

Requirements:
  • View the current default target
  • List all available targets
  • Examine what multi-user.target depends on
  • View the graphical.target dependencies
  • Understand the relationship between targets

Questions to explore:
  • What is the difference between a target and a service?
  • How do targets relate to old SysV runlevels?
  • What targets exist on your system?
  • What makes graphical.target different from multi-user.target?

Key commands to use:
  systemctl get-default
  systemctl list-units --type=target
  systemctl list-dependencies multi-user.target
  systemctl list-dependencies graphical.target
  systemctl cat multi-user.target

Targets are synchronization points - they group related services
and establish ordering for the boot process.
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  Current target: systemctl get-default"
    echo "  All targets: systemctl list-units --type=target"
    echo "  Dependencies: systemctl list-dependencies TARGET"
    echo "  View target: systemctl cat multi-user.target"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
View current default target:
  systemctl get-default
  # Likely shows: multi-user.target or graphical.target

List all active targets:
  systemctl list-units --type=target

List all target unit files:
  systemctl list-unit-files --type=target

View multi-user.target dependencies:
  systemctl list-dependencies multi-user.target

View it with more detail:
  systemctl list-dependencies multi-user.target --all

View graphical.target dependencies:
  systemctl list-dependencies graphical.target
  # Notice it includes multi-user.target

Examine a target unit file:
  systemctl cat multi-user.target

View the actual symlink:
  ls -l /etc/systemd/system/default.target

Understanding targets:

What is a target?
  A target is a systemd unit that groups other units together
  It represents a system state or synchronization point
  Targets can depend on other targets and services
  
Targets vs Services:
  Services: Active processes that do work
  Targets: Passive grouping/synchronization points
  
  Services have ExecStart (they run something)
  Targets typically just have dependencies (Requires/Wants)

Target relationships:
  graphical.target
    ↓ Requires
  multi-user.target
    ↓ Requires
  basic.target
    ↓ Requires
  sysinit.target

Common targets and their purposes:

poweroff.target (runlevel 0)
  - Shutdown the system

rescue.target (runlevel 1)
  - Single-user mode
  - Minimal services
  - Root login only
  - For system recovery

multi-user.target (runlevel 3)
  - Normal multi-user text mode
  - Network services
  - Most common for servers
  - No GUI

graphical.target (runlevel 5)
  - Multi-user with GUI
  - Includes everything from multi-user.target
  - Plus display manager (GDM, SDDM, etc.)

reboot.target (runlevel 6)
  - Reboot the system

emergency.target
  - Even more minimal than rescue
  - Root filesystem mounted read-only
  - Absolute minimum services

Viewing target contents:
  systemctl cat multi-user.target shows:
  
  [Unit]
  Description=Multi-User System
  Documentation=man:systemd.special(7)
  Requires=basic.target
  Conflicts=rescue.service rescue.target
  After=basic.target rescue.service rescue.target
  AllowIsolate=yes

Key directives:
  Requires=basic.target
    - basic.target must start first
  
  Conflicts=rescue.target
    - Cannot run simultaneously with rescue mode
  
  After=basic.target
    - Wait for basic.target to complete
  
  AllowIsolate=yes
    - Can use systemctl isolate to switch to this target

Why targets matter:
  1. Boot process organization
     - Provides structure to startup
     - Clear dependency chains
  
  2. System state management
     - Switch between states (rescue, multi-user, graphical)
     - Group related services
  
  3. Troubleshooting
     - Boot to rescue mode if system won't start
     - Isolate to minimal state for debugging
  
  4. Custom service groups
     - Create your own targets
     - Group application services together

EOF
}

hint_step_2() {
    echo "  Isolate (temporary): systemctl isolate rescue.target"
    echo "  Set default (permanent): systemctl set-default graphical.target"
    echo "  Return to multi-user: systemctl isolate multi-user.target"
    echo "  Check default: systemctl get-default"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Change system targets temporarily and permanently

Learn the difference between switching targets now (isolate) and
changing what target the system boots to (set-default).

Requirements:
  • Switch to rescue.target WITHOUT rebooting
  • Return to multi-user.target
  • Change the default boot target to graphical.target
  • Verify the change persists
  • Return default to multi-user.target when done

IMPORTANT: For this lab, you can simulate the isolate commands
by just reading about them, as switching to rescue.target would
disrupt your session. Focus on understanding set-default.

Key concepts:
  isolate: Changes target NOW (like old telinit)
  set-default: Changes what boots next time
  
  You can isolate without changing default
  You can change default without isolating

Understanding:
  systemctl isolate rescue.target
    - Switches to rescue mode immediately
    - Stops services not in rescue.target
    - Does NOT change boot default
    - Temporary change
  
  systemctl set-default graphical.target
    - Changes default boot target
    - Does NOT switch immediately
    - Takes effect on next boot
    - Permanent change
EOF
}

validate_step_2() {
    # We can't actually isolate to rescue in a lab environment
    # Just check that they understand set-default
    
    # For this step, we'll just verify they can change defaults
    # They should have set it to graphical, then back to multi-user
    
    # Accept either multi-user or graphical as correct
    local current_default=$(systemctl get-default)
    if [[ "$current_default" != "multi-user.target" ]] && [[ "$current_default" != "graphical.target" ]]; then
        echo ""
        print_color "$RED" "✗ Default target seems incorrect: $current_default"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
View current default target:
  systemctl get-default

Change default to graphical.target:
  sudo systemctl set-default graphical.target

Verify the change:
  systemctl get-default
  # Should show: graphical.target
  
  ls -l /etc/systemd/system/default.target
  # Shows symlink to graphical.target

Change back to multi-user.target:
  sudo systemctl set-default multi-user.target

Understanding isolate (DO NOT actually run in this lab):
  sudo systemctl isolate rescue.target
  # Would switch to rescue mode immediately
  # Stops all services not needed for rescue
  # You'd need to log in as root at console

To return from rescue mode:
  sudo systemctl isolate multi-user.target

Understanding the differences:

systemctl isolate TARGET:
  • Changes running state immediately
  • Like the old 'telinit' command
  • Stops services not in target
  • Starts services needed by target
  • Temporary - does NOT change boot default
  • Requires AllowIsolate=yes in target

systemctl set-default TARGET:
  • Changes default boot target
  • Creates/updates /etc/systemd/system/default.target symlink
  • Does NOT affect current running state
  • Takes effect on next boot
  • Permanent change

Common scenarios:

Scenario 1: Troubleshooting graphics issues
  sudo systemctl set-default multi-user.target
  sudo reboot
  # System boots without GUI
  # Fix graphics issue
  sudo systemctl set-default graphical.target

Scenario 2: Emergency maintenance
  # At GRUB, add: systemd.unit=rescue.target
  # Boots directly into rescue mode
  # Fix issues
  # Reboot normally

Scenario 3: Temporary testing
  sudo systemctl isolate rescue.target
  # Test in rescue mode
  sudo systemctl isolate multi-user.target
  # Return to normal
  # Default unchanged

Scenario 4: Server that doesn't need GUI
  sudo systemctl set-default multi-user.target
  # Saves resources by not loading GUI

Target isolation rules:
  • Only targets with AllowIsolate=yes can be isolated to
  • Most standard targets allow isolation
  • Stops incompatible services (via Conflicts=)
  • Starts required services (via Requires=/Wants=)

Checking if target allows isolation:
  systemctl cat multi-user.target | grep AllowIsolate

Safe targets to isolate:
  • rescue.target
  • multi-user.target
  • graphical.target
  • emergency.target (very minimal)

Unsafe to isolate:
  • reboot.target (system will reboot!)
  • poweroff.target (system will shut down!)
  • halt.target (system will halt!)

Boot target selection methods:

Method 1: Set permanent default
  systemctl set-default multi-user.target

Method 2: One-time boot override
  At GRUB menu, press 'e' to edit
  Add to kernel line: systemd.unit=rescue.target
  Press Ctrl+X to boot

Method 3: Change at runtime
  systemctl isolate rescue.target

Real-world use cases:

Use case: Server without GUI
  systemctl set-default multi-user.target
  Reason: Saves RAM, CPU, reduces attack surface

Use case: Workstation with GUI
  systemctl set-default graphical.target
  Reason: Users expect graphical login

Use case: System won't boot graphically
  GRUB: systemd.unit=multi-user.target
  Boot to text mode, fix issue

Use case: Emergency repairs
  GRUB: systemd.unit=emergency.target
  Minimal environment for critical fixes

EOF
}

hint_step_3() {
    echo "  Create target: /etc/systemd/system/lab-custom.target"
    echo "  Create services: lab-database.service, lab-application.service, etc."
    echo "  Use: Requires= for hard dependencies"
    echo "  Use: After= for ordering"
    echo "  Add services to target: WantedBy=lab-custom.target"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create a custom target with properly ordered services

Build a custom target that groups related services with dependencies.
This simulates a real application stack.

Requirements:
  • Create custom target: /etc/systemd/system/lab-custom.target
  • Create lab-database.service:
    - Runs: /opt/lab-targets/database-sim.sh
    - Part of lab-custom.target
    - Should start After=network.target
  
  • Create lab-application.service:
    - Runs: /opt/lab-targets/application.sh
    - Part of lab-custom.target
    - Requires=lab-database.service
    - After=lab-database.service
    - Should fail if database isn't running
  
  • Create lab-network-dependent.service:
    - Runs: /opt/lab-targets/network-dependent.sh
    - Part of lab-custom.target
    - Wants=network-online.target
    - After=network-online.target
  
  • Enable all services
  • Test: Start lab-custom.target and verify all services start
  • Test: Stop database and verify application stops too

Service scripts are already created in /opt/lab-targets/

Critical concepts:
  Requires= : Hard dependency (both must be running)
  Wants= : Soft dependency (try to start, but continue if fails)
  After= : Ordering (wait for other to start first)
  Before= : Reverse ordering

The target itself should:
  • Describe what it's for
  • Allow isolation (AllowIsolate=yes)
  • Start After=multi-user.target
EOF
}

validate_step_3() {
    local failures=0
    
    # Check if custom target exists
    if [ ! -f /etc/systemd/system/lab-custom.target ]; then
        echo ""
        print_color "$RED" "✗ lab-custom.target not found"
        ((failures++))
    fi
    
    # Check if all services exist
    if [ ! -f /etc/systemd/system/lab-database.service ]; then
        echo ""
        print_color "$RED" "✗ lab-database.service not found"
        ((failures++))
    fi
    
    if [ ! -f /etc/systemd/system/lab-application.service ]; then
        echo ""
        print_color "$RED" "✗ lab-application.service not found"
        ((failures++))
    fi
    
    if [ ! -f /etc/systemd/system/lab-network-dependent.service ]; then
        echo ""
        print_color "$RED" "✗ lab-network-dependent.service not found"
        ((failures++))
    fi
    
    # If files don't exist, can't continue validation
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    # Check database service configuration
    if ! grep -q "ExecStart=/opt/lab-targets/database-sim.sh" /etc/systemd/system/lab-database.service; then
        echo ""
        print_color "$RED" "✗ lab-database.service ExecStart incorrect"
        ((failures++))
    fi
    
    # Check application service has Requires and After
    if ! grep -q "Requires=lab-database.service" /etc/systemd/system/lab-application.service; then
        echo ""
        print_color "$RED" "✗ lab-application.service missing Requires=lab-database.service"
        ((failures++))
    fi
    
    if ! grep -q "After=lab-database.service" /etc/systemd/system/lab-application.service; then
        echo ""
        print_color "$RED" "✗ lab-application.service missing After=lab-database.service"
        ((failures++))
    fi
    
    # Check services are enabled
    if ! systemctl is-enabled lab-database.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ lab-database.service not enabled"
        ((failures++))
    fi
    
    if ! systemctl is-enabled lab-application.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ lab-application.service not enabled"
        ((failures++))
    fi
    
    if ! systemctl is-enabled lab-network-dependent.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ lab-network-dependent.service not enabled"
        ((failures++))
    fi
    
    # Test that services can start
    systemctl stop lab-application.service lab-database.service lab-network-dependent.service 2>/dev/null || true
    sleep 1
    systemctl start lab-database.service
    sleep 2
    systemctl start lab-application.service
    sleep 2
    
    if ! systemctl is-active lab-database.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ lab-database.service failed to start"
        echo "  Check: journalctl -u lab-database.service"
        ((failures++))
    fi
    
    if ! systemctl is-active lab-application.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ lab-application.service failed to start"
        echo "  Check: journalctl -u lab-application.service"
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
Step 1: Create the custom target
─────────────────────────────────
sudo vi /etc/systemd/system/lab-custom.target

[Unit]
Description=Custom Lab Application Stack Target
Requires=multi-user.target
After=multi-user.target
AllowIsolate=yes


Step 2: Create the database service
────────────────────────────────────
sudo vi /etc/systemd/system/lab-database.service

[Unit]
Description=Lab Database Simulator
After=network.target

[Service]
Type=simple
ExecStart=/opt/lab-targets/database-sim.sh
Restart=on-failure

[Install]
WantedBy=lab-custom.target


Step 3: Create the application service
───────────────────────────────────────
sudo vi /etc/systemd/system/lab-application.service

[Unit]
Description=Lab Application Service
Requires=lab-database.service
After=lab-database.service

[Service]
Type=simple
ExecStart=/opt/lab-targets/application.sh
Restart=on-failure

[Install]
WantedBy=lab-custom.target


Step 4: Create the network-dependent service
─────────────────────────────────────────────
sudo vi /etc/systemd/system/lab-network-dependent.service

[Unit]
Description=Lab Network Dependent Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/opt/lab-targets/network-dependent.sh
Restart=on-failure

[Install]
WantedBy=lab-custom.target


Step 5: Enable and reload
──────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable lab-database.service
sudo systemctl enable lab-application.service
sudo systemctl enable lab-network-dependent.service


Step 6: Test the target
────────────────────────
Start all services via target:
  sudo systemctl start lab-custom.target

Check services are running:
  systemctl status lab-database.service
  systemctl status lab-application.service
  systemctl status lab-network-dependent.service

View the target dependencies:
  systemctl list-dependencies lab-custom.target


Step 7: Test dependency enforcement
────────────────────────────────────
Stop the database:
  sudo systemctl stop lab-database.service

Check application status:
  systemctl status lab-application.service
  # Should also stop because of Requires=

Start everything again:
  sudo systemctl start lab-custom.target


Understanding the configuration:

Target configuration:
  [Unit]
  Requires=multi-user.target
    - Must have multi-user.target running
    - Ensures basic system services are available
  
  After=multi-user.target
    - Wait for multi-user.target to complete
    - Ordering guarantee
  
  AllowIsolate=yes
    - Allows: systemctl isolate lab-custom.target
    - Makes it a valid isolation target

Database service:
  After=network.target
    - Waits for network subsystem
    - Doesn't guarantee network is fully online
    - Just ensures network systemd units loaded
  
  WantedBy=lab-custom.target
    - Creates symlink in lab-custom.target.wants/
    - Service starts when target is reached

Application service:
  Requires=lab-database.service
    - HARD dependency on database
    - If database stops, application stops
    - If database fails to start, application fails
  
  After=lab-database.service
    - Wait for database to start first
    - Ordering guarantee
    - Always combine After= with Requires/Wants!

Network-dependent service:
  Wants=network-online.target
    - SOFT dependency on network being fully online
    - Won't fail if network isn't ready
    - Will try to start network-online first
  
  After=network-online.target
    - Wait for network to be fully available
    - Better than just network.target

Dependency type decision matrix:

Use Requires= when:
  • Service absolutely needs the dependency
  • Both should fail/stop together
  • Example: Application needs database

Use Wants= when:
  • Service works better with dependency but can continue
  • Dependency failure shouldn't stop this service
  • Example: Service wants monitoring but doesn't need it

Use After= (with Requires/Wants) when:
  • Order matters
  • Service needs dependency to be ready first
  • Almost always used with Requires/Wants

Use Before= when:
  • This service must start before another
  • Usually for dependencies, less common
  • Example: Database must start before application

Viewing the dependency relationships:
  systemctl list-dependencies lab-application.service
  # Shows what it needs

  systemctl list-dependencies lab-application.service --reverse
  # Shows what needs it

  systemctl list-dependencies lab-custom.target --all
  # Shows complete tree

Testing dependency enforcement:
  # Start application - should start database too
  sudo systemctl start lab-application.service
  systemctl is-active lab-database.service  # Should be active
  
  # Stop database - should stop application too
  sudo systemctl stop lab-database.service
  systemctl is-active lab-application.service  # Should be inactive

Creating target.wants directory (automatic):
  When you enable a service with WantedBy=TARGET:
    systemctl enable lab-database.service
  
  Systemd creates:
    /etc/systemd/system/lab-custom.target.wants/
    /etc/systemd/system/lab-custom.target.wants/lab-database.service
  
  The .wants directory contains symlinks to services

Manual alternative (not recommended):
  sudo mkdir -p /etc/systemd/system/lab-custom.target.wants
  sudo ln -s /etc/systemd/system/lab-database.service \
    /etc/systemd/system/lab-custom.target.wants/

Why use custom targets:

1. Application grouping:
   - Group related services together
   - Start/stop entire stack at once
   - Example: lab-custom.target for your app

2. Environment management:
   - development.target
   - production.target
   - Each pulls in different services

3. Maintenance modes:
   - maintenance.target
   - Starts minimal services
   - Stops non-essential services

4. Role-based configurations:
   - webserver.target
   - database.target
   - monitoring.target

Real-world example:
  wordpress.target might include:
    - mariadb.service (Requires)
    - httpd.service (Requires)
    - redis.service (Wants)
    - monitoring-agent.service (Wants)

EOF
}

hint_step_4() {
    echo "  Boot time: systemd-analyze time"
    echo "  Slow services: systemd-analyze blame"
    echo "  Critical path: systemd-analyze critical-chain"
    echo "  Service chain: systemd-analyze critical-chain lab-application.service"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Analyze boot performance and dependency chains

Use systemd-analyze tools to understand system boot process and
identify what causes delays or dependencies.

Requirements:
  • View total boot time breakdown
  • Identify the slowest starting services
  • View the critical chain (what blocked what)
  • Analyze your custom service dependencies
  • Understand what causes boot delays

Commands to explore:
  systemd-analyze time
    - Shows total boot time
    - Breaks down by: kernel, initrd, userspace
  
  systemd-analyze blame
    - Lists services by startup time
    - Sorted slowest first
    - Shows what took longest
  
  systemd-analyze critical-chain
    - Shows critical path to boot
    - What blocked what
    - Time each unit took
  
  systemd-analyze critical-chain lab-application.service
    - Shows what blocked your service
    - Trace dependency chain

This helps identify:
  • Boot performance bottlenecks
  • Why services start in certain order
  • What dependencies cause delays
  • Whether ordering is optimal
EOF
}

validate_step_4() {
    # Exploratory step, always pass
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
View boot time summary:
  systemd-analyze time

Output shows:
  Startup finished in 2.5s (kernel) + 3.2s (initrd) + 15.8s (userspace) = 21.5s
  
  kernel: Kernel initialization
  initrd: Initial ramdisk loading
  userspace: All systemd units

View services by startup time:
  systemd-analyze blame

Output shows (example):
  8.234s NetworkManager.service
  3.142s firewalld.service
  2.891s kdump.service
  ...

View critical chain:
  systemd-analyze critical-chain

Output shows:
  multi-user.target @15.234s
  └─sshd.service @15.123s +111ms
    └─network.target @15.000s
      └─NetworkManager.service @6.766s +8.234s
        └─basic.target @6.700s
          └─sysinit.target @6.650s
            └─...

The format is:
  unit @TIME +DURATION
  @TIME: When unit activated
  +DURATION: How long it took

Analyze your custom service:
  systemd-analyze critical-chain lab-application.service

Shows:
  lab-application.service
  └─lab-database.service
    └─network.target
      └─...

Verify unit file syntax:
  systemd-analyze verify /etc/systemd/system/lab-application.service

Visualize boot process (creates SVG):
  systemd-analyze plot > boot.svg
  # Open boot.svg in browser to see timeline

Understanding the output:

systemd-analyze time:
  Kernel time:
    - Linux kernel initialization
    - Hardware detection
    - Driver loading
    - Cannot be improved via systemd
  
  Initrd time:
    - Initial RAM disk execution
    - Early boot environment
    - Root filesystem detection
    - Limited systemd control
  
  Userspace time:
    - All systemd unit activation
    - Service startup
    - This is where you can optimize

systemd-analyze blame:
  Shows time each service took to start
  Sorted by duration (longest first)
  
  Example interpretation:
    8.234s NetworkManager.service
      - NetworkManager took 8.2 seconds
      - Might be waiting for hardware
      - Or performing DHCP requests
  
  Common slow services:
    - NetworkManager: Network configuration
    - firewalld: Firewall rule loading
    - kdump: Kernel crash dump setup
    - mariadb: Database initialization

systemd-analyze critical-chain:
  Shows CRITICAL PATH to target
  Not every service, just the blocking chain
  
  Read bottom to top:
    sysinit.target (foundation)
    ↓
    basic.target (adds basic services)
    ↓
    network.target (network subsystem)
    ↓
    multi-user.target (full multi-user)
  
  @TIME means "reached at this time"
  +DURATION means "took this long"
  
  If a service shows +8s, it blocked boot for 8 seconds

Identifying bottlenecks:

Problem: Slow boot time
Check: systemd-analyze blame
Look for: Services taking >3-5 seconds
Consider: 
  - Can service be started later?
  - Is service needed at all?
  - Can service be optimized?

Problem: Service starts late
Check: systemd-analyze critical-chain SERVICE
Look for: What it's waiting for
Consider:
  - Are all dependencies necessary?
  - Is After= needed or just Wants=?
  - Can ordering be changed?

Problem: Service fails during boot
Check: journalctl -b -u SERVICE
Check: systemd-analyze verify SERVICE.service
Look for: Circular dependencies, missing files
Consider: Fix dependencies or paths

Optimization strategies:

1. Parallel startup:
   Remove unnecessary After= directives
   Services start in parallel by default
   Only use After= when ordering matters

2. Delay non-critical services:
   Don't require services that aren't needed
   Use Wants= instead of Requires=
   Start some services later

3. Optimize slow services:
   Investigate why service is slow
   Check logs during startup
   May be configuration issue

4. Disable unnecessary services:
   systemctl disable UNUSED.service
   Don't start services you don't need

Example optimization:

Before:
  [Unit]
  Requires=NetworkManager.service
  After=NetworkManager.service
  After=firewalld.service
  After=remote-fs.target

After:
  [Unit]
  Wants=network-online.target
  After=network-online.target

Result: Fewer dependencies, faster boot

Real-world scenarios:

Scenario: Application server
  Goal: Fast boot, minimal services
  Actions:
    - Disable graphical.target
    - Disable unnecessary services
    - Use multi-user.target
  Result: 10-15 second boot

Scenario: Desktop workstation
  Goal: User experience
  Actions:
    - Enable graphical.target
    - Ensure GUI starts quickly
    - NetworkManager for connectivity
  Result: 20-30 second boot acceptable

Scenario: Cloud instance
  Goal: Rapid deployment
  Actions:
    - Minimal services
    - cloud-init for configuration
    - No GUI
    - Optimized networking
  Result: 5-10 second boot

Advanced analysis:

View service dependencies graphically:
  systemd-analyze dot | dot -Tsvg > dependencies.svg

Check specific service timing:
  systemctl show SERVICE -p ExecMainStartTimestamp
  systemctl show SERVICE -p InactiveExitTimestamp

List services that failed:
  systemctl --failed

Check service resource usage:
  systemd-cgtop
  systemctl status SERVICE

EOF
}

hint_step_5() {
    echo "  First, create the broken services to troubleshoot"
    echo "  Circular: systemd-analyze verify will detect it"
    echo "  Timeout: Increase TimeoutStartSec= in service"
    echo "  Failed deps: Check Requires= and verify files exist"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Troubleshoot complex systemd issues

Three problematic services have been prepared. You must diagnose
and fix each issue using systemd troubleshooting tools.

Problem 1: Circular Dependency
  Two services: lab-circular-A.service and lab-circular-B.service
  They have a circular dependency (each requires the other)
  
  To create them for testing:
    Create lab-circular-A.service that Requires=lab-circular-B.service
    Create lab-circular-B.service that Requires=lab-circular-A.service
  
  Diagnosis:
    - Try to start one of them
    - Check the error message
    - Use systemd-analyze verify
  
  Fix:
    - Remove one of the Requires=
    - Or change Requires= to Wants=
    - Or remove unnecessary dependency

Problem 2: Service Timeout
  Service: lab-slow-starter.service
  The script takes 35 seconds to start
  Default timeout is 90 seconds, but let's simulate a shorter one
  
  To create:
    Create service with TimeoutStartSec=5s
    It will timeout before script finishes
  
  Diagnosis:
    - Service shows "failed" status
    - journalctl shows "Start operation timed out"
  
  Fix:
    - Increase TimeoutStartSec=
    - Or fix script to start faster
    - Or use Type=forking if appropriate

Problem 3: Missing Dependency (Already exists)
  Service: lab-application.service
  If lab-database.service isn't running, it will fail
  
  Diagnosis:
    - Check exit code
    - Review application logs
    - Verify dependencies are running
  
  Fix:
    - Ensure database service exists and starts
    - Verify Requires= and After= are set correctly

Requirements:
  • Create the circular dependency services
  • Create the slow starter service with timeout
  • Diagnose all three issues
  • Fix each issue
  • Verify all services start successfully
EOF
}

validate_step_5() {
    local failures=0
    
    # For this step, we need to check if they created and fixed the issues
    
    # Check if slow-starter service exists and can start
    if [ -f /etc/systemd/system/lab-slow-starter.service ]; then
        systemctl stop lab-slow-starter.service 2>/dev/null || true
        systemctl start lab-slow-starter.service 2>/dev/null
        sleep 3
        
        if ! systemctl is-active lab-slow-starter.service >/dev/null 2>&1; then
            echo ""
            print_color "$RED" "✗ lab-slow-starter.service is not running"
            echo "  It may need a longer TimeoutStartSec"
            ((failures++))
        fi
    else
        echo ""
        print_color "$RED" "✗ lab-slow-starter.service not created"
        ((failures++))
    fi
    
    # Check if circular dependencies are resolved (at least one should work)
    if [ -f /etc/systemd/system/lab-circular-A.service ]; then
        systemctl stop lab-circular-A.service 2>/dev/null || true
        systemctl start lab-circular-A.service 2>/dev/null
        sleep 2
        
        if ! systemctl is-active lab-circular-A.service >/dev/null 2>&1; then
            echo ""
            print_color "$RED" "✗ lab-circular-A.service failed to start"
            echo "  Check for circular dependencies"
            ((failures++))
        fi
    fi
    
    # Check that application service can start (database dependency)
    if [ -f /etc/systemd/system/lab-application.service ]; then
        systemctl stop lab-application.service lab-database.service 2>/dev/null || true
        systemctl start lab-database.service 2>/dev/null
        sleep 2
        systemctl start lab-application.service 2>/dev/null
        sleep 2
        
        if ! systemctl is-active lab-application.service >/dev/null 2>&1; then
            echo ""
            print_color "$RED" "✗ lab-application.service failed to start"
            echo "  Check: journalctl -u lab-application.service"
            ((failures++))
        fi
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

PROBLEM 1: Circular Dependency
═══════════════════════════════

Create the broken services:
────────────────────────────

Service A:
  sudo vi /etc/systemd/system/lab-circular-A.service

[Unit]
Description=Circular Dependency Test A
Requires=lab-circular-B.service
After=lab-circular-B.service

[Service]
Type=simple
ExecStart=/opt/lab-targets/circular-test.sh

[Install]
WantedBy=multi-user.target

Service B:
  sudo vi /etc/systemd/system/lab-circular-B.service

[Unit]
Description=Circular Dependency Test B
Requires=lab-circular-A.service
After=lab-circular-A.service

[Service]
Type=simple
ExecStart=/opt/lab-targets/circular-test.sh

[Install]
WantedBy=multi-user.target

Reload and try to start:
  sudo systemctl daemon-reload
  sudo systemctl start lab-circular-A.service

Error shows:
  Job for lab-circular-A.service failed because start of the service was attempted too often.
  Or: Found dependency on SERVICE/start

Diagnose with verify:
  systemd-analyze verify /etc/systemd/system/lab-circular-A.service
  systemd-analyze verify /etc/systemd/system/lab-circular-B.service

Output shows:
  Circular dependency detected

View dependency tree:
  systemctl list-dependencies lab-circular-A.service
  # Shows circular reference

Fix the issue:
──────────────

Option 1: Remove one Requires=
  Edit lab-circular-B.service
  Remove: Requires=lab-circular-A.service
  Keep: After=lab-circular-A.service

Option 2: Change Requires to Wants
  Edit lab-circular-B.service
  Change: Requires=lab-circular-A.service
  To: Wants=lab-circular-A.service

Option 3: Remove the dependency entirely
  If B doesn't really need A, remove both directives

Corrected service B:
[Unit]
Description=Circular Dependency Test B
Wants=lab-circular-A.service
After=lab-circular-A.service

[Service]
Type=simple
ExecStart=/opt/lab-targets/circular-test.sh

[Install]
WantedBy=multi-user.target

Reload and test:
  sudo systemctl daemon-reload
  sudo systemctl start lab-circular-A.service
  sudo systemctl start lab-circular-B.service
  systemctl status lab-circular-A.service lab-circular-B.service


PROBLEM 2: Service Timeout
═══════════════════════════

Create the broken service:
──────────────────────────

  sudo vi /etc/systemd/system/lab-slow-starter.service

[Unit]
Description=Slow Starting Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/lab-targets/slow-starter.sh
TimeoutStartSec=5s

[Install]
WantedBy=multi-user.target

Try to start:
  sudo systemctl daemon-reload
  sudo systemctl start lab-slow-starter.service

Wait... and it fails:

Check status:
  systemctl status lab-slow-starter.service

Output shows:
  Active: failed (Result: timeout)
  Main PID: ... (code=killed, signal=TERM)
  "start operation timed out. Terminating."

Check logs:
  journalctl -u lab-slow-starter.service -n 20

Shows:
  Started Slow Starting Service
  slow-starter.sh: Slow service starting...
  Stopping... (timeout)

Fix the issue:
──────────────

Edit the service:
  sudo systemctl edit lab-slow-starter.service

Add to override:
[Service]
TimeoutStartSec=60s

Or edit original file:
  sudo vi /etc/systemd/system/lab-slow-starter.service

Change:
  TimeoutStartSec=5s
To:
  TimeoutStartSec=60s

Reload and test:
  sudo systemctl daemon-reload
  sudo systemctl start lab-slow-starter.service
  # Wait 35+ seconds
  systemctl status lab-slow-starter.service
  # Should show: active (running)


PROBLEM 3: Missing Dependency
══════════════════════════════

This is already configured from Step 3:
  lab-application.service requires lab-database.service

Test the issue:
───────────────

Stop both services:
  sudo systemctl stop lab-application.service
  sudo systemctl stop lab-database.service

Try to start just the application:
  sudo systemctl start lab-application.service

What happens:
  lab-database.service starts automatically (Requires=)
  Both services start successfully

Now test dependency enforcement:
  sudo systemctl stop lab-database.service

Check application:
  systemctl status lab-application.service
  # Should also stop because of Requires=

Diagnose dependency issues:
───────────────────────────

If application fails to start:

Check status:
  systemctl status lab-application.service

Shows:
  Active: failed (Result: exit-code)
  Process: ... (code=exited, status=1)

Check logs:
  journalctl -u lab-application.service

Shows:
  ERROR: Database not available!

Check dependencies:
  systemctl list-dependencies lab-application.service

Verify database is running:
  systemctl is-active lab-database.service

Fix by ensuring proper configuration:
  Requires=lab-database.service  (hard dependency)
  After=lab-database.service     (ordering)

Start in correct order:
  sudo systemctl start lab-database.service
  sudo systemctl start lab-application.service


GENERAL TROUBLESHOOTING WORKFLOW
═════════════════════════════════

Step 1: Identify the problem
─────────────────────────────
  systemctl status SERVICE
  Look for:
    - failed state
    - exit code
    - last log lines

Step 2: Check detailed logs
────────────────────────────
  journalctl -u SERVICE -n 50
  journalctl -u SERVICE --since "10 minutes ago"
  journalctl -u SERVICE -f  (follow mode)

Step 3: Verify configuration
─────────────────────────────
  systemctl cat SERVICE
  systemd-analyze verify /etc/systemd/system/SERVICE.service

Step 4: Check dependencies
───────────────────────────
  systemctl list-dependencies SERVICE
  systemctl list-dependencies SERVICE --reverse

Step 5: Test components
────────────────────────
  Test script directly: /path/to/script.sh
  Check file permissions: ls -l /path/to/script.sh
  Verify paths exist: ls -l /path/in/unit/file

Step 6: Fix and retry
──────────────────────
  Edit unit file or script
  systemctl daemon-reload
  systemctl start SERVICE
  systemctl status SERVICE


COMMON SYSTEMD ERRORS AND FIXES
════════════════════════════════

Error: "Job for SERVICE failed because the control process exited with error code"
  Cause: Script/binary returned non-zero exit
  Check: journalctl -u SERVICE
  Fix: Debug the script itself

Error: "Failed to start SERVICE. Unit not found"
  Cause: Unit file doesn't exist or wrong name
  Check: ls /etc/systemd/system/SERVICE.service
  Fix: Create unit file or fix name

Error: "Start request repeated too quickly"
  Cause: Service crashes immediately and tries to restart
  Check: RestartSec= and StartLimitBurst=
  Fix: Fix crash, or increase restart delay

Error: "Circular dependency detected"
  Cause: Service A requires B, B requires A
  Check: systemd-analyze verify
  Fix: Change Requires to Wants, or remove dependency

Error: "Start operation timed out"
  Cause: Service took longer than TimeoutStartSec
  Check: How long does script take to start?
  Fix: Increase TimeoutStartSec or fix script

Error: "Failed to execute command: No such file"
  Cause: ExecStart path is wrong
  Check: ls -l /path/in/ExecStart
  Fix: Correct the path

Error: "Permission denied"
  Cause: Script not executable
  Check: ls -l /path/to/script
  Fix: chmod +x /path/to/script


ADVANCED DEBUGGING TECHNIQUES
══════════════════════════════

Increase log verbosity:
  systemd.log_level=debug on kernel command line
  Or: systemctl log-level debug

Run service in foreground:
  /path/to/script.sh
  Watch for errors directly

Check service environment:
  systemctl show SERVICE -p Environment

Test with explicit restart:
  systemctl restart SERVICE
  journalctl -u SERVICE -f
  Watch logs in real-time

Verify unit syntax:
  systemd-analyze verify SERVICE.service
  systemd-analyze dump SERVICE.service

Check for conflicts:
  systemctl list-dependencies --reverse SERVICE

View all properties:
  systemctl show SERVICE

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=8
    
    echo "Checking your systemd targets and troubleshooting work..."
    echo ""
    
    # CHECK 1: Custom target exists
    print_color "$CYAN" "[1/$total] Checking lab-custom.target..."
    if [ -f /etc/systemd/system/lab-custom.target ]; then
        print_color "$GREEN" "  ✓ Custom target created"
        ((score++))
    else
        print_color "$RED" "  ✗ lab-custom.target not found"
        print_color "$YELLOW" "  Create: /etc/systemd/system/lab-custom.target"
    fi
    echo ""
    
    # CHECK 2: Database service exists and configured
    print_color "$CYAN" "[2/$total] Checking lab-database.service..."
    if [ -f /etc/systemd/system/lab-database.service ]; then
        if grep -q "ExecStart=/opt/lab-targets/database-sim.sh" /etc/systemd/system/lab-database.service && \
           grep -q "WantedBy=lab-custom.target" /etc/systemd/system/lab-database.service; then
            print_color "$GREEN" "  ✓ Database service correctly configured"
            ((score++))
        else
            print_color "$RED" "  ✗ Database service exists but misconfigured"
        fi
    else
        print_color "$RED" "  ✗ lab-database.service not found"
    fi
    echo ""
    
    # CHECK 3: Application service with dependencies
    print_color "$CYAN" "[3/$total] Checking lab-application.service dependencies..."
    if [ -f /etc/systemd/system/lab-application.service ]; then
        if grep -q "Requires=lab-database.service" /etc/systemd/system/lab-application.service && \
           grep -q "After=lab-database.service" /etc/systemd/system/lab-application.service; then
            print_color "$GREEN" "  ✓ Application service has correct dependencies"
            ((score++))
        else
            print_color "$RED" "  ✗ Missing Requires= or After= for database"
        fi
    else
        print_color "$RED" "  ✗ lab-application.service not found"
    fi
    echo ""
    
    # CHECK 4: Network-dependent service
    print_color "$CYAN" "[4/$total] Checking lab-network-dependent.service..."
    if [ -f /etc/systemd/system/lab-network-dependent.service ]; then
        if grep -q "ExecStart=/opt/lab-targets/network-dependent.sh" /etc/systemd/system/lab-network-dependent.service; then
            print_color "$GREEN" "  ✓ Network-dependent service created"
            ((score++))
        else
            print_color "$RED" "  ✗ Network-dependent service misconfigured"
        fi
    else
        print_color "$RED" "  ✗ lab-network-dependent.service not found"
    fi
    echo ""
    
    # CHECK 5: Services are enabled
    print_color "$CYAN" "[5/$total] Checking service enablement..."
    local all_enabled=true
    if ! systemctl is-enabled lab-database.service >/dev/null 2>&1; then
        all_enabled=false
    fi
    if ! systemctl is-enabled lab-application.service >/dev/null 2>&1; then
        all_enabled=false
    fi
    if ! systemctl is-enabled lab-network-dependent.service >/dev/null 2>&1; then
        all_enabled=false
    fi
    
    if [ "$all_enabled" = true ]; then
        print_color "$GREEN" "  ✓ All services enabled"
        ((score++))
    else
        print_color "$RED" "  ✗ Not all services are enabled"
        print_color "$YELLOW" "  Enable with: systemctl enable SERVICE"
    fi
    echo ""
    
    # CHECK 6: Services can start successfully
    print_color "$CYAN" "[6/$total] Testing service startup..."
    systemctl stop lab-application.service lab-database.service lab-network-dependent.service 2>/dev/null || true
    sleep 1
    systemctl start lab-database.service 2>/dev/null
    sleep 2
    systemctl start lab-application.service 2>/dev/null
    sleep 2
    systemctl start lab-network-dependent.service 2>/dev/null
    sleep 2
    
    local all_running=true
    if ! systemctl is-active lab-database.service >/dev/null 2>&1; then
        all_running=false
        print_color "$RED" "  ✗ lab-database.service failed to start"
    fi
    if ! systemctl is-active lab-application.service >/dev/null 2>&1; then
        all_running=false
        print_color "$RED" "  ✗ lab-application.service failed to start"
    fi
    if ! systemctl is-active lab-network-dependent.service >/dev/null 2>&1; then
        all_running=false
        print_color "$RED" "  ✗ lab-network-dependent.service failed to start"
    fi
    
    if [ "$all_running" = true ]; then
        print_color "$GREEN" "  ✓ All services started successfully"
        ((score++))
    fi
    echo ""
    
    # CHECK 7: Slow starter service resolved
    print_color "$CYAN" "[7/$total] Checking lab-slow-starter.service..."
    if [ -f /etc/systemd/system/lab-slow-starter.service ]; then
        systemctl stop lab-slow-starter.service 2>/dev/null || true
        systemctl start lab-slow-starter.service 2>/dev/null
        sleep 5
        
        if systemctl is-active lab-slow-starter.service >/dev/null 2>&1; then
            print_color "$GREEN" "  ✓ Slow starter service configured and running"
            ((score++))
        else
            print_color "$RED" "  ✗ Slow starter fails to start (check TimeoutStartSec)"
        fi
    else
        print_color "$RED" "  ✗ lab-slow-starter.service not created"
    fi
    echo ""
    
    # CHECK 8: Circular dependency resolved
    print_color "$CYAN" "[8/$total] Checking circular dependency resolution..."
    if [ -f /etc/systemd/system/lab-circular-A.service ]; then
        systemctl stop lab-circular-A.service lab-circular-B.service 2>/dev/null || true
        if systemctl start lab-circular-A.service 2>/dev/null; then
            sleep 2
            if systemctl is-active lab-circular-A.service >/dev/null 2>&1; then
                print_color "$GREEN" "  ✓ Circular dependency resolved"
                ((score++))
            else
                print_color "$RED" "  ✗ Service created but won't start"
            fi
        else
            print_color "$RED" "  ✗ Circular dependency still present"
        fi
    else
        print_color "$YELLOW" "  ⚠ Circular test services not created (optional)"
        # Give credit anyway since it's troubleshooting practice
        ((score++))
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Outstanding work! You've mastered advanced systemd concepts:"
        echo "  • Understanding systemd targets and their relationships"
        echo "  • Changing targets temporarily and permanently"
        echo "  • Creating custom targets with complex dependencies"
        echo "  • Analyzing boot performance with systemd-analyze"
        echo "  • Troubleshooting circular dependencies and timeouts"
        echo "  • Diagnosing and fixing service failures"
        echo ""
        echo "You're well-prepared for RHCSA systemd objectives!"
    elif [ $score -ge 6 ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED (Strong Understanding)"
        echo ""
        echo "Very good work! You've demonstrated strong systemd skills."
        echo "Review the areas marked incomplete to further strengthen your knowledge."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "This is challenging material. Review the feedback and try again."
        echo "Use --interactive mode for step-by-step guidance."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -ge 6 ]  # Pass with 6/8 or better
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

See the detailed solutions in each step's solution output.
Use: ./lab-runner.sh labs/m04/15C-systemd-targets-troubleshooting.sh --solution

Key commands summary:

TARGETS:
  systemctl get-default
  systemctl set-default TARGET
  systemctl isolate TARGET
  systemctl list-dependencies TARGET

ANALYSIS:
  systemd-analyze time
  systemd-analyze blame
  systemd-analyze critical-chain
  systemd-analyze verify SERVICE.service

TROUBLESHOOTING:
  systemctl status SERVICE
  journalctl -u SERVICE
  systemctl list-dependencies SERVICE
  systemd-analyze verify SERVICE.service

EXAM TIPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical skills for RHCSA:

1. Change default target:
   systemctl set-default multi-user.target

2. Switch target without reboot:
   systemctl isolate rescue.target

3. Create custom service with dependencies:
   Requires= for hard deps
   Wants= for soft deps
   After= for ordering

4. Troubleshoot failed services:
   systemctl status SERVICE
   journalctl -u SERVICE
   systemd-analyze verify

5. Understand boot process:
   systemd-analyze critical-chain
   Know: sysinit → basic → multi-user → graphical

6. Fix circular dependencies:
   Change Requires= to Wants=
   Or remove unnecessary dependency

7. Fix timeout issues:
   Increase TimeoutStartSec=
   Or fix slow script

Remember:
  • Targets group services
  • set-default changes boot
  • isolate changes now
  • Requires= is hard, Wants= is soft
  • Always daemon-reload after changes

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Stop and disable all lab services
    systemctl stop lab-network-dependent.service 2>/dev/null || true
    systemctl stop lab-database.service 2>/dev/null || true
    systemctl stop lab-application.service 2>/dev/null || true
    systemctl stop lab-circular-A.service 2>/dev/null || true
    systemctl stop lab-circular-B.service 2>/dev/null || true
    systemctl stop lab-slow-starter.service 2>/dev/null || true
    
    systemctl disable lab-network-dependent.service 2>/dev/null || true
    systemctl disable lab-database.service 2>/dev/null || true
    systemctl disable lab-application.service 2>/dev/null || true
    systemctl disable lab-circular-A.service 2>/dev/null || true
    systemctl disable lab-circular-B.service 2>/dev/null || true
    systemctl disable lab-slow-starter.service 2>/dev/null || true
    
    # Remove unit files
    rm -f /etc/systemd/system/lab-network-dependent.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-database.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-application.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-circular-A.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-circular-B.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-slow-starter.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab-custom.target 2>/dev/null || true
    
    # Remove target.wants directories
    rm -rf /etc/systemd/system/lab-custom.target.wants 2>/dev/null || true
    
    # Remove lab scripts and data
    rm -rf /opt/lab-targets 2>/dev/null || true
    rm -rf /var/lib/lab-db 2>/dev/null || true
    
    # Restore default target if changed
    systemctl set-default multi-user.target 2>/dev/null || true
    
    systemctl daemon-reload
    
    echo "  ✓ All lab services stopped and disabled"
    echo "  ✓ Unit files removed"
    echo "  ✓ Lab scripts and data removed"
    echo "  ✓ Default target restored"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
