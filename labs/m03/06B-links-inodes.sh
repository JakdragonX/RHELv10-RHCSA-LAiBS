#!/bin/bash
# labs/06B-links-inodes.sh
# Lab: Understanding Links and Inodes
# Difficulty: Intermediate
# RHCSA Objective: Create and manage hard links and symbolic links

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Understanding Links and Inodes"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    rm -rf /tmp/links-lab 2>/dev/null || true
    
    # Create working directory structure
    mkdir -p /tmp/links-lab/{original,hardlinks,symlinks,broken,testing}
    
    # Create original files with content
    cat > /tmp/links-lab/original/document.txt << 'EOF'
This is the original document.
It contains important data.
Line 3 of content.
EOF

    echo "Configuration file version 1.0" > /tmp/links-lab/original/config.conf
    echo "Application: WebServer" >> /tmp/links-lab/original/config.conf
    echo "Port: 8080" >> /tmp/links-lab/original/config.conf
    
    cat > /tmp/links-lab/original/script.sh << 'EOF'
#!/bin/bash
echo "This is a test script"
EOF
    chmod +x /tmp/links-lab/original/script.sh
    
    # Create a file to demonstrate inode persistence
    echo "Data that survives deletion" > /tmp/links-lab/original/persistent.txt
    
    # Fix ownership
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" /tmp/links-lab 2>/dev/null || true
    fi
    
    echo "  ✓ Created test files with content"
    echo "  ✓ Prepared for link exploration"
    echo "  ✓ Ready to learn about inodes"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic file operations (cp, mv, rm)
  • Understanding of file paths
  • Comfortable with command line

Commands You'll Use:
  • ln        - Create links (hard and symbolic)
  • ls -li    - List with inode numbers
  • stat      - Display detailed file information
  • df -i     - Show inode usage
  • rm        - Remove files (to test link behavior)
  • cat       - View file contents
  • echo      - Modify file contents

Core Concepts You'll Learn:
  • What an inode actually is
  • How filenames relate to inodes
  • Hard links: multiple names, same data
  • Symbolic links: pointers to paths
  • Why hard links can't cross filesystems
  • How to identify and fix broken symlinks

Why This Matters:
  Understanding inodes and links is fundamental to Linux filesystems.
  This knowledge helps you:
    • Understand what "deleting" a file really means
    • Create efficient backups without duplicating data
    • Safely update configuration files (atomic replacement)
    • Troubleshoot "file in use" issues
    • Understand how Docker layers work (they use hard links!)
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're managing a production web server with multiple configuration files
that need to be available in different locations. You also need to understand
what happens when files are deleted while processes are using them.

BACKGROUND:
In Linux, every file has two parts:
  1. Inode - The file's "identity card" containing metadata
  2. Data blocks - The actual content of the file

The inode contains:
  • File type (regular file, directory, symlink)
  • Permissions (rwxrwxrwx)
  • Ownership (user, group)
  • Timestamps (modified, changed, accessed)
  • Size in bytes
  • Number of hard links pointing to it
  • Pointers to data blocks (where actual content is stored)

What inodes DON'T contain:
  • Filename (names are stored in directories!)
  • File path
  • The actual file content

A filename is just a directory entry mapping "name → inode number"

This separation enables powerful features:
  • Hard links: Multiple names for the same inode
  • Safe atomic file replacement
  • Files can be deleted while still open (process holds inode)

OBJECTIVES:
Complete these tasks to master links and inodes:

  1. Explore inodes and understand file structure
     • View inode numbers: ls -li /tmp/links-lab/original/
     • Examine file metadata: stat original/document.txt
     • Create proof file: ls -li original/ > inode-listing.txt

  2. Create hard links and observe behavior
     • Create hard link: ln original/document.txt hardlinks/doc-link.txt
     • Verify same inode: ls -li original/document.txt hardlinks/doc-link.txt
     • Modify via hard link: echo "New line" >> hardlinks/doc-link.txt
     • Verify original changed: cat original/document.txt
     • Check link count: stat original/document.txt (Links: 2)

  3. Test hard link persistence
     • Create hard link to persistent.txt
     • Delete original file: rm original/persistent.txt
     • Verify hard link still works: cat hardlinks/persistent-link.txt
     • Data survives because link count > 0!

  4. Create symbolic links (symlinks)
     • Create symlink: ln -s /tmp/links-lab/original/config.conf symlinks/config-link.conf
     • Verify different inode: ls -li original/config.conf symlinks/config-link.conf
     • Symlink points to path, not data
     • Test: cat symlinks/config-link.conf (reads through symlink)

  5. Demonstrate broken symlinks
     • Create symlink to script.sh
     • Delete original: rm original/script.sh
     • Symlink breaks: ls -l symlinks/script-link.sh (shows red/broken)
     • Try to read: cat symlinks/script-link.sh (fails!)

  6. Compare absolute vs relative symlinks
     • Absolute: ln -s /tmp/links-lab/original/config.conf symlinks/absolute.conf
     • Relative: ln -s ../original/config.conf symlinks/relative.conf
     • Move symlinks to different directory
     • Absolute still works, relative breaks!

HINTS:
  • Use ls -li to see inode numbers (first column)
  • stat shows detailed file information including link count
  • Hard links have SAME inode number
  • Symlinks have DIFFERENT inode numbers
  • Use file command to identify symlinks
  • Broken symlinks show in red when using ls --color

SUCCESS CRITERIA:
  • You understand what an inode is
  • You can create both hard links and symlinks
  • You know the difference between them
  • You understand when to use each type
  • You can identify and troubleshoot broken symlinks
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore inodes with ls -li and stat, create inode-listing.txt
  ☐ 2. Create hard link, verify same inode, test modifications
  ☐ 3. Delete original, verify hard link data persists
  ☐ 4. Create symlinks, verify different inode
  ☐ 5. Delete symlink target, observe broken link
  ☐ 6. Compare absolute vs relative symlinks behavior
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
You're learning how files REALLY work in Linux. Understanding inodes
and links is fundamental to system administration, backups, and
troubleshooting mysterious file behavior.
EOF
}

# STEP 1: Explore inodes
show_step_1() {
    cat << 'EOF'
TASK: Examine inode numbers and file metadata

Learn what inodes are and how to view them. Every file has exactly
one inode containing its metadata.

Requirements:
  • Navigate to: cd /tmp/links-lab
  • List with inodes: ls -li original/
  • Examine metadata: stat original/document.txt
  • Save listing: ls -li original/ > inode-listing.txt

Commands you'll use:
  • ls -li   - List with inode numbers (-i flag)
  • stat     - Show detailed file metadata
  • df -i    - Show inode usage on filesystem

What you're learning:
  An inode is the file's "identity card" - it contains everything
  about the file EXCEPT its name and content.
  
  The inode number is like a "file ID" - it's unique within a
  filesystem. The filename is just a label pointing to that ID.

Key insight:
  Filename → Directory entry → Inode number → Inode → Data blocks
  
  Example:
    "document.txt" → inode #12345 → metadata + data pointers

When you run ls -li, the first column is the inode number.
Files with the SAME inode number are the SAME file (hard links).
EOF
}

validate_step_1() {
    if [ ! -f "/tmp/links-lab/inode-listing.txt" ]; then
        echo ""
        print_color "$RED" "✗ File inode-listing.txt not created"
        echo "  Run: ls -li /tmp/links-lab/original/ > /tmp/links-lab/inode-listing.txt"
        return 1
    fi
    
    # Check if it contains inode numbers (numeric first column)
    if ! grep -E "^[[:space:]]*[0-9]+" /tmp/links-lab/inode-listing.txt >/dev/null; then
        echo ""
        print_color "$RED" "✗ inode-listing.txt doesn't contain inode numbers"
        echo "  Make sure you used ls -li (with -i flag)"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/links-lab
  
  # List files with inode numbers
  ls -li original/
  
  # Output example:
  # 12345 -rw-r--r-- 1 user group 89 Jan 14 10:00 document.txt
  # ↑
  # This is the inode number
  
  # Detailed file information
  stat original/document.txt
  
  # Save listing to file
  ls -li original/ > inode-listing.txt

Understanding the output:

  ls -li output columns:
  ┌─────────┬──────┬───┬────┬─────┬────┬─────┬──────┬────────────┐
  │ Inode # │ Perm │ Links│ Owner│Group│Size│ Date │ Time │ Filename  │
  └─────────┴──────┴───┴────┴─────┴────┴─────┴──────┴────────────┘
  
  Example:
  12345 -rw-r--r-- 1 jaxon jaxon 89 Jan 14 10:00 document.txt
  
  • 12345: Inode number (unique ID)
  • -rw-r--r--: Permissions
  • 1: Number of hard links
  • jaxon: Owner
  • jaxon: Group
  • 89: Size in bytes
  • Jan 14 10:00: Last modified
  • document.txt: Filename

stat output breakdown:
  
  $ stat original/document.txt
  
  File: original/document.txt
  Size: 89              Blocks: 8          IO Block: 4096
  Device: 803h/2051d    Inode: 12345       Links: 1
  Access: (0644/-rw-r--r--)  Uid: (1000/  jaxon)
  Access: 2025-01-14 10:00:00.000000000 -0500
  Modify: 2025-01-14 10:00:00.000000000 -0500
  Change: 2025-01-14 10:00:00.000000000 -0500
  
  Key fields:
  • Inode: 12345 - The file's unique ID
  • Links: 1 - Number of hard links (names pointing to this inode)
  • Size: 89 bytes
  • Blocks: 8 - Number of disk blocks used
  • Access/Modify/Change: Three different timestamps

Three timestamps explained:
  
  atime (Access): When file was last read
  mtime (Modify): When file content was last changed
  ctime (Change): When inode metadata was last changed
  
  Note: Changing permissions updates ctime, not mtime!

What's stored WHERE:
  
  In the inode:
  ✓ Permissions (rwx)
  ✓ Ownership (UID, GID)
  ✓ Size
  ✓ Timestamps
  ✓ Link count
  ✓ Pointers to data blocks
  
  In the directory:
  ✓ Filename
  ✓ Inode number
  
  In data blocks:
  ✓ Actual file content

Why this matters:
  • The filename is NOT part of the file!
  • Multiple filenames can point to the same inode (hard links)
  • You can delete a filename but data persists if links remain
  • Processes hold inodes open, not filenames

Verification:
  cat inode-listing.txt
  # Should show files with inode numbers in first column

EOF
}

hint_step_2() {
    echo "  Use: ln original/document.txt hardlinks/doc-link.txt (no -s flag!)"
}

# STEP 2: Create hard links
show_step_2() {
    cat << 'EOF'
TASK: Create a hard link and understand its behavior

A hard link is a second name for the same file. Both names point to
the SAME inode, meaning they ARE the same file.

Requirements:
  • Create hard link: ln original/document.txt hardlinks/doc-link.txt
  • Verify same inode: ls -li original/document.txt hardlinks/doc-link.txt
  • Modify via link: echo "Added via hard link" >> hardlinks/doc-link.txt
  • Verify original changed: cat original/document.txt
  • Check link count: stat original/document.txt
  • Save proof: ls -li original/document.txt hardlinks/doc-link.txt > hardlink-proof.txt

Commands you'll use:
  • ln file1 file2     - Create hard link (NO -s flag!)
  • ls -li             - Verify same inode
  • stat               - Check link count

What you're learning:
  Hard links create a second directory entry pointing to the same inode.
  
  Before: "document.txt" → inode #12345 → data
  After:  "document.txt" → inode #12345 → data
          "doc-link.txt" → inode #12345 → data
          
  Both names point to SAME inode = SAME file!
  
  Modifying through either name changes the same data.
  Deleting one name doesn't delete the data (link count > 0).

Hard link characteristics:
  ✓ Same inode number
  ✓ Same permissions
  ✓ Same size
  ✓ Same content
  ✓ Cannot span filesystems
  ✓ Cannot link directories (prevents loops)
EOF
}

validate_step_2() {
    if [ ! -f "/tmp/links-lab/hardlinks/doc-link.txt" ]; then
        echo ""
        print_color "$RED" "✗ Hard link not created"
        echo "  Create with: ln /tmp/links-lab/original/document.txt /tmp/links-lab/hardlinks/doc-link.txt"
        return 1
    fi
    
    # Check if they have the same inode
    local inode1=$(stat -c %i /tmp/links-lab/original/document.txt 2>/dev/null)
    local inode2=$(stat -c %i /tmp/links-lab/hardlinks/doc-link.txt 2>/dev/null)
    
    if [ "$inode1" != "$inode2" ]; then
        echo ""
        print_color "$RED" "✗ Files don't have the same inode (not a hard link)"
        echo "  Did you use ln -s by mistake? Hard links use: ln file1 file2"
        return 1
    fi
    
    if [ ! -f "/tmp/links-lab/hardlink-proof.txt" ]; then
        echo ""
        print_color "$RED" "✗ Proof file not created"
        echo "  Save output: ls -li original/document.txt hardlinks/doc-link.txt > hardlink-proof.txt"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/links-lab
  
  # Create hard link (no -s flag!)
  ln original/document.txt hardlinks/doc-link.txt
  
  # Verify same inode number
  ls -li original/document.txt hardlinks/doc-link.txt
  # Output:
  # 12345 -rw-r--r-- 2 user group 89 Jan 14 document.txt
  # 12345 -rw-r--r-- 2 user group 89 Jan 14 doc-link.txt
  #   ↑                  ↑
  #   Same inode!        Link count increased to 2
  
  # Modify through hard link
  echo "Added via hard link" >> hardlinks/doc-link.txt
  
  # Verify original also changed
  cat original/document.txt
  # Shows the new line!
  
  # Check link count
  stat original/document.txt
  # Links: 2 (increased from 1)
  
  # Save proof
  ls -li original/document.txt hardlinks/doc-link.txt > hardlink-proof.txt

Breaking down what happened:

  Before creating hard link:
  Directory: original/
    Entry: "document.txt" → inode 12345
  
  Inode 12345:
    Links: 1
    Size: 89
    Data: [pointer to blocks]
  
  After creating hard link:
  Directory: original/
    Entry: "document.txt" → inode 12345
  Directory: hardlinks/
    Entry: "doc-link.txt" → inode 12345  ← NEW!
  
  Inode 12345:
    Links: 2  ← Incremented!
    Size: 89
    Data: [same pointer to blocks]

Key insight: It's the SAME file!
  
  There's only ONE inode, ONE set of data blocks.
  You just have TWO names pointing to it.
  
  This means:
  • Editing through either name changes the same data
  • Both names always show same content
  • Permissions apply to the inode (both names see same permissions)
  • Deleting one name doesn't delete the data

Testing modifications:
  
  # Edit through hard link
  echo "New content" >> hardlinks/doc-link.txt
  
  # Check original
  cat original/document.txt
  # Shows "New content" - they're the same file!
  
  # Change permissions on one
  chmod 600 original/document.txt
  
  # Check the other
  ls -l hardlinks/doc-link.txt
  # Shows 600 permissions - same inode = same permissions!

Why link count matters:
  
  The link count tracks how many directory entries point to this inode.
  
  When you "delete" a file, you're really just:
  1. Removing the directory entry
  2. Decrementing the link count
  3. If link count reaches 0, THEN data is freed
  
  This is why:
  • Deleting a file with hard links doesn't lose data
  • Processes can keep files open after deletion
  • "rm" doesn't directly delete - it unlinks

Real-world use cases:
  
  1. Efficient backups:
     ln /data/original.txt /backup/original.txt
     # No disk space used! Same data, different name
  
  2. Software versioning:
     ln python3.9 python3
     ln python3.9 python
     # One binary, multiple names
  
  3. Docker layers:
     Docker uses hard links to share unchanged files between layers

Limitations of hard links:
  
  ✗ Cannot cross filesystem boundaries
    ln /home/file.txt /mnt/other-disk/file.txt  # FAILS
    (Different filesystems have separate inode tables)
  
  ✗ Cannot link directories
    ln /source/dir /dest/dir  # FAILS
    (Would create loops: dir/subdir/../.. = dir!)
  
  ✓ Can only link regular files
  ✓ Must be on same filesystem

Verification:
  cat hardlink-proof.txt
  # Should show same inode number for both files

EOF
}

hint_step_3() {
    echo "  Create link, then rm original - link still works because link count > 0"
}

# STEP 3: Hard link persistence
show_step_3() {
    cat << 'EOF'
TASK: Demonstrate that hard links preserve data

Learn the most important concept: deleting a file doesn't delete
the data if other hard links exist!

Requirements:
  • Create hard link: ln original/persistent.txt hardlinks/persistent-link.txt
  • Verify link count: stat original/persistent.txt (Links: 2)
  • DELETE original: rm original/persistent.txt
  • Verify hard link STILL WORKS: cat hardlinks/persistent-link.txt
  • Data survives!

What you're learning:
  "Deleting" a file really means "unlinking" it. The rm command
  removes a directory entry and decrements the link count.
  
  Data is only freed when the link count reaches 0.
  
  This is fundamental to how Linux filesystems work!

The process:
  1. Create file: Links = 1
  2. Create hard link: Links = 2
  3. Delete "original": Links = 1
  4. Data still exists! (one link remains)
  5. Delete last link: Links = 0 → data freed

Real-world application:
  This is why you can delete a log file while a program is writing
  to it - the program keeps the inode open, so data isn't lost!
EOF
}

validate_step_3() {
    # The original should be deleted
    if [ -f "/tmp/links-lab/original/persistent.txt" ]; then
        echo ""
        print_color "$RED" "✗ Original file still exists (not deleted)"
        echo "  You need to: rm /tmp/links-lab/original/persistent.txt"
        return 1
    fi
    
    # But the hard link should still exist and be readable
    if [ ! -f "/tmp/links-lab/hardlinks/persistent-link.txt" ]; then
        echo ""
        print_color "$RED" "✗ Hard link doesn't exist"
        echo "  Create it first: ln original/persistent.txt hardlinks/persistent-link.txt"
        return 1
    fi
    
    # And it should still have content
    if ! grep -q "survives" /tmp/links-lab/hardlinks/persistent-link.txt 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ Hard link doesn't contain expected data"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/links-lab
  
  # Create hard link
  ln original/persistent.txt hardlinks/persistent-link.txt
  
  # Check link count
  stat original/persistent.txt
  # Links: 2
  
  # DELETE the original
  rm original/persistent.txt
  
  # The hard link STILL WORKS!
  cat hardlinks/persistent-link.txt
  # Output: Data that survives deletion
  
  # Check link count now
  stat hardlinks/persistent-link.txt
  # Links: 1 (decremented from 2)

What happened step-by-step:

  Initial state:
  Directory: original/
    "persistent.txt" → inode 67890
  Inode 67890:
    Links: 1
    Data: "Data that survives deletion"
  
  After creating hard link:
  Directory: original/
    "persistent.txt" → inode 67890
  Directory: hardlinks/
    "persistent-link.txt" → inode 67890
  Inode 67890:
    Links: 2  ← Incremented!
    Data: [unchanged]
  
  After rm original/persistent.txt:
  Directory: original/
    [empty - entry removed]
  Directory: hardlinks/
    "persistent-link.txt" → inode 67890  ← Still here!
  Inode 67890:
    Links: 1  ← Decremented!
    Data: [STILL EXISTS because Links > 0]

The key insight:
  
  rm doesn't "delete files" - it UNLINKS them.
  
  Specifically, rm does:
  1. Remove directory entry
  2. Decrement inode link count
  3. IF link count == 0, mark data blocks as free
  
  Since our inode still has Links: 1, the data remains!

Real-world example - log rotation:
  
  # Apache is writing to /var/log/apache2/access.log
  
  # You "delete" it:
  rm /var/log/apache2/access.log
  
  # BUT Apache still has the file open!
  # The process holds the inode, so:
  # - Link count: 0 (directory entry removed)
  # - Inode: Still in use (process has it open)
  # - Data: Still being written!
  
  # Disk space isn't freed until Apache closes the file
  
  # Proper rotation:
  mv /var/log/apache2/access.log /var/log/apache2/access.log.1
  systemctl reload apache2
  # Now Apache opens a NEW file

Another example - atomic file replacement:
  
  # Safe config file update:
  echo "new config" > /etc/app.conf.new
  mv /etc/app.conf.new /etc/app.conf
  
  # If a process has /etc/app.conf open:
  # - It continues reading the OLD inode
  # - New processes get the NEW inode
  # - No race condition!

Practical demonstration:
  
  # Open a file in one terminal
  tail -f /tmp/links-lab/hardlinks/persistent-link.txt &
  PID=$!
  
  # In same or different terminal
  rm /tmp/links-lab/hardlinks/persistent-link.txt
  
  # The tail process STILL WORKS!
  # It's reading from the inode, not the filename
  
  # Check with lsof:
  lsof -p $PID
  # Shows: persistent-link.txt (deleted)
  
  # Kill the process
  kill $PID
  # NOW the inode is freed (link count reached 0)

Why this matters for system administration:
  
  1. Deleting large files doesn't always free space immediately
     (processes may still have them open)
  
  2. Log rotation must be done carefully
     (move, don't delete, or signal process to reopen)
  
  3. Atomic file replacement is safe
     (readers see old content until they reopen)
  
  4. "Disk full" can happen even after deleting files
     (deleted but still open = space not freed)

Verification:
  # Original should be gone
  ls original/persistent.txt
  # Error: No such file
  
  # But link still works
  cat hardlinks/persistent-link.txt
  # Shows content!

EOF
}

hint_step_4() {
    echo "  Use: ln -s (with -s flag!) and use ABSOLUTE paths"
}

# STEP 4: Create symbolic links
show_step_4() {
    cat << 'EOF'
TASK: Create symbolic links and understand how they differ

Symbolic links (symlinks) are like shortcuts - they point to a PATH,
not directly to an inode.

Requirements:
  • Create symlink: ln -s /tmp/links-lab/original/config.conf symlinks/config-link.conf
  • Verify DIFFERENT inode: ls -li original/config.conf symlinks/config-link.conf
  • Read through symlink: cat symlinks/config-link.conf
  • Check symlink target: readlink symlinks/config-link.conf
  • Save proof: ls -li original/config.conf symlinks/config-link.conf > symlink-proof.txt

Commands you'll use:
  • ln -s target linkname  - Create symbolic link (-s flag required!)
  • ls -li                 - See different inodes
  • readlink               - Show what symlink points to
  • file                   - Identify file type

What you're learning:
  Symlinks are SEPARATE files that contain a path to another file.
  
  Hard link: name → inode → data
  Symlink:   name → inode → "path/to/target" → target's inode → data
             ↑              ↑
       Symlink's inode    Stored path
  
  The symlink has its OWN inode containing the target path.

Symlink characteristics:
  ✓ Different inode from target
  ✓ Can span filesystems
  ✓ Can link to directories
  ✓ Can link to non-existent targets (broken links)
  ✓ Permissions shown as lrwxrwxrwx (l = link)
  ✓ Size = length of path string
EOF
}

validate_step_4() {
    if [ ! -L "/tmp/links-lab/symlinks/config-link.conf" ]; then
        echo ""
        print_color "$RED" "✗ Symbolic link not created"
        echo "  Create with: ln -s /tmp/links-lab/original/config.conf /tmp/links-lab/symlinks/config-link.conf"
        return 1
    fi
    
    # Verify it's actually a symlink, not a hard link
    local inode1=$(stat -c %i /tmp/links-lab/original/config.conf 2>/dev/null)
    local inode2=$(stat -c %i /tmp/links-lab/symlinks/config-link.conf 2>/dev/null)
    
    if [ "$inode1" = "$inode2" ]; then
        echo ""
        print_color "$RED" "✗ Same inode detected - this is a hard link, not a symlink"
        echo "  Use ln -s (with -s flag) to create symbolic links"
        return 1
    fi
    
    if [ ! -f "/tmp/links-lab/symlink-proof.txt" ]; then
        echo ""
        print_color "$RED" "✗ Proof file not created"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/links-lab
  
  # Create symbolic link (note the -s flag!)
  ln -s /tmp/links-lab/original/config.conf symlinks/config-link.conf
  
  # Verify DIFFERENT inodes
  ls -li original/config.conf symlinks/config-link.conf
  # Output:
  # 12345 -rw-r--r-- 1 user group 89 Jan 14 config.conf
  # 67890 lrwxrwxrwx 1 user group 34 Jan 14 config-link.conf -> ...
  #   ↑↑                ↑
  #   Different inodes! l = symbolic link
  
  # Read through symlink
  cat symlinks/config-link.conf
  # Shows content of target file
  
  # Show what symlink points to
  readlink symlinks/config-link.conf
  # Output: /tmp/links-lab/original/config.conf
  
  # Identify file type
  file symlinks/config-link.conf
  # Output: symbolic link to /tmp/links-lab/original/config.conf
  
  # Save proof
  ls -li original/config.conf symlinks/config-link.conf > symlink-proof.txt

Understanding symlink structure:

  The symlink is a SEPARATE file:
  
  Symlink inode 67890:
    Type: symbolic link
    Size: 34 bytes (length of path string)
    Data: "/tmp/links-lab/original/config.conf"
    Permissions: lrwxrwxrwx
  
  Target inode 12345:
    Type: regular file
    Size: 89 bytes
    Data: [actual config content]
    Permissions: -rw-r--r--

Symlink permissions explained:
  
  ls -l output:
  lrwxrwxrwx 1 user group 34 Jan 14 config-link.conf -> target
  ↑
  l = symbolic link
  rwxrwxrwx = symlink permissions (always 777, not used)
  
  The permissions that matter are the TARGET's permissions!
  
  When you access the symlink, the kernel:
  1. Reads the symlink to get the target path
  2. Follows the path to the target file
  3. Checks the TARGET's permissions
  4. Accesses the target's data

Symlink size:
  
  The "size" of a symlink is the length of the path it stores:
  
  ln -s /tmp/file.txt link
  ls -l link
  # Size: 13 (length of "/tmp/file.txt")
  
  The symlink's data blocks contain only the path string!

Reading through symlinks:
  
  # These are equivalent:
  cat symlinks/config-link.conf
  cat /tmp/links-lab/original/config.conf
  
  The kernel automatically follows the symlink.

Symlink vs hard link comparison:

  Hard Link:
  • Same inode
  • Same data
  • Cannot span filesystems
  • Cannot link directories
  • Target can be deleted (data persists)
  • Indistinguishable from original
  
  Symbolic Link:
  • Different inode
  • Contains path to target
  • Can span filesystems
  • Can link directories
  • Breaks if target deleted
  • Clearly marked as link

When to use each:

  Use hard links:
  ✓ Backup/snapshot same filesystem
  ✓ Multiple names for same file
  ✓ Ensure data persists
  ✗ Can't span filesystems
  ✗ Can't link directories
  
  Use symbolic links:
  ✓ Link across filesystems
  ✓ Link to directories
  ✓ Clear indication of link
  ✓ Can link to non-existent targets
  ✗ Breaks if target moves/deleted

Real-world examples:

  # System libraries (symlinks for versioning):
  /usr/lib/libssl.so.1.1 -> libssl.so.1.1.0
  /usr/lib/libssl.so -> libssl.so.1.1
  
  # Python versioning:
  /usr/bin/python3 -> python3.9
  /usr/bin/python -> python3
  
  # Apache modules:
  /etc/apache2/mods-enabled/ssl.conf -> ../mods-available/ssl.conf

Verification:
  cat symlink-proof.txt
  # Should show different inode numbers

EOF
}

hint_step_5() {
    echo "  Create symlink to script.sh, then rm the original - symlink breaks!"
}

# STEP 5: Broken symlinks
show_step_5() {
    cat << 'EOF'
TASK: Demonstrate broken symbolic links

Learn what happens when a symlink's target is deleted.

Requirements:
  • Create symlink: ln -s /tmp/links-lab/original/script.sh symlinks/script-link.sh
  • Verify it works: cat symlinks/script-link.sh
  • DELETE target: rm original/script.sh
  • Try to read: cat symlinks/script-link.sh (fails!)
  • Symlink still exists but points to non-existent file
  • List to see broken link: ls -l symlinks/script-link.sh

What you're learning:
  Symlinks point to PATHS, not inodes. If the target path no longer
  exists, the symlink becomes "broken" or "dangling".
  
  The symlink itself still exists (it's a file containing a path),
  but following it fails because the target is gone.

Identifying broken symlinks:
  • ls --color shows them in red
  • ls -l shows the arrow but target doesn't exist
  • cat fails with "No such file or directory"
  • find /path -xtype l finds broken symlinks
EOF
}

validate_step_5() {
    # The symlink should exist
    if [ ! -L "/tmp/links-lab/symlinks/script-link.sh" ]; then
        echo ""
        print_color "$RED" "✗ Symbolic link to script.sh not created"
        echo "  Create: ln -s /tmp/links-lab/original/script.sh /tmp/links-lab/symlinks/script-link.sh"
        return 1
    fi
    
    # The target should be deleted
    if [ -f "/tmp/links-lab/original/script.sh" ]; then
        echo ""
        print_color "$RED" "✗ Original script.sh still exists (not deleted)"
        echo "  Delete it: rm /tmp/links-lab/original/script.sh"
        return 1
    fi
    
    # The symlink should be broken (target doesn't exist)
    if [ -e "/tmp/links-lab/symlinks/script-link.sh" ]; then
        echo ""
        print_color "$RED" "✗ Symlink target still exists or is accessible"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/links-lab
  
  # Create symlink
  ln -s /tmp/links-lab/original/script.sh symlinks/script-link.sh
  
  # Verify it works
  cat symlinks/script-link.sh
  # Shows: #!/bin/bash ...
  
  # DELETE the target
  rm original/script.sh
  
  # Try to read through symlink
  cat symlinks/script-link.sh
  # Error: No such file or directory
  
  # List the symlink
  ls -l symlinks/script-link.sh
  # Shows: script-link.sh -> /tmp/links-lab/original/script.sh (in red)

What happened:

  Before deletion:
  Symlink: script-link.sh → "/tmp/links-lab/original/script.sh"
           (inode 11111)       ↓
                         (inode 22222, exists)
                               ↓
                         [script data]
  
  After deletion:
  Symlink: script-link.sh → "/tmp/links-lab/original/script.sh"
           (inode 11111)       ↓
                         (path doesn't exist!) ✗
  
  The symlink still exists and contains the path, but the path
  no longer points to anything!

Broken symlink behavior:
  
  # The symlink file itself exists:
  ls -l symlinks/
  # Shows: script-link.sh -> /tmp/links-lab/original/script.sh
  
  # But following it fails:
  cat symlinks/script-link.sh
  # cat: symlinks/script-link.sh: No such file or directory
  
  # The symlink inode exists, but its target doesn't

Identifying broken symlinks:
  
  # Find all broken symlinks:
  find /tmp/links-lab -type l -xtype l
  # or
  find /tmp/links-lab -xtype l
  
  # Explanation:
  # -type l    : is a symbolic link
  # -xtype l   : is a symlink pointing to a symlink (broken)
  
  # With ls:
  ls -l symlinks/script-link.sh
  # Output color: Red (if --color enabled)
  
  # Test if link is broken:
  if [ ! -e symlinks/script-link.sh ]; then
      echo "Broken symlink!"
  fi

Fixing broken symlinks:
  
  Option 1: Delete the broken symlink
  rm symlinks/script-link.sh
  
  Option 2: Recreate the target
  echo "#!/bin/bash" > original/script.sh
  # Now symlink works again!
  
  Option 3: Update the symlink
  ln -sf /new/target symlinks/script-link.sh
  # -f forces overwrite

Common causes of broken symlinks:
  
  1. Target file deleted or moved
  2. Relative symlink moved to different directory
  3. Filesystem unmounted (target on different mount)
  4. Package removed but left symlinks behind

Real-world troubleshooting:
  
  # Find all broken symlinks in /etc:
  find /etc -xtype l
  
  # Find and delete broken symlinks:
  find /path -xtype l -delete
  
  # Find and list what they point to:
  find /path -xtype l -exec ls -l {} \;

Why symlinks break vs hard links don't:
  
  Symlink:
  • Points to PATH (string)
  • If path doesn't exist → broken
  • Symlink doesn't know target was deleted
  
  Hard link:
  • Points to INODE (directly to data)
  • If one name deleted, others still work
  • Data persists until all links gone

Verification:
  ls -l symlinks/script-link.sh
  # Should show broken link (may appear in red)
  
  cat symlinks/script-link.sh
  # Should fail with error

EOF
}

hint_step_6() {
    echo "  Create both, then move them: mv symlinks/*.conf testing/"
}

# STEP 6: Absolute vs relative symlinks
show_step_6() {
    cat << 'EOF'
TASK: Compare absolute and relative symlink paths

Learn the crucial difference between absolute and relative symlinks,
and why it matters when moving links.

Requirements:
  • Create absolute: ln -s /tmp/links-lab/original/config.conf symlinks/absolute.conf
  • Create relative: cd symlinks && ln -s ../original/config.conf relative.conf
  • Verify both work: cat symlinks/absolute.conf symlinks/relative.conf
  • Move links: mv symlinks/*.conf testing/
  • Test again: cat testing/absolute.conf (works!) testing/relative.conf (broken!)

What you're learning:
  Absolute paths always work from anywhere.
  Relative paths break if you move the symlink to a different location.
  
  Best practice: Use absolute paths unless you're certain the relative
  structure won't change.

When to use each:
  Absolute: /full/path/to/target
    ✓ Always works
    ✓ Safe to move symlink
    ✗ Breaks if target moves
    
  Relative: ../path/to/target  
    ✓ Portable with directory structure
    ✓ Works if you move entire tree
    ✗ Breaks if you move just the symlink
EOF
}

validate_step_6() {
    # Both symlinks should have been moved to testing/
    if [ ! -L "/tmp/links-lab/testing/absolute.conf" ]; then
        echo ""
        print_color "$RED" "✗ Absolute symlink not in testing/ directory"
        return 1
    fi
    
    if [ ! -L "/tmp/links-lab/testing/relative.conf" ]; then
        echo ""
        print_color "$RED" "✗ Relative symlink not in testing/ directory"
        return 1
    fi
    
    # Absolute should still work
    if [ ! -e "/tmp/links-lab/testing/absolute.conf" ]; then
        echo ""
        print_color "$RED" "✗ Absolute symlink appears broken"
        return 1
    fi
    
    # Relative should be broken
    if [ -e "/tmp/links-lab/testing/relative.conf" ]; then
        echo ""
        print_color "$YELLOW" "⚠ Relative symlink still works (unexpected)"
        echo "  It should break when moved from symlinks/ to testing/"
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/links-lab
  
  # Create absolute symlink
  ln -s /tmp/links-lab/original/config.conf symlinks/absolute.conf
  
  # Create relative symlink (note the ../ path)
  cd symlinks
  ln -s ../original/config.conf relative.conf
  cd ..
  
  # Or in one command:
  ln -s ../original/config.conf symlinks/relative.conf
  
  # Verify both work initially
  cat symlinks/absolute.conf
  cat symlinks/relative.conf
  # Both show config content
  
  # Move both to testing/
  mv symlinks/*.conf testing/
  
  # Test absolute (still works!)
  cat testing/absolute.conf
  # Shows config content
  
  # Test relative (broken!)
  cat testing/relative.conf
  # Error: No such file or directory

Why this happens:

  Absolute symlink:
  testing/absolute.conf → "/tmp/links-lab/original/config.conf"
                           ↑
                     Full path from root
                     Works from anywhere!
  
  Relative symlink (before move):
  symlinks/relative.conf → "../original/config.conf"
                            ↑
                      From symlinks/ directory
                      ../original = /tmp/links-lab/original ✓
  
  Relative symlink (after move):
  testing/relative.conf → "../original/config.conf"
                           ↑
                     From testing/ directory
                     ../original = /tmp/original ✗ (doesn't exist!)

Path resolution step-by-step:

  Before move:
  symlinks/relative.conf → ../original/config.conf
  
  Resolution from symlinks/:
  symlinks/ + ../ = /tmp/links-lab/
  /tmp/links-lab/ + original/config.conf = /tmp/links-lab/original/config.conf ✓
  
  After move:
  testing/relative.conf → ../original/config.conf
  
  Resolution from testing/:
  testing/ + ../ = /tmp/links-lab/
  /tmp/links-lab/ + original/config.conf = /tmp/links-lab/original/config.conf ✓
  
  Wait, why does this work in our example?
  Because testing/ is at the same level as symlinks/!
  
  Let's try moving to a different level:
  mv testing/relative.conf /tmp/
  cat /tmp/relative.conf
  
  Resolution from /tmp/:
  /tmp/ + ../ = /
  / + original/config.conf = /original/config.conf ✗

Real-world examples:

  Package installation (absolute):
  /usr/bin/python3 -> /usr/bin/python3.9
  # Works from anywhere
  
  Library versioning (relative):
  /usr/lib/libssl.so -> libssl.so.1.1
  # Works as long as files stay in same directory
  
  Web server document root (relative):
  /var/www/html/current -> ./releases/v2.0
  # Breaks if you move 'current' symlink

Best practices:

  Use absolute paths when:
  ✓ Symlink might be moved
  ✓ Target is in a completely different tree
  ✓ Clarity is more important than portability
  
  Use relative paths when:
  ✓ Moving entire directory tree together
  ✓ Creating portable archive
  ✓ Files will always maintain relative positions
  
  Example - tarball with relative links:
  project/
    bin/app -> ../lib/app.so
    lib/app.so
  
  This works anywhere you extract the tarball!

Checking symlink targets:
  
  # Show what symlink points to:
  readlink testing/absolute.conf
  # Output: /tmp/links-lab/original/config.conf (absolute)
  
  readlink testing/relative.conf  
  # Output: ../original/config.conf (relative)
  
  # Resolve to actual file:
  readlink -f testing/absolute.conf
  # Shows full canonical path

Fixing relative symlinks after move:
  
  # Option 1: Recreate with correct relative path
  rm testing/relative.conf
  ln -s ../original/config.conf testing/relative.conf
  
  # Option 2: Convert to absolute
  rm testing/relative.conf
  ln -s /tmp/links-lab/original/config.conf testing/relative.conf

Finding relative vs absolute symlinks:
  
  # Find absolute symlinks (start with /):
  find /tmp/links-lab -type l -exec readlink {} \; | grep ^/
  
  # Find relative symlinks (don't start with /):
  find /tmp/links-lab -type l -exec readlink {} \; | grep -v ^/

Verification:
  readlink testing/absolute.conf
  readlink testing/relative.conf
  # Compare the paths

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your links and inodes work..."
    echo ""
    
    # Check 1: Inode exploration
    print_color "$CYAN" "[1/$total] Checking inode exploration..."
    if [ -f "/tmp/links-lab/inode-listing.txt" ]; then
        if grep -E "^[[:space:]]*[0-9]+" /tmp/links-lab/inode-listing.txt >/dev/null; then
            print_color "$GREEN" "  ✓ Inode numbers explored and documented"
            ((score++))
        else
            print_color "$RED" "  ✗ inode-listing.txt missing inode numbers"
        fi
    else
        print_color "$RED" "  ✗ inode-listing.txt not created"
    fi
    echo ""
    
    # Check 2: Hard links
    print_color "$CYAN" "[2/$total] Checking hard link creation..."
    if [ -f "/tmp/links-lab/hardlinks/doc-link.txt" ]; then
        local inode1=$(stat -c %i /tmp/links-lab/original/document.txt 2>/dev/null || echo "0")
        local inode2=$(stat -c %i /tmp/links-lab/hardlinks/doc-link.txt 2>/dev/null || echo "1")
        if [ "$inode1" = "$inode2" ] && [ "$inode1" != "0" ]; then
            print_color "$GREEN" "  ✓ Hard link created with same inode"
            ((score++))
        else
            print_color "$RED" "  ✗ Files don't share the same inode (not a hard link)"
        fi
    else
        print_color "$RED" "  ✗ Hard link not created"
    fi
    echo ""
    
    # Check 3: Hard link persistence
    print_color "$CYAN" "[3/$total] Checking hard link persistence..."
    if [ ! -f "/tmp/links-lab/original/persistent.txt" ] && \
       [ -f "/tmp/links-lab/hardlinks/persistent-link.txt" ]; then
        if grep -q "survives" /tmp/links-lab/hardlinks/persistent-link.txt 2>/dev/null; then
            print_color "$GREEN" "  ✓ Data persists after deleting original (hard link works!)"
            ((score++))
        else
            print_color "$RED" "  ✗ Hard link doesn't contain expected data"
        fi
    else
        print_color "$RED" "  ✗ Persistence test incomplete"
    fi
    echo ""
    
    # Check 4: Symbolic links
    print_color "$CYAN" "[4/$total] Checking symbolic link creation..."
    if [ -L "/tmp/links-lab/symlinks/config-link.conf" ]; then
        local inode1=$(stat -c %i /tmp/links-lab/original/config.conf 2>/dev/null || echo "0")
        local inode2=$(stat -c %i /tmp/links-lab/symlinks/config-link.conf 2>/dev/null || echo "0")
        if [ "$inode1" != "$inode2" ]; then
            print_color "$GREEN" "  ✓ Symbolic link created (different inode)"
            ((score++))
        else
            print_color "$RED" "  ✗ Same inode detected (hard link, not symlink)"
        fi
    else
        print_color "$RED" "  ✗ Symbolic link not created"
    fi
    echo ""
    
    # Check 5: Broken symlinks
    print_color "$CYAN" "[5/$total] Checking broken symlink demonstration..."
    if [ -L "/tmp/links-lab/symlinks/script-link.sh" ]; then
        if [ ! -f "/tmp/links-lab/original/script.sh" ]; then
            if [ ! -e "/tmp/links-lab/symlinks/script-link.sh" ]; then
                print_color "$GREEN" "  ✓ Broken symlink demonstrated correctly"
                ((score++))
            else
                print_color "$RED" "  ✗ Symlink target still exists"
            fi
        else
            print_color "$RED" "  ✗ Original not deleted (can't test broken link)"
        fi
    else
        print_color "$RED" "  ✗ Symlink not created"
    fi
    echo ""
    
    # Check 6: Absolute vs relative
    print_color "$CYAN" "[6/$total] Checking absolute vs relative symlinks..."
    if [ -L "/tmp/links-lab/testing/absolute.conf" ]; then
        if [ -e "/tmp/links-lab/testing/absolute.conf" ]; then
            print_color "$GREEN" "  ✓ Absolute symlink survives move"
            ((score++))
        else
            print_color "$RED" "  ✗ Absolute symlink broken (unexpected)"
        fi
    else
        print_color "$RED" "  ✗ Absolute symlink not in testing/ directory"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Outstanding! You now deeply understand:"
        echo "  • What inodes are and how they work"
        echo "  • Hard links: multiple names, same data"
        echo "  • Symbolic links: pointers to paths"
        echo "  • Data persistence and link counts"
        echo "  • Broken symlinks and how to fix them"
        echo "  • Absolute vs relative symlink behavior"
        echo ""
        echo "This knowledge is fundamental to advanced Linux administration!"
    elif [ $score -ge 4 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're getting the concepts! Review missed sections."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Links and inodes are complex - keep practicing!"
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

This lab teaches the fundamental concept of how files actually work
in Linux filesystems. Understanding inodes and links is essential.


CONCEPTUAL FOUNDATION: WHAT IS A FILE?
─────────────────────────────────────────────────────────────────
In Linux, a "file" is really two separate components:

  1. Inode (metadata + pointers to data)
  2. Data blocks (actual file content)

The filename is just a directory entry pointing to an inode number.

  Filename → Directory entry → Inode # → Inode → Data blocks
  
  "document.txt" → inode #12345 → [metadata] → [disk blocks]


WHAT'S IN AN INODE?
─────────────────────────────────────────────────────────────────
The inode contains:
  • File type (regular, directory, symlink, etc.)
  • Permissions (rwxrwxrwx)
  • Owner (UID) and group (GID)
  • Size in bytes
  • Timestamps (atime, mtime, ctime)
  • Number of hard links
  • Pointers to data blocks on disk

The inode does NOT contain:
  • Filename
  • Directory path
  • File content (content is in data blocks)


HARD LINKS: MULTIPLE NAMES, SAME FILE
─────────────────────────────────────────────────────────────────
A hard link creates a second directory entry pointing to the same inode.

  Before: "document.txt" → inode #12345
  After:  "document.txt" → inode #12345
          "doc-link.txt" → inode #12345
  
  Both names point to THE SAME inode = THE SAME file!

Characteristics:
  • Same inode number
  • Same permissions, ownership, size
  • Modifications through either name affect both
  • Deleting one name doesn't delete data
  • Cannot span filesystems
  • Cannot link directories

When you "delete" a file: rm decrements the link count
  • Link count > 0: Data persists
  • Link count = 0: Data blocks marked free


SYMBOLIC LINKS: SHORTCUTS TO PATHS
─────────────────────────────────────────────────────────────────
A symlink is a separate file containing a path to another file.

  "link.txt" → inode #67890 → data: "/path/to/target.txt"
                                      ↓
                               inode #12345 → [actual data]

Characteristics:
  • Different inode from target
  • Contains path string as data
  • Can span filesystems
  • Can link to directories
  • Breaks if target deleted
  • Permissions: lrwxrwxrwx (always 777, not enforced)

Real permissions come from the TARGET, not the symlink.


HARD LINK VS SYMBOLIC LINK COMPARISON
─────────────────────────────────────────────────────────────────

                Hard Link           Symbolic Link
  ────────────────────────────────────────────────────────
  Inode         Same                Different
  Data          Shared              Points to path
  Filesystem    Same only           Can span
  Directories   No                  Yes
  Deletion      Data persists       Link breaks
  Visibility    Indistinguishable   Clearly marked (l)


WHEN TO USE EACH
─────────────────────────────────────────────────────────────────
Hard links:
  ✓ Efficient backups (no disk space duplication)
  ✓ Multiple names for same file
  ✓ Data must persist after deletion
  ✗ Can't span filesystems
  ✗ Can't link directories

Symbolic links:
  ✓ Link across filesystems
  ✓ Link to directories
  ✓ Clear indication it's a link
  ✓ Can point to non-existent targets
  ✗ Breaks if target moves/deleted


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Know how to create links:
   ln file1 file2           # Hard link
   ln -s target linkname    # Symbolic link

2. Know how to identify link types:
   ls -li                   # Show inode numbers
   ls -l                    # Symlinks show →
   file linkname            # Describes link type

3. Understanding persistence:
   Hard link: Data survives deletion
   Symlink: Breaks if target deleted

4. Absolute vs relative symlinks:
   Absolute: Always works
   Relative: Breaks if link moved

5. Common exam tasks:
   • Create hard link to config file
   • Create symlink to directory
   • Identify broken symlinks
   • Fix broken symlinks

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/links-lab 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

# Execute the main framework
main "$@"
