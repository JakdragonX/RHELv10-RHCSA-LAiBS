#!/bin/bash
# labs/m04/12B-dnf-package-management.sh
# Lab: Understanding DNF
# Difficulty: Intermediate
# RHCSA Objective: 12.4, 12.5, 12.6 - DNF package management, groups, and history

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Understanding DNF"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="40-50 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create working directory
    mkdir -p /tmp/dnf-lab 2>/dev/null || true
    
    # Backup DNF history for reference
    cp /var/log/dnf.rpm.log /tmp/dnf-lab/dnf-backup.log 2>/dev/null || true
    
    # Remove test packages if they exist from previous attempts
    dnf remove -y tree nano wget 2>/dev/null || true
    
    echo "  ✓ Lab environment ready"
    echo "  ✓ Test packages removed if present"
    echo ""
    echo "  NOTE: This lab involves actual package installation"
    echo "  Changes will be documented and can be reverted"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of RPM packages
  • Repository configuration basics
  • Dependency concepts

Commands You'll Use:
  • dnf - Dandified YUM package manager
  • dnf list - List packages
  • dnf search - Search for packages
  • dnf info - Show package information
  • dnf install - Install packages
  • dnf remove - Remove packages
  • dnf update - Update packages
  • dnf group - Manage package groups
  • dnf history - View transaction history

Files You'll Interact With:
  • /var/log/dnf.rpm.log - DNF transaction log
  • /var/log/dnf.log - DNF detailed log
  • /etc/yum.repos.d/ - Repository configuration
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You are managing a RHEL system and need to master DNF for package management.
Your tasks include searching for packages, installing and removing software,
managing package groups, and tracking system changes through DNF history.

BACKGROUND:
DNF (Dandified YUM) is the default package manager on RHEL. It handles
dependencies automatically, works with repositories, and maintains detailed
transaction history. Mastering DNF is critical for the RHCSA exam.

OBJECTIVES:
  1. Search and query packages
     • List all available packages
     • Search for packages containing "security" in name or summary
     • Search all fields including description for "container"
     • Find which package provides the command "/usr/bin/tree"
     • Show detailed information about the bash package
     • Document findings in /tmp/dnf-lab/search-results.txt

  2. Install and verify packages
     • Install the tree package
     • Verify installation succeeded
     • Test the tree command works
     • List all files installed by tree package
     • Document installation in /tmp/dnf-lab/install-log.txt

  3. Work with package dependencies
     • Install wget package
     • Display what dependencies wget requires
     • Show what packages depend on a library like glibc
     • Remove wget and observe dependency handling
     • Document in /tmp/dnf-lab/dependencies.txt

  4. Manage package groups
     • List available package groups
     • Show hidden groups
     • Display information about "Development Tools" group
     • Identify mandatory vs optional packages in a group
     • Document in /tmp/dnf-lab/groups.txt

  5. Explore DNF history and transactions
     • View DNF history
     • Show details of your recent installations
     • Practice undoing a transaction (undo tree installation)
     • View transaction logs
     • Document in /tmp/dnf-lab/history.txt

  6. Update and repository management
     • Check for available updates (do not install)
     • List enabled repositories
     • Temporarily disable a repository and try listing packages
     • Re-enable repository
     • Document in /tmp/dnf-lab/updates-repos.txt

HINTS:
  • dnf uses intelligent tab completion
  • dnf search looks in name and summary by default
  • dnf provides finds packages by file path
  • Groups may be hidden, use appropriate flag
  • History can be undone by transaction ID
  • Use -y flag to skip confirmation prompts

SUCCESS CRITERIA:
  • All search queries completed
  • Packages installed and verified
  • Dependencies understood
  • Groups examined and documented
  • History operations performed
  • Repository operations completed
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Search and query packages with dnf
  ☐ 2. Install and verify package installation
  ☐ 3. Work with package dependencies
  ☐ 4. Manage and examine package groups
  ☐ 5. Explore DNF history and undo transactions
  ☐ 6. Check updates and manage repositories
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "6"
}

scenario_context() {
    cat << 'EOF'
You are mastering DNF package management on a RHEL system.

Output directory: /tmp/dnf-lab/

NOTE: You will install real packages. Changes can be reverted using dnf history.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Search and query packages

Learn to find packages using various search methods. DNF provides multiple
ways to search based on package names, summaries, descriptions, and file paths.

Requirements:
  • List all available packages
  • Search for "security" in package names and summaries
  • Search all fields for "container"
  • Find which package provides /usr/bin/tree
  • Show information about bash package
  • Save findings to /tmp/dnf-lab/search-results.txt

DNF search commands:
  • dnf list: List packages
  • dnf search: Search name and summary
  • dnf search all: Search all fields
  • dnf provides: Find package providing file
  • dnf info: Show package details

Questions to explore:
  • What's the difference between "dnf search" and "dnf search all"?
  • How many packages are available vs installed?
  • What information does "dnf info" show?
EOF
}

validate_step_1() {
    if [ ! -f /tmp/dnf-lab/search-results.txt ]; then
        echo ""
        print_color "$RED" "✗ search-results.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/dnf-lab/search-results.txt ]; then
        echo ""
        print_color "$RED" "✗ search-results.txt is empty"
        return 1
    fi
    
    return 0
}

hint_step_1() {
    echo "  List packages: dnf list available"
    echo "  Search: dnf search KEYWORD"
    echo "  Find provider: dnf provides */FILENAME"
    echo "  Package info: dnf info PACKAGE"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
List all available packages:
  dnf list available | wc -l

Search for security packages:
  dnf search security

Search all fields for container:
  dnf search all container

Find package providing /usr/bin/tree:
  dnf provides /usr/bin/tree
  dnf provides */tree

Show bash package info:
  dnf info bash

Document findings:
  dnf search security > /tmp/dnf-lab/search-results.txt
  echo "" >> /tmp/dnf-lab/search-results.txt
  echo "=== PROVIDES TREE ===" >> /tmp/dnf-lab/search-results.txt
  dnf provides */tree >> /tmp/dnf-lab/search-results.txt
  echo "" >> /tmp/dnf-lab/search-results.txt
  echo "=== BASH INFO ===" >> /tmp/dnf-lab/search-results.txt
  dnf info bash >> /tmp/dnf-lab/search-results.txt

Understanding:
  dnf list: Shows packages (installed, available, updates)
  dnf search: Searches name and summary fields
  dnf search all: Searches all metadata including description
  dnf provides: Finds package by file path (supports wildcards)
  dnf info: Shows detailed package information

EOF
}

hint_step_2() {
    echo "  Install: dnf install tree"
    echo "  Verify: which tree or tree --version"
    echo "  List files: dnf repoquery -l tree"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Install and verify packages

Practice installing packages and verifying successful installation. Learn to
confirm packages are working and examine installed files.

Requirements:
  • Install tree package
  • Verify tree command is available
  • Test tree command in /etc directory
  • List all files installed by tree
  • Save installation details to /tmp/dnf-lab/install-log.txt

DNF installation commands:
  • dnf install: Install package
  • dnf repoquery -l: List files from package
  • rpm -ql: Alternative to list files

Verification methods:
  • which COMMAND: Find command location
  • COMMAND --version: Test command works
  • rpm -q: Check if package installed

Explore:
  • What happens when you install an already-installed package?
  • How does DNF handle dependencies automatically?
EOF
}

validate_step_2() {
    if ! rpm -q tree >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ tree package not installed"
        return 1
    fi
    
    if [ ! -f /tmp/dnf-lab/install-log.txt ]; then
        echo ""
        print_color "$RED" "✗ install-log.txt not found"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Install tree:
  sudo dnf install -y tree

Verify installation:
  which tree
  tree --version
  rpm -q tree

Test command:
  tree /etc | head -20

List installed files:
  rpm -ql tree
  # OR
  dnf repoquery -l tree

Document:
  echo "=== INSTALLATION ===" > /tmp/dnf-lab/install-log.txt
  rpm -q tree >> /tmp/dnf-lab/install-log.txt
  echo "" >> /tmp/dnf-lab/install-log.txt
  echo "=== INSTALLED FILES ===" >> /tmp/dnf-lab/install-log.txt
  rpm -ql tree >> /tmp/dnf-lab/install-log.txt

Understanding:
  dnf install handles dependencies automatically
  -y flag skips confirmation prompt
  Installation recorded in dnf history
  Files tracked in RPM database

EOF
}

hint_step_3() {
    echo "  Install: dnf install wget"
    echo "  Show requires: dnf repoquery --requires wget"
    echo "  Show reverse deps: dnf repoquery --whatrequires glibc"
    echo "  Remove: dnf remove wget"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Work with package dependencies

Understand how DNF handles dependencies automatically. Learn to view what
packages require and what requires them.

Requirements:
  • Install wget package
  • Display dependencies wget requires
  • Show packages that depend on a common library
  • Remove wget and observe dependency handling
  • Document in /tmp/dnf-lab/dependencies.txt

DNF dependency commands:
  • dnf repoquery --requires: Show what package needs
  • dnf repoquery --whatrequires: Show what needs package
  • dnf deplist: Show all dependencies

Explore:
  • Does removing wget remove its dependencies?
  • What dependencies are shared across packages?
  • How does DNF resolve dependency conflicts?
EOF
}

validate_step_3() {
    # wget should be removed by end of this step
    if [ ! -f /tmp/dnf-lab/dependencies.txt ]; then
        echo ""
        print_color "$RED" "✗ dependencies.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/dnf-lab/dependencies.txt ]; then
        echo ""
        print_color "$RED" "✗ dependencies.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Install wget:
  sudo dnf install -y wget

Show wget dependencies:
  dnf repoquery --requires wget

Show what requires glibc:
  dnf repoquery --whatrequires glibc | head -20

Remove wget:
  sudo dnf remove -y wget

Document:
  echo "=== WGET REQUIREMENTS ===" > /tmp/dnf-lab/dependencies.txt
  dnf repoquery --requires wget >> /tmp/dnf-lab/dependencies.txt
  echo "" >> /tmp/dnf-lab/dependencies.txt
  echo "=== PACKAGES REQUIRING GLIBC ===" >> /tmp/dnf-lab/dependencies.txt
  dnf repoquery --whatrequires glibc | head -20 >> /tmp/dnf-lab/dependencies.txt

Understanding:
  DNF tracks dependencies in metadata
  Installing package installs required dependencies
  Removing package does NOT remove dependencies
  Dependencies may be shared by multiple packages
  Use dnf autoremove to remove unused dependencies

EOF
}

hint_step_4() {
    echo "  List groups: dnf group list"
    echo "  Show hidden: dnf group list hidden"
    echo "  Group info: dnf group info 'Development Tools'"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Manage package groups

Package groups bundle related packages together. Learn to discover groups,
examine their contents, and understand group installation behavior.

Requirements:
  • List available package groups
  • Show hidden groups
  • Display information about "Development Tools" group
  • Identify mandatory vs default vs optional packages
  • Document in /tmp/dnf-lab/groups.txt

DNF group commands:
  • dnf group list: Show groups
  • dnf group list hidden: Include hidden groups
  • dnf group info: Show group contents
  • dnf group install: Install group

Explore:
  • Why are some groups hidden?
  • What's the difference between mandatory and optional packages?
  • How many packages in a typical group?

Note: Group names with spaces need quotes
EOF
}

validate_step_4() {
    if [ ! -f /tmp/dnf-lab/groups.txt ]; then
        echo ""
        print_color "$RED" "✗ groups.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/dnf-lab/groups.txt ]; then
        echo ""
        print_color "$RED" "✗ groups.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
List groups:
  dnf group list

List all groups including hidden:
  dnf group list hidden

Show Development Tools info:
  dnf group info "Development Tools"

Document:
  dnf group list > /tmp/dnf-lab/groups.txt
  echo "" >> /tmp/dnf-lab/groups.txt
  echo "=== HIDDEN GROUPS ===" >> /tmp/dnf-lab/groups.txt
  dnf group list hidden >> /tmp/dnf-lab/groups.txt
  echo "" >> /tmp/dnf-lab/groups.txt
  echo "=== DEVELOPMENT TOOLS ===" >> /tmp/dnf-lab/groups.txt
  dnf group info "Development Tools" >> /tmp/dnf-lab/groups.txt

Understanding:
  Groups simplify installing related packages
  Environment groups contain multiple groups
  Package classifications:
    Mandatory: Always installed
    Default: Installed by default
    Optional: Available but not installed by default
  
  Use dnf group install to install groups
  Hidden groups typically installed via environments

EOF
}

hint_step_5() {
    echo "  View history: dnf history"
    echo "  Show transaction: dnf history info TRANSACTION_ID"
    echo "  Undo: dnf history undo TRANSACTION_ID"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Explore DNF history and transactions

DNF records every transaction. Learn to view history, examine transactions,
and undo changes when needed.

Requirements:
  • View DNF history
  • Show details of recent tree installation
  • Undo the tree installation transaction
  • Verify tree is removed
  • Check transaction log file
  • Document in /tmp/dnf-lab/history.txt

DNF history commands:
  • dnf history: List transactions
  • dnf history info ID: Show transaction details
  • dnf history undo ID: Reverse transaction
  • dnf history redo ID: Repeat transaction

Explore:
  • What information is in each transaction?
  • Can you undo any transaction?
  • What's recorded in /var/log/dnf.rpm.log?

Note: Transaction IDs are sequential numbers
EOF
}

validate_step_5() {
    # tree should be removed by undo operation
    if rpm -q tree >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: tree package still installed"
        echo "  Expected to be removed via dnf history undo"
    fi
    
    if [ ! -f /tmp/dnf-lab/history.txt ]; then
        echo ""
        print_color "$RED" "✗ history.txt not found"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
View history:
  dnf history

Find tree installation transaction:
  dnf history | grep tree

Show transaction details (replace ID):
  dnf history info TRANSACTION_ID

Undo tree installation:
  sudo dnf history undo TRANSACTION_ID

Verify removal:
  rpm -q tree
  # Should show: package tree is not installed

View transaction log:
  tail -50 /var/log/dnf.rpm.log

Document:
  dnf history > /tmp/dnf-lab/history.txt
  echo "" >> /tmp/dnf-lab/history.txt
  echo "=== RECENT TRANSACTIONS ===" >> /tmp/dnf-lab/history.txt
  tail -20 /var/log/dnf.rpm.log >> /tmp/dnf-lab/history.txt

Understanding:
  Every dnf operation creates transaction
  History stored in SQLite database
  Can undo/redo transactions by ID
  Transaction log in /var/log/dnf.rpm.log
  Useful for troubleshooting and auditing

EOF
}

# STEP 6
show_step_6() {
    cat << 'EOF'
TASK: Update and repository management

Learn to check for updates and manage repository usage at runtime without
modifying configuration files.

Requirements:
  • Check for available updates (do not install)
  • List enabled repositories
  • Count how many repositories are enabled
  • Temporarily disable a repo and list packages
  • Re-enable repository
  • Document in /tmp/dnf-lab/updates-repos.txt

DNF update and repo commands:
  • dnf check-update: Show available updates
  • dnf repolist: List repositories
  • dnf repolist all: Show disabled repos too
  • dnf --disablerepo=REPO: Temporarily disable
  • dnf --enablerepo=REPO: Temporarily enable

Explore:
  • How many packages have updates available?
  • What repositories are configured?
  • What happens when you disable all repos?

Note: Using --disablerepo does not modify config files
EOF
}

validate_step_6() {
    if [ ! -f /tmp/dnf-lab/updates-repos.txt ]; then
        echo ""
        print_color "$RED" "✗ updates-repos.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/dnf-lab/updates-repos.txt ]; then
        echo ""
        print_color "$RED" "✗ updates-repos.txt is empty"
        return 1
    fi
    
    return 0
}

hint_step_6() {
    echo "  Check updates: dnf check-update"
    echo "  List repos: dnf repolist"
    echo "  Disable temporarily: dnf --disablerepo=REPO_ID list"
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Check for updates:
  dnf check-update

List enabled repositories:
  dnf repolist

Show all repositories:
  dnf repolist all

Temporarily disable repo and list:
  dnf --disablerepo=* --enablerepo=baseos list available | head -20

Document:
  echo "=== AVAILABLE UPDATES ===" > /tmp/dnf-lab/updates-repos.txt
  dnf check-update >> /tmp/dnf-lab/updates-repos.txt 2>&1
  echo "" >> /tmp/dnf-lab/updates-repos.txt
  echo "=== ENABLED REPOSITORIES ===" >> /tmp/dnf-lab/updates-repos.txt
  dnf repolist >> /tmp/dnf-lab/updates-repos.txt

Understanding:
  dnf check-update shows packages with updates
  Exit code 100 means updates available
  --disablerepo and --enablerepo are runtime flags
  Do not modify repository configuration files
  Useful for testing or troubleshooting

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your DNF package management work..."
    echo ""
    
    # CHECK 1: Search and query
    print_color "$CYAN" "[1/$total] Checking package search results..."
    if [ -f /tmp/dnf-lab/search-results.txt ] && \
       [ -s /tmp/dnf-lab/search-results.txt ]; then
        print_color "$GREEN" "  ✓ Package search results documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Package search not completed"
        print_color "$YELLOW" "  Hint: Use dnf search, dnf provides, dnf info"
    fi
    echo ""
    
    # CHECK 2: Installation
    print_color "$CYAN" "[2/$total] Checking package installation..."
    if [ -f /tmp/dnf-lab/install-log.txt ] && \
       [ -s /tmp/dnf-lab/install-log.txt ]; then
        print_color "$GREEN" "  ✓ Package installation documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Package installation not documented"
        print_color "$YELLOW" "  Hint: Install tree and document the process"
    fi
    echo ""
    
    # CHECK 3: Dependencies
    print_color "$CYAN" "[3/$total] Checking dependency work..."
    if [ -f /tmp/dnf-lab/dependencies.txt ] && \
       [ -s /tmp/dnf-lab/dependencies.txt ]; then
        print_color "$GREEN" "  ✓ Dependencies documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Dependencies not documented"
        print_color "$YELLOW" "  Hint: Use dnf repoquery --requires and --whatrequires"
    fi
    echo ""
    
    # CHECK 4: Groups
    print_color "$CYAN" "[4/$total] Checking package groups..."
    if [ -f /tmp/dnf-lab/groups.txt ] && \
       [ -s /tmp/dnf-lab/groups.txt ]; then
        print_color "$GREEN" "  ✓ Package groups documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Package groups not documented"
        print_color "$YELLOW" "  Hint: Use dnf group list and dnf group info"
    fi
    echo ""
    
    # CHECK 5: History
    print_color "$CYAN" "[5/$total] Checking DNF history..."
    if [ -f /tmp/dnf-lab/history.txt ] && \
       [ -s /tmp/dnf-lab/history.txt ]; then
        print_color "$GREEN" "  ✓ DNF history documented"
        ((score++))
    else
        print_color "$RED" "  ✗ DNF history not documented"
        print_color "$YELLOW" "  Hint: Use dnf history and dnf history undo"
    fi
    echo ""
    
    # CHECK 6: Updates and repos
    print_color "$CYAN" "[6/$total] Checking updates and repositories..."
    if [ -f /tmp/dnf-lab/updates-repos.txt ] && \
       [ -s /tmp/dnf-lab/updates-repos.txt ]; then
        print_color "$GREEN" "  ✓ Updates and repositories documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Updates and repositories not documented"
        print_color "$YELLOW" "  Hint: Use dnf check-update and dnf repolist"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Searching for packages with dnf"
        echo "  • Installing and verifying packages"
        echo "  • Working with dependencies"
        echo "  • Managing package groups"
        echo "  • Using DNF history to track and undo changes"
        echo "  • Managing repositories and updates"
        echo ""
        echo "You are ready for RHCSA DNF questions!"
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

OBJECTIVE 1: Search and query packages
─────────────────────────────────────────────────────────────────
List packages:
  dnf list available

Search name and summary:
  dnf search security

Search all fields:
  dnf search all container

Find package providing file:
  dnf provides */tree
  dnf provides /usr/bin/tree

Show package info:
  dnf info bash


OBJECTIVE 2: Install and verify
─────────────────────────────────────────────────────────────────
Install package:
  sudo dnf install -y tree

Verify:
  which tree
  tree --version
  rpm -q tree

List files:
  rpm -ql tree


OBJECTIVE 3: Dependencies
─────────────────────────────────────────────────────────────────
Install:
  sudo dnf install -y wget

Show requirements:
  dnf repoquery --requires wget

Show reverse dependencies:
  dnf repoquery --whatrequires glibc

Remove:
  sudo dnf remove -y wget


OBJECTIVE 4: Package groups
─────────────────────────────────────────────────────────────────
List groups:
  dnf group list
  dnf group list hidden

Group info:
  dnf group info "Development Tools"


OBJECTIVE 5: DNF history
─────────────────────────────────────────────────────────────────
View history:
  dnf history

Transaction details:
  dnf history info ID

Undo transaction:
  sudo dnf history undo ID

View log:
  tail /var/log/dnf.rpm.log


OBJECTIVE 6: Updates and repositories
─────────────────────────────────────────────────────────────────
Check updates:
  dnf check-update

List repos:
  dnf repolist
  dnf repolist all

Disable repo temporarily:
  dnf --disablerepo=appstream list


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DNF Architecture:
  Package manager: dnf
  Backend: libdnf
  Metadata: /var/cache/dnf/
  Configuration: /etc/dnf/dnf.conf
  Repositories: /etc/yum.repos.d/
  Transaction log: /var/log/dnf.rpm.log

Package states:
  Available: In repository, not installed
  Installed: Currently on system
  Updates: Newer version available

Search methods:
  dnf search: Searches name and summary
  dnf search all: Searches all metadata
  dnf provides: Finds by file path
  dnf list: Shows package states

Dependencies:
  Automatic: DNF resolves dependencies
  --requires: Show what package needs
  --whatrequires: Show what needs package
  Shared libraries can have many dependents

Package groups:
  Regular groups: Collection of packages
  Environment groups: Collections of groups
  Hidden groups: Not shown by default
  
  Package types:
  Mandatory: Always installed
  Default: Installed with group
  Optional: Available but not auto-installed

DNF history:
  Transaction database: /var/lib/dnf/
  Each operation gets transaction ID
  Can undo/redo transactions
  Useful for auditing and rollback

Repository management:
  Enabled: Used for package operations
  Disabled: Ignored unless explicitly enabled
  Runtime flags: --enablerepo, --disablerepo
  Do not modify config files


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting sudo for installation
  dnf install package → Permission denied
  sudo dnf install package → Correct

Mistake 2: Not using quotes for group names
  dnf group info Development Tools → Error
  dnf group info "Development Tools" → Correct

Mistake 3: Confusing search and provides
  dnf search /usr/bin/tree → Searches for literal string
  dnf provides */tree → Finds package by file

Mistake 4: Expecting dependencies to be removed
  Removing package does not remove dependencies
  Use: dnf autoremove (carefully)

Mistake 5: Permanent vs temporary repo changes
  --disablerepo flag is temporary
  Edit .repo file for permanent changes


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Essential DNF commands for RHCSA:
1. dnf search - Find packages
2. dnf provides - Find package by file
3. dnf install - Install packages
4. dnf remove - Remove packages
5. dnf update - Update packages (kernel keeps old)
6. dnf group install - Install package groups
7. dnf history - View transactions
8. dnf history undo - Revert changes
9. dnf repolist - List repositories
10. dnf info - Show package details

Quick reference:
  • Use -y to skip confirmation
  • Tab completion works extensively
  • Group names need quotes if they contain spaces
  • check-update exit code 100 means updates available
  • history undo requires transaction ID
  • provides supports wildcards: */filename

Time-savers:
  • dnf list installed | wc -l → Count packages
  • dnf provides */COMMAND → Find package fast
  • dnf history | head → Recent transactions
  • dnf repoquery -l PACKAGE → List files without installing

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove test packages
    dnf remove -y tree wget 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/dnf-lab 2>/dev/null || true
    
    echo "  ✓ Test packages removed"
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
