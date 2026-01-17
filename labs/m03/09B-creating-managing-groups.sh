#!/bin/bash
# labs/m03/09B-creating-managing-groups.sh
# Lab: Creating and Managing Groups
# Difficulty: Beginner
# RHCSA Objective: 9.6-9.7 - Group creation, modification, and membership management

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Creating and Managing Groups"
LAB_DIFFICULTY="Beginner"
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
    userdel -r dave 2>/dev/null || true
    groupdel developers 2>/dev/null || true
    groupdel testers 2>/dev/null || true
    groupdel devops 2>/dev/null || true
    groupdel managers 2>/dev/null || true
    rm -rf /opt/grouptest 2>/dev/null || true
    
    # Create some test users
    useradd -m alice 2>/dev/null || true
    useradd -m bob 2>/dev/null || true
    useradd -m charlie 2>/dev/null || true
    useradd -m dave 2>/dev/null || true
    
    # Create test directory
    mkdir -p /opt/grouptest 2>/dev/null || true
    
    echo "  ✓ Created test users: alice, bob, charlie, dave"
    echo "  ✓ System ready for group management"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of user accounts
  • Understanding of primary vs secondary groups
  • Basic understanding of file permissions and group ownership

Commands You'll Use:
  • groupadd - Create new groups
  • groupmod - Modify existing groups
  • groupdel - Delete groups
  • usermod - Modify user group membership
  • gpasswd - Manage group membership and passwords
  • newgrp - Change current group ID during session
  • getent - Query group database
  • id - Show user's groups
  • groups - List groups a user belongs to

Files You'll Interact With:
  • /etc/group - Group account information
  • /etc/gshadow - Secure group account information
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're organizing your development team into different groups for better access
control. Developers need access to code repositories, testers need access to
testing environments, and some people need to be in multiple groups. You must
create groups, manage membership, and understand primary vs secondary groups.

BACKGROUND:
Linux uses groups to manage file permissions and organize users. Every user has
a primary group (stored in /etc/passwd) and can be a member of multiple secondary
groups (stored in /etc/group). Understanding group membership is crucial for
managing collaborative workspaces.

LAB DIRECTORY: /opt/grouptest
  (Used for testing group ownership)

OBJECTIVES:
  1. Create groups for the organization
     • Create group: developers (GID 3000)
     • Create group: testers (GID 3001)
     • Create group: devops (default GID)
     • Verify groups in /etc/group

  2. Add users to groups (secondary membership)
     • Add alice to developers group
     • Add bob to developers group
     • Add charlie to testers group
     • Add alice to devops group (she's in multiple groups!)
     • Use usermod -aG (append to groups)

  3. Verify group membership
     • Use id command to check alice's groups
     • Use groups command to list bob's groups
     • Use getent group developers to see all members
     • Create file as alice and check its group ownership

  4. Change primary group and test with newgrp
     • Change alice's primary group to developers
     • Use newgrp to temporarily switch bob's group context
     • Create files before and after newgrp to see difference
     • Test directory: /opt/grouptest

  5. Manage group with gpasswd
     • Add dave to developers using gpasswd
     • Remove charlie from testers using gpasswd
     • Create managers group and set administrators
     • Verify changes with getent

HINTS:
  • usermod -aG group user (append to group, keep existing)
  • usermod -G group user (replace all groups - dangerous!)
  • usermod -g group user (change primary group)
  • gpasswd -a user group (add user to group)
  • gpasswd -d user group (remove user from group)
  • id username shows UID, GID, and all groups
  • getent group groupname shows all members

SUCCESS CRITERIA:
  • developers group exists with GID 3000
  • testers group exists with GID 3001
  • alice is member of developers and devops
  • bob is member of developers
  • Group memberships verified with id and getent
  • Primary group changes tested and verified
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create groups: developers (3000), testers (3001), devops
  ☐ 2. Add users to groups: alice→developers,devops; bob→developers; charlie→testers
  ☐ 3. Verify membership with id, groups, and getent commands
  ☐ 4. Change alice's primary group to developers, test with newgrp
  ☐ 5. Use gpasswd to add dave to developers, remove charlie from testers
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
You're organizing your development team into groups. You'll create groups, add
users as members, and understand the difference between primary and secondary
group membership.

Test users: alice, bob, charlie, dave
Test directory: /opt/grouptest
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Create groups for the organization

Groups organize users and control access to resources. You'll create three groups
with specific GIDs for the developers and testers, and a default GID for devops.

What to do:
  • Create group: developers with GID 3000
  • Create group: testers with GID 3001
  • Create group: devops (let system assign GID)

Tools available:
  • groupadd - Create groups
  • groupadd -g GID - Create with specific GID
  • getent group - Query group database

Format:
  sudo groupadd -g 3000 developers
  sudo groupadd -g 3001 testers
  sudo groupadd devops

Think about:
  • Why specify a GID?
  • What's the difference between system and regular groups?
  • Where are groups stored?

After completing: Verify with: getent group developers testers devops
EOF
}

validate_step_1() {
    # Check developers with GID 3000
    if ! getent group developers >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Group developers does not exist"
        echo "  Try: sudo groupadd -g 3000 developers"
        return 1
    fi
    
    local dev_gid=$(getent group developers | cut -d: -f3)
    if [ "$dev_gid" != "3000" ]; then
        echo ""
        print_color "$RED" "✗ developers GID is $dev_gid (expected 3000)"
        echo "  Try: sudo groupdel developers; sudo groupadd -g 3000 developers"
        return 1
    fi
    
    # Check testers with GID 3001
    if ! getent group testers >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Group testers does not exist"
        echo "  Try: sudo groupadd -g 3001 testers"
        return 1
    fi
    
    local test_gid=$(getent group testers | cut -d: -f3)
    if [ "$test_gid" != "3001" ]; then
        echo ""
        print_color "$RED" "✗ testers GID is $test_gid (expected 3001)"
        return 1
    fi
    
    # Check devops exists
    if ! getent group devops >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Group devops does not exist"
        echo "  Try: sudo groupadd devops"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo groupadd -g 3000 developers
  sudo groupadd -g 3001 testers
  sudo groupadd devops

Explanation:
  • groupadd: Command to create groups
  • -g 3000: Specify GID 3000
  • Group name: developers, testers, devops

Why specify GID?
  • Consistency across multiple systems
  • Avoid conflicts with existing groups
  • Required for some NFS configurations
  • Makes system administration easier

/etc/group format:
  groupname:x:GID:member_list
  
  Example:
  developers:x:3000:alice,bob

Verification:
  getent group developers
  # Should show: developers:x:3000:
  
  getent group testers
  # Should show: testers:x:3001:
  
  getent group devops
  # Should show: devops:x:####: (system-assigned GID)

EOF
}

hint_step_2() {
    echo "  Use: sudo usermod -aG developers alice"
    echo "  Remember -aG (append) not -G (replace)!"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Add users to groups as secondary members

Secondary groups allow users to access resources shared by the group. Users can
be members of multiple secondary groups, but only one primary group.

What to do:
  • Add alice to developers
  • Add bob to developers
  • Add charlie to testers
  • Add alice to devops (yes, she's in multiple groups!)

Tools available:
  • usermod -aG group user - Append user to group
  • getent group - Verify group membership

Format:
  sudo usermod -aG developers alice
  sudo usermod -aG developers bob
  sudo usermod -aG testers charlie
  sudo usermod -aG devops alice

CRITICAL:
  Use -aG (append), NOT -G (replace)!
  -G alone removes user from other groups

Think about:
  • What's the difference between -aG and -G?
  • Can a user be in multiple groups?
  • What's the difference between primary and secondary groups?

After completing: Check with: id alice
EOF
}

validate_step_2() {
    # Check alice in developers and devops
    if ! id alice 2>/dev/null | grep -q "developers"; then
        echo ""
        print_color "$RED" "✗ alice is not in developers group"
        echo "  Try: sudo usermod -aG developers alice"
        return 1
    fi
    
    if ! id alice 2>/dev/null | grep -q "devops"; then
        echo ""
        print_color "$RED" "✗ alice is not in devops group"
        echo "  Try: sudo usermod -aG devops alice"
        return 1
    fi
    
    # Check bob in developers
    if ! id bob 2>/dev/null | grep -q "developers"; then
        echo ""
        print_color "$RED" "✗ bob is not in developers group"
        echo "  Try: sudo usermod -aG developers bob"
        return 1
    fi
    
    # Check charlie in testers
    if ! id charlie 2>/dev/null | grep -q "testers"; then
        echo ""
        print_color "$RED" "✗ charlie is not in testers group"
        echo "  Try: sudo usermod -aG testers charlie"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo usermod -aG developers alice
  sudo usermod -aG developers bob
  sudo usermod -aG testers charlie
  sudo usermod -aG devops alice

Explanation:
  • usermod: Modify user account
  • -a: Append (keep existing groups)
  • -G: Supplementary groups
  • -aG: Append to supplementary groups

CRITICAL DIFFERENCE:
  usermod -aG group user  ← Adds to group (safe)
  usermod -G group user   ← Replaces all groups (dangerous!)

Example of the danger:
  # alice is in: developers, devops
  sudo usermod -G testers alice
  # Now alice is ONLY in: testers
  # Lost developers and devops membership!

Always use -aG to append safely!

Primary vs Secondary Groups:
  Primary group:
  • One per user
  • Set in /etc/passwd
  • Used for new files
  • Changed with: usermod -g
  
  Secondary groups:
  • Multiple allowed
  • Set in /etc/group
  • Additional permissions
  • Changed with: usermod -aG

Verification:
  id alice
  # Should show groups: alice developers devops
  
  getent group developers
  # Should show: developers:x:3000:alice,bob

EOF
}

hint_step_3() {
    echo "  Use: id alice"
    echo "  Use: groups bob"
    echo "  Use: getent group developers"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Verify group membership with multiple commands

Different commands show group information in different ways. Learn when to use
each command for querying group membership.

What to do:
  • Use id alice to see all groups
  • Use groups bob to list group names
  • Use getent group developers to see all members
  • Create a file as alice to test group ownership

Tools available:
  • id username - Shows UID, GID, all groups
  • groups username - Lists group names only
  • getent group groupname - Shows group info and members

Test:
  sudo -u alice touch /opt/grouptest/alice-test.txt
  ls -l /opt/grouptest/alice-test.txt

Think about:
  • Which command is most detailed?
  • How do you see all members of a group?
  • What group owns files created by alice?

After completing: Compare output from different commands
EOF
}

validate_step_3() {
    # Check if commands work
    if ! id alice >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Cannot query alice's groups"
        return 1
    fi
    
    if ! groups bob >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Cannot list bob's groups"
        return 1
    fi
    
    # Optional: check if test file was created
    if [ ! -f /opt/grouptest/alice-test.txt ]; then
        echo ""
        print_color "$YELLOW" "  Note: Test file not created (optional)"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  id alice
  groups bob
  getent group developers
  sudo -u alice touch /opt/grouptest/alice-test.txt
  ls -l /opt/grouptest/alice-test.txt

Sample Output:

1. id alice:
   uid=1001(alice) gid=1001(alice) groups=1001(alice),3000(developers),1004(devops)
   
   Shows: UID, primary GID, all group memberships

2. groups bob:
   bob : bob developers
   
   Shows: Just group names (simpler output)

3. getent group developers:
   developers:x:3000:alice,bob
   
   Shows: Group info and all members

4. File ownership test:
   -rw-r--r-- 1 alice alice 0 Jan 17 10:00 alice-test.txt
   
   File owned by alice user and alice group (primary group)

Command Comparison:
  id:
  • Most comprehensive
  • Shows numeric IDs and names
  • Best for troubleshooting
  
  groups:
  • Simple list of groups
  • Easy to read
  • Good for quick checks
  
  getent group:
  • Shows all group members
  • View from group perspective
  • Good for auditing

Why does alice's file belong to alice group?
  Because alice's PRIMARY group is alice (her private group).
  New files belong to the user's primary group, not secondary groups.

EOF
}

hint_step_4() {
    echo "  Change primary: sudo usermod -g developers alice"
    echo "  Test newgrp: newgrp developers (as bob)"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Change primary group and test with newgrp

The primary group determines default group ownership for new files. You can
change it permanently (usermod) or temporarily (newgrp).

What to do:
  • Change alice's primary group to developers permanently
  • Test by creating a file as alice
  • Use newgrp to temporarily change bob's group context

Tools available:
  • usermod -g group user - Change primary group permanently
  • newgrp group - Start new shell with different primary group
  • id - Verify current group context

Test sequence:
  1. Change alice's primary group to developers
  2. Create file: sudo -u alice touch /opt/grouptest/alice-new.txt
  3. Check ownership: ls -l /opt/grouptest/alice-new.txt
  4. File should now belong to developers group!

Think about:
  • What's the difference between primary and secondary groups?
  • When would you use newgrp vs usermod?
  • How can you tell which is your primary group?

After completing: Verify with: id alice | grep -o "gid=[0-9]*([^)]*)"
EOF
}

validate_step_4() {
    # Check if alice's primary group is developers
    local alice_primary=$(id -gn alice 2>/dev/null)
    
    if [ "$alice_primary" != "developers" ]; then
        echo ""
        print_color "$RED" "✗ alice's primary group is $alice_primary (expected developers)"
        echo "  Try: sudo usermod -g developers alice"
        return 1
    fi
    
    # Check if test file exists with correct group
    if [ -f /opt/grouptest/alice-new.txt ]; then
        local file_group=$(stat -c "%G" /opt/grouptest/alice-new.txt 2>/dev/null)
        if [ "$file_group" != "developers" ]; then
            echo ""
            print_color "$YELLOW" "  Note: Test file has group $file_group (expected developers)"
        fi
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo usermod -g developers alice
  sudo -u alice touch /opt/grouptest/alice-new.txt
  ls -l /opt/grouptest/alice-new.txt

Explanation:
  • usermod -g: Changes primary group permanently
  • -g: Primary group (lowercase g)
  • -G: Secondary groups (uppercase G)

Primary Group Change Effect:
  BEFORE (primary group = alice):
  -rw-r--r-- 1 alice alice    0 alice-test.txt
  
  AFTER (primary group = developers):
  -rw-r--r-- 1 alice developers 0 alice-new.txt

Verification:
  id alice
  # Now shows: gid=3000(developers)
  
  getent passwd alice
  # Fourth field is now 3000 (developers GID)

Using newgrp (temporary change):
  # As bob (primary group: bob)
  touch /tmp/before.txt
  ls -l /tmp/before.txt
  # Shows: bob bob
  
  newgrp developers
  # Now in new shell with developers as primary group
  
  touch /tmp/after.txt
  ls -l /tmp/after.txt
  # Shows: bob developers
  
  exit  # Exit newgrp shell
  # Back to original primary group

When to use:
  usermod -g: Permanent change for user
  newgrp: Temporary change for current session

EOF
}

hint_step_5() {
    echo "  Add user: sudo gpasswd -a dave developers"
    echo "  Remove user: sudo gpasswd -d charlie testers"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Manage groups with gpasswd

gpasswd is an alternative to usermod for managing group membership. It's especially
useful for group administrators and batch operations.

What to do:
  • Add dave to developers group using gpasswd
  • Remove charlie from testers group using gpasswd
  • Create managers group
  • Verify all changes with getent

Tools available:
  • gpasswd -a user group - Add user to group
  • gpasswd -d user group - Remove user from group
  • gpasswd -A user group - Set group administrators
  • getent group - Verify changes

Format:
  sudo gpasswd -a dave developers
  sudo gpasswd -d charlie testers
  sudo groupadd managers

Think about:
  • What's the difference between gpasswd and usermod?
  • Can you remove a user from their primary group?
  • What's a group administrator?

After completing: Verify with: getent group developers testers
EOF
}

validate_step_5() {
    # Check dave in developers
    if ! getent group developers | grep -q "dave"; then
        echo ""
        print_color "$RED" "✗ dave is not in developers group"
        echo "  Try: sudo gpasswd -a dave developers"
        return 1
    fi
    
    # Check charlie NOT in testers
    if getent group testers | grep -q "charlie"; then
        echo ""
        print_color "$RED" "✗ charlie is still in testers group"
        echo "  Try: sudo gpasswd -d charlie testers"
        return 1
    fi
    
    # Check managers group exists
    if ! getent group managers >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ managers group does not exist"
        echo "  Try: sudo groupadd managers"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo gpasswd -a dave developers
  sudo gpasswd -d charlie testers
  sudo groupadd managers

Explanation:
  • gpasswd -a: Add user to group
  • gpasswd -d: Delete user from group
  • groupadd: Create new group

gpasswd vs usermod:
  gpasswd:
  • Simpler syntax for single group operations
  • Can set group administrators
  • Better for scripting (one user, one group)
  • Immediate operation
  
  usermod:
  • Can modify multiple groups at once
  • More versatile (change shell, home, etc.)
  • Better for complex user modifications
  • -aG syntax (append to groups)

Verification:
  getent group developers
  # Should show: developers:x:3000:alice,bob,dave
  
  getent group testers
  # Should NOT show charlie
  
  id dave
  # Should include developers group

Group Administrators:
  sudo gpasswd -A alice developers
  # Makes alice an administrator of developers group
  # Alice can add/remove members without sudo

Useful gpasswd commands:
  gpasswd -a user group   # Add user
  gpasswd -d user group   # Remove user
  gpasswd -A user group   # Set admin
  gpasswd -M user1,user2 group  # Set members list

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your group configuration..."
    echo ""
    
    # CHECK 1: Groups created with correct GIDs
    print_color "$CYAN" "[1/$total] Checking group creation..."
    local dev_gid=$(getent group developers 2>/dev/null | cut -d: -f3)
    local test_gid=$(getent group testers 2>/dev/null | cut -d: -f3)
    
    if [ "$dev_gid" = "3000" ] && [ "$test_gid" = "3001" ] && \
       getent group devops >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ All groups created with correct GIDs"
        ((score++))
    else
        print_color "$RED" "  ✗ Groups not configured correctly"
        print_color "$YELLOW" "  Fix: sudo groupadd -g 3000 developers; sudo groupadd -g 3001 testers"
    fi
    echo ""
    
    # CHECK 2: User group membership
    print_color "$CYAN" "[2/$total] Checking user group memberships..."
    local membership_ok=true
    
    if ! id alice 2>/dev/null | grep -q "developers"; then
        print_color "$RED" "  ✗ alice not in developers"
        membership_ok=false
    fi
    
    if ! id alice 2>/dev/null | grep -q "devops"; then
        print_color "$RED" "  ✗ alice not in devops"
        membership_ok=false
    fi
    
    if ! id bob 2>/dev/null | grep -q "developers"; then
        print_color "$RED" "  ✗ bob not in developers"
        membership_ok=false
    fi
    
    if ! id charlie 2>/dev/null | grep -q "testers"; then
        print_color "$RED" "  ✗ charlie not in testers"
        membership_ok=false
    fi
    
    if [ "$membership_ok" = true ]; then
        print_color "$GREEN" "  ✓ All users added to correct groups"
        ((score++))
    else
        print_color "$YELLOW" "  Fix: sudo usermod -aG groupname username"
    fi
    echo ""
    
    # CHECK 3: Verification commands work
    print_color "$CYAN" "[3/$total] Checking group query commands..."
    if id alice >/dev/null 2>&1 && \
       groups bob >/dev/null 2>&1 && \
       getent group developers >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Group verification commands working"
        ((score++))
    else
        print_color "$RED" "  ✗ Cannot query group information"
    fi
    echo ""
    
    # CHECK 4: Primary group change
    print_color "$CYAN" "[4/$total] Checking alice's primary group..."
    local alice_primary=$(id -gn alice 2>/dev/null)
    
    if [ "$alice_primary" = "developers" ]; then
        print_color "$GREEN" "  ✓ alice's primary group is developers"
        ((score++))
    else
        print_color "$RED" "  ✗ alice's primary group is $alice_primary (expected developers)"
        print_color "$YELLOW" "  Fix: sudo usermod -g developers alice"
    fi
    echo ""
    
    # CHECK 5: gpasswd operations
    print_color "$CYAN" "[5/$total] Checking gpasswd group management..."
    local gpasswd_ok=true
    
    if ! getent group developers | grep -q "dave"; then
        print_color "$RED" "  ✗ dave not in developers"
        gpasswd_ok=false
    fi
    
    if getent group testers | grep -q "charlie"; then
        print_color "$RED" "  ✗ charlie still in testers"
        gpasswd_ok=false
    fi
    
    if ! getent group managers >/dev/null 2>&1; then
        print_color "$RED" "  ✗ managers group doesn't exist"
        gpasswd_ok=false
    fi
    
    if [ "$gpasswd_ok" = true ]; then
        print_color "$GREEN" "  ✓ gpasswd operations completed correctly"
        ((score++))
    else
        print_color "$YELLOW" "  Fix: Use gpasswd -a/-d to add/remove users"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Creating groups with specific GIDs"
        echo "  • Adding users to secondary groups"
        echo "  • Verifying group membership with multiple commands"
        echo "  • Changing primary groups"
        echo "  • Managing groups with gpasswd"
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

OBJECTIVE 1: Create groups
─────────────────────────────────────────────────────────────────
Commands:
  sudo groupadd -g 3000 developers
  sudo groupadd -g 3001 testers
  sudo groupadd devops

Verification:
  getent group developers testers devops


OBJECTIVE 2: Add users to groups
─────────────────────────────────────────────────────────────────
Commands:
  sudo usermod -aG developers alice
  sudo usermod -aG developers bob
  sudo usermod -aG testers charlie
  sudo usermod -aG devops alice

Verification:
  id alice
  id bob
  getent group developers


OBJECTIVE 3: Verify group membership
─────────────────────────────────────────────────────────────────
Commands:
  id alice
  groups bob
  getent group developers
  sudo -u alice touch /opt/grouptest/alice-test.txt
  ls -l /opt/grouptest/alice-test.txt


OBJECTIVE 4: Change primary group
─────────────────────────────────────────────────────────────────
Commands:
  sudo usermod -g developers alice
  sudo -u alice touch /opt/grouptest/alice-new.txt
  ls -l /opt/grouptest/alice-new.txt

Verification:
  id alice | grep "gid="


OBJECTIVE 5: Manage with gpasswd
─────────────────────────────────────────────────────────────────
Commands:
  sudo gpasswd -a dave developers
  sudo gpasswd -d charlie testers
  sudo groupadd managers

Verification:
  getent group developers
  getent group testers


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/etc/group Structure:
  groupname:x:GID:member_list
  
  Example:
  developers:x:3000:alice,bob,dave

Primary vs Secondary Groups:
  Primary Group:
  • One per user
  • Stored in /etc/passwd (4th field)
  • Default group for new files
  • Changed with: usermod -g
  • Shown in id output as gid=
  
  Secondary Groups:
  • Multiple allowed
  • Stored in /etc/group
  • Additional access permissions
  • Changed with: usermod -aG
  • Shown in id output as groups=

User Private Groups (UPG):
  By default, each user gets a private group:
  • Same name as username
  • GID typically equals UID
  • Only contains that user
  • Improves security (no shared primary group)

Group Membership Changes:
  usermod -aG: Append (safe, keeps existing groups)
  usermod -G: Replace (dangerous, loses other groups)
  usermod -g: Change primary group
  gpasswd -a: Add to group (alternative to usermod)
  gpasswd -d: Remove from group

Commands Comparison:
  id username:
  • Most detailed
  • Shows UID, GID, all groups
  • Numeric and text format
  
  groups username:
  • Simple list
  • Just group names
  • Quick reference
  
  getent group groupname:
  • Group perspective
  • Shows all members
  • Good for auditing


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using -G instead of -aG
  Result: Removes user from all other groups
  Wrong: sudo usermod -G developers alice
  Right: sudo usermod -aG developers alice

Mistake 2: Trying to remove primary group
  Result: Error - cannot remove primary group
  Fix: Change primary group first, then remove from secondary
  Example:
    sudo usermod -g alice alice  # Set primary back to alice
    sudo gpasswd -d alice developers  # Now can remove

Mistake 3: Forgetting to log out/in after group changes
  Result: User still shows old groups
  Fix: Log out and back in, or use newgrp
  Group changes don't apply to current shell

Mistake 4: Using wrong command to view group members
  id alice → Shows alice's groups (user perspective)
  getent group developers → Shows group members (group perspective)

EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always use -aG, never just -G (will lose other groups)
2. Primary group: usermod -g (lowercase)
3. Secondary groups: usermod -aG (uppercase with append)
4. Use getent group to see all members of a group
5. Use id to see all groups for a user
6. gpasswd -a/-d is alternative to usermod for single operations

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
    userdel -r dave 2>/dev/null || true
    groupdel developers 2>/dev/null || true
    groupdel testers 2>/dev/null || true
    groupdel devops 2>/dev/null || true
    groupdel managers 2>/dev/null || true
    rm -rf /opt/grouptest 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
