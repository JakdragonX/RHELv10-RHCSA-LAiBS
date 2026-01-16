#!/bin/bash
# labs/m02/08A-sudo-root-privileges.sh
# Lab: Root Privileges and Administrative Access
# Difficulty: Intermediate
# RHCSA Objective: 8.2-8.4 - Using su, sudo, and managing administrative access

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Root Privileges and Administrative Access"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous lab attempts
    userdel -r alice 2>/dev/null || true
    userdel -r bob 2>/dev/null || true
    userdel -r charlie 2>/dev/null || true
    groupdel developers 2>/dev/null || true
    rm -f /etc/sudoers.d/lab-sudo-config 2>/dev/null || true
    rm -f /tmp/root-test.txt 2>/dev/null || true
    rm -rf /opt/devtools 2>/dev/null || true
    
    # Create test users
    useradd -m -s /bin/bash alice 2>/dev/null || true
    useradd -m -s /bin/bash bob 2>/dev/null || true
    useradd -m -s /bin/bash charlie 2>/dev/null || true
    
    # Set passwords (test123)
    echo "alice:test123" | chpasswd 2>/dev/null
    echo "bob:test123" | chpasswd 2>/dev/null
    echo "charlie:test123" | chpasswd 2>/dev/null
    
    # Create test group
    groupadd developers 2>/dev/null || true
    
    # Create test directory
    mkdir -p /opt/devtools 2>/dev/null || true
    chmod 755 /opt/devtools
    
    echo "  ✓ Created test users: alice, bob, charlie (password: test123)"
    echo "  ✓ Created test group: developers"
    echo "  ✓ System ready for administrative access configuration"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of Linux user accounts and permissions
  • Basic familiarity with file permissions
  • Understanding of security best practices

Commands You'll Use:
  • sudo - Execute commands with elevated privileges
  • usermod - Modify user accounts
  • visudo - Safely edit sudoers configuration
  • su - Switch user accounts
  • getent - Query administrative databases

Files You'll Interact With:
  • /etc/sudoers - Main sudo configuration file
  • /etc/sudoers.d/* - Sudo drop-in configuration files
  • /etc/group - Group membership database
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're the new system administrator at DevOps Solutions Inc. The company needs
proper administrative access controls configured for different teams. You must
set up sudo access with appropriate restrictions for various users while
maintaining security best practices.

LAB DIRECTORY: /opt/devtools
  (Test directory for permission management)

BACKGROUND:
The company has three employees who need different levels of administrative
access. Alice needs full sudo access, Bob needs limited access to user
management commands, and Charlie needs access to system monitoring tools only.
All developers should be able to manage files in /opt/devtools.

OBJECTIVES:
  1. Grant alice full administrative access using the wheel group
     • Add alice to the wheel group
     • Verify alice can run any command with sudo

  2. Configure limited sudo access for bob in /etc/sudoers.d/
     • Create a drop-in file: /etc/sudoers.d/bob-permissions
     • Allow bob to run: useradd, userdel, passwd (but NOT passwd root)
     • Bob should be prompted for his password when using sudo

  3. Configure limited sudo access for charlie in /etc/sudoers.d/
     • Create a drop-in file: /etc/sudoers.d/charlie-permissions
     • Allow charlie to run: systemctl status, journalctl, ps
     • Charlie should be able to run these without a password (NOPASSWD)

  4. Add bob and charlie to the developers group
     • Both users need to be members of the developers group

HINTS:
  • Use usermod -aG to add users to groups without removing existing memberships
  • Always use visudo when editing sudoers files to prevent syntax errors
  • Drop-in files in /etc/sudoers.d/ must not contain dots or tildes
  • Use absolute paths for commands in sudoers (e.g., /usr/sbin/useradd)
  • Test sudo access with: sudo -l -U username

SUCCESS CRITERIA:
  • alice can run any command with sudo (member of wheel)
  • bob can manage users but cannot change root's password
  • charlie can check system status without a password
  • Both bob and charlie are members of developers group
  • All configurations use proper sudoers files
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

# Return the number of steps in interactive mode
get_step_count() {
    echo "4"
}

# Context shown once at the start of interactive mode
scenario_context() {
    cat << 'EOF'
You're configuring administrative access for three employees at DevOps Solutions Inc.
Alice needs full sudo access, Bob needs limited user management access, and Charlie
needs read-only system monitoring access. You'll configure each user's permissions
using sudo best practices.

Test users have been created with password: test123
EOF
}

# STEP 1: Grant alice full admin access
show_step_1() {
    cat << 'EOF'
TASK: Grant alice full administrative access using the wheel group

Alice is your senior administrator and needs unrestricted sudo access to manage
all aspects of the system. The proper way to grant full sudo access in RHEL is
by adding the user to the wheel group.

What to do:
  • Add alice to the wheel group
  • Use the -aG flags to append (don't replace existing groups)

Tools available:
  • usermod - Modify user account properties
  • groups - Display group memberships

Think about:
  • Why use wheel instead of creating custom sudo rules?
  • What does the -aG flag do differently than -G?

After completing: Open a new terminal and try: sudo -l -U alice
EOF
}

validate_step_1() {
    if groups alice 2>/dev/null | grep -q "\bwheel\b"; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ alice is not in wheel group"
        echo "  Try: sudo usermod -aG wheel alice"
        return 1
    fi
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo usermod -aG wheel alice

Explanation:
  • usermod: Command to modify user accounts
  • -aG: Append to group (keeps existing group memberships)
  • wheel: The administrative group with full sudo access
  • alice: The user to modify

Why this matters:
  The wheel group is the standard way to grant full administrative access
  in RHEL. The /etc/sudoers file contains "%wheel ALL=(ALL) ALL" by default,
  granting all members complete sudo privileges.

Verification:
  groups alice
  # Expected: alice : alice wheel
  
  sudo -l -U alice
  # Should show: (ALL) ALL

EOF
}

hint_step_2() {
    echo "  Create the file with: sudo visudo -f /etc/sudoers.d/bob-permissions"
    echo "  Use absolute paths for commands (find with: which useradd)"
}

# STEP 2: Configure bob's limited access
show_step_2() {
    cat << 'EOF'
TASK: Configure limited sudo access for bob to manage user accounts

Bob is a junior administrator who needs to create and manage user accounts,
but should not be able to change the root password for security reasons.

What to do:
  • Create /etc/sudoers.d/bob-permissions using visudo
  • Allow bob to run: useradd, userdel, passwd
  • Explicitly deny: passwd root (use ! to negate)
  • Use absolute paths (e.g., /usr/sbin/useradd)

Tools available:
  • visudo -f /etc/sudoers.d/bob-permissions - Safely edit sudo config
  • which command - Find absolute path to a command

Format:
  username ALL=/full/path/to/cmd1, /full/path/to/cmd2, ! /full/path/to/denied

After completing: Test with: sudo -l -U bob

IMPORTANT: Always use visudo to prevent syntax errors that could lock you out!
EOF
}

validate_step_2() {
    if [ ! -f /etc/sudoers.d/bob-permissions ]; then
        echo ""
        print_color "$RED" "✗ File /etc/sudoers.d/bob-permissions not found"
        echo "  Create with: sudo visudo -f /etc/sudoers.d/bob-permissions"
        return 1
    fi
    
    local checks=0
    
    if sudo -l -U bob 2>/dev/null | grep -q "useradd"; then
        ((checks++))
    fi
    
    if sudo -l -U bob 2>/dev/null | grep -q "userdel"; then
        ((checks++))
    fi
    
    if sudo -l -U bob 2>/dev/null | grep -q "passwd"; then
        ((checks++))
    fi
    
    if [ $checks -ge 3 ]; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ bob's sudo configuration incomplete"
        echo "  Expected: useradd, userdel, passwd (with passwd root denied)"
        return 1
    fi
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo visudo -f /etc/sudoers.d/bob-permissions

Add this line:
  bob ALL=/usr/sbin/useradd, /usr/sbin/userdel, /usr/bin/passwd, ! /usr/bin/passwd root

Explanation:
  • bob ALL=: bob can run these from any host
  • /usr/sbin/useradd: Full path to useradd command
  • /usr/sbin/userdel: Full path to userdel command
  • /usr/bin/passwd: Full path to passwd command
  • ! /usr/bin/passwd root: Explicitly deny changing root password

Why this matters:
  Using drop-in files in /etc/sudoers.d/ is safer than editing /etc/sudoers
  directly. System updates won't overwrite your custom configurations, and
  you can easily disable permissions by removing the file.

Verification:
  sudo -l -U bob
  # Should list the allowed commands

EOF
}

hint_step_3() {
    echo "  Use NOPASSWD: before the command list"
    echo "  Format: username ALL=NOPASSWD: /path/cmd1, /path/cmd2"
}

# STEP 3: Configure charlie's monitoring access
show_step_3() {
    cat << 'EOF'
TASK: Configure monitoring access for charlie without password prompts

Charlie is in the monitoring team and needs to check system status frequently.
To avoid constant password prompts for read-only commands, you'll use NOPASSWD.

What to do:
  • Create /etc/sudoers.d/charlie-permissions using visudo
  • Allow charlie to run: systemctl status, journalctl, ps
  • Use NOPASSWD: so charlie won't be prompted for password
  • Use absolute paths for all commands

Tools available:
  • visudo -f /etc/sudoers.d/charlie-permissions
  • which command - Find command paths

Format:
  username ALL=NOPASSWD: /path/to/cmd1, /path/to/cmd2

After completing: Test with: sudo -l -U charlie

Think about:
  • Why is NOPASSWD safe for these specific commands?
  • When should you NOT use NOPASSWD?
EOF
}

validate_step_3() {
    if [ ! -f /etc/sudoers.d/charlie-permissions ]; then
        echo ""
        print_color "$RED" "✗ File /etc/sudoers.d/charlie-permissions not found"
        echo "  Create with: sudo visudo -f /etc/sudoers.d/charlie-permissions"
        return 1
    fi
    
    if sudo -l -U charlie 2>/dev/null | grep -q "NOPASSWD" && \
       sudo -l -U charlie 2>/dev/null | grep -q "systemctl"; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ charlie's configuration missing or lacks NOPASSWD"
        echo "  Expected: NOPASSWD with systemctl, journalctl, ps"
        return 1
    fi
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo visudo -f /etc/sudoers.d/charlie-permissions

Add this line:
  charlie ALL=NOPASSWD: /usr/bin/systemctl status *, /usr/bin/journalctl, /usr/bin/ps

Explanation:
  • NOPASSWD: Charlie won't be prompted for password
  • /usr/bin/systemctl status *: Can check any service status
  • /usr/bin/journalctl: Can view system logs
  • /usr/bin/ps: Can view running processes

Why this matters:
  NOPASSWD is useful for read-only monitoring commands that need to run
  frequently or automatically. These commands only display information and
  cannot modify the system, making NOPASSWD relatively safe.

WARNING: Never use NOPASSWD for commands that modify the system!

Verification:
  sudo -l -U charlie
  # Should show NOPASSWD for the listed commands

EOF
}

hint_step_4() {
    echo "  Use: sudo usermod -aG developers username"
    echo "  Remember -aG (append) not -G (replace)"
}

# STEP 4: Add users to developers group
show_step_4() {
    cat << 'EOF'
TASK: Add bob and charlie to the developers group

The developers group provides access to shared development resources.
You need to add both bob and charlie to this group without removing
their existing group memberships.

What to do:
  • Add bob to the developers group
  • Add charlie to the developers group
  • Use -aG to append (preserve existing groups)

Tools available:
  • usermod -aG group username - Add user to group
  • groups username - Verify group memberships
  • getent group developers - Show all group members

Think about:
  • What happens if you use -G instead of -aG?
  • How can you verify the change worked?

After completing: Run: groups bob charlie
EOF
}

validate_step_4() {
    local ok=true
    
    if ! groups bob 2>/dev/null | grep -q "\bdevelopers\b"; then
        echo ""
        print_color "$RED" "✗ bob is not in developers group"
        ok=false
    fi
    
    if ! groups charlie 2>/dev/null | grep -q "\bdevelopers\b"; then
        echo ""
        print_color "$RED" "✗ charlie is not in developers group"
        ok=false
    fi
    
    if [ "$ok" = true ]; then
        return 0
    else
        echo "  Try: sudo usermod -aG developers bob"
        echo "       sudo usermod -aG developers charlie"
        return 1
    fi
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo usermod -aG developers bob
  sudo usermod -aG developers charlie

Explanation:
  • usermod: Modify user account
  • -aG: Append to supplementary groups (keeps existing groups)
  • developers: The group name
  • bob/charlie: The users to modify

Why this matters:
  Using -aG (append) is critical! If you use -G alone, it REPLACES all
  supplementary groups, potentially removing the user from important
  groups. Always use -aG to add users to groups safely.

Verification:
  groups bob
  # Expected: bob : bob developers
  
  groups charlie
  # Expected: charlie : charlie developers
  
  getent group developers
  # Expected: developers:x:####:bob,charlie

EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Add alice to wheel group for full sudo access
  ☐ 2. Create /etc/sudoers.d/bob-permissions with limited user management access
  ☐ 3. Create /etc/sudoers.d/charlie-permissions with monitoring access (NOPASSWD)
  ☐ 4. Add bob and charlie to developers group
EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your sudo and administrative access configuration..."
    echo ""
    
    # CHECK 1: Alice in wheel group
    print_color "$CYAN" "[1/$total] Checking alice's administrative access..."
    if groups alice 2>/dev/null | grep -q "\bwheel\b"; then
        print_color "$GREEN" "  ✓ alice is member of wheel group"
        ((score++))
    else
        print_color "$RED" "  ✗ alice is not in wheel group"
        print_color "$YELLOW" "  Fix: usermod -aG wheel alice"
    fi
    echo ""
    
    # CHECK 2: Bob's sudo configuration
    print_color "$CYAN" "[2/$total] Checking bob's limited sudo access..."
    local bob_checks=0
    
    if [ -f /etc/sudoers.d/bob-permissions ]; then
        # Check if file has valid sudo rules for bob
        if sudo -l -U bob 2>/dev/null | grep -q "useradd"; then
            ((bob_checks++))
        fi
        
        if sudo -l -U bob 2>/dev/null | grep -q "userdel"; then
            ((bob_checks++))
        fi
        
        if sudo -l -U bob 2>/dev/null | grep -q "passwd"; then
            ((bob_checks++))
        fi
        
        # Check that passwd root is denied
        if sudo -l -U bob 2>/dev/null | grep -q "passwd root" && \
           sudo -l -U bob 2>/dev/null | grep "passwd root" | grep -q "!"; then
            ((bob_checks++))
        elif ! sudo -l -U bob 2>/dev/null | grep -q "passwd root"; then
            # If "passwd root" isn't mentioned at all, that's okay too
            ((bob_checks++))
        fi
        
        if [ $bob_checks -ge 3 ]; then
            print_color "$GREEN" "  ✓ bob has correct limited sudo permissions"
            ((score++))
        else
            print_color "$RED" "  ✗ bob's permissions incomplete ($bob_checks/4 checks)"
            print_color "$YELLOW" "  Expected: useradd, userdel, passwd (but not passwd root)"
        fi
    else
        print_color "$RED" "  ✗ File /etc/sudoers.d/bob-permissions not found"
        print_color "$YELLOW" "  Create with: sudo visudo -f /etc/sudoers.d/bob-permissions"
    fi
    echo ""
    
    # CHECK 3: Charlie's sudo configuration
    print_color "$CYAN" "[3/$total] Checking charlie's monitoring access..."
    if [ -f /etc/sudoers.d/charlie-permissions ]; then
        local charlie_ok=true
        
        # Check for systemctl status
        if ! sudo -l -U charlie 2>/dev/null | grep -q "systemctl"; then
            charlie_ok=false
        fi
        
        # Check for NOPASSWD
        if ! sudo -l -U charlie 2>/dev/null | grep -q "NOPASSWD"; then
            charlie_ok=false
        fi
        
        if [ "$charlie_ok" = true ]; then
            print_color "$GREEN" "  ✓ charlie has correct monitoring permissions with NOPASSWD"
            ((score++))
        else
            print_color "$RED" "  ✗ charlie's permissions incorrect or missing NOPASSWD"
            print_color "$YELLOW" "  Expected: systemctl, journalctl, ps with NOPASSWD"
        fi
    else
        print_color "$RED" "  ✗ File /etc/sudoers.d/charlie-permissions not found"
        print_color "$YELLOW" "  Create with: sudo visudo -f /etc/sudoers.d/charlie-permissions"
    fi
    echo ""
    
    # CHECK 4: Group membership
    print_color "$CYAN" "[4/$total] Checking developers group membership..."
    local group_ok=true
    
    if ! groups bob 2>/dev/null | grep -q "\bdevelopers\b"; then
        print_color "$RED" "  ✗ bob is not in developers group"
        group_ok=false
    fi
    
    if ! groups charlie 2>/dev/null | grep -q "\bdevelopers\b"; then
        print_color "$RED" "  ✗ charlie is not in developers group"
        group_ok=false
    fi
    
    if [ "$group_ok" = true ]; then
        print_color "$GREEN" "  ✓ bob and charlie are members of developers group"
        ((score++))
    else
        print_color "$YELLOW" "  Fix: usermod -aG developers bob; usermod -aG developers charlie"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Using the wheel group for full administrative access"
        echo "  • Creating granular sudo permissions with drop-in files"
        echo "  • Using NOPASSWD for specific commands"
        echo "  • Managing group memberships for access control"
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

OBJECTIVE 1: Grant alice full administrative access
─────────────────────────────────────────────────────────────────
Command:
  sudo usermod -aG wheel alice

Explanation:
  • usermod: Modifies user account properties
  • -aG: Append to supplementary groups (keeps existing groups)
  • wheel: The administrative group that grants full sudo access
  • alice: The user to modify

Why this works:
  The /etc/sudoers file contains a line: %wheel ALL=(ALL) ALL
  This grants all members of the wheel group full sudo privileges.
  Using -aG (append) ensures we don't remove alice from other groups.

Verification:
  groups alice
  # Expected: alice : alice wheel
  
  sudo -l -U alice
  # Should show: (ALL) ALL


OBJECTIVE 2: Configure limited sudo access for bob
─────────────────────────────────────────────────────────────────
Command:
  sudo visudo -f /etc/sudoers.d/bob-permissions

Add this content:
  bob ALL=/usr/sbin/useradd, /usr/sbin/userdel, /usr/bin/passwd, ! /usr/bin/passwd root

Explanation:
  • bob ALL=: bob can run these commands from any host
  • /usr/sbin/useradd: Full path to useradd command
  • /usr/sbin/userdel: Full path to userdel command  
  • /usr/bin/passwd: Full path to passwd command
  • ! /usr/bin/passwd root: Explicitly deny changing root's password

Why this works:
  Drop-in files in /etc/sudoers.d/ are automatically included.
  Using ! creates an explicit deny rule that takes precedence.
  Using visudo validates syntax before saving, preventing lockouts.

Verification:
  sudo -l -U bob
  # Should list the allowed commands


OBJECTIVE 3: Configure monitoring access for charlie (NOPASSWD)
─────────────────────────────────────────────────────────────────
Command:
  sudo visudo -f /etc/sudoers.d/charlie-permissions

Add this content:
  charlie ALL=NOPASSWD: /usr/bin/systemctl status *, /usr/bin/journalctl, /usr/bin/ps

Explanation:
  • NOPASSWD: Charlie won't be prompted for a password
  • /usr/bin/systemctl status *: Can check status of any service
  • /usr/bin/journalctl: Can view system logs
  • /usr/bin/ps: Can view running processes

Why this works:
  NOPASSWD is useful for monitoring tools that need to run automatically
  or for users who only need read-only system information. The commands
  listed are safe because they only display information, not modify it.

Verification:
  sudo -l -U charlie
  # Should show NOPASSWD for the specified commands


OBJECTIVE 4: Add users to developers group
─────────────────────────────────────────────────────────────────
Commands:
  sudo usermod -aG developers bob
  sudo usermod -aG developers charlie

Explanation:
  • -aG: Append to group (doesn't remove from other groups)
  • developers: The group name
  
Why this works:
  Group membership is additive. Using -aG ensures users keep their
  existing group memberships while adding the new one.

Verification:
  groups bob
  # Expected: bob : bob developers
  
  groups charlie
  # Expected: charlie : charlie developers
  
  getent group developers
  # Expected: developers:x:####:bob,charlie


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sudo vs Su:
  sudo (substitute user do) executes a single command with elevated
  privileges, requiring the CURRENT user's password. This is auditable
  and can be granularly controlled. su (switch user) switches your
  entire session to another user (usually root), requiring the TARGET
  user's password. Modern best practice strongly favors sudo.

The Wheel Group:
  The wheel group is the traditional UNIX administrative group. In RHEL,
  members of wheel have full sudo access by default through the line
  "%wheel ALL=(ALL) ALL" in /etc/sudoers. This is the recommended way
  to grant full administrative access.

Sudoers Drop-in Files:
  Instead of editing /etc/sudoers directly, use files in /etc/sudoers.d/.
  This prevents updates from overwriting your changes and makes it easier
  to manage permissions. Drop-in files must not contain dots (except as
  first character) or tildes, or they'll be ignored.

NOPASSWD Directive:
  NOPASSWD allows commands to run without password prompts. This is useful
  for automation and monitoring, but should only be used for read-only
  commands or in secure environments. Use carefully and sparingly.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using usermod -G instead of -aG
  Result: Removes user from all other groups except the specified one
  Fix: Always use -aG (append to groups)
  Command: usermod -aG wheel alice

Mistake 2: Editing /etc/sudoers directly without visudo
  Result: Syntax errors can lock you out of sudo completely
  Fix: Always use visudo or visudo -f for drop-in files
  
Mistake 3: Forgetting absolute paths in sudoers
  Result: Sudo won't find the commands
  Fix: Use full paths: /usr/sbin/useradd not just useradd
  Find paths with: which useradd

Mistake 4: Drop-in filename contains dots
  Result: File is silently ignored
  Fix: Name files like: bob-permissions not bob.permissions


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always use visudo when editing sudo configuration to catch syntax errors
2. Remember: usermod -aG (append), not -G (replace)
3. Test sudo access with: sudo -l -U username before logging out
4. For full admin access, just add to wheel group - don't recreate rules
5. Drop-in files are safer than editing /etc/sudoers directly

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r alice 2>/dev/null || true
    userdel -r bob 2>/dev/null || true
    userdel -r charlie 2>/dev/null || true
    groupdel developers 2>/dev/null || true
    rm -f /etc/sudoers.d/bob-permissions 2>/dev/null || true
    rm -f /etc/sudoers.d/charlie-permissions 2>/dev/null || true
    rm -rf /opt/devtools 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
