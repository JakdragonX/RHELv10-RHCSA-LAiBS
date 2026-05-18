#!/bin/bash
# labs/28A-firewall.sh
# Lab: Firewall Configuration — ss, firewall-cmd, services and ports
# Difficulty: Intermediate
# RHCSA Objective: Manage firewall settings using firewall-cmd

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Firewall Configuration with firewall-cmd and ss"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Ensure firewalld is running
    systemctl enable --now firewalld 2>/dev/null || true

    # Remove any previous lab rules to start clean
    firewall-cmd --remove-service=http --permanent 2>/dev/null || true
    firewall-cmd --remove-port=8080/tcp --permanent 2>/dev/null || true
    firewall-cmd --remove-port=9090/tcp --permanent 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true

    echo "  ✓ firewalld is running"
    echo "  ✓ Previous lab firewall rules cleared"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • That a firewall controls which network traffic is allowed in and out
  • Basic networking: ports, protocols (TCP/UDP), IP addresses
  • systemctl for managing the firewalld service

The Firewall Stack on RHEL:
  Application code
       ↓
  firewall-cmd     ← the tool you use (CLI)
  firewall-config  ← graphical alternative (available on exam with GUI)
       ↓
  firewalld        ← the daemon that manages rules
       ↓
  nftables         ← the kernel framework that actually filters packets
       ↓
  netfilter        ← kernel subsystem

  You interact with firewall-cmd. It writes to firewalld. You never touch
  nftables or netfilter directly for standard firewall tasks.

Key Concept — Runtime vs Persistent:
  firewall-cmd --add-service=http          → runtime only (lost on reload/reboot)
  firewall-cmd --add-service=http --permanent → persistent only (needs reload)
  Exam workflow: add --permanent, then --reload to apply to both.
  Or: add without --permanent (takes effect now), then add --permanent too.

Commands You'll Use:
  • ss -tulpn              - Show listening sockets with process names
  • firewall-cmd --list-all        - Show current zone rules
  • firewall-cmd --add-service=    - Allow a named service
  • firewall-cmd --add-port=       - Allow a specific port/protocol
  • firewall-cmd --remove-service= - Remove a service rule
  • firewall-cmd --permanent       - Write to persistent config
  • firewall-cmd --reload          - Apply persistent rules to runtime
  • firewall-cmd --list-services   - List currently allowed services
  • firewall-cmd --list-ports      - List currently allowed ports

NOTE on firewall-config:
  On RHEL exam environments that include a GUI, firewall-config provides
  a graphical interface to the same firewalld rules. Everything you do
  in firewall-config is equivalent to firewall-cmd --permanent commands.
  The CLI is faster and is what this lab focuses on, but knowing
  firewall-config exists is useful if you prefer a visual view.

Files You'll Interact With:
  • /usr/lib/firewalld/services/   - Built-in service definitions (read-only)
  • /etc/firewalld/services/       - Custom service definitions
  • /etc/firewalld/zones/          - Persistent zone configurations
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A RHEL server needs its firewall configured to allow web traffic and a
custom application port. First you'll inspect what is currently listening
on the system, then open the required services and ports in firewalld.

OBJECTIVES:
  1. Use ss -tulpn to list all listening TCP and UDP ports on the system.
     Identify which process is listening on port 22 (sshd). Note the
     format of the output: local address, port, process name.

  2. Check the current firewall state with firewall-cmd --list-all.
     Note which zone is active (likely 'public') and what services are
     currently allowed. Then add the 'http' service permanently and reload
     the firewall. Verify http appears in the active rules.

  3. Open port 8080/tcp permanently using --add-port. Reload and verify
     the port appears in firewall-cmd --list-ports.

  4. Remove the http service rule you added in step 2. Verify it is gone.
     This demonstrates the remove workflow you'll need when cleaning up
     or correcting rules on the exam.

HINTS:
  • ss -tulpn: t=TCP u=UDP l=listening p=process n=numeric (no hostname resolution)
  • Always pair --permanent changes with firewall-cmd --reload
  • firewall-cmd --list-all shows the complete picture for the active zone
  • firewall-cmd --get-active-zones shows which zone is in use
  • Built-in service definitions live in /usr/lib/firewalld/services/*.xml

SUCCESS CRITERIA:
  • port 8080/tcp is permanently allowed in firewalld
  • http service is NOT in the allowed list (removed in step 4)
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. ss -tulpn — list listening ports; identify sshd on port 22
  ☐ 2. firewall-cmd --list-all; add http service permanently; reload; verify
  ☐ 3. firewall-cmd --add-port=8080/tcp --permanent; reload; verify
  ☐ 4. firewall-cmd --remove-service=http --permanent; reload; verify it's gone
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "4"
}

scenario_context() {
    cat << 'EOF'
A server needs its firewall configured for web traffic and a custom port.
You will inspect listening sockets, allow services and ports, then practice
removing rules — all using firewall-cmd.
EOF
}

# STEP 1: ss socket inspection
show_step_1() {
    cat << 'EOF'
CONCEPT: ss — Socket Statistics
────────────────────────────────
ss is the modern replacement for netstat. It shows network socket state
directly from the kernel. The flags you need most:

  ss -tulpn
    t = TCP sockets
    u = UDP sockets
    l = listening sockets only (servers waiting for connections)
    p = show process name/PID
    n = numeric output (don't resolve port names or hostnames)

Output columns:
  Netid  State   Recv-Q  Send-Q  Local Address:Port   Peer Address:Port  Process
  tcp    LISTEN  0       128     0.0.0.0:22            0.0.0.0:*          sshd

  Local Address:Port: what this socket is bound to
    0.0.0.0:22   = listening on ALL interfaces, port 22
    127.0.0.1:22 = listening on loopback only
    :::22         = IPv6 equivalent of 0.0.0.0

────────────────────────────────
TASK: Inspect listening ports with ss

Requirements:
  • Run ss -tulpn and read the output
  • Identify which process owns port 22
  • Note any other services that are listening

Commands you might need:
  • ss -tulpn
  • ss -tulpn | grep :22
  • ss -tlnp   (TCP only, slightly less output)
EOF
}

validate_step_1() {
    # Verify ss works and sshd is listening
    if ! ss -tulpn 2>/dev/null | grep -q ":22"; then
        echo ""
        print_color "$RED" "✗ No process found listening on port 22 — is sshd running?"
        return 1
    fi
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
ss -tulpn
ss -tulpn | grep :22
# → tcp  LISTEN  0  128  0.0.0.0:22  0.0.0.0:*  users:(("sshd",pid=XXX,fd=3))

The process field shows: users:(("sshd",pid=1234,fd=3))
  sshd = process name
  pid  = process ID
  fd   = file descriptor number

One thing to remember:
  ss -tulpn is your first diagnostic tool when troubleshooting whether a
  service is listening at all, before even looking at the firewall. The
  firewall only matters if the service IS listening but connections from
  outside are blocked.

  Diagnostic flow:
  1. Is the service listening?    ss -tulpn | grep PORT
  2. Is the firewall allowing it? firewall-cmd --list-all
  3. Is SELinux blocking it?      grep AVC /var/log/audit/audit.log

EOF
}

hint_step_2() {
    echo "  firewall-cmd --list-all"
    echo "  firewall-cmd --add-service=http --permanent"
    echo "  firewall-cmd --reload"
    echo "  firewall-cmd --list-services"
}

# STEP 2: Allow a service
show_step_2() {
    cat << 'EOF'
CONCEPT: firewall-cmd — Services and the --permanent Flag
──────────────────────────────────────────────────────────
A firewalld "service" is a named collection of ports defined in an XML
file. Using service names is cleaner than raw ports because the name is
self-documenting and the XML can include multiple ports at once.

The critical --permanent distinction:
  Without --permanent: change is live NOW but lost after reload/reboot
  With --permanent:    change is saved to disk but NOT live until reload

Exam-safe workflow (apply to both runtime and persistent):
  firewall-cmd --add-service=http --permanent
  firewall-cmd --reload

Inspection commands:
  firewall-cmd --list-all        everything in the active zone
  firewall-cmd --list-services   just the services
  firewall-cmd --get-active-zones  which zone applies to which interface
  firewall-cmd --get-services    all available named services

──────────────────────────────────────────────────────
TASK: Add the http service to the firewall

Requirements:
  • Run firewall-cmd --list-all to see the current state
  • Add the http service permanently
  • Reload the firewall
  • Verify http appears in: firewall-cmd --list-services

Commands you might need:
  • firewall-cmd --list-all
  • firewall-cmd --add-service=http --permanent
  • firewall-cmd --reload
  • firewall-cmd --list-services
EOF
}

validate_step_2() {
    # Check http is in permanent config
    if firewall-cmd --list-services --permanent 2>/dev/null | grep -qw "http"; then
        return 0
    fi
    # Also check runtime in case they added without --permanent
    if firewall-cmd --list-services 2>/dev/null | grep -qw "http"; then
        echo ""
        print_color "$YELLOW" "  ⚠ http is in runtime rules but may not be in permanent config"
        echo "  Run: firewall-cmd --add-service=http --permanent && firewall-cmd --reload"
        return 1
    fi
    echo ""
    print_color "$RED" "✗ http service is not allowed in firewalld"
    echo "  Fix: firewall-cmd --add-service=http --permanent && firewall-cmd --reload"
    return 1
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
firewall-cmd --list-all                    # see current state
firewall-cmd --add-service=http --permanent
firewall-cmd --reload
firewall-cmd --list-services               # verify: http appears

What --reload actually does:
  It discards the current runtime rules and rebuilds them from the
  permanent configuration. Any runtime-only changes (added without
  --permanent) are lost. This is why you must use --permanent for
  anything you want to survive a reload or reboot.

To inspect the http service XML definition:
  cat /usr/lib/firewalld/services/http.xml
  # → shows it allows port 80/tcp

To create a custom service:
  Copy an existing XML to /etc/firewalld/services/myservice.xml and edit it.
  Files in /etc/firewalld/ override /usr/lib/firewalld/ for the same name.

EOF
}

hint_step_3() {
    echo "  firewall-cmd --add-port=8080/tcp --permanent"
    echo "  firewall-cmd --reload"
    echo "  firewall-cmd --list-ports"
}

# STEP 3: Allow a port
show_step_3() {
    cat << 'EOF'
CONCEPT: Allowing Raw Ports
────────────────────────────
When no named service exists for your port, use --add-port:
  firewall-cmd --add-port=8080/tcp --permanent
  firewall-cmd --reload

Port syntax: NUMBER/PROTOCOL where protocol is tcp or udp.
  8080/tcp   single TCP port
  8080-8090/tcp  port range
  53/udp     UDP port

You can verify with:
  firewall-cmd --list-ports        (runtime)
  firewall-cmd --list-ports --permanent  (persistent)

────────────────────────────────────────
TASK: Open port 8080/tcp permanently

Requirements:
  • Add 8080/tcp permanently with firewall-cmd
  • Reload to apply
  • Verify with firewall-cmd --list-ports

Commands you might need:
  • firewall-cmd --add-port=8080/tcp --permanent
  • firewall-cmd --reload
  • firewall-cmd --list-ports
  • firewall-cmd --list-all
EOF
}

validate_step_3() {
    if firewall-cmd --list-ports --permanent 2>/dev/null | grep -q "8080/tcp"; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ Port 8080/tcp is not permanently allowed"
    echo "  Fix: firewall-cmd --add-port=8080/tcp --permanent && firewall-cmd --reload"
    return 1
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-ports
# → 8080/tcp

firewall-cmd --list-all
# Shows ports: 8080/tcp in the zone summary

One thing to remember:
  Prefer services over raw ports when possible. A port entry in the
  firewall tells you nothing about WHY it's open. A service name like
  "http" or "cockpit" is self-documenting. If you repeatedly open the
  same port on multiple systems, create a custom service XML and use
  --add-service instead.

  To check what port a named service uses before adding it:
    firewall-cmd --info-service=http
    # → ports: 80/tcp

EOF
}

hint_step_4() {
    echo "  firewall-cmd --remove-service=http --permanent"
    echo "  firewall-cmd --reload"
    echo "  firewall-cmd --list-services   (http should be gone)"
}

# STEP 4: Remove a rule
show_step_4() {
    cat << 'EOF'
CONCEPT: Removing Firewall Rules
──────────────────────────────────
--remove-service and --remove-port are the mirror of --add-service and --add-port:

  firewall-cmd --remove-service=http --permanent
  firewall-cmd --reload

The same --permanent + --reload pattern applies. Without --permanent,
you only remove it from runtime — it comes back on reload. Without
--reload, the change doesn't take effect in the running firewall.

──────────────────────────────────────────────────
TASK: Remove the http service rule you added in step 2

Requirements:
  • Remove http from the permanent firewall config
  • Reload to apply
  • Verify with firewall-cmd --list-services that http is gone
  • Confirm 8080/tcp is still there (you should only have removed http)

Commands you might need:
  • firewall-cmd --remove-service=http --permanent
  • firewall-cmd --reload
  • firewall-cmd --list-services
  • firewall-cmd --list-all
EOF
}

validate_step_4() {
    # http should be gone
    if firewall-cmd --list-services --permanent 2>/dev/null | grep -qw "http"; then
        echo ""
        print_color "$RED" "✗ http service is still in the permanent firewall config"
        echo "  Fix: firewall-cmd --remove-service=http --permanent && firewall-cmd --reload"
        return 1
    fi
    # 8080 should still be there
    if ! firewall-cmd --list-ports --permanent 2>/dev/null | grep -q "8080/tcp"; then
        echo ""
        print_color "$RED" "✗ Port 8080/tcp was also removed (it should still be there)"
        echo "  Fix: firewall-cmd --add-port=8080/tcp --permanent && firewall-cmd --reload"
        return 1
    fi
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
firewall-cmd --remove-service=http --permanent
firewall-cmd --reload
firewall-cmd --list-services   # http should not appear
firewall-cmd --list-ports      # 8080/tcp should still appear

One thing to remember:
  --remove only affects what you specify. Removing http does not touch
  the 8080/tcp port rule — each rule is independent.

Full rule audit after any changes:
  firewall-cmd --list-all        (runtime state)
  firewall-cmd --list-all --permanent  (what survives a reload)

  If these two differ, you have runtime-only changes that will be lost.
  The exam grader typically reboots — always ensure --permanent is used.

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=2

    echo "Checking your firewall configuration..."
    echo ""

    print_color "$CYAN" "[1/$total] Checking port 8080/tcp is permanently allowed..."
    if firewall-cmd --list-ports --permanent 2>/dev/null | grep -q "8080/tcp"; then
        print_color "$GREEN" "  ✓ Port 8080/tcp is permanently allowed"
        ((score++))
    else
        print_color "$RED" "  ✗ Port 8080/tcp is not in permanent firewall config"
        print_color "$YELLOW" "  Fix: firewall-cmd --add-port=8080/tcp --permanent && firewall-cmd --reload"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking http service is NOT in permanent config (was removed)..."
    if ! firewall-cmd --list-services --permanent 2>/dev/null | grep -qw "http"; then
        print_color "$GREEN" "  ✓ http service correctly removed from permanent config"
        ((score++))
    else
        print_color "$RED" "  ✗ http service is still in permanent config (should have been removed)"
        print_color "$YELLOW" "  Fix: firewall-cmd --remove-service=http --permanent && firewall-cmd --reload"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Firewall correctly configured."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above. Run with --solution for detailed steps."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — Inspect listening sockets:
  ss -tulpn
  ss -tulpn | grep :22    # → sshd

STEP 2 — Allow http service:
  firewall-cmd --list-all
  firewall-cmd --add-service=http --permanent
  firewall-cmd --reload
  firewall-cmd --list-services   # → http appears

STEP 3 — Open port 8080/tcp:
  firewall-cmd --add-port=8080/tcp --permanent
  firewall-cmd --reload
  firewall-cmd --list-ports      # → 8080/tcp

STEP 4 — Remove http service:
  firewall-cmd --remove-service=http --permanent
  firewall-cmd --reload
  firewall-cmd --list-services   # → http gone, 8080/tcp still there


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always --permanent + --reload. The exam grader reboots the VM.
2. firewall-cmd --list-all is your verification command after every change
3. ss -tulpn before touching the firewall — confirm the service is listening
4. Services: named, from XML; Ports: raw number/protocol. Prefer services.
5. firewall-cmd --get-services lists all available service names you can use
6. Zones: 'public' is the default; interfaces are assigned to zones.
   For the exam, you almost always work in the default zone (public).

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    firewall-cmd --remove-service=http --permanent 2>/dev/null || true
    firewall-cmd --remove-port=8080/tcp --permanent 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true

    echo "  ✓ Lab firewall rules removed"
}

main "$@"
