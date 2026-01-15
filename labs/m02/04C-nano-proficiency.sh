#!/bin/bash
# labs/04C-nano-proficiency.sh
# Lab: Nano Editor Proficiency
# Difficulty: Intermediate  
# RHCSA Objective: Use text editors to create and edit files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Nano Editor Proficiency"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="15-20 minutes"

setup_lab() {
    echo "Preparing lab environment..."
    userdel -r nanouser 2>/dev/null || true
    useradd -m -s /bin/bash nanouser 2>/dev/null || true
    rm -rf /opt/nano_lab 2>/dev/null || true
    mkdir -p /opt/nano_lab 2>/dev/null || true
    
    # Create files to edit
    echo "This is line 1" > /opt/nano_lab/sample.txt
    echo "This is line 2" >> /opt/nano_lab/sample.txt
    echo "This is line 3 with a typo: recieve" >> /opt/nano_lab/sample.txt
    
    chown -R nanouser:nanouser /opt/nano_lab
    echo "  ✓ Nano practice environment ready"
}

prerequisites() {
    cat << 'EOF'
Commands: nano, ^O (Ctrl+O save), ^X (Ctrl+X exit), ^K (cut), ^U (paste), ^W (search)
Files: /opt/nano_lab/sample.txt, /etc/hosts (practice editing)
EOF
}

scenario() {
    cat << 'EOF'
SCENARIO: You need to quickly edit configuration files on a production server.
Nano is perfect for quick edits when you don't need vim's advanced features.

OBJECTIVES:
  1. Edit /opt/nano_lab/sample.txt - fix typo "recieve" → "receive"
  2. Add new line at end: "This is line 4"
  3. Cut line 2 and paste at end (Ctrl+K, Ctrl+U)
  4. Search for "line" (Ctrl+W)
  5. Save and exit (Ctrl+O, Ctrl+X)
  6. Create new file /opt/nano_lab/config.conf with 5 lines
EOF
}

objectives_quick() {
    cat << 'EOF'
  ☐ 1. Fix typo in sample.txt (recieve → receive)
  ☐ 2. Add line 4
  ☐ 3. Cut and paste line 2 to end
  ☐ 4. Save properly (Ctrl+O)
  ☐ 5. Create config.conf with 5 lines
EOF
}

get_step_count() { echo "3"; }

scenario_context() {
    echo "Master nano for quick config file edits on production servers"
}

show_step_1() {
    cat << 'EOF'
TASK: Edit existing file and fix typo
Open /opt/nano_lab/sample.txt, find "recieve", change to "receive", save.
Commands: nano /opt/nano_lab/sample.txt, Ctrl+O (save), Ctrl+X (exit)
EOF
}

validate_step_1() {
    grep -q "receive" /opt/nano_lab/sample.txt 2>/dev/null && \
    ! grep -q "recieve" /opt/nano_lab/sample.txt 2>/dev/null
}

solution_step_1() {
    cat << 'EOF'
nano /opt/nano_lab/sample.txt
# Navigate to "recieve" with arrow keys
# Delete "ie" and type "ei" to make "receive"
# Press Ctrl+O (WriteOut/Save)
# Press Enter to confirm filename
# Press Ctrl+X to exit
EOF
}

hint_step_1() {
    echo "Open with nano, edit text, Ctrl+O to save, Ctrl+X to exit"
}

show_step_2() {
    cat << 'EOF'
TASK: Add new line and practice cut/paste
Add "This is line 4" at end. Cut line 2 (Ctrl+K), paste at end (Ctrl+U).
EOF
}

validate_step_2() {
    [ -f /opt/nano_lab/sample.txt ] && [ $(wc -l < /opt/nano_lab/sample.txt) -ge 4 ]
}

solution_step_2() {
    cat << 'EOF'
nano /opt/nano_lab/sample.txt
# Go to end, add: This is line 4
# Go to line 2, press Ctrl+K (cuts entire line)
# Go to end, press Ctrl+U (pastes line)
# Ctrl+O, Enter, Ctrl+X
EOF
}

hint_step_2() {
    echo "Ctrl+K cuts line, Ctrl+U pastes line"
}

show_step_3() {
    cat << 'EOF'
TASK: Create new config file
Create /opt/nano_lab/config.conf with 5 lines of config settings.
EOF
}

validate_step_3() {
    [ -f /opt/nano_lab/config.conf ] && [ $(wc -l < /opt/nano_lab/config.conf) -ge 5 ]
}

solution_step_3() {
    cat << 'EOF'
nano /opt/nano_lab/config.conf
# Type 5 lines:
# setting1=value1
# setting2=value2
# setting3=value3
# setting4=value4
# setting5=value5
# Ctrl+O, Enter, Ctrl+X
EOF
}

hint_step_3() {
    echo "Create new file with nano, add 5 lines, save"
}

validate() {
    local score=0
    local total=3
    
    validate_step_1 && ((score++))
    validate_step_2 && ((score++))
    validate_step_3 && ((score++))
    
    print_color "$CYAN" "FINAL SCORE: $score/$total"
    [ $score -eq $total ] && print_color "$GREEN" "PASSED" || print_color "$YELLOW" "INCOMPLETE"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    [ $score -eq $total ]
}

solution() {
    cat << 'EOF'
NANO ESSENTIALS:
- Ctrl+O: Save (WriteOut)
- Ctrl+X: Exit
- Ctrl+K: Cut line
- Ctrl+U: Paste
- Ctrl+W: Search
- Ctrl+G: Help

Use nano for quick edits, vim for complex editing.
EOF
}

cleanup_lab() {
    userdel -r nanouser 2>/dev/null || true
    rm -rf /opt/nano_lab 2>/dev/null || true
}

main "$@"
