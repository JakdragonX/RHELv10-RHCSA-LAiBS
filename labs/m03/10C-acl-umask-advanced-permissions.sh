#!/bin/bash
# labs/m03/10C-acl-umask-advanced-permissions.sh
# Lab: ACLs, umask, and Advanced Permission Management
# Difficulty: Intermediate
# RHCSA Objective: 10.5 + ACLs - Managing default permissions and granular access control

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="ACLs, umask, and Advanced Permission Management"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="35-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous lab attempts
    userdel -r alice 2>/dev/null || true
    userdel -r bob 2>/dev/null || true
    userdel -r charlie 2>/dev/null || true
    userdel -r david 2>/dev/null || true
    groupdel research 2>/dev/null || true
    groupdel analysts 2>/dev/null || true
    rm -rf /opt/research 2>/dev/null || true
    rm -rf /tmp/acl-test 2>/dev/null || true
    
    # Create test users
    useradd -m -s /bin/bash alice 2>/dev/null || true
    useradd -m -s /bin/bash bob 2>/dev/null || true
    useradd -m -s /bin/bash charlie 2>/dev/null || true
    useradd -m -s /bin/bash david 2>/dev/null || true
    
    # Create groups
    groupadd research 2>/dev/null || true
    groupadd analysts 2>/dev/null || true
    
    # Add users to groups
    usermod -aG research alice 2>/dev/null
    usermod -aG research bob 2>/dev/null
    usermod -aG analysts charlie 2>/dev/null
    
    # Create directory structure
    mkdir -p /opt/research/{data,reports,archive} 2>/dev/null || true
    mkdir -p /tmp/acl-test 2>/dev/null || true
    
    # Create test files
    echo "Research Data" > /opt/research/data/dataset1.csv
    echo "Report Draft" > /opt/research/reports/report1.txt
    echo "Old Data" > /opt/research/archive/legacy.dat
    
    # Set basic ownership
    chown -R root:research /opt/research
    chmod -R 770 /opt/research
    chmod 755 /opt/research  # Make directory itself accessible
    
    # Create a file with wrong umask for demonstration
    echo "Test file" > /tmp/acl-test/testfile.txt
    chmod 644 /tmp/acl-test/testfile.txt
    
    echo "  ✓ Created test users: alice, bob, charlie, david"
    echo "  ✓ Created groups: research, analysts"
    echo "  ✓ Created directory structure: /opt/research"
    echo "  ✓ System ready for ACL and umask configuration"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of basic Linux permissions (UGO)
  • Familiarity with file ownership concepts
  • Understanding of groups and collaboration

Commands You'll Use:
  • setfacl - Set file access control lists
  • getfacl - Display file access control lists
  • umask - Set default permission mask
  • chmod - Change permissions (symbolic and numeric modes)
  • ls -l - Display file permissions with ACL indicator (+)

Files You'll Interact With:
  • /opt/research/ - Research directory with ACL requirements
  • /etc/bashrc - System-wide bash configuration (view only)
  • ~/.bashrc - User-specific bash configuration
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're managing a research department's file system. The research team needs
shared access to data, but some external analysts need special access to specific
files without being full team members. You must use ACLs to provide granular
access control beyond standard Unix permissions.

LAB DIRECTORY: /opt/research
  (Contains data/, reports/, and archive/ subdirectories)

BACKGROUND:
Alice and Bob are in the research group and need full access. Charlie is an
external analyst who needs read-only access to the reports directory. David
should have no access except to ONE specific file. Standard Unix permissions
can't handle this complexity - you need ACLs (Access Control Lists).

OBJECTIVES:
  1. Grant charlie read and execute access to /opt/research/reports using ACL
     • Use setfacl to add ACL entry for user charlie
     • Permissions: read (r) and execute (x) only
     • Do not add charlie to any groups
     • Verify with getfacl and check for + indicator

  2. Grant david read-only access to /opt/research/data/dataset1.csv only
     • Use ACL to give david read permission (r) to this specific file
     • David should not have access to the directory or other files
     • Verify the ACL with getfacl

  3. Set default ACLs on /opt/research/reports directory
     • New files should automatically give charlie r-x permissions
     • Use default ACL (-d flag) so it applies to future files
     • Create a test file to verify inheritance
     • Test file: /opt/research/reports/test-acl.txt

  4. Configure umask for secure file creation
     • Set umask to 027 for the current session
     • This means new files: 640 (rw-r-----)
     • New directories: 750 (rwxr-x---)
     • Create test file /tmp/umask-test.txt to verify
     • Create test directory /tmp/umask-testdir to verify

  5. Use symbolic chmod to fix mixed permissions
     • File /opt/research/archive/legacy.dat has wrong permissions
     • Requirements:
       - Owner: add execute permission (u+x)
       - Group: remove write permission (g-w)
       - Others: set to no permissions (o=)
     • Use symbolic mode, not numeric
     • Final result should be: rwxr-----

HINTS:
  • ACL syntax: setfacl -m u:username:permissions file
  • Default ACL: setfacl -d -m u:username:permissions directory
  • The + after permissions in ls -l indicates ACL is present
  • umask 027 = 777-027=750 for dirs, 666-027=640 for files
  • Symbolic chmod: u+x (add), g-w (remove), o= (set exact)
  • Check ACLs with: getfacl filename

SUCCESS CRITERIA:
  • charlie has r-x ACL on /opt/research/reports
  • david has r ACL on dataset1.csv
  • Default ACL set on reports/ (verify with new file)
  • umask set to 027 (verify with new files/dirs)
  • legacy.dat has rwxr----- permissions via symbolic chmod
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Grant charlie r-x ACL on /opt/research/reports
  ☐ 2. Grant david r ACL on /opt/research/data/dataset1.csv
  ☐ 3. Set default ACL on reports/ for charlie (r-x)
  ☐ 4. Set umask to 027 and verify with test files
  ☐ 5. Fix /opt/research/archive/legacy.dat with symbolic chmod (rwxr-----)
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
You're configuring granular file access for a research team. Standard Unix
permissions aren't flexible enough, so you'll use ACLs to grant specific users
access without adding them to groups. You'll also configure umask for secure
default permissions.

Test users: alice, bob (research group), charlie, david (external)
Directory: /opt/research
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Grant charlie read and execute access using ACL

Charlie is an external analyst who needs to access the reports directory but
shouldn't be a full member of the research group. ACLs let you grant access
to specific users without modifying groups.

What to do:
  • Target: /opt/research/reports directory
  • User: charlie
  • Permissions: read and execute (r-x)
  • Use: setfacl command

Tools available:
  • setfacl -m u:username:perms file - Modify ACL
  • getfacl file - View ACLs
  • ls -l - Check for + indicator

Format:
  sudo setfacl -m u:charlie:r-x /opt/research/reports

Think about:
  • Why use ACL instead of adding charlie to research group?
  • What does the + after permissions mean?
  • How is this different from chmod?

After completing: Verify with getfacl /opt/research/reports
EOF
}

validate_step_1() {
    # Check if ACL exists for charlie
    if ! getfacl /opt/research/reports 2>/dev/null | grep -q "user:charlie:r-x"; then
        echo ""
        print_color "$RED" "✗ ACL for charlie not found or incorrect"
        echo "  Try: sudo setfacl -m u:charlie:r-x /opt/research/reports"
        return 1
    fi
    
    # Check for + indicator
    if ! ls -ld /opt/research/reports 2>/dev/null | grep -q "+"; then
        echo ""
        print_color "$RED" "✗ ACL not visible (no + indicator)"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo setfacl -m u:charlie:r-x /opt/research/reports

Explanation:
  • setfacl: Set file ACL command
  • -m: Modify ACL (add or change entry)
  • u:charlie:r-x: User charlie gets read and execute
  • /opt/research/reports: Target directory

Why this works:
  ACLs provide permissions beyond the standard UGO model. You can grant
  specific users or groups access without modifying the file's ownership
  or standard permissions. This is perfect for external collaborators.

Verification:
  getfacl /opt/research/reports
  # Should show:
  # user::rwx
  # user:charlie:r-x
  # group::rwx
  # ...
  
  ls -ld /opt/research/reports
  # Should show + after permissions: drwxrwx---+

EOF
}

hint_step_2() {
    echo "  Use: sudo setfacl -m u:david:r /opt/research/data/dataset1.csv"
    echo "  Only read (r) permission, not execute!"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Grant david read-only access to a specific file

David needs to read ONE specific dataset but shouldn't have access to anything
else. ACLs let you set permissions on individual files, not just directories.

What to do:
  • Target: /opt/research/data/dataset1.csv
  • User: david
  • Permission: read only (r)
  • No execute or write access

Format:
  sudo setfacl -m u:david:r /opt/research/data/dataset1.csv

Think about:
  • Why no execute permission on a data file?
  • Can david access other files in /opt/research/data/?
  • What happens if someone creates a new file in that directory?

After completing: Check with getfacl /opt/research/data/dataset1.csv
EOF
}

validate_step_2() {
    if ! getfacl /opt/research/data/dataset1.csv 2>/dev/null | grep -q "user:david:r--"; then
        echo ""
        print_color "$RED" "✗ ACL for david not found or incorrect on dataset1.csv"
        echo "  Try: sudo setfacl -m u:david:r /opt/research/data/dataset1.csv"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo setfacl -m u:david:r /opt/research/data/dataset1.csv

Explanation:
  • u:david:r: User david gets read-only permission
  • No execute needed for data files
  • ACL applies only to this specific file

Why read-only:
  Data files (CSV, DAT, etc.) don't need execute permission. Execute is
  only for scripts and directories. Read permission lets david view and
  copy the file contents but not modify them.

Verification:
  getfacl /opt/research/data/dataset1.csv
  # Should show user:david:r--
  
  ls -l /opt/research/data/dataset1.csv
  # Should show + indicator

EOF
}

hint_step_3() {
    echo "  Use -d flag for default ACL: sudo setfacl -d -m u:charlie:r-x /opt/research/reports"
    echo "  Then create test file: sudo touch /opt/research/reports/test-acl.txt"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Set default ACL so new files automatically inherit permissions

Default ACLs ensure that any new files created in a directory automatically
get specific ACL permissions. This is crucial for collaborative directories.

What to do:
  • Set default ACL on: /opt/research/reports
  • For user: charlie
  • Permissions: r-x
  • Use -d (default) flag
  • Create test file to verify: /opt/research/reports/test-acl.txt

Tools available:
  • setfacl -d -m - Set default ACL
  • touch - Create test file
  • getfacl - View both regular and default ACLs

Think about:
  • What's the difference between regular and default ACL?
  • Do existing files get the default ACL?
  • What happens to new files without default ACL?

After completing: Create test file and check its ACL with getfacl
EOF
}

validate_step_3() {
    # Check if default ACL is set
    if ! getfacl /opt/research/reports 2>/dev/null | grep -q "default:user:charlie:r-x"; then
        echo ""
        print_color "$RED" "✗ Default ACL for charlie not found"
        echo "  Try: sudo setfacl -d -m u:charlie:r-x /opt/research/reports"
        return 1
    fi
    
    # Check if test file exists and has inherited ACL
    if [ ! -f /opt/research/reports/test-acl.txt ]; then
        echo ""
        print_color "$RED" "✗ Test file /opt/research/reports/test-acl.txt not found"
        echo "  Create with: sudo touch /opt/research/reports/test-acl.txt"
        return 1
    fi
    
    if ! getfacl /opt/research/reports/test-acl.txt 2>/dev/null | grep -q "user:charlie:r-x"; then
        echo ""
        print_color "$RED" "✗ Test file doesn't have inherited ACL"
        echo "  Default ACL may not be set correctly"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo setfacl -d -m u:charlie:r-x /opt/research/reports
  sudo touch /opt/research/reports/test-acl.txt

Explanation:
  • -d: Set default ACL (for future files)
  • Default ACLs don't affect existing files
  • New files automatically inherit the default ACL

How it works:
  1. Default ACL is set on directory
  2. Any new file created inherits those ACLs
  3. Existing files are NOT affected
  4. This ensures consistent permissions for collaboration

Verification:
  getfacl /opt/research/reports
  # Should show both:
  # user:charlie:r-x (regular ACL)
  # default:user:charlie:r-x (default ACL)
  
  getfacl /opt/research/reports/test-acl.txt
  # New file should have: user:charlie:r-x

EOF
}

hint_step_4() {
    echo "  Set umask: umask 027"
    echo "  Test: touch /tmp/umask-test.txt; mkdir /tmp/umask-testdir"
    echo "  Check: ls -l /tmp/umask-test*"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Configure umask for secure default file permissions

umask determines default permissions for new files and directories. A umask of
027 is more secure than the default 022, preventing group write and all others
access.

What to do:
  • Set umask to: 027
  • Create test file: /tmp/umask-test.txt
  • Create test directory: /tmp/umask-testdir
  • Verify permissions match expectations

Expected results:
  • Files: 640 (rw-r-----) [666-027=640]
  • Directories: 750 (rwxr-x---) [777-027=750]

Tools available:
  • umask - View or set umask
  • touch - Create test file
  • mkdir - Create test directory
  • stat -c "%a" - Show numeric permissions

Think about:
  • How is umask calculated? (subtraction from default)
  • Why are file defaults 666 and directory defaults 777?
  • What's the difference between umask 022 and 027?

After completing: Check permissions with ls -l /tmp/umask-test*
EOF
}

validate_step_4() {
    # Check current umask
    local current_umask=$(umask)
    if [ "$current_umask" != "0027" ] && [ "$current_umask" != "027" ]; then
        echo ""
        print_color "$RED" "✗ umask is $current_umask (expected 027)"
        echo "  Try: umask 027"
        return 1
    fi
    
    # Check test file
    if [ ! -f /tmp/umask-test.txt ]; then
        echo ""
        print_color "$RED" "✗ Test file /tmp/umask-test.txt not found"
        echo "  Create with: touch /tmp/umask-test.txt"
        return 1
    fi
    
    local file_perms=$(stat -c "%a" /tmp/umask-test.txt 2>/dev/null)
    if [ "$file_perms" != "640" ]; then
        echo ""
        print_color "$RED" "✗ File permissions: $file_perms (expected 640)"
        echo "  Set umask before creating file"
        return 1
    fi
    
    # Check test directory
    if [ ! -d /tmp/umask-testdir ]; then
        echo ""
        print_color "$RED" "✗ Test directory /tmp/umask-testdir not found"
        echo "  Create with: mkdir /tmp/umask-testdir"
        return 1
    fi
    
    local dir_perms=$(stat -c "%a" /tmp/umask-testdir 2>/dev/null)
    if [ "$dir_perms" != "750" ]; then
        echo ""
        print_color "$RED" "✗ Directory permissions: $dir_perms (expected 750)"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  umask 027
  touch /tmp/umask-test.txt
  mkdir /tmp/umask-testdir

Explanation:
  • umask 027: Sets the permission mask
  • Files: 666 - 027 = 640 (rw-r-----)
  • Directories: 777 - 027 = 750 (rwxr-x---)

How umask works:
  Base permissions:
  • Files: 666 (rw-rw-rw-)
  • Directories: 777 (rwxrwxrwx)
  
  Subtract umask (027):
  • 666 - 027 = 640
  • 777 - 027 = 750

Common umask values:
  • 022: Files 644, Dirs 755 (default for root)
  • 002: Files 664, Dirs 775 (default for users)
  • 027: Files 640, Dirs 750 (more secure)
  • 077: Files 600, Dirs 700 (maximum privacy)

Verification:
  umask
  # Should show: 0027
  
  ls -l /tmp/umask-test.txt
  # Should show: -rw-r-----
  
  ls -ld /tmp/umask-testdir
  # Should show: drwxr-x---

Making permanent:
  echo "umask 027" >> ~/.bashrc

EOF
}

hint_step_5() {
    echo "  Symbolic format: chmod u+x,g-w,o= /opt/research/archive/legacy.dat"
    echo "  Remember: + adds, - removes, = sets exactly"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Fix permissions using symbolic chmod notation

The legacy.dat file has inconsistent permissions. You must fix it using
symbolic mode (not numeric) to practice this important RHCSA skill.

What to do:
  • File: /opt/research/archive/legacy.dat
  • Owner: ADD execute permission (u+x)
  • Group: REMOVE write permission (g-w)
  • Others: SET to no permissions (o=)
  • Use symbolic mode only!

Symbolic syntax:
  • u = user (owner)
  • g = group
  • o = others
  • a = all
  • + = add permission
  • - = remove permission
  • = = set exact permissions

Expected result: rwxr----- (750)

Think about:
  • Why use symbolic instead of numeric?
  • What's the difference between g-w and g=r?
  • How do you clear all permissions? (use =)

After completing: Verify with ls -l /opt/research/archive/legacy.dat
EOF
}

validate_step_5() {
    local perms=$(stat -c "%a" /opt/research/archive/legacy.dat 2>/dev/null)
    
    if [ "$perms" != "750" ]; then
        echo ""
        print_color "$RED" "✗ Permissions: $perms (expected 750/rwxr-x---)"
        echo "  Try: sudo chmod u+x,g-w,o= /opt/research/archive/legacy.dat"
        return 1
    fi
    
    # Verify it's executable for owner
    if [ ! -x /opt/research/archive/legacy.dat ]; then
        echo ""
        print_color "$RED" "✗ File not executable for owner"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo chmod u+x,g-w,o= /opt/research/archive/legacy.dat

Explanation:
  • u+x: Add execute for owner
  • g-w: Remove write from group
  • o=: Set others to nothing (clear all)
  • Comma separates multiple operations

Symbolic notation benefits:
  • More readable than numbers
  • Can modify without knowing current state
  • Can target specific permission bits
  • Relative changes (+ and -) are safer

Symbolic operators:
  • +: Add permissions (chmod g+w)
  • -: Remove permissions (chmod o-r)
  • =: Set exact permissions (chmod u=rwx)

Examples:
  chmod u+x file        # Add execute for owner
  chmod g-w file        # Remove write from group
  chmod o=r file        # Set others to read-only
  chmod a+r file        # Add read for all
  chmod u=rwx,g=rx,o=   # Set all at once

Verification:
  ls -l /opt/research/archive/legacy.dat
  # Should show: -rwxr----- root research

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your ACL, umask, and advanced permissions configuration..."
    echo ""
    
    # CHECK 1: charlie ACL on reports
    print_color "$CYAN" "[1/$total] Checking charlie's ACL on /opt/research/reports..."
    if getfacl /opt/research/reports 2>/dev/null | grep -q "user:charlie:r-x"; then
        if ls -ld /opt/research/reports | grep -q "+"; then
            print_color "$GREEN" "  ✓ ACL set correctly for charlie (r-x)"
            ((score++))
        else
            print_color "$RED" "  ✗ ACL data present but no + indicator"
        fi
    else
        print_color "$RED" "  ✗ ACL for charlie not found"
        print_color "$YELLOW" "  Fix: sudo setfacl -m u:charlie:r-x /opt/research/reports"
    fi
    echo ""
    
    # CHECK 2: david ACL on dataset1.csv
    print_color "$CYAN" "[2/$total] Checking david's ACL on dataset1.csv..."
    if getfacl /opt/research/data/dataset1.csv 2>/dev/null | grep -q "user:david:r--"; then
        print_color "$GREEN" "  ✓ ACL set correctly for david (r)"
        ((score++))
    else
        print_color "$RED" "  ✗ ACL for david not found or incorrect"
        print_color "$YELLOW" "  Fix: sudo setfacl -m u:david:r /opt/research/data/dataset1.csv"
    fi
    echo ""
    
    # CHECK 3: Default ACL and inheritance
    print_color "$CYAN" "[3/$total] Checking default ACL on reports/..."
    local default_ok=true
    
    if ! getfacl /opt/research/reports 2>/dev/null | grep -q "default:user:charlie:r-x"; then
        print_color "$RED" "  ✗ Default ACL not set"
        default_ok=false
    fi
    
    if [ ! -f /opt/research/reports/test-acl.txt ]; then
        print_color "$RED" "  ✗ Test file not found"
        default_ok=false
    elif ! getfacl /opt/research/reports/test-acl.txt 2>/dev/null | grep -q "user:charlie:r-x"; then
        print_color "$RED" "  ✗ Test file doesn't have inherited ACL"
        default_ok=false
    fi
    
    if [ "$default_ok" = true ]; then
        print_color "$GREEN" "  ✓ Default ACL set and verified with test file"
        ((score++))
    else
        print_color "$YELLOW" "  Fix: sudo setfacl -d -m u:charlie:r-x /opt/research/reports"
    fi
    echo ""
    
    # CHECK 4: umask configuration
    print_color "$CYAN" "[4/$total] Checking umask configuration..."
    local umask_ok=true
    local current_umask=$(umask)
    
    if [ "$current_umask" != "0027" ] && [ "$current_umask" != "027" ]; then
        print_color "$RED" "  ✗ umask is $current_umask (expected 027)"
        umask_ok=false
    fi
    
    if [ ! -f /tmp/umask-test.txt ] || [ ! -d /tmp/umask-testdir ]; then
        print_color "$RED" "  ✗ Test file or directory missing"
        umask_ok=false
    else
        local file_perms=$(stat -c "%a" /tmp/umask-test.txt 2>/dev/null)
        local dir_perms=$(stat -c "%a" /tmp/umask-testdir 2>/dev/null)
        
        if [ "$file_perms" != "640" ] || [ "$dir_perms" != "750" ]; then
            print_color "$RED" "  ✗ Permissions don't match umask 027"
            echo "    File: $file_perms (expected 640)"
            echo "    Dir: $dir_perms (expected 750)"
            umask_ok=false
        fi
    fi
    
    if [ "$umask_ok" = true ]; then
        print_color "$GREEN" "  ✓ umask set to 027 and verified"
        ((score++))
    else
        print_color "$YELLOW" "  Fix: umask 027; touch /tmp/umask-test.txt; mkdir /tmp/umask-testdir"
    fi
    echo ""
    
    # CHECK 5: Symbolic chmod
    print_color "$CYAN" "[5/$total] Checking symbolic chmod on legacy.dat..."
    local legacy_perms=$(stat -c "%a" /opt/research/archive/legacy.dat 2>/dev/null)
    
    if [ "$legacy_perms" = "750" ] && [ -x /opt/research/archive/legacy.dat ]; then
        print_color "$GREEN" "  ✓ Permissions set correctly (750/rwxr-x---)"
        ((score++))
    else
        print_color "$RED" "  ✗ Permissions: $legacy_perms (expected 750)"
        print_color "$YELLOW" "  Fix: sudo chmod u+x,g-w,o= /opt/research/archive/legacy.dat"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Setting and viewing ACLs with setfacl/getfacl"
        echo "  • Using default ACLs for automatic inheritance"
        echo "  • Configuring umask for secure default permissions"
        echo "  • Using symbolic chmod notation effectively"
        echo "  • Providing granular access beyond standard UGO"
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

OBJECTIVE 1: Grant charlie ACL on reports directory
─────────────────────────────────────────────────────────────────
Command:
  sudo setfacl -m u:charlie:r-x /opt/research/reports

Explanation:
  • setfacl: Set file ACL
  • -m: Modify (add or change ACL entry)
  • u:charlie:r-x: User charlie gets read and execute
  • ACL doesn't affect standard UGO permissions

Why use ACL:
  Standard Unix permissions only allow one owner, one group, and others.
  ACLs let you grant specific users access without group membership.
  Perfect for external collaborators or exceptions.

Verification:
  getfacl /opt/research/reports
  ls -ld /opt/research/reports  # Look for + indicator


OBJECTIVE 2: Grant david read-only ACL on specific file
─────────────────────────────────────────────────────────────────
Command:
  sudo setfacl -m u:david:r /opt/research/data/dataset1.csv

Explanation:
  • u:david:r: User david gets read-only
  • No execute needed for data files
  • ACL applies to this file only, not directory

File vs Directory ACLs:
  Files usually need: r (read), w (write)
  Directories need: r (list), x (enter), w (modify)
  Execute on files is only for scripts/binaries

Verification:
  getfacl /opt/research/data/dataset1.csv


OBJECTIVE 3: Set default ACL for automatic inheritance
─────────────────────────────────────────────────────────────────
Commands:
  sudo setfacl -d -m u:charlie:r-x /opt/research/reports
  sudo touch /opt/research/reports/test-acl.txt

Explanation:
  • -d: Set default ACL
  • Default ACLs apply to new files/dirs only
  • Existing files are NOT affected
  • Test file should automatically inherit the ACL

Regular vs Default ACL:
  • Regular ACL: Affects current file/directory
  • Default ACL: Inherited by new files created inside
  • Directories can have both types
  • Use default ACLs for collaborative directories

Verification:
  getfacl /opt/research/reports  # Shows both types
  getfacl /opt/research/reports/test-acl.txt  # Shows inherited ACL


OBJECTIVE 4: Configure umask for secure defaults
─────────────────────────────────────────────────────────────────
Commands:
  umask 027
  touch /tmp/umask-test.txt
  mkdir /tmp/umask-testdir

Explanation:
  • umask subtracts from default permissions
  • Files: 666 - 027 = 640 (rw-r-----)
  • Directories: 777 - 027 = 750 (rwxr-x---)

umask calculation:
  Default base:
  • Files: 666 (rw-rw-rw-)
  • Directories: 777 (rwxrwxrwx)
  
  With umask 027:
  • 666 - 027 = 640 (rw-r-----)
  • 777 - 027 = 750 (rwxr-x---)

Common umask values:
  • 022: Standard (files 644, dirs 755)
  • 002: Group collaboration (files 664, dirs 775)
  • 027: More secure (files 640, dirs 750)
  • 077: Maximum privacy (files 600, dirs 700)

Making permanent:
  echo "umask 027" >> ~/.bashrc

Verification:
  umask  # Should show 0027
  ls -l /tmp/umask-test*


OBJECTIVE 5: Use symbolic chmod notation
─────────────────────────────────────────────────────────────────
Command:
  sudo chmod u+x,g-w,o= /opt/research/archive/legacy.dat

Explanation:
  • u+x: Add execute for user (owner)
  • g-w: Remove write from group
  • o=: Set others to nothing (clear all)
  • Comma separates operations

Symbolic notation syntax:
  WHO:
  • u: user (owner)
  • g: group
  • o: others
  • a: all (ugo)
  
  OPERATOR:
  • +: add permission
  • -: remove permission
  • =: set exact permission
  
  PERMISSION:
  • r: read
  • w: write
  • x: execute

Examples:
  chmod u+x file        # Add execute for owner
  chmod g-w file        # Remove write from group
  chmod o=r file        # Set others to read-only
  chmod a+r file        # Add read for everyone
  chmod u=rwx,g=rx,o=   # Set all permissions at once
  chmod ug+rw file      # Add read-write for user and group

When to use symbolic vs numeric:
  • Use symbolic when modifying existing permissions
  • Use numeric when setting from scratch
  • Symbolic is safer for scripts (relative changes)

Verification:
  ls -l /opt/research/archive/legacy.dat
  # Should show: -rwxr-----


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ACLs (Access Control Lists):
  Standard Unix permissions (UGO) are limited:
  • One owner
  • One group
  • Everyone else (others)
  
  ACLs add flexibility:
  • Multiple users can have different permissions
  • Multiple groups can have different permissions
  • Grant exceptions without changing ownership
  
  ACL types:
  • Access ACL: Applies to current file/directory
  • Default ACL: Inherited by new files (directories only)

ACL Mask:
  The mask limits maximum permissions for:
  • Named users (beyond owner)
  • Named groups (beyond group owner)
  • Group owner
  
  Mask is calculated automatically but can be set:
  setfacl -m m::rwx file  # Set mask to rwx

umask Explained:
  Purpose: Set default permissions for new files/directories
  
  Calculation:
  • Subtract umask from base permissions
  • Files: 666 - umask
  • Directories: 777 - umask
  
  Why files start at 666:
  • Execute permission must be explicitly granted
  • Security: Don't make every new file executable
  
  System-wide: /etc/bashrc or /etc/profile
  User-specific: ~/.bashrc or ~/.bash_profile

Symbolic vs Numeric chmod:
  Numeric (absolute):
  • chmod 755 file
  • Replaces all permissions
  • Need to know current state
  
  Symbolic (relative):
  • chmod u+x file
  • Modifies specific bits
  • Safe for scripts
  • More readable

ACL Indicator (+):
  When you see + after permissions in ls -l:
  -rw-r--r--+ 1 user group 100 file.txt
               ↑
  This means ACLs are present. Use getfacl to view them.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting -d for default ACL
  Result: ACL applies to directory but not new files
  Fix: setfacl -d -m u:user:perms directory
  Always use -d when you want inheritance

Mistake 2: Wrong umask calculation
  Result: Unexpected file permissions
  Fix: Remember it's SUBTRACTION not addition
  Files: 666 - umask, Dirs: 777 - umask

Mistake 3: Using = instead of - in symbolic mode
  Result: Removes all other permissions
  chmod g=r file  # Sets group to read ONLY (removes others)
  chmod g-w file  # Just removes write (keeps others)

Mistake 4: Not checking ACL with getfacl
  Result: Can't see actual permissions
  Fix: Always verify with getfacl, not just ls -l
  ls -l only shows + indicator, not details

Mistake 5: Setting execute on data files
  Result: Security risk (files shouldn't be executable unless needed)
  Fix: Only use execute (x) for scripts and directories
  Data files need read/write, not execute


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always check for + indicator with ls -l to detect ACLs
2. Use getfacl to view ACLs, not just ls -l
3. Remember: setfacl -m (modify), setfacl -x (remove)
4. Default ACLs use -d flag and only work on directories
5. umask calculation: 666-umask (files), 777-umask (dirs)
6. Symbolic chmod: u+x (add), g-w (remove), o= (set exact)
7. ACLs complement, don't replace, standard permissions

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
    userdel -r david 2>/dev/null || true
    groupdel research 2>/dev/null || true
    groupdel analysts 2>/dev/null || true
    rm -rf /opt/research 2>/dev/null || true
    rm -rf /tmp/acl-test 2>/dev/null || true
    rm -f /tmp/umask-test.txt 2>/dev/null || true
    rm -rf /tmp/umask-testdir 2>/dev/null || true
    
    # Reset umask to system default
    umask 0022
    
    echo "  ✓ All lab components removed"
    echo "  ✓ umask reset to system default"
}

# Execute the main framework
main "$@"
