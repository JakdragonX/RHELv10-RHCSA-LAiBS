#!/bin/bash
# labs/m03/13A-shell-jobs-processes.sh
# Lab: Shell jobs and process basics
# Difficulty: Beginner
# RHCSA Objective: 13.1, 13.2 - Understanding processes and managing shell jobs

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Shell jobs and process basics"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="25-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Kill any existing sleep processes from previous attempts
    pkill -u $(whoami) sleep 2>/dev/null || true
    
    # Create a working directory
    mkdir -p /tmp/jobs-lab 2>/dev/null || true
    
    echo "  ✓ Previous processes cleaned up"
    echo "  ✓ Lab environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of processes
  • Familiarity with shell commands
  • Understanding of foreground vs background

Commands You'll Use:
  • jobs - List shell jobs
  • bg - Move job to background
  • fg - Move job to foreground
  • Ctrl+Z - Suspend current job
  • & - Start command in background
  • ps - Show processes

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
You are a system administrator working in a terminal session. You need to
run multiple long-running commands while still being able to use your shell
for other work. Understanding job control allows you to manage multiple
tasks efficiently from a single terminal.

BACKGROUND:
Every command you run creates a process with a unique PID. When run from a
shell, these become "jobs" that you can control. Jobs can run in the
foreground (blocking your shell) or background (allowing you to continue
working).

OBJECTIVES:
  1. Understand processes and PIDs
     • Run a command and identify its PID
     • Understand what a process is
     • See the relationship between commands and processes
     • Explore the /proc filesystem

  2. Start jobs in the background
     • Run a long-running command in background
     • Use the & operator
     • View running jobs
     • Understand job numbering

  3. Suspend and resume jobs
     • Start a job in foreground
     • Suspend it with Ctrl+Z
     • Move suspended job to background
     • Resume a background job to foreground

  4. Manage multiple jobs
     • Run several background jobs
     • List all jobs
     • Bring specific job to foreground
     • Terminate jobs

  5. Understand job vs process concepts
     • Compare job numbers with PIDs
     • See how jobs relate to processes
     • Understand when to use jobs vs process management
     • Clean up all jobs

HINTS:
  • jobs shows shell jobs with [numbers]
  • ps shows system processes with PIDs
  • Use Ctrl+Z to suspend, NOT Ctrl+C
  • & at end of command runs in background
  • fg and bg without arguments affect most recent job

SUCCESS CRITERIA:
  • Can start jobs in background
  • Can suspend and resume jobs
  • Understand difference between jobs and processes
  • Can manage multiple concurrent jobs
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Understand processes and PIDs
  ☐ 2. Start jobs in background with &
  ☐ 3. Suspend and resume jobs
  ☐ 4. Manage multiple jobs
  ☐ 5. Distinguish jobs from processes
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
You are learning shell job control to manage multiple tasks efficiently.

Working directory: /tmp/jobs-lab/

Master foreground, background, and job management.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Understand processes and PIDs

Every command creates a process. Learn what processes are and how to
identify them.

Requirements:
  • Run a simple command: sleep 30
  • While it runs, open another terminal
  • Find the sleep process and its PID
  • Understand what PID means
  • Explore /proc/PID directory

Questions to explore:
  • What is a PID?
  • How do you find a process ID?
  • What information is in /proc/?
  • Why does every process have a unique PID?

After exploring, stop the sleep command with Ctrl+C.
EOF
}

validate_step_1() {
    # Exploratory step
    return 0
}

hint_step_1() {
    echo "  Start: sleep 30"
    echo "  Find it: ps aux | grep sleep"
    echo "  Or: pgrep sleep"
    echo "  Explore: ls /proc/\$(pgrep sleep)"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Start a long command:
  sleep 30
  # This blocks your terminal for 30 seconds

In another terminal, find the PID:
  ps aux | grep sleep
  pgrep sleep
  pidof sleep

Explore process info:
  ls /proc/$(pgrep sleep)
  cat /proc/$(pgrep sleep)/status | head

Stop it:
  Press Ctrl+C in the terminal running sleep

Understanding:
  PID = Process ID
  - Unique number for each process
  - Assigned by kernel when process starts
  - Used to identify and manage processes
  
  /proc/ filesystem:
  - Virtual filesystem
  - Each PID has directory: /proc/PID/
  - Contains process information
  - Updated in real-time by kernel

  Every command becomes a process:
  - ls, sleep, cat, etc.
  - Each gets a unique PID
  - Lives until command completes

EOF
}

hint_step_2() {
    echo "  Background: sleep 60 &"
    echo "  List jobs: jobs"
    echo "  See PID: jobs -l"
    echo "  Process list: ps"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Start jobs in the background

Learn to run commands in background so your shell stays available.

Requirements:
  • Start a command in background: sleep 60 &
  • View the job list
  • See the job number and PID
  • Verify your shell is still usable
  • Understand the & operator

The & operator runs a command in background immediately.
Your shell returns control to you right away.

Background jobs continue running while you work.
EOF
}

validate_step_2() {
    # Check if user has background jobs
    local job_count=$(jobs | wc -l)
    
    if [ "$job_count" -lt 1 ]; then
        echo ""
        print_color "$YELLOW" "  Note: No background jobs detected"
        echo "  Try: sleep 60 &"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Start command in background:
  sleep 60 &

Output shows:
  [1] 12345
  
  [1] = Job number (shell assigns)
  12345 = PID (kernel assigns)

List jobs:
  jobs
  
  Output:
  [1]+  Running    sleep 60 &

List jobs with PIDs:
  jobs -l
  
  Output:
  [1]+ 12345 Running    sleep 60 &

Understanding:
  & operator:
  - Runs command in background
  - Shell immediately returns prompt
  - Job runs independently
  
  Job numbers:
  - Assigned by shell: [1], [2], [3]
  - Unique within your shell session
  - Used with fg, bg commands
  
  Background jobs:
  - Continue running
  - Don't block your terminal
  - Output may appear in terminal
  - Useful for long tasks

Verify job is running:
  jobs
  ps aux | grep sleep

EOF
}

hint_step_3() {
    echo "  Start: sleep 100"
    echo "  Suspend: Press Ctrl+Z"
    echo "  Background: bg"
    echo "  Foreground: fg"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Suspend and resume jobs

Learn to suspend foreground jobs and move them to background.

Requirements:
  • Start: sleep 100 (foreground)
  • Suspend it with Ctrl+Z
  • Move to background with bg
  • Bring back to foreground with fg
  • Stop it with Ctrl+C

Workflow:
  1. Start command (foreground, blocking)
  2. Realize you need the terminal
  3. Suspend with Ctrl+Z
  4. Continue in background with bg
  5. Or bring back with fg when needed

Ctrl+Z suspends (pauses) the job.
bg resumes it in background.
fg brings it back to foreground.
EOF
}

validate_step_3() {
    # Exploratory step about job control
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Start in foreground:
  sleep 100
  # Terminal is blocked

Suspend the job:
  Press Ctrl+Z
  
  Output:
  [1]+  Stopped    sleep 100

Check status:
  jobs
  
  Shows:
  [1]+  Stopped    sleep 100

Move to background:
  bg
  
  Output:
  [1]+ sleep 100 &
  
  Jobs shows:
  [1]+  Running    sleep 100 &

Bring back to foreground:
  fg
  
  Now blocking your terminal again

Stop it:
  Press Ctrl+C

Understanding:
  Ctrl+Z:
  - Sends SIGTSTP signal
  - Suspends (pauses) job
  - Job state: Stopped
  - Does NOT terminate
  
  bg command:
  - Resumes suspended job
  - Runs in background
  - Shell becomes available
  
  fg command:
  - Brings background job to foreground
  - Job blocks terminal again
  - Can interact with it
  
  Ctrl+C:
  - Sends SIGINT signal
  - Terminates foreground job
  - Job is killed, not stopped

Common workflow:
  1. Start job
  2. Realize it's taking too long
  3. Ctrl+Z to suspend
  4. bg to continue in background
  5. Keep working

EOF
}

hint_step_4() {
    echo "  Start multiple: sleep 200 & sleep 300 & sleep 400 &"
    echo "  List all: jobs"
    echo "  Foreground specific: fg %2"
    echo "  Kill job: kill %1"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Manage multiple jobs

Work with several background jobs simultaneously.

Requirements:
  • Start three background jobs
  • List all jobs
  • Bring a specific job to foreground
  • Kill a job using its job number
  • Verify remaining jobs

Commands to use:
  • Start: sleep 200 & sleep 300 & sleep 400 &
  • List: jobs
  • Foreground specific: fg %N
  • Kill job: kill %N

The % symbol refers to job numbers.
%1 means job [1], %2 means job [2], etc.
EOF
}

validate_step_4() {
    local job_count=$(jobs | wc -l)
    
    if [ "$job_count" -lt 1 ]; then
        echo ""
        print_color "$YELLOW" "  Note: No jobs running"
        echo "  Start some: sleep 200 & sleep 300 &"
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Start multiple jobs:
  sleep 200 &
  sleep 300 &
  sleep 400 &

List all jobs:
  jobs
  
  Output:
  [1]   Running    sleep 200 &
  [2]-  Running    sleep 300 &
  [3]+  Running    sleep 400 &

Bring specific job to foreground:
  fg %2
  
  Job [2] now in foreground
  Press Ctrl+Z to suspend it again

List jobs with PIDs:
  jobs -l
  
  Shows:
  [1]  12345 Running    sleep 200 &
  [2]- 12346 Running    sleep 300 &
  [3]+ 12347 Running    sleep 400 &

Kill a specific job:
  kill %1
  
  Or:
  kill 12345

Verify:
  jobs
  
  Job [1] should be gone

Clean up all jobs:
  kill %2 %3
  
  Or:
  killall sleep

Understanding:
  Job notation:
  %N - Job number N
  %+ - Most recent job (current)
  %- - Previous job
  %% - Most recent job (same as %+)
  
  Special markers:
  + = Most recent job
  - = Previous job
  
  Using job numbers:
  fg %2 - Foreground job 2
  bg %3 - Background job 3
  kill %1 - Kill job 1
  
  Multiple ways to reference:
  %2 - By job number
  12346 - By PID
  %sleep - By command name
  
  Managing many jobs:
  jobs -l shows all with PIDs
  fg/bg without number affects current (+)
  kill %N terminates specific job

EOF
}

hint_step_5() {
    echo "  Compare: jobs vs ps aux | grep sleep"
    echo "  Job numbers are shell-specific"
    echo "  PIDs are system-wide"
    echo "  Clean up: killall sleep"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Understand jobs vs processes

Learn the difference between shell jobs and system processes.

Requirements:
  • Start a background job
  • Compare jobs output with ps output
  • Understand when to use job numbers vs PIDs
  • See that jobs are shell-specific
  • Clean up all processes

Key differences to explore:
  • jobs - Shows shell jobs only
  • ps - Shows all system processes
  • Job numbers are shell-local
  • PIDs are system-wide

After exploring, clean up all sleep processes.
EOF
}

validate_step_5() {
    # Check if sleep processes are cleaned up
    local sleep_count=$(pgrep -u $(whoami) sleep | wc -l)
    
    if [ "$sleep_count" -gt 0 ]; then
        echo ""
        print_color "$YELLOW" "  Note: Sleep processes still running"
        echo "  Clean up with: killall sleep"
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Start a background job:
  sleep 500 &

View as job:
  jobs
  
  Output:
  [1]+  Running    sleep 500 &

View as process:
  ps aux | grep sleep
  pgrep sleep

Compare:
  jobs shows: [1]+ Running
  ps shows: PID, USER, %CPU, %MEM, etc.

Open another terminal:
  jobs
  # Shows nothing!
  
  ps aux | grep sleep
  # Shows the process

Understanding:
  Jobs:
  - Shell concept
  - Only visible in originating shell
  - Use %N syntax
  - Managed with fg, bg, jobs
  - Job numbers are shell-local
  
  Processes:
  - System concept
  - Visible system-wide
  - Use PID
  - Managed with kill, ps, top
  - PIDs are unique across system
  
  When to use jobs:
  - Managing tasks in current shell
  - Quick fg/bg switching
  - Interactive terminal work
  
  When to use processes:
  - Managing tasks from any terminal
  - System-wide process management
  - Automated scripts
  - Service management

Clean up:
  killall sleep
  
  Or from original terminal:
  jobs
  kill %1 %2 %3 ...
  
  Or by PID:
  pkill sleep
  kill $(pgrep sleep)

Verification:
  jobs
  # Should show nothing
  
  pgrep sleep
  # Should return nothing

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=3
    
    echo "Checking your job management understanding..."
    echo ""
    
    # CHECK 1: No leftover sleep processes
    print_color "$CYAN" "[1/$total] Checking for cleanup..."
    local sleep_count=$(pgrep -u $(whoami) sleep 2>/dev/null | wc -l)
    
    if [ "$sleep_count" -eq 0 ]; then
        print_color "$GREEN" "  ✓ All jobs cleaned up"
        ((score++))
    else
        print_color "$YELLOW" "  Note: $sleep_count sleep process(es) still running"
        echo "  This is okay, but remember to clean up: killall sleep"
        ((score++))
    fi
    echo ""
    
    # CHECK 2: Understanding demonstrated
    print_color "$CYAN" "[2/$total] Checking understanding..."
    if [ $score -ge 1 ]; then
        print_color "$GREEN" "  ✓ Job control concepts explored"
        ((score++))
    fi
    echo ""
    
    # CHECK 3: Skills practiced
    print_color "$CYAN" "[3/$total] Checking skills practice..."
    if [ $score -ge 2 ]; then
        print_color "$GREEN" "  ✓ Job management skills demonstrated"
        ((score++))
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You understand:"
        echo "  • What processes and PIDs are"
        echo "  • How to start jobs in background"
        echo "  • Suspending and resuming jobs"
        echo "  • Managing multiple jobs"
        echo "  • Difference between jobs and processes"
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

STEP 1: Understanding processes
─────────────────────────────────────────────────────────────────
sleep 30
# In another terminal:
ps aux | grep sleep
pgrep sleep
ls /proc/$(pgrep sleep)


STEP 2: Background jobs
─────────────────────────────────────────────────────────────────
sleep 60 &
jobs
jobs -l


STEP 3: Suspend and resume
─────────────────────────────────────────────────────────────────
sleep 100
# Press Ctrl+Z
bg
jobs
fg
# Press Ctrl+C


STEP 4: Multiple jobs
─────────────────────────────────────────────────────────────────
sleep 200 & sleep 300 & sleep 400 &
jobs
fg %2
# Press Ctrl+Z
kill %1


STEP 5: Jobs vs processes
─────────────────────────────────────────────────────────────────
sleep 500 &
jobs
ps aux | grep sleep
killall sleep


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Processes:
  Every command creates a process
  PID = Process ID (unique system-wide)
  Managed by kernel
  Visible in ps, top, /proc/

Jobs:
  Shell concept for process management
  Job number [1], [2], etc.
  Shell-specific (not visible in other terminals)
  Managed with fg, bg, jobs

Background vs Foreground:
  Foreground: Blocks terminal
  Background: Runs independently
  & operator starts in background
  Ctrl+Z suspends foreground job

Key commands:
  jobs - List shell jobs
  fg - Move to foreground
  bg - Move to background
  kill %N - Kill job N
  Ctrl+Z - Suspend
  Ctrl+C - Terminate

Job notation:
  %N - Job number N
  %+ - Current job
  %- - Previous job
  %% - Current job


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using Ctrl+C instead of Ctrl+Z
  Ctrl+C kills the process
  Ctrl+Z suspends it
  Can't resume after Ctrl+C

Mistake 2: Forgetting & for background
  sleep 60 - Blocks terminal
  sleep 60 & - Runs in background

Mistake 3: Confusing job numbers with PIDs
  %1 for job numbers
  PID numbers without %

Mistake 4: Expecting jobs in different terminal
  Jobs are shell-specific
  Use ps to see from other terminals


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. & runs command in background
2. Ctrl+Z suspends, bg resumes in background
3. fg brings job to foreground
4. jobs shows only current shell's jobs
5. Use % with job numbers, not PIDs

Quick reference:
  command & - Start in background
  Ctrl+Z, bg - Suspend and background
  fg - Bring to foreground
  jobs - List jobs
  kill %N - Kill job

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Kill any sleep processes
    pkill -u $(whoami) sleep 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/jobs-lab 2>/dev/null || true
    
    echo "  ✓ All processes terminated"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
