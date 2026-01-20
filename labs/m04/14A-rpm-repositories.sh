#!/bin/bash
# labs/m04/14A-rpm-repositories.sh
# Lab: Understanding RPMs and repositories
# Difficulty: Beginner
# RHCSA Objective: 12.2, 12.3 - RPM package management and repository configuration

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Understanding RPMs and repositories"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="30-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create working directory
    mkdir -p /tmp/rpm-lab 2>/dev/null || true
    
    # Backup repository configuration
    mkdir -p /tmp/rpm-lab-backup 2>/dev/null || true
    cp -r /etc/yum.repos.d/* /tmp/rpm-lab-backup/ 2>/dev/null || true
    
    echo "  ✓ Lab environment ready"
    echo "  ✓ Repository configuration backed up"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of software packages
  • Familiarity with Linux file system
  • Understanding of repositories concept

Commands You'll Use:
  • rpm - Query and analyze RPM packages
  • rpm2cpio - Extract package contents
  • cpio - Archive utility
  • dnf config-manager - Manage repositories

Files You'll Interact With:
  • /etc/yum.repos.d/ - Repository configuration directory
  • /var/lib/rpm/ - RPM database
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You are a new system administrator learning how RPM packages work and how to
configure repository access. Your manager wants you to understand package
metadata, dependencies, and repository configuration before managing production
systems.

BACKGROUND:
RPM (Red Hat Package Manager) is the foundation of software management on RHEL.
Understanding how to query packages, examine their contents, and configure
repositories is essential for system administration.

OBJECTIVES:
  1. Query the RPM database
     • Find which package provides /bin/bash
     • List all installed packages and count them
     • Show files installed by the bash package
     • View changelog for an installed package
     • Save your findings to /tmp/rpm-lab/package-queries.txt

  2. Analyze package metadata
     • Pick any installed package
     • Display its dependencies
     • Show scripts that run during installation
     • View package information
     • Document findings in /tmp/rpm-lab/package-metadata.txt

  3. Extract package contents without installing
     • Find an RPM file in /var/cache/dnf/ or download one
     • List contents using rpm2cpio and cpio
     • Extract files to /tmp/rpm-lab/extracted/
     • Document the process in /tmp/rpm-lab/extraction-notes.txt

  4. Examine repository configuration
     • List current repository files in /etc/yum.repos.d/
     • View contents of an existing repo file
     • Identify key directives: baseurl, gpgcheck, enabled
     • Document in /tmp/rpm-lab/repo-config.txt

  5. Create a custom repository configuration
     • Create /etc/yum.repos.d/custom-test.repo
     • Configure with: name, baseurl, gpgcheck=0, enabled=1
     • Use a fake baseurl like: file:///tmp/fake-repo
     • Verify with dnf repolist (it will show as unavailable, expected)
     • Document the configuration in /tmp/rpm-lab/custom-repo.txt

HINTS:
  • rpm -q queries packages
  • rpm -qa lists all packages
  • rpm -qf queries which package owns a file
  • rpm -ql lists files from a package
  • rpm --scripts shows installation scripts
  • rpm2cpio extracts without installing
  • Repository files end in .repo

SUCCESS CRITERIA:
  • All query results documented
  • Package metadata analyzed
  • Package contents extracted
  • Repository configuration understood
  • Custom repo file created
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Query RPM database for package information
  ☐ 2. Analyze package metadata and dependencies
  ☐ 3. Extract package contents without installing
  ☐ 4. Examine repository configuration files
  ☐ 5. Create custom repository configuration
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
You are learning RPM package management and repository configuration.

Output directory: /tmp/rpm-lab/
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Query the RPM database

The rpm command can query the RPM database to find information about installed
packages. Learn to find packages, their files, and metadata.

Requirements:
  • Find which package provides /bin/bash
  • Count total installed packages
  • List files from the bash package
  • View changelog for any package
  • Save findings to /tmp/rpm-lab/package-queries.txt

Key rpm query flags:
  • -q: Query
  • -a: All packages
  • -f: Which package owns this file
  • -l: List files in package
  • --changelog: Show package changelog

Think about:
  • How does rpm -qa differ from rpm -q?
  • What information is in a changelog?
  • How do you count lines of output?
EOF
}

validate_step_1() {
    if [ ! -f /tmp/rpm-lab/package-queries.txt ]; then
        echo ""
        print_color "$RED" "✗ package-queries.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/rpm-lab/package-queries.txt ]; then
        echo ""
        print_color "$RED" "✗ package-queries.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Query which package provides /bin/bash:
  rpm -qf /bin/bash
  # Output: bash-5.x.x

Count installed packages:
  rpm -qa | wc -l
  # Output: number of packages

List files from bash:
  rpm -ql bash

View changelog:
  rpm -q --changelog bash | head -20

Document findings:
  rpm -qf /bin/bash > /tmp/rpm-lab/package-queries.txt
  echo "Total packages: $(rpm -qa | wc -l)" >> /tmp/rpm-lab/package-queries.txt
  rpm -ql bash >> /tmp/rpm-lab/package-queries.txt

Understanding:
  • -q queries packages
  • -f finds package owning a file
  • -a lists all packages
  • -l lists files in package
  • Pipe to wc -l to count lines

EOF
}

hint_step_2() {
    echo "  Try: rpm -q --requires PACKAGE"
    echo "  Try: rpm -q --scripts PACKAGE"
    echo "  Try: rpm -qi PACKAGE"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Analyze package metadata

RPM packages contain metadata including dependencies and installation scripts.
Learn to examine this information.

Requirements:
  • Choose an installed package (like bash or coreutils)
  • Display package dependencies
  • Show installation/removal scripts
  • View package information
  • Save to /tmp/rpm-lab/package-metadata.txt

Useful rpm flags:
  • --requires: Show dependencies
  • --scripts: Show installation scripts
  • -qi: Query information

Explore:
  • What dependencies does bash have?
  • What scripts run when installing?
  • What information does -qi show?
EOF
}

validate_step_2() {
    if [ ! -f /tmp/rpm-lab/package-metadata.txt ]; then
        echo ""
        print_color "$RED" "✗ package-metadata.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/rpm-lab/package-metadata.txt ]; then
        echo ""
        print_color "$RED" "✗ package-metadata.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Analyze bash package:
  rpm -q --requires bash
  rpm -q --scripts bash
  rpm -qi bash

Save results:
  echo "=== DEPENDENCIES ===" > /tmp/rpm-lab/package-metadata.txt
  rpm -q --requires bash >> /tmp/rpm-lab/package-metadata.txt
  echo "" >> /tmp/rpm-lab/package-metadata.txt
  echo "=== SCRIPTS ===" >> /tmp/rpm-lab/package-metadata.txt
  rpm -q --scripts bash >> /tmp/rpm-lab/package-metadata.txt

Understanding:
  --requires shows what a package needs
  --scripts shows pre/post install actions
  -qi shows detailed package info

EOF
}

hint_step_3() {
    echo "  Find packages: ls /var/cache/dnf/*/*/packages/*.rpm | head -1"
    echo "  List contents: rpm2cpio PACKAGE.rpm | cpio -tv"
    echo "  Extract: rpm2cpio PACKAGE.rpm | cpio -idmv"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Extract package contents without installing

Learn to extract and examine RPM package files without installing them using
rpm2cpio and cpio utilities.

Requirements:
  • Find an RPM file (check /var/cache/dnf/)
  • List package contents
  • Extract to /tmp/rpm-lab/extracted/
  • Document in /tmp/rpm-lab/extraction-notes.txt

Tools to use:
  • rpm2cpio: Convert RPM to cpio archive
  • cpio: Archive utility
  • Flags: -t (list), -v (verbose), -i (extract), -d (directories), -m (preserve time)

Challenge:
  • How do you pipe rpm2cpio output to cpio?
  • What does -tv show vs -idmv do?
EOF
}

validate_step_3() {
    if [ ! -f /tmp/rpm-lab/extraction-notes.txt ]; then
        echo ""
        print_color "$RED" "✗ extraction-notes.txt not found"
        return 1
    fi
    
    if [ ! -d /tmp/rpm-lab/extracted ]; then
        echo ""
        print_color "$YELLOW" "  Note: /tmp/rpm-lab/extracted directory not found"
        echo "  Make sure you extracted package contents"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Find an RPM package:
  PKG=$(find /var/cache/dnf -name "*.rpm" 2>/dev/null | head -1)
  
  If nothing found, download one:
  dnf download --downloadonly bash

List contents:
  rpm2cpio $PKG | cpio -tv

Extract contents:
  mkdir -p /tmp/rpm-lab/extracted
  cd /tmp/rpm-lab/extracted
  rpm2cpio $PKG | cpio -idmv

Document:
  echo "Package extracted: $PKG" > /tmp/rpm-lab/extraction-notes.txt
  echo "Contents:" >> /tmp/rpm-lab/extraction-notes.txt
  rpm2cpio $PKG | cpio -tv >> /tmp/rpm-lab/extraction-notes.txt

Understanding:
  rpm2cpio converts RPM to cpio format
  Pipe output to cpio for processing
  -tv lists contents (table, verbose)
  -idmv extracts (input, dirs, preserve time, verbose)

EOF
}

hint_step_4() {
    echo "  List files: ls /etc/yum.repos.d/"
    echo "  View file: cat /etc/yum.repos.d/*.repo"
    echo "  Look for: [name], baseurl, gpgcheck, enabled"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Examine repository configuration

Repository configuration files define where dnf finds packages. Learn to read
and understand these configurations.

Requirements:
  • List repository files in /etc/yum.repos.d/
  • View at least one .repo file
  • Identify key directives
  • Document in /tmp/rpm-lab/repo-config.txt

Key directives to find:
  • [repository-id]: Section header
  • name: Human-readable name
  • baseurl: Repository URL
  • gpgcheck: Enable signature verification
  • enabled: Repository active status

Explore:
  • What makes a repository enabled or disabled?
  • Why use gpgcheck?
  • What URL schemes are supported?
EOF
}

validate_step_4() {
    if [ ! -f /tmp/rpm-lab/repo-config.txt ]; then
        echo ""
        print_color "$RED" "✗ repo-config.txt not found"
        return 1
    fi
    
    if [ ! -s /tmp/rpm-lab/repo-config.txt ]; then
        echo ""
        print_color "$RED" "✗ repo-config.txt is empty"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
List repository files:
  ls /etc/yum.repos.d/

View a repository file:
  cat /etc/yum.repos.d/redhat.repo

Document configuration:
  ls /etc/yum.repos.d/ > /tmp/rpm-lab/repo-config.txt
  echo "" >> /tmp/rpm-lab/repo-config.txt
  echo "=== SAMPLE REPO FILE ===" >> /tmp/rpm-lab/repo-config.txt
  cat /etc/yum.repos.d/*.repo | head -20 >> /tmp/rpm-lab/repo-config.txt

Repository file format:
  [repository-id]
  name=Repository Name
  baseurl=http://example.com/repo
  gpgcheck=1
  enabled=1

Key directives:
  [id]: Unique identifier
  name: Display name
  baseurl: Package location (http://, file://, ftp://)
  gpgcheck: 1=verify, 0=skip verification
  enabled: 1=active, 0=disabled

EOF
}

hint_step_5() {
    echo "  Create file: sudo vi /etc/yum.repos.d/custom-test.repo"
    echo "  Format: [id], name=, baseurl=, gpgcheck=, enabled="
    echo "  Verify: dnf repolist"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Create custom repository configuration

Practice creating a repository configuration file manually. This skill is
essential for configuring local or custom repositories.

Requirements:
  • Create /etc/yum.repos.d/custom-test.repo
  • Include: [custom-test], name, baseurl, gpgcheck=0, enabled=1
  • Use baseurl: file:///tmp/fake-repo
  • Verify with dnf repolist (will show error, expected)
  • Save configuration to /tmp/rpm-lab/custom-repo.txt

Format reminder:
  [section-header]
  name=Description
  baseurl=URL
  gpgcheck=0
  enabled=1

Note: Repository will fail to load (no packages there), this is expected
EOF
}

validate_step_5() {
    if [ ! -f /etc/yum.repos.d/custom-test.repo ]; then
        echo ""
        print_color "$RED" "✗ /etc/yum.repos.d/custom-test.repo not found"
        return 1
    fi
    
    if ! grep -q "\[custom-test\]" /etc/yum.repos.d/custom-test.repo 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ Repository configuration incomplete"
        return 1
    fi
    
    if [ ! -f /tmp/rpm-lab/custom-repo.txt ]; then
        echo ""
        print_color "$RED" "✗ custom-repo.txt not found"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Create repository file:
  sudo cat > /etc/yum.repos.d/custom-test.repo << 'EOF'
[custom-test]
name=Custom Test Repository
baseurl=file:///tmp/fake-repo
gpgcheck=0
enabled=1
EOF

Verify configuration:
  dnf repolist
  # Will show error for custom-test (expected)

Document:
  cat /etc/yum.repos.d/custom-test.repo > /tmp/rpm-lab/custom-repo.txt

Understanding:
  Repository ID in [brackets]
  Each directive on separate line
  gpgcheck=0 skips signature verification, use carefully
  enabled=1 makes repository active
  file:// for local repositories
  http:// or https:// for network repositories

For real repository:
  Repository needs repodata/repomd.xml file
  Create with: createrepo_c /path/to/repo

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your RPM and repository work..."
    echo ""
    
    # CHECK 1: Package queries
    print_color "$CYAN" "[1/$total] Checking package queries..."
    if [ -f /tmp/rpm-lab/package-queries.txt ] && \
       [ -s /tmp/rpm-lab/package-queries.txt ]; then
        print_color "$GREEN" "  ✓ Package queries documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Package queries not documented"
        print_color "$YELLOW" "  Hint: Use rpm -q commands to query packages"
    fi
    echo ""
    
    # CHECK 2: Package metadata
    print_color "$CYAN" "[2/$total] Checking package metadata analysis..."
    if [ -f /tmp/rpm-lab/package-metadata.txt ] && \
       [ -s /tmp/rpm-lab/package-metadata.txt ]; then
        print_color "$GREEN" "  ✓ Package metadata analyzed"
        ((score++))
    else
        print_color "$RED" "  ✗ Package metadata not analyzed"
        print_color "$YELLOW" "  Hint: Use rpm -q --requires and --scripts"
    fi
    echo ""
    
    # CHECK 3: Package extraction
    print_color "$CYAN" "[3/$total] Checking package extraction..."
    if [ -f /tmp/rpm-lab/extraction-notes.txt ] && \
       [ -s /tmp/rpm-lab/extraction-notes.txt ]; then
        print_color "$GREEN" "  ✓ Package extraction documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Package extraction not documented"
        print_color "$YELLOW" "  Hint: Use rpm2cpio and cpio utilities"
    fi
    echo ""
    
    # CHECK 4: Repository examination
    print_color "$CYAN" "[4/$total] Checking repository configuration examination..."
    if [ -f /tmp/rpm-lab/repo-config.txt ] && \
       [ -s /tmp/rpm-lab/repo-config.txt ]; then
        print_color "$GREEN" "  ✓ Repository configuration examined"
        ((score++))
    else
        print_color "$RED" "  ✗ Repository configuration not examined"
        print_color "$YELLOW" "  Hint: Look in /etc/yum.repos.d/"
    fi
    echo ""
    
    # CHECK 5: Custom repository
    print_color "$CYAN" "[5/$total] Checking custom repository creation..."
    if [ -f /etc/yum.repos.d/custom-test.repo ] && \
       grep -q "\[custom-test\]" /etc/yum.repos.d/custom-test.repo 2>/dev/null && \
       [ -f /tmp/rpm-lab/custom-repo.txt ]; then
        print_color "$GREEN" "  ✓ Custom repository created"
        ((score++))
    else
        print_color "$RED" "  ✗ Custom repository not created correctly"
        print_color "$YELLOW" "  Hint: Create .repo file with proper format"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Querying RPM database"
        echo "  • Analyzing package metadata"
        echo "  • Extracting package contents"
        echo "  • Repository configuration"
        echo "  • Creating custom repositories"
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

OBJECTIVE 1: Query RPM database
─────────────────────────────────────────────────────────────────
Find package providing file:
  rpm -qf /bin/bash

Count packages:
  rpm -qa | wc -l

List package files:
  rpm -ql bash

View changelog:
  rpm -q --changelog bash | head


OBJECTIVE 2: Analyze package metadata
─────────────────────────────────────────────────────────────────
Show dependencies:
  rpm -q --requires bash

Show scripts:
  rpm -q --scripts bash

Show info:
  rpm -qi bash


OBJECTIVE 3: Extract package contents
─────────────────────────────────────────────────────────────────
Find package:
  find /var/cache/dnf -name "*.rpm" | head -1

List contents:
  rpm2cpio PACKAGE.rpm | cpio -tv

Extract:
  mkdir -p /tmp/rpm-lab/extracted
  cd /tmp/rpm-lab/extracted
  rpm2cpio PACKAGE.rpm | cpio -idmv


OBJECTIVE 4: Examine repositories
─────────────────────────────────────────────────────────────────
List repo files:
  ls /etc/yum.repos.d/

View repo:
  cat /etc/yum.repos.d/redhat.repo


OBJECTIVE 5: Create custom repository
─────────────────────────────────────────────────────────────────
Create repo file:
  sudo cat > /etc/yum.repos.d/custom-test.repo << 'ENDFILE'
[custom-test]
name=Custom Test Repository
baseurl=file:///tmp/fake-repo
gpgcheck=0
enabled=1
ENDFILE

Verify:
  dnf repolist


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RPM Package Manager:
  Database: /var/lib/rpm/
  Contains metadata and file ownership
  Query without installing packages

rpm query modes:
  -q PACKAGE: Query specific package
  -qa: Query all packages
  -qf FILE: Find package owning file
  -ql PACKAGE: List files in package
  -qi PACKAGE: Show package info
  -qR PACKAGE: Show requirements (dependencies)

rpm2cpio and cpio:
  rpm2cpio: Convert RPM to cpio archive
  cpio: Archive utility (older than tar)
  Allows extraction without installation

Repository configuration:
  Location: /etc/yum.repos.d/
  Format: INI-style with sections
  
  Essential directives:
  [id]: Repository identifier
  name: Description
  baseurl: Package location
  gpgcheck: Signature verification
  enabled: Active or disabled


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting -q with rpm
  rpm bash → error
  rpm -q bash → correct

Mistake 2: Wrong cpio flags
  -tv: List (table view)
  -idmv: Extract (input, dirs, time, verbose)

Mistake 3: Repository file not ending in .repo
  Must use .repo extension

Mistake 4: Syntax errors in repo file
  Must have [section]
  key=value format (no spaces around =)


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. rpm -qf finds which package owns a file
2. rpm -ql lists files from a package
3. Repository files must be in /etc/yum.repos.d/
4. Repository ID in [brackets] must be unique
5. gpgcheck=0 disables signature verification (useful for local repos)
6. Use file:// for local repository paths

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove custom repository
    rm -f /etc/yum.repos.d/custom-test.repo 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/rpm-lab 2>/dev/null || true
    rm -rf /tmp/rpm-lab-backup 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
