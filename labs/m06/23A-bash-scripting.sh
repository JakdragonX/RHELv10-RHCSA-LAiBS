#!/bin/bash
# labs/23A-advanced-scripting.sh
# Lab: Positional Parameters, case, source, and while read
# Difficulty: Intermediate
# RHCSA Objective: Create simple shell scripts; use conditionals and loops

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Positional Parameters, case, source, and while read"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    rm -rf /tmp/lab23a 2>/dev/null || true
    mkdir -p /tmp/lab23a/{scripts,output,config}

    # A structured data file for while read parsing
    cat > /tmp/lab23a/users.csv << 'EOF'
alice:developers:bash
bob:sysadmin:zsh
charlie:developers:bash
diana:dba:sh
EOF

    # A partial /etc/passwd-style file for IFS parsing practice
    cat > /tmp/lab23a/accounts.txt << 'EOF'
webuser:x:1001:1001:Web Application User:/home/webuser:/bin/bash
dbuser:x:1002:1002:Database User:/home/dbuser:/bin/bash
monuser:x:1003:1003:Monitoring User:/home/monuser:/bin/sh
EOF

    # Config file to be sourced
    cat > /tmp/lab23a/config/deploy.conf << 'EOF'
# Deploy configuration — sourced by deploy.sh
APP_NAME="myapp"
DEPLOY_DIR="/tmp/lab23a/output/deploy"
LOG_FILE="/tmp/lab23a/output/deploy.log"
MAX_BACKUPS=3
EOF

    echo "  ✓ Created /tmp/lab23a with sample data"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Lab 24A completion (for-loops, while-loops, if-elif-else, command chaining)
  • Understanding that scripts receive input in multiple ways:
    hardcoded variables, arguments passed at runtime, or sourced config files

Commands You'll Use:
  • source / .     - Execute a file in the current shell (imports its variables)
  • read           - Read a line from stdin into one or more variables
  • IFS            - Internal Field Separator (controls how bash splits input)
  • cut            - Extract fields from delimited text
  • case/esac      - Multi-branch conditional (like a switch statement)
  • shift          - Discard $1 and shift all positional parameters left

KEY CONCEPTS:

  Positional Parameters:
    $0   the script name itself
    $1   first argument passed to the script
    $2   second argument, $3 third, and so on
    $@   all arguments as separate words (use in loops)
    $*   all arguments as a single word (rarely what you want)
    $#   total count of arguments passed

  source vs executing a script:
    ./script.sh  — runs in a SUBSHELL; its variables disappear when done
    source script.sh  — runs in the CURRENT shell; its variables persist
    . script.sh   — identical to source (POSIX spelling)

  IFS (Internal Field Separator):
    Bash uses IFS to split strings into words. Default: space, tab, newline.
    Set IFS=: to split on colons (useful for /etc/passwd-style files).
    Always restore IFS after changing it, or scope it with a subshell.

Files You'll Create:
  • /tmp/lab23a/scripts/greet.sh       - Uses $1, $2 with validation
  • /tmp/lab23a/scripts/dispatch.sh    - Uses case for multi-branch logic
  • /tmp/lab23a/scripts/parse-users.sh - Uses while read + IFS to parse CSV
  • /tmp/lab23a/scripts/deploy.sh      - Sources a config file
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
The team's bash scripts are all hardcoded with fixed paths and usernames.
You need to refactor them to accept arguments at runtime, use sourced config
files for site-specific values, parse structured data files cleanly, and
use case statements to handle multiple command modes in a single script.

BACKGROUND:
These four patterns appear constantly in real RHCSA exam scripts and
production automation: accepting and validating arguments, dispatching
to sub-functions via case, parsing colon- or CSV-delimited files with
while read, and sourcing shared config rather than duplicating values.

OBJECTIVES:
  1. Write greet.sh — accepts a name ($1) and optional title ($2). If no
     name is given, print a usage message and exit 1. Otherwise print:
     "Hello, [title] [name]!" (title defaults to "User" if not provided).
     Validate: the script must exit 1 when called with no arguments.

  2. Write dispatch.sh — accepts one argument (start|stop|status|restart).
     Use a case statement to print a different message for each. For any
     other value print "Unknown command: $1" and exit 1.
     The default (*) case must exit 1.

  3. Write parse-users.sh — reads /tmp/lab23a/users.csv line by line using
     while read with IFS=: splitting each line into three variables
     (username, group, shell). For each user, append a line to
     /tmp/lab23a/output/user-report.txt in this format:
     "User: alice | Group: developers | Shell: bash"

  4. Write deploy.sh — sources /tmp/lab23a/config/deploy.conf to load its
     variables, then uses those variables to:
     - Create $DEPLOY_DIR
     - Write "Deployed $APP_NAME at $(date)" to $LOG_FILE
     Validate: $DEPLOY_DIR must exist and $LOG_FILE must contain "Deployed".

HINTS:
  • [ -z "$1" ] tests if $1 is empty (no argument given)
  • case $1 in start) ... ;; stop) ... ;; *) ... ;; esac
  • while IFS=: read user group shell; do ... done < file
  • source /path/to/file  OR  . /path/to/file — both work on the exam
  • After sourcing, $APP_NAME, $DEPLOY_DIR etc. are available as normal vars

SUCCESS CRITERIA:
  • greet.sh exits 1 with no args; prints greeting with $1 and optional $2
  • dispatch.sh handles start/stop/status/restart and exits 1 for unknown
  • /tmp/lab23a/output/user-report.txt has 4 lines, one per user in the CSV
  • $DEPLOY_DIR exists and $LOG_FILE contains "Deployed"
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. greet.sh — validate $1 exists; print "Hello, ${2:-User} $1!"; exit 1 if no args
  ☐ 2. dispatch.sh — case $1 in start|stop|status|restart with * exit 1 default
  ☐ 3. parse-users.sh — while IFS=: read user group shell; output user-report.txt
  ☐ 4. deploy.sh — source deploy.conf; mkdir $DEPLOY_DIR; write to $LOG_FILE
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "4"
}

scenario_context() {
    cat << 'EOF'
You need to refactor a set of hardcoded scripts to accept arguments,
use sourced config files, parse structured data, and handle multiple
operating modes through a case statement.
EOF
}

# STEP 1: Positional parameters with validation
show_step_1() {
    cat << 'EOF'
TASK: Write greet.sh using positional parameters and argument validation

Requirements:
  • Script: /tmp/lab23a/scripts/greet.sh
  • If called with no arguments: print "Usage: greet.sh <name> [title]" and exit 1
  • If called with one argument ($1 = name): print "Hello, User alice!"
  • If called with two arguments ($1 = name, $2 = title): print "Hello, Dr alice!"
  • Make executable, then test:
      /tmp/lab23a/scripts/greet.sh              # should exit 1
      /tmp/lab23a/scripts/greet.sh alice        # Hello, User alice!
      /tmp/lab23a/scripts/greet.sh alice Dr     # Hello, Dr alice!

Key variables:
  $1   first argument       $#   argument count
  $2   second argument      $0   script name

Default value syntax (no if needed):
  ${2:-User}   means: use $2 if set and non-empty, otherwise use "User"
EOF
}

validate_step_1() {
    local script="/tmp/lab23a/scripts/greet.sh"

    if [ ! -f "$script" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/lab23a/scripts/greet.sh not found"
        return 1
    fi

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        echo "  Fix: chmod +x $script"
        return 1
    fi

    # Test: no arguments should exit 1
    "$script" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ""
        print_color "$RED" "✗ Script should exit 1 when called with no arguments, but it exited 0"
        echo "  Add: [ -z \"\$1\" ] && { echo \"Usage: ...\"; exit 1; }"
        return 1
    fi

    # Test: one argument should produce output containing the name
    local output
    output=$("$script" alice 2>/dev/null)
    if ! echo "$output" | grep -q "alice"; then
        echo ""
        print_color "$RED" "✗ Script with one argument does not include the name in output"
        echo "  Output was: '$output'"
        return 1
    fi

    # Test: two arguments should include both name and title
    output=$("$script" alice Dr 2>/dev/null)
    if ! echo "$output" | grep -q "alice" || ! echo "$output" | grep -q "Dr"; then
        echo ""
        print_color "$RED" "✗ Script with two arguments does not include both name and title"
        echo "  Output was: '$output'"
        return 1
    fi

    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /tmp/lab23a/scripts/greet.sh << 'SCRIPT'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $(basename $0) <name> [title]"
    exit 1
fi

NAME="$1"
TITLE="${2:-User}"

echo "Hello, ${TITLE} ${NAME}!"
SCRIPT

chmod +x /tmp/lab23a/scripts/greet.sh

# Test it:
/tmp/lab23a/scripts/greet.sh              # exits 1, prints usage
echo "Exit code: $?"                      # → 1
/tmp/lab23a/scripts/greet.sh alice        # → Hello, User alice!
/tmp/lab23a/scripts/greet.sh alice Dr     # → Hello, Dr alice!

Key concepts:

  [ -z "$1" ]: -z tests if a string is ZERO length (empty).
    If no argument was given, $1 is empty/unset → -z is true → print usage.
    Always quote: [ -z "$1" ] not [ -z $1 ] (unquoted fails if $1 is unset)

  $(basename $0): $0 is the script's name including path. basename strips
    the path so the usage message shows just the filename, not the full path.

  ${2:-User}: parameter expansion with default value.
    If $2 is unset or empty → substitute "User"
    If $2 has a value → use that value
    Other useful forms:
      ${VAR:-default}    use default if VAR unset or empty
      ${VAR:=default}    set VAR to default if unset or empty (modifies VAR)
      ${VAR:?message}    exit with message if VAR unset or empty
      ${VAR:+other}      use 'other' if VAR IS set (inverse of :-)

  exit 1: terminates the script immediately with exit code 1.
    The calling shell or script can test this: if ./greet.sh; then ...

Verification:
  /tmp/lab23a/scripts/greet.sh; echo $?           # should print 1
  /tmp/lab23a/scripts/greet.sh alice; echo $?     # should print 0

EOF
}

hint_step_2() {
    echo "  case \$1 in"
    echo "    start)  echo 'Starting...' ;;"
    echo "    stop)   echo 'Stopping...' ;;"
    echo "    *)      echo \"Unknown: \$1\"; exit 1 ;;"
    echo "  esac"
}

# STEP 2: case statement
show_step_2() {
    cat << 'EOF'
TASK: Write dispatch.sh using a case statement

Requirements:
  • Script: /tmp/lab23a/scripts/dispatch.sh
  • Accepts one argument: start | stop | status | restart
  • Print a different message for each valid option
  • For any other value (including no argument): print "Unknown command: $1"
    and exit 1
  • Make executable and test all four valid options plus one invalid one

case syntax:
  case $variable in
      pattern1)
          commands
          ;;
      pattern2|pattern3)    # pipe = OR
          commands
          ;;
      *)                    # default (catch-all)
          commands
          ;;
  esac

Why case over if-elif:
  case is cleaner and faster when matching one variable against many fixed
  values. if-elif works but becomes hard to read beyond 3-4 branches.
  case also supports glob patterns: case $file in *.txt) ... ;; esac
EOF
}

validate_step_2() {
    local script="/tmp/lab23a/scripts/dispatch.sh"

    if [ ! -f "$script" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/lab23a/scripts/dispatch.sh not found"
        return 1
    fi

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi

    # Valid commands should exit 0
    for cmd in start stop status restart; do
        "$script" "$cmd" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo ""
            print_color "$RED" "✗ dispatch.sh '$cmd' should exit 0, but exited non-zero"
            return 1
        fi
    done

    # Invalid command should exit 1
    "$script" bogus >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ""
        print_color "$RED" "✗ dispatch.sh with unknown command should exit 1, but exited 0"
        echo "  Add 'exit 1' to the *) default case"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /tmp/lab23a/scripts/dispatch.sh << 'SCRIPT'
#!/bin/bash
case $1 in
    start)
        echo "Starting service..."
        ;;
    stop)
        echo "Stopping service..."
        ;;
    status)
        echo "Service is running"
        ;;
    restart)
        echo "Restarting service..."
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: $(basename $0) {start|stop|status|restart}"
        exit 1
        ;;
esac
SCRIPT

chmod +x /tmp/lab23a/scripts/dispatch.sh

# Test:
/tmp/lab23a/scripts/dispatch.sh start
/tmp/lab23a/scripts/dispatch.sh bogus; echo $?   # → exits 1

Key concepts:

  Pattern syntax:
    start)     exact match
    start|stop) matches either — | means OR inside case patterns
    *.txt)     glob pattern — matches any value ending in .txt
    [Yy]es)    character class — matches "Yes" or "yes"
    *)         matches everything — always put this last

  ;; terminates each branch. Forgetting ;; causes bash to fall through
  into the next branch (unlike C's switch, bash does NOT fall through
  by default — ;; prevents it, but missing it causes a parse error).

  case does not require break (unlike C). Each branch ends at ;;.

  Real-world case pattern — script mode dispatch:
    case $1 in
        -h|--help)    show_help ;;
        -v|--verbose) VERBOSE=1 ;;
        -f|--file)    FILE="$2"; shift ;;  # shift consumes $2
        *)            echo "Unknown option"; exit 1 ;;
    esac

  shift: discards $1 and shifts all other parameters left.
    Before shift: $1="-f" $2="file.txt" $3="other"
    After shift:  $1="file.txt" $2="other"
    Useful for option parsing in loops.

Verification:
  for cmd in start stop status restart bogus; do
      echo -n "$cmd: "
      /tmp/lab23a/scripts/dispatch.sh "$cmd"
  done

EOF
}

hint_step_3() {
    echo "  while IFS=: read user group shell; do"
    echo "    echo \"User: \$user | Group: \$group | Shell: \$shell\""
    echo "  done < /tmp/lab23a/users.csv"
}

# STEP 3: while read with IFS
show_step_3() {
    cat << 'EOF'
TASK: Parse a colon-delimited CSV using while read with IFS

The file /tmp/lab23a/users.csv has this format:
  alice:developers:bash
  bob:sysadmin:zsh

Requirements:
  • Script: /tmp/lab23a/scripts/parse-users.sh
  • Read each line and split on ':' using IFS
  • Assign fields to variables: username, group, shell
  • Append one formatted line per user to /tmp/lab23a/output/user-report.txt:
    "User: alice | Group: developers | Shell: bash"
  • Clear the output file at the start of each run

while read with IFS syntax:
  while IFS=: read username group shell; do
      echo "$username $group $shell"
  done < /tmp/lab23a/users.csv

Why while read instead of for:
  for line in $(cat file): splits on ALL whitespace — breaks on spaces in values
  while read -r line: reads one complete line at a time — handles spaces safely
  -r flag: prevents backslash from being treated as an escape character
EOF
}

validate_step_3() {
    local script="/tmp/lab23a/scripts/parse-users.sh"

    if [ ! -f "$script" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/lab23a/scripts/parse-users.sh not found"
        return 1
    fi

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi

    if [ ! -f "/tmp/lab23a/output/user-report.txt" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/lab23a/output/user-report.txt not created — run the script"
        return 1
    fi

    local line_count
    line_count=$(wc -l < /tmp/lab23a/output/user-report.txt)
    if [ "$line_count" -lt 4 ]; then
        echo ""
        print_color "$RED" "✗ user-report.txt has $line_count lines (expected 4, one per user)"
        return 1
    fi

    # Check that all four usernames appear in the report
    for user in alice bob charlie diana; do
        if ! grep -q "$user" /tmp/lab23a/output/user-report.txt; then
            echo ""
            print_color "$RED" "✗ '$user' not found in user-report.txt"
            return 1
        fi
    done

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /tmp/lab23a/scripts/parse-users.sh << 'SCRIPT'
#!/bin/bash
OUTPUT="/tmp/lab23a/output/user-report.txt"

# Clear output file
> "$OUTPUT"

while IFS=: read -r username group shell; do
    echo "User: $username | Group: $group | Shell: $shell" >> "$OUTPUT"
done < /tmp/lab23a/users.csv

echo "Report written to $OUTPUT"
cat "$OUTPUT"
SCRIPT

chmod +x /tmp/lab23a/scripts/parse-users.sh
/tmp/lab23a/scripts/parse-users.sh

Key concepts:

  IFS=: before read: sets the field separator to colon for this read
    command only. The assignment is scoped to the command — IFS reverts
    after each iteration. This is safer than setting IFS globally.

    Alternative (global, requires restore):
      OLD_IFS=$IFS
      IFS=:
      while read user group shell; do ...; done < file
      IFS=$OLD_IFS

  -r flag: without -r, a backslash at the end of a line is treated as
    a continuation character and the next line is appended. -r treats
    backslashes as literal characters. Always use -r unless you
    specifically need backslash continuation.

  < file redirection to while: the while loop reads from the file via
    stdin redirection. This keeps the loop in the current shell, so
    variables set inside the loop are visible after it. Contrast with:
    cat file | while read ...; done  — this creates a subshell for the
    while body, and any variables you set inside vanish afterward.

  Parsing /etc/passwd the same way:
    while IFS=: read user pass uid gid gecos home shell; do
        echo "$user uses $shell"
    done < /etc/passwd

  Process substitution alternative (avoids subshell issue with pipes):
    while read line; do
        echo "$line"
    done < <(command_that_produces_output)

Verification:
  cat /tmp/lab23a/output/user-report.txt
  wc -l /tmp/lab23a/output/user-report.txt   # should be 4

EOF
}

hint_step_4() {
    echo "  source /tmp/lab23a/config/deploy.conf  (or: . /tmp/lab23a/config/deploy.conf)"
    echo "  After sourcing, \$APP_NAME, \$DEPLOY_DIR, \$LOG_FILE are available"
}

# STEP 4: source / .
show_step_4() {
    cat << 'EOF'
TASK: Write deploy.sh that sources a config file and uses its variables

The config file /tmp/lab23a/config/deploy.conf defines:
  APP_NAME="myapp"
  DEPLOY_DIR="/tmp/lab23a/output/deploy"
  LOG_FILE="/tmp/lab23a/output/deploy.log"
  MAX_BACKUPS=3

Requirements:
  • Script: /tmp/lab23a/scripts/deploy.sh
  • Source the config file at the top of the script
  • Use $DEPLOY_DIR, $APP_NAME, and $LOG_FILE — do NOT hardcode these paths
  • Create $DEPLOY_DIR (mkdir -p)
  • Write "Deployed $APP_NAME at $(date)" to $LOG_FILE
  • Print a summary showing which variables were loaded from config

source syntax:
  source /path/to/file.conf   # bash spelling
  . /path/to/file.conf        # POSIX spelling — identical behavior

Both execute the file in the CURRENT shell, making its variables available
to the rest of the script. Running ./file.conf or bash file.conf would
execute it in a subshell — its variables would disappear immediately.
EOF
}

validate_step_4() {
    local script="/tmp/lab23a/scripts/deploy.sh"

    if [ ! -f "$script" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/lab23a/scripts/deploy.sh not found"
        return 1
    fi

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi

    # Run the script to generate output
    "$script" >/dev/null 2>&1

    if [ ! -d "/tmp/lab23a/output/deploy" ]; then
        echo ""
        print_color "$RED" "✗ \$DEPLOY_DIR (/tmp/lab23a/output/deploy) was not created"
        echo "  Check that you sourced deploy.conf and used \$DEPLOY_DIR"
        return 1
    fi

    if [ ! -f "/tmp/lab23a/output/deploy.log" ]; then
        echo ""
        print_color "$RED" "✗ \$LOG_FILE (/tmp/lab23a/output/deploy.log) was not created"
        return 1
    fi

    if ! grep -q "Deployed" /tmp/lab23a/output/deploy.log; then
        echo ""
        print_color "$RED" "✗ /tmp/lab23a/output/deploy.log does not contain 'Deployed'"
        echo "  Contents: $(cat /tmp/lab23a/output/deploy.log 2>/dev/null)"
        return 1
    fi

    # Check the script actually uses source (not hardcoded paths)
    if ! grep -qE "^(source|\.) " "$script"; then
        echo ""
        print_color "$RED" "✗ Script does not appear to use 'source' or '.' to load config"
        echo "  Add: source /tmp/lab23a/config/deploy.conf"
        return 1
    fi

    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /tmp/lab23a/scripts/deploy.sh << 'SCRIPT'
#!/bin/bash
CONFIG="/tmp/lab23a/config/deploy.conf"

# Verify config exists before sourcing
if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Config file not found: $CONFIG"
    exit 1
fi

# Source the config — loads APP_NAME, DEPLOY_DIR, LOG_FILE, MAX_BACKUPS
source "$CONFIG"

# Use the sourced variables
mkdir -p "$DEPLOY_DIR"
echo "Deployed $APP_NAME at $(date)" >> "$LOG_FILE"

echo "Deploy summary:"
echo "  App:        $APP_NAME"
echo "  Deploy dir: $DEPLOY_DIR"
echo "  Log file:   $LOG_FILE"
echo "  Max backups: $MAX_BACKUPS"
SCRIPT

chmod +x /tmp/lab23a/scripts/deploy.sh
/tmp/lab23a/scripts/deploy.sh

Key concepts:

  source vs subshell execution:
    ./deploy.conf        subshell — variables vanish when done
    bash deploy.conf     subshell — same issue
    source deploy.conf   current shell — variables persist afterward
    . deploy.conf        identical to source (POSIX spelling)

  Why this pattern matters:
    Config files let you separate site-specific values from script logic.
    The same deploy.sh works in dev, staging, and production by pointing
    at different .conf files. The script code never changes.

  Checking the config file exists before sourcing is important: if source
  is given a non-existent file, bash errors out but the script may continue
  executing with undefined variables — leading to confusing failures.

  source in interactive shells:
    You can also use source in your bash session to load environment
    variables from a file without starting a new shell. This is exactly
    what ~/.bashrc does: it's sourced by your login shell.

  Multiple config files / layering:
    source /etc/myapp/defaults.conf   # site-wide defaults
    source ~/.myapp.conf              # user overrides (loaded after, wins)

Verification:
  cat /tmp/lab23a/output/deploy.log   # → Deployed myapp at [timestamp]
  ls /tmp/lab23a/output/deploy/       # directory exists

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=4

    echo "Checking your work..."
    echo ""

    # CHECK 1: greet.sh
    print_color "$CYAN" "[1/$total] Checking greet.sh (positional parameters + validation)..."
    local script="/tmp/lab23a/scripts/greet.sh"
    if [ -x "$script" ]; then
        "$script" >/dev/null 2>&1
        local no_args_exit=$?
        local one_arg_out; one_arg_out=$("$script" alice 2>/dev/null)
        local two_arg_out; two_arg_out=$("$script" alice Dr 2>/dev/null)

        if [ "$no_args_exit" -ne 0 ] && \
           echo "$one_arg_out" | grep -q "alice" && \
           echo "$two_arg_out" | grep -q "alice" && \
           echo "$two_arg_out" | grep -q "Dr"; then
            print_color "$GREEN" "  ✓ Argument validation and default value working"
            ((score++))
        else
            [ "$no_args_exit" -eq 0 ] && print_color "$RED" "  ✗ Should exit 1 with no arguments"
            ! echo "$one_arg_out" | grep -q "alice" && print_color "$RED" "  ✗ Name not in output"
            ! echo "$two_arg_out" | grep -q "Dr" && print_color "$RED" "  ✗ Title not in output"
        fi
    else
        print_color "$RED" "  ✗ greet.sh not found or not executable"
    fi
    echo ""

    # CHECK 2: dispatch.sh
    print_color "$CYAN" "[2/$total] Checking dispatch.sh (case statement)..."
    script="/tmp/lab23a/scripts/dispatch.sh"
    if [ -x "$script" ]; then
        local all_valid=1
        for cmd in start stop status restart; do
            "$script" "$cmd" >/dev/null 2>&1 || { all_valid=0; break; }
        done
        "$script" bogus >/dev/null 2>&1
        local invalid_exit=$?

        if [ "$all_valid" -eq 1 ] && [ "$invalid_exit" -ne 0 ]; then
            print_color "$GREEN" "  ✓ case statement handles all branches correctly"
            ((score++))
        else
            [ "$all_valid" -eq 0 ] && print_color "$RED" "  ✗ A valid command (start/stop/status/restart) returned non-zero"
            [ "$invalid_exit" -eq 0 ] && print_color "$RED" "  ✗ Unknown command should exit 1, not 0"
        fi
    else
        print_color "$RED" "  ✗ dispatch.sh not found or not executable"
    fi
    echo ""

    # CHECK 3: parse-users.sh
    print_color "$CYAN" "[3/$total] Checking parse-users.sh (while read with IFS)..."
    script="/tmp/lab23a/scripts/parse-users.sh"
    if [ -x "$script" ]; then
        "$script" >/dev/null 2>&1
        local report="/tmp/lab23a/output/user-report.txt"
        if [ -f "$report" ]; then
            local lines; lines=$(wc -l < "$report")
            local all_users=1
            for user in alice bob charlie diana; do
                grep -q "$user" "$report" || { all_users=0; break; }
            done
            if [ "$lines" -ge 4 ] && [ "$all_users" -eq 1 ]; then
                print_color "$GREEN" "  ✓ while read parsed all 4 users into user-report.txt"
                ((score++))
            else
                print_color "$RED" "  ✗ user-report.txt has $lines lines or missing users"
            fi
        else
            print_color "$RED" "  ✗ user-report.txt not created — run the script"
        fi
    else
        print_color "$RED" "  ✗ parse-users.sh not found or not executable"
    fi
    echo ""

    # CHECK 4: deploy.sh
    print_color "$CYAN" "[4/$total] Checking deploy.sh (source config file)..."
    script="/tmp/lab23a/scripts/deploy.sh"
    if [ -x "$script" ]; then
        "$script" >/dev/null 2>&1
        local uses_source=0
        grep -qE "^(source|\.) " "$script" && uses_source=1

        if [ "$uses_source" -eq 1 ] && \
           [ -d "/tmp/lab23a/output/deploy" ] && \
           grep -q "Deployed" /tmp/lab23a/output/deploy.log 2>/dev/null; then
            print_color "$GREEN" "  ✓ Config sourced, DEPLOY_DIR created, LOG_FILE written"
            ((score++))
        else
            [ "$uses_source" -eq 0 ] && print_color "$RED" "  ✗ Script does not use source or '.'"
            [ ! -d "/tmp/lab23a/output/deploy" ] && print_color "$RED" "  ✗ \$DEPLOY_DIR not created"
            ! grep -q "Deployed" /tmp/lab23a/output/deploy.log 2>/dev/null && \
                print_color "$RED" "  ✗ 'Deployed' not found in \$LOG_FILE"
        fi
    else
        print_color "$RED" "  ✗ deploy.sh not found or not executable"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "You've covered the four patterns that appear most in real RHCSA exam scripts."
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
# SOLUTION (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — greet.sh (positional parameters):
─────────────────────────────────────────────────────────────────
  #!/bin/bash
  [ -z "$1" ] && { echo "Usage: $(basename $0) <name> [title]"; exit 1; }
  echo "Hello, ${2:-User} ${1}!"

  $1, $2: positional parameters from command line
  ${2:-User}: use $2 if set, otherwise "User"
  -z: test for empty string


STEP 2 — dispatch.sh (case statement):
─────────────────────────────────────────────────────────────────
  #!/bin/bash
  case $1 in
      start)   echo "Starting..." ;;
      stop)    echo "Stopping..." ;;
      status)  echo "Status: running" ;;
      restart) echo "Restarting..." ;;
      *)       echo "Unknown: $1"; exit 1 ;;
  esac

  *) is the catch-all default — always put it last
  ;; terminates each branch (required — not optional like C's break)
  | between patterns means OR: start|begin)


STEP 3 — parse-users.sh (while read + IFS):
─────────────────────────────────────────────────────────────────
  #!/bin/bash
  > /tmp/lab23a/output/user-report.txt
  while IFS=: read -r username group shell; do
      echo "User: $username | Group: $group | Shell: $shell" \
          >> /tmp/lab23a/output/user-report.txt
  done < /tmp/lab23a/users.csv

  IFS=: scoped to read command; -r prevents backslash interpretation
  < file feeds the file into the while loop via stdin


STEP 4 — deploy.sh (source):
─────────────────────────────────────────────────────────────────
  #!/bin/bash
  source /tmp/lab23a/config/deploy.conf
  mkdir -p "$DEPLOY_DIR"
  echo "Deployed $APP_NAME at $(date)" >> "$LOG_FILE"

  source runs the config in the current shell — variables persist
  . is the POSIX equivalent of source


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The Four Input Patterns for Scripts:
  1. Hardcoded:   VAR="value" inside the script
  2. Arguments:   $1, $2, $@ — passed at runtime
  3. Sourced:     . config.conf — loaded from external file
  4. Prompted:    read -p "Enter value: " VAR — interactive

When to use which:
  Arguments → when values vary per invocation (filename, username)
  source    → when values are site-specific but stable (paths, app names)
  read      → when the script needs interactive user input
  Hardcoded → only for truly constant values that never change

while read vs for loop for files:
  for line in $(cat file)  → splits on whitespace; breaks on spaces in data
  while read -r line       → reads one full line; safe for any content
  Always prefer while read for line-by-line file processing.


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Know $1, $2, $@, $#, $0 — positional parameters appear on every exam
2. case is cleaner than long if-elif chains — use it when matching one var
3. while IFS=: read — the standard pattern for parsing /etc/passwd-style files
4. source / . — both spellings work; . is more portable (POSIX)
5. ${VAR:-default} — parameter expansion with fallback; avoids if blocks
6. Always validate arguments: [ -z "$1" ] && { echo "Usage..."; exit 1; }

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/lab23a 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

main "$@"
