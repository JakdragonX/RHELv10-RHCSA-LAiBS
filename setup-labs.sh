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
readonly BIN_DIR="/usr/bin"
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
    print_color "$YELLOW" "This script requires sudo privileges for some operations."
    print_color "$YELLOW" "You may be prompted for your password..."
    echo ""
    
    if ! sudo -v; then
        print_error "Failed to obtain sudo privileges"
        exit 1
    fi
    
    # Keep sudo credentials refreshed in background
    # This prevents timeout during long-running operations
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
    
    # Count scripts
    local script_count=$(find "$SCRIPT_DIR" -type f -name "*.sh" 2>/dev/null | wc -l)
    
    if [ $script_count -eq 0 ]; then
        print_warning "No shell scripts found in $SCRIPT_DIR"
        return 0
    fi
    
    print_color "$CYAN" "  Found $script_count shell scripts to check..."
    
    # Convert all scripts directly (dos2unix is idempotent - safe to run on already-converted files)
    # Using + instead of \; to batch process files for efficiency
    if find "$SCRIPT_DIR" -type f -name "*.sh" -exec dos2unix {} + 2>/dev/null; then
        print_success "All $script_count scripts now have Unix line endings"
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
        print_warning "No shell scripts found to make executable"
        return 0
    fi
    
    print_color "$CYAN" "  Found $count shell scripts to make executable..."
    
    # Use find with -exec for direct execution (most reliable)
    if find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null; then
        print_success "Made $count scripts executable"
    else
        print_warning "Some scripts may not have been made executable"
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
    
    echo "DEBUG: [install_commands] Starting installation" >&2
    
    # Install rhcsa-progress command
    local source_file="$LAB_HOME/track-progress.sh"
    local target_link="$BIN_DIR/rhcsa-progress"
    
    echo "DEBUG: [install_commands] source=$source_file" >&2
    echo "DEBUG: [install_commands] target=$target_link" >&2
    
    if [ ! -f "$source_file" ]; then
        print_error "Script not found: $source_file"
        return 1
    fi
    
    echo "DEBUG: [install_commands] Source file exists" >&2
    
    # Remove old symlink if exists
    sudo rm -f "$target_link" 2>/dev/null || true
    
    echo "DEBUG: [install_commands] About to create symlink" >&2
    
    # Create new symlink
    sudo ln -sf "$source_file" "$target_link" || {
        print_error "Failed to create symlink"
        return 1
    }
    
    echo "DEBUG: [install_commands] Symlink created successfully" >&2
    
    print_success "Installed: rhcsa-progress → track-progress.sh"
    
    echo "DEBUG: [install_commands] Printed success message" >&2
    echo ""
    
    print_success "Core framework command installed (rhcsa-progress)"
    print_color "$YELLOW" "  → Lab-specific commands (rhcsa-lab-XX) will be created in next step..."
    
    echo "" >&2
    echo "DEBUG: [install_commands] Function completing" >&2
    
    return 0
}

# Create helper wrapper scripts for individual labs
create_lab_wrappers() {
    print_step "Creating convenience commands for labs..."
    
    # Check if labs directory exists
    if [ ! -d "$LAB_HOME/labs" ]; then
        print_warning "No 'labs' directory found - skipping wrapper creation"
        return 0
    fi
    
    # Count lab scripts
    local lab_count=$(find "$LAB_HOME/labs" -type f -name "[0-9][0-9]*-*.sh" 2>/dev/null | wc -l)
    
    if [ "$lab_count" -eq 0 ]; then
        print_warning "No numbered lab scripts found in labs/ directory"
        echo ""
        print_color "$YELLOW" "  Labs should be named: XX-topic.sh or XXY-topic.sh"
        print_color "$YELLOW" "  Where XX is a number (01, 02, 03...) and Y is optional letter (A, B, C...)"
        return 0
    fi
    
    print_color "$CYAN" "  Found $lab_count lab scripts to process..."
    echo ""
    
    # Store all lab files in a temp file to process
    local temp_list=$(mktemp)
    find "$LAB_HOME/labs" -type f -name "[0-9][0-9]*-*.sh" 2>/dev/null > "$temp_list"
    
    # Process each lab file - create wrapper script
    cat "$temp_list" | while IFS= read -r lab_file; do
        [ -z "$lab_file" ] && continue
        [ ! -f "$lab_file" ] && continue
        
        local lab_basename=$(basename "$lab_file")
        
        # Extract FULL lab identifier including letter suffix (01, 03A, 03B, etc.)
        if [[ $lab_basename =~ ^([0-9]{2}[A-Z]?)-.*\.sh$ ]]; then
            local lab_id="${BASH_REMATCH[1]}"
            local cmd_name="rhcsa-lab-${lab_id}"
            local target_script="$BIN_DIR/$cmd_name"
            
            # Create a temporary wrapper script
            local wrapper_temp=$(mktemp)
            cat > "$wrapper_temp" << WRAPPER_EOF
#!/bin/bash
# Wrapper for ${lab_basename}
exec "${lab_file}" "\$@"
WRAPPER_EOF
            
            # Make temp file executable first
            chmod +x "$wrapper_temp"
            
            # Copy to target location with sudo (preserves permissions)
            sudo cp "$wrapper_temp" "$target_script"
            rm -f "$wrapper_temp"
            
            echo "✓ Created: $cmd_name → $lab_basename"
        fi
    done || true
    
    rm -f "$temp_list"
    
    echo ""
    print_success "Lab command shortcuts created!"
    echo ""
    print_color "$CYAN" "  You can now run labs with commands like:"
    print_color "$CYAN" "    • sudo rhcsa-lab-01  (if it exists)"
    print_color "$CYAN" "    • sudo rhcsa-lab-03A (for lab 03 part A)"
    print_color "$CYAN" "    • sudo rhcsa-lab-03B (for lab 03 part B)"
    print_color "$CYAN" "    • sudo rhcsa-lab-04A"
    echo ""
    print_color "$YELLOW" "  Note: Labs with letter suffixes (A, B, C) have separate commands"
    
    return 0
}

# Display usage information
show_post_install_info() {
    echo ""  # Ensure we start on a new line
    print_header "Installation Complete!"
    
    cat << 'EOF'
Your RHELv10-RHCSA-LAiBS lab environment is now set up and ready to use!

QUICK START GUIDE:
──────────────────────────────────────────────────────────────────

1. VIEW AVAILABLE LABS:
   cd ~/Labs/labs
   
   # List all modules
   ls -d m*/
   
   # View labs in a specific module
   ls m02/
   
   # View all labs at once
   find . -name "[0-9]*.sh" -type f

2. RUN A LAB (two ways):
   
   Standard mode (exam-style):
     cd ~/Labs/labs/m02
     sudo ./03A-bash-shell-basics.sh
   
   Or using the shortcut command:
     sudo rhcsa-lab-03

3. INTERACTIVE MODE (step-by-step learning):
     sudo rhcsa-lab-03 --interactive

4. VALIDATE YOUR WORK:
     sudo rhcsa-lab-03 --validate

5. VIEW SOLUTION:
     rhcsa-lab-03 --solution

6. TRACK YOUR PROGRESS:
     rhcsa-progress --summary
     rhcsa-progress --retry

COMMAND REFERENCE:
──────────────────────────────────────────────────────────────────

rhcsa-progress         View your lab completion progress
rhcsa-lab-XX           Run specific lab (replace XX with lab number)

DIRECTORY STRUCTURE:
──────────────────────────────────────────────────────────────────

~/Labs/
  ├── labs/              Lab scripts organized by modules
  │   ├── 00-lab-template.sh
  │   ├── 01-lab-example.sh
  │   ├── m02/          Module 2: Essential Command Line Skills
  │   │   ├── 03A-bash-shell-basics.sh
  │   │   ├── 03B-virtual-terminals-history.sh
  │   │   └── ...
  │   ├── m03/          Module 3: File Management
  │   └── ...
  ├── lab-runner.sh      Core framework (don't run directly)
  ├── track-progress.sh  Progress tracking system
  └── lab_progress.txt   Your progress data (auto-created)

TIPS:
──────────────────────────────────────────────────────────────────

• Always use sudo when running labs (they modify system state)
• Use --interactive mode for learning, standard mode for exam prep
• Use --objectives flag for quick reference while working
• Check your progress regularly with rhcsa-progress

For issues or updates, see: ~/Labs/README.md

EOF
}

# Uninstall function
uninstall_labs() {
    print_header "Uninstalling RHELv10-RHCSA-LAiBS"
    
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
    
    # Remove core command (just rhcsa-progress, not rhcsa-lab which doesn't exist)
    local removed=0
    if [ -L "$BIN_DIR/rhcsa-progress" ]; then
        sudo rm "$BIN_DIR/rhcsa-progress"
        print_success "Removed: rhcsa-progress"
        ((removed++))
    fi
    
    # Remove lab wrapper commands using temp file
    local temp_file=$(mktemp)
    find "$BIN_DIR" -type l -name "rhcsa-lab-[0-9][0-9]" 2>/dev/null > "$temp_file"
    
    while IFS= read -r lab_cmd; do
        if [ -n "$lab_cmd" ] && [ -L "$lab_cmd" ]; then
            sudo rm "$lab_cmd" 2>/dev/null
            print_success "Removed: $(basename "$lab_cmd")"
            ((removed++))
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
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
    
    echo "" >&2  # Force flush
    echo "DEBUG: About to install commands..." >&2
    
    install_commands
    local install_exit=$?
    
    echo "DEBUG: install_commands returned with exit code: $install_exit" >&2
    echo "" >&2
    echo "DEBUG: About to create lab wrappers..." >&2
    
    create_lab_wrappers
    
    echo "" >&2
    echo "DEBUG: Finished creating lab wrappers" >&2
    echo "DEBUG: About to show post-install info..." >&2
    
    # Show final information
    show_post_install_info
    
    echo "DEBUG: Finished showing post-install info" >&2
    
    # Cleanup sudo refresh process
    cleanup_sudo_refresh
    
    # Explicit exit with success
    exit 0
}

# Execute main function
main "$@"
