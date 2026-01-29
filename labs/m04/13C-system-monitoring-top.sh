#!/bin/bash
# labs/m04/13C-system-monitoring-top.sh
# Lab: System monitoring with top and resource analysis
# Difficulty: Intermediate
# RHCSA Objective: 13.5, 13.6, 13.7 - Memory usage, CPU load, and top monitoring

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="System monitoring with top and resource analysis"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="40-50 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    pkill -u $(whoami) -f "stress-ng" 2>/dev/null || true
    pkill -u $(whoami) -f "memory-hog" 2>/dev/null || true
    rm -f /tmp/memory-hog.sh 2>/dev/null || true
    rm -f /tmp/cpu-burner.sh 2>/dev/null || true
    rm -rf /tmp/monitoring-lab 2>/dev/null || true
    
    # Install stress-ng if not present
    if ! command -v stress-ng >/dev/null 2>&1; then
        echo "  Installing stress-ng..."
        dnf install -y stress-ng >/dev/null 2>&1
    fi
    
    # Create working directory
    mkdir -p /tmp/monitoring-lab
    
    # Create a memory hog script
    cat > /tmp/memory-hog.sh << 'SCRIPT'
#!/bin/bash
# Allocates memory slowly
data=""
for i in {1..1000}; do
    data="$data$(head -c 1M /dev/zero | tr '\0' 'X')"
    sleep 0.1
done
sleep 300
SCRIPT
    chmod +x /tmp/memory-hog.sh
    
    # Create a CPU burner script
    cat > /tmp/cpu-burner.sh << 'SCRIPT'
#!/bin/bash
# Burns CPU cycles
while true; do
    echo "scale=5000; a(1)*4" | bc -l > /dev/null
done
SCRIPT
    chmod +x /tmp/cpu-burner.sh
    
    echo "  ✓ Cleanup complete"
    echo "  ✓ Test scripts created"
    echo "  ✓ Lab environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Process management basics
  • Understanding of CPU and memory
  • Familiarity with ps command

Commands You'll Use:
  • top - Interactive process viewer
  • uptime - System uptime and load average
  • free - Memory usage statistics
  • lscpu - CPU architecture info
  • stress-ng - Stress testing utility
  • kill - Terminate processes

Files You'll Interact With:
  • /proc/meminfo - Detailed memory information
  • /proc/cpuinfo - CPU information
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your production server is experiencing performance degradation. Users report
applications are slow, and some services are timing out. You must identify
the cause using system monitoring tools, determine which processes are
consuming excessive resources, and take corrective action.

BACKGROUND:
System monitoring is a critical skill for troubleshooting performance issues.
Understanding CPU load averages, memory usage (RAM vs cache), and how to use
top effectively will help you quickly identify and resolve problems.

OBJECTIVES:
  1. Analyze system baseline metrics
     • Check how many CPU cores the system has
     • Determine total available memory
     • View current load average
     • Calculate if load average is healthy
     • Determine how much swap is configured

  2. Identify a memory leak
     • A process will be consuming excessive memory
     • Use top to find the memory hog
     • Identify the PID of the top memory consumer
     • Calculate how much RAM it's using
     • Terminate the process

  3. Diagnose CPU overload
     • Multiple CPU-intensive processes will be running
     • Find which processes are using >50% CPU
     • Calculate the total CPU usage
     • Kill all CPU-hogging processes
     • Verify CPU usage returns to normal

  4. Analyze memory usage patterns
     • Check available vs free memory
     • Understand the difference
     • Identify how much memory is cached
     • Determine if swap is being used
     • Calculate actual memory pressure

  5. Monitor system recovery
     • Verify all problem processes are terminated
     • Confirm CPU load has normalized
     • Check memory has been freed
     • Verify load average is healthy
     • Confirm system is stable

HINTS:
  • Use lscpu to count CPU cores
  • Load average should be <= number of cores
  • In top: Press M to sort by memory, P for CPU
  • free -h shows human-readable memory
  • available memory is what matters, not free

SUCCESS CRITERIA:
  • System baseline metrics recorded correctly
  • Memory hog process identified and killed
  • All CPU-intensive processes terminated
  • Memory freed and available increased
  • Load average returned to healthy levels
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Record system baseline (CPUs, RAM, load)
  ☐ 2. Find and kill memory hog process
  ☐ 3. Identify and kill CPU hog processes
  ☐ 4. Analyze memory usage patterns
  ☐ 5. Verify system recovery
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
Your server is under performance stress. Identify and resolve the issues.

Working directory: /tmp/monitoring-lab/

Use monitoring tools to diagnose and fix the problems.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Establish system baseline metrics

Before troubleshooting, understand your system's normal capacity.

Requirements:
  • Determine number of CPU cores
  • Check total memory (GB)
  • View current load average
  • Record current available memory
  • Calculate healthy load threshold

Record these in: /tmp/monitoring-lab/baseline.txt

Expected format:
  CPU_CORES: X
  TOTAL_MEMORY_GB: Y
  CURRENT_LOAD: X.XX
  AVAILABLE_MEMORY_GB: Y.YY
  HEALTHY_LOAD_THRESHOLD: X

Healthy load = number of CPU cores (approximately)
EOF
}

validate_step_1() {
    if [ ! -f /tmp/monitoring-lab/baseline.txt ]; then
        echo ""
        print_color "$RED" "✗ baseline.txt not found"
        echo "  Create: /tmp/monitoring-lab/baseline.txt"
        return 1
    fi
    
    # Check if file has required fields
    local required_fields=("CPU_CORES" "TOTAL_MEMORY_GB" "CURRENT_LOAD" "AVAILABLE_MEMORY_GB")
    for field in "${required_fields[@]}"; do
        if ! grep -q "^$field:" /tmp/monitoring-lab/baseline.txt; then
            echo ""
            print_color "$RED" "✗ Missing field: $field"
            return 1
        fi
    done
    
    return 0
}

hint_step_1() {
    cat << 'EOF'
  CPU cores: lscpu | grep "^CPU(s):"
  Total RAM: free -g
  Load average: uptime
  Available memory: free -h (check "available" column)
  
  Example commands:
    echo "CPU_CORES: $(nproc)" > /tmp/monitoring-lab/baseline.txt
    echo "TOTAL_MEMORY_GB: $(free -g | grep Mem | awk '{print $2}')" >> /tmp/monitoring-lab/baseline.txt
EOF
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Get CPU cores:
  lscpu | grep "^CPU(s):"
  # Or: nproc

Get total memory:
  free -g | grep Mem | awk '{print $2}'

Get load average:
  uptime | awk -F'load average:' '{print $2}'

Get available memory:
  free -h | grep Mem | awk '{print $7}'

Create baseline file:
  echo "CPU_CORES: $(nproc)" > /tmp/monitoring-lab/baseline.txt
  echo "TOTAL_MEMORY_GB: $(free -g | grep Mem | awk '{print $2}')" >> /tmp/monitoring-lab/baseline.txt
  echo "CURRENT_LOAD: $(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)" >> /tmp/monitoring-lab/baseline.txt
  echo "AVAILABLE_MEMORY_GB: $(free -g | grep Mem | awk '{print $7}')" >> /tmp/monitoring-lab/baseline.txt
  echo "HEALTHY_LOAD_THRESHOLD: $(nproc)" >> /tmp/monitoring-lab/baseline.txt

Understanding:
  CPU cores: Total processing units
  Load average: Number of processes waiting for CPU
  Healthy load: Load <= CPU cores (approximately)
  Available memory: RAM available for new processes

EOF
}

hint_step_2() {
    cat << 'EOF'
  Start memory hog: /tmp/memory-hog.sh &
  Watch in top: Press M to sort by memory
  Find PID: Look at top of list
  Memory used: Check %MEM and RES columns
  Kill it: kill PID
  Record PID: echo "MEMORY_HOG_PID: 12345" >> /tmp/monitoring-lab/findings.txt
EOF
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Identify and terminate memory leak

A process is consuming excessive memory. Find it and kill it.

Requirements:
  • Start the memory hog: /tmp/memory-hog.sh &
  • Wait 10 seconds for memory to grow
  • Use top to find the process with highest memory
  • Record the PID in /tmp/monitoring-lab/findings.txt
  • Record how much memory it's using (MB or GB)
  • Terminate the process
  • Verify it's gone

Record in findings.txt:
  MEMORY_HOG_PID: XXXX
  MEMORY_HOG_USAGE_MB: YYYY

In top:
  - Press M to sort by memory usage
  - Look at %MEM and RES columns
  - RES shows actual RAM used
  - Press q to quit top
EOF
}

validate_step_2() {
    # Check findings file exists
    if [ ! -f /tmp/monitoring-lab/findings.txt ]; then
        echo ""
        print_color "$RED" "✗ findings.txt not found"
        return 1
    fi
    
    # Check if memory hog is killed
    if pgrep -u $(whoami) -f "memory-hog" >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Memory hog still running"
        echo "  Find PID: pgrep -f memory-hog"
        echo "  Kill it: kill \$(pgrep -f memory-hog)"
        return 1
    fi
    
    # Check if PID was recorded
    if ! grep -q "MEMORY_HOG_PID:" /tmp/monitoring-lab/findings.txt; then
        echo ""
        print_color "$YELLOW" "  Note: PID not recorded in findings.txt"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Start the memory hog:
  /tmp/memory-hog.sh &

Wait for memory to grow:
  sleep 10

Open top:
  top

In top:
  Press M (sort by memory)
  Look for memory-hog.sh at top
  Note the PID (first column)
  Note RES (resident memory)
  Press q to quit

Or use ps:
  ps aux --sort=-%mem | head -5

Find the PID:
  pgrep -f memory-hog

Record findings:
  PID=$(pgrep -f memory-hog)
  MEM=$(ps -p $PID -o rss= 2>/dev/null | awk '{print $1/1024}')
  
  echo "MEMORY_HOG_PID: $PID" >> /tmp/monitoring-lab/findings.txt
  echo "MEMORY_HOG_USAGE_MB: $MEM" >> /tmp/monitoring-lab/findings.txt

Kill the process:
  kill $(pgrep -f memory-hog)

Verify it's gone:
  pgrep -f memory-hog
  # Should return nothing

Understanding:
  RES (Resident): Actual RAM used
  %MEM: Percentage of total RAM
  Memory leaks grow over time
  Kill them to free memory

EOF
}

hint_step_3() {
    cat << 'EOF'
  Start 3 processes:
    stress-ng --cpu 1 --timeout 300 &
    stress-ng --cpu 1 --timeout 300 &
    stress-ng --cpu 1 --timeout 300 &
  
  Wait: sleep 5
  
  Find them: top (press P) or ps aux --sort=-%cpu | head
  
  Get PIDs: pgrep -f stress-ng
  
  Kill all: pkill -f stress-ng
  
  Record: echo "CPU_HOG_PIDS: $(pgrep -f stress-ng | tr '\n' ',')" >> findings.txt
EOF
}

# STEP 3
show_step_3() {
    # Auto-start CPU stress processes when this step begins
    if ! pgrep -u $(whoami) -f "stress-ng --cpu" >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "Starting CPU stress processes..."
        stress-ng --cpu 1 --timeout 300 >/dev/null 2>&1 &
        stress-ng --cpu 1 --timeout 300 >/dev/null 2>&1 &
        stress-ng --cpu 1 --timeout 300 >/dev/null 2>&1 &
        sleep 3
        print_color "$GREEN" "✓ 3 CPU-intensive processes started"
        echo ""
    fi
    
    cat << 'EOF'
TASK: Eliminate CPU overload

CPU-intensive processes are now running. Find and kill them ALL.

Requirements:
  • Use top or ps to find processes with >50% CPU
  
  • List ALL PIDs consuming excessive CPU
  
  • Record the PIDs in findings.txt:
    CPU_HOG_PIDS: PID1,PID2,PID3
  
  • Kill ALL of them
  
  • Verify CPU usage drops significantly

In top:
  - Press P to sort by CPU
  - Look at %CPU column
  - stress-ng processes should show high CPU
  - Note ALL their PIDs
  - Press q to quit

You must kill ALL 3 CPU hogs for this step to pass.
EOF
}

validate_step_3() {
    # Check if CPU hogs are still running
    local cpu_hogs=$(pgrep -u $(whoami) -f "stress-ng --cpu" 2>/dev/null | wc -l)
    
    if [ "$cpu_hogs" -gt 0 ]; then
        echo ""
        print_color "$RED" "✗ $cpu_hogs CPU hog process(es) still running"
        echo "  Find them: pgrep -f stress-ng"
        echo "  Kill them: pkill -f stress-ng"
        return 1
    fi
    
    # Check findings file
    if [ ! -f /tmp/monitoring-lab/findings.txt ]; then
        echo ""
        print_color "$YELLOW" "  Note: findings.txt not found"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Start 3 CPU stress processes:
  stress-ng --cpu 1 --timeout 300 &
  stress-ng --cpu 1 --timeout 300 &
  stress-ng --cpu 1 --timeout 300 &

Wait for them to ramp up:
  sleep 5

Find CPU hogs with top:
  top
  Press P (sort by CPU)
  Look for stress-ng processes with high %CPU
  Note all 3 PIDs
  Press q to quit

Or use ps:
  ps aux --sort=-%cpu | head -10
  # stress-ng processes should be at top

Find all stress-ng PIDs:
  pgrep -f stress-ng

Record PIDs:
  PIDS=$(pgrep -f stress-ng | tr '\n' ',' | sed 's/,$//')
  echo "CPU_HOG_PIDS: $PIDS" >> /tmp/monitoring-lab/findings.txt

Kill all CPU hogs:
  pkill -f stress-ng
  
  Or individually:
  kill $(pgrep -f stress-ng)

Verify they're gone:
  pgrep -f stress-ng
  # Should return nothing

Check CPU usage normalized:
  top
  # Look at %Cpu(s) line
  # id (idle) should be high
  # us (user) should be low

Understanding:
  %CPU can exceed 100% on multi-core
  Each stress-ng uses ~100% of one core
  3 processes = ~300% total on 4-core system
  Kill them to free CPU cycles
  Load average will drop after killing

EOF
}

hint_step_4() {
    cat << 'EOF'
  Check memory: free -h
  Detailed info: cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Cached"
  Available vs Free: Different!
  Cache is reclaimable: Not a problem
  Swap used: Check if any active swapping
EOF
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Analyze memory usage and understand what's normal

Understand the difference between free, available, and cached memory.

Requirements:
  • Check total, free, and available memory
  • Identify how much is cached
  • Check if swap is being used
  • Determine actual memory pressure
  • Record analysis in findings.txt

Record in findings.txt:
  MEMORY_CACHED_GB: X.X
  SWAP_USED_GB: X.X
  MEMORY_PRESSURE: [LOW/MEDIUM/HIGH]

Memory pressure levels:
  LOW: Available > 50% of total
  MEDIUM: Available 20-50% of total
  HIGH: Available < 20% of total

Understanding:
  - free: Completely unused (usually low)
  - available: Can be freed if needed (what matters)
  - cached: File cache (automatically freed when needed)
  - Cached memory is NOT a problem
EOF
}

validate_step_4() {
    if [ ! -f /tmp/monitoring-lab/findings.txt ]; then
        echo ""
        print_color "$RED" "✗ findings.txt not found"
        return 1
    fi
    
    # Check for required fields
    if ! grep -q "MEMORY_PRESSURE:" /tmp/monitoring-lab/findings.txt; then
        echo ""
        print_color "$RED" "✗ MEMORY_PRESSURE not recorded"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Check memory with free:
  free -h

Output columns:
  total: Total RAM
  used: RAM in use (includes cache)
  free: Completely unused
  shared: Shared between processes
  buff/cache: Buffers and cache
  available: RAM available for new processes

Get specific values:
  TOTAL=$(free -g | grep Mem | awk '{print $2}')
  AVAIL=$(free -g | grep Mem | awk '{print $7}')
  CACHED=$(free -g | grep Mem | awk '{print $6}')
  SWAP_USED=$(free -g | grep Swap | awk '{print $3}')

Calculate memory pressure:
  PERCENT=$((AVAIL * 100 / TOTAL))
  
  If PERCENT > 50: LOW
  If PERCENT 20-50: MEDIUM
  If PERCENT < 20: HIGH

Check detailed memory:
  cat /proc/meminfo | head -20

Record analysis using echo:
  echo "MEMORY_CACHED_GB: $CACHED" >> /tmp/monitoring-lab/findings.txt
  echo "SWAP_USED_GB: $SWAP_USED" >> /tmp/monitoring-lab/findings.txt
  echo "MEMORY_PRESSURE: LOW" >> /tmp/monitoring-lab/findings.txt

Understanding memory:
  Free memory is normal to be low
  Linux uses unused RAM for cache
  Cache is automatically freed when needed
  Available memory is what matters
  
  High cache = Good (fast file access)
  Low available = Bad (memory pressure)
  Swap usage = OK if not constantly swapping
  Active swapping = Problem (thrashing)

Check for swapping:
  vmstat 1 5
  # Watch si (swap in) and so (swap out)
  # High values = active swapping = bad

EOF
}

hint_step_5() {
    cat << 'EOF'
  Check load: uptime
  List processes: ps aux | wc -l
  Verify no stress: pgrep stress-ng
  Check CPU idle: top (look at %id)
  Check memory: free -h
EOF
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Verify complete system recovery

Confirm all issues are resolved and system is healthy.

Requirements:
  • Check current load average
  • Verify it's below healthy threshold
  • Confirm no stress processes remain
  • Check CPU idle percentage is high (>90%)
  • Verify memory is available
  • Record final status in findings.txt

Record in findings.txt:
  FINAL_LOAD: X.XX
  LOAD_HEALTHY: [YES/NO]
  CPU_IDLE_PERCENT: XX
  SYSTEM_STATUS: [HEALTHY/DEGRADED]

System is HEALTHY if:
  - Load <= CPU cores
  - No rogue processes
  - CPU idle >90%
  - Memory available >20%
EOF
}

validate_step_5() {
    # Check no test processes remain
    local stress_count=$(pgrep -u $(whoami) -f "stress-ng\|memory-hog\|cpu-burner" 2>/dev/null | wc -l)
    
    if [ "$stress_count" -gt 0 ]; then
        echo ""
        print_color "$RED" "✗ Test processes still running"
        echo "  Clean up: pkill -f 'stress-ng'; pkill -f 'memory-hog'; pkill -f 'cpu-burner'"
        return 1
    fi
    
    # Check findings file
    if [ ! -f /tmp/monitoring-lab/findings.txt ]; then
        echo ""
        print_color "$RED" "✗ findings.txt not found"
        return 1
    fi
    
    if ! grep -q "SYSTEM_STATUS:" /tmp/monitoring-lab/findings.txt; then
        echo ""
        print_color "$YELLOW" "  Note: SYSTEM_STATUS not recorded"
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Check current load:
  uptime

Get load average:
  LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)

Compare to threshold:
  CORES=$(nproc)
  # If LOAD <= CORES, then healthy

Verify no stress processes:
  pgrep -f stress-ng
  pgrep -f memory-hog
  pgrep -f cpu-burner
  # All should return nothing

Check CPU usage in top:
  top
  # Look at %Cpu(s) line
  # id (idle) should be >90%

Check memory:
  free -h
  # available should be reasonable

Calculate CPU idle:
  IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)

Record final status using echo:
  echo "FINAL_LOAD: $LOAD" >> /tmp/monitoring-lab/findings.txt
  echo "LOAD_HEALTHY: YES" >> /tmp/monitoring-lab/findings.txt
  echo "CPU_IDLE_PERCENT: $IDLE" >> /tmp/monitoring-lab/findings.txt
  echo "SYSTEM_STATUS: HEALTHY" >> /tmp/monitoring-lab/findings.txt

Verify everything:
  cat /tmp/monitoring-lab/findings.txt

Understanding recovery:
  Load drops after killing CPU hogs
  Memory freed after killing leaks
  System returns to normal
  Cache remains (that's good)
  
  Healthy system characteristics:
  - Load <= CPU cores
  - High CPU idle
  - Reasonable memory available
  - No rogue processes
  - Low wait times

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your system monitoring work..."
    echo ""
    
    # CHECK 1: Baseline recorded
    print_color "$CYAN" "[1/$total] Checking baseline metrics..."
    if [ -f /tmp/monitoring-lab/baseline.txt ] && \
       grep -q "CPU_CORES:" /tmp/monitoring-lab/baseline.txt; then
        print_color "$GREEN" "  ✓ System baseline recorded"
        ((score++))
    else
        print_color "$RED" "  ✗ Baseline not properly recorded"
        print_color "$YELLOW" "  Create: /tmp/monitoring-lab/baseline.txt"
    fi
    echo ""
    
    # CHECK 2: Memory hog killed
    print_color "$CYAN" "[2/$total] Checking memory hog cleanup..."
    if ! pgrep -u $(whoami) -f "memory-hog" >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Memory hog process terminated"
        ((score++))
    else
        print_color "$RED" "  ✗ Memory hog still running"
        print_color "$YELLOW" "  Kill it: pkill -f memory-hog"
    fi
    echo ""
    
    # CHECK 3: CPU hogs killed
    print_color "$CYAN" "[3/$total] Checking CPU hog cleanup..."
    local cpu_count=$(pgrep -u $(whoami) -f "stress-ng" 2>/dev/null | wc -l)
    if [ "$cpu_count" -eq 0 ]; then
        print_color "$GREEN" "  ✓ All CPU hogs terminated"
        ((score++))
    else
        print_color "$RED" "  ✗ $cpu_count CPU hog(s) still running"
        print_color "$YELLOW" "  Kill them: pkill -f stress-ng"
    fi
    echo ""
    
    # CHECK 4: Memory analysis
    print_color "$CYAN" "[4/$total] Checking memory analysis..."
    if [ -f /tmp/monitoring-lab/findings.txt ] && \
       grep -q "MEMORY_PRESSURE:" /tmp/monitoring-lab/findings.txt; then
        print_color "$GREEN" "  ✓ Memory analysis completed"
        ((score++))
    else
        print_color "$RED" "  ✗ Memory analysis not recorded"
    fi
    echo ""
    
    # CHECK 5: System recovery
    print_color "$CYAN" "[5/$total] Checking system recovery..."
    local all_clean=$(pgrep -u $(whoami) -f "stress-ng\|memory-hog\|cpu-burner" 2>/dev/null | wc -l)
    if [ "$all_clean" -eq 0 ]; then
        print_color "$GREEN" "  ✓ System recovered and clean"
        ((score++))
    else
        print_color "$RED" "  ✗ Test processes still active"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent troubleshooting! You successfully:"
        echo "  • Established system baseline metrics"
        echo "  • Identified and killed memory leak"
        echo "  • Eliminated CPU overload"
        echo "  • Analyzed memory usage correctly"
        echo "  • Verified complete system recovery"
        echo ""
        echo "You can now diagnose real performance issues!"
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

STEP 1: Establish baseline
─────────────────────────────────────────────────────────────────
lscpu | grep "^CPU(s):"
free -h
uptime

echo "CPU_CORES: $(nproc)" > /tmp/monitoring-lab/baseline.txt
echo "TOTAL_MEMORY_GB: $(free -g | grep Mem | awk '{print $2}')" >> /tmp/monitoring-lab/baseline.txt
echo "CURRENT_LOAD: $(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)" >> /tmp/monitoring-lab/baseline.txt
echo "AVAILABLE_MEMORY_GB: $(free -g | grep Mem | awk '{print $7}')" >> /tmp/monitoring-lab/baseline.txt
echo "HEALTHY_LOAD_THRESHOLD: $(nproc)" >> /tmp/monitoring-lab/baseline.txt


STEP 2: Kill memory hog
─────────────────────────────────────────────────────────────────
/tmp/memory-hog.sh &
sleep 10
top  # Press M, note PID
kill $(pgrep -f memory-hog)

echo "MEMORY_HOG_PID: $(pgrep -f memory-hog)" >> /tmp/monitoring-lab/findings.txt


STEP 3: Kill CPU hogs
─────────────────────────────────────────────────────────────────
stress-ng --cpu 1 --timeout 300 &
stress-ng --cpu 1 --timeout 300 &
stress-ng --cpu 1 --timeout 300 &
sleep 5

top  # Press P to see CPU usage
pgrep -f stress-ng
pkill -f stress-ng

echo "CPU_HOG_PIDS: $(pgrep -f stress-ng | tr '\n' ',')" >> /tmp/monitoring-lab/findings.txt


STEP 4: Analyze memory
─────────────────────────────────────────────────────────────────
free -h
cat /proc/meminfo | head -20

echo "MEMORY_CACHED_GB: $(free -g | grep Mem | awk '{print $6}')" >> /tmp/monitoring-lab/findings.txt
echo "SWAP_USED_GB: $(free -g | grep Swap | awk '{print $3}')" >> /tmp/monitoring-lab/findings.txt
echo "MEMORY_PRESSURE: LOW" >> /tmp/monitoring-lab/findings.txt


STEP 5: Verify recovery
─────────────────────────────────────────────────────────────────
uptime
top  # Check CPU idle
free -h

echo "FINAL_LOAD: $(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)" >> /tmp/monitoring-lab/findings.txt
echo "LOAD_HEALTHY: YES" >> /tmp/monitoring-lab/findings.txt
echo "CPU_IDLE_PERCENT: 95" >> /tmp/monitoring-lab/findings.txt
echo "SYSTEM_STATUS: HEALTHY" >> /tmp/monitoring-lab/findings.txt


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Load average:
  1, 5, 15 minute averages
  Should be <= CPU cores
  >cores = CPU bottleneck

Memory types:
  free: Completely unused
  available: Can be freed (what matters)
  cached: File cache (reclaimable)
  
Top shortcuts:
  M - Sort by memory
  P - Sort by CPU
  k - Kill process
  q - Quit

System health:
  Load <= cores
  CPU idle >90%
  Memory available >20%
  No swap thrashing


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical commands:
1. top - Interactive monitoring
2. free -h - Memory overview
3. uptime - Load average
4. lscpu - CPU info
5. ps aux --sort=-%cpu - CPU hogs

Quick checks:
  Load: uptime
  Memory: free -h
  CPU: top, press P
  Kill: pkill NAME

Remember:
  Cached memory is normal
  Available matters, not free
  Load should match cores
  Top is your friend

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Kill all test processes
    pkill -u $(whoami) -f "stress-ng" 2>/dev/null || true
    pkill -u $(whoami) -f "memory-hog" 2>/dev/null || true
    pkill -u $(whoami) -f "cpu-burner" 2>/dev/null || true
    
    # Remove test files
    rm -f /tmp/memory-hog.sh 2>/dev/null || true
    rm -f /tmp/cpu-burner.sh 2>/dev/null || true
    rm -rf /tmp/monitoring-lab 2>/dev/null || true
    
    echo "  ✓ All test processes terminated"
    echo "  ✓ Test files removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
