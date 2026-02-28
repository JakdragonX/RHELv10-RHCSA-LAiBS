#!/bin/bash
# m05/18C-backup-restore.sh
# Lab: Backup and Restore with tar and cpio
# Difficulty: Intermediate
# RHCSA Objective: Create and restore backups using tar and cpio

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Backup and Restore with tar and cpio"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Remove previous backup files and test directories
    rm -rf /backups 2>/dev/null || true
    rm -rf /restore-test 2>/dev/null || true
    rm -rf /tmp/lab-data 2>/dev/null || true
    
    # Create directory structure for backup practice
    mkdir -p /tmp/lab-data/{documents,configs,scripts}
    
    # Create sample files with known content
    cat > /tmp/lab-data/documents/report.txt << 'EOF'
Quarterly Report - Q4 2024
Sales: $2.5M
Growth: 15%
EOF
    
    cat > /tmp/lab-data/documents/notes.txt << 'EOF'
Meeting Notes - Project Alpha
- Deadline: March 15
- Team: 5 members
- Budget: $50K
EOF
    
    cat > /tmp/lab-data/configs/app.conf << 'EOF'
[database]
host=localhost
port=5432
name=production

[cache]
enabled=true
ttl=3600
EOF
    
    cat > /tmp/lab-data/configs/system.conf << 'EOF'
[logging]
level=INFO
destination=/var/log/app.log

[security]
ssl=true
EOF
    
    cat > /tmp/lab-data/scripts/backup.sh << 'EOF'
#!/bin/bash
# Daily backup script
tar czf /backups/daily-$(date +%Y%m%d).tar.gz /data
EOF
    chmod +x /tmp/lab-data/scripts/backup.sh
    
    cat > /tmp/lab-data/scripts/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script
echo "Deploying application..."
systemctl restart myapp
EOF
    chmod +x /tmp/lab-data/scripts/deploy.sh
    
    # Create backup directory
    mkdir -p /backups
    
    echo "  ✓ Created test directory structure at /tmp/lab-data"
    echo "  ✓ Sample files ready for backup"
    echo "  ✓ Backup directory created at /backups"
    echo ""
    echo "Directory structure:"
    tree -L 2 /tmp/lab-data 2>/dev/null || find /tmp/lab-data -type f | head -10
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of backup strategies (full, incremental, differential)
  • Purpose and importance of data backups
  • Difference between tar and cpio
  • Compression methods (gzip, bzip2)
  • Absolute vs relative path backups
  • Archive verification and listing

Commands You'll Use:
  • tar     - Tape archiver (create, extract, list archives)
  • cpio    - Copy files to/from archives
  • gzip    - Compress files with gzip algorithm
  • find    - Find files to feed to cpio
  • ls      - List directory contents

Files You'll Create:
  • /backups/lab-data.tar.gz     - Compressed tar archive
  • /backups/configs.cpio.gz     - Compressed cpio archive
  • /restore-test/*              - Restored files for verification

Reference Material:
  • man tar
  • man cpio
  • man gzip
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your company's application server stores critical data in /tmp/lab-data. The
IT security team requires regular backups of this data to prevent data loss.
You need to implement backup procedures using both tar and cpio, then verify
you can successfully restore the data.

BACKGROUND:
The /tmp/lab-data directory contains:
  • documents/ - Business reports and meeting notes
  • configs/   - Application configuration files
  • scripts/   - Automation and deployment scripts

Requirements from IT security:
  • Full backup of /tmp/lab-data using tar with gzip compression
  • Separate backup of configs/ directory using cpio
  • Both backups must be verifiable without extraction
  • Must demonstrate successful restoration

OBJECTIVES:
  1. Create compressed tar backup of /tmp/lab-data
     • Use relative path (not absolute)
     • Compress with gzip
     • Save to /backups/lab-data.tar.gz
     • Verify archive contents without extracting

  2. Create compressed cpio backup of configs directory
     • Use find to generate file list
     • Compress with gzip
     • Save to /backups/configs.cpio.gz
     • Verify archive contents

  3. Test restoration from tar archive
     • Extract to /restore-test/from-tar/
     • Verify all files restored correctly
     • Confirm file contents match originals

  4. Test restoration from cpio archive
     • Extract to /restore-test/from-cpio/
     • Verify config files restored correctly

HINTS:
  • Change to /tmp before creating tar to use relative paths
  • tar flags: c=create, z=gzip, f=file, v=verbose, t=list
  • find with -print for cpio input
  • Use pipe (|) to connect find → cpio and cpio → gunzip
  • Test archives with 't' flag before extracting
  • Compare files with 'diff' or 'cat'

SUCCESS CRITERIA:
  • /backups/lab-data.tar.gz exists and contains all files
  • /backups/configs.cpio.gz exists and contains config files
  • Both archives can be listed without errors
  • Full restoration to /restore-test/ succeeds
  • Restored files match original content
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create tar backup: /tmp/lab-data → /backups/lab-data.tar.gz
  ☐ 2. Verify tar archive contents (list without extracting)
  ☐ 3. Create cpio backup: configs/ → /backups/configs.cpio.gz
  ☐ 4. Extract tar to /restore-test/from-tar/ and verify
  ☐ 5. Extract cpio to /restore-test/from-cpio/ and verify
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################

get_step_count() {
    echo "5"
}

scenario_context() {
    cat << 'EOF'
You need to backup critical application data from /tmp/lab-data using both
tar and cpio, then verify you can restore the data successfully.
EOF
}

# STEP 1: Create tar backup
show_step_1() {
    cat << 'EOF'
TASK: Create a compressed tar backup of /tmp/lab-data

tar (tape archive) is the most common backup tool in Linux. It bundles multiple
files and directories into a single archive file, optionally compressed.

Requirements:
  • Change to /tmp directory first (for relative paths)
  • Create archive of lab-data/ directory
  • Use gzip compression (-z flag)
  • Save to /backups/lab-data.tar.gz
  • Use relative path (not absolute)

Commands you might need:
  • cd /tmp
  • tar czf /backups/lab-data.tar.gz lab-data/
  
  Flags explained:
    c - Create new archive
    z - Compress with gzip
    f - Specify filename
    v - Verbose (optional, shows files being archived)

Why relative paths:
  Relative paths make archives portable and safer to extract.
  Absolute paths can overwrite system files if extracted carelessly.

Alternative with verbose:
  tar czvf /backups/lab-data.tar.gz lab-data/
EOF
}

validate_step_1() {
    # Check if backup file exists
    if [ ! -f /backups/lab-data.tar.gz ]; then
        echo ""
        print_color "$RED" "✗ Backup file /backups/lab-data.tar.gz not found"
        echo "  Try: cd /tmp && tar czf /backups/lab-data.tar.gz lab-data/"
        return 1
    fi
    
    # Check if it's a valid gzip file
    if ! file /backups/lab-data.tar.gz | grep -q gzip; then
        echo ""
        print_color "$RED" "✗ File is not gzip compressed"
        echo "  Make sure to use 'z' flag: tar czf"
        return 1
    fi
    
    # Check if archive contains expected files
    if ! tar tzf /backups/lab-data.tar.gz 2>/dev/null | grep -q "lab-data/documents/report.txt"; then
        echo ""
        print_color "$RED" "✗ Archive doesn't contain expected files"
        echo "  Check: tar tzf /backups/lab-data.tar.gz"
        return 1
    fi
    
    # Check for relative paths (should not start with /)
    if tar tzf /backups/lab-data.tar.gz 2>/dev/null | grep -q "^/"; then
        echo ""
        print_color "$YELLOW" "⚠ Archive contains absolute paths (not recommended)"
        echo "  Should use relative: cd /tmp && tar czf ..."
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cd /tmp
  tar czf /backups/lab-data.tar.gz lab-data/

Explanation:
  • cd /tmp: Changes to parent directory of lab-data
  • c: Creates new archive
  • z: Compresses with gzip algorithm (~10:1 ratio for text)
  • f: Specifies output filename
  • lab-data/: Directory to archive (relative path)

Why this approach:
  1. Relative paths are safer (won't overwrite system files)
  2. Archives are portable (can extract anywhere)
  3. gzip provides good compression for text files
  4. Single command creates complete backup

Verification:
  ls -lh /backups/lab-data.tar.gz
  # Should show compressed file size
  
  file /backups/lab-data.tar.gz
  # Should show: gzip compressed data

EOF
}

hint_step_1() {
    echo "  cd /tmp first, then: tar czf /backups/lab-data.tar.gz lab-data/"
}

# STEP 2: Verify tar archive
show_step_2() {
    cat << 'EOF'
TASK: List contents of tar archive without extracting

Before relying on a backup, you should verify it contains the expected files.
The 't' flag lists archive contents without extraction.

Requirements:
  • List contents of /backups/lab-data.tar.gz
  • Verify it contains all expected directories and files
  • Do NOT extract the archive yet

Commands you might need:
  • tar tzf /backups/lab-data.tar.gz
  
  Flags:
    t - List (table of contents)
    z - Decompress gzip
    f - Filename
    v - Verbose (shows permissions, ownership)

Expected to see:
  lab-data/
  lab-data/documents/
  lab-data/documents/report.txt
  lab-data/documents/notes.txt
  lab-data/configs/
  lab-data/configs/app.conf
  lab-data/configs/system.conf
  lab-data/scripts/
  lab-data/scripts/backup.sh
  lab-data/scripts/deploy.sh
EOF
}

validate_step_2() {
    # This is more of a "did you verify" step
    # Check that archive is still valid and readable
    if ! tar tzf /backups/lab-data.tar.gz >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Cannot list archive contents"
        echo "  Archive may be corrupted"
        return 1
    fi
    
    # Count files in archive (should have at least 6 files)
    local file_count=$(tar tzf /backups/lab-data.tar.gz 2>/dev/null | grep -v "/$" | wc -l)
    if [ "$file_count" -lt 6 ]; then
        echo ""
        print_color "$YELLOW" "⚠ Archive contains only $file_count files (expected 6+)"
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  tar tzf /backups/lab-data.tar.gz

Or with verbose output:
  tar tzvf /backups/lab-data.tar.gz

Explanation:
  • t: List mode (table of contents)
  • z: Decompress gzip to read
  • v: Verbose (shows permissions, sizes, dates)
  • f: Filename to read

What to verify:
  1. All expected directories present
  2. All files present (6 total)
  3. File paths are relative (don't start with /)
  4. No errors during listing

Why verify before restore:
  - Confirms backup completed successfully
  - Detects corruption early
  - Ensures backup contains what you expect
  - Prevents surprises during actual recovery

Additional verification:
  # Count total files
  tar tzf /backups/lab-data.tar.gz | grep -v "/$" | wc -l
  
  # Check archive integrity
  gzip -t /backups/lab-data.tar.gz

EOF
}

hint_step_2() {
    echo "  List contents: tar tzf /backups/lab-data.tar.gz"
}

# STEP 3: Create cpio backup
show_step_3() {
    cat << 'EOF'
TASK: Create compressed cpio backup of configs directory

cpio (copy in/out) is another archiving tool that works with stdin/stdout.
It's commonly used with find to backup specific file patterns.

Requirements:
  • Use find to locate all files in /tmp/lab-data/configs/
  • Pipe to cpio to create archive
  • Compress with gzip
  • Save to /backups/configs.cpio.gz

Commands you might need:
  cd /tmp/lab-data
  find configs -type f -print | cpio -o | gzip > /backups/configs.cpio.gz
  
  Command breakdown:
    find configs -type f -print  - Find all files in configs/
    |                            - Pipe to next command
    cpio -o                      - Create archive (output mode)
    |                            - Pipe to compression
    gzip                         - Compress
    > /backups/configs.cpio.gz   - Save to file

Why use cpio:
  - Better at preserving permissions and ownership
  - Can skip damaged files in archives
  - Works well with find for selective backups
  - Used by rpm package manager
EOF
}

validate_step_3() {
    # Check if cpio backup exists
    if [ ! -f /backups/configs.cpio.gz ]; then
        echo ""
        print_color "$RED" "✗ Backup file /backups/configs.cpio.gz not found"
        echo "  Try: cd /tmp/lab-data && find configs -type f -print | cpio -o | gzip > /backups/configs.cpio.gz"
        return 1
    fi
    
    # Check if it's gzip compressed
    if ! file /backups/configs.cpio.gz | grep -q gzip; then
        echo ""
        print_color "$RED" "✗ File is not gzip compressed"
        return 1
    fi
    
    # Try to list contents
    if ! gunzip -c /backups/configs.cpio.gz 2>/dev/null | cpio -t >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Cannot list cpio archive contents"
        echo "  Archive may be corrupted"
        return 1
    fi
    
    # Check for expected files
    if ! gunzip -c /backups/configs.cpio.gz 2>/dev/null | cpio -t 2>/dev/null | grep -q "app.conf"; then
        echo ""
        print_color "$RED" "✗ Archive doesn't contain expected config files"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cd /tmp/lab-data
  find configs -type f -print | cpio -o | gzip > /backups/configs.cpio.gz

Explanation:
  • find configs -type f: Finds all regular files in configs/
  • -print: Outputs filenames (one per line)
  • cpio -o: Creates archive in output mode
  • gzip: Compresses the archive
  • >: Redirects to file

cpio modes:
  -o (copy-out): Create archive from file list
  -i (copy-in):  Extract from archive
  -p (pass):     Copy files tree to tree

Why this pattern works:
  1. find generates list of files
  2. cpio reads list from stdin
  3. cpio writes archive to stdout
  4. gzip compresses from stdin
  5. Shell redirects to file

Verification:
  gunzip -c /backups/configs.cpio.gz | cpio -t
  # Lists files in archive
  
  ls -lh /backups/configs.cpio.gz
  # Shows compressed size

EOF
}

hint_step_3() {
    echo "  cd /tmp/lab-data"
    echo "  find configs -type f -print | cpio -o | gzip > /backups/configs.cpio.gz"
}

# STEP 4: Restore from tar
show_step_4() {
    cat << 'EOF'
TASK: Extract tar archive to /restore-test/from-tar/

Test the backup by restoring to a separate location and verifying the files.

Requirements:
  • Create directory /restore-test/from-tar/
  • Extract /backups/lab-data.tar.gz to this directory
  • Verify restored files match originals

Commands you might need:
  • mkdir -p /restore-test/from-tar/
  • cd /restore-test/from-tar/
  • tar xzf /backups/lab-data.tar.gz
  
  Flags:
    x - Extract
    z - Decompress gzip
    f - Filename
    v - Verbose (optional)

Verification:
  • Check if lab-data/ directory exists in /restore-test/from-tar/
  • Verify file contents match originals
  • Compare with: diff or cat commands
EOF
}

validate_step_4() {
    # Check if restore directory exists
    if [ ! -d /restore-test/from-tar ]; then
        echo ""
        print_color "$RED" "✗ Directory /restore-test/from-tar does not exist"
        echo "  Create: mkdir -p /restore-test/from-tar"
        return 1
    fi
    
    # Check if files were extracted
    if [ ! -f /restore-test/from-tar/lab-data/documents/report.txt ]; then
        echo ""
        print_color "$RED" "✗ Files not extracted to /restore-test/from-tar/"
        echo "  Try: cd /restore-test/from-tar && tar xzf /backups/lab-data.tar.gz"
        return 1
    fi
    
    # Verify content matches
    if ! diff -q /tmp/lab-data/documents/report.txt /restore-test/from-tar/lab-data/documents/report.txt >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "⚠ Restored file content differs from original"
    fi
    
    # Check if all expected files present
    local restored_count=$(find /restore-test/from-tar/lab-data -type f 2>/dev/null | wc -l)
    if [ "$restored_count" -lt 6 ]; then
        echo ""
        print_color "$YELLOW" "⚠ Only $restored_count files restored (expected 6+)"
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  mkdir -p /restore-test/from-tar/
  cd /restore-test/from-tar/
  tar xzf /backups/lab-data.tar.gz

Verification:
  ls -R /restore-test/from-tar/lab-data/
  # Shows directory structure
  
  cat /restore-test/from-tar/lab-data/documents/report.txt
  # Display file content
  
  diff /tmp/lab-data/documents/report.txt \
       /restore-test/from-tar/lab-data/documents/report.txt
  # No output = files identical

Explanation:
  • mkdir -p: Creates directory and parents
  • cd: Changes to extraction directory
  • x: Extract mode
  • z: Decompress gzip
  • f: Filename to extract

Why change directory first:
  tar extracts files using paths stored in archive. Since we used
  relative path (lab-data/), extracting from /restore-test/from-tar/
  creates /restore-test/from-tar/lab-data/.

Alternative (extract to specific path):
  tar xzf /backups/lab-data.tar.gz -C /restore-test/from-tar/
  
  -C flag changes to directory before extracting

EOF
}

hint_step_4() {
    echo "  mkdir -p /restore-test/from-tar/"
    echo "  cd /restore-test/from-tar/ && tar xzf /backups/lab-data.tar.gz"
}

# STEP 5: Restore from cpio
show_step_5() {
    cat << 'EOF'
TASK: Extract cpio archive to /restore-test/from-cpio/

Test the cpio backup by restoring and verifying the config files.

Requirements:
  • Create directory /restore-test/from-cpio/
  • Extract /backups/configs.cpio.gz
  • Verify config files restored correctly

Commands you might need:
  • mkdir -p /restore-test/from-cpio/
  • cd /restore-test/from-cpio/
  • gunzip -c /backups/configs.cpio.gz | cpio -id
  
  Flags:
    gunzip -c: Decompress to stdout (don't remove .gz)
    cpio -i:   Extract (input mode)
    cpio -d:   Create directories as needed

Verification:
  • Check if configs/ directory exists
  • Verify app.conf and system.conf present
  • Compare with originals
EOF
}

validate_step_5() {
    # Check if restore directory exists
    if [ ! -d /restore-test/from-cpio ]; then
        echo ""
        print_color "$RED" "✗ Directory /restore-test/from-cpio does not exist"
        echo "  Create: mkdir -p /restore-test/from-cpio"
        return 1
    fi
    
    # Check if files were extracted
    if [ ! -f /restore-test/from-cpio/configs/app.conf ]; then
        echo ""
        print_color "$RED" "✗ Config files not extracted"
        echo "  Try: cd /restore-test/from-cpio && gunzip -c /backups/configs.cpio.gz | cpio -id"
        return 1
    fi
    
    # Verify content matches
    if ! diff -q /tmp/lab-data/configs/app.conf /restore-test/from-cpio/configs/app.conf >/dev/null 2>&1; then
        echo ""
        print_color "$YELLOW" "⚠ Restored config differs from original"
    fi
    
    # Check both config files
    if [ ! -f /restore-test/from-cpio/configs/system.conf ]; then
        echo ""
        print_color "$YELLOW" "⚠ system.conf not found"
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  mkdir -p /restore-test/from-cpio/
  cd /restore-test/from-cpio/
  gunzip -c /backups/configs.cpio.gz | cpio -id

Verification:
  ls -R /restore-test/from-cpio/configs/
  
  diff /tmp/lab-data/configs/app.conf \
       /restore-test/from-cpio/configs/app.conf
  # No output = files identical

Explanation:
  • gunzip -c: Decompresses to stdout (keeps original .gz file)
  • |: Pipes decompressed data to cpio
  • cpio -i: Extract mode (copy-in)
  • cpio -d: Create directories as needed

Why this works:
  1. gunzip decompresses archive
  2. Sends raw cpio data to stdout
  3. cpio reads from stdin
  4. Extracts files to current directory
  5. -d flag ensures directories are created

Alternative (decompress first):
  gunzip /backups/configs.cpio.gz
  cpio -id < /backups/configs.cpio
  gzip /backups/configs.cpio

EOF
}

hint_step_5() {
    echo "  mkdir -p /restore-test/from-cpio/"
    echo "  cd /restore-test/from-cpio/ && gunzip -c /backups/configs.cpio.gz | cpio -id"
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your backup and restore operations..."
    echo ""
    
    # CHECK 1: tar backup exists and valid
    print_color "$CYAN" "[1/$total] Checking tar backup..."
    if [ -f /backups/lab-data.tar.gz ] && \
       file /backups/lab-data.tar.gz | grep -q gzip && \
       tar tzf /backups/lab-data.tar.gz 2>/dev/null | grep -q "report.txt"; then
        local size=$(ls -lh /backups/lab-data.tar.gz | awk '{print $5}')
        print_color "$GREEN" "  ✓ tar backup created ($size)"
        ((score++))
    else
        print_color "$RED" "  ✗ tar backup missing or invalid"
    fi
    echo ""
    
    # CHECK 2: tar archive verified (can list)
    print_color "$CYAN" "[2/$total] Checking tar archive integrity..."
    if tar tzf /backups/lab-data.tar.gz >/dev/null 2>&1; then
        local file_count=$(tar tzf /backups/lab-data.tar.gz 2>/dev/null | grep -v "/$" | wc -l)
        print_color "$GREEN" "  ✓ tar archive valid ($file_count files)"
        ((score++))
    else
        print_color "$RED" "  ✗ Cannot list tar archive"
    fi
    echo ""
    
    # CHECK 3: cpio backup exists and valid
    print_color "$CYAN" "[3/$total] Checking cpio backup..."
    if [ -f /backups/configs.cpio.gz ] && \
       file /backups/configs.cpio.gz | grep -q gzip && \
       gunzip -c /backups/configs.cpio.gz 2>/dev/null | cpio -t 2>/dev/null | grep -q "app.conf"; then
        local size=$(ls -lh /backups/configs.cpio.gz | awk '{print $5}')
        print_color "$GREEN" "  ✓ cpio backup created ($size)"
        ((score++))
    else
        print_color "$RED" "  ✗ cpio backup missing or invalid"
    fi
    echo ""
    
    # CHECK 4: tar restore successful
    print_color "$CYAN" "[4/$total] Checking tar restoration..."
    if [ -f /restore-test/from-tar/lab-data/documents/report.txt ] && \
       [ -f /restore-test/from-tar/lab-data/configs/app.conf ]; then
        # Verify content matches
        if diff -q /tmp/lab-data/documents/report.txt \
                   /restore-test/from-tar/lab-data/documents/report.txt >/dev/null 2>&1; then
            print_color "$GREEN" "  ✓ tar restore successful and verified"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ Files restored but content differs"
            ((score++))
        fi
    else
        print_color "$RED" "  ✗ tar restore incomplete"
    fi
    echo ""
    
    # CHECK 5: cpio restore successful
    print_color "$CYAN" "[5/$total] Checking cpio restoration..."
    if [ -f /restore-test/from-cpio/configs/app.conf ] && \
       [ -f /restore-test/from-cpio/configs/system.conf ]; then
        if diff -q /tmp/lab-data/configs/app.conf \
                   /restore-test/from-cpio/configs/app.conf >/dev/null 2>&1; then
            print_color "$GREEN" "  ✓ cpio restore successful and verified"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ Files restored but content differs"
            ((score++))
        fi
    else
        print_color "$RED" "  ✗ cpio restore incomplete"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! Backup and restore operations completed successfully!"
        echo ""
        echo "Backup summary:"
        echo "  tar backup:  $(ls -lh /backups/lab-data.tar.gz 2>/dev/null | awk '{print $5}')"
        echo "  cpio backup: $(ls -lh /backups/configs.cpio.gz 2>/dev/null | awk '{print $5}')"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
        echo "Run with --solution for detailed steps."
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
COMPLETE SOLUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Create tar backup
─────────────────────────────────────────────────────────────────
  cd /tmp
  tar czf /backups/lab-data.tar.gz lab-data/

STEP 2: Verify tar archive
─────────────────────────────────────────────────────────────────
  tar tzf /backups/lab-data.tar.gz

STEP 3: Create cpio backup
─────────────────────────────────────────────────────────────────
  cd /tmp/lab-data
  find configs -type f -print | cpio -o | gzip > /backups/configs.cpio.gz

STEP 4: Restore from tar
─────────────────────────────────────────────────────────────────
  mkdir -p /restore-test/from-tar/
  cd /restore-test/from-tar/
  tar xzf /backups/lab-data.tar.gz
  
  # Verify
  diff /tmp/lab-data/documents/report.txt \
       /restore-test/from-tar/lab-data/documents/report.txt

STEP 5: Restore from cpio
─────────────────────────────────────────────────────────────────
  mkdir -p /restore-test/from-cpio/
  cd /restore-test/from-cpio/
  gunzip -c /backups/configs.cpio.gz | cpio -id
  
  # Verify
  diff /tmp/lab-data/configs/app.conf \
       /restore-test/from-cpio/configs/app.conf


KEY CONCEPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

tar vs cpio:
  tar:
    ✓ Simple syntax
    ✓ Built-in compression options
    ✓ Most common in Linux
    ✓ Good for full backups
  
  cpio:
    ✓ Better permission preservation
    ✓ Can skip damaged files
    ✓ Works well with find
    ✓ Used by RPM internally

Compression methods:
  gzip (tar -z):
    • Fast compression/decompression
    • ~10:1 ratio for text
    • .tar.gz or .tgz extension
  
  bzip2 (tar -j):
    • Better compression (~15:1)
    • Slower than gzip
    • .tar.bz2 or .tbz extension
  
  xz (tar -J):
    • Best compression (~20:1)
    • Slowest
    • .tar.xz extension

Absolute vs Relative paths:
  Absolute (/home/user/data):
    ✗ Overwrites system files on extract
    ✗ Not portable
    ✗ Dangerous
  
  Relative (data/):
    ✓ Safe to extract
    ✓ Portable
    ✓ Best practice

Backup verification:
  Always verify before relying on backup:
    1. List contents (tar -t, cpio -t)
    2. Check file count
    3. Test extraction to temp location
    4. Compare checksums/content

tar flags reference:
  c - Create archive
  x - Extract archive
  t - List (table of contents)
  z - gzip compression
  j - bzip2 compression
  J - xz compression
  f - Filename
  v - Verbose
  C - Change to directory

cpio modes:
  -o - Output (create archive)
  -i - Input (extract archive)
  -p - Pass-through (copy tree)
  -d - Create directories
  -t - List contents


COMMON MISTAKES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Using absolute paths in backups
   Problem: tar cf backup.tar /etc/myapp
   Fix: cd / && tar cf backup.tar etc/myapp

2. Wrong compression flag
   Problem: tar czf backup.tar.bz2 (uses gzip, not bzip2)
   Fix: tar cjf backup.tar.bz2 or tar czf backup.tar.gz

3. Forgetting to change directory for relative paths
   Problem: tar czf backup.tar.gz /tmp/data
   Fix: cd /tmp && tar czf backup.tar.gz data/

4. Not verifying backups before emergency
   Problem: Discover corruption during restore
   Fix: Always test: tar tzf backup.tar.gz

5. cpio without -d flag
   Problem: Extraction fails if directories don't exist
   Fix: Always use: cpio -id

6. Overwriting production data during test restore
   Problem: Extract to same location as source
   Fix: Always extract to /tmp or /restore-test first


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. tar quick reference:
   • Create: tar czf backup.tar.gz dir/
   • List:   tar tzf backup.tar.gz
   • Extract: tar xzf backup.tar.gz

2. cpio quick reference:
   • Create: find dir | cpio -o | gzip > backup.cpio.gz
   • List:   gunzip -c backup.cpio.gz | cpio -t
   • Extract: gunzip -c backup.cpio.gz | cpio -id

3. Always use relative paths:
   cd to parent directory first, then archive

4. Test your backup:
   List contents before considering task complete

5. Compression shortcuts:
   .tar.gz = -z
   .tar.bz2 = -j
   .tar.xz = -J

6. Time management:
   • tar backup: 30 seconds
   • Verify: 15 seconds
   • cpio backup: 45 seconds
   • Restores: 1 minute each
   • Total: ~3-4 minutes

7. Quick verification during exam:
   tar tzf file.tar.gz | wc -l  # Count files
   tar tzf file.tar.gz | head   # See first files

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    rm -rf /backups 2>/dev/null || true
    rm -rf /restore-test 2>/dev/null || true
    rm -rf /tmp/lab-data 2>/dev/null || true
    
    echo "  ✓ All lab files removed"
    echo "  ✓ System restored to pre-lab state"
}

main "$@"
