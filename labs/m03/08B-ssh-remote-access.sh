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
