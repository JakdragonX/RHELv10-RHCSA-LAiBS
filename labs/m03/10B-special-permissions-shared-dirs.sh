#!/bin/bash
# labs/m03/10B-special-permissions-shared-dirs.sh
# Lab: Special Permissions and Shared Group Directories
# Difficulty: Intermediate
# RHCSA Objective: 10.5-10.6 - Managing umask, SGID, and sticky bit for collaboration

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Special Permissions and Shared Group Directories"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous lab attempts
    userdel -r alice 2>/dev/null || true
    userdel -r bob 2>/dev/null || true
    userdel -r charlie 2>/dev/null || true
    groupdel devteam 2>/dev/null || true
    rm -rf /opt/shared 2>/dev/null || true
    rm -rf /tmp/team-workspace 2>/dev/null || true
    
    # Create test users
    useradd -m -s /bin/bash alice 2>/dev/null || true
    useradd -m -s /bin/bash bob 2>/dev/null || true
    useradd -m -s /bin/bash charlie 2>/dev/null || true
    
    # Create shared group
    groupadd devteam 2>/dev/null || true
    
    # Add users to shared group
    usermod -aG devteam alice 2>/dev/null
    usermod -aG devteam bob 2>/dev/null
    usermod -aG devteam charlie 2>/dev/null
    
    # Create directories
    mkdir -p /opt/shared 2>/dev/null || true
    mkdir -p /tmp/team-workspace 2>/dev/null || true
    
    # Set initial state (intentionally wrong for lab)
    chown root:root /opt/shared
    chmod 755 /opt/shared
    chown root:root /tmp/team-workspace
    chmod 777 /tmp/team-workspace
    
    echo "  ✓ Created test users: alice, bob, charlie"
    echo "  ✓ Created devteam group"
    echo "  ✓ Created directories: /opt/shared, /tmp/team-workspace"
    echo "  ✓ System ready for special permissions configuration"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of basic Linux permissions (rwx)
  • Familiarity with file ownership concepts
  • Understanding of groups and group collaboration

Commands You'll Use:
  • chmod - Change file permissions (including special permissions)
  • chown - Change file ownership
  • ls -ld - List directory details
  • stat - Show detailed file information
  • find - Search for files with specific permissions

Files You'll Interact With:
  • /opt/shared - Shared directory for team collaboration
  • /tmp/team-workspace - Temporary workspace with protection
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're setting up collaborative workspaces for a development team. Team members
need to share files in common directories, but you must prevent accidental
deletion of each other's files and ensure new files inherit proper group
ownership automatically.

LAB DIRECTORIES:
  • /opt/shared - Permanent shared directory (needs SGID)
  • /tmp/team-workspace - Temporary workspace (needs SGID + sticky bit)

BACKGROUND:
The development team (devteam group) needs two shared directories. In /opt/shared,
all files should automatically belong to the devteam group regardless of who
creates them. In /tmp/team-workspace, users should additionally be prevented
from deleting files they don't own, similar to the /tmp directory behavior.

OBJECTIVES:
  1. Configure /opt/shared for shared group access with SGID
     • Change group ownership to devteam
     • Set permissions: rwxrwxr-x (775)
     • Apply SGID (Set Group ID) so new files inherit group ownership
     • Final numeric permissions: 2775

  2. Configure /tmp/team-workspace with SGID and sticky bit
     • Change group ownership to devteam
     • Set permissions: rwxrwxrwt (1775)
     • Apply SGID so new files belong to devteam
     • Apply sticky bit so users can't delete others' files
     • Final numeric permissions: 3775

  3. Verify SGID is working in /opt/shared
     • Create a test file as root
     • Confirm it belongs to devteam group (not root group)
     • File should exist at: /opt/shared/test-sgid.txt

  4. Find all files with SUID permission on the system
     • Use find command to locate files with SUID bit set
     • Search from root directory (/)
     • Redirect errors to /dev/null
     • Save results to: /tmp/suid-files.txt

HINTS:
  • SGID on directories: chmod g+s or use 2 prefix (2775)
  • Sticky bit: chmod +t or use 1 prefix (1775)
  • Combined: use 3 prefix (3775 = SGID + sticky)
  • find with -perm /4000 finds SUID files
  • ls -ld shows directory permissions (not contents)

SUCCESS CRITERIA:
  • /opt/shared has 2775 permissions (SGID set)
  • /tmp/team-workspace has 3775 permissions (SGID + sticky)
  • New files in /opt/shared belong to devteam group
  • SUID files list saved to /tmp/suid-files.txt
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Set /opt/shared with SGID (2775, rwxrwsr-x)
  ☐ 2. Set /tmp/team-workspace with SGID+sticky (3775, rwxrwsr-t)
  ☐ 3. Create /opt/shared/test-sgid.txt and verify group ownership
  ☐ 4. Find SUID files and save list to /tmp/suid-files.txt
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "4"
}

scenario_context() {
    cat << 'EOF'
You're configuring shared directories for team collaboration. You'll use special
permissions (SGID and sticky bit) to ensure files inherit group ownership and
users can't delete each other's work.

Test users: alice, bob, charlie (all in devteam group)
Directories: /opt/shared, /tmp/team-workspace
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Configure /opt/shared with SGID for automatic group inheritance

The SGID (Set Group ID) permission on a directory ensures that new files created
inside inherit the directory's group ownership, not the creator's primary group.

What to do:
  • Change group ownership to: devteam
  • Set base permissions: 775 (rwxrwxr-x)
  • Add SGID: use 2 prefix or g+s flag
  • Final permissions: 2775

Tools available:
  • chgrp devteam - Change group ownership
  • chmod 2775 - Set permissions with SGID
  • ls -ld - Verify directory permissions

Numeric breakdown:
  • 2: SGID bit
  • 7: Owner rwx
  • 7: Group rwx
  • 5: Others r-x

Think about:
  • What does the 's' in rwxrwsr-x mean?
  • Why use SGID for shared directories?
  • What happens without SGID?

After completing: Verify with: ls -ld /opt/shared
Look for: drwxrwsr-x (the 's' indicates SGID)
EOF
}

validate_step_1() {
    local group=$(stat -c "%G" /opt/shared 2>/dev/null)
    local perms=$(stat -c "%a" /opt/shared 2>/dev/null)
    
    if [ "$group" != "devteam" ]; then
        echo ""
        print_color "$RED" "✗ /opt/shared group is not devteam"
        echo "  Try: sudo chgrp devteam /opt/shared"
        return 1
    fi
    
    if [ "$perms" != "2775" ]; then
        echo ""
        print_color "$RED" "✗ /opt/shared permissions: $perms (expected 2775)"
        echo "  Try: sudo chmod 2775 /opt/shared"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo chgrp devteam /opt/shared
  sudo chmod 2775 /opt/shared

Or combined:
  sudo chown :devteam /opt/shared
  sudo chmod g+s,u=rwx,g=rwx,o=rx /opt/shared

Explanation:
  • chgrp devteam: Sets group ownership to devteam
  • 2775: Special permission with SGID
    - 2: SGID bit (Set Group ID)
    - 7: Owner rwx (full access)
    - 7: Group rwx (full access for team)
    - 5: Others r-x (can list and enter)

Why this matters:
  Without SGID, new files would belong to the creator's primary group
  (usually their private group). With SGID, all files automatically
  belong to devteam, making collaboration seamless.

Verification:
  ls -ld /opt/shared
  # Should show: drwxrwsr-x ... devteam
  # Note the 's' in group position (rwxrwsr-x)
  
  stat /opt/shared
  # Access: (2775/drwxrwsr-x)

EOF
}

hint_step_2() {
    echo "  Use: sudo chmod 3775 /tmp/team-workspace"
    echo "  The 3 = 2(SGID) + 1(sticky)"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Configure /tmp/team-workspace with SGID and sticky bit

The sticky bit prevents users from deleting files they don't own, even if they
have write permission on the directory. Combined with SGID, this creates a safe
collaborative environment.

What to do:
  • Change group ownership to: devteam
  • Set base permissions: 775
  • Add both SGID (2) and sticky bit (1)
  • Final permissions: 3775 (3 = 2+1)

Numeric breakdown:
  • 3: SGID (2) + sticky bit (1)
  • 7: Owner rwx
  • 7: Group rwx
  • 5: Others r-x

Think about:
  • Why does /tmp have sticky bit?
  • What does the 't' in rwxrwxr-t mean?
  • Can you delete files you don't own with sticky bit?

After completing: Verify with: ls -ld /tmp/team-workspace
Look for: drwxrwsr-t (both 's' and 't')
EOF
}

validate_step_2() {
    local group=$(stat -c "%G" /tmp/team-workspace 2>/dev/null)
    local perms=$(stat -c "%a" /tmp/team-workspace 2>/dev/null)
    
    if [ "$group" != "devteam" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/team-workspace group is not devteam"
        echo "  Try: sudo chgrp devteam /tmp/team-workspace"
        return 1
    fi
    
    if [ "$perms" != "3775" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/team-workspace permissions: $perms (expected 3775)"
        echo "  Try: sudo chmod 3775 /tmp/team-workspace"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo chgrp devteam /tmp/team-workspace
  sudo chmod 3775 /tmp/team-workspace

Or using symbolic:
  sudo chmod g+s,o+t /tmp/team-workspace

Explanation:
  • 3775: Combined special permissions
    - 3: SGID (2) + sticky bit (1)
    - 7: Owner rwx
    - 7: Group rwx
    - 5: Others r-x

Special Permission Values:
  • 1: Sticky bit only
  • 2: SGID only
  • 3: SGID + sticky (2+1)
  • 4: SUID only
  • 5: SUID + sticky (4+1)
  • 6: SUID + SGID (4+2)
  • 7: All three (4+2+1)

Why this matters:
  Temporary workspaces need both features:
  - SGID ensures group ownership (for collaboration)
  - Sticky bit prevents accidental deletion (for safety)
  This is exactly how /tmp works system-wide!

Verification:
  ls -ld /tmp/team-workspace
  # Should show: drwxrwsr-t ... devteam
  # Note both 's' and 't'

EOF
}

hint_step_3() {
    echo "  Create file: sudo touch /opt/shared/test-sgid.txt"
    echo "  Check group: stat -c '%G' /opt/shared/test-sgid.txt"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Verify SGID is working by creating a test file

Create a file as root in the SGID directory and verify it inherits the
devteam group ownership instead of root's group.

What to do:
  • Create file: /opt/shared/test-sgid.txt
  • Check its group ownership
  • It should belong to devteam (not root)

Tools available:
  • touch - Create empty file
  • stat -c "%G" - Show group ownership
  • ls -l - Display permissions and ownership

Think about:
  • Normally, files created by root belong to which group?
  • What changed because of SGID?
  • Would this work without SGID?

After completing: Check with: ls -l /opt/shared/test-sgid.txt
The group should be devteam, not root!
EOF
}

validate_step_3() {
    if [ ! -f /opt/shared/test-sgid.txt ]; then
        echo ""
        print_color "$RED" "✗ File /opt/shared/test-sgid.txt does not exist"
        echo "  Try: sudo touch /opt/shared/test-sgid.txt"
        return 1
    fi
    
    local file_group=$(stat -c "%G" /opt/shared/test-sgid.txt 2>/dev/null)
    
    if [ "$file_group" != "devteam" ]; then
        echo ""
        print_color "$RED" "✗ File group is $file_group (expected devteam)"
        echo "  SGID might not be set correctly on /opt/shared"
        echo "  Try: sudo chmod 2775 /opt/shared"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo touch /opt/shared/test-sgid.txt

Verification:
  ls -l /opt/shared/test-sgid.txt
  # Expected: -rw-r--r-- root devteam ...
  #           ^^^^^^^^^^ ^^^^ ^^^^^^^
  #           perms      user group (inherited from directory!)
  
  stat -c "%U:%G" /opt/shared/test-sgid.txt
  # Expected: root:devteam (not root:root)

Why this works:
  Normally, files created by root would have:
    Owner: root
    Group: root (root's primary group)
  
  With SGID on the directory:
    Owner: root (still the creator)
    Group: devteam (inherited from directory, not creator!)
  
  This is the magic of SGID - new files automatically inherit the
  directory's group, making collaboration seamless.

EOF
}

hint_step_4() {
    echo "  Use: find / -perm /4000 -type f 2>/dev/null > /tmp/suid-files.txt"
    echo "  The /4000 matches any file with SUID bit set"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Find all files with SUID permission on the system

SUID (Set User ID) allows a file to run with the owner's permissions instead
of the executor's. This is powerful but dangerous. You'll locate all SUID files.

What to do:
  • Use find to search from root (/)
  • Look for files with SUID bit set (4000)
  • Only search regular files (-type f)
  • Redirect errors to /dev/null
  • Save results to: /tmp/suid-files.txt

Tools available:
  • find / -perm /4000 - Find files with SUID
  • 2>/dev/null - Hide permission denied errors
  • > file - Redirect output to file

Permission values:
  • /4000 - SUID bit set (matches 4xxx)
  • /2000 - SGID bit set
  • /1000 - Sticky bit set

Think about:
  • Why is SUID dangerous?
  • What legitimate programs use SUID?
  • How is SUID different from sudo?

After completing: Check results: wc -l /tmp/suid-files.txt
EOF
}

validate_step_4() {
    if [ ! -f /tmp/suid-files.txt ]; then
        echo ""
        print_color "$RED" "✗ File /tmp/suid-files.txt does not exist"
        echo "  Try: sudo find / -perm /4000 -type f 2>/dev/null > /tmp/suid-files.txt"
        return 1
    fi
    
    local line_count=$(wc -l < /tmp/suid-files.txt 2>/dev/null)
    
    if [ "$line_count" -lt 10 ]; then
        echo ""
        print_color "$RED" "✗ File has only $line_count lines (expected 10+)"
        echo "  Did you search from root (/) and include all filesystems?"
        echo "  Try: sudo find / -perm /4000 -type f 2>/dev/null > /tmp/suid-files.txt"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo find / -perm /4000 -type f 2>/dev/null > /tmp/suid-files.txt

Explanation:
  • find /: Search starting from root directory
  • -perm /4000: Find files with SUID bit (4 = SUID)
  • -type f: Only regular files (not directories)
  • 2>/dev/null: Suppress "Permission denied" errors
  • > /tmp/suid-files.txt: Save results to file

Permission bits:
  • 4000: SUID (Set User ID)
  • 2000: SGID (Set Group ID)
  • 1000: Sticky bit
  
  Use /4000 not -perm 4000:
  • /4000: Matches if SUID is set (4755, 4750, etc.)
  • 4000: Exact match only (rarely what you want)

Why this matters:
  SUID files run as their owner (often root), which is powerful but
  risky. System administrators should regularly audit SUID files for
  security purposes. Common legitimate SUID programs include:
  • /usr/bin/passwd (needs root to modify /etc/shadow)
  • /usr/bin/sudo (needs root to elevate privileges)
  • /usr/bin/ping (needs root for raw sockets)

Verification:
  wc -l /tmp/suid-files.txt
  # Typical system: 20-40 SUID files
  
  head /tmp/suid-files.txt
  # Sample output: /usr/bin/passwd, /usr/bin/sudo, etc.

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your special permissions configuration..."
    echo ""
    
    # CHECK 1: /opt/shared SGID
    print_color "$CYAN" "[1/$total] Checking /opt/shared SGID configuration..."
    local shared_perms=$(stat -c "%a" /opt/shared 2>/dev/null)
    local shared_group=$(stat -c "%G" /opt/shared 2>/dev/null)
    
    if [ "$shared_group" = "devteam" ] && [ "$shared_perms" = "2775" ]; then
        print_color "$GREEN" "  ✓ SGID set correctly (2775, group: devteam)"
        ((score++))
    else
        print_color "$RED" "  ✗ Configuration incorrect"
        echo "  Current: $shared_perms, group: $shared_group"
        echo "  Expected: 2775, group: devteam"
        print_color "$YELLOW" "  Fix: sudo chgrp devteam /opt/shared && sudo chmod 2775 /opt/shared"
    fi
    echo ""
    
    # CHECK 2: /tmp/team-workspace SGID + sticky
    print_color "$CYAN" "[2/$total] Checking /tmp/team-workspace SGID+sticky..."
    local workspace_perms=$(stat -c "%a" /tmp/team-workspace 2>/dev/null)
    local workspace_group=$(stat -c "%G" /tmp/team-workspace 2>/dev/null)
    
    if [ "$workspace_group" = "devteam" ] && [ "$workspace_perms" = "3775" ]; then
        print_color "$GREEN" "  ✓ SGID and sticky bit set correctly (3775)"
        ((score++))
    else
        print_color "$RED" "  ✗ Configuration incorrect"
        echo "  Current: $workspace_perms, group: $workspace_group"
        echo "  Expected: 3775, group: devteam"
        print_color "$YELLOW" "  Fix: sudo chgrp devteam /tmp/team-workspace && sudo chmod 3775 /tmp/team-workspace"
    fi
    echo ""
    
    # CHECK 3: SGID verification file
    print_color "$CYAN" "[3/$total] Checking SGID functionality test..."
    if [ -f /opt/shared/test-sgid.txt ]; then
        local test_group=$(stat -c "%G" /opt/shared/test-sgid.txt 2>/dev/null)
        if [ "$test_group" = "devteam" ]; then
            print_color "$GREEN" "  ✓ Test file exists and inherited devteam group"
            ((score++))
        else
            print_color "$RED" "  ✗ Test file exists but group is $test_group (not devteam)"
            print_color "$YELLOW" "  SGID might not be working. Check: ls -ld /opt/shared"
        fi
    else
        print_color "$RED" "  ✗ Test file /opt/shared/test-sgid.txt not found"
        print_color "$YELLOW" "  Create: sudo touch /opt/shared/test-sgid.txt"
    fi
    echo ""
    
    # CHECK 4: SUID files list
    print_color "$CYAN" "[4/$total] Checking SUID files search..."
    if [ -f /tmp/suid-files.txt ]; then
        local line_count=$(wc -l < /tmp/suid-files.txt 2>/dev/null)
        if [ "$line_count" -ge 10 ]; then
            print_color "$GREEN" "  ✓ SUID files found and saved ($line_count files)"
            ((score++))
        else
            print_color "$RED" "  ✗ File exists but only has $line_count entries"
            print_color "$YELLOW" "  Try: sudo find / -perm /4000 -type f 2>/dev/null > /tmp/suid-files.txt"
        fi
    else
        print_color "$RED" "  ✗ File /tmp/suid-files.txt not found"
        print_color "$YELLOW" "  Try: sudo find / -perm /4000 -type f 2>/dev/null > /tmp/suid-files.txt"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Configuring SGID for automatic group inheritance"
        echo "  • Using sticky bit to protect files from deletion"
        echo "  • Combining special permissions (SGID + sticky)"
        echo "  • Finding files with special permissions using find"
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

OBJECTIVE 1: Configure /opt/shared with SGID
─────────────────────────────────────────────────────────────────
Commands:
  sudo chgrp devteam /opt/shared
  sudo chmod 2775 /opt/shared

Explanation:
  • chgrp devteam: Sets group to devteam
  • 2775: Special permission with SGID
    - 2: SGID (Set Group ID)
    - 775: rwxrwxr-x base permissions

How SGID works:
  Without SGID: New files belong to creator's primary group
  With SGID: New files inherit directory's group (devteam)
  
  This makes collaboration seamless - everyone's files automatically
  belong to the shared group.

Verification:
  ls -ld /opt/shared
  # drwxrwsr-x ... devteam (note the 's')


OBJECTIVE 2: Configure workspace with SGID + sticky bit
─────────────────────────────────────────────────────────────────
Commands:
  sudo chgrp devteam /tmp/team-workspace
  sudo chmod 3775 /tmp/team-workspace

Explanation:
  • 3775: Combined special permissions
    - 3 = 2(SGID) + 1(sticky)
    - 775: rwxrwxr-x

Sticky bit behavior:
  • Users can only delete files they own
  • Even with write permission on directory
  • Prevents accidental deletion of others' work
  
  This is exactly how /tmp works!

Verification:
  ls -ld /tmp/team-workspace
  # drwxrwsr-t ... devteam (note 's' and 't')


OBJECTIVE 3: Verify SGID functionality
─────────────────────────────────────────────────────────────────
Command:
  sudo touch /opt/shared/test-sgid.txt

Expected result:
  ls -l /opt/shared/test-sgid.txt
  # -rw-r--r-- root devteam ...
  #            ^^^^ ^^^^^^^ (group inherited!)

Without SGID, it would show:
  # -rw-r--r-- root root ...


OBJECTIVE 4: Find SUID files
─────────────────────────────────────────────────────────────────
Command:
  sudo find / -perm /4000 -type f 2>/dev/null > /tmp/suid-files.txt

Explanation:
  • /: Search entire filesystem
  • -perm /4000: Files with SUID bit
  • -type f: Regular files only
  • 2>/dev/null: Hide permission errors
  • >: Save to file

Common SUID programs:
  • /usr/bin/passwd - Modify password database
  • /usr/bin/sudo - Elevate privileges
  • /usr/bin/su - Switch users
  • /usr/bin/mount - Mount filesystems

Verification:
  wc -l /tmp/suid-files.txt
  head -5 /tmp/suid-files.txt


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Special Permissions Overview:
  • SUID (4): Run as file owner (dangerous!)
  • SGID (2): 
    - Files: Run as file's group
    - Directories: New files inherit group
  • Sticky (1): Users can't delete others' files

Numeric values (first digit):
  • 0: No special permissions (normal)
  • 1: Sticky bit only
  • 2: SGID only
  • 3: SGID + Sticky
  • 4: SUID only
  • 5: SUID + Sticky
  • 6: SUID + SGID
  • 7: All three

Display in ls -l:
  • SUID: s in owner execute (rwsr-xr-x)
  • SGID: s in group execute (rwxr-sr-x)
  • Sticky: t in others execute (rwxr-xr-t)
  • Capital S or T: Bit set but no execute permission

When to use each:
  • SUID: Almost never (dangerous)
  • SGID: Shared group directories (common)
  • Sticky: Public writable directories (/tmp)

Shared Directory Best Practices:
  1. Create shared group (groupadd)
  2. Add users to group (usermod -aG)
  3. Set directory group (chgrp)
  4. Apply SGID (chmod 2775)
  5. Add sticky if needed (chmod 3775)


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting SGID on shared directories
  Result: New files belong to creator's primary group
  Fix: chmod 2775 /path/to/shared/dir
  Always use SGID for team collaboration!

Mistake 2: Setting SUID on directories
  Result: Ignored (SUID doesn't work on directories)
  Fix: Use SGID (2) instead of SUID (4)
  Only SGID and sticky work on directories

Mistake 3: Capital S or T in ls output
  Result: Special bit set but no execute permission
  Fix: Add execute: chmod +x or include in numeric (775 not 774)
  Example: rwSr-Sr-T (wrong) → rwsr-sr-t (correct)

Mistake 4: Using -perm 4000 instead of /4000 with find
  Result: Finds only exact 4000 (almost nothing)
  Fix: Use /4000 to match any file with SUID bit
  / means "any of these bits set"


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Shared directories need SGID (2) for group inheritance
2. /tmp-style directories need SGID (2) + sticky (1) = 3
3. Never use SUID (4) on new files - serious security risk
4. Use find / -perm /4000 to audit SUID files
5. Verify special permissions with: ls -ld (look for s and t)

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
    groupdel devteam 2>/dev/null || true
    rm -rf /opt/shared 2>/dev/null || true
    rm -rf /tmp/team-workspace 2>/dev/null || true
    rm -f /tmp/suid-files.txt 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
