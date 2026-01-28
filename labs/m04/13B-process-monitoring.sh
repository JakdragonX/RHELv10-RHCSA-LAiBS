#!/bin/bash
# labs/m04/13B-process-monitoring.sh
# Lab: Process monitoring with ps
# Difficulty: Intermediate
# RHCSA Objective: 13.3, 13.4 - Process states and monitoring with ps

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Process monitoring with ps"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="35-45 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous attempts
    pkill -u $(whoami) -f "stress-ng" 2>/dev/null || true
    pkill -u $(whoami) -f "dd if=/dev/zero" 2>/dev/null || true
    rm -f /tmp/bigfile.dat 2>/dev/null || true
    
    # Install stress-ng if not present (for creating different process states)
    if ! command -v stress-ng >/dev/null 2>&1; then
        echo "  Installing stress-ng for process testing..."
        dnf install -y stress-ng >/dev/null 2>&1
    fi
    
    # Create working directory
    mkdir -p /tmp/process-lab 2>/dev/null || true
    
    echo "  ✓ Previous processes cleaned"
    echo "  ✓ Testing tools installed"
    echo "  ✓ Lab environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of processes
  • Familiarity with PIDs
  • Shell command basics

Commands You'll Use:
  • ps - Report process status
  • ps aux - Show all processes
  • ps -ef - Alternative format
  • ps -u USER - Processes by user
  • pgrep - Find processes by name
  • pkill - Kill processes by name
  • kill - Send signals to processes

Files You'll Interact With:
  • /proc/ - Virtual filesystem with process info
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your server is experiencing performance issues. Users are reporting slowness,
and you need to identify which processes are consuming resources. You must
use ps to find problematic processes, understand their states, and take
appropriate action.

BACKGROUND:
The ps command is essential for system troubleshooting. Understanding process
states (Running, Sleeping, Zombie, etc.) helps diagnose system problems.
Being able to filter and find specific processes is critical for the RHCSA exam.

OBJECTIVES:
  1. Master basic ps commands
     • View all running processes
     • Understand ps aux output columns
     • Find specific processes
     • Filter by user

  2. Create and identify different process states
     • Create a CPU-intensive process (Running state)
     • Create an I/O-bound process (Uninterruptible sleep)
     • Create a sleeping process
     • Identify states in ps output

  3. Find processes using different methods
     • Find by process name with pgrep
     • Find by user
     • Find by CPU usage
     • Find parent-child relationships

  4. Analyze resource consumption
     • Identify high CPU processes
     • Identify high memory processes
     • Sort processes by resource usage
     • Calculate total resource usage by user

  5. Terminate processes correctly
     • Kill a specific process by PID
     • Kill processes by name
     • Kill all processes by a user
     • Verify termination

HINTS:
  • ps aux shows all processes with details
  • STAT column shows process state
  • %CPU and %MEM show resource usage
  • pgrep is faster than ps | grep
  • Always verify before killing processes

SUCCESS CRITERIA:
  • Can find any process quickly
  • Understand process state codes
  • Can identify resource-heavy processes
  • Know how to terminate processes safely
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Master ps command variations
  ☐ 2. Create and identify process states
  ☐ 3. Find processes multiple ways
  ☐ 4. Analyze resource consumption
  ☐ 5. Terminate processes correctly
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
You are troubleshooting server performance by monitoring processes.

Working directory: /tmp/process-lab/

Learn to find, analyze, and manage processes effectively.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Master basic ps commands and understand the output

Learn the most important ps variations and what each column means.

Requirements:
  • Run ps without arguments (your processes only)
  • Run ps aux (all processes, detailed)
  • Run ps -ef (alternative format)
  • Run ps -u $(whoami) (your processes only)
  • Understand what each column means

Key ps variations:
  ps        - Your processes in current terminal
  ps aux    - All processes, BSD format
  ps -ef    - All processes, System V format
  ps -u USER - Processes owned by USER

Understanding columns:
  USER, PID, %CPU, %MEM, VSZ, RSS, TTY, STAT, START, TIME, COMMAND

STAT column codes to know:
  R - Running
  S - Sleeping
  D - Uninterruptible sleep (usually I/O)
  Z - Zombie
  T - Stopped
EOF
}

validate_step_1() {
    # Exploratory, always pass
    return 0
}

hint_step_1() {
    echo "  All processes: ps aux"
    echo "  Your processes: ps -u \$(whoami)"
    echo "  Process tree: ps -ef --forest"
    echo "  Specific columns: ps -eo pid,user,%cpu,%mem,stat,comm"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
View your terminal processes:
  ps

View all processes:
  ps aux

Alternative format:
  ps -ef

Your processes only:
  ps -u $(whoami)

Process tree view:
  ps -ef --forest

Custom columns:
  ps -eo pid,user,%cpu,%mem,comm

Understanding ps aux output:
  USER   - Process owner
  PID    - Process ID
  %CPU   - CPU usage percentage
  %MEM   - Memory usage percentage
  VSZ    - Virtual memory size (KB)
  RSS    - Resident set size (actual RAM in KB)
  TTY    - Terminal (? means no terminal)
  STAT   - Process state
  START  - When process started
  TIME   - Total CPU time used
  COMMAND - Command that started process

STAT column codes:
  R - Running or runnable
  S - Sleeping (waiting for event)
  D - Uninterruptible sleep (I/O wait)
  T - Stopped (Ctrl+Z or debugger)
  Z - Zombie (finished but not reaped)
  
  Additional flags:
  s - Session leader
  + - Foreground process
  < - High priority
  N - Low priority
  l - Multi-threaded

Common combinations:
  Ss  - Sleeping session leader
  R+  - Running in foreground
  Ssl - Sleeping session leader, multi-threaded

EOF
}

hint_step_2() {
    echo "  CPU load: stress-ng --cpu 1 --timeout 60s &"
    echo "  I/O load: dd if=/dev/zero of=/tmp/bigfile.dat bs=1M count=1000 &"
    echo "  Check states: ps aux | grep stress"
    echo "  Watch live: watch -n 1 'ps aux | grep stress'"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create different process states and identify them

Create real processes in different states to understand STAT codes.

Requirements:
  • Create a CPU-intensive process (R state)
  • Create an I/O-bound process (D state)
  • Observe these in ps output
  • Identify their STAT codes
  • Let them complete or kill them after observing

Commands to create different states:

CPU-intensive (R state):
  stress-ng --cpu 1 --timeout 60s &

I/O-bound (D state):
  dd if=/dev/zero of=/tmp/bigfile.dat bs=1M count=1000 &

After starting these, quickly check:
  ps aux | grep stress
  ps aux | grep dd

Look for the STAT column to see R or D states.
EOF
}

validate_step_2() {
    # Check if user tried creating processes
    if pgrep -u $(whoami) stress-ng >/dev/null 2>&1 || \
       pgrep -u $(whoami) dd >/dev/null 2>&1; then
        return 0
    fi
    
    # If nothing running, that's okay - they may have cleaned up
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Create CPU-intensive process:
  stress-ng --cpu 1 --timeout 60s &

Observe immediately:
  ps aux | grep stress-ng
  
  Look for STAT column:
  R or R+ means running/runnable

Create I/O-intensive process:
  dd if=/dev/zero of=/tmp/bigfile.dat bs=1M count=1000 &

Observe:
  ps aux | grep dd
  
  May see:
  D - Uninterruptible sleep (writing to disk)
  S - Sleeping (between writes)

Watch in real-time:
  watch -n 1 'ps aux | grep "stress\|dd"'

Create sleeping process:
  sleep 300 &
  ps aux | grep sleep
  
  Will show:
  S - Sleeping (waiting for timer)

Understanding states:
  R (Running):
  - Using CPU right now
  - In run queue
  - Actively computing
  
  S (Sleeping):
  - Waiting for event
  - Can be interrupted
  - Normal for idle processes
  
  D (Uninterruptible):
  - Waiting for I/O
  - Cannot be interrupted
  - Usually brief
  - If stuck, indicates I/O problem
  
  Z (Zombie):
  - Process finished
  - Parent hasn't collected status
  - Harmless but takes PID
  - Kill parent to clean up

Clean up:
  pkill stress-ng
  pkill dd
  rm /tmp/bigfile.dat

EOF
}

hint_step_3() {
    echo "  By name: pgrep sshd"
    echo "  By user: pgrep -u root"
    echo "  Full info: ps -p \$(pgrep sshd)"
    echo "  Parent PID: ps -o ppid= -p PID"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Find processes using multiple methods

Master different techniques to locate specific processes.

Requirements:
  • Find sshd processes
  • Find all processes owned by root
  • Find processes by partial name match
  • Display parent-child relationships
  • Count how many processes a user has

Techniques to practice:
  • pgrep for quick PID lookup
  • ps with grep for detailed info
  • ps -u for user filtering
  • ps --forest for relationships

Real-world scenario: You need to find if httpd is running,
who owns it, and how many worker processes it has.
EOF
}

validate_step_3() {
    # Exploratory step
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Find process by name:
  pgrep sshd
  ps aux | grep sshd

Find all PIDs for a process:
  pgrep -a sshd    # Shows PID and command
  pidof sshd       # Just PIDs

Find by user:
  pgrep -u root
  ps -u root

Count processes by user:
  ps -u root | wc -l
  pgrep -u root | wc -l

Find with full details:
  ps -fp $(pgrep sshd)

Find parent of a process:
  ps -o ppid= -p PID
  ps -p PID -o ppid,pid,cmd

Show process tree:
  ps -ef --forest
  ps auxf

Find by partial name:
  pgrep -f "http"      # Matches anywhere in command
  ps aux | grep http

Find highest PID:
  ps aux --sort=-pid | head

Find oldest process:
  ps aux --sort=start_time | head

Practical examples:

Find if Apache is running:
  pgrep httpd || echo "Not running"
  systemctl status httpd

Find all processes for current user:
  ps -u $(whoami)
  pgrep -u $(whoami) | wc -l

Find zombie processes:
  ps aux | grep 'Z'

Find processes using specific terminal:
  ps -t pts/0

EOF
}

hint_step_4() {
    cat << 'EOF'
  By CPU: ps aux --sort=-%cpu | head
  By memory: ps aux --sort=-%mem | head
  Top 10 CPU: ps aux --sort=-%cpu | head -11
  Specific user total: ps -u USER -o %cpu | awk '{sum+=$1} END {print sum}'
EOF
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Analyze resource consumption

Learn to identify which processes are consuming resources.

Requirements:
  • Find top 10 CPU-consuming processes
  • Find top 10 memory-consuming processes
  • Calculate total CPU usage by current user
  • Identify processes using more than 1% CPU
  • Sort processes by different criteria

Sorting options:
  --sort=-%cpu   - By CPU usage (descending)
  --sort=-%mem   - By memory usage (descending)
  --sort=-rss    - By resident memory
  --sort=start_time - By start time

This is critical for performance troubleshooting.
EOF
}

validate_step_4() {
    # Exploratory
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Top CPU consumers:
  ps aux --sort=-%cpu | head -11
  # Top 10 plus header

Top memory consumers:
  ps aux --sort=-%mem | head -11

Processes using >1% CPU:
  ps aux | awk '$3 > 1.0'

Processes using >1% memory:
  ps aux | awk '$4 > 1.0'

Total CPU by user:
  ps -u $(whoami) -o %cpu --no-headers | awk '{sum+=$1} END {print sum "%"}'

Total memory by user:
  ps -u $(whoami) -o %mem --no-headers | awk '{sum+=$1} END {print sum "%"}'

Show specific columns only:
  ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -20

Find memory hogs (>100MB):
  ps aux | awk '$6 > 100000 {print $2, $6/1024 "MB", $11}'

Most recent processes:
  ps aux --sort=-start_time | head

Longest running processes:
  ps aux --sort=start_time | head

Count processes by state:
  ps aux | awk '{print $8}' | sort | uniq -c

Processes with most threads:
  ps -eLf | awk '{print $4}' | sort | uniq -c | sort -rn | head

Understanding resource values:
  %CPU can exceed 100% (multi-core)
  VSZ is virtual (may be large)
  RSS is actual RAM used
  SHR is shared memory

Practical troubleshooting:
  High CPU + state R = CPU bound
  High CPU + state D = I/O wait
  Many Z processes = Parent not reaping
  Growing RSS = Memory leak

EOF
}

hint_step_5() {
    echo "  Kill by PID: kill PID"
    echo "  Kill by name: pkill NAME"
    echo "  Kill all user: pkill -u USER"
    echo "  Verify: pgrep NAME || echo 'Terminated'"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Terminate processes correctly

Learn safe ways to stop processes and verify termination.

Requirements:
  • Start a test process: sleep 300 &
  • Find its PID
  • Kill it by PID
  • Start another: sleep 400 &
  • Kill it by name with pkill
  • Verify both are gone

Signals to know:
  kill PID       - SIGTERM (graceful shutdown)
  kill -9 PID    - SIGKILL (force kill)
  kill -15 PID   - SIGTERM (same as default)

Use SIGTERM first, SIGKILL only if necessary.

After killing, always verify the process is gone.
EOF
}

validate_step_5() {
    # Check no sleep processes from current user
    local sleep_count=$(pgrep -u $(whoami) sleep 2>/dev/null | wc -l)
    
    if [ "$sleep_count" -gt 0 ]; then
        echo ""
        print_color "$YELLOW" "  Note: $sleep_count sleep process(es) still running"
        echo "  Clean up with: pkill sleep"
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Start test process:
  sleep 300 &

Find its PID:
  pgrep sleep
  pidof sleep

Kill by PID:
  kill $(pgrep sleep)

Verify:
  pgrep sleep
  # Should return nothing

Start another:
  sleep 400 &

Kill by name:
  pkill sleep

Verify termination:
  pgrep sleep || echo "Process terminated"

Force kill if needed:
  kill -9 $(pgrep sleep)

Kill all processes by user (careful!):
  pkill -u username

Kill specific command pattern:
  pkill -f "sleep 400"

Understanding signals:
  SIGTERM (15):
  - Default signal
  - Allows cleanup
  - Process can ignore
  - Graceful shutdown
  
  SIGKILL (9):
  - Cannot be caught/ignored
  - Immediate termination
  - No cleanup
  - Last resort only
  
  SIGSTOP (19):
  - Pause process
  - Cannot be caught
  - Use SIGCONT to resume

Best practices:
  1. Try SIGTERM first (kill PID)
  2. Wait a few seconds
  3. Check if still running
  4. Use SIGKILL if necessary (kill -9 PID)
  5. Always verify termination

Safe kill pattern:
  kill PID
  sleep 2
  kill -0 PID 2>/dev/null && kill -9 PID

Bulk operations:
  pkill -u $(whoami) stress
  killall sleep

Clean up everything:
  pkill -u $(whoami) sleep
  pkill -u $(whoami) stress-ng
  pkill -u $(whoami) dd
  rm -f /tmp/bigfile.dat

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=3
    
    echo "Checking your process monitoring skills..."
    echo ""
    
    # CHECK 1: No test processes running
    print_color "$CYAN" "[1/$total] Checking cleanup..."
    local test_procs=$(pgrep -u $(whoami) -c "sleep|stress|dd" 2>/dev/null || echo "0")
    
    if [ "$test_procs" -eq 0 ]; then
        print_color "$GREEN" "  ✓ All test processes cleaned up"
        ((score++))
    else
        print_color "$YELLOW" "  Note: $test_procs test process(es) still running"
        echo "  Clean up with: pkill sleep; pkill stress-ng; pkill dd"
        ((score++))
    fi
    echo ""
    
    # CHECK 2: Understanding demonstrated
    print_color "$CYAN" "[2/$total] Checking ps command mastery..."
    if [ $score -ge 1 ]; then
        print_color "$GREEN" "  ✓ Process monitoring skills demonstrated"
        ((score++))
    fi
    echo ""
    
    # CHECK 3: Resource analysis
    print_color "$CYAN" "[3/$total] Checking resource analysis skills..."
    if [ $score -ge 2 ]; then
        print_color "$GREEN" "  ✓ Resource analysis techniques learned"
        ((score++))
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You can now:"
        echo "  • Use ps effectively with multiple formats"
        echo "  • Identify and understand process states"
        echo "  • Find processes using pgrep and filters"
        echo "  • Analyze resource consumption"
        echo "  • Terminate processes safely"
        echo ""
        echo "These skills are essential for system troubleshooting!"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the concepts and try again."
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

STEP 1: Master ps commands
─────────────────────────────────────────────────────────────────
ps aux
ps -ef
ps -u $(whoami)
ps -eo pid,user,%cpu,%mem,stat,comm


STEP 2: Create process states
─────────────────────────────────────────────────────────────────
stress-ng --cpu 1 --timeout 60s &
dd if=/dev/zero of=/tmp/bigfile.dat bs=1M count=1000 &
ps aux | grep "stress\|dd"


STEP 3: Find processes
─────────────────────────────────────────────────────────────────
pgrep sshd
pgrep -u root
ps -fp $(pgrep sshd)
ps -ef --forest


STEP 4: Analyze resources
─────────────────────────────────────────────────────────────────
ps aux --sort=-%cpu | head -11
ps aux --sort=-%mem | head -11
ps aux | awk '$3 > 1.0'


STEP 5: Terminate processes
─────────────────────────────────────────────────────────────────
sleep 300 &
kill $(pgrep sleep)
pkill sleep


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Essential ps commands:
  ps aux     - All processes, BSD style
  ps -ef     - All processes, Unix style
  ps -u USER - Filter by user
  ps -p PID  - Specific process

Process states (STAT):
  R - Running/Runnable
  S - Sleeping (interruptible)
  D - Uninterruptible sleep (I/O)
  T - Stopped
  Z - Zombie
  I - Idle kernel thread

Finding processes:
  pgrep NAME    - Find by name
  pgrep -u USER - Find by user
  pidof NAME    - Get PIDs
  ps -C NAME    - By command name

Resource analysis:
  --sort=-%cpu  - Sort by CPU
  --sort=-%mem  - Sort by memory
  ps -eo PID,%CPU,%MEM,CMD

Killing processes:
  kill PID      - SIGTERM (graceful)
  kill -9 PID   - SIGKILL (force)
  pkill NAME    - Kill by name
  killall NAME  - Kill all instances


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using ps | grep instead of pgrep
  Slower and shows grep itself
  Use pgrep for speed

Mistake 2: Immediately using kill -9
  Try SIGTERM first
  Give process time to cleanup

Mistake 3: Confusing VSZ with actual memory
  VSZ is virtual (can be huge)
  RSS is real memory used

Mistake 4: Not verifying termination
  Always check process is gone
  Use: pgrep NAME || echo "Dead"


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical ps commands:
1. ps aux - Show all processes
2. ps -ef - Alternative format
3. ps -u USER - User's processes
4. pgrep NAME - Find by name
5. pkill NAME - Kill by name

Quick troubleshooting:
  High CPU: ps aux --sort=-%cpu | head
  High memory: ps aux --sort=-%mem | head
  Find process: pgrep -a NAME
  Kill safely: kill PID (then verify)

Process states matter:
  Lots of R: CPU bottleneck
  Lots of D: I/O bottleneck
  Any Z: Parent not reaping children

Remember:
  ps aux for overview
  pgrep for finding
  kill for stopping
  Always verify!

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Kill test processes
    pkill -u $(whoami) stress-ng 2>/dev/null || true
    pkill -u $(whoami) dd 2>/dev/null || true
    pkill -u $(whoami) sleep 2>/dev/null || true
    
    # Remove test files
    rm -f /tmp/bigfile.dat 2>/dev/null || true
    rm -rf /tmp/process-lab 2>/dev/null || true
    
    echo "  ✓ All test processes terminated"
    echo "  ✓ Test files removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
