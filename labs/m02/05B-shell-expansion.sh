#!/bin/bash
# labs/06-shell-expansion-lab.sh
# Lab: Shell Expansion, Variables, and Quoting
# Difficulty: Intermediate
# RHCSA Objective: Configure local storage - Understanding shell behavior

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Shell Expansion, Variables, and Quoting"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up any previous attempts
    rm -rf /tmp/expansion-lab 2>/dev/null || true
    unset LAB_VAR LAB_PATH LAB_COUNT 2>/dev/null || true
    
    # Create working directory
    mkdir -p /tmp/expansion-lab/{test1,test2,test3}
    
    # Create sample files for globbing practice
    touch /tmp/expansion-lab/file{1..5}.txt
    touch /tmp/expansion-lab/data{A..C}.log
    touch /tmp/expansion-lab/test1/report-{2024,2025}.pdf
    touch /tmp/expansion-lab/test2/backup.tar.gz
    touch /tmp/expansion-lab/test3/doc{1..3}.md
    


#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic command line navigation
  • Understanding of variables concept
  • Familiarity with file paths

Commands You'll Use:
  • echo    - Display text and expansion results
  • export  - Make variables available to child processes
  • env     - Display environment variables
  • ls      - List files (to see globbing results)
  • touch   - Create empty files

Core Concepts You'll Learn:
  • Shell Expansion Order: The exact sequence Bash processes commands
  • Variable Expansion: $VAR and ${VAR} syntax
  • Command Substitution: $(command) and `command`
  • Globbing/Wildcards: *, ?, [], {}
  • Quoting: Single quotes '', double quotes "", backslash \
  • Escaping: Preventing special character interpretation

Why This Matters:
  Shell expansion is the "hidden machinery" that processes your commands
  before they run. Understanding it prevents confusion and enables you to
  write more powerful commands and scripts.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're writing shell scripts and interactive commands, but sometimes the
results aren't what you expect. Variables don't expand, wildcards match
the wrong files, or commands produce mysterious errors.

BACKGROUND:
Bash doesn't execute your commands exactly as typed. Before running anything,
it performs multiple transformation steps called "shell expansion." These
expansions happen in a specific order, and understanding this order is
crucial for predicting command behavior.

The shell expansion sequence:
  1. Brace expansion       {}
  2. Tilde expansion       ~
  3. Parameter expansion   $VAR
  4. Command substitution  $()
  5. Arithmetic expansion  $(())
  6. Word splitting        (spaces)
  7. Globbing             * ? []
  8. Quote removal        ' " \



HINTS:
  • Use 'echo' to see expansion results before running commands
  • Single quotes prevent ALL expansion
  • Double quotes allow $variable and $(command) expansion
  • Always quote variables when they might contain spaces
  • Globbing happens LAST (after variable expansion)

SUCCESS CRITERIA:
  • You can predict what expansions will occur
  • You understand the order of expansion
  • You know when to quote and when not to
  • You can debug unexpected command behavior
  • You can write commands that handle spaces and special characters
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create variables and export them to environment
  ☐ 2. Use brace expansion to create multiple files efficiently
  ☐ 3. Practice command substitution to capture output
  ☐ 4. Use glob patterns to match specific files
  ☐ 5. Properly quote variables with spaces
  ☐ 6. Escape special characters in filenames
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
You're learning how Bash processes commands before executing them. This
"shell expansion" is the hidden machinery that transforms what you type
into what actually runs. Understanding it is crucial for writing effective
commands and scripts.
EOF
}

# STEP 1: Variables and export





  • MY_APP_DIR="/opt/myapp"
    - Creates a variable in the current shell
    - The quotes preserve any spaces in the value
  
  • export MY_APP_DIR
    - Marks the variable for export to child processes
    - Any subprocess (script, command) will inherit this
  
  • FILE_COUNT=42
    - Creates a LOCAL variable
    - Only available in current shell
    - NOT passed to child processes

CRITICAL SYNTAX RULE:
  NO SPACES around the equals sign!
  
  RIGHT: VAR=value
  WRONG: VAR = value    # Tries to run command 'VAR'
  WRONG: VAR= value     # Runs 'value' with empty VAR
  WRONG: VAR =value     # Runs command '=' with VAR as argument

Variable naming conventions:
  • Use UPPERCASE for environment variables (convention)
  • Use lowercase for local script variables
  • Use underscores to separate words
  • Start with letter or underscore (not number)

Verification:
  # Display the variables:
  echo $MY_APP_DIR
  echo $FILE_COUNT
  
  # Check if MY_APP_DIR is in environment:
  env | grep MY_APP_DIR
  # Should show: MY_APP_DIR=/opt/myapp
  
  # Check if FILE_COUNT is NOT in environment:
  env | grep FILE_COUNT
  # Should show nothing (it's local only)

When to export:
  ✓ Variables that scripts or programs need
  ✓ PATH, HOME, LANG, etc. (system variables)
  ✓ Configuration that child processes use
  
  ✗ Temporary calculations in current shell
  ✗ Loop counters and local script variables
  ✗ Sensitive data you don't want leaked to subprocesses

EOF
}

hint_step_2() {
    echo "  Use {1..5} for numbers, {A..C} for letters, {a,b,c} for explicit lists"
}

# STEP 2: Brace expansion
show_step_2() {
    cat << 'EOF'
TASK: Use brace expansion to create files efficiently

Use a single command with brace expansion to create these files
in /tmp/expansion-lab/:
  • log1.txt, log2.txt, log3.txt
  • backup-A.tar, backup-B.tar, backup-C.tar

Requirements:
  • Use two separate commands (one for each set)
  • Use brace expansion: {1..3} or {A..C}
  • Pattern: touch /tmp/expansion-lab/prefix{expansion}.suffix

Commands you'll use:
  • touch - Create empty files
  • {}    - Brace expansion syntax

What you're learning:
  Brace expansion happens FIRST, before any other expansion. It's a
  powerful way to generate multiple arguments to a command without
  typing them all out.

Brace expansion patterns:
  • {1..5}      - Sequence: 1 2 3 4 5
  • {a..e}      - Letters: a b c d e
  • {A..C}      - Uppercase: A B C
  • {a,b,c}     - Explicit list
  • {01..10}    - Zero-padded: 01 02 03 ... 10
  • prefix{1,2}suffix - Multiple combinations

Important: Brace expansion does NOT look at filesystem. It just
generates text patterns!
EOF
}

validate_step_2() {
    local missing=()
    
    # Check for log files
    for i in 1 2 3; do
        if [ ! -f "/tmp/expansion-lab/log$i.txt" ]; then
            missing+=("log$i.txt")
        fi
    done
    
    # Check for backup files
    for letter in A B C; do
        if [ ! -f "/tmp/expansion-lab/backup-$letter.tar" ]; then
            missing+=("backup-$letter.tar")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        print_color "$RED" "✗ Missing files: ${missing[*]}"
        echo "  Create log files: touch /tmp/expansion-lab/log{1..3}.txt"
        echo "  Create backups: touch /tmp/expansion-lab/backup-{A..C}.tar"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  touch /tmp/expansion-lab/log{1..3}.txt
  touch /tmp/expansion-lab/backup-{A..C}.tar

Breaking it down:
  • touch /tmp/expansion-lab/log{1..3}.txt
    
    Expansion process:
    1. Bash sees {1..3}
    2. Expands to: log1.txt log2.txt log3.txt
    3. Final command: touch /tmp/expansion-lab/log1.txt log2.txt log3.txt
  
  • touch /tmp/expansion-lab/backup-{A..C}.tar
    
    Expansion process:
    1. Bash sees {A..C}
    2. Expands to: backup-A.tar backup-B.tar backup-C.tar
    3. Creates three files in one command

Brace expansion rules:
  • Happens FIRST (before variable expansion, before globbing)
  • Does NOT check if files exist
  • Generates text combinations
  • No spaces allowed inside braces (unless explicitly wanted)

More brace expansion examples:
  # Create numbered directories:
  mkdir dir{1..10}
  
  # Create nested structure:
  mkdir -p project/{src,bin,doc}/{main,test}
  # Creates: project/src/main, project/src/test, etc.
  
  # Multiple expansions in one command:
  touch file{1..3}.{txt,log}
  # Creates: file1.txt file1.log file2.txt file2.log file3.txt file3.log
  
  # Backup with date:
  cp config.txt config-{2024..2026}-backup.txt
  
  # Zero-padded sequences:
  touch photo_{001..010}.jpg
  # Creates: photo_001.jpg, photo_002.jpg, ..., photo_010.jpg

Common mistakes:
  ✗ {1-5}      # Wrong syntax, use ..
  ✓ {1..5}     # Correct
  
  ✗ {1, 2, 3}  # Spaces create literal braces
  ✓ {1,2,3}    # Correct (no spaces)
  
  ✗ $VAR{1..3} # Variable expands AFTER brace expansion
  ✓ {1..3}$VAR # Works (brace first, then variable)

Verification:
  ls /tmp/expansion-lab/log*.txt
  ls /tmp/expansion-lab/backup-*.tar

EOF
}

hint_step_3() {
    echo "  Use $(command) to capture output: FILES=$(ls /tmp) captures file list"
}

# STEP 3: Command substitution




solution_step_3() {
    cat << 'EOF'


  • find /tmp/expansion-lab -name "*.txt"
    - Searches recursively for .txt files
    - Outputs one filename per line
  
  • | wc -l
    - Counts the lines from find
    - Outputs a number
  
  • $(...)
    - Command substitution
    - Captures the output (the number)
    - Replaces $(…) with that output
  
  • TXT_COUNT=$(...)
    - Stores the result in a variable
  
  • summary-${TXT_COUNT}.txt
    - Uses ${} form for clarity
    - Expands to something like: summary-8.txt

Expansion order:
  1. $(find ...) runs and outputs a number (e.g., 8)
  2. TXT_COUNT=8 is executed
  3. In the second command, ${TXT_COUNT} expands to 8
  4. Final command: touch /tmp/expansion-lab/summary-8.txt

Why ${VAR} instead of $VAR?
  When concatenating with text, ${} is clearer:
  
  # Ambiguous:
  echo "$VARsuffix"    # Is variable name "VARsuffix"?
  
  # Clear:
  echo "${VAR}suffix"  # Variable is "VAR", suffix is literal

Nested command substitution:
  You can nest $(command substitution):
  
  OWNER=$(stat -c '%U' $(find /tmp -name "file.txt"))
  
  Evaluation:
  1. Inner $(find ...) runs first
  2. Outer $(stat ...) uses that result

Real-world examples:
  # Get today's date in filename:
  BACKUP=backup-$(date +%Y-%m-%d).tar.gz
  
  # Count logged-in users:
  USERS=$(who | wc -l)
  
  # Get kernel version:
  KERNEL=$(uname -r)
  
  # Get disk usage:
  USAGE=$(df -h / | tail -1 | awk '{print $5}')

Verification:
  echo $TXT_COUNT
  # Should show a number
  
  ls /tmp/expansion-lab/summary-*.txt
  # Should show the created file

Old vs new syntax:
  # Old (backticks):
  VAR=`command`
  
  # New (preferred):
  VAR=$(command)
  
  Why prefer $()? 
  • Easier to read
  • Can nest: $(command $(inner))
  • Works better in quotes

EOF
}

hint_step_4() {
    echo "  Use ls /tmp/expansion-lab/data*.log to match data files, */report* for reports"
}

# STEP 4: Globbing (wildcards)
show_step_4() {
    cat << 'EOF'

  • *     - Matches zero or more characters
  • ?     - Matches exactly one character
  • [abc] - Matches any character in the set
  • [a-z] - Matches any character in the range

What you're learning:
  Globbing happens LATE in expansion (step 7 of 8). This means variables
  expand before globbing occurs. Understanding this order prevents
  confusing errors.

Critical: The shell does globbing, not the command!
  When you type: ls *.txt
  The shell expands *.txt to a list of files
  Then runs: ls file1.txt file2.txt file3.txt
EOF
}



solution_step_4() {
    cat << 'EOF'


  • ls /tmp/expansion-lab/*.log
    
    Expansion process:
    1. Shell sees *.log
    2. Globbing expands it to: dataA.log dataB.log dataC.log
    3. Shell runs: ls dataA.log dataB.log dataC.log
  
  • find /tmp/expansion-lab -name "report*.pdf"
    
    Note: -name "report*.pdf" is QUOTED
    Why? Because we want find to do the matching, not the shell!
    
    If we wrote: find ... -name report*.pdf (no quotes)
    The shell would expand report*.pdf before find sees it
    This could match wrong files or cause errors

Glob pattern reference:
  Pattern  | Matches              | Example
  ---------|----------------------|------------------
  *        | Any characters       | *.txt → all .txt files
  ?        | Single character     | file?.txt → file1.txt, fileA.txt
  [abc]    | One of: a, b, or c   | file[123].txt → file1.txt, file2.txt, file3.txt
  [a-z]    | Range a through z    | [a-c]* → starts with a, b, or c
  [!abc]   | NOT a, b, or c       | file[!0-9].txt → no digits

Common glob patterns:
  # All text files:
  ls *.txt
  
  # Files starting with 'log':
  ls log*
  
  # Files with single-digit number:
  ls file[0-9].txt
  
  # Hidden files (dot files):
  ls .*
  
  # Everything except .txt:
  ls !(*.txt)   # Requires extglob option

Globbing vs find:
  # Shell globbing (shell expands before ls runs):
  ls /tmp/*.txt
  - Only matches in /tmp directly
  - Shell does the expansion
  
  # find does its own matching (recursive):
  find /tmp -name "*.txt"
  - Searches all subdirectories
  - find does the matching (so we quote the pattern)

Why quote glob patterns in find/grep?
  # WRONG:
  find /tmp -name *.txt
  # Shell expands *.txt before find sees it
  # If current dir has file.txt, this becomes:
  # find /tmp -name file.txt (only matches that exact name!)
  
  # RIGHT:
  find /tmp -name "*.txt"
  # find receives the literal pattern "*.txt"
  # find then matches against all files it finds

Variables and globs:
  # If variable contains glob pattern:
  PATTERN="*.txt"
  ls $PATTERN        # Glob expands
  ls "$PATTERN"      # Literal "*.txt" (quote prevents globbing)
  
  # Be careful:
  FILES=$(ls *.txt)  # Word splitting can break filenames with spaces!
  FILES="$(ls *.txt)" # Better, preserves spaces

Verification:
  ls /tmp/expansion-lab/*.log
  # Should show: dataA.log  dataB.log  dataC.log
  
  echo $REPORT_COUNT
  # Should show: 2 (report-2024.pdf and report-2025.pdf)

EOF
}

hint_step_5() {
    echo "  Always quote variables: cp \"\$SOURCE\" \"\$DEST\" preserves spaces"
}

# STEP 5: Quoting variables with spaces
show_step_5() {
    cat << 'EOF'
TASK: Handle filenames with spaces using proper quoting

Create a variable containing "test file.txt" and use it to create
a file in /tmp/expansion-lab/. Then copy it to a new name with spaces.

Requirements:
  • FILENAME="test file.txt"
  • Create: /tmp/expansion-lab/test file.txt
  • Copy to: /tmp/expansion-lab/new test.txt
  • CRITICAL: Quote all variable references!

Commands:
  • touch "$FILENAME"
  • cp "$SOURCE" "$DESTINATION"

What you're learning:
  Unquoted variables undergo word splitting. This breaks filenames with
  spaces into multiple arguments, causing mysterious errors.
  
  This is one of the most common shell scripting bugs!

The golden rule:
  Always quote variables unless you specifically want word splitting:
  
  RIGHT: cp "$FILE" "$DEST"
  WRONG: cp $FILE $DEST

Why quoting matters:
  Without quotes:
    FILE="my document.txt"
    cp $FILE backup/
    # Expands to: cp my document.txt backup/
    # cp sees 3 arguments: my, document.txt, backup/
    # Error: cannot stat 'my'
  
  With quotes:
    FILE="my document.txt"
    cp "$FILE" backup/
    # Expands to: cp "my document.txt" backup/
    # cp sees 2 arguments: my document.txt, backup/
    # Works correctly!
EOF
}

validate_step_5() {
    if [ ! -f "/tmp/expansion-lab/test file.txt" ]; then
        echo ""
        print_color "$RED" "✗ File 'test file.txt' does not exist"
        echo "  Create with: touch \"/tmp/expansion-lab/test file.txt\""
        return 1
    fi
    
    if [ ! -f "/tmp/expansion-lab/new test.txt" ]; then
        echo ""
        print_color "$RED" "✗ File 'new test.txt' does not exist"
        echo "  Copy with: cp \"/tmp/expansion-lab/test file.txt\" \"/tmp/expansion-lab/new test.txt\""
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  FILENAME="test file.txt"
  touch "/tmp/expansion-lab/$FILENAME"
  cp "/tmp/expansion-lab/test file.txt" "/tmp/expansion-lab/new test.txt"

Breaking it down:
  • FILENAME="test file.txt"
    - Quotes preserve the space in the value
  
  • touch "/tmp/expansion-lab/$FILENAME"
    - Double quotes allow $FILENAME expansion
    - But prevent word splitting
    - Results in: touch "/tmp/expansion-lab/test file.txt"
    - Single filename (with space) passed to touch
  
  • cp "source" "destination"
    - Both paths are quoted
    - Spaces preserved in both arguments

What happens without quotes:
  # WRONG:
  FILENAME="test file.txt"
  touch /tmp/expansion-lab/$FILENAME
  
  Expansion process:
  1. $FILENAME expands to: test file.txt
  2. Word splitting occurs on space
  3. Command becomes: touch /tmp/expansion-lab/test file.txt
  4. touch sees TWO arguments:
     - /tmp/expansion-lab/test
     - file.txt
  5. Creates wrong files!

Quote types:
  • Double quotes "...":
    - Allow $variable expansion
    - Allow $(command) substitution
    - Allow \\n escapes (some shells)
    - Prevent word splitting
    - Prevent glob expansion
  
  • Single quotes '...':
    - Prevent ALL expansion
    - Everything is literal
    - Use for literal strings with $ or *
  
  • No quotes:
    - All expansions occur
    - Word splitting happens
    - Globbing happens
    - Use rarely, only when needed

Examples:
  NAME="John Doe"
  
  # Double quotes (variable expands):
  echo "Hello $NAME"
  # Output: Hello John Doe
  
  # Single quotes (literal):
  echo 'Hello $NAME'
  # Output: Hello $NAME
  
  # No quotes (breaks on space):
  echo Hello $NAME
  # Output: Hello John Doe (but spaces collapsed)

Array elements with spaces:
  FILES=("file 1.txt" "file 2.txt")
  
  # WRONG:
  for f in ${FILES[@]}; do
      echo $f    # Breaks on spaces!
  done
  
  # RIGHT:
  for f in "${FILES[@]}"; do
      echo "$f"  # Preserves spaces
  done

When NOT to quote:
  # If you specifically want word splitting:
  OPTIONS="-v -r -f"
  cp $OPTIONS file1 file2    # Becomes: cp -v -r -f file1 file2
  
  # If you want globbing:
  PATTERN="*.txt"
  ls $PATTERN                # Glob expands
  
  # But in these cases, it's often better to use arrays:
  OPTIONS=(-v -r -f)
  cp "${OPTIONS[@]}" file1 file2

Verification:
  ls -l "/tmp/expansion-lab/"
  # Should show both files with spaces in names

EOF
}

hint_step_6() {
    echo "  Use backslash before special chars: touch file\\ with\\ spaces.txt"
}

# STEP 6: Escaping special characters
show_step_6() {
    cat << 'EOF'
TASK: Create files with special characters using escaping

Create these files in /tmp/expansion-lab/ (use escaping, not quotes):
  • dollar$sign.txt
  • star*file.txt
  • question?mark.txt

Requirements:
  • Use backslash \ to escape special characters
  • Three separate touch commands (one per file)
  • Pattern: touch /tmp/expansion-lab/name\$char.txt

What you're learning:
  Sometimes you need to use special characters literally but can't use
  quotes (e.g., in the middle of a longer command). The backslash
  escapes a single character, removing its special meaning.

Special characters that need escaping:
  $ * ? [ ] ( ) { } < > & | ; ` \ " ' space

Escaping vs quoting:
  • Escape: Protects ONE character: \$
  • Single quotes: Protects ALL: '$file'
  • Double quotes: Protects most: "$file"
EOF
}

validate_step_6() {
    local missing=()
    
    if [ ! -f "/tmp/expansion-lab/dollar\$sign.txt" ]; then
        missing+=("dollar\$sign.txt")
    fi
    
    if [ ! -f "/tmp/expansion-lab/star*file.txt" ]; then
        missing+=("star*file.txt")
    fi
    
    if [ ! -f "/tmp/expansion-lab/question?mark.txt" ]; then
        missing+=("question?mark.txt")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        print_color "$RED" "✗ Missing files: ${missing[*]}"
        echo "  Use backslash to escape: touch file\\\$name.txt"
        return 1
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  touch /tmp/expansion-lab/dollar\$sign.txt
  touch /tmp/expansion-lab/star\*file.txt
  touch /tmp/expansion-lab/question\?mark.txt

Breaking it down:
  • dollar\$sign.txt
    - \$ escapes the dollar sign
    - Prevents variable expansion
    - Creates literal filename with $ character
  
  • star\*file.txt
    - \* escapes the asterisk
    - Prevents glob expansion
    - Creates literal filename with * character
  
  • question\?mark.txt
    - \? escapes the question mark
    - Prevents glob matching
    - Creates literal filename with ? character

Escaping rules:
  • \ removes special meaning from next character
  • Works for: $ * ? [ ] ( ) { } < > & | ; ` \ " ' space
  • To get literal \, use: \\

Examples of escaping:
  # Escape dollar sign:
  echo \$HOME           # Outputs: $HOME (literal)
  echo $HOME            # Outputs: /home/user (expanded)
  
  # Escape space:
  cd my\ directory      # Changes to "my directory"
  cd my directory       # Error: too many arguments
  
  # Escape backslash:
  echo \\               # Outputs: \
  
  # Multiple escapes:
  touch file\$with\*special\?chars.txt

Escape vs quotes comparison:
  # Single quotes (everything literal):
  echo '$HOME * ?'      # Outputs: $HOME * ?
  
  # Double quotes (some expansion):
  echo "$HOME * ?"      # Outputs: /home/user * ?
  
  # Backslash (selective escape):
  echo \$HOME \* \?     # Outputs: $HOME * ?

When to use each:
  • Backslash: Single character in middle of string
    example: cd /path/to/my\ directory
  
  • Single quotes: Block of literal text
    example: echo 'Total: $AMOUNT * $COUNT'
  
  • Double quotes: Text with some variables
    example: echo "User: $USER"

Escaping in different contexts:
  # In filenames:
  touch file\ with\ spaces.txt
  
  # In commands:
  echo \$HOME is your home
  
  # In grep patterns (literal dot):
  grep "192\.168\.1\.1" file
  
  # In find:
  find . -name "\*.txt"     # Pattern for find
  find . -name "*.txt"      # Same thing (quotes protect from shell)

Common mistakes:
  ✗ Forgetting to escape in loops:
    for f in *; do echo $f; done   # Breaks on spaces
  ✓ Properly quoted:
    for f in *; do echo "$f"; done
  
  ✗ Double escaping:
    echo \\$HOME              # Wrong: \$HOME
  ✓ Single escape:
    echo \$HOME               # Right: $HOME

Verification:
  ls -l /tmp/expansion-lab/
  # Should show files with $, *, ? in their names

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your shell expansion work..."
    echo ""
    

    
    # Check 2: Brace expansion files
    print_color "$CYAN" "[2/$total] Checking brace expansion results..."
    local brace_ok=true
    for i in 1 2 3; do
        [ ! -f "/tmp/expansion-lab/log$i.txt" ] && brace_ok=false
    done
    for l in A B C; do
        [ ! -f "/tmp/expansion-lab/backup-$l.tar" ] && brace_ok=false
    done
    
    if $brace_ok; then
        print_color "$GREEN" "  ✓ All brace expansion files created"
        ((score++))
    else
        print_color "$RED" "  ✗ Some brace expansion files missing"
        print_color "$YELLOW" "  Fix: touch /tmp/expansion-lab/log{1..3}.txt backup-{A..C}.tar"
    fi
    echo ""
    

    
    # Check 5: Files with spaces
    print_color "$CYAN" "[5/$total] Checking quoted variables (spaces)..."
    if [ -f "/tmp/expansion-lab/test file.txt" ] && [ -f "/tmp/expansion-lab/new test.txt" ]; then
        print_color "$GREEN" "  ✓ Files with spaces created correctly"
        ((score++))
    else
        print_color "$RED" "  ✗ Files with spaces not found"
        print_color "$YELLOW" "  Fix: touch \"/tmp/expansion-lab/test file.txt\""
    fi
    echo ""
    
    # Check 6: Escaped special characters
    print_color "$CYAN" "[6/$total] Checking escaped special characters..."
    local escape_ok=true
    [ ! -f "/tmp/expansion-lab/dollar\$sign.txt" ] && escape_ok=false
    [ ! -f "/tmp/expansion-lab/star*file.txt" ] && escape_ok=false
    [ ! -f "/tmp/expansion-lab/question?mark.txt" ] && escape_ok=false
    
    if $escape_ok; then
        print_color "$GREEN" "  ✓ Special characters escaped correctly"
        ((score++))
    else
        print_color "$RED" "  ✗ Some escaped files missing"
        print_color "$YELLOW" "  Fix: touch file\\\$name.txt (use backslash before special chars)"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Variable expansion and scope"
        echo "  • Brace expansion for efficiency"
        echo "  • Command substitution to capture output"
        echo "  • Glob patterns and when they expand"
        echo "  • Proper quoting to handle spaces"
        echo "  • Escaping special characters"
        echo ""
        echo "You understand the shell expansion order and can predict command behavior!"
    elif [ $score -ge 4 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're getting it! Review the concepts above."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Shell expansion takes practice. Review with --solution."
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

Understanding shell expansion is crucial for effective Linux administration.
This lab covers the expansion sequence and practical applications.

SHELL EXPANSION ORDER (Memorize This!)
─────────────────────────────────────────────────────────────────
Bash processes commands in this exact order:

  1. Brace expansion       {...}
  2. Tilde expansion       ~
  3. Parameter expansion   $VAR, ${VAR}
  4. Command substitution  $(command), `command`
  5. Arithmetic expansion  $((expression))
  6. Word splitting        (on IFS characters)
  7. Glob expansion        *, ?, [...]
  8. Quote removal         Remove ', ", \

Each step transforms the command before the next step runs.


STEP 1: Variables and Export
─────────────────────────────────────────────────────────────────
Commands:
  export MY_APP_DIR="/opt/myapp"
  FILE_COUNT=42

Concepts:
  • Shell variables exist only in current shell
  • export makes them available to child processes
  • Environment variables persist across subshells
  • NO SPACES around = sign!

When to export:
  ✓ Configuration for scripts/programs
  ✓ PATH, JAVA_HOME, etc.
  ✗ Temporary loop counters
  ✗ Local calculations


STEP 2: Brace Expansion
─────────────────────────────────────────────────────────────────
Commands:
  touch /tmp/expansion-lab/log{1..3}.txt
  touch /tmp/expansion-lab/backup-{A..C}.tar

Key insight:
  Brace expansion happens FIRST, before anything else!
  It generates text patterns without checking the filesystem.

Patterns:
  {1..10}    - Numeric sequence
  {A..Z}     - Letter sequence
  {a,b,c}    - Explicit list
  {01..10}   - Zero-padded


STEP 3: Command Substitution
─────────────────────────────────────────────────────────────────
Commands:
  TXT_COUNT=$(find /tmp/expansion-lab -name "*.txt" | wc -l)
  touch /tmp/expansion-lab/summary-${TXT_COUNT}.txt

The $() syntax:
  • Runs command inside
  • Captures STDOUT
  • Replaces $() with output
  • Can be nested

Why ${VAR} instead of $VAR?
  Prevents ambiguity: ${VAR}suffix vs $VARsuffix


STEP 4: Globbing (Wildcards)
─────────────────────────────────────────────────────────────────
Commands:
  ls /tmp/expansion-lab/*.log
  REPORT_COUNT=$(find /tmp/expansion-lab -name "report*.pdf" | wc -l)

Glob patterns:
  *      - Any characters
  ?      - Single character
  [...]  - Character set
  [!...] - NOT in set

Critical rule:
  Glob expansion happens AFTER variable expansion.
  This causes common bugs if not understood!


STEP 5: Quoting Variables
─────────────────────────────────────────────────────────────────
Commands:
  FILENAME="test file.txt"
  touch "/tmp/expansion-lab/$FILENAME"
  cp "/tmp/expansion-lab/test file.txt" "/tmp/expansion-lab/new test.txt"

The golden rule:
  ALWAYS quote variables with "$VAR" unless you specifically
  want word splitting.

Quote types:
  "..."  - Allow variable/command expansion
  '...'  - Everything literal
  none   - All expansion + word splitting + globbing


STEP 6: Escaping Special Characters
─────────────────────────────────────────────────────────────────
Commands:
  touch /tmp/expansion-lab/dollar\$sign.txt
  touch /tmp/expansion-lab/star\*file.txt
  touch /tmp/expansion-lab/question\?mark.txt

Backslash rules:
  • Escapes ONE character
  • Removes special meaning
  • Use for: $ * ? [ ] ( ) { } < > & | ; ` \ " ' space


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Why does order matter?
  Because each step feeds into the next. Example:

  DIR="test"
  ls $DIR/*.txt

  Expansion sequence:
  1. $DIR expands to "test"
  2. Command becomes: ls test/*.txt
  3. Glob expands *.txt to matching files
  4. Final: ls test/file1.txt test/file2.txt

Variable expansion vs Brace expansion:
  # This works (brace first, then variable):
  PREFIX="file"
  touch {1..3}.txt
  
  # This doesn't work as expected:
  SEQ="{1..3}"
  touch $SEQ.txt       # Creates literal "{1..3}.txt"
  
  Why? Variable expansion happens AFTER brace expansion!

When quoting prevents problems:
  FILES="*.txt"
  echo $FILES          # Glob expands (shows filenames)
  echo "$FILES"        # Literal (shows "*.txt")

Common pitfall with spaces:
  FILE="my document.txt"
  
  # WRONG:
  ls $FILE             # ls sees: "my" "document.txt"
  
  # RIGHT:
  ls "$FILE"           # ls sees: "my document.txt"


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Spaces around =
  VAR = value     # WRONG: Runs command 'VAR'
  VAR=value       # RIGHT

Mistake 2: Unquoted variables
  cp $FILE $DEST  # Breaks with spaces
  cp "$FILE" "$DEST"  # Safe

Mistake 3: Wrong expansion order assumptions
  N=3
  touch file{1..$N}.txt   # Creates: file{1..3}.txt (literal!)
  # Brace expansion happens before $N expands

Mistake 4: Not escaping find patterns
  find . -name *.txt      # Shell expands *, might match wrong thing
  find . -name "*.txt"    # find gets literal pattern, works correctly

Mistake 5: Forgetting globbing happens
  FILES=*.txt
  rm $FILES               # Dangerous: expands all .txt files!
  rm "$FILES"             # Safer: literal "*.txt" filename


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Use echo to preview expansions:
   echo rm $FILES    # See what would be deleted!

2. Remember quoting rules:
   • "$VAR" preserves spaces
   • '$VAR' is literal
   • $VAR allows splitting

3. Glob patterns:
   • Use with ls, rm, cp directly
   • Quote in find: find -name "*.txt"

4. Test commands before running:
   • Add echo before dangerous commands
   • Check with ls first
   • Use -i flag for interactive mode

5. Common exam patterns:
   • Creating backup files: cp file{,.bak}
   • Batch operations: for f in *.txt; do ...; done
   • Dynamic filenames: backup-$(date +%F).tar

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/expansion-lab 2>/dev/null || true
    unset MY_APP_DIR FILE_COUNT TXT_COUNT REPORT_COUNT 2>/dev/null || true
    echo "  ✓ All lab files and variables removed"
}

# Execute the main framework
main "$@"
