#!/bin/bash
# labs/m04/14C-flatpak-troubleshooting.sh
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
    mkdir -p /tmp/package-lab 2>/dev/null || true
    
    # Install flatpak if not present
    if ! command -v flatpak >/dev/null 2>&1; then
        echo "  Installing flatpak..."
        dnf install -y flatpak >/dev/null 2>&1
    fi
    
    # Create a broken repository
    cat > /etc/yum.repos.d/broken-repo.repo << 'EOF'
[broken-repo]
name=Broken Repository
baseurl=http://does-not-exist.invalid.local/repo
enabled=1
gpgcheck=0
EOF
    
    # Install a test package that we'll work with
    dnf install -y tree >/dev/null 2>&1 || true
    
    # Corrupt DNF cache to create a scenario
    touch /var/cache/dnf/.broken-cache-marker
    
    echo "  ✓ Lab environment ready"
    echo "  ✓ Broken scenarios created"
    echo ""
    echo "  SCENARIO: Your system has several package management issues"
    echo "  You'll diagnose and fix them step by step"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • RPM and DNF basics
  • Repository configuration
  • Package management concepts

Commands You'll Use:
  • flatpak - Flatpak package manager
  • dnf - DNF package manager
  • rpm - RPM package manager

Files You'll Interact With:
  • /etc/yum.repos.d/ - Repository configuration
  • /var/cache/dnf/ - DNF cache
  • /var/lib/rpm/ - RPM database
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your RHEL system has multiple package management issues. DNF operations are
failing, and you need to diagnose and fix each problem systematically. You'll
also explore Flatpak as an alternative packaging system.

BACKGROUND:
Real-world systems often develop package management issues from interrupted
updates, network problems, or configuration errors. This lab simulates common
problems you'll encounter as a system administrator.

OBJECTIVES:
  1. Diagnose why DNF operations are failing
     • Try to update package lists
     • Identify the broken repository
     • Fix the repository issue
     • Verify DNF works again

  2. Clean up DNF cache issues
     • Check for cache problems
     • Clean the DNF cache completely
     • Rebuild repository metadata
     • Test DNF operations work smoothly

  3. Verify RPM database integrity
     • Check RPM database is healthy
     • Verify installed package integrity
     • Understand database location and structure
     • Know when rebuilding is necessary

  4. Install and configure Flatpak
     • Verify Flatpak is installed
     • Add a Flatpak remote repository
     • Search for available applications
     • Understand Flatpak architecture

  5. Compare package management systems
     • Install a package with DNF
     • Explore how Flatpak differs
     • Remove test packages
     • Understand when to use each system

HINTS:
  • DNF errors often point to the problem
  • Repository files are in /etc/yum.repos.d/
  • dnf clean all is powerful
  • Flatpak remotes provide applications
  • Each step builds on the previous

SUCCESS CRITERIA:
  • DNF repository issue resolved
  • DNF cache cleaned and rebuilt
  • RPM database verified healthy
  • Flatpak configured with remote
  • Understanding of both packaging systems
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Fix broken DNF repository
  ☐ 2. Clean and rebuild DNF cache
  ☐ 3. Verify RPM database integrity
  ☐ 4. Configure Flatpak with remote
  ☐ 5. Compare packaging systems
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
Your system has package management issues to diagnose and fix.

Working directory: /tmp/package-lab/

This is a sequential troubleshooting workflow.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Diagnose and fix DNF repository failure

Your first task is to identify why DNF is failing and fix the problem.

Requirements:
  • Try running: dnf repolist
  • Observe the error about a failing repository
  • Find the broken repository in /etc/yum.repos.d/
  • Fix it by setting enabled=0 or removing the file
  • Verify dnf repolist succeeds

Workflow:
  1. Attempt DNF operation to see error
  2. Identify which repository is broken
  3. Disable or remove the broken repository
  4. Confirm DNF works

This simulates a common real-world issue where a repository
becomes unavailable or is misconfigured.
EOF
}

validate_step_1() {
    # Check if broken repo is fixed
    local broken_enabled=0
    if [ -f /etc/yum.repos.d/broken-repo.repo ]; then
        if grep -q "enabled=1" /etc/yum.repos.d/broken-repo.repo 2>/dev/null; then
            broken_enabled=1
        fi
    fi
    
    if [ $broken_enabled -eq 1 ]; then
        echo ""
        print_color "$RED" "✗ Broken repository still enabled"
        echo "  The broken-repo is still causing issues"
        echo "  Hint: Edit /etc/yum.repos.d/broken-repo.repo"
        return 1
    fi
    
    # Verify DNF works
    if ! dnf repolist >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ DNF still not working"
        return 1
    fi
    
    return 0
}

hint_step_1() {
    echo "  Try: dnf repolist (observe error)"
    echo "  Check: ls /etc/yum.repos.d/"
    echo "  Fix: Edit broken-repo.repo, set enabled=0"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Try DNF operation
  dnf repolist

Step 2: Observe error about broken-repo

Step 3: Check repository files
  ls /etc/yum.repos.d/
  cat /etc/yum.repos.d/broken-repo.repo

Step 4: Fix the issue
  Option A - Disable:
    sudo vi /etc/yum.repos.d/broken-repo.repo
    Change: enabled=1 to enabled=0
  
  Option B - Remove:
    sudo rm /etc/yum.repos.d/broken-repo.repo

Step 5: Verify fix
  dnf repolist

Key learning: Repository errors prevent all DNF operations.
Always check enabled repositories when DNF fails.

EOF
}

hint_step_2() {
    echo "  Clean cache: sudo dnf clean all"
    echo "  Rebuild metadata: sudo dnf makecache"
    echo "  Test: dnf repolist"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Clean and rebuild DNF cache

Now that repositories work, clean up the DNF cache and rebuild metadata.

Requirements:
  • Remove all cached data: dnf clean all
  • Download fresh metadata: dnf makecache
  • Verify cache directory is clean
  • Test that DNF operations are fast and clean

Workflow:
  1. Clean all DNF cache
  2. Rebuild repository metadata
  3. Verify operations work smoothly

This fixes stale metadata and corrupted cache files.
EOF
}

validate_step_2() {
    # Check if the broken cache marker was removed
    # (this indicates they cleaned the cache)
    if [ -f /var/cache/dnf/.broken-cache-marker ]; then
        echo ""
        print_color "$RED" "✗ DNF cache not cleaned"
        echo "  Hint: Run dnf clean all"
        return 1
    fi
    
    # Check if metadata exists (indicates makecache was run)
    if ! ls /var/cache/dnf/*/repodata/repomd.xml >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Warning: Metadata may not be rebuilt"
        echo "  Hint: Run dnf makecache"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Clean all cache
  sudo dnf clean all

Step 2: Rebuild metadata
  sudo dnf makecache

Step 3: Verify
  ls /var/cache/dnf/
  dnf repolist

Understanding:
  dnf clean all removes:
  - Downloaded packages
  - Repository metadata
  - Database cache

  dnf makecache:
  - Downloads fresh metadata
  - Prepares for fast operations

When to clean cache:
  - After repository changes
  - When seeing stale package info
  - After network issues
  - For disk space recovery

EOF
}

hint_step_3() {
    echo "  Test database: rpm -qa | head"
    echo "  Verify package: rpm -V tree"
    echo "  Check location: ls /var/lib/rpm/"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Verify RPM database integrity

Confirm the RPM database is healthy and packages are intact.

Requirements:
  • Query the RPM database
  • Verify an installed package
  • Check database location
  • Understand database health

Workflow:
  1. Test RPM database by querying packages
  2. Verify the tree package integrity
  3. Check RPM database location
  4. Confirm database is healthy

This ensures the foundational package database is working correctly.
EOF
}

validate_step_3() {
    # Test RPM database works
    if ! rpm -qa >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ RPM database has issues"
        return 1
    fi
    
    # Test that tree package exists and is verified
    if ! rpm -q tree >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "  Note: tree package not found"
        echo "  This is okay if you removed it"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Test RPM database
  rpm -qa | head -20
  rpm -qa | wc -l

Step 2: Verify package integrity
  rpm -V tree

Step 3: Check database location
  ls -lh /var/lib/rpm/

Step 4: Understanding verification
  rpm -V tree output:
  - No output = package intact
  - S = Size changed
  - M = Mode changed
  - 5 = MD5 checksum changed
  - L = Symlink changed
  - U = User changed
  - G = Group changed
  - T = Modification time changed

Database health checks:
  - rpm -qa should complete quickly
  - No errors during queries
  - Verification completes successfully

When to rebuild database:
  - rpm commands hang
  - Database corruption errors
  - Inconsistent query results
  Command: rpm --rebuilddb

EOF
}

hint_step_4() {
    echo "  Check version: flatpak --version"
    echo "  Add remote: flatpak remote-add --if-not-exists NAME URL"
    echo "  List remotes: flatpak remotes"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Install and configure Flatpak

Set up Flatpak as an alternative packaging system.

Requirements:
  • Verify Flatpak is installed
  • Add the Fedora registry as a remote
  • List configured remotes
  • Search for an application

Workflow:
  1. Check Flatpak installation
  2. Add Fedora remote: oci+https://registry.fedoraproject.org
  3. Verify remote is added
  4. Search for applications

Remote URL to use:
  oci+https://registry.fedoraproject.org

Remote name to use:
  fedora
EOF
}

validate_step_4() {
    # Check Flatpak is installed
    if ! command -v flatpak >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Flatpak not installed"
        return 1
    fi
    
    # Check if fedora remote exists
    if ! flatpak remotes | grep -q "fedora"; then
        echo ""
        print_color "$RED" "✗ Fedora remote not added"
        echo "  Hint: flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Verify Flatpak
  flatpak --version
  which flatpak

Step 2: Add Fedora remote
  flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org

Step 3: List remotes
  flatpak remotes
  flatpak remotes -d

Step 4: Search applications
  flatpak search firefox
  flatpak search gimp

Understanding Flatpak:
  Architecture:
  - Container-based applications
  - Includes all dependencies
  - Sandboxed execution
  - Cross-distribution

  Remotes:
  - OCI registries with applications
  - Similar to DNF repositories
  - Common: Flathub, Fedora

  Application IDs:
  - Format: org.domain.appname
  - Example: org.mozilla.firefox

  When to use:
  - Desktop applications
  - User-level installs
  - Need latest versions
  - Cross-platform apps

EOF
}

hint_step_5() {
    echo "  Install with DNF: sudo dnf install nano"
    echo "  Check size: rpm -qi nano | grep Size"
    echo "  Remove: sudo dnf remove nano"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Compare packaging systems

Install a small package with DNF and understand the differences
between DNF and Flatpak packaging.

Requirements:
  • Install nano with DNF
  • Check package size and dependencies
  • Remove the package
  • Compare with Flatpak approach

Workflow:
  1. Install nano using DNF
  2. Check package information
  3. Verify it's installed
  4. Remove the package
  5. Understand DNF vs Flatpak trade-offs

This demonstrates traditional package management workflow.
EOF
}

validate_step_5() {
    # We don't require nano to be installed at validation
    # Just that they understand the process
    # Check if they tried installing (it's okay if removed)
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Install with DNF
  sudo dnf install -y nano

Step 2: Check package info
  rpm -qi nano
  rpm -ql nano | head
  rpm -qR nano

Step 3: Verify installation
  which nano
  nano --version

Step 4: Remove package
  sudo dnf remove -y nano

Step 5: Compare approaches

DNF (traditional):
  Pros:
  - Tight system integration
  - Smaller package size
  - Shared libraries
  - Distribution tested
  
  Cons:
  - Distribution specific
  - Dependency conflicts possible
  - Requires root for install
  - System-wide only

Flatpak (container):
  Pros:
  - Cross-distribution
  - Isolated dependencies
  - User-level installs possible
  - Sandboxed security
  
  Cons:
  - Larger downloads
  - More disk space
  - Less system integration
  - Best for desktop apps

Use DNF for:
  - System packages
  - Server software
  - Daemons and services
  - CLI tools

Use Flatpak for:
  - Desktop applications
  - GUI programs
  - Latest software versions
  - User applications

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your package management troubleshooting..."
    echo ""
    
    # CHECK 1: Repository fixed
    print_color "$CYAN" "[1/$total] Checking repository fix..."
    local broken_enabled=0
    if [ -f /etc/yum.repos.d/broken-repo.repo ]; then
        if grep -q "enabled=1" /etc/yum.repos.d/broken-repo.repo 2>/dev/null; then
            broken_enabled=1
        fi
    fi
    
    if [ $broken_enabled -eq 0 ]; then
        print_color "$GREEN" "  ✓ Broken repository fixed"
        ((score++))
    else
        print_color "$RED" "  ✗ Repository still broken"
        print_color "$YELLOW" "  Fix: Disable or remove broken-repo.repo"
    fi
    echo ""
    
    # CHECK 2: Cache cleaned
    print_color "$CYAN" "[2/$total] Checking DNF cache..."
    if [ ! -f /var/cache/dnf/.broken-cache-marker ]; then
        print_color "$GREEN" "  ✓ DNF cache cleaned"
        ((score++))
    else
        print_color "$RED" "  ✗ DNF cache not cleaned"
        print_color "$YELLOW" "  Fix: Run dnf clean all"
    fi
    echo ""
    
    # CHECK 3: RPM database
    print_color "$CYAN" "[3/$total] Checking RPM database..."
    if rpm -qa >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ RPM database healthy"
        ((score++))
    else
        print_color "$RED" "  ✗ RPM database has issues"
        print_color "$YELLOW" "  Fix: Check rpm commands work"
    fi
    echo ""
    
    # CHECK 4: Flatpak configured
    print_color "$CYAN" "[4/$total] Checking Flatpak configuration..."
    if command -v flatpak >/dev/null 2>&1 && flatpak remotes | grep -q "fedora"; then
        print_color "$GREEN" "  ✓ Flatpak configured with remote"
        ((score++))
    else
        print_color "$RED" "  ✗ Flatpak not fully configured"
        print_color "$YELLOW" "  Fix: Add fedora remote"
    fi
    echo ""
    
    # CHECK 5: Understanding demonstrated
    print_color "$CYAN" "[5/$total] Checking package management understanding..."
    if [ $score -ge 3 ]; then
        print_color "$GREEN" "  ✓ Demonstrated troubleshooting skills"
        ((score++))
    else
        print_color "$YELLOW" "  Complete previous steps to demonstrate understanding"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You successfully:"
        echo "  • Fixed DNF repository issues"
        echo "  • Cleaned and rebuilt DNF cache"
        echo "  • Verified RPM database integrity"
        echo "  • Configured Flatpak with remote"
        echo "  • Understand both packaging systems"
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

STEP 1: Fix broken repository
─────────────────────────────────────────────────────────────────
dnf repolist
sudo vi /etc/yum.repos.d/broken-repo.repo
# Change enabled=1 to enabled=0
dnf repolist


STEP 2: Clean DNF cache
─────────────────────────────────────────────────────────────────
sudo dnf clean all
sudo dnf makecache
dnf repolist


STEP 3: Verify RPM database
─────────────────────────────────────────────────────────────────
rpm -qa | head
rpm -V tree
ls /var/lib/rpm/


STEP 4: Configure Flatpak
─────────────────────────────────────────────────────────────────
flatpak --version
flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org
flatpak remotes
flatpak search firefox


STEP 5: Compare systems
─────────────────────────────────────────────────────────────────
sudo dnf install -y nano
rpm -qi nano
sudo dnf remove -y nano


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Repository troubleshooting:
  - Check /etc/yum.repos.d/
  - Disable with enabled=0
  - Check /var/log/dnf.log

Cache management:
  - Location: /var/cache/dnf/
  - Clean: dnf clean all
  - Rebuild: dnf makecache

RPM database:
  - Location: /var/lib/rpm/
  - Test: rpm -qa
  - Verify: rpm -V PACKAGE
  - Rebuild: rpm --rebuilddb

Flatpak vs DNF:
  DNF: System packages, tight integration
  Flatpak: Desktop apps, sandboxed


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DNF fails? Check repositories first
2. Stale metadata? Clean cache
3. Package issues? Verify with rpm -V
4. Always check /var/log/dnf.log
5. Flatpak for desktop, DNF for system

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove broken repository
    rm -f /etc/yum.repos.d/broken-repo.repo 2>/dev/null || true
    
    # Remove cache marker
    rm -f /var/cache/dnf/.broken-cache-marker 2>/dev/null || true
    
    # Remove test packages
    dnf remove -y tree nano 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/package-lab 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
