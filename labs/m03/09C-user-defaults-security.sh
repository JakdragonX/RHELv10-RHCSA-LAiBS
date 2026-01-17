#!/bin/bash
# labs/m03/09C-user-defaults-security.sh
# Lab: User Defaults, Password Security, and /etc/skel
# Difficulty: Intermediate
# RHCSA Objective: 9.4-9.5, 9.8 - User defaults, password policies, and security

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="User Defaults, Password Security, and /etc/skel"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous lab attempts
    userdel -r testuser1 2>/dev/null || true
    userdel -r testuser2 2>/dev/null || true
    userdel -r secureuser 2>/dev/null || true
    rm -f /etc/skel/README.txt 2>/dev/null || true
    rm -f /etc/skel/.company_profile 2>/dev/null || true
    rm -rf /tmp/skel-test 2>/dev/null || true
    
    # Backup original login.defs if not already backed up
    if [ ! -f /etc/login.defs.lab-backup ]; then
        cp /etc/login.defs /etc/login.defs.lab-backup 2>/dev/null || true
    fi
    
    # Ensure /etc/skel exists
    mkdir -p /etc/skel 2>/dev/null || true
    
    echo "  ✓ Cleaned up previous lab attempts"
    echo "  ✓ Backed up /etc/login.defs"
    echo "  ✓ System ready for user defaults configuration"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of user account creation
  • Basic understanding of password security
  • Familiarity with shell configuration files

Commands You'll Use:
  • useradd - Create user accounts
  • chage - Change password aging information
  • passwd - Set passwords and password policies
  • grep - Search configuration files
  • cat - View file contents

Files You'll Interact With:
  • /etc/skel/ - Template directory for new user home directories
  • /etc/login.defs - Default settings for user creation
  • /etc/shadow - Password aging information
  • ~/.bashrc - User shell configuration
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your organization is implementing new security policies. All new users must have
secure password policies, receive company documentation in their home directories,
and have customized shell configurations. You'll configure system defaults so
every new user automatically meets these requirements.

BACKGROUND:
The /etc/skel directory contains template files copied to every new user's home
directory. The /etc/login.defs file sets default password aging policies. Using
these properly ensures consistent, secure user environments without manual
configuration for each user.

OBJECTIVES:
  1. Configure /etc/skel with default files for new users
     • Create /etc/skel/README.txt with welcome message
     • Create /etc/skel/.company_profile with company info
     • Create test user to verify /etc/skel files are copied
     • User: testuser1
     • Verify files appear in /home/testuser1/

  2. Modify /etc/login.defs password aging defaults
     • Set PASS_MAX_DAYS to 90 (password expires after 90 days)
     • Set PASS_MIN_DAYS to 7 (minimum 7 days between changes)
     • Set PASS_WARN_AGE to 14 (warn 14 days before expiration)
     • Create testuser2 to verify defaults apply
     • Check with: sudo chage -l testuser2

  3. Configure password aging for existing user with chage
     • Create user: secureuser
     • Set password: securepass123
     • Configure password aging:
       - Maximum age: 60 days
       - Minimum age: 5 days
       - Warning: 10 days
       - Inactive: 30 days (account locks 30 days after password expires)
     • Verify with: sudo chage -l secureuser

  4. Set account expiration date with chage
     • Set secureuser account to expire on: 2026-06-30
     • Verify expiration with chage -l
     • Check /etc/shadow for expiration date
     • Understand shadow date format (days since 1970-01-01)

  5. Test and verify password policies
     • Use passwd command to view password status
     • Use chage -l to view detailed aging information
     • Verify /etc/shadow entries for password aging fields
     • Understand /etc/shadow field meanings

HINTS:
  • /etc/skel files are copied during useradd only
  • Changes to /etc/login.defs only affect NEW users
  • chage can modify existing users
  • Shadow dates are days since Jan 1, 1970
  • Use sudo chage -l username to view aging info
  • Field order in /etc/shadow matters

SUCCESS CRITERIA:
  • /etc/skel contains README.txt and .company_profile
  • testuser1 has files from /etc/skel in home directory
  • /etc/login.defs configured with password aging defaults
  • testuser2 has default aging from /etc/login.defs
  • secureuser has custom password aging (60/5/10/30)
  • secureuser expires on 2026-06-30
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create files in /etc/skel/, create testuser1, verify files copied
  ☐ 2. Modify /etc/login.defs (PASS_MAX_DAYS=90, MIN=7, WARN=14)
  ☐ 3. Use chage to set secureuser password aging (60/5/10/30)
  ☐ 4. Set secureuser expiration to 2026-06-30 with chage
  ☐ 5. Verify all configurations with chage -l and /etc/shadow
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
You're implementing security policies for user accounts. You'll configure default
files for new users, set password aging policies, and ensure accounts expire
appropriately.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Configure /etc/skel with default files for new users

The /etc/skel directory is a template. Its contents are automatically copied to
every new user's home directory when you run useradd.

What to do:
  • Create /etc/skel/README.txt with content:
    "Welcome to the company! Please read our policies."
  • Create /etc/skel/.company_profile with content:
    "COMPANY=TechCorp"
  • Create user testuser1
  • Verify files appear in /home/testuser1/

Tools available:
  • echo "text" > file - Create file with content
  • useradd - Create user
  • ls -la - View files including hidden ones

Format:
  sudo bash -c 'echo "Welcome to the company!" > /etc/skel/README.txt'
  sudo bash -c 'echo "COMPANY=TechCorp" > /etc/skel/.company_profile'
  sudo useradd -m testuser1
  ls -la /home/testuser1/

Think about:
  • Why use /etc/skel instead of manually creating files?
  • When are /etc/skel files copied?
  • What about existing users?

After completing: Check with: ls -la /home/testuser1/
EOF
}

validate_step_1() {
    # Check /etc/skel files exist
    if [ ! -f /etc/skel/README.txt ]; then
        echo ""
        print_color "$RED" "✗ /etc/skel/README.txt not found"
        echo "  Try: sudo bash -c 'echo \"Welcome message\" > /etc/skel/README.txt'"
        return 1
    fi
    
    if [ ! -f /etc/skel/.company_profile ]; then
        echo ""
        print_color "$RED" "✗ /etc/skel/.company_profile not found"
        echo "  Try: sudo bash -c 'echo \"COMPANY=TechCorp\" > /etc/skel/.company_profile'"
        return 1
    fi
    
    # Check user exists
    if ! getent passwd testuser1 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ testuser1 does not exist"
        echo "  Try: sudo useradd -m testuser1"
        return 1
    fi
    
    # Check files copied to user's home
    if [ ! -f /home/testuser1/README.txt ]; then
        echo ""
        print_color "$RED" "✗ README.txt not found in testuser1's home"
        echo "  Files from /etc/skel not copied (user may have been created before /etc/skel setup)"
        return 1
    fi
    
    if [ ! -f /home/testuser1/.company_profile ]; then
        echo ""
        print_color "$RED" "✗ .company_profile not found in testuser1's home"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo bash -c 'echo "Welcome to the company! Please read our policies." > /etc/skel/README.txt'
  sudo bash -c 'echo "COMPANY=TechCorp" > /etc/skel/.company_profile'
  sudo useradd -m testuser1

Explanation:
  • bash -c '...': Runs command in new shell (for redirection with sudo)
  • > /etc/skel/README.txt: Creates file in /etc/skel
  • useradd -m: Creates user with home directory
  • Files from /etc/skel automatically copied

How /etc/skel works:
  1. useradd is executed with -m (create home)
  2. System creates /home/username
  3. System copies ALL files from /etc/skel to /home/username
  4. User owns all copied files

Common /etc/skel files:
  • .bashrc - Shell configuration
  • .bash_profile - Login configuration
  • .bash_logout - Logout actions
  • README.txt - Company information
  • .vimrc - Editor configuration

Important notes:
  • Only affects NEW users
  • Existing users don't get updates
  • Hidden files (starting with .) are copied too
  • Useful for company standards

Verification:
  ls -la /etc/skel/
  # Should show README.txt and .company_profile
  
  ls -la /home/testuser1/
  # Should show both files copied from /etc/skel

EOF
}

hint_step_2() {
    echo "  Edit /etc/login.defs with sudo"
    echo "  Find PASS_MAX_DAYS, PASS_MIN_DAYS, PASS_WARN_AGE"
    echo "  Change values, then create testuser2"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Modify /etc/login.defs for default password aging

The /etc/login.defs file sets system-wide defaults for new user accounts.
Changes only affect users created AFTER the modification.

What to do:
  • Edit /etc/login.defs (use sudo and your preferred editor)
  • Find and modify these lines:
    PASS_MAX_DAYS   90
    PASS_MIN_DAYS   7
    PASS_WARN_AGE   14
  • Create testuser2 to test defaults
  • Verify with: sudo chage -l testuser2

Tools available:
  • sudo vi /etc/login.defs - Edit file
  • grep PASS /etc/login.defs - View password settings
  • useradd - Create test user
  • chage -l - View password aging

Think about:
  • Why only affect new users?
  • What about existing users?
  • What do these numbers mean?

After completing: Verify with: sudo chage -l testuser2
EOF
}

validate_step_2() {
    # Check /etc/login.defs values
    local max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local min_days=$(grep "^PASS_MIN_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local warn_age=$(grep "^PASS_WARN_AGE" /etc/login.defs 2>/dev/null | awk '{print $2}')
    
    if [ "$max_days" != "90" ] || [ "$min_days" != "7" ] || [ "$warn_age" != "14" ]; then
        echo ""
        print_color "$RED" "✗ /etc/login.defs not configured correctly"
        echo "  Current: MAX=$max_days MIN=$min_days WARN=$warn_age"
        echo "  Expected: MAX=90 MIN=7 WARN=14"
        echo "  Edit with: sudo vi /etc/login.defs"
        return 1
    fi
    
    # Check if testuser2 exists
    if ! getent passwd testuser2 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ testuser2 does not exist"
        echo "  Try: sudo useradd -m testuser2"
        return 1
    fi
    
    # Check if testuser2 has correct defaults
    local user_max=$(sudo chage -l testuser2 2>/dev/null | grep "Maximum" | grep -o "[0-9]*")
    if [ -z "$user_max" ] || [ "$user_max" != "90" ]; then
        echo ""
        print_color "$YELLOW" "  Note: testuser2 may have been created before login.defs changes"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo vi /etc/login.defs
  # Find and modify:
  # PASS_MAX_DAYS   90
  # PASS_MIN_DAYS   7
  # PASS_WARN_AGE   14
  
  sudo useradd -m testuser2

Explanation:
  • PASS_MAX_DAYS 90: Password expires after 90 days
  • PASS_MIN_DAYS 7: Must wait 7 days between password changes
  • PASS_WARN_AGE 14: Warn user 14 days before expiration

Why these defaults matter:
  • MAX_DAYS: Forces regular password changes
  • MIN_DAYS: Prevents rapid password cycling
  • WARN_AGE: Gives users advance notice

/etc/login.defs also controls:
  • UID_MIN, UID_MAX: User ID ranges
  • GID_MIN, GID_MAX: Group ID ranges
  • CREATE_HOME: Whether to create home directories
  • UMASK: Default permissions for new files

Important: Changes only affect NEW users!
  Existing users keep their current settings.
  Use chage to modify existing users.

Verification:
  grep PASS /etc/login.defs
  # Should show:
  # PASS_MAX_DAYS   90
  # PASS_MIN_DAYS   7
  # PASS_WARN_AGE   14
  
  sudo chage -l testuser2
  # Should show the new defaults

EOF
}

hint_step_3() {
    echo "  Use: sudo chage -M 60 -m 5 -W 10 -I 30 secureuser"
    echo "  Or: sudo chage secureuser (interactive mode)"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Configure password aging for existing user with chage

The chage command modifies password aging for existing users. This is how you
enforce policies on accounts created before policy changes.

What to do:
  • Create user: secureuser
  • Set password: securepass123
  • Configure password aging:
    - Maximum age: 60 days (-M 60)
    - Minimum age: 5 days (-m 5)
    - Warning: 10 days (-W 10)
    - Inactive: 30 days (-I 30)

Tools available:
  • useradd - Create user
  • passwd - Set password
  • chage - Modify password aging
  • chage -l - View aging information

Format:
  sudo useradd -m secureuser
  sudo passwd secureuser
  sudo chage -M 60 -m 5 -W 10 -I 30 secureuser

Think about:
  • What happens after password expires?
  • What does "inactive" mean?
  • How is this different from /etc/login.defs?

After completing: Verify with: sudo chage -l secureuser
EOF
}

validate_step_3() {
    # Check if user exists
    if ! getent passwd secureuser >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ secureuser does not exist"
        echo "  Try: sudo useradd -m secureuser"
        return 1
    fi
    
    # Check password aging settings
    local max_days=$(sudo chage -l secureuser 2>/dev/null | grep "Maximum" | grep -o "[0-9]*" | head -1)
    local min_days=$(sudo chage -l secureuser 2>/dev/null | grep "Minimum" | grep -o "[0-9]*" | head -1)
    local warn_days=$(sudo chage -l secureuser 2>/dev/null | grep "warning" | grep -o "[0-9]*")
    local inactive=$(sudo chage -l secureuser 2>/dev/null | grep "inactive" | grep -o "[0-9]*")
    
    if [ "$max_days" != "60" ] || [ "$min_days" != "5" ] || \
       [ "$warn_days" != "10" ] || [ "$inactive" != "30" ]; then
        echo ""
        print_color "$RED" "✗ Password aging not configured correctly"
        echo "  Current: MAX=$max_days MIN=$min_days WARN=$warn_days INACTIVE=$inactive"
        echo "  Expected: MAX=60 MIN=5 WARN=10 INACTIVE=30"
        echo "  Try: sudo chage -M 60 -m 5 -W 10 -I 30 secureuser"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo useradd -m secureuser
  sudo passwd secureuser
  # Enter: securepass123
  sudo chage -M 60 -m 5 -W 10 -I 30 secureuser

Alternative (interactive):
  sudo chage secureuser
  # Then enter values when prompted

Explanation:
  • -M 60: Maximum password age (60 days)
  • -m 5: Minimum password age (5 days)
  • -W 10: Warning period (10 days before expiration)
  • -I 30: Inactive period (30 days after expiration)

Password lifecycle:
  Day 0: Password set
  Day 5: Can change password (minimum age passed)
  Day 50: Warning starts (10 days before 60)
  Day 60: Password expires
  Day 90: Account locks (60 + 30 inactive days)

Inactive period explained:
  After password expires, user can still log in to change it.
  After inactive period expires, account locks completely.
  Admin must unlock: passwd -u username

chage flags:
  -M: Maximum days (password expires)
  -m: Minimum days (can't change before)
  -W: Warning days (alert before expiration)
  -I: Inactive days (grace period after expiration)
  -E: Account expiration date (YYYY-MM-DD)
  -l: List current settings

Verification:
  sudo chage -l secureuser
  # Shows all password aging information
  
  sudo getent shadow secureuser
  # Shows raw /etc/shadow entry

EOF
}

hint_step_4() {
    echo "  Use: sudo chage -E 2026-06-30 secureuser"
    echo "  Format: YYYY-MM-DD"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Set account expiration date

Account expiration is different from password expiration. When an account expires,
the user cannot log in at all, even with a valid password.

What to do:
  • Set secureuser to expire on: 2026-06-30
  • Use chage -E with date format: YYYY-MM-DD
  • Verify with chage -l

Tools available:
  • chage -E YYYY-MM-DD username - Set expiration
  • chage -l username - View expiration
  • getent shadow - View raw shadow entry

Format:
  sudo chage -E 2026-06-30 secureuser

Think about:
  • When to use account expiration?
  • How is this different from password expiration?
  • What about contractors and temporary employees?

After completing: Verify with: sudo chage -l secureuser
EOF
}

validate_step_4() {
    # Check expiration date
    local expire_info=$(sudo chage -l secureuser 2>/dev/null | grep "Account expires")
    
    if ! echo "$expire_info" | grep -qi "2026"; then
        echo ""
        print_color "$RED" "✗ Account expiration not set or incorrect"
        echo "  Current: $expire_info"
        echo "  Try: sudo chage -E 2026-06-30 secureuser"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo chage -E 2026-06-30 secureuser

Explanation:
  • -E: Set account expiration date
  • 2026-06-30: Date in YYYY-MM-DD format
  • secureuser: Username

Account vs Password Expiration:
  Password Expiration (-M):
  • User can still log in
  • Must change password immediately
  • Can recover themselves
  
  Account Expiration (-E):
  • User CANNOT log in
  • Even with valid password
  • Admin must change date

When to use account expiration:
  • Contractors with end dates
  • Temporary employees
  • Student accounts (end of semester)
  • Test accounts
  • Project-based access

/etc/shadow date format:
  Dates stored as days since 1970-01-01
  Example: 20635 = 2026-06-30
  
  Calculation:
  (2026-1970)*365 + leap years + days in year

Verification:
  sudo chage -l secureuser
  # Should show: Account expires: Jun 30, 2026
  
  sudo getent shadow secureuser | cut -d: -f8
  # Shows numeric date (days since 1970-01-01)

Removing expiration:
  sudo chage -E -1 secureuser
  # -1 means no expiration

EOF
}

hint_step_5() {
    echo "  Use: sudo chage -l secureuser"
    echo "  Use: sudo passwd -S secureuser"
    echo "  Compare output formats"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Verify and understand password policies

Multiple commands show password information in different formats. Understanding
what each shows helps with troubleshooting and auditing.

What to do:
  • Use chage -l to view detailed aging
  • Use passwd -S to view status
  • Use getent shadow to view raw shadow entry
  • Compare the different outputs

Tools available:
  • chage -l username - Detailed aging information
  • passwd -S username - Password status
  • getent shadow username - Raw /etc/shadow entry

Commands to run:
  sudo chage -l secureuser
  sudo passwd -S secureuser
  sudo getent shadow secureuser

Think about:
  • Which command is most detailed?
  • When would you use each?
  • What do the /etc/shadow fields mean?

After completing: Compare the different output formats
EOF
}

validate_step_5() {
    # This is informational, just verify commands work
    if ! sudo chage -l secureuser >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Cannot query password aging information"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo chage -l secureuser
  sudo passwd -S secureuser
  sudo getent shadow secureuser

Sample Output Comparison:

1. chage -l secureuser (most detailed):
   Last password change: Jan 17, 2026
   Password expires: Mar 18, 2026
   Password inactive: Apr 17, 2026
   Account expires: Jun 30, 2026
   Minimum number of days: 5
   Maximum number of days: 60
   Number of days of warning: 10

2. passwd -S secureuser (status):
   secureuser PS 2026-01-17 5 60 10 30 (PS = Password Set)
   Format: username status last_change min max warn inactive

3. getent shadow secureuser (raw):
   secureuser:$6$xyz...:20635:5:60:10:30:20635:

/etc/shadow field meanings:
  1. username
  2. password hash ($6$ = SHA-512)
  3. last change (days since 1970-01-01)
  4. minimum age (days)
  5. maximum age (days)
  6. warning period (days)
  7. inactive period (days)
  8. expiration date (days since 1970-01-01)
  9. reserved (unused)

passwd -S status codes:
  PS: Password set (usable)
  LK: Locked (! in shadow)
  NP: No password (* in shadow)

When to use each:
  chage -l:
  • Human-readable dates
  • Complete information
  • Best for auditing
  
  passwd -S:
  • Quick status check
  • See lock status
  • Good for scripts
  
  getent shadow:
  • Raw data
  • Numeric values
  • For deep troubleshooting

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your user defaults and security configuration..."
    echo ""
    
    # CHECK 1: /etc/skel files
    print_color "$CYAN" "[1/$total] Checking /etc/skel configuration..."
    if [ -f /etc/skel/README.txt ] && [ -f /etc/skel/.company_profile ] && \
       [ -f /home/testuser1/README.txt ] && [ -f /home/testuser1/.company_profile ]; then
        print_color "$GREEN" "  ✓ /etc/skel files created and copied to testuser1"
        ((score++))
    else
        print_color "$RED" "  ✗ /etc/skel not configured correctly"
        print_color "$YELLOW" "  Fix: Create files in /etc/skel, then create testuser1"
    fi
    echo ""
    
    # CHECK 2: /etc/login.defs
    print_color "$CYAN" "[2/$total] Checking /etc/login.defs password aging..."
    local max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local min_days=$(grep "^PASS_MIN_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local warn_age=$(grep "^PASS_WARN_AGE" /etc/login.defs 2>/dev/null | awk '{print $2}')
    
    if [ "$max_days" = "90" ] && [ "$min_days" = "7" ] && [ "$warn_age" = "14" ]; then
        print_color "$GREEN" "  ✓ /etc/login.defs configured correctly"
        ((score++))
    else
        print_color "$RED" "  ✗ /etc/login.defs values incorrect"
        echo "  Current: MAX=$max_days MIN=$min_days WARN=$warn_age"
        echo "  Expected: MAX=90 MIN=7 WARN=14"
        print_color "$YELLOW" "  Fix: sudo vi /etc/login.defs"
    fi
    echo ""
    
    # CHECK 3: secureuser password aging
    print_color "$CYAN" "[3/$total] Checking secureuser password aging..."
    if getent passwd secureuser >/dev/null 2>&1; then
        local max_days=$(sudo chage -l secureuser 2>/dev/null | grep "Maximum" | grep -o "[0-9]*" | head -1)
        local min_days=$(sudo chage -l secureuser 2>/dev/null | grep "Minimum" | grep -o "[0-9]*" | head -1)
        local warn=$(sudo chage -l secureuser 2>/dev/null | grep "warning" | grep -o "[0-9]*")
        local inactive=$(sudo chage -l secureuser 2>/dev/null | grep "inactive" | grep -o "[0-9]*")
        
        if [ "$max_days" = "60" ] && [ "$min_days" = "5" ] && \
           [ "$warn" = "10" ] && [ "$inactive" = "30" ]; then
            print_color "$GREEN" "  ✓ secureuser has correct password aging"
            ((score++))
        else
            print_color "$RED" "  ✗ Password aging incorrect"
            echo "  Current: MAX=$max_days MIN=$min_days WARN=$warn INACTIVE=$inactive"
            print_color "$YELLOW" "  Fix: sudo chage -M 60 -m 5 -W 10 -I 30 secureuser"
        fi
    else
        print_color "$RED" "  ✗ secureuser does not exist"
        print_color "$YELLOW" "  Fix: sudo useradd -m secureuser"
    fi
    echo ""
    
    # CHECK 4: Account expiration
    print_color "$CYAN" "[4/$total] Checking secureuser account expiration..."
    if getent passwd secureuser >/dev/null 2>&1; then
        local expire_info=$(sudo chage -l secureuser 2>/dev/null | grep "Account expires")
        
        if echo "$expire_info" | grep -qi "2026"; then
            print_color "$GREEN" "  ✓ Account expiration set to 2026"
            ((score++))
        else
            print_color "$RED" "  ✗ Account expiration not set correctly"
            print_color "$YELLOW" "  Fix: sudo chage -E 2026-06-30 secureuser"
        fi
    else
        print_color "$RED" "  ✗ secureuser does not exist"
    fi
    echo ""
    
    # CHECK 5: Verification commands
    print_color "$CYAN" "[5/$total] Checking password policy verification..."
    if sudo chage -l secureuser >/dev/null 2>&1 && \
       sudo passwd -S secureuser >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Password verification commands working"
        ((score++))
    else
        print_color "$RED" "  ✗ Cannot verify password policies"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Configuring /etc/skel for default user files"
        echo "  • Setting password aging defaults in /etc/login.defs"
        echo "  • Using chage to configure password policies"
        echo "  • Setting account expiration dates"
        echo "  • Verifying password policies multiple ways"
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

OBJECTIVE 1: Configure /etc/skel
─────────────────────────────────────────────────────────────────
Commands:
  sudo bash -c 'echo "Welcome to the company! Please read our policies." > /etc/skel/README.txt'
  sudo bash -c 'echo "COMPANY=TechCorp" > /etc/skel/.company_profile'
  sudo useradd -m testuser1
  ls -la /home/testuser1/


OBJECTIVE 2: Modify /etc/login.defs
─────────────────────────────────────────────────────────────────
Commands:
  sudo vi /etc/login.defs
  # Modify:
  # PASS_MAX_DAYS   90
  # PASS_MIN_DAYS   7
  # PASS_WARN_AGE   14
  
  sudo useradd -m testuser2
  sudo chage -l testuser2


OBJECTIVE 3: Configure password aging with chage
─────────────────────────────────────────────────────────────────
Commands:
  sudo useradd -m secureuser
  sudo passwd secureuser
  # Enter: securepass123
  sudo chage -M 60 -m 5 -W 10 -I 30 secureuser
  sudo chage -l secureuser


OBJECTIVE 4: Set account expiration
─────────────────────────────────────────────────────────────────
Command:
  sudo chage -E 2026-06-30 secureuser
  sudo chage -l secureuser


OBJECTIVE 5: Verify password policies
─────────────────────────────────────────────────────────────────
Commands:
  sudo chage -l secureuser
  sudo passwd -S secureuser
  sudo getent shadow secureuser


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/etc/skel Purpose:
  Template directory for new user home directories.
  • Files copied during useradd -m
  • Only affects new users
  • Existing users unaffected
  • Can contain any file or directory

Common /etc/skel contents:
  • .bashrc - Shell configuration
  • .bash_profile - Login shell config
  • .bash_logout - Logout actions
  • README - Welcome/instructions
  • Company documents
  • Default application configs

/etc/login.defs:
  System-wide defaults for new users:
  • PASS_MAX_DAYS: Password expiration
  • PASS_MIN_DAYS: Minimum age
  • PASS_WARN_AGE: Warning period
  • UID_MIN/MAX: User ID ranges
  • CREATE_HOME: Auto-create home dirs
  • UMASK: Default permissions

Password Aging with chage:
  Controls password lifecycle:
  • Maximum age (-M): When password expires
  • Minimum age (-m): Prevents rapid changes
  • Warning (-W): Alert before expiration
  • Inactive (-I): Grace period after expiration
  • Expiration (-E): Account lockout date

Password vs Account Expiration:
  Password Expiration:
  • User can log in
  • Must change password immediately
  • User can self-recover
  
  Account Expiration:
  • User cannot log in
  • Admin must intervene
  • Used for contractors/temp staff

/etc/shadow Fields:
  username:hash:last:min:max:warn:inactive:expire:reserved
  
  Example:
  alice:$6$xyz:19500:5:60:10:30:20635:
  
  • last: Days since 1970-01-01 of last change
  • min: Minimum days between changes
  • max: Maximum days before expiration
  • warn: Warning days
  • inactive: Grace period
  • expire: Account expiration date


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Creating user before /etc/skel files
  Result: User doesn't get /etc/skel files
  Fix: Delete user, add files to /etc/skel, recreate user
  Files only copied at account creation

Mistake 2: Expecting /etc/login.defs to affect existing users
  Result: Existing users keep old settings
  Fix: Use chage to modify existing users individually
  login.defs only affects NEW users

Mistake 3: Confusing password and account expiration
  Password expired: Can log in, must change password
  Account expired: Cannot log in at all
  Use -M for password, -E for account

Mistake 4: Wrong date format with chage -E
  Wrong: chage -E 06/30/2026
  Right: chage -E 2026-06-30
  Format: YYYY-MM-DD


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. /etc/skel only works for NEW users
2. /etc/login.defs only affects NEW users
3. Use chage to modify existing users
4. chage -E format: YYYY-MM-DD
5. Verify with: sudo chage -l username
6. Remember: -M (password max), -E (account expiration)

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r testuser1 2>/dev/null || true
    userdel -r testuser2 2>/dev/null || true
    userdel -r secureuser 2>/dev/null || true
    rm -f /etc/skel/README.txt 2>/dev/null || true
    rm -f /etc/skel/.company_profile 2>/dev/null || true
    
    # Restore original login.defs if backup exists
    if [ -f /etc/login.defs.lab-backup ]; then
        cp /etc/login.defs.lab-backup /etc/login.defs 2>/dev/null || true
        rm -f /etc/login.defs.lab-backup 2>/dev/null || true
        echo "  ✓ Restored original /etc/login.defs"
    fi
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
