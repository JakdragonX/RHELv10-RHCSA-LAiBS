#!/bin/bash
# labs/03C-bash-scripting-basics.sh
# Lab: Basic Bash Scripting Fundamentals
# Difficulty: Beginner
# RHCSA Objective: Create simple shell scripts

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Basic Bash Scripting Fundamentals"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Remove from previous attempts
    userdel -r scriptuser 2>/dev/null || true
    rm -rf /home/labscripts 2>/dev/null || true
    rm -rf /tmp/script_test 2>/dev/null || true
    
    # Create test user
    useradd -m -s /bin/bash scriptuser 2>/dev/null || true
    echo "scriptuser:password123" | chpasswd 2>/dev/null || true
    
    # Create directory for scripts
    mkdir -p /home/labscripts 2>/dev/null || true
    chown scriptuser:scriptuser /home/labscripts
    
    # Create test directory with files
    mkdir -p /tmp/script_test 2>/dev/null || true
    touch /tmp/script_test/file{1..5}.txt
    echo "test content" > /tmp/script_test/data.txt
    
    echo "  ✓ User 'scriptuser' created"
    echo "  ✓ Directory /home/labscripts created"
    echo "  ✓ Test files created in /tmp/script_test"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of variables in bash
  • Concept of script arguments ($1, $2)
  • Simple if/then/else logic
  • Basic for loop syntax
  • What makes a file executable (chmod +x)

Commands You'll Use:
  • #!/bin/bash      - Shebang (first line of script)
  • chmod +x file    - Make script executable
  • bash script.sh   - Run a script
  • echo             - Display output
  • if/then/fi       - Conditional logic
  • for/do/done      - Loop structure
  • $1, $2           - Script arguments
  • exit 0/1         - Exit with status code

Files You'll Create:
  • /home/labscripts/hello.sh         - Simple greeting script
  • /home/labscripts/count_files.sh   - Count files in directory
  • /home/labscripts/create_users.sh  - Loop to create users (simulation)
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a new system administrator learning automation basics. Your supervisor
wants you to create three simple scripts to demonstrate basic bash scripting
skills: a greeting script, a file counter, and a user creation simulator.

OBJECTIVES:
  1. Create a simple greeting script (hello.sh):
     • Location: /home/labscripts/hello.sh
     • Must have #!/bin/bash as first line
     • Accept name as first argument ($1)
     • Display: "Hello, [name]!" if argument provided
     • Display: "Hello, World!" if no argument
     • Make executable (chmod +x)
  
  2. Create a file counting script (count_files.sh):
     • Location: /home/labscripts/count_files.sh
     • Accept directory path as argument ($1)
     • Count number of files in that directory
     • Display count to user
     • Use a simple for loop to iterate files
     • Make executable
  
  3. Create a user simulation script (create_users.sh):
     • Location: /home/labscripts/create_users.sh
     • Use a for loop to process usernames: alice bob charlie
     • For each name, just echo "Would create user: [name]"
     • Demonstrate basic loop structure
     • Make executable

SUCCESS CRITERIA:
  • All three scripts exist at specified locations
  • All scripts have correct shebang (#!/bin/bash)
  • All scripts are executable (chmod +x)
  • hello.sh works with and without arguments
  • count_files.sh correctly counts files
  • create_users.sh loops through all three names
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create hello.sh - greeting with optional argument
  ☐ 2. Create count_files.sh - count files in directory
  ☐ 3. Create create_users.sh - loop through usernames
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "3"
}

scenario_context() {
    cat << 'EOF'
You're learning bash scripting basics. Create three simple scripts demonstrating
variables, arguments, conditionals, and loops.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Create a simple greeting script

Create a script that greets a user by name, or says "Hello, World!" if
no name is provided. This teaches arguments and conditionals.

Requirements:
  • Location: /home/labscripts/hello.sh
  • First line: #!/bin/bash
  • If argument given ($1): Display "Hello, NAME!"
  • If no argument: Display "Hello, World!"
  • Use if/then/else structure
  • Make executable

Example:
  ./hello.sh Alice    → "Hello, Alice!"
  ./hello.sh          → "Hello, World!"
EOF
}

validate_step_1() {
    local script="/home/labscripts/hello.sh"
    
    if [ ! -f "$script" ]; then
        print_color "$RED" "✗ Script not found: $script"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    if ! head -1 "$script" | grep -q "^#!/bin/bash"; then
        print_color "$RED" "✗ Missing or incorrect shebang"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ hello.sh created and executable"
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /home/labscripts/hello.sh << 'SCRIPT'
#!/bin/bash
# Simple greeting script

if [ -n "$1" ]; then
    echo "Hello, $1!"
else
    echo "Hello, World!"
fi
SCRIPT

chmod +x /home/labscripts/hello.sh

EXPLANATION:
───────────
• #!/bin/bash: Shebang - tells system to use bash
• $1: First argument passed to script
• [ -n "$1" ]: Tests if $1 is NOT empty
  - -n means "not zero length"
  - Quotes around $1 prevent errors with spaces
• echo: Displays text to screen
• chmod +x: Makes file executable

Testing:
  /home/labscripts/hello.sh Alice
  # Output: Hello, Alice!
  
  /home/labscripts/hello.sh
  # Output: Hello, World!

Key Concepts:
  • $1, $2, $3: Positional arguments
  • $@: All arguments
  • $#: Number of arguments
  • $?: Exit code of last command
EOF
}

hint_step_1() {
    echo "  Use if [ -n \"\$1\" ]; then ... else ... fi"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create a file counting script

Create a script that counts how many files are in a directory. This
teaches loops and arguments.

Requirements:
  • Location: /home/labscripts/count_files.sh
  • Accept directory path as $1
  • Use for loop to iterate through files
  • Count the files
  • Display total count

Example:
  ./count_files.sh /tmp/script_test
  # Output: Found 6 files in /tmp/script_test
EOF
}

validate_step_2() {
    local script="/home/labscripts/count_files.sh"
    
    if [ ! -f "$script" ]; then
        print_color "$RED" "✗ Script not found: $script"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ count_files.sh created and executable"
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /home/labscripts/count_files.sh << 'SCRIPT'
#!/bin/bash
# Count files in a directory

DIR="$1"
COUNT=0

for file in "$DIR"/*; do
    if [ -f "$file" ]; then
        COUNT=$((COUNT + 1))
    fi
done

echo "Found $COUNT files in $DIR"
SCRIPT

chmod +x /home/labscripts/count_files.sh

EXPLANATION:
───────────
• DIR="$1": Store first argument in variable
• COUNT=0: Initialize counter (no spaces around =!)
• for file in "$DIR"/*: Loop through all items in directory
  - "$DIR"/* expands to: /path/file1 /path/file2 ...
  - Each iteration, $file gets next value
• [ -f "$file" ]: Tests if it's a regular file
  - -f: true for files
  - -d: true for directories
  - -e: true if exists (any type)
• COUNT=$((COUNT + 1)): Arithmetic expansion
  - $(( )) for math operations
  - Alternative: ((COUNT++))

Testing:
  /home/labscripts/count_files.sh /tmp/script_test
  # Should show count of files in that directory

Key Loop Syntax:
  for VAR in LIST; do
      commands using $VAR
  done
  
  Common patterns:
    for file in /path/*         # All files
    for file in *.txt           # All .txt files
    for i in {1..10}            # Numbers 1 to 10
    for user in alice bob       # Explicit list
EOF
}

hint_step_2() {
    echo "  Use for file in \"\$DIR\"/*; do ... done with counter"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create a user creation simulator

Create a script with a for loop that processes a list of usernames.
This teaches loops with explicit lists.

Requirements:
  • Location: /home/labscripts/create_users.sh
  • Loop through: alice bob charlie
  • For each name, echo "Would create user: NAME"
  • Don't actually create users (just simulate)

Example output:
  Would create user: alice
  Would create user: bob
  Would create user: charlie
EOF
}

validate_step_3() {
    local script="/home/labscripts/create_users.sh"
    
    if [ ! -f "$script" ]; then
        print_color "$RED" "✗ Script not found: $script"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        print_color "$RED" "✗ Script is not executable"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ create_users.sh created and executable"
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /home/labscripts/create_users.sh << 'SCRIPT'
#!/bin/bash
# Simulate user creation

for username in alice bob charlie; do
    echo "Would create user: $username"
done
SCRIPT

chmod +x /home/labscripts/create_users.sh

EXPLANATION:
───────────
• for username in alice bob charlie: Explicit list of values
  - Could also be: for user in "$@" to use script arguments
  - Or read from file: for user in $(cat users.txt)
• $username: Variable containing current item
• No need for counter - just processing each item

Testing:
  /home/labscripts/create_users.sh
  # Should display three lines

Real-World Version:
  If this were real, you'd use:
    for username in alice bob charlie; do
        useradd -m "$username"
        echo "Created user: $username"
    done
  
  But NEVER run user creation commands in practice scripts!

Loop Variations:
  # C-style loop
  for ((i=1; i<=10; i++)); do
      echo "Number $i"
  done
  
  # While loop
  while [ $COUNT -lt 10 ]; do
      echo $COUNT
      COUNT=$((COUNT + 1))
  done
  
  # Read from file
  while read line; do
      echo "Processing: $line"
  done < file.txt
EOF
}

hint_step_3() {
    echo "  Use for username in alice bob charlie; do echo ... done"
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=3
    
    echo "Checking your scripts..."
    echo ""
    
    # CHECK 1
    print_color "$CYAN" "[1/$total] Checking hello.sh..."
    if [ -x "/home/labscripts/hello.sh" ] && head -1 "/home/labscripts/hello.sh" | grep -q "#!/bin/bash"; then
        print_color "$GREEN" "  ✓ hello.sh exists, executable, has shebang"
        ((score++))
    else
        print_color "$RED" "  ✗ hello.sh issues"
    fi
    echo ""
    
    # CHECK 2
    print_color "$CYAN" "[2/$total] Checking count_files.sh..."
    if [ -x "/home/labscripts/count_files.sh" ]; then
        print_color "$GREEN" "  ✓ count_files.sh exists and executable"
        ((score++))
    else
        print_color "$RED" "  ✗ count_files.sh issues"
    fi
    echo ""
    
    # CHECK 3
    print_color "$CYAN" "[3/$total] Checking create_users.sh..."
    if [ -x "/home/labscripts/create_users.sh" ]; then
        print_color "$GREEN" "  ✓ create_users.sh exists and executable"
        ((score++))
    else
        print_color "$RED" "  ✗ create_users.sh issues"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Great work! You understand:"
        echo "  • Basic script structure with shebang"
        echo "  • Using script arguments ($1)"
        echo "  • Simple if/then/else conditionals"
        echo "  • For loops with lists and wildcards"
        echo "  • Making scripts executable"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total)"
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
See solution_step_1(), solution_step_2(), and solution_step_3() above.

RHCSA SCRIPTING ESSENTIALS:
──────────────────────────
1. Shebang: #!/bin/bash (always first line)
2. Variables: NAME="value" (no spaces around =)
3. Arguments: $1, $2, $@ (positional parameters)
4. Conditionals: if [ test ]; then ... fi
5. Loops: for var in list; do ... done
6. Executable: chmod +x script.sh
7. Exit codes: exit 0 (success), exit 1 (failure)

That's it for RHCSA! Keep it simple.
EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up..."
    userdel -r scriptuser 2>/dev/null || true
    rm -rf /home/labscripts 2>/dev/null || true
    rm -rf /tmp/script_test 2>/dev/null || true
    echo "  ✓ Cleanup complete"
}

# Execute
main "$@"
