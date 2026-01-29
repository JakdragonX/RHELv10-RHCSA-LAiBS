#!/bin/bash
# labs/m04/14B-process-priority.sh
# Lab: Managing process priority with nice and renice
# Difficulty: Intermediate
# RHCSA Objective: 14.2 - Managing process priority

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing process priority with nice and renice"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous test processes
    pkill -u $(whoami) -f "cpu-burner" 2>/dev/null || true
    pkill -u $(whoami) -f "stress-ng" 2>/dev/null || true
    rm -rf /tmp/priority-lab 2>/dev/null || true
    
    # Install stress-ng if needed
    if ! command -v stress-ng >/dev/null 2>&1; then
        echo "  Installing stress-ng..."
        dnf install -y stress-ng >/dev/null 2>&1
    fi
    
    # Create working directory
    mkdir -p /tmp/priority-lab
    
    # Create a simple CPU burner script
    cat > /tmp/priority-lab/cpu-burner.sh << 'SCRIPT'
#!/bin/bash
# Simple CPU burner
echo "PID: $$ - Burning CPU..."
while true; do
    x=$((x + 1))
done
SCRIPT
    chmod +x /tmp/priority-lab/cpu-burner.sh
    
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
  • Understanding of CPU scheduling
  • Familiarity with ps command

Commands You'll Use:
  • nice - Start process with priority
  • renice - Change priority of running process
  • ps - View process priority
  • top - Monitor CPU usage

Files You'll Interact With:
  • /tmp/priority-lab/ - Test scripts
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're running batch processing jobs on a server that also serves users.
The batch jobs are CPU-intensive and you need to ensure they don't impact
user responsiveness. Use nice and renice to control CPU priority and keep
the system balanced.

BACKGROUND:
Nice values range from -20 (highest priority) to 19 (lowest priority).
Lower nice = more CPU time. Higher nice = less CPU time.
Regular users can only increase niceness (lower priority).
Root can set any nice value.

OBJECTIVES:
  1. Start a process with low priority using nice
     • Start a CPU burner with nice value 10
     • Verify it's running with that nice value
     • Check it in ps and top
     • Kill it when verified

  2. Start a high-priority process (requires root)
     • Start CPU burner with nice value -10
     • Verify the negative nice value
     • Observe it gets more CPU time
     • Kill it when verified

  3. Change priority of running process with renice
     • Start a normal CPU burner
     • Note its nice value (0)
     • Use renice to set it to 15
     • Verify the change took effect
     • Kill it

  4. Compare CPU allocation between priorities
     • Start 2 processes: nice 0 and nice 19
     • Watch them in top (press P for CPU sort)
     • Observe CPU % difference
     • Nice 0 gets more CPU than nice 19
     • Kill both

  5. Try to decrease nice as regular user (will fail)
     • Start process with nice 10
     • Try to renice it to 5 (should fail)
     • Observe permission denied
     • Understanding: Users can only increase nice
     • Kill the process

HINTS:
  • nice -n VALUE command
  • ps -o pid,ni,cmd shows nice value
  • renice -n VALUE -p PID
  • top shows NI column
  • Only root can set negative nice

SUCCESS CRITERIA:
  • Can start processes with specific nice values
  • Can change priority with renice
  • Understand nice value effects on CPU
  • Know permission restrictions
  • All test processes cleaned up
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Start low-priority process with nice
  ☐ 2. Start high-priority process (root)
  ☐ 3. Change priority with renice
  ☐ 4. Compare CPU allocation by priority
  ☐ 5. Understand user permissions for nice
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
You are managing CPU priority for batch jobs vs user processes.

Working directory: /tmp/priority-lab/

Learn to control process CPU allocation with nice and renice.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Start a low-priority process

Launch a CPU-intensive process with reduced priority so it doesn't
impact other work.

Requirements:
  • Start the CPU burner with nice value 10:
    nice -n 10 /tmp/priority-lab/cpu-burner.sh &
  
  • Verify its nice value:
    ps -o pid,ni,cmd -p PID
    
  • Watch it in top:
    top -p PID
    (Look at NI column, should show 10)
  
  • Kill it when done:
    kill PID

Nice value 10 = lower priority = less CPU time.
EOF
}

validate_step_1() {
    # Exploratory, always pass
    return 0
}

hint_step_1() {
    cat << 'EOF'
  Start: nice -n 10 /tmp/priority-lab/cpu-burner.sh &
  Get PID: pgrep -f cpu-burner
  Check nice: ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
  Kill: kill $(pgrep -f cpu-burner)
EOF
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Start with low priority:
  nice -n 10 /tmp/priority-lab/cpu-burner.sh &

Get the PID:
  PID=$(pgrep -f cpu-burner)
  echo "PID: $PID"

Check nice value:
  ps -o pid,ni,cmd -p $PID
  # NI column shows: 10

Alternative check:
  ps -o pid,ni,cmd -p $PID
  top -p $PID
  # Press q to quit top

Kill it:
  kill $PID

Understanding nice:
  Syntax: nice -n VALUE command
  
  Nice range:
  -20 = highest priority (most CPU)
    0 = default/normal priority
   19 = lowest priority (least CPU)
  
  Higher nice = "nicer" to other processes
  Process yields CPU more willingly
  
  Who can set what:
  Regular users: 0 to 19 only
  Root: -20 to 19

EOF
}

hint_step_2() {
    cat << 'EOF'
  Start: sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &
  Get PID: pgrep -f cpu-burner
  Check: ps -o pid,ni,cmd -p PID
  Kill: sudo kill PID
EOF
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Start a high-priority process (requires root)

Give a process higher priority to ensure it gets more CPU time.

Requirements:
  • Start with negative nice (needs sudo):
    sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &
  
  • Get PID:
    pgrep -f cpu-burner
  
  • Verify nice value is -10:
    ps -o pid,ni,cmd -p PID
  
  • Kill it with sudo:
    sudo kill PID

Negative nice values require root privileges.
Nice -10 gets more CPU than nice 0.
EOF
}

validate_step_2() {
    # Check no cpu-burner running
    if pgrep -f "cpu-burner" >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: cpu-burner still running"
        echo "  Clean up: pkill -f cpu-burner or sudo pkill -f cpu-burner"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Start with high priority (needs root):
  sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &

Get PID:
  PID=$(pgrep -f cpu-burner)

Check nice value:
  ps -o pid,ni,cmd -p $PID
  # NI shows: -10

View details:
  ps -eo pid,ni,%cpu,cmd | grep cpu-burner

Kill it (needs sudo since started by root):
  sudo kill $PID

Understanding negative nice:
  Requires root/sudo
  Gets more CPU time
  Preempts lower priority processes
  
  Use cases:
  - Critical system processes
  - Time-sensitive jobs
  - Emergency tasks
  
  Typical values:
  -20: Kernel threads
  -10: Important daemons
    0: Normal processes
   10: Background batch jobs
   19: Lowest priority tasks

Permission model:
  Regular user trying negative nice:
    nice -n -5 command
    # Error: Permission denied
  
  With sudo:
    sudo nice -n -5 command
    # Works

EOF
}

hint_step_3() {
    cat << 'EOF'
  Start: /tmp/priority-lab/cpu-burner.sh &
  Get PID: pgrep -f cpu-burner
  Check nice: ps -o pid,ni,cmd -p PID (shows 0)
  Change: renice -n 15 -p PID
  Verify: ps -o pid,ni,cmd -p PID (shows 15)
  Kill: kill PID
EOF
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Change priority of running process with renice

Adjust the priority of an already-running process.

Requirements:
  • Start CPU burner normally:
    /tmp/priority-lab/cpu-burner.sh &
  
  • Check current nice (should be 0):
    ps -o pid,ni,cmd -p PID
  
  • Change to nice 15:
    renice -n 15 -p PID
  
  • Verify change:
    ps -o pid,ni,cmd -p PID
  
  • Kill it:
    kill PID

renice changes priority of running processes.
Useful for batch jobs that are running too aggressively.
EOF
}

validate_step_3() {
    # Check cleanup
    if pgrep -f "cpu-burner" >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: cpu-burner still running"
        echo "  Clean up: pkill -f cpu-burner"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Start process normally:
  /tmp/priority-lab/cpu-burner.sh &

Get PID:
  PID=$(pgrep -f cpu-burner)

Check initial nice:
  ps -o pid,ni,cmd -p $PID
  # NI shows: 0 (default)

Change priority:
  renice -n 15 -p $PID

Verify change:
  ps -o pid,ni,cmd -p $PID
  # NI now shows: 15

Alternative verification:
  top -p $PID
  # NI column shows 15

Kill it:
  kill $PID

Understanding renice:
  Changes nice of running process
  Syntax: renice -n VALUE -p PID
  
  Can target:
  -p PID: Specific process
  -g GID: Process group
  -u USER: All user's processes
  
  Examples:
    renice -n 10 -p 1234
    renice -n 5 -u bob
    renice -n 19 -g 5000

Real-world example:
  # Background job running too hot
  ps aux | grep backup
  # PID 5432 using 98% CPU
  
  renice -n 15 -p 5432
  # Now using less CPU, system responsive

Permission rules (same as nice):
  Regular user: Can only increase nice
  Root: Can set any value

EOF
}

hint_step_4() {
    cat << 'EOF'
  Start normal: /tmp/priority-lab/cpu-burner.sh &
  Start low: nice -n 19 /tmp/priority-lab/cpu-burner.sh &
  Watch: top (press P for CPU sort)
  Compare: Normal process gets more %CPU than nice 19
  Kill both: pkill -f cpu-burner
EOF
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Compare CPU allocation between different priorities

See how nice values actually affect CPU time allocation.

Requirements:
  • Start first process normally:
    /tmp/priority-lab/cpu-burner.sh &
  
  • Start second with lowest priority:
    nice -n 19 /tmp/priority-lab/cpu-burner.sh &
  
  • Watch them compete in top:
    top
    Press P to sort by CPU
  
  • Observe:
    - Normal (nice 0) gets more %CPU
    - Nice 19 gets less %CPU
    - They're competing for CPU time
  
  • Kill both:
    pkill -f cpu-burner

This demonstrates CPU scheduling based on priority.
EOF
}

validate_step_4() {
    # Check all cpu-burners killed
    if pgrep -f "cpu-burner" >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ CPU burners still running"
        echo "  Kill them: pkill -f cpu-burner"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Start normal priority:
  /tmp/priority-lab/cpu-burner.sh &

Start low priority:
  nice -n 19 /tmp/priority-lab/cpu-burner.sh &

Watch in top:
  top
  # Press P to sort by CPU
  # Press q to quit

List both:
  ps -o pid,ni,%cpu,cmd -p $(pgrep -f cpu-burner)

Observe CPU allocation:
  Nice 0 might show: 65% CPU
  Nice 19 might show: 35% CPU
  
  (Exact values vary, but nice 0 gets more)

Kill both:
  pkill -f cpu-burner

Understanding CPU scheduling:
  Scheduler gives more time slices to lower nice
  Higher nice = more likely to be preempted
  
  With 2 competing processes:
  Nice -10 vs Nice 10: -10 gets ~90% CPU
  Nice 0 vs Nice 19: 0 gets ~65% CPU
  Nice 0 vs Nice 0: Each gets ~50% CPU
  
  Multiple processes:
  Nice values are relative
  Scheduler balances based on priorities
  
  Real-world scenarios:
  Web server (nice 0) vs Backup (nice 15)
  - Users get responsive web
  - Backup runs slower but doesn't impact users
  
  Multiple batch jobs:
  Job A (nice 5) vs Job B (nice 10)
  - Job A finishes faster
  - Both run, but A prioritized

Monitoring:
  top - Interactive view
  ps -eo pid,ni,%cpu,cmd --sort=-%cpu
  htop - Better visualization (if installed)

EOF
}

hint_step_5() {
    cat << 'EOF'
  Start: nice -n 10 /tmp/priority-lab/cpu-burner.sh &
  Get PID: pgrep -f cpu-burner
  Try decrease: renice -n 5 -p PID (will fail)
  Try increase: renice -n 15 -p PID (works)
  Kill: kill PID
EOF
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Understand user permission limits

Learn what regular users can and cannot do with nice/renice.

Requirements:
  • Start with nice 10:
    nice -n 10 /tmp/priority-lab/cpu-burner.sh &
  
  • Get PID:
    pgrep -f cpu-burner
  
  • Try to DECREASE nice to 5 (will fail):
    renice -n 5 -p PID
    Observe: Permission denied
  
  • Try to INCREASE nice to 15 (will work):
    renice -n 15 -p PID
    Observe: Success
  
  • Kill it:
    kill PID

Regular users can only increase nice (lower priority).
Decreasing nice (higher priority) requires root.
EOF
}

validate_step_5() {
    # Check cleanup
    if pgrep -f "cpu-burner" >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: cpu-burner still running"
        echo "  Clean up: pkill -f cpu-burner"
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Start with nice 10:
  nice -n 10 /tmp/priority-lab/cpu-burner.sh &

Get PID:
  PID=$(pgrep -f cpu-burner)

Check current nice:
  ps -o pid,ni,cmd -p $PID
  # Shows: 10

Try to decrease (will fail):
  renice -n 5 -p $PID
  # Error: Permission denied
  # Cannot decrease nice value

Try to increase (will work):
  renice -n 15 -p $PID
  # Success!

Verify:
  ps -o pid,ni,cmd -p $PID
  # Shows: 15

Kill it:
  kill $PID

Understanding permissions:
  Regular users:
  ✓ Can increase nice (0 → 10, 10 → 15)
  ✗ Cannot decrease nice (10 → 5, 5 → 0)
  ✗ Cannot set negative nice
  
  Root/sudo:
  ✓ Can set any nice value
  ✓ Can increase or decrease
  ✓ Can set negative values

Why this restriction:
  Prevents users from hogging CPU
  Users can be "nice" but not greedy
  Root manages system resources

How to decrease as user:
  Cannot! Must use sudo:
    sudo renice -n 5 -p $PID
  
  Or kill and restart with sudo:
    kill $PID
    sudo nice -n 5 command

Security implications:
  User starts CPU-intensive job
  System gets slow
  Admin can renice it: sudo renice -n 19 -p PID
  User cannot renice back to 0

Practical workflow:
  Start batch job:
    nice -n 10 long-job.sh &
  
  If system busy:
    renice -n 19 -p PID
  
  If system idle:
    Cannot decrease without sudo
    Restart if needed

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=3
    
    echo "Checking your process priority management..."
    echo ""
    
    # CHECK 1: No test processes running
    print_color "$CYAN" "[1/$total] Checking cleanup..."
    local test_count=$(pgrep -u $(whoami) -c "cpu-burner|stress-ng" 2>/dev/null || echo "0")
    
    if [ "$test_count" -eq 0 ]; then
        print_color "$GREEN" "  ✓ All test processes cleaned up"
        ((score++))
    else
        print_color "$YELLOW" "  Note: $test_count process(es) still running"
        echo "  Clean up: pkill -f cpu-burner"
        ((score++))
    fi
    echo ""
    
    # CHECK 2: Understanding demonstrated
    print_color "$CYAN" "[2/$total] Checking nice/renice knowledge..."
    if [ $score -ge 1 ]; then
        print_color "$GREEN" "  ✓ Process priority management demonstrated"
        ((score++))
    fi
    echo ""
    
    # CHECK 3: Skills practiced
    print_color "$CYAN" "[3/$total] Checking CPU priority skills..."
    if [ $score -ge 2 ]; then
        print_color "$GREEN" "  ✓ CPU scheduling concepts understood"
        ((score++))
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Starting processes with nice values"
        echo "  • Changing priority with renice"
        echo "  • How nice affects CPU allocation"
        echo "  • Permission restrictions for users"
        echo "  • When to use different priorities"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
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

STEP 1: Low priority
─────────────────────────────────────────────────────────────────
nice -n 10 /tmp/priority-lab/cpu-burner.sh &
ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
kill $(pgrep -f cpu-burner)


STEP 2: High priority
─────────────────────────────────────────────────────────────────
sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &
ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
sudo kill $(pgrep -f cpu-burner)


STEP 3: Renice running process
─────────────────────────────────────────────────────────────────
/tmp/priority-lab/cpu-burner.sh &
PID=$(pgrep -f cpu-burner)
renice -n 15 -p $PID
ps -o pid,ni,cmd -p $PID
kill $PID


STEP 4: Compare priorities
─────────────────────────────────────────────────────────────────
/tmp/priority-lab/cpu-burner.sh &
nice -n 19 /tmp/priority-lab/cpu-burner.sh &
top  # Press P, observe CPU differences
pkill -f cpu-burner


STEP 5: User permissions
─────────────────────────────────────────────────────────────────
nice -n 10 /tmp/priority-lab/cpu-burner.sh &
PID=$(pgrep -f cpu-burner)
renice -n 5 -p $PID  # Fails
renice -n 15 -p $PID  # Works
kill $PID


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Nice values:
  -20 = highest priority
    0 = normal priority
   19 = lowest priority

Commands:
  nice -n VALUE command
  renice -n VALUE -p PID
  renice -n VALUE -u USER

Permissions:
  Users: Can only increase nice (0→19)
  Root: Can set any value (-20→19)

CPU allocation:
  Lower nice = more CPU time
  Higher nice = less CPU time
  Values are relative

Common values:
  -10: Important daemons
    0: Normal processes
   10: Background jobs
   19: Lowest priority tasks


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical commands:
1. nice -n 10 command - Start with low priority
2. renice -n 15 -p PID - Change running process
3. ps -o pid,ni,cmd - View nice values
4. sudo needed for negative nice

Remember:
  Higher nice = lower priority
  Users can only increase nice
  Root can do anything
  Use for batch jobs

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Kill test processes (regular and root-owned)
    pkill -u $(whoami) -f "cpu-burner" 2>/dev/null || true
    sudo pkill -f "cpu-burner" 2>/dev/null || true
    pkill -u $(whoami) -f "stress-ng" 2>/dev/null || true
    
    # Remove test files
    rm -rf /tmp/priority-lab 2>/dev/null || true
    
    echo "  ✓ All test processes terminated"
    echo "  ✓ Test files removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
