#!/bin/bash
# labs/m04/12C-flatpak-troubleshooting.sh
# Lab: Understanding Flatpak and troubleshooting package management
# Difficulty: Intermediate
# RHCSA Objective: 12.8, 12.9 - Flatpak management and package troubleshooting

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Understanding Flatpak and troubleshooting package management"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="35-45 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create working directory
    mkdir -p /tmp/flatpak-lab 2>/dev/null || true
    
    # Install flatpak if not present
    if ! command -v flatpak >/dev/null 2>&1; then
        echo "  Installing flatpak..."
        dnf install -y flatpak >/dev/null 2>&1
    fi
    
    # Create a broken repository scenario for troubleshooting
    cat > /etc/yum.repos.d/broken-test.repo << 'EOF'
[broken-test]
name=Broken Test Repository
baseurl=http://invalid.example.com/repo
enabled=1
gpgcheck=1
EOF
    
    echo "  ✓ Lab environment ready"
    echo "  ✓ Flatpak installed"
    echo "  ✓ Troubleshooting scenarios prepared"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of RPM and DNF
  • Repository configuration basics
  • Container concepts helpful but not required

Commands You'll Use:
  • flatpak - Flatpak package manager
  • flatpak remote-add - Add remote repositories
  • flatpak search - Search for applications
  • flatpak install - Install applications
  • flatpak list - List installed apps
  • flatpak remove - Remove applications
  • dnf - For troubleshooting DNF issues

Files You'll Interact With:
  • /etc/flatpak/remotes.d/ - Flatpak remote repositories
  • /var/lib/flatpak/ - Flatpak data directory
  • /etc/yum.repos.d/ - DNF repository configuration
  • /var/log/dnf.log - DNF operation log
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You are a system administrator learning modern package management with Flatpak
and developing troubleshooting skills for common RPM, DNF, and repository
issues. Your organization is evaluating Flatpak for desktop applications while
maintaining traditional DNF for server packages.

BACKGROUND:
Flatpak provides containerized applications that work across distributions.
Understanding both Flatpak and traditional package management is important for
modern RHEL administration. You also need strong troubleshooting skills for
when package operations fail.

OBJECTIVES:
  1. Explore Flatpak installation and configuration
     • Verify flatpak is installed
     • Check flatpak version
     • List configured remotes
     • Understand Flatpak vs DNF use cases
     • Document in /tmp/flatpak-lab/flatpak-setup.txt

  2. Work with Flatpak remotes
     • List available remotes
     • Add Fedora registry remote (if not present)
     • List applications in a remote
     • Understand OCI registry concept
     • Document in /tmp/flatpak-lab/remotes.txt

  3. Search and explore Flatpak applications
     • Search for available applications
     • Show information about an application
     • Understand application IDs and naming
     • Document findings in /tmp/flatpak-lab/search-results.txt

  4. Troubleshoot DNF repository issues
     • Identify the broken repository in /etc/yum.repos.d/
     • Attempt dnf operation and observe error
     • Fix by disabling or removing broken repo
     • Verify dnf works again
     • Document in /tmp/flatpak-lab/dnf-troubleshooting.txt

  5. Troubleshoot RPM database issues
     • Simulate common RPM problems
     • Check RPM database integrity
     • Understand when to rebuild database
     • Learn to verify package installation
     • Document in /tmp/flatpak-lab/rpm-troubleshooting.txt

  6. Practice DNF cache and metadata troubleshooting
     • Clean DNF cache
     • Rebuild metadata
     • Understand makecache operation
     • Test after cleaning
     • Document in /tmp/flatpak-lab/cache-troubleshooting.txt

HINTS:
  • flatpak --version shows installation
  • flatpak remotes lists configured remotes
  • DNF errors often point to repository issues
  • Check /var/log/dnf.log for detailed errors
  • dnf clean all removes cache
  • Broken repos can be disabled without removal

SUCCESS CRITERIA:
  • Flatpak configuration explored
  • Remotes managed successfully
  • Application search completed
  • DNF repository issue resolved
  • RPM troubleshooting understood
  • DNF cache management demonstrated
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore Flatpak installation and configuration
  ☐ 2. Work with Flatpak remotes
  ☐ 3. Search and explore Flatpak applications
  ☐ 4. Troubleshoot DNF repository issues
  ☐ 5. Troubleshoot RPM database issues
  ☐ 6. Practice DNF cache troubleshooting
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
You are learning Flatpak and developing package management troubleshooting
skills for RHEL systems.

Output directory: /tmp/flatpak-lab/

NOTE: A broken repository has been created for troubleshooting practice.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore Flatpak installation and configuration

Learn about Flatpak installation, verify it works, and understand when to
use Flatpak versus DNF for package management.

Requirements:
  • Check if flatpak is installed
  • Display flatpak version
  • List configured Flatpak remotes
  • Compare Flatpak and DNF use cases
  • Save findings to /tmp/flatpak-lab/flatpak-setup.txt

Commands to explore:
  • flatpak --version
  • flatpak remotes
  • which flatpak
  • rpm -q flatpak

Questions to consider:
  • When should you use Flatpak vs DNF?
  • What are Flatpak remotes?
  • Where does Flatpak store data?
EOF
}

validate_step_1() {
    if [ ! -f /tmp/flatpak-lab/flatpak-setup.txt ]; then
        echo ""
        print_color "$RED" "✗ flatpak-setup.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/flatpak-lab/flatpak-setup.txt ]; then
        echo ""
        print_color "$RED" "✗ flatpak-setup.txt is empty"
        return 1
    fi
    
    return 0
}

hint_step_1() {
    echo "  Check version: flatpak --version"
    echo "  List remotes: flatpak remotes"
    echo "  Verify install: rpm -q flatpak"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Check installation:
  which flatpak
  flatpak --version
  rpm -q flatpak

List remotes:
  flatpak remotes

Document:
  echo "=== FLATPAK INSTALLATION ===" > /tmp/flatpak-lab/flatpak-setup.txt
  flatpak --version >> /tmp/flatpak-lab/flatpak-setup.txt
  echo "" >> /tmp/flatpak-lab/flatpak-setup.txt
  echo "=== CONFIGURED REMOTES ===" >> /tmp/flatpak-lab/flatpak-setup.txt
  flatpak remotes >> /tmp/flatpak-lab/flatpak-setup.txt

Understanding use cases:
  Flatpak best for:
  - Desktop applications
  - Cross-distribution compatibility
  - Sandboxed applications
  - User-installed software
  
  DNF best for:
  - System packages
  - Server daemons
  - Packages needing system integration
  - Traditional RHEL packages

EOF
}

hint_step_2() {
    echo "  List remotes: flatpak remotes"
    echo "  Add remote: flatpak remote-add NAME URL"
    echo "  List apps: flatpak remote-ls REMOTE_NAME"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Work with Flatpak remotes

Flatpak remotes are repositories that provide applications. Learn to list,
add, and explore remotes.

Requirements:
  • List current Flatpak remotes
  • Understand remote repository structure
  • Optionally add Fedora remote if not present
  • List applications in a remote
  • Document in /tmp/flatpak-lab/remotes.txt

Commands to explore:
  • flatpak remotes
  • flatpak remote-ls
  • flatpak remote-add

Note: Adding remotes requires understanding OCI registries
Common remote: oci+https://registry.fedoraproject.org

Explore:
  • What does OCI stand for?
  • How many remotes are configured?
  • What applications are available?
EOF
}

validate_step_2() {
    if [ ! -f /tmp/flatpak-lab/remotes.txt ]; then
        echo ""
        print_color "$RED" "✗ remotes.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/flatpak-lab/remotes.txt ]; then
        echo ""
        print_color "$RED" "✗ remotes.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
List remotes:
  flatpak remotes
  flatpak remotes -d

Add Fedora remote (if desired):
  flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org

List applications in remote:
  flatpak remote-ls fedora --app

Document:
  flatpak remotes -d > /tmp/flatpak-lab/remotes.txt
  echo "" >> /tmp/flatpak-lab/remotes.txt
  echo "=== AVAILABLE APPLICATIONS ===" >> /tmp/flatpak-lab/remotes.txt
  flatpak remote-ls --app 2>/dev/null | head -20 >> /tmp/flatpak-lab/remotes.txt

Understanding:
  OCI: Open Container Initiative
  Remotes stored in /etc/flatpak/remotes.d/
  Each remote has metadata updated daily
  --if-not-exists prevents duplicate adds

EOF
}

hint_step_3() {
    echo "  Search: flatpak search KEYWORD"
    echo "  Show info: flatpak info APP_ID"
    echo "  Note: Search requires configured remotes"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Search and explore Flatpak applications

Learn to search for Flatpak applications and view their information.

Requirements:
  • Search for applications by keyword
  • View information about an application
  • Understand application ID format
  • Document in /tmp/flatpak-lab/search-results.txt

Commands to use:
  • flatpak search KEYWORD
  • flatpak info APP_ID

Explore:
  • What is an application ID?
  • How are Flatpak apps named?
  • What information does flatpak info show?

Note: This is exploration only, no installation required
EOF
}

validate_step_3() {
    if [ ! -f /tmp/flatpak-lab/search-results.txt ]; then
        echo ""
        print_color "$RED" "✗ search-results.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/flatpak-lab/search-results.txt ]; then
        echo ""
        print_color "$RED" "✗ search-results.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Search for applications:
  flatpak search firefox
  flatpak search editor

View app information:
  flatpak info org.mozilla.firefox

Document:
  flatpak search editor > /tmp/flatpak-lab/search-results.txt 2>&1
  echo "" >> /tmp/flatpak-lab/search-results.txt
  echo "=== APPLICATION INFO EXAMPLE ===" >> /tmp/flatpak-lab/search-results.txt
  echo "Command: flatpak info APP_ID" >> /tmp/flatpak-lab/search-results.txt

Understanding:
  Application ID format: org.domain.appname
  Examples: org.mozilla.firefox, org.gnome.gedit
  Search queries remote metadata
  Info shows version, runtime, permissions

EOF
}

hint_step_4() {
    echo "  List repos: ls /etc/yum.repos.d/"
    echo "  Try dnf: dnf repolist"
    echo "  Fix: Disable or remove broken-test.repo"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Troubleshoot DNF repository issues

A broken repository has been configured. Practice identifying and fixing
repository problems that prevent DNF operations.

Requirements:
  • Find the broken repository file
  • Try a DNF operation and observe the error
  • Fix the issue by disabling or removing the repo
  • Verify DNF works after fix
  • Document process in /tmp/flatpak-lab/dnf-troubleshooting.txt

Troubleshooting steps:
  1. Identify broken repo in /etc/yum.repos.d/
  2. Attempt: dnf repolist
  3. Observe error message
  4. Fix: disable enabled=0 or remove file
  5. Verify: dnf repolist succeeds

Explore:
  • What errors indicate repository problems?
  • How do you disable vs remove a repo?
  • Where are error details logged?
EOF
}

validate_step_4() {
    # Check if broken repo is fixed (disabled or removed)
    local broken_enabled=0
    if [ -f /etc/yum.repos.d/broken-test.repo ]; then
        if grep -q "enabled=1" /etc/yum.repos.d/broken-test.repo 2>/dev/null; then
            broken_enabled=1
        fi
    fi
    
    if [ $broken_enabled -eq 1 ]; then
        echo ""
        print_color "$RED" "✗ Broken repository still enabled"
        echo "  Fix: Disable or remove /etc/yum.repos.d/broken-test.repo"
        return 1
    fi
    
    if [ ! -f /tmp/flatpak-lab/dnf-troubleshooting.txt ]; then
        echo ""
        print_color "$RED" "✗ dnf-troubleshooting.txt not found"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Identify broken repo:
  ls /etc/yum.repos.d/
  cat /etc/yum.repos.d/broken-test.repo

Attempt DNF operation:
  dnf repolist
  # Observe error about broken-test repository

Fix option 1 - Disable:
  sudo vi /etc/yum.repos.d/broken-test.repo
  # Change enabled=1 to enabled=0

Fix option 2 - Remove:
  sudo rm /etc/yum.repos.d/broken-test.repo

Verify fix:
  dnf repolist

Document:
  cat > /tmp/flatpak-lab/dnf-troubleshooting.txt << 'ENDFILE'
Problem: broken-test repository with invalid URL
Error: Cannot retrieve repository metadata
Fix: Disabled broken repository
Result: DNF operations successful
ENDFILE

Understanding:
  Repository errors prevent all DNF operations
  Check /var/log/dnf.log for details
  enabled=0 disables repository
  Removing .repo file permanent solution
  Can use --disablerepo flag as workaround

EOF
}

hint_step_5() {
    echo "  Check database: rpm -qa | wc -l"
    echo "  Verify package: rpm -V PACKAGE"
    echo "  Rebuild db: rpm --rebuilddb"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Troubleshoot RPM database issues

Learn to identify and resolve common RPM database problems. Understand when
database rebuilding is necessary.

Requirements:
  • Verify RPM database is functional
  • Learn to check package integrity
  • Understand database rebuild process
  • Document in /tmp/flatpak-lab/rpm-troubleshooting.txt

Commands to explore:
  • rpm -qa: Query all packages (tests database)
  • rpm -V PACKAGE: Verify package integrity
  • rpm --rebuilddb: Rebuild database indexes
  • rpm -q --verify bash: Verify specific package

Explore:
  • Where is RPM database stored?
  • What causes database corruption?
  • When should you rebuild the database?

Note: Do not actually rebuild unless necessary
EOF
}

validate_step_5() {
    if [ ! -f /tmp/flatpak-lab/rpm-troubleshooting.txt ]; then
        echo ""
        print_color "$RED" "✗ rpm-troubleshooting.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/flatpak-lab/rpm-troubleshooting.txt ]; then
        echo ""
        print_color "$RED" "✗ rpm-troubleshooting.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Test RPM database:
  rpm -qa | wc -l
  # Should return count of packages

Verify package integrity:
  rpm -V bash
  # No output means package is intact

Check specific files:
  rpm -V --noconfig bash
  # Ignore config file changes

Document:
  cat > /tmp/flatpak-lab/rpm-troubleshooting.txt << 'ENDFILE'
RPM DATABASE TROUBLESHOOTING

Database location: /var/lib/rpm/

Test database:
  rpm -qa | wc -l

Verify package:
  rpm -V PACKAGE

Rebuild database (if corrupted):
  sudo rpm --rebuilddb

Common issues:
- Database locks from interrupted operations
- Corruption from system crashes
- Permission problems

Signs of corruption:
- rpm commands hang
- Errors about database
- Inconsistent query results

When to rebuild:
- After database corruption
- When queries behave strangely
- As last resort for rpm issues
ENDFILE

Understanding:
  RPM database: /var/lib/rpm/
  Stores package metadata and file ownership
  Corruption rare but serious
  Always backup before rebuild
  rpm -V checks file integrity

EOF
}

hint_step_6() {
    echo "  Clean cache: dnf clean all"
    echo "  Rebuild metadata: dnf makecache"
    echo "  Test: dnf repolist"
}

# STEP 6
show_step_6() {
    cat << 'EOF'
TASK: Practice DNF cache and metadata troubleshooting

Learn to manage DNF cache and metadata. Understand when cache cleaning
resolves issues.

Requirements:
  • Clean DNF cache
  • Rebuild repository metadata
  • Understand cache location
  • Test DNF after cleaning
  • Document in /tmp/flatpak-lab/cache-troubleshooting.txt

Commands to use:
  • dnf clean all
  • dnf makecache
  • dnf repolist

Explore:
  • Where is DNF cache stored?
  • What does makecache do?
  • When should you clean cache?
EOF
}

validate_step_6() {
    if [ ! -f /tmp/flatpak-lab/cache-troubleshooting.txt ]; then
        echo ""
        print_color "$RED" "✗ cache-troubleshooting.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/flatpak-lab/cache-troubleshooting.txt ]; then
        echo ""
        print_color "$RED" "✗ cache-troubleshooting.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Clean DNF cache:
  sudo dnf clean all

Rebuild metadata cache:
  sudo dnf makecache

Test DNF:
  dnf repolist

Document:
  cat > /tmp/flatpak-lab/cache-troubleshooting.txt << 'ENDFILE'
DNF CACHE TROUBLESHOOTING

Cache location: /var/cache/dnf/

Clean cache:
  dnf clean all
  - Removes all cached data
  - Removes downloaded packages
  - Removes metadata

Rebuild cache:
  dnf makecache
  - Downloads fresh metadata
  - Updates repository information

When to clean cache:
- Repository metadata errors
- After repository configuration changes
- Stale package information
- Disk space recovery

Cache types:
- metadata: Repository information
- packages: Downloaded RPMs
- dbcache: Database cache

Best practices:
- Clean after repo changes
- Use makecache to refresh
- Check /var/log/dnf.log for issues
ENDFILE

Understanding:
  DNF caches metadata for performance
  Stale cache causes issues
  clean all removes everything
  makecache rebuilds metadata
  Happens automatically periodically

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your Flatpak and troubleshooting work..."
    echo ""
    
    # CHECK 1: Flatpak setup
    print_color "$CYAN" "[1/$total] Checking Flatpak setup..."
    if [ -f /tmp/flatpak-lab/flatpak-setup.txt ] && \
       [ -s /tmp/flatpak-lab/flatpak-setup.txt ]; then
        print_color "$GREEN" "  ✓ Flatpak setup documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Flatpak setup not documented"
        print_color "$YELLOW" "  Hint: Use flatpak --version and flatpak remotes"
    fi
    echo ""
    
    # CHECK 2: Flatpak remotes
    print_color "$CYAN" "[2/$total] Checking Flatpak remotes..."
    if [ -f /tmp/flatpak-lab/remotes.txt ] && \
       [ -s /tmp/flatpak-lab/remotes.txt ]; then
        print_color "$GREEN" "  ✓ Flatpak remotes documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Flatpak remotes not documented"
        print_color "$YELLOW" "  Hint: Use flatpak remotes and flatpak remote-ls"
    fi
    echo ""
    
    # CHECK 3: Flatpak search
    print_color "$CYAN" "[3/$total] Checking Flatpak search..."
    if [ -f /tmp/flatpak-lab/search-results.txt ] && \
       [ -s /tmp/flatpak-lab/search-results.txt ]; then
        print_color "$GREEN" "  ✓ Flatpak search documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Flatpak search not documented"
        print_color "$YELLOW" "  Hint: Use flatpak search"
    fi
    echo ""
    
    # CHECK 4: DNF repository troubleshooting
    print_color "$CYAN" "[4/$total] Checking DNF repository fix..."
    local broken_enabled=0
    if [ -f /etc/yum.repos.d/broken-test.repo ]; then
        if grep -q "enabled=1" /etc/yum.repos.d/broken-test.repo 2>/dev/null; then
            broken_enabled=1
        fi
    fi
    
    if [ $broken_enabled -eq 0 ] && \
       [ -f /tmp/flatpak-lab/dnf-troubleshooting.txt ]; then
        print_color "$GREEN" "  ✓ DNF repository issue resolved"
        ((score++))
    else
        print_color "$RED" "  ✗ DNF repository not fixed"
        print_color "$YELLOW" "  Hint: Disable or remove broken-test.repo"
    fi
    echo ""
    
    # CHECK 5: RPM troubleshooting
    print_color "$CYAN" "[5/$total] Checking RPM troubleshooting..."
    if [ -f /tmp/flatpak-lab/rpm-troubleshooting.txt ] && \
       [ -s /tmp/flatpak-lab/rpm-troubleshooting.txt ]; then
        print_color "$GREEN" "  ✓ RPM troubleshooting documented"
        ((score++))
    else
        print_color "$RED" "  ✗ RPM troubleshooting not documented"
        print_color "$YELLOW" "  Hint: Document RPM database verification"
    fi
    echo ""
    
    # CHECK 6: DNF cache troubleshooting
    print_color "$CYAN" "[6/$total] Checking DNF cache troubleshooting..."
    if [ -f /tmp/flatpak-lab/cache-troubleshooting.txt ] && \
       [ -s /tmp/flatpak-lab/cache-troubleshooting.txt ]; then
        print_color "$GREEN" "  ✓ DNF cache troubleshooting documented"
        ((score++))
    else
        print_color "$RED" "  ✗ DNF cache troubleshooting not documented"
        print_color "$YELLOW" "  Hint: Use dnf clean and dnf makecache"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Flatpak installation and configuration"
        echo "  • Managing Flatpak remotes"
        echo "  • Searching for Flatpak applications"
        echo "  • Troubleshooting DNF repository issues"
        echo "  • RPM database verification"
        echo "  • DNF cache management"
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

OBJECTIVE 1: Flatpak setup
─────────────────────────────────────────────────────────────────
Check installation:
  flatpak --version
  rpm -q flatpak

List remotes:
  flatpak remotes

Document:
  flatpak --version > /tmp/flatpak-lab/flatpak-setup.txt
  flatpak remotes >> /tmp/flatpak-lab/flatpak-setup.txt


OBJECTIVE 2: Flatpak remotes
─────────────────────────────────────────────────────────────────
List remotes:
  flatpak remotes -d

Add remote (optional):
  flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org

List apps:
  flatpak remote-ls fedora --app


OBJECTIVE 3: Search applications
─────────────────────────────────────────────────────────────────
Search:
  flatpak search firefox

Show info:
  flatpak info org.mozilla.firefox


OBJECTIVE 4: Fix DNF repository
─────────────────────────────────────────────────────────────────
Identify problem:
  dnf repolist
  # Observe error

Fix - Disable:
  sudo vi /etc/yum.repos.d/broken-test.repo
  # Change enabled=1 to enabled=0

Fix - Remove:
  sudo rm /etc/yum.repos.d/broken-test.repo

Verify:
  dnf repolist


OBJECTIVE 5: RPM troubleshooting
─────────────────────────────────────────────────────────────────
Test database:
  rpm -qa | wc -l

Verify package:
  rpm -V bash

Rebuild if needed:
  sudo rpm --rebuilddb


OBJECTIVE 6: DNF cache
─────────────────────────────────────────────────────────────────
Clean cache:
  sudo dnf clean all

Rebuild metadata:
  sudo dnf makecache

Test:
  dnf repolist


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Flatpak architecture:
  Container-based application delivery
  Sandboxed execution environment
  Runtime dependencies included
  Cross-distribution compatibility

Flatpak vs DNF:
  Flatpak:
  - Desktop applications
  - User-level installs possible
  - Sandboxed security
  - Distribution-independent
  
  DNF:
  - System packages
  - Server software
  - System integration
  - RHEL-specific packages

Flatpak remotes:
  OCI registries containing applications
  Stored in /etc/flatpak/remotes.d/
  Common: Flathub, Fedora Registry
  Updated automatically

DNF repository troubleshooting:
  Common causes:
  - Invalid URLs
  - Network issues
  - Missing GPG keys
  - Incorrect configuration
  
  Solutions:
  - Disable problematic repos
  - Fix configuration
  - Use --disablerepo temporarily
  - Check /var/log/dnf.log

RPM database issues:
  Location: /var/lib/rpm/
  
  Problems:
  - Corruption from crashes
  - Lock files from interrupted ops
  - Permission issues
  
  Solutions:
  - Remove lock files
  - Rebuild database
  - Verify integrity

DNF cache management:
  Location: /var/cache/dnf/
  
  When to clean:
  - Stale metadata
  - After repo changes
  - Disk space issues
  - Strange package behavior
  
  Commands:
  - dnf clean all: Remove everything
  - dnf clean metadata: Remove metadata only
  - dnf makecache: Rebuild metadata


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Not cleaning cache after repo changes
  Result: Stale metadata causes issues
  Fix: dnf clean all after changes

Mistake 2: Rebuilding RPM database unnecessarily
  Result: Wasted time
  Fix: Only rebuild when corrupted

Mistake 3: Removing repos instead of disabling
  Result: Permanent removal
  Fix: Disable with enabled=0 first

Mistake 4: Confusing Flatpak and DNF use cases
  Result: Wrong tool for the job
  Fix: Use Flatpak for desktop, DNF for system


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Flatpak commands:
1. flatpak remotes - List configured remotes
2. flatpak search - Find applications
3. flatpak install - Install application
4. flatpak list - Show installed apps
5. flatpak remove - Uninstall application

DNF troubleshooting:
1. Check /var/log/dnf.log for details
2. dnf clean all fixes many cache issues
3. Disable broken repos with enabled=0
4. Use --disablerepo for temporary fix
5. dnf repolist shows repo status

RPM troubleshooting:
1. rpm -qa tests database
2. rpm -V verifies package integrity
3. rpm --rebuilddb fixes corruption
4. Check /var/lib/rpm/ for lock files
5. Database issues are rare

Quick fixes:
  Repository error → Disable repo or clean cache
  Package conflict → Check dependencies
  Metadata error → dnf clean all; dnf makecache
  Database error → rpm --rebuilddb

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove broken test repository
    rm -f /etc/yum.repos.d/broken-test.repo 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/flatpak-lab 2>/dev/null || true
    
    echo "  ✓ Broken repository removed"
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
