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
LAB_TIME_ESTIMATE="25-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous test processes
    pkill -u $(whoami) -f "cpu-burner" 2>/dev/null || true
    sudo pkill -f "cpu-burner" 2>/dev/null || true
    rm -rf /tmp/priority-lab 2>/dev/null || true
    
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
  1. Start processes with nice values
     • Start CPU burner with nice value 10
     • Verify nice value in ps
     • Try starting with negative nice (needs sudo)
     • Understand nice ranges and permissions

  2. Change priority with renice
     • Start normal CPU burner (nice 0)
     • Increase nice to 15 with renice
     • Try to decrease nice (will fail as user)
     • Use sudo to set negative nice
     • Understand renice permissions

  3. Compare CPU allocation in top
     • Start 2 processes: nice 0 vs nice 19
     • Watch them compete in top (Shift+P)
     • Observe CPU % differences
     • Kill both processes

HINTS:
  • nice -n VALUE command
  • ps -o pid,ni,cmd shows nice value
  • renice -n VALUE -p PID
  • top: Shift+P sorts by CPU
  • Only root can set negative nice
  • Users can only increase nice

SUCCESS CRITERIA:
  • Can start processes with nice values
  • Can change priority with renice
  • Understand CPU allocation differences
  • Know permission restrictions
  • All test processes cleaned up
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Start processes with nice
  ☐ 2. Change priority with renice
  ☐ 3. Compare CPU allocation in top
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "3"
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
TASK: Start processes with different nice values

Learn how to launch processes with specific priority levels.

Requirements:
  • Start with low priority (nice 10):
    nice -n 10 /tmp/priority-lab/cpu-burner.sh &
  
  • Check nice value:
    ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
    (Should show NI=10)
  
  • Kill it:
    kill $(pgrep -f cpu-burner)
  
  • Start with high priority (needs sudo):
    sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &
  
  • Check nice value:
    ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
    (Should show NI=-10)
  
  • Kill it:
    sudo kill $(pgrep -f cpu-burner)

Nice ranges: -20 (highest) to 19 (lowest)
Regular users: 0 to 19 only
Root: can set any value
EOF
}

validate_step_1() {
    # Check cleanup
    if pgrep -f "cpu-burner" >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: cpu-burner still running"
        echo "  Clean up: pkill -f cpu-burner or sudo pkill -f cpu-burner"
    fi
    
    return 0
}

hint_step_1() {
    cat << 'EOF'
  Low priority: nice -n 10 /tmp/priority-lab/cpu-burner.sh &
  Check: ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
  Kill: kill $(pgrep -f cpu-burner)
  High priority: sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &
  Kill: sudo kill $(pgrep -f cpu-burner)
EOF
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Start with low priority:
  nice -n 10 /tmp/priority-lab/cpu-burner.sh &

Check nice value:
  ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
  # NI column shows: 10

Kill it:
  kill $(pgrep -f cpu-burner)

Start with high priority (needs root):
  sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &

Check nice value:
  ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
  # NI column shows: -10

Kill it (needs sudo since started by root):
  sudo kill $(pgrep -f cpu-burner)

Understanding nice:
  Syntax: nice -n VALUE command
  
  Nice range:
  -20 = highest priority (most CPU)
    0 = default/normal priority
   19 = lowest priority (least CPU)
  
  Permission rules:
  Regular users: Can only set 0 to 19
  Root: Can set -20 to 19
  
  Higher nice = "nicer" to other processes
  
  Typical values:
  -10: Important system daemons
    0: Normal user processes
   10: Background batch jobs
   19: Lowest priority tasks

EOF
}

hint_step_2() {
    cat << 'EOF'
  Start: /tmp/priority-lab/cpu-burner.sh &
  Get PID: pgrep -f cpu-burner
  Check: ps -o pid,ni,cmd -p PID (shows 0)
  Increase: renice -n 15 -p PID (works)
  Decrease: renice -n 5 -p PID (fails)
  Sudo: sudo renice -n -5 -p PID (works)
  Kill: sudo kill PID
EOF
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Change priority with renice and test permissions

Adjust running process priority and understand permission limits.

Requirements:
  • Start CPU burner normally:
    /tmp/priority-lab/cpu-burner.sh &
  
  • Get PID and check nice (should be 0):
    ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
  
  • Increase nice to 15 (works):
    renice -n 15 -p $(pgrep -f cpu-burner)
  
  • Verify change:
    ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
  
  • Try to decrease to 5 (will fail):
    renice -n 5 -p $(pgrep -f cpu-burner)
    Observe: Permission denied
  
  • Use sudo to set negative nice:
    sudo renice -n -5 -p $(pgrep -f cpu-burner)
  
  • Verify:
    ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
  
  • Kill it:
    sudo kill $(pgrep -f cpu-burner)

Users can only increase nice (lower priority).
Root can set any value.
EOF
}

validate_step_2() {
    # Check cleanup
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
Start process normally:
  /tmp/priority-lab/cpu-burner.sh &

Get PID:
  PID=$(pgrep -f cpu-burner)

Check initial nice:
  ps -o pid,ni,cmd -p $PID
  # NI shows: 0 (default)

Increase nice to 15:
  renice -n 15 -p $PID
  # Works for regular users

Verify:
  ps -o pid,ni,cmd -p $PID
  # NI shows: 15

Try to decrease to 5:
  renice -n 5 -p $PID
  # Error: Permission denied

Use sudo to set negative:
  sudo renice -n -5 -p $PID

Verify:
  ps -o pid,ni,cmd -p $PID
  # NI shows: -5

Kill it:
  sudo kill $PID

Understanding renice:
  Syntax: renice -n VALUE -p PID
  
  Can also target:
  -u USER: All user processes
  -g GID: Process group
  
  Permission rules:
  Regular users:
  ✓ Can increase nice (0→10, 10→15)
  ✗ Cannot decrease nice (10→5, 5→0)
  ✗ Cannot set negative values
  
  Root:
  ✓ Can set any value
  ✓ Can increase or decrease

Why restriction exists:
  Prevents users from hogging CPU
  Users can be "nice" but not greedy

Real-world use:
  Background job using too much CPU:
    ps aux | grep backup
    renice -n 15 -p 5432
  Now system is responsive again

EOF
}

hint_step_3() {
    cat << 'EOF'
  Start normal: /tmp/priority-lab/cpu-burner.sh &
  Start low: nice -n 19 /tmp/priority-lab/cpu-burner.sh &
  Watch: top
  Sort: Press Shift+P (capital P for CPU sort)
  Observe: Nice 0 gets more %CPU than nice 19
  Kill: pkill -f cpu-burner
EOF
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Compare CPU allocation between priorities in top

See how nice values actually affect CPU time distribution.

Requirements:
  • Start first process normally:
    /tmp/priority-lab/cpu-burner.sh &
  
  • Start second with lowest priority:
    nice -n 19 /tmp/priority-lab/cpu-burner.sh &
  
  • Open top:
    top
  
  • Sort by CPU usage:
    Press Shift+P (capital P)
  
  • Observe differences:
    - Look at %CPU column
    - Nice 0 gets more CPU
    - Nice 19 gets less CPU
    - Look at NI column to confirm values
  
  • Press q to quit top
  
  • Kill both:
    pkill -f cpu-burner

This demonstrates CPU scheduler favoring lower nice values.
EOF
}

validate_step_3() {
    # Check all cpu-burners killed
    if pgrep -f "cpu-burner" >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ CPU burners still running"
        echo "  Kill them: pkill -f cpu-burner"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Start normal priority:
  /tmp/priority-lab/cpu-burner.sh &

Start low priority:
  nice -n 19 /tmp/priority-lab/cpu-burner.sh &

Open top:
  top

Sort by CPU:
  Press Shift+P
  (That's capital P - sorts by CPU usage)

Observe:
  %CPU column shows usage
  NI column shows nice value
  
  Typical results:
  Nice 0: 65% CPU
  Nice 19: 35% CPU
  
  (Exact values vary, but nice 0 gets more)

Press q to quit top

Alternative view:
  ps -o pid,ni,%cpu,cmd -p $(pgrep -f cpu-burner)

Kill both:
  pkill -f cpu-burner

Understanding CPU scheduling:
  Scheduler gives more time to lower nice
  Higher nice = more likely preempted
  
  Examples:
  Nice -10 vs Nice 10: -10 gets ~90%
  Nice 0 vs Nice 19: 0 gets ~65%
  Nice 0 vs Nice 0: Each gets ~50%

Real-world scenario:
  Web server (nice 0) vs Backup (nice 15)
  - Users get responsive web pages
  - Backup runs slower but doesn't impact users
  - Both processes make progress

Multiple processes:
  Nice values are relative
  Scheduler balances based on priorities
  All processes run, but at different speeds

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
    local test_count=$(pgrep -u $(whoami) -c "cpu-burner" 2>/dev/null || echo "0")
    
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

STEP 1: Start with nice
─────────────────────────────────────────────────────────────────
nice -n 10 /tmp/priority-lab/cpu-burner.sh &
ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
kill $(pgrep -f cpu-burner)

sudo nice -n -10 /tmp/priority-lab/cpu-burner.sh &
ps -o pid,ni,cmd -p $(pgrep -f cpu-burner)
sudo kill $(pgrep -f cpu-burner)


STEP 2: Change with renice
─────────────────────────────────────────────────────────────────
/tmp/priority-lab/cpu-burner.sh &
PID=$(pgrep -f cpu-burner)
renice -n 15 -p $PID
ps -o pid,ni,cmd -p $PID

renice -n 5 -p $PID  # Fails
sudo renice -n -5 -p $PID  # Works
ps -o pid,ni,cmd -p $PID
sudo kill $PID


STEP 3: Compare in top
─────────────────────────────────────────────────────────────────
/tmp/priority-lab/cpu-burner.sh &
nice -n 19 /tmp/priority-lab/cpu-burner.sh &
top
# Press Shift+P to sort by CPU
# Observe differences
# Press q to quit
pkill -f cpu-burner


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Nice values:
  -20 = highest priority
    0 = normal priority
   19 = lowest priority

Commands:
  nice -n VALUE command
  renice -n VALUE -p PID

Permissions:
  Users: 0 to 19 only, can only increase
  Root: -20 to 19, can do anything

CPU allocation:
  Lower nice = more CPU
  Higher nice = less CPU
  Values are relative


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical commands:
1. nice -n 10 command
2. renice -n 15 -p PID
3. ps -o pid,ni,cmd
4. top (Shift+P for CPU sort)

Remember:
  Higher nice = lower priority
  Users can only increase nice
  Use for batch jobs
  top shows NI column

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
    
    # Remove test files
    rm -rf /tmp/priority-lab 2>/dev/null || true
    
    echo "  ✓ All test processes terminated"
    echo "  ✓ Test files removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
