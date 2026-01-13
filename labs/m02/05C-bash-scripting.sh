#!/bin/bash
# labs/07-bash-scripting-lab.sh
# Lab: Bash Scripting Fundamentals - Loops and Conditionals
# Difficulty: Intermediate
# RHCSA Objective: Create simple shell scripts

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Bash Scripting Fundamentals - Loops and Conditionals"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    rm -rf /tmp/script-lab 2>/dev/null || true
    
    # Create working directory
    mkdir -p /tmp/script-lab/{data,scripts,logs}
    
    # Create sample data files
    cat > /tmp/script-lab/data/servers.txt << 'EOF'
web1
web2
db1
cache1
backup1
EOF

    cat > /tmp/script-lab/data/services.txt << 'EOF'
nginx
postgresql
redis
EOF

    cat > /tmp/script-lab/data/users.txt << 'EOF'
alice
bob
charlie
EOF

    # Create files with different sizes for testing
    dd if=/dev/zero of=/tmp/script-lab/data/small.dat bs=1K count=10 2>/dev/null
    dd if=/dev/zero of=/tmp/script-lab/data/medium.dat bs=1M count=5 2>/dev/null
    dd if=/dev/zero of=/tmp/script-lab/data/large.dat bs=1M count=20 2>/dev/null
    
    # Create some numbered test files
    touch /tmp/script-lab/data/file{01..05}.txt
    
    echo "  ✓ Cleaned up previous lab session"
    echo "  ✓ Created test data files"
    echo "  ✓ System ready for scripting practice"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic command line usage
  • Understanding of variables from previous labs
  • Familiarity with file operations

Commands You'll Use:
  • for/while - Loop constructs
  • if/then/else - Conditional statements
  • test/[ ] - Condition testing
  • [[ ]] - Enhanced test operator
  • && - Execute if previous succeeds
  • || - Execute if previous fails
  • ; - Command separator

Core Concepts You'll Learn:
  • For loops: Iterate over lists, ranges, files
  • While loops: Repeat while condition is true
  • If statements: Execute code conditionally
  • Test operators: Compare numbers, strings, files
  • Command chaining: &&, ||, ;
  • Exit codes: $? and success/failure

Why This Matters:
  Shell scripting is the glue that holds Linux automation together.
  These fundamentals let you automate repetitive tasks, create
  system maintenance scripts, and build deployment pipelines.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're automating common system administration tasks. Manual operations
don't scale - you need to script routine maintenance, bulk operations,
and conditional logic to handle different situations.

BACKGROUND:
Bash scripts are the most common automation tool in Linux. Unlike
compiled programs, they're easy to write, modify, and debug. They're
perfect for tasks like:
  • Processing lists of servers or users
  • Checking system conditions and taking action
  • Batch file operations
  • Log processing and reporting
  • Conditional deployments

LEARNING OBJECTIVES:

  1. Master for-loop syntax and usage
     • Iterate over lists: for item in list
     • Loop through files: for f in *.txt
     • Use ranges: for i in {1..10}
     • Process command output: for line in $(cat file)

  2. Understand while-loop patterns
     • Loop with counters
     • Read files line-by-line
     • Continue until condition met
     • Infinite loops with break

  3. Write if-then-else conditional logic
     • Test file existence: if [ -f file ]
     • Compare numbers: if [ $a -gt $b ]
     • Check strings: if [ "$var" = "value" ]
     • Use [[  ]] for advanced tests

  4. Use test operators effectively
     • File tests: -f, -d, -e, -x
     • Number comparisons: -eq, -ne, -lt, -gt
     • String comparisons: =, !=, -z, -n
     • Logical operators: -a (AND), -o (OR), ! (NOT)

  5. Chain commands with logic operators
     • && for "and" (run if previous succeeds)
     • || for "or" (run if previous fails)
     • ; to separate independent commands
     • Combine for error handling

  6. Create practical automation scripts
     • Backup script with timestamp
     • Service checker with status reporting
     • File processor with size filtering
     • User account validator

HINTS:
  • Always quote variables in tests: [ "$var" = "value" ]
  • Use [[ ]] for pattern matching: [[ $file == *.txt ]]
  • Check exit codes: if command; then ... fi
  • Test scripts with echo before making changes
  • Use ; to put loops on one line for interactive testing

SUCCESS CRITERIA:
  • You can write for-loops to process lists
  • You understand while-loop patterns
  • You can write if-then-else logic
  • You know which test operators to use when
  • You can chain commands for error handling
  • You've created working automation scripts
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Write for-loop to process server list
  ☐ 2. Create while-loop with counter
  ☐ 3. Build if-else script to check file sizes
  ☐ 4. Use test operators for file validation
  ☐ 5. Chain commands with && and ||
  ☐ 6. Create backup script with timestamp
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################

get_step_count() {
    echo "6"
}

scenario_context() {
    cat << 'EOF'
You're automating system administration tasks using bash scripts. You'll
learn loops, conditionals, and command chaining to build practical
automation tools.
EOF
}

# STEP 1: Basic for-loop
show_step_1() {
    cat << 'EOF'
TASK: Create a script that loops through servers and generates reports

Write a script that reads /tmp/script-lab/data/servers.txt and creates
a status file for each server.

Requirements:
  • Script location: /tmp/script-lab/scripts/server-check.sh
  • For each server in servers.txt:
    - Create file: /tmp/script-lab/logs/${server}-status.txt
    - Content: "Checking ${server} at $(date)"
  • Make the script executable
  • Run it to generate the log files

Commands you'll need:
  • for var in $(cat file)
  • touch or echo > to create files
  • chmod +x to make executable

For-loop syntax:
  for item in list; do
      commands
  done

One-line version:
  for item in list; do command; done

What you're learning:
  For-loops let you process lists efficiently. This pattern appears
  constantly in system administration - processing servers, users,
  files, or any collection of items.
EOF
}

validate_step_1() {
    if [ ! -f "/tmp/script-lab/scripts/server-check.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script /tmp/script-lab/scripts/server-check.sh not found"
        echo "  Create the script file first"
        return 1
    fi
    
    if [ ! -x "/tmp/script-lab/scripts/server-check.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script exists but is not executable"
        echo "  Run: chmod +x /tmp/script-lab/scripts/server-check.sh"
        return 1
    fi
    
    # Check if log files were created
    local server_count=$(wc -l < /tmp/script-lab/data/servers.txt)
    local log_count=$(ls /tmp/script-lab/logs/*-status.txt 2>/dev/null | wc -l)
    
    if [ "$log_count" -lt "$server_count" ]; then
        echo ""
        print_color "$RED" "✗ Expected $server_count log files, found $log_count"
        echo "  Run the script to generate logs"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:

cat > /tmp/script-lab/scripts/server-check.sh << 'SCRIPT'
#!/bin/bash
# Server status checker

for server in $(cat /tmp/script-lab/data/servers.txt); do
    echo "Checking $server at $(date)" > /tmp/script-lab/logs/${server}-status.txt
done

echo "Generated status files for all servers"
SCRIPT

Make it executable and run:
  chmod +x /tmp/script-lab/scripts/server-check.sh
  /tmp/script-lab/scripts/server-check.sh

Breaking it down:
  • #!/bin/bash
    - Shebang line - tells system which interpreter to use
    - Required for scripts to be executable
  
  • for server in $(cat file)
    - $(cat file) outputs the file contents
    - for iterates over each line
    - Variable 'server' holds current value
  
  • do ... done
    - Encloses the loop body
    - All commands between do/done execute for each item
  
  • echo "text" > file
    - Creates/overwrites file with content
    - ${server} expands to current loop value
    - $(date) executes date command

For-loop variations:
  # Simple list:
  for color in red blue green; do
      echo $color
  done
  
  # Numeric range:
  for i in {1..10}; do
      echo "Count: $i"
  done
  
  # Files in directory:
  for file in *.txt; do
      echo "Processing $file"
  done
  
  # Command output:
  for user in $(cut -d: -f1 /etc/passwd); do
      echo "User: $user"
  done

Why quote variables?
  for server in $(cat file); do
      echo "$server"     # SAFE: preserves spaces
      echo $server       # RISKY: word splitting occurs
  done

Alternative: read in while loop (better for lines with spaces):
  while read -r server; do
      echo "Checking $server"
  done < /tmp/script-lab/data/servers.txt

Verification:
  ls -l /tmp/script-lab/logs/
  # Should show: web1-status.txt, web2-status.txt, etc.
  
  cat /tmp/script-lab/logs/web1-status.txt
  # Should show: Checking web1 at [timestamp]

EOF
}

hint_step_2() {
    echo "  Use: i=1; while [ \$i -le 5 ]; do ...; i=\$((i+1)); done"
}

# STEP 2: While loop with counter
show_step_2() {
    cat << 'EOF'
TASK: Create a countdown timer script using a while loop

Write a script that counts down from 5 to 1, creating a file for
each number.

Requirements:
  • Script location: /tmp/script-lab/scripts/countdown.sh
  • Start with COUNTER=5
  • While COUNTER is greater than 0:
    - Create file: /tmp/script-lab/logs/count-${COUNTER}.txt
    - Decrement counter
  • Make executable and run

While-loop syntax:
  while condition; do
      commands
  done

Counter pattern:
  i=1
  while [ $i -le 10 ]; do
      echo $i
      i=$((i + 1))
  done

What you're learning:
  While loops continue until a condition becomes false. They're perfect
  for counted iterations, reading files, or waiting for conditions.
EOF
}

validate_step_2() {
    if [ ! -f "/tmp/script-lab/scripts/countdown.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script /tmp/script-lab/scripts/countdown.sh not found"
        return 1
    fi
    
    if [ ! -x "/tmp/script-lab/scripts/countdown.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    # Check if countdown files were created (5 down to 1)
    local count_files=0
    for i in {1..5}; do
        [ -f "/tmp/script-lab/logs/count-$i.txt" ] && ((count_files++))
    done
    
    if [ "$count_files" -ne 5 ]; then
        echo ""
        print_color "$RED" "✗ Expected 5 count files (count-1.txt through count-5.txt), found $count_files"
        echo "  Run the script to generate files"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:

cat > /tmp/script-lab/scripts/countdown.sh << 'SCRIPT'
#!/bin/bash
# Countdown timer

COUNTER=5

while [ $COUNTER -gt 0 ]; do
    echo "Count: $COUNTER" > /tmp/script-lab/logs/count-${COUNTER}.txt
    COUNTER=$((COUNTER - 1))
done

echo "Countdown complete"
SCRIPT

chmod +x /tmp/script-lab/scripts/countdown.sh
/tmp/script-lab/scripts/countdown.sh

Breaking it down:
  • COUNTER=5
    - Initialize counter variable
  
  • while [ $COUNTER -gt 0 ]
    - Test if COUNTER is greater than 0
    - Loop continues while this is true
  
  • [ $COUNTER -gt 0 ]
    - Test operator: -gt means "greater than"
    - Returns exit code 0 (true) or 1 (false)
  
  • COUNTER=$((COUNTER - 1))
    - Arithmetic expansion: $(( expression ))
    - Decrements the counter
    - Alternative: ((COUNTER--))

While loop patterns:
  # Count up:
  i=1
  while [ $i -le 10 ]; do
      echo $i
      i=$((i + 1))
  done
  
  # Read file line by line:
  while read -r line; do
      echo "Line: $line"
  done < file.txt
  
  # Infinite loop with break:
  while true; do
      read -p "Enter 'quit' to exit: " input
      [ "$input" = "quit" ] && break
  done
  
  # Wait for condition:
  while ! ping -c1 server >/dev/null 2>&1; do
      echo "Waiting for server..."
      sleep 1
  done

Arithmetic operations:
  # Arithmetic expansion:
  result=$((5 + 3))        # Addition
  result=$((10 - 4))       # Subtraction
  result=$((6 * 7))        # Multiplication
  result=$((20 / 5))       # Division
  result=$((17 % 5))       # Modulo (remainder)
  
  # Increment/decrement:
  i=$((i + 1))
  i=$((i++))               # Post-increment
  i=$((++i))               # Pre-increment
  ((i++))                  # Alternative syntax

Test operators for numbers:
  -eq    equal to
  -ne    not equal to
  -lt    less than
  -le    less than or equal
  -gt    greater than
  -ge    greater than or equal

Verification:
  ls -l /tmp/script-lab/logs/count-*.txt
  # Should show: count-1.txt through count-5.txt

EOF
}

hint_step_3() {
    echo "  Use [ -f file ] to test if file exists, stat -c%s for file size"
}

# STEP 3: If-else with file tests
show_step_3() {
    cat << 'EOF'
TASK: Create a script that categorizes files by size

Write a script that checks each .dat file in /tmp/script-lab/data/
and categorizes it as small, medium, or large based on size.

Requirements:
  • Script: /tmp/script-lab/scripts/size-check.sh
  • For each .dat file:
    - If size < 100KB: echo "small" > logs/${filename}-category.txt
    - If size < 10MB: echo "medium" > logs/${filename}-category.txt
    - Otherwise: echo "large" > logs/${filename}-category.txt
  • Use stat -c%s to get file size in bytes

If-else syntax:
  if condition; then
      commands
  elif condition; then
      commands
  else
      commands
  fi

What you're learning:
  Conditional logic lets scripts make decisions. Combined with file
  tests and comparisons, you can handle different scenarios intelligently.
EOF
}

validate_step_3() {
    if [ ! -f "/tmp/script-lab/scripts/size-check.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script /tmp/script-lab/scripts/size-check.sh not found"
        return 1
    fi
    
    if [ ! -x "/tmp/script-lab/scripts/size-check.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    # Check if category files were created
    local cat_count=$(ls /tmp/script-lab/logs/*-category.txt 2>/dev/null | wc -l)
    if [ "$cat_count" -lt 3 ]; then
        echo ""
        print_color "$RED" "✗ Expected 3 category files, found $cat_count"
        echo "  Run the script to categorize files"
        return 1
    fi
    
    # Validate small.dat is categorized as small
    if [ -f "/tmp/script-lab/logs/small.dat-category.txt" ]; then
        if ! grep -q "small" /tmp/script-lab/logs/small.dat-category.txt 2>/dev/null; then
            echo ""
            print_color "$RED" "✗ small.dat not categorized correctly"
            return 1
        fi
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:

cat > /tmp/script-lab/scripts/size-check.sh << 'SCRIPT'
#!/bin/bash
# File size categorizer

for file in /tmp/script-lab/data/*.dat; do
    # Get filename without path
    filename=$(basename "$file")
    
    # Get file size in bytes
    size=$(stat -c%s "$file")
    
    # Categorize by size
    if [ $size -lt 102400 ]; then
        # Less than 100KB
        category="small"
    elif [ $size -lt 10485760 ]; then
        # Less than 10MB
        category="medium"
    else
        category="large"
    fi
    
    echo "$category" > /tmp/script-lab/logs/${filename}-category.txt
    echo "$filename: $category ($size bytes)"
done
SCRIPT

chmod +x /tmp/script-lab/scripts/size-check.sh
/tmp/script-lab/scripts/size-check.sh

Breaking it down:
  • for file in *.dat
    - Glob expands to all .dat files
    - Processes each file in turn
  
  • filename=$(basename "$file")
    - Strips directory path
    - /tmp/script-lab/data/small.dat becomes small.dat
  
  • size=$(stat -c%s "$file")
    - stat command gets file info
    - -c%s outputs size in bytes
    - Stored in size variable
  
  • if [ $size -lt 102400 ]
    - Compare size to 100KB (100 * 1024 = 102400)
    - -lt means "less than"
  
  • elif [ $size -lt 10485760 ]
    - "else if" - checked if first condition was false
    - 10MB = 10 * 1024 * 1024 = 10485760 bytes
  
  • else
    - Catches everything else (larger than 10MB)

If-statement variations:
  # Simple if:
  if [ -f /etc/passwd ]; then
      echo "File exists"
  fi
  
  # If-else:
  if [ $count -gt 10 ]; then
      echo "More than 10"
  else
      echo "10 or less"
  fi
  
  # If-elif-else:
  if [ "$status" = "active" ]; then
      echo "Running"
  elif [ "$status" = "stopped" ]; then
      echo "Not running"
  else
      echo "Unknown status"
  fi

File test operators:
  -f file    file exists and is regular file
  -d dir     directory exists
  -e path    path exists (file or directory)
  -r file    file exists and is readable
  -w file    file exists and is writable
  -x file    file exists and is executable
  -s file    file exists and has size > 0
  -L link    path is a symbolic link

Numeric comparison operators:
  -eq    equal
  -ne    not equal
  -lt    less than
  -le    less than or equal
  -gt    greater than
  -ge    greater than or equal

String comparison:
  =      equal
  !=     not equal
  -z     string is empty
  -n     string is not empty

Logical operators:
  -a     AND (both conditions true)
  -o     OR (either condition true)
  !      NOT (invert condition)

Example combinations:
  # File exists AND is readable:
  if [ -f "$file" -a -r "$file" ]; then
      cat "$file"
  fi
  
  # Either condition:
  if [ "$user" = "root" -o "$user" = "admin" ]; then
      echo "Privileged user"
  fi
  
  # NOT condition:
  if [ ! -f "$file" ]; then
      echo "File does not exist"
  fi

Modern [[ ]] syntax (preferred in bash):
  # Pattern matching:
  if [[ $file == *.txt ]]; then
      echo "Text file"
  fi
  
  # Regex matching:
  if [[ $string =~ ^[0-9]+$ ]]; then
      echo "Number"
  fi
  
  # Safer with spaces:
  if [[ $var == "value with spaces" ]]; then
      echo "Match"
  fi

Verification:
  ls -l /tmp/script-lab/logs/*-category.txt
  cat /tmp/script-lab/logs/*.dat-category.txt

EOF
}

hint_step_4() {
    echo "  Chain with &&: mkdir dir && cd dir && touch file"
}

# STEP 4: Command chaining
show_step_4() {
    cat << 'EOF'
TASK: Use command chaining for error handling

Create a script that safely creates a backup directory structure,
handling errors at each step.

Requirements:
  • Script: /tmp/script-lab/scripts/safe-backup.sh
  • Create /tmp/script-lab/backups directory (if missing)
  • AND create subdirectory: backups/$(date +%Y-%m-%d)
  • AND create a file: backups/$(date +%Y-%m-%d)/backup.log
  • Use && to chain commands
  • If any step fails, subsequent steps don't run

Command chaining:
  command1 && command2      # Run cmd2 only if cmd1 succeeds
  command1 || command2      # Run cmd2 only if cmd1 fails
  command1 ; command2       # Run cmd2 regardless

What you're learning:
  Exit codes determine success (0) or failure (non-zero). Command
  chaining uses these codes for flow control without if statements.
EOF
}

validate_step_4() {
    if [ ! -f "/tmp/script-lab/scripts/safe-backup.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script not found"
        return 1
    fi
    
    if [ ! -x "/tmp/script-lab/scripts/safe-backup.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    # Check if directories were created
    if [ ! -d "/tmp/script-lab/backups" ]; then
        echo ""
        print_color "$RED" "✗ Backup directory not created"
        echo "  Run the script"
        return 1
    fi
    
    # Check if a dated subdirectory exists
    local dated_dir_count=$(find /tmp/script-lab/backups -maxdepth 1 -type d -name "????-??-??" 2>/dev/null | wc -l)
    if [ "$dated_dir_count" -lt 1 ]; then
        echo ""
        print_color "$RED" "✗ Dated backup directory not created"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:

cat > /tmp/script-lab/scripts/safe-backup.sh << 'SCRIPT'
#!/bin/bash
# Safe backup directory creator

mkdir -p /tmp/script-lab/backups && \
cd /tmp/script-lab/backups && \
mkdir $(date +%Y-%m-%d) && \
touch $(date +%Y-%m-%d)/backup.log && \
echo "Backup structure created successfully" || \
echo "Error creating backup structure"
SCRIPT

chmod +x /tmp/script-lab/scripts/safe-backup.sh
/tmp/script-lab/scripts/safe-backup.sh

Breaking it down:
  • mkdir -p /tmp/script-lab/backups
    - Create directory (and parents if needed)
    - -p prevents error if already exists
  
  • &&
    - "AND" operator
    - Runs next command ONLY if previous succeeded (exit code 0)
    - If previous failed, chain stops
  
  • cd /tmp/script-lab/backups
    - Only runs if mkdir succeeded
    - Changes to backup directory
  
  • mkdir $(date +%Y-%m-%d)
    - $(date +%Y-%m-%d) outputs: 2025-01-13
    - Creates directory with today's date
    - Only runs if cd succeeded
  
  • ||
    - "OR" operator
    - Runs if previous command FAILED
    - Used for error messages
  
  • \
    - Line continuation
    - Makes long command chains readable

Command chaining patterns:
  # Simple success chain:
  command1 && command2 && command3
  # Each only runs if previous succeeded
  
  # Error handling:
  command || echo "Command failed"
  
  # Both together:
  mkdir dir && cd dir || echo "Failed to create/enter directory"
  
  # Independent commands:
  command1 ; command2 ; command3
  # All run regardless of exit codes

Exit codes:
  # 0 = Success
  # 1-255 = Failure (different meanings)
  
  # Check last exit code:
  echo $?
  
  # Example:
  ls /nonexistent
  echo $?    # Shows non-zero (failure)
  
  ls /tmp
  echo $?    # Shows 0 (success)

Using exit codes in scripts:
  #!/bin/bash
  
  if mkdir /tmp/test 2>/dev/null; then
      echo "Directory created"
  else
      echo "Failed to create directory"
  fi
  
  # Same thing with && and ||:
  mkdir /tmp/test 2>/dev/null && \
      echo "Directory created" || \
      echo "Failed"

Complex chaining example:
  # Backup script with full error handling:
  mkdir -p /backup/$(date +%Y-%m-%d) && \
  tar czf /backup/$(date +%Y-%m-%d)/data.tar.gz /data 2>/dev/null && \
  chmod 600 /backup/$(date +%Y-%m-%d)/data.tar.gz && \
  echo "Backup successful" || \
  { echo "Backup failed"; exit 1; }
  
  # If ANY step fails, final echo runs and script exits

Short-circuit evaluation:
  # This pattern is common:
  [ -f config.txt ] || { echo "Config missing"; exit 1; }
  # If file doesn't exist, error and exit
  
  # Or for success:
  [ -f config.txt ] && echo "Config found"
  # Only echo if file exists

Verification:
  ls -R /tmp/script-lab/backups/
  # Should show dated directory with backup.log

Real-world examples:
  # Safe cd:
  cd /some/path || exit 1
  
  # Create and enter directory:
  mkdir project && cd project && git init
  
  # Download and extract:
  wget https://example.com/file.tar.gz && tar xzf file.tar.gz
  
  # Check service:
  systemctl is-active nginx && echo "Running" || echo "Stopped"

EOF
}

hint_step_5() {
    echo "  Combine loops and conditions: for f in *; do if [ -f \"\$f\" ]; then ...; fi; done"
}

# STEP 5: Combining loops and conditionals
show_step_5() {
    cat << 'EOF'
TASK: Create a file processor with multiple conditions

Write a script that processes files in /tmp/script-lab/data/ and:
  - Skips non-regular files (directories, etc.)
  - For .txt files: echo "Text: $filename" >> logs/processed.log
  - For .dat files: echo "Data: $filename" >> logs/processed.log
  - For other files: echo "Other: $filename" >> logs/processed.log

Requirements:
  • Script: /tmp/script-lab/scripts/file-processor.sh
  • Loop through /tmp/script-lab/data/*
  • Use if statements to check file types
  • Use [[ ]] for pattern matching
  • Output to: /tmp/script-lab/logs/processed.log

Pattern matching with [[ ]]:
  if [[ $filename == *.txt ]]; then
      echo "Text file"
  fi

What you're learning:
  Real scripts combine loops, conditionals, and tests to handle
  complex scenarios. This pattern processes collections of items
  with different logic for each type.
EOF
}

validate_step_5() {
    if [ ! -f "/tmp/script-lab/scripts/file-processor.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script not found"
        return 1
    fi
    
    if [ ! -x "/tmp/script-lab/scripts/file-processor.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    if [ ! -f "/tmp/script-lab/logs/processed.log" ]; then
        echo ""
        print_color "$RED" "✗ processed.log not created"
        echo "  Run the script"
        return 1
    fi
    
    # Check if log contains expected entries
    if ! grep -q "Text:" /tmp/script-lab/logs/processed.log 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ No Text: entries in processed.log"
        return 1
    fi
    
    if ! grep -q "Data:" /tmp/script-lab/logs/processed.log 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ No Data: entries in processed.log"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:

cat > /tmp/script-lab/scripts/file-processor.sh << 'SCRIPT'
#!/bin/bash
# File type processor

# Clear previous log
> /tmp/script-lab/logs/processed.log

for path in /tmp/script-lab/data/*; do
    # Skip if not a regular file
    [ ! -f "$path" ] && continue
    
    # Get just the filename
    filename=$(basename "$path")
    
    # Check file type and process accordingly
    if [[ $filename == *.txt ]]; then
        echo "Text: $filename" >> /tmp/script-lab/logs/processed.log
    elif [[ $filename == *.dat ]]; then
        echo "Data: $filename" >> /tmp/script-lab/logs/processed.log
    else
        echo "Other: $filename" >> /tmp/script-lab/logs/processed.log
    fi
done

echo "Processing complete. Check /tmp/script-lab/logs/processed.log"
SCRIPT

chmod +x /tmp/script-lab/scripts/file-processor.sh
/tmp/script-lab/scripts/file-processor.sh

Breaking it down:
  • > /tmp/script-lab/logs/processed.log
    - Clears the log file
    - Creates it if doesn't exist
    - Ensures fresh start
  
  • for path in /tmp/script-lab/data/*
    - Loop through all items in data/
    - Includes files and directories
  
  • [ ! -f "$path" ] && continue
    - Test if NOT a regular file
    - continue skips to next iteration
    - This filters out directories
  
  • [[ $filename == *.txt ]]
    - Double bracket syntax
    - Allows pattern matching with ==
    - No need to quote the pattern
  
  • elif [[ $filename == *.dat ]]
    - Second condition (if first was false)
    - Checks for .dat extension
  
  • else
    - Catches everything else

Key concepts:
  • continue statement
    - Skips current iteration
    - Jumps to next loop iteration
    - Used to filter unwanted items
  
  • break statement (not used here but useful)
    - Exits loop entirely
    - Useful when search condition met
  
  • [[ ]] vs [ ]
    - [[ ]] is bash-specific enhancement
    - Allows pattern matching
    - Safer with variables (less quoting needed)
    - Supports && and || inside

Pattern matching examples:
  # File extensions:
  [[ $file == *.txt ]]
  [[ $file == *.log ]] || [[ $file == *.txt ]]
  
  # Starts with:
  [[ $file == log* ]]
  
  # Contains:
  [[ $file == *backup* ]]
  
  # Multiple patterns:
  [[ $file == *.txt || $file == *.md ]]

Loop control statements:
  # continue - skip to next iteration:
  for i in {1..10}; do
      [ $i -eq 5 ] && continue
      echo $i    # Prints 1,2,3,4,6,7,8,9,10 (skips 5)
  done
  
  # break - exit loop:
  for i in {1..10}; do
      [ $i -eq 5 ] && break
      echo $i    # Prints 1,2,3,4 then stops
  done

Real-world pattern - processing with filters:
  #!/bin/bash
  # Process log files, skip archives
  
  for file in /var/log/*; do
      # Skip if not regular file
      [ ! -f "$file" ] && continue
      
      # Skip if archived (gzipped)
      [[ $file == *.gz ]] && continue
      
      # Skip if empty
      [ ! -s "$file" ] && continue
      
      # Process the file
      echo "Processing $file"
      grep "ERROR" "$file" >> /tmp/errors.log
  done

Combining multiple conditions:
  for user in $(cut -d: -f1 /etc/passwd); do
      # Skip system users (UID < 1000)
      uid=$(id -u "$user" 2>/dev/null)
      [ -z "$uid" ] && continue
      [ $uid -lt 1000 ] && continue
      
      # Skip if no home directory
      home=$(eval echo ~"$user")
      [ ! -d "$home" ] && continue
      
      # Process regular user with home directory
      echo "User: $user (UID: $uid, Home: $home)"
  done

Verification:
  cat /tmp/script-lab/logs/processed.log
  # Should show:
  # Text: file01.txt
  # Text: file02.txt
  # ...
  # Data: small.dat
  # Data: medium.dat
  # Data: large.dat
  # Other: servers.txt
  # etc.

EOF
}

hint_step_6() {
    echo "  Use tar czf backup-\$(date +%Y%m%d-%H%M%S).tar.gz to create timestamped archive"
}

# STEP 6: Complete automation script
show_step_6() {
    cat << 'EOF'
TASK: Create a comprehensive backup script

Write a production-ready backup script that:
  1. Creates timestamped backup directory
  2. Checks if source exists
  3. Creates tar.gz archive with timestamp
  4. Validates archive was created
  5. Reports success or failure

Requirements:
  • Script: /tmp/script-lab/scripts/backup.sh
  • Backup /tmp/script-lab/data to /tmp/script-lab/backups/
  • Format: backup-YYYYMMDD-HHMMSS.tar.gz
  • Include error checking at each step
  • Final message: "Backup completed" or "Backup failed"

Commands needed:
  • date +%Y%m%d-%H%M%S for timestamp
  • tar czf to create compressed archive
  • if statements for validation
  • && and || for flow control

What you're learning:
  Production scripts need robust error handling. This combines all
  the concepts: variables, conditionals, command substitution, and
  error handling into a reliable automation tool.
EOF
}

validate_step_6() {
    if [ ! -f "/tmp/script-lab/scripts/backup.sh" ]; then
        echo ""
        print_color "$RED" "✗ Backup script not found"
        return 1
    fi
    
    if [ ! -x "/tmp/script-lab/scripts/backup.sh" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    # Check if any backup file was created
    local backup_count=$(ls /tmp/script-lab/backups/backup-*.tar.gz 2>/dev/null | wc -l)
    if [ "$backup_count" -lt 1 ]; then
        echo ""
        print_color "$RED" "✗ No backup archive found"
        echo "  Run the script to create backup"
        return 1
    fi
    
    # Verify archive is not empty
    local backup_file=$(ls -t /tmp/script-lab/backups/backup-*.tar.gz 2>/dev/null | head -1)
    if [ -n "$backup_file" ]; then
        local size=$(stat -c%s "$backup_file" 2>/dev/null || echo 0)
        if [ "$size" -lt 100 ]; then
            echo ""
            print_color "$RED" "✗ Backup archive seems empty or corrupt"
            return 1
        fi
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Create the script:

cat > /tmp/script-lab/scripts/backup.sh << 'SCRIPT'
#!/bin/bash
# Production backup script

# Variables
SOURCE_DIR="/tmp/script-lab/data"
BACKUP_DIR="/tmp/script-lab/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="backup-${TIMESTAMP}.tar.gz"

# Validation
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# Create backup directory if needed
mkdir -p "$BACKUP_DIR" || {
    echo "ERROR: Failed to create backup directory"
    exit 1
}

# Create backup
echo "Creating backup of $SOURCE_DIR..."
tar czf "${BACKUP_DIR}/${BACKUP_FILE}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null

# Verify backup was created
if [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    SIZE=$(stat -c%s "${BACKUP_DIR}/${BACKUP_FILE}")
    echo "✓ Backup completed successfully"
    echo "  File: ${BACKUP_FILE}"
    echo "  Size: ${SIZE} bytes"
    exit 0
else
    echo "✗ ERROR: Backup failed"
    exit 1
fi
SCRIPT

chmod +x /tmp/script-lab/scripts/backup.sh
/tmp/script-lab/scripts/backup.sh

Breaking it down:
  • Variables at the top
    - Makes script configurable
    - Easy to modify paths
    - TIMESTAMP captures current time
  
  • First validation block
    - Checks if source exists
    - Exits with error code 1 if not
    - exit 1 signals failure to calling script
  
  • mkdir -p "$BACKUP_DIR" || { ... }
    - Create backup dir
    - || block executes if mkdir fails
    - { } groups multiple commands
    - exit 1 stops script
  
  • tar czf
    - c: create archive
    - z: compress with gzip
    - f: filename follows
    - -C: change to directory
    - Captures dirname/basename for clean archive
  
  • Final validation
    - Checks if backup file exists
    - Reports size
    - Different exit codes for success/failure

Script best practices:
  • Use variables for paths and values
  • Validate inputs and prerequisites
  • Check each critical step
  • Provide clear error messages
  • Use appropriate exit codes
  • Add comments for complex logic
  • Quote all variables

Exit codes convention:
  0    Success
  1    General error
  2    Misuse of command
  126  Command cannot execute
  127  Command not found
  130  Script terminated by Ctrl+C

Using exit codes:
  # In calling script:
  if /path/to/backup.sh; then
      echo "Backup successful"
  else
      echo "Backup failed"
  fi
  
  # Or with &&:
  /path/to/backup.sh && echo "Success" || echo "Failed"

Production enhancements:
  # Add logging:
  LOG="/var/log/backup.log"
  exec 1>> "$LOG" 2>&1    # Redirect all output to log
  
  # Add email notification:
  if ! /path/to/backup.sh; then
      echo "Backup failed" | mail -s "Backup Error" admin@example.com
  fi
  
  # Add retention (keep last 7 days):
  find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +7 -delete
  
  # Add remote copy:
  scp "${BACKUP_DIR}/${BACKUP_FILE}" backup-server:/backups/
  
  # Add integrity check:
  tar tzf "$BACKUP_FILE" >/dev/null || {
      echo "Archive corrupted"
      exit 1
  }

Complete production script pattern:
  #!/bin/bash
  set -euo pipefail    # Exit on error, undefined vars, pipe failures
  
  # Configuration
  SOURCE="/data"
  DEST="/backup"
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  LOG="/var/log/backup.log"
  
  # Logging function
  log() {
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
  }
  
  # Main backup function
  perform_backup() {
      log "Starting backup..."
      
      if ! tar czf "${DEST}/backup-${TIMESTAMP}.tar.gz" "$SOURCE"; then
          log "ERROR: Backup failed"
          return 1
      fi
      
      log "SUCCESS: Backup completed"
      return 0
  }
  
  # Cleanup old backups
  cleanup_old() {
      log "Cleaning up old backups..."
      find "$DEST" -name "backup-*.tar.gz" -mtime +7 -delete
  }
  
  # Main execution
  perform_backup && cleanup_old || {
      log "Backup process failed"
      exit 1
  }

Verification:
  ls -lh /tmp/script-lab/backups/
  # Should show backup-YYYYMMDD-HHMMSS.tar.gz
  
  tar tzf /tmp/script-lab/backups/backup-*.tar.gz | head
  # Lists contents to verify

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your bash scripting work..."
    echo ""
    
    # Check 1: For-loop script
    print_color "$CYAN" "[1/$total] Checking for-loop (server-check.sh)..."
    if [ -x "/tmp/script-lab/scripts/server-check.sh" ]; then
        local log_count=$(ls /tmp/script-lab/logs/*-status.txt 2>/dev/null | wc -l)
        if [ "$log_count" -ge 5 ]; then
            print_color "$GREEN" "  ✓ For-loop script working ($log_count status files created)"
            ((score++))
        else
            print_color "$RED" "  ✗ Script exists but not all log files created"
        fi
    else
        print_color "$RED" "  ✗ server-check.sh not found or not executable"
        print_color "$YELLOW" "  Create script with for-loop processing servers.txt"
    fi
    echo ""
    
    # Check 2: While loop script
    print_color "$CYAN" "[2/$total] Checking while-loop (countdown.sh)..."
    if [ -x "/tmp/script-lab/scripts/countdown.sh" ]; then
        local count_files=0
        for i in {1..5}; do
            [ -f "/tmp/script-lab/logs/count-$i.txt" ] && ((count_files++))
        done
        if [ "$count_files" -eq 5 ]; then
            print_color "$GREEN" "  ✓ While-loop countdown working correctly"
            ((score++))
        else
            print_color "$RED" "  ✗ Missing countdown files ($count_files/5)"
        fi
    else
        print_color "$RED" "  ✗ countdown.sh not found or not executable"
    fi
    echo ""
    
    # Check 3: If-else script
    print_color "$CYAN" "[3/$total] Checking if-else (size-check.sh)..."
    if [ -x "/tmp/script-lab/scripts/size-check.sh" ]; then
        if [ -f "/tmp/script-lab/logs/small.dat-category.txt" ] && \
           [ -f "/tmp/script-lab/logs/medium.dat-category.txt" ] && \
           [ -f "/tmp/script-lab/logs/large.dat-category.txt" ]; then
            print_color "$GREEN" "  ✓ File categorization working"
            ((score++))
        else
            print_color "$RED" "  ✗ Not all category files created"
        fi
    else
        print_color "$RED" "  ✗ size-check.sh not found or not executable"
    fi
    echo ""
    
    # Check 4: Command chaining
    print_color "$CYAN" "[4/$total] Checking command chaining (safe-backup.sh)..."
    if [ -x "/tmp/script-lab/scripts/safe-backup.sh" ]; then
        if [ -d "/tmp/script-lab/backups" ]; then
            local dated=$(find /tmp/script-lab/backups -maxdepth 1 -type d -name "????-??-??" | wc -l)
            if [ "$dated" -ge 1 ]; then
                print_color "$GREEN" "  ✓ Command chaining with && working"
                ((score++))
            else
                print_color "$RED" "  ✗ Dated directory not created"
            fi
        else
            print_color "$RED" "  ✗ Backup directory not created"
        fi
    else
        print_color "$RED" "  ✗ safe-backup.sh not found or not executable"
    fi
    echo ""
    
    # Check 5: Combined loops and conditions
    print_color "$CYAN" "[5/$total] Checking combined logic (file-processor.sh)..."
    if [ -x "/tmp/script-lab/scripts/file-processor.sh" ]; then
        if [ -f "/tmp/script-lab/logs/processed.log" ]; then
            if grep -q "Text:" /tmp/script-lab/logs/processed.log && \
               grep -q "Data:" /tmp/script-lab/logs/processed.log; then
                print_color "$GREEN" "  ✓ File processing with conditions working"
                ((score++))
            else
                print_color "$RED" "  ✗ processed.log missing expected entries"
            fi
        else
            print_color "$RED" "  ✗ processed.log not created"
        fi
    else
        print_color "$RED" "  ✗ file-processor.sh not found or not executable"
    fi
    echo ""
    
    # Check 6: Complete backup script
    print_color "$CYAN" "[6/$total] Checking backup script..."
    if [ -x "/tmp/script-lab/scripts/backup.sh" ]; then
        local backup_count=$(ls /tmp/script-lab/backups/backup-*.tar.gz 2>/dev/null | wc -l)
        if [ "$backup_count" -ge 1 ]; then
            local backup=$(ls -t /tmp/script-lab/backups/backup-*.tar.gz 2>/dev/null | head -1)
            local size=$(stat -c%s "$backup" 2>/dev/null || echo 0)
            if [ "$size" -gt 100 ]; then
                print_color "$GREEN" "  ✓ Complete backup script working"
                ((score++))
            else
                print_color "$RED" "  ✗ Backup file too small or corrupt"
            fi
        else
            print_color "$RED" "  ✗ No backup archive created"
        fi
    else
        print_color "$RED" "  ✗ backup.sh not found or not executable"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Outstanding! You've mastered:"
        echo "  • For-loops for list processing"
        echo "  • While-loops with counters"
        echo "  • If-then-else conditional logic"
        echo "  • Test operators and file checks"
        echo "  • Command chaining with && and ||"
        echo "  • Production-ready automation scripts"
        echo ""
        echo "You can now automate complex system administration tasks!"
    elif [ $score -ge 4 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're on the right track! Review failed sections."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Scripting takes practice. Review with --solution."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This lab covers the fundamental building blocks of bash scripting:
loops, conditionals, tests, and command chaining.


FOR-LOOPS: Processing Lists
─────────────────────────────────────────────────────────────────
Basic syntax:
  for variable in list; do
      commands
  done

Variations:
  # Explicit list:
  for color in red green blue; do echo $color; done
  
  # File glob:
  for file in *.txt; do echo $file; done
  
  # Command output:
  for user in $(cut -d: -f1 /etc/passwd); do echo $user; done
  
  # Range:
  for i in {1..10}; do echo $i; done
  
  # C-style:
  for ((i=1; i<=10; i++)); do echo $i; done


WHILE-LOOPS: Conditional Repetition
─────────────────────────────────────────────────────────────────
Basic syntax:
  while condition; do
      commands
  done

Patterns:
  # Counter:
  i=1
  while [ $i -le 10 ]; do
      echo $i
      i=$((i+1))
  done
  
  # Read file:
  while read -r line; do
      echo "$line"
  done < file.txt
  
  # Infinite with break:
  while true; do
      read -p "Continue? " answer
      [ "$answer" = "no" ] && break
  done


IF-THEN-ELSE: Conditional Execution
─────────────────────────────────────────────────────────────────
Basic syntax:
  if condition; then
      commands
  elif condition; then
      commands
  else
      commands
  fi

Test operators:
  # Files:
  -f file    regular file exists
  -d dir     directory exists
  -e path    path exists
  -r/-w/-x   readable/writable/executable
  -s file    file has size > 0
  
  # Numbers:
  -eq -ne -lt -le -gt -ge
  
  # Strings:
  = != -z -n
  
  # Logic:
  -a (AND)  -o (OR)  ! (NOT)


COMMAND CHAINING: Flow Control
─────────────────────────────────────────────────────────────────
Operators:
  &&    AND (run if previous succeeded)
  ||    OR (run if previous failed)
  ;     separator (run regardless)

Examples:
  mkdir dir && cd dir && touch file
  command || echo "Failed"
  cmd1 ; cmd2 ; cmd3


PRACTICAL PATTERNS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Processing files with filtering:
  for file in /path/*; do
      [ ! -f "$file" ] && continue
      [[ $file == *.txt ]] || continue
      # Process text files only
  done

Safe operations:
  mkdir -p /backup && \
  tar czf /backup/data.tar.gz /data && \
  echo "Success" || echo "Failed"

Validation before action:
  if [ ! -d "$SOURCE" ]; then
      echo "Source missing"
      exit 1
  fi

Reading user input:
  while true; do
      read -p "Enter choice: " choice
      case $choice in
          1) echo "Option 1";;
          2) echo "Option 2";;
          q) break;;
          *) echo "Invalid";;
      esac
  done


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Test on command line first:
   for i in {1..5}; do echo $i; done

2. Always quote variables in tests:
   [ "$var" = "value" ]

3. Use [[ ]] for pattern matching:
   [[ $file == *.txt ]]

4. Check exit codes:
   echo $?

5. Use set -x for debugging:
   #!/bin/bash
   set -x    # Print each command

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/script-lab 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

# Execute the main framework
main "$@"
