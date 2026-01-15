#!/bin/bash
# labs/04D-vim-mastery.sh  
# Lab: Vim Mastery and Real-World Text Editing
# Difficulty: Advanced
# RHCSA Objective: Use vim to create and edit text files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Vim Mastery and Real-World Text Editing"
LAB_DIFFICULTY="Advanced"
LAB_TIME_ESTIMATE="40-50 minutes"

setup_lab() {
    echo "Preparing vim mastery environment..."
    userdel -r vimuser 2>/dev/null || true
    useradd -m -s /bin/bash vimuser 2>/dev/null || true
    rm -rf /opt/vim_lab 2>/dev/null || true
    mkdir -p /opt/vim_lab/{configs,scripts,data} 2>/dev/null || true
    
    # Create practice files
    cat > /opt/vim_lab/hosts.txt << 'EOF'
127.0.0.1 localhost
192.168.1.10 server1.example.com server1
192.168.1.11 server2.example.com server2
192.168.1.12 server3.example.com server3
EOF

    cat > /opt/vim_lab/users.txt << 'EOF'
john:1001:users
jane:1002:users
admin:1003:wheel
guest:1004:users  
EOF

    cat > /opt/vim_lab/config_with_errors.txt << 'EOF'
# Configuration file
ServerName webserver01
Port 8080
Enabled true
LogLevel info
MaxConnections 1000
Timeout 30
# End of file
EOF

    chown -R vimuser:vimuser /opt/vim_lab
    echo "  ✓ Vim practice environment ready with sample files"
}

prerequisites() {
    cat << 'EOF'
Essential Vim Modes:
  • Normal mode (Esc) - Navigation and commands
  • Insert mode (i,a,o) - Text entry
  • Visual mode (v,V) - Selection
  • Command mode (:) - Ex commands

Critical Commands:
  • Navigation: hjkl, gg, G, w, b, 0, $
  • Insert: i, a, o, O, I, A
  • Delete: x, dd, dw, d$
  • Copy/Paste: yy, p, P
  • Undo/Redo: u, Ctrl+r
  • Search: /pattern, n, N  
  • Replace: :s/old/new/, :%s/old/new/g
  • Save/Quit: :w, :q, :wq, :q!, ZZ
EOF
}

scenario() {
    cat << 'EOF'
SCENARIO:
You're managing RHEL 10 servers and need to edit configuration files efficiently.
Vim is the standard editor on minimal systems and in emergency situations.
Master vim to handle complex edits quickly and confidently.

OBJECTIVES:
  1. Basic editing - Create /opt/vim_lab/scripts/backup.sh:
     • Enter insert mode (i)
     • Type shebang: #!/bin/bash
     • Add 3 comment lines
     • Add echo command
     • Save and quit (:wq)

  2. Navigation mastery - Edit /opt/vim_lab/hosts.txt:
     • Jump to beginning (gg) and end (G)
     • Jump to end of line ($)
     • Navigate by words (w, b)
     • Go to specific line (:15 or 15G)

  3. Deletion techniques - Edit /opt/vim_lab/users.txt:
     • Delete single character (x)
     • Delete entire line (dd)
     • Delete word (dw)
     • Delete from cursor to end of line (d$)
     • Undo changes (u)

  4. Copy and paste - Duplicate entries in users.txt:
     • Yank (copy) line (yy)
     • Paste below (p) or above (P)
     • Visual mode selection (V)
     • Yank multiple lines
     • Paste block

  5. Search and replace - Fix /opt/vim_lab/config_with_errors.txt:
     • Search for "Port" (/)
     • Replace single: :s/8080/80/
     • Replace all: :%s/old/new/g
     • Replace with confirm: :%s/old/new/gc

  6. Advanced editing - Create /opt/vim_lab/configs/system.conf:
     • Multiple lines at once (o for new line)
     • Insert at beginning of line (I)
     • Append at end of line (A)
     • Visual block mode (Ctrl+v)
     • Repeat last command (.)

SUCCESS CRITERIA:
  • Can enter/exit insert mode instinctively
  • Navigate without arrow keys (hjkl, gg, G, w, b)
  • Delete efficiently (dd, dw, d$)
  • Copy/paste blocks (yy, p, visual mode)
  • Search and replace (:s, :%s)
  • Save/quit without hesitation (:wq, :q!, ZZ)
EOF
}

objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create script with basic editing (i, :wq)
  ☐ 2. Navigate files (gg, G, $, w, b)
  ☐ 3. Delete with dd, dw, d$, x
  ☐ 4. Copy with yy, paste with p
  ☐ 5. Search (/) and replace (:s, :%s/old/new/g)
  ☐ 6. Advanced: visual mode, block editing
EOF
}

get_step_count() { echo "6"; }

scenario_context() {
    echo "Master vim for efficient server configuration editing"
}

show_step_1() {
    cat << 'EOF'
TASK: Basic vim editing - Create shell script

Create /opt/vim_lab/scripts/backup.sh with:
  #!/bin/bash
  # Backup script for system files
  # Created: $(date)
  echo "Starting backup..."

Practice: i (insert), Esc (normal), :wq (save and quit)
EOF
}

validate_step_1() {
    [ -f /opt/vim_lab/scripts/backup.sh ] && grep -q "#!/bin/bash" /opt/vim_lab/scripts/backup.sh
}

solution_step_1() {
    cat << 'EOF'
vim /opt/vim_lab/scripts/backup.sh
# Press: i (enter insert mode)
# Type: #!/bin/bash
# Press: Enter
# Type: # Backup script for system files
# Press: Enter  
# Type: # Created: $(date)
# Press: Enter
# Type: echo "Starting backup..."
# Press: Esc (back to normal mode)
# Type: :wq
# Press: Enter

KEY CONCEPTS:
- i: Insert before cursor
- I: Insert at beginning of line
- a: Append after cursor
- A: Append at end of line
- o: Open new line below
- O: Open new line above
- Esc: Always returns to normal mode
- :wq: Write and quit
- :w: Write (save) only
- :q: Quit (fails if unsaved)
- :q!: Force quit (discard changes)
- ZZ: Save and quit (no colon needed)
EOF
}

hint_step_1() {
    echo "vim file, press i to insert, type content, Esc, :wq to save"
}

show_step_2() {
    cat << 'EOF'
TASK: Navigation mastery

Open /opt/vim_lab/hosts.txt and practice:
  • gg - Go to first line
  • G - Go to last line
  • 3G or :3 - Go to line 3
  • 0 - Beginning of line
  • $ - End of line
  • w - Next word
  • b - Previous word
  • } - Next paragraph
  • { - Previous paragraph

Navigate WITHOUT using arrow keys!
EOF
}

validate_step_2() {
    [ -f /opt/vim_lab/hosts.txt ]
}

solution_step_2() {
    cat << 'EOF'
vim /opt/vim_lab/hosts.txt

NAVIGATION COMMANDS:
====================

Line Movement:
  gg    - First line of file (like 1G)
  G     - Last line of file
  5G    - Go to line 5
  :5    - Alternative to 5G
  
Horizontal Movement:
  0     - Beginning of line (column 0)
  ^     - First non-blank character
  $     - End of line
  
Word Movement:
  w     - Next word start
  W     - Next WORD (ignores punctuation)
  b     - Previous word start
  B     - Previous WORD
  e     - End of word
  E     - End of WORD
  
Character Movement:
  h     - Left
  j     - Down
  k     - Up
  l     - Right
  fx    - Find next 'x' on line
  Fx    - Find previous 'x' on line
  tx    - Until next 'x' on line
  ;     - Repeat last f/F/t/T
  ,     - Repeat last f/F/t/T backward
  
Screen Movement:
  Ctrl+f - Forward one screen (Page Down)
  Ctrl+b - Backward one screen (Page Up)
  Ctrl+d - Forward half screen
  Ctrl+u - Backward half screen
  H      - Top of screen (High)
  M      - Middle of screen (Middle)
  L      - Bottom of screen (Low)
  zz     - Center screen on cursor

WHY NO ARROW KEYS:
  1. Efficiency - hands stay on home row
  2. Speed - hjkl faster than reaching for arrows
  3. Universal - works on all systems (even vi on minimal installs)
  4. Pro habit - separates beginners from experts

PRACTICE DRILL:
  gg    - Jump to top
  G     - Jump to bottom
  3G    - Jump to line 3
  $     - End of line
  0     - Beginning of line
  w w w - Forward 3 words
  b b   - Back 2 words

Press: :q to quit without saving
EOF
}

hint_step_2() {
    echo "gg (top), G (bottom), $ (end of line), w (next word)"
}

show_step_3() {
    cat << 'EOF'
TASK: Deletion techniques

Edit /opt/vim_lab/users.txt:
  • x - Delete character under cursor
  • dd - Delete entire line
  • 3dd - Delete 3 lines
  • dw - Delete word
  • d$ - Delete to end of line
  • d0 - Delete to beginning of line
  • u - Undo last change
  • Ctrl+r - Redo

Delete the "guest" user line entirely.
EOF
}

validate_step_3() {
    [ -f /opt/vim_lab/users.txt ] && ! grep -q "guest" /opt/vim_lab/users.txt 2>/dev/null
}

solution_step_3() {
    cat << 'EOF'
vim /opt/vim_lab/users.txt

DELETION COMMANDS:
==================

Character:
  x     - Delete character under cursor
  X     - Delete character before cursor (backspace)
  3x    - Delete 3 characters

Word:
  dw    - Delete from cursor to start of next word
  dW    - Delete from cursor to start of next WORD
  de    - Delete from cursor to end of word
  dE    - Delete from cursor to end of WORD
  db    - Delete from cursor to start of previous word
  3dw   - Delete 3 words

Line:
  dd    - Delete entire line
  3dd   - Delete 3 lines
  d$    - Delete from cursor to end of line (same as D)
  d0    - Delete from cursor to beginning of line
  d^    - Delete from cursor to first non-blank
  
Special:
  dgg   - Delete from cursor to beginning of file
  dG    - Delete from cursor to end of file
  :3,5d - Delete lines 3-5 (command mode)
  :3,$d - Delete from line 3 to end

Undo/Redo:
  u       - Undo last change
  U       - Undo all changes to current line
  Ctrl+r  - Redo (undo the undo)
  .       - Repeat last change (powerful!)

TO DELETE "guest" LINE:
  1. Navigate to line with "guest": /guest then Enter
  2. Press: dd (deletes entire line)
  3. Save: :wq

Or alternatively:
  :g/guest/d   - Delete all lines containing "guest"

PRACTICE SEQUENCE:
  gg       - Go to top
  dd       - Delete first line
  u        - Undo (restore line)
  3dd      - Delete 3 lines
  u        - Undo
  dw       - Delete a word
  u        - Undo
  d$       - Delete to end of line
  u        - Undo
  :q!      - Quit without saving
EOF
}

hint_step_3() {
    echo "dd deletes line, dw deletes word, u undoes"
}

show_step_4() {
    cat << 'EOF'
TASK: Copy and paste (yank and put)

In /opt/vim_lab/users.txt:
  • yy - Yank (copy) current line
  • 3yy - Yank 3 lines
  • p - Paste below cursor
  • P - Paste above cursor
  • V - Visual line mode (select lines)
  • y - Yank selection

Duplicate the "admin" user line.
EOF
}

validate_step_4() {
    [ -f /opt/vim_lab/users.txt ] && [ $(grep -c "admin" /opt/vim_lab/users.txt) -ge 2 ]
}

solution_step_4() {
    cat << 'EOF'
vim /opt/vim_lab/users.txt

COPY/PASTE COMMANDS:
====================

Yank (Copy):
  yy    - Yank current line
  3yy   - Yank 3 lines
  y$    - Yank from cursor to end of line
  y0    - Yank from cursor to beginning of line
  yw    - Yank word
  yG    - Yank from cursor to end of file
  ygg   - Yank from cursor to beginning of file

Put (Paste):
  p     - Paste below/after cursor
  P     - Paste above/before cursor
  3p    - Paste 3 times

Visual Mode (Selection):
  v     - Visual character mode
  V     - Visual line mode
  Ctrl+v - Visual block mode
  
  In visual mode:
    hjkl  - Extend selection
    y     - Yank selection
    d     - Delete selection
    >     - Indent selection
    <     - Unindent selection

TO DUPLICATE "admin" LINE:
  Method 1:
    1. Navigate to admin line: /admin then Enter
    2. Yank line: yy
    3. Paste below: p
    4. Save: :wq
  
  Method 2:
    1. Navigate to admin line
    2. Visual line: V
    3. Yank: y
    4. Move cursor where you want
    5. Paste: p
    6. Save: :wq

ADVANCED TECHNIQUES:
  "ayy     - Yank line to register 'a'
  "ap      - Paste from register 'a'
  :reg     - View all registers
  
  Ctrl+v (visual block)
    - Select rectangular block
    - y to copy, p to paste
    - I to insert at start of all lines
    - Esc Esc to apply

COMMON PATTERNS:
  ddp      - Swap current line with next
  yyp      - Duplicate current line
  3yy      - Copy 3 lines
  5p       - Paste 5 times
EOF
}

hint_step_4() {
    echo "yy copies line, p pastes below, P pastes above"
}

show_step_5() {
    cat << 'EOF'
TASK: Search and replace

Edit /opt/vim_lab/config_with_errors.txt:
  • /pattern - Search forward
  • ?pattern - Search backward
  • n - Next match
  • N - Previous match
  • :s/old/new/ - Replace on current line
  • :%s/old/new/g - Replace in entire file
  • :%s/old/new/gc - Replace with confirmation

Change Port from 8080 to 80
Change "info" to "debug"
EOF
}

validate_step_5() {
    [ -f /opt/vim_lab/config_with_errors.txt ] && \
    grep -q "Port 80" /opt/vim_lab/config_with_errors.txt && \
    grep -q "LogLevel debug" /opt/vim_lab/config_with_errors.txt
}

solution_step_5() {
    cat << 'EOF'
vim /opt/vim_lab/config_with_errors.txt

SEARCH COMMANDS:
================

Basic Search:
  /pattern   - Search forward for pattern
  ?pattern   - Search backward for pattern
  n          - Repeat search forward
  N          - Repeat search backward
  *          - Search forward for word under cursor
  #          - Search backward for word under cursor

Search Options:
  :set ic        - Ignore case
  :set noic      - Case sensitive (default)
  :set hls       - Highlight search
  :set nohls     - No highlight
  /pattern\c     - Case-insensitive this search only
  /pattern\C     - Case-sensitive this search only

REPLACE COMMANDS:
=================

Current Line:
  :s/old/new/      - Replace first occurrence on line
  :s/old/new/g     - Replace all occurrences on line
  :s/old/new/gc    - Replace with confirmation

Entire File:
  :%s/old/new/     - Replace first in each line (whole file)
  :%s/old/new/g    - Replace ALL occurrences (whole file)
  :%s/old/new/gc   - Replace ALL with confirmation

Range:
  :3,7s/old/new/g   - Lines 3-7 only
  :.,+5s/old/new/g  - Current line plus next 5
  :'<,'>s/old/new/g - Visual selection (automatically added)

Special:
  :g/pattern/s/old/new/g   - Replace in lines matching pattern
  :g!/pattern/s/old/new/g  - Replace in lines NOT matching

SOLUTION FOR THIS LAB:
======================

Step 1: Change Port 8080 to 80
  /Port          - Find "Port"
  :s/8080/80/    - Replace on this line
  # Or: :%s/8080/80/g for all occurrences

Step 2: Change info to debug
  /info          - Find "info"
  :s/info/debug/ - Replace on this line
  # Or: :%s/info/debug/g for all occurrences

Step 3: Save
  :wq

ALTERNATIVE (all at once):
  :%s/8080/80/g | %s/info/debug/g
  :wq

CONFIRMATION MODE EXAMPLE:
  :%s/old/new/gc
  
  For each match, vim asks:
    y - Replace this match
    n - Skip this match
    a - Replace this and all remaining
    q - Quit (don't replace any more)
    l - Replace this match and quit
    ^E - Scroll down
    ^Y - Scroll up

WHY USE CONFIRMATION:
  - When you're not 100% sure
  - When pattern might match unintended places
  - When you want to review each change
  - When working with critical config files

REGEX PATTERNS:
  .     - Any character
  *     - 0 or more of previous
  ^     - Start of line
  $     - End of line
  \d    - Digit
  \w    - Word character
  
  Example: :%s/Port.*$/Port 80/
  Replaces "Port anything" with "Port 80"
EOF
}

hint_step_5() {
    echo "/pattern to search, :s/old/new/ to replace on line, :%s/old/new/g for entire file"
}

show_step_6() {
    cat << 'EOF'
TASK: Advanced editing techniques

Create /opt/vim_lab/configs/system.conf with 10 lines of configuration.
Practice:
  • o - Open new line below
  • O - Open new line above
  • I - Insert at line beginning
  • A - Insert at line end
  • Ctrl+v - Visual block mode
  • . - Repeat last command

Add comment # to start of lines 2-5 using visual block mode.
EOF
}

validate_step_6() {
    [ -f /opt/vim_lab/configs/system.conf ] && [ $(wc -l < /opt/vim_lab/configs/system.conf) -ge 10 ]
}

solution_step_6() {
    cat << 'EOF'
vim /opt/vim_lab/configs/system.conf

ADVANCED EDITING:
=================

Multiple Insert Modes:
  i    - Insert before cursor
  I    - Insert at beginning of line (first non-blank)
  a    - Append after cursor
  A    - Append at end of line
  o    - Open new line below current line
  O    - Open new line above current line
  s    - Substitute character (delete char, enter insert)
  S    - Substitute entire line
  C    - Change from cursor to end of line

Repeat Command:
  .    - Repeat last change
  
  Example workflow:
    dd   - Delete line
    j    - Move down
    .    - Delete this line too (repeats dd)
    j    - Move down
    .    - Delete this line too

Visual Block Mode (Ctrl+v):
  1. Move cursor to start position
  2. Press Ctrl+v (enter visual block mode)
  3. Use hjkl to select rectangular block
  4. Press I (capital i)
  5. Type text (e.g., # for comment)
  6. Press Esc twice
  7. Text inserted at start of all selected lines

TO ADD # TO LINES 2-5:
  Method 1 (Visual Block):
    :2          - Go to line 2
    Ctrl+v      - Visual block
    3j          - Select down 3 more lines (total 4 lines: 2-5)
    I           - Insert mode
    # (space)   - Type "# "
    Esc Esc     - Apply to all lines
  
  Method 2 (Command):
    :2,5s/^/# / - Add "# " to start of lines 2-5
  
  Method 3 (Loop):
    :2          - Go to line 2
    I           - Insert mode
    # (space)   - Type "# "
    Esc         - Back to normal
    j           - Down one line
    .           - Repeat (adds # )
    j           - Down
    .           - Repeat
    j           - Down
    .           - Repeat

CREATE 10-LINE CONFIG:
  vim /opt/vim_lab/configs/system.conf
  i           - Insert mode
  Type line 1: hostname=server01
  o           - New line below (enters insert)
  Type line 2: ip_address=192.168.1.100
  o           - New line
  ... continue for 10 lines ...
  Esc         - Normal mode
  :wq         - Save and quit

MACROS (Advanced):
  qa          - Start recording macro to register 'a'
  ... commands ...
  q           - Stop recording
  @a          - Play macro from register 'a'
  5@a         - Play macro 5 times
  @@          - Repeat last macro

MARKS (Advanced):
  ma          - Set mark 'a' at current position
  'a          - Jump to line of mark 'a'
  `a          - Jump to exact position of mark 'a'
  '.          - Jump to last edited line
  ''          - Jump to previous location
EOF
}

hint_step_6() {
    echo "o for new line, Ctrl+v for block selection, I to insert at block start"
}

validate() {
    local score=0
    local total=6
    
    echo "Checking your configuration..."
    echo ""
    
    validate_step_1 && { print_color "$GREEN" "  ✓ Step 1: Script created"; ((score++)); } || print_color "$RED" "  ✗ Step 1 incomplete"
    validate_step_2 && { print_color "$GREEN" "  ✓ Step 2: File exists"; ((score++)); } || print_color "$RED" "  ✗ Step 2 incomplete"
    validate_step_3 && { print_color "$GREEN" "  ✓ Step 3: Guest deleted"; ((score++)); } || print_color "$RED" "  ✗ Step 3 incomplete"
    validate_step_4 && { print_color "$GREEN" "  ✓ Step 4: Admin duplicated"; ((score++)); } || print_color "$RED" "  ✗ Step 4 incomplete"
    validate_step_5 && { print_color "$GREEN" "  ✓ Step 5: Replacements made"; ((score++)); } || print_color "$RED" "  ✗ Step 5 incomplete"
    validate_step_6 && { print_color "$GREEN" "  ✓ Step 6: Config created"; ((score++)); } || print_color "$RED" "  ✗ Step 6 incomplete"
    
    echo ""
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED - VIM MASTERY ACHIEVED!"
        echo ""
        echo "You've mastered the essential vim skills:"
        echo "  • Mode switching (normal, insert, visual)"
        echo "  • Efficient navigation (hjkl, gg, G, w, b, $)"
        echo "  • Deletion techniques (dd, dw, d$, x)"
        echo "  • Copy/paste operations (yy, p, visual mode)"
        echo "  • Search and replace (/, :s, :%s)"
        echo "  • Advanced editing (o, I, A, visual block)"
        echo ""
        echo "You're now ready for real-world vim usage!"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Keep practicing! Vim mastery takes time."
        echo "Run with --solution to see detailed explanations."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    [ $score -eq $total ]
}

solution() {
    cat << 'EOF'
VIM MASTERY CHEAT SHEET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MODES:
  Normal (Esc) - Navigation and commands
  Insert (i,a,o) - Type text
  Visual (v,V,Ctrl+v) - Select text
  Command (:) - Ex commands

ESSENTIAL COMMANDS:
  Movement: hjkl, gg, G, w, b, 0, $
  Insert: i, a, o, O, I, A
  Delete: x, dd, dw, d$
  Copy: yy, p, P
  Undo: u, Ctrl+r
  Search: /pattern, n, N
  Replace: :s/old/new/, :%s/old/new/g
  Save/Quit: :w, :wq, :q!, ZZ

EXAM SURVIVAL:
  1. Esc Esc - Return to normal mode (if confused)
  2. :q! - Quit without saving (escape hatch)
  3. u - Undo mistakes
  4. /keyword - Find what you need fast
  5. :%s/old/new/g - Quick global changes

PRACTICE DAILY:
  Run: vimtutor (built-in 30-minute tutorial)
  Practice: Edit /etc/hosts, ~/.bashrc
  Goal: Stop using arrow keys entirely

Remember: Vim seems hard at first, but becomes natural
with practice. The speed and power are worth the learning curve!
EOF
}

cleanup_lab() {
    echo "Cleaning up vim lab..."
    userdel -r vimuser 2>/dev/null || true
    rm -rf /opt/vim_lab 2>/dev/null || true
    echo "  ✓ All vim lab components removed"
}

main "$@"
