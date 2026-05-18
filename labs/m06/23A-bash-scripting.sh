#!/bin/bash
# labs/23A-bash-scripting.sh
# Lab: Positional Parameters, case, source, and while read
# Difficulty: Intermediate
# RHCSA Objective: Create simple shell scripts; use conditionals and loops

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Positional Parameters, case, source, and while read"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

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
  • Completion of Lab 24A (for-loops, while-loops, if-else, command chaining)
  • Comfort writing and running a basic bash script with #!/bin/bash

What This Lab Teaches (one concept per step):
  Step 1 — Positional parameters: $1, $2, and ${VAR:-default}
  Step 2 — case statements: multi-branch dispatch on a single variable
  Step 3 — while read + IFS: parsing a colon-delimited file line by line
  Step 4 — source / .: loading variables from a config file

Each step shows you the syntax first, then asks you to write a short script
(5-10 lines) that uses it. The solutions are minimal on purpose — the goal
is to get the pattern into muscle memory.

Files You'll Create:
  • /tmp/lab23a/scripts/greet.sh        - 6 lines
  • /tmp/lab23a/scripts/dispatch.sh     - 12 lines
  • /tmp/lab23a/scripts/parse-users.sh  - 8 lines
  • /tmp/lab23a/scripts/deploy.sh       - 8 lines
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're writing your first real bash scripts. Each one is short, but each
introduces one new pattern you'll use constantly on the RHCSA exam and in
day-to-day sysadmin work.

OBJECTIVES:
  1. Write greet.sh — a script that accepts a name as $1 and prints a greeting.
     If no name is given, it prints a usage message and exits with code 1.

  2. Write dispatch.sh — a script that accepts a mode word (start|stop|status)
     and prints a different message for each, using a case statement.

  3. Write parse-users.sh — a script that reads a colon-delimited file
     line by line and prints a formatted summary of each line.

  4. Write deploy.sh — a script that loads variables from an external config
     file using source, then uses those variables to do its work.

HINTS:
  • Each step shows you the syntax before asking you to write it
  • All four scripts are short — resist the urge to over-engineer
  • Test each script from the command line immediately after writing it

SUCCESS CRITERIA:
  • All four scripts exist, are executable, and produce the expected output
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. greet.sh — print "Hello, $1!" or usage message if no argument given
  ☐ 2. dispatch.sh — case statement: start|stop|status prints a message; * exits 1
  ☐ 3. parse-users.sh — while IFS=: read to print each user from users.csv
  ☐ 4. deploy.sh — source deploy.conf; use its variables to create dir and write log
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
Four short scripts, one new pattern each. Read the syntax explanation in
each step before writing — the goal is to recognise and reproduce these
patterns, not to figure them out from scratch.
EOF
}

# STEP 1: Positional parameters with validation
show_step_1() {
    cat << 'EOF'
CONCEPT: Positional Parameters and Argument Validation
──────────────────────────────────────────────────────
When you run a script, any words after the script name become positional
parameters:

  ./greet.sh alice Dr
  #           $1    $2

  $1   → "alice"   (first argument)
  $2   → "Dr"      (second argument)
  $#   → 2         (total count of arguments)
  $0   → "./greet.sh" (the script name itself)

To check if no argument was given, test if $1 is empty:
  if [ -z "$1" ]; then        # -z means "zero length" (empty string)
      echo "Usage: $0 <name>"
      exit 1
  fi

To use a default value when $2 is not provided:
  TITLE="${2:-User}"          # uses "User" if $2 is unset or empty
  echo "Hello, ${TITLE} ${1}!"

──────────────────────────────────────────────────────
TASK: Write greet.sh using the pattern above

Requirements:
  • Script: /tmp/lab23a/scripts/greet.sh
  • If $1 is empty: print "Usage: greet.sh <name>" and exit 1
  • Otherwise: print "Hello, ${2:-User} $1!"
  • Make executable, then test:
      /tmp/lab23a/scripts/greet.sh              → exits 1
      /tmp/lab23a/scripts/greet.sh alice        → Hello, User alice!
      /tmp/lab23a/scripts/greet.sh alice Dr     → Hello, Dr alice!
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
    echo "Usage: greet.sh <name>"
    exit 1
fi
echo "Hello, ${2:-User} ${1}!"
SCRIPT

chmod +x /tmp/lab23a/scripts/greet.sh

Two things to remember:
  [ -z "$1" ]: the -z flag tests for an empty string. Always quote "$1" —
    if $1 is unset and unquoted, bash removes it entirely and [ -z ] gets
    no arguments at all, which causes a different error.

  ${2:-User}: the :- operator provides a fallback. Read it as "use $2,
    or if that's empty, use User". This avoids needing a second if block.

Verification:
  /tmp/lab23a/scripts/greet.sh; echo "exit: $?"         # → exit: 1
  /tmp/lab23a/scripts/greet.sh alice                     # → Hello, User alice!
  /tmp/lab23a/scripts/greet.sh alice Dr                  # → Hello, Dr alice!

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
CONCEPT: case Statements
────────────────────────
case matches one variable against a list of patterns. It's cleaner than
a long if-elif chain when you're checking a single value:

  case $1 in
      start)
          echo "Starting..."
          ;;
      stop)
          echo "Stopping..."
          ;;
      *)                      # * matches anything not caught above
          echo "Unknown: $1"
          exit 1
          ;;
  esac

Rules:
  • Each branch ends with ;; (required — don't forget it)
  • * is the catch-all default, always put it last
  • Separate multiple patterns with |: start|begin) matches either word
  • esac closes the block (case spelled backwards)

────────────────────────────────────────────
TASK: Write dispatch.sh using a case statement

Requirements:
  • Script: /tmp/lab23a/scripts/dispatch.sh
  • start   → print "Starting service"
  • stop    → print "Stopping service"
  • status  → print "Service is running"
  • anything else → print "Unknown: $1" and exit 1
  • Make executable and test each branch:
      ./dispatch.sh start
      ./dispatch.sh bogus; echo $?    # → 1
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
    start)   echo "Starting service" ;;
    stop)    echo "Stopping service" ;;
    status)  echo "Service is running" ;;
    *)       echo "Unknown: $1"; exit 1 ;;
esac
SCRIPT

chmod +x /tmp/lab23a/scripts/dispatch.sh

One thing to remember:
  The ;; after each branch is not optional. Missing it causes a parse error.
  Each branch can also be written on one line as shown above — fine for
  short commands; use the multi-line form from the concept box when the
  body is longer than one command.

Verification:
  /tmp/lab23a/scripts/dispatch.sh start          # → Starting service
  /tmp/lab23a/scripts/dispatch.sh bogus; echo $? # → exit 1

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
CONCEPT: while read with IFS for Parsing Delimited Files
─────────────────────────────────────────────────────────
IFS (Internal Field Separator) controls how bash splits a line into words.
By default it splits on spaces. Setting IFS=: splits on colons instead —
which is exactly what you need for /etc/passwd-style files.

This pattern reads a file line by line and splits each line on ':':

  while IFS=: read -r field1 field2 field3; do
      echo "$field1 and $field2"
  done < /path/to/file

The file /tmp/lab23a/users.csv looks like:
  alice:developers:bash
  bob:sysadmin:zsh

So with IFS=: read -r username group shell:
  • On the first iteration: username=alice  group=developers  shell=bash
  • On the second:          username=bob    group=sysadmin    shell=zsh

Why use this instead of for $(cat file)?
  for line in $(cat file) splits on ALL whitespace and breaks if any
  field contains a space. while read processes one complete line at a time
  and is safe for any content.

The -r flag prevents backslashes in the file from being treated as escape
characters. Always use -r unless you specifically need that behaviour.

─────────────────────────────────────────────────────────
TASK: Write parse-users.sh using while IFS=: read

Requirements:
  • Script: /tmp/lab23a/scripts/parse-users.sh
  • Read /tmp/lab23a/users.csv line by line, splitting on ':'
  • For each line print to /tmp/lab23a/output/user-report.txt:
    "User: alice | Group: developers | Shell: bash"
  • Clear the output file at the start (> "$OUTPUT")
  • Make executable and run it
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
> "$OUTPUT"

while IFS=: read -r username group shell; do
    echo "User: $username | Group: $group | Shell: $shell" >> "$OUTPUT"
done < /tmp/lab23a/users.csv

cat "$OUTPUT"
SCRIPT

chmod +x /tmp/lab23a/scripts/parse-users.sh
/tmp/lab23a/scripts/parse-users.sh

One thing to remember:
  The redirection goes at the end of 'done', not at the top of the loop.
  done < file feeds the file into the whole while loop as stdin. If you
  put 'cat file |' before the while instead, the loop runs in a subshell
  and any variables you set inside it vanish when the loop ends.

Verification:
  cat /tmp/lab23a/output/user-report.txt   # should have 4 lines

EOF
}

hint_step_4() {
    echo "  source /tmp/lab23a/config/deploy.conf  (or: . /tmp/lab23a/config/deploy.conf)"
    echo "  After sourcing, \$APP_NAME, \$DEPLOY_DIR, \$LOG_FILE are available"
}

# STEP 4: source / .
show_step_4() {
    cat << 'EOF'
CONCEPT: source and . — Loading Variables from a Config File
─────────────────────────────────────────────────────────────
When you run a script normally (./script.sh or bash script.sh), it runs
in its own subshell. Any variables it sets disappear when it finishes.

source (or its POSIX alias .) runs a file in the CURRENT shell instead,
so its variables are available for the rest of your script:

  source /path/to/config.conf    # bash spelling
  . /path/to/config.conf         # POSIX spelling — identical

The config file /tmp/lab23a/config/deploy.conf looks like:
  APP_NAME="myapp"
  DEPLOY_DIR="/tmp/lab23a/output/deploy"
  LOG_FILE="/tmp/lab23a/output/deploy.log"

After sourcing that file, $APP_NAME, $DEPLOY_DIR, and $LOG_FILE are
all available as normal variables in your script.

─────────────────────────────────────────────────────────
TASK: Write deploy.sh that sources deploy.conf and uses its variables

Requirements:
  • Script: /tmp/lab23a/scripts/deploy.sh
  • Source /tmp/lab23a/config/deploy.conf
  • Create $DEPLOY_DIR with mkdir -p
  • Write "Deployed $APP_NAME at $(date)" to $LOG_FILE
  • Do NOT hardcode any paths — use the variables from the config file
  • Make executable and run it
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
source /tmp/lab23a/config/deploy.conf

mkdir -p "$DEPLOY_DIR"
echo "Deployed $APP_NAME at $(date)" >> "$LOG_FILE"

echo "Done — log at $LOG_FILE"
SCRIPT

chmod +x /tmp/lab23a/scripts/deploy.sh
/tmp/lab23a/scripts/deploy.sh

One thing to remember:
  source runs the config file in the same shell process as deploy.sh, so
  $APP_NAME and friends are set for the rest of the script. If you used
  bash deploy.conf or ./deploy.conf instead, they'd run in a child process
  and those variables would be lost the moment the child exits.

Verification:
  cat /tmp/lab23a/output/deploy.log   # → Deployed myapp at [timestamp]
  ls /tmp/lab23a/output/deploy/       # directory should exist

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
COMPLETE SOLUTION REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — greet.sh (positional parameters + default value):
  #!/bin/bash
  if [ -z "$1" ]; then echo "Usage: greet.sh <name>"; exit 1; fi
  echo "Hello, ${2:-User} ${1}!"

  $1, $2 = arguments passed at runtime
  ${2:-User} = use $2, or "User" if $2 is empty
  [ -z "$VAR" ] = true if VAR is empty (zero length)


STEP 2 — dispatch.sh (case statement):
  #!/bin/bash
  case $1 in
      start)   echo "Starting service" ;;
      stop)    echo "Stopping service" ;;
      status)  echo "Service is running" ;;
      *)       echo "Unknown: $1"; exit 1 ;;
  esac

  *) = catch-all default (always last)
  ;; = required branch terminator
  pattern1|pattern2) = OR match


STEP 3 — parse-users.sh (while IFS=: read):
  #!/bin/bash
  > /tmp/lab23a/output/user-report.txt
  while IFS=: read -r username group shell; do
      echo "User: $username | Group: $group | Shell: $shell" \
          >> /tmp/lab23a/output/user-report.txt
  done < /tmp/lab23a/users.csv

  IFS=: splits each line on colons
  -r prevents backslash interpretation
  done < file = feed file as stdin (keeps loop in current shell)


STEP 4 — deploy.sh (source):
  #!/bin/bash
  source /tmp/lab23a/config/deploy.conf
  mkdir -p "$DEPLOY_DIR"
  echo "Deployed $APP_NAME at $(date)" >> "$LOG_FILE"

  source = run file in current shell; its variables persist
  . = identical POSIX spelling of source


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always quote "$1" in tests — unquoted $1 disappears if it's unset
2. case ;; is not optional — missing it is a syntax error
3. done < file, not cat file | while — the pipe creates a subshell
4. source and . are identical — use whichever you remember
5. ${VAR:-default} is shorter than an if block for optional arguments

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
