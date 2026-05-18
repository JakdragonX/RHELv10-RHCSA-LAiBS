#!/bin/bash
# labs/23B-scripting-capstone.sh
# Lab: Scripting Capstone — Build a Complete User Provisioning Tool
# Difficulty: Advanced
# RHCSA Objective: Create simple shell scripts; use variables, loops, and conditionals

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Scripting Capstone — Build a Complete User Provisioning Tool"
LAB_DIFFICULTY="Advanced"
LAB_TIME_ESTIMATE="30-40 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    rm -rf /tmp/lab23b 2>/dev/null || true
    mkdir -p /tmp/lab23b/{scripts,config,output,logs}

    # Input file the provision script will read
    cat > /tmp/lab23b/config/new-users.csv << 'EOF'
labuser01:developers:bash
labuser02:sysadmin:bash
labuser03:developers:sh
EOF

    # Config file to source
    cat > /tmp/lab23b/config/provision.conf << 'EOF'
# Provisioning configuration
DEFAULT_SHELL="/bin/bash"
HOME_BASE="/tmp/lab23b/output/homes"
LOG_FILE="/tmp/lab23b/logs/provision.log"
GROUP_PREFIX="lab"
EOF

    # Ensure the lab users don't exist from a previous run
    for u in labuser01 labuser02 labuser03; do
        userdel -r "$u" 2>/dev/null || true
    done
    # Ensure lab groups don't exist
    for g in labdevelopers labsysadmin; do
        groupdel "$g" 2>/dev/null || true
    done

    mkdir -p /tmp/lab23b/output/homes

    echo "  ✓ Created /tmp/lab23b with config and input files"
    echo "  ✓ Cleaned up any users/groups from previous attempts"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Labs 24A and 23A — all prior scripting concepts are combined here
  • User and group management: useradd, groupadd, usermod, id
  • That useradd requires root; this lab must be run as root or with sudo

Commands You'll Use:
  • source / .              - Load config file variables
  • while IFS=: read        - Parse colon-delimited input file
  • case                    - Branch on argument value
  • useradd -m -s -g        - Create user with home dir, shell, primary group
  • groupadd                - Create a group
  • getent passwd/group     - Query user/group database (safer than grepping /etc/passwd)
  • id                      - Show user's UID, GID, and groups
  • tee -a                  - Write to stdout AND append to a file simultaneously
  • date +%Y-%m-%d\ %H:%M:%S - Timestamp format for log entries

WHAT YOU'RE BUILDING:
  A single script (provision.sh) that:
  1. Accepts a mode argument: create | verify | cleanup
  2. Sources a config file for paths and defaults
  3. Reads a CSV of users to provision (while read + IFS)
  4. For 'create': creates groups and users, writes a log
  5. For 'verify': checks each user exists and reports status
  6. For 'cleanup': removes the created users and groups
  7. Validates arguments; exits 1 for unknown modes

This is a realistic RHCSA-style script task: building a tool that
does real system work, is configurable, handles errors, and logs output.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You need to provision three new developer accounts from an onboarding CSV.
Rather than running useradd three times manually, you've been asked to write
a reusable provisioning script that can create, verify, and clean up accounts
based on a config-driven input file.

BACKGROUND:
The script will be run by the ops team with different mode arguments depending
on what they need. It must be safe to run multiple times (idempotent where
possible), log its actions, and clearly report success or failure.

OBJECTIVES:
  1. Write /tmp/lab23b/scripts/provision.sh as a single script that:
       • Accepts $1 as mode: create | verify | cleanup
       • Sources /tmp/lab23b/config/provision.conf for config variables
       • Uses while IFS=: read to process /tmp/lab23b/config/new-users.csv
       • Uses case to dispatch to different logic per mode
       • Validates $1 with a *) default that exits 1

  2. The 'create' mode must:
       • For each user in the CSV: create group "${GROUP_PREFIX}${group}" if absent,
         then create the user with: useradd -m -d ${HOME_BASE}/${username}
         -s /bin/${shell} -g ${GROUP_PREFIX}${group} ${username}
       • Skip gracefully if user already exists (check with getent passwd)
       • Log each action to $LOG_FILE with a timestamp

  3. The 'verify' mode must:
       • For each user in the CSV: check if they exist with getent passwd
       • Print "OK: username" or "MISSING: username" for each
       • Exit 1 if any user is missing

  4. Run the script in all three modes and validate final state:
       ./provision.sh create   → creates all 3 users
       ./provision.sh verify   → all 3 show OK
       ./provision.sh cleanup  → removes users and groups

HINTS:
  • getent passwd username returns 0 if user exists, 1 if not — use in if
  • groupadd returns 9 if group already exists — suppress with 2>/dev/null || true
  • useradd -m creates the home directory; -d sets its path; -s sets shell
  • tee -a $LOG_FILE lets you print to screen and append to file simultaneously
  • For cleanup: userdel -r removes user and home dir; groupdel removes group

SUCCESS CRITERIA:
  • All 3 users (labuser01, labuser02, labuser03) exist after 'create'
  • $LOG_FILE contains entries for each user action
  • 'verify' mode exits 0 when all users exist
  • After 'cleanup', users no longer exist (getent passwd labuser01 fails)
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Write provision.sh with case dispatch, source config, while read CSV
  ☐ 2. 'create' mode: groupadd + useradd for each CSV user, log to $LOG_FILE
  ☐ 3. 'verify' mode: getent passwd check per user, exit 1 if any missing
  ☐ 4. Run all three modes; confirm users exist then are removed by cleanup
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
Build a reusable user provisioning script that creates, verifies, and
cleans up accounts from a CSV file. The script combines every scripting
concept from this module into one real-world tool.
EOF
}

# STEP 1: Script skeleton with case dispatch and source
show_step_1() {
    cat << 'EOF'
TASK: Write the provision.sh skeleton with case dispatch and config sourcing

Build the structure first — argument validation, source the config,
and the case skeleton with all four branches (create, verify, cleanup, *).
You do not need to implement the logic inside each branch yet; just make
the structure valid and test that each branch runs and exits correctly.

Requirements:
  • Script: /tmp/lab23b/scripts/provision.sh, executable
  • First thing: validate $1 is not empty (exit 1 if so)
  • Second: source /tmp/lab23b/config/provision.conf
  • Third: case $1 in create|verify|cleanup|*) ... esac
  • Each valid branch: echo "Mode: $1" (placeholder for now)
  • *) default: echo "Unknown mode: $1" and exit 1

Test the skeleton:
  ./provision.sh             # → exits 1 (no argument)
  ./provision.sh create      # → prints "Mode: create"
  ./provision.sh bogus       # → "Unknown mode: bogus", exits 1
  echo $?                    # → 1
EOF
}

validate_step_1() {
    local script="/tmp/lab23b/scripts/provision.sh"

    if [ ! -f "$script" ]; then
        echo ""
        print_color "$RED" "✗ /tmp/lab23b/scripts/provision.sh not found"
        return 1
    fi

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ Script is not executable"
        echo "  Fix: chmod +x $script"
        return 1
    fi

    # No-argument check
    "$script" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ""
        print_color "$RED" "✗ Script should exit 1 with no arguments"
        return 1
    fi

    # Unknown mode should exit 1
    "$script" bogus >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ""
        print_color "$RED" "✗ Unknown mode 'bogus' should exit 1, but exited 0"
        echo "  Add 'exit 1' to the *) case branch"
        return 1
    fi

    # Valid mode should exit 0 (even if just placeholder)
    "$script" create >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo ""
        print_color "$RED" "✗ 'create' mode exited non-zero (expected 0 for valid mode)"
        return 1
    fi

    # Check source is present
    if ! grep -qE "^(source|\.) " "$script"; then
        echo ""
        print_color "$RED" "✗ Script does not source the config file"
        echo "  Add: source /tmp/lab23b/config/provision.conf"
        return 1
    fi

    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
cat > /tmp/lab23b/scripts/provision.sh << 'SCRIPT'
#!/bin/bash
# User provisioning tool
# Usage: provision.sh <create|verify|cleanup>

CONFIG="/tmp/lab23b/config/provision.conf"
USERS_CSV="/tmp/lab23b/config/new-users.csv"

# Validate argument
if [ -z "$1" ]; then
    echo "Usage: $(basename $0) {create|verify|cleanup}"
    exit 1
fi

# Load configuration
if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Config file not found: $CONFIG"
    exit 1
fi
source "$CONFIG"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Dispatch based on mode
case $1 in
    create)
        echo "Mode: create"
        ;;
    verify)
        echo "Mode: verify"
        ;;
    cleanup)
        echo "Mode: cleanup"
        ;;
    *)
        echo "Unknown mode: $1"
        echo "Usage: $(basename $0) {create|verify|cleanup}"
        exit 1
        ;;
esac
SCRIPT

chmod +x /tmp/lab23b/scripts/provision.sh

# Test the skeleton:
/tmp/lab23b/scripts/provision.sh           # → exits 1
/tmp/lab23b/scripts/provision.sh create    # → Mode: create
/tmp/lab23b/scripts/provision.sh bogus; echo "Exit: $?"  # → exit 1

Key points:
  • Argument validation before anything else — no point loading config
    or parsing files if the invocation is wrong.
  • Source the config early, after validation, so all subsequent code
    can use $LOG_FILE, $HOME_BASE, etc. without re-referencing paths.
  • The case skeleton is the scaffold; logic fills in each branch later.
    Building the structure first lets you test argument handling before
    worrying about the implementation.

EOF
}

hint_step_2() {
    echo "  Replace 'echo Mode: create' with the groupadd/useradd logic"
    echo "  getent passwd username — exits 0 if user exists"
    echo "  groupadd \${GROUP_PREFIX}\${group} 2>/dev/null || true — safe repeated run"
}

# STEP 2: Implement create mode
show_step_2() {
    cat << 'EOF'
TASK: Implement the 'create' mode in provision.sh

Replace the "echo Mode: create" placeholder with real logic.
For each line in new-users.csv, the create mode should:

  1. Parse the line into: username, group, shell (IFS=:, while read)
  2. Create the group: ${GROUP_PREFIX}${group}  (e.g., labdevelopers)
     Skip silently if already exists: groupadd ... 2>/dev/null || true
  3. Check if user already exists: getent passwd $username
     If exists: log "SKIP: $username already exists" and continue
     If not:    useradd -m -d ${HOME_BASE}/${username} \
                         -s /bin/${shell} \
                         -g ${GROUP_PREFIX}${group} $username
  4. Log each action with timestamp to $LOG_FILE using tee -a

Timestamp format for log:
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$TIMESTAMP] Created: $username" | tee -a "$LOG_FILE"

After implementing, run:
  /tmp/lab23b/scripts/provision.sh create
  cat /tmp/lab23b/logs/provision.log
  id labuser01
EOF
}

validate_step_2() {
    local script="/tmp/lab23b/scripts/provision.sh"

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ provision.sh not found or not executable"
        return 1
    fi

    # Run create mode
    "$script" create >/dev/null 2>&1

    # Check all three users exist
    local all_exist=1
    for user in labuser01 labuser02 labuser03; do
        if ! getent passwd "$user" >/dev/null 2>&1; then
            all_exist=0
            echo ""
            print_color "$RED" "✗ User '$user' was not created"
        fi
    done
    [ "$all_exist" -eq 0 ] && return 1

    # Check log file was written
    if [ ! -f "/tmp/lab23b/logs/provision.log" ]; then
        echo ""
        print_color "$RED" "✗ Log file /tmp/lab23b/logs/provision.log not created"
        echo "  Add logging to each action in create mode"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Replace the create) branch in provision.sh:

    create)
        echo "Starting user provisioning..."
        while IFS=: read -r username group shell; do
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            FULL_GROUP="${GROUP_PREFIX}${group}"

            # Create group if needed
            groupadd "$FULL_GROUP" 2>/dev/null || true

            # Skip if user already exists
            if getent passwd "$username" >/dev/null 2>&1; then
                echo "[$TIMESTAMP] SKIP: $username already exists" | tee -a "$LOG_FILE"
                continue
            fi

            # Create user
            useradd -m \
                    -d "${HOME_BASE}/${username}" \
                    -s "/bin/${shell}" \
                    -g "$FULL_GROUP" \
                    "$username"

            echo "[$TIMESTAMP] CREATED: $username (group: $FULL_GROUP, shell: /bin/${shell})" \
                | tee -a "$LOG_FILE"
        done < "$USERS_CSV"
        echo "Provisioning complete. Log: $LOG_FILE"
        ;;

Key points:
  • getent passwd username: queries NSS (Name Service Switch) for the user.
    Returns 0 if found, 1 if not. Safer than 'grep username /etc/passwd'
    because getent also checks LDAP/AD if configured.
  • tee -a $LOG_FILE: 'tee' reads stdin and writes to both stdout and the
    named file. -a appends rather than overwriting.
  • continue inside while read: skips to the next line of the CSV.
  • useradd options:
    -m: create home directory
    -d: set home directory path (overrides the default /home/username)
    -s: set login shell
    -g: set primary group (must already exist when useradd runs)

Verification:
  id labuser01
  # Expected: uid=XXXX(labuser01) gid=XXXX(labdevelopers) groups=XXXX(labdevelopers)
  cat /tmp/lab23b/logs/provision.log

EOF
}

hint_step_3() {
    echo "  Replace 'echo Mode: verify' with a while read loop using getent passwd"
    echo "  Track failures: FAIL=0; ...; [ \$FAIL -eq 1 ] && exit 1"
}

# STEP 3: Implement verify and cleanup modes
show_step_3() {
    cat << 'EOF'
TASK: Implement verify and cleanup modes

VERIFY MODE:
  For each user in the CSV:
    • Check: getent passwd $username >/dev/null 2>&1
    • Print "OK: $username" or "MISSING: $username"
    • Track failures with a flag variable (MISSING=0; ... MISSING=1)
  After the loop: exit 1 if MISSING is 1, exit 0 if all OK

CLEANUP MODE:
  For each user in the CSV:
    • userdel -r $username 2>/dev/null || true  (removes user + home)
    • groupdel ${GROUP_PREFIX}${group} 2>/dev/null || true
    • Log the removal

After implementing, test:
  /tmp/lab23b/scripts/provision.sh verify    # all OK after create
  /tmp/lab23b/scripts/provision.sh cleanup   # removes users
  /tmp/lab23b/scripts/provision.sh verify    # all MISSING after cleanup
  echo $?                                    # → 1
EOF
}

validate_step_3() {
    local script="/tmp/lab23b/scripts/provision.sh"

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ provision.sh not found or not executable"
        return 1
    fi

    # Ensure users exist first (re-run create if needed)
    "$script" create >/dev/null 2>&1

    # verify should exit 0 when all users exist
    "$script" verify >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo ""
        print_color "$RED" "✗ 'verify' mode exited non-zero even though all users exist"
        echo "  Check that verify exits 0 when all users are found"
        return 1
    fi

    # Run cleanup
    "$script" cleanup >/dev/null 2>&1

    # verify should now exit 1 (users are gone)
    "$script" verify >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ""
        print_color "$RED" "✗ 'verify' should exit 1 after cleanup (users removed), but exited 0"
        echo "  Check that verify exits 1 when any user is missing"
        return 1
    fi

    # Confirm users are gone
    for user in labuser01 labuser02 labuser03; do
        if getent passwd "$user" >/dev/null 2>&1; then
            echo ""
            print_color "$RED" "✗ User '$user' still exists after cleanup"
            echo "  Check the cleanup mode: userdel -r $user"
            return 1
        fi
    done

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Replace verify) and cleanup) branches:

    verify)
        echo "Verifying provisioned users..."
        MISSING=0
        while IFS=: read -r username group shell; do
            if getent passwd "$username" >/dev/null 2>&1; then
                echo "OK: $username"
            else
                echo "MISSING: $username"
                MISSING=1
            fi
        done < "$USERS_CSV"
        [ "$MISSING" -eq 1 ] && exit 1
        echo "All users verified"
        ;;

    cleanup)
        echo "Cleaning up provisioned users..."
        while IFS=: read -r username group shell; do
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            FULL_GROUP="${GROUP_PREFIX}${group}"

            userdel -r "$username" 2>/dev/null || true
            groupdel "$FULL_GROUP" 2>/dev/null || true

            echo "[$TIMESTAMP] REMOVED: $username" | tee -a "$LOG_FILE"
        done < "$USERS_CSV"
        echo "Cleanup complete"
        ;;

Key points:
  • MISSING=0 flag: set to 1 if any user is missing. After the loop,
    [ "$MISSING" -eq 1 ] && exit 1 reports overall failure. This is the
    standard pattern for accumulating failures without stopping early.
  • userdel -r: removes the user AND their home directory and mail spool.
    Without -r, the home directory stays on disk as an orphaned directory.
  • groupdel: removes the group. Will fail if users still have this as their
    primary group — so always remove users before groups.
  • || true after userdel/groupdel: suppresses errors if the user/group
    doesn't exist (idempotent cleanup — safe to run multiple times).

Verification:
  /tmp/lab23b/scripts/provision.sh create
  /tmp/lab23b/scripts/provision.sh verify; echo "Exit: $?"   # → 0
  /tmp/lab23b/scripts/provision.sh cleanup
  /tmp/lab23b/scripts/provision.sh verify; echo "Exit: $?"   # → 1

EOF
}

hint_step_4() {
    echo "  Run all three modes in sequence and check the log file"
    echo "  cat /tmp/lab23b/logs/provision.log"
}

# STEP 4: End-to-end verification
show_step_4() {
    cat << 'EOF'
TASK: Run the full provisioning lifecycle and verify the log

Run the complete workflow in sequence and confirm everything works end-to-end.

Requirements:
  1. Run: provision.sh create
     Confirm: all 3 users exist (id labuser01, id labuser02, id labuser03)
  2. Run: provision.sh create again
     Confirm: script handles already-existing users gracefully (SKIP entries in log)
  3. Run: provision.sh verify
     Confirm: exits 0, all show OK
  4. Run: provision.sh cleanup
     Confirm: users removed
  5. Run: provision.sh verify
     Confirm: exits 1, all show MISSING

Commands to run:
  /tmp/lab23b/scripts/provision.sh create
  id labuser01
  /tmp/lab23b/scripts/provision.sh create    # second run — should SKIP
  cat /tmp/lab23b/logs/provision.log
  /tmp/lab23b/scripts/provision.sh verify; echo "Exit: $?"
  /tmp/lab23b/scripts/provision.sh cleanup
  /tmp/lab23b/scripts/provision.sh verify; echo "Exit: $?"
EOF
}

validate_step_4() {
    local script="/tmp/lab23b/scripts/provision.sh"

    if [ ! -x "$script" ]; then
        echo ""
        print_color "$RED" "✗ provision.sh not found or not executable"
        return 1
    fi

    # Run create
    "$script" create >/dev/null 2>&1

    # Check all users exist
    for user in labuser01 labuser02 labuser03; do
        if ! getent passwd "$user" >/dev/null 2>&1; then
            echo ""
            print_color "$RED" "✗ User '$user' does not exist after create"
            return 1
        fi
    done

    # Check log file has entries
    if [ ! -s "/tmp/lab23b/logs/provision.log" ]; then
        echo ""
        print_color "$RED" "✗ Log file is empty or missing"
        echo "  Ensure create and cleanup modes write to \$LOG_FILE"
        return 1
    fi

    # Run cleanup and verify users are gone
    "$script" cleanup >/dev/null 2>&1
    for user in labuser01 labuser02 labuser03; do
        if getent passwd "$user" >/dev/null 2>&1; then
            echo ""
            print_color "$RED" "✗ User '$user' still exists after cleanup"
            return 1
        fi
    done

    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  /tmp/lab23b/scripts/provision.sh create
  id labuser01
  id labuser02
  id labuser03
  cat /tmp/lab23b/logs/provision.log

  # Second run — should show SKIP entries
  /tmp/lab23b/scripts/provision.sh create
  grep SKIP /tmp/lab23b/logs/provision.log

  /tmp/lab23b/scripts/provision.sh verify; echo "Exit: $?"
  # Expected: OK: labuser01 / OK: labuser02 / OK: labuser03 / Exit: 0

  /tmp/lab23b/scripts/provision.sh cleanup
  /tmp/lab23b/scripts/provision.sh verify; echo "Exit: $?"
  # Expected: MISSING: labuser01 / ... / Exit: 1

Complete provision.sh for reference — all four modes together:

#!/bin/bash
CONFIG="/tmp/lab23b/config/provision.conf"
USERS_CSV="/tmp/lab23b/config/new-users.csv"

[ -z "$1" ] && { echo "Usage: $(basename $0) {create|verify|cleanup}"; exit 1; }
[ -f "$CONFIG" ] || { echo "ERROR: Config missing: $CONFIG"; exit 1; }

source "$CONFIG"
mkdir -p "$(dirname "$LOG_FILE")"

case $1 in
    create)
        while IFS=: read -r username group shell; do
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            FULL_GROUP="${GROUP_PREFIX}${group}"
            groupadd "$FULL_GROUP" 2>/dev/null || true
            if getent passwd "$username" >/dev/null 2>&1; then
                echo "[$TIMESTAMP] SKIP: $username" | tee -a "$LOG_FILE"
                continue
            fi
            useradd -m -d "${HOME_BASE}/${username}" -s "/bin/${shell}" \
                    -g "$FULL_GROUP" "$username"
            echo "[$TIMESTAMP] CREATED: $username" | tee -a "$LOG_FILE"
        done < "$USERS_CSV"
        ;;
    verify)
        MISSING=0
        while IFS=: read -r username group shell; do
            if getent passwd "$username" >/dev/null 2>&1; then
                echo "OK: $username"
            else
                echo "MISSING: $username"
                MISSING=1
            fi
        done < "$USERS_CSV"
        [ "$MISSING" -eq 1 ] && exit 1
        ;;
    cleanup)
        while IFS=: read -r username group shell; do
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            userdel -r "$username" 2>/dev/null || true
            groupdel "${GROUP_PREFIX}${group}" 2>/dev/null || true
            echo "[$TIMESTAMP] REMOVED: $username" | tee -a "$LOG_FILE"
        done < "$USERS_CSV"
        ;;
    *)
        echo "Unknown mode: $1"; exit 1 ;;
esac

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=4

    echo "Checking your provisioning script..."
    echo ""

    local script="/tmp/lab23b/scripts/provision.sh"

    print_color "$CYAN" "[1/$total] Checking script structure (source, case, argument validation)..."
    if [ -x "$script" ]; then
        local uses_source=0; grep -qE "^(source|\.) " "$script" && uses_source=1
        local uses_case=0;   grep -q "^case" "$script" && uses_case=1

        "$script" >/dev/null 2>&1
        local no_arg_exit=$?
        "$script" bogus >/dev/null 2>&1
        local bogus_exit=$?

        if [ "$uses_source" -eq 1 ] && [ "$uses_case" -eq 1 ] && \
           [ "$no_arg_exit" -ne 0 ] && [ "$bogus_exit" -ne 0 ]; then
            print_color "$GREEN" "  ✓ Script structure correct: source, case, argument validation"
            ((score++))
        else
            [ "$uses_source" -eq 0 ] && print_color "$RED" "  ✗ Config not sourced"
            [ "$uses_case" -eq 0 ]   && print_color "$RED" "  ✗ case statement not found"
            [ "$no_arg_exit" -eq 0 ] && print_color "$RED" "  ✗ Should exit 1 with no arguments"
            [ "$bogus_exit" -eq 0 ]  && print_color "$RED" "  ✗ Unknown mode should exit 1"
        fi
    else
        print_color "$RED" "  ✗ provision.sh not found or not executable"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking 'create' mode (users exist after running)..."
    "$script" create >/dev/null 2>&1
    local all_exist=1
    for user in labuser01 labuser02 labuser03; do
        getent passwd "$user" >/dev/null 2>&1 || { all_exist=0; break; }
    done
    if [ "$all_exist" -eq 1 ]; then
        print_color "$GREEN" "  ✓ All 3 users created successfully"
        ((score++))
    else
        print_color "$RED" "  ✗ Not all users were created"
        print_color "$YELLOW" "  Fix: implement create mode with groupadd + useradd per CSV user"
    fi
    echo ""

    print_color "$CYAN" "[3/$total] Checking 'verify' mode exit codes..."
    "$script" verify >/dev/null 2>&1
    local verify_with_users=$?
    if [ "$verify_with_users" -eq 0 ]; then
        print_color "$GREEN" "  ✓ verify exits 0 when all users exist"
        ((score++))
    else
        print_color "$RED" "  ✗ verify should exit 0 when all users exist (got $verify_with_users)"
    fi
    echo ""

    print_color "$CYAN" "[4/$total] Checking 'cleanup' mode and log file..."
    if [ -s "/tmp/lab23b/logs/provision.log" ]; then
        "$script" cleanup >/dev/null 2>&1
        local all_gone=1
        for user in labuser01 labuser02 labuser03; do
            getent passwd "$user" >/dev/null 2>&1 && { all_gone=0; break; }
        done
        if [ "$all_gone" -eq 1 ]; then
            print_color "$GREEN" "  ✓ All users removed by cleanup; log file has content"
            ((score++))
        else
            print_color "$RED" "  ✗ Not all users removed by cleanup"
        fi
    else
        print_color "$RED" "  ✗ Log file is empty or missing (/tmp/lab23b/logs/provision.log)"
        print_color "$YELLOW" "  Fix: add tee -a \"\$LOG_FILE\" logging to create/cleanup modes"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "You built a complete, production-style provisioning tool combining"
        echo "every bash scripting concept from this module."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above. Run with --solution for the complete script."
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
COMPLETE SOLUTION — provision.sh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cat > /tmp/lab23b/scripts/provision.sh << 'SCRIPT'
#!/bin/bash
# User provisioning tool
# Usage: provision.sh {create|verify|cleanup}

CONFIG="/tmp/lab23b/config/provision.conf"
USERS_CSV="/tmp/lab23b/config/new-users.csv"

# Argument validation
if [ -z "$1" ]; then
    echo "Usage: $(basename $0) {create|verify|cleanup}"
    exit 1
fi

# Load config
if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Config not found: $CONFIG"
    exit 1
fi
source "$CONFIG"
mkdir -p "$(dirname "$LOG_FILE")"

# Dispatch
case $1 in
    create)
        echo "Provisioning users from $USERS_CSV..."
        while IFS=: read -r username group shell; do
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            FULL_GROUP="${GROUP_PREFIX}${group}"
            groupadd "$FULL_GROUP" 2>/dev/null || true
            if getent passwd "$username" >/dev/null 2>&1; then
                echo "[$TIMESTAMP] SKIP: $username already exists" | tee -a "$LOG_FILE"
                continue
            fi
            useradd -m \
                    -d "${HOME_BASE}/${username}" \
                    -s "/bin/${shell}" \
                    -g "$FULL_GROUP" \
                    "$username"
            echo "[$TIMESTAMP] CREATED: $username (${FULL_GROUP}, /bin/${shell})" \
                | tee -a "$LOG_FILE"
        done < "$USERS_CSV"
        echo "Done. Log: $LOG_FILE"
        ;;
    verify)
        MISSING=0
        while IFS=: read -r username group shell; do
            if getent passwd "$username" >/dev/null 2>&1; then
                echo "OK: $username"
            else
                echo "MISSING: $username"
                MISSING=1
            fi
        done < "$USERS_CSV"
        [ "$MISSING" -eq 1 ] && exit 1
        echo "All users verified"
        ;;
    cleanup)
        echo "Removing provisioned users..."
        while IFS=: read -r username group shell; do
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            userdel -r "$username" 2>/dev/null || true
            groupdel "${GROUP_PREFIX}${group}" 2>/dev/null || true
            echo "[$TIMESTAMP] REMOVED: $username" | tee -a "$LOG_FILE"
        done < "$USERS_CSV"
        echo "Cleanup complete"
        ;;
    *)
        echo "Unknown mode: $1"
        echo "Usage: $(basename $0) {create|verify|cleanup}"
        exit 1
        ;;
esac
SCRIPT

chmod +x /tmp/lab23b/scripts/provision.sh


CONCEPTS DEMONSTRATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Every construct from the scripting module appears in this script:

  Positional params:  $1 (mode argument), $0 (script name in usage)
  Parameter expansion: ${GROUP_PREFIX}${group}, $(basename $0)
  Argument validation: [ -z "$1" ] → exit 1
  source:             Loads config variables into current shell
  case:               Dispatches to create/verify/cleanup/default
  while IFS=: read:  Parses CSV line by line, splits on colon
  getent:             Checks user/group existence safely
  continue:           Skips already-existing users in create loop
  Exit codes:         exit 0 (success), exit 1 (failure)
  tee -a:             Logs to file while still printing to stdout
  || true:            Makes idempotent — safe to re-run
  Failure flag:       MISSING=0; set to 1; check after loop → exit 1


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Build structure first, implement logic second — skeleton + test, then fill in
2. getent passwd/group is the correct way to check existence on any RHEL system
3. Always remove users before groups (userdel first, then groupdel)
4. || true after cleanup commands prevents pipefail errors on re-runs
5. tee -a is the clean way to log without redirecting the whole script
6. The MISSING=0 flag pattern handles "any failure in a loop → overall failure"

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    for u in labuser01 labuser02 labuser03; do
        userdel -r "$u" 2>/dev/null || true
    done
    for g in labdevelopers labsysadmin; do
        groupdel "$g" 2>/dev/null || true
    done
    rm -rf /tmp/lab23b 2>/dev/null || true

    echo "  ✓ Users and groups removed"
    echo "  ✓ All lab files removed"
}

main "$@"
