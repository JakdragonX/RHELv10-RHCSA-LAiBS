#!/bin/bash
# labs/m03/11B-hostname-hardware-resolution.sh
# Lab: Exploring hostnamectl, lspci, and hostname resolution
# Difficulty: Beginner
# RHCSA Objective: 11.3, 11.4 - Hostname configuration and DNS resolution

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Exploring hostnamectl, lspci, and hostname resolution"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Backup original hostname
    if [ ! -f /tmp/original-hostname.bak ]; then
        hostnamectl hostname > /tmp/original-hostname.bak 2>/dev/null || hostname > /tmp/original-hostname.bak
    fi
    
    # Backup /etc/hosts if not already backed up
    if [ ! -f /etc/hosts.lab-backup ]; then
        cp /etc/hosts /etc/hosts.lab-backup 2>/dev/null || true
    fi
    
    # Create working directory
    mkdir -p /tmp/hostname-lab 2>/dev/null || true
    
    echo "  ✓ Backed up original hostname"
    echo "  ✓ Backed up /etc/hosts"
    echo "  ✓ Lab environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of hostnames and DNS
  • Understanding of network configuration
  • Familiarity with system hardware concepts

Commands You'll Use:
  • hostnamectl - View and set system hostname
  • lspci - List PCI devices
  • getent - Query system databases
  • nslookup - Query DNS servers
  • dig - DNS lookup utility

Files You'll Interact With:
  • /etc/hostname - System hostname configuration
  • /etc/hosts - Static hostname-to-IP mapping
  • /etc/resolv.conf - DNS resolver configuration
  • /etc/nsswitch.conf - Name service switch configuration
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You are configuring a newly deployed Linux server. Your manager has asked you
to set the hostname appropriately, verify the system hardware, configure local
hostname resolution, and ensure DNS is working correctly.

BACKGROUND:
Proper hostname configuration is essential for system identification, logging,
and network services. Understanding hardware detection helps with driver
troubleshooting. Hostname resolution through /etc/hosts and DNS is critical
for network communications.

OBJECTIVES:
  1. Use hostnamectl to manage system hostname
     • View current hostname settings with: hostnamectl
     • Set hostname to: lab-server.example.com
     • Verify hostname is persistent across reboots
     • Save hostname info to /tmp/hostname-lab/hostname-info.txt

  2. Use lspci to examine system hardware
     • List all PCI devices with: lspci
     • List devices with kernel drivers: lspci -k
     • Identify network card and its driver
     • Save network card info to /tmp/hostname-lab/network-card.txt

  3. Configure /etc/hosts for local hostname resolution
     • Add entry: 10.0.0.10 testserver.lab.local testserver
     • Add entry: 10.0.0.11 dbserver.lab.local dbserver
     • Test resolution with: getent hosts testserver.lab.local
     • Verify entries exist in /etc/hosts

  4. Examine DNS configuration
     • View DNS settings in /etc/resolv.conf
     • Check nameserver entries
     • Save resolv.conf to /tmp/hostname-lab/resolv-conf.txt
     • Understand the role of /etc/nsswitch.conf

  5. Test hostname resolution
     • Use getent hosts to resolve testserver.lab.local
     • Use getent hosts to resolve google.com
     • Document which uses /etc/hosts vs DNS
     • Save results to /tmp/hostname-lab/resolution-test.txt

HINTS:
  • hostnamectl without arguments shows current settings
  • hostnamectl hostname sets the hostname
  • lspci -k shows kernel drivers for devices
  • /etc/hosts entries: IP_ADDRESS FQDN shortname
  • getent hosts queries both /etc/hosts and DNS
  • /etc/nsswitch.conf determines resolution order

SUCCESS CRITERIA:
  • Hostname changed to lab-server.example.com
  • Network card identified with driver information
  • /etc/hosts contains two test entries
  • All output files created in /tmp/hostname-lab/
  • Resolution tests documented
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Use hostnamectl to set hostname to lab-server.example.com
  ☐ 2. Use lspci to identify network card and driver
  ☐ 3. Add entries to /etc/hosts for testserver and dbserver
  ☐ 4. Examine and document DNS configuration
  ☐ 5. Test hostname resolution with getent
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
You are configuring hostname settings, examining system hardware, and setting
up hostname resolution for a Linux server.

Output directory: /tmp/hostname-lab/
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Use hostnamectl to manage system hostname

The hostnamectl command is used to view and configure the system hostname.
The hostname identifies your system on the network.

Requirements:
  • View current hostname: hostnamectl
  • Set hostname: hostnamectl hostname lab-server.example.com
  • Verify change: hostnamectl
  • Save output: hostnamectl > /tmp/hostname-lab/hostname-info.txt

Commands you might need:
  • hostnamectl - Show current hostname settings
  • hostnamectl hostname NAME - Set system hostname
  • hostname - Display current hostname
EOF
}

validate_step_1() {
    local current_hostname=$(hostnamectl hostname 2>/dev/null || hostname)
    
    if [ "$current_hostname" != "lab-server.example.com" ]; then
        echo ""
        print_color "$RED" "✗ Hostname is not set to lab-server.example.com"
        echo "  Current hostname: $current_hostname"
        echo "  Try: sudo hostnamectl hostname lab-server.example.com"
        return 1
    fi
    
    if [ ! -f /tmp/hostname-lab/hostname-info.txt ]; then
        echo ""
        print_color "$RED" "✗ hostname-info.txt not found"
        echo "  Try: hostnamectl > /tmp/hostname-lab/hostname-info.txt"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  hostnamectl
  sudo hostnamectl hostname lab-server.example.com
  hostnamectl
  hostnamectl > /tmp/hostname-lab/hostname-info.txt

Explanation:
  • hostnamectl: Shows current hostname configuration
  • hostnamectl hostname NAME: Sets the system hostname
  • Changes are persistent across reboots

Understanding hostnamectl output:
  Static hostname: lab-server.example.com
  Icon name: computer-vm
  Chassis: vm
  Machine ID: abc123...
  Boot ID: xyz789...
  Operating System: Red Hat Enterprise Linux 10
  Kernel: Linux 6.x.x

Fields explained:
  • Static hostname: Configured hostname
  • Transient hostname: Temporary hostname from DHCP
  • Pretty hostname: UTF-8 hostname for display
  • Icon name: Icon identifier for GUI
  • Chassis: Hardware type

Verification:
  cat /tmp/hostname-lab/hostname-info.txt
  cat /etc/hostname

EOF
}

hint_step_2() {
    echo "  Physical/PCI: lspci -k > /tmp/hostname-lab/network-card.txt"
    echo "  VM alternative: ip link show > /tmp/hostname-lab/network-card.txt"
    echo "  Then: ethtool -i INTERFACE >> /tmp/hostname-lab/network-card.txt"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Use lspci to examine system hardware

The lspci command lists all PCI devices on your system, including network
cards, storage controllers, and graphics cards. Understanding hardware helps
with driver troubleshooting.

Requirements:
  • List all PCI devices: lspci
  • Show kernel drivers: lspci -k
  • Identify network card
  • Save output: lspci -k > /tmp/hostname-lab/network-card.txt
  
  NOTE: If in a virtual machine with no PCI devices shown:
  • Use: ip link show > /tmp/hostname-lab/network-card.txt
  • Then: ethtool -i INTERFACE >> /tmp/hostname-lab/network-card.txt
  • Replace INTERFACE with your network interface name from ip link

Commands you might need:
  • lspci - List PCI devices
  • lspci -k - Show kernel drivers
  • ip link show - Show network interfaces (VM alternative)
  • ethtool -i INTERFACE - Show driver info (VM alternative)
EOF
}

validate_step_2() {
    if [ ! -f /tmp/hostname-lab/network-card.txt ]; then
        echo ""
        print_color "$RED" "✗ network-card.txt not found"
        echo "  Try: lspci -k > /tmp/hostname-lab/network-card.txt"
        echo "  Or for VMs: ip link show > /tmp/hostname-lab/network-card.txt"
        return 1
    fi
    
    # Check if file has content - accept either lspci output or ip link output
    if [ ! -s /tmp/hostname-lab/network-card.txt ]; then
        echo ""
        print_color "$RED" "✗ network-card.txt is empty"
        return 1
    fi
    
    # If file contains network information, that's sufficient
    # Could be from lspci or from ip link show
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Physical Hardware / VMs with PCI devices:
  lspci
  lspci -k
  lspci | grep -i ethernet
  lspci -k > /tmp/hostname-lab/network-card.txt

Virtual Machines without PCI devices:
  ip link show
  ip link show > /tmp/hostname-lab/network-card.txt
  
  # Get driver info for your interface (replace ens160 with yours)
  ethtool -i ens160 >> /tmp/hostname-lab/network-card.txt

Explanation - lspci:
  • lspci: List all PCI devices
  • -k: Show kernel drivers in use
  • -v: Verbose output with more details

Sample lspci output:
  02:00.0 Ethernet controller: Intel Corporation 82540EM Gigabit Ethernet
  Subsystem: Intel Corporation PRO/1000 MT Desktop Adapter
  Kernel driver in use: e1000
  Kernel modules: e1000

Fields explained:
  • 02:00.0: PCI bus address
  • Ethernet controller: Device type
  • Intel Corporation: Manufacturer
  • Kernel driver in use: Active driver
  • Kernel modules: Available drivers

Explanation - VM alternative with ip link and ethtool:
  ip link show output:
  2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
      link/ether 00:0c:29:3a:2b:1c brd ff:ff:ff:ff:ff:ff
  
  ethtool -i ens160 output:
  driver: vmxnet3
  version: 1.7.0.0-k
  firmware-version: 
  bus-info: 0000:03:00.0

Why VMs may not show PCI devices:
  • Some virtualization platforms use paravirtualized devices
  • These appear as virtual devices, not PCI
  • KVM, VMware, VirtualBox may differ
  • ip link shows all network interfaces regardless
  • ethtool shows driver information

Common VM network drivers:
  • vmxnet3: VMware paravirtualized
  • virtio_net: KVM/QEMU paravirtualized
  • e1000: Intel emulated (older)
  • e1000e: Intel emulated (newer)

Verification:
  cat /tmp/hostname-lab/network-card.txt
  ip link show
  lspci | grep -i network

EOF
}

hint_step_3() {
    echo "  Edit with: sudo vi /etc/hosts"
    echo "  Add lines:"
    echo "  10.0.0.10 testserver.lab.local testserver"
    echo "  10.0.0.11 dbserver.lab.local dbserver"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Configure /etc/hosts for local hostname resolution

The /etc/hosts file provides static hostname-to-IP mappings. It is checked
before DNS and is useful for local testing and frequently accessed hosts.

Requirements:
  • Edit /etc/hosts with your preferred editor
  • Add entry: 10.0.0.10 testserver.lab.local testserver
  • Add entry: 10.0.0.11 dbserver.lab.local dbserver
  • Test with: getent hosts testserver.lab.local

Commands you might need:
  • sudo vi /etc/hosts - Edit hosts file
  • getent hosts HOSTNAME - Query hostname resolution
  • cat /etc/hosts - View hosts file
EOF
}

validate_step_3() {
    if ! grep -q "10.0.0.10.*testserver" /etc/hosts 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ testserver entry not found in /etc/hosts"
        echo "  Add: 10.0.0.10 testserver.lab.local testserver"
        return 1
    fi
    
    if ! grep -q "10.0.0.11.*dbserver" /etc/hosts 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ dbserver entry not found in /etc/hosts"
        echo "  Add: 10.0.0.11 dbserver.lab.local dbserver"
        return 1
    fi
    
    # Test resolution
    if ! getent hosts testserver.lab.local >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ testserver.lab.local does not resolve"
        echo "  Check /etc/hosts syntax"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo vi /etc/hosts
  
  Add these lines:
  10.0.0.10 testserver.lab.local testserver
  10.0.0.11 dbserver.lab.local dbserver

Test resolution:
  getent hosts testserver.lab.local
  getent hosts dbserver.lab.local

Explanation:
  /etc/hosts format:
  IP_ADDRESS FQDN shortname [additional_aliases]
  
  Fields:
  • IP_ADDRESS: IPv4 or IPv6 address
  • FQDN: Fully Qualified Domain Name
  • shortname: Short hostname alias
  • additional_aliases: Optional additional names

Sample /etc/hosts:
  127.0.0.1   localhost localhost.localdomain
  ::1         localhost localhost.localdomain
  192.168.1.100 server1.example.com server1
  10.0.0.10 testserver.lab.local testserver
  10.0.0.11 dbserver.lab.local dbserver

Verification:
  getent hosts testserver.lab.local
  ping -c 1 testserver

EOF
}

hint_step_4() {
    echo "  View: cat /etc/resolv.conf"
    echo "  Save: cat /etc/resolv.conf > /tmp/hostname-lab/resolv-conf.txt"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Examine DNS configuration

The /etc/resolv.conf file contains DNS resolver configuration, including which
nameservers to query. Understanding DNS configuration is essential for
troubleshooting name resolution issues.

Requirements:
  • View DNS configuration: cat /etc/resolv.conf
  • Identify nameserver entries
  • Save to file: cat /etc/resolv.conf > /tmp/hostname-lab/resolv-conf.txt
  • Understand /etc/nsswitch.conf role

Commands you might need:
  • cat /etc/resolv.conf - View DNS configuration
  • cat /etc/nsswitch.conf - View name service switch config
  • resolvectl status - View systemd-resolved status
EOF
}

validate_step_4() {
    if [ ! -f /tmp/hostname-lab/resolv-conf.txt ]; then
        echo ""
        print_color "$RED" "✗ resolv-conf.txt not found"
        echo "  Try: cat /etc/resolv.conf > /tmp/hostname-lab/resolv-conf.txt"
        return 1
    fi
    
    if [ ! -s /tmp/hostname-lab/resolv-conf.txt ]; then
        echo ""
        print_color "$RED" "✗ resolv-conf.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cat /etc/resolv.conf
  cat /etc/resolv.conf > /tmp/hostname-lab/resolv-conf.txt
  cat /etc/nsswitch.conf | grep hosts

Explanation:
  /etc/resolv.conf format:
  nameserver 8.8.8.8
  nameserver 8.8.4.4
  search example.com
  domain example.com

Fields explained:
  • nameserver: DNS server IP address
  • search: Domain search list
  • domain: Local domain name

Sample /etc/resolv.conf:
  # Generated by NetworkManager
  nameserver 192.168.1.1
  nameserver 8.8.8.8
  search lab.local example.com

Verification:
  cat /tmp/hostname-lab/resolv-conf.txt
  grep "^hosts:" /etc/nsswitch.conf

EOF
}

hint_step_5() {
    echo "  Test local: getent hosts testserver.lab.local"
    echo "  Test DNS: getent hosts google.com"
    echo "  Save results to /tmp/hostname-lab/resolution-test.txt"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Test hostname resolution

Test both local hosts file resolution and DNS resolution to understand
how the system resolves different types of hostnames.

Requirements:
  • Test local resolution: getent hosts testserver.lab.local
  • Test DNS resolution: getent hosts google.com
  • Document which uses /etc/hosts vs DNS
  • Save results to /tmp/hostname-lab/resolution-test.txt

Commands you might need:
  • getent hosts HOSTNAME - Query hostname resolution
  • nslookup HOSTNAME - DNS lookup tool
  • dig HOSTNAME - Detailed DNS query tool
EOF
}

validate_step_5() {
    if [ ! -f /tmp/hostname-lab/resolution-test.txt ]; then
        echo ""
        print_color "$RED" "✗ resolution-test.txt not found"
        echo "  Create file documenting resolution tests"
        return 1
    fi
    
    if [ ! -s /tmp/hostname-lab/resolution-test.txt ]; then
        echo ""
        print_color "$RED" "✗ resolution-test.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands to test resolution:
  getent hosts testserver.lab.local
  getent hosts google.com
  getent hosts dbserver

Create documentation:
  cat > /tmp/hostname-lab/resolution-test.txt << 'ENDFILE'
  HOSTNAME RESOLUTION TEST RESULTS
  
  Test 1: Local /etc/hosts resolution
  Command: getent hosts testserver.lab.local
  Result: 10.0.0.10 testserver.lab.local testserver
  Source: /etc/hosts file
  
  Test 2: DNS resolution
  Command: getent hosts google.com
  Result: Multiple IP addresses
  Source: DNS query to nameservers
  
  Conclusion:
  - testserver resolves via /etc/hosts
  - google.com resolves via DNS
  - Resolution order: files then dns per /etc/nsswitch.conf
ENDFILE

Verification:
  cat /tmp/hostname-lab/resolution-test.txt
  getent hosts testserver.lab.local

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your hostname and resolution configuration..."
    echo ""
    
    # CHECK 1: Hostname configuration
    print_color "$CYAN" "[1/$total] Checking hostname configuration..."
    local current_hostname=$(hostnamectl hostname 2>/dev/null || hostname)
    if [ "$current_hostname" = "lab-server.example.com" ] && \
       [ -f /tmp/hostname-lab/hostname-info.txt ]; then
        print_color "$GREEN" "  ✓ Hostname set to lab-server.example.com"
        ((score++))
    else
        print_color "$RED" "  ✗ Hostname not configured correctly"
        echo "  Current: $current_hostname"
        print_color "$YELLOW" "  Fix: sudo hostnamectl hostname lab-server.example.com"
    fi
    echo ""
    
    # CHECK 2: PCI hardware information
    print_color "$CYAN" "[2/$total] Checking PCI hardware documentation..."
    if [ -f /tmp/hostname-lab/network-card.txt ] && \
       [ -s /tmp/hostname-lab/network-card.txt ]; then
        print_color "$GREEN" "  ✓ Network card information documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Network card information not found"
        print_color "$YELLOW" "  Fix: lspci -k > /tmp/hostname-lab/network-card.txt"
    fi
    echo ""
    
    # CHECK 3: /etc/hosts entries
    print_color "$CYAN" "[3/$total] Checking /etc/hosts configuration..."
    local hosts_ok=true
    
    if ! grep -q "10.0.0.10.*testserver" /etc/hosts 2>/dev/null; then
        print_color "$RED" "  ✗ testserver entry missing from /etc/hosts"
        hosts_ok=false
    fi
    
    if ! grep -q "10.0.0.11.*dbserver" /etc/hosts 2>/dev/null; then
        print_color "$RED" "  ✗ dbserver entry missing from /etc/hosts"
        hosts_ok=false
    fi
    
    if [ "$hosts_ok" = true ]; then
        print_color "$GREEN" "  ✓ /etc/hosts configured with test entries"
        ((score++))
    else
        print_color "$YELLOW" "  Fix: Add entries to /etc/hosts"
    fi
    echo ""
    
    # CHECK 4: DNS configuration documentation
    print_color "$CYAN" "[4/$total] Checking DNS configuration documentation..."
    if [ -f /tmp/hostname-lab/resolv-conf.txt ] && \
       [ -s /tmp/hostname-lab/resolv-conf.txt ]; then
        print_color "$GREEN" "  ✓ DNS configuration documented"
        ((score++))
    else
        print_color "$RED" "  ✗ DNS configuration not documented"
        print_color "$YELLOW" "  Fix: cat /etc/resolv.conf > /tmp/hostname-lab/resolv-conf.txt"
    fi
    echo ""
    
    # CHECK 5: Resolution testing
    print_color "$CYAN" "[5/$total] Checking resolution test documentation..."
    if [ -f /tmp/hostname-lab/resolution-test.txt ] && \
       [ -s /tmp/hostname-lab/resolution-test.txt ]; then
        print_color "$GREEN" "  ✓ Resolution tests documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Resolution tests not documented"
        print_color "$YELLOW" "  Fix: Document getent hosts tests in resolution-test.txt"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Using hostnamectl to manage system hostname"
        echo "  • Using lspci to examine system hardware"
        echo "  • Configuring /etc/hosts for local resolution"
        echo "  • Understanding DNS configuration"
        echo "  • Testing hostname resolution"
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

OBJECTIVE 1: Configure hostname with hostnamectl
─────────────────────────────────────────────────────────────────
Commands:
  hostnamectl
  sudo hostnamectl hostname lab-server.example.com
  hostnamectl
  hostnamectl > /tmp/hostname-lab/hostname-info.txt


OBJECTIVE 2: Examine hardware with lspci
─────────────────────────────────────────────────────────────────
Physical Hardware Commands:
  lspci
  lspci -k
  lspci | grep -i ethernet
  lspci -k > /tmp/hostname-lab/network-card.txt

Virtual Machine Alternative:
  ip link show
  ip link show > /tmp/hostname-lab/network-card.txt
  ethtool -i ens160 >> /tmp/hostname-lab/network-card.txt
  # Replace ens160 with your actual interface name


OBJECTIVE 3: Configure /etc/hosts
─────────────────────────────────────────────────────────────────
Commands:
  sudo vi /etc/hosts
  
  Add:
  10.0.0.10 testserver.lab.local testserver
  10.0.0.11 dbserver.lab.local dbserver

Test:
  getent hosts testserver.lab.local


OBJECTIVE 4: Document DNS configuration
─────────────────────────────────────────────────────────────────
Commands:
  cat /etc/resolv.conf
  cat /etc/resolv.conf > /tmp/hostname-lab/resolv-conf.txt


OBJECTIVE 5: Test hostname resolution
─────────────────────────────────────────────────────────────────
Commands:
  getent hosts testserver.lab.local
  getent hosts google.com

Document in /tmp/hostname-lab/resolution-test.txt


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

hostnamectl:
  Purpose: Manage system hostname
  Configuration file: /etc/hostname
  Changes persist across reboots

lspci:
  Purpose: List PCI hardware devices
  Common flag: -k shows kernel drivers
  
  Virtual Machine Note:
  • Some VMs use paravirtualized devices
  • May not show in lspci output
  • Use ip link show and ethtool as alternatives
  • Common VM drivers: vmxnet3, virtio_net, e1000

/etc/hosts:
  Purpose: Static hostname-to-IP mappings
  Format: IP_ADDRESS FQDN shortname
  Checked before DNS by default

/etc/resolv.conf:
  Purpose: DNS resolver configuration
  Contains nameserver directives

/etc/nsswitch.conf:
  Purpose: Name Service Switch configuration
  Controls resolution order
  hosts: files dns means check /etc/hosts first then DNS


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Hostname not persisting after reboot
  Fix: Use hostnamectl hostname not just hostname command

Mistake 2: Wrong /etc/hosts syntax
  Fix: Ensure format is IP space FQDN space shortname

Mistake 3: /etc/resolv.conf changes overwritten
  Fix: Use NetworkManager to configure DNS persistently

Mistake 4: Forgetting to test resolution
  Fix: Always test with getent hosts or ping


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Use hostnamectl hostname to set hostname persistently
2. lspci -k shows which kernel driver is in use
3. /etc/hosts format: IP FQDN shortname
4. Test resolution with getent hosts HOSTNAME
5. /etc/nsswitch.conf defines resolution order

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Restore original hostname if backup exists
    if [ -f /tmp/original-hostname.bak ]; then
        local orig_hostname=$(cat /tmp/original-hostname.bak)
        hostnamectl hostname "$orig_hostname" 2>/dev/null || hostname "$orig_hostname" 2>/dev/null
        rm /tmp/original-hostname.bak
        echo "  ✓ Restored original hostname"
    fi
    
    # Restore original /etc/hosts
    if [ -f /etc/hosts.lab-backup ]; then
        cp /etc/hosts.lab-backup /etc/hosts 2>/dev/null || true
        rm /etc/hosts.lab-backup
        echo "  ✓ Restored original /etc/hosts"
    fi
    
    # Remove working directory
    rm -rf /tmp/hostname-lab 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
