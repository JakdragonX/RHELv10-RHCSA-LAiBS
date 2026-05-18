#!/bin/bash
# labs/22C-network-performance.sh
# Lab: Network Troubleshooting and Performance Diagnostics
# Difficulty: Intermediate
# RHCSA Objective: Diagnose and correct network connectivity problems; manage system performance

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Network Troubleshooting and Performance Diagnostics"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Back up resolv.conf if not already done
    if [ ! -f /etc/resolv.conf.lab-backup ]; then
        cp /etc/resolv.conf /etc/resolv.conf.lab-backup 2>/dev/null || true
    fi

    # Inject a broken DNS entry to simulate a misconfigured resolver
    # We prepend a bad nameserver so resolution fails for the first server
    # but the system falls back to (hopefully) working ones after a delay
    # A completely broken resolv.conf is too disruptive; we inject an unreachable IP.
    if ! grep -q "LAB22C" /etc/resolv.conf 2>/dev/null; then
        sed -i '1s/^/# LAB22C-INJECTED\nnameserver 192.0.2.1\n/' /etc/resolv.conf
    fi

    # Create a broken network config file for a dummy interface to diagnose
    # NetworkManager-key-file format; we create an intentionally misconfigured profile
    cat > /etc/NetworkManager/system-connections/lab22c-broken.nmconnection << 'NMEOF'
[connection]
id=lab22c-broken
uuid=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
type=ethernet
interface-name=lab22c0
autoconnect=false

[ethernet]

[ipv4]
# INTENTIONAL ERROR: gateway is not in the same subnet as the address
address1=10.99.1.100/24
gateway=10.99.2.1
method=manual

[ipv6]
method=disabled
NMEOF

    chmod 600 /etc/NetworkManager/system-connections/lab22c-broken.nmconnection

    echo "  ✓ Injected a non-functional nameserver into /etc/resolv.conf"
    echo "  ✓ Created broken NM profile at /etc/NetworkManager/system-connections/lab22c-broken.nmconnection"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of IP networking: addresses, subnets, gateways, DNS
  • What /etc/resolv.conf controls and how DNS resolution works
  • That the gateway must be in the same subnet as the interface address
  • Basic familiarity with reading NetworkManager connection profiles

Commands You'll Use:
  • ip addr / ip route   - Show interface addresses and routing table
  • ss -tuln             - Show listening sockets (replacement for netstat)
  • ping                 - Test basic connectivity
  • dig / nslookup       - Test DNS resolution
  • cat /etc/resolv.conf - Inspect DNS configuration
  • nmcli                - NetworkManager command-line interface
  • top                  - Real-time process and resource monitor
  • vmstat               - Virtual memory, CPU, and I/O statistics
  • free -h              - Memory usage summary

Files You'll Interact With:
  • /etc/resolv.conf                                 - DNS resolver configuration
  • /etc/resolv.conf.lab-backup                      - Backup created by lab setup
  • /etc/NetworkManager/system-connections/           - NM connection profiles

NETWORK TROUBLESHOOTING FRAMEWORK (four layers):
  1. Physical/Link:  Is the interface UP? (ip link show)
  2. Network/IP:     Does it have an address? Is the subnet correct? (ip addr)
  3. Routing:        Is there a default gateway? Is it in the local subnet? (ip route)
  4. DNS:            Does /etc/resolv.conf have working nameservers? (dig, cat)

  Work top-down: confirm each layer before blaming the next.
  Most issues on the RHCSA exam are at layers 3 and 4.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Multiple issues have been reported on this server: DNS resolution is slow or
failing, a network interface profile has a misconfigured gateway, and the
ops team wants a performance snapshot before escalating to Red Hat support.
Your task is to diagnose each issue, implement the correct fix, and collect
performance data.

BACKGROUND:
The lab setup injected a non-routable nameserver (192.0.2.1, from the
documentation/test IP range per RFC 5737) at the top of /etc/resolv.conf,
and created a broken NetworkManager profile with a gateway outside its subnet.

OBJECTIVES:
  1. Inspect /etc/resolv.conf and identify the broken nameserver entry
     (192.0.2.1). Remove it by restoring the backup. Verify DNS works
     afterward using dig or nslookup against a known hostname.

  2. Inspect the broken NetworkManager profile at
     /etc/NetworkManager/system-connections/lab22c-broken.nmconnection.
     Identify the misconfiguration: the gateway (10.99.2.1) is not in the
     same /24 subnet as the address (10.99.1.100/24).
     Fix the profile: change the gateway to 10.99.1.1 (valid for that subnet).
     Reload NetworkManager to apply the change.

  3. Collect a performance snapshot using top, vmstat, and free.
     Run 'vmstat 2 5' (5 samples, 2 seconds apart) and identify the
     columns: r (run queue), b (blocked), si/so (swap in/out), bi/bo (block I/O).
     Understand what high values in each indicate.

HINTS:
  • 192.0.2.x is an RFC 5737 documentation range — never a real nameserver
  • The gateway must share the same network prefix as the interface address
    10.99.1.100/24 → network is 10.99.1.0/24 → valid gateways: 10.99.1.1-254
  • nmcli connection reload after editing an .nmconnection file
  • vmstat 2 5: first line is averages since boot; subsequent lines are live

SUCCESS CRITERIA:
  • /etc/resolv.conf no longer contains 192.0.2.1
  • lab22c-broken.nmconnection has gateway=10.99.1.1
  • You can interpret vmstat 2 5 output and identify what each key column means
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Remove 192.0.2.1 from /etc/resolv.conf; verify DNS resolution works
  ☐ 2. Fix gateway in lab22c-broken.nmconnection from 10.99.2.1 to 10.99.1.1; reload NM
  ☐ 3. Run 'vmstat 2 5' and interpret the r, b, si, so, bi, bo columns
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "3"
}

scenario_context() {
    cat << 'EOF'
DNS is failing, a network profile has a misconfigured gateway, and a
performance baseline is needed before escalating to Red Hat support.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Diagnose and fix the broken DNS configuration

Inspect /etc/resolv.conf, identify the non-functional nameserver,
and restore the working configuration.

Requirements:
  • Display /etc/resolv.conf and identify the 192.0.2.1 entry
  • Remove the broken entry (restore from backup OR edit manually)
  • Verify DNS works with dig or nslookup

Commands you might need:
  • cat /etc/resolv.conf
  • cp /etc/resolv.conf.lab-backup /etc/resolv.conf
  • dig redhat.com
  • nslookup redhat.com
  • host redhat.com
EOF
}

validate_step_1() {
    if grep -q "192.0.2.1" /etc/resolv.conf 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ 192.0.2.1 is still present in /etc/resolv.conf"
        echo "  Fix: cp /etc/resolv.conf.lab-backup /etc/resolv.conf"
        echo "  Or:  sed -i '/192.0.2.1/d' /etc/resolv.conf"
        return 1
    fi

    if grep -q "LAB22C" /etc/resolv.conf 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ Lab22C injection comment still in /etc/resolv.conf"
        echo "  Fix: cp /etc/resolv.conf.lab-backup /etc/resolv.conf"
        return 1
    fi

    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cat /etc/resolv.conf
  # Observe: 192.0.2.1 as the first nameserver — this is a documentation/test
  # range (RFC 5737) and is never routable on a real network

  cp /etc/resolv.conf.lab-backup /etc/resolv.conf
  # Restore from backup — simplest and safest fix

  dig redhat.com +short
  # Verify DNS resolution works

What to look for in /etc/resolv.conf:
  nameserver <IP>     → DNS server to query (up to 3)
  search <domain>     → Appended to bare hostnames for resolution
  options timeout:2   → Seconds to wait per nameserver before trying next
  options attempts:3  → Number of retries per nameserver

  The resolver tries nameservers in order. A non-routable first entry
  (like 192.0.2.1) causes a timeout before falling through to the next,
  which explains why DNS feels "slow" rather than completely broken.

When /etc/resolv.conf is managed by NetworkManager:
  On RHEL 9, NetworkManager typically manages /etc/resolv.conf via
  systemd-resolved or by writing directly. Manual edits to /etc/resolv.conf
  may be overwritten when NM reconnects an interface. To make permanent DNS
  changes: nmcli connection modify <name> ipv4.dns "8.8.8.8 8.8.4.4"
  Manual edits are appropriate for quick diagnostics, not permanent config.

Verification:
  cat /etc/resolv.conf
  # Should NOT contain 192.0.2.1 or LAB22C comment
  dig redhat.com +short
  # Should return one or more IP addresses

EOF
}

hint_step_2() {
    echo "  Open the file and change gateway=10.99.2.1 to gateway=10.99.1.1"
    echo "  Then: nmcli connection reload"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Fix the misconfigured gateway in the NetworkManager profile

The lab22c-broken profile has gateway=10.99.2.1, but the interface address
is 10.99.1.100/24. A /24 subnet covers 10.99.1.0 - 10.99.1.255. The gateway
10.99.2.1 is in a DIFFERENT subnet — the kernel cannot reach it directly and
will refuse to use it as a gateway.

Requirements:
  • Inspect the profile and confirm the misconfiguration
  • Change gateway=10.99.2.1 to gateway=10.99.1.1 in the file
  • Run nmcli connection reload so NetworkManager picks up the change
  • Verify the change is present in the file

Commands you might need:
  • cat /etc/NetworkManager/system-connections/lab22c-broken.nmconnection
  • vi /etc/NetworkManager/system-connections/lab22c-broken.nmconnection
  • nmcli connection reload
  • nmcli connection show lab22c-broken
EOF
}

validate_step_2() {
    local profile="/etc/NetworkManager/system-connections/lab22c-broken.nmconnection"

    if ! grep -q "gateway=10.99.1.1" "$profile" 2>/dev/null; then
        echo ""
        local current_gw
        current_gw=$(grep "^gateway=" "$profile" 2>/dev/null || echo "not found")
        print_color "$RED" "✗ Gateway is not set to 10.99.1.1 in lab22c-broken.nmconnection"
        echo "  Current: $current_gw"
        echo "  Fix: Change gateway=10.99.2.1 to gateway=10.99.1.1 in the profile"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cat /etc/NetworkManager/system-connections/lab22c-broken.nmconnection
  # Observe: address1=10.99.1.100/24 and gateway=10.99.2.1

  # Fix: the gateway must be within the 10.99.1.0/24 subnet
  sed -i 's/gateway=10.99.2.1/gateway=10.99.1.1/' \
      /etc/NetworkManager/system-connections/lab22c-broken.nmconnection

  nmcli connection reload

  grep gateway /etc/NetworkManager/system-connections/lab22c-broken.nmconnection
  # Verify: gateway=10.99.1.1

Why the gateway must be in the local subnet:
  The kernel routes traffic by checking: "Is the destination in my local subnet?
  If yes, send directly. If no, send to the gateway."
  If the gateway itself is not in the local subnet, the kernel can't reach it
  directly — and you have a recursive routing problem. This is the most common
  misconfiguration for newly provisioned interfaces.

  Subnet math check:
    address: 10.99.1.100
    mask:    /24 = 255.255.255.0
    network: 10.99.1.0  (first 3 octets locked)
    valid range: 10.99.1.1 - 10.99.1.254
    gateway 10.99.2.1 → starts with 10.99.2 → DIFFERENT network → invalid

nmcli connection reload vs restart:
  reload: tells NM to re-read all connection files from disk. Existing active
          connections are NOT disconnected; the new config applies on next activation.
  nmcli connection up <name>: activates (or re-activates) a specific connection.
  systemctl restart NetworkManager: restarts the entire NM daemon — more disruptive.
  For editing inactive profiles (like this one), 'reload' is sufficient.

Verification:
  grep gateway /etc/NetworkManager/system-connections/lab22c-broken.nmconnection
  # Expected: gateway=10.99.1.1

EOF
}

hint_step_3() {
    echo "  Run: vmstat 2 5"
    echo "  Focus on: r (run queue), si/so (swap), bi/bo (disk I/O)"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Collect a performance snapshot with vmstat

Run vmstat with a 2-second interval for 5 samples. Read and interpret
the output. This is the data you would include in a 'sos report' or
provide to Red Hat support as a performance baseline.

Requirements:
  • Run: vmstat 2 5
  • Identify and explain what each of these columns means:
    r, b, si, so, bi, bo, us, sy, id, wa
  • Run 'free -h' and interpret the output
  • Run 'top' briefly (press q to quit) — note the load average line

Commands you might need:
  • vmstat 2 5
  • free -h
  • top  (then press q to quit)
  • uptime  (shows load averages without entering top)
EOF
}

validate_step_3() {
    # Observational — verify vmstat is available and functional
    if vmstat 1 1 >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ vmstat is not responding"
    echo "  Install: dnf install procps-ng"
    return 1
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  vmstat 2 5
  free -h
  uptime

vmstat output columns explained:
  PROCS:
    r  = processes in run queue (waiting for CPU). Values consistently > number
         of CPU cores indicate CPU saturation.
    b  = processes blocked waiting for I/O. High values indicate disk/network
         bottleneck.

  MEMORY (in KB):
    swpd = virtual memory in use (swap). Non-zero means RAM pressure.
    free = idle/unused RAM.
    buff = memory used as I/O buffers.
    cache = memory used as filesystem cache (this is GOOD — it's recyclable).

  SWAP:
    si = swap in (pages read from swap to RAM) — memory pressure indicator
    so = swap out (pages written from RAM to swap)
    Both non-zero simultaneously = active swapping = performance problem.

  I/O (blocks per second):
    bi = blocks received from block device (reads)
    bo = blocks sent to block device (writes)
    High bi/bo means heavy disk I/O — correlate with 'b' column.

  CPU (%):
    us = user-space CPU time
    sy = kernel/system CPU time. High sy with low us = kernel bottleneck.
    id = idle CPU. Low id = CPU busy.
    wa = wait for I/O. High wa = processes blocked on disk/network I/O.

NOTE — first row is averages since boot:
  The first vmstat line averages all values since the system started. All
  subsequent rows (one per interval) are live snapshots. Diagnose from the
  interval rows, not the first row.

free -h output:
  total  = physical RAM installed
  used   = RAM actively in use by processes
  free   = completely unused RAM (often low — Linux uses this for cache)
  buff/cache = I/O buffers and page cache (Linux reclaims this when needed)
  available = estimated RAM available without swapping (more useful than 'free')

The key metric for memory health is 'available', not 'free'.
A system with 100MB free but 8GB available is fine — it's using RAM as cache.
A system with 100MB available is approaching memory pressure.

Verification:
  vmstat 2 5
  # Look for:
  #   r consistently < number of CPU cores → CPU healthy
  #   si and so both = 0 → no active swapping
  #   wa < 5% → disk I/O not causing bottlenecks

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=2

    echo "Checking your configuration..."
    echo ""

    print_color "$CYAN" "[1/$total] Checking /etc/resolv.conf does not contain 192.0.2.1..."
    if ! grep -q "192.0.2.1" /etc/resolv.conf 2>/dev/null && \
       ! grep -q "LAB22C" /etc/resolv.conf 2>/dev/null; then
        print_color "$GREEN" "  ✓ Broken nameserver removed from /etc/resolv.conf"
        ((score++))
    else
        print_color "$RED" "  ✗ 192.0.2.1 or lab injection still present in /etc/resolv.conf"
        print_color "$YELLOW" "  Fix: cp /etc/resolv.conf.lab-backup /etc/resolv.conf"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking lab22c-broken.nmconnection has correct gateway..."
    local profile="/etc/NetworkManager/system-connections/lab22c-broken.nmconnection"
    if grep -q "gateway=10.99.1.1" "$profile" 2>/dev/null; then
        print_color "$GREEN" "  ✓ Gateway correctly set to 10.99.1.1"
        ((score++))
    else
        local current_gw
        current_gw=$(grep "^gateway=" "$profile" 2>/dev/null | head -1 || echo "not found")
        print_color "$RED" "  ✗ Gateway is not 10.99.1.1 (current: $current_gw)"
        print_color "$YELLOW" "  Fix: Edit the profile and change gateway to 10.99.1.1, then nmcli connection reload"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "DNS and network config fixed. Review the vmstat solution output to"
        echo "ensure you can interpret performance data for the exam."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
        echo "Run with --solution to see detailed steps."
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
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Fix /etc/resolv.conf
─────────────────────────────────────────────────────────────────
  cat /etc/resolv.conf           # identify 192.0.2.1
  cp /etc/resolv.conf.lab-backup /etc/resolv.conf
  dig redhat.com +short          # verify DNS works


STEP 2: Fix the NetworkManager gateway
─────────────────────────────────────────────────────────────────
  cat /etc/NetworkManager/system-connections/lab22c-broken.nmconnection
  sed -i 's/gateway=10.99.2.1/gateway=10.99.1.1/' \
      /etc/NetworkManager/system-connections/lab22c-broken.nmconnection
  nmcli connection reload
  grep gateway /etc/NetworkManager/system-connections/lab22c-broken.nmconnection


STEP 3: Collect performance data
─────────────────────────────────────────────────────────────────
  vmstat 2 5
  free -h
  uptime


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The Four Performance Areas (from lesson 22.6):
  Memory:  free -h, vmstat (swpd, si, so), /proc/meminfo
  CPU:     top, vmstat (r, us, sy, id), uptime (load average)
  Disk:    vmstat (b, bi, bo, wa), iostat, iotop
  Network: ss -tuln, ip -s link, sar -n DEV

Load Average (from uptime / top):
  Three numbers: 1-minute, 5-minute, 15-minute averages
  Value = average number of processes in run queue + waiting for CPU
  Healthy: consistently below number of CPU cores (check: nproc)
  Warning: consistently above nproc for 5+ minutes → CPU saturation

When to Use sos report:
  'sos report' collects a comprehensive snapshot (logs, config, hardware info,
  performance data) into a tarball for Red Hat support. Run it before making
  any changes so support has a baseline. The output path is printed when complete.
  Requires: dnf install sos


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Reading only the first vmstat row for diagnostics
  Result: Making decisions based on boot-time averages, not current state
  Fix: Always use interval mode (vmstat 2 N) and read the interval rows

Mistake 2: Assuming low 'free' memory means a problem
  Result: Unnecessary memory upgrades or tuning
  Fix: Read 'available' column — Linux intentionally uses free RAM as cache

Mistake 3: Editing NM connection files without running nmcli connection reload
  Result: Changes on disk but NM is still using the old in-memory config
  Fix: Always reload or restart NM after editing connection files directly


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DNS not working → check /etc/resolv.conf first, then test with dig
2. Gateway unreachable → confirm it's in the same subnet as the interface
3. Wrong subnet mask → all hosts in the same logical network must share the same prefix
4. vmstat si/so both > 0 → active swapping = memory problem
5. vmstat wa > 10% → processes blocked on disk → I/O bottleneck
6. Know: ss -tuln (listening ports), ip route (routing table), ip addr (addresses)

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    # Restore resolv.conf
    if [ -f /etc/resolv.conf.lab-backup ]; then
        cp /etc/resolv.conf.lab-backup /etc/resolv.conf
        rm -f /etc/resolv.conf.lab-backup
        echo "  ✓ /etc/resolv.conf restored from backup"
    else
        # Remove the injection if backup is gone
        sed -i '/LAB22C-INJECTED/d; /192.0.2.1/d' /etc/resolv.conf 2>/dev/null || true
        echo "  ✓ Removed lab injection from /etc/resolv.conf"
    fi

    # Remove the broken NM profile
    rm -f /etc/NetworkManager/system-connections/lab22c-broken.nmconnection 2>/dev/null || true
    nmcli connection reload 2>/dev/null || true

    echo "  ✓ Removed lab22c-broken NetworkManager profile"
}

main "$@"
