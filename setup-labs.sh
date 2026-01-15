#!/bin/bash
# setup-labs.sh
# RHCSA Lab Environment Setup Script - SIMPLIFIED VERSION

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

print_color() { echo -e "${1}${2}${NC}"; }

# Must run as regular user (not root)
if [ "$EUID" -eq 0 ]; then
    print_color "$RED" "ERROR: Do not run as root"
    echo "Run as regular user: bash setup-labs.sh"
    echo "The script will prompt for sudo when needed."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/local/bin"

echo ""
print_color "$CYAN" "═══════════════════════════════════════════════════════"
print_color "$CYAN" "  RHCSA Lab Setup"
print_color "$CYAN" "═══════════════════════════════════════════════════════"
echo ""
echo "Working directory: $SCRIPT_DIR"
echo ""

# Get sudo access upfront
print_color "$YELLOW" "This script needs sudo access..."
if ! sudo -v; then
    print_color "$RED" "Failed to get sudo access"
    exit 1
fi
print_color "$GREEN" "✓ Sudo access obtained"
echo ""

# 1. Fix line endings if dos2unix available
if command -v dos2unix &>/dev/null; then
    echo "Converting line endings..."
    find "$SCRIPT_DIR" -name "*.sh" -exec dos2unix {} + 2>/dev/null
    print_color "$GREEN" "✓ Line endings fixed"
else
    print_color "$YELLOW" "⚠ dos2unix not installed (skipping)"
fi

# 2. Set permissions
echo "Setting permissions..."
find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
print_color "$GREEN" "✓ Permissions set"

# 3. Install rhcsa-progress
echo "Installing rhcsa-progress..."
sudo bash -c "cat > '$BIN_DIR/rhcsa-progress'" << 'EOF'
#!/bin/bash
cd "SCRIPT_DIR_PLACEHOLDER" || exit 1
exec bash "./track-progress.sh" "$@"
EOF
sudo sed -i "s|SCRIPT_DIR_PLACEHOLDER|$SCRIPT_DIR|g" "$BIN_DIR/rhcsa-progress"
sudo chmod +x "$BIN_DIR/rhcsa-progress"
print_color "$GREEN" "✓ Installed rhcsa-progress"

# 4. Create lab wrappers using a completely different approach
echo ""
echo "Creating lab wrappers..."

# Create temp directory
TEMP_DIR=$(mktemp -d)

# Use find with -exec to create wrappers (avoids loop issues)
find "$SCRIPT_DIR/labs" -type f -path "*/m[0-9][0-9]/*" -name "[0-9][0-9]*-*.sh" -print0 | \
while IFS= read -r -d '' lab_file; do
    lab_name=$(basename "$lab_file")
    
    # Extract lab ID (03A, 04B, etc.)
    if [[ $lab_name =~ ^([0-9]{2}[A-Z]?)-.*\.sh$ ]]; then
        lab_id="${BASH_REMATCH[1]}"
        cmd_name="rhcsa-lab-${lab_id}"
        lab_dir=$(dirname "$lab_file")
        
        # Create wrapper
        cat > "$TEMP_DIR/$cmd_name" << WRAPPER_EOF
#!/bin/bash
cd "$lab_dir" || exit 1
exec "./$lab_name" "\$@"
WRAPPER_EOF
        
        chmod +x "$TEMP_DIR/$cmd_name"
        echo "  ✓ $cmd_name"
    fi
done

# Count wrappers created
WRAPPER_COUNT=$(ls -1 "$TEMP_DIR"/rhcsa-lab-* 2>/dev/null | wc -l)

if [ "$WRAPPER_COUNT" -eq 0 ]; then
    print_color "$RED" "✗ No wrappers created!"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Copy all at once with sudo
echo ""
echo "Installing $WRAPPER_COUNT commands..."
sudo cp "$TEMP_DIR"/rhcsa-lab-* "$BIN_DIR/"

# Cleanup
rm -rf "$TEMP_DIR"

print_color "$GREEN" "✓ Installed $WRAPPER_COUNT lab commands"

# Show what's in one wrapper for verification
echo ""
print_color "$CYAN" "Verifying wrapper (showing rhcsa-lab-03A):"
echo "─────────────────────────────────────────"
cat "$BIN_DIR/rhcsa-lab-03A" 2>/dev/null || echo "Wrapper not found!"
echo "─────────────────────────────────────────"
echo ""
print_color "$YELLOW" "The 'cd' path above should be: $SCRIPT_DIR/labs/m02"

# 5. Show completion
echo ""
print_color "$CYAN" "═══════════════════════════════════════════════════════"
print_color "$GREEN" "Installation Complete!"
print_color "$CYAN" "═══════════════════════════════════════════════════════"
echo ""
echo "Try these commands:"
echo "  sudo rhcsa-lab-03A --validate"
echo "  rhcsa-progress --summary"
echo ""
