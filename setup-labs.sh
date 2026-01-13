#!/bin/bash
# setup-labs.sh
# RHCSA Lab Environment Setup Script
# 
# Purpose: Automate the setup of the RHCSA lab framework after cloning from GitHub
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
readonly LAB_HOME="$HOME/Labs"
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
    
    # Check for file command (used for line ending detection)
    if ! command -v file &>/dev/null; then
        missing_deps+=("file")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
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
                sudo dnf install -y "${missing_deps[@]}" || {
                    print_error "Installation failed"
                    exit 1
                }
            elif command -v yum &>/dev/null; then
                sudo yum install -y "${missing_deps[@]}" || {
                    print_error "Installation failed"
                    exit 1
                }
            elif command -v apt-get &>/dev/null; then
                sudo apt-get update && sudo apt-get install -y "${missing_deps[@]}" || {
                    print_error "Installation failed"
                    exit 1
                }
            else
                print_error "Could not detect package manager"
                print_color "$YELLOW" "Please install dependencies manually and re-run this script"
                exit 1
            fi
            print_success "Dependencies installed"
        else
            print_error "Cannot proceed without required dependencies"
            echo ""
            print_color "$YELLOW" "You can skip line ending conversion and run manually later:"
            echo "  find ~/Labs -name '*.sh' -exec dos2unix {} +"
            echo ""
            read -p "Continue without dos2unix? (not recommended) (y/n) " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            print_warning "Proceeding without line ending conversion"
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
        print_color "$YELLOW" "  You can fix line endings manually later with:"
        print_color "$YELLOW" "    find ~/Labs -name '*.sh' -exec dos2unix {} +"
        return 0
    fi
    
    local script_count=0
    local fixed_count=0
    local error_count=0
    
    # Use temporary file to store script list
    local temp_file=$(mktemp)
    find "$SCRIPT_DIR" -type f -name "*.sh" 2>/dev/null > "$temp_file"
    
    script_count=$(wc -l < "$temp_file")
    
    if [ $script_count -eq 0 ]; then
        print_warning "No shell scripts found in $SCRIPT_DIR"
        rm -f "$temp_file"
        return 0
    fi
    
    print_color "$CYAN" "  Found $script_count shell scripts to check..."
    
    # Process each script
    while IFS= read -r script; do
        if [ -f "$script" ]; then
            # Check if file has CRLF line endings (Windows format)
            # Use a timeout to prevent hanging
            if timeout 2s file "$script" 2>/dev/null | grep -q "CRLF" 2>/dev/null; then
                # Try to convert with timeout
                if timeout 5s dos2unix "$script" 2>/dev/null; then
                    ((fixed_count++))
                else
                    ((error_count++))
                fi
            fi
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    if [ $fixed_count -eq 0 ]; then
        print_success "All $script_count scripts already have Unix line endings"
    else
        print_success "Converted $fixed_count of $script_count scripts"
        if [ $error_count -gt 0 ]; then
            print_warning "$error_count scripts encountered errors during conversion"
        fi
    fi
}

# Set executable permissions on all shell scripts
set_permissions() {
    print_step "Setting executable permissions on shell scripts..."
    
    # Use a temporary file to avoid process substitution issues
    local temp_file=$(mktemp)
    find "$SCRIPT_DIR" -type f -name "*.sh" 2>/dev/null > "$temp_file"
    
    local count=$(wc -l < "$temp_file")
    
    if [ "$count" -eq 0 ]; then
        print_warning "No shell scripts found to make executable"
        rm -f "$temp_file"
        return 0
    fi
    
    print_color "$CYAN" "  Found $count shell scripts to make executable..."
    
    local success=0
    local failed=0
    
    # Make each script executable
    while IFS= read -r script; do
        if [ -f "$script" ]; then
            if chmod +x "$script" 2>/dev/null; then
                ((success++))
            else
                ((failed++))
            fi
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    if [ $success -gt 0 ]; then
        print_success "Made $success scripts executable"
        if [ $failed -gt 0 ]; then
            print_warning "$failed scripts could not be made executable"
        fi
    else
        print_error "Failed to set executable permissions"
    fi
}
        fi
    else
        print_error "Could not make any scripts executable"
    fi
}

# Create or update the Labs directory
setup_lab_directory() {
    print_step "Setting up lab directory at $LAB_HOME..."
    
    # If Labs directory doesn't exist, create it
    if [ ! -d "$LAB_HOME" ]; then
        mkdir -p "$LAB_HOME"
        print_success "Created $LAB_HOME directory"
    else
        print_success "Lab directory already exists at $LAB_HOME"
    fi
    
    # Copy/sync the repository contents to ~/Labs
    # We use rsync if available, otherwise cp
    if command -v rsync &>/dev/null; then
        rsync -a --exclude='.git' "$SCRIPT_DIR/" "$LAB_HOME/"
        print_success "Synchronized repository to $LAB_HOME"
    else
        cp -r "$SCRIPT_DIR/"* "$LAB_HOME/" 2>/dev/null || true
        print_success "Copied repository to $LAB_HOME"
    fi
    
    # Create a .lab-framework file to identify this as a lab directory
    echo "RHCSA Lab Framework" > "$LAB_HOME/.lab-framework"
    echo "Installed: $(date)" >> "$LAB_HOME/.lab-framework"
}

# Install command-line shortcuts
install_commands() {
    print_step "Installing lab commands to system PATH..."
    
    # Core scripts to install as commands
    declare -A commands=(
        ["lab-runner.sh"]="rhcsa-lab"
        ["track-progress.sh"]="rhcsa-progress"
    )
    
    local installed=0
    for script in "${!commands[@]}"; do
        local cmd_name="${commands[$script]}"
        local source_file="$LAB_HOME/$script"
        local target_link="$BIN_DIR/$cmd_name"
        
        if [ -f "$source_file" ]; then
            # Remove old symlink if it exists
            if [ -L "$target_link" ]; then
                sudo rm "$target_link"
            fi
            
            # Create new symlink
            sudo ln -sf "$source_file" "$target_link"
            print_success "Installed: $cmd_name → $script"
            ((installed++))
        else
            print_warning "Script not found: $source_file"
        fi
    done
    
    if [ $installed -eq 0 ]; then
        print_error "No commands were installed"
        return 1
    fi
    
    echo ""
    print_color "$GREEN" "  You can now use these commands from anywhere:"
    for cmd_name in "${commands[@]}"; do
        print_color "$CYAN" "    • $cmd_name"
    done
}

# Create helper wrapper scripts for individual labs
create_lab_wrappers() {
    print_step "Creating convenience commands for labs..."
    
    # Check if labs directory exists
    if [ ! -d "$LAB_HOME/labs" ]; then
        print_warning "No 'labs' directory found - skipping wrapper creation"
        return 0
    fi
    
    local wrapper_count=0
    
    # Find all lab scripts in both root labs/ and module subdirectories
    # Use temporary file to avoid process substitution issues
    local temp_file=$(mktemp)
    find "$LAB_HOME/labs" -type f -name "[0-9][0-9]*-*.sh" 2>/dev/null > "$temp_file"
    
    local lab_count=$(wc -l < "$temp_file")
    print_color "$CYAN" "  Found $lab_count lab scripts to process..."
    
    # Process each lab script
    while IFS= read -r lab_script; do
        if [ -f "$lab_script" ]; then
            local lab_basename=$(basename "$lab_script")
            
            # Extract lab number from various formats:
            # 01-name.sh → 01
            # 03A-name.sh → 03
            # 10B-name.sh → 10
            if [[ $lab_basename =~ ^([0-9]{2})[A-Z]?-.*\.sh$ ]]; then
                local lab_num="${BASH_REMATCH[1]}"
                local cmd_name="rhcsa-lab-${lab_num}"
                local target_link="$BIN_DIR/$cmd_name"
                
                # Remove old symlink if exists
                if [ -L "$target_link" ]; then
                    sudo rm "$target_link" 2>/dev/null
                fi
                
                # Create symlink
                if sudo ln -sf "$lab_script" "$target_link" 2>/dev/null; then
                    ((wrapper_count++))
                fi
            fi
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    if [ $wrapper_count -gt 0 ]; then
        print_success "Created $wrapper_count lab shortcuts"
        echo ""
        print_color "$CYAN" "  Examples:"
        print_color "$CYAN" "    • sudo rhcsa-lab-01  (run lab 01)"
        print_color "$CYAN" "    • sudo rhcsa-lab-03  (run lab 03A or first 03x found)"
    else
        print_warning "No numbered lab scripts found in labs/ directory"
        echo ""
        print_color "$YELLOW" "  Labs should be named: XX-topic.sh or XXY-topic.sh"
        print_color "$YELLOW" "  Where XX is a number (01, 02, 03...) and Y is optional letter (A, B, C...)"
    fi
}

# Display usage information
show_post_install_info() {
    print_header "Installation Complete!"
    
    cat << EOF
Your RHCSA lab environment is now set up and ready to use!

QUICK START GUIDE:
──────────────────────────────────────────────────────────────────

1. VIEW AVAILABLE LABS:
   cd $LAB_HOME/labs
   ls -1 [0-9]*.sh

2. RUN A LAB (two ways):
   
   Standard mode (exam-style):
     cd $LAB_HOME/labs
     sudo ./01-user-management.sh
   
   Or using the shortcut command:
     sudo rhcsa-lab-01

3. INTERACTIVE MODE (step-by-step learning):
     sudo rhcsa-lab-01 --interactive

4. VALIDATE YOUR WORK:
     sudo rhcsa-lab-01 --validate

5. VIEW SOLUTION:
     rhcsa-lab-01 --solution

6. TRACK YOUR PROGRESS:
     rhcsa-progress --summary
     rhcsa-progress --retry

COMMAND REFERENCE:
──────────────────────────────────────────────────────────────────

rhcsa-progress         View your lab completion progress
rhcsa-lab-XX           Run specific lab (replace XX with lab number)

DIRECTORY STRUCTURE:
──────────────────────────────────────────────────────────────────

$LAB_HOME/
  ├── labs/              Lab scripts (01-*.sh, 02-*.sh, etc.)
  ├── lab-runner.sh      Core framework (don't run directly)
  ├── track-progress.sh  Progress tracking system
  └── lab_progress.txt   Your progress data (auto-created)

TIPS:
──────────────────────────────────────────────────────────────────

• Always use sudo when running labs (they modify system state)
• Use --interactive mode for learning, standard mode for exam prep
• Use --objectives flag for quick reference while working
• Check your progress regularly with rhcsa-progress

For issues or updates, see: $LAB_HOME/README.md

EOF
}

# Uninstall function
uninstall_labs() {
    print_header "Uninstalling RHCSA Lab Framework"
    
    print_color "$YELLOW" "This will:"
    echo "  • Remove command shortcuts from $BIN_DIR"
    echo "  • Optionally remove $LAB_HOME directory"
    echo ""
    
    read -p "Are you sure you want to uninstall? (y/n) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "$CYAN" "Uninstall cancelled"
        exit 0
    fi
    
    print_step "Removing command shortcuts..."
    
    # Remove core commands
    local removed=0
    for cmd in rhcsa-lab rhcsa-progress; do
        if [ -L "$BIN_DIR/$cmd" ]; then
            sudo rm "$BIN_DIR/$cmd"
            print_success "Removed: $cmd"
            ((removed++))
        fi
    done
    
    # Remove lab wrapper commands
    mapfile -t lab_cmds < <(find "$BIN_DIR" -type l -name "rhcsa-lab-[0-9][0-9]" 2>/dev/null)
    for lab_cmd in "${lab_cmds[@]}"; do
        if [ -n "$lab_cmd" ] && [ -L "$lab_cmd" ]; then
            sudo rm "$lab_cmd" 2>/dev/null
            print_success "Removed: $(basename "$lab_cmd")"
            ((removed++))
        fi
    done
    
    if [ $removed -gt 0 ]; then
        print_success "Removed $removed command shortcuts"
    else
        print_warning "No command shortcuts found to remove"
    fi
    
    # Ask about removing lab directory
    echo ""
    read -p "Remove lab directory at $LAB_HOME? (y/n) " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "$LAB_HOME" ]; then
            rm -rf "$LAB_HOME"
            print_success "Removed $LAB_HOME"
        else
            print_warning "Lab directory not found at $LAB_HOME"
        fi
    else
        print_color "$CYAN" "Lab directory preserved at $LAB_HOME"
    fi
    
    echo ""
    print_color "$GREEN" "Uninstall complete!"
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
    --uninstall, -u    Uninstall the lab framework
    --help, -h         Show this help message

INSTALLATION PROCESS:
    1. Check and install dependencies (dos2unix)
    2. Convert scripts to Unix line endings (LF)
    3. Set executable permissions
    4. Copy files to ~/Labs directory
    5. Create command shortcuts in /usr/local/bin

AFTER INSTALLATION:
    • Labs will be in ~/Labs/labs/
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
    
    print_color "$CYAN" "This script will:"
    echo "  1. Check and install dependencies"
    echo "  2. Fix script encoding (convert CRLF to LF)"
    echo "  3. Set executable permissions"
    echo "  4. Set up lab directory at $LAB_HOME"
    echo "  5. Install command shortcuts for easy access"
    echo ""
    
    read -p "Press ENTER to continue or Ctrl+C to cancel..." -r
    
    # Run setup steps
    check_privileges
    check_dependencies
    fix_line_endings
    set_permissions
    setup_lab_directory
    install_commands
    create_lab_wrappers
    
    # Show final information
    show_post_install_info
}

# Execute main function
main "$@"
