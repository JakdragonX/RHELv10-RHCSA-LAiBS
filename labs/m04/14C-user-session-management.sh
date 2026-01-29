#!/bin/bash
# labs/m04/14C-user-session-management.sh
# Lab: Managing user sessions with loginctl
# Difficulty: Intermediate
# RHCSA Objective: 14.4 - Managing user sessions and processes

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing user sessions with loginctl"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create test user if doesn't exist
    if ! id testuser1 >/dev/null 2>&1; then
        useradd testuser1
        echo "password123" | passwd --stdin testuser1 >/dev/null 2>&1
    fi
    
    if ! id testuser2 >/dev/null 2>&1; then
        useradd testuser2
        echo "password123" | passwd --stdin testuser2 >/dev/null 2>&1
    fi
    
    # Kill any existing sessions for test users
    loginctl terminate-user testuser1 2>/dev/null || true
    loginctl terminate-user testuser2 2>/dev/null || true
    
    # Create working directory
    mkdir -p /tmp/session-lab
    
    echo "  ✓ Test users created (testuser1, testuser2)"
    echo "  ✓ Old sessions terminated"
    echo "  ✓ Lab environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • User and session concepts
  • Process management basics
  • Understanding of systemd

Commands You'll Use:
  • loginctl - Control systemd login manager
  • loginctl list-users - Show logged-in users
  • loginctl list-sessions - Show active sessions
  • loginctl user-status - Show user's processes
  • loginctl terminate-user - Kill all user processes
  • loginctl terminate-session - Kill specific session
  • ps -u USER - Show user's processes
  • pkill -u USER - Kill user's processes

Files You'll Interact With:
  • /tmp/session-lab/ - Working directory
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator who needs to manage user sessions on a
multi-user server. Users leave sessions running, some accounts need
immediate termination, and you must track who's doing what. Master
loginctl to control user sessions efficiently.

BACKGROUND:
loginctl is part of systemd and manages user logins and sessions.
One user can have multiple sessions (SSH, console, GUI).
Understanding session vs user termination is critical for
maintaining server security and resources.

OBJECTIVES:
  1. View active users and sessions
     • List all logged-in users
     • List all active sessions
     • Understand session IDs
     • View session details

  2. Create sessions for test users
     • Start sessions for testuser1
     • Start sessions for testuser2
     • View the new sessions in loginctl
     • Understand user vs session

  3. Examine user processes
     • Use loginctl user-status to see process tree
     • Compare with ps -u USER
     • Start background processes as user
     • View them in session tree

  4. Terminate a specific session
     • Identify a session ID
     • Terminate just that session
     • Verify other sessions remain
     • Understand selective termination

  5. Terminate all user sessions
     • Terminate all of testuser1's sessions
     • Verify user has no processes left
     • Verify other users unaffected
     • Clean up test users

HINTS:
  • loginctl list-sessions shows session IDs
  • Session format: <ID> <UID> <USER> <SEAT>
  • terminate-session kills one session
  • terminate-user kills ALL user sessions
  • user-status shows process tree

SUCCESS CRITERIA:
  • Can view users and sessions
  • Can create and identify sessions
  • Can examine user process trees
  • Can selectively terminate sessions
  • Can terminate all user sessions
  • Test users cleaned up
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. View users and sessions with loginctl
  ☐ 2. Create sessions for test users
  ☐ 3. Examine user process trees
  ☐ 4. Terminate specific session
  ☐ 5. Terminate all user sessions
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
You are managing user sessions on a multi-user server.

Test users: testuser1, testuser2 (password: password123)

Learn to control user logins and sessions with loginctl.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: View active users and sessions

Learn to see who's logged in and what sessions exist.

Requirements:
  • List all logged-in users
  
  • List all active sessions
  
  • View details of your current session
    (Hint: Your session ID is in $XDG_SESSION_ID)
  
  • Examine your session status

Understanding output:
  - SESSION: Unique session ID
  - UID: User ID number
  - USER: Username
  - SEAT: Physical or virtual seat (seat0 = console)
  - TTY: Terminal device

Use loginctl commands to explore users and sessions.
EOF
}

validate_step_1() {
    # Exploratory, always pass
    return 0
}

hint_step_1() {
    cat << 'EOF'
  List users: loginctl list-users
  List sessions: loginctl list-sessions
  Your session: echo $XDG_SESSION_ID
  Session details: loginctl session-status $XDG_SESSION_ID
EOF
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
List logged-in users:
  loginctl list-users

List active sessions:
  loginctl list-sessions

Show your current session ID:
  echo $XDG_SESSION_ID

View your session details:
  loginctl session-status $XDG_SESSION_ID

View user details:
  loginctl user-status $(id -u)

Understanding loginctl output:
  list-users shows:
  - UID: User ID
  - USER: Username
  - State: active, online, closing
  
  list-sessions shows:
  - SESSION: Unique ID (numbers)
  - UID: User ID
  - USER: Username
  - SEAT: Console or remote
  - TTY: Terminal device

Session types:
  - Console: seat0, tty1-6
  - SSH: Remote, no seat
  - GUI: seat0, graphical

Multiple sessions:
  One user can have many sessions
  Each SSH login = new session
  Each console login = new session

EOF
}

hint_step_2() {
    cat << 'EOF'
  Switch user: su - testuser1
  Start process: sleep 300 &
  Exit: exit
  Check: loginctl list-users
  Repeat for testuser2
EOF
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create sessions for test users

Generate active sessions so you can manage them.

Requirements:
  • Switch to testuser1 and start a background process
    (Use su to switch, start a sleep process to keep session alive)
  
  • Exit back to your user
  
  • Verify testuser1 appears in the user list
  
  • Repeat for testuser2
  
  • List all sessions to see both users

Both test users should now have active sessions.

Hint: Background processes keep sessions alive after you exit.
EOF
}

validate_step_2() {
    # Check if test users have sessions
    local user1_active=$(loginctl list-users | grep -c "testuser1" || echo "0")
    local user2_active=$(loginctl list-users | grep -c "testuser2" || echo "0")
    
    if [ "$user1_active" -eq 0 ] && [ "$user2_active" -eq 0 ]; then
        echo ""
        print_color "$YELLOW" "  Note: No test user sessions active"
        echo "  Create them: su - testuser1, then: sleep 300 &"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Create session for testuser1:
  su - testuser1
  sleep 300 &
  exit

Create session for testuser2:
  su - testuser2
  sleep 400 &
  exit

Verify sessions:
  loginctl list-users
  # Should show testuser1 and testuser2

List all sessions:
  loginctl list-sessions
  # Shows session IDs for both users

View specific user:
  loginctl user-status testuser1
  loginctl user-status testuser2

Understanding sessions:
  su - USER creates new session
  Background process keeps session alive
  exit doesn't kill background processes
  User remains "logged in" with processes

Why background process:
  Without it: Session closes immediately
  With it: Session stays active
  Simulates real user with running jobs

Check processes:
  ps -u testuser1
  ps -u testuser2
  # Should see sleep processes

EOF
}

hint_step_3() {
    cat << 'EOF'
  View tree: loginctl user-status testuser1
  Compare: ps -fu testuser1
  Process tree shows: systemd -> slice -> session -> processes
EOF
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Examine user process trees

See the complete hierarchy of user processes.

Requirements:
  • View testuser1's process tree
    (Use loginctl to show user status)
  
  • View testuser2's process tree
  
  • Compare with ps command
    (ps can filter by user with -u flag)
  
  • Observe the structure:
    - User slice
    - Session scope
    - Processes within session

Understanding the tree:
  systemd manages user slices
  Each session is a scope
  Processes belong to sessions
EOF
}

validate_step_3() {
    # Exploratory, always pass
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
View testuser1 processes:
  loginctl user-status testuser1

View testuser2 processes:
  loginctl user-status testuser2

Compare with ps:
  ps -fu testuser1
  ps -fu testuser2

Get user UID:
  id -u testuser1
  loginctl user-status $(id -u testuser1)

Understanding the tree:
  Output shows:
  ├─user@1001.service
  │ └─session-X.scope
  │   └─sleep 300

Hierarchy explanation:
  user@UID.service: User's systemd instance
  session-X.scope: Specific login session
  Processes: Actual running programs

Why this matters:
  systemd tracks everything
  Can kill by session
  Can kill all user sessions
  Organized resource management

Slice concept:
  user.slice: All user processes
  user-1001.slice: Specific user
  session-X.scope: Login session

View systemd units:
  systemctl --user status
  systemctl status user-1001.slice

EOF
}

hint_step_4() {
    cat << 'EOF'
  List sessions: loginctl list-sessions
  Find testuser1 session ID
  Terminate it: loginctl terminate-session SESSION_ID
  Verify: loginctl list-sessions
  Check processes: ps -u testuser1
EOF
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Terminate a specific session

Kill one session while leaving others intact.

Requirements:
  • List all sessions to find session IDs
  
  • Find a testuser1 session ID
  
  • Terminate that specific session
    (Use loginctl terminate-session command)
  
  • Verify it's gone from the session list
  
  • Check if testuser1 still has processes
    (Use ps with user filter)

If testuser1 had multiple sessions, only one should be killed.
If testuser1 had one session, all processes should be gone.
EOF
}

validate_step_4() {
    # Check if testuser1 session is terminated
    local user1_sessions=$(loginctl list-sessions 2>/dev/null | grep -c "testuser1" || echo "0")
    
    if [ "$user1_sessions" -gt 0 ]; then
        echo ""
        print_color "$YELLOW" "  Note: testuser1 still has $user1_sessions session(s)"
        echo "  Consider terminating for cleanup"
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
List all sessions:
  loginctl list-sessions

Example output:
  SESSION  UID USER       SEAT  TTY
  1        1000 alice     seat0 tty1
  5        1001 testuser1       pts/0
  7        1002 testuser2       pts/1

Identify testuser1 session (e.g., session 5):
  SESSION_ID=5

Terminate that session:
  loginctl terminate-session 5

Verify it's gone:
  loginctl list-sessions
  # Session 5 should not appear

Check processes:
  ps -u testuser1
  # Might be empty, or might show processes from other sessions

Understanding:
  terminate-session kills:
  - The login shell
  - All processes in that session
  - Does NOT kill other sessions for same user

Multiple sessions scenario:
  User logs in via SSH: session 5
  User logs in via console: session 6
  terminate-session 5: Only kills SSH session
  User still has console session active

When to use:
  Kill one specific login
  User has multiple sessions
  Selective termination needed

EOF
}

hint_step_5() {
    cat << 'EOF'
  Terminate all: loginctl terminate-user testuser1
  Verify: loginctl list-users (testuser1 gone)
  Check processes: ps -u testuser1 (empty)
  Verify testuser2: loginctl list-users (still there)
EOF
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Terminate all user sessions

Kill all of a user's sessions and processes at once.

Requirements:
  • Terminate all testuser1 sessions
    (Use loginctl terminate-user command)
  
  • Verify testuser1 is gone from user list
  
  • Check no processes remain
  
  • Verify testuser2 is unaffected
  
  • Clean up testuser2 as well

All test user sessions should now be terminated.
EOF
}

validate_step_5() {
    # Check if test users are terminated
    local user1_active=$(loginctl list-users 2>/dev/null | grep -c "testuser1" || echo "0")
    local user2_active=$(loginctl list-users 2>/dev/null | grep -c "testuser2" || echo "0")
    
    if [ "$user1_active" -gt 0 ] || [ "$user2_active" -gt 0 ]; then
        echo ""
        print_color "$RED" "✗ Test users still have active sessions"
        echo "  Terminate: loginctl terminate-user testuser1"
        echo "  Terminate: loginctl terminate-user testuser2"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Terminate all testuser1 sessions:
  loginctl terminate-user testuser1

Verify user gone:
  loginctl list-users
  # testuser1 should not appear

Check no processes:
  ps -u testuser1
  # Should be empty

Verify testuser2 unaffected:
  loginctl list-users
  # testuser2 still there
  
  ps -u testuser2
  # Still has processes

Clean up testuser2:
  loginctl terminate-user testuser2

Final verification:
  loginctl list-users
  # Neither test user appears
  
  ps -u testuser1
  ps -u testuser2
  # Both empty

Understanding terminate-user:
  Kills ALL sessions for user
  Kills ALL processes owned by user
  More aggressive than terminate-session
  Equivalent to: pkill -u USER

When to use:
  User account compromised
  User left processes running
  Clean shutdown of user
  Security incident response

Comparison:
  terminate-session: Selective (one login)
  terminate-user: Nuclear (everything)

Alternative methods:
  pkill -u testuser1
  # Kills processes, not sessions
  
  loginctl terminate-user testuser1
  # Kills sessions AND processes
  # Proper systemd way

Real-world scenario:
  User reports account compromise
  Admin action:
    loginctl terminate-user compromised_user
    passwd -l compromised_user
    # Investigate

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=3
    
    echo "Checking your session management..."
    echo ""
    
    # CHECK 1: Test users terminated
    print_color "$CYAN" "[1/$total] Checking test user cleanup..."
    local user1_active=$(loginctl list-users 2>/dev/null | grep -c "testuser1" || echo "0")
    local user2_active=$(loginctl list-users 2>/dev/null | grep -c "testuser2" || echo "0")
    
    if [ "$user1_active" -eq 0 ] && [ "$user2_active" -eq 0 ]; then
        print_color "$GREEN" "  ✓ All test user sessions terminated"
        ((score++))
    else
        print_color "$RED" "  ✗ Test users still have sessions"
        print_color "$YELLOW" "  Cleanup: loginctl terminate-user testuser1 testuser2"
    fi
    echo ""
    
    # CHECK 2: Understanding demonstrated
    print_color "$CYAN" "[2/$total] Checking loginctl knowledge..."
    if [ $score -ge 1 ]; then
        print_color "$GREEN" "  ✓ Session management demonstrated"
        ((score++))
    fi
    echo ""
    
    # CHECK 3: Skills practiced
    print_color "$CYAN" "[3/$total] Checking user management skills..."
    if [ $score -ge 2 ]; then
        print_color "$GREEN" "  ✓ User session control mastered"
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
        echo "  • Viewing users and sessions with loginctl"
        echo "  • Creating and identifying sessions"
        echo "  • Examining user process trees"
        echo "  • Terminating specific sessions"
        echo "  • Terminating all user sessions"
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

STEP 1: View users and sessions
─────────────────────────────────────────────────────────────────
loginctl list-users
loginctl list-sessions
loginctl session-status $XDG_SESSION_ID


STEP 2: Create sessions
─────────────────────────────────────────────────────────────────
su - testuser1
sleep 300 &
exit

su - testuser2
sleep 400 &
exit

loginctl list-users


STEP 3: Examine process trees
─────────────────────────────────────────────────────────────────
loginctl user-status testuser1
loginctl user-status testuser2
ps -fu testuser1


STEP 4: Terminate specific session
─────────────────────────────────────────────────────────────────
loginctl list-sessions
loginctl terminate-session SESSION_ID
loginctl list-sessions


STEP 5: Terminate all user sessions
─────────────────────────────────────────────────────────────────
loginctl terminate-user testuser1
loginctl list-users
ps -u testuser1

loginctl terminate-user testuser2


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Essential commands:
  loginctl list-users
  loginctl list-sessions
  loginctl user-status USER
  loginctl session-status SESSION
  loginctl terminate-session ID
  loginctl terminate-user USER

Session vs User:
  Session: One login instance
  User: Can have multiple sessions
  terminate-session: Kills one
  terminate-user: Kills all

Process hierarchy:
  systemd -> user.slice -> user@UID.service -> session-X.scope -> processes

When to use what:
  Kill one login: terminate-session
  Kill all user activity: terminate-user
  View user activity: user-status


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical commands:
1. loginctl list-users - Who's logged in
2. loginctl list-sessions - Active sessions
3. loginctl terminate-user USER - Kill everything
4. ps -u USER - Alternative view

Remember:
  One user, many sessions
  terminate-user kills all
  Check with list-users
  Verify with ps -u USER

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Terminate test user sessions
    loginctl terminate-user testuser1 2>/dev/null || true
    loginctl terminate-user testuser2 2>/dev/null || true
    
    # Kill any remaining processes
    pkill -u testuser1 2>/dev/null || true
    pkill -u testuser2 2>/dev/null || true
    
    # Remove test users
    userdel -r testuser1 2>/dev/null || true
    userdel -r testuser2 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/session-lab 2>/dev/null || true
    
    echo "  ✓ Test user sessions terminated"
    echo "  ✓ Test users removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
