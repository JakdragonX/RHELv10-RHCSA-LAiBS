#!/bin/bash
# labs/12-grep-regex.sh
# Lab: grep and Regular Expressions
# Difficulty: Intermediate
# RHCSA Objective: Search for patterns using grep and regex

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="grep and Regular Expressions"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    rm -rf /tmp/grep-lab 2>/dev/null || true
    
    # Create working directory
    mkdir -p /tmp/grep-lab/{logs,configs,data,results}
    
    # Create application log with various patterns
    cat > /tmp/grep-lab/logs/app.log << 'EOF'
2025-01-14 10:00:00 INFO Application starting
2025-01-14 10:00:05 INFO Loading configuration
2025-01-14 10:00:10 DEBUG Connecting to database
2025-01-14 10:00:15 INFO Database connected
2025-01-14 10:05:00 ERROR Connection timeout to 192.168.1.100
2025-01-14 10:05:05 ERROR Failed to reach external service
2025-01-14 10:05:10 WARNING Retrying connection
2025-01-14 10:05:15 INFO Connection established
2025-01-14 10:10:00 error Invalid user input
2025-01-14 10:10:05 Error Authentication failed for user alice
2025-01-14 10:10:10 ERROR Permission denied
2025-01-14 10:15:00 INFO User bob logged in
2025-01-14 10:15:05 INFO User Bob created new record
2025-01-14 10:15:10 INFO User BOB updated profile
2025-01-14 10:20:00 WARNING High memory usage: 85%
2025-01-14 10:20:05 WARNING High CPU usage: 92%
2025-01-14 10:20:10 CRITICAL System overload detected
2025-01-14 10:25:00 INFO Backup started
2025-01-14 10:25:05 INFO Backup completed successfully
2025-01-14 10:30:00 DEBUG Cleaning temporary files
EOF

    # Create network log with IP addresses
    cat > /tmp/grep-lab/logs/network.log << 'EOF'
Connection from 192.168.1.10 accepted
Connection from 192.168.1.20 accepted
Connection from 10.0.0.5 rejected
Connection from 192.168.1.100 timeout
Connection from 172.16.0.50 accepted
Connection from 10.0.0.10 rejected
Connection from 192.168.2.15 closed
Connection from 172.16.0.60 closed
Incoming connection 8.8.8.8 external accepted
Incoming connection 1.1.1.1 external accepted
EOF

    # Create config files with various patterns
    cat > /tmp/grep-lab/configs/server.conf << 'EOF'
# Server Configuration
server_name=web01
port=8080
host=0.0.0.0
max_connections=1000

# Database Settings
db_host=localhost
db_port=5432
db_name=production
db_user=admin

# Email Settings
email_enabled=true
email_host=smtp.example.com
email_port=587
email_user=noreply@example.com
EOF

    # Create file with words for regex practice
    cat > /tmp/grep-lab/data/words.txt << 'EOF'
cat
bat
hat
mat
rat
boat
coat
goat
cart
dart
start
heart
cats
bats
hats
catch
batch
match
EOF

    # Create file with various line patterns
    cat > /tmp/grep-lab/data/patterns.txt << 'EOF'
The quick brown fox
the lazy dog sleeps
A bird in the hand
the bird flew away
end of the line
start at the beginning
testing
test
best
rest
beast
feast
EOF

    # Create system info file
    cat > /tmp/grep-lab/data/system.txt << 'EOF'
hostname: server1
ip_address: 192.168.1.50
mac_address: 00:1A:2B:3C:4D:5E
os_version: Ubuntu 24.04 LTS
kernel: 6.8.0-49-generic
uptime: 45 days
memory: 16GB
disk: 500GB SSD
cpu_cores: 8
load_average: 0.50 0.45 0.40
EOF

    # Fix ownership
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" /tmp/grep-lab 2>/dev/null || true
    fi
    
    echo "  ✓ Created log files with patterns"
    echo "  ✓ Created config files"
    echo "  ✓ Created pattern practice files"
    echo "  ✓ Ready for grep practice"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic command line skills
  • Understanding of text files
  • Familiarity with piping

Commands You'll Use:
  • grep         - Search for patterns in text
  • grep -i      - Case-insensitive search
  • grep -v      - Invert match (exclude pattern)
  • grep -c      - Count matching lines
  • grep -n      - Show line numbers
  • grep -r/-R   - Recursive search in directories
  • grep -l      - List only filenames
  • grep -A NUM  - Show NUM lines after match
  • grep -B NUM  - Show NUM lines before match
  • grep -C NUM  - Show NUM lines before and after
  • grep -E      - Extended regex (for +, ?, |, etc.)

Regular Expression Basics:
  Anchors:
    ^       Start of line
    $       End of line
    \b      Word boundary
  
  Wildcards:
    .       Any single character
    *       Zero or more of previous character
    +       One or more (needs grep -E)
    ?       Zero or one (needs grep -E)
  
  Character Classes:
    [abc]   Match a, b, or c
    [a-z]   Match lowercase letters
    [0-9]   Match digits
    [^abc]  Match anything except a, b, or c

Important Notes:
  • Always use single quotes for regex: grep 'pattern' file
  • Use grep -E for extended regex (+, ?, |)
  • Don't confuse regex with shell wildcards (globbing)

Why This Matters:
  grep is one of the most-used tools in Linux. System administrators
  use it daily to search logs, filter output, find configurations,
  and troubleshoot issues.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're troubleshooting system issues and need to search through logs,
configuration files, and data files using grep and regular expressions.

LAB DIRECTORY: /tmp/grep-lab
  (All file paths in this lab are relative to this directory)

OBJECTIVES:
Complete these tasks to master grep and regular expressions:

  1. Find all ERROR messages (case-insensitive)
     • Search logs/app.log for any line containing "error" (any case)
     • Save matching lines to: results/all-errors.txt
     • Count how many error lines exist

  2. Find lines starting with "Connection from"
     • Search logs/network.log for lines that START with "Connection from"
     • Save to: results/connections.txt
     • Use ^ anchor for "start of line"

  3. Find lines ending with "accepted"
     • Search logs/network.log for lines that END with "accepted"
     • Save to: results/accepted-connections.txt
     • Use $ anchor for "end of line"

  4. Find 3-letter words ending in 'at'
     • Search data/words.txt for exactly 3-letter words ending in "at"
     • Examples: cat, bat, hat, mat, rat (but NOT boat, coat, cats)
     • Save to: results/three-letter-at.txt
     • Use word boundary \b and pattern ^..at$

  5. Find IP addresses in private ranges
     • Search logs/network.log for IPs starting with 192.168 or 10.0
     • Save to: results/private-ips.txt
     • Use extended regex with | (OR operator)
     • Hint: grep -E '192\.168|10\.0'

  6. Find all lines containing "the" at START of line (case-insensitive)
     • Search data/patterns.txt
     • Lines must START with "the" (any case)
     • Save to: results/lines-starting-the.txt
     • Combine ^ with -i flag

HINTS:
  • Use single quotes around patterns: grep 'pattern' file
  • -i makes search case-insensitive
  • ^ matches start of line
  • $ matches end of line
  • \b matches word boundary
  • . matches any single character
  • grep -E enables extended regex for | (OR)
  • Remember to escape special characters: \. for literal dot

SUCCESS CRITERIA:
  • You can search with case-insensitive matching
  • You understand line anchors (^ and $)
  • You can use word boundaries
  • You can use extended regex with grep -E
  • You understand when to use single quotes
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Find "error" (any case) → results/all-errors.txt, count matches
  ☐ 2. Lines starting with "Connection from" → results/connections.txt
  ☐ 3. Lines ending with "accepted" → results/accepted-connections.txt
  ☐ 4. 3-letter words ending in "at" → results/three-letter-at.txt
  ☐ 5. IPs starting 192.168 or 10.0 → results/private-ips.txt
  ☐ 6. Lines starting "the" (any case) → results/lines-starting-the.txt
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
You're searching log files and data files using grep and regular
expressions. Master these tools to quickly find information.

Working directory: /tmp/grep-lab
EOF
}

# STEP 1: Case-insensitive search
show_step_1() {
    cat << 'EOF'
TASK: Find all error messages regardless of case

Log files often have inconsistent capitalization. You need to find
ALL error messages: ERROR, error, Error, etc.

What to do:
  • Search logs/app.log for any line containing "error" (any case)
  • Save matching lines to results/all-errors.txt
  • Count how many matches you found

Tools available:
  • grep - search for patterns
  • -i flag - case-insensitive
  • -c flag - count matches

Think about:
  • Which grep flag ignores case?
  • How do you save output to a file?
  • How do you count matching lines?

Expected result:
  results/all-errors.txt should contain lines with:
  - ERROR (uppercase)
  - error (lowercase)  
  - Error (mixed case)
  
  There are 5 total error lines in the file.
EOF
}

validate_step_1() {
    if [ ! -f "/tmp/grep-lab/results/all-errors.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/all-errors.txt not found"
        return 1
    fi
    
    local count=$(wc -l < /tmp/grep-lab/results/all-errors.txt)
    if [ "$count" -ne 5 ]; then
        echo ""
        print_color "$RED" "✗ Found $count lines (expected 5)"
        echo "  Make sure you're using case-insensitive search"
        return 1
    fi
    
    # Verify it contains various case patterns
    if ! grep -q "ERROR" /tmp/grep-lab/results/all-errors.txt || \
       ! grep -q "error" /tmp/grep-lab/results/all-errors.txt || \
       ! grep -q "Error" /tmp/grep-lab/results/all-errors.txt; then
        echo ""
        print_color "$RED" "✗ Missing some error patterns"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cd /tmp/grep-lab
  
  # Search case-insensitively
  grep -i 'error' logs/app.log > results/all-errors.txt
  
  # Count matches
  grep -i -c 'error' logs/app.log
  # Output: 5
  
  # Or count from saved file:
  wc -l results/all-errors.txt

Breaking it down:
  
  grep -i 'error' logs/app.log
       ││  └────┬─────   └──────┬─────
       ││       │                └─ File to search
       ││       └─ Pattern (always in quotes!)
       │└─ Case-insensitive flag
       └─ grep command
  
  > results/all-errors.txt
  • Redirects output to file

Why -i matters:
  
  WITHOUT -i (case-sensitive):
  grep 'error' logs/app.log
  • Finds: "error"
  • Misses: "ERROR", "Error"
  
  WITH -i (case-insensitive):
  grep -i 'error' logs/app.log
  • Finds: "error", "ERROR", "Error", "eRRor"
  • Any case combination matches!

More grep flags:
  -i    Case-insensitive
  -v    Invert (show non-matching lines)
  -c    Count matches
  -n    Show line numbers
  -w    Match whole words only
  -l    List filenames only
  -r    Recursive search

Real-world examples:
  # Find all SSH login failures:
  grep -i 'failed' /var/log/auth.log
  
  # Case-insensitive search for user:
  grep -i 'username' /etc/passwd
  
  # Find warnings or errors:
  grep -iE 'warning|error' app.log

Verification:
  cat results/all-errors.txt
  wc -l results/all-errors.txt
  # Should show: 5

EOF
}

hint_step_2() {
    echo "  Use grep '^Connection from' - the ^ means start of line"
}

# STEP 2: Line start anchor
show_step_2() {
    cat << 'EOF'
TASK: Find lines that start with a specific pattern

Not all lines contain "Connection from" at the start. You need
to find ONLY lines that BEGIN with this exact phrase.

What to do:
  • Search logs/network.log
  • Find lines that START with "Connection from"
  • Save to results/connections.txt

Regular expression needed:
  • ^ means "start of line"
  • Pattern: ^Connection from

Think about:
  • What anchor matches the start of a line?
  • Where does the ^ go in your pattern?
  • Why use single quotes?

Important:
  "Connection from 192.168.1.10" ✓ Starts with pattern
  "  Connection from ..." ✗ Has spaces before
  "New connection from ..." ✗ Doesn't start with pattern

Expected result:
  Should find 8 lines that begin with "Connection from"
EOF
}

validate_step_2() {
    if [ ! -f "/tmp/grep-lab/results/connections.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/connections.txt not found"
        return 1
    fi
    
    local count=$(wc -l < /tmp/grep-lab/results/connections.txt)
    if [ "$count" -ne 8 ]; then
        echo ""
        print_color "$RED" "✗ Found $count lines (expected 8)"
        echo "  Use ^ to match start of line"
        return 1
    fi
    
    # Verify all lines start with "Connection from"
    if ! grep -v '^Connection from' /tmp/grep-lab/results/connections.txt | grep -q .; then
        : # Good, no non-matching lines
    else
        echo ""
        print_color "$RED" "✗ File contains lines not starting with 'Connection from'"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/grep-lab
  grep '^Connection from' logs/network.log > results/connections.txt

Breaking down the regex:
  
  ^Connection from
  │└──────┬──────
  │       └─ Literal text to match
  └─ Anchor: start of line

How ^ works:
  
  Pattern: 'Connection from'
  • Matches ANYWHERE in line:
    "Connection from 192.168.1.10" ✓
    "New connection from ..." ✓ (contains pattern)
    "  Connection from ..." ✓ (contains pattern)
  
  Pattern: '^Connection from'
  • Matches ONLY at START of line:
    "Connection from 192.168.1.10" ✓ (starts with pattern)
    "New connection from ..." ✗ (doesn't start)
    "  Connection from ..." ✗ (starts with space)

Anchors in regex:
  ^     Start of line
  $     End of line
  \b    Word boundary

Examples:
  grep '^ERROR' file
  • Lines starting with "ERROR"
  
  grep '^#' file
  • Lines starting with # (comments)
  
  grep '^$' file
  • Empty lines (start = end, nothing between)
  
  grep '^[0-9]' file
  • Lines starting with a digit

Real-world usage:
  # Find uncommented lines in config:
  grep -v '^#' /etc/ssh/sshd_config
  
  # Find lines starting with specific user:
  grep '^alice:' /etc/passwd
  
  # Find ERROR at line start only:
  grep '^ERROR' /var/log/app.log

Why quotes matter:
  grep ^ERROR file     # Shell might interpret ^
  grep '^ERROR' file   # Safe: shell doesn't touch it

Verification:
  wc -l results/connections.txt
  # Should show: 8
  
  head -3 results/connections.txt
  # All should start with "Connection from"

EOF
}

hint_step_3() {
    echo "  Use grep 'accepted$' - the $ means end of line"
}

# STEP 3: Line end anchor
show_step_3() {
    cat << 'EOF'
TASK: Find lines that end with a specific pattern

You need to find lines that END with "accepted" (not lines that
just contain it somewhere).

What to do:
  • Search logs/network.log
  • Find lines that END with "accepted"
  • Save to results/accepted-connections.txt

Regular expression needed:
  • $ means "end of line"
  • Pattern: accepted$

Think about:
  • What anchor matches the end of a line?
  • Where does the $ go in your pattern?

Important:
  "Connection accepted" ✓ Ends with "accepted"
  "Connection accepted." ✗ Ends with period
  "accepted connection" ✗ "accepted" not at end

Expected result:
  Should find 5 lines ending with "accepted"
EOF
}

validate_step_3() {
    if [ ! -f "/tmp/grep-lab/results/accepted-connections.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/accepted-connections.txt not found"
        return 1
    fi
    
    local count=$(wc -l < /tmp/grep-lab/results/accepted-connections.txt)
    if [ "$count" -ne 5 ]; then
        echo ""
        print_color "$RED" "✗ Found $count lines (expected 5)"
        echo "  Use $ to match end of line"
        return 1
    fi
    
    # Verify all lines end with "accepted"
    if ! grep -v 'accepted$' /tmp/grep-lab/results/accepted-connections.txt | grep -q .; then
        : # Good
    else
        echo ""
        print_color "$RED" "✗ File contains lines not ending with 'accepted'"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/grep-lab
  grep 'accepted$' logs/network.log > results/accepted-connections.txt

Breaking down the regex:
  
  accepted$
  ───┬──── │
     │     └─ Anchor: end of line
     └─ Literal text to match

How $ works:
  
  Pattern: 'accepted'
  • Matches ANYWHERE:
    "Connection accepted" ✓
    "accepted connection" ✓
    "re-accepted request" ✓
  
  Pattern: 'accepted$'
  • Matches ONLY at END:
    "Connection accepted" ✓ (ends with)
    "accepted connection" ✗ (not at end)
    "Connection accepted." ✗ (ends with period)

Combining anchors:
  ^pattern$    Entire line must be exactly "pattern"
  ^$           Empty line (start = end immediately)
  ^.*pattern$  Line must end with "pattern"

Examples:
  grep 'ERROR$' file
  • Lines ending with "ERROR"
  
  grep '\.$' file
  • Lines ending with period (dot must be escaped)
  
  grep '^start.*end$' file
  • Lines starting with "start" and ending with "end"
  
  grep '^[0-9].*[0-9]$' file
  • Lines starting and ending with digits

Real-world usage:
  # Find lines ending with semicolon:
  grep ';$' script.js
  
  # Find shell scripts (ending with .sh):
  ls | grep '\.sh$'
  
  # Find successfully completed jobs:
  grep 'completed$' /var/log/jobs.log
  
  # Find empty lines:
  grep '^$' file

Both anchors together:
  grep '^ERROR.*failed$' log
  • Starts with "ERROR"
  • Ends with "failed"
  • Can have anything in between (. matches any char, * means zero or more)

Verification:
  wc -l results/accepted-connections.txt
  # Should show: 5
  
  tail -2 results/accepted-connections.txt
  # All should end with "accepted"

EOF
}

hint_step_4() {
    echo "  Pattern: ^..at$ where . matches any char, use whole line match"
}

# STEP 4: Specific pattern matching
show_step_4() {
    cat << 'EOF'
TASK: Find exactly 3-letter words ending in "at"

You need precise pattern matching to find ONLY 3-letter words
that end in "at": cat, bat, hat, mat, rat.

NOT: boat (4 letters), cats (ends in 's'), catch (5 letters)

What to do:
  • Search data/words.txt
  • Find words that are EXACTLY 3 letters ending in "at"
  • Save to results/three-letter-at.txt

Regular expression needed:
  • ^ start of line
  • . any single character (matches one letter)
  • .. two characters
  • at literal "at"
  • $ end of line
  
  Pattern: ^..at$

Think about:
  • How many dots do you need for 3 total letters?
  • Why do you need both ^ and $?
  • What does . match?

Expected result:
  Should find: cat, bat, hat, mat, rat (5 words)
  Should NOT find: boat, coat, cats, catch
EOF
}

validate_step_4() {
    if [ ! -f "/tmp/grep-lab/results/three-letter-at.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/three-letter-at.txt not found"
        return 1
    fi
    
    local count=$(wc -l < /tmp/grep-lab/results/three-letter-at.txt)
    if [ "$count" -ne 5 ]; then
        echo ""
        print_color "$RED" "✗ Found $count words (expected 5)"
        echo "  Pattern should be: ^..at$"
        return 1
    fi
    
    # Verify it contains expected words
    if grep -q 'cat' /tmp/grep-lab/results/three-letter-at.txt && \
       grep -q 'bat' /tmp/grep-lab/results/three-letter-at.txt && \
       ! grep -q 'boat' /tmp/grep-lab/results/three-letter-at.txt && \
       ! grep -q 'cats' /tmp/grep-lab/results/three-letter-at.txt; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ Pattern not matching correctly"
        return 1
    fi
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/grep-lab
  grep '^..at$' data/words.txt > results/three-letter-at.txt

Breaking down the regex:
  
  ^..at$
  │││││└─ End of line anchor
  ││││└─ Literal 't'
  │││└─ Literal 'a'
  ││└─ Any character (one letter)
  │└─ Any character (one letter)
  └─ Start of line anchor
  
  Total: 2 any + 'at' = 4 characters, but we want 3?
  No! We want 3 LETTERS total: [any][any][at]
  Pattern: ^[any char][any char]at$

How the pattern works:
  
  ^..at$
  • ^ ensures we start at beginning
  • . matches first letter (c, b, h, m, r)
  • . matches second letter (a)
  • at matches literal "at"
  • $ ensures nothing after "at"
  
  Matches:
  cat    ^cat$    ✓ (c + a + t)
  bat    ^bat$    ✓ (b + a + t)
  mat    ^mat$    ✓ (m + a + t)
  
  Doesn't match:
  boat   ^boat$   ✗ (4 chars, pattern expects 3)
  cats   ^cats$   ✗ (ends with 's', not 'at$')
  at     ^at$     ✗ (2 chars, pattern expects 3)

The dot wildcard:
  .     Matches ANY single character
  ..    Matches any TWO characters
  ...   Matches any THREE characters
  .*    Matches ZERO or more of any character

Examples:
  ^..$        Exactly 2 characters
  ^...$       Exactly 3 characters
  ^....$      Exactly 4 characters
  ^h.t$       h + any char + t (hat, hot, hit, h9t)
  ^.at$       Any char + at (cat, bat, @at, 5at)

Real-world patterns:
  # Find 4-digit numbers:
  grep '^[0-9][0-9][0-9][0-9]$' file
  # or
  grep '^[0-9]\{4\}$' file
  
  # Find 3-letter words starting with 's':
  grep '^s..$' words.txt
  
  # Find lines with exactly 5 characters:
  grep '^.....$' file

Why both anchors matter:
  
  Pattern: ..at (no anchors)
  boat    ✓ Contains "oat" which matches ..at
  
  Pattern: ^..at (only start)
  boat    ✓ Matches from start: "boat" = b o at
  
  Pattern: ..at$ (only end)
  boat    ✓ Matches at end: "boat" = b o at $
  
  Pattern: ^..at$ (both anchors)
  boat    ✗ Too long! Must be EXACTLY 4 chars: ^XXat$

Verification:
  cat results/three-letter-at.txt
  # Should show: cat, bat, hat, mat, rat

EOF
}

hint_step_5() {
    echo "  Use grep -E '192\.168|10\.0' - escape dots, use | for OR"
}

# STEP 5: Extended regex with OR
show_step_5() {
    cat << 'EOF'
TASK: Find private IP addresses using OR operator

You need to find IPs in private ranges: 192.168.x.x or 10.0.x.x

What to do:
  • Search logs/network.log
  • Find lines with IPs starting "192.168" OR "10.0"
  • Save to results/private-ips.txt

Regular expression needed:
  • Use grep -E for extended regex (enables |)
  • | means OR
  • \. is escaped dot (literal period)
  • Pattern: 192\.168|10\.0

Think about:
  • Why use grep -E instead of grep?
  • Why escape the dots with \?
  • What does | do?

Important:
  192.168.1.10   ✓ Starts with 192.168
  10.0.0.5       ✓ Starts with 10.0
  172.16.0.50    ✗ Different private range
  8.8.8.8        ✗ Public IP

Expected result:
  Should find 5 lines with private IPs
EOF
}

validate_step_5() {
    if [ ! -f "/tmp/grep-lab/results/private-ips.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/private-ips.txt not found"
        return 1
    fi
    
    local count=$(wc -l < /tmp/grep-lab/results/private-ips.txt)
    if [ "$count" -ne 5 ]; then
        echo ""
        print_color "$RED" "✗ Found $count lines (expected 5)"
        echo "  Should match 192.168.x.x or 10.0.x.x"
        return 1
    fi
    
    # Verify it contains private IPs only
    if grep -q '172\.16' /tmp/grep-lab/results/private-ips.txt || \
       grep -q '8\.8\.8\.8' /tmp/grep-lab/results/private-ips.txt; then
        echo ""
        print_color "$RED" "✗ File contains non-private IPs"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/grep-lab
  grep -E '192\.168|10\.0' logs/network.log > results/private-ips.txt

Breaking down the regex:
  
  grep -E '192\.168|10\.0'
       ││  └─────┬─────
       ││        └─ Pattern with OR
       │└─ Extended regex flag (required for |)
       └─ grep command
  
  192\.168|10\.0
  ────┬───│ ──┬─
      │   │   └─ OR match "10.0"
      │   └─ OR operator
      └─ Match "192.168"

Why escape dots:
  
  . (unescaped)    Matches ANY character
  192.168          Matches "192A168", "192X168", etc.
  
  \. (escaped)     Matches LITERAL dot
  192\.168         Matches only "192.168"

Extended regex with grep -E:
  
  Basic grep (grep):
  • No need for -E
  • Limited regex: ^, $, ., *, [ ]
  • Can't use: +, ?, |, ( )
  
  Extended grep (grep -E):
  • Enables extended operators
  • Can use: +, ?, |, ( )
  • Required for OR (|)

The OR operator:
  
  pattern1|pattern2
  • Matches EITHER pattern1 OR pattern2
  
  Examples:
  cat|dog          Matches "cat" or "dog"
  ERROR|WARNING    Matches either word
  ^start|end$      Lines starting "start" or ending "end"

Real-world examples:
  # Find errors or warnings:
  grep -E 'ERROR|WARNING|CRITICAL' app.log
  
  # Find multiple users:
  grep -E 'alice|bob|charlie' /etc/passwd
  
  # Find different file types:
  ls | grep -E '\.txt$|\.log$|\.conf$'
  
  # Find different IP ranges:
  grep -E '192\.168|10\.|172\.16' network.log

More extended regex:
  +     One or more (vs * which is zero or more)
  ?     Zero or one (optional)
  ( )   Grouping

  Examples with grep -E:
  'error+'      Matches "error", "errorr", "errorrr"
  'colou?r'     Matches "color" or "colour"
  '(cat|dog)s'  Matches "cats" or "dogs"

Why quotes are critical:
  grep -E 192.168|10.0 file    # Shell interprets | as pipe!
  grep -E '192.168|10.0' file  # Correct: shell doesn't touch it

Verification:
  wc -l results/private-ips.txt
  # Should show: 5
  
  cat results/private-ips.txt
  # Should only show 192.168.x.x and 10.0.x.x

EOF
}

hint_step_6() {
    echo "  Combine ^ with -i: grep -i '^the' file"
}

# STEP 6: Combine case-insensitive with anchor
show_step_6() {
    cat << 'EOF'
TASK: Find lines starting with "the" (any case)

Combine what you've learned: case-insensitive search with
line anchors.

What to do:
  • Search data/patterns.txt
  • Find lines that START with "the" (case doesn't matter)
  • Save to results/lines-starting-the.txt

Think about:
  • What flag makes grep case-insensitive?
  • What anchor matches start of line?
  • Can you combine flags?

Should match:
  "The quick brown fox"     ✓ (starts with "The")
  "the lazy dog"            ✓ (starts with "the")
  "THE END"                 ✓ (starts with "THE")

Should NOT match:
  "In the beginning"        ✗ ("the" not at start)
  "testing"                 ✗ (doesn't start with "the")

Expected result:
  Should find 3 lines
EOF
}

validate_step_6() {
    if [ ! -f "/tmp/grep-lab/results/lines-starting-the.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/lines-starting-the.txt not found"
        return 1
    fi
    
    local count=$(wc -l < /tmp/grep-lab/results/lines-starting-the.txt)
    if [ "$count" -ne 3 ]; then
        echo ""
        print_color "$RED" "✗ Found $count lines (expected 3)"
        echo "  Use -i with ^the pattern"
        return 1
    fi
    
    # Verify correct lines
    if grep -q "^The quick brown" /tmp/grep-lab/results/lines-starting-the.txt && \
       grep -q "^the lazy dog" /tmp/grep-lab/results/lines-starting-the.txt && \
       grep -q "^the bird flew" /tmp/grep-lab/results/lines-starting-the.txt; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ Wrong lines captured"
        return 1
    fi
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/grep-lab
  grep -i '^the' data/patterns.txt > results/lines-starting-the.txt

Breaking it down:
  
  grep -i '^the' data/patterns.txt
       ││  └┬─
       ││   └─ Pattern: start of line + "the"
       │└─ Case-insensitive flag
       └─ grep command

How it works:
  
  -i makes "the" match:
  • the
  • The
  • THE
  • tHe
  • Any case combination
  
  ^ ensures it's at start:
  • "The quick brown" ✓ (starts with)
  • "In the beginning" ✗ (not at start)

Combining flags:
  
  You can combine multiple grep flags:
  
  grep -i pattern file         Case-insensitive
  grep -n pattern file         Show line numbers
  grep -in pattern file        Both! Case-insensitive + line numbers
  grep -inC5 pattern file      Plus 5 lines context

Order doesn't matter:
  grep -in '^the' file
  grep -ni '^the' file
  # Both work the same!

Real-world combinations:
  # Case-insensitive with line numbers:
  grep -in 'error' /var/log/syslog
  
  # Case-insensitive with context:
  grep -iC3 'failed' /var/log/auth.log
  
  # Case-insensitive word match:
  grep -iw 'root' /etc/passwd
  
  # Case-insensitive recursive:
  grep -ir 'password' /etc/
  
  # Case-insensitive count:
  grep -ic 'warning' app.log

Complex example:
  grep -inC2 '^ERROR' /var/log/app.log
  • -i: Case-insensitive
  • -n: Show line numbers
  • -C2: Show 2 lines before and after
  • ^ERROR: Lines starting with "ERROR"

Common flag combinations:
  -in     Case-insensitive with line numbers
  -ir     Case-insensitive recursive search
  -iw     Case-insensitive whole word
  -iv     Case-insensitive invert (exclude)
  -ic     Case-insensitive count
  -il     Case-insensitive list filenames only

Verification:
  cat results/lines-starting-the.txt
  # Should show 3 lines all starting with "the" (any case)

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your grep and regex work..."
    echo ""
    
    # Check 1: Case-insensitive
    print_color "$CYAN" "[1/$total] Checking case-insensitive error search..."
    if [ -f "/tmp/grep-lab/results/all-errors.txt" ]; then
        local count=$(wc -l < /tmp/grep-lab/results/all-errors.txt)
        if [ "$count" -eq 5 ]; then
            print_color "$GREEN" "  ✓ Found all 5 error lines (case-insensitive)"
            ((score++))
        else
            print_color "$RED" "  ✗ Found $count lines (expected 5)"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 2: Start anchor
    print_color "$CYAN" "[2/$total] Checking line start pattern..."
    if [ -f "/tmp/grep-lab/results/connections.txt" ]; then
        local count=$(wc -l < /tmp/grep-lab/results/connections.txt)
        if [ "$count" -eq 8 ]; then
            print_color "$GREEN" "  ✓ Found lines starting with 'Connection from'"
            ((score++))
        else
            print_color "$RED" "  ✗ Found $count lines (expected 8)"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 3: End anchor
    print_color "$CYAN" "[3/$total] Checking line end pattern..."
    if [ -f "/tmp/grep-lab/results/accepted-connections.txt" ]; then
        local count=$(wc -l < /tmp/grep-lab/results/accepted-connections.txt)
        if [ "$count" -eq 5 ]; then
            print_color "$GREEN" "  ✓ Found lines ending with 'accepted'"
            ((score++))
        else
            print_color "$RED" "  ✗ Found $count lines (expected 5)"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 4: Specific pattern
    print_color "$CYAN" "[4/$total] Checking specific pattern matching..."
    if [ -f "/tmp/grep-lab/results/three-letter-at.txt" ]; then
        local count=$(wc -l < /tmp/grep-lab/results/three-letter-at.txt)
        if [ "$count" -eq 5 ]; then
            print_color "$GREEN" "  ✓ Found 3-letter words ending in 'at'"
            ((score++))
        else
            print_color "$RED" "  ✗ Found $count words (expected 5)"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 5: Extended regex
    print_color "$CYAN" "[5/$total] Checking extended regex with OR..."
    if [ -f "/tmp/grep-lab/results/private-ips.txt" ]; then
        local count=$(wc -l < /tmp/grep-lab/results/private-ips.txt)
        if [ "$count" -eq 5 ]; then
            print_color "$GREEN" "  ✓ Found private IP addresses"
            ((score++))
        else
            print_color "$RED" "  ✗ Found $count lines (expected 5)"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 6: Combined flags
    print_color "$CYAN" "[6/$total] Checking combined flags..."
    if [ -f "/tmp/grep-lab/results/lines-starting-the.txt" ]; then
        local count=$(wc -l < /tmp/grep-lab/results/lines-starting-the.txt)
        if [ "$count" -eq 3 ]; then
            print_color "$GREEN" "  ✓ Found lines starting with 'the' (any case)"
            ((score++))
        else
            print_color "$RED" "  ✗ Found $count lines (expected 3)"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now master:"
        echo "  • Case-insensitive searching"
        echo "  • Line anchors (^ and $)"
        echo "  • Pattern wildcards (.)"
        echo "  • Extended regex (grep -E)"
        echo "  • OR operator (|)"
        echo "  • Combining grep flags"
        echo ""
        echo "grep is now your most powerful search tool!"
    elif [ $score -ge 4 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're getting it! Review the regex concepts."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Regular expressions take practice - keep trying!"
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

GREP BASICS
─────────────────────────────────────────────────────────────────
grep 'pattern' file       Basic search
grep -i 'pattern' file    Case-insensitive
grep -v 'pattern' file    Invert (exclude matches)
grep -c 'pattern' file    Count matches
grep -n 'pattern' file    Show line numbers
grep -w 'pattern' file    Match whole words only
grep -r 'pattern' dir     Recursive search


REGULAR EXPRESSION ANCHORS
─────────────────────────────────────────────────────────────────
^        Start of line
$        End of line
\b       Word boundary

Examples:
grep '^ERROR' file        Lines starting with ERROR
grep 'ERROR$' file        Lines ending with ERROR
grep '^ERROR$' file       Lines with only ERROR


WILDCARDS
─────────────────────────────────────────────────────────────────
.        Any single character
*        Zero or more of previous
+        One or more (grep -E required)
?        Zero or one (grep -E required)

Examples:
grep 'h.t' file          hat, hot, h9t
grep 'ca*t' file         ct, cat, caat, caaaat
grep -E 'ca+t' file      cat, caat (but not "ct")


EXTENDED REGEX (grep -E)
─────────────────────────────────────────────────────────────────
|        OR operator
( )      Grouping
+        One or more
?        Zero or one

Examples:
grep -E 'cat|dog' file      Matches "cat" or "dog"
grep -E '(ERROR|WARN)' file Either ERROR or WARN
grep -E 'colou?r' file      color or colour


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Always use single quotes: grep 'pattern' file
2. Use grep -E for extended regex (|, +, ?)
3. Escape special chars: \. for literal dot
4. Combine flags: grep -in '^ERROR'
5. Test patterns incrementally
6. Use man 7 regex for reference

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/grep-lab 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

# Execute the main framework
main "$@"
