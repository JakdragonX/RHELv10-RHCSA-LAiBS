#!/bin/bash
# labs/01-user-management.sh - UPDATED with Interactive Mode Support
# Lab: Basic User and Group Management

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Basic User and Group Management"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="10-15 minutes"

#############################################################################
# PHASE 1: Setup Function
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    userdel -r devuser1 2>/dev/null || true
    userdel -r devuser2 2>/dev/null || true
    groupdel webdevs 2>/dev/null || true
    rm -rf /home/developers 2>/dev/null || true
    
    echo "  ✓ Cleaned up any previous lab attempts"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PHASE 2: Prerequisites
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of Linux users and groups concept
  • Familiarity with the command line

Commands You'll Use:
  • groupadd  - Create a new group
  • useradd   - Create a new user account
  • id        - Display user and group information
  • getent    - Query system databases

Files You'll Interact With:
  • /etc/passwd - User account information
  • /etc/group  - Group definitions
EOF
}

#############################################################################
# PHASE 3: Scenario (Standard Mode)
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your company is setting up a new web development team. As the system
administrator, you need to create the necessary user accounts and groups
following company naming conventions and security policies.

BACKGROUND:
The web development team will work on company websites and web applications.
They need their own group for shared project access, and each developer
needs an individual user account.

OBJECTIVES:
  1. Create a group named "webdevs" with GID 5000
  
  2. Create a user "devuser1" with:
     • UID: 5001
     • Primary group: webdevs
     • Full name (GECOS): "Alice Developer"
     • Home directory: /home/developers/devuser1
  
  3. Create a user "devuser2" with:
     • UID: 5002
     • Primary group: webdevs
     • Home directory: /home/developers/devuser2

HINTS:
  • Remember to create home directories with the -m flag
  • Use -d to specify custom home directory paths
  • GECOS field is set with the -c option

SUCCESS CRITERIA:
  • Both users can be identified with the 'id' command
  • Both users belong to the webdevs group
  • Home directories exist and are owned by respective users
EOF
}

# Quick objectives list
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create group "webdevs" with GID 5000
  ☐ 2. Create user "devuser1" (UID 5001, group: webdevs, GECOS: "Alice Developer")
  ☐ 3. Create user "devuser2" (UID 5002, group: webdevs)
  ☐ 4. Home directories: /home/developers/devuser1 and /home/developers/devuser2
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

# Return the number of steps in interactive mode
get_step_count() {
    echo "3"
}

# Context shown once at the start of interactive mode
scenario_context() {
    cat << 'EOF'
Your company is setting up a new web development team. As the system
administrator, you need to create the necessary user accounts and groups.

The web development team will work on company websites and web applications.
They need their own group for shared project access, and each developer
needs an individual user account.
EOF
}

# Step 1: Create the group
show_step_1() {
    cat << 'EOF'
TASK: Create the webdevs group

Create a new group called "webdevs" with GID 5000.

Requirements:
  • Group name: webdevs
  • GID: 5000

Commands you might need:
  • groupadd - Create a new group
  • getent group - Verify group was created
EOF
}

validate_step_1() {
    if ! getent group webdevs >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Group 'webdevs' does not exist"
        echo "  Try: groupadd -g 5000 webdevs"
        return 1
    fi
    
    local actual_gid=$(getent group webdevs | cut -d: -f3)
    if [ "$actual_gid" != "5000" ]; then
        echo ""
        print_color "$RED" "✗ Group 'webdevs' exists but GID is $actual_gid (expected 5000)"
        echo "  You may need to: groupdel webdevs && groupadd -g 5000 webdevs"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  groupadd -g 5000 webdevs

Explanation:
  • groupadd: Creates a new group
  • -g 5000: Specifies the GID (Group ID) as 5000

Why specify a GID?
  In enterprise environments, standardized GIDs ensure consistent permissions
  across multiple systems, especially when using network file systems (NFS).

Verification:
  getent group webdevs
  # Should output: webdevs:x:5000:

EOF
}

hint_step_2() {
    echo "  Use the 'useradd' command with flags for UID (-u), group (-g), home directory (-d), and create home (-m)"
}

# Step 2: Create devuser1
show_step_2() {
    cat << 'EOF'
TASK: Create the first developer account

Create user "devuser1" with specific attributes.

Requirements:
  • Username: devuser1
  • UID: 5001
  • Primary group: webdevs
  • Full name (GECOS): "Alice Developer"
  • Home directory: /home/developers/devuser1
  • Home directory must be created

Commands you might need:
  • useradd - Create a new user
  • id - Verify user was created
  • ls -ld - Check directory ownership
EOF
}

validate_step_2() {
    if ! id devuser1 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ User 'devuser1' does not exist"
        echo "  Try: useradd -u 5001 -g webdevs -d /home/developers/devuser1 -m -c \"Alice Developer\" devuser1"
        return 1
    fi
    
    local actual_uid=$(id -u devuser1)
    if [ "$actual_uid" != "5001" ]; then
        echo ""
        print_color "$RED" "✗ User 'devuser1' UID is $actual_uid (expected 5001)"
        return 1
    fi
    
    local primary_group=$(id -gn devuser1)
    if [ "$primary_group" != "webdevs" ]; then
        echo ""
        print_color "$RED" "✗ User 'devuser1' primary group is '$primary_group' (expected 'webdevs')"
        echo "  Try: usermod -g webdevs devuser1"
        return 1
    fi
    
    if [ ! -d "/home/developers/devuser1" ]; then
        echo ""
        print_color "$RED" "✗ Home directory /home/developers/devuser1 does not exist"
        echo "  Try: mkdir -p /home/developers/devuser1 && chown devuser1:webdevs /home/developers/devuser1"
        return 1
    fi
    
    local owner=$(stat -c '%U' /home/developers/devuser1 2>/dev/null)
    if [ "$owner" != "devuser1" ]; then
        echo ""
        print_color "$RED" "✗ Home directory owned by '$owner' (expected 'devuser1')"
        echo "  Try: chown devuser1:webdevs /home/developers/devuser1"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  useradd -u 5001 -g webdevs -d /home/developers/devuser1 -m -c "Alice Developer" devuser1

Breaking it down:
  • useradd: Creates a new user
  • -u 5001: Sets the UID to 5001
  • -g webdevs: Sets primary group to 'webdevs'
  • -d /home/developers/devuser1: Specifies custom home directory path
  • -m: Creates the home directory (and parent directories if needed)
  • -c "Alice Developer": Sets the GECOS field (full name)
  • devuser1: The username

What happens behind the scenes:
  1. Entry added to /etc/passwd
  2. Entry added to /etc/shadow
  3. Directory /home/developers/devuser1 created
  4. Skeleton files from /etc/skel copied to new home directory
  5. Ownership set to devuser1:webdevs

Verification:
  id devuser1
  ls -ld /home/developers/devuser1

EOF
}

hint_step_3() {
    echo "  This is similar to step 2, but without the GECOS field"
}

# Step 3: Create devuser2
show_step_3() {
    cat << 'EOF'
TASK: Create the second developer account

Create user "devuser2" with specific attributes.

Requirements:
  • Username: devuser2
  • UID: 5002
  • Primary group: webdevs
  • Home directory: /home/developers/devuser2
  • Home directory must be created

Commands you might need:
  • useradd - Create a new user
  • id - Verify user was created
EOF
}

validate_step_3() {
    if ! id devuser2 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ User 'devuser2' does not exist"
        echo "  Try: useradd -u 5002 -g webdevs -d /home/developers/devuser2 -m devuser2"
        return 1
    fi
    
    local actual_uid=$(id -u devuser2)
    if [ "$actual_uid" != "5002" ]; then
        echo ""
        print_color "$RED" "✗ User 'devuser2' UID is $actual_uid (expected 5002)"
        return 1
    fi
    
    local primary_group=$(id -gn devuser2)
    if [ "$primary_group" != "webdevs" ]; then
        echo ""
        print_color "$RED" "✗ User 'devuser2' primary group is '$primary_group' (expected 'webdevs')"
        return 1
    fi
    
    if [ ! -d "/home/developers/devuser2" ]; then
        echo ""
        print_color "$RED" "✗ Home directory /home/developers/devuser2 does not exist"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  useradd -u 5002 -g webdevs -d /home/developers/devuser2 -m devuser2

This is similar to devuser1 but without the GECOS (-c) field.

Verification:
  id devuser2
  ls -ld /home/developers/devuser2

EOF
}

#############################################################################
# PHASE 4: Validation (Standard Mode - Full Validation)
#############################################################################
validate() {
    local score=0
    local total=5  # Reduced to essential checks only
    
    echo "Checking your configuration..."
    echo ""
    
    # Check 1: Group exists with GID 5000
    print_color "$CYAN" "[1/$total] Checking group 'webdevs'..."
    if getent group webdevs >/dev/null 2>&1; then
        local actual_gid=$(getent group webdevs | cut -d: -f3)
        if [ "$actual_gid" = "5000" ]; then
            print_color "$GREEN" "  ✓ Group 'webdevs' exists with GID 5000"
            ((score++))
        else
            print_color "$RED" "  ✗ Group 'webdevs' has GID $actual_gid (expected 5000)"
            print_color "$YELLOW" "  Fix: groupdel webdevs && groupadd -g 5000 webdevs"
        fi
    else
        print_color "$RED" "  ✗ Group 'webdevs' does not exist"
        print_color "$YELLOW" "  Fix: groupadd -g 5000 webdevs"
    fi
    echo ""
    
    # Check 2: User devuser1 configured correctly
    print_color "$CYAN" "[2/$total] Checking user 'devuser1'..."
    local devuser1_ok=true
    
    if ! id devuser1 >/dev/null 2>&1; then
        print_color "$RED" "  ✗ User 'devuser1' does not exist"
        print_color "$YELLOW" "  Fix: useradd -u 5001 -g webdevs -d /home/developers/devuser1 -m devuser1"
        devuser1_ok=false
    else
        # Check UID
        local uid1=$(id -u devuser1 2>/dev/null)
        if [ "$uid1" != "5001" ]; then
            print_color "$RED" "  ✗ UID is $uid1 (expected 5001)"
            devuser1_ok=false
        fi
        
        # Check primary group
        local gid1=$(id -gn devuser1 2>/dev/null)
        if [ "$gid1" != "webdevs" ]; then
            print_color "$RED" "  ✗ Primary group is '$gid1' (expected 'webdevs')"
            devuser1_ok=false
        fi
        
        if $devuser1_ok; then
            print_color "$GREEN" "  ✓ User 'devuser1' exists with UID 5001 and group 'webdevs'"
            ((score++))
        fi
    fi
    echo ""
    
    # Check 3: devuser1 home directory
    print_color "$CYAN" "[3/$total] Checking devuser1 home directory..."
    if [ -d "/home/developers/devuser1" ]; then
        local owner1=$(stat -c '%U' /home/developers/devuser1 2>/dev/null || echo "unknown")
        if [ "$owner1" = "devuser1" ]; then
            print_color "$GREEN" "  ✓ Directory /home/developers/devuser1 exists and is owned by devuser1"
            ((score++))
        else
            print_color "$RED" "  ✗ Directory exists but owned by '$owner1' (expected 'devuser1')"
            print_color "$YELLOW" "  Fix: chown devuser1:webdevs /home/developers/devuser1"
        fi
    else
        print_color "$RED" "  ✗ Directory /home/developers/devuser1 does not exist"
        print_color "$YELLOW" "  Fix: mkdir -p /home/developers/devuser1 && chown devuser1:webdevs /home/developers/devuser1"
    fi
    echo ""
    
    # Check 4: User devuser2 configured correctly
    print_color "$CYAN" "[4/$total] Checking user 'devuser2'..."
    local devuser2_ok=true
    
    if ! id devuser2 >/dev/null 2>&1; then
        print_color "$RED" "  ✗ User 'devuser2' does not exist"
        print_color "$YELLOW" "  Fix: useradd -u 5002 -g webdevs -d /home/developers/devuser2 -m devuser2"
        devuser2_ok=false
    else
        local uid2=$(id -u devuser2 2>/dev/null)
        if [ "$uid2" != "5002" ]; then
            print_color "$RED" "  ✗ UID is $uid2 (expected 5002)"
            devuser2_ok=false
        fi
        
        local gid2=$(id -gn devuser2 2>/dev/null)
        if [ "$gid2" != "webdevs" ]; then
            print_color "$RED" "  ✗ Primary group is '$gid2' (expected 'webdevs')"
            devuser2_ok=false
        fi
        
        if $devuser2_ok; then
            print_color "$GREEN" "  ✓ User 'devuser2' exists with UID 5002 and group 'webdevs'"
            ((score++))
        fi
    fi
    echo ""
    
    # Check 5: devuser2 home directory
    print_color "$CYAN" "[5/$total] Checking devuser2 home directory..."
    if [ -d "/home/developers/devuser2" ]; then
        local owner2=$(stat -c '%U' /home/developers/devuser2 2>/dev/null || echo "unknown")
        if [ "$owner2" = "devuser2" ]; then
            print_color "$GREEN" "  ✓ Directory /home/developers/devuser2 exists and is owned by devuser2"
            ((score++))
        else
            print_color "$RED" "  ✗ Directory exists but owned by '$owner2' (expected 'devuser2')"
            print_color "$YELLOW" "  Fix: chown devuser2:webdevs /home/developers/devuser2"
        fi
    else
        print_color "$RED" "  ✗ Directory /home/developers/devuser2 does not exist"
        print_color "$YELLOW" "  Fix: mkdir -p /home/developers/devuser2 && chown devuser2:webdevs /home/developers/devuser2"
    fi
    echo ""
    
        # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've successfully completed all objectives."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
        echo "Run with --solution to see detailed steps."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Export for progress tracking - THIS IS CRITICAL
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    # Return exit code based on score
    [ $score -eq $total ]
}

#############################################################################
# PHASE 5: Solution (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Create the webdevs group
─────────────────────────────────────────────────────────────────
Command:
  groupadd -g 5000 webdevs

Verification:
  getent group webdevs


STEP 2: Create devuser1
─────────────────────────────────────────────────────────────────
Command:
  useradd -u 5001 -g webdevs -d /home/developers/devuser1 -m -c "Alice Developer" devuser1

Verification:
  id devuser1
  ls -ld /home/developers/devuser1


STEP 3: Create devuser2
─────────────────────────────────────────────────────────────────
Command:
  useradd -u 5002 -g webdevs -d /home/developers/devuser2 -m devuser2

Verification:
  id devuser2
  ls -ld /home/developers/devuser2

EOF
}

#############################################################################
# Cleanup
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    userdel -r devuser1 2>/dev/null || true
    userdel -r devuser2 2>/dev/null || true
    groupdel webdevs 2>/dev/null || true
    rm -rf /home/developers 2>/dev/null || true
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"