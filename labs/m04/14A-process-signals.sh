#!/bin/bash
# labs/m04/14A-process-signals.sh
# Lab: Managing processes with signals
# Difficulty: Beginner
# RHCSA Objective: 14.1 - Using signals to manage process states

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing processes with signals"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="25-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous test processes
    pkill -u $(whoami) -f "test-daemon" 2>/dev/null || true
    pkill -u $(whoami) -f "signal-test" 2>/dev/null || true
    rm -rf /tmp/signal-lab 2>/dev/null || true
    
    # Create working directory
    mkdir -p /tmp/signal-lab
    
    # Create a test script that handles signals
    cat > /tmp/signal-lab/signal-test.sh << 'SCRIPT'
#!/bin/bash
# Signal test script

trap 'echo "Caught SIGTERM, cleaning up..."; exit 0' TERM
trap 'echo "Caught SIGHUP, reloading config..."' HUP
trap 'echo "Caught SIGUSR1, doing custom action..."' USR1

echo "PID: $$"
echo "Signal test running. Send me signals!"

while true; do
    sleep 1
done
SCRIPT
    chmod +x /tmp/signal-lab/signal-test.sh
    
    echo "  ✓ Test scripts created"
    echo "  ✓ Lab environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic process management
  • Understanding of PIDs
  • Familiarity with ps and kill

Commands You'll Use:
  • kill - Send signal to process
  • pkill - Kill by process name
  • killall - Kill all instances
  • trap - Handle signals (in scripts)

Files You'll Interact With:
  • /tmp/signal-lab/ - Test scripts
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You need to manage misbehaving processes on a production server. Some processes
need graceful shutdown, others need to reload configuration, and some are hung
and require forceful termination. Master signal usage to control processes
without causing data corruption.

BACKGROUND:
Signals are how the kernel and administrators communicate with processes.
Knowing when to use SIGTERM vs SIGKILL, how to reload configs with SIGHUP,
and how to use custom signals is essential for production system management.

OBJECTIVES:
  1. Terminate a process gracefully with SIGTERM
     • Start the test script
     • Find its PID
     • Send SIGTERM (default kill)
     • Verify it cleaned up properly

  2. Force kill a hung process with SIGKILL
     • Start a sleep process
     • Try SIGTERM (it will ignore)
     • Use SIGKILL to force termination
     • Verify it's actually dead

  3. Reload a process configuration with SIGHUP
     • Start the test script
     • Send SIGHUP signal
     • Observe it reloads without dying
     • Process continues running

  4. Use pkill and killall efficiently
     • Start multiple sleep processes
     • Kill all by name with pkill
     • Verify all instances terminated
     • Understand when to use each tool

  5. Stop and continue a process
     • Start a process
     • Pause it with SIGSTOP
     • Verify it's stopped
     • Resume with SIGCONT
     • Verify it's running again

HINTS:
  • Default kill sends SIGTERM (15)
  • kill -9 sends SIGKILL (cannot be caught)
  • kill -HUP sends SIGHUP (reload)
  • SIGSTOP pauses, SIGCONT resumes
  • pkill works on process names

SUCCESS CRITERIA:
  • Can gracefully terminate processes
  • Can force kill when necessary
  • Can reload process configs
  • Can stop/continue processes
  • Understand signal differences
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Graceful termination with SIGTERM
  ☐ 2. Force kill with SIGKILL
  ☐ 3. Reload config with SIGHUP
  ☐ 4. Mass termination with pkill
  ☐ 5. Stop and continue processes
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
You are managing processes on a production server using signals.

Working directory: /tmp/signal-lab/

Learn to control processes with different signals.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Terminate a process gracefully with SIGTERM

Start a process and terminate it cleanly so it can clean up resources.

Requirements:
  • Start the test script: /tmp/signal-lab/signal-test.sh &
  • Note its PID when it starts
  • Send SIGTERM to it: kill PID
  • Observe it says "Caught SIGTERM, cleaning up..."
  • Verify process is gone

SIGTERM (15) is the default signal.
It allows the process to clean up before exiting.
EOF
}

validate_step_1() {
    # Check no signal-test processes running
    if pgrep -u $(whoami) -f "signal-test" >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: signal-test still running"
        echo "  Make sure to kill it for this step"
    fi
    
    return 0
}

hint_step_1() {
    cat << 'EOF'
  Start: /tmp/signal-lab/signal-test.sh &
  Find PID: It prints its own PID, or use: pgrep -f signal-test
  Kill: kill PID (SIGTERM is default)
  Verify: pgrep -f signal-test (should be empty)
EOF
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Start the test script:
  /tmp/signal-lab/signal-test.sh &

It will print its PID and keep running.

Get the PID:
  pgrep -f signal-test
  # Or it printed PID when started

Send SIGTERM:
  kill PID
  # Or: kill -15 PID
  # Or: kill -TERM PID

Observe output:
  "Caught SIGTERM, cleaning up..."
  Process exits

Verify it's gone:
  pgrep -f signal-test
  # Should return nothing

Understanding SIGTERM:
  Signal number: 15
  Default signal when you type: kill PID
  Process can catch it
  Allows cleanup (close files, save state)
  Process can ignore it (bad practice)
  
  Use SIGTERM first, always
  It's the polite way to ask a process to exit

EOF
}

hint_step_2() {
    cat << 'EOF'
  Start: sleep 300 &
  Get PID: pgrep sleep
  Force kill: kill -9 PID
  Verify: pgrep sleep (empty)
EOF
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Force kill a hung process with SIGKILL

When a process won't respond to SIGTERM, use SIGKILL as last resort.

Requirements:
  • Start: sleep 300 &
  • Get its PID
  • Try: kill PID (SIGTERM - won't kill sleep)
  • Use: kill -9 PID (SIGKILL - immediate death)
  • Verify it's dead

SIGKILL (9) cannot be caught or ignored.
Use it only when SIGTERM fails.
Process gets NO chance to clean up.
EOF
}

validate_step_2() {
    # Check no sleep processes from user
    if pgrep -u $(whoami) sleep >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Sleep process still running"
        echo "  Kill it with: kill -9 \$(pgrep sleep)"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Start sleep:
  sleep 300 &

Get PID:
  PID=$(pgrep sleep)
  echo $PID

Try SIGTERM (won't work on sleep):
  kill $PID
  # Sleep ignores SIGTERM by default

Process still running:
  pgrep sleep
  # Still there

Force kill with SIGKILL:
  kill -9 $PID
  # Or: kill -KILL $PID
  # Or: kill -SIGKILL $PID

Verify terminated:
  pgrep sleep
  # Should be gone

Understanding SIGKILL:
  Signal number: 9
  Cannot be caught
  Cannot be ignored
  Cannot be blocked
  Immediate termination
  NO cleanup happens
  
  Dangers:
  - Corrupted data
  - Lost work
  - Locked files
  - Resources not freed
  
  When to use:
  - Process hung/frozen
  - SIGTERM already failed
  - Emergency situations
  - Last resort only

Proper kill sequence:
  1. Try SIGTERM (kill PID)
  2. Wait 5-10 seconds
  3. Check if still running
  4. Use SIGKILL if necessary (kill -9 PID)

EOF
}

hint_step_3() {
    cat << 'EOF'
  Start: /tmp/signal-lab/signal-test.sh &
  Get PID: pgrep -f signal-test
  Reload: kill -HUP PID
  Observe: It says "reloading config" but keeps running
  Verify: pgrep -f signal-test (still there)
EOF
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Reload process configuration with SIGHUP

Many daemons reload their config when receiving SIGHUP.

Requirements:
  • Start: /tmp/signal-lab/signal-test.sh &
  • Get PID
  • Send SIGHUP: kill -HUP PID
  • Observe it says "reloading config"
  • Verify process is still running
  • Kill it with SIGTERM when done

SIGHUP (1) traditionally meant "hangup" (terminal disconnected).
Modern use: Reload configuration without restarting.
EOF
}

validate_step_3() {
    # This is exploratory, always pass
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Start test script:
  /tmp/signal-lab/signal-test.sh &

Get PID:
  PID=$(pgrep -f signal-test)

Send SIGHUP:
  kill -HUP $PID
  # Or: kill -1 $PID
  # Or: kill -SIGHUP $PID

Observe output:
  "Caught SIGHUP, reloading config..."
  Process continues running

Verify still running:
  pgrep -f signal-test
  # Still there

Send multiple SIGHUPs:
  kill -HUP $PID
  kill -HUP $PID
  # Each time it reloads

Clean up when done:
  kill $PID

Understanding SIGHUP:
  Signal number: 1
  Original meaning: Terminal hangup
  Modern use: Reload configuration
  
  Common daemons using SIGHUP:
  - nginx: Reload config
  - apache: Graceful restart
  - sshd: Re-read config
  - rsyslog: Rotate logs
  
  Example real-world use:
    vi /etc/nginx/nginx.conf
    # Edit configuration
    nginx -t
    # Test config syntax
    pkill -HUP nginx
    # Reload without dropping connections

EOF
}

hint_step_4() {
    cat << 'EOF'
  Start multiple: sleep 100 & sleep 200 & sleep 300 &
  Count them: pgrep sleep | wc -l
  Kill all: pkill sleep
  Verify: pgrep sleep (empty)
EOF
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Use pkill to terminate multiple processes

Kill all instances of a process by name efficiently.

Requirements:
  • Start three sleep processes:
    sleep 100 & sleep 200 & sleep 300 &
  
  • Count how many sleep processes you have
  
  • Kill ALL of them with one command: pkill sleep
  
  • Verify all are gone

pkill kills by process name, not PID.
Useful for cleaning up multiple instances.
EOF
}

validate_step_4() {
    # Check all sleep processes gone
    if pgrep -u $(whoami) sleep >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Sleep processes still running"
        echo "  Kill them: pkill sleep"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Start multiple processes:
  sleep 100 &
  sleep 200 &
  sleep 300 &

Count them:
  pgrep sleep | wc -l
  # Should show 3

List them:
  pgrep sleep
  # Shows 3 PIDs

Kill all at once:
  pkill sleep
  # Sends SIGTERM to all matching processes

Verify all gone:
  pgrep sleep
  # Should be empty

Alternative methods:
  killall sleep
  # Same as pkill

  kill $(pgrep sleep)
  # Manual way

  pkill -9 sleep
  # Force kill all

Understanding pkill:
  Matches process name
  Can use patterns
  Can filter by user: pkill -u username
  Default signal: SIGTERM
  Can specify signal: pkill -9 process
  
  pkill vs killall:
  - pkill: Pattern matching, more flexible
  - killall: Exact name match
  - Both send signals to multiple processes

Safety with pkill:
  Check first:
    pgrep -a sleep
    # Shows what matches
  
  Then kill:
    pkill sleep
  
  Always verify:
    pgrep sleep

EOF
}

hint_step_5() {
    cat << 'EOF'
  Start: sleep 500 &
  Get PID: pgrep sleep
  Stop: kill -STOP PID
  Check state: ps -p PID -o state=
  Continue: kill -CONT PID
  Check state: ps -p PID -o state=
  Clean up: kill PID
EOF
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Stop and continue a process

Pause and resume processes without killing them.

Requirements:
  • Start: sleep 500 &
  • Get its PID
  • Pause it: kill -STOP PID
  • Check its state: ps -p PID -o state=
    (Should show T for stopped)
  • Resume it: kill -CONT PID
  • Check state again: ps -p PID -o state=
    (Should show S for sleeping)
  • Kill it when done: kill PID

SIGSTOP pauses execution.
SIGCONT resumes execution.
Neither can be caught or ignored.
EOF
}

validate_step_5() {
    # Check cleanup
    if pgrep -u $(whoami) sleep >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: Sleep process still running"
        echo "  Remember to clean up: pkill sleep"
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Start process:
  sleep 500 &

Get PID:
  PID=$(pgrep sleep)

Stop the process:
  kill -STOP $PID
  # Or: kill -19 $PID

Check state:
  ps -p $PID -o state=
  # Shows: T (stopped)

Full details:
  ps -p $PID -o pid,state,cmd

Resume the process:
  kill -CONT $PID
  # Or: kill -18 $PID

Check state again:
  ps -p $PID -o state=
  # Shows: S (sleeping)

Clean up:
  kill $PID

Understanding STOP/CONT:
  SIGSTOP (19):
  - Pauses process
  - Cannot be caught
  - Process frozen in place
  
  SIGCONT (18):
  - Resumes process
  - Continues from where stopped
  - Process thinks nothing happened
  
  Use cases:
  - Debugging
  - Temporary pause
  - Resource management
  - Job control (Ctrl+Z, fg, bg)

Process states:
  R - Running
  S - Sleeping (interruptible)
  T - Stopped
  Z - Zombie
  D - Uninterruptible sleep

Job control:
  Ctrl+Z sends SIGTSTP (like SIGSTOP)
  bg sends SIGCONT and backgrounds
  fg sends SIGCONT and foregrounds

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=3
    
    echo "Checking your signal management skills..."
    echo ""
    
    # CHECK 1: No test processes running
    print_color "$CYAN" "[1/$total] Checking cleanup..."
    local test_count=$(pgrep -u $(whoami) -c "signal-test|sleep" 2>/dev/null || echo "0")
    
    if [ "$test_count" -eq 0 ]; then
        print_color "$GREEN" "  ✓ All test processes terminated"
        ((score++))
    else
        print_color "$YELLOW" "  Note: $test_count test process(es) still running"
        echo "  Clean up: pkill sleep; pkill -f signal-test"
        ((score++))
    fi
    echo ""
    
    # CHECK 2: Understanding demonstrated
    print_color "$CYAN" "[2/$total] Checking signal knowledge..."
    if [ $score -ge 1 ]; then
        print_color "$GREEN" "  ✓ Signal usage demonstrated"
        ((score++))
    fi
    echo ""
    
    # CHECK 3: Skills practiced
    print_color "$CYAN" "[3/$total] Checking process control skills..."
    if [ $score -ge 2 ]; then
        print_color "$GREEN" "  ✓ Process management skills practiced"
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
        echo "  • SIGTERM for graceful shutdown"
        echo "  • SIGKILL for force termination"
        echo "  • SIGHUP for config reload"
        echo "  • pkill for mass termination"
        echo "  • SIGSTOP/SIGCONT for pause/resume"
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

STEP 1: SIGTERM
─────────────────────────────────────────────────────────────────
/tmp/signal-lab/signal-test.sh &
kill $(pgrep -f signal-test)


STEP 2: SIGKILL
─────────────────────────────────────────────────────────────────
sleep 300 &
kill -9 $(pgrep sleep)


STEP 3: SIGHUP
─────────────────────────────────────────────────────────────────
/tmp/signal-lab/signal-test.sh &
kill -HUP $(pgrep -f signal-test)
kill $(pgrep -f signal-test)


STEP 4: pkill
─────────────────────────────────────────────────────────────────
sleep 100 & sleep 200 & sleep 300 &
pkill sleep


STEP 5: STOP/CONT
─────────────────────────────────────────────────────────────────
sleep 500 &
PID=$(pgrep sleep)
kill -STOP $PID
ps -p $PID -o state=
kill -CONT $PID
ps -p $PID -o state=
kill $PID


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Essential signals:
  SIGTERM (15) - Graceful shutdown
  SIGKILL (9) - Force kill
  SIGHUP (1) - Reload config
  SIGSTOP (19) - Pause
  SIGCONT (18) - Resume

Kill sequence:
  1. kill PID (SIGTERM)
  2. Wait 5-10 seconds
  3. kill -9 PID (SIGKILL if needed)

Process control:
  pkill NAME - Kill by name
  killall NAME - Kill all instances
  kill -STOP PID - Pause
  kill -CONT PID - Resume


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical commands:
1. kill PID - Graceful termination
2. kill -9 PID - Force termination
3. kill -HUP PID - Reload config
4. pkill NAME - Kill by name
5. ps -p PID -o state - Check state

Remember:
  Always SIGTERM first
  SIGKILL is last resort
  Verify with pgrep/ps
  SIGHUP reloads configs

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Kill test processes
    pkill -u $(whoami) -f "signal-test" 2>/dev/null || true
    pkill -u $(whoami) sleep 2>/dev/null || true
    
    # Remove test files
    rm -rf /tmp/signal-lab 2>/dev/null || true
    
    echo "  ✓ All test processes terminated"
    echo "  ✓ Test files removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
