#!/bin/bash
# labs/m03/10A-file-ownership-permissions.sh
# Lab: File Ownership and Basic Permissions
# Difficulty: Beginner
# RHCSA Objective: 10.1-10.4 - Understanding and managing file ownership and permissions

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="File Ownership and Basic Permissions"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous lab attempts
    userdel -r projectmgr 2>/dev/null || true
    userdel -r developer1 2>/dev/null || true
    userdel -r developer2 2>/dev/null || true
    groupdel projectteam 2>/dev/null || true
    rm -rf /opt/project 2>/dev/null || true
    
    # Create test users and group
    useradd -m -s /bin/bash projectmgr 2>/dev/null || true
    useradd -m -s /bin/bash developer1 2>/dev/null || true
    useradd -m -s /bin/bash developer2 2>/dev/null || true
    groupadd projectteam 2>/dev/null || true
    
    # Add users to project group
    usermod -aG projectteam projectmgr 2>/dev/null
    usermod -aG projectteam developer1 2>/dev/null
    usermod -aG projectteam developer2 2>/dev/null
    
    # Create project directory structure
    mkdir -p /opt/project/{docs,scripts,data} 2>/dev/null || true
    
    # Create test files with wrong ownership/permissions
    echo "Project Documentation" > /opt/project/docs/readme.txt
    echo "#!/bin/bash" > /opt/project/scripts/deploy.sh
    echo "echo 'Deployment script'" >> /opt/project/scripts/deploy.sh
    echo "Sensitive data" > /opt/project/data/config.dat
    
    # Set initial ownership (intentionally wrong for lab)
    chown -R root:root /opt/project 2>/dev/null
    chmod -R 644 /opt/project 2>/dev/null
    chmod 755 /opt/project /opt/project/docs /opt/project/scripts /opt/project/data
    
    echo "  ✓ Created test users: projectmgr, developer1, developer2"
    echo "  ✓ Created projectteam group"
    echo "  ✓ Created project directory: /opt/project"
    echo "  ✓ System ready for permission configuration"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of Linux user and group concepts
  • Basic understanding of file system hierarchy
  • Familiarity with read, write, and execute permissions

Commands You'll Use:
  • ls -l - Display file permissions and ownership
  • chown - Change file ownership
  • chgrp - Change group ownership
  • chmod - Change file permissions
  • stat - Display detailed file information

Files You'll Interact With:
  • /opt/project/ - Project directory structure
  • /opt/project/docs/ - Documentation files
  • /opt/project/scripts/ - Shell scripts
  • /opt/project/data/ - Data files
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're the system administrator for a software development team. The team needs
a shared project directory with proper ownership and permissions. Different team
members need different levels of access to various parts of the project.

LAB DIRECTORY: /opt/project
  (Contains docs/, scripts/, and data/ subdirectories)

BACKGROUND:
The project manager needs full control over all files. Developers need to read
and modify documentation, execute scripts, but only read data files. You must
configure ownership and permissions to implement this access control using
standard Linux permissions (UGO - User, Group, Others).

OBJECTIVES:
  1. Set ownership of /opt/project directory and all contents
     • Owner: projectmgr
     • Group: projectteam
     • Apply recursively to all files and subdirectories

  2. Configure permissions for /opt/project/docs/readme.txt
     • Owner (projectmgr): read and write (rw-)
     • Group (projectteam): read and write (rw-)
     • Others: read only (r--)
     • Numeric: 664

  3. Configure permissions for /opt/project/scripts/deploy.sh
     • Owner: read, write, execute (rwx)
     • Group: read and execute (r-x)
     • Others: no permissions (---)
     • Numeric: 750
     • This is a script and must be executable

  4. Configure permissions for /opt/project/data/config.dat
     • Owner: read and write (rw-)
     • Group: read only (r--)
     • Others: no permissions (---)
     • Numeric: 640
     • Sensitive data should be protected

HINTS:
  • Use chown user:group to set both owner and group at once
  • Use -R flag with chown to apply recursively
  • chmod can use numeric (755) or symbolic (u+x) notation
  • Verify permissions with: ls -l filename
  • Check ownership with: stat filename

SUCCESS CRITERIA:
  • All files in /opt/project owned by projectmgr:projectteam
  • readme.txt has 664 permissions
  • deploy.sh has 750 permissions and is executable
  • config.dat has 640 permissions
  • Use ls -l to verify all settings
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Set /opt/project ownership to projectmgr:projectteam (recursive)
  ☐ 2. Set docs/readme.txt permissions to 664 (rw-rw-r--)
  ☐ 3. Set scripts/deploy.sh permissions to 750 (rwxr-x---)
  ☐ 4. Set data/config.dat permissions to 640 (rw-r-----)
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
You're configuring a shared project directory for a development team. The project
manager needs full control, while developers need varying levels of access to
documentation, scripts, and data files.

LAB DIRECTORY: /opt/project
Test users: projectmgr, developer1, developer2
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Set ownership of the project directory and all its contents

The /opt/project directory and everything inside it needs to be owned by
projectmgr (user) and projectteam (group). This establishes who has primary
control and which group can access the files.

What to do:
  • Set owner to: projectmgr
  • Set group to: projectteam
  • Apply to: /opt/project and ALL contents (recursive)

Tools available:
  • chown - Change file owner and group
  • ls -l - Verify ownership
  • stat - Show detailed file information

Think about:
  • Why set ownership before permissions?
  • What does the -R flag do?
  • Can you set user and group in one command?

After completing: Verify with: ls -l /opt/project
EOF
}

validate_step_1() {
    # Check directory ownership
    local dir_owner=$(stat -c "%U" /opt/project 2>/dev/null)
    local dir_group=$(stat -c "%G" /opt/project 2>/dev/null)
    
    if [ "$dir_owner" != "projectmgr" ] || [ "$dir_group" != "projectteam" ]; then
        echo ""
        print_color "$RED" "✗ /opt/project ownership incorrect"
        echo "  Current: $dir_owner:$dir_group"
        echo "  Expected: projectmgr:projectteam"
        echo "  Try: sudo chown -R projectmgr:projectteam /opt/project"
        return 1
    fi
    
    # Check a file inside
    local file_owner=$(stat -c "%U" /opt/project/docs/readme.txt 2>/dev/null)
    local file_group=$(stat -c "%G" /opt/project/docs/readme.txt 2>/dev/null)
    
    if [ "$file_owner" != "projectmgr" ] || [ "$file_group" != "projectteam" ]; then
        echo ""
        print_color "$RED" "✗ Files inside /opt/project have wrong ownership"
        echo "  Did you use -R (recursive)?"
        echo "  Try: sudo chown -R projectmgr:projectteam /opt/project"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo chown -R projectmgr:projectteam /opt/project

Explanation:
  • chown: Change ownership command
  • -R: Recursive - apply to directory and all contents
  • projectmgr: The new owner (user)
  • :projectteam: The new group (colon separates user:group)
  • /opt/project: Target directory

Why this matters:
  Ownership must be set before permissions because permissions are relative
  to the owner. The user "projectmgr" is the primary owner with most control,
  while the group "projectteam" allows multiple users to share access.

Verification:
  ls -l /opt/project
  # All items should show: projectmgr projectteam
  
  stat /opt/project/docs/readme.txt
  # Should show owner: projectmgr and group: projectteam

EOF
}

hint_step_2() {
    echo "  Use: sudo chmod 664 /opt/project/docs/readme.txt"
    echo "  Or symbolic: sudo chmod u=rw,g=rw,o=r /opt/project/docs/readme.txt"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Configure permissions for the documentation file

The readme.txt file contains project documentation that should be readable and
writable by the project manager and all team members, but only readable by others.

What to do:
  • File: /opt/project/docs/readme.txt
  • Owner permissions: rw- (read, write)
  • Group permissions: rw- (read, write)
  • Others permissions: r-- (read only)
  • Numeric equivalent: 664

Tools available:
  • chmod - Change file permissions
  • ls -l - Verify permissions

Numeric breakdown:
  • 6 (owner): 4(read) + 2(write) = rw-
  • 6 (group): 4(read) + 2(write) = rw-
  • 4 (others): 4(read) = r--

After completing: Verify with: ls -l /opt/project/docs/readme.txt
EOF
}

validate_step_2() {
    local perms=$(stat -c "%a" /opt/project/docs/readme.txt 2>/dev/null)
    
    if [ "$perms" != "664" ]; then
        echo ""
        print_color "$RED" "✗ readme.txt has incorrect permissions: $perms"
        echo "  Expected: 664 (rw-rw-r--)"
        echo "  Try: sudo chmod 664 /opt/project/docs/readme.txt"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo chmod 664 /opt/project/docs/readme.txt

Alternative (symbolic):
  sudo chmod u=rw,g=rw,o=r /opt/project/docs/readme.txt

Explanation:
  • 6 (first digit): Owner gets read(4) + write(2) = rw-
  • 6 (second digit): Group gets read(4) + write(2) = rw-
  • 4 (third digit): Others get read(4) = r--

Why this matters:
  Documentation should be collaborative. Both the owner and group members
  need to read and modify it, while others (not in the group) should only
  be able to read it for reference.

Verification:
  ls -l /opt/project/docs/readme.txt
  # Should show: -rw-rw-r-- projectmgr projectteam
  
  stat -c "%a %n" /opt/project/docs/readme.txt
  # Should show: 664 /opt/project/docs/readme.txt

EOF
}

hint_step_3() {
    echo "  Use: sudo chmod 750 /opt/project/scripts/deploy.sh"
    echo "  Scripts need execute permission to run!"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Configure permissions for the deployment script

The deploy.sh script should be executable by the owner and group, but completely
inaccessible to others. Only the owner should be able to modify it.

What to do:
  • File: /opt/project/scripts/deploy.sh
  • Owner permissions: rwx (read, write, execute)
  • Group permissions: r-x (read, execute only)
  • Others permissions: --- (no access)
  • Numeric equivalent: 750

Tools available:
  • chmod - Change file permissions

Numeric breakdown:
  • 7 (owner): 4(read) + 2(write) + 1(execute) = rwx
  • 5 (group): 4(read) + 1(execute) = r-x
  • 0 (others): no permissions = ---

Think about:
  • Why does the script need execute permission?
  • Why can't the group write to it?
  • What happens if others have read permission on scripts?

After completing: Test with: ls -l /opt/project/scripts/deploy.sh
EOF
}

validate_step_3() {
    local perms=$(stat -c "%a" /opt/project/scripts/deploy.sh 2>/dev/null)
    
    if [ "$perms" != "750" ]; then
        echo ""
        print_color "$RED" "✗ deploy.sh has incorrect permissions: $perms"
        echo "  Expected: 750 (rwxr-x---)"
        echo "  Try: sudo chmod 750 /opt/project/scripts/deploy.sh"
        return 1
    fi
    
    # Check if executable
    if [ ! -x /opt/project/scripts/deploy.sh ]; then
        echo ""
        print_color "$RED" "✗ deploy.sh is not executable"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo chmod 750 /opt/project/scripts/deploy.sh

Explanation:
  • 7 (owner): read(4) + write(2) + execute(1) = rwx
  • 5 (group): read(4) + execute(1) = r-x
  • 0 (others): no permissions = ---

Why this matters:
  Scripts need execute permission to run. The owner needs full control to
  modify the script, the group needs to execute it but not modify it (to
  prevent accidental changes), and others shouldn't see deployment scripts
  at all for security reasons.

Execute Permission Explained:
  Without execute permission, trying to run the script gives "Permission denied"
  even if you can read the contents. Execute permission is what allows the
  shell to actually run the file as a program.

Verification:
  ls -l /opt/project/scripts/deploy.sh
  # Should show: -rwxr-x--- projectmgr projectteam
  
  # Test executability:
  /opt/project/scripts/deploy.sh
  # Should run without "Permission denied" errors

EOF
}

hint_step_4() {
    echo "  Use: sudo chmod 640 /opt/project/data/config.dat"
    echo "  Sensitive data should be restrictive!"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Configure permissions for the sensitive data file

The config.dat file contains sensitive configuration data. The owner needs full
access, the group should only read it, and others should have no access at all.

What to do:
  • File: /opt/project/data/config.dat
  • Owner permissions: rw- (read, write)
  • Group permissions: r-- (read only)
  • Others permissions: --- (no access)
  • Numeric equivalent: 640

Numeric breakdown:
  • 6 (owner): 4(read) + 2(write) = rw-
  • 4 (group): 4(read) = r--
  • 0 (others): no permissions = ---

Think about:
  • Why is this more restrictive than readme.txt?
  • Why can't the group write to this file?
  • What's the security risk if others can read it?

After completing: Verify with: ls -l /opt/project/data/config.dat
EOF
}

validate_step_4() {
    local perms=$(stat -c "%a" /opt/project/data/config.dat 2>/dev/null)
    
    if [ "$perms" != "640" ]; then
        echo ""
        print_color "$RED" "✗ config.dat has incorrect permissions: $perms"
        echo "  Expected: 640 (rw-r-----)"
        echo "  Try: sudo chmod 640 /opt/project/data/config.dat"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  sudo chmod 640 /opt/project/data/config.dat

Explanation:
  • 6 (owner): read(4) + write(2) = rw-
  • 4 (group): read(4) = r--
  • 0 (others): no permissions = ---

Why this matters:
  Sensitive configuration files should be highly restrictive. Only the
  project manager needs to modify configuration, team members need to
  read it for their work, and no one else should have any access.
  This follows the principle of least privilege.

Verification:
  ls -l /opt/project/data/config.dat
  # Should show: -rw-r----- projectmgr projectteam
  
  stat -c "%a %n" /opt/project/data/config.dat
  # Should show: 640 /opt/project/data/config.dat

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your file ownership and permissions configuration..."
    echo ""
    
    # CHECK 1: Directory ownership
    print_color "$CYAN" "[1/$total] Checking /opt/project ownership..."
    local dir_owner=$(stat -c "%U:%G" /opt/project 2>/dev/null)
    
    if [ "$dir_owner" = "projectmgr:projectteam" ]; then
        # Check recursive application
        local file_owner=$(stat -c "%U:%G" /opt/project/docs/readme.txt 2>/dev/null)
        if [ "$file_owner" = "projectmgr:projectteam" ]; then
            print_color "$GREEN" "  ✓ Ownership set correctly (recursive)"
            ((score++))
        else
            print_color "$RED" "  ✗ Directory correct but files inside are not"
            print_color "$YELLOW" "  Fix: sudo chown -R projectmgr:projectteam /opt/project"
        fi
    else
        print_color "$RED" "  ✗ Ownership incorrect: $dir_owner"
        print_color "$YELLOW" "  Fix: sudo chown -R projectmgr:projectteam /opt/project"
    fi
    echo ""
    
    # CHECK 2: readme.txt permissions
    print_color "$CYAN" "[2/$total] Checking docs/readme.txt permissions..."
    local readme_perms=$(stat -c "%a" /opt/project/docs/readme.txt 2>/dev/null)
    
    if [ "$readme_perms" = "664" ]; then
        print_color "$GREEN" "  ✓ Permissions: 664 (rw-rw-r--)"
        ((score++))
    else
        print_color "$RED" "  ✗ Permissions: $readme_perms (expected 664)"
        print_color "$YELLOW" "  Fix: sudo chmod 664 /opt/project/docs/readme.txt"
    fi
    echo ""
    
    # CHECK 3: deploy.sh permissions
    print_color "$CYAN" "[3/$total] Checking scripts/deploy.sh permissions..."
    local script_perms=$(stat -c "%a" /opt/project/scripts/deploy.sh 2>/dev/null)
    
    if [ "$script_perms" = "750" ]; then
        if [ -x /opt/project/scripts/deploy.sh ]; then
            print_color "$GREEN" "  ✓ Permissions: 750 (rwxr-x---) and executable"
            ((score++))
        else
            print_color "$RED" "  ✗ Correct number but not executable"
            print_color "$YELLOW" "  Fix: sudo chmod 750 /opt/project/scripts/deploy.sh"
        fi
    else
        print_color "$RED" "  ✗ Permissions: $script_perms (expected 750)"
        print_color "$YELLOW" "  Fix: sudo chmod 750 /opt/project/scripts/deploy.sh"
    fi
    echo ""
    
    # CHECK 4: config.dat permissions
    print_color "$CYAN" "[4/$total] Checking data/config.dat permissions..."
    local data_perms=$(stat -c "%a" /opt/project/data/config.dat 2>/dev/null)
    
    if [ "$data_perms" = "640" ]; then
        print_color "$GREEN" "  ✓ Permissions: 640 (rw-r-----)"
        ((score++))
    else
        print_color "$RED" "  ✗ Permissions: $data_perms (expected 640)"
        print_color "$YELLOW" "  Fix: sudo chmod 640 /opt/project/data/config.dat"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Setting file and directory ownership with chown"
        echo "  • Using recursive operations with -R flag"
        echo "  • Configuring permissions with chmod (numeric mode)"
        echo "  • Applying appropriate permissions for different file types"
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

OBJECTIVE 1: Set ownership recursively
─────────────────────────────────────────────────────────────────
Command:
  sudo chown -R projectmgr:projectteam /opt/project

Explanation:
  • chown: Changes file ownership
  • -R: Recursive - applies to directory and all contents
  • projectmgr: New owner (user)
  • :projectteam: New group (separated by colon)
  • /opt/project: Target directory

Why set ownership first:
  Permissions are relative to ownership. You need to establish who owns
  the file before setting what they can do with it. Always set ownership
  before permissions.

Verification:
  ls -l /opt/project
  stat /opt/project/docs/readme.txt


OBJECTIVE 2: Configure documentation permissions (664)
─────────────────────────────────────────────────────────────────
Command:
  sudo chmod 664 /opt/project/docs/readme.txt

Explanation:
  • 6 (owner): 4(r) + 2(w) = rw-
  • 6 (group): 4(r) + 2(w) = rw-
  • 4 (others): 4(r) = r--

Binary breakdown:
  • 6 = 110 in binary = rw-
  • 4 = 100 in binary = r--

Verification:
  ls -l /opt/project/docs/readme.txt
  # Expected: -rw-rw-r--


OBJECTIVE 3: Configure script permissions (750)
─────────────────────────────────────────────────────────────────
Command:
  sudo chmod 750 /opt/project/scripts/deploy.sh

Explanation:
  • 7 (owner): 4(r) + 2(w) + 1(x) = rwx
  • 5 (group): 4(r) + 1(x) = r-x
  • 0 (others): no permissions = ---

Why these permissions:
  Scripts need execute permission to run. Owner needs full control,
  group can run but not modify (prevents accidents), others get no
  access to deployment scripts for security.

Verification:
  ls -l /opt/project/scripts/deploy.sh
  # Expected: -rwxr-x---


OBJECTIVE 4: Configure data file permissions (640)
─────────────────────────────────────────────────────────────────
Command:
  sudo chmod 640 /opt/project/data/config.dat

Explanation:
  • 6 (owner): 4(r) + 2(w) = rw-
  • 4 (group): 4(r) = r--
  • 0 (others): no permissions = ---

Why these permissions:
  Sensitive configuration should be highly restricted. Only the owner
  modifies it, group members can read it for their work, no one else
  gets access. This follows the principle of least privilege.

Verification:
  ls -l /opt/project/data/config.dat
  # Expected: -rw-r-----


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

UGO (User, Group, Others):
  Linux permissions operate on three entities:
  • User (owner): The person who owns the file
  • Group: A collection of users who share access
  • Others: Everyone else on the system
  
  Permissions are NOT additive. If you're the owner, only owner permissions
  apply (not group, even if you're in the group).

Permission Numeric System:
  Each permission has a value:
  • Read (r) = 4
  • Write (w) = 2
  • Execute (x) = 1
  
  Add them together:
  • 7 = 4+2+1 = rwx (full access)
  • 6 = 4+2 = rw- (read and write)
  • 5 = 4+1 = r-x (read and execute)
  • 4 = 4 = r-- (read only)
  • 0 = no permissions

Execute Permission:
  For files: Allows running the file as a program
  For directories: Allows cd into the directory (always set with read)
  Without execute on a directory, you can't access its contents even
  if you have read permission.

Ownership vs Permissions:
  Ownership = WHO owns it (user and group)
  Permissions = WHAT they can do with it (rwx)
  Always set ownership before permissions!


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting -R flag with chown
  Result: Only the directory itself changes ownership, files inside don't
  Fix: sudo chown -R user:group /path/to/directory
  Always use -R for directories

Mistake 2: Setting permissions before ownership
  Result: Wrong user's permissions might apply
  Fix: Always do chown first, then chmod
  Order matters!

Mistake 3: Scripts not executable
  Result: "Permission denied" when trying to run
  Fix: chmod +x script.sh or chmod 755 script.sh
  Scripts need execute permission (1 or x)

Mistake 4: Confusing user and group
  Result: Wrong entity gets permissions
  Fix: Remember the format user:group with the colon
  Example: chown alice:developers file.txt


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always set ownership before permissions (chown first, chmod second)
2. Use ls -l to verify both ownership and permissions quickly
3. Remember: 7=rwx, 6=rw-, 5=r-x, 4=r--, 0=---
4. Scripts and directories need execute permission
5. Use stat command for detailed permission information: stat -c "%a %n" file

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r projectmgr 2>/dev/null || true
    userdel -r developer1 2>/dev/null || true
    userdel -r developer2 2>/dev/null || true
    groupdel projectteam 2>/dev/null || true
    rm -rf /opt/project 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
