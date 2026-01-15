#!/bin/bash
# labs/03A-bash-shell-basics.sh
# Lab: Basic Command Line Navigation and Bash Features
# Difficulty: Beginner
# RHCSA Objective: Understand and use essential tools for handling files, directories, command-line environments, and documentation

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Basic Command Line Navigation and Bash Features"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="15-20 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Remove test user and directories from previous attempts
    userdel -r labuser 2>/dev/null || true
    rm -rf /opt/labwork 2>/dev/null || true
    rm -rf /var/log/labtest 2>/dev/null || true
    
    # Create test user for the lab
    useradd -m -s /bin/bash labuser 2>/dev/null || true
    echo "labuser:password123" | chpasswd 2>/dev/null || true
    
    # Create directory structure for the lab
    mkdir -p /opt/labwork/{docs,scripts,config} 2>/dev/null || true
    mkdir -p /var/log/labtest 2>/dev/null || true
    
    # Create sample files for exploration
    echo "System configuration file" > /opt/labwork/config/system.conf
    echo "Application settings" > /opt/labwork/config/app.conf
    echo "#!/bin/bash" > /opt/labwork/scripts/backup.sh
    echo "echo 'Running backup...'" >> /opt/labwork/scripts/backup.sh
    echo "Technical Documentation" > /opt/labwork/docs/readme.txt
    echo "Installation Guide" > /opt/labwork/docs/install.txt
    
    # Set proper ownership
    chown -R labuser:labuser /opt/labwork 2>/dev/null || true
    
    echo "  ✓ Test user 'labuser' created"
    echo "  ✓ Directory structure created at /opt/labwork"
    echo "  ✓ Sample files generated"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES: Knowledge and commands needed
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of Linux directory structure
  • Basic concept of command syntax (command + options + arguments)
  • Familiarity with file permissions concepts
  • Understanding of absolute vs relative paths

Commands You'll Use:
  • ls       - List directory contents with various options
  • cd       - Change the current working directory
  • pwd      - Print the current working directory path
  • mkdir    - Create new directories
  • touch    - Create empty files or update timestamps
  • cat      - Display file contents to stdout
  • less     - Paginate file contents for easier reading
  • history  - View previously executed commands
  • man      - Access manual pages for commands
  • type     - Display information about command type

Files You'll Interact With:
  • ~/.bashrc             - User-specific bash configuration
  • ~/.bash_history       - Command history for the user
  • /opt/labwork/*        - Test directory structure
  • /var/log/labtest/     - Log directory for practice
EOF
}

#############################################################################
# SCENARIO: The lab story and objectives (Standard Mode)
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You've just been hired as a junior system administrator at a manufacturing
company. Your manager wants to assess your basic Linux command-line skills
before granting you access to production systems. You need to demonstrate
proficiency with fundamental bash operations and file navigation.

BACKGROUND:
The company uses Red Hat Enterprise Linux 10 across its infrastructure. All
administrators must be comfortable with command-line operations, as many
systems are managed remotely without GUI access. Your test environment has
been prepared with sample directories and files that simulate real system
layouts.

OBJECTIVES:
  1. Navigate to /opt/labwork and create a new directory called "reports"
     • Directory must be owned by labuser
     • Must be created within /opt/labwork
  
  2. Create three empty files in /opt/labwork/reports:
     • monthly_report.txt
     • weekly_summary.log
     • system_status.dat
     • All files must be owned by labuser
  
  3. Use command-line listing to display detailed information about all files
     in /opt/labwork/config (long format with human-readable sizes)
     • Output should show permissions, ownership, size, and timestamps
     • Must use a single command with appropriate options
  
  4. Find the complete path to the bash executable on the system
     • Use the 'type' command to identify bash's location
     • Verify it's located in /usr/bin/bash
  
  5. View the contents of /opt/labwork/docs/readme.txt using a pager
     • Must use the 'less' command for viewing
     • Practice navigation: space, arrows, 'q' to quit

HINTS:
  • Use 'cd' with absolute paths for navigation
  • The -l flag for ls provides long format listing
  • The -h flag for ls shows human-readable file sizes
  • Command completion with TAB can speed up your work
  • Use 'pwd' frequently to confirm your current location

SUCCESS CRITERIA:
  • /opt/labwork/reports directory exists and is owned by labuser
  • Three required files exist in reports directory
  • You can demonstrate proper use of ls with -l and -h flags
  • You can identify the bash executable location
  • You understand how to use basic navigation commands
EOF
}

#############################################################################
# QUICK OBJECTIVES: Condensed checklist
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Navigate to /opt/labwork and create "reports" directory
  ☐ 2. Create three files: monthly_report.txt, weekly_summary.log, system_status.dat
  ☐ 3. List /opt/labwork/config contents with detailed info (ls -lh)
  ☐ 4. Find bash executable location using 'type' command
  ☐ 5. View readme.txt using 'less' pager
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
You've just been hired as a junior system administrator at a manufacturing
company. Your manager wants to assess your basic Linux command-line skills
before granting you access to production systems. You need to demonstrate
proficiency with fundamental bash operations and file navigation.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Create the reports directory

As part of your assessment, you need to create a new directory called
"reports" within the /opt/labwork directory structure. This will be used
to store various system and operational reports.

Requirements:
  • Directory name must be exactly "reports" (lowercase)
  • Must be created at path: /opt/labwork/reports
  • Must be owned by user labuser
  • You should navigate to /opt/labwork before creating it

Commands you might need:
  • cd /opt/labwork  - Change to the target directory
  • pwd              - Verify your current location
  • mkdir reports    - Create the directory
  • ls -ld reports   - Verify the directory was created
EOF
}

validate_step_1() {
    if [ ! -d "/opt/labwork/reports" ]; then
        echo ""
        print_color "$RED" "✗ Directory /opt/labwork/reports does not exist"
        echo "  Try: cd /opt/labwork && mkdir reports"
        return 1
    fi
    
    local owner=$(stat -c '%U' /opt/labwork/reports 2>/dev/null)
    if [ "$owner" != "labuser" ]; then
        print_color "$RED" "✗ Directory is owned by $owner, not labuser"
        echo "  Fix: chown labuser:labuser /opt/labwork/reports"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cd /opt/labwork
  mkdir reports

Explanation:
  • cd /opt/labwork: Changes your current working directory to /opt/labwork
    - This uses an absolute path (starts with /) to navigate directly
    - The cd command modifies the shell's current directory context
  
  • mkdir reports: Creates a new directory named "reports"
    - Because we're already in /opt/labwork, this creates /opt/labwork/reports
    - This is a relative path (doesn't start with /)
    - The directory inherits ownership from the current user (labuser)

Why this matters:
  Understanding the difference between absolute and relative paths is crucial
  for system administration. Absolute paths (/opt/labwork) always start from
  root (/), while relative paths (reports) are relative to your current
  location. This becomes important when writing scripts or working across
  different directory contexts.

Verification:
  pwd
  # Expected output: /opt/labwork
  
  ls -ld reports
  # Expected output: drwxr-xr-x. 2 labuser labuser ... reports

EOF
}

hint_step_1() {
    echo "  Use 'cd' to navigate first, then 'mkdir' to create the directory"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create three report files

You need to create three empty files within the newly created reports
directory. These files will serve as templates for different types of
reports that administrators will generate.

Requirements:
  • Navigate to /opt/labwork/reports
  • Create file: monthly_report.txt
  • Create file: weekly_summary.log
  • Create file: system_status.dat
  • All files must be owned by labuser
  • Files can be empty (0 bytes)

Commands you might need:
  • cd reports       - Navigate into the reports directory
  • touch filename   - Create an empty file
  • ls -l            - List files to verify creation
EOF
}

validate_step_2() {
    local files=("monthly_report.txt" "weekly_summary.log" "system_status.dat")
    local all_exist=true
    
    for file in "${files[@]}"; do
        if [ ! -f "/opt/labwork/reports/$file" ]; then
            print_color "$RED" "✗ File $file does not exist in /opt/labwork/reports"
            echo "  Try: touch /opt/labwork/reports/$file"
            all_exist=false
        fi
    done
    
    [ "$all_exist" = true ] && return 0 || return 1
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cd /opt/labwork/reports
  touch monthly_report.txt weekly_summary.log system_status.dat

Explanation:
  • cd /opt/labwork/reports: Navigates into the reports directory
    - This assumes you're starting from /opt/labwork
    - Could also use absolute path: cd /opt/labwork/reports
  
  • touch [files]: Creates multiple empty files in one command
    - touch is primarily used to update file timestamps
    - If files don't exist, touch creates them with 0 bytes
    - Multiple filenames can be specified separated by spaces
    - Files inherit ownership from the user executing the command

Alternative approaches:
  You could create files one at a time:
    touch monthly_report.txt
    touch weekly_summary.log
    touch system_status.dat
  
  Or use absolute paths from any directory:
    touch /opt/labwork/reports/monthly_report.txt
    touch /opt/labwork/reports/weekly_summary.log
    touch /opt/labwork/reports/system_status.dat

Why this matters:
  The touch command is frequently used in system administration for creating
  placeholder files, updating timestamps (for triggering automations), or
  ensuring files exist before scripts attempt to write to them. Understanding
  both relative and absolute path usage gives you flexibility in scripts.

Verification:
  ls -l /opt/labwork/reports
  # Expected output: Shows three files with 0 byte sizes
  # -rw-r--r--. 1 labuser labuser 0 Dec 23 ... monthly_report.txt
  # -rw-r--r--. 1 labuser labuser 0 Dec 23 ... system_status.dat
  # -rw-r--r--. 1 labuser labuser 0 Dec 23 ... weekly_summary.log

EOF
}

hint_step_2() {
    echo "  Use 'touch' command to create empty files - you can specify multiple files"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Display detailed file listing

Demonstrate your ability to use ls command options to display detailed
information about files in the /opt/labwork/config directory. This is
a critical skill for system administration as you need to verify file
permissions, ownership, and sizes.

Requirements:
  • Use ls command with appropriate options
  • Display long format (permissions, owner, size, timestamp, name)
  • Show human-readable file sizes (KB, MB instead of bytes)
  • Target directory: /opt/labwork/config

Commands you might need:
  • ls -l  /path     - Long format listing
  • ls -h  /path     - Human-readable sizes
  • ls -lh /path     - Combined: long format with human-readable sizes
  • man ls           - View manual page for all ls options
EOF
}

validate_step_3() {
    # This step is validation of understanding rather than system state
    # Check that config directory exists and has files
    if [ ! -d "/opt/labwork/config" ]; then
        print_color "$RED" "✗ Directory /opt/labwork/config does not exist"
        return 1
    fi
    
    local file_count=$(ls -1 /opt/labwork/config 2>/dev/null | wc -l)
    if [ "$file_count" -lt 2 ]; then
        print_color "$RED" "✗ Expected files not found in /opt/labwork/config"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Config directory exists with files"
    print_color "$YELLOW" "  Note: Run 'ls -lh /opt/labwork/config' to verify your output"
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  ls -lh /opt/labwork/config

Explanation:
  • ls: The list command displays directory contents
  • -l: Long format flag shows detailed file information:
       - File permissions (rwxr-xr-x)
       - Number of hard links
       - Owner name
       - Group name
       - File size
       - Modification timestamp
       - File name
  
  • -h: Human-readable flag converts bytes to KB, MB, GB
       - Makes file sizes easier to interpret at a glance
       - Without -h, sizes show in bytes (e.g., 1524 vs 1.5K)
  
  • /opt/labwork/config: Target directory (absolute path)
       - Can be used from any current working directory
       - Shows contents of config directory

Why this matters:
  The ls command with -lh flags is one of the most commonly used combinations
  in Linux administration. The long format provides critical information for
  troubleshooting permission issues, identifying file owners, and checking
  file sizes before operations. The -h flag makes output more readable,
  especially when dealing with logs or large files.

Common flag combinations:
  • ls -la   : Shows hidden files (those starting with .)
  • ls -lt   : Sorts by modification time (newest first)
  • ls -ltr  : Sorts by time, reversed (oldest first)
  • ls -lhS  : Sorts by file size, largest first
  • ls -ld   : Shows directory info instead of contents

Verification:
  ls -lh /opt/labwork/config
  # Expected output format:
  # total 8.0K
  # -rw-r--r--. 1 labuser labuser 21 Dec 23 10:30 app.conf
  # -rw-r--r--. 1 labuser labuser 27 Dec 23 10:30 system.conf

EOF
}

hint_step_3() {
    echo "  Combine -l and -h flags: ls -lh /path/to/directory"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Locate the bash executable

Use the 'type' command to identify where the bash shell executable is
located on your RHEL system. This demonstrates understanding of command
types and how the shell locates executables.

Requirements:
  • Use the 'type' command to find bash
  • Verify bash is located at /usr/bin/bash
  • Understand the difference between builtin commands and executables

Commands you might need:
  • type bash        - Show information about bash
  • type cd          - Compare with a builtin command
  • which bash       - Alternative way to find executables
  • whereis bash     - Show all locations related to bash
EOF
}

validate_step_4() {
    # Check if bash exists at expected location
    if [ ! -f "/usr/bin/bash" ]; then
        print_color "$RED" "✗ Bash not found at /usr/bin/bash"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Bash executable verified at /usr/bin/bash"
    print_color "$YELLOW" "  Run 'type bash' to see the full output"
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  type bash

Explanation:
  • type: A bash builtin command that displays information about commands
    - Shows whether a command is a builtin, function, alias, or external executable
    - For executables, displays the full path
    - More comprehensive than 'which' for understanding command types
  
  • bash: The command name we're looking up
    - This is the Bourne Again Shell executable
    - Default shell for most Linux distributions including RHEL

Expected Output:
  bash is /usr/bin/bash

Why this matters:
  Understanding where commands are located is crucial for several reasons:
  1. Troubleshooting: When commands don't work, verifying their location helps
  2. Scripting: Shebang lines (#!/usr/bin/bash) require exact paths
  3. Security: Knowing the difference between builtin and external commands
  4. PATH management: Understanding how the shell finds executables

Command types in Linux:
  1. Builtin commands: Part of the shell itself (cd, echo, type)
     - Executed directly by the shell
     - No separate executable file
     - Generally faster than external commands
  
  2. External executables: Separate binary files (ls, cat, grep)
     - Located in directories like /usr/bin, /bin, /usr/sbin
     - Shell searches PATH variable to find them
     - Spawns new process to execute
  
  3. Functions: User-defined shell functions
  
  4. Aliases: Shortcuts for commands (often defined in .bashrc)

Verification:
  type cd
  # Output: cd is a shell builtin
  
  type ls
  # Output: ls is aliased to `ls --color=auto'
  # Or: ls is /usr/bin/ls
  
  type -a bash
  # Shows all occurrences of bash in PATH

Related commands:
  which bash    # Shows path to executable (simpler than type)
  whereis bash  # Shows binary, source, and manual page locations

EOF
}

hint_step_4() {
    echo "  Use 'type bash' to display information about the bash command"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Use a pager to view file contents

Demonstrate the use of 'less' pager to view the contents of the readme.txt
file. Pagers are essential for reading long files without overwhelming the
terminal screen.

Requirements:
  • Use 'less' command to view /opt/labwork/docs/readme.txt
  • Practice navigation within less:
    - Space bar to move forward one page
    - 'b' to move backward one page
    - Up/down arrows for line-by-line navigation
    - 'q' to quit less and return to shell
    - '/' to search for text
    - 'h' for help within less

Commands you might need:
  • less filename    - Open file in pager
  • cat filename     - Display entire file (compare with less)
  • more filename    - Older pager (less is more capable)
EOF
}

validate_step_5() {
    # Check if readme.txt exists
    if [ ! -f "/opt/labwork/docs/readme.txt" ]; then
        print_color "$RED" "✗ File /opt/labwork/docs/readme.txt does not exist"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ readme.txt file exists"
    print_color "$YELLOW" "  Practice: less /opt/labwork/docs/readme.txt"
    print_color "$YELLOW" "  Remember: 'q' to quit, Space to scroll, '/' to search"
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  less /opt/labwork/docs/readme.txt

Explanation:
  • less: An interactive file pager for viewing text
    - Allows forward and backward navigation
    - Doesn't load entire file into memory (efficient for large files)
    - Provides search capabilities
    - Name comes from "less is more" (improvement over 'more' command)
  
  • /opt/labwork/docs/readme.txt: Absolute path to the file
    - Can be used from any current directory

Key navigation commands within less:
  ┌─────────────┬──────────────────────────────────────┐
  │ Key         │ Action                               │
  ├─────────────┼──────────────────────────────────────┤
  │ Space       │ Forward one page                     │
  │ b           │ Backward one page                    │
  │ d           │ Forward half page                    │
  │ u           │ Backward half page                   │
  │ Down arrow  │ Forward one line                     │
  │ Up arrow    │ Backward one line                    │
  │ /pattern    │ Search forward for pattern           │
  │ ?pattern    │ Search backward for pattern          │
  │ n           │ Repeat last search (next occurrence) │
  │ N           │ Repeat last search (previous)        │
  │ g           │ Go to beginning of file              │
  │ G           │ Go to end of file                    │
  │ h           │ Display help screen                  │
  │ q           │ Quit less and return to shell        │
  └─────────────┴──────────────────────────────────────┘

Why this matters:
  System administrators frequently need to examine log files, configuration
  files, and other text files that are too large to comfortably view with
  cat. The less pager allows efficient navigation through files, searching
  for specific content, and viewing only what you need without flooding the
  terminal with output.

Common use cases:
  1. Examining log files: less /var/log/messages
  2. Reading documentation: less /usr/share/doc/package/README
  3. Piping command output: command --help | less
  4. Viewing multiple files: less file1.txt file2.txt (use :n, :p to switch)

Comparison with other commands:
  • cat: Dumps entire file to stdout (good for short files, scripts)
  • more: Older pager, forward-only navigation (less capable than less)
  • less: Modern pager, bidirectional, search, doesn't exit on EOF
  • head: Shows first N lines only
  • tail: Shows last N lines (useful for logs with -f flag)

Practical example:
  # View a long help message
  ls --help | less
  
  # Search within a file
  less /var/log/messages
  # Then type: /error (searches for "error")
  # Press 'n' to find next occurrence

EOF
}

hint_step_5() {
    echo "  Use 'less /opt/labwork/docs/readme.txt' then 'q' to quit when done"
}

#############################################################################
# VALIDATION: Check the final state (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: Reports directory
    print_color "$CYAN" "[1/$total] Checking reports directory..."
    if [ -d "/opt/labwork/reports" ] && [ "$(stat -c '%U' /opt/labwork/reports)" = "labuser" ]; then
        print_color "$GREEN" "  ✓ Directory /opt/labwork/reports exists and is owned by labuser"
        ((score++))
    else
        print_color "$RED" "  ✗ Reports directory missing or incorrect ownership"
        print_color "$YELLOW" "  Fix: mkdir /opt/labwork/reports"
    fi
    echo ""
    
    # CHECK 2: Three report files
    print_color "$CYAN" "[2/$total] Checking report files..."
    local files=("monthly_report.txt" "weekly_summary.log" "system_status.dat")
    local files_exist=true
    for file in "${files[@]}"; do
        if [ ! -f "/opt/labwork/reports/$file" ]; then
            files_exist=false
            break
        fi
    done
    
    if [ "$files_exist" = true ]; then
        print_color "$GREEN" "  ✓ All three report files exist"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing one or more report files"
        print_color "$YELLOW" "  Fix: touch /opt/labwork/reports/{monthly_report.txt,weekly_summary.log,system_status.dat}"
    fi
    echo ""
    
    # CHECK 3: Config directory and files
    print_color "$CYAN" "[3/$total] Checking config directory structure..."
    if [ -d "/opt/labwork/config" ] && [ $(ls -1 /opt/labwork/config 2>/dev/null | wc -l) -ge 2 ]; then
        print_color "$GREEN" "  ✓ Config directory exists with files"
        print_color "$YELLOW" "  Verify: ls -lh /opt/labwork/config"
        ((score++))
    else
        print_color "$RED" "  ✗ Config directory structure issue"
    fi
    echo ""
    
    # CHECK 4: Bash executable location
    print_color "$CYAN" "[4/$total] Checking bash executable..."
    if [ -f "/usr/bin/bash" ]; then
        print_color "$GREEN" "  ✓ Bash found at /usr/bin/bash"
        print_color "$YELLOW" "  Run: type bash"
        ((score++))
    else
        print_color "$RED" "  ✗ Bash not found at expected location"
    fi
    echo ""
    
    # CHECK 5: Docs directory and readme file
    print_color "$CYAN" "[5/$total] Checking documentation files..."
    if [ -f "/opt/labwork/docs/readme.txt" ]; then
        print_color "$GREEN" "  ✓ readme.txt exists for viewing"
        print_color "$YELLOW" "  Practice: less /opt/labwork/docs/readme.txt"
        ((score++))
    else
        print_color "$RED" "  ✗ readme.txt not found"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've demonstrated solid understanding of:"
        echo "  • Directory and file creation"
        echo "  • Command-line navigation"
        echo "  • Using ls with options"
        echo "  • Identifying command locations"
        echo "  • Using pagers for file viewing"
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

STEP 1: Create the reports directory
─────────────────────────────────────────────────────────────────
Commands:
  cd /opt/labwork
  mkdir reports

Explanation:
  • cd /opt/labwork: Changes working directory using absolute path
  • mkdir reports: Creates directory using relative path

Why this works:
  The mkdir command creates a directory in the current location. Since we
  used cd first, our current directory is /opt/labwork, so the relative
  path "reports" creates /opt/labwork/reports. Alternatively, we could
  have used the absolute path: mkdir /opt/labwork/reports

Verification:
  pwd
  # Expected: /opt/labwork
  
  ls -ld reports
  # Expected: drwxr-xr-x. 2 labuser labuser ... reports


STEP 2: Create three report files
─────────────────────────────────────────────────────────────────
Command:
  cd reports
  touch monthly_report.txt weekly_summary.log system_status.dat

Explanation:
  • cd reports: Navigates into the newly created directory
  • touch [files]: Creates all three files in a single command
    - Space-separated list of filenames
    - Files are created with 0 bytes
    - Inherits labuser ownership

Why this works:
  The touch command's primary purpose is updating file timestamps, but it
  has the useful side effect of creating files if they don't exist. This
  makes it perfect for creating empty placeholder files.

Verification:
  ls -l
  # Shows three files with 0 bytes:
  # -rw-r--r--. 1 labuser labuser 0 Dec 23 ... monthly_report.txt
  # -rw-r--r--. 1 labuser labuser 0 Dec 23 ... system_status.dat
  # -rw-r--r--. 1 labuser labuser 0 Dec 23 ... weekly_summary.log


STEP 3: Display detailed file listing
─────────────────────────────────────────────────────────────────
Command:
  ls -lh /opt/labwork/config

Explanation:
  • ls: List directory contents
  • -l: Long format showing permissions, owner, group, size, timestamp, name
  • -h: Human-readable sizes (1.5K instead of 1524 bytes)
  • /opt/labwork/config: Absolute path to target directory

Why this works:
  The combination of -l and -h provides comprehensive file information in
  a readable format. This is essential for system administration tasks like
  checking permissions, identifying large files, or verifying ownership.

Verification:
  # Output shows detailed information:
  total 8.0K
  -rw-r--r--. 1 labuser labuser 21 Dec 23 10:30 app.conf
  -rw-r--r--. 1 labuser labuser 27 Dec 23 10:30 system.conf


STEP 4: Locate bash executable
─────────────────────────────────────────────────────────────────
Command:
  type bash

Explanation:
  • type: Bash builtin that displays command information
  • bash: The command to look up

Expected Output:
  bash is /usr/bin/bash

Why this works:
  The type command is more informative than which or whereis because it
  distinguishes between builtins, functions, aliases, and executables. For
  bash, it shows that it's an external executable located at /usr/bin/bash.

Verification:
  type -a bash
  # Shows all locations where bash is found
  
  type cd
  # Shows: cd is a shell builtin


STEP 5: View file with pager
─────────────────────────────────────────────────────────────────
Command:
  less /opt/labwork/docs/readme.txt

Explanation:
  • less: Interactive pager for viewing text files
  • /opt/labwork/docs/readme.txt: File to view

Navigation within less:
  - Space: Move forward one page
  - b: Move backward one page
  - Down/Up arrows: Line-by-line navigation
  - /text: Search for "text"
  - q: Quit less

Why this works:
  Unlike cat which dumps the entire file to the terminal, less provides
  controlled viewing with navigation and search capabilities. It's especially
  useful for long files like logs or documentation.

Verification:
  # Inside less:
  # 1. Press Space to scroll
  # 2. Type /Technical to search
  # 3. Press q to quit


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Absolute vs Relative Paths:
  Absolute paths start with / and specify location from filesystem root.
  They work from any directory: /opt/labwork/reports
  
  Relative paths are relative to current directory and don't start with /.
  They're shorter but depend on where you are: reports/monthly_report.txt

Command Options and Arguments:
  Linux commands follow a pattern: command [options] [arguments]
  
  Options modify command behavior:
    -l: long format
    -h: human-readable
  
  Options can be:
    - Combined: -lh (same as -l -h)
    - Short form: -a
    - Long form: --all
  
  Arguments specify what to act on:
    ls -lh /opt/labwork/config
    ^   ^  ^
    |   |  └─ argument (directory to list)
    |   └──── options (how to format)
    └──────── command (what to do)

File Creation and Ownership:
  When you create files as labuser, they automatically inherit:
    - Owner: labuser
    - Group: labuser (primary group)
    - Permissions: Based on umask (typically 644 for files, 755 for dirs)
  
  This is why mkdir and touch create resources owned by labuser without
  needing explicit chown commands.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using relative paths without knowing current directory
  Result: Files/directories created in wrong location
  Fix: Always use pwd to check location before using relative paths
       Or use absolute paths: mkdir /opt/labwork/reports

Mistake 2: Forgetting to navigate before creating resources
  Result: Resources created in home directory or wrong location
  Fix: cd to the target directory first, or use full paths
       Example: mkdir /opt/labwork/reports (works from anywhere)

Mistake 3: Not verifying command completion
  Result: Assuming command worked without checking
  Fix: Use verification commands after each step:
       - ls -l to verify file creation
       - pwd to verify location
       - ls -ld to verify directory creation

Mistake 4: Confusing cat and less for large files
  Result: Terminal flooded with output from cat
  Fix: Use less for any file you want to navigate through
       Use cat only for quick viewing of short files

Mistake 5: Not understanding command options
  Result: Output doesn't show needed information
  Fix: Read man pages (man ls) or use --help flag
       Practice common option combinations: -lh, -la, -lt


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Use TAB completion aggressively to save time and avoid typos:
   - Type first few characters and press TAB
   - Double-TAB shows all possible completions
   - Works for commands, filenames, paths

2. Always verify your work immediately after each task:
   - ls -l to check file creation
   - pwd to verify location
   - cat or less to verify file contents

3. Prefer absolute paths in exam scenarios:
   - Less room for error
   - Works regardless of current directory
   - /opt/labwork/reports is clearer than ../reports

4. Master the ls command and its options:
   - ls -l: Long format (most common)
   - ls -a: Show hidden files
   - ls -lh: Human-readable sizes
   - ls -lt: Sort by modification time
   - ls -ld: Directory info (not contents)

5. Know when to use pagers:
   - Use less for files >1 page
   - Pipe long command output: command | less
   - Remember q to quit, Space to scroll

6. Understand command types:
   - Builtins (cd, type, pwd): Part of shell
   - Executables (ls, cat, less): Separate programs
   - Use 'type' command to identify

EOF
}

#############################################################################
# CLEANUP: Remove lab components
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r labuser 2>/dev/null || true
    rm -rf /opt/labwork 2>/dev/null || true
    rm -rf /var/log/labtest 2>/dev/null || true
    
    echo "  ✓ Lab user removed"
    echo "  ✓ Lab directories removed"
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
