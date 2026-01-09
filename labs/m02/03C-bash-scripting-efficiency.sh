#!/bin/bash
# labs/03C-bash-scripting-efficiency.sh
# Lab: Bash Scripting and Command-Line Efficiency
# Difficulty: Advanced
# RHCSA Objective: Create simple shell scripts; Use essential tools for handling files and directories

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Bash Scripting and Command-Line Efficiency"
LAB_DIFFICULTY="Advanced"
LAB_TIME_ESTIMATE="35-45 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Remove test user and directories from previous attempts
    userdel -r scriptdev 2>/dev/null || true
    rm -rf /opt/scripts 2>/dev/null || true
    rm -rf /var/log/automation 2>/dev/null || true
    
    # Create test user for the lab
    useradd -m -s /bin/bash scriptdev 2>/dev/null || true
    echo "scriptdev:password123" | chpasswd 2>/dev/null || true
    
    # Create directory structure
    mkdir -p /opt/scripts/{backup,monitoring,utils} 2>/dev/null || true
    mkdir -p /var/log/automation 2>/dev/null || true
    mkdir -p /opt/data/{configs,logs,temp} 2>/dev/null || true
    
    # Create sample files for script operations
    echo "server01.example.com" > /opt/data/configs/servers.txt
    echo "server02.example.com" >> /opt/data/configs/servers.txt
    echo "server03.example.com" >> /opt/data/configs/servers.txt
    
    # Create sample log files
    for i in {1..5}; do
        echo "$(date) INFO Application started" > "/opt/data/logs/app_$i.log"
        echo "$(date) ERROR Connection failed" >> "/opt/data/logs/app_$i.log"
        echo "$(date) WARN Slow response detected" >> "/opt/data/logs/app_$i.log"
    done
    
    # Set ownership
    chown -R scriptdev:scriptdev /opt/scripts 2>/dev/null || true
    chown -R scriptdev:scriptdev /opt/data 2>/dev/null || true
    chmod 755 /opt/scripts 2>/dev/null || true
    
    echo "  ✓ User 'scriptdev' created"
    echo "  ✓ Directory structure created at /opt/scripts and /opt/data"
    echo "  ✓ Sample files generated for script operations"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES: Knowledge and commands needed
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of bash scripting syntax
  • Knowledge of variables, conditionals, and loops
  • Understanding of file permissions and execution
  • Familiarity with command substitution and pipes
  • Understanding of exit codes and script debugging

Commands You'll Use:
  • bash        - Execute bash scripts
  • chmod       - Change file permissions to make scripts executable
  • sh -x       - Execute script with debugging (trace mode)
  • set -x      - Enable debugging within script
  • source      - Execute script in current shell context
  • $()         - Command substitution (preferred over backticks)
  • ||          - Logical OR for error handling
  • &&          - Logical AND for command chaining
  • echo        - Output text (with special flags)
  • read        - Read user input into variables
  • test / [ ]  - Conditional expression evaluation

Files You'll Create/Interact With:
  • /opt/scripts/backup/system_backup.sh      - Automated backup script
  • /opt/scripts/monitoring/check_logs.sh     - Log monitoring script
  • /opt/scripts/utils/user_report.sh         - User information script
  • ~/.bashrc_aliases                         - Custom alias definitions
  • /var/log/automation/script_run.log        - Script execution log

Important Script Components:
  • #!/bin/bash              - Shebang (interpreter directive)
  • Variables: VAR="value"   - Variable assignment (no spaces!)
  • Arguments: $1, $2, $@    - Script parameters
  • Exit codes: exit 0/1     - Script return status
  • Conditionals: if/then/else/fi
  • Loops: for, while
EOF
}

#############################################################################
# SCENARIO: The lab story and objectives (Standard Mode)
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your manufacturing company is transitioning to infrastructure automation. As
a junior system administrator, you've been tasked with creating several bash
scripts to automate routine tasks. These scripts need to be robust, well-
documented, and follow best practices for error handling and logging.

BACKGROUND:
The IT team currently performs many tasks manually, leading to inconsistencies
and human error. Management has approved a project to automate common operations
through bash scripting. You need to demonstrate proficiency in creating
production-quality scripts that handle errors gracefully and provide clear
feedback to operators.

OBJECTIVES:
  1. Create a system backup script (system_backup.sh):
     • Location: /opt/scripts/backup/system_backup.sh
     • Must include proper shebang (#!/bin/bash)
     • Accept directory path as first argument ($1)
     • Create timestamped backup archive (tar.gz format)
     • Implement error handling (check if directory exists)
     • Log operations to /var/log/automation/backup.log
     • Exit with code 0 on success, 1 on failure
     • Make script executable (chmod +x)
  
  2. Create log monitoring script (check_logs.sh):
     • Location: /opt/scripts/monitoring/check_logs.sh
     • Search /opt/data/logs for ERROR entries
     • Count total errors across all log files
     • Display which files contain errors
     • Use grep with appropriate flags
     • Output formatted report to stdout
     • Store results in /var/log/automation/error_summary.log
  
  3. Create interactive user report script (user_report.sh):
     • Location: /opt/scripts/utils/user_report.sh
     • Prompt user for username input
     • Check if user exists on system (using id command)
     • Display: username, UID, GID, home directory, shell
     • Handle case where user doesn't exist (error message)
     • Use if/then/else conditional logic
     • Demonstrate use of command substitution $()
  
  4. Set up command aliases for efficiency:
     • Create ~/.bashrc_aliases for user scriptdev
     • Alias: ll='ls -lah --color=auto'
     • Alias: scripts='cd /opt/scripts'
     • Alias: logs='cd /var/log/automation'
     • Source aliases from ~/.bashrc
     • Test that aliases work after sourcing
  
  5. Create a multi-function utility script (admin_tools.sh):
     • Location: /opt/scripts/utils/admin_tools.sh
     • Accept command-line argument: backup|check|report
     • Use case statement to execute different functions
     • backup: Calls system_backup.sh with /opt/data
     • check: Calls check_logs.sh
     • report: Displays system information (uptime, disk usage)
     • Include usage/help message for invalid input
     • Demonstrate script modularity and function usage

HINTS:
  • Always test scripts before marking them executable
  • Use 'bash -x script.sh' to debug issues
  • Remember: no spaces around = in variable assignment
  • Use quotes around variables to handle spaces: "$VAR"
  • Test exit codes: echo $? after script execution
  • mkdir -p creates parent directories if needed

SUCCESS CRITERIA:
  • All three scripts exist at specified locations
  • Scripts have proper shebang and are executable
  • system_backup.sh creates valid tar.gz archives
  • check_logs.sh correctly identifies and counts errors
  • user_report.sh handles both existing and non-existing users
  • Aliases are configured and functional
  • admin_tools.sh properly routes to subfunctions
  • All scripts have appropriate error handling
  • Log files created in /var/log/automation
EOF
}

#############################################################################
# QUICK OBJECTIVES: Condensed checklist
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create system_backup.sh with error handling and logging
  ☐ 2. Create check_logs.sh to find and count ERROR entries
  ☐ 3. Create user_report.sh with interactive user lookup
  ☐ 4. Set up ~/.bashrc_aliases with ll, scripts, logs aliases
  ☐ 5. Create admin_tools.sh with case statement for routing
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
Your manufacturing company is transitioning to infrastructure automation.
You need to create several bash scripts to automate routine tasks, demonstrating
proficiency in script creation, error handling, and best practices.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Create automated backup script

Create a robust backup script that accepts a directory path, creates a
timestamped tar.gz archive, and handles errors appropriately.

Requirements:
  • Script location: /opt/scripts/backup/system_backup.sh
  • Must start with #!/bin/bash shebang
  • Accept directory path as $1 (first argument)
  • Check if directory exists before backup
  • Create backup with format: backup_YYYYMMDD_HHMMSS.tar.gz
  • Save backup to /opt/scripts/backup/
  • Log all operations to /var/log/automation/backup.log
  • Display success/error messages to user
  • Exit with code 0 (success) or 1 (failure)
  • Make script executable with chmod +x

Commands you might need:
  • #!/bin/bash               - Shebang line
  • if [ -d "$1" ]; then      - Check if directory exists
  • DATE=$(date +%Y%m%d_%H%M%S)  - Generate timestamp
  • tar -czf archive.tar.gz /path  - Create compressed archive
  • echo "message" >> logfile   - Append to log
  • exit 0                    - Exit with success
  • exit 1                    - Exit with failure
  • chmod +x script.sh        - Make executable
EOF
}

validate_step_1() {
    local script="/opt/scripts/backup/system_backup.sh"
    
    if [ ! -f "$script" ]; then
        print_color "$RED" "✗ Script not found: $script"
        echo "  Create the script at this location"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        print_color "$RED" "✗ Script is not executable"
        echo "  Fix: chmod +x $script"
        return 1
    fi
    
    if ! head -1 "$script" | grep -q "^#!/bin/bash"; then
        print_color "$RED" "✗ Missing or incorrect shebang"
        echo "  First line should be: #!/bin/bash"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Backup script exists and is executable"
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:
  cat > /opt/scripts/backup/system_backup.sh << 'SCRIPT_EOF'
#!/bin/bash
# system_backup.sh - Automated directory backup script
# Usage: ./system_backup.sh /path/to/directory

# Configuration
BACKUP_DIR="/opt/scripts/backup"
LOG_FILE="/var/log/automation/backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if argument provided
if [ $# -eq 0 ]; then
    echo "Error: No directory specified"
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

SOURCE_DIR="$1"

# Check if directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR: Directory does not exist: $SOURCE_DIR"
    echo "Error: Directory '$SOURCE_DIR' does not exist"
    exit 1
fi

# Create backup filename
BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Log start of backup
log_message "Starting backup of $SOURCE_DIR"

# Perform backup
if tar -czf "$BACKUP_PATH" "$SOURCE_DIR" 2>/dev/null; then
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    log_message "SUCCESS: Backup created: $BACKUP_NAME (Size: $BACKUP_SIZE)"
    echo "Backup successful: $BACKUP_NAME"
    echo "Location: $BACKUP_PATH"
    echo "Size: $BACKUP_SIZE"
    exit 0
else
    log_message "ERROR: Backup failed for $SOURCE_DIR"
    echo "Error: Backup operation failed"
    exit 1
fi
SCRIPT_EOF

  chmod +x /opt/scripts/backup/system_backup.sh

Explanation:

Shebang (#!/bin/bash):
  • MUST be first line of script
  • Tells system to use bash interpreter
  • Absolute path to bash: /usr/bin/bash
  • Without shebang, script runs in sh (limited features)

Variable Assignment:
  • BACKUP_DIR="/opt/scripts/backup"
  • No spaces around = sign (critical!)
  • Use quotes for values with spaces
  • Variable naming: UPPERCASE for constants, lowercase for local vars

Command Substitution:
  • TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  • $() syntax (preferred over backticks)
  • Captures command output into variable
  • Useful for dynamic values (dates, calculations)

Argument Handling:
  • $1: First command-line argument
  • $#: Count of arguments
  • $@: All arguments
  • "$1" with quotes: Handles spaces in arguments

Conditional Logic:
  • if [ condition ]; then ... fi
  • Space required after [ and before ]
  • -d: Tests if directory exists
  • -f: Tests if file exists
  • -x: Tests if executable
  • !: Negation operator

Error Handling:
  • exit 0: Success (any non-zero is failure)
  • exit 1: Generic failure
  • Always check: $? for exit code
  • Use meaningful exit codes in complex scripts

Logging Pattern:
  • Append to log: echo "message" >> logfile
  • Timestamp logs: $(date '+%Y-%m-%d %H:%M:%S')
  • tee command: Output to both stdout and file
  • Consistent format helps with parsing/monitoring

Tar Command:
  • tar -czf: Create compressed (gzip) archive
    - c: Create
    - z: Compress with gzip
    - f: Filename follows
  • tar -xzf: Extract compressed archive
  • Output redirection: 2>/dev/null suppresses errors

Testing the Script:
  # Test with valid directory
  /opt/scripts/backup/system_backup.sh /opt/data/configs
  echo $?  # Should output: 0
  
  # Test with invalid directory
  /opt/scripts/backup/system_backup.sh /nonexistent
  echo $?  # Should output: 1
  
  # Check log file
  cat /var/log/automation/backup.log
  
  # Verify backup was created
  ls -lh /opt/scripts/backup/

Verification:
  bash -n /opt/scripts/backup/system_backup.sh
  # Checks syntax without executing
  
  bash -x /opt/scripts/backup/system_backup.sh /opt/data
  # Runs with debug output (shows each command)

EOF
}

hint_step_1() {
    echo "  Start with shebang, check $1, use tar -czf for backup, log to file"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create log monitoring script

Create a script that searches log files for ERROR entries and generates
a summary report. This demonstrates text processing and grep usage.

Requirements:
  • Script location: /opt/scripts/monitoring/check_logs.sh
  • Search directory: /opt/data/logs/*.log
  • Find all lines containing "ERROR" (case-insensitive)
  • Count total number of errors found
  • Display which files contain errors
  • Output formatted report to stdout
  • Save results to /var/log/automation/error_summary.log
  • Make executable

Commands you might need:
  • grep -i "pattern" file    - Case-insensitive search
  • grep -c "pattern" file    - Count matching lines
  • grep -l "pattern" files   - List files with matches
  • wc -l                     - Count lines
  • for file in /path/*; do   - Loop through files
EOF
}

validate_step_2() {
    local script="/opt/scripts/monitoring/check_logs.sh"
    
    if [ ! -f "$script" ]; then
        print_color "$RED" "✗ Script not found: $script"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        print_color "$RED" "✗ Script is not executable"
        echo "  Fix: chmod +x $script"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Log monitoring script exists and is executable"
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:
  cat > /opt/scripts/monitoring/check_logs.sh << 'SCRIPT_EOF'
#!/bin/bash
# check_logs.sh - Monitor logs for ERROR entries
# Searches log files and generates error summary report

LOG_DIR="/opt/data/logs"
OUTPUT_LOG="/var/log/automation/error_summary.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Initialize counters
TOTAL_ERRORS=0
FILES_WITH_ERRORS=0

# Header for report
echo "======================================"
echo "  ERROR LOG SUMMARY"
echo "  Generated: $TIMESTAMP"
echo "======================================"
echo ""

# Save to output log
{
    echo "======================================"
    echo "  ERROR LOG SUMMARY"
    echo "  Generated: $TIMESTAMP"
    echo "======================================"
    echo ""
} > "$OUTPUT_LOG"

# Check if log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo "Error: Log directory not found: $LOG_DIR"
    exit 1
fi

# Process each log file
for logfile in "$LOG_DIR"/*.log; do
    if [ -f "$logfile" ]; then
        # Count errors in this file
        ERROR_COUNT=$(grep -ci "error" "$logfile")
        
        if [ "$ERROR_COUNT" -gt 0 ]; then
            FILENAME=$(basename "$logfile")
            echo "[$FILES_WITH_ERRORS] $FILENAME: $ERROR_COUNT errors"
            echo "[$FILES_WITH_ERRORS] $FILENAME: $ERROR_COUNT errors" >> "$OUTPUT_LOG"
            
            # Show first 3 error lines from this file
            echo "    Sample errors:"
            grep -i "error" "$logfile" | head -3 | sed 's/^/    → /'
            echo ""
            
            ((FILES_WITH_ERRORS++))
            TOTAL_ERRORS=$((TOTAL_ERRORS + ERROR_COUNT))
        fi
    fi
done

# Summary
echo "======================================"
echo "SUMMARY:"
echo "  Total errors found: $TOTAL_ERRORS"
echo "  Files with errors: $FILES_WITH_ERRORS"
echo "======================================"

# Append summary to output log
{
    echo "======================================"
    echo "SUMMARY:"
    echo "  Total errors found: $TOTAL_ERRORS"
    echo "  Files with errors: $FILES_WITH_ERRORS"
    echo "======================================"
} >> "$OUTPUT_LOG"

# Exit with code based on errors found
if [ "$TOTAL_ERRORS" -gt 0 ]; then
    exit 1  # Errors found
else
    exit 0  # No errors
fi
SCRIPT_EOF

  chmod +x /opt/scripts/monitoring/check_logs.sh

Explanation:

Grep Command Options:
  • grep -i: Case-insensitive search
    - Matches ERROR, error, Error, eRRoR
    - Essential for catching all variants
  
  • grep -c: Count matching lines
    - Returns number, not the lines themselves
    - Useful for summary statistics
  
  • grep -l: List files with matches
    - Shows filename only, not content
    - Good for identifying affected files
  
  • grep -n: Show line numbers
    - Helps locate errors in large files
  
  • grep -v: Invert match (exclude pattern)

For Loop Syntax:
  • for variable in list; do ... done
  • Iterates over each item in list
  • $LOG_DIR/*.log expands to all .log files
  • Quotes important: "$logfile" handles spaces

Arithmetic Operations:
  • ((VARIABLE++)):  Increment by 1
  • ((VARIABLE--)):  Decrement by 1
  • TOTAL=$((A + B)): Add variables
  • [ "$A" -gt "$B" ]: Compare numbers
    - -gt: Greater than
    - -lt: Less than
    - -eq: Equal to
    - -ne: Not equal

Basename Command:
  • basename /path/to/file.txt
  • Returns: file.txt
  • Strips directory path
  • Useful for clean output formatting

Output Redirection:
  • >  : Overwrite file
  • >> : Append to file
  • 2> : Redirect stderr
  • &> : Redirect both stdout and stderr
  • tee: Send to file AND stdout

Sed Command (Stream Editor):
  • sed 's/^/prefix/': Add prefix to lines
  • sed 's/old/new/': Replace text
  • Used here to indent error messages
  • Powerful text transformation tool

Testing the Script:
  # Run the script
  /opt/scripts/monitoring/check_logs.sh
  
  # Check exit code
  echo $?
  
  # Review summary log
  cat /var/log/automation/error_summary.log

Verification:
  # Test with log files
  grep -i "error" /opt/data/logs/*.log
  
  # Count errors manually
  grep -ci "error" /opt/data/logs/*.log | paste -sd+ | bc

EOF
}

hint_step_2() {
    echo "  Use grep -ci to count errors, loop through files, summarize results"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create interactive user report script

Create a script that prompts for a username, checks if it exists, and
displays detailed user information. This demonstrates interactive scripts
and conditional logic.

Requirements:
  • Script location: /opt/scripts/utils/user_report.sh
  • Prompt user for username input
  • Check if user exists using 'id' command
  • If exists: Display username, UID, GID, home, shell
  • If not: Display error message
  • Use if/then/else logic
  • Demonstrate command substitution
  • Make executable

Commands you might need:
  • read -p "prompt" VARIABLE   - Read user input
  • id username                 - Get user information
  • id -u username              - Get UID only
  • id -g username              - Get GID only
  • getent passwd username      - Get passwd entry
  • $?                          - Last command exit code
EOF
}

validate_step_3() {
    local script="/opt/scripts/utils/user_report.sh"
    
    if [ ! -f "$script" ]; then
        print_color "$RED" "✗ Script not found: $script"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ User report script exists and is executable"
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:
  cat > /opt/scripts/utils/user_report.sh << 'SCRIPT_EOF'
#!/bin/bash
# user_report.sh - Interactive user information lookup
# Prompts for username and displays account details

echo "======================================"
echo "  USER INFORMATION REPORT"
echo "======================================"
echo ""

# Prompt for username
read -p "Enter username to lookup: " USERNAME

# Check if username provided
if [ -z "$USERNAME" ]; then
    echo "Error: No username provided"
    exit 1
fi

# Check if user exists
if id "$USERNAME" &>/dev/null; then
    echo ""
    echo "User found: $USERNAME"
    echo "------------------------------------"
    
    # Get user information using command substitution
    USER_UID=$(id -u "$USERNAME")
    USER_GID=$(id -g "$USERNAME")
    USER_GROUPS=$(id -Gn "$USERNAME" | tr ' ' ',')
    
    # Get additional info from passwd file
    PASSWD_ENTRY=$(getent passwd "$USERNAME")
    USER_HOME=$(echo "$PASSWD_ENTRY" | cut -d: -f6)
    USER_SHELL=$(echo "$PASSWD_ENTRY" | cut -d: -f7)
    USER_GECOS=$(echo "$PASSWD_ENTRY" | cut -d: -f5)
    
    # Display information
    echo "  Username:     $USERNAME"
    echo "  UID:          $USER_UID"
    echo "  Primary GID:  $USER_GID"
    echo "  Groups:       $USER_GROUPS"
    echo "  Home Dir:     $USER_HOME"
    echo "  Shell:        $USER_SHELL"
    
    if [ -n "$USER_GECOS" ]; then
        echo "  Full Name:    $USER_GECOS"
    fi
    
    echo "------------------------------------"
    
    # Check if home directory exists
    if [ -d "$USER_HOME" ]; then
        echo "  Home directory: EXISTS"
        HOME_SIZE=$(du -sh "$USER_HOME" 2>/dev/null | cut -f1)
        echo "  Home dir size:  $HOME_SIZE"
    else
        echo "  Home directory: MISSING"
    fi
    
    # Check last login
    LAST_LOGIN=$(last -1 "$USERNAME" 2>/dev/null | head -1)
    if [ -n "$LAST_LOGIN" ]; then
        echo "  Last login:     $LAST_LOGIN"
    fi
    
    echo ""
    exit 0
    
else
    echo ""
    echo "Error: User '$USERNAME' does not exist on this system"
    echo ""
    echo "Available users:"
    cut -d: -f1 /etc/passwd | grep -v '^_' | head -10 | column
    echo "  (showing first 10 users...)"
    echo ""
    exit 1
fi
SCRIPT_EOF

  chmod +x /opt/scripts/utils/user_report.sh

Explanation:

Read Command:
  • read -p "prompt" VARIABLE: Prompts and stores input
    - -p: Display prompt text
    - -s: Silent mode (for passwords)
    - -t 10: Timeout after 10 seconds
    - -n 1: Read single character
  
  • Variables store exactly what user types
  • No need for quotes during read
  • Always validate input before using

String Tests:
  • [ -z "$VAR" ]: True if string is empty
  • [ -n "$VAR" ]: True if string is NOT empty
  • [ "$A" = "$B" ]: String equality
  • [ "$A" != "$B" ]: String inequality
  • Always quote variables in tests!

Command Existence Check:
  • id "$USERNAME" &>/dev/null
  • &>/dev/null: Redirects all output to nowhere
  • Purpose: Suppress error messages
  • Check $? or use in if condition directly

ID Command:
  • id username: Full user information
  • id -u username: UID only
  • id -g username: Primary GID only
  • id -G username: All GIDs (numeric)
  • id -Gn username: All group names
  • Returns non-zero if user doesn't exist

Getent Command:
  • getent passwd username: Get /etc/passwd entry
  • getent group groupname: Get /etc/group entry
  • Works with NSS (includes LDAP, AD users)
  • Safer than directly reading /etc/passwd

Field Extraction:
  • cut -d: -f6: Cut using : delimiter, field 6
  • Fields in /etc/passwd:
    1: Username
    2: Password (x = shadowed)
    3: UID
    4: GID
    5: GECOS (full name, etc.)
    6: Home directory
    7: Shell

Conditional Operators:
  • &&: AND - second command runs if first succeeds
  • ||: OR - second command runs if first fails
  • Examples:
    - cd /tmp && ls: Change dir, then list (if cd worked)
    - rm file || echo "Failed": Delete or show error

Testing the Script:
  # Interactive test
  /opt/scripts/utils/user_report.sh
  # Enter: root (should work)
  
  # Test with non-existent user
  echo "fakeuser" | /opt/scripts/utils/user_report.sh
  
  # Test with scriptdev user
  echo "scriptdev" | /opt/scripts/utils/user_report.sh

Verification:
  # Manually check user info
  id root
  getent passwd root
  
  # Test script with known users
  for user in root scriptdev; do
      echo "$user" | /opt/scripts/utils/user_report.sh
  done

EOF
}

hint_step_3() {
    echo "  Use 'read' for input, 'id' to check user exists, command substitution for details"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Set up bash aliases for efficiency

Create a custom aliases file and configure it to be sourced from .bashrc.
Aliases provide shortcuts for commonly used commands.

Requirements:
  • Create ~/.bashrc_aliases file
  • Define aliases:
    - ll='ls -lah --color=auto'
    - scripts='cd /opt/scripts'
    - logs='cd /var/log/automation'
  • Add source line to ~/.bashrc
  • Test aliases work after sourcing

Commands you might need:
  • alias name='command'        - Define alias
  • source ~/.bashrc            - Reload bash configuration
  • alias                       - List all aliases
  • unalias name                - Remove alias
  • type name                   - Check if name is alias
EOF
}

validate_step_4() {
    local alias_file="/home/scriptdev/.bashrc_aliases"
    local bashrc="/home/scriptdev/.bashrc"
    
    if [ ! -f "$alias_file" ]; then
        print_color "$RED" "✗ Alias file not found: $alias_file"
        return 1
    fi
    
    if ! grep -q "ll=" "$alias_file"; then
        print_color "$RED" "✗ Missing 'll' alias"
        return 1
    fi
    
    if ! grep -q "scripts=" "$alias_file"; then
        print_color "$RED" "✗ Missing 'scripts' alias"
        return 1
    fi
    
    if ! grep -q ".bashrc_aliases" "$bashrc" 2>/dev/null; then
        print_color "$YELLOW" "⚠ Aliases not sourced from .bashrc"
    fi
    
    print_color "$GREEN" "  ✓ Alias configuration complete"
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Create alias file:
  # As user scriptdev
  su - scriptdev
  
  cat > ~/.bashrc_aliases << 'ALIAS_EOF'
# Custom aliases for system administration
# File: ~/.bashrc_aliases

# Enhanced ls commands
alias ll='ls -lah --color=auto'
alias ls='ls --color=auto'
alias l='ls -CF'

# Quick directory navigation
alias scripts='cd /opt/scripts'
alias logs='cd /var/log/automation'
alias data='cd /opt/data'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# System information shortcuts
alias ports='netstat -tulanp'
alias meminfo='free -h'
alias diskinfo='df -h'

# Quick process viewing
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'

# History shortcuts
alias h='history'
alias hg='history | grep'
ALIAS_EOF

Add to .bashrc:
  cat >> ~/.bashrc << 'BASHRC_EOF'

# Load custom aliases
if [ -f ~/.bashrc_aliases ]; then
    . ~/.bashrc_aliases
fi
BASHRC_EOF

Apply changes:
  source ~/.bashrc

Test aliases:
  type ll
  # Should show: ll is aliased to `ls -lah --color=auto'
  
  ll
  # Should execute ls -lah --color=auto
  
  scripts
  # Should change to /opt/scripts
  
  pwd
  # Should show: /opt/scripts

Explanation:

Alias Syntax:
  • alias name='command': Define alias
  • No spaces around =
  • Quote the command
  • Can include arguments and options
  • Active only in current shell (unless in .bashrc)

Alias vs Function:
  Aliases:
    - Simple command substitution
    - No parameters beyond what you type
    - Faster for simple shortcuts
    - Example: alias ll='ls -la'
  
  Functions:
    - Can accept parameters
    - More complex logic
    - Better for scripts
    - Example: lsdir() { ls -la "$1"; }

Common Alias Patterns:
  1. Add colors: alias ls='ls --color=auto'
  2. Add safety: alias rm='rm -i'
  3. Navigation: alias docs='cd ~/Documents'
  4. Command chains: alias update='sudo yum update -y'

Sourcing Files:
  • source file: Execute commands in current shell
  • . file: Same as source (POSIX compatible)
  • ./file: Execute in subshell (doesn't affect current shell)
  
  Key difference:
    - source: Variables, aliases affect current shell
    - ./file: Changes isolated to subshell

Alias Scope:
  • Defined in .bashrc: Available in all interactive shells
  • Defined in .bash_profile: Login shells only
  • Defined interactively: Current shell only
  • Not inherited by child processes or scripts

Troubleshooting Aliases:
  # Check if alias exists
  type ll
  
  # List all aliases
  alias
  
  # Temporarily disable alias
  \ll  # Backslash bypasses alias
  
  # Remove alias
  unalias ll
  
  # Re-source .bashrc if not working
  source ~/.bashrc

Best Practices:
  1. Keep aliases simple (use functions for complex logic)
  2. Document your aliases (comments in alias file)
  3. Don't override system commands (or use safety options)
  4. Group related aliases together
  5. Source from .bashrc, not .bash_profile (for all shells)

Verification:
  # Check alias definition
  type -a ll
  
  # Test each alias
  ll
  scripts && pwd  # Should be in /opt/scripts
  logs && pwd     # Should be in /var/log/automation
  
  # List all custom aliases
  alias | grep -E '(ll|scripts|logs)'

EOF
}

hint_step_4() {
    echo "  Create ~/.bashrc_aliases, add alias lines, source from ~/.bashrc"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Create multi-function admin utility script

Create a master script that uses a case statement to route to different
administrative functions. This demonstrates script modularity and argument
handling.

Requirements:
  • Script location: /opt/scripts/utils/admin_tools.sh
  • Accept argument: backup|check|report
  • Use case statement for routing
  • backup: Execute system_backup.sh with /opt/data
  • check: Execute check_logs.sh
  • report: Display system info (uptime, disk, memory)
  • Display usage message for invalid/missing arguments
  • Make executable

Commands you might need:
  • case "$VAR" in ... esac     - Case statement
  • $1                           - First argument
  • /path/to/script.sh           - Execute other scripts
  • uptime                       - System uptime
  • df -h                        - Disk usage
  • free -h                      - Memory usage
EOF
}

validate_step_5() {
    local script="/opt/scripts/utils/admin_tools.sh"
    
    if [ ! -f "$script" ]; then
        print_color "$RED" "✗ Script not found: $script"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    if ! grep -q "case" "$script"; then
        print_color "$YELLOW" "⚠ Case statement not found in script"
    fi
    
    print_color "$GREEN" "  ✓ Admin tools script exists and is executable"
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:
  cat > /opt/scripts/utils/admin_tools.sh << 'SCRIPT_EOF'
#!/bin/bash
# admin_tools.sh - Multi-function administrative utility
# Usage: ./admin_tools.sh {backup|check|report|help}

SCRIPT_DIR="/opt/scripts"

# Function definitions
show_usage() {
    cat << 'USAGE'
====================================
  ADMIN TOOLS UTILITY
====================================

Usage: $0 {backup|check|report|help}

Commands:
  backup  - Backup system data directories
  check   - Check logs for errors
  report  - Display system information
  help    - Show this help message

Examples:
  $0 backup
  $0 check
  $0 report
USAGE
    exit 1
}

run_backup() {
    echo "Running system backup..."
    if [ -x "$SCRIPT_DIR/backup/system_backup.sh" ]; then
        "$SCRIPT_DIR/backup/system_backup.sh" /opt/data
    else
        echo "Error: Backup script not found or not executable"
        exit 1
    fi
}

run_check() {
    echo "Checking system logs..."
    if [ -x "$SCRIPT_DIR/monitoring/check_logs.sh" ]; then
        "$SCRIPT_DIR/monitoring/check_logs.sh"
    else
        echo "Error: Log check script not found or not executable"
        exit 1
    fi
}

show_report() {
    echo "======================================"
    echo "  SYSTEM INFORMATION REPORT"
    echo "  Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "======================================"
    echo ""
    
    echo "UPTIME:"
    uptime
    echo ""
    
    echo "DISK USAGE:"
    df -h | grep -E '(Filesystem|^/dev/)'
    echo ""
    
    echo "MEMORY USAGE:"
    free -h
    echo ""
    
    echo "LOAD AVERAGE:"
    cat /proc/loadavg
    echo ""
    
    echo "TOP PROCESSES:"
    ps aux --sort=-%mem | head -6
    echo ""
    
    echo "LOGGED IN USERS:"
    who
    echo ""
    
    echo "======================================"
}

# Main logic using case statement
case "$1" in
    backup)
        run_backup
        ;;
    check)
        run_check
        ;;
    report)
        show_report
        ;;
    help|-h|--help)
        show_usage
        ;;
    "")
        echo "Error: No command specified"
        echo ""
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        show_usage
        ;;
esac

exit 0
SCRIPT_EOF

  chmod +x /opt/scripts/utils/admin_tools.sh

Explanation:

Case Statement Syntax:
  case "$VARIABLE" in
    pattern1)
        commands
        ;;
    pattern2|pattern3)
        commands
        ;;
    *)
        default commands
        ;;
  esac

  • Each pattern ends with )
  • Commands for that pattern follow
  • ;; ends each case block
  • * is catch-all (default case)
  • Can use | for multiple patterns

Pattern Matching:
  • Exact match: "backup")
  • Multiple options: "help"|"-h"|"--help")
  • Wildcard: *)
  • Empty string: "")
  • Can use glob patterns: *.txt)

Function Definition:
  function_name() {
      commands
      local VAR="value"
      return 0
  }
  
  • No function keyword needed (bash-specific)
  • Local variables: use 'local' keyword
  • Return codes: 0-255
  • Access with: function_name

Function Benefits:
  1. Code reusability
  2. Better organization
  3. Easier testing
  4. Clearer logic flow
  5. Can be sourced by other scripts

Script Organization Pattern:
  #!/bin/bash
  
  # Variables and configuration
  SCRIPT_DIR="/opt/scripts"
  
  # Function definitions
  function1() { ... }
  function2() { ... }
  
  # Main logic
  case "$1" in
      option1) function1 ;;
      option2) function2 ;;
  esac

Command Execution:
  • "$SCRIPT_DIR/script.sh": Execute script
  • bash script.sh: Execute with bash
  • . script.sh: Source (run in current shell)
  • ( script.sh ): Run in subshell

Exit Codes Convention:
  • 0: Success
  • 1: General errors
  • 2: Misuse of command
  • 126: Command not executable
  • 127: Command not found
  • 130: Terminated by Ctrl+C
  • 255: Exit status out of range

Testing the Script:
  # Test each command
  /opt/scripts/utils/admin_tools.sh backup
  /opt/scripts/utils/admin_tools.sh check
  /opt/scripts/utils/admin_tools.sh report
  
  # Test error handling
  /opt/scripts/utils/admin_tools.sh invalid
  /opt/scripts/utils/admin_tools.sh
  
  # Test help
  /opt/scripts/utils/admin_tools.sh help

Verification:
  bash -n /opt/scripts/utils/admin_tools.sh
  # Check syntax
  
  chmod +x /opt/scripts/utils/admin_tools.sh
  # Make executable
  
  ./admin_tools.sh help
  # Test help function

EOF
}

hint_step_5() {
    echo "  Use case statement with $1, define functions, route to appropriate actions"
}

#############################################################################
# VALIDATION: Check the final state (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: Backup script
    print_color "$CYAN" "[1/$total] Checking backup script..."
    if [ -x "/opt/scripts/backup/system_backup.sh" ] && head -1 "/opt/scripts/backup/system_backup.sh" | grep -q "#!/bin/bash"; then
        print_color "$GREEN" "  ✓ Backup script exists, executable, has shebang"
        ((score++))
    else
        print_color "$RED" "  ✗ Backup script missing, not executable, or missing shebang"
        print_color "$YELLOW" "  Location: /opt/scripts/backup/system_backup.sh"
    fi
    echo ""
    
    # CHECK 2: Log monitoring script
    print_color "$CYAN" "[2/$total] Checking log monitoring script..."
    if [ -x "/opt/scripts/monitoring/check_logs.sh" ]; then
        print_color "$GREEN" "  ✓ Log monitoring script exists and executable"
        ((score++))
    else
        print_color "$RED" "  ✗ Log monitoring script missing or not executable"
        print_color "$YELLOW" "  Location: /opt/scripts/monitoring/check_logs.sh"
    fi
    echo ""
    
    # CHECK 3: User report script
    print_color "$CYAN" "[3/$total] Checking user report script..."
    if [ -x "/opt/scripts/utils/user_report.sh" ]; then
        print_color "$GREEN" "  ✓ User report script exists and executable"
        ((score++))
    else
        print_color "$RED" "  ✗ User report script missing or not executable"
        print_color "$YELLOW" "  Location: /opt/scripts/utils/user_report.sh"
    fi
    echo ""
    
    # CHECK 4: Bash aliases
    print_color "$CYAN" "[4/$total] Checking bash aliases configuration..."
    if [ -f "/home/scriptdev/.bashrc_aliases" ]; then
        local alias_count=$(grep -c "^alias" /home/scriptdev/.bashrc_aliases)
        if [ "$alias_count" -ge 3 ]; then
            print_color "$GREEN" "  ✓ Alias file exists with $alias_count aliases"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ Alias file found but may be incomplete"
            ((score++))
        fi
    else
        print_color "$RED" "  ✗ Alias file not found"
        print_color "$YELLOW" "  Create: /home/scriptdev/.bashrc_aliases"
    fi
    echo ""
    
    # CHECK 5: Admin tools script
    print_color "$CYAN" "[5/$total] Checking admin tools script..."
    if [ -x "/opt/scripts/utils/admin_tools.sh" ]; then
        if grep -q "case" "/opt/scripts/utils/admin_tools.sh"; then
            print_color "$GREEN" "  ✓ Admin tools script exists with case statement"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ Script exists but may not have case statement"
        fi
    else
        print_color "$RED" "  ✗ Admin tools script missing or not executable"
        print_color "$YELLOW" "  Location: /opt/scripts/utils/admin_tools.sh"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Outstanding work! You've mastered:"
        echo "  • Bash script creation with proper structure"
        echo "  • Error handling and logging"
        echo "  • Conditional logic and loops"
        echo "  • Interactive scripts with user input"
        echo "  • Command aliases for efficiency"
        echo "  • Case statements for command routing"
        echo "  • Script modularity and functions"
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
[Complete solutions for all steps are provided in the solution_step_1() through
solution_step_5() functions above]

EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always test scripts before marking complete:
   bash -n script.sh    # Check syntax
   bash -x script.sh    # Debug execution
   
2. Shebang is mandatory:
   #!/bin/bash must be first line
   
3. Make scripts executable:
   chmod +x script.sh
   Always verify with: ls -l script.sh
   
4. Test error conditions:
   - Missing arguments
   - Invalid input
   - Non-existent files
   
5. Use meaningful exit codes:
   exit 0 for success
   exit 1 for errors
   
6. Quote variables in tests:
   if [ -d "$DIR" ]; then    # CORRECT
   if [ -d $DIR ]; then      # WRONG (breaks with spaces)

EOF
}

#############################################################################
# CLEANUP: Remove lab components
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r scriptdev 2>/dev/null || true
    rm -rf /opt/scripts 2>/dev/null || true
    rm -rf /opt/data 2>/dev/null || true
    rm -rf /var/log/automation 2>/dev/null || true
    
    echo "  ✓ Lab user removed"
    echo "  ✓ Lab directories removed"
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
