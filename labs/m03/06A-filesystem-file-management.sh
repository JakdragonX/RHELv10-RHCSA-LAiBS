#!/bin/bash
# labs/06A-filesystem-file-management.sh
# Lab: Filesystem Navigation and File Management
# Difficulty: Beginner
# RHCSA Objective: Navigate the filesystem and manage files

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Filesystem Navigation and File Management"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    rm -rf /tmp/filesystem-lab 2>/dev/null || true
    
    # Create working directory structure
    mkdir -p /tmp/filesystem-lab/{bin,etc,var/{log,spool},usr/{bin,lib},home/webadmin,backup}
    
    # Create sample configuration files
    cat > /tmp/filesystem-lab/etc/app.conf << 'EOF'
[application]
name=WebApp
version=2.1
port=8080
debug=false

[database]
host=localhost
port=5432
name=webapp_db
EOF

    cat > /tmp/filesystem-lab/etc/users.conf << 'EOF'
admin:1000:administrators
webuser:1001:webteam
dbuser:1002:database
EOF

    # Create sample log files
    echo "[2025-01-14 10:00:00] Application started" > /tmp/filesystem-lab/var/log/app.log
    echo "[2025-01-14 10:01:23] Connection established" >> /tmp/filesystem-lab/var/log/app.log
    echo "[2025-01-14 10:02:45] Processing request" >> /tmp/filesystem-lab/var/log/app.log
    
    echo "[2025-01-14 10:00:15] ERROR: Database timeout" > /tmp/filesystem-lab/var/log/error.log
    echo "[2025-01-14 10:03:20] WARNING: High memory usage" >> /tmp/filesystem-lab/var/log/error.log
    
    # Create sample binaries (scripts)
    cat > /tmp/filesystem-lab/bin/deploy.sh << 'EOF'
#!/bin/bash
echo "Deploying application..."
EOF
    chmod +x /tmp/filesystem-lab/bin/deploy.sh
    
    cat > /tmp/filesystem-lab/usr/bin/backup-db.sh << 'EOF'
#!/bin/bash
echo "Backing up database..."
EOF
    chmod +x /tmp/filesystem-lab/usr/bin/backup-db.sh
    
    # Create some files to practice finding
    echo "README: This is the main documentation" > /tmp/filesystem-lab/README.md
    echo "README: User guide" > /tmp/filesystem-lab/home/webadmin/README.md
    echo "hosts configuration" > /tmp/filesystem-lab/etc/hosts
    
    # Create files of different sizes for finding practice
    dd if=/dev/zero of=/tmp/filesystem-lab/var/spool/large-file.dat bs=1M count=15 2>/dev/null
    dd if=/dev/zero of=/tmp/filesystem-lab/backup/small-file.dat bs=1K count=50 2>/dev/null
    
    # Fix ownership
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" /tmp/filesystem-lab 2>/dev/null || true
    fi
    
    echo "  ✓ Created mock filesystem structure"
    echo "  ✓ Populated with sample files"
    echo "  ✓ Ready for exploration"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic terminal navigation (cd, pwd)
  • Understanding of files and directories
  • Familiarity with the concept of paths

Commands You'll Use:
  • ls        - List directory contents
  • cd        - Change directory
  • pwd       - Print working directory
  • mkdir     - Make directory
  • cp        - Copy files and directories
  • mv        - Move or rename files
  • rm/rmdir  - Remove files and directories
  • find      - Search for files by criteria
  • which     - Locate command executables
  • tree      - Display directory structure (if available)

Core Concepts:
  • Filesystem Hierarchy Standard (FHS)
  • Absolute vs relative paths
  • Current directory (.) and parent directory (..)
  • Home directory (~)
  • Recursive operations

Why This Matters:
  Understanding the filesystem layout is fundamental to Linux administration.
  The FHS provides a predictable structure that all distributions follow,
  making system navigation intuitive once you understand the conventions.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You've been hired as a junior system administrator for a web hosting company.
Your first task is to familiarize yourself with the filesystem structure,
locate important files, and perform basic file management operations.

BACKGROUND:
Linux organizes files according to the Filesystem Hierarchy Standard (FHS).
This standard defines what types of files belong in which directories:

  /bin      - Essential user binaries (ls, cp, cat)
  /sbin     - Essential system binaries (mount, ifconfig)
  /etc      - System configuration files
  /home     - User home directories
  /var      - Variable data (logs, spools, caches)
  /usr      - User programs and data
  /tmp      - Temporary files
  /opt      - Optional/third-party software

Understanding this structure helps you:
  • Find configuration files quickly
  • Know where to look for logs
  • Understand where to install software
  • Navigate efficiently during troubleshooting

OBJECTIVES:
Complete these tasks to demonstrate filesystem navigation mastery:

  1. Explore the filesystem structure
     • Navigate to /tmp/filesystem-lab
     • Use pwd to verify your location
     • List contents recursively: ls -R
     • Explore subdirectories: etc, var/log, usr/bin
     • Understand the FHS-style layout

  2. Practice absolute and relative paths
     • Create directory: /tmp/filesystem-lab/opt/myapp
     • From /tmp/filesystem-lab/home/webadmin, navigate to ../../etc
     • Use pwd at each step to track location
     • Return to filesystem-lab using absolute path

  3. Find files by name
     • Find all files named "README.md" in /tmp/filesystem-lab
       Command: find /tmp/filesystem-lab -name "README.md"
     • Find all .conf files
       Command: find /tmp/filesystem-lab -name "*.conf"
     • Find executable files (.sh)
       Command: find /tmp/filesystem-lab -name "*.sh" -type f

  4. Find files by size
     • Find files larger than 10MB
       Command: find /tmp/filesystem-lab -type f -size +10M
     • Find files smaller than 100KB
       Command: find /tmp/filesystem-lab -type f -size -100k
     • Create list: find output → /tmp/filesystem-lab/large-files.txt

  5. Copy and organize files
     • Copy all .conf files from etc/ to backup/config-backup/
     • Create the backup directory structure first
     • Use cp with -v (verbose) to see what's copied
     • Verify files were copied: ls backup/config-backup/

  6. Move and rename operations
     • Move var/log/error.log to var/log/error.log.old
     • Create new empty error.log: touch var/log/error.log
     • Move all .sh files from bin/ to usr/bin/
     • Verify with: ls -l usr/bin/

HINTS:
  • Use tab completion to speed up typing paths
  • pwd is your friend - use it often to know where you are
  • ls -la shows hidden files and detailed info
  • find is extremely powerful - practice different flags
  • Use -R or -r for recursive operations (copy, list, remove)
  • Always double-check paths before using rm -r!

SUCCESS CRITERIA:
  • You can navigate using both absolute and relative paths
  • You can find files based on name, type, and size
  • You understand the purpose of different directories
  • You can copy, move, and organize files effectively
  • You're comfortable with find command syntax
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Navigate and explore /tmp/filesystem-lab structure
  ☐ 2. Practice using absolute and relative paths
  ☐ 3. Find files: all README.md files and all .conf files
  ☐ 4. Find by size: files > 10MB, create list in large-files.txt
  ☐ 5. Copy all .conf files from etc/ to backup/config-backup/
  ☐ 6. Move error.log to error.log.old, move .sh files to usr/bin/
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
You're a junior sysadmin learning to navigate the Linux filesystem. You'll
explore the FHS structure, find files using various criteria, and perform
essential file management operations.
EOF
}

# STEP 1: Explore filesystem
show_step_1() {
    cat << 'EOF'
TASK: Navigate and explore the mock filesystem structure

Get familiar with the layout of /tmp/filesystem-lab, which mimics
a real Linux filesystem following FHS conventions.

Requirements:
  • Navigate to: cd /tmp/filesystem-lab
  • Show current location: pwd
  • List all contents recursively: ls -R
  • Explore key directories: etc, var/log, usr/bin, home
  • Count directories: find . -type d | wc -l

Commands you'll use:
  • cd    - Change directory
  • pwd   - Print working directory
  • ls    - List contents
  • find  - Search filesystem

What you're learning:
  The Filesystem Hierarchy Standard defines where different types of
  files belong. Configuration files go in /etc, logs in /var/log,
  user binaries in /usr/bin, etc. This consistency makes Linux
  predictable and easier to administer.

Real FHS directories you should know:
  /etc      - Configuration files (editable text configs)
  /var      - Variable data (logs, spools, databases)
  /var/log  - Log files
  /usr/bin  - User commands (non-essential)
  /bin      - Essential commands needed for boot
  /home     - User home directories
  /tmp      - Temporary files (cleared on reboot)
  /opt      - Optional software packages

To complete this step, navigate around and familiarize yourself
with the structure. No specific file to create - just explore!
EOF
}

validate_step_1() {
    # This is exploratory - we just check if the lab structure exists
    if [ ! -d "/tmp/filesystem-lab" ]; then
        echo ""
        print_color "$RED" "✗ Lab directory doesn't exist"
        echo "  Run setup again"
        return 1
    fi
    
    # They should have explored - we'll just pass this step
    echo ""
    print_color "$GREEN" "✓ Filesystem structure is ready for exploration"
    echo ""
    echo "  Try these commands to explore:"
    echo "    cd /tmp/filesystem-lab"
    echo "    pwd"
    echo "    ls -R"
    echo "    cd etc && ls -la"
    echo "    cd ../var/log && ls -la"
    echo ""
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Exploration commands:

  # Navigate to lab directory
  cd /tmp/filesystem-lab
  
  # Verify location
  pwd
  # Output: /tmp/filesystem-lab
  
  # List all contents recursively
  ls -R
  
  # Explore specific directories
  cd etc
  ls -la
  
  cd ../var/log
  ls -la
  
  cd ../../usr/bin
  ls -la
  
  # Count directories
  find /tmp/filesystem-lab -type d | wc -l

Understanding the structure:
  • /tmp/filesystem-lab acts as the "root" (/)
  • etc/ contains configuration files
  • var/log/ contains log files
  • usr/bin/ contains user programs
  • home/ contains user directories
  • backup/ is for backup storage

This mirrors the real Linux filesystem:
  
  Real Linux          Lab Directory
  ──────────          ─────────────
  /etc/               /tmp/filesystem-lab/etc/
  /var/log/           /tmp/filesystem-lab/var/log/
  /usr/bin/           /tmp/filesystem-lab/usr/bin/
  /home/username/     /tmp/filesystem-lab/home/webadmin/

Key navigation commands:
  pwd                 Show current directory
  cd /absolute/path   Jump to absolute location
  cd relative/path    Navigate relative to current location
  cd ..               Go up one directory
  cd ~                Go to home directory
  cd -                Go to previous directory

Tab completion:
  Type part of a directory name and press Tab
  Example: cd /tmp/fil[Tab] → completes to /tmp/filesystem-lab/

EOF
}

hint_step_2() {
    echo "  Use .. to go up, use absolute paths starting with /"
}

# STEP 2: Absolute vs relative paths
show_step_2() {
    cat << 'EOF'
TASK: Practice navigating with absolute and relative paths

Master the difference between absolute paths (starting with /)
and relative paths (starting from current location).

Requirements:
  • Create: /tmp/filesystem-lab/opt/myapp (absolute path)
  • Navigate to: /tmp/filesystem-lab/home/webadmin
  • From there, go to etc using relative path: ../../etc
  • Use pwd after each cd to verify location
  • Create proof file: /tmp/filesystem-lab/step2-proof.txt
    Content: pwd output from each location visited

Commands to run:
  mkdir -p /tmp/filesystem-lab/opt/myapp
  cd /tmp/filesystem-lab/home/webadmin
  pwd > /tmp/filesystem-lab/step2-proof.txt
  cd ../../etc
  pwd >> /tmp/filesystem-lab/step2-proof.txt
  cd /tmp/filesystem-lab
  pwd >> /tmp/filesystem-lab/step2-proof.txt

What you're learning:
  Absolute paths: Always start from root (/)
    • Work from anywhere
    • Explicit and unambiguous
    • Example: /tmp/filesystem-lab/etc/app.conf
  
  Relative paths: Start from current directory
    • Shorter to type when already nearby
    • Use . (current) and .. (parent)
    • Example: ../../etc (go up two levels, then into etc)

Path symbols:
  /     Root directory (starting point)
  .     Current directory
  ..    Parent directory (one level up)
  ~     Home directory (/home/username)
  -     Previous directory (used with cd)
EOF
}

validate_step_2() {
    if [ ! -d "/tmp/filesystem-lab/opt/myapp" ]; then
        echo ""
        print_color "$RED" "✗ Directory /tmp/filesystem-lab/opt/myapp not created"
        echo "  Create with: mkdir -p /tmp/filesystem-lab/opt/myapp"
        return 1
    fi
    
    if [ ! -f "/tmp/filesystem-lab/step2-proof.txt" ]; then
        echo ""
        print_color "$RED" "✗ Proof file not found"
        echo "  Create /tmp/filesystem-lab/step2-proof.txt with pwd outputs"
        return 1
    fi
    
    # Check if proof file contains expected paths
    if ! grep -q "webadmin" /tmp/filesystem-lab/step2-proof.txt; then
        echo ""
        print_color "$RED" "✗ Proof file missing webadmin path"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  # Create directory using absolute path
  mkdir -p /tmp/filesystem-lab/opt/myapp
  
  # Navigate to webadmin home using absolute path
  cd /tmp/filesystem-lab/home/webadmin
  pwd > /tmp/filesystem-lab/step2-proof.txt
  # Output: /tmp/filesystem-lab/home/webadmin
  
  # Navigate to etc using relative path
  cd ../../etc
  pwd >> /tmp/filesystem-lab/step2-proof.txt
  # Output: /tmp/filesystem-lab/etc
  
  # Return to lab root using absolute path
  cd /tmp/filesystem-lab
  pwd >> /tmp/filesystem-lab/step2-proof.txt
  # Output: /tmp/filesystem-lab

Breaking down relative paths:
  Starting from: /tmp/filesystem-lab/home/webadmin
  
  cd ..           → /tmp/filesystem-lab/home
  cd ../..        → /tmp/filesystem-lab
  cd ../../etc    → /tmp/filesystem-lab/etc
  
  Each .. goes up one level:
  webadmin → home → filesystem-lab → etc

Absolute vs Relative examples:
  
  Current directory: /tmp/filesystem-lab/home/webadmin
  
  Absolute: cd /tmp/filesystem-lab/etc
  Relative: cd ../../etc
  
  Both achieve the same result!

When to use each:
  Absolute paths:
    ✓ In scripts (always works)
    ✓ When jumping to far locations
    ✓ When clarity is critical
  
  Relative paths:
    ✓ Interactive work (faster)
    ✓ When already nearby
    ✓ For quick navigation

Special path shortcuts:
  cd                Go to home directory
  cd ~              Same as above
  cd -              Go to previous directory
  cd ../..          Go up two levels
  cd ./script.sh    Run script in current directory

Verification:
  cat /tmp/filesystem-lab/step2-proof.txt
  # Should show three different pwd outputs

EOF
}

hint_step_3() {
    echo "  Use: find /tmp/filesystem-lab -name \"README.md\" and -name \"*.conf\""
}

# STEP 3: Find files by name
show_step_3() {
    cat << 'EOF'
TASK: Use find command to locate files by name

The find command is one of the most powerful file search tools.
Learn to search by filename and pattern.

Requirements:
  • Find all files named "README.md" anywhere in /tmp/filesystem-lab
  • Find all .conf files
  • Find all .sh files
  • Save results: find output > /tmp/filesystem-lab/found-files.txt

Commands to run:
  find /tmp/filesystem-lab -name "README.md"
  find /tmp/filesystem-lab -name "*.conf"
  find /tmp/filesystem-lab -name "*.sh" -type f

  # Combine into one file:
  find /tmp/filesystem-lab -name "*.conf" -o -name "*.sh" > /tmp/filesystem-lab/found-files.txt

What you're learning:
  find searches recursively by default - it looks in ALL subdirectories.
  
  Basic syntax:
    find [where] [criteria] [action]
  
  Common criteria:
    -name "pattern"    Match by name (case-sensitive)
    -iname "pattern"   Match by name (case-insensitive)
    -type f            Files only
    -type d            Directories only
    -size +10M         Files larger than 10MB
    -size -100k        Files smaller than 100KB

Pattern matching:
  *        Matches anything
  ?.txt    Matches single character
  [abc]*   Matches files starting with a, b, or c

Combining conditions:
  -o       OR (either condition)
  -a       AND (both conditions)
  !        NOT (negation)
EOF
}

validate_step_3() {
    if [ ! -f "/tmp/filesystem-lab/found-files.txt" ]; then
        echo ""
        print_color "$RED" "✗ File found-files.txt not created"
        echo "  Save find results to /tmp/filesystem-lab/found-files.txt"
        return 1
    fi
    
    # Check if it contains expected files
    if ! grep -q "conf" /tmp/filesystem-lab/found-files.txt; then
        echo ""
        print_color "$RED" "✗ found-files.txt doesn't contain .conf files"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  # Find all README.md files
  find /tmp/filesystem-lab -name "README.md"
  # Output:
  #   /tmp/filesystem-lab/README.md
  #   /tmp/filesystem-lab/home/webadmin/README.md
  
  # Find all .conf files
  find /tmp/filesystem-lab -name "*.conf"
  # Output:
  #   /tmp/filesystem-lab/etc/app.conf
  #   /tmp/filesystem-lab/etc/users.conf
  
  # Find all .sh files (scripts)
  find /tmp/filesystem-lab -name "*.sh" -type f
  # Output:
  #   /tmp/filesystem-lab/bin/deploy.sh
  #   /tmp/filesystem-lab/usr/bin/backup-db.sh
  
  # Combine and save
  find /tmp/filesystem-lab \( -name "*.conf" -o -name "*.sh" \) > /tmp/filesystem-lab/found-files.txt

Breaking down the find command:
  
  find /tmp/filesystem-lab
    ↑ Where to search (starting point)
  
  -name "*.conf"
    ↑ What to match (pattern)
  
  -type f
    ↑ Only files (not directories)

Advanced find examples:
  
  # Find by multiple names (OR):
  find /tmp -name "*.log" -o -name "*.txt"
  
  # Find AND execute command on each:
  find /tmp/filesystem-lab -name "*.conf" -exec cat {} \;
  
  # Find and show details:
  find /tmp/filesystem-lab -name "*.sh" -ls
  
  # Find in current directory only (not recursive):
  find . -maxdepth 1 -name "*.txt"
  
  # Find modified in last 7 days:
  find /tmp -type f -mtime -7
  
  # Find and delete (DANGEROUS - test without -delete first!):
  find /tmp -name "*.tmp" -delete

Why quote the pattern?
  
  # WRONG:
  find /tmp -name *.txt
  # Shell expands *.txt BEFORE find sees it!
  
  # RIGHT:
  find /tmp -name "*.txt"
  # find receives the literal pattern

Using find with other commands:
  
  # Count results:
  find /tmp/filesystem-lab -name "*.conf" | wc -l
  
  # Process each result:
  find /tmp/filesystem-lab -name "*.conf" | while read file; do
      echo "Processing: $file"
  done
  
  # Copy all found files:
  find /tmp/filesystem-lab -name "*.conf" -exec cp {} /tmp/backup/ \;

Verification:
  cat /tmp/filesystem-lab/found-files.txt
  wc -l /tmp/filesystem-lab/found-files.txt

EOF
}

hint_step_4() {
    echo "  Use: find /tmp/filesystem-lab -type f -size +10M"
}

# STEP 4: Find by size
show_step_4() {
    cat << 'EOF'
TASK: Find files based on size criteria

Learn to search for files by size, which is critical for finding
large files consuming disk space.

Requirements:
  • Find files larger than 10MB in /tmp/filesystem-lab
  • Find files smaller than 100KB
  • Save large file list: find output > /tmp/filesystem-lab/large-files.txt

Commands to run:
  find /tmp/filesystem-lab -type f -size +10M
  find /tmp/filesystem-lab -type f -size -100k
  find /tmp/filesystem-lab -type f -size +10M > /tmp/filesystem-lab/large-files.txt

Size units in find:
  b    512-byte blocks (default)
  c    bytes
  k    kilobytes (1024 bytes)
  M    megabytes (1024 KB)
  G    gigabytes (1024 MB)

Size prefixes:
  +    greater than
  -    less than
  (no prefix) exactly

What you're learning:
  Finding large files is a common troubleshooting task. When disk
  space is low, you need to quickly identify what's consuming space.
  
  Real-world usage:
    • Find log files that grew too large
    • Locate backup files taking up space
    • Identify temporary files to delete
    • Audit disk usage
EOF
}

validate_step_4() {
    if [ ! -f "/tmp/filesystem-lab/large-files.txt" ]; then
        echo ""
        print_color "$RED" "✗ File large-files.txt not created"
        echo "  Find large files and save to /tmp/filesystem-lab/large-files.txt"
        return 1
    fi
    
    # Check if it found the large file we created
    if ! grep -q "large-file.dat" /tmp/filesystem-lab/large-files.txt; then
        echo ""
        print_color "$RED" "✗ large-files.txt doesn't contain expected large file"
        echo "  Make sure you searched for files > 10M"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  # Find files larger than 10MB
  find /tmp/filesystem-lab -type f -size +10M
  # Output: /tmp/filesystem-lab/var/spool/large-file.dat
  
  # Find files smaller than 100KB
  find /tmp/filesystem-lab -type f -size -100k
  # Output: Most config files, logs, scripts
  
  # Save large file list
  find /tmp/filesystem-lab -type f -size +10M > /tmp/filesystem-lab/large-files.txt

Size syntax breakdown:
  
  -size +10M      Larger than 10 megabytes
        ↑ ↑↑
        | |└─ Unit (M = megabytes)
        | └── Size value
        └──── + means "greater than"
  
  -size -100k     Smaller than 100 kilobytes
  -size 50M       Exactly 50 megabytes
  -size +1G       Larger than 1 gigabyte

Real-world disk space troubleshooting:
  
  # Find largest files in /var/log:
  find /var/log -type f -size +100M -exec ls -lh {} \;
  
  # Find all files over 1GB anywhere:
  find / -type f -size +1G 2>/dev/null
  
  # Find and show sizes sorted:
  find /home -type f -size +10M -exec du -h {} \; | sort -h
  
  # Find large files modified recently:
  find /tmp -type f -size +100M -mtime -7

Combining size with other criteria:
  
  # Large log files:
  find /var/log -name "*.log" -size +50M
  
  # Large files older than 30 days:
  find /var/log -type f -size +100M -mtime +30
  
  # Empty files (0 bytes):
  find /tmp -type f -size 0
  
  # Files between 10MB and 100MB:
  find /tmp -type f -size +10M -size -100M

Using find for disk space auditing:
  
  # Top 10 largest files:
  find /home -type f -exec du -h {} \; | sort -rh | head -10
  
  # Total size of files over 100MB:
  find /var -type f -size +100M -exec du -ch {} + | tail -1
  
  # Count files by size range:
  echo "Files over 100M: $(find / -type f -size +100M 2>/dev/null | wc -l)"
  echo "Files over 1G: $(find / -type f -size +1G 2>/dev/null | wc -l)"

Verification:
  cat /tmp/filesystem-lab/large-files.txt
  # Should show the 15MB file we created

EOF
}

hint_step_5() {
    echo "  Create backup/config-backup/ first, then use cp -v to copy .conf files"
}

# STEP 5: Copy and organize files
show_step_5() {
    cat << 'EOF'
TASK: Copy configuration files to backup location

Practice copying files while maintaining organization and verifying
the operation succeeded.

Requirements:
  • Create directory: /tmp/filesystem-lab/backup/config-backup/
  • Copy ALL .conf files from etc/ to backup/config-backup/
  • Use -v (verbose) flag to see what's copied
  • Verify: ls -l backup/config-backup/

Commands to run:
  mkdir -p /tmp/filesystem-lab/backup/config-backup
  find /tmp/filesystem-lab/etc -name "*.conf" -exec cp -v {} /tmp/filesystem-lab/backup/config-backup/ \;

Or alternative approach:
  mkdir -p /tmp/filesystem-lab/backup/config-backup
  cp -v /tmp/filesystem-lab/etc/*.conf /tmp/filesystem-lab/backup/config-backup/

What you're learning:
  Copying files is a fundamental operation. The key is understanding:
    • When to use -v (verbose) for visibility
    • When to use -r (recursive) for directories
    • How to preserve permissions and timestamps
    • How to avoid overwriting important files

cp flags:
  -v    Verbose (show what's being copied)
  -r    Recursive (copy directories)
  -p    Preserve (keep permissions, timestamps)
  -i    Interactive (prompt before overwrite)
  -u    Update (copy only if source is newer)
  -a    Archive (combines -r -p -d, for full backups)
EOF
}

validate_step_5() {
    if [ ! -d "/tmp/filesystem-lab/backup/config-backup" ]; then
        echo ""
        print_color "$RED" "✗ Backup directory not created"
        echo "  Create: mkdir -p /tmp/filesystem-lab/backup/config-backup"
        return 1
    fi
    
    # Check if .conf files were copied
    local conf_count=$(ls /tmp/filesystem-lab/backup/config-backup/*.conf 2>/dev/null | wc -l)
    if [ "$conf_count" -lt 2 ]; then
        echo ""
        print_color "$RED" "✗ .conf files not copied (found $conf_count, expected at least 2)"
        echo "  Copy files from etc/ to backup/config-backup/"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  # Create backup directory
  mkdir -p /tmp/filesystem-lab/backup/config-backup
  
  # Method 1: Using find and cp
  find /tmp/filesystem-lab/etc -name "*.conf" -exec cp -v {} /tmp/filesystem-lab/backup/config-backup/ \;
  
  # Method 2: Using cp with glob pattern
  cp -v /tmp/filesystem-lab/etc/*.conf /tmp/filesystem-lab/backup/config-backup/
  
  # Verify
  ls -l /tmp/filesystem-lab/backup/config-backup/

Breaking down Method 1 (find + exec):
  
  find /tmp/filesystem-lab/etc
    ↑ Where to search
  
  -name "*.conf"
    ↑ What to find
  
  -exec cp -v {} /tmp/filesystem-lab/backup/config-backup/ \;
    ↑       ↑  ↑↑                                          ↑
    |       |  |└── Placeholder for found file            |
    |       |  └─── Verbose flag                          |
    |       └────── Copy command                          |
    └────────────────────────────────────────────────────┘
                   End of -exec command

The {} placeholder:
  find replaces {} with each found file's path
  
  Example execution:
  cp -v /tmp/filesystem-lab/etc/app.conf /tmp/filesystem-lab/backup/config-backup/
  cp -v /tmp/filesystem-lab/etc/users.conf /tmp/filesystem-lab/backup/config-backup/

Method 2 is simpler but less flexible:
  • Only works for files directly in etc/
  • Won't find files in subdirectories
  • Can't combine with other find criteria

Advanced cp examples:
  
  # Copy and preserve everything (archive mode):
  cp -av /etc/nginx/ /backup/nginx/
  
  # Copy only if source is newer:
  cp -uv source.txt dest.txt
  
  # Interactive (prompt before overwrite):
  cp -iv important.txt backup.txt
  
  # Copy multiple files to directory:
  cp file1.txt file2.txt file3.txt /destination/
  
  # Copy recursively with progress (rsync alternative):
  cp -rv --progress /source/ /dest/

Copying directories:
  
  # WRONG (copies directory itself):
  cp -r /source /dest
  # Result: /dest/source/files
  
  # RIGHT (copies contents):
  cp -r /source/. /dest/
  # Result: /dest/files
  
  # Or use trailing slash:
  cp -r /source/ /dest/

Backup strategies with cp:
  
  # Full backup preserving everything:
  cp -a /important/data/ /backup/data-$(date +%Y%m%d)/
  
  # Incremental backup (only changed files):
  cp -u /source/* /backup/
  
  # Backup with confirmation:
  cp -iv /etc/*.conf /backup/configs/

Common mistakes to avoid:
  
  # WRONG: Overwrites directory:
  cp file.txt /destination/dir
  
  # RIGHT: Specifies destination filename:
  cp file.txt /destination/dir/file.txt
  
  # WRONG: Missing -r for directories:
  cp /source/dir /dest/
  
  # RIGHT: Recursive copy:
  cp -r /source/dir /dest/

Verification:
  ls -l /tmp/filesystem-lab/backup/config-backup/
  # Should show app.conf and users.conf

EOF
}

hint_step_6() {
    echo "  Use mv to rename: mv error.log error.log.old, then mv *.sh to move files"
}

# STEP 6: Move and rename
show_step_6() {
    cat << 'EOF'
TASK: Move and rename files for organization

Learn the difference between renaming and moving files, and how
to safely reorganize filesystem contents.

Requirements:
  • Rename: var/log/error.log → var/log/error.log.old
  • Create new empty: touch var/log/error.log
  • Move all .sh files from bin/ to usr/bin/
  • Verify: ls -l usr/bin/

Commands to run:
  cd /tmp/filesystem-lab
  mv var/log/error.log var/log/error.log.old
  touch var/log/error.log
  mv bin/*.sh usr/bin/
  ls -l usr/bin/

What you're learning:
  The mv command serves two purposes:
    1. Rename: mv oldname newname (same directory)
    2. Move: mv file /new/location/ (different directory)
  
  Unlike cp, mv doesn't create copies - it actually moves the file.
  This makes it atomic and faster for large files.

mv flags:
  -v    Verbose (show what's moved)
  -i    Interactive (prompt before overwrite)
  -n    No-clobber (don't overwrite existing files)
  -u    Update (move only if source is newer)
  -f    Force (don't prompt, even with -i)

Important: mv preserves:
  • Inode (it's not copying data, just updating directory entries)
  • Permissions
  • Ownership
  • Timestamps
EOF
}

validate_step_6() {
    if [ ! -f "/tmp/filesystem-lab/var/log/error.log.old" ]; then
        echo ""
        print_color "$RED" "✗ error.log not renamed to error.log.old"
        echo "  Run: mv var/log/error.log var/log/error.log.old"
        return 1
    fi
    
    if [ ! -f "/tmp/filesystem-lab/var/log/error.log" ]; then
        echo ""
        print_color "$RED" "✗ New error.log not created"
        echo "  Run: touch var/log/error.log"
        return 1
    fi
    
    # Check if .sh files were moved to usr/bin
    local sh_count=$(ls /tmp/filesystem-lab/usr/bin/*.sh 2>/dev/null | wc -l)
    if [ "$sh_count" -lt 2 ]; then
        echo ""
        print_color "$RED" "✗ .sh files not moved to usr/bin/ (found $sh_count)"
        echo "  Move with: mv bin/*.sh usr/bin/"
        return 1
    fi
    
    # Check that bin/ no longer has .sh files
    if ls /tmp/filesystem-lab/bin/*.sh 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ .sh files still in bin/ (should have been moved)"
        return 1
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/filesystem-lab
  
  # Rename error.log to error.log.old
  mv var/log/error.log var/log/error.log.old
  
  # Create new empty error.log
  touch var/log/error.log
  
  # Move all .sh files from bin/ to usr/bin/
  mv bin/*.sh usr/bin/
  
  # Verify
  ls -l usr/bin/
  ls -l bin/  # Should no longer have .sh files

Breaking down the operations:
  
  1. Rename (same directory):
     mv var/log/error.log var/log/error.log.old
        ↑                 ↑
        old name          new name
     
     This is atomic - no temporary copies
  
  2. Move (different directories):
     mv bin/*.sh usr/bin/
        ↑        ↑
        source   destination directory
     
     Glob expands to:
     mv bin/deploy.sh usr/bin/
     mv bin/backup-db.sh usr/bin/ (if it existed there)

mv vs cp:
  
  cp creates a copy → original remains
  mv relocates → original is gone
  
  Example:
    cp file.txt backup.txt    # Now have both files
    mv file.txt backup.txt    # Only backup.txt exists

Renaming patterns:
  
  # Add timestamp suffix:
  mv app.log app.log.$(date +%Y%m%d)
  
  # Add .old extension:
  mv config.txt config.txt.old
  
  # Change extension:
  mv document.txt document.md
  
  # Rename with prefix:
  mv report.pdf 2025-report.pdf

Moving multiple files:
  
  # Move all .txt files to directory:
  mv *.txt /destination/
  
  # Move files matching pattern:
  mv log-202* /archive/
  
  # Move specific files:
  mv file1.txt file2.txt file3.txt /dest/

Safe renaming with mv:
  
  # Interactive mode (prompt before overwrite):
  mv -i important.txt backup.txt
  
  # Verbose mode (see what's happening):
  mv -v *.log /archive/
  
  # No clobber (never overwrite):
  mv -n source.txt dest.txt

Common mv patterns in sysadmin work:
  
  # Rotate logs:
  mv /var/log/app.log /var/log/app.log.1
  mv /var/log/app.log.1 /var/log/app.log.2
  
  # Archive old files:
  mv /data/old-* /archive/
  
  # Reorganize directory structure:
  mv /old/location/* /new/location/
  
  # Rename with datestamp:
  mv backup.tar.gz backup-$(date +%Y%m%d).tar.gz

mv edge cases to be aware of:
  
  # Moving across filesystems (becomes copy+delete):
  mv /home/file /mnt/other-disk/
  # This is slower for large files!
  
  # Moving directory into itself (ERROR):
  mv /source/ /source/backup/
  # Use rsync or cp -r instead
  
  # Overwriting directory with file (ERROR):
  mv file.txt existing-directory/
  # Specify full destination: mv file.txt existing-directory/file.txt

Verification:
  ls -l /tmp/filesystem-lab/var/log/
  # Should show both error.log and error.log.old
  
  ls -l /tmp/filesystem-lab/usr/bin/
  # Should show .sh files moved from bin/
  
  ls -l /tmp/filesystem-lab/bin/
  # Should be empty or have no .sh files

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5  # Step 1 is exploratory
    
    echo "Checking your filesystem work..."
    echo ""
    
    # Check 1: Exploratory - just verify structure exists
    print_color "$CYAN" "[1/$total] Checking filesystem structure..."
    if [ -d "/tmp/filesystem-lab/etc" ] && [ -d "/tmp/filesystem-lab/var/log" ]; then
        print_color "$GREEN" "  ✓ Filesystem structure explored"
        ((score++))
    else
        print_color "$RED" "  ✗ Lab structure missing"
    fi
    echo ""
    
    # Check 2: Paths
    print_color "$CYAN" "[2/$total] Checking path navigation..."
    if [ -d "/tmp/filesystem-lab/opt/myapp" ] && [ -f "/tmp/filesystem-lab/step2-proof.txt" ]; then
        print_color "$GREEN" "  ✓ Path navigation completed"
        ((score++))
    else
        print_color "$RED" "  ✗ Path exercises incomplete"
        print_color "$YELLOW" "  Create /tmp/filesystem-lab/opt/myapp and step2-proof.txt"
    fi
    echo ""
    
    # Check 3: Find by name
    print_color "$CYAN" "[3/$total] Checking find by name..."
    if [ -f "/tmp/filesystem-lab/found-files.txt" ]; then
        if grep -q "conf" /tmp/filesystem-lab/found-files.txt; then
            print_color "$GREEN" "  ✓ Files found by name"
            ((score++))
        else
            print_color "$RED" "  ✗ found-files.txt incomplete"
        fi
    else
        print_color "$RED" "  ✗ found-files.txt not created"
    fi
    echo ""
    
    # Check 4: Find by size
    print_color "$CYAN" "[4/$total] Checking find by size..."
    if [ -f "/tmp/filesystem-lab/large-files.txt" ]; then
        if grep -q "large-file" /tmp/filesystem-lab/large-files.txt; then
            print_color "$GREEN" "  ✓ Large files found correctly"
            ((score++))
        else
            print_color "$RED" "  ✗ large-files.txt doesn't contain expected files"
        fi
    else
        print_color "$RED" "  ✗ large-files.txt not created"
    fi
    echo ""
    
    # Check 5: Copy operations
    print_color "$CYAN" "[5/$total] Checking file copy operations..."
    local conf_count=$(ls /tmp/filesystem-lab/backup/config-backup/*.conf 2>/dev/null | wc -l)
    if [ "$conf_count" -ge 2 ]; then
        print_color "$GREEN" "  ✓ Configuration files backed up"
        ((score++))
    else
        print_color "$RED" "  ✗ .conf files not copied to backup/config-backup/"
    fi
    echo ""
    
    # Check 6: Move operations (bonus - not counted)
    print_color "$CYAN" "[BONUS] Checking file move operations..."
    if [ -f "/tmp/filesystem-lab/var/log/error.log.old" ] && \
       [ $(ls /tmp/filesystem-lab/usr/bin/*.sh 2>/dev/null | wc -l) -ge 2 ]; then
        print_color "$GREEN" "  ✓ Files moved and renamed correctly"
        echo "  (Bonus points - excellent work!)"
    else
        print_color "$YELLOW" "  ⚠ Move operations incomplete (optional)"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • FHS directory structure and conventions"
        echo "  • Absolute vs relative path navigation"
        echo "  • Finding files by name, type, and size"
        echo "  • Copying and organizing files effectively"
        echo ""
        echo "You're ready to navigate any Linux filesystem with confidence!"
    elif [ $score -ge 3 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're getting it! Review the missed sections."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Keep practicing - filesystem skills are fundamental."
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

This lab teaches fundamental filesystem navigation and file management
skills essential for any Linux system administrator.


UNDERSTANDING THE FHS (Filesystem Hierarchy Standard)
─────────────────────────────────────────────────────────────────
The FHS defines a consistent directory structure across Linux distributions:

  /bin        Essential user binaries (ls, cat, cp)
  /sbin       Essential system binaries (mount, ifconfig)
  /etc        Configuration files (text-based, editable)
  /home       User home directories
  /root       Root user's home directory
  /var        Variable data (logs, spools, mail)
  /var/log    System and application log files
  /tmp        Temporary files (often cleared on boot)
  /usr        User programs and read-only data
  /usr/bin    User command binaries
  /usr/sbin   System administration binaries
  /usr/lib    Libraries for /usr/bin and /usr/sbin
  /opt        Optional/add-on software packages

This standardization means:
  • You always know where to find config files
  • Log files are always in /var/log
  • User data is always in /home
  • System works predictably across distributions


NAVIGATION FUNDAMENTALS
─────────────────────────────────────────────────────────────────
Absolute vs Relative Paths:

  Absolute: Always starts from root (/)
    /home/jaxon/Documents/file.txt
    ↑
    Starts with /
    Works from anywhere
  
  Relative: Starts from current location
    Documents/file.txt
    ↑
    No leading /
    Depends on current directory

Special path symbols:
  .     Current directory
  ..    Parent directory (one level up)
  ~     Home directory
  -     Previous directory (used with cd -)
  /     Root directory


THE FIND COMMAND
─────────────────────────────────────────────────────────────────
Most versatile file search tool:

  Basic syntax:
    find [where] [criteria] [action]
  
  By name:
    find /path -name "*.conf"
    find /path -iname "README.md"  # Case-insensitive
  
  By type:
    find /path -type f             # Files only
    find /path -type d             # Directories only
    find /path -type l             # Symbolic links
  
  By size:
    find /path -size +100M         # Larger than 100MB
    find /path -size -1k           # Smaller than 1KB
    find /path -size 50M           # Exactly 50MB
  
  By time:
    find /path -mtime -7           # Modified in last 7 days
    find /path -atime +30          # Accessed over 30 days ago
  
  With actions:
    find /path -name "*.log" -delete
    find /path -name "*.conf" -exec cp {} /backup/ \;
    find /path -type f -exec chmod 644 {} \;


FILE OPERATIONS
─────────────────────────────────────────────────────────────────
Copy (cp):
  Creates duplicate - original remains
  
  cp file.txt backup.txt           # Copy and rename
  cp -r dir/ backup/               # Copy directory recursively
  cp -p file.txt backup.txt        # Preserve permissions/timestamps
  cp -v file.txt dest/             # Verbose output
  cp -u source.txt dest.txt        # Only if source is newer

Move (mv):
  Relocates - original is removed
  
  mv file.txt newname.txt          # Rename
  mv file.txt /new/location/       # Move to directory
  mv *.log /archive/               # Move multiple files
  mv -i file.txt dest.txt          # Interactive (prompt before overwrite)
  mv -n file.txt dest.txt          # Never overwrite

Remove (rm):
  Permanently deletes files
  
  rm file.txt                      # Delete file
  rm -r directory/                 # Delete directory recursively
  rm -f file.txt                   # Force (no prompt)
  rm -i *.txt                      # Interactive (confirm each file)
  rm -rf dir/                      # Force recursive (DANGEROUS!)


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Know the FHS by heart
   Config files? Check /etc
   Logs? Check /var/log
   User data? Check /home

2. Use find for file searches
   Don't waste time manually browsing directories
   Practice find by name, size, and time

3. Always verify operations
   Use ls to check results
   Use -v flag to see what's happening
   Test with non-critical files first

4. Path efficiency
   Learn to use .. and ~ effectively
   Use tab completion
   Use cd - to toggle between directories

5. Common exam patterns:
   • Find and copy config files to backup
   • Locate large files consuming disk space
   • Find files modified recently
   • Reorganize directory structures

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/filesystem-lab 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

# Execute the main framework
main "$@"
