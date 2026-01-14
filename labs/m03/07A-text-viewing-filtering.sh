#!/bin/bash
# labs/11-text-viewing-filtering.sh
# Lab: Text File Viewing and Filtering
# Difficulty: Beginner
# RHCSA Objective: View and process text file contents

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Text File Viewing and Filtering"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    rm -rf /tmp/text-lab 2>/dev/null || true
    
    # Create working directory
    mkdir -p /tmp/text-lab/{logs,data,output}
    
    # Create sample log files
    cat > /tmp/text-lab/logs/application.log << 'EOF'
2025-01-14 08:00:00 INFO Starting application
2025-01-14 08:00:05 INFO Loading configuration from /etc/app/config.conf
2025-01-14 08:00:10 INFO Connecting to database at db.example.com:5432
2025-01-14 08:00:15 INFO Database connection established
2025-01-14 08:00:20 INFO Starting web server on port 8080
2025-01-14 08:00:25 INFO Application started successfully
2025-01-14 08:05:00 DEBUG Processing user request from 192.168.1.100
2025-01-14 08:05:02 DEBUG Query executed: SELECT * FROM users WHERE id=42
2025-01-14 08:05:05 INFO Request completed in 5ms
2025-01-14 08:10:00 WARNING High memory usage detected: 85%
2025-01-14 08:10:30 DEBUG Garbage collection started
2025-01-14 08:10:35 DEBUG Garbage collection completed, freed 512MB
2025-01-14 08:15:00 ERROR Failed to connect to cache server at 192.168.1.50:6379
2025-01-14 08:15:05 ERROR Connection timeout after 30s
2025-01-14 08:15:10 WARNING Retrying cache connection (attempt 1/3)
2025-01-14 08:15:15 INFO Cache connection re-established
2025-01-14 08:20:00 INFO Processing batch job #1234
2025-01-14 08:20:30 INFO Batch job completed successfully
2025-01-14 08:25:00 DEBUG Session cleanup started
2025-01-14 08:25:05 DEBUG Removed 150 expired sessions
EOF

    # Create system logs
    cat > /tmp/text-lab/logs/system.log << 'EOF'
Jan 14 08:00:00 server1 systemd[1]: Starting Network Manager...
Jan 14 08:00:00 server1 systemd[1]: Started Network Manager.
Jan 14 08:00:05 server1 NetworkManager[1234]: <info> NetworkManager (version 1.30.0) is starting...
Jan 14 08:00:10 server1 NetworkManager[1234]: <info> eth0: carrier is now ON
Jan 14 08:00:15 server1 NetworkManager[1234]: <info> eth0: IPv4 address 192.168.1.100
Jan 14 08:05:00 server1 sshd[5678]: Accepted publickey for admin from 192.168.1.200 port 54321
Jan 14 08:10:00 server1 kernel: [12345.678] EXT4-fs (sda1): mounted filesystem with ordered data mode
Jan 14 08:15:00 server1 systemd[1]: Starting HTTP Server...
Jan 14 08:15:05 server1 httpd[9012]: Server started on port 80
Jan 14 08:20:00 server1 cron[3456]: (root) CMD (/usr/local/bin/backup.sh)
EOF

    # Create user database file
    cat > /tmp/text-lab/data/users.csv << 'EOF'
username:uid:gid:home:shell
alice:1001:1001:/home/alice:/bin/bash
bob:1002:1002:/home/bob:/bin/bash
charlie:1003:1003:/home/charlie:/bin/zsh
diana:1004:1004:/home/diana:/bin/bash
eve:1005:1005:/home/eve:/bin/sh
frank:1006:1006:/home/frank:/bin/bash
grace:1007:1007:/home/grace:/bin/bash
henry:1008:1008:/home/henry:/bin/zsh
iris:1009:1009:/home/iris:/bin/bash
jack:1010:1010:/home/jack:/bin/bash
EOF

    # Create sales data
    cat > /tmp/text-lab/data/sales.txt << 'EOF'
Product:Price:Quantity:Total
Laptop:1200:5:6000
Mouse:25:50:1250
Keyboard:75:30:2250
Monitor:300:10:3000
Headphones:50:25:1250
Webcam:80:15:1200
USB Cable:10:100:1000
Docking Station:200:8:1600
External Drive:120:12:1440
RAM Module:150:20:3000
EOF

    # Create mixed case file for tr practice
    cat > /tmp/text-lab/data/mixed-text.txt << 'EOF'
Hello World
This is a TEST file
With MIXED case letters
Some lowercase
Some UPPERCASE
And Some MiXeD
EOF

    # Fix ownership
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" /tmp/text-lab 2>/dev/null || true
    fi
    
    echo "  ✓ Created log files"
    echo "  ✓ Created data files"
    echo "  ✓ Ready for text processing"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic command line navigation
  • Understanding of text files
  • Familiarity with pipes (|)

Commands You'll Use:
  • less      - View files page by page (q to quit, / to search)
  • head      - Show first N lines of file
  • tail      - Show last N lines of file
  • cat       - Display entire file contents
  • tac       - Display file in reverse order
  • cut       - Extract columns/fields from files
  • sort      - Sort lines of text
  • tr        - Translate or delete characters
  • wc        - Count lines, words, characters

Key Flags to Remember:
  • head/tail: -n NUM or -NUM (show NUM lines)
  • tail: -f (follow file as it grows)
  • cat: -n (number lines), -A (show non-printable chars)
  • cut: -d DELIM (delimiter), -f FIELDS (which fields)
  • sort: -t DELIM (delimiter), -k FIELD (sort by field), -n (numeric)
  • tr: [:lower:] [:upper:] (translate lowercase to uppercase)

Core Concepts:
  • Pagers (less/more) for large files
  • Piping commands together
  • Field/column extraction
  • Data transformation
  • Sorting and filtering

Why This Matters:
  System administrators constantly work with log files, configuration
  files, and data files. These tools let you quickly extract, filter,
  and analyze information without opening a text editor.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're monitoring a production web server and need to analyze log files,
extract specific data, and create reports. You'll use text processing
tools to quickly get the information you need.

OBJECTIVES:
Complete these tasks to demonstrate text processing mastery:

  1. Monitor active log file
     • View the last 20 lines of application.log
     • Save those 20 lines to: output/recent-activity.txt
     • In production, you'd use: tail -f to watch logs in real-time

  2. Extract ERROR messages from logs
     • Find all lines containing "ERROR" in application.log
     • Save ONLY those lines to: output/errors.txt
     • Count how many errors occurred

  3. Extract usernames from CSV data
     • Get ONLY the username field (first field) from users.csv
     • Skip the header line
     • Save sorted list to: output/usernames.txt

  4. Extract and sort UIDs
     • Get the UID field (second field) from users.csv
     • Sort them numerically (not alphabetically!)
     • Skip the header
     • Save to: output/sorted-uids.txt

  5. Find highest price in sales data
     • Extract the Price field from sales.txt
     • Sort numerically in reverse order (highest first)
     • Show ONLY the top price
     • Save to: output/highest-price.txt

  6. Convert text to uppercase
     • Take mixed-text.txt
     • Convert ALL text to uppercase
     • Save to: output/uppercase.txt

HINTS:
  • tail -n NUM shows last NUM lines
  • head -n NUM shows first NUM lines
  • Combine them: tail -n +2 skips header (starts from line 2)
  • cut needs -d for delimiter and -f for field number
  • sort needs -t for delimiter, -k for field, -n for numeric
  • sort -r reverses order (descending)
  • tr [:lower:] [:upper:] converts case
  • Pipe commands together: command1 | command2 | command3

SUCCESS CRITERIA:
  • You can view and navigate log files
  • You can extract specific fields from delimited files
  • You can sort data numerically and alphabetically
  • You can transform text (change case)
  • You understand piping for complex operations
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Extract last 20 lines → output/recent-activity.txt
  ☐ 2. Find ERROR lines → output/errors.txt, count them
  ☐ 3. Extract usernames (skip header), sort → output/usernames.txt
  ☐ 4. Extract UIDs, sort numerically → output/sorted-uids.txt
  ☐ 5. Find highest price → output/highest-price.txt
  ☐ 6. Convert to uppercase → output/uppercase.txt
EOF
}

#############################################################################
# INTERACTIVE MODE - LESS HAND-HOLDY
#############################################################################

get_step_count() {
    echo "6"
}

scenario_context() {
    cat << 'EOF'
You're analyzing log files and data files on a production server.
Use text processing tools to extract information quickly.
EOF
}

# STEP 1: View recent log entries
show_step_1() {
    cat << 'EOF'
TASK: Extract the most recent log entries

You need to see what happened recently in the application log.

What to do:
  • Look at the LAST 20 lines of logs/application.log
  • Save those 20 lines to output/recent-activity.txt

Tools available:
  • tail - shows end of file
  • head - shows beginning of file
  • Use -n NUM or just -NUM to specify line count

Think about:
  • Which tool shows the END of a file?
  • How do you specify the number of lines?
  • How do you save output to a file?

Expected result:
  output/recent-activity.txt should contain the last 20 lines
  from application.log
EOF
}

validate_step_1() {
    if [ ! -f "/tmp/text-lab/output/recent-activity.txt" ]; then
        echo ""
        print_color "$RED" "✗ File output/recent-activity.txt not found"
        echo "  Did you save the output?"
        return 1
    fi
    
    local line_count=$(wc -l < /tmp/text-lab/output/recent-activity.txt)
    if [ "$line_count" -ne 20 ]; then
        echo ""
        print_color "$RED" "✗ File has $line_count lines (expected 20)"
        echo "  Make sure you're extracting exactly 20 lines"
        return 1
    fi
    
    # Check if it contains expected content from the end of the log
    if ! grep -q "Session cleanup" /tmp/text-lab/output/recent-activity.txt; then
        echo ""
        print_color "$RED" "✗ File doesn't contain expected log entries"
        echo "  Make sure you're getting the LAST 20 lines"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/text-lab
  tail -n 20 logs/application.log > output/recent-activity.txt
  
  # Or using shorthand:
  tail -20 logs/application.log > output/recent-activity.txt

Why this works:
  • tail shows the END of a file
  • -n 20 means "show last 20 lines"
  • > redirects output to file

Alternative approaches:
  # View without saving:
  tail -20 logs/application.log
  
  # View with line numbers:
  tail -20 logs/application.log | cat -n
  
  # Follow file in real-time (production use):
  tail -f logs/application.log
  # Press Ctrl+C to stop

Real-world usage:
  # Monitor active log:
  tail -f /var/log/syslog
  
  # Last 50 lines:
  tail -50 /var/log/nginx/error.log
  
  # Last 100 lines with line numbers:
  tail -100 app.log | cat -n

Verification:
  wc -l output/recent-activity.txt
  # Should show: 20
  
  head -5 output/recent-activity.txt
  # Shows first 5 lines of your output

EOF
}

hint_step_2() {
    echo "  Use grep to filter, save with >, then use wc -l to count lines"
}

# STEP 2: Extract errors
show_step_2() {
    cat << 'EOF'
TASK: Find and extract all error messages

You need to identify all errors that occurred.

What to do:
  • Find all lines containing "ERROR" in logs/application.log
  • Save those lines to output/errors.txt
  • Count how many error lines you found

Tools available:
  • grep - searches for patterns in text
  • wc -l - counts lines

Think about:
  • How do you search for a specific word in a file?
  • How do you save those matching lines?
  • How do you count lines in a file?

Challenge:
  This requires TWO separate commands:
  1. Extract and save ERROR lines
  2. Count the lines in your output file

Expected result:
  output/errors.txt should contain only lines with "ERROR"
  You should know how many errors occurred (2 errors in this log)
EOF
}

validate_step_2() {
    if [ ! -f "/tmp/text-lab/output/errors.txt" ]; then
        echo ""
        print_color "$RED" "✗ File output/errors.txt not found"
        return 1
    fi
    
    # Check if it contains ERROR lines
    if ! grep -q "ERROR" /tmp/text-lab/output/errors.txt; then
        echo ""
        print_color "$RED" "✗ File doesn't contain ERROR lines"
        return 1
    fi
    
    # Check that it ONLY contains ERROR lines (no other lines)
    local total_lines=$(wc -l < /tmp/text-lab/output/errors.txt)
    local error_lines=$(grep -c "ERROR" /tmp/text-lab/output/errors.txt)
    
    if [ "$total_lines" -ne "$error_lines" ]; then
        echo ""
        print_color "$RED" "✗ File contains non-ERROR lines"
        echo "  Should only contain lines with 'ERROR'"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cd /tmp/text-lab
  
  # Extract ERROR lines
  grep "ERROR" logs/application.log > output/errors.txt
  
  # Count the errors
  wc -l output/errors.txt
  # Output: 2 output/errors.txt

Breaking it down:
  grep "ERROR" logs/application.log
  • Searches for lines containing "ERROR"
  • Prints matching lines to STDOUT
  
  > output/errors.txt
  • Redirects output to file
  
  wc -l output/errors.txt
  • Counts lines in the file
  • -l means "count lines only"

One-liner alternative:
  grep "ERROR" logs/application.log | tee output/errors.txt | wc -l
  # tee saves to file AND passes to next command

Why grep is powerful:
  # Case-insensitive search:
  grep -i "error" file.log
  
  # Show 5 lines before and after match:
  grep -C5 "ERROR" file.log
  
  # Count matches without saving:
  grep -c "ERROR" file.log
  
  # Invert match (lines WITHOUT "ERROR"):
  grep -v "ERROR" file.log

Real-world patterns:
  # Find recent errors:
  grep "ERROR" /var/log/application.log | tail -20
  
  # Errors from last hour:
  grep "$(date +%H):" /var/log/app.log | grep ERROR
  
  # Multiple patterns:
  grep -E "ERROR|FATAL|CRITICAL" app.log

Verification:
  cat output/errors.txt
  # Should show 2 ERROR lines

EOF
}

hint_step_3() {
    echo "  Use cut with -d for delimiter and -f for field, combine with tail to skip header"
}

# STEP 3: Extract usernames
show_step_3() {
    cat << 'EOF'
TASK: Extract and sort usernames from user database

You need a sorted list of all usernames.

What to do:
  • Extract ONLY the username field from data/users.csv
  • Skip the header line (first line)
  • Sort the usernames alphabetically
  • Save to output/usernames.txt

File format:
  data/users.csv uses : as delimiter
  Fields are: username:uid:gid:home:shell
  First field is the username

Tools available:
  • cut - extracts fields from delimited files
  • sort - sorts lines
  • tail - can skip lines from beginning

Think about:
  • What's the delimiter character?
  • Which field number is the username?
  • How do you skip the first line?
  • How do you sort the results?

This requires piping multiple commands together!

Expected result:
  output/usernames.txt should contain:
  alice
  bob
  charlie
  (and so on, in alphabetical order)
EOF
}

validate_step_3() {
    if [ ! -f "/tmp/text-lab/output/usernames.txt" ]; then
        echo ""
        print_color "$RED" "✗ File output/usernames.txt not found"
        return 1
    fi
    
    # Check if header is excluded
    if grep -q "username" /tmp/text-lab/output/usernames.txt; then
        echo ""
        print_color "$RED" "✗ File contains header line (should be skipped)"
        return 1
    fi
    
    # Check if it contains expected usernames
    if ! grep -q "alice" /tmp/text-lab/output/usernames.txt; then
        echo ""
        print_color "$RED" "✗ File doesn't contain expected usernames"
        return 1
    fi
    
    # Check if sorted
    local sorted=$(sort /tmp/text-lab/output/usernames.txt)
    local actual=$(cat /tmp/text-lab/output/usernames.txt)
    if [ "$sorted" != "$actual" ]; then
        echo ""
        print_color "$RED" "✗ Usernames are not sorted alphabetically"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/text-lab
  tail -n +2 data/users.csv | cut -d: -f1 | sort > output/usernames.txt

Breaking down the pipeline:
  
  tail -n +2 data/users.csv
  • -n +2 means "start from line 2" (skips header)
  • Outputs all lines except the first
  
  | cut -d: -f1
  • -d: sets delimiter to colon
  • -f1 selects first field (username)
  
  | sort
  • Sorts lines alphabetically
  
  > output/usernames.txt
  • Saves result to file

Alternative approaches:
  # Using sed to skip header:
  sed '1d' data/users.csv | cut -d: -f1 | sort > output/usernames.txt
  
  # Using awk (more advanced):
  awk -F: 'NR>1 {print $1}' data/users.csv | sort > output/usernames.txt

Understanding tail -n +2:
  tail -n NUM   # Last NUM lines
  tail -n +NUM  # Starting from line NUM
  
  Examples:
  tail -n 5 file    # Last 5 lines
  tail -n +5 file   # Line 5 to end (skip first 4)

Understanding cut:
  cut -d DELIM -f FIELDS
  
  -d:    Delimiter is colon
  -f1    Field 1
  -f1,3  Fields 1 and 3
  -f1-3  Fields 1 through 3

Real-world usage:
  # Extract email addresses from CSV:
  cut -d, -f3 users.csv | sort -u
  
  # Get all usernames from /etc/passwd:
  cut -d: -f1 /etc/passwd | sort
  
  # Extract IPs from log:
  cut -d' ' -f1 access.log | sort -u

Verification:
  cat output/usernames.txt
  # Should show sorted usernames
  
  wc -l output/usernames.txt
  # Should show: 10

EOF
}

hint_step_4() {
    echo "  Similar to step 3, but use -f2 for second field and add -n to sort numerically"
}

# STEP 4: Sort UIDs numerically
show_step_4() {
    cat << 'EOF'
TASK: Extract and sort user IDs numerically

You need a list of UIDs in numeric order.

What to do:
  • Extract the UID field (second field) from data/users.csv
  • Skip the header line
  • Sort numerically (NOT alphabetically!)
  • Save to output/sorted-uids.txt

Think about:
  • Which field number is the UID? (count from 1)
  • What's the difference between alphabetic and numeric sort?
  • What flag makes sort work numerically?

Important:
  Without numeric sort, "1010" comes before "1002" (alphabetically)
  With numeric sort, "1002" comes before "1010" (mathematically)

This is similar to step 3 but with different field and sort type!

Expected result:
  output/sorted-uids.txt should contain:
  1001
  1002
  1003
  (and so on, in numeric order)
EOF
}

validate_step_4() {
    if [ ! -f "/tmp/text-lab/output/sorted-uids.txt" ]; then
        echo ""
        print_color "$RED" "✗ File output/sorted-uids.txt not found"
        return 1
    fi
    
    # Check if header is excluded
    if grep -q "uid" /tmp/text-lab/output/sorted-uids.txt; then
        echo ""
        print_color "$RED" "✗ File contains header (should be skipped)"
        return 1
    fi
    
    # Check if sorted numerically
    local sorted=$(sort -n /tmp/text-lab/output/sorted-uids.txt)
    local actual=$(cat /tmp/text-lab/output/sorted-uids.txt)
    if [ "$sorted" != "$actual" ]; then
        echo ""
        print_color "$RED" "✗ UIDs are not sorted numerically"
        echo "  Did you use sort -n?"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/text-lab
  tail -n +2 data/users.csv | cut -d: -f2 | sort -n > output/sorted-uids.txt

Breaking it down:
  
  tail -n +2 data/users.csv
  • Skips header (starts from line 2)
  
  | cut -d: -f2
  • -f2 selects SECOND field (UID)
  
  | sort -n
  • -n sorts NUMERICALLY (not alphabetically)
  
  > output/sorted-uids.txt
  • Saves result

Why -n matters:
  
  WITHOUT -n (alphabetic sort):
  1001
  1010  ← Wrong! This comes before 1002 alphabetically
  1002
  1003
  
  WITH -n (numeric sort):
  1001
  1002  ← Correct! 1002 < 1010 mathematically
  1003
  1010

More sort options:
  -n    Numeric sort
  -r    Reverse order (descending)
  -nr   Numeric descending
  -k2   Sort by 2nd field
  -t:   Use : as field delimiter
  -u    Unique (remove duplicates)

Real-world examples:
  # Sort IPs numerically:
  sort -t. -k1,1n -k2,2n -k3,3n -k4,4n ips.txt
  
  # Sort by file size (human-readable):
  ls -lh | sort -k5 -h
  
  # Sort /etc/passwd by UID:
  sort -t: -k3 -n /etc/passwd
  
  # Find highest UID:
  cut -d: -f3 /etc/passwd | sort -n | tail -1

Verification:
  head output/sorted-uids.txt
  # Should start with: 1001

EOF
}

hint_step_5() {
    echo "  Extract price field, sort -nr (numeric reverse), use head -1 to get top line"
}

# STEP 5: Find highest price
show_step_5() {
    cat << 'EOF'
TASK: Find the most expensive product

You need to identify the highest price in the sales data.

What to do:
  • Extract the Price field (second field) from data/sales.txt
  • Skip the header line
  • Sort numerically in REVERSE order (highest first)
  • Show ONLY the top price
  • Save to output/highest-price.txt

File format:
  data/sales.txt uses : as delimiter
  Fields are: Product:Price:Quantity:Total

Think about:
  • Which field is the price?
  • How do you sort in reverse (descending) order?
  • How do you show only the first line after sorting?

This combines everything you've learned so far!

Expected result:
  output/highest-price.txt should contain one line:
  1200
EOF
}

validate_step_5() {
    if [ ! -f "/tmp/text-lab/output/highest-price.txt" ]; then
        echo ""
        print_color "$RED" "✗ File output/highest-price.txt not found"
        return 1
    fi
    
    # Check if it contains exactly one line with the highest price
    local line_count=$(wc -l < /tmp/text-lab/output/highest-price.txt)
    if [ "$line_count" -ne 1 ]; then
        echo ""
        print_color "$RED" "✗ File should contain exactly one line"
        echo "  Use head -1 to get only the top result"
        return 1
    fi
    
    local price=$(cat /tmp/text-lab/output/highest-price.txt | tr -d '[:space:]')
    if [ "$price" != "1200" ]; then
        echo ""
        print_color "$RED" "✗ Wrong price: $price (expected 1200)"
        echo "  Make sure you're sorting in reverse (highest first)"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/text-lab
  tail -n +2 data/sales.txt | cut -d: -f2 | sort -nr | head -1 > output/highest-price.txt

Breaking down the pipeline:
  
  tail -n +2 data/sales.txt
  • Skips header
  
  | cut -d: -f2
  • Extracts Price field (second field)
  
  | sort -nr
  • -n: Numeric sort
  • -r: Reverse (descending)
  • Result: Highest prices first
  
  | head -1
  • Shows only first line (highest price)
  
  > output/highest-price.txt
  • Saves result

Understanding sort -nr:
  
  -n alone (ascending):
  10
  25
  50
  1200  ← Last
  
  -nr (descending):
  1200  ← First!
  50
  25
  10

Alternative approaches:
  # Using tail to get last line (after ascending sort):
  tail -n +2 data/sales.txt | cut -d: -f2 | sort -n | tail -1
  
  # Using awk:
  awk -F: 'NR>1 {print $2}' data/sales.txt | sort -nr | head -1

Real-world usage:
  # Find largest files:
  du -h /var/log/* | sort -hr | head -5
  
  # Top memory-consuming processes:
  ps aux | sort -k4 -nr | head -10
  
  # Highest UIDs in system:
  cut -d: -f3 /etc/passwd | sort -nr | head -5
  
  # Find oldest files:
  ls -lt | head -20
  
  # Top 10 IP addresses in log:
  cut -d' ' -f1 access.log | sort | uniq -c | sort -nr | head -10

Complex sorting:
  # Sort by multiple fields:
  sort -t: -k3,3n -k4,4n file.txt
  # Sorts by 3rd field numerically, then 4th field
  
  # Sort CSV by column 2, then column 5:
  sort -t, -k2,2 -k5,5n data.csv

Verification:
  cat output/highest-price.txt
  # Should show: 1200

EOF
}

hint_step_6() {
    echo "  Use cat to display file, pipe to tr with [:lower:] [:upper:], save output"
}

# STEP 6: Convert case
show_step_6() {
    cat << 'EOF'
TASK: Convert all text to uppercase

You need to standardize text by converting everything to uppercase.

What to do:
  • Read data/mixed-text.txt
  • Convert ALL lowercase letters to uppercase
  • Save to output/uppercase.txt

Tools available:
  • tr - translates (transforms) characters
  • Character classes: [:lower:] and [:upper:]

Think about:
  • How do you display a file's contents?
  • How do you pipe that to tr?
  • What's the tr syntax for case conversion?

Hint:
  tr OLD NEW
  Where OLD and NEW are character sets

Expected result:
  output/uppercase.txt should have all text in UPPERCASE
EOF
}

validate_step_6() {
    if [ ! -f "/tmp/text-lab/output/uppercase.txt" ]; then
        echo ""
        print_color "$RED" "✗ File output/uppercase.txt not found"
        return 1
    fi
    
    # Check if there are any lowercase letters (there shouldn't be)
    if grep -q '[a-z]' /tmp/text-lab/output/uppercase.txt; then
        echo ""
        print_color "$RED" "✗ File still contains lowercase letters"
        echo "  All text should be converted to uppercase"
        return 1
    fi
    
    # Check if it contains expected uppercase content
    if ! grep -q "HELLO WORLD" /tmp/text-lab/output/uppercase.txt; then
        echo ""
        print_color "$RED" "✗ File doesn't contain expected content"
        return 1
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/text-lab
  cat data/mixed-text.txt | tr [:lower:] [:upper:] > output/uppercase.txt
  
  # Or without cat:
  tr [:lower:] [:upper:] < data/mixed-text.txt > output/uppercase.txt

Breaking it down:
  
  cat data/mixed-text.txt
  • Displays file contents
  
  | tr [:lower:] [:upper:]
  • tr: Translate characters
  • [:lower:]: All lowercase letters (a-z)
  • [:upper:]: All uppercase letters (A-Z)
  • Translates a→A, b→B, etc.
  
  > output/uppercase.txt
  • Saves result

Understanding tr:
  
  tr SET1 SET2
  • Translates characters in SET1 to corresponding characters in SET2
  
  Character classes:
  [:lower:]   lowercase letters (a-z)
  [:upper:]   uppercase letters (A-Z)
  [:digit:]   digits (0-9)
  [:alpha:]   letters (a-zA-Z)
  [:alnum:]   alphanumeric (a-zA-Z0-9)
  [:space:]   whitespace (space, tab, newline)

More tr examples:
  # Lowercase to uppercase:
  echo "Hello World" | tr [:lower:] [:upper:]
  # Output: HELLO WORLD
  
  # Uppercase to lowercase:
  echo "HELLO" | tr [:upper:] [:lower:]
  # Output: hello
  
  # Replace spaces with underscores:
  echo "hello world" | tr ' ' '_'
  # Output: hello_world
  
  # Delete specific characters:
  echo "hello123" | tr -d [:digit:]
  # Output: hello
  
  # Squeeze repeated characters:
  echo "hellllllo" | tr -s 'l'
  # Output: hello
  
  # Replace newlines with spaces:
  cat file.txt | tr '\n' ' '

Real-world usage:
  # Normalize filenames (spaces to underscores):
  echo "$filename" | tr ' ' '_'
  
  # Remove all non-alphanumeric:
  echo "hello-world!" | tr -cd '[:alnum:]'
  # Output: helloworld
  
  # Convert DOS line endings to Unix:
  tr -d '\r' < dosfile.txt > unixfile.txt
  
  # Create password without special chars:
  tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16

Combining tr with other tools:
  # Convert and sort:
  cat names.txt | tr [:lower:] [:upper:] | sort
  
  # Remove digits and count words:
  cat file.txt | tr -d [:digit:] | wc -w
  
  # Replace multiple spaces with single:
  cat messy.txt | tr -s ' '

Verification:
  cat output/uppercase.txt
  # All text should be UPPERCASE

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your text processing work..."
    echo ""
    
    # Check 1: Recent activity
    print_color "$CYAN" "[1/$total] Checking recent log extraction..."
    if [ -f "/tmp/text-lab/output/recent-activity.txt" ]; then
        local lines=$(wc -l < /tmp/text-lab/output/recent-activity.txt)
        if [ "$lines" -eq 20 ]; then
            print_color "$GREEN" "  ✓ Last 20 lines extracted correctly"
            ((score++))
        else
            print_color "$RED" "  ✗ Wrong number of lines: $lines (expected 20)"
        fi
    else
        print_color "$RED" "  ✗ File output/recent-activity.txt not found"
    fi
    echo ""
    
    # Check 2: Error extraction
    print_color "$CYAN" "[2/$total] Checking ERROR line extraction..."
    if [ -f "/tmp/text-lab/output/errors.txt" ]; then
        local error_count=$(wc -l < /tmp/text-lab/output/errors.txt)
        if [ "$error_count" -eq 2 ] && grep -q "ERROR" /tmp/text-lab/output/errors.txt; then
            print_color "$GREEN" "  ✓ ERROR lines extracted (found 2 errors)"
            ((score++))
        else
            print_color "$RED" "  ✗ Incorrect error extraction"
        fi
    else
        print_color "$RED" "  ✗ File output/errors.txt not found"
    fi
    echo ""
    
    # Check 3: Username extraction
    print_color "$CYAN" "[3/$total] Checking username extraction..."
    if [ -f "/tmp/text-lab/output/usernames.txt" ]; then
        if ! grep -q "username" /tmp/text-lab/output/usernames.txt && \
           grep -q "alice" /tmp/text-lab/output/usernames.txt; then
            local sorted=$(sort /tmp/text-lab/output/usernames.txt)
            local actual=$(cat /tmp/text-lab/output/usernames.txt)
            if [ "$sorted" = "$actual" ]; then
                print_color "$GREEN" "  ✓ Usernames extracted and sorted"
                ((score++))
            else
                print_color "$RED" "  ✗ Usernames not sorted alphabetically"
            fi
        else
            print_color "$RED" "  ✗ Username extraction incorrect"
        fi
    else
        print_color "$RED" "  ✗ File output/usernames.txt not found"
    fi
    echo ""
    
    # Check 4: UID sorting
    print_color "$CYAN" "[4/$total] Checking UID numeric sorting..."
    if [ -f "/tmp/text-lab/output/sorted-uids.txt" ]; then
        local sorted=$(sort -n /tmp/text-lab/output/sorted-uids.txt)
        local actual=$(cat /tmp/text-lab/output/sorted-uids.txt)
        if [ "$sorted" = "$actual" ] && ! grep -q "uid" /tmp/text-lab/output/sorted-uids.txt; then
            print_color "$GREEN" "  ✓ UIDs sorted numerically"
            ((score++))
        else
            print_color "$RED" "  ✗ UIDs not sorted correctly"
        fi
    else
        print_color "$RED" "  ✗ File output/sorted-uids.txt not found"
    fi
    echo ""
    
    # Check 5: Highest price
    print_color "$CYAN" "[5/$total] Checking highest price extraction..."
    if [ -f "/tmp/text-lab/output/highest-price.txt" ]; then
        local price=$(cat /tmp/text-lab/output/highest-price.txt | tr -d '[:space:]')
        if [ "$price" = "1200" ]; then
            print_color "$GREEN" "  ✓ Highest price found: 1200"
            ((score++))
        else
            print_color "$RED" "  ✗ Wrong price: $price (expected 1200)"
        fi
    else
        print_color "$RED" "  ✗ File output/highest-price.txt not found"
    fi
    echo ""
    
    # Check 6: Case conversion
    print_color "$CYAN" "[6/$total] Checking case conversion..."
    if [ -f "/tmp/text-lab/output/uppercase.txt" ]; then
        if ! grep -q '[a-z]' /tmp/text-lab/output/uppercase.txt && \
           grep -q "HELLO WORLD" /tmp/text-lab/output/uppercase.txt; then
            print_color "$GREEN" "  ✓ Text converted to uppercase"
            ((score++))
        else
            print_color "$RED" "  ✗ Case conversion incorrect"
        fi
    else
        print_color "$RED" "  ✗ File output/uppercase.txt not found"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now master:"
        echo "  • Viewing and extracting from files (head/tail)"
        echo "  • Filtering with grep"
        echo "  • Field extraction with cut"
        echo "  • Numeric and alphabetic sorting"
        echo "  • Text transformation with tr"
        echo "  • Piping commands for complex operations"
        echo ""
        echo "These skills are essential for daily sysadmin work!"
    elif [ $score -ge 4 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're getting it! Review the missed sections."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Keep practicing - text processing is fundamental!"
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

TEXT VIEWING TOOLS
─────────────────────────────────────────────────────────────────
less    Interactive pager (q to quit, / to search)
more    Older pager (less featured)
head    Show first N lines
tail    Show last N lines
cat     Display entire file
tac     Display file in reverse


FIELD EXTRACTION
─────────────────────────────────────────────────────────────────
cut -d DELIM -f FIELDS file
  -d:     Delimiter
  -f1     First field
  -f1,3   Fields 1 and 3
  -f1-3   Fields 1 through 3


SORTING
─────────────────────────────────────────────────────────────────
sort file
  -n      Numeric sort
  -r      Reverse (descending)
  -nr     Numeric descending
  -t:     Field delimiter
  -k2     Sort by field 2
  -u      Unique (remove duplicates)


TEXT TRANSFORMATION
─────────────────────────────────────────────────────────────────
tr SET1 SET2
  [:lower:]  Lowercase letters
  [:upper:]  Uppercase letters
  [:digit:]  Digits
  [:alpha:]  Letters
  [:space:]  Whitespace


COMMON PATTERNS
─────────────────────────────────────────────────────────────────
Monitor log:
  tail -f /var/log/syslog

Extract field and sort:
  cut -d: -f1 /etc/passwd | sort

Skip header:
  tail -n +2 file.csv

Find top 10:
  sort -nr data.txt | head -10


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. tail -f for monitoring active logs
2. Always use -n with sort for numbers
3. Pipe commands: tool1 | tool2 | tool3
4. tail -n +2 skips header lines
5. tr for case conversion and character replacement

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/text-lab 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

# Execute the main framework
main "$@"
