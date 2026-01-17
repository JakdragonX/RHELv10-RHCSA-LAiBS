#!/bin/bash
# labs/m02/08B-ssh-remote-access.sh
# Lab: SSH Remote Access and Secure File Transfer
# Difficulty: Beginner
# RHCSA Objective: 8.5 - Using SSH and SCP for remote system access

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="SSH Remote Access and Secure File Transfer"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    userdel -r sshuser 2>/dev/null || true
    rm -rf /home/sshuser 2>/dev/null || true
    rm -rf /tmp/ssh-lab-test 2>/dev/null || true
    rm -f /tmp/transferred-*.txt 2>/dev/null || true
    
    # Create test user
    useradd -m -s /bin/bash sshuser 2>/dev/null || true
    echo "sshuser:testpass123" | chpasswd 2>/dev/null
    
    # Create test directories and files
    mkdir -p /tmp/ssh-lab-test/{source,dest} 2>/dev/null || true
    echo "This is test file 1" > /tmp/ssh-lab-test/source/testfile1.txt
    echo "This is test file 2" > /tmp/ssh-lab-test/source/testfile2.txt
    echo "Configuration data" > /tmp/ssh-lab-test/source/config.conf
    chmod 644 /tmp/ssh-lab-test/source/*.txt /tmp/ssh-lab-test/source/*.conf
    
    # Ensure SSH service is running
    systemctl start sshd 2>/dev/null || true
    systemctl enable sshd 2>/dev/null || true
    
    echo "  ✓ Created test user: sshuser (password: testpass123)"
    echo "  ✓ Created test files in /tmp/ssh-lab-test/source/"
    echo "  ✓ SSH service is running"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of network connectivity
  • Understanding of file permissions
  • Familiarity with Linux file paths

Commands You'll Use:
  • ssh - Securely connect to remote systems
  • scp - Securely copy files between systems
  • systemctl - Manage system services
  • ip - Display network information

Files You'll Interact With:
  • /tmp/ssh-lab-test/source/* - Source files to transfer
  • /tmp/ssh-lab-test/dest/ - Destination for transferred files
  • /etc/ssh/sshd_config - SSH server configuration (view only)
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator who needs to manage remote servers and transfer
files securely between systems. SSH (Secure Shell) is the standard tool for
remote administration in Linux environments. You need to demonstrate proficiency
in connecting to remote systems and transferring files securely.

LAB DIRECTORY: /tmp/ssh-lab-test
  (Contains source/ and dest/ subdirectories for file transfer practice)

BACKGROUND:
The company requires all remote connections to use SSH for security. You need
to demonstrate connecting to the local system (to simulate remote access),
executing remote commands, and transferring files using SCP. For this lab,
you'll connect to localhost to practice SSH commands.

OBJECTIVES:
  1. Verify SSH service is active and enabled
     • Check sshd service status
     • Ensure it's set to start automatically at boot

  2. Connect to localhost as sshuser and create a file
     • SSH to localhost as the sshuser account
     • Create the file /tmp/ssh-connection-test.txt with content "SSH works"
     • Use a single SSH command (don't start an interactive session)

  3. Use SCP to copy testfile1.txt to the destination directory
     • Source: /tmp/ssh-lab-test/source/testfile1.txt
     • Destination: /tmp/ssh-lab-test/dest/testfile1.txt
     • Use sshuser@localhost as the remote target
     • Note: Password is testpass123

  4. Use SCP to copy ALL files from source to destination
     • Copy all files from /tmp/ssh-lab-test/source/
     • Destination: /tmp/ssh-lab-test/dest/
     • Use sshuser@localhost as the remote target

HINTS:
  • Use systemctl status sshd to check service status
  • SSH command format: ssh user@host command
  • SCP format: scp source user@host:destination
  • Use wildcards with SCP: scp *.txt user@host:/path/
  • You'll be prompted for the password (testpass123) for each scp command

SUCCESS CRITERIA:
  • sshd service is active and enabled
  • File /tmp/ssh-connection-test.txt exists with correct content
  • testfile1.txt is copied to /tmp/ssh-lab-test/dest/
  • All files from source/ are copied to dest/
  • All operations use secure SSH/SCP protocols
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

# Return the number of steps in interactive mode
get_step_count() {
    echo "4"
}

# Context shown once at the start of interactive mode
scenario_context() {
    cat << 'EOF'
You need to practice SSH remote administration and secure file transfer. SSH is
the standard protocol for secure remote access in Linux environments. You'll
practice connecting to localhost (to simulate remote access), executing commands
remotely, and transferring files securely using SCP.

Test user: sshuser (password: testpass123)
Test files are in: /tmp/ssh-lab-test/source/
EOF
}

# STEP 1: Verify SSH service
show_step_1() {
    cat << 'EOF'
TASK: Verify that the SSH service (sshd) is active and enabled

The SSH daemon (sshd) must be running to accept incoming connections. You need
to verify it's currently active and set to start automatically at boot.

What to do:
  • Check if sshd is currently running
  • Check if sshd is enabled to start at boot
  • If not active or enabled, fix it

Tools available:
  • systemctl status sshd - Check service status
  • systemctl is-active sshd - Check if running
  • systemctl is-enabled sshd - Check if starts at boot
  • systemctl enable --now sshd - Enable and start in one command

Think about:
  • What's the difference between "active" and "enabled"?
  • Why is SSH important for remote administration?

After completing: Type 'done' to validate
EOF
}

validate_step_1() {
    local ok=true
    
    if ! systemctl is-active sshd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ sshd service is not active"
        ok=false
    fi
    
    if ! systemctl is-enabled sshd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ sshd service is not enabled"
        ok=false
    fi
    
    if [ "$ok" = true ]; then
        return 0
    else
        echo "  Try: sudo systemctl enable --now sshd"
        return 1
    fi
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo systemctl status sshd
  sudo systemctl enable --now sshd

Explanation:
  • systemctl status: Shows detailed service status
  • systemctl enable: Sets service to start at boot
  • --now: Also starts the service immediately
  • sshd: The SSH daemon service

Why this matters:
  Without sshd running, you cannot accept SSH connections. The enable
  command ensures the service starts automatically after a reboot, while
  --now starts it immediately.

Verification:
  systemctl is-active sshd
  # Expected: active
  
  systemctl is-enabled sshd
  # Expected: enabled

EOF
}

hint_step_2() {
    echo "  Format: ssh user@host 'command to run'"
    echo "  Remember to quote the command so it runs remotely"
}

# STEP 2: Execute remote command via SSH
show_step_2() {
    cat << 'EOF'
TASK: Use SSH to execute a command on localhost and create a test file

Instead of starting an interactive SSH session, you can execute a single
command remotely. This is useful for automation and quick administrative tasks.

What to do:
  • SSH to localhost as user 'sshuser'
  • Execute this command remotely: echo "SSH works" > /tmp/ssh-connection-test.txt
  • Do this in ONE ssh command (don't start an interactive session)
  • Password is: testpass123

Tools available:
  • ssh user@host 'command' - Execute single command remotely

Format:
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'

Think about:
  • Why do we quote the command?
  • What happens if you don't quote it?

After completing: Verify with: cat /tmp/ssh-connection-test.txt
Then type 'done'
EOF
}

validate_step_2() {
    if [ ! -f /tmp/ssh-connection-test.txt ]; then
        echo ""
        print_color "$RED" "✗ File /tmp/ssh-connection-test.txt not found"
        echo "  Try: ssh sshuser@localhost 'echo \"SSH works\" > /tmp/ssh-connection-test.txt'"
        return 1
    fi
    
    if grep -q "SSH works" /tmp/ssh-connection-test.txt 2>/dev/null; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ File exists but content is incorrect"
        echo "  Expected content: 'SSH works'"
        return 1
    fi
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'

(Enter password: testpass123 when prompted)

Explanation:
  • ssh: The SSH client command
  • sshuser@localhost: Connect as sshuser to localhost
  • 'command': Single-quoted command to execute remotely
  • The command creates a file with the specified content

Why this matters:
  Executing remote commands via SSH is essential for automation and
  quick administrative tasks. The quotes are critical - without them,
  the redirect (>) would happen on your local machine, not remotely.

Wrong (runs locally):
  ssh sshuser@localhost echo "SSH works" > /tmp/ssh-connection-test.txt
  # File created on YOUR machine, not remote

Correct (runs remotely):
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'
  # File created on REMOTE machine

Verification:
  cat /tmp/ssh-connection-test.txt
  # Expected output: SSH works

EOF
}

hint_step_3() {
    echo "  Format: scp /source/file user@host:/destination/"
    echo "  Don't forget the colon (:) before the destination path"
}

# STEP 3: Transfer single file with SCP
show_step_3() {
    cat << 'EOF'
TASK: Use SCP to securely copy testfile1.txt to the destination directory

SCP (Secure Copy Protocol) uses SSH to transfer files securely between systems.
You'll copy one file from the source directory to the destination directory.

What to do:
  • Copy /tmp/ssh-lab-test/source/testfile1.txt
  • To: /tmp/ssh-lab-test/dest/
  • Use sshuser@localhost as the remote target
  • Password is: testpass123

Tools available:
  • scp source user@host:destination - Secure file copy

Format:
  scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/

Think about:
  • Why do we need the colon (:) in the destination?
  • What happens if you forget it?

After completing: Verify with: ls /tmp/ssh-lab-test/dest/
Then type 'done'
EOF
}

validate_step_3() {
    if [ ! -f /tmp/ssh-lab-test/dest/testfile1.txt ]; then
        echo ""
        print_color "$RED" "✗ testfile1.txt not found in destination"
        echo "  Try: scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/"
        return 1
    fi
    
    if grep -q "This is test file 1" /tmp/ssh-lab-test/dest/testfile1.txt 2>/dev/null; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ File exists but content is incorrect"
        return 1
    fi
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/

(Enter password: testpass123 when prompted)

Explanation:
  • scp: Secure copy command
  • /tmp/ssh-lab-test/source/testfile1.txt: Source file (local)
  • sshuser@localhost: Remote user and host
  • :/tmp/ssh-lab-test/dest/: Remote destination (note the colon!)

Why this matters:
  The colon (:) after the hostname tells SCP this is a remote path.
  Without it, SCP treats it as a local path, which is a common mistake.

Common mistakes:
  Wrong: scp file user@host/path  (missing colon)
  Right: scp file user@host:/path (has colon)

Verification:
  ls /tmp/ssh-lab-test/dest/
  # Should show: testfile1.txt
  
  cat /tmp/ssh-lab-test/dest/testfile1.txt
  # Should show: This is test file 1

EOF
}

hint_step_4() {
    echo "  Use wildcards: /tmp/ssh-lab-test/source/*"
    echo "  The * will match all files in the directory"
}

# STEP 4: Transfer multiple files with wildcards
show_step_4() {
    cat << 'EOF'
TASK: Use SCP to copy ALL remaining files from source to destination

Now you'll transfer multiple files at once using a wildcard. This is more
efficient than copying files one at a time.

What to do:
  • Copy ALL files from /tmp/ssh-lab-test/source/
  • To: /tmp/ssh-lab-test/dest/
  • Use a wildcard (*) to match all files
  • Use sshuser@localhost as the remote target
  • Password is: testpass123

Tools available:
  • scp with wildcard: scp /path/to/source/* user@host:/dest/

Format:
  scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/

Think about:
  • How does the shell expand the * wildcard?
  • Can you use wildcards for the destination?

After completing: Verify with: ls /tmp/ssh-lab-test/dest/
You should see: testfile1.txt, testfile2.txt, config.conf
Then type 'done'
EOF
}

validate_step_4() {
    local ok=true
    
    if [ ! -f /tmp/ssh-lab-test/dest/testfile2.txt ]; then
        echo ""
        print_color "$RED" "✗ testfile2.txt not found in destination"
        ok=false
    fi
    
    if [ ! -f /tmp/ssh-lab-test/dest/config.conf ]; then
        echo ""
        print_color "$RED" "✗ config.conf not found in destination"
        ok=false
    fi
    
    if [ "$ok" = true ]; then
        return 0
    else
        echo "  Try: scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/"
        return 1
    fi
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/

(Enter password: testpass123 when prompted)

Explanation:
  • * wildcard: Matches all files in the directory
  • The shell expands * before SCP runs
  • SCP sees: scp file1 file2 file3 user@host:/dest/
  • All files are transferred using one SSH connection

Why this matters:
  Using wildcards is more efficient than running scp multiple times.
  The files are transferred in a single operation, reducing connection
  overhead and making the process faster.

Alternative for directories:
  scp -r /source/dir/ user@host:/dest/
  # The -r flag recursively copies entire directories

Verification:
  ls /tmp/ssh-lab-test/dest/
  # Should show: testfile1.txt testfile2.txt config.conf
  
  # Check file count
  ls /tmp/ssh-lab-test/dest/ | wc -l
  # Should show: 3

EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

# Return the number of steps in interactive mode
get_step_count() {
    echo "4"
}

# Context shown once at the start of interactive mode
scenario_context() {
    cat << 'EOF'
You need to manage remote servers and transfer files securely using SSH and SCP.
For this lab, you'll practice by connecting to localhost (simulating remote access).
A test user 'sshuser' has been created with password: testpass123

Lab directory: /tmp/ssh-lab-test
EOF
}

# STEP 1: Verify SSH service
show_step_1() {
    cat << 'EOF'
TASK: Verify the SSH service is active and enabled

Before you can connect remotely, the SSH server daemon (sshd) must be running
and configured to start automatically at boot. You'll use systemctl to check
and configure the service.

What to do:
  • Check if sshd service is currently active
  • Ensure sshd is enabled to start at boot
  • If not active/enabled, start and enable it

Tools available:
  • systemctl status sshd - Check current status
  • systemctl is-active sshd - Check if running
  • systemctl is-enabled sshd - Check if auto-starts
  • systemctl enable --now sshd - Enable and start in one command

Think about:
  • What's the difference between "active" and "enabled"?
  • Why does a service need to be both?

After completing: Run: systemctl status sshd
EOF
}

validate_step_1() {
    if systemctl is-active sshd >/dev/null 2>&1 && \
       systemctl is-enabled sshd >/dev/null 2>&1; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ sshd service is not both active and enabled"
        echo "  Try: sudo systemctl enable --now sshd"
        return 1
    fi
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo systemctl status sshd
  sudo systemctl enable --now sshd

Or separately:
  sudo systemctl start sshd
  sudo systemctl enable sshd

Explanation:
  • systemctl: System and service manager command
  • enable: Configure service to start at boot
  • --now: Also start the service immediately
  • start: Start the service now (if not using --now)

Why this matters:
  SSH requires the sshd daemon to be running to accept connections.
  "Active" means it's running now. "Enabled" means it starts at boot.
  Both are needed for reliable remote access.

Verification:
  systemctl is-active sshd
  # Expected: active
  
  systemctl is-enabled sshd
  # Expected: enabled

EOF
}

hint_step_2() {
    echo "  Format: ssh user@host 'command'"
    echo "  Use single quotes to prevent local shell interpretation"
}

# STEP 2: Execute remote command via SSH
show_step_2() {
    cat << 'EOF'
TASK: Use SSH to create a file on the remote system (localhost)

SSH can execute a single command on a remote system without starting an
interactive session. This is useful for automation and quick tasks.

What to do:
  • Connect to localhost as user 'sshuser'
  • Execute a command that creates: /tmp/ssh-connection-test.txt
  • The file should contain: "SSH works"
  • Do this with ONE ssh command (no interactive session)

Password: testpass123

Tools available:
  • ssh user@host 'command' - Execute command remotely
  • echo "text" > file - Create file with content

Format:
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'

Think about:
  • Why use single quotes around the command?
  • What happens if you use double quotes or no quotes?

After completing: Check with: cat /tmp/ssh-connection-test.txt
EOF
}

validate_step_2() {
    if [ -f /tmp/ssh-connection-test.txt ]; then
        if grep -q "SSH works" /tmp/ssh-connection-test.txt 2>/dev/null; then
            return 0
        else
            echo ""
            print_color "$RED" "✗ File exists but content is incorrect"
            echo "  Expected: 'SSH works'"
            return 1
        fi
    else
        echo ""
        print_color "$RED" "✗ File /tmp/ssh-connection-test.txt not found"
        echo "  Create with: ssh sshuser@localhost 'echo \"SSH works\" > /tmp/ssh-connection-test.txt'"
        return 1
    fi
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'

(Password: testpass123)

Explanation:
  • ssh: The SSH client command
  • sshuser@localhost: User and hostname to connect to
  • 'command': Command to execute on remote system (in single quotes)
  • echo "SSH works": Command to run remotely
  • > /tmp/ssh-connection-test.txt: Redirect to file (happens remotely)

Why this matters:
  Single quotes prevent the local shell from interpreting the command.
  Everything inside the quotes is sent to the remote system and executed
  there. This is crucial for automation and scripting.

Verification:
  cat /tmp/ssh-connection-test.txt
  # Expected output: SSH works

EOF
}

hint_step_3() {
    echo "  Format: scp source user@host:/destination/path/"
    echo "  Don't forget the colon (:) after hostname!"
}

# STEP 3: Transfer single file with SCP
show_step_3() {
    cat << 'EOF'
TASK: Use SCP to copy a single file to the destination directory

SCP (Secure Copy Protocol) uses SSH to transfer files securely. You'll copy
one test file from the source directory to the destination.

What to do:
  • Copy: /tmp/ssh-lab-test/source/testfile1.txt
  • To: /tmp/ssh-lab-test/dest/testfile1.txt
  • Use sshuser@localhost as the remote target
  • End the destination path with / to preserve the filename

Password: testpass123

Tools available:
  • scp source user@host:/dest/ - Copy file to remote system

Format:
  scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/

Think about:
  • Why is the colon (:) important in the destination?
  • What happens if you forget the / at the end?

After completing: Check with: ls -l /tmp/ssh-lab-test/dest/
EOF
}

validate_step_3() {
    if [ -f /tmp/ssh-lab-test/dest/testfile1.txt ]; then
        if grep -q "This is test file 1" /tmp/ssh-lab-test/dest/testfile1.txt 2>/dev/null; then
            return 0
        else
            echo ""
            print_color "$RED" "✗ File exists but content is incorrect"
            return 1
        fi
    else
        echo ""
        print_color "$RED" "✗ testfile1.txt not found in destination"
        echo "  Copy with: scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/"
        return 1
    fi
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/

(Password: testpass123)

Explanation:
  • scp: Secure copy protocol command
  • /tmp/ssh-lab-test/source/testfile1.txt: Source file (local)
  • sshuser@localhost: Remote user and hostname
  • :/tmp/ssh-lab-test/dest/: Remote destination path (note the colon!)

Why this matters:
  The colon (:) after the hostname tells SCP this is a remote path, not
  a local one. Ending with / preserves the original filename. Without
  it, the file might be renamed.

Verification:
  ls -l /tmp/ssh-lab-test/dest/testfile1.txt
  cat /tmp/ssh-lab-test/dest/testfile1.txt
  # Should contain: This is test file 1

EOF
}

hint_step_4() {
    echo "  Use wildcards: scp /path/to/source/* user@host:/dest/"
    echo "  The * expands to all files before SCP runs"
}

# STEP 4: Transfer multiple files with wildcards
show_step_4() {
    cat << 'EOF'
TASK: Use SCP to copy all remaining files from source to destination

Instead of copying files one at a time, you can use wildcards to transfer
multiple files in a single command. You'll copy all remaining files.

What to do:
  • Copy ALL files from: /tmp/ssh-lab-test/source/
  • To: /tmp/ssh-lab-test/dest/
  • Use a wildcard (*) to match all files
  • Use sshuser@localhost as the remote target

Password: testpass123

Tools available:
  • scp source/* user@host:/dest/ - Copy multiple files

Format:
  scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/

Think about:
  • How does the shell expand the * wildcard?
  • What files haven't been copied yet?

After completing: Run: ls /tmp/ssh-lab-test/dest/
Should show: testfile1.txt testfile2.txt config.conf
EOF
}

validate_step_4() {
    local ok=true
    
    if [ ! -f /tmp/ssh-lab-test/dest/testfile2.txt ]; then
        echo ""
        print_color "$RED" "✗ testfile2.txt not found in destination"
        ok=false
    fi
    
    if [ ! -f /tmp/ssh-lab-test/dest/config.conf ]; then
        echo ""
        print_color "$RED" "✗ config.conf not found in destination"
        ok=false
    fi
    
    if [ "$ok" = true ]; then
        return 0
    else
        echo "  Copy with: scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/"
        return 1
    fi
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/

(Password: testpass123)

Explanation:
  • * wildcard: Matches all files in the source directory
  • Shell expands * before SCP runs, so SCP sees all filenames
  • All files are transferred using the same SSH connection

Why this matters:
  Using wildcards is much more efficient than copying files individually.
  The shell expands the wildcard, so:
    scp file1 file2 file3 user@host:/dest/
  All files transfer in one operation.

Alternative for directories:
  scp -r /source/directory/ user@host:/dest/
  # -r recursively copies entire directories

Verification:
  ls /tmp/ssh-lab-test/dest/
  # Should show: config.conf testfile1.txt testfile2.txt

EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

# Return the number of steps in interactive mode
get_step_count() {
    echo "4"
}

# Context shown once at the start of interactive mode
scenario_context() {
    cat << 'EOF'
You're practicing SSH remote administration and secure file transfer. SSH is the
standard protocol for remote system management in Linux. You'll connect to localhost
to simulate remote access, execute commands remotely, and transfer files securely.

Test user created: sshuser (password: testpass123)
Test files available in: /tmp/ssh-lab-test/source/
EOF
}

# STEP 1: Verify SSH service
show_step_1() {
    cat << 'EOF'
TASK: Ensure the SSH service is running and enabled

Before you can use SSH, the sshd (SSH daemon) service must be running on the
target system and configured to start automatically at boot.

What to do:
  • Check if sshd service is active (running)
  • Enable sshd to start automatically at boot
  • If not running, start it

Tools available:
  • systemctl status sshd - Check service status
  • systemctl enable sshd - Enable at boot
  • systemctl start sshd - Start service now
  • systemctl is-active sshd - Quick status check
  • systemctl is-enabled sshd - Check if enabled

Think about:
  • What's the difference between "enable" and "start"?
  • What port does SSH use by default?

After completing: Type 'done' to verify
EOF
}

validate_step_1() {
    local ok=true
    
    if ! systemctl is-active sshd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ sshd service is not active"
        echo "  Try: sudo systemctl start sshd"
        ok=false
    fi
    
    if ! systemctl is-enabled sshd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ sshd service is not enabled"
        echo "  Try: sudo systemctl enable sshd"
        ok=false
    fi
    
    if [ "$ok" = true ]; then
        return 0
    else
        return 1
    fi
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  sudo systemctl start sshd
  sudo systemctl enable sshd

Or combined:
  sudo systemctl enable --now sshd

Explanation:
  • systemctl start: Starts the service immediately
  • systemctl enable: Configures service to start at boot
  • --now: Combines enable and start in one command
  • sshd: The SSH daemon (server) service name

Why this matters:
  The SSH server (sshd) must be running to accept incoming connections.
  Enable ensures it starts automatically after reboots, which is essential
  for servers that need remote access after maintenance restarts.

Verification:
  systemctl is-active sshd
  # Expected: active
  
  systemctl is-enabled sshd
  # Expected: enabled
  
  systemctl status sshd
  # Shows detailed status including recent log entries

EOF
}

hint_step_2() {
    echo "  Format: ssh user@host 'command'"
    echo "  Use single quotes to prevent local shell interpretation"
}

# STEP 2: Execute remote command
show_step_2() {
    cat << 'EOF'
TASK: Use SSH to execute a single command on localhost

Instead of opening an interactive SSH session, you can execute a single command
remotely and have the output returned. This is useful for automation and scripts.

What to do:
  • Use SSH to connect to localhost as sshuser
  • Execute a command that creates: /tmp/ssh-connection-test.txt
  • The file should contain the text: "SSH works"
  • Password is: testpass123

Tools available:
  • ssh user@host 'command' - Execute single command
  • echo "text" > file - Create file with content

Format:
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'

Think about:
  • Why use quotes around the remote command?
  • What happens without quotes?
  • Where does the file get created - locally or remotely?

After completing: Verify with: cat /tmp/ssh-connection-test.txt
EOF
}

validate_step_2() {
    if [ ! -f /tmp/ssh-connection-test.txt ]; then
        echo ""
        print_color "$RED" "✗ File /tmp/ssh-connection-test.txt not found"
        echo "  Try: ssh sshuser@localhost 'echo \"SSH works\" > /tmp/ssh-connection-test.txt'"
        return 1
    fi
    
    if grep -q "SSH works" /tmp/ssh-connection-test.txt 2>/dev/null; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ File exists but content is incorrect"
        echo "  Expected content: SSH works"
        return 1
    fi
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'

Password: testpass123

Explanation:
  • ssh: The SSH client command
  • sshuser@localhost: Username and hostname to connect to
  • 'command': Command to execute on remote system (in quotes)
  • The entire command runs on the remote system, not locally

Why this works:
  When you provide a command after SSH connection details, SSH executes
  that command on the remote system and exits immediately (no interactive
  shell). The quotes prevent your local shell from interpreting special
  characters like > and executing the redirect locally.

Without quotes (WRONG):
  ssh sshuser@localhost echo "SSH works" > /tmp/ssh-connection-test.txt
  # This would create the file LOCALLY, not on the remote system!

Verification:
  cat /tmp/ssh-connection-test.txt
  # Expected output: SSH works
  
  ls -l /tmp/ssh-connection-test.txt
  # Check ownership - should be owned by sshuser

EOF
}

hint_step_3() {
    echo "  Format: scp source user@host:/destination/path/"
    echo "  Remember the colon (:) after the hostname!"
}

# STEP 3: Transfer single file with SCP
show_step_3() {
    cat << 'EOF'
TASK: Use SCP to securely copy a single file

SCP (Secure Copy Protocol) uses SSH to transfer files between systems.
You'll copy one file from the source directory to the destination directory.

What to do:
  • Copy: /tmp/ssh-lab-test/source/testfile1.txt
  • Destination: /tmp/ssh-lab-test/dest/testfile1.txt
  • Use sshuser@localhost as the remote target
  • Password is: testpass123

Tools available:
  • scp source user@host:destination - Copy file securely

Format:
  scp /path/to/source/file user@host:/path/to/destination/

Think about:
  • What's the difference between SCP and regular cp command?
  • Why do you need the colon (:) after the hostname?
  • What port does SCP use?

After completing: Check with: ls /tmp/ssh-lab-test/dest/
EOF
}

validate_step_3() {
    if [ ! -f /tmp/ssh-lab-test/dest/testfile1.txt ]; then
        echo ""
        print_color "$RED" "✗ testfile1.txt not found in destination"
        echo "  Try: scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/"
        return 1
    fi
    
    if grep -q "This is test file 1" /tmp/ssh-lab-test/dest/testfile1.txt 2>/dev/null; then
        return 0
    else
        echo ""
        print_color "$RED" "✗ File exists but content is incorrect"
        return 1
    fi
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/

Password: testpass123

Explanation:
  • scp: Secure copy protocol command
  • /tmp/ssh-lab-test/source/testfile1.txt: Source file (local)
  • sshuser@localhost: Remote user and hostname
  • :/tmp/ssh-lab-test/dest/: Remote destination path
  • The colon (:) separates hostname from path

Why this works:
  SCP uses SSH protocol for secure file transfer. The syntax follows:
  scp [local_file] [user@host:remote_path]
  
  When the destination ends with /, SCP preserves the original filename.
  Without the /, SCP might rename or create issues.

Common mistake:
  scp file user@host/path  ← WRONG (missing colon)
  scp file user@host:/path ← CORRECT

Verification:
  ls -l /tmp/ssh-lab-test/dest/testfile1.txt
  cat /tmp/ssh-lab-test/dest/testfile1.txt
  # Should contain: This is test file 1

EOF
}

hint_step_4() {
    echo "  Use wildcard: scp /path/to/source/* user@host:/path/to/dest/"
    echo "  The * will expand to match all files"
}

# STEP 4: Transfer multiple files with SCP
show_step_4() {
    cat << 'EOF'
TASK: Use SCP to copy all remaining files from source to destination

Instead of copying files one at a time, you can use wildcards to transfer
multiple files in a single command.

What to do:
  • Copy ALL files from: /tmp/ssh-lab-test/source/
  • Destination: /tmp/ssh-lab-test/dest/
  • Use sshuser@localhost as the remote target
  • Use a wildcard (*) to match all files
  • Password is: testpass123

Tools available:
  • scp source/* user@host:/dest/ - Copy multiple files

Think about:
  • How does the shell expand the * wildcard?
  • Can you copy directories with scp?
  • What flag would you need for directories?

After completing: Check with: ls /tmp/ssh-lab-test/dest/
You should see: testfile1.txt, testfile2.txt, config.conf
EOF
}

validate_step_4() {
    local ok=true
    
    if [ ! -f /tmp/ssh-lab-test/dest/testfile2.txt ]; then
        echo ""
        print_color "$RED" "✗ testfile2.txt not found in destination"
        ok=false
    fi
    
    if [ ! -f /tmp/ssh-lab-test/dest/config.conf ]; then
        echo ""
        print_color "$RED" "✗ config.conf not found in destination"
        ok=false
    fi
    
    if [ "$ok" = true ]; then
        return 0
    else
        echo "  Try: scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/"
        return 1
    fi
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/

Password: testpass123

Explanation:
  • * wildcard: Matches all files in the source directory
  • The shell expands * before SCP runs
  • All matched files are transferred in one SSH connection
  • More efficient than multiple separate scp commands

Why this works:
  When you use *, your shell expands it to a list of filenames before
  passing them to scp. So scp actually sees:
  scp file1 file2 file3 user@host:/dest/
  
  SCP then transfers all files using a single SSH connection, which is
  more efficient than running scp multiple times.

For directories (different command):
  scp -r /source/directory/ user@host:/dest/
  # The -r flag recursively copies entire directories

Verification:
  ls /tmp/ssh-lab-test/dest/
  # Should show: testfile1.txt testfile2.txt config.conf
  
  # Check content of transferred files:
  cat /tmp/ssh-lab-test/dest/testfile2.txt
  cat /tmp/ssh-lab-test/dest/config.conf

EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Verify sshd service is active and enabled
  ☐ 2. Use SSH to create /tmp/ssh-connection-test.txt on localhost
  ☐ 3. Use SCP to copy testfile1.txt to dest directory
  ☐ 4. Use SCP to copy all files from source to dest directory
EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    echo "Checking your SSH and file transfer configuration..."
    echo ""
    
    # CHECK 1: SSH service status
    print_color "$CYAN" "[1/$total] Checking sshd service status..."
    local sshd_ok=true
    
    if ! systemctl is-active sshd >/dev/null 2>&1; then
        print_color "$RED" "  ✗ sshd service is not active"
        sshd_ok=false
    fi
    
    if ! systemctl is-enabled sshd >/dev/null 2>&1; then
        print_color "$RED" "  ✗ sshd service is not enabled"
        sshd_ok=false
    fi
    
    if [ "$sshd_ok" = true ]; then
        print_color "$GREEN" "  ✓ sshd service is active and enabled"
        ((score++))
    else
        print_color "$YELLOW" "  Fix: sudo systemctl enable --now sshd"
    fi
    echo ""
    
    # CHECK 2: SSH remote command test
    print_color "$CYAN" "[2/$total] Checking SSH remote command execution..."
    if [ -f /tmp/ssh-connection-test.txt ]; then
        if grep -q "SSH works" /tmp/ssh-connection-test.txt 2>/dev/null; then
            print_color "$GREEN" "  ✓ File created via SSH with correct content"
            ((score++))
        else
            print_color "$RED" "  ✗ File exists but content is incorrect"
            print_color "$YELLOW" "  Expected content: 'SSH works'"
        fi
    else
        print_color "$RED" "  ✗ File /tmp/ssh-connection-test.txt not found"
        print_color "$YELLOW" "  Create with: ssh sshuser@localhost 'echo \"SSH works\" > /tmp/ssh-connection-test.txt'"
    fi
    echo ""
    
    # CHECK 3: Single file SCP transfer
    print_color "$CYAN" "[3/$total] Checking SCP file transfer (testfile1.txt)..."
    if [ -f /tmp/ssh-lab-test/dest/testfile1.txt ]; then
        if grep -q "This is test file 1" /tmp/ssh-lab-test/dest/testfile1.txt 2>/dev/null; then
            print_color "$GREEN" "  ✓ testfile1.txt successfully copied via SCP"
            ((score++))
        else
            print_color "$RED" "  ✗ File exists but content is incorrect"
        fi
    else
        print_color "$RED" "  ✗ testfile1.txt not found in destination"
        print_color "$YELLOW" "  Copy with: scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/"
    fi
    echo ""
    
    # CHECK 4: Multiple file SCP transfer
    print_color "$CYAN" "[4/$total] Checking bulk file transfer..."
    local files_ok=true
    
    if [ ! -f /tmp/ssh-lab-test/dest/testfile2.txt ]; then
        print_color "$RED" "  ✗ testfile2.txt not found in destination"
        files_ok=false
    fi
    
    if [ ! -f /tmp/ssh-lab-test/dest/config.conf ]; then
        print_color "$RED" "  ✗ config.conf not found in destination"
        files_ok=false
    fi
    
    if [ "$files_ok" = true ]; then
        print_color "$GREEN" "  ✓ All files successfully transferred"
        ((score++))
    else
        print_color "$YELLOW" "  Copy with: scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Managing SSH service with systemctl"
        echo "  • Executing remote commands via SSH"
        echo "  • Transferring individual files with SCP"
        echo "  • Transferring multiple files with wildcards"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Export for progress tracking
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

OBJECTIVE 1: Verify and enable SSH service
─────────────────────────────────────────────────────────────────
Commands:
  sudo systemctl status sshd
  sudo systemctl enable sshd
  sudo systemctl start sshd

Explanation:
  • systemctl status: Shows current status of the service
  • systemctl enable: Sets service to start automatically at boot
  • systemctl start: Starts the service immediately
  • sshd: The SSH daemon (server) service name

Why this works:
  SSH requires the sshd (SSH daemon) service to be running to accept
  incoming connections. The enable command creates a symlink so the
  service starts at boot, while start activates it immediately.

Verification:
  systemctl is-active sshd
  # Expected: active
  
  systemctl is-enabled sshd
  # Expected: enabled


OBJECTIVE 2: Execute remote command via SSH
─────────────────────────────────────────────────────────────────
Command:
  ssh sshuser@localhost 'echo "SSH works" > /tmp/ssh-connection-test.txt'

(Password: testpass123)

Explanation:
  • ssh: The SSH client command
  • sshuser@localhost: User and hostname to connect to
  • 'command': Command to execute on the remote system
  • Echo and redirect to create the file remotely

Why this works:
  When you provide a command after the SSH connection details, SSH
  executes that command on the remote system and exits, rather than
  starting an interactive shell. This is perfect for automation.

Verification:
  cat /tmp/ssh-connection-test.txt
  # Expected output: SSH works


OBJECTIVE 3: Transfer single file with SCP
─────────────────────────────────────────────────────────────────
Command:
  scp /tmp/ssh-lab-test/source/testfile1.txt sshuser@localhost:/tmp/ssh-lab-test/dest/

(Password: testpass123)

Explanation:
  • scp: Secure copy protocol command
  • /tmp/ssh-lab-test/source/testfile1.txt: Source file path
  • sshuser@localhost: Remote user and host
  • :/tmp/ssh-lab-test/dest/: Remote destination path

Why this works:
  SCP uses SSH protocol to transfer files securely. The syntax is:
  scp [source] [user@host:destination]
  If the destination is a directory (ending with /), the filename is preserved.

Verification:
  ls -l /tmp/ssh-lab-test/dest/testfile1.txt
  cat /tmp/ssh-lab-test/dest/testfile1.txt
  # Should contain: This is test file 1


OBJECTIVE 4: Transfer multiple files with SCP
─────────────────────────────────────────────────────────────────
Command:
  scp /tmp/ssh-lab-test/source/* sshuser@localhost:/tmp/ssh-lab-test/dest/

(Password: testpass123)

Explanation:
  • * wildcard: Matches all files in the source directory
  • Same scp syntax as before, but with wildcard
  • All matched files are transferred in one operation

Why this works:
  The shell expands the * wildcard before SCP runs, so SCP sees:
  scp file1 file2 file3 user@host:/dest/
  All files are transferred using the same SSH connection.

Alternative for directories:
  scp -r /tmp/ssh-lab-test/source/ sshuser@localhost:/tmp/ssh-lab-test/dest/
  # The -r flag recursively copies directories

Verification:
  ls /tmp/ssh-lab-test/dest/
  # Should show: testfile1.txt testfile2.txt config.conf


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SSH (Secure Shell):
  SSH is a cryptographic network protocol for secure remote access. It
  replaces insecure protocols like telnet and rlogin. SSH provides:
  • Encrypted communication channel
  • Strong authentication (password or key-based)
  • Port forwarding and tunneling capabilities
  • Secure file transfer (via SCP or SFTP)

SSH Client vs Server:
  • sshd (SSH daemon): The server that accepts connections
  • ssh: The client that initiates connections
  • The server must be running (systemctl start sshd)
  • The client is just a command you run when needed

SCP vs SFTP vs rsync:
  • SCP: Simple, fast, good for one-time transfers
  • SFTP: Interactive, like FTP but secure, good for browsing
  • rsync: Advanced, can resume transfers, synchronize directories
  For the RHCSA exam, focus on SCP as it's most commonly tested.

SSH Default Port:
  SSH uses TCP port 22 by default. Firewall rules must allow this port
  for remote access. Check with: sudo firewall-cmd --list-services


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting the colon in SCP destination
  Result: SCP treats it as a local path, not remote
  Wrong: scp file user@host/path
  Correct: scp file user@host:/path
  # Note the : after hostname

Mistake 2: Incorrect destination path format
  Result: Files copied with wrong names or to wrong location
  Fix: End directory paths with / to preserve filenames
  scp file user@host:/path/to/dir/

Mistake 3: SSH service not running
  Result: "Connection refused" errors
  Fix: sudo systemctl start sshd
  Check: systemctl status sshd

Mistake 4: Using quotes incorrectly with SSH commands
  Result: Command not executed on remote system
  Wrong: ssh user@host echo "test" > file
  # This redirects locally, not remotely
  Correct: ssh user@host 'echo "test" > file'
  # Single quotes prevent local interpretation


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always check sshd is running: systemctl status sshd
2. Remember the colon (:) in SCP destination paths
3. Use wildcards (*) to copy multiple files at once
4. Quote SSH remote commands to prevent local shell interpretation
5. Default SSH port is 22 - remember for firewall questions

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r sshuser 2>/dev/null || true
    rm -rf /tmp/ssh-lab-test 2>/dev/null || true
    rm -f /tmp/ssh-connection-test.txt 2>/dev/null || true
    rm -f /tmp/transferred-*.txt 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
