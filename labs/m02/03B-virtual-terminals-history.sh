#!/bin/bash
# labs/03B-virtual-terminals-history.sh
# Lab: Virtual Terminals and Command History Management
# Difficulty: Intermediate
# RHCSA Objective: Understand and use essential tools; Access systems via text console

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Virtual Terminals and Command History Management"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Remove test users from previous attempts
    userdel -r sysadmin1 2>/dev/null || true
    userdel -r sysadmin2 2>/dev/null || true
    rm -rf /opt/terminal_lab 2>/dev/null || true
    
    # Create test users for multi-session practice
    useradd -m -s /bin/bash sysadmin1 2>/dev/null || true
    echo "sysadmin1:password123" | chpasswd 2>/dev/null || true
    useradd -m -s /bin/bash sysadmin2 2>/dev/null || true
    echo "sysadmin2:password123" | chpasswd 2>/dev/null || true
    
    # Create working directory
    mkdir -p /opt/terminal_lab 2>/dev/null || true
    
    # Setup bash history configuration file for practice
    mkdir -p /home/sysadmin1/.config 2>/dev/null || true
    cat > /home/sysadmin1/.bashrc_custom << 'EOFRC'
# Custom history settings for lab
export HISTSIZE=1000
export HISTFILESIZE=2000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups:erasedups
EOFRC
    
    chown -R sysadmin1:sysadmin1 /home/sysadmin1 2>/dev/null || true
    chown -R sysadmin2:sysadmin2 /home/sysadmin2 2>/dev/null || true
    
    echo "  ✓ Test users created: sysadmin1, sysadmin2"
    echo "  ✓ Working directory created at /opt/terminal_lab"
    echo "  ✓ Custom bash configuration prepared"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES: Knowledge and commands needed
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of Linux virtual console concepts
  • Basic knowledge of bash shell environment
  • Familiarity with environment variables
  • Understanding of multi-user systems

Commands You'll Use:
  • who       - Display currently logged in users
  • w         - Show who is logged in and what they're doing
  • chvt      - Change virtual terminal (requires root)
  • tty       - Print current terminal device name
  • history   - Display command history
  • fc        - Fix (edit) and re-execute commands
  • !         - History expansion operators
  • ctrl+r    - Reverse search through command history

Files You'll Interact With:
  • ~/.bash_history       - Stores command history for the user
  • ~/.bashrc             - User's bash configuration file
  • /dev/tty[1-6]         - Virtual terminal device files
  • $HISTSIZE             - Environment variable controlling history size
  • $HISTFILESIZE         - Controls history file size
  • $HISTTIMEFORMAT       - Adds timestamps to history
  • $HISTCONTROL          - Controls history behavior (duplication handling)
EOF
}

#############################################################################
# SCENARIO: The lab story and objectives (Standard Mode)
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your company's data center has experienced a network connectivity issue, and
the IPMI/remote management interface is temporarily unavailable. You need to
physically access the RHEL servers to troubleshoot. Multiple system administrators
need to work on the same server simultaneously, requiring effective use of
virtual terminals and command history management.

BACKGROUND:
RHEL 10 provides six virtual terminals (tty1-tty6) by default, allowing
multiple users to log in to the same system simultaneously without requiring
a graphical interface. You need to demonstrate proficiency with these virtual
terminals and efficient command history usage to minimize errors and maximize
productivity during the troubleshooting session.

OBJECTIVES:
  1. Identify your current terminal device:
     • Use the tty command to display current terminal
     • Understand the output format (/dev/tty# or /dev/pts/#)
     • Document the difference between physical and pseudo terminals
  
  2. Display currently logged in users and their terminal sessions:
     • Use the 'who' command to show all logged in users
     • Use the 'w' command for detailed session information
     • Identify which terminals are in use (tty1, tty2, pts/0, etc.)
  
  3. Configure bash history settings for user sysadmin1:
     • Set HISTSIZE to 2000 commands in memory
     • Set HISTFILESIZE to 5000 lines on disk
     • Enable timestamps in history with format "YYYY-MM-DD HH:MM:SS"
     • Configure HISTCONTROL to ignore duplicate consecutive commands
     • Add these settings to ~/.bashrc for persistence
  
  4. Practice command history navigation and re-execution:
     • View history with line numbers and timestamps
     • Use history expansion to re-execute commands by number
     • Use reverse search (Ctrl+R) to find previous commands
     • Execute the last command that started with specific letters
     • Clear history and demonstrate selective history deletion
  
  5. Create a command history audit trail:
     • Configure bash to log all commands with timestamps
     • Export history to file /opt/terminal_lab/sysadmin1_history.log
     • Ensure the log includes timestamp, command, and user information
     • Demonstrate that history persists across multiple sessions

HINTS:
  • Virtual terminal switching: Ctrl+Alt+F1 through F6 (may not work in VMs)
  • History expansion: !! (last command), !$ (last argument), !n (command #n)
  • Environment variables must be exported to affect the shell
  • History writes to file on shell exit (or with 'history -a')
  • HISTTIMEFORMAT must include at least one space to work properly

SUCCESS CRITERIA:
  • Can identify current terminal using tty command
  • Can view active user sessions with who/w commands
  • ~/.bashrc contains proper history configuration for sysadmin1
  • HISTSIZE=2000, HISTFILESIZE=5000 are set and exported
  • HISTTIMEFORMAT displays timestamps properly
  • History export file exists with proper format
  • Can demonstrate history navigation and re-execution techniques
EOF
}

#############################################################################
# QUICK OBJECTIVES: Condensed checklist
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Identify current terminal device with tty command
  ☐ 2. Display logged in users with who and w commands
  ☐ 3. Configure history: HISTSIZE=2000, HISTFILESIZE=5000, timestamps
  ☐ 4. Practice history navigation: !!, !$, !n, Ctrl+R, history search
  ☐ 5. Export history to /opt/terminal_lab/sysadmin1_history.log with timestamps
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
Your company's data center has experienced a network connectivity issue. You need
to physically access RHEL servers and demonstrate proficiency with virtual
terminals and command history management for efficient troubleshooting.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Identify your current terminal device

Before working with virtual terminals, you need to understand which terminal
device you're currently using. This is critical for troubleshooting session
issues and understanding the difference between physical and pseudo terminals.

Requirements:
  • Use the tty command to display current terminal
  • Understand the output format
  • Run 'who' to see your user and terminal in the user list

Terminal Types:
  • /dev/tty[1-6]: Physical virtual terminals (console)
  • /dev/pts/[0-N]: Pseudo-terminal slaves (SSH, terminal emulator)

Commands you might need:
  • tty                    - Print current terminal device name
  • who                    - Show who is logged in and their terminals
  • who am i               - Show current user's session only
  • echo $SSH_CONNECTION   - Check if you're in SSH session
EOF
}

validate_step_1() {
    # This validates understanding rather than system state
    # The terminal will be whatever the user is currently using
    print_color "$GREEN" "  ✓ To complete this step, run: tty"
    print_color "$YELLOW" "  Understanding: You should see either /dev/tty# or /dev/pts/#"
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  tty

Explanation:
  • tty: Prints the file name of the terminal connected to stdin
    - Stands for "TeleTYpewriter" (historical reference)
    - Reports the device file that represents your current terminal
    - Essential for identifying session type and troubleshooting

Output formats:
  1. /dev/tty1 through /dev/tty6:
     - Physical virtual consoles
     - Accessed directly at the server (not via network)
     - Switch between them with Ctrl+Alt+F1 through F6
     - Example: /dev/tty1 (first virtual terminal)
  
  2. /dev/pts/0, /dev/pts/1, etc.:
     - Pseudo-terminal slaves
     - Created for SSH sessions, terminal emulators, screen, tmux
     - Each connection gets a unique pts number
     - Example: /dev/pts/0 (first pseudo-terminal)
  
  3. "not a tty":
     - Stdin is not connected to a terminal
     - Common in scripts, cron jobs, or piped commands

Why this matters:
  Understanding your terminal type helps with:
  - Troubleshooting access issues
  - Understanding where commands are being executed
  - Debugging why certain terminal features don't work
  - Security auditing (tracking which terminals users are on)

Virtual Terminal Switching:
  On a physical server (not in SSH):
    Ctrl+Alt+F1  →  Switch to tty1
    Ctrl+Alt+F2  →  Switch to tty2
    ...
    Ctrl+Alt+F6  →  Switch to tty6
    Ctrl+Alt+F7  →  Usually returns to graphical environment (if running)
  
  From command line (requires root):
    chvt 1  →  Switch to tty1
    chvt 2  →  Switch to tty2

Verification:
  tty
  # Example outputs:
  # /dev/pts/0   (SSH or terminal emulator)
  # /dev/tty1    (Physical console)
  
  who
  # Shows all users and their terminals:
  # sysadmin1 pts/0   2025-12-23 10:30 (192.168.1.100)
  # sysadmin2 tty1    2025-12-23 10:25
  
  who am i
  # Shows only your current session:
  # sysadmin1 pts/0   2025-12-23 10:30 (192.168.1.100)

Related commands:
  ps -o tty,pid,cmd  # Shows processes and their controlling terminals
  w                  # Detailed info about logged-in users and their activity

EOF
}

hint_step_1() {
    echo "  Run 'tty' to see your current terminal device, then 'who' to see all sessions"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Display currently logged in users

System administrators need to know who else is working on a system to avoid
conflicts and coordinate work. Use commands to display detailed information
about all active user sessions.

Requirements:
  • Use 'who' to display basic login information
  • Use 'w' to display detailed session information
  • Understand the difference between these commands
  • Identify terminal types for each user (tty vs pts)

Commands you might need:
  • who          - Show who is logged in
  • who -H       - Show with column headers
  • who -a       - Show all login information
  • w            - Show who and what they're doing
  • users        - Simple list of usernames only
  • last         - Show history of logins
EOF
}

validate_step_2() {
    # Verify the commands exist and can be executed
    if command -v who >/dev/null 2>&1 && command -v w >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Commands 'who' and 'w' are available"
        print_color "$YELLOW" "  Run both commands to compare their output"
        return 0
    else
        print_color "$RED" "  ✗ Required commands not found"
        return 1
    fi
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  who
  who -H
  w

Explanation:
  • who: Displays basic login information for all users
    - Shows: username, terminal, login time, remote host (if applicable)
    - Lightweight and quick
    - Format: USER   TTY   DATE TIME   (HOST)
  
  • who -H: Same as 'who' but adds column headers
    - Makes output easier to read
    - Helps identify what each column represents
  
  • w: More detailed information about users and their activities
    - Shows: uptime, load average, user login time, idle time, processes
    - Displays what command each user is currently running
    - More comprehensive than 'who'

Output Comparison:

who output:
  sysadmin1 pts/0   2025-12-23 10:30 (192.168.1.100)
  sysadmin2 pts/1   2025-12-23 10:35 (192.168.1.105)
  root      tty1    2025-12-23 09:00

w output:
  10:45:32 up 2 days,  5:15,  3 users,  load average: 0.15, 0.10, 0.08
  USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
  sysadmin1 pts/0   192.168.1.100   10:30    1.00s  0.12s  0.01s w
  sysadmin2 pts/1   192.168.1.105   10:35    5:00   0.05s  0.02s vim /etc/hosts
  root      tty1    -                09:00   1:45m  0.23s  0.05s -bash

Column Explanations:
  • USER: Username of logged-in user
  • TTY: Terminal device (tty# for console, pts/# for SSH/pseudo-terminal)
  • FROM: Remote hostname or IP (blank for local logins)
  • LOGIN@: Time when user logged in
  • IDLE: Time since user last interacted with terminal
  • JCPU: Time used by all processes on this TTY
  • PCPU: Time used by current process (shown in WHAT column)
  • WHAT: Current command/process being executed

Why this matters:
  1. Coordination: Know who else is working to avoid conflicts
  2. Security: Detect unauthorized access or unusual sessions
  3. Troubleshooting: Identify if performance issues are user-caused
  4. Resource Management: See which users are consuming resources
  5. Maintenance Planning: Know when users are active before reboots

Practical examples:
  # Check if specific user is logged in
  who | grep sysadmin1
  
  # Count how many users are logged in
  who | wc -l
  
  # See only remote logins (via SSH)
  who | grep pts
  
  # See only console logins
  who | grep tty
  
  # Get detailed info with load averages
  w
  
  # Check last logins (historical)
  last
  
  # Check recent failed logins
  lastb

Verification:
  who -H
  # Shows all logged-in users with headers
  
  w
  # Shows detailed activity information
  
  users
  # Simple space-separated list of usernames

EOF
}

hint_step_2() {
    echo "  Run 'who' for basic info, then 'w' for detailed session information"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Configure bash history settings

Configure the bash history environment variables for user sysadmin1 to
enable better command history management. These settings will improve
productivity and provide an audit trail of commands.

Requirements:
  • Log in as sysadmin1 or switch to that user context
  • Edit ~/.bashrc to add history configuration
  • Set HISTSIZE=2000 (commands in memory)
  • Set HISTFILESIZE=5000 (lines in history file)
  • Set HISTTIMEFORMAT="%F %T " (timestamp format)
  • Set HISTCONTROL=ignoredups:erasedups (avoid duplicates)
  • Export all variables to make them effective
  • Source ~/.bashrc or login again to apply changes

Commands you might need:
  • su - sysadmin1            - Switch to sysadmin1
  • echo "export VAR=value" >> ~/.bashrc  - Add to bashrc
  • source ~/.bashrc          - Reload bashrc without logout
  • echo $HISTSIZE            - Verify variable is set
  • history 10                - Test by viewing recent commands
EOF
}

validate_step_3() {
    local bashrc_file="/home/sysadmin1/.bashrc"
    local all_good=true
    
    # Check if .bashrc exists
    if [ ! -f "$bashrc_file" ]; then
        print_color "$RED" "  ✗ ~/.bashrc not found for sysadmin1"
        return 1
    fi
    
    # Check for HISTSIZE
    if ! grep -q "HISTSIZE=2000" "$bashrc_file" 2>/dev/null; then
        print_color "$RED" "  ✗ HISTSIZE=2000 not found in ~/.bashrc"
        all_good=false
    fi
    
    # Check for HISTFILESIZE
    if ! grep -q "HISTFILESIZE=5000" "$bashrc_file" 2>/dev/null; then
        print_color "$RED" "  ✗ HISTFILESIZE=5000 not found in ~/.bashrc"
        all_good=false
    fi
    
    # Check for HISTTIMEFORMAT
    if ! grep -q "HISTTIMEFORMAT=" "$bashrc_file" 2>/dev/null; then
        print_color "$RED" "  ✗ HISTTIMEFORMAT not configured in ~/.bashrc"
        all_good=false
    fi
    
    # Check for HISTCONTROL
    if ! grep -q "HISTCONTROL=" "$bashrc_file" 2>/dev/null; then
        print_color "$RED" "  ✗ HISTCONTROL not configured in ~/.bashrc"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        print_color "$GREEN" "  ✓ All history settings configured in ~/.bashrc"
        return 0
    else
        print_color "$YELLOW" "  Add missing settings to /home/sysadmin1/.bashrc"
        return 1
    fi
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  # Switch to sysadmin1 user
  su - sysadmin1
  
  # Add history configuration to ~/.bashrc
  cat >> ~/.bashrc << 'EOF_BASHRC'

# Command History Configuration
export HISTSIZE=2000
export HISTFILESIZE=5000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups:erasedups

# Optional: Append to history immediately (don't wait for logout)
shopt -s histappend
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
EOF_BASHRC
  
  # Apply changes immediately
  source ~/.bashrc
  
  # Verify settings
  echo "HISTSIZE: $HISTSIZE"
  echo "HISTFILESIZE: $HISTFILESIZE"
  echo "HISTTIMEFORMAT: $HISTTIMEFORMAT"
  echo "HISTCONTROL: $HISTCONTROL"

Explanation:
  • HISTSIZE=2000: Controls how many commands bash keeps in memory
    - This is the working history during your current session
    - Larger values mean more commands accessible via history command
    - Default is typically 500-1000
  
  • HISTFILESIZE=5000: Controls size of ~/.bash_history file
    - This is persistent history stored on disk
    - When shell exits, it writes in-memory history to this file
    - Can be different from HISTSIZE (usually larger)
  
  • HISTTIMEFORMAT="%F %T ": Adds timestamps to history entries
    - %F: Date in YYYY-MM-DD format
    - %T: Time in HH:MM:SS format
    - Trailing space is REQUIRED for proper formatting
    - Makes history more useful for auditing and troubleshooting
  
  • HISTCONTROL=ignoredups:erasedups: Controls duplicate handling
    - ignoredups: Don't add command if it's same as previous
    - erasedups: Remove all previous occurrences of command
    - Can also use: ignorespace (don't save commands starting with space)
    - Can combine: ignoreboth (ignoredups:ignorespace)
  
  • shopt -s histappend: Append to history file (don't overwrite)
    - Prevents multiple shells from overwriting each other's history
    - Especially important when using multiple terminal sessions
  
  • PROMPT_COMMAND: Runs commands before each prompt is displayed
    - history -a: Append new history to file immediately
    - history -c: Clear in-memory history
    - history -r: Re-read history from file
    - This syncs history across multiple shell sessions in real-time

Why this matters:
  1. Productivity: Larger history means easier to find past commands
  2. Auditing: Timestamps provide accountability and troubleshooting info
  3. Efficiency: Duplicate removal keeps history clean and searchable
  4. Multi-session: Proper configuration prevents history loss with multiple shells
  5. Forensics: Timestamped history helps investigate security incidents

History File Location:
  The history file is stored at ~/.bash_history
  - Written when shell exits (or with history -a)
  - Read when shell starts (or with history -r)
  - Plain text file, can be viewed with cat or less
  - One command per line (timestamps stored differently)

Verification:
  # Check environment variables
  echo $HISTSIZE
  # Expected: 2000
  
  echo $HISTFILESIZE
  # Expected: 5000
  
  echo $HISTTIMEFORMAT
  # Expected: %F %T 
  
  # View history with timestamps
  history 10
  # Expected output:
  # 1985  2025-12-23 10:45:12 ls -la
  # 1986  2025-12-23 10:45:15 cd /opt
  # 1987  2025-12-23 10:45:18 pwd

Troubleshooting:
  If timestamps don't appear:
  - Ensure HISTTIMEFORMAT has trailing space
  - Source .bashrc or start new shell
  - Check export command was used
  
  If history seems short:
  - Check HISTSIZE value: echo $HISTSIZE
  - Verify .bashrc was sourced: source ~/.bashrc
  - Check ~/.bash_history file size: wc -l ~/.bash_history

EOF
}

hint_step_3() {
    echo "  Edit ~/.bashrc, add history exports, then 'source ~/.bashrc' to apply"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Practice command history navigation and re-execution

Demonstrate proficiency with bash history features to quickly re-execute
previous commands. This is a critical efficiency skill for system administrators.

Requirements:
  • Execute several test commands to populate history
  • View history with 'history' command
  • Re-execute command by history number: !n
  • Re-execute last command: !!
  • Use last argument from previous command: !$
  • Use reverse search: Ctrl+R
  • Clear specific history entries

Practice Commands to Execute:
  1. Run: ls -la /opt
  2. Run: cd /opt/terminal_lab
  3. Run: pwd
  4. Run: mkdir test_directory
  5. Run: touch test_file.txt
  6. Re-execute command #2 using !2
  7. Re-execute last command using !!
  8. Use Ctrl+R to search for 'mkdir'
  9. Delete a specific history entry

Commands you might need:
  • history          - View command history with numbers
  • !!               - Re-execute last command
  • !n               - Execute command number n from history
  • !string          - Execute most recent command starting with 'string'
  • !$               - Use last argument of previous command
  • ^old^new         - Replace 'old' with 'new' in last command
  • Ctrl+R           - Reverse search through history
  • history -d n     - Delete history entry number n
  • history -c       - Clear all history (be careful!)
EOF
}

validate_step_4() {
    # Check if sysadmin1 has bash history
    if [ -f "/home/sysadmin1/.bash_history" ]; then
        local hist_count=$(wc -l < /home/sysadmin1/.bash_history)
        if [ "$hist_count" -gt 5 ]; then
            print_color "$GREEN" "  ✓ Command history exists for sysadmin1"
            print_color "$YELLOW" "  Practice: Use 'history', '!!', '!n', Ctrl+R"
            return 0
        fi
    fi
    
    print_color "$YELLOW" "  Run several commands to build history, then practice navigation"
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command Sequence for Practice:

# 1. Execute test commands
ls -la /opt
cd /opt/terminal_lab
pwd
mkdir test_directory
touch test_file.txt

# 2. View history
history
# Shows numbered list with timestamps:
# 1001  2025-12-23 10:45:12 ls -la /opt
# 1002  2025-12-23 10:45:15 cd /opt/terminal_lab
# 1003  2025-12-23 10:45:18 pwd
# 1004  2025-12-23 10:45:20 mkdir test_directory
# 1005  2025-12-23 10:45:22 touch test_file.txt

# 3. Re-execute by number
!1001
# Executes: ls -la /opt

# 4. Re-execute last command
!!
# Executes the previous command again

# 5. Re-execute last command with specific start
!mk
# Executes most recent command starting with 'mk' (mkdir test_directory)

# 6. Use last argument from previous command
ls !$
# If previous command was 'cd /opt/terminal_lab'
# This becomes: ls /opt/terminal_lab

# 7. Replace text in last command
mkdir test_dir_old
^old^new
# Becomes: mkdir test_dir_new

# 8. Reverse search (Interactive)
Press Ctrl+R
Type: mkdir
# Searches backward through history for 'mkdir'
# Press Ctrl+R again to find previous occurrence
# Press Enter to execute
# Press Ctrl+G to cancel

Explanation:

History Expansion Operators:
  • !!: Re-executes the last command
    - Useful for running with sudo: sudo !!
    - Quick repetition of commands
  
  • !n: Executes command number n from history
    - Example: !1005 executes command #1005
    - Use 'history' to see command numbers
  
  • !-n: Executes command n positions back
    - Example: !-3 executes the command 3 steps back
    - Relative position instead of absolute number
  
  • !string: Executes most recent command starting with 'string'
    - Example: !mk executes last 'mkdir' command
    - Dangerous if multiple commands start with same letters
  
  • !?string?: Executes most recent command containing 'string'
    - Example: !?terminal? finds command containing 'terminal'
    - More flexible than !string
  
  • !$: Represents last argument of previous command
    - Example after 'ls /var/log': cd !$ → cd /var/log
    - Very useful for working with same file/directory
  
  • !*: All arguments from previous command
    - Example after 'cp file1 file2 /tmp': ls !* → ls file1 file2 /tmp
  
  • ^old^new: Quick substitution
    - Replaces first occurrence of 'old' with 'new' in last command
    - Example after 'cat fiel.txt': ^fiel^file → cat file.txt

Reverse Search (Ctrl+R):
  1. Press Ctrl+R to activate reverse search
  2. Start typing to search backward through history
  3. Press Ctrl+R again to cycle through matches
  4. Press Enter to execute the found command
  5. Press Right Arrow to edit before executing
  6. Press Ctrl+G or Ctrl+C to cancel search

History Management Commands:
  • history: Show all history with numbers
  • history n: Show last n commands
  • history -c: Clear all history (careful!)
  • history -d n: Delete entry number n
  • history -w: Write current history to file immediately
  • history -a: Append new entries to file
  • history -r: Read history file into current session

Why this matters:
  1. Speed: Re-executing complex commands without retyping
  2. Accuracy: Reduces typos by reusing verified commands
  3. Efficiency: Find and modify previous commands quickly
  4. Learning: Review what you've done for documentation
  5. Troubleshooting: Reconstruct sequence of actions

Advanced Techniques:

Working with arguments:
  # After: cp /etc/hosts /tmp/hosts.backup
  !^      # First argument: /etc/hosts
  !$      # Last argument: /tmp/hosts.backup
  !*      # All arguments: /etc/hosts /tmp/hosts.backup

Event designators:
  !-2     # Command 2 steps back
  !-5:p   # Preview command 5 steps back (don't execute)
  !!:p    # Preview last command

Word designators:
  !!:0    # Command name from last command
  !!:1    # First argument
  !!:2-4  # Arguments 2 through 4
  !!:*    # All arguments

Modifiers:
  !!:h    # Remove last pathname component (head)
  !!:t    # Keep only last pathname component (tail)
  !!:r    # Remove extension
  !!:e    # Keep only extension

Verification:
  # Execute test sequence
  ls /opt
  cd /opt/terminal_lab
  pwd
  
  # Test history expansion
  !!
  # Should re-execute 'pwd'
  
  echo !$
  # Should echo the last argument from pwd (current directory)
  
  history 5
  # Shows last 5 commands

Troubleshooting:
  If history expansion doesn't work:
  - Check if disabled: set +H (should be set -H for history expansion)
  - Enable it: set -H
  - Check .bashrc for 'set +H' that disables it

  If Ctrl+R doesn't work:
  - Verify you're in bash (not sh)
  - Check terminal emulator key bindings
  - Try in a fresh bash session

EOF
}

hint_step_4() {
    echo "  Run 'history', then try !n, !!, !$, and Ctrl+R for search"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Export history audit trail

Create a comprehensive history audit trail by exporting the command history
to a log file with proper formatting and timestamps. This is useful for
documentation, compliance, and troubleshooting.

Requirements:
  • Export history to /opt/terminal_lab/sysadmin1_history.log
  • Include timestamps in the export
  • Format should be: TIMESTAMP COMMAND
  • Ensure file is readable and properly formatted
  • File should be owned by sysadmin1

Commands you might need:
  • history > file.log        - Export history to file
  • history -w file.log       - Write history to specific file
  • HISTTIMEFORMAT="%F %T " history  - Show with timestamps
  • cat ~/.bash_history       - View raw history file
EOF
}

validate_step_5() {
    local log_file="/opt/terminal_lab/sysadmin1_history.log"
    
    if [ ! -f "$log_file" ]; then
        print_color "$RED" "  ✗ History log file not found at $log_file"
        echo "  Create: history > /opt/terminal_lab/sysadmin1_history.log"
        return 1
    fi
    
    local line_count=$(wc -l < "$log_file")
    if [ "$line_count" -lt 5 ]; then
        print_color "$RED" "  ✗ History log appears empty or incomplete"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ History log file exists with content"
    print_color "$YELLOW" "  Review: cat /opt/terminal_lab/sysadmin1_history.log"
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  # As user sysadmin1
  su - sysadmin1
  
  # Export history with timestamps
  history > /opt/terminal_lab/sysadmin1_history.log
  
  # Or alternatively, using full path to history file
  cat ~/.bash_history > /opt/terminal_lab/sysadmin1_history.log
  
  # Verify the export
  cat /opt/terminal_lab/sysadmin1_history.log

Explanation:
  • history > file: Redirects history output to a file
    - Includes timestamps if HISTTIMEFORMAT is set
    - Includes line numbers
    - This is the formatted history (what you see in terminal)
  
  • cat ~/.bash_history: Raw history file contents
    - May not have timestamps (depends on bash version)
    - No line numbers
    - This is the actual stored history

Format of exported history:
  1001  2025-12-23 10:45:12 ls -la /opt
  1002  2025-12-23 10:45:15 cd /opt/terminal_lab
  1003  2025-12-23 10:45:18 pwd
  1004  2025-12-23 10:45:20 mkdir test_directory
  1005  2025-12-23 10:45:22 touch test_file.txt

Why this matters:
  1. Compliance: Many regulations require audit trails of admin actions
  2. Documentation: Record of what was done for training or handoff
  3. Troubleshooting: Reconstruct sequence of events
  4. Security: Detect unauthorized or suspicious activity
  5. Change Management: Track system modifications

Advanced History Auditing:

Real-time logging (add to .bashrc):
  # Log every command immediately
  PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug "$(whoami) [$$]: $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//" )"'

This sends every command to syslog in real-time:
  - whoami: Current username
  - $$: Process ID
  - history 1: Last command
  - logger: Sends to syslog

Centralized logging:
  Configure rsyslog to forward to central log server
  /etc/rsyslog.conf:
    local6.*  @192.168.1.10:514

Enhanced audit script:
  Create /usr/local/bin/audit-history.sh:
    #!/bin/bash
    echo "History Audit: $(date)"
    echo "User: $(whoami)"
    echo "Hostname: $(hostname)"
    echo "Terminal: $(tty)"
    echo "------------------------"
    history
  
  Add to cron: 0 * * * * /usr/local/bin/audit-history.sh >> /var/log/command-audit.log

Verification:
  cat /opt/terminal_lab/sysadmin1_history.log
  # Should show commands with timestamps and line numbers
  
  wc -l /opt/terminal_lab/sysadmin1_history.log
  # Should show count of commands logged
  
  tail -20 /opt/terminal_lab/sysadmin1_history.log
  # Shows most recent 20 commands

Best Practices:
  1. Regular exports: Set up cron job for periodic history backups
  2. Retention: Keep history files for compliance period
  3. Protection: Set immutable flag on critical logs: chattr +a logfile
  4. Centralization: Send to syslog server for tamper-proof storage
  5. Review: Regularly audit history for security and learning

EOF
}

hint_step_5() {
    echo "  Use 'history > /opt/terminal_lab/sysadmin1_history.log' to export"
}

#############################################################################
# VALIDATION: Check the final state (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: Terminal identification
    print_color "$CYAN" "[1/$total] Checking terminal identification understanding..."
    if command -v tty >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ tty command available"
        print_color "$YELLOW" "  Practice: Run 'tty' to see your terminal device"
        ((score++))
    else
        print_color "$RED" "  ✗ tty command not found"
    fi
    echo ""
    
    # CHECK 2: User session commands
    print_color "$CYAN" "[2/$total] Checking user session commands..."
    if command -v who >/dev/null 2>&1 && command -v w >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Commands 'who' and 'w' available"
        print_color "$YELLOW" "  Practice: Run 'who' and 'w' to compare output"
        ((score++))
    else
        print_color "$RED" "  ✗ User session commands not available"
    fi
    echo ""
    
    # CHECK 3: History configuration
    print_color "$CYAN" "[3/$total] Checking bash history configuration..."
    local bashrc_file="/home/sysadmin1/.bashrc"
    if [ -f "$bashrc_file" ]; then
        local config_count=0
        grep -q "HISTSIZE=2000" "$bashrc_file" && ((config_count++))
        grep -q "HISTFILESIZE=5000" "$bashrc_file" && ((config_count++))
        grep -q "HISTTIMEFORMAT=" "$bashrc_file" && ((config_count++))
        grep -q "HISTCONTROL=" "$bashrc_file" && ((config_count++))
        
        if [ $config_count -eq 4 ]; then
            print_color "$GREEN" "  ✓ All history settings configured in ~/.bashrc"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ Only $config_count/4 history settings found"
            print_color "$YELLOW" "  Required: HISTSIZE=2000, HISTFILESIZE=5000, HISTTIMEFORMAT, HISTCONTROL"
        fi
    else
        print_color "$RED" "  ✗ .bashrc not found for sysadmin1"
    fi
    echo ""
    
    # CHECK 4: Command history exists
    print_color "$CYAN" "[4/$total] Checking command history..."
    if [ -f "/home/sysadmin1/.bash_history" ]; then
        local hist_count=$(wc -l < /home/sysadmin1/.bash_history)
        print_color "$GREEN" "  ✓ Command history exists ($hist_count commands)"
        print_color "$YELLOW" "  Practice navigation: 'history', '!!', '!n', Ctrl+R"
        ((score++))
    else
        print_color "$YELLOW" "  ⚠ No command history found yet"
        print_color "$YELLOW" "  Run several commands as sysadmin1 to build history"
    fi
    echo ""
    
    # CHECK 5: History export file
    print_color "$CYAN" "[5/$total] Checking history audit trail..."
    local log_file="/opt/terminal_lab/sysadmin1_history.log"
    if [ -f "$log_file" ] && [ $(wc -l < "$log_file") -gt 5 ]; then
        print_color "$GREEN" "  ✓ History audit trail exported"
        print_color "$YELLOW" "  Review: cat $log_file"
        ((score++))
    else
        print_color "$RED" "  ✗ History export not found or incomplete"
        print_color "$YELLOW" "  Fix: history > $log_file"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've mastered:"
        echo "  • Terminal device identification"
        echo "  • User session management"
        echo "  • Bash history configuration"
        echo "  • History navigation techniques"
        echo "  • Audit trail creation"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
        echo "Run with --solution to see detailed steps."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION: Complete walkthrough (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Solutions for all 5 steps are included above in solution_step_1() through
solution_step_5() functions. This comprehensive solution section synthesizes
key concepts across all steps.]

CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Virtual Terminals vs Pseudo-Terminals:
  Virtual Terminals (tty1-tty6):
  - Physical console access
  - Exist even without network
  - Accessed via Ctrl+Alt+F1 through F6
  - Critical for troubleshooting network issues
  - Each is a full login session
  
  Pseudo-Terminals (pts/0, pts/1, etc.):
  - Created for SSH sessions, terminal emulators
  - Require network or graphics
  - Dynamic allocation as connections are made
  - Each connection gets unique number
  - More flexible but network-dependent

Bash History Mechanics:
  1. Commands stored in memory during session (HISTSIZE)
  2. Written to ~/.bash_history on shell exit
  3. Read from ~/.bash_history on shell start
  4. Size controlled by HISTFILESIZE
  5. Behavior modified by HISTCONTROL and other variables

History File Management:
  - Default location: ~/.bash_history
  - Plain text file, one command per line
  - Timestamps stored in special format (#1234567890)
  - Can be manually edited (though not recommended)
  - Multiple shells can cause race conditions

Best Practices for System Administrators:
  1. Always set HISTSIZE and HISTFILESIZE large enough
  2. Enable timestamps for audit trails
  3. Use ignoredups to keep history clean
  4. Set up histappend to prevent overwriting
  5. Consider real-time logging for critical systems


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Not exporting history variables
  Result: Variables set but not effective in shell
  Fix: Always use 'export' keyword:
       export HISTSIZE=2000
       Not just: HISTSIZE=2000

Mistake 2: Forgetting trailing space in HISTTIMEFORMAT
  Result: Timestamps run together with commands
  Fix: HISTTIMEFORMAT="%F %T " (note the space at end)

Mistake 3: Not sourcing .bashrc after changes
  Result: Changes don't take effect until next login
  Fix: source ~/.bashrc or logout and login again

Mistake 4: Using history expansion in scripts
  Result: Unexpected behavior or errors
  Fix: History expansion works in interactive shells only
       Scripts should use explicit commands

Mistake 5: Clearing history accidentally
  Result: Lose valuable command history
  Fix: Use history -d n for specific entries
       Avoid history -c unless intentional

Mistake 6: Not testing history expansion before executing
  Result: Execute wrong command
  Fix: Use :p modifier to preview:
       !123:p (preview command 123 without executing)


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Virtual terminal knowledge for exam:
   - Know that tty1-tty6 exist by default
   - Understand switching methods (Ctrl+Alt+Fn)
   - Be able to identify current terminal with tty
   - Know difference between console and SSH terminals

2. Essential history commands to memorize:
   - history: View all history
   - !!: Re-execute last command
   - !n: Execute command number n
   - !$: Last argument of previous command
   - Ctrl+R: Reverse search (most useful!)

3. Must-know history variables:
   - HISTSIZE: In-memory history size
   - HISTFILESIZE: On-disk history size
   - HISTTIMEFORMAT: Enable timestamps
   - HISTCONTROL: Duplicate handling

4. Persistence is key:
   - Always add settings to ~/.bashrc
   - Use 'export' for variables
   - Test persistence by opening new shell
   - Verify with: echo $VARIABLENAME

5. Time-savers for exam:
   - Use Ctrl+R to find previous commands quickly
   - Use !! sudo !! pattern for forgotten sudo
   - Use !$ to avoid retyping long paths
   - Practice history navigation before exam

6. User management awareness:
   - Know how to check who's logged in (who, w)
   - Understand implications of multiple admins
   - Be able to identify terminal types
   - Know how to view last login times (last command)

EOF
}

#############################################################################
# CLEANUP: Remove lab components
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r sysadmin1 2>/dev/null || true
    userdel -r sysadmin2 2>/dev/null || true
    rm -rf /opt/terminal_lab 2>/dev/null || true
    
    echo "  ✓ Lab users removed"
    echo "  ✓ Lab directories removed"
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
