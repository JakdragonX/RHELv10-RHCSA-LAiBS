#!/bin/bash
# setup-labs.sh
# RHCSA Lab Environment Setup Script
# 
# Purpose: Setup the RHCSA lab framework in-place (no copying)
# Usage: bash setup-labs.sh [--uninstall]

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Configuration
readonly BIN_DIR="/usr/local/bin"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper functions
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo ""
    print_color "$CYAN" "═══════════════════════════════════════════════════════════════"
    print_color "$BOLD$CYAN" " $1"
    print_color "$CYAN" "═══════════════════════════════════════════════════════════════"
    echo ""
}

print_step() {
    echo ""
    print_color "$BLUE" "▶ $1"
}

print_success() {
    print_color "$GREEN" "  ✓ $1"
}

print_warning() {
    print_color "$YELLOW" "  ⚠ $1"
}

print_error() {
    print_color "$RED" "  ✗ $1"
}

# Cleanup function for sudo refresh background process
cleanup_sudo_refresh() {
    if [ -f /tmp/setup-labs-sudo-refresh.pid ]; then
        local pid=$(cat /tmp/setup-labs-sudo-refresh.pid 2>/dev/null)
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
        fi
        rm -f /tmp/setup-labs-sudo-refresh.pid
    fi
}

# Set trap to cleanup on exit
trap cleanup_sudo_refresh EXIT INT TERM

# Check if running as root (we need sudo for some operations)
check_privileges() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please run this script as a regular user, not as root"
        print_color "$YELLOW" "The script will prompt for sudo when needed"
        exit 1
    fi
    
    # Check if sudo is available
    if ! command -v sudo &>/dev/null; then
        print_error "sudo is required but not installed"
        print_color "$YELLOW" "Please install sudo or run individual commands as root"
        exit 1
    fi
    
    # Request sudo credentials upfront and keep them cached
    print_color "$YELLOW" "This script requires sudo privileges for installing commands."
    print_color "$YELLOW" "You may be prompted for your password..."
    echo ""
    
    if ! sudo -v; then
        print_error "Failed to obtain sudo privileges"
        exit 1
    fi
    
    # Keep sudo credentials refreshed in background
    (
        while true; do
            sleep 50
            sudo -v
        done
    ) &
    local sudo_refresh_pid=$!
    
    # Store PID for cleanup
    echo "$sudo_refresh_pid" > /tmp/setup-labs-sudo-refresh.pid
    
    print_success "Sudo credentials obtained"
}

# Check and install dependencies
check_dependencies() {
    print_step "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for dos2unix (for line ending conversion)
    if ! command -v dos2unix &>/dev/null; then
        missing_deps+=("dos2unix")
    fi
    
    # Check for bash version (need 4.0+)
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        print_error "Bash 4.0 or higher is required (you have ${BASH_VERSION})"
        exit 1
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing optional dependencies: ${missing_deps[*]}"
        echo ""
        print_color "$YELLOW" "Install with one of these commands (based on your distro):"
        echo ""
        echo "  RHEL/CentOS/Rocky/Alma:"
        echo "    sudo dnf install -y ${missing_deps[*]}"
        echo ""
        echo "  Ubuntu/Debian:"
        echo "    sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
        echo ""
        
        read -p "Would you like to install missing dependencies now? (y/n) " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Detect package manager
            if command -v dnf &>/dev/null; then
                sudo dnf install -y "${missing_deps[@]}"
            elif command -v yum &>/dev/null; then
                sudo yum install -y "${missing_deps[@]}"
            elif command -v apt-get &>/dev/null; then
                sudo apt-get update && sudo apt-get install -y "${missing_deps[@]}"
            else
                print_error "Could not detect package manager"
                print_color "$YELLOW" "Please install dependencies manually"
                return 0
            fi
            print_success "Dependencies installed"
        else
            print_warning "Continuing without dos2unix (line ending conversion will be skipped)"
        fi
    else
        print_success "All dependencies satisfied"
    fi
}

# Convert all shell scripts to Unix line endings
fix_line_endings() {
    print_step "Converting shell scripts to Unix format (LF line endings)..."
    
    # Check if dos2unix is available
    if ! command -v dos2unix &>/dev/null; then
        print_warning "dos2unix not available, skipping line ending conversion"
        return 0
    fi
    
    # Count scripts
    local script_count=$(find "$SCRIPT_DIR" -type f -name "*.sh" 2>/dev/null | wc -l)
    
    if [ $script_count -eq 0 ]; then
        print_warning "No shell scripts found"
        return 0
    fi
    
    print_color "$CYAN" "  Found $script_count shell scripts to check..."
    
    # Convert all scripts (dos2unix is idempotent)
    if find "$SCRIPT_DIR" -type f -name "*.sh" -exec dos2unix {} + 2>/dev/null; then
        print_success "All scripts now have Unix line endings"
    else
        print_warning "Line ending conversion completed with some warnings"
    fi
}

# Set executable permissions on all shell scripts
set_permissions() {
    print_step "Setting executable permissions on shell scripts..."
    
    # Count scripts first
    local count=$(find "$SCRIPT_DIR" -type f -name "*.sh" 2>/dev/null | wc -l)
    
    if [ "$count" -eq 0 ]; then
        print_warning "No shell scripts found"
        return 0
    fi
    
    print_color "$CYAN" "  Found $count shell scripts..."
    
    if find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null; then
        print_success "Made $count scripts executable"
    else
        print_warning "Some scripts may not have been made executable"
    fi
}

# Install command-line shortcuts
install_commands() {
    print_step "Installing lab commands to system PATH..."
    
    # Install rhcsa-progress command
    local source_file="$SCRIPT_DIR/track-progress.sh"
    local target_script="$BIN_DIR/rhcsa-progress"
    
    if [ ! -f "$source_file" ]; then
        print_error "Script not found: $source_file"
        return 1
    fi
    
    # Create wrapper that runs track-progress.sh from its directory
    local wrapper_temp=$(mktemp)
    printf '#!/bin/bash\ncd "%s" || exit 1\nexec bash "./track-progress.sh" "$@"\n' \
        "$SCRIPT_DIR" > "$wrapper_temp"
    
    chmod +x "$wrapper_temp"
    
    if sudo cp "$wrapper_temp" "$target_script" 2>/dev/null; then
        sudo chmod +x "$target_script"
        print_success "Installed: rhcsa-progress"
    else
        print_error "Failed to install rhcsa-progress command"
        rm -f "$wrapper_temp"
        return 1
    fi
    
    rm -f "$wrapper_temp"
    return 0
}

# Create helper wrapper scripts for individual labs
create_lab_wrappers() {
    print_step "Creating convenience commands for labs..."
    
    # Check if labs directory exists
    if [ ! -d "$SCRIPT_DIR/labs" ]; then
        print_warning "No 'labs' directory found - skipping wrapper creation"
        return 0
    fi
    
    # Count lab scripts (only in module subdirectories, exclude templates)
    local lab_count=$(find "$SCRIPT_DIR/labs" -type f -path "*/m[0-9][0-9]/*" -name "[0-9][0-9]*-*.sh" 2>/dev/null | wc -l)
    
    if [ "$lab_count" -eq 0 ]; then
        print_warning "No numbered lab scripts found in labs/mXX/ directories"
        echo ""
        print_color "$YELLOW" "  Labs should be in module directories: labs/m02/, labs/m03/, etc."
        print_color "$YELLOW" "  Filename format: XX-topic.sh or XXY-topic.sh"
        return 0
    fi
    
    print_color "$CYAN" "  Found $lab_count lab scripts to process..."
    echo ""
    
    # Create a temporary directory for all wrapper scripts
    local wrapper_dir=$(mktemp -d)
    
    # Collect all lab files (ONLY from module subdirectories)
    local lab_files=()
    while IFS= read -r -d '' lab_file; do
        lab_files+=("$lab_file")
    done < <(find "$SCRIPT_DIR/labs" -type f -path "*/m[0-9][0-9]/*" -name "[0-9][0-9]*-*.sh" -print0 2>/dev/null)
    
    echo "  Creating wrapper scripts..."
    local created=0
    
    # Create all wrapper scripts in temp directory
    for lab_file in "${lab_files[@]}"; do
        [ -z "$lab_file" ] || [ ! -f "$lab_file" ] && continue
        
        local lab_basename=$(basename "$lab_file")
        
        # Extract lab identifier (01, 03A, 03B, etc.)
        if [[ $lab_basename =~ ^([0-9]{2}[A-Z]?)-.*\.sh$ ]]; then
            local lab_id="${BASH_REMATCH[1]}"
            local cmd_name="rhcsa-lab-${lab_id}"
            local lab_dir=$(dirname "$lab_file")
            
            # Create wrapper using printf
            printf '#!/bin/bash\ncd "%s" || exit 1\nexec "./%s" "$@"\n' \
                "$lab_dir" "$lab_basename" > "$wrapper_dir/$cmd_name"
            
            chmod +x "$wrapper_dir/$cmd_name"
            echo "  ✓ $cmd_name"
            ((created++))
        fi
    done
    
    echo ""
    echo "  Installing $created commands to $BIN_DIR..."
    
    # ONE sudo operation to copy everything
    if sudo cp "$wrapper_dir"/rhcsa-lab-* "$BIN_DIR/" 2>/dev/null; then
        print_success "Installed $created lab command shortcuts!"
    else
        print_error "Failed to install commands to $BIN_DIR"
        rm -rf "$wrapper_dir"
        return 1
    fi
    
    # Cleanup temp directory
    rm -rf "$wrapper_dir"
    
    echo ""
    print_color "$CYAN" "  Examples:"
    print_color "$CYAN" "    • sudo rhcsa-lab-03A --interactive"
    print_color "$CYAN" "    • sudo rhcsa-lab-04B --validate"
    
    return 0
}

# Display post-install information
show_post_install_info() {
    print_header "Installation Complete!"
    
    cat << EOF
Your RHCSA lab environment is ready to use!

LOCATION:
  Lab Directory: $SCRIPT_DIR

QUICK START:
──────────────────────────────────────────────────────────────────

1. VIEW AVAILABLE LABS:
   cd $SCRIPT_DIR/labs
   ls -d m*/

2. RUN A LAB:
   sudo rhcsa-lab-03A              # Using command shortcut
   cd $SCRIPT_DIR/labs/m02
   sudo ./03A-bash-shell-basics.sh # Or directly

3. MODES:
   sudo rhcsa-lab-03A --interactive    # Step-by-step learning
   sudo rhcsa-lab-03A --validate       # Check your work
   rhcsa-lab-03A --solution            # View solution

4. TRACK PROGRESS:
   rhcsa-progress --summary
   rhcsa-progress --retry

COMMANDS INSTALLED:
──────────────────────────────────────────────────────────────────

rhcsa-progress         View your lab completion progress
rhcsa-lab-XX           Run specific lab (XX = lab number)

DIRECTORY STRUCTURE:
──────────────────────────────────────────────────────────────────

$SCRIPT_DIR/
  ├── labs/              Lab scripts organized by modules
  │   ├── m02/          Module 2: Essential Command Line
  │   ├── m03/          Module 3: File Management
  │   └── ...
  ├── lab-runner.sh      Core framework
  ├── track-progress.sh  Progress tracking
  └── lab_progress.txt   Your progress (auto-created)

TIPS:
──────────────────────────────────────────────────────────────────

• Use git pull to get updates (this is the repo!)
• Always use sudo when running labs
• Check your progress with rhcsa-progress

EOF
}

# Uninstall function
uninstall_labs() {
    print_header "Uninstalling RHCSA Lab Commands"
    
    print_color "$YELLOW" "This will:"
    echo "  • Remove command shortcuts from $BIN_DIR"
    echo "  • Keep your lab directory at $SCRIPT_DIR"
    echo ""
    
    read -p "Are you sure? (y/n) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "$CYAN" "Cancelled"
        exit 0
    fi
    
    print_step "Removing command shortcuts..."
    
    local removed=0
    
    # Remove rhcsa-progress
    if [ -f "$BIN_DIR/rhcsa-progress" ]; then
        sudo rm "$BIN_DIR/rhcsa-progress"
        print_success "Removed: rhcsa-progress"
        ((removed++))
    fi
    
    # Remove all lab commands
    while IFS= read -r lab_cmd; do
        if [ -n "$lab_cmd" ] && [ -f "$lab_cmd" ]; then
            local cmd_name=$(basename "$lab_cmd")
            sudo rm "$lab_cmd" 2>/dev/null
            echo "  ✓ Removed: $cmd_name"
            ((removed++))
        fi
    done < <(find "$BIN_DIR" -type f -name "rhcsa-lab-[0-9][0-9]*" 2>/dev/null)
    
    echo ""
    if [ $removed -gt 0 ]; then
        print_success "Removed $removed command shortcuts"
    else
        print_warning "No command shortcuts found"
    fi
    
    echo ""
    print_color "$GREEN" "Uninstall complete!"
    echo ""
    print_color "$CYAN" "Your lab files are still at: $SCRIPT_DIR"
}

# Main installation flow
main() {
    # Parse command line arguments
    case "${1:-}" in
        --uninstall|-u)
            check_privileges
            uninstall_labs
            exit 0
            ;;
        --help|-h)
            cat << EOF
RHCSA Lab Framework Setup Script

USAGE:
    bash setup-labs.sh [OPTIONS]

OPTIONS:
    (no option)        Install the lab framework
    --uninstall, -u    Remove command shortcuts (keeps lab files)
    --help, -h         Show this help message

WHAT IT DOES:
    1. Check and install dependencies (dos2unix)
    2. Convert scripts to Unix line endings (LF)
    3. Set executable permissions
    4. Create command shortcuts in $BIN_DIR

NOTE: This script works IN-PLACE on your cloned repository.
      It does NOT copy files to ~/Labs/.

AFTER INSTALLATION:
    • Labs remain in: $(dirname "$0")
    • Commands available: rhcsa-lab-XX, rhcsa-progress
    • Run 'rhcsa-progress --summary' to get started

EOF
            exit 0
            ;;
        "")
            # Continue with installation
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Run with --help for usage information"
            exit 1
            ;;
    esac
    
    print_header "RHCSA Lab Framework Setup"
    
    print_color "$CYAN" "Working directory: $SCRIPT_DIR"
    echo ""
    print_color "$CYAN" "This script will:"
    echo "  1. Check dependencies (dos2unix)"
    echo "  2. Fix script encoding (CRLF → LF)"
    echo "  3. Set executable permissions"
    echo "  4. Install command shortcuts to $BIN_DIR"
    echo ""
    print_color "$YELLOW" "Note: This works IN-PLACE. No files will be copied."
    echo ""
    
    read -p "Press ENTER to continue or Ctrl+C to cancel..." -r
    
    # Run setup steps
    check_privileges
    check_dependencies
    fix_line_endings
    set_permissions
    install_commands
    create_lab_wrappers
    
    # Show final information
    show_post_install_info
    
    # Cleanup sudo refresh process
    cleanup_sudo_refresh
    
    exit 0
}

# Execute main function
main "$@"
