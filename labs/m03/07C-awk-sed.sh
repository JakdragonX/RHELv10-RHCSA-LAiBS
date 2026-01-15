#!/bin/bash
# labs/13-awk-sed.sh
# Lab: Advanced Text Processing (awk and sed)
# Difficulty: Intermediate
# RHCSA Objective: Use awk and sed for text processing

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Advanced Text Processing (awk and sed)"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    rm -rf /tmp/awk-sed-lab 2>/dev/null || true
    
    # Create working directory
    mkdir -p /tmp/awk-sed-lab/{data,configs,results}
    
    # Create passwd-style file for awk practice
    cat > /tmp/awk-sed-lab/data/users.txt << 'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
alice:x:1001:1001:Alice Smith:/home/alice:/bin/bash
bob:x:1002:1002:Bob Jones:/home/bob:/bin/bash
charlie:x:1003:1003:Charlie Brown:/home/charlie:/bin/zsh
diana:x:1004:1004:Diana Prince:/home/diana:/bin/bash
eve:x:1005:1005:Eve Adams:/home/eve:/bin/sh
frank:x:1006:1006:Frank Castle:/home/frank:/bin/bash
grace:x:1007:1007:Grace Hopper:/home/grace:/bin/bash
EOF

    # Create CSV-style sales data
    cat > /tmp/awk-sed-lab/data/sales.csv << 'EOF'
Product,Price,Quantity,Revenue
Laptop,1200,5,6000
Mouse,25,50,1250
Keyboard,75,30,2250
Monitor,300,10,3000
Headphones,50,25,1250
Webcam,80,15,1200
USB-Cable,10,100,1000
Docking-Station,200,8,1600
External-Drive,120,12,1440
RAM-Module,150,20,3000
EOF

    # Create log file for awk filtering
    cat > /tmp/awk-sed-lab/data/server.log << 'EOF'
2025-01-14 10:00:00 user:alice action:login status:success
2025-01-14 10:05:00 user:bob action:login status:success
2025-01-14 10:10:00 user:alice action:file_upload status:success
2025-01-14 10:15:00 user:charlie action:login status:failed
2025-01-14 10:20:00 user:bob action:file_delete status:success
2025-01-14 10:25:00 user:diana action:login status:success
2025-01-14 10:30:00 user:alice action:logout status:success
2025-01-14 10:35:00 user:charlie action:login status:failed
2025-01-14 10:40:00 user:eve action:file_upload status:failed
2025-01-14 10:45:00 user:bob action:logout status:success
EOF

    # Create config file for sed practice
    cat > /tmp/awk-sed-lab/configs/app.conf << 'EOF'
# Application Configuration
server_name=localhost
port=8080
debug_mode=true
max_connections=100
timeout=30
database_host=localhost
database_port=5432
database_name=myapp
cache_enabled=false
log_level=DEBUG
EOF

    # Create file with passwords for sed redaction
    cat > /tmp/awk-sed-lab/configs/credentials.txt << 'EOF'
username: admin
password: SecretPass123
api_key: abc123def456
database_password: MyDBPass789
email: admin@example.com
smtp_password: EmailPass456
EOF

    # Create HTML file for sed practice
    cat > /tmp/awk-sed-lab/data/template.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>COMPANY_NAME Website</title>
</head>
<body>
    <h1>Welcome to COMPANY_NAME</h1>
    <p>Contact us at: EMAIL_ADDRESS</p>
    <p>Phone: PHONE_NUMBER</p>
    <footer>© 2025 COMPANY_NAME. All rights reserved.</footer>
</body>
</html>
EOF

    # Fix ownership
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" /tmp/awk-sed-lab 2>/dev/null || true
    fi
    
    echo "  ✓ Created user data files"
    echo "  ✓ Created CSV data"
    echo "  ✓ Created log files"
    echo "  ✓ Created config files"
    echo "  ✓ Ready for awk and sed practice"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic command line and text processing
  • Understanding of delimited files
  • Familiarity with pipes

Commands You'll Use:

awk:
  • awk '{print}' file              Print all lines
  • awk '{print $1}' file           Print first field
  • awk '{print $1, $3}' file       Print fields 1 and 3
  • awk -F: '{print $1}' file       Use : as delimiter
  • awk '/pattern/ {action}' file   Pattern matching
  • awk '$3 > 100 {print}' file     Conditional filtering
  • awk 'NR > 1 {print}' file       Skip header (line > 1)

sed:
  • sed 's/old/new/' file           Substitute first occurrence
  • sed 's/old/new/g' file          Substitute all (global)
  • sed 's/old/new/gi' file         Case-insensitive global
  • sed -i 's/old/new/g' file       In-place editing
  • sed '/pattern/d' file           Delete matching lines
  • sed -n '5,10p' file             Print lines 5-10 only

Key Concepts:

awk:
  • Field-oriented text processing
  • $1, $2, $3 = fields 1, 2, 3
  • $0 = entire line
  • NR = line number (Number of Records)
  • -F sets field separator

sed:
  • Stream editor (line-by-line)
  • s/old/new/ = substitute
  • /g = global (all occurrences)
  • -i = in-place edit
  • -n = suppress automatic printing

Why This Matters:
  awk is perfect for column-based data (CSV, logs, /etc/passwd)
  sed is perfect for search-and-replace in configs and scripts
  Together they're essential for automation and text manipulation
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're automating data extraction and configuration file updates.
Use awk for field extraction and filtering, sed for text substitution.

LAB DIRECTORY: /tmp/awk-sed-lab
  (All file paths in this lab are relative to this directory)

OBJECTIVES:
Complete these tasks to master awk and sed:

  1. Extract usernames from passwd-style file
     • File: data/users.txt (colon-delimited)
     • Extract ONLY the username (first field)
     • Save to: results/usernames.txt

  2. Extract high-value products from sales data
     • File: data/sales.csv (comma-delimited)
     • Find products with Price > 100
     • Print: Product and Price columns
     • Skip the header row
     • Save to: results/high-value-products.txt

  3. Extract failed login attempts
     • File: data/server.log (space-delimited)
     • Find lines containing "status:failed"
     • Print ONLY the username (field 3, remove "user:" prefix)
     • Save to: results/failed-users.txt

  4. Replace localhost with production hostname
     • File: configs/app.conf
     • Replace ALL occurrences of "localhost" with "prod.example.com"
     • Save to: results/app.conf.updated
     • Don't modify the original!

  5. Redact passwords in credentials file
     • File: configs/credentials.txt
     • Replace any text after "password:" or "password :" with "********"
     • This includes: password, database_password, smtp_password
     • Save to: results/credentials.redacted

  6. Customize HTML template with sed
     • File: data/template.html
     • Replace: COMPANY_NAME with "Acme Corp"
     • Replace: EMAIL_ADDRESS with "info@acme.com"
     • Replace: PHONE_NUMBER with "555-1234"
     • Save to: results/customized.html

HINTS:
  awk:
    • -F sets delimiter: awk -F: means colon-delimited
    • $1 is first field, $2 is second, etc.
    • /pattern/ {action} filters by pattern
    • $N > 100 filters by numeric comparison
    • NR > 1 skips first line (header)
  
  sed:
    • s/old/new/ replaces first occurrence per line
    • s/old/new/g replaces ALL occurrences (global)
    • Multiple replacements: sed -e 's/.../.../' -e 's/.../.../'
    • Save output: sed 's/old/new/g' file > newfile

SUCCESS CRITERIA:
  • You can extract fields with awk
  • You can filter data with awk patterns
  • You can replace text with sed
  • You understand field separators
  • You know when to use awk vs sed
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Extract usernames (field 1) → results/usernames.txt
  ☐ 2. Find products > $100, show Product & Price → results/high-value-products.txt
  ☐ 3. Extract users from failed logins → results/failed-users.txt
  ☐ 4. Replace "localhost" with "prod.example.com" → results/app.conf.updated
  ☐ 5. Redact all passwords with "********" → results/credentials.redacted
  ☐ 6. Customize HTML template → results/customized.html
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
You're using awk for data extraction and sed for text substitution.
These are essential automation tools for system administrators.

Working directory: /tmp/awk-sed-lab
EOF
}

# STEP 1: Extract usernames with awk
show_step_1() {
    cat << 'EOF'
TASK: Extract usernames from passwd-style file

You have a colon-delimited file similar to /etc/passwd.
Extract ONLY the username field.

What to do:
  • File: data/users.txt
  • Format: username:x:uid:gid:fullname:home:shell
  • Extract: username (first field)
  • Save to: results/usernames.txt

Tools available:
  • awk - field-oriented text processor
  • -F: - set field delimiter to colon
  • {print $1} - print first field

Think about:
  • What's the delimiter in this file?
  • Which field number is the username?
  • How do you specify delimiter with awk?
  • How do you print a specific field?

Expected result:
  results/usernames.txt should contain:
  root
  daemon
  bin
  alice
  bob
  (etc.)
EOF
}

validate_step_1() {
    if [ ! -f "/tmp/awk-sed-lab/results/usernames.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/usernames.txt not found"
        return 1
    fi
    
    # Check if it contains expected usernames
    if ! grep -q "^alice$" /tmp/awk-sed-lab/results/usernames.txt || \
       ! grep -q "^root$" /tmp/awk-sed-lab/results/usernames.txt; then
        echo ""
        print_color "$RED" "✗ File doesn't contain expected usernames"
        return 1
    fi
    
    # Check that it's ONLY usernames (no colons)
    if grep -q ':' /tmp/awk-sed-lab/results/usernames.txt; then
        echo ""
        print_color "$RED" "✗ File contains extra data (should be usernames only)"
        echo "  Extract only the first field"
        return 1
    fi
    
    local count=$(wc -l < /tmp/awk-sed-lab/results/usernames.txt)
    if [ "$count" -ne 10 ]; then
        echo ""
        print_color "$RED" "✗ Found $count lines (expected 10)"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/awk-sed-lab
  awk -F: '{print $1}' data/users.txt > results/usernames.txt

Breaking down the awk command:
  
  awk -F: '{print $1}' data/users.txt
      ││   └────┬───
      ││        └─ Action: print first field
      │└─ Set field separator to colon
      └─ awk command

How awk processes the file:
  
  Line: "alice:x:1001:1001:Alice Smith:/home/alice:/bin/bash"
  
  awk splits by : delimiter:
  $1 = "alice"
  $2 = "x"
  $3 = "1001"
  $4 = "1001"
  $5 = "Alice Smith"
  $6 = "/home/alice"
  $7 = "/bin/bash"
  
  {print $1} outputs: "alice"

awk field reference:
  $0    Entire line
  $1    First field
  $2    Second field
  $3    Third field
  $NF   Last field
  $(NF-1)  Second-to-last field

awk field separator:
  Default: whitespace (space/tab)
  -F:   Colon
  -F,   Comma
  -F'\t'  Tab

Alternative syntax:
  # Using BEGIN block to set separator:
  awk 'BEGIN {FS=":"} {print $1}' data/users.txt
  
  # Print multiple fields:
  awk -F: '{print $1, $3}' data/users.txt
  # Output: alice 1001

Real-world examples:
  # Extract usernames from /etc/passwd:
  awk -F: '{print $1}' /etc/passwd
  
  # Extract users with UID >= 1000:
  awk -F: '$3 >= 1000 {print $1}' /etc/passwd
  
  # Print username and home directory:
  awk -F: '{print $1, $6}' /etc/passwd
  
  # Count number of fields:
  awk -F: '{print NF}' file

Verification:
  head -5 results/usernames.txt
  wc -l results/usernames.txt
  # Should show 10 lines

EOF
}

hint_step_2() {
    echo "  Use awk with -F, (comma), filter \$2 > 100, print \$1 and \$2, skip NR > 1"
}

# STEP 2: Filter high-value products
show_step_2() {
    cat << 'EOF'
TASK: Extract products with price over $100

You have CSV sales data. Find expensive products.

What to do:
  • File: data/sales.csv
  • Format: Product,Price,Quantity,Revenue
  • Find: Products where Price > 100
  • Extract: Product name (field 1) and Price (field 2)
  • Skip: Header row (first line)
  • Save to: results/high-value-products.txt

Tools available:
  • awk - with conditions
  • -F, - comma delimiter
  • NR > 1 - skip first line (line Number > 1)
  • $2 > 100 - filter by price

Think about:
  • What's the delimiter?
  • Which field is the price?
  • How do you skip the header?
  • How do you filter by numeric value?
  • How do you print multiple fields?

Expected result:
  Should contain products like:
  Laptop 1200
  Monitor 300
  (only products over $100)
EOF
}

validate_step_2() {
    if [ ! -f "/tmp/awk-sed-lab/results/high-value-products.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/high-value-products.txt not found"
        return 1
    fi
    
    # Check if header is excluded
    if grep -q "Product" /tmp/awk-sed-lab/results/high-value-products.txt; then
        echo ""
        print_color "$RED" "✗ File contains header (should be skipped)"
        return 1
    fi
    
    # Check that it only contains high-value products
    if grep -q "Mouse" /tmp/awk-sed-lab/results/high-value-products.txt; then
        echo ""
        print_color "$RED" "✗ File contains products under $100"
        echo "  Filter with: \$2 > 100"
        return 1
    fi
    
    # Check if it contains expected products
    if ! grep -q "Laptop" /tmp/awk-sed-lab/results/high-value-products.txt || \
       ! grep -q "Monitor" /tmp/awk-sed-lab/results/high-value-products.txt; then
        echo ""
        print_color "$RED" "✗ Missing expected high-value products"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/awk-sed-lab
  awk -F, 'NR > 1 && $2 > 100 {print $1, $2}' data/sales.csv > results/high-value-products.txt

Breaking down the awk command:
  
  awk -F, 'NR > 1 && $2 > 100 {print $1, $2}' data/sales.csv
      ││  └──┬──    └──┬──   └─────┬────
      ││     │        │            └─ Action: print fields 1 and 2
      ││     │        └─ Condition: price > 100
      ││     └─ Condition: line number > 1 (skip header)
      │└─ Comma delimiter
      └─ awk command

How conditions work:
  
  NR > 1
  • NR = Number of Records (line number)
  • NR > 1 means "line 2 and beyond" (skip first line)
  
  $2 > 100
  • $2 = Second field (Price)
  • > 100 = greater than 100
  
  &&
  • AND operator (both conditions must be true)

What awk does line-by-line:
  
  Line 1: "Product,Price,Quantity,Revenue"
  NR = 1, NR > 1 is FALSE → Skip
  
  Line 2: "Laptop,1200,5,6000"
  NR = 2, NR > 1 is TRUE
  $2 = 1200, $2 > 100 is TRUE
  Both TRUE → Print: Laptop 1200
  
  Line 3: "Mouse,25,50,1250"
  NR = 3, NR > 1 is TRUE
  $2 = 25, $2 > 100 is FALSE
  Not both TRUE → Skip

awk comparison operators:
  ==    Equal
  !=    Not equal
  >     Greater than
  >=    Greater than or equal
  <     Less than
  <=    Less than or equal

awk logical operators:
  &&    AND (both conditions true)
  ||    OR (either condition true)
  !     NOT (negate condition)

More awk filtering examples:
  # Lines where field 3 equals "success":
  awk '$3 == "success" {print}' file
  
  # Lines where UID >= 1000:
  awk -F: '$3 >= 1000 {print $1}' /etc/passwd
  
  # Lines containing "ERROR" with line numbers:
  awk '/ERROR/ {print NR, $0}' log.txt
  
  # Print lines 10-20:
  awk 'NR >= 10 && NR <= 20 {print}' file

Skipping header alternatives:
  # Using NR:
  awk 'NR > 1 {print}' file
  
  # Using FNR (File Number of Records):
  awk 'FNR > 1 {print}' file
  
  # Using tail (outside awk):
  tail -n +2 file | awk '{print}'

Real-world examples:
  # Find large files (over 1GB):
  df -h | awk '$3 > 1 {print $1, $3}'
  
  # Active users (UID >= 1000, shell not nologin):
  awk -F: '$3 >= 1000 && $7 !~ /nologin/ {print $1}' /etc/passwd
  
  # High CPU processes:
  ps aux | awk '$3 > 50 {print $2, $3, $11}'

Verification:
  cat results/high-value-products.txt
  # Should show only products over $100

EOF
}

hint_step_3() {
    echo "  Use awk with /action:login/ && /status:failed/, print \$3, then remove 'user:' prefix"
}

# STEP 3: Extract failed login users
show_step_3() {
    cat << 'EOF'
TASK: Find users with failed login attempts

You have a log file with login attempts. Extract usernames
for failed login attempts only.

What to do:
  • File: data/server.log
  • Find: Lines with "action:login" AND "status:failed"
  • Extract: Username from field 3 (format: "user:alice")
  • Remove: The "user:" prefix (just show "alice")
  • Save to: results/failed-users.txt

Tools available:
  • awk with pattern matching: /pattern/ {action}
  • awk with multiple patterns: /pattern1/ && /pattern2/
  • Multiple approaches for removing prefix

Think about:
  • How do you filter for TWO conditions in awk?
  • Which field contains the username?
  • How do you remove "user:" prefix?

Approaches to consider:
  1. awk with && for multiple patterns
  2. Pipe grep to awk
  3. Use awk pattern matching with sub()

Expected result:
  Should contain only failed LOGIN usernames:
  charlie
  charlie
  (not eve, who had a failed file_upload, not a failed login)
EOF
}

validate_step_3() {
    if [ ! -f "/tmp/awk-sed-lab/results/failed-users.txt" ]; then
        echo ""
        print_color "$RED" "✗ File results/failed-users.txt not found"
        return 1
    fi
    
    # Check if it contains the correct username
    if ! grep -q "charlie" /tmp/awk-sed-lab/results/failed-users.txt; then
        echo ""
        print_color "$RED" "✗ Missing expected usernames"
        return 1
    fi
    
    # Check that "user:" prefix is removed
    if grep -q "user:" /tmp/awk-sed-lab/results/failed-users.txt; then
        echo ""
        print_color "$RED" "✗ 'user:' prefix not removed"
        echo "  Output should be just the username"
        return 1
    fi
    
    # Should have exactly 2 failed attempts (both charlie)
    local count=$(wc -l < /tmp/awk-sed-lab/results/failed-users.txt)
    if [ "$count" -ne 2 ]; then
        echo ""
        print_color "$RED" "✗ Found $count lines (expected 2 failed logins)"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Method 1 - awk with multiple patterns:
  cd /tmp/awk-sed-lab
  awk '/action:login/ && /status:failed/ {sub(/user:/, "", $3); print $3}' data/server.log > results/failed-users.txt

Method 2 - awk piped to sed:
  awk '/action:login/ && /status:failed/ {print $3}' data/server.log | sed 's/user://' > results/failed-users.txt

Method 3 - grep then awk:
  grep 'action:login' data/server.log | grep 'status:failed' | awk '{sub(/user:/, "", $3); print $3}' > results/failed-users.txt

Breaking down Method 1:
  
  awk '/action:login/ && /status:failed/ {sub(/user:/, "", $3); print $3}' data/server.log
      └─────┬──────    └──────┬──────   │└───────┬────────    └───┬──
            │                 │         │        │                 └─ Print modified field 3
            │                 │         │        └─ Remove "user:" from field 3
            │                 │         └─ sub() function
            │                 └─ AND both patterns must match
            └─ Pattern 1: line contains "action:login"
  
  Example line that matches:
  "2025-01-14 10:15:00 user:charlie action:login status:failed"
  
  /action:login/ → TRUE (contains "action:login")
  /status:failed/ → TRUE (contains "status:failed")
  Both TRUE → Execute action
  
  Example line that does NOT match:
  "2025-01-14 10:40:00 user:eve action:file_upload status:failed"
  
  /action:login/ → FALSE (contains "action:file_upload", not login)
  /status:failed/ → TRUE
  Not both TRUE → Skip this line

Why we need BOTH patterns:
  
  If we only use /status:failed/:
  • Matches charlie's failed logins ✓
  • Also matches eve's failed file_upload ✗
  
  We need /action:login/ && /status:failed/:
  • Only matches failed login attempts ✓
  • Skips other failed actions (file_upload, etc.) ✓

awk multiple pattern matching:
  
  /pattern1/ && /pattern2/
  • Both patterns must match (AND)
  
  /pattern1/ || /pattern2/
  • Either pattern can match (OR)
  
  /pattern1/ && !/pattern2/
  • First matches, second does NOT match
  
  Examples:
  # Lines with ERROR and containing "database":
  awk '/ERROR/ && /database/ {print}' log
  
  # Lines with either ERROR or WARNING:
  awk '/ERROR/ || /WARNING/ {print}' log
  
  # Lines with ERROR but NOT containing "ignore":
  awk '/ERROR/ && !/ignore/ {print}' log

Real-world examples:
  # Failed SSH logins only (not other SSH events):
  awk '/sshd/ && /Failed password/ {print}' /var/log/auth.log
  
  # Apache 500 errors for specific domain:
  awk '/example.com/ && /500/ {print}' /var/log/apache/access.log
  
  # Successful logins during business hours:
  awk '/login/ && /success/ && /09:|10:|11:|12:|13:|14:|15:|16:|17:/ {print}' app.log

Verification:
  cat results/failed-users.txt
  # Should show:
  # charlie
  # charlie
  # (no eve, because her failure was file_upload, not login)

EOF
}

hint_step_4() {
    echo "  Use sed 's/localhost/prod.example.com/g' - the g means global (all occurrences)"
}

# STEP 4: Replace with sed
show_step_4() {
    cat << 'EOF'
TASK: Update configuration file for production

Replace all localhost references with production hostname.

What to do:
  • File: configs/app.conf
  • Replace: ALL occurrences of "localhost"
  • With: "prod.example.com"
  • Save to: results/app.conf.updated
  • Don't modify the original file!

Tools available:
  • sed - stream editor
  • s/old/new/ - substitute
  • g - global flag (all occurrences per line)

Think about:
  • What's the sed substitution syntax?
  • Why do you need the 'g' flag?
  • How do you save to a different file?

Important:
  Without 'g': Only first "localhost" per line is replaced
  With 'g': ALL "localhost" occurrences are replaced

Expected result:
  results/app.conf.updated should have:
  server_name=prod.example.com
  database_host=prod.example.com
  (both instances of "localhost" replaced)
EOF
}

validate_step_4() {
    if [ ! -f "/tmp/awk-sed-lab/results/app.conf.updated" ]; then
        echo ""
        print_color "$RED" "✗ File results/app.conf.updated not found"
        return 1
    fi
    
    # Check if localhost is replaced
    if grep -q "localhost" /tmp/awk-sed-lab/results/app.conf.updated; then
        echo ""
        print_color "$RED" "✗ File still contains 'localhost'"
        echo "  Make sure to use /g flag for global replacement"
        return 1
    fi
    
    # Check if replacement exists
    if ! grep -q "prod.example.com" /tmp/awk-sed-lab/results/app.conf.updated; then
        echo ""
        print_color "$RED" "✗ File doesn't contain replacement text"
        return 1
    fi
    
    # Count replacements (should be 2)
    local count=$(grep -c "prod.example.com" /tmp/awk-sed-lab/results/app.conf.updated)
    if [ "$count" -ne 2 ]; then
        echo ""
        print_color "$RED" "✗ Expected 2 replacements, found $count"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/awk-sed-lab
  sed 's/localhost/prod.example.com/g' configs/app.conf > results/app.conf.updated

Breaking down sed:
  
  sed 's/localhost/prod.example.com/g' configs/app.conf
      │└────┬───  └────────┬──────── │
      │     │              │          └─ Global: all occurrences
      │     │              └─ Replacement text
      │     └─ Pattern to find
      └─ Substitute command
  
  > results/app.conf.updated
  • Redirect output to new file

sed substitution syntax:
  
  s/pattern/replacement/flags
  
  s        Substitute command
  pattern  Text to find (can be regex)
  replacement  Text to replace with
  flags:
    g      Global (all on line)
    i      Case-insensitive
    2      Only 2nd occurrence
    p      Print if substitution made

Why 'g' flag matters:
  
  WITHOUT /g (only first occurrence):
  Input:  "localhost:8080 connects to localhost:5432"
  Output: "prod.example.com:8080 connects to localhost:5432"
          └─ First replaced                    └─ Second NOT replaced
  
  WITH /g (global):
  Input:  "localhost:8080 connects to localhost:5432"
  Output: "prod.example.com:8080 connects to prod.example.com:5432"
          └─ First replaced                    └─ Second replaced

Multiple sed commands:
  
  # Multiple substitutions with -e:
  sed -e 's/old1/new1/g' -e 's/old2/new2/g' file
  
  # Or with semicolons:
  sed 's/old1/new1/g; s/old2/new2/g' file
  
  # Or on separate lines:
  sed '
    s/old1/new1/g
    s/old2/new2/g
  ' file

In-place editing with -i:
  
  # Edit file directly (DANGEROUS):
  sed -i 's/old/new/g' file
  
  # Create backup first (.bak):
  sed -i.bak 's/old/new/g' file
  
  For this lab: Don't use -i, save to new file instead!

Case-insensitive replacement:
  
  sed 's/error/ERROR/gi' file
  • /gi = global + case-insensitive
  • Matches: error, Error, ERROR, ErRoR

Escaping special characters:
  
  If pattern contains /, use different delimiter:
  
  # Replacing /usr/local/bin:
  sed 's/\/usr\/local\/bin/\/opt\/bin/g' file
  # Hard to read! Use | instead:
  sed 's|/usr/local/bin|/opt/bin|g' file

Real-world examples:
  # Update IP address:
  sed 's/192\.168\.1\.100/10\.0\.0\.50/g' config
  
  # Remove comments:
  sed 's/#.*$//' file
  
  # Change debug to production:
  sed 's/DEBUG/INFO/g' app.conf
  
  # Update all URLs:
  sed 's|http://localhost|https://example.com|g' config

sed vs awk:
  
  Use sed when:
  • Simple search-and-replace
  • Modifying config files
  • Removing/changing patterns
  
  Use awk when:
  • Working with columns/fields
  • Filtering by conditions
  • Calculating/summing values

Verification:
  grep prod.example.com results/app.conf.updated
  # Should show both replacements

EOF
}

hint_step_5() {
    echo "  Use sed 's/password.*/password: ********/gi' - matches any password line"
}

# STEP 5: Redact passwords
show_step_5() {
    cat << 'EOF'
TASK: Redact sensitive information from credentials file

Replace password values with asterisks for security.

What to do:
  • File: configs/credentials.txt
  • Find: Lines with "password" (case-insensitive)
  • Replace: Everything after "password:" with " ********"
  • Save to: results/credentials.redacted

Lines to match:
  password: SecretPass123
  database_password: MyDBPass789
  smtp_password: EmailPass456

Tools available:
  • sed with regex
  • .* matches any text
  • i flag for case-insensitive

Think about:
  • How do you match the rest of the line after "password:"?
  • What does .* mean in regex?
  • How do you make it case-insensitive?

Expected result:
  password: ********
  database_password: ********
  smtp_password: ********
EOF
}

validate_step_5() {
    if [ ! -f "/tmp/awk-sed-lab/results/credentials.redacted" ]; then
        echo ""
        print_color "$RED" "✗ File results/credentials.redacted not found"
        return 1
    fi
    
    # Check that passwords are redacted
    if grep -qi "SecretPass\|MyDBPass\|EmailPass" /tmp/awk-sed-lab/results/credentials.redacted; then
        echo ""
        print_color "$RED" "✗ Passwords not redacted"
        return 1
    fi
    
    # Check that redaction exists
    if ! grep -q "\*\*\*\*\*\*\*\*" /tmp/awk-sed-lab/results/credentials.redacted; then
        echo ""
        print_color "$RED" "✗ Missing redaction markers"
        return 1
    fi
    
    # All password lines should be redacted (3 total)
    local count=$(grep -c "password.*\*\*\*\*" /tmp/awk-sed-lab/results/credentials.redacted)
    if [ "$count" -ne 3 ]; then
        echo ""
        print_color "$RED" "✗ Expected 3 redacted password lines, found $count"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/awk-sed-lab
  sed 's/password[: ]*[^ ]*/password: ********/gi' configs/credentials.txt > results/credentials.redacted

Simpler alternative:
  sed 's/\(password\):.*$/\1: ********/gi' configs/credentials.txt > results/credentials.redacted

Breaking down the pattern:
  
  s/password[: ]*[^ ]*/password: ********/gi
    └────┬───   │  └┬ └──┬─
         │      │   │    └─ Any non-space chars (the actual password)
         │      │   └─ Zero or more spaces
         │      └─ Either : or space
         └─ Literal "password"
  
  /gi = global + case-insensitive
  • Matches: password, Password, DATABASE_PASSWORD, etc.

How regex works:
  
  Input: "password: SecretPass123"
  
  password       Matches "password"
  :              Matches ":"
  .*             Matches " SecretPass123"
  
  Replacement: "password: ********"

Regex components used:
  
  .*      Match any character (.), zero or more times (*)
  .+      Match any character, one or more times
  [: ]    Match colon OR space
  [^ ]    Match anything except space
  *       Zero or more of previous
  +       One or more of previous

Understanding .* (greedy matching):
  
  Input: "database_password: MyPass and more text"
  
  password.*
  • .* is GREEDY (matches as much as possible)
  • Matches: "password: MyPass and more text"
  
  If you only want to match until space:
  password[^ ]*
  • [^ ]* = any non-space characters
  • Matches only: "password: MyPass"

Case-insensitive flag:
  
  /gi
  • g = global (all occurrences per line)
  • i = ignore case
  
  Matches:
  password:      ✓
  Password:      ✓
  PASSWORD:      ✓
  database_password:  ✓ (contains "password")
  smtp_password:      ✓ (contains "password")

sed capture groups:
  
  Alternative approach using \( \) for capturing:
  
  sed 's/\(password\):.*$/\1: ********/gi' file
      └────┬───      │   └┬
           │         │    └─ Reference to captured group
           │         └─ Match rest of line
           └─ Capture "password"
  
  \1 refers back to what was captured in \( \)

Real-world redaction examples:
  # Redact credit card numbers:
  sed 's/[0-9]\{16\}/XXXX-XXXX-XXXX-XXXX/g' file
  
  # Redact email addresses:
  sed 's/[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}/***@***.com/g' file
  
  # Redact IP addresses:
  sed 's/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/XXX.XXX.XXX.XXX/g' file
  
  # Redact API keys (32 char hex):
  sed 's/api_key=[a-f0-9]\{32\}/api_key=REDACTED/g' file

Multiple patterns:
  # Redact multiple sensitive fields:
  sed -e 's/password.*/password: ********/gi' \
      -e 's/api_key.*/api_key: ********/gi' \
      -e 's/secret.*/secret: ********/gi' file

Verification:
  cat results/credentials.redacted
  # Should show ******** for all password values

EOF
}

hint_step_6() {
    echo "  Use sed with multiple -e: sed -e 's/COMPANY_NAME/Acme Corp/g' -e '...'"
}

# STEP 6: Template substitution
show_step_6() {
    cat << 'EOF'
TASK: Customize HTML template with sed

Replace placeholder text in HTML template.

What to do:
  • File: data/template.html
  • Replace these placeholders:
    - COMPANY_NAME → "Acme Corp"
    - EMAIL_ADDRESS → "info@acme.com"
    - PHONE_NUMBER → "555-1234"
  • Save to: results/customized.html

Tools available:
  • sed with multiple substitutions
  • -e flag for each substitution

Think about:
  • How do you do multiple replacements?
  • Do you need separate sed commands?
  • Can you chain them?

Expected result:
  HTML file with all placeholders replaced with actual values
EOF
}

validate_step_6() {
    if [ ! -f "/tmp/awk-sed-lab/results/customized.html" ]; then
        echo ""
        print_color "$RED" "✗ File results/customized.html not found"
        return 1
    fi
    
    # Check that all placeholders are replaced
    if grep -q "COMPANY_NAME\|EMAIL_ADDRESS\|PHONE_NUMBER" /tmp/awk-sed-lab/results/customized.html; then
        echo ""
        print_color "$RED" "✗ Some placeholders not replaced"
        return 1
    fi
    
    # Check that replacements exist
    if ! grep -q "Acme Corp" /tmp/awk-sed-lab/results/customized.html || \
       ! grep -q "info@acme.com" /tmp/awk-sed-lab/results/customized.html || \
       ! grep -q "555-1234" /tmp/awk-sed-lab/results/customized.html; then
        echo ""
        print_color "$RED" "✗ Replacement values not found"
        return 1
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cd /tmp/awk-sed-lab
  sed -e 's/COMPANY_NAME/Acme Corp/g' \
      -e 's/EMAIL_ADDRESS/info@acme.com/g' \
      -e 's/PHONE_NUMBER/555-1234/g' \
      data/template.html > results/customized.html

Alternative (semicolon syntax):
  sed 's/COMPANY_NAME/Acme Corp/g; s/EMAIL_ADDRESS/info@acme.com/g; s/PHONE_NUMBER/555-1234/g' \
      data/template.html > results/customized.html

Breaking down multiple substitutions:
  
  sed -e 's/COMPANY_NAME/Acme Corp/g' \
      -e 's/EMAIL_ADDRESS/info@acme.com/g' \
      -e 's/PHONE_NUMBER/555-1234/g' \
      file
  
  -e    Add another editing command
  \     Line continuation (for readability)
  
  Each -e applies its substitution in sequence

How sed processes the file:
  
  Original line:
  "<h1>Welcome to COMPANY_NAME</h1>"
  
  After first -e:
  "<h1>Welcome to Acme Corp</h1>"
  
  (Other lines processed similarly)

Multiple methods for chaining:
  
  Method 1 - Multiple -e flags:
  sed -e 's/A/B/g' -e 's/C/D/g' file
  
  Method 2 - Semicolons:
  sed 's/A/B/g; s/C/D/g' file
  
  Method 3 - Newlines:
  sed '
    s/A/B/g
    s/C/D/g
  ' file
  
  Method 4 - sed script file:
  cat > script.sed << 'EOF'
  s/A/B/g
  s/C/D/g
  EOF
  sed -f script.sed file

Real-world template examples:
  # Customize nginx config:
  sed -e "s/SERVER_NAME/$hostname/g" \
      -e "s/PORT/$port/g" \
      template.conf > /etc/nginx/sites-available/mysite
  
  # Customize systemd service:
  sed -e "s/USER/$username/g" \
      -e "s/WORKING_DIR/$workdir/g" \
      service.template > /etc/systemd/system/myapp.service
  
  # Generate SQL from template:
  sed -e "s/DATABASE/$dbname/g" \
      -e "s/USERNAME/$user/g" \
      schema.sql.template > schema.sql

Using variables in sed:
  
  company="Acme Corp"
  email="info@acme.com"
  
  # Use double quotes to allow variable expansion:
  sed -e "s/COMPANY_NAME/$company/g" \
      -e "s/EMAIL_ADDRESS/$email/g" \
      template.html > output.html
  
  Note: Use double quotes (") not single quotes (')

Escaping in replacements:
  
  # If replacement contains /, use different delimiter:
  sed 's|OLD_PATH|/usr/local/bin|g' file
  
  # If replacement contains &, escape it:
  sed 's/SYMBOL/\&copy;/g' file

Combined with other tools:
  # Generate config files from template:
  for server in web1 web2 web3; do
    sed "s/SERVER_NAME/$server/g" template.conf > $server.conf
  done

Verification:
  grep -E "Acme Corp|info@acme.com|555-1234" results/customized.html
  # Should show all three replacements

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your awk and sed work..."
    echo ""
    
    # Check 1: Extract usernames
    print_color "$CYAN" "[1/$total] Checking username extraction..."
    if [ -f "/tmp/awk-sed-lab/results/usernames.txt" ]; then
        if grep -q "^alice$" /tmp/awk-sed-lab/results/usernames.txt && \
           ! grep -q ':' /tmp/awk-sed-lab/results/usernames.txt; then
            print_color "$GREEN" "  ✓ Usernames extracted with awk"
            ((score++))
        else
            print_color "$RED" "  ✗ Username extraction incorrect"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 2: High-value products
    print_color "$CYAN" "[2/$total] Checking high-value product filtering..."
    if [ -f "/tmp/awk-sed-lab/results/high-value-products.txt" ]; then
        if grep -q "Laptop" /tmp/awk-sed-lab/results/high-value-products.txt && \
           ! grep -q "Mouse" /tmp/awk-sed-lab/results/high-value-products.txt && \
           ! grep -q "Product" /tmp/awk-sed-lab/results/high-value-products.txt; then
            print_color "$GREEN" "  ✓ Products filtered correctly with awk"
            ((score++))
        else
            print_color "$RED" "  ✗ Product filtering incorrect"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 3: Failed login users
    print_color "$CYAN" "[3/$total] Checking failed login extraction..."
    if [ -f "/tmp/awk-sed-lab/results/failed-users.txt" ]; then
        if grep -q "charlie" /tmp/awk-sed-lab/results/failed-users.txt && \
           ! grep -q "user:" /tmp/awk-sed-lab/results/failed-users.txt; then
            print_color "$GREEN" "  ✓ Failed users extracted with awk"
            ((score++))
        else
            print_color "$RED" "  ✗ Failed user extraction incorrect"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 4: Localhost replacement
    print_color "$CYAN" "[4/$total] Checking localhost replacement..."
    if [ -f "/tmp/awk-sed-lab/results/app.conf.updated" ]; then
        if ! grep -q "localhost" /tmp/awk-sed-lab/results/app.conf.updated && \
           grep -q "prod.example.com" /tmp/awk-sed-lab/results/app.conf.updated; then
            print_color "$GREEN" "  ✓ localhost replaced with sed"
            ((score++))
        else
            print_color "$RED" "  ✗ Replacement incorrect"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 5: Password redaction
    print_color "$CYAN" "[5/$total] Checking password redaction..."
    if [ -f "/tmp/awk-sed-lab/results/credentials.redacted" ]; then
        if ! grep -qi "SecretPass\|MyDBPass\|EmailPass" /tmp/awk-sed-lab/results/credentials.redacted && \
           grep -q "\*\*\*\*\*\*\*\*" /tmp/awk-sed-lab/results/credentials.redacted; then
            print_color "$GREEN" "  ✓ Passwords redacted with sed"
            ((score++))
        else
            print_color "$RED" "  ✗ Password redaction incorrect"
        fi
    else
        print_color "$RED" "  ✗ File not found"
    fi
    echo ""
    
    # Check 6: Template customization
    print_color "$CYAN" "[6/$total] Checking template customization..."
    if [ -f "/tmp/awk-sed-lab/results/customized.html" ]; then
        if ! grep -q "COMPANY_NAME\|EMAIL_ADDRESS\|PHONE_NUMBER" /tmp/awk-sed-lab/results/customized.html && \
           grep -q "Acme Corp" /tmp/awk-sed-lab/results/customized.html; then
            print_color "$GREEN" "  ✓ Template customized with sed"
            ((score++))
        else
            print_color "$RED" "  ✗ Template customization incorrect"
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
        echo "  • awk for field extraction"
        echo "  • awk for filtering and pattern matching"
        echo "  • sed for text substitution"
        echo "  • sed for multiple replacements"
        echo "  • Choosing awk vs sed for each task"
        echo ""
        echo "You can now automate complex text processing tasks!"
    elif [ $score -ge 4 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're getting it! Review the concepts and try again."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "awk and sed take practice - keep working at it!"
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

AWK BASICS
─────────────────────────────────────────────────────────────────
awk '{print $1}' file          Print first field
awk -F: '{print $1}' file      Use : as delimiter
awk '/pattern/ {print}' file   Filter by pattern
awk '$3 > 100 {print}' file    Filter by condition
awk 'NR > 1 {print}' file      Skip first line

Field reference:
$1, $2, $3    Fields 1, 2, 3
$0            Entire line
$NF           Last field
NR            Line number


SED BASICS
─────────────────────────────────────────────────────────────────
sed 's/old/new/' file          Replace first occurrence
sed 's/old/new/g' file         Replace all (global)
sed 's/old/new/gi' file        Case-insensitive global
sed -i 's/old/new/g' file      In-place editing
sed -e 's/A/B/g' -e 's/C/D/g'  Multiple substitutions


AWK VS SED
─────────────────────────────────────────────────────────────────
Use awk for:
  • Field/column extraction
  • Filtering by conditions
  • Working with CSV, logs, /etc/passwd
  • Calculations and summations

Use sed for:
  • Search and replace
  • Configuration file updates
  • Text transformations
  • Removing/adding lines


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. awk uses -F for delimiter
2. sed needs /g for global replacement
3. Use NR > 1 to skip headers
4. Test sed before using -i (in-place)
5. Combine with pipes: awk | sed | sort

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/awk-sed-lab 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

# Execute the main framework
main "$@"
