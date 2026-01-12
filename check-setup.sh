#!/bin/bash
# check-setup.sh
# Diagnostic script to verify RHCSA lab framework installation

set -uo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

print_color() {A
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo ""
    print_color "$CYAN" "════════════════════════════════════════════════════"
    print_color "$BOLD$CYAN" " $1"
    print_color "$CYAN" "════════════════════════════════════════════════════"
    echo ""
}

check_pass() {
    print_color "$GREEN" "  ✓ $1"
}

check_fail() {
    print_color "$RED" "  ✗ $1"
}

check_warn() {
    print_color "$YELLOW" "  ⚠ $1"
}

# Track overall status
ISSUES_FOUND=0

print_header "RHCSA Lab Framework Setup Diagnostic"

# Check 1: Lab directory exists
print_color "$CYAN" "[1/8] Checking lab directory..."
if [ -d "$HOME/Labs" ]; then
    check_pass "Lab directory exists at $HOME/Labs"
    
    # Check for framework marker
    if [ -f "$HOME/Labs/.lab-framework" ]; then
        check_pass "Framework marker file found"
        echo "        Installed: $(grep "Installed:" "$HOME/Labs/.lab-framework" | cut -d: -f2-)"
    else
        check_warn "Framework marker missing (minor issue)"
    fi
else
    check_fail "Lab directory not found at $HOME/Labs"
    echo ""
    print_color "$YELLOW" "        Run: bash setup-labs.sh"
    ((ISSUES_FOUND++))
fi
echo ""

# Check 2: Core framework files
print_color "$CYAN" "[2/8] Checking framework files..."
declare -a required_files=(
    "$HOME/Labs/lab-runner.sh"
    "$HOME/Labs/track-progress.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            check_pass "$(basename "$file") exists and is executable"
        else
            check_warn "$(basename "$file") exists but is not executable"
            echo "        Fix: chmod +x $file"
            ((ISSUES_FOUND++))
        fi
    else
        check_fail "$(basename "$file") not found"
        echo "        Expected location: $file"
        ((ISSUES_FOUND++))
    fi
done
echo ""

# Check 3: Labs directory and scripts
print_color "$CYAN" "[3/8] Checking lab scripts..."
if [ -d "$HOME/Labs/labs" ]; then
    lab_count=$(find "$HOME/Labs/labs" -type f -name "[0-9][0-9]-*.sh" 2>/dev/null | wc -l)
    
    if [ "$lab_count" -gt 0 ]; then
        check_pass "Found $lab_count lab scripts"
        
        # Check if they're executable
        non_executable=$(find "$HOME/Labs/labs" -type f -name "[0-9][0-9]-*.sh" ! -executable 2>/dev/null | wc -l)
        if [ "$non_executable" -gt 0 ]; then
            check_warn "$non_executable lab scripts are not executable"
            echo "        Fix: chmod +x $HOME/Labs/labs/*.sh"
            ((ISSUES_FOUND++))
        else
            check_pass "All lab scripts are executable"
        fi
    else
        check_warn "No numbered lab scripts found in labs/ directory"
        echo "        This might be normal if you haven't created labs yet"
    fi
else
    check_fail "Labs directory not found at $HOME/Labs/labs"
    ((ISSUES_FOUND++))
fi
echo ""

# Check 4: Command shortcuts
print_color "$CYAN" "[4/8] Checking command shortcuts in PATH..."
declare -A commands=(
    ["rhcsa-progress"]="$HOME/Labs/track-progress.sh"
)

# Add lab commands if they exist
if [ -d "$HOME/Labs/labs" ]; then
    while IFS= read -r -d '' lab_script; do
        lab_basename=$(basename "$lab_script")
        if [[ $lab_basename =~ ^([0-9]{2})-.*\.sh$ ]]; then
            lab_num="${BASH_REMATCH[1]}"
            commands["rhcsa-lab-${lab_num}"]="$lab_script"
        fi
    done < <(find "$HOME/Labs/labs" -type f -name "[0-9][0-9]-*.sh" -print0 2>/dev/null)
fi

missing_commands=0
for cmd_name in "${!commands[@]}"; do
    if command -v "$cmd_name" &>/dev/null; then
        # Check if it's a symlink to the right location
        cmd_path=$(command -v "$cmd_name")
        if [ -L "$cmd_path" ]; then
            target=$(readlink -f "$cmd_path")
            expected=$(readlink -f "${commands[$cmd_name]}")
            if [ "$target" = "$expected" ]; then
                check_pass "$cmd_name → correct target"
            else
                check_warn "$cmd_name points to wrong location"
                echo "        Current: $target"
                echo "        Expected: $expected"
                ((ISSUES_FOUND++))
            fi
        else
            check_warn "$cmd_name exists but is not a symlink"
            ((ISSUES_FOUND++))
        fi
    else
        check_fail "$cmd_name not found in PATH"
        ((missing_commands++))
        ((ISSUES_FOUND++))
    fi
done

if [ $missing_commands -gt 0 ]; then
    echo ""
    print_color "$YELLOW" "        Fix: bash setup-labs.sh"
fi
echo ""

# Check 5: Line endings (CRLF vs LF)
print_color "$CYAN" "[5/8] Checking script line endings..."
if command -v file &>/dev/null; then
    crlf_count=0
    
    while IFS= read -r -d '' script; do
        if file "$script" | grep -q "CRLF"; then
            if [ $crlf_count -eq 0 ]; then
                check_warn "Found scripts with Windows line endings (CRLF):"
            fi
            echo "        $(basename "$script")"
            ((crlf_count++))
        fi
    done < <(find "$HOME/Labs" -type f -name "*.sh" -print0 2>/dev/null)
    
    if [ $crlf_count -gt 0 ]; then
        echo ""
        print_color "$YELLOW" "        Fix: cd $HOME/Labs && dos2unix **/*.sh"
        ((ISSUES_FOUND++))
    else
        check_pass "All scripts have Unix line endings (LF)"
    fi
else
    check_warn "Cannot check line endings (file command not available)"
fi
echo ""

# Check 6: Dependencies
print_color "$CYAN" "[6/8] Checking dependencies..."
deps_ok=true

# Check dos2unix
if command -v dos2unix &>/dev/null; then
    check_pass "dos2unix is installed"
else
    check_fail "dos2unix is not installed"
    echo "        Install: sudo dnf install dos2unix"
    deps_ok=false
    ((ISSUES_FOUND++))
fi

# Check bash version
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    check_pass "Bash version ${BASH_VERSION} (>= 4.0 required)"
else
    check_fail "Bash version ${BASH_VERSION} is too old (need 4.0+)"
    deps_ok=false
    ((ISSUES_FOUND++))
fi

# Check sudo
if command -v sudo &>/dev/null; then
    check_pass "sudo is available"
else
    check_warn "sudo is not available (required for running labs)"
    echo "        Install: su -c 'dnf install sudo'"
    ((ISSUES_FOUND++))
fi
echo ""

# Check 7: Progress tracking
print_color "$CYAN" "[7/8] Checking progress tracking..."
if [ -f "$HOME/Labs/lab_progress.txt" ]; then
    entry_count=$(grep -cv "^#" "$HOME/Labs/lab_progress.txt" 2>/dev/null || echo "0")
    if [ "$entry_count" -gt 0 ]; then
        check_pass "Progress file exists with $entry_count recorded attempts"
    else
        check_pass "Progress file exists (no attempts yet)"
    fi
else
    check_pass "No progress file yet (will be created on first validation)"
fi
echo ""

# Check 8: File permissions on Labs directory
print_color "$CYAN" "[8/8] Checking directory permissions..."
if [ -d "$HOME/Labs" ]; then
    labs_owner=$(stat -c '%U' "$HOME/Labs" 2>/dev/null)
    current_user=$(whoami)
    
    if [ "$labs_owner" = "$current_user" ]; then
        check_pass "Lab directory owned by $current_user"
    else
        check_warn "Lab directory owned by '$labs_owner' (you are '$current_user')"
        echo "        This might cause permission issues"
        ((ISSUES_FOUND++))
    fi
    
    # Check if writable
    if [ -w "$HOME/Labs" ]; then
        check_pass "Lab directory is writable"
    else
        check_fail "Lab directory is not writable"
        echo "        Fix: chmod u+w $HOME/Labs"
        ((ISSUES_FOUND++))
    fi
fi
echo ""

# Final summary
print_header "Diagnostic Summary"

if [ $ISSUES_FOUND -eq 0 ]; then
    print_color "$GREEN" "✓ All checks passed!"
    echo ""
    echo "Your RHCSA lab framework is properly installed and ready to use."
    echo ""
    print_color "$CYAN" "Quick Start:"
    echo "  1. View available labs:  ls ~/Labs/labs/"
    echo "  2. Run your first lab:   sudo rhcsa-lab-01"
    echo "  3. Track progress:       rhcsa-progress --summary"
else
    print_color "$YELLOW" "⚠ Found $ISSUES_FOUND issue(s)"
    echo ""
    echo "Review the warnings and errors above for specific fixes."
    echo ""
    print_color "$CYAN" "Common Fixes:"
    echo "  • Reinstall:         cd ~/rhcsa-labs && bash setup-labs.sh"
    echo "  • Fix line endings:  cd ~/Labs && dos2unix **/*.sh"
    echo "  • Fix permissions:   chmod +x ~/Labs/**/*.sh"
    echo "  • Install deps:      sudo dnf install dos2unix"
fi
echo ""

exit $ISSUES_FOUND
