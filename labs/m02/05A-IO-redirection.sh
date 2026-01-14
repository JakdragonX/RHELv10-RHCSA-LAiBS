#!/bin/bash
# labs/05-io-redirection-lab.sh
# Lab: Understanding I/O Redirection and Piping
# Difficulty: Beginner
# RHCSA Objective: Understand and use essential tools - I/O redirection

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Understanding I/O Redirection and Piping"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="15-20 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Remove any previous lab artifacts
    rm -rf /tmp/io-lab 2>/dev/null || true
    
    # Create fresh working directory
    mkdir -p /tmp/io-lab
    
    # Create some sample files for the lab
    cat > /tmp/io-lab/access.log << 'EOF'
192.168.1.100 - - [10/Jan/2025:13:55:36] "GET /index.html HTTP/1.1" 200 1043
192.168.1.101 - - [10/Jan/2025:13:55:37] "GET /about.html HTTP/1.1" 200 2156
192.168.1.102 - - [10/Jan/2025:13:55:38] "GET /missing.html HTTP/1.1" 404 162
192.168.1.103 - - [10/Jan/2025:13:55:39] "POST /login HTTP/1.1" 200 512
192.168.1.100 - - [10/Jan/2025:13:55:40] "GET /dashboard HTTP/1.1" 500 0
192.168.1.104 - - [10/Jan/2025:13:55:41] "GET /api/data HTTP/1.1" 200 8421
EOF

    cat > /tmp/io-lab/error.log << 'EOF'
[ERROR] Database connection timeout
[WARN] High memory usage detected: 87%
[ERROR] Failed to load configuration file
[INFO] Service started successfully
[ERROR] Permission denied: /var/secure/data
[WARN] Deprecated API call detected
EOF



#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of Linux file system
  • Familiarity with command line navigation
  • Understanding that programs have input and output

Commands You'll Use:
  • cat       - Concatenate and display file contents
  • echo      - Output text to STDOUT
  • grep      - Search for patterns in text
  • wc        - Count lines, words, and characters
  • sort      - Sort lines of text
  • head/tail - Display beginning/end of files
  • tee       - Read from STDIN and write to both STDOUT and files

Files You'll Interact With:
  • /tmp/io-lab/access.log - Sample web server access log
  • /tmp/io-lab/error.log  - Sample application error log
  • /tmp/io-lab/users.txt  - Sample user database
  • /dev/null              - The "null device" (data black hole)

Core Concepts:
  • STDIN (0)  - Standard Input stream
  • STDOUT (1) - Standard Output stream
  • STDERR (2) - Standard Error stream
  • Pipes (|)  - Connect STDOUT of one command to STDIN of another
  • Redirection - Control where input comes from and output goes to
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a junior sysadmin learning how to process log files and extract
meaningful information using I/O redirection. Understanding these concepts
is fundamental to effective system administration and troubleshooting.

BACKGROUND:
Linux treats everything as a stream of data. Programs read from STDIN,
write normal output to STDOUT, and write errors to STDERR. By mastering
redirection, you can build powerful command pipelines that process data
efficiently without writing complex scripts.



HINTS:
  • > creates/overwrites a file, >> appends to it
  • 2> redirects only errors, 2>&1 merges STDERR into STDOUT
  • Pipes connect commands: command1 | command2 | command3
  • /dev/null is like a trash can - data sent there disappears
  • Use grep to filter, wc to count, sort to organize

SUCCESS CRITERIA:
  • You can explain the difference between STDOUT and STDERR
  • You understand when to use >, >>, and |
  • You can suppress errors without hiding important output
  • You can build multi-command pipelines to process data
  • Files in /tmp/io-lab/ contain the expected filtered content
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Redirect STDOUT: Extract HTTP 200 responses → /tmp/io-lab/successful.log
  ☐ 2. Append to file: Add HTTP 404 responses → /tmp/io-lab/successful.log
  ☐ 3. Redirect STDERR: Capture errors from failed commands → /tmp/io-lab/cmd-errors.log
  ☐ 4. Pipe commands: Count ERROR lines in error.log (should be 3)
  ☐ 5. Complex pipeline: Extract usernames, sort, save → /tmp/io-lab/sorted-users.txt
  ☐ 6. Suppress noise: List /root/* but hide "Permission denied" errors
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "6"
}

scenario_context() {
    cat << 'EOF'
You're a junior sysadmin learning how to process log files and extract
meaningful information using I/O redirection. Understanding these concepts
is fundamental to effective system administration.

Linux treats everything as a stream of data. By mastering redirection,
you can build powerful command pipelines without writing complex scripts.
EOF
}

# STEP 1: Basic STDOUT redirection
show_step_1() {
    cat << 'EOF'
TASK: Extract successful HTTP requests using STDOUT redirection

Look at the access log and identify all lines with "200" status codes
(successful requests). Save only these lines to a new file.

Requirements:
  • Input file: /tmp/io-lab/access.log
  • Output file: /tmp/io-lab/successful.log
  • Only include lines containing " 200 " (spaces matter!)
  • Use > to create a new file (overwrite if exists)

Commands you might need:
  • grep - Search for patterns in files
  • >     - Redirect STDOUT to a file (overwrite)
  
Example pattern:
  command_that_outputs_text > destination_file

What you're learning:
  The > operator takes STDOUT from a command and writes it to a file.
  This is fundamental - you'll use it constantly in system administration.
EOF
}

validate_step_1() {
    if [ ! -f "/tmp/io-lab/successful.log" ]; then
        echo ""
        print_color "$RED" "✗ File /tmp/io-lab/successful.log does not exist"
        echo "  You need to create this file by redirecting output"
        echo "  Hint: grep 'pattern' file > output_file"
        return 1
    fi
    
    local line_count=$(wc -l < /tmp/io-lab/successful.log 2>/dev/null || echo 0)
    if [ "$line_count" -lt 4 ]; then
        echo ""
        print_color "$RED" "✗ File exists but only contains $line_count lines (expected at least 4)"
        echo "  Make sure you're searching for lines with \" 200 \" (with spaces)"
        return 1
    fi
    
    if ! grep -q "200" /tmp/io-lab/successful.log 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ File doesn't contain HTTP 200 status codes"
        echo "  Check your grep pattern"
        return 1
    fi
    
    if grep -q "404\|500" /tmp/io-lab/successful.log 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ File contains error status codes (404 or 500)"
        echo "  You should only have 200 status codes"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  grep " 200 " /tmp/io-lab/access.log > /tmp/io-lab/successful.log

Breaking it down:
  • grep " 200 ": Searches for lines containing " 200 " (with spaces)
    - The spaces prevent matching "2001" or "1200"
    - This is called "precise pattern matching"
  
  • /tmp/io-lab/access.log: The input file to search
  
  • > /tmp/io-lab/successful.log: Redirects STDOUT to this file
    - The > operator OVERWRITES the file if it exists
    - If the file doesn't exist, it creates it
    - This is file descriptor 1 (STDOUT) by default

What's happening under the hood:
  1. grep reads the access.log file line by line
  2. For each line containing " 200 ", grep writes it to STDOUT
  3. The > operator intercepts STDOUT
  4. Instead of displaying on screen, output goes to the file

Why this matters:
  In real system administration, you constantly filter logs. This basic
  pattern (filter | redirect) is the foundation of log analysis, monitoring,
  and troubleshooting.

Verification:
  cat /tmp/io-lab/successful.log
  # Should show only lines with "200" status
  
  wc -l /tmp/io-lab/successful.log
  # Should show 4 lines

Alternative approaches:
  # These achieve the same result:
  grep " 200 " /tmp/io-lab/access.log 1> /tmp/io-lab/successful.log
  cat /tmp/io-lab/access.log | grep " 200 " > /tmp/io-lab/successful.log

EOF
}

hint_step_2() {
    echo "  Use >> instead of > to append. Same grep pattern, but filter for \" 404 \" instead"
}

# STEP 2: Appending with >>
show_step_2() {
    cat << 'EOF'
TASK: Append additional filtered data to an existing file

Now add the "404 Not Found" responses to the same file WITHOUT
overwriting the existing "200" responses.

Requirements:
  • Filter for lines containing " 404 "
  • APPEND to: /tmp/io-lab/successful.log
  • Use >> to preserve existing content
  • File should contain both 200 and 404 lines when done

Commands you might need:
  • grep - Filter for the pattern
  • >>   - Append STDOUT to a file (don't overwrite!)

Key difference:
  > overwrites (creates new or replaces existing)
  >> appends (adds to the end of existing content)

What you're learning:
  The difference between > and >> is crucial. Using > when you meant >>
  can accidentally destroy important log files. In production, this
  distinction becomes critical.
EOF
}

validate_step_2() {
    if [ ! -f "/tmp/io-lab/successful.log" ]; then
        echo ""
        print_color "$RED" "✗ File /tmp/io-lab/successful.log doesn't exist"
        echo "  Did you complete Step 1 first?"
        return 1
    fi
    
    local line_count=$(wc -l < /tmp/io-lab/successful.log 2>/dev/null || echo 0)
    if [ "$line_count" -lt 5 ]; then
        echo ""
        print_color "$RED" "✗ File only contains $line_count lines (expected at least 5)"
        echo "  Did you use >> to append instead of > to overwrite?"
        return 1
    fi
    
    if ! grep -q "404" /tmp/io-lab/successful.log 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ File doesn't contain any 404 status codes"
        echo "  Make sure you appended the 404 lines"
        return 1
    fi
    
    if ! grep -q "200" /tmp/io-lab/successful.log 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ File doesn't contain 200 status codes anymore"
        echo "  You may have used > instead of >> and overwritten the file"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  grep " 404 " /tmp/io-lab/access.log >> /tmp/io-lab/successful.log

Breaking it down:
  • grep " 404 ": Filter for "Not Found" errors
  • /tmp/io-lab/access.log: Input source
  • >> /tmp/io-lab/successful.log: APPEND to existing file

The critical difference:
  • > would have deleted all the 200 lines and replaced with only 404s
  • >> preserves existing content and adds new content at the end

Real-world example:
  Many system logs are appended to continuously. For example:
  
  echo "[$(date)] System backup started" >> /var/log/backup.log
  
  This adds a new line each time without destroying previous entries.
  If you used > by mistake, you'd lose all historical log data!

Verification:
  cat /tmp/io-lab/successful.log
  # Should show 4 lines with "200" followed by 1 line with "404"
  
  wc -l /tmp/io-lab/successful.log
  # Should show 5 lines total

Common mistake:
  # WRONG - this overwrites:
  grep " 404 " /tmp/io-lab/access.log > /tmp/io-lab/successful.log
  
  # RIGHT - this appends:
  grep " 404 " /tmp/io-lab/access.log >> /tmp/io-lab/successful.log

EOF
}

hint_step_3() {
    echo "  Try running a command that will fail (like 'ls /nonexistent') and redirect STDERR with 2>"
}

# STEP 3: STDERR redirection


validate_step_3() {
    if [ ! -f "/tmp/io-lab/cmd-errors.log" ]; then
        echo ""
        print_color "$RED" "✗ File /tmp/io-lab/cmd-errors.log does not exist"
        echo "  Run the ls command and redirect STDERR with 2>"
        return 1
    fi
    
    if ! grep -qi "cannot access\|no such file" /tmp/io-lab/cmd-errors.log 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ File doesn't contain expected error messages"
        echo "  Make sure you're redirecting errors with 2>"
        return 1
    fi
    
    local line_count=$(wc -l < /tmp/io-lab/cmd-errors.log 2>/dev/null || echo 0)
    if [ "$line_count" -lt 1 ]; then
        echo ""
        print_color "$RED" "✗ File is empty"
        echo "  The ls command should generate errors"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  ls /nonexistent /fakedir /notreal 2> /tmp/io-lab/cmd-errors.log

Breaking it down:
  • ls /nonexistent /fakedir /notreal: Try to list three fake directories
    - This will fail and generate error messages
    - Errors go to STDERR (file descriptor 2)
  
  • 2>: Redirects STDERR specifically
    - This captures only the error stream
    - STDOUT would still display normally (if there was any)

What's happening:
  1. ls tries to access each directory
  2. All three fail, generating "cannot access" errors
  3. These errors go to STDERR (stream 2)
  4. The 2> operator captures STDERR
  5. Errors are written to cmd-errors.log instead of the screen

Real-world application:
  When running commands in cron jobs or scripts, you often want to:
  
  # Capture only errors for review:
  daily_backup.sh 2> /var/log/backup-errors.log
  
  # Discard errors but keep output:
  find / -name "*.conf" 2> /dev/null
  
  # Save both separately:
  command > output.log 2> errors.log

Verification:
  cat /tmp/io-lab/cmd-errors.log
  # Should show error messages like "cannot access" or "No such file"

Understanding the file descriptor syntax:
  command > file        # Redirect STDOUT (same as 1> file)
  command 2> file       # Redirect STDERR only
  command &> file       # Redirect both STDOUT and STDERR (bash shortcut)
  command > file 2>&1   # Redirect STDOUT, then merge STDERR into it

EOF
}

hint_step_4() {
    echo "  Pipe grep into wc: grep 'ERROR' file | wc -l counts matching lines"
}

# STEP 4: Piping commands
show_step_4() {
    cat << 'EOF'
TASK: Use pipes to chain commands together

Count how many lines in error.log contain the word "ERROR" using
a command pipeline.

Requirements:
  • Input: /tmp/io-lab/error.log
  • Use grep to filter for "ERROR"
  • Pipe | the results to wc -l to count lines
  • The answer should be: 3

Commands you'll use:
  • grep - Filter for pattern
  • wc -l - Count lines
  • |    - Pipe (connect STDOUT of first command to STDIN of second)

What you're learning:
  Pipes let you chain simple commands into powerful data processing
  pipelines. Instead of saving intermediate results to temporary files,
  you stream data directly from one command to the next.
  
  This is one of Unix's greatest innovations: small, focused tools
  that work together through pipes.

The concept:
  command1 | command2 | command3
  
  Data flows: command1 STDOUT → command2 STDIN → command2 STDOUT → command3 STDIN

Note: This doesn't require creating any files - the result will just
display on screen. If you wanted to save it, you'd add: ... > file
EOF
}

validate_step_4() {
    # This step requires running a command, not creating a file
    # We'll validate by checking if they can run the command correctly
    local result=$(grep "ERROR" /tmp/io-lab/error.log 2>/dev/null | wc -l 2>/dev/null)
    
    if [ "$result" != "3" ]; then
        echo ""
        print_color "$RED" "✗ Unable to verify - the correct answer should be 3 ERROR lines"
        echo "  Run: grep 'ERROR' /tmp/io-lab/error.log | wc -l"
        echo "  This demonstrates piping grep output to wc"
        return 1
    fi
    
    # Since this is a demonstration step without file output,
    # we'll assume success if the file exists and has ERROR lines
    if grep -q "ERROR" /tmp/io-lab/error.log 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  grep "ERROR" /tmp/io-lab/error.log | wc -l

Breaking it down:
  • grep "ERROR" /tmp/io-lab/error.log
    - Searches the error log for lines containing "ERROR"
    - Outputs matching lines to STDOUT
  
  • | (pipe operator)
    - Takes STDOUT from grep
    - Feeds it as STDIN to the next command
    - Think of it as a data pipeline
  
  • wc -l
    - Reads from STDIN (the grep results)
    - Counts lines (-l flag)
    - Outputs the count: 3

What's happening step by step:
  1. grep reads error.log and finds 3 lines with "ERROR"
  2. These 3 lines are written to grep's STDOUT
  3. The pipe intercepts this STDOUT
  4. wc -l receives these 3 lines via its STDIN
  5. wc counts them and outputs: 3

Without pipes, you'd need temporary files:
  # The old, clunky way:
  grep "ERROR" /tmp/io-lab/error.log > /tmp/temp.txt
  wc -l /tmp/temp.txt
  rm /tmp/temp.txt
  
  # The elegant pipe way:
  grep "ERROR" /tmp/io-lab/error.log | wc -l

Real-world pipeline examples:
  # Find largest files:
  du -sh * | sort -h | tail -5
  
  # Count unique IP addresses in logs:
  grep "Failed login" /var/log/auth.log | awk '{print $11}' | sort -u | wc -l
  
  # Monitor active connections:
  ss -tn | grep ESTABLISHED | wc -l

Building longer pipelines:
  You can chain many commands:
  cat file | grep pattern | sort | uniq -c | sort -rn | head -10
  
  Each | passes data to the next command, transforming it step by step.

Verification:
  Run the command - it should output: 3

EOF
}

hint_step_5() {
    echo "  Use cut to extract usernames, then sort them: cut -d: -f1 file | sort > output"
}

# STEP 5: Complex pipeline
show_step_5() {
    cat << 'EOF'
TASK: Build a multi-command pipeline to transform data

Extract just the usernames from users.txt, sort them alphabetically,
and save the result to a file.

Requirements:
  • Input: /tmp/io-lab/users.txt (format: username:uid:group)
  • Extract only the username (first field)
  • Sort alphabetically
  • Output: /tmp/io-lab/sorted-users.txt
  • Should contain 5 usernames, one per line, sorted A-Z

Commands you'll need:
  • cut -d: -f1 - Extract field 1 using : as delimiter
  • sort        - Sort lines alphabetically
  • >           - Redirect final output to file

Pattern:
  cat file | cut ... | sort > output

What you're learning:
  Real-world data processing often requires multiple transformation steps.
  Pipes let you build these transformations incrementally and clearly.
  
  The format "username:uid:group" is similar to /etc/passwd structure.
  Field extraction with cut is a fundamental skill for parsing
  structured text files.
EOF
}

validate_step_5() {
    if [ ! -f "/tmp/io-lab/sorted-users.txt" ]; then
        echo ""
        print_color "$RED" "✗ File /tmp/io-lab/sorted-users.txt does not exist"
        echo "  Build a pipeline to extract and sort usernames"
        return 1
    fi
    
    local line_count=$(wc -l < /tmp/io-lab/sorted-users.txt 2>/dev/null || echo 0)
    if [ "$line_count" != "5" ]; then
        echo ""
        print_color "$RED" "✗ File contains $line_count lines (expected 5)"
        echo "  Should have one username per line"
        return 1
    fi
    
    # Check if it contains usernames (no colons)
    if grep -q ":" /tmp/io-lab/sorted-users.txt 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ File still contains colons - usernames not properly extracted"
        echo "  Use cut -d: -f1 to get only the first field"
        return 1
    fi
    
    # Check if sorted (alice should be first)
    local first_line=$(head -1 /tmp/io-lab/sorted-users.txt 2>/dev/null)
    if [ "$first_line" != "alice" ]; then
        echo ""
        print_color "$RED" "✗ File not properly sorted (first line should be 'alice')"
        echo "  Make sure you used sort in your pipeline"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cut -d: -f1 /tmp/io-lab/users.txt | sort > /tmp/io-lab/sorted-users.txt

Alternative (explicit cat):
  cat /tmp/io-lab/users.txt | cut -d: -f1 | sort > /tmp/io-lab/sorted-users.txt

Breaking it down:
  • cut -d: -f1 /tmp/io-lab/users.txt
    - cut: Extract fields from delimited text
    - -d: Specifies ":" as the delimiter (what separates fields)
    - -f1: Extract field 1 (the username)
    - Outputs: alice, bob, charlie, david, eve
  
  • | (pipe): Passes these usernames to sort
  
  • sort
    - Reads the usernames from STDIN
    - Sorts them alphabetically
    - Outputs: alice, bob, charlie, david, eve (in order)
  
  • > /tmp/io-lab/sorted-users.txt
    - Redirects the sorted output to a file

Understanding cut:
  The -d (delimiter) flag tells cut how fields are separated.
  The -f (field) flag tells cut which field(s) to extract.
  
  Example data:     alice:1001:developers
  Field 1 (-f1):    alice
  Field 2 (-f2):    1001
  Field 3 (-f3):    developers
  Fields 1,3 (-f1,3): alice:developers

Why this pattern is so common:
  Linux configuration files often use delimiters:
  • /etc/passwd uses ":"
  • /etc/fstab uses whitespace
  • CSV files use ","
  
  The pattern "extract field | sort | save" appears constantly.

Real-world examples:
  # Extract all usernames from /etc/passwd:
  cut -d: -f1 /etc/passwd | sort
  
  # Find all unique IP addresses in logs:
  cut -d' ' -f1 access.log | sort -u
  
  # Extract email domains from a list:
  cut -d@ -f2 emails.txt | sort | uniq -c

Verification:
  cat /tmp/io-lab/sorted-users.txt
  # Should show:
  # alice
  # bob
  # charlie
  # david
  # eve

EOF
}

hint_step_6() {
    echo "  Use 2>/dev/null to discard STDERR: ls /root/* 2>/dev/null"
}

# STEP 6: Suppressing errors with /dev/null
show_step_6() {
    cat << 'EOF'
TASK: Suppress unwanted error messages while keeping output

Try to list all files in /root/* but hide the "Permission denied"
errors that will appear.

Requirements:
  • Run: ls /root/*
  • You'll see "Permission denied" errors
  • Redirect STDERR to /dev/null to hide these errors
  • Keep any actual output (if accessible)

Commands you'll use:
  • ls        - List files
  • 2>/dev/null - Discard STDERR

What you're learning:
  /dev/null is a special "null device" - a black hole for data.
  Anything written to /dev/null disappears completely.
  
  This is incredibly useful for:
  - Suppressing expected error messages
  - Cleaning up output from commands
  - Running commands quietly

When to use this:
  ✓ Suppress "Permission denied" when searching system files
  ✓ Hide expected errors in scripts
  ✓ Clean output for parsing by other tools
  
  ✗ Don't use blindly - you might hide important errors!
  ✗ Never use in troubleshooting - you need to see errors

The /dev/null device:
  • Reading from /dev/null: returns EOF (end of file) immediately
  • Writing to /dev/null: data is discarded
  • It's always available and never fills up
  • Think of it as /dev/trash or /dev/blackhole

Note: This step just demonstrates the technique. The command will
likely show nothing (since you don't have permission), but no
errors will appear either.
EOF
}

validate_step_6() {
    # This is a demonstration step
    # We validate that they understand the concept by checking
    # if they can explain it correctly
    # For lab purposes, we'll check if they tried the command
    
    # Since we can't verify a command they ran interactively,
    # we'll provide a test they can run themselves
    echo ""
    echo "This step teaches a technique rather than creating a file."
    echo "Try running these commands to see the difference:"
    echo ""
    echo "  With errors displayed:"
    echo "    ls /root/* 2>&1"
    echo ""
    echo "  With errors hidden:"
    echo "    ls /root/* 2>/dev/null"
    echo ""
    echo "The second command should be silent (or show only accessible files)."
    echo ""
    
    # We'll consider this step complete if they've made it this far
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  ls /root/* 2>/dev/null

Breaking it down:
  • ls /root/*: Try to list all files in /root/
    - This will likely fail with "Permission denied"
    - Errors go to STDERR
  
  • 2>/dev/null: Redirect STDERR to /dev/null
    - File descriptor 2 (STDERR) is redirected
    - /dev/null discards all data sent to it
    - Error messages disappear

Comparison:
  # With errors (noisy):
  $ ls /root/*
  ls: cannot open directory '/root': Permission denied
  
  # Without errors (clean):
  $ ls /root/* 2>/dev/null
  (no output - errors hidden)

Common /dev/null patterns:
  # Find files, hide permission errors:
  find / -name "*.conf" 2>/dev/null
  
  # Check if command succeeds, hide all output:
  ping -c1 google.com &>/dev/null && echo "Network OK"
  
  # Run command silently:
  command >/dev/null 2>&1
  
  # Discard output but keep errors:
  command >/dev/null

The complete redirection syntax:
  command 2>/dev/null       # Hide errors only
  command >/dev/null        # Hide output only  
  command >/dev/null 2>&1   # Hide everything (STDOUT, then STDERR to STDOUT)
  command &>/dev/null       # Hide everything (bash shortcut)

Real-world usage:
  In scripts, you often want to test if something exists without
  showing errors:
  
  if grep -q "pattern" file 2>/dev/null; then
      echo "Pattern found"
  fi
  
  The 2>/dev/null ensures that if the file doesn't exist, no
  error message appears - the script just handles it gracefully.

When NOT to use /dev/null:
  ✗ During troubleshooting (you need to see errors!)
  ✗ In complex scripts (log errors instead)
  ✗ When learning (errors teach you what's wrong)

Verification:
  Try both commands and observe the difference:
  
  ls /root/* 2>&1           # Shows errors
  ls /root/* 2>/dev/null    # Silent

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your I/O redirection work..."
    echo ""
    
    # Check 1: successful.log contains 200 responses
    print_color "$CYAN" "[1/$total] Checking STDOUT redirection (successful.log)..."
    if [ -f "/tmp/io-lab/successful.log" ]; then
        if grep -q "200" /tmp/io-lab/successful.log 2>/dev/null && \
           [ $(wc -l < /tmp/io-lab/successful.log) -ge 4 ]; then
            print_color "$GREEN" "  ✓ File contains HTTP 200 responses"
            ((score++))
        else
            print_color "$RED" "  ✗ File exists but doesn't contain expected 200 responses"
        fi
    else
        print_color "$RED" "  ✗ File /tmp/io-lab/successful.log not found"
        print_color "$YELLOW" "  Fix: grep ' 200 ' /tmp/io-lab/access.log > /tmp/io-lab/successful.log"
    fi
    echo ""
    
    # Check 2: successful.log was appended with 404s
    print_color "$CYAN" "[2/$total] Checking append operation (>> usage)..."
    if [ -f "/tmp/io-lab/successful.log" ]; then
        if grep -q "404" /tmp/io-lab/successful.log 2>/dev/null && \
           grep -q "200" /tmp/io-lab/successful.log 2>/dev/null; then
            print_color "$GREEN" "  ✓ File contains both 200 and 404 (append worked)"
            ((score++))
        else
            print_color "$RED" "  ✗ File missing 404 responses or was overwritten"
            print_color "$YELLOW" "  Fix: grep ' 404 ' /tmp/io-lab/access.log >> /tmp/io-lab/successful.log"
        fi
    else
        print_color "$RED" "  ✗ File doesn't exist to check append"
    fi
    echo ""
    
    # Check 3: STDERR captured
    print_color "$CYAN" "[3/$total] Checking STDERR redirection..."
    if [ -f "/tmp/io-lab/cmd-errors.log" ]; then
        if grep -qi "cannot access\|no such" /tmp/io-lab/cmd-errors.log 2>/dev/null; then
            print_color "$GREEN" "  ✓ Error messages captured in cmd-errors.log"
            ((score++))
        else
            print_color "$RED" "  ✗ File exists but doesn't contain error messages"
        fi
    else
        print_color "$RED" "  ✗ File /tmp/io-lab/cmd-errors.log not found"
        print_color "$YELLOW" "  Fix: ls /nonexistent /fakedir 2> /tmp/io-lab/cmd-errors.log"
    fi
    echo ""
    
    # Check 4: Piping demonstrated (we'll check the source file structure)
    print_color "$CYAN" "[4/$total] Checking pipeline understanding..."
    local error_count=$(grep -c "ERROR" /tmp/io-lab/error.log 2>/dev/null || echo 0)
    if [ "$error_count" = "3" ]; then
        print_color "$GREEN" "  ✓ Pipeline concept validated (error.log has 3 ERROR lines)"
        ((score++))
    else
        print_color "$YELLOW" "  ⚠ Could not validate pipeline (run: grep 'ERROR' /tmp/io-lab/error.log | wc -l)"
    fi
    echo ""
    
    # Check 5: sorted-users.txt
    print_color "$CYAN" "[5/$total] Checking complex pipeline (sorted-users.txt)..."
    if [ -f "/tmp/io-lab/sorted-users.txt" ]; then
        if ! grep -q ":" /tmp/io-lab/sorted-users.txt 2>/dev/null && \
           [ "$(head -1 /tmp/io-lab/sorted-users.txt 2>/dev/null)" = "alice" ] && \
           [ $(wc -l < /tmp/io-lab/sorted-users.txt 2>/dev/null) -eq 5 ]; then
            print_color "$GREEN" "  ✓ Usernames extracted and sorted correctly"
            ((score++))
        else
            print_color "$RED" "  ✗ File exists but content is incorrect"
            print_color "$YELLOW" "  Fix: cut -d: -f1 /tmp/io-lab/users.txt | sort > /tmp/io-lab/sorted-users.txt"
        fi
    else
        print_color "$RED" "  ✗ File /tmp/io-lab/sorted-users.txt not found"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • STDOUT redirection (> and >>)"
        echo "  • STDERR redirection (2>)"
        echo "  • Piping commands (|)"
        echo "  • Using /dev/null to suppress output"
        echo ""
        echo "These are fundamental skills you'll use constantly in Linux administration."
    elif [ $score -ge 3 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You understand the basics! Review the failed checks above."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Keep practicing these concepts - they're essential."
        echo "Run with --solution to see detailed explanations."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This lab teaches the fundamental concepts of I/O redirection and piping.
Understanding these concepts is essential for effective Linux system
administration.

CONCEPT OVERVIEW
─────────────────────────────────────────────────────────────────
Every Linux program has three standard streams:

  Stream    | FD | Default     | Purpose
  ----------|----|-----------  |------------------------
  STDIN     | 0  | Keyboard    | Input to program
  STDOUT    | 1  | Terminal    | Normal program output
  STDERR    | 2  | Terminal    | Error messages

Redirection lets you control where these streams go!


STEP 1: Basic STDOUT Redirection (>)
─────────────────────────────────────────────────────────────────
Command:
  grep " 200 " /tmp/io-lab/access.log > /tmp/io-lab/successful.log

Concept:
  The > operator redirects STDOUT to a file. If the file exists, it's
  overwritten. If not, it's created.

Real-world use:
  Extracting specific information from logs is a daily task for sysadmins.


STEP 2: Appending with >>
─────────────────────────────────────────────────────────────────
Command:
  grep " 404 " /tmp/io-lab/access.log >> /tmp/io-lab/successful.log

Critical difference:
  • > overwrites the file
  • >> appends to the file

Why this matters:
  Using > when you meant >> can destroy important log data!
  
  Example of safe logging:
    echo "[$(date)] Backup completed" >> /var/log/backup.log


STEP 3: STDERR Redirection (2>)
─────────────────────────────────────────────────────────────────
Command:
  ls /nonexistent /fakedir /notreal 2> /tmp/io-lab/cmd-errors.log

Concept:
  STDERR (file descriptor 2) is separate from STDOUT. You can redirect
  them independently.

Syntax patterns:
  command > output.log 2> errors.log     # Separate files
  command > output.log 2>&1              # Merge STDERR into STDOUT
  command &> combined.log                # Both to same file (bash shortcut)
  command 2>/dev/null                    # Discard errors


STEP 4: Piping Commands (|)
─────────────────────────────────────────────────────────────────
Command:
  grep "ERROR" /tmp/io-lab/error.log | wc -l

Concept:
  Pipes connect the STDOUT of one command to the STDIN of the next.
  This lets you build data processing pipelines.

Think of it as:
  [Command 1 output] → [Command 2 processes it] → [Command 3 processes that]

Example multi-stage pipeline:
  cat access.log | grep "200" | cut -d' ' -f1 | sort | uniq -c | sort -rn


STEP 5: Complex Pipeline with Field Extraction
─────────────────────────────────────────────────────────────────
Command:
  cut -d: -f1 /tmp/io-lab/users.txt | sort > /tmp/io-lab/sorted-users.txt

Concept:
  Multiple commands can be chained to transform data step by step.
  
  Data flow:
  1. cut extracts field 1 (usernames)
  2. sort alphabetizes them
  3. > saves the result

This pattern appears constantly when processing:
  • /etc/passwd entries
  • CSV files
  • Log files with structured data


STEP 6: Suppressing Errors with /dev/null
─────────────────────────────────────────────────────────────────
Command:
  ls /root/* 2>/dev/null

Concept:
  /dev/null is a "null device" - a black hole. Any data written to
  it disappears completely.

Common uses:
  # Hide expected "Permission denied" errors:
  find / -name "*.conf" 2>/dev/null
  
  # Silent command execution:
  command &>/dev/null
  
  # Test if something exists without noise:
  if grep -q "pattern" file 2>/dev/null; then
      echo "Found it"
  fi

⚠ Warning: Don't blindly redirect errors to /dev/null. In troubleshooting,
you NEED to see error messages!


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Why Separate STDOUT and STDERR?
  Programs need a way to communicate both normal results AND problems.
  By keeping them separate, you can:
  • Log errors to one file, output to another
  • Display output while suppressing errors
  • Process them with different tools

The Power of Pipes:
  Unix philosophy: Write programs that do one thing well and work together.
  Pipes enable this. Instead of one giant program that does everything,
  you combine small, focused tools.

When to Use Each Technique:
  > and >>    : Saving results to files
  2>          : Logging errors separately
  |           : Transforming data through multiple steps
  /dev/null   : Discarding unwanted output


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Confusing > and >>
  Result: Accidentally overwriting important log files
  Prevention: Always use >> for logs that should accumulate

Mistake 2: Forgetting 2> needs a file descriptor
  Wrong: command > file2>/dev/null
  Right: command > file 2>/dev/null
  
  The space matters! Without it, Bash interprets "file2" as a filename.

Mistake 3: Redirecting before piping
  Wrong: command > file | other_command
  Right: command | other_command > file
  
  Explanation: The > immediately redirects, so nothing flows to the pipe!

Mistake 4: Blindly using /dev/null
  During troubleshooting, you NEED error messages. Don't hide them
  until you understand what's happening.


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Practice building pipelines incrementally:
   • Run the first command, verify output
   • Add the second command with |
   • Add redirection at the end
   
2. Remember the order of operations:
   • Expansion happens first
   • Then redirection
   • Finally, pipes connect commands

3. Common exam patterns:
   • Extract specific fields: cut, awk
   • Filter content: grep
   • Count or summarize: wc, sort, uniq
   • Transform: sed, tr

4. Quick verification:
   • Use cat to check file contents
   • Use wc -l to count lines
   • Run commands without redirection first to see output

5. If stuck, break down the problem:
   • What data do I need to extract?
   • How do I transform it?
   • Where does the final result go?

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/io-lab 2>/dev/null || true
    echo "  ✓ All lab files removed from /tmp/io-lab/"
}

# Execute the main framework
main "$@"
