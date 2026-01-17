#!/bin/bash
# labs/m03/09A-creating-managing-users.sh
# Lab: Creating and Managing User Accounts
# Difficulty: Beginner
# RHCSA Objective: 9.1-9.3 - User account creation, modification, and management

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Creating and Managing User Accounts"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous lab attempts
    userdel -r developer1 2>/dev/null || true
    userdel -r sysadmin1 2>/dev/null || true
    userdel -r appuser1 2>/dev/null || true
    userdel -r tempuser 2>/dev/null || true
    
    # Ensure /etc/skel has some default files for testing
    mkdir -p /etc/skel 2>/dev/null || true
    
    echo "  ✓ Cleaned up any previous user accounts"
    echo "  ✓ System ready for user management"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of Linux security principals
  • Basic understanding of file permissions
  • Familiarity with user accounts vs system accounts

Commands You'll Use:
  • useradd - Create new user accounts
  • usermod - Modify existing user accounts
  • userdel - Delete user accounts
  • passwd - Set or change user passwords
  • getent - Query system databases (passwd, shadow, group)
  • id - Display user identity information
  • chage - Manage password aging information

Files You'll Interact With:
  • /etc/passwd - User account information
  • /etc/shadow - Encrypted password information
  • /etc/login.defs - Default settings for user creation
  • /etc/skel/ - Template files for new user home directories
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're the system administrator for a growing IT company. Your manager has asked
you to create several user accounts with specific properties. Some are regular
employees, one is a system application account, and one is a temporary contractor.
You must configure each account appropriately.

BACKGROUND:
Different types of users require different account configurations. Regular employees
need full login access and home directories. Application accounts need restricted
access and shouldn't be able to log in interactively. Temporary accounts need
expiration dates. You'll use useradd, usermod, and related commands to configure these.

OBJECTIVES:
  1. Create a regular user account: developer1
     • Full name (GECOS): "Jane Developer"
     • Create home directory
     • Default shell: /bin/bash
     • Set password to: devpass123
     • Verify account in /etc/passwd and /etc/shadow

  2. Create a system application account: appuser1
     • UID: under 1000 (system account range)
     • No home directory created
     • Shell: /sbin/nologin (prevent interactive login)
     • Use --system flag with useradd

  3. Create a temporary contractor account: tempuser
     • Account expires on: 2025-12-31
     • Set password to: temppass123
     • Password must be changed on first login
     • Verify expiration with: chage -l tempuser

  4. Modify sysadmin1 account (create first, then modify)
     • Create user: sysadmin1
     • Change shell to: /bin/zsh
     • Add comment: "System Administrator"
     • Lock the account (simulate suspended employee)
     • Verify lock status in /etc/shadow (look for !)

  5. Query user information using getent
     • Use getent to display developer1's passwd entry
     • Use getent to verify sysadmin1's shadow entry (if permitted)
     • Use id command to show developer1's UID/GID

HINTS:
  • useradd -c for GECOS/comment field
  • useradd --system creates system accounts
  • useradd -e for expiration date (YYYY-MM-DD format)
  • usermod -L locks account, -U unlocks
  • usermod -s changes shell
  • passwd -e forces password change at next login
  • getent passwd username shows /etc/passwd entry
  • Locked accounts have ! in /etc/shadow

SUCCESS CRITERIA:
  • All accounts exist in /etc/passwd
  • developer1 has home directory and can log in
  • appuser1 is a system account with nologin shell
  • tempuser has expiration date set
  • sysadmin1 is locked (! in /etc/shadow)
  • All accounts verified with getent
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create developer1 with home, bash shell, GECOS, password
  ☐ 2. Create appuser1 as system account with nologin shell
  ☐ 3. Create tempuser with expiration 2025-12-31, force password change
  ☐ 4. Create and modify sysadmin1: change shell, add comment, lock account
  ☐ 5. Verify all accounts with getent and id commands
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
You're creating various types of user accounts for your organization. Each account
type has specific requirements: regular employees, system accounts, temporary
contractors, and accounts that need modification and locking.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Create a regular employee user account

Create a standard user account for a new developer joining the team. This account
needs a home directory, proper shell, and descriptive information.

What to do:
  • Username: developer1
  • Full name (GECOS): "Jane Developer"
  • Create home directory (default)
  • Shell: /bin/bash (default)
  • Set password: devpass123

Tools available:
  • useradd - Create user accounts
  • passwd - Set passwords
  • getent passwd - Verify account creation
  • id - Check user information

Format:
  sudo useradd -c "Jane Developer" developer1
  sudo passwd developer1

Think about:
  • What files are created when you add a user?
  • Where is the password hash stored?
  • What's the difference between /etc/passwd and /etc/shadow?

After completing: Verify with: getent passwd developer1
EOF
}

validate_step_1() {
    # Check if user exists
    if ! getent passwd developer1 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ User developer1 does not exist"
        echo "  Try: sudo useradd -c \"Jane Developer\" developer1"
        return 1
    fi
    
    # Check if home directory exists
    if [ ! -d /home/developer1 ]; then
        echo ""
        print_color "$RED" "✗ Home directory /home/developer1 does not exist"
        return 1
    fi
    
    # Check if password is set (not ! or * in shadow)
    if ! sudo getent shadow developer1 | grep -v "!" | grep -v "*" | grep -q ":"; then
        echo ""
        print_color "$RED" "✗ Password not set for developer1"
        echo "  Try: sudo passwd developer1"
        return 1
    fi
    
    # Check GECOS field
    if ! getent passwd developer1 | grep -q "Jane Developer"; then
        echo ""
        print_color "$RED" "✗ GECOS field not set correctly"
        echo "  Expected: Jane Developer"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo useradd -c "Jane Developer" developer1
  sudo passwd developer1
  # Enter password: devpass123
  # Confirm password: devpass123

Explanation:
  • useradd: Command to create user accounts
  • -c "Jane Developer": Sets GECOS field (full name/comment)
  • developer1: Username
  • passwd: Sets the password

What happens:
  1. Entry added to /etc/passwd with UID, GID, home, shell
  2. Entry added to /etc/shadow with password hash
  3. Home directory created: /home/developer1
  4. Files from /etc/skel copied to home directory
  5. Primary group created: developer1

Verification:
  getent passwd developer1
  # Should show: developer1:x:1001:1001:Jane Developer:/home/developer1:/bin/bash
  
  ls -la /home/developer1
  # Should show home directory contents
  
  sudo getent shadow developer1
  # Should show password hash (starts with $6$ for SHA-512)

EOF
}

hint_step_2() {
    echo "  Use: sudo useradd --system -s /sbin/nologin appuser1"
    echo "  System accounts get UID < 1000"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create a system application account

Application accounts are used by services and daemons, not by people. They should
not be able to log in interactively and typically don't need home directories.

What to do:
  • Username: appuser1
  • Create as system account (UID < 1000)
  • Shell: /sbin/nologin (prevents login)
  • No home directory needed

Tools available:
  • useradd --system - Create system account
  • useradd -s - Specify shell
  • getent passwd - Verify UID range

Format:
  sudo useradd --system -s /sbin/nologin appuser1

Think about:
  • Why use UID < 1000 for system accounts?
  • What happens if someone tries to log in as appuser1?
  • When would you use this type of account?

After completing: Check UID with: getent passwd appuser1
EOF
}

validate_step_2() {
    if ! getent passwd appuser1 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ User appuser1 does not exist"
        echo "  Try: sudo useradd --system -s /sbin/nologin appuser1"
        return 1
    fi
    
    # Check if UID is < 1000 (system account)
    local uid=$(getent passwd appuser1 | cut -d: -f3)
    if [ "$uid" -ge 1000 ]; then
        echo ""
        print_color "$RED" "✗ appuser1 UID is $uid (should be < 1000)"
        echo "  Use --system flag to create system account"
        return 1
    fi
    
    # Check shell
    local shell=$(getent passwd appuser1 | cut -d: -f7)
    if [ "$shell" != "/sbin/nologin" ] && [ "$shell" != "/usr/sbin/nologin" ]; then
        echo ""
        print_color "$RED" "✗ Shell is $shell (expected /sbin/nologin)"
        echo "  Try: sudo usermod -s /sbin/nologin appuser1"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo useradd --system -s /sbin/nologin appuser1

Explanation:
  • --system: Creates system account with UID < 1000
  • -s /sbin/nologin: Sets non-interactive shell
  • appuser1: Username for the application

System Accounts:
  • UID range: typically 1-999
  • Used by services and daemons
  • Should not have login capability
  • Often don't need home directories

What is /sbin/nologin?
  This shell displays a message and exits immediately, preventing
  interactive login. It's used for accounts that only need to own
  files or run specific processes, not for human logins.

Verification:
  getent passwd appuser1
  # Should show UID < 1000 and shell /sbin/nologin
  
  id appuser1
  # Shows UID, GID, and groups

EOF
}

hint_step_3() {
    echo "  Use: sudo useradd -e 2025-12-31 tempuser"
    echo "  Then: sudo passwd -e tempuser (force password change)"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create a temporary contractor account with expiration

Temporary employees and contractors should have accounts that automatically
expire. Additionally, they should be forced to change their password on first login.

What to do:
  • Username: tempuser
  • Account expires: 2025-12-31
  • Password: temppass123
  • Force password change on first login

Tools available:
  • useradd -e - Set expiration date
  • passwd - Set password
  • passwd -e - Force password change at next login
  • chage -l - View password aging information

Format:
  sudo useradd -e 2025-12-31 tempuser
  sudo passwd tempuser
  sudo passwd -e tempuser

Think about:
  • Why expire temporary accounts?
  • What happens when the account expires?
  • Why force password change on first login?

After completing: Verify with: sudo chage -l tempuser
EOF
}

validate_step_3() {
    if ! getent passwd tempuser >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ User tempuser does not exist"
        echo "  Try: sudo useradd -e 2025-12-31 tempuser"
        return 1
    fi
    
    # Check expiration date
    local expire_date=$(sudo chage -l tempuser | grep "Account expires" | awk -F: '{print $2}' | xargs)
    if ! echo "$expire_date" | grep -q "2025"; then
        echo ""
        print_color "$RED" "✗ Expiration date not set or incorrect"
        echo "  Current: $expire_date"
        echo "  Try: sudo usermod -e 2025-12-31 tempuser"
        return 1
    fi
    
    # Check if password must be changed (last change = 0 days)
    local last_change=$(sudo chage -l tempuser | grep "Last password change" | awk -F: '{print $2}' | xargs)
    if ! echo "$last_change" | grep -qi "password must be changed"; then
        echo ""
        print_color "$RED" "✗ Password change not forced"
        echo "  Try: sudo passwd -e tempuser"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo useradd -e 2025-12-31 tempuser
  sudo passwd tempuser
  # Enter: temppass123
  sudo passwd -e tempuser

Explanation:
  • -e 2025-12-31: Sets account expiration date
  • passwd tempuser: Sets initial password
  • passwd -e: Forces password change at next login

Account Expiration:
  After the expiration date:
  • User cannot log in
  • Account is not deleted (can be re-enabled)
  • Useful for contractors, temporary staff, test accounts

Force Password Change:
  passwd -e sets "last password change" to epoch 0, which means:
  • System sees password as expired
  • User must change it on next login
  • Good security practice for new accounts

Verification:
  sudo chage -l tempuser
  # Should show:
  # Account expires: Dec 31, 2025
  # Last password change: password must be changed
  
  getent passwd tempuser
  # Shows basic account info

EOF
}

hint_step_4() {
    echo "  Create: sudo useradd -c \"System Administrator\" -s /bin/zsh sysadmin1"
    echo "  Lock: sudo usermod -L sysadmin1"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Create, modify, and lock a user account

Sometimes you need to create an account and then modify it. You might also need
to lock accounts for suspended employees or security reasons.

What to do:
  • Create user: sysadmin1
  • Set GECOS: "System Administrator"
  • Set shell: /bin/zsh
  • Lock the account

Tools available:
  • useradd - Create account
  • usermod -s - Change shell
  • usermod -c - Change GECOS
  • usermod -L - Lock account
  • getent shadow - View lock status

Format:
  sudo useradd -c "System Administrator" -s /bin/zsh sysadmin1
  sudo usermod -L sysadmin1

Think about:
  • What does locking an account do?
  • Can a locked user still own files?
  • How do you unlock an account?

After completing: Check with: sudo getent shadow sysadmin1 | cut -d: -f2
Look for ! at the start of the password hash
EOF
}

validate_step_4() {
    if ! getent passwd sysadmin1 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ User sysadmin1 does not exist"
        echo "  Try: sudo useradd -c \"System Administrator\" -s /bin/zsh sysadmin1"
        return 1
    fi
    
    # Check shell
    local shell=$(getent passwd sysadmin1 | cut -d: -f7)
    if [ "$shell" != "/bin/zsh" ]; then
        echo ""
        print_color "$RED" "✗ Shell is $shell (expected /bin/zsh)"
        echo "  Try: sudo usermod -s /bin/zsh sysadmin1"
        return 1
    fi
    
    # Check GECOS
    if ! getent passwd sysadmin1 | grep -q "System Administrator"; then
        echo ""
        print_color "$RED" "✗ GECOS field not set correctly"
        return 1
    fi
    
    # Check if account is locked (! in shadow)
    local shadow_pass=$(sudo getent shadow sysadmin1 2>/dev/null | cut -d: -f2)
    if ! echo "$shadow_pass" | grep -q "^!"; then
        echo ""
        print_color "$RED" "✗ Account not locked (no ! in /etc/shadow)"
        echo "  Try: sudo usermod -L sysadmin1"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo useradd -c "System Administrator" -s /bin/zsh sysadmin1
  sudo usermod -L sysadmin1

Alternative (do it all at once):
  sudo useradd -c "System Administrator" -s /bin/zsh sysadmin1
  sudo passwd sysadmin1  # Set password first
  sudo usermod -L sysadmin1  # Then lock

Explanation:
  • -c "System Administrator": Sets GECOS comment
  • -s /bin/zsh: Sets zsh as default shell
  • usermod -L: Locks account by adding ! to password hash

Account Locking:
  When you lock an account with usermod -L:
  • Adds ! prefix to password hash in /etc/shadow
  • User cannot log in with password
  • SSH key authentication may still work (use passwd -l to prevent)
  • Account still owns files and processes
  • Reversible with usermod -U

When to lock accounts:
  • Employee suspended or on leave
  • Security incident investigation
  • Account compromise suspected
  • Before deleting (to test impact)

Verification:
  getent passwd sysadmin1
  # Should show shell: /bin/zsh and GECOS
  
  sudo getent shadow sysadmin1 | cut -d: -f2
  # Should start with !
  
  # To unlock later:
  sudo usermod -U sysadmin1

EOF
}

hint_step_5() {
    echo "  Use: getent passwd developer1"
    echo "  Use: id developer1"
    echo "  Use: sudo getent shadow developer1"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Query user information using getent and id

The getent command is the proper way to query user information because it checks
all configured sources (local files, LDAP, SSSD, etc.), not just /etc/passwd.

What to do:
  • Query developer1's passwd entry with getent
  • Show developer1's UID and groups with id
  • Try to view shadow entry (requires sudo)

Tools available:
  • getent passwd username - Show user account info
  • getent shadow username - Show password aging info
  • id username - Show UID, GID, and groups

Format:
  getent passwd developer1
  id developer1
  sudo getent shadow developer1

Think about:
  • Why use getent instead of cat /etc/passwd?
  • What information does id show that getent doesn't?
  • Why does getent shadow require sudo?

After completing: Compare output from different commands
EOF
}

validate_step_5() {
    # This step is informational, just verify the user exists
    if ! getent passwd developer1 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Cannot query developer1 (user doesn't exist)"
        return 1
    fi
    
    # Check if commands work
    if ! id developer1 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ id command failed for developer1"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  getent passwd developer1
  id developer1
  sudo getent shadow developer1

Sample Output:

1. getent passwd developer1:
   developer1:x:1001:1001:Jane Developer:/home/developer1:/bin/bash
   
   Fields: username:x:UID:GID:GECOS:home:shell

2. id developer1:
   uid=1001(developer1) gid=1001(developer1) groups=1001(developer1)
   
   Shows: UID, primary GID, and all group memberships

3. sudo getent shadow developer1:
   developer1:$6$xyz...:19500:0:99999:7:::
   
   Fields: username:hash:last_change:min:max:warn:inactive:expire

Why use getent?
  • Works with LDAP, SSSD, NIS, not just local files
  • Respects /etc/nsswitch.conf configuration
  • Universal across different authentication sources
  • More reliable than cat /etc/passwd

Comparison:
  cat /etc/passwd         → Only local file
  getent passwd           → All configured sources
  
  cat /etc/shadow         → Requires root, local only
  getent shadow           → Requires root, checks all sources

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your user account configuration..."
    echo ""
    
    # CHECK 1: developer1
    print_color "$CYAN" "[1/$total] Checking developer1 account..."
    if getent passwd developer1 >/dev/null 2>&1 && \
       [ -d /home/developer1 ] && \
       getent passwd developer1 | grep -q "Jane Developer"; then
        print_color "$GREEN" "  ✓ developer1 created with home directory and GECOS"
        ((score++))
    else
        print_color "$RED" "  ✗ developer1 not configured correctly"
        print_color "$YELLOW" "  Fix: sudo useradd -c \"Jane Developer\" developer1; sudo passwd developer1"
    fi
    echo ""
    
    # CHECK 2: appuser1
    print_color "$CYAN" "[2/$total] Checking appuser1 system account..."
    local uid=$(getent passwd appuser1 2>/dev/null | cut -d: -f3)
    local shell=$(getent passwd appuser1 2>/dev/null | cut -d: -f7)
    
    if [ -n "$uid" ] && [ "$uid" -lt 1000 ] && \
       ([ "$shell" = "/sbin/nologin" ] || [ "$shell" = "/usr/sbin/nologin" ]); then
        print_color "$GREEN" "  ✓ appuser1 is system account with nologin shell"
        ((score++))
    else
        print_color "$RED" "  ✗ appuser1 not configured correctly"
        print_color "$YELLOW" "  Fix: sudo useradd --system -s /sbin/nologin appuser1"
    fi
    echo ""
    
    # CHECK 3: tempuser
    print_color "$CYAN" "[3/$total] Checking tempuser expiration..."
    if getent passwd tempuser >/dev/null 2>&1; then
        local expire_check=$(sudo chage -l tempuser 2>/dev/null | grep "Account expires")
        local pass_check=$(sudo chage -l tempuser 2>/dev/null | grep "Last password change")
        
        if echo "$expire_check" | grep -q "2025" && \
           echo "$pass_check" | grep -qi "must be changed"; then
            print_color "$GREEN" "  ✓ tempuser has expiration and forced password change"
            ((score++))
        else
            print_color "$RED" "  ✗ tempuser configuration incomplete"
            print_color "$YELLOW" "  Fix: sudo usermod -e 2025-12-31 tempuser; sudo passwd -e tempuser"
        fi
    else
        print_color "$RED" "  ✗ tempuser does not exist"
        print_color "$YELLOW" "  Fix: sudo useradd -e 2025-12-31 tempuser; sudo passwd tempuser"
    fi
    echo ""
    
    # CHECK 4: sysadmin1
    print_color "$CYAN" "[4/$total] Checking sysadmin1 modification and lock..."
    if getent passwd sysadmin1 >/dev/null 2>&1; then
        local shell=$(getent passwd sysadmin1 | cut -d: -f7)
        local shadow_pass=$(sudo getent shadow sysadmin1 2>/dev/null | cut -d: -f2)
        
        if [ "$shell" = "/bin/zsh" ] && echo "$shadow_pass" | grep -q "^!"; then
            print_color "$GREEN" "  ✓ sysadmin1 has zsh shell and is locked"
            ((score++))
        else
            print_color "$RED" "  ✗ sysadmin1 not configured correctly"
            print_color "$YELLOW" "  Fix: sudo usermod -s /bin/zsh sysadmin1; sudo usermod -L sysadmin1"
        fi
    else
        print_color "$RED" "  ✗ sysadmin1 does not exist"
        print_color "$YELLOW" "  Fix: sudo useradd -c \"System Administrator\" -s /bin/zsh sysadmin1"
    fi
    echo ""
    
    # CHECK 5: Query commands
    print_color "$CYAN" "[5/$total] Checking ability to query user information..."
    if getent passwd developer1 >/dev/null 2>&1 && \
       id developer1 >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ User information query commands working"
        ((score++))
    else
        print_color "$RED" "  ✗ Cannot query user information"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Creating regular user accounts with useradd"
        echo "  • Creating system accounts for applications"
        echo "  • Setting account expiration and password aging"
        echo "  • Modifying and locking user accounts"
        echo "  • Querying user information with getent and id"
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

OBJECTIVE 1: Create regular user (developer1)
─────────────────────────────────────────────────────────────────
Commands:
  sudo useradd -c "Jane Developer" developer1
  sudo passwd developer1
  # Enter password: devpass123

Verification:
  getent passwd developer1
  ls -la /home/developer1
  sudo getent shadow developer1


OBJECTIVE 2: Create system account (appuser1)
─────────────────────────────────────────────────────────────────
Command:
  sudo useradd --system -s /sbin/nologin appuser1

Verification:
  getent passwd appuser1
  # Check UID < 1000 and shell /sbin/nologin


OBJECTIVE 3: Create temporary account (tempuser)
─────────────────────────────────────────────────────────────────
Commands:
  sudo useradd -e 2025-12-31 tempuser
  sudo passwd tempuser
  # Enter: temppass123
  sudo passwd -e tempuser

Verification:
  sudo chage -l tempuser


OBJECTIVE 4: Create, modify, and lock account (sysadmin1)
─────────────────────────────────────────────────────────────────
Commands:
  sudo useradd -c "System Administrator" -s /bin/zsh sysadmin1
  sudo usermod -L sysadmin1

Verification:
  getent passwd sysadmin1
  sudo getent shadow sysadmin1 | cut -d: -f2
  # Should start with !


OBJECTIVE 5: Query user information
─────────────────────────────────────────────────────────────────
Commands:
  getent passwd developer1
  id developer1
  sudo getent shadow developer1


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/etc/passwd Structure:
  username:x:UID:GID:GECOS:home:shell
  
  • x: Password placeholder (actual hash in /etc/shadow)
  • UID: User ID (1000+ for regular users, < 1000 for system)
  • GID: Primary group ID
  • GECOS: Comment/full name field
  • home: Home directory path
  • shell: Login shell

/etc/shadow Structure:
  username:hash:lastchange:min:max:warn:inactive:expire:reserved
  
  • hash: Encrypted password (or ! for locked, * for no password)
  • lastchange: Days since 1970-01-01 of last password change
  • min: Minimum days between password changes
  • max: Maximum days before password expires
  • warn: Days before expiration to warn user
  • inactive: Days after expiration before account locks
  • expire: Absolute expiration date (days since 1970-01-01)

Password Hash Format:
  $algorithm$salt$hash
  
  • $6$: SHA-512 (current standard)
  • $5$: SHA-256
  • $1$: MD5 (deprecated)

System vs Regular Accounts:
  System Accounts (UID < 1000):
  • Used by services and daemons
  • Typically have /sbin/nologin shell
  • Often don't have home directories
  • Examples: apache, nginx, mysql
  
  Regular Accounts (UID >= 1000):
  • Used by people
  • Have /bin/bash or similar shell
  • Have home directories
  • Can log in interactively

Account Locking:
  usermod -L (lock):
  • Adds ! to password hash
  • Prevents password authentication
  • SSH keys may still work
  • Reversible with usermod -U
  
  usermod -s /sbin/nologin:
  • Sets shell that rejects login
  • More permanent than locking
  • Used for system/application accounts

COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Not setting password after creating user
  Result: User exists but cannot log in
  Fix: sudo passwd username

Mistake 2: Forgetting --system flag for application accounts
  Result: UID >= 1000 (wrong range)
  Fix: sudo useradd --system username

Mistake 3: Confusing -L (lock) with -s /sbin/nologin
  -L: Temporary lock, reversible
  -s /sbin/nologin: Permanent no-login shell
  Use -L for suspended employees, nologin for system accounts

Mistake 4: Using cat instead of getent
  cat /etc/passwd: Only local files
  getent passwd: Checks all sources (LDAP, SSSD, etc.)
  Always use getent for querying users

EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Use useradd -c for GECOS field (full name/comment)
2. System accounts need --system flag (UID < 1000)
3. Lock accounts with usermod -L, unlock with -U
4. Set expiration with useradd -e or usermod -e (YYYY-MM-DD)
5. Force password change with passwd -e username
6. Always verify with getent, not cat

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r developer1 2>/dev/null || true
    userdel -r sysadmin1 2>/dev/null || true
    userdel -r appuser1 2>/dev/null || true
    userdel -r tempuser 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
