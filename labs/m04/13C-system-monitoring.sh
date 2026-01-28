#!/bin/bash
# labs/m04/13C-system-monitoring.sh
# Lab: System monitoring with top, memory, and CPU analysis
# Difficulty: Intermediate
# RHCSA Objective: 13.5, 13.6, 13.7 - Memory usage, CPU load, and top

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="System monitoring with top, memory, and CPU analysis"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    pkill -u $(whoami) -f "stress-ng" 2>/dev/null || true
    pkill -u $(whoami) -f "dd if=/dev/zero" 2>/dev/null || true
    rm -f /tmp/lab-memory-check.txt 2>/dev/null || true
    rm -f /tmp/lab-cpu-check.txt 2>/dev/null || true
    rm -f /tmp/lab-top-check.txt 2>/dev/null || true
    
    # Install required tools
    if ! command -v stress-ng >/dev/null 2>&1; then
        echo "  Installing stress-ng..."
        dnf install -y stress-ng >/dev/null 2>&1
    fi
    
    # Create working directory
    mkdir -p /tmp/monitor-lab 2>/dev/null || true
    
    echo "  ✓ Previous lab data cleaned"
    echo "  ✓ Monitoring tools ready"
    echo "  ✓ Lab environment prepared"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of processes and PIDs
  • Basic memory concepts (RAM, swap)
  • CPU and load average basics

Commands You'll Use:
  • free - Display memory usage
  • uptime - Show system uptime and load
  • top - Interactive process viewer
  • lscpu - Display CPU information

Files You'll Interact With:
  • /proc/meminfo - Detailed memory statistics
  • /tmp/monitor-lab/ - Lab output directory
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your server is experiencing performance issues. Users report slowness and
you need to investigate. You'll analyze memory usage, check CPU load, and
use top to identify resource-consuming processes. Document your findings
for the team.

BACKGROUND:
System monitoring is critical for troubleshooting. Understanding memory
(RAM vs swap), CPU load averages, and using top effectively are essential
RHCSA skills. You need concrete data to make informed decisions.

OBJECTIVES:
  1. Analyze system memory and document findings
     • Check total, used, and available memory
     • Understand buffers and cache
     • Calculate percentage of memory used
     • Document in /tmp/monitor-lab/memory-report.txt
     • Include: Total RAM, Used, Available, Swap status

  2. Measure CPU load and core count
     • Check system load averages (1, 5, 15 min)
     • Determine number of CPU cores
     • Calculate if load is acceptable
     • Document in /tmp/monitor-lab/cpu-report.txt
     • Include: Load averages, CPU cores, Load/core ratio

  3. Create high CPU load and identify it
     • Start a CPU-intensive process
     • Use top to identify the process
     • Document PID and %CPU usage
     • Save findings to /tmp/monitor-lab/top-cpu.txt
     • Must show PID, COMMAND, and %CPU

  4. Create memory pressure and monitor it
     • Start a memory-consuming process
     • Watch memory usage change with free
     • Identify process in top by memory
     • Document in /tmp/monitor-lab/top-memory.txt
     • Show PID, COMMAND, and %MEM

  5. Use top interactively to sort and filter
     • Sort by CPU usage
     • Sort by memory usage
     • Filter to show only your processes
     • Save top configuration
     • Document sorting keys used

HINTS:
  • free -h shows human-readable sizes
  • uptime shows load averages
  • lscpu | grep "^CPU(s)" shows core count
  • In top: M sorts by memory, P sorts by CPU
  • top -u $(whoami) shows only your processes

SUCCESS CRITERIA:
  • Memory report exists with correct data
  • CPU report shows load analysis
  • High CPU process documented with PID
  • Memory-intensive process documented
  • Understanding of top commands demonstrated
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Analyze and document memory usage
  ☐ 2. Measure and document CPU load
  ☐ 3. Create high CPU load and identify it
  ☐ 4. Create memory pressure and document it
  ☐ 5. Master top sorting and filtering
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
You are investigating server performance issues.

Output directory: /tmp/monitor-lab/

Document your findings in report files for validation.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Analyze system memory and create a report

Real-world scenario: Your manager asks "How much memory do we have and 
how much is being used?" You need concrete numbers.

Requirements:
  • Use free -h to check memory
  • Use free -m for calculations
  • Create /tmp/monitor-lab/memory-report.txt containing:
    - Total RAM (in MB or GB)
    - Used memory
    - Available memory
    - Swap total and used
    - Your interpretation (is memory healthy?)

Example report format:
  Total RAM: 4096 MB
  Used: 2048 MB
  Available: 1800 MB
  Swap Total: 2048 MB
  Swap Used: 0 MB
  Status: Healthy - plenty of free memory

Understanding:
  - "available" is what's actually usable (includes reclaimable cache)
  - High swap usage indicates memory pressure
  - Buffers/cache is memory used for performance, can be freed
EOF
}

validate_step_1() {
    if [ ! -f /tmp/monitor-lab/memory-report.txt ]; then
        echo ""
        print_color "$RED" "✗ Memory report not found"
        echo "  Create: /tmp/monitor-lab/memory-report.txt"
        echo "  Include: Total RAM, Used, Available, Swap status"
        return 1
    fi
    
    # Check if file has content
    if [ ! -s /tmp/monitor-lab/memory-report.txt ]; then
        echo ""
        print_color "$RED" "✗ Memory report is empty"
        return 1
    fi
    
    # Check for key terms
    local has_total=$(grep -i "total" /tmp/monitor-lab/memory-report.txt | wc -l)
    local has_memory=$(grep -i -E "memory|ram|used|available" /tmp/monitor-lab/memory-report.txt | wc -l)
    
    if [ "$has_total" -lt 1 ] || [ "$has_memory" -lt 2 ]; then
        echo ""
        print_color "$YELLOW" "  Warning: Report may be incomplete"
        echo "  Should include: Total, Used, Available, Swap"
    fi
    
    return 0
}

hint_step_1() {
    cat << 'EOF'
  Check memory: free -h
  Get numbers: free -m
  Create file: vim /tmp/monitor-lab/memory-report.txt
  Or redirect: free -h > /tmp/monitor-lab/memory-report.txt
  Then add your analysis
EOF
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Check memory:
  free -h
  free -m

Create report:
  cat > /tmp/monitor-lab/memory-report.txt << 'REPORT'
MEMORY ANALYSIS REPORT
======================

Total RAM: $(free -h | awk '/^Mem:/ {print $2}')
Used: $(free -h | awk '/^Mem:/ {print $3}')
Available: $(free -h | awk '/^Mem:/ {print $7}')

Swap Total: $(free -h | awk '/^Swap:/ {print $2}')
Swap Used: $(free -h | awk '/^Swap:/ {print $3}')

Status: Memory usage is normal. Available memory is sufficient.
No swap pressure detected.
REPORT

Or manually:
  vim /tmp/monitor-lab/memory-report.txt
  
  Write:
  Total RAM: 4096 MB
  Used: 2048 MB
  Available: 1800 MB
  Swap Total: 2048 MB
  Swap Used: 0 MB
  Status: Healthy

Understanding memory output:
  total: Physical RAM installed
  used: Memory actively in use
  free: Completely unused (usually small)
  available: Memory available for apps (includes reclaimable)
  buff/cache: Used for performance, can be freed
  
Memory health indicators:
  Good: Available > 20% of total, Swap used = 0
  Warning: Available < 10% of total
  Critical: Swap actively being used
  
Why "available" matters more than "free":
  Linux uses free memory for cache
  Cache improves performance
  Cache is dropped when apps need memory
  "available" = free + reclaimable cache

EOF
}

hint_step_2() {
    cat << 'EOF'
  Load average: uptime
  CPU cores: lscpu | grep "^CPU(s):"
  Or: nproc
  Create report: /tmp/monitor-lab/cpu-report.txt
  Calculate: load / cores
EOF
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Measure CPU load and analyze it

Real-world scenario: Server feels slow. Is it actually CPU-bound?
You need load averages and context (number of cores).

Requirements:
  • Check system load with uptime
  • Count CPU cores with lscpu or nproc
  • Create /tmp/monitor-lab/cpu-report.txt containing:
    - Load averages (1, 5, 15 min)
    - Number of CPU cores
    - Load per core ratio
    - Your assessment (is CPU overloaded?)

Example report:
  Load Average: 1.5, 1.2, 0.8
  CPU Cores: 4
  Load per core: 0.375 (1.5 / 4)
  Status: Normal - load well below core count

Load interpretation:
  - Load = average number of processes waiting for CPU
  - Load < cores = good
  - Load = cores = fully utilized
  - Load > cores = overloaded
EOF
}

validate_step_2() {
    if [ ! -f /tmp/monitor-lab/cpu-report.txt ]; then
        echo ""
        print_color "$RED" "✗ CPU report not found"
        echo "  Create: /tmp/monitor-lab/cpu-report.txt"
        echo "  Include: Load averages, CPU cores, analysis"
        return 1
    fi
    
    if [ ! -s /tmp/monitor-lab/cpu-report.txt ]; then
        echo ""
        print_color "$RED" "✗ CPU report is empty"
        return 1
    fi
    
    local has_load=$(grep -i "load" /tmp/monitor-lab/cpu-report.txt | wc -l)
    local has_cpu=$(grep -i -E "cpu|core" /tmp/monitor-lab/cpu-report.txt | wc -l)
    
    if [ "$has_load" -lt 1 ] || [ "$has_cpu" -lt 1 ]; then
        echo ""
        print_color "$YELLOW" "  Warning: Report may be incomplete"
        echo "  Should include: Load averages and CPU cores"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Check load and uptime:
  uptime

Check CPU cores:
  lscpu | grep "^CPU(s):"
  nproc

Create report:
  cat > /tmp/monitor-lab/cpu-report.txt << 'REPORT'
CPU LOAD ANALYSIS
=================

Load Average: $(uptime | awk -F'load average:' '{print $2}')
CPU Cores: $(nproc)

Load per core (1 min): $(echo "scale=2; $(uptime | awk '{print $(NF-2)}' | tr -d ',') / $(nproc)" | bc)

Analysis:
Load is $(if [ $(echo "$(uptime | awk '{print $(NF-2)}' | tr -d ',') < $(nproc)" | bc) -eq 1 ]; then echo "NORMAL"; else echo "HIGH"; fi)
REPORT

Or manually:
  uptime
  # Shows: load average: 0.50, 0.75, 0.60
  
  nproc
  # Shows: 4
  
  vim /tmp/monitor-lab/cpu-report.txt
  
  Write:
  Load Average: 0.50, 0.75, 0.60
  CPU Cores: 4
  Load per core: 0.125 (0.50 / 4)
  Status: Excellent - very light load

Understanding load averages:
  Three numbers = 1 min, 5 min, 15 min
  
  Load represents:
  - Processes using CPU now
  - Processes waiting for CPU
  
  Interpretation per core:
  < 0.7 = light load
  0.7-1.0 = moderate load
  > 1.0 = overloaded (queuing)
  
  Example with 4 cores:
  Load 1.0 = 25% busy (1 of 4 cores)
  Load 4.0 = 100% busy (all 4 cores)
  Load 8.0 = 200% (4 cores busy, 4 waiting)

Why three time periods:
  1 min: Current state
  5 min: Recent trend
  15 min: Long-term average
  
  Increasing: 0.5, 1.5, 3.0 = load growing
  Decreasing: 3.0, 1.5, 0.5 = load dropping

EOF
}

hint_step_3() {
    cat << 'EOF'
  Start load: stress-ng --cpu 2 --timeout 120s &
  View in top: top
  Sort by CPU: Press Shift+P in top
  Find it: ps aux --sort=-%cpu | head
  Document: echo "PID: xxx COMMAND: stress-ng CPU: 50%" > /tmp/monitor-lab/top-cpu.txt
EOF
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create high CPU load and identify it

Real-world scenario: A process is consuming CPU. Find and document it
so you can report to management or kill it if needed.

Requirements:
  • Start CPU-intensive process: stress-ng --cpu 2 --timeout 120s &
  • Use top or ps to identify it
  • Document in /tmp/monitor-lab/top-cpu.txt:
    - PID of the process
    - Command name
    - %CPU usage (approximate)

Example documentation:
  PID: 12345
  COMMAND: stress-ng-cpu
  %CPU: 99.8%
  Found using: top sorted by CPU

In top:
  • Press Shift+P to sort by CPU (uppercase P)
  • The highest CPU process appears at top
  • Note the PID, COMMAND, and %CPU columns
  • Press 'q' to quit

Let the process run - it will stop automatically after 120 seconds.
EOF
}

validate_step_3() {
    if [ ! -f /tmp/monitor-lab/top-cpu.txt ]; then
        echo ""
        print_color "$RED" "✗ CPU process documentation not found"
        echo "  Create: /tmp/monitor-lab/top-cpu.txt"
        echo "  Include: PID, COMMAND, %CPU"
        return 1
    fi
    
    if [ ! -s /tmp/monitor-lab/top-cpu.txt ]; then
        echo ""
        print_color "$RED" "✗ CPU documentation is empty"
        return 1
    fi
    
    local has_pid=$(grep -i "pid" /tmp/monitor-lab/top-cpu.txt | wc -l)
    local has_process=$(grep -i -E "command|process|stress" /tmp/monitor-lab/top-cpu.txt | wc -l)
    
    if [ "$has_pid" -lt 1 ] || [ "$has_process" -lt 1 ]; then
        echo ""
        print_color "$YELLOW" "  Warning: Documentation may be incomplete"
        echo "  Should include: PID and process information"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Start CPU load:
  stress-ng --cpu 2 --timeout 120s &

Method 1 - Using top:
  top
  
  Press: Shift+P (uppercase P)
  This sorts by CPU usage
  
  Look at top of list:
  PID    USER    %CPU  %MEM  COMMAND
  12345  student 99.8  0.1   stress-ng-cpu
  
  Note the information
  Press 'q' to quit

Method 2 - Using ps:
  ps aux --sort=-%cpu | head -5
  
  First line after header shows highest CPU

Document findings:
  cat > /tmp/monitor-lab/top-cpu.txt << 'DOC'
CPU-INTENSIVE PROCESS IDENTIFIED
================================

PID: 12345
COMMAND: stress-ng-cpu
%CPU: 99.8%
USER: student

Method used: top sorted by CPU (Shift+P)

Analysis: Process is consuming nearly 100% of one CPU core.
This is expected behavior for stress-ng CPU test.
DOC

Or simply:
  echo "PID: 12345" > /tmp/monitor-lab/top-cpu.txt
  echo "COMMAND: stress-ng-cpu" >> /tmp/monitor-lab/top-cpu.txt
  echo "%CPU: 99.8%" >> /tmp/monitor-lab/top-cpu.txt

Top keyboard shortcuts:
  Shift+P: Sort by %CPU (capital P)
  Shift+M: Sort by %MEM (capital M)
  k: Kill process (prompts for PID)
  u: Filter by user
  1: Show individual CPU cores
  q: Quit

Understanding %CPU:
  Can exceed 100% on multi-core systems
  99.8% = using one full core
  200% = using two full cores
  
  stress-ng --cpu 2 creates 2 workers
  Each uses ~100% of one core
  Total system %CPU ≈ 200%

EOF
}

hint_step_4() {
    cat << 'EOF'
  Memory stress: stress-ng --vm 1 --vm-bytes 512M --timeout 120s &
  Watch: watch -n 1 free -h
  In top: Press Shift+M to sort by memory
  Document: /tmp/monitor-lab/top-memory.txt
EOF
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Create memory pressure and monitor it

Real-world scenario: Application is using excessive memory. Identify which
process before it causes system issues.

Requirements:
  • Start memory-intensive process: stress-ng --vm 1 --vm-bytes 512M --timeout 120s &
  • Watch memory with: watch -n 1 free -h (Ctrl+C to stop)
  • Use top to identify the memory-consuming process
  • Document in /tmp/monitor-lab/top-memory.txt:
    - PID
    - Command name
    - %MEM or RSS size

Example documentation:
  PID: 12346
  COMMAND: stress-ng-vm
  %MEM: 12.5%
  RSS: 512M
  Impact: Consuming 512MB of RAM

In top:
  • Press Shift+M to sort by memory (uppercase M)
  • Look for stress-ng-vm at the top
  • Note RES (resident memory) column
EOF
}

validate_step_4() {
    if [ ! -f /tmp/monitor-lab/top-memory.txt ]; then
        echo ""
        print_color "$RED" "✗ Memory process documentation not found"
        echo "  Create: /tmp/monitor-lab/top-memory.txt"
        echo "  Include: PID, COMMAND, %MEM or RSS"
        return 1
    fi
    
    if [ ! -s /tmp/monitor-lab/top-memory.txt ]; then
        echo ""
        print_color "$RED" "✗ Memory documentation is empty"
        return 1
    fi
    
    local has_info=$(grep -i -E "pid|mem|command|stress" /tmp/monitor-lab/top-memory.txt | wc -l)
    
    if [ "$has_info" -lt 2 ]; then
        echo ""
        print_color "$YELLOW" "  Warning: Documentation may be incomplete"
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Start memory stress:
  stress-ng --vm 1 --vm-bytes 512M --timeout 120s &

Watch memory change:
  watch -n 1 free -h
  
  Observe "used" memory increase
  Press Ctrl+C to stop watching

Use top to identify:
  top
  
  Press: Shift+M (uppercase M)
  This sorts by memory usage
  
  Look at top of list:
  PID    USER    %MEM  RES   COMMAND
  12346  student 12.5  512M  stress-ng-vm

Document:
  cat > /tmp/monitor-lab/top-memory.txt << 'DOC'
MEMORY-INTENSIVE PROCESS
========================

PID: 12346
COMMAND: stress-ng-vm
%MEM: 12.5%
RES: 512M
USER: student

Method: top sorted by memory (Shift+M)

Impact: Process is consuming 512MB of RAM as expected
for the stress test parameters.
DOC

Understanding memory in top:
  VIRT (Virtual):
  - Total virtual memory
  - Includes swapped and mapped
  - Can be very large
  
  RES (Resident):
  - Actual physical RAM used
  - This is real memory consumption
  - Most important for troubleshooting
  
  SHR (Shared):
  - Shared with other processes
  - Libraries, shared memory
  
  %MEM:
  - Percentage of total RAM
  - RES / Total RAM

Memory stress parameters:
  --vm 1: One memory worker
  --vm-bytes 512M: Allocate 512MB
  --timeout 120s: Run for 2 minutes

Real-world memory issues:
  Memory leak: RES grows over time
  Cache: Can be high but reclaimable
  Swap: If used, indicates pressure

EOF
}

hint_step_5() {
    cat << 'EOF'
  Start top: top
  Sort by CPU: Shift+P
  Sort by memory: Shift+M
  Filter user: Press 'u', type username
  Save config: Press 'W'
  Individual CPUs: Press '1'
EOF
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Master top interactive commands

Real-world scenario: You need to quickly analyze system state using top's
various sorting and filtering options.

Requirements:
  • Start top
  • Practice sorting by CPU (Shift+P)
  • Practice sorting by memory (Shift+M)
  • Filter to show only your processes (u)
  • Try showing individual CPU cores (1)
  • No file to create - this is hands-on practice

Key commands to try:
  top          # Start top
  Shift+P      # Sort by CPU
  Shift+M      # Sort by memory  
  u            # Filter by user (type your username)
  1            # Toggle individual CPU display
  k            # Kill a process (type PID)
  q            # Quit

Take your time and explore. Understanding top is critical for
system administration and the RHCSA exam.

Other useful top commands:
  c: Show full command line
  V: Show process hierarchy
  W: Save current configuration
EOF
}

validate_step_5() {
    # This is practical experience, always pass if they got here
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Start top:
  top

Essential top commands:
  
  Shift+P (uppercase P):
  - Sort by CPU usage
  - Highest CPU consumers at top
  - Default sort mode
  
  Shift+M (uppercase M):
  - Sort by memory usage
  - Highest memory consumers at top
  - Critical for memory issues
  
  u:
  - Filter by user
  - Type username when prompted
  - Shows only that user's processes
  - Press Enter with blank to show all
  
  1:
  - Toggle individual CPU cores
  - Shows per-core usage
  - Useful on multi-core systems
  - Press 1 again to toggle back
  
  k:
  - Kill a process
  - Enter PID when prompted
  - Enter signal (default 15)
  - Requires appropriate permissions
  
  c:
  - Toggle command line display
  - Shows full command with arguments
  - Helps identify processes
  
  V:
  - Forest/tree view
  - Shows parent-child relationships
  - Useful for process hierarchies
  
  W:
  - Write/save configuration
  - Saves to ~/.toprc
  - Preserves sort order, display options
  
  q:
  - Quit top
  - Returns to shell

Top header information:
  Line 1: uptime, users, load average
  Line 2: Tasks (total, running, sleeping, stopped, zombie)
  Line 3: CPU usage breakdown
  Line 4: Physical memory
  Line 5: Swap memory

CPU states explained:
  us: User space (applications)
  sy: System/kernel
  ni: Nice (low priority)
  id: Idle
  wa: I/O wait
  hi: Hardware interrupts
  si: Software interrupts
  st: Stolen (virtualization)

Reading top effectively:
  1. Check load average (line 1)
  2. Check CPU idle % (line 3)
  3. Check available memory (line 4)
  4. Check swap usage (line 5)
  5. Identify top consumers

Common troubleshooting with top:
  High CPU:
  - Sort by CPU (Shift+P)
  - Identify culprit process
  - Check if expected or rogue
  
  High memory:
  - Sort by memory (Shift+M)
  - Check RES column
  - Look for growing usage (memory leak)
  
  Many zombie processes:
  - Parent not reaping children
  - Find parent PID (PPID)
  - May need to restart parent

Alternative: htop
  More user-friendly than top
  Color-coded display
  Mouse support
  Install: dnf install htop

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your system monitoring work..."
    echo ""
    
    # CHECK 1: Memory report
    print_color "$CYAN" "[1/$total] Checking memory analysis..."
    if [ -f /tmp/monitor-lab/memory-report.txt ] && [ -s /tmp/monitor-lab/memory-report.txt ]; then
        local has_content=$(grep -i -E "total|memory|swap" /tmp/monitor-lab/memory-report.txt | wc -l)
        if [ "$has_content" -ge 2 ]; then
            print_color "$GREEN" "  ✓ Memory report created with analysis"
            ((score++))
        else
            print_color "$YELLOW" "  Memory report exists but may be incomplete"
        fi
    else
        print_color "$RED" "  ✗ Memory report missing or empty"
        print_color "$YELLOW" "  Create: /tmp/monitor-lab/memory-report.txt"
    fi
    echo ""
    
    # CHECK 2: CPU report
    print_color "$CYAN" "[2/$total] Checking CPU load analysis..."
    if [ -f /tmp/monitor-lab/cpu-report.txt ] && [ -s /tmp/monitor-lab/cpu-report.txt ]; then
        local has_content=$(grep -i -E "load|cpu|core" /tmp/monitor-lab/cpu-report.txt | wc -l)
        if [ "$has_content" -ge 2 ]; then
            print_color "$GREEN" "  ✓ CPU report created with load analysis"
            ((score++))
        else
            print_color "$YELLOW" "  CPU report exists but may be incomplete"
        fi
    else
        print_color "$RED" "  ✗ CPU report missing or empty"
        print_color "$YELLOW" "  Create: /tmp/monitor-lab/cpu-report.txt"
    fi
    echo ""
    
    # CHECK 3: CPU process documentation
    print_color "$CYAN" "[3/$total] Checking CPU process identification..."
    if [ -f /tmp/monitor-lab/top-cpu.txt ] && [ -s /tmp/monitor-lab/top-cpu.txt ]; then
        local has_info=$(grep -i -E "pid|stress|cpu" /tmp/monitor-lab/top-cpu.txt | wc -l)
        if [ "$has_info" -ge 2 ]; then
            print_color "$GREEN" "  ✓ CPU process documented"
            ((score++))
        else
            print_color "$YELLOW" "  CPU process doc exists but may be incomplete"
        fi
    else
        print_color "$RED" "  ✗ CPU process documentation missing"
        print_color "$YELLOW" "  Create: /tmp/monitor-lab/top-cpu.txt"
    fi
    echo ""
    
    # CHECK 4: Memory process documentation
    print_color "$CYAN" "[4/$total] Checking memory process identification..."
    if [ -f /tmp/monitor-lab/top-memory.txt ] && [ -s /tmp/monitor-lab/top-memory.txt ]; then
        local has_info=$(grep -i -E "pid|stress|mem" /tmp/monitor-lab/top-memory.txt | wc -l)
        if [ "$has_info" -ge 2 ]; then
            print_color "$GREEN" "  ✓ Memory process documented"
            ((score++))
        else
            print_color "$YELLOW" "  Memory process doc exists but may be incomplete"
        fi
    else
        print_color "$RED" "  ✗ Memory process documentation missing"
        print_color "$YELLOW" "  Create: /tmp/monitor-lab/top-memory.txt"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You have mastered:"
        echo "  ✓ Memory analysis with free"
        echo "  ✓ CPU load assessment with uptime"
        echo "  ✓ Process identification with top"
        echo "  ✓ Resource consumption monitoring"
        echo "  ✓ Documenting findings professionally"
        echo ""
        echo "These are critical RHCSA troubleshooting skills!"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total tasks completed)"
        echo ""
        echo "Complete the missing tasks:"
        [ ! -f /tmp/monitor-lab/memory-report.txt ] && echo "  • Create memory analysis report"
        [ ! -f /tmp/monitor-lab/cpu-report.txt ] && echo "  • Create CPU load report"
        [ ! -f /tmp/monitor-lab/top-cpu.txt ] && echo "  • Document CPU-intensive process"
        [ ! -f /tmp/monitor-lab/top-memory.txt ] && echo "  • Document memory-intensive process"
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

STEP 1: Memory analysis
─────────────────────────────────────────────────────────────────
free -h
free -m

cat > /tmp/monitor-lab/memory-report.txt << 'REPORT'
Total RAM: 4096 MB
Used: 2048 MB
Available: 1800 MB
Swap Total: 2048 MB
Swap Used: 0 MB
Status: Healthy - no memory pressure
REPORT


STEP 2: CPU load analysis
─────────────────────────────────────────────────────────────────
uptime
nproc

cat > /tmp/monitor-lab/cpu-report.txt << 'REPORT'
Load Average: 0.50, 0.75, 0.60
CPU Cores: 4
Load per core: 0.125
Status: Normal - light load
REPORT


STEP 3: Identify CPU process
─────────────────────────────────────────────────────────────────
stress-ng --cpu 2 --timeout 120s &
top
# Press Shift+P to sort by CPU

cat > /tmp/monitor-lab/top-cpu.txt << 'DOC'
PID: 12345
COMMAND: stress-ng-cpu
%CPU: 99.8%
DOC


STEP 4: Identify memory process
─────────────────────────────────────────────────────────────────
stress-ng --vm 1 --vm-bytes 512M --timeout 120s &
top
# Press Shift+M to sort by memory

cat > /tmp/monitor-lab/top-memory.txt << 'DOC'
PID: 12346
COMMAND: stress-ng-vm
%MEM: 12.5%
RES: 512M
DOC


STEP 5: Practice top commands
─────────────────────────────────────────────────────────────────
top
Shift+P  # Sort by CPU
Shift+M  # Sort by memory
u        # Filter by user
1        # Show individual CPUs
q        # Quit


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Memory monitoring:
  free -h: Human-readable memory
  free -m: Megabytes for calculations
  available: Memory actually usable
  buff/cache: Reclaimable if needed
  Swap usage: Indicates memory pressure

CPU load:
  Load average: Processes waiting for CPU
  Three numbers: 1, 5, 15 minute averages
  Compare to core count
  Load < cores = healthy
  Load > cores = overloaded

Top commands:
  Shift+P: Sort by CPU
  Shift+M: Sort by memory
  u: Filter by user
  k: Kill process
  1: Show individual cores
  W: Save configuration

Process states:
  R: Running
  S: Sleeping
  D: Uninterruptible (I/O)
  Z: Zombie


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Essential commands:
1. free -h - Check memory
2. uptime - Check load
3. top - Interactive monitoring
4. Shift+P in top - Sort by CPU
5. Shift+M in top - Sort by memory

Quick checks:
  free -h | grep Mem
  uptime
  top -bn1 | head -20

Troubleshooting:
  High memory: Check swap usage
  High CPU: Sort top by CPU
  High load: Compare to core count

Remember:
  "available" memory matters, not "free"
  Load should be < CPU cores
  Swap usage indicates pressure
  top is your friend!

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Kill test processes
    pkill -u $(whoami) stress-ng 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/monitor-lab 2>/dev/null || true
    
    echo "  ✓ All test processes terminated"
    echo "  ✓ Lab files removed"
    echo "  ✓ Cleanup complete"
}

# Execute the main framework
main "$@"
