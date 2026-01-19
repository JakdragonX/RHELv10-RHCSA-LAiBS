#!/bin/bash
# labs/m03/11A-network-analysis-tools.sh
# Lab: Exploring ping, ip, tracepath, and ss
# Difficulty: Beginner
# RHCSA Objective: 11.1, 11.5, 11.9 - Network analysis and troubleshooting

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Exploring ping, ip, tracepath, and ss"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure we have network connectivity
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "  ⚠ Warning: No internet connectivity detected"
        echo "  Some exercises may not work without network access"
    fi
    
    # Create directory for storing results
    mkdir -p /tmp/network-lab 2>/dev/null || true
    
    echo "  ✓ Lab environment ready"
    echo "  ✓ Network analysis tools available"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of IP addressing
  • Understanding of network connectivity concepts
  • Familiarity with command line

Commands You'll Use:
  • ping - Test network connectivity
  • ip - Display and manage network configuration
  • tracepath - Trace the network path to a destination
  • ss - Display socket statistics

Files You'll Interact With:
  • /tmp/network-lab/ - Directory for storing command output
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator who needs to troubleshoot network connectivity
and analyze the network configuration of your Linux system. You'll use standard
Linux network tools to verify connectivity, examine routing, analyze network
interfaces, and check which services are listening on the network.

BACKGROUND:
Network troubleshooting is a critical skill for system administrators. The basic
tools - ping, ip, tracepath, and ss - form the foundation of network diagnostics.
Understanding what these tools show and how to interpret their output is essential
for maintaining reliable network services.

OBJECTIVES:
  1. Use ping to test network connectivity
     • Test connectivity to localhost: 127.0.0.1
     • Test connectivity to external host: 8.8.8.8
     • Use ping -c to limit packet count
     • Save output to /tmp/network-lab/ping-results.txt

  2. Use ip command to analyze network configuration
     • View network interfaces with: ip link show
     • View IP addresses with: ip addr show
     • Identify your primary network interface
     • View routing table with: ip route show
     • Save routing table to /tmp/network-lab/routing.txt

  3. Use tracepath to trace network routes
     • Trace route to 8.8.8.8
     • Understand hop count and network path
     • Save tracepath output to /tmp/network-lab/tracepath.txt

  4. Use ss to analyze socket statistics
     • View all TCP connections: ss -t
     • View all listening sockets: ss -tln
     • View listening and established connections: ss -tuna
     • Identify which services are listening on your system
     • Save listening services to /tmp/network-lab/listening.txt

  5. Interpret and analyze network information
     • Identify your system's IP address
     • Identify your default gateway
     • Count how many network hops to 8.8.8.8
     • List all services listening on TCP port 22
     • Document findings in /tmp/network-lab/analysis.txt

HINTS:
  • ping -c 4 limits to 4 packets
  • ip addr shows all IP addresses
  • ip route shows routing table
  • tracepath shows network path hop-by-hop
  • ss -tln shows TCP listening sockets with numeric ports
  • Use > to save output to files
  • Use | grep to filter output

SUCCESS CRITERIA:
  • Successfully ping localhost and external hosts
  • All output files created in /tmp/network-lab/
  • Routing table captured and saved
  • Network path traced to external destination
  • Listening services identified and documented
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Test connectivity with ping - localhost, gateway, 8.8.8.8
  ☐ 2. Analyze network config with ip - link, addr, route
  ☐ 3. Trace network path with tracepath to 8.8.8.8
  ☐ 4. View socket statistics with ss - TCP, listening, all
  ☐ 5. Document findings in analysis.txt
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
You are troubleshooting network connectivity and analyzing your system's network
configuration using standard Linux tools.

Output directory: /tmp/network-lab/
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Use ping to test network connectivity

The ping command sends ICMP echo requests to verify network connectivity. It is
the first tool you should use when troubleshooting network issues.

Requirements:
  • Test localhost: ping -c 4 127.0.0.1
  • Test external host: ping -c 4 8.8.8.8
  • Save results: ping -c 4 8.8.8.8 > /tmp/network-lab/ping-results.txt

Commands you might need:
  • ping -c N - Send N packets then stop
  • ping -c 4 - Common usage, sends 4 packets
  • Ctrl+C - Stop continuous ping
EOF
}

validate_step_1() {
    if [ ! -f /tmp/network-lab/ping-results.txt ]; then
        echo ""
        print_color "$RED" "✗ ping-results.txt not found"
        echo "  Try: ping -c 4 8.8.8.8 > /tmp/network-lab/ping-results.txt"
        return 1
    fi
    
    if ! grep -q "bytes from" /tmp/network-lab/ping-results.txt 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ ping-results.txt does not contain valid ping output"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  mkdir -p /tmp/network-lab
  ping -c 4 127.0.0.1
  ping -c 4 8.8.8.8
  ping -c 4 8.8.8.8 > /tmp/network-lab/ping-results.txt

Explanation:
  • ping: Send ICMP echo requests
  • -c 4: Send 4 packets then stop
  • 127.0.0.1: Localhost loopback interface
  • 8.8.8.8: Google's public DNS server
  • >: Redirect output to file

Understanding ping output:
  64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=14.2 ms
  
  Fields:
  • 64 bytes: Packet size
  • icmp_seq: Sequence number
  • ttl: Time To Live, hops remaining
  • time: Round-trip time, latency

Ping statistics:
  4 packets transmitted, 4 received, 0% packet loss
  
  • 0% packet loss = good connectivity
  • Greater than 0% packet loss = network issues
  • 100% packet loss = no connectivity

Verification:
  cat /tmp/network-lab/ping-results.txt

EOF
}

hint_step_2() {
    echo "  View interfaces: ip link show"
    echo "  View addresses: ip addr show"
    echo "  View routes: ip route show > /tmp/network-lab/routing.txt"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Use ip command to analyze network configuration

The ip command is the modern tool for managing and viewing network configuration.
It replaces the deprecated ifconfig command.

Requirements:
  • View network interfaces: ip link show
  • View IP addresses: ip addr show
  • View routing table: ip route show
  • Save routing table: ip route show > /tmp/network-lab/routing.txt

Commands you might need:
  • ip link - Show network interfaces
  • ip addr - Show IP addresses
  • ip route - Show routing table
  • ip -s link - Show interface statistics
EOF
}

validate_step_2() {
    if [ ! -f /tmp/network-lab/routing.txt ]; then
        echo ""
        print_color "$RED" "✗ routing.txt not found"
        echo "  Try: ip route show > /tmp/network-lab/routing.txt"
        return 1
    fi
    
    if ! grep -q "default" /tmp/network-lab/routing.txt 2>/dev/null; then
        echo ""
        print_color "$YELLOW" "  Note: No default route found, may be expected in some environments"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  ip link show
  ip addr show
  ip route show
  ip route show > /tmp/network-lab/routing.txt

Explanation:
  • ip link: Shows network interfaces, layer 2
  • ip addr: Shows IP addresses, layer 3
  • ip route: Shows routing table

ip link output:
  2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
  
  Fields:
  • ens33: Interface name
  • UP: Interface is active
  • LOWER_UP: Physical link is up
  • mtu 1500: Maximum transmission unit

ip addr output:
  inet 192.168.1.100/24 brd 192.168.1.255 scope global ens33
  
  Fields:
  • inet: IPv4 address
  • 192.168.1.100/24: IP address with subnet
  • brd: Broadcast address
  • scope global: Address scope

ip route output:
  default via 192.168.1.1 dev ens33
  192.168.1.0/24 dev ens33 proto kernel scope link src 192.168.1.100
  
  Fields:
  • default via X.X.X.X: Default gateway
  • dev ens33: Network interface
  • proto kernel: Added by kernel
  • src: Source address

Verification:
  cat /tmp/network-lab/routing.txt

EOF
}

hint_step_3() {
    echo "  Use: tracepath 8.8.8.8"
    echo "  Save: tracepath 8.8.8.8 > /tmp/network-lab/tracepath.txt"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Use tracepath to trace network routes

tracepath shows the network path packets take to reach a destination. Each
hop represents a router along the path.

Requirements:
  • Trace route to 8.8.8.8: tracepath 8.8.8.8
  • Save output: tracepath 8.8.8.8 > /tmp/network-lab/tracepath.txt
  • Note: This may take 30-60 seconds

Commands you might need:
  • tracepath - Trace network path
  • tracepath -n - Do not resolve hostnames, faster
EOF
}

validate_step_3() {
    if [ ! -f /tmp/network-lab/tracepath.txt ]; then
        echo ""
        print_color "$RED" "✗ tracepath.txt not found"
        echo "  Try: tracepath 8.8.8.8 > /tmp/network-lab/tracepath.txt"
        return 1
    fi
    
    if [ ! -s /tmp/network-lab/tracepath.txt ]; then
        echo ""
        print_color "$RED" "✗ tracepath.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  tracepath 8.8.8.8
  tracepath 8.8.8.8 > /tmp/network-lab/tracepath.txt

Alternative:
  tracepath -n 8.8.8.8
  tracepath google.com

Explanation:
  • tracepath: Shows network path hop-by-hop
  • Each line is one hop, one router
  • Shows latency and MTU

Sample tracepath output:
  1?: [LOCALHOST]     pmtu 1500
  1:  gateway         0.326ms
  2:  10.1.1.1        2.045ms
  3:  no reply
  4:  8.8.8.8         14.221ms reached

Understanding output:
  • Line 1: Your gateway
  • Lines 2-N: Intermediate routers
  • "no reply": Router does not respond, common
  • "reached": Destination found

Verification:
  cat /tmp/network-lab/tracepath.txt

EOF
}

hint_step_4() {
    echo "  View TCP: ss -t"
    echo "  View listening: ss -tln"
    echo "  Save: ss -tln > /tmp/network-lab/listening.txt"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Use ss to analyze socket statistics

The ss command shows network connections and listening services. It replaces
the deprecated netstat command.

Requirements:
  • View all TCP connections: ss -t
  • View TCP listening sockets: ss -tln
  • View all sockets: ss -tuna
  • Save listening services: ss -tln > /tmp/network-lab/listening.txt

Commands you might need:
  • ss -t - TCP sockets
  • ss -u - UDP sockets
  • ss -l - Listening sockets
  • ss -n - Numeric, do not resolve names
  • ss -a - All sockets
EOF
}

validate_step_4() {
    if [ ! -f /tmp/network-lab/listening.txt ]; then
        echo ""
        print_color "$RED" "✗ listening.txt not found"
        echo "  Try: ss -tln > /tmp/network-lab/listening.txt"
        return 1
    fi
    
    if ! grep -q "State" /tmp/network-lab/listening.txt 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ listening.txt does not contain valid ss output"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  ss -t
  ss -tln
  ss -tuna
  ss -tln > /tmp/network-lab/listening.txt

Explanation:
  • ss: Socket statistics
  • -t: TCP sockets
  • -u: UDP sockets
  • -l: Listening sockets
  • -n: Numeric, no name resolution
  • -a: All sockets, listening and established

Sample ss output:
  State   Recv-Q Send-Q Local Address:Port  Peer Address:Port
  LISTEN  0      128    0.0.0.0:22          0.0.0.0:*
  ESTAB   0      0      192.168.1.100:22    192.168.1.50:54321

Understanding columns:
  • State: Socket state, LISTEN or ESTAB
  • Recv-Q: Receive queue
  • Send-Q: Send queue
  • Local Address:Port: Your system
  • Peer Address:Port: Remote system

Common socket states:
  LISTEN - Waiting for connections
  ESTAB - Established connection
  TIME-WAIT - Connection closing
  CLOSE-WAIT - Waiting to close

Verification:
  cat /tmp/network-lab/listening.txt

EOF
}

hint_step_5() {
    echo "  Create file with your findings"
    echo "  Include: IP address, gateway, hop count, listening services"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Interpret and analyze network information

Review all the information you have gathered and document your findings in a
summary analysis file.

Requirements:
  • Create /tmp/network-lab/analysis.txt
  • Document the following:
    - Your system's primary IP address
    - Your default gateway IP
    - Number of hops to 8.8.8.8
    - Services listening on port 22
    - Any observations about network connectivity

Commands you might need:
  • cat /tmp/network-lab/routing.txt
  • cat /tmp/network-lab/tracepath.txt
  • cat /tmp/network-lab/listening.txt
EOF
}

validate_step_5() {
    if [ ! -f /tmp/network-lab/analysis.txt ]; then
        echo ""
        print_color "$RED" "✗ analysis.txt not found"
        echo "  Create file with your network analysis"
        return 1
    fi
    
    if [ ! -s /tmp/network-lab/analysis.txt ]; then
        echo ""
        print_color "$RED" "✗ analysis.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Review your saved files and create analysis:

Commands to extract information:
  ip addr show | grep "inet " | grep -v 127.0.0.1
  ip route show | grep default
  grep "reached" /tmp/network-lab/tracepath.txt
  grep ":22" /tmp/network-lab/listening.txt

Create analysis file:
  cat > /tmp/network-lab/analysis.txt << 'ENDFILE'
  NETWORK ANALYSIS SUMMARY
  
  Primary IP Address: 192.168.1.100
  Subnet Mask: /24
  Default Gateway: 192.168.1.1
  Network Interface: ens33
  
  Connectivity Test Results:
  - Localhost ping: Success
  - Gateway ping: Success
  - External ping 8.8.8.8: Success
  
  Route to 8.8.8.8:
  - Number of hops: 12
  - Average latency: 14ms
  
  Listening Services:
  - SSH port 22: Yes, listening on all interfaces
  
  Network Status: Fully operational
ENDFILE

Verification:
  cat /tmp/network-lab/analysis.txt

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your network analysis work..."
    echo ""
    
    # CHECK 1: ping results
    print_color "$CYAN" "[1/$total] Checking ping results..."
    if [ -f /tmp/network-lab/ping-results.txt ] && \
       grep -q "bytes from" /tmp/network-lab/ping-results.txt 2>/dev/null; then
        print_color "$GREEN" "  ✓ ping results saved successfully"
        ((score++))
    else
        print_color "$RED" "  ✗ ping results not found or invalid"
        print_color "$YELLOW" "  Fix: ping -c 4 8.8.8.8 > /tmp/network-lab/ping-results.txt"
    fi
    echo ""
    
    # CHECK 2: routing table
    print_color "$CYAN" "[2/$total] Checking routing table..."
    if [ -f /tmp/network-lab/routing.txt ] && [ -s /tmp/network-lab/routing.txt ]; then
        print_color "$GREEN" "  ✓ Routing table saved successfully"
        ((score++))
    else
        print_color "$RED" "  ✗ Routing table not found"
        print_color "$YELLOW" "  Fix: ip route show > /tmp/network-lab/routing.txt"
    fi
    echo ""
    
    # CHECK 3: tracepath results
    print_color "$CYAN" "[3/$total] Checking tracepath results..."
    if [ -f /tmp/network-lab/tracepath.txt ] && [ -s /tmp/network-lab/tracepath.txt ]; then
        print_color "$GREEN" "  ✓ tracepath results saved successfully"
        ((score++))
    else
        print_color "$RED" "  ✗ tracepath results not found"
        print_color "$YELLOW" "  Fix: tracepath 8.8.8.8 > /tmp/network-lab/tracepath.txt"
    fi
    echo ""
    
    # CHECK 4: socket statistics
    print_color "$CYAN" "[4/$total] Checking socket statistics..."
    if [ -f /tmp/network-lab/listening.txt ] && \
       grep -q "State" /tmp/network-lab/listening.txt 2>/dev/null; then
        print_color "$GREEN" "  ✓ Socket statistics saved successfully"
        ((score++))
    else
        print_color "$RED" "  ✗ Socket statistics not found or invalid"
        print_color "$YELLOW" "  Fix: ss -tln > /tmp/network-lab/listening.txt"
    fi
    echo ""
    
    # CHECK 5: analysis file
    print_color "$CYAN" "[5/$total] Checking network analysis..."
    if [ -f /tmp/network-lab/analysis.txt ] && [ -s /tmp/network-lab/analysis.txt ]; then
        print_color "$GREEN" "  ✓ Network analysis documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Network analysis not found"
        print_color "$YELLOW" "  Fix: Create /tmp/network-lab/analysis.txt with your findings"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Using ping to test network connectivity"
        echo "  • Using ip to view network configuration"
        echo "  • Using tracepath to trace network routes"
        echo "  • Using ss to analyze socket statistics"
        echo "  • Interpreting network diagnostic information"
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

OBJECTIVE 1: Test connectivity with ping
─────────────────────────────────────────────────────────────────
Commands:
  mkdir -p /tmp/network-lab
  ping -c 4 127.0.0.1
  ping -c 4 8.8.8.8
  ping -c 4 8.8.8.8 > /tmp/network-lab/ping-results.txt


OBJECTIVE 2: Analyze network configuration with ip
─────────────────────────────────────────────────────────────────
Commands:
  ip link show
  ip addr show
  ip route show
  ip route show > /tmp/network-lab/routing.txt


OBJECTIVE 3: Trace network path with tracepath
─────────────────────────────────────────────────────────────────
Commands:
  tracepath 8.8.8.8
  tracepath 8.8.8.8 > /tmp/network-lab/tracepath.txt


OBJECTIVE 4: Analyze sockets with ss
─────────────────────────────────────────────────────────────────
Commands:
  ss -t
  ss -tln
  ss -tuna
  ss -tln > /tmp/network-lab/listening.txt


OBJECTIVE 5: Document findings
─────────────────────────────────────────────────────────────────
Extract and analyze:
  ip addr show | grep "inet "
  ip route show | grep default
  cat /tmp/network-lab/tracepath.txt
  cat /tmp/network-lab/listening.txt

Create analysis.txt with your findings.


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ping command:
  Purpose: Test network connectivity
  Protocol: ICMP - Internet Control Message Protocol
  
  Options:
  -c N - Send N packets
  -i N - Wait N seconds between packets
  -W N - Timeout after N seconds
  
  Output interpretation:
  • 0% packet loss: Good connectivity
  • Less than 5% packet loss: Acceptable
  • Greater than 10% packet loss: Network issues
  • 100% packet loss: No connectivity

ip command:
  Replaces deprecated: ifconfig, route, arp
  
  Subcommands:
  ip link - Network interfaces, layer 2
  ip addr - IP addresses, layer 3
  ip route - Routing table
  ip neigh - ARP table
  
  Interface states:
  UP - Interface is active
  DOWN - Interface is inactive
  LOWER_UP - Physical link detected

tracepath command:
  Purpose: Show network path to destination
  Shows: Each router hop along the path
  
  Similar to: traceroute, but does not need root
  
  Output shows:
  - Hop number
  - Router IP or hostname
  - Latency in milliseconds
  - MTU - Maximum Transmission Unit

ss command:
  Replaces deprecated: netstat
  
  Common options:
  -t - TCP sockets
  -u - UDP sockets
  -l - Listening sockets
  -n - Numeric, no DNS lookups
  -a - All sockets
  -p - Show process, needs root
  
  Socket states:
  LISTEN - Waiting for connections
  ESTAB - Connected
  TIME-WAIT - Closing connection
  CLOSE-WAIT - Waiting to close


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting -c with ping
  Result: Ping runs forever
  Fix: Use Ctrl+C to stop, or use -c 4

Mistake 2: Not using numeric -n flag with ss
  Result: Slow output due to DNS lookups
  Fix: Use ss -tln instead of ss -tl

Mistake 3: Confusing ip addr and ip route
  ip addr: Shows IP addresses
  ip route: Shows routing table
  Different purposes!

Mistake 4: Expecting all tracepath hops to respond
  Result: See "no reply" or asterisks
  Fix: This is normal - routers often do not respond


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Use ping -c to limit packets, avoid infinite ping
2. ip command replaces ifconfig, know ip addr and ip route
3. ss replaces netstat, use ss -tln for listening
4. tracepath does not require root, unlike traceroute
5. Always check connectivity before complex troubleshooting

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    rm -rf /tmp/network-lab 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
