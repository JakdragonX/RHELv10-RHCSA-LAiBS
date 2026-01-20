#!/bin/bash
# labs/m03/11C-nmcli-nmtui-troubleshooting.sh
# Lab: Exploring nmcli, nmtui, and network troubleshooting
# Difficulty: Intermediate
# RHCSA Objective: 11.6, 11.7, 11.8, 11.9 - NetworkManager and troubleshooting

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Exploring nmcli, nmtui, and network troubleshooting"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Backup NetworkManager connections
    mkdir -p /tmp/network-config-backup 2>/dev/null || true
    
    if [ -d /etc/NetworkManager/system-connections ]; then
        cp -r /etc/NetworkManager/system-connections/* /tmp/network-config-backup/ 2>/dev/null || true
    fi
    
    # Create working directory
    mkdir -p /tmp/nmcli-lab 2>/dev/null || true
    
    echo "  ✓ Backed up NetworkManager connections"
    echo "  ✓ Lab environment ready"
    echo ""
    echo "  NOTE: This lab explores NetworkManager commands"
    echo "  Changes made will be documented but not activated to avoid network disruption"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of IP networking basics
  • Familiarity with network interfaces
  • Basic understanding of DHCP and static IP configuration

Commands You'll Use:
  • nmcli - NetworkManager command-line tool
  • nmtui - NetworkManager text user interface
  • ip - Network interface configuration
  • ping - Test connectivity
  • ss - Socket statistics

Files You'll Interact With:
  • /etc/NetworkManager/system-connections/ - Connection profiles
  • /etc/sysconfig/network-scripts/ - Legacy network scripts (deprecated)
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You are a system administrator learning to manage network configuration using
NetworkManager tools. You need to understand how to view connections, examine
device status, and use both command-line and text-based interfaces for network
management. You will also practice basic network troubleshooting techniques.

BACKGROUND:
NetworkManager is the standard network configuration service on RHEL. It manages
network devices and connections through multiple interfaces including nmcli
(command-line) and nmtui (text UI). Understanding these tools is essential for
the RHCSA exam and real-world system administration.

OBJECTIVES:
  1. Explore nmcli to view network configuration
     • List all connections: nmcli con show
     • List all devices: nmcli dev status
     • View detailed connection info for primary connection
     • Save connection list to /tmp/nmcli-lab/connections.txt
     • Save device status to /tmp/nmcli-lab/devices.txt

  2. Examine connection properties with nmcli
     • Find your primary connection name
     • View all settings: nmcli con show CONNECTION_NAME
     • Identify IPv4 configuration method (dhcp or manual)
     • Document IP address, gateway, and DNS settings
     • Save to /tmp/nmcli-lab/connection-details.txt

  3. Explore nmtui interface
     • Launch nmtui (text-based interface)
     • Navigate through the menu options
     • View "Edit a connection" (DO NOT MAKE CHANGES)
     • View "Activate a connection"
     • Document observations in /tmp/nmcli-lab/nmtui-notes.txt

  4. Practice network troubleshooting workflow
     • Verify interface is up: ip link show
     • Check IP address: ip addr show
     • Test local connectivity: ping -c 2 127.0.0.1
     • Test gateway: ping -c 2 GATEWAY_IP
     • Test external: ping -c 2 8.8.8.8
     • Check DNS: ping -c 2 google.com
     • Document results in /tmp/nmcli-lab/troubleshooting.txt

  5. Examine NetworkManager permissions
     • Check current permissions: nmcli gen permissions
     • Understand dbus authentication
     • View NetworkManager status: systemctl status NetworkManager
     • Save status to /tmp/nmcli-lab/nm-status.txt

HINTS:
  • nmcli uses tab completion for convenience
  • nmcli con show lists connections
  • nmcli dev status shows device states
  • nmtui is menu-driven, use arrows and Enter
  • Troubleshooting follows: physical -> IP -> gateway -> DNS
  • NetworkManager is a systemd service

SUCCESS CRITERIA:
  • All nmcli output files created in /tmp/nmcli-lab/
  • Connection and device information documented
  • nmtui interface explored and documented
  • Troubleshooting workflow completed
  • NetworkManager status verified
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Use nmcli to view connections and devices
  ☐ 2. Examine connection properties with nmcli con show
  ☐ 3. Explore nmtui text interface (observation only)
  ☐ 4. Practice network troubleshooting workflow
  ☐ 5. Check NetworkManager permissions and status
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
You are learning NetworkManager tools (nmcli and nmtui) and practicing network
troubleshooting techniques.

Output directory: /tmp/nmcli-lab/

NOTE: This is an exploration lab. You will view and document existing
configuration without making disruptive changes.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore nmcli to view network configuration

nmcli is the primary command-line tool for NetworkManager. It allows you to
view and manage network connections and devices.

Requirements:
  • List connections: nmcli con show
  • List devices: nmcli dev status
  • Save connections: nmcli con show > /tmp/nmcli-lab/connections.txt
  • Save devices: nmcli dev status > /tmp/nmcli-lab/devices.txt

Commands you might need:
  • nmcli con show - List all connections
  • nmcli dev status - List all network devices
  • nmcli - Shows general status
  • nmcli help - Show help information
EOF
}

validate_step_1() {
    if [ ! -f /tmp/nmcli-lab/connections.txt ]; then
        echo ""
        print_color "$RED" "✗ connections.txt not found"
        echo "  Try: nmcli con show > /tmp/nmcli-lab/connections.txt"
        return 1
    fi
    
    if [ ! -f /tmp/nmcli-lab/devices.txt ]; then
        echo ""
        print_color "$RED" "✗ devices.txt not found"
        echo "  Try: nmcli dev status > /tmp/nmcli-lab/devices.txt"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  nmcli
  nmcli con show
  nmcli dev status
  nmcli con show > /tmp/nmcli-lab/connections.txt
  nmcli dev status > /tmp/nmcli-lab/devices.txt

Explanation:
  • nmcli: NetworkManager command-line interface
  • con show: Show all connections (profiles)
  • dev status: Show all devices and their state

nmcli con show output:
  NAME    UUID                                  TYPE      DEVICE
  ens160  abc-123-def-456                       ethernet  ens160

Fields:
  • NAME: Connection profile name
  • UUID: Unique identifier
  • TYPE: Connection type (ethernet, wifi, etc)
  • DEVICE: Associated network device

nmcli dev status output:
  DEVICE  TYPE      STATE      CONNECTION
  ens160  ethernet  connected  ens160
  lo      loopback  unmanaged  --

Fields:
  • DEVICE: Network interface name
  • TYPE: Device type
  • STATE: Current state (connected, disconnected, unavailable)
  • CONNECTION: Active connection profile

Device states:
  • connected: Device is up with active connection
  • disconnected: Device is up but no connection
  • unavailable: Device is not available
  • unmanaged: Not managed by NetworkManager

Verification:
  cat /tmp/nmcli-lab/connections.txt
  cat /tmp/nmcli-lab/devices.txt

EOF
}

hint_step_2() {
    echo "  Find connection name: nmcli con show"
    echo "  View details: nmcli con show CONNECTION_NAME"
    echo "  Save: nmcli con show CONNECTION_NAME > /tmp/nmcli-lab/connection-details.txt"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Examine connection properties with nmcli

View detailed configuration of your primary network connection to understand
how NetworkManager stores network settings.

Requirements:
  • Find your primary connection name from connections.txt
  • View all settings: nmcli con show CONNECTION_NAME
  • Identify IPv4 method, address, gateway, DNS
  • Save output: nmcli con show NAME > /tmp/nmcli-lab/connection-details.txt

Commands you might need:
  • nmcli con show CONNECTION_NAME - Show all connection properties
  • nmcli con show CONNECTION_NAME | grep ipv4 - Filter IPv4 settings
  • nmcli -f ipv4 con show CONNECTION_NAME - Show only IPv4 fields
EOF
}

validate_step_2() {
    if [ ! -f /tmp/nmcli-lab/connection-details.txt ]; then
        echo ""
        print_color "$RED" "✗ connection-details.txt not found"
        echo "  Try: nmcli con show CONNECTION_NAME > /tmp/nmcli-lab/connection-details.txt"
        return 1
    fi
    
    if ! grep -q "ipv4" /tmp/nmcli-lab/connection-details.txt 2>/dev/null; then
        echo ""
        print_color "$YELLOW" "  Warning: File may not contain connection details"
        echo "  Make sure you used: nmcli con show CONNECTION_NAME"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  # First, find your connection name
  nmcli con show
  
  # Then show details (replace "ens160" with your connection name)
  nmcli con show ens160
  nmcli con show ens160 > /tmp/nmcli-lab/connection-details.txt
  
  # Filter for IPv4 settings
  nmcli con show ens160 | grep ipv4

Explanation:
  nmcli con show CONNECTION_NAME displays ALL properties
  for a connection profile, including:
  • General settings
  • IPv4 configuration
  • IPv6 configuration
  • Connection settings
  • Device settings

Key IPv4 properties to look for:
  ipv4.method: auto (DHCP) or manual (static)
  ipv4.addresses: IP address and subnet
  ipv4.gateway: Default gateway
  ipv4.dns: DNS servers

Sample output:
  ipv4.method:                auto
  ipv4.dns:                   8.8.8.8,8.8.4.4
  ipv4.gateway:               192.168.1.1
  ipv4.addresses:             192.168.1.100/24
  
  OR for DHCP:
  ipv4.method:                auto
  ipv4.dns:                   --
  ipv4.gateway:               --
  IP4.ADDRESS[1]:             192.168.1.100/24
  IP4.GATEWAY:                192.168.1.1
  IP4.DNS[1]:                 192.168.1.1

Understanding the difference:
  • Lowercase (ipv4.method): Configuration setting
  • Uppercase (IP4.ADDRESS): Active runtime value
  
  Configured vs Active:
  • ipv4.addresses: What you configured
  • IP4.ADDRESS: What is currently active
  • May differ if using DHCP

Verification:
  cat /tmp/nmcli-lab/connection-details.txt | grep ipv4
  cat /tmp/nmcli-lab/connection-details.txt | grep IP4

EOF
}

hint_step_3() {
    echo "  Launch: nmtui"
    echo "  Navigate with arrow keys and Enter"
    echo "  Press ESC or select Quit to exit"
    echo "  Document what you see in /tmp/nmcli-lab/nmtui-notes.txt"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Explore nmtui interface

nmtui is a text-based user interface for NetworkManager. It provides a
menu-driven alternative to nmcli commands.

Requirements:
  • Launch nmtui
  • Navigate the main menu
  • Explore "Edit a connection" (DO NOT MODIFY)
  • Explore "Activate a connection"
  • Exit nmtui
  • Document observations in /tmp/nmcli-lab/nmtui-notes.txt

Commands you might need:
  • nmtui - Launch NetworkManager TUI
  • Arrow keys - Navigate menus
  • Enter - Select option
  • ESC - Go back or cancel
  • Tab - Move between fields

IMPORTANT: Only observe the interface, do not make changes
EOF
}

validate_step_3() {
    if [ ! -f /tmp/nmcli-lab/nmtui-notes.txt ]; then
        echo ""
        print_color "$RED" "✗ nmtui-notes.txt not found"
        echo "  Create file documenting your nmtui observations"
        return 1
    fi
    
    if [ ! -s /tmp/nmcli-lab/nmtui-notes.txt ]; then
        echo ""
        print_color "$RED" "✗ nmtui-notes.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  nmtui

Navigation:
  • Use Arrow keys to move
  • Enter to select
  • Tab to move between fields
  • ESC to go back
  • Select Quit to exit

Create documentation:
  cat > /tmp/nmcli-lab/nmtui-notes.txt << 'ENDFILE'
  NMTUI EXPLORATION NOTES
  
  Main Menu Options:
  1. Edit a connection
     - Shows list of existing connections
     - Can view connection settings
     - Organized by connection type
     - Shows device assignments
  
  2. Activate a connection
     - Lists available connections
     - Shows which are currently active
     - Can activate/deactivate connections
     - Useful for switching networks
  
  3. Set system hostname
     - Simple interface to change hostname
     - Alternative to hostnamectl
  
  Interface observations:
  - Menu-driven, user-friendly
  - Good for quick configuration changes
  - Safer than editing files directly
  - Less powerful than nmcli for scripting
  - Requires console or SSH access
  
  Use cases:
  - Quick configuration on servers
  - When you forget nmcli syntax
  - Testing connection changes
  - Initial network setup
ENDFILE

Explanation:
  nmtui provides three main functions:
  
  1. Edit a connection:
     • Modify existing connections
     • Create new connections
     • Configure IP, DNS, gateway
     • Set connection properties
  
  2. Activate a connection:
     • Turn connections on/off
     • Switch between profiles
     • Useful for laptop users
  
  3. Set system hostname:
     • Simple hostname configuration
     • Same as hostnamectl

When to use nmtui:
  • Quick interactive changes
  • Don't remember nmcli syntax
  • Prefer menu-driven interface
  • Not automating with scripts

When to use nmcli:
  • Scripting network configuration
  • Remote management
  • Need detailed output
  • Automating tasks

Verification:
  cat /tmp/nmcli-lab/nmtui-notes.txt

EOF
}

hint_step_4() {
    echo "  Check interface: ip link show"
    echo "  Check address: ip addr show"
    echo "  Test localhost: ping -c 2 127.0.0.1"
    echo "  Test gateway: ping -c 2 GATEWAY_IP"
    echo "  Test external: ping -c 2 8.8.8.8"
    echo "  Test DNS: ping -c 2 google.com"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Practice network troubleshooting workflow

Follow a systematic troubleshooting workflow to verify network connectivity
at each layer. This is the approach to use when diagnosing network issues.

Requirements:
  • Verify interface is UP: ip link show
  • Verify IP address assigned: ip addr show
  • Test loopback: ping -c 2 127.0.0.1
  • Test gateway: ping -c 2 GATEWAY_IP (find from ip route)
  • Test external IP: ping -c 2 8.8.8.8
  • Test DNS resolution: ping -c 2 google.com
  • Document all results in /tmp/nmcli-lab/troubleshooting.txt

Commands you might need:
  • ip link show - Check interface state
  • ip addr show - Check IP configuration
  • ip route show - Find gateway
  • ping -c 2 HOST - Test connectivity (2 packets)
  • ss -tln - Check listening services
EOF
}

validate_step_4() {
    if [ ! -f /tmp/nmcli-lab/troubleshooting.txt ]; then
        echo ""
        print_color "$RED" "✗ troubleshooting.txt not found"
        echo "  Document your troubleshooting workflow results"
        return 1
    fi
    
    if [ ! -s /tmp/nmcli-lab/troubleshooting.txt ]; then
        echo ""
        print_color "$RED" "✗ troubleshooting.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Systematic troubleshooting workflow:

Step 1: Check physical layer (interface state)
  ip link show
  # Look for: UP,LOWER_UP in interface flags
  # If DOWN: Interface is disabled or cable unplugged

Step 2: Check IP configuration
  ip addr show
  # Verify: IP address is assigned
  # Check: Correct subnet mask
  # If no IP: DHCP may have failed or static not configured

Step 3: Test loopback (local TCP/IP stack)
  ping -c 2 127.0.0.1
  # Success: TCP/IP stack is working
  # Failure: Serious system problem

Step 4: Test gateway (local network)
  ip route show
  # Note the default gateway IP
  ping -c 2 GATEWAY_IP
  # Success: Local network is working
  # Failure: Check network config, cable, switch

Step 5: Test external connectivity (internet)
  ping -c 2 8.8.8.8
  # Success: Internet routing works
  # Failure: Gateway, routing, or firewall issue

Step 6: Test DNS resolution
  ping -c 2 google.com
  # Success: DNS is working
  # Failure: DNS configuration issue

Create troubleshooting report:
  cat > /tmp/nmcli-lab/troubleshooting.txt << 'ENDFILE'
  NETWORK TROUBLESHOOTING WORKFLOW RESULTS
  
  Test 1: Interface State
  Command: ip link show
  Result: Interface UP, LOWER_UP
  Status: PASS - Physical layer OK
  
  Test 2: IP Configuration
  Command: ip addr show
  Result: 192.168.1.100/24 assigned
  Status: PASS - IP configured correctly
  
  Test 3: Loopback Test
  Command: ping -c 2 127.0.0.1
  Result: 2 packets transmitted, 2 received, 0% loss
  Status: PASS - TCP/IP stack functional
  
  Test 4: Gateway Test
  Command: ping -c 2 192.168.1.1
  Result: 2 packets transmitted, 2 received, 0% loss
  Status: PASS - Local network reachable
  
  Test 5: External Connectivity
  Command: ping -c 2 8.8.8.8
  Result: 2 packets transmitted, 2 received, 0% loss
  Status: PASS - Internet connectivity OK
  
  Test 6: DNS Resolution
  Command: ping -c 2 google.com
  Result: 2 packets transmitted, 2 received, 0% loss
  Status: PASS - DNS working correctly
  
  Conclusion: All network layers functioning correctly
ENDFILE

Troubleshooting decision tree:
  Loopback fails? → TCP/IP stack problem, rare
  Gateway fails? → Check cable, IP config, local network
  External fails? → Check routing, firewall, ISP
  DNS fails? → Check /etc/resolv.conf, nameserver reachable

Common issues and fixes:
  No IP address:
    → Check: nmcli con show CONNECTION
    → Fix: nmcli con up CONNECTION
  
  Can't reach gateway:
    → Check: ip route show
    → Check: Cable connected
    → Fix: Verify gateway IP correct
  
  Can't resolve names:
    → Check: cat /etc/resolv.conf
    → Fix: Add nameserver 8.8.8.8

Verification:
  cat /tmp/nmcli-lab/troubleshooting.txt

EOF
}

hint_step_5() {
    echo "  Check permissions: nmcli gen permissions"
    echo "  Check status: systemctl status NetworkManager"
    echo "  Save: systemctl status NetworkManager > /tmp/nmcli-lab/nm-status.txt"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Examine NetworkManager permissions and status

Understand how NetworkManager permissions work and verify the service is
running correctly.

Requirements:
  • Check permissions: nmcli gen permissions
  • Check service status: systemctl status NetworkManager
  • Verify service is enabled
  • Save status: systemctl status NetworkManager > /tmp/nmcli-lab/nm-status.txt

Commands you might need:
  • nmcli gen permissions - Show current permissions
  • nmcli general - Show NetworkManager state
  • systemctl status NetworkManager - Check service status
  • systemctl is-enabled NetworkManager - Check if enabled
EOF
}

validate_step_5() {
    if [ ! -f /tmp/nmcli-lab/nm-status.txt ]; then
        echo ""
        print_color "$RED" "✗ nm-status.txt not found"
        echo "  Try: systemctl status NetworkManager > /tmp/nmcli-lab/nm-status.txt"
        return 1
    fi
    
    if [ ! -s /tmp/nmcli-lab/nm-status.txt ]; then
        echo ""
        print_color "$RED" "✗ nm-status.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  nmcli gen permissions
  nmcli general
  systemctl status NetworkManager
  systemctl is-enabled NetworkManager
  systemctl status NetworkManager > /tmp/nmcli-lab/nm-status.txt

Explanation:
  nmcli gen permissions shows access rights:
  
  PERMISSION                VALUE
  org.freedesktop.NetworkManager.enable-disable-network    yes
  org.freedesktop.NetworkManager.enable-disable-wifi       yes
  org.freedesktop.NetworkManager.network-control           yes
  org.freedesktop.NetworkManager.settings.modify.system    auth
  
  Permission values:
  • yes: Allowed without authentication
  • no: Not allowed
  • auth: Requires authentication (PolicyKit)

Understanding permissions:
  • Console users: More permissions via dbus
  • SSH users: Limited permissions
  • Root: Full permissions
  • Managed by PolicyKit/dbus

systemctl status output:
  ● NetworkManager.service - Network Manager
     Loaded: loaded (/usr/lib/systemd/system/NetworkManager.service; enabled)
     Active: active (running) since Mon 2026-01-19 10:00:00
     
  Key fields:
  • Loaded: Service definition loaded
  • enabled: Starts at boot
  • Active: Currently running
  • Main PID: Process ID

NetworkManager states:
  • running: Service active and managing network
  • stopped: Service not running
  • failed: Service encountered error

Why NetworkManager:
  • Handles dynamic network changes
  • Manages WiFi, Ethernet, VPN
  • Provides DHCP client
  • Integrates with desktop environments
  • Handles DNS configuration

Verification:
  cat /tmp/nmcli-lab/nm-status.txt
  systemctl is-active NetworkManager
  systemctl is-enabled NetworkManager

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your NetworkManager exploration..."
    echo ""
    
    # CHECK 1: nmcli connection and device information
    print_color "$CYAN" "[1/$total] Checking nmcli outputs..."
    if [ -f /tmp/nmcli-lab/connections.txt ] && \
       [ -f /tmp/nmcli-lab/devices.txt ] && \
       [ -s /tmp/nmcli-lab/connections.txt ] && \
       [ -s /tmp/nmcli-lab/devices.txt ]; then
        print_color "$GREEN" "  ✓ Connection and device information documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or empty nmcli output files"
        print_color "$YELLOW" "  Fix: nmcli con show > /tmp/nmcli-lab/connections.txt"
        print_color "$YELLOW" "       nmcli dev status > /tmp/nmcli-lab/devices.txt"
    fi
    echo ""
    
    # CHECK 2: Connection details
    print_color "$CYAN" "[2/$total] Checking connection details..."
    if [ -f /tmp/nmcli-lab/connection-details.txt ] && \
       [ -s /tmp/nmcli-lab/connection-details.txt ]; then
        print_color "$GREEN" "  ✓ Connection details documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Connection details not found"
        print_color "$YELLOW" "  Fix: nmcli con show CONNECTION_NAME > /tmp/nmcli-lab/connection-details.txt"
    fi
    echo ""
    
    # CHECK 3: nmtui exploration
    print_color "$CYAN" "[3/$total] Checking nmtui exploration..."
    if [ -f /tmp/nmcli-lab/nmtui-notes.txt ] && \
       [ -s /tmp/nmcli-lab/nmtui-notes.txt ]; then
        print_color "$GREEN" "  ✓ nmtui exploration documented"
        ((score++))
    else
        print_color "$RED" "  ✗ nmtui notes not found"
        print_color "$YELLOW" "  Fix: Document your nmtui observations in nmtui-notes.txt"
    fi
    echo ""
    
    # CHECK 4: Troubleshooting workflow
    print_color "$CYAN" "[4/$total] Checking troubleshooting workflow..."
    if [ -f /tmp/nmcli-lab/troubleshooting.txt ] && \
       [ -s /tmp/nmcli-lab/troubleshooting.txt ]; then
        print_color "$GREEN" "  ✓ Troubleshooting workflow documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Troubleshooting workflow not documented"
        print_color "$YELLOW" "  Fix: Complete troubleshooting steps and document results"
    fi
    echo ""
    
    # CHECK 5: NetworkManager status
    print_color "$CYAN" "[5/$total] Checking NetworkManager status..."
    if [ -f /tmp/nmcli-lab/nm-status.txt ] && \
       [ -s /tmp/nmcli-lab/nm-status.txt ]; then
        print_color "$GREEN" "  ✓ NetworkManager status documented"
        ((score++))
    else
        print_color "$RED" "  ✗ NetworkManager status not documented"
        print_color "$YELLOW" "  Fix: systemctl status NetworkManager > /tmp/nmcli-lab/nm-status.txt"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Using nmcli to manage NetworkManager"
        echo "  • Examining connection properties"
        echo "  • Using nmtui for interactive configuration"
        echo "  • Following systematic troubleshooting workflow"
        echo "  • Checking NetworkManager permissions and status"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Export for progress tracking
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

OBJECTIVE 1: Explore nmcli
─────────────────────────────────────────────────────────────────
Commands:
  nmcli
  nmcli con show
  nmcli dev status
  nmcli con show > /tmp/nmcli-lab/connections.txt
  nmcli dev status > /tmp/nmcli-lab/devices.txt


OBJECTIVE 2: Examine connection properties
─────────────────────────────────────────────────────────────────
Commands:
  nmcli con show
  nmcli con show CONNECTION_NAME
  nmcli con show CONNECTION_NAME | grep ipv4
  nmcli con show CONNECTION_NAME > /tmp/nmcli-lab/connection-details.txt


OBJECTIVE 3: Explore nmtui
─────────────────────────────────────────────────────────────────
Commands:
  nmtui
  
Navigate and document observations in /tmp/nmcli-lab/nmtui-notes.txt


OBJECTIVE 4: Practice troubleshooting workflow
─────────────────────────────────────────────────────────────────
Commands:
  ip link show
  ip addr show
  ping -c 2 127.0.0.1
  ip route show
  ping -c 2 GATEWAY_IP
  ping -c 2 8.8.8.8
  ping -c 2 google.com

Document results in /tmp/nmcli-lab/troubleshooting.txt


OBJECTIVE 5: Check NetworkManager
─────────────────────────────────────────────────────────────────
Commands:
  nmcli gen permissions
  nmcli general
  systemctl status NetworkManager
  systemctl is-enabled NetworkManager
  systemctl status NetworkManager > /tmp/nmcli-lab/nm-status.txt


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NetworkManager:
  Purpose: Manage network configuration dynamically
  Service: systemd service
  Config: /etc/NetworkManager/system-connections/
  
  Components:
  • nmcli: Command-line interface
  • nmtui: Text user interface
  • nm-connection-editor: GUI (GNOME)

nmcli structure:
  nmcli [OPTIONS] OBJECT { COMMAND | help }
  
  Objects:
  • general: NetworkManager status and operations
  • networking: Overall networking control
  • radio: Wireless hardware control
  • connection: Connection profiles
  • device: Network devices
  • agent: Secret agent operations

Connection vs Device:
  Connection: Configuration profile (saved settings)
  Device: Physical or virtual network interface
  
  One device can have multiple connections
  Only one connection active per device at a time

nmtui interface:
  Purpose: Interactive text-based configuration
  Use cases:
  • Quick configuration changes
  • When unfamiliar with nmcli syntax
  • Console-only access
  
  Limitations:
  • Cannot script
  • Less detailed than nmcli
  • Requires interactive session

Troubleshooting layers:
  Layer 1 - Physical: Cable, interface state
  Layer 2 - Data Link: MAC address, switch
  Layer 3 - Network: IP address, routing
  Layer 4+ - Application: Services, DNS

NetworkManager permissions:
  Managed by: PolicyKit and dbus
  Console users: More permissions
  SSH users: Limited permissions
  Root: Full permissions


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Confusing connection and device
  Connection: Profile with settings
  Device: Actual network interface
  Fix: Use nmcli dev status to see relationship

Mistake 2: Forgetting to activate connection after changes
  Result: Changes not applied
  Fix: nmcli con up CONNECTION_NAME

Mistake 3: Editing /etc/resolv.conf directly
  Result: Changes overwritten by NetworkManager
  Fix: Use nmcli to configure DNS

Mistake 4: Not following systematic troubleshooting
  Result: Missing root cause
  Fix: Follow workflow - physical, IP, gateway, DNS


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. nmcli con show lists connections, nmcli dev status lists devices
2. Use nmtui for quick interactive changes on exam
3. Always activate connection after changes: nmcli con up NAME
4. Troubleshoot systematically: interface -> IP -> gateway -> DNS
5. NetworkManager is a systemd service: systemctl status NetworkManager
6. Connection files stored in /etc/NetworkManager/system-connections/
7. Use tab completion with nmcli for faster typing

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove working directory
    rm -rf /tmp/nmcli-lab 2>/dev/null || true
    
    # Remove backup (connections weren't actually modified in this lab)
    rm -rf /tmp/network-config-backup 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
