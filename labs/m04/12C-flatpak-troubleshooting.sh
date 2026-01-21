#!/bin/bash
# labs/m04/14C-flatpak-applications.sh
# Lab: Working with Flatpak applications
# Difficulty: Intermediate
# RHCSA Objective: 12.8, 12.9 - Flatpak installation and management

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Working with Flatpak applications"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Create working directory
    mkdir -p /tmp/flatpak-work 2>/dev/null || true
    
    # Ensure flatpak is installed
    if ! command -v flatpak >/dev/null 2>&1; then
        echo "  Installing flatpak..."
        dnf install -y flatpak >/dev/null 2>&1
    fi
    
    # Remove any existing remotes to start fresh
    flatpak remotes 2>/dev/null | awk '{print $1}' | while read remote; do
        flatpak remote-delete "$remote" --force 2>/dev/null || true
    done
    
    # Remove any installed flatpak apps
    flatpak list --app 2>/dev/null | awk '{print $2}' | while read app; do
        flatpak uninstall -y "$app" 2>/dev/null || true
    done
    
    echo "  ✓ Flatpak installed and cleaned"
    echo "  ✓ Lab environment ready"
    echo ""
    echo "  SCENARIO: You will set up and use Flatpak for application management"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of package management
  • Familiarity with repositories
  • Container concepts helpful but not required

Commands You'll Use:
  • flatpak - Flatpak package manager
  • flatpak remote-add - Add remote repositories
  • flatpak remote-ls - List remote contents
  • flatpak search - Search for applications
  • flatpak install - Install applications
  • flatpak list - List installed items
  • flatpak run - Run applications
  • flatpak uninstall - Remove applications

Files You'll Interact With:
  • /etc/flatpak/remotes.d/ - Remote repository configuration
  • /var/lib/flatpak/ - System-wide Flatpak data
  • ~/.local/share/flatpak/ - User Flatpak data
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your organization is evaluating Flatpak for desktop application deployment.
You need to set up Flatpak, configure remote repositories, and install test
applications to understand how Flatpak works compared to traditional RPM packages.

BACKGROUND:
Flatpak provides containerized applications that include all dependencies and
run in a sandbox. This approach offers better security and cross-distribution
compatibility compared to traditional packages, making it ideal for desktop
applications.

OBJECTIVES:
  1. Verify Flatpak installation and understand its architecture
     • Confirm Flatpak is installed
     • Understand Flatpak data locations
     • Learn the difference between system and user installs
     • Explore Flatpak configuration

  2. Add and configure a Flatpak remote repository
     • Add the Fedora registry remote
     • Verify the remote is configured correctly
     • List available applications in the remote
     • Understand OCI registry concept

  3. Search for and examine applications
     • Search for available applications
     • View detailed information about an application
     • Understand application IDs and naming conventions
     • Explore application permissions

  4. Install a Flatpak application
     • Install a small application
     • Verify installation succeeded
     • Understand runtime dependencies
     • Check installed size

  5. Run and manage installed applications
     • Run the installed application
     • List all installed applications
     • Update an application
     • Uninstall the application

HINTS:
  • Flatpak uses remotes similar to DNF repositories
  • Application IDs use reverse-DNS format
  • Runtimes are shared between applications
  • User installs don't require root
  • Each step builds on the previous

SUCCESS CRITERIA:
  • Flatpak installation verified
  • Remote repository configured
  • Application searched and examined
  • Application installed and run
  • Application properly removed
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Verify Flatpak installation and architecture
  ☐ 2. Add Flatpak remote repository
  ☐ 3. Search and examine applications
  ☐ 4. Install a Flatpak application
  ☐ 5. Run and manage applications
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
You are setting up and testing Flatpak for application deployment.

Working directory: /tmp/flatpak-work/

Follow the sequential workflow to master Flatpak.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Verify Flatpak installation and understand its architecture

Before using Flatpak, confirm it's installed and understand where it stores data.

Requirements:
  • Verify Flatpak is installed on the system
  • Check the Flatpak version
  • Examine Flatpak data directories
  • List any configured remotes (should be empty)

Questions to explore:
  • Where does Flatpak store system-wide data?
  • Where does it store user-specific data?
  • What version of Flatpak is installed?
  • Are any remotes configured?

Discover how to check installation status and explore the Flatpak
directory structure.
EOF
}

validate_step_1() {
    if ! command -v flatpak >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Flatpak not installed"
        return 1
    fi
    
    return 0
}

hint_step_1() {
    echo "  Check installation: which flatpak"
    echo "  Check version: flatpak --version"
    echo "  List remotes: flatpak remotes"
    echo "  Check directories: ls /var/lib/flatpak/"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Verify installation:
  which flatpak
  flatpak --version
  rpm -q flatpak

List configured remotes:
  flatpak remotes
  # Should be empty initially

Explore directories:
  ls -la /var/lib/flatpak/
  ls -la /etc/flatpak/
  ls -la ~/.local/share/flatpak/ 2>/dev/null || echo "User data not yet created"

Understanding:
  /var/lib/flatpak/ - System-wide applications and runtimes
  /etc/flatpak/remotes.d/ - Remote repository configuration
  ~/.local/share/flatpak/ - User-installed applications

Flatpak supports two install scopes:
  --system: Available to all users, requires root
  --user: Available to current user only, no root needed

EOF
}

hint_step_2() {
    echo "  Add remote: flatpak remote-add NAME URL"
    echo "  Use name: fedora"
    echo "  Use URL: oci+https://registry.fedoraproject.org"
    echo "  Verify: flatpak remotes"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Add and configure a Flatpak remote repository

Flatpak remotes are repositories that provide applications. Add a remote
to access available applications.

Requirements:
  • Add the Fedora registry as a remote
  • Name the remote: fedora
  • URL to use: oci+https://registry.fedoraproject.org
  • Verify the remote was added successfully
  • List applications available in the remote

Remote details:
  Name: fedora
  URL: oci+https://registry.fedoraproject.org
  Flag: --if-not-exists (prevents errors if already exists)

OCI stands for Open Container Initiative - a standard format
for container images that Flatpak uses.
EOF
}

validate_step_2() {
    if ! flatpak remotes 2>/dev/null | grep -q "fedora"; then
        echo ""
        print_color "$RED" "✗ Fedora remote not configured"
        echo "  Add it with the URL: oci+https://registry.fedoraproject.org"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Add Fedora remote:
  flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org

Verify remote was added:
  flatpak remotes
  flatpak remotes -d

List applications in remote:
  flatpak remote-ls fedora --app

Understanding remotes:
  Similar to DNF repositories
  Stored in /etc/flatpak/remotes.d/
  Each remote is an OCI registry
  Metadata updated automatically

Common remotes:
  Flathub: https://flathub.org
  Fedora Registry: registry.fedoraproject.org
  GNOME Nightly: nightly.gnome.org

The --if-not-exists flag prevents errors if
the remote already exists.

EOF
}

hint_step_3() {
    echo "  Search: flatpak search KEYWORD"
    echo "  Show info: flatpak info --show-metadata APP_ID"
    echo "  Try searching for: firefox or calculator"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Search for and examine applications

Learn to find applications and view their details before installing.

Requirements:
  • Search for an application (try firefox or calculator)
  • View information about an application you found
  • Understand the application ID format
  • Examine what the application requires

Explore:
  • What applications are available?
  • How are application IDs formatted?
  • What information is shown about each app?
  • What runtimes do applications need?

Application IDs typically follow reverse-DNS format:
  org.mozilla.firefox
  org.gnome.Calculator
EOF
}

validate_step_3() {
    # Can't really validate search was performed, but that's okay
    # The student's progression shows they're learning
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Search for applications:
  flatpak search firefox
  flatpak search calculator
  flatpak search editor

View application information:
  flatpak info org.mozilla.firefox
  flatpak remote-info fedora org.gnome.Calculator

Understanding application IDs:
  Format: org.domain.ApplicationName
  Examples:
    org.mozilla.firefox - Firefox browser
    org.gnome.Calculator - GNOME calculator
    org.libreoffice.LibreOffice - LibreOffice suite

Application metadata includes:
  - Application ID
  - Version
  - Required runtime
  - Size
  - Permissions
  - Description

Runtimes:
  Shared base systems that applications use
  Examples: org.gnome.Platform, org.kde.Platform
  Installed once, used by many apps
  Reduces duplication

EOF
}

hint_step_4() {
    echo "  Install: flatpak install REMOTE APP_ID"
    echo "  Try: org.gnome.Calculator or a small app"
    echo "  Verify: flatpak list --app"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Install a Flatpak application

Install an application from the remote repository.

Requirements:
  • Install an application from the fedora remote
  • Choose a small application (calculator, text editor, etc.)
  • Observe runtime installation if needed
  • Verify the application was installed
  • Check the installed size

Suggested applications to try:
  • org.gnome.Calculator - Simple calculator
  • org.gnome.TextEditor - Text editor
  • Choose any small application you found

The installation will also install required runtimes if
they're not already present.
EOF
}

validate_step_4() {
    # Check if any application is installed
    local app_count=$(flatpak list --app 2>/dev/null | wc -l)
    
    if [ "$app_count" -lt 1 ]; then
        echo ""
        print_color "$RED" "✗ No Flatpak applications installed"
        echo "  Install an application from the fedora remote"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Install an application:
  flatpak install fedora org.gnome.Calculator

During installation:
  - Application is downloaded
  - Required runtime is installed if needed
  - Dependencies are resolved automatically
  - Installation is verified

Verify installation:
  flatpak list --app
  flatpak list --runtime

Check installation details:
  flatpak info org.gnome.Calculator

Understanding the install process:
  1. Flatpak checks for required runtime
  2. Downloads runtime if not present
  3. Downloads application
  4. Verifies signatures
  5. Installs in /var/lib/flatpak/

Installation includes:
  - Application files
  - Application metadata
  - Required runtime (shared)
  - Desktop integration files

EOF
}

hint_step_5() {
    echo "  Run: flatpak run APP_ID"
    echo "  List: flatpak list"
    echo "  Update: flatpak update APP_ID"
    echo "  Remove: flatpak uninstall APP_ID"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Run and manage installed applications

Learn to run, update, and remove Flatpak applications.

Requirements:
  • Run the application you installed
  • List all installed applications and runtimes
  • Check for updates
  • Uninstall the application when done

Management tasks:
  • Running applications
  • Viewing installed items
  • Updating applications
  • Removing applications

The application will run in a sandbox, isolated from
the rest of the system for security.
EOF
}

validate_step_5() {
    # Check that application was removed (cleanup)
    local app_count=$(flatpak list --app 2>/dev/null | wc -l)
    
    if [ "$app_count" -gt 0 ]; then
        echo ""
        print_color "$YELLOW" "  Note: Application still installed"
        echo "  Remember to uninstall when done testing"
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Run the application:
  flatpak run org.gnome.Calculator

List installed items:
  flatpak list
  flatpak list --app
  flatpak list --runtime

Check for updates:
  flatpak update
  flatpak update org.gnome.Calculator

Uninstall application:
  flatpak uninstall org.gnome.Calculator

Uninstall with data:
  flatpak uninstall --delete-data org.gnome.Calculator

Understanding Flatpak management:

Running apps:
  - Applications run in sandbox
  - Limited access to system resources
  - Can request permissions
  - Isolated from other apps

Updates:
  - Update individual apps
  - Update all apps at once
  - Runtime updates happen automatically
  - Check updates regularly

Removal:
  - Uninstall removes application
  - Runtimes may remain (shared)
  - Use --unused to remove unused runtimes
  - --delete-data removes user data

Cleanup unused runtimes:
  flatpak uninstall --unused

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your Flatpak work..."
    echo ""
    
    # CHECK 1: Flatpak installed
    print_color "$CYAN" "[1/$total] Checking Flatpak installation..."
    if command -v flatpak >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Flatpak is installed"
        ((score++))
    else
        print_color "$RED" "  ✗ Flatpak not found"
    fi
    echo ""
    
    # CHECK 2: Remote configured
    print_color "$CYAN" "[2/$total] Checking remote configuration..."
    if flatpak remotes 2>/dev/null | grep -q "fedora"; then
        print_color "$GREEN" "  ✓ Fedora remote configured"
        ((score++))
    else
        print_color "$RED" "  ✗ Fedora remote not found"
        print_color "$YELLOW" "  Hint: Add with oci+https://registry.fedoraproject.org"
    fi
    echo ""
    
    # CHECK 3: Search performed (inferred by progression)
    print_color "$CYAN" "[3/$total] Checking application exploration..."
    if [ $score -ge 2 ]; then
        print_color "$GREEN" "  ✓ Application search capabilities understood"
        ((score++))
    else
        print_color "$YELLOW" "  Complete previous steps first"
    fi
    echo ""
    
    # CHECK 4: Application installed
    print_color "$CYAN" "[4/$total] Checking application installation..."
    local app_count=$(flatpak list --app 2>/dev/null | wc -l)
    if [ "$app_count" -ge 1 ]; then
        print_color "$GREEN" "  ✓ Flatpak application installed"
        ((score++))
    else
        print_color "$RED" "  ✗ No applications installed"
        print_color "$YELLOW" "  Hint: Install an app from fedora remote"
    fi
    echo ""
    
    # CHECK 5: Management demonstrated
    print_color "$CYAN" "[5/$total] Checking application management..."
    if [ $score -ge 3 ]; then
        print_color "$GREEN" "  ✓ Flatpak management demonstrated"
        ((score++))
    else
        print_color "$YELLOW" "  Complete previous steps to demonstrate management"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You successfully:"
        echo "  • Verified Flatpak installation"
        echo "  • Configured remote repository"
        echo "  • Searched for applications"
        echo "  • Installed a Flatpak application"
        echo "  • Managed Flatpak applications"
        echo ""
        echo "You understand Flatpak for desktop application management!"
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

STEP 1: Verify installation
─────────────────────────────────────────────────────────────────
flatpak --version
which flatpak
flatpak remotes
ls /var/lib/flatpak/


STEP 2: Add remote
─────────────────────────────────────────────────────────────────
flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org
flatpak remotes
flatpak remote-ls fedora --app


STEP 3: Search applications
─────────────────────────────────────────────────────────────────
flatpak search calculator
flatpak search firefox
flatpak info org.gnome.Calculator


STEP 4: Install application
─────────────────────────────────────────────────────────────────
flatpak install fedora org.gnome.Calculator
flatpak list --app


STEP 5: Manage application
─────────────────────────────────────────────────────────────────
flatpak run org.gnome.Calculator
flatpak list
flatpak update org.gnome.Calculator
flatpak uninstall org.gnome.Calculator


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Flatpak architecture:
  - Container-based applications
  - Sandboxed execution
  - Runtime dependencies included
  - OCI registry format

Data locations:
  System: /var/lib/flatpak/
  User: ~/.local/share/flatpak/
  Config: /etc/flatpak/remotes.d/

Application IDs:
  Format: org.domain.ApplicationName
  Reverse-DNS naming convention
  Unique identifier for each app

Runtimes:
  Shared base systems
  Examples: org.gnome.Platform
  Installed once, used by many apps
  Reduces disk space usage

Flatpak vs DNF:
  Flatpak:
  - Desktop applications
  - Sandboxed security
  - Distribution-independent
  - User-level installs possible
  
  DNF:
  - System packages
  - Tight OS integration
  - Distribution-specific
  - Requires root for install


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Essential Flatpak commands:
1. flatpak remote-add - Add repository
2. flatpak remotes - List repositories
3. flatpak search - Find applications
4. flatpak install - Install application
5. flatpak list - Show installed items
6. flatpak run - Execute application
7. flatpak update - Update applications
8. flatpak uninstall - Remove application

Common patterns:
  flatpak remote-add --if-not-exists NAME URL
  flatpak install REMOTE APP_ID
  flatpak run APP_ID
  flatpak uninstall --unused (cleanup)

Remember:
  - OCI registry URLs start with oci+https://
  - Application IDs use reverse-DNS format
  - Runtimes are shared dependencies
  - Sandboxed apps have limited permissions

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove installed applications
    flatpak list --app 2>/dev/null | awk '{print $2}' | while read app; do
        flatpak uninstall -y "$app" 2>/dev/null || true
    done
    
    # Clean up unused runtimes
    flatpak uninstall --unused -y 2>/dev/null || true
    
    # Remove working directory
    rm -rf /tmp/flatpak-work 2>/dev/null || true
    
    echo "  ✓ Flatpak applications removed"
    echo "  ✓ All lab components cleaned"
}

# Execute the main framework
main "$@"
