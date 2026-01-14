#!/bin/bash
# labs/06C-archiving-compression.sh
# Lab: Archiving and Compression
# Difficulty: Beginner
# RHCSA Objective: Create and extract archives, use compression

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="Archiving and Compression"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Clean up previous attempts
    rm -rf /tmp/archive-lab 2>/dev/null || true
    
    # Create working directory structure
    mkdir -p /tmp/archive-lab/{website/{css,js,images},configs,logs,backup}
    
    # Create sample website files
    cat > /tmp/archive-lab/website/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Sample Website</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <h1>Welcome to My Website</h1>
    <script src="js/app.js"></script>
</body>
</html>
EOF

    cat > /tmp/archive-lab/website/css/style.css << 'EOF'
body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
    background-color: #f0f0f0;
}

h1 {
    color: #333;
}
EOF

    cat > /tmp/archive-lab/website/js/app.js << 'EOF'
console.log('Website loaded successfully');

function init() {
    console.log('Application initialized');
}

init();
EOF

    # Create sample images (small text files representing images)
    echo "PNG image data" > /tmp/archive-lab/website/images/logo.png
    echo "JPEG image data" > /tmp/archive-lab/website/images/banner.jpg
    
    # Create sample config files
    cat > /tmp/archive-lab/configs/app.conf << 'EOF'
[server]
host=localhost
port=8080
workers=4

[database]
host=db.example.com
port=5432
name=production_db
EOF

    cat > /tmp/archive-lab/configs/nginx.conf << 'EOF'
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

    # Create sample log files
    for i in {1..5}; do
        echo "[2025-01-14 10:0$i:00] INFO: Request processed" >> /tmp/archive-lab/logs/app.log
        echo "[2025-01-14 10:0$i:00] DEBUG: Query executed" >> /tmp/archive-lab/logs/app.log
    done
    
    echo "[2025-01-14 10:00:00] ERROR: Database timeout" > /tmp/archive-lab/logs/error.log
    echo "[2025-01-14 10:01:00] ERROR: Connection failed" >> /tmp/archive-lab/logs/error.log
    
    # Create some files to test extraction
    mkdir -p /tmp/archive-lab/test-data
    echo "File 1 content" > /tmp/archive-lab/test-data/file1.txt
    echo "File 2 content" > /tmp/archive-lab/test-data/file2.txt
    echo "File 3 content" > /tmp/archive-lab/test-data/file3.txt
    
    # Fix ownership
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" /tmp/archive-lab 2>/dev/null || true
    fi
    
    echo "  ✓ Created website files"
    echo "  ✓ Created configuration files"
    echo "  ✓ Created log files"
    echo "  ✓ Ready for archiving practice"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic file operations (cp, mv, ls)
  • Understanding of directories and paths
  • Comfortable with command line

Commands You'll Use:
  • tar      - Tape archive utility (create/extract/list)
  • gzip     - Compress with gzip (.gz)
  • bzip2    - Compress with bzip2 (.bz2)
  • xz       - Compress with xz (.xz)
  • file     - Identify file types
  • ls -lh   - List with human-readable sizes

Core Concepts:
  • Archiving vs compression
  • tar flags: c (create), x (extract), t (list), f (file)
  • Compression flags: z (gzip), j (bzip2), J (xz)
  • Preserving permissions and ownership
  • Streaming archives (tar through pipes)

Why This Matters:
  tar is the standard tool for:
    • Creating backups
    • Packaging software
    • Transferring directory structures
    • Distributing source code
    • Container image layers
  
  Compression reduces:
    • Storage space requirements
    • Transfer time over networks
    • Backup costs
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're a system administrator responsible for backing up website files,
configuration files, and logs. You need to create compressed archives
for efficient storage and transfer.

BACKGROUND:
tar (Tape ARchive) was originally designed to write data to magnetic tape,
but today it's the standard for creating archives on Linux.

Key concepts:
  • tar ARCHIVES (bundles files, preserves metadata)
  • gzip/bzip2/xz COMPRESS (reduces file size)
  • They work together: tar bundles, then compresses

tar doesn't compress by itself!
  tar creates: .tar file (uncompressed archive)
  tar + gzip:  .tar.gz or .tgz
  tar + bzip2: .tar.bz2
  tar + xz:    .tar.xz

Common tar flags:
  -c  Create archive
  -x  Extract archive
  -t  List contents (test/table of contents)
  -f  File (specify archive filename)
  -v  Verbose (show what's happening)
  -z  Compress with gzip
  -j  Compress with bzip2
  -J  Compress with xz
  -C  Change to directory before operation

OBJECTIVES:
Complete these tasks to master archiving and compression:

  1. Create a basic uncompressed archive
     • Archive website directory: tar -cf website.tar website/
     • Verify: ls -lh website.tar
     • List contents: tar -tf website.tar

  2. Create gzip-compressed archives
     • Archive configs with gzip: tar -czf configs.tar.gz configs/
     • Compare sizes: ls -lh configs.tar configs.tar.gz
     • Gzip is fastest, moderate compression

  3. Create bzip2-compressed archive
     • Archive logs with bzip2: tar -cjf logs.tar.bz2 logs/
     • Compare to gzip version
     • Bzip2: slower but better compression

  4. Create xz-compressed archive (best compression)
     • Archive test-data with xz: tar -cJf test-data.tar.xz test-data/
     • Compare all three compression methods
     • XZ: slowest but best compression

  5. Extract archives safely
     • List contents first: tar -tf archive.tar.gz
     • Extract to specific directory: tar -xf archive.tar.gz -C backup/
     • Verify extracted files: ls -R backup/

  6. Compare compression efficiency
     • Create all three versions of website/
     • Compare file sizes
     • Document results: sizes.txt

HINTS:
  • Always use -f flag to specify filename
  • Use -v for verbose output (helpful for learning)
  • List contents (-t) before extracting (-x)
  • Extensions help identify compression: .tar.gz, .tar.bz2, .tar.xz
  • tar auto-detects compression on extraction (no need for -z/-j/-J)

SUCCESS CRITERIA:
  • You can create tar archives
  • You understand different compression methods
  • You can safely extract archives
  • You can compare compression efficiency
  • You understand when to use each compression type
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Create uncompressed archive: website.tar
  ☐ 2. Create gzip archive: configs.tar.gz
  ☐ 3. Create bzip2 archive: logs.tar.bz2
  ☐ 4. Create xz archive: test-data.tar.xz
  ☐ 5. Extract archive to backup/ directory
  ☐ 6. Compare compression sizes, save to sizes.txt
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
You're learning to backup and archive files using tar and various
compression methods. This is essential for system administration,
backups, and software distribution.
EOF
}

# STEP 1: Basic tar archive
show_step_1() {
    cat << 'EOF'
TASK: Create a basic uncompressed tar archive

Learn the fundamental tar command for creating archives without
compression.

Requirements:
  • Navigate to: cd /tmp/archive-lab
  • Create archive: tar -cf website.tar website/
  • Verify created: ls -lh website.tar
  • List contents: tar -tf website.tar

Commands you'll use:
  • tar -cf archive.tar directory/  - Create archive
  • tar -tf archive.tar              - List (table) contents
  • ls -lh                           - Show file sizes

What you're learning:
  tar bundles multiple files/directories into a single file.
  The archive preserves:
    • Directory structure
    • File permissions
    • Ownership (if run as root)
    • Timestamps
    • Symbolic links
  
  But it does NOT compress by default!

tar flags breakdown:
  -c  Create new archive
  -f  File (next argument is the archive filename)
  
  Together: -cf means "create file"

The order matters: filename comes after -f
  tar -cf archive.tar files/   ← Correct
  tar -fc files/ archive.tar   ← Wrong!
EOF
}

validate_step_1() {
    if [ ! -f "/tmp/archive-lab/website.tar" ]; then
        echo ""
        print_color "$RED" "✗ Archive website.tar not created"
        echo "  Create with: tar -cf website.tar website/"
        return 1
    fi
    
    # Check if it's actually a tar file
    if ! file /tmp/archive-lab/website.tar | grep -q "tar archive"; then
        echo ""
        print_color "$RED" "✗ website.tar is not a valid tar archive"
        return 1
    fi
    
    # Check if it contains expected files
    if ! tar -tf /tmp/archive-lab/website.tar | grep -q "index.html"; then
        echo ""
        print_color "$RED" "✗ Archive doesn't contain expected files"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/archive-lab
  
  # Create uncompressed tar archive
  tar -cf website.tar website/
  
  # Verify it was created
  ls -lh website.tar
  # Output: -rw-r--r-- 1 user group 10K Jan 14 10:00 website.tar
  
  # List contents without extracting
  tar -tf website.tar
  # Output:
  # website/
  # website/index.html
  # website/css/
  # website/css/style.css
  # website/js/
  # website/js/app.js
  # website/images/
  # website/images/logo.png
  # website/images/banner.jpg

Breaking down the tar command:
  
  tar -cf website.tar website/
      ││  └─────────┬──────────┘
      ││            └── Source (what to archive)
      │└── Archive filename
      └── Flags

  -c  Create a new archive
  -f  Use file (not tape device)
  
  The filename (website.tar) must come immediately after -f!

What's inside a tar archive?
  
  A tar file contains a series of records:
  [header][file data][header][file data]...[EOF]
  
  Each header contains:
    • Filename
    • File size
    • Permissions
    • Owner/group
    • Timestamps
    • File type
  
  The file data follows immediately after each header.

Why tar doesn't compress by default:
  
  tar was designed for magnetic tape, which is sequential.
  Compression would make it impossible to seek to specific files.
  
  Modern use: tar bundles, separate tools compress
  
  But for convenience, tar now has built-in compression flags!

Viewing contents with -t:
  
  The -t flag lists (table of contents) without extracting:
  
  tar -tf website.tar
  
  This is SAFE - it doesn't modify anything.
  Always list before extracting from untrusted sources!

Verbose output:
  
  Add -v to see what tar is doing:
  
  tar -cvf website.tar website/
  # Output shows each file as it's added:
  # website/
  # website/index.html
  # website/css/
  # website/css/style.css
  # ...

Common tar patterns:
  
  # Archive current directory:
  tar -cf backup.tar .
  
  # Archive multiple items:
  tar -cf backup.tar file1 file2 dir1/ dir2/
  
  # Archive with verbose output:
  tar -cvf backup.tar directory/
  
  # Archive specific files only:
  tar -cf logs.tar *.log

Archive file size:
  
  Uncompressed tar is roughly the sum of all file sizes plus headers.
  
  If website/ is 8KB total:
  website.tar will be ~10KB (8KB data + 2KB headers)
  
  No space saved! That's why compression is important.

Verification:
  ls -lh website.tar
  tar -tf website.tar | head
  # Should list website files

EOF
}

hint_step_2() {
    echo "  Use: tar -czf configs.tar.gz configs/ (note the -z flag)"
}

# STEP 2: Gzip compression
show_step_2() {
    cat << 'EOF'
TASK: Create a gzip-compressed tar archive

Gzip is the most common compression for tar archives. It's fast
and provides good compression.

Requirements:
  • Create compressed: tar -czf configs.tar.gz configs/
  • Create uncompressed for comparison: tar -cf configs.tar configs/
  • Compare sizes: ls -lh configs.tar*
  • Verify compression: file configs.tar.gz

Commands you'll use:
  • tar -czf  - Create + gzip compress
  • file      - Identify file type
  • ls -lh    - Compare file sizes

What you're learning:
  The -z flag tells tar to compress with gzip AFTER archiving.
  
  Process:
  1. tar bundles files → creates .tar in memory
  2. gzip compresses the tar → creates .tar.gz
  
  This is why extensions are .tar.gz (tar, then gzip)

Gzip characteristics:
  ✓ Fast compression/decompression
  ✓ Moderate compression ratio (60-70% reduction)
  ✓ Universal support (every system has gzip)
  ✓ Used by default in most scenarios
  
  .tar.gz = .tgz (same thing, shorter extension)
EOF
}

validate_step_2() {
    if [ ! -f "/tmp/archive-lab/configs.tar.gz" ]; then
        echo ""
        print_color "$RED" "✗ Compressed archive configs.tar.gz not created"
        echo "  Create with: tar -czf configs.tar.gz configs/"
        return 1
    fi
    
    # Check if it's compressed
    if ! file /tmp/archive-lab/configs.tar.gz | grep -q "gzip"; then
        echo ""
        print_color "$RED" "✗ configs.tar.gz is not gzip compressed"
        echo "  Did you use -z flag?"
        return 1
    fi
    
    # Check it contains expected content
    if ! tar -tzf /tmp/archive-lab/configs.tar.gz | grep -q "app.conf"; then
        echo ""
        print_color "$RED" "✗ Archive doesn't contain expected files"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/archive-lab
  
  # Create gzip-compressed archive
  tar -czf configs.tar.gz configs/
  
  # Create uncompressed version for comparison
  tar -cf configs.tar configs/
  
  # Compare file sizes
  ls -lh configs.tar*
  # Output:
  # -rw-r--r-- 1 user group 10K Jan 14 configs.tar
  # -rw-r--r-- 1 user group  3K Jan 14 configs.tar.gz
  #                               ↑
  #                          70% smaller!
  
  # Verify compression type
  file configs.tar.gz
  # Output: configs.tar.gz: gzip compressed data
  
  # List contents (works on compressed archives!)
  tar -tzf configs.tar.gz
  # or just:
  tar -tf configs.tar.gz
  # (tar auto-detects gzip)

Breaking down tar -czf:
  
  tar -czf configs.tar.gz configs/
      │││  └───────┬───────────┘
      │││          └── Source
      ││└── Archive filename  
      │└── Use file (-f)
      └── Compress with gzip (-z) + Create (-c)
  
  The -z flag enables gzip compression.

How gzip compression works:
  
  Gzip uses DEFLATE algorithm (LZ77 + Huffman coding):
  
  1. Find repeated patterns in data
  2. Replace repetitions with references
  3. Encode using variable-length codes
  
  Text compresses well (70-80% reduction)
  Already-compressed files (images, video) don't compress much

Compression comparison:
  
  Example with text files:
  Original configs/: 10KB
  configs.tar:       10KB (no compression)
  configs.tar.gz:     3KB (70% reduction)
  
  Why such good compression?
  • Text files have lots of repeated patterns
  • Whitespace, common words compress well
  • Similar file structures (configs) compress better

tar auto-detection on extraction:
  
  When extracting, tar automatically detects compression:
  
  tar -xf configs.tar.gz    # Works! Auto-detects gzip
  tar -xzf configs.tar.gz   # Also works (explicit)
  
  Both commands do the same thing. The -z is optional for extraction.

Common gzip patterns:
  
  # Create compressed backup:
  tar -czf backup-$(date +%Y%m%d).tar.gz /etc/
  
  # Compress with verbose output:
  tar -czvf website.tar.gz website/
  
  # List compressed archive contents:
  tar -tzf archive.tar.gz
  
  # Extract compressed archive:
  tar -xzf archive.tar.gz

Alternative: gzip separately
  
  You can also tar and gzip separately:
  
  tar -cf configs.tar configs/
  gzip configs.tar
  # Creates: configs.tar.gz
  
  This is equivalent to: tar -czf

File extensions:
  
  .tar.gz  - Standard, explicit
  .tgz     - Shorthand (same thing)
  
  Both are gzipped tar archives.

Gzip compression levels:
  
  gzip has compression levels 1-9:
  
  gzip -1 file.tar  # Fast, less compression
  gzip -9 file.tar  # Slow, best compression
  
  tar doesn't expose this (uses default level 6)

When to use gzip:
  
  ✓ General-purpose backups
  ✓ Quick compression needed
  ✓ Web serving (gzipped assets)
  ✓ Log file compression
  ✓ Universal compatibility required

Verification:
  ls -lh configs.tar configs.tar.gz
  # Should show .tar.gz is much smaller

EOF
}

hint_step_3() {
    echo "  Use: tar -cjf logs.tar.bz2 logs/ (note the -j flag for bzip2)"
}

# STEP 3: Bzip2 compression
show_step_3() {
    cat << 'EOF'
TASK: Create a bzip2-compressed tar archive

Bzip2 provides better compression than gzip but is slower.

Requirements:
  • Create bzip2 archive: tar -cjf logs.tar.bz2 logs/
  • Create gzip version: tar -czf logs.tar.gz logs/
  • Compare sizes: ls -lh logs.tar*
  • Note the size difference

Commands you'll use:
  • tar -cjf  - Create + bzip2 compress (-j flag)

What you're learning:
  Bzip2 uses a different algorithm than gzip (Burrows-Wheeler transform).
  
  Trade-off:
  • Better compression (10-15% smaller than gzip)
  • Slower compression/decompression
  • Less common than gzip
  
  File extension: .tar.bz2 or .tbz2

When to use bzip2:
  ✓ Archiving for long-term storage
  ✓ When space is more important than time
  ✓ Large text-based files
  ✗ When speed is critical
  ✗ When CPU is limited
EOF
}

validate_step_3() {
    if [ ! -f "/tmp/archive-lab/logs.tar.bz2" ]; then
        echo ""
        print_color "$RED" "✗ Bzip2 archive logs.tar.bz2 not created"
        echo "  Create with: tar -cjf logs.tar.bz2 logs/"
        return 1
    fi
    
    # Check if it's bzip2 compressed
    if ! file /tmp/archive-lab/logs.tar.bz2 | grep -q "bzip2"; then
        echo ""
        print_color "$RED" "✗ logs.tar.bz2 is not bzip2 compressed"
        echo "  Did you use -j flag?"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/archive-lab
  
  # Create bzip2-compressed archive
  tar -cjf logs.tar.bz2 logs/
  
  # Create gzip version for comparison
  tar -czf logs.tar.gz logs/
  
  # Compare sizes
  ls -lh logs.tar*
  # Output example:
  # -rw-r--r-- 1 user group 2.0K Jan 14 logs.tar.bz2
  # -rw-r--r-- 1 user group 2.3K Jan 14 logs.tar.gz
  #                               ↑          ↑
  #                          bzip2 smaller!
  
  # Verify compression
  file logs.tar.bz2
  # Output: logs.tar.bz2: bzip2 compressed data

Breaking down tar -cjf:
  
  tar -cjf logs.tar.bz2 logs/
      │││
      ││└── Use file (-f)
      │└── Compress with bzip2 (-j)
      └── Create (-c)
  
  The -j flag enables bzip2 compression.

Compression comparison:
  
  Same data, different algorithms:
  
  logs/ directory:      2.5KB
  logs.tar (no comp):   2.5KB
  logs.tar.gz:          2.3KB (gzip)
  logs.tar.bz2:         2.0KB (bzip2) ← ~10-15% better
  
  Bzip2 achieves better compression but takes longer.

How bzip2 works:
  
  Bzip2 uses Burrows-Wheeler Transform + Huffman coding:
  
  1. Rearrange data to group similar bytes
  2. Apply run-length encoding
  3. Huffman code the result
  
  More CPU intensive than gzip, but better compression ratio.

Speed comparison (relative):
  
  Compression speed:
  gzip:  Fast     ████████
  bzip2: Slower   ████░░░░
  
  Compression ratio:
  gzip:  Good     ███████░
  bzip2: Better   ████████

File extensions:
  
  .tar.bz2  - Standard extension
  .tbz2     - Shorthand
  .tbz      - Also used sometimes
  
  All are bzip2-compressed tar archives.

Extraction (auto-detects bzip2):
  
  tar -xf logs.tar.bz2     # Auto-detects
  tar -xjf logs.tar.bz2    # Explicit bzip2
  
  Both work the same way.

Bzip2 compression levels:
  
  Like gzip, bzip2 has levels 1-9:
  
  bzip2 -1 file.tar  # Fast, less compression
  bzip2 -9 file.tar  # Slow, best compression
  
  tar uses default level

When to choose bzip2 over gzip:
  
  Use bzip2 when:
  ✓ Storage space is expensive
  ✓ Transfer bandwidth is limited
  ✓ Compression is one-time (infrequent decompression)
  ✓ Archiving for long-term storage
  
  Use gzip when:
  ✓ Speed matters
  ✓ Frequent compression/decompression
  ✓ Universal compatibility needed
  ✓ Web serving (faster decompression)

Real-world usage:
  
  # System backup (space-critical):
  tar -cjf /backup/system-$(date +%Y%m%d).tar.bz2 /etc /home
  
  # Database dump (large text, rarely accessed):
  mysqldump database | bzip2 > backup.sql.bz2
  
  # Source code distribution:
  tar -cjf myapp-1.0.tar.bz2 myapp/

Verification:
  file logs.tar.bz2
  ls -lh logs.tar.gz logs.tar.bz2
  # Compare sizes

EOF
}

hint_step_4() {
    echo "  Use: tar -cJf test-data.tar.xz test-data/ (note the -J flag, capital J)"
}

# STEP 4: XZ compression
show_step_4() {
    cat << 'EOF'
TASK: Create an xz-compressed tar archive (best compression)

XZ provides the best compression ratio but is the slowest.

Requirements:
  • Create xz archive: tar -cJf test-data.tar.xz test-data/
  • Compare all three: ls -lh test-data.tar.*
  • Create all three versions to compare:
    - tar -cf test-data.tar test-data/
    - tar -czf test-data.tar.gz test-data/
    - tar -cjf test-data.tar.bz2 test-data/
    - tar -cJf test-data.tar.xz test-data/

What you're learning:
  XZ uses LZMA2 algorithm - the best compression available in tar.
  
  Trade-off:
  • Best compression (20-30% better than gzip)
  • Slowest compression (can be 5-10x slower)
  • High memory usage
  • Becoming more common (Fedora, Arch Linux use it)
  
  File extension: .tar.xz or .txz

Compression comparison:
  Speed:       gzip > bzip2 > xz
  Compression: xz > bzip2 > gzip
  
  NOTE: Capital -J for xz (lowercase -j is bzip2)
EOF
}

validate_step_4() {
    if [ ! -f "/tmp/archive-lab/test-data.tar.xz" ]; then
        echo ""
        print_color "$RED" "✗ XZ archive test-data.tar.xz not created"
        echo "  Create with: tar -cJf test-data.tar.xz test-data/"
        return 1
    fi
    
    # Check if it's xz compressed
    if ! file /tmp/archive-lab/test-data.tar.xz | grep -q "XZ"; then
        echo ""
        print_color "$RED" "✗ test-data.tar.xz is not XZ compressed"
        echo "  Did you use capital -J flag?"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/archive-lab
  
  # Create all versions for comparison
  tar -cf test-data.tar test-data/          # No compression
  tar -czf test-data.tar.gz test-data/      # Gzip
  tar -cjf test-data.tar.bz2 test-data/     # Bzip2
  tar -cJf test-data.tar.xz test-data/      # XZ
  
  # Compare all sizes
  ls -lh test-data.tar*
  # Output example:
  # -rw-r--r-- 1 user group 10K Jan 14 test-data.tar
  # -rw-r--r-- 1 user group  4K Jan 14 test-data.tar.gz
  # -rw-r--r-- 1 user group  3K Jan 14 test-data.tar.bz2
  # -rw-r--r-- 1 user group  2K Jan 14 test-data.tar.xz  ← Smallest!
  
  # Verify compression type
  file test-data.tar.xz
  # Output: test-data.tar.xz: XZ compressed data

Breaking down tar -cJf:
  
  tar -cJf test-data.tar.xz test-data/
      │││
      ││└── Use file (-f)
      │└── Compress with XZ (-J, capital!)
      └── Create (-c)
  
  CRITICAL: Capital -J for xz, lowercase -j for bzip2

Full compression comparison:
  
  Original size:        10KB
  ────────────────────────────
  .tar (none):          10KB   (100%)
  .tar.gz (gzip):        4KB   (40%)  ← Fast
  .tar.bz2 (bzip2):      3KB   (30%)  ← Medium
  .tar.xz (xz):          2KB   (20%)  ← Slow, best compression
  
  XZ achieves 50% better compression than gzip!

How XZ/LZMA2 works:
  
  XZ uses LZMA2 algorithm (Lempel-Ziv-Markov chain):
  
  1. Dictionary-based compression (finds long matches)
  2. Range encoding (arithmetic coding)
  3. Better pattern recognition than gzip/bzip2
  
  This achieves superior compression at the cost of speed and memory.

Speed comparison (relative):
  
  Compression time:
  gzip:  1x      ████████
  bzip2: 3x      ████████████████████████
  xz:    5-10x   ████████████████████████████████████████
  
  Decompression time:
  gzip:  1x      ████
  bzip2: 2x      ████████
  xz:    2-3x    ████████████

Memory usage:
  
  gzip:   Low  (~1MB)
  bzip2:  Medium (~4MB)
  xz:     High (~100MB+ for high compression)
  
  XZ can be memory-intensive!

File extensions:
  
  .tar.xz   - Standard extension
  .txz      - Shorthand
  
  Both are xz-compressed tar archives.

Extraction:
  
  tar -xf test-data.tar.xz     # Auto-detects
  tar -xJf test-data.tar.xz    # Explicit xz
  
  Both work the same.

When to use each compression:

  Gzip (-z):
  ✓ Quick backups
  ✓ Frequent access needed
  ✓ Web assets
  ✓ Universal compatibility
  
  Bzip2 (-j):
  ✓ Better compression, acceptable speed
  ✓ Long-term archives
  ✓ Limited storage
  
  XZ (-J):
  ✓ Maximum compression needed
  ✓ One-time compression, rare extraction
  ✓ Very large files
  ✓ Bandwidth is expensive
  ✗ Quick operations needed

Real-world examples:
  
  # Software distribution (best compression):
  tar -cJf myapp-1.0.tar.xz myapp/
  
  # Kernel source code (Linux uses xz):
  linux-6.7.tar.xz
  
  # Large database backup:
  mysqldump database | xz > backup.sql.xz
  
  # Maximum compression for archival:
  tar -cJf archive-2025.tar.xz /important/data/

XZ compression levels:
  
  xz -0  Fast, less compression (like gzip)
  xz -9  Extreme compression (very slow, huge memory)
  
  tar uses reasonable default (-6)

Trade-off decision matrix:
  
  Need it FAST? → gzip (-z)
  Need it SMALL? → xz (-J)
  Need BALANCE? → bzip2 (-j)

Verification:
  ls -lh test-data.tar*
  # Should show .tar.xz is smallest

EOF
}

hint_step_5() {
    echo "  Use: tar -tf to list, then tar -xf archive.tar.gz -C backup/"
}

# STEP 5: Extract archives
show_step_5() {
    cat << 'EOF'
TASK: Safely extract tar archives

Learn to extract archives to specific directories without
making a mess.

Requirements:
  • Create directory: mkdir -p backup/extracted
  • List archive first: tar -tf configs.tar.gz
  • Extract to directory: tar -xf configs.tar.gz -C backup/extracted/
  • Verify: ls -R backup/extracted/
  • Extract website too: tar -xf website.tar -C backup/extracted/

Commands you'll use:
  • tar -tf  - List contents (always do this first!)
  • tar -xf  - Extract files
  • tar -C   - Change to directory before extracting

What you're learning:
  ALWAYS list contents before extracting!
  
  Why? Tar archives might:
  • Extract to current directory (messy!)
  • Overwrite existing files
  • Not have a top-level directory
  
  Best practice:
  1. tar -tf archive.tar.gz  (check what's inside)
  2. mkdir extraction-dir    (create safe space)
  3. tar -xf archive.tar.gz -C extraction-dir/

The -C flag changes directory BEFORE extracting:
  tar -xf file.tar.gz -C /destination/
  
  This is safer than:
  cd /destination && tar -xf /path/to/file.tar.gz
EOF
}

validate_step_5() {
    if [ ! -d "/tmp/archive-lab/backup/extracted" ]; then
        echo ""
        print_color "$RED" "✗ Directory backup/extracted/ not created"
        return 1
    fi
    
    # Check if configs were extracted
    if [ ! -d "/tmp/archive-lab/backup/extracted/configs" ]; then
        echo ""
        print_color "$RED" "✗ configs/ not extracted to backup/extracted/"
        echo "  Extract with: tar -xf configs.tar.gz -C backup/extracted/"
        return 1
    fi
    
    # Check if expected files exist
    if [ ! -f "/tmp/archive-lab/backup/extracted/configs/app.conf" ]; then
        echo ""
        print_color "$RED" "✗ Expected files not found in extracted directory"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/archive-lab
  
  # Create extraction directory
  mkdir -p backup/extracted
  
  # ALWAYS list contents first!
  tar -tf configs.tar.gz
  # Output:
  # configs/
  # configs/app.conf
  # configs/nginx.conf
  
  # Extract to specific directory
  tar -xf configs.tar.gz -C backup/extracted/
  
  # Verify extraction
  ls -R backup/extracted/
  # Output:
  # backup/extracted/configs/app.conf
  # backup/extracted/configs/nginx.conf
  
  # Extract another archive
  tar -xf website.tar -C backup/extracted/
  
  # Verify both extracted
  ls backup/extracted/
  # Output: configs/ website/

Breaking down tar -xf:
  
  tar -xf configs.tar.gz -C backup/extracted/
      ││                  │
      ││                  └── Change to this dir before extracting
      │└── Use file (-f)
      └── Extract (-x)

Why list before extracting:
  
  Example of "tar bomb" (poor packaging):
  
  Bad archive:
  tar -tf bad.tar
  # Output:
  # file1.txt
  # file2.txt
  # dir1/file3.txt
  
  If you extract this in your current directory:
  tar -xf bad.tar
  # Now files are scattered everywhere!
  
  Better approach:
  mkdir extraction/
  tar -xf bad.tar -C extraction/
  # All files contained in extraction/

Good vs bad tar packaging:
  
  Good (has top-level directory):
  myapp-1.0.tar.gz:
    myapp-1.0/
      bin/
      lib/
      README
  
  Bad (no top-level directory):
  myapp-1.0.tar.gz:
    bin/
    lib/
    README
  
  The good archive creates a single directory.
  The bad archive scatters files everywhere!

Extraction with verbose output:
  
  tar -xvf archive.tar.gz -C destination/
  
  Shows each file as it's extracted:
  configs/
  configs/app.conf
  configs/nginx.conf

Extract specific files only:
  
  # List to find file path:
  tar -tf configs.tar.gz
  
  # Extract specific file:
  tar -xf configs.tar.gz configs/app.conf
  
  # Extract multiple specific files:
  tar -xf configs.tar.gz configs/app.conf configs/nginx.conf
  
  # Extract files matching pattern:
  tar -xf archive.tar.gz --wildcards '*.conf'

Preserve permissions and ownership:
  
  By default, tar preserves:
  • File permissions
  • Timestamps
  
  As root, also preserves:
  • Ownership (UID/GID)
  
  To preserve everything as regular user:
  tar -xpf archive.tar.gz
  # -p preserves permissions (already default)

Overwrite protection:
  
  # Don't overwrite existing files:
  tar -xkf archive.tar.gz
  # -k keeps (skips) existing files
  
  # Only extract newer files:
  tar -xf archive.tar.gz --keep-newer-files

Common extraction patterns:
  
  # Safe extraction:
  mkdir -p extract/
  tar -tf archive.tar.gz  # Check contents
  tar -xf archive.tar.gz -C extract/
  
  # Extract with progress:
  tar -xvf large.tar.gz
  
  # Extract compressed archive:
  tar -xzf file.tar.gz    # Gzip
  tar -xjf file.tar.bz2   # Bzip2
  tar -xJf file.tar.xz    # XZ
  # Or just: tar -xf (auto-detects!)

Streaming extraction:
  
  # Extract from remote system:
  ssh server "tar -czf - /data" | tar -xzf - -C /backup/
  
  # Extract from URL:
  curl https://example.com/file.tar.gz | tar -xzf -
  
  The - means stdin/stdout instead of a file

Extraction troubleshooting:
  
  # Permission denied:
  sudo tar -xf archive.tar.gz
  # May need root to restore ownership
  
  # Out of space:
  tar -tf archive.tar.gz  # Check size first
  df -h                   # Check available space
  
  # Corrupt archive:
  gzip -t archive.tar.gz  # Test integrity
  tar -tf archive.tar.gz  # List (reads entire file)

Verification:
  ls -R backup/extracted/
  # Should show configs/ and website/ directories

EOF
}

hint_step_6() {
    echo "  Create all three versions and compare: ls -lh website.tar*"
}

# STEP 6: Compare compression
show_step_6() {
    cat << 'EOF'
TASK: Compare compression methods and document results

Create archives with all three compression methods and analyze
the trade-offs.

Requirements:
  • Create uncompressed: tar -cf website.tar website/
  • Create gzip: tar -czf website.tar.gz website/
  • Create bzip2: tar -cjf website.tar.bz2 website/
  • Create xz: tar -cJf website.tar.xz website/
  • Compare: ls -lh website.tar* > sizes.txt
  • Document findings in sizes.txt

What you're learning:
  Real-world compression decisions involve trade-offs:
  
  Factors to consider:
  • File size reduction
  • Compression time
  • Decompression time
  • CPU usage
  • Memory usage
  • Compatibility
  
  Decision matrix:
  Speed priority → gzip
  Size priority → xz
  Balance → bzip2

Your task:
  Create all four versions and compare:
  1. Which is smallest?
  2. Which compressed fastest? (observe subjectively)
  3. What's the size difference percentage?
  4. When would you choose each?
EOF
}

validate_step_6() {
    # Check if all compression versions exist
    local missing=0
    
    if [ ! -f "/tmp/archive-lab/website.tar.gz" ]; then
        missing=1
    fi
    
    if [ ! -f "/tmp/archive-lab/website.tar.bz2" ]; then
        missing=1
    fi
    
    if [ ! -f "/tmp/archive-lab/website.tar.xz" ]; then
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        echo ""
        print_color "$RED" "✗ Not all compression versions created"
        echo "  Create: website.tar.gz, website.tar.bz2, website.tar.xz"
        return 1
    fi
    
    if [ ! -f "/tmp/archive-lab/sizes.txt" ]; then
        echo ""
        print_color "$RED" "✗ Comparison file sizes.txt not created"
        echo "  Save comparison: ls -lh website.tar* > sizes.txt"
        return 1
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:

  cd /tmp/archive-lab
  
  # Create all versions
  echo "Creating uncompressed archive..."
  time tar -cf website.tar website/
  
  echo "Creating gzip archive..."
  time tar -czf website.tar.gz website/
  
  echo "Creating bzip2 archive..."
  time tar -cjf website.tar.bz2 website/
  
  echo "Creating xz archive..."
  time tar -cJf website.tar.xz website/
  
  # Compare all sizes
  ls -lh website.tar* > sizes.txt
  cat sizes.txt
  
  # Show percentage reduction
  echo "" >> sizes.txt
  echo "COMPRESSION ANALYSIS:" >> sizes.txt
  original=$(stat -c%s website.tar)
  gz=$(stat -c%s website.tar.gz)
  bz2=$(stat -c%s website.tar.bz2)
  xz=$(stat -c%s website.tar.xz)
  
  echo "Original:  $original bytes" >> sizes.txt
  echo "Gzip:      $gz bytes ($(( 100 - (gz * 100 / original) ))% reduction)" >> sizes.txt
  echo "Bzip2:     $bz2 bytes ($(( 100 - (bz2 * 100 / original) ))% reduction)" >> sizes.txt
  echo "XZ:        $xz bytes ($(( 100 - (xz * 100 / original) ))% reduction)" >> sizes.txt

Example output:

  -rw-r--r-- 1 user group  10K Jan 14 website.tar
  -rw-r--r-- 1 user group  4.0K Jan 14 website.tar.gz
  -rw-r--r-- 1 user group  3.5K Jan 14 website.tar.bz2
  -rw-r--r-- 1 user group  3.0K Jan 14 website.tar.xz
  
  COMPRESSION ANALYSIS:
  Original:  10240 bytes
  Gzip:      4096 bytes (60% reduction)
  Bzip2:     3584 bytes (65% reduction)
  XZ:        3072 bytes (70% reduction)

Timing comparison (using time command):

  real    0m0.050s  # gzip   (fastest)
  real    0m0.150s  # bzip2  (3x slower)
  real    0m0.500s  # xz     (10x slower)

Full decision matrix:

  Gzip (-z):
  ──────────────────────────────────
  Speed:          ★★★★★ Fastest
  Compression:    ★★★☆☆ Good (60%)
  CPU:            ★★★★★ Low
  Memory:         ★★★★★ Low (~1MB)
  Compatibility:  ★★★★★ Universal
  
  Best for:
  • Quick backups
  • Frequent compression/decompression
  • Web assets (faster serving)
  • Low-power systems
  
  Bzip2 (-j):
  ──────────────────────────────────
  Speed:          ★★★☆☆ Medium
  Compression:    ★★★★☆ Better (65%)
  CPU:            ★★★☆☆ Medium
  Memory:         ★★★★☆ Medium (~4MB)
  Compatibility:  ★★★★☆ Common
  
  Best for:
  • Long-term archives
  • Balance of size/speed
  • Moderate storage constraints
  
  XZ (-J):
  ──────────────────────────────────
  Speed:          ★★☆☆☆ Slow
  Compression:    ★★★★★ Best (70%)
  CPU:            ★★☆☆☆ High
  Memory:         ★★☆☆☆ High (~100MB+)
  Compatibility:  ★★★☆☆ Modern systems
  
  Best for:
  • Maximum space savings
  • Software distribution
  • One-time compression
  • Expensive bandwidth

Real-world scenarios:

  Web Server Logs (frequent access):
  → gzip (fast decompression)
  # tar -czf logs-$(date +%Y%m%d).tar.gz /var/log/nginx/
  
  Database Backups (large, infrequent):
  → xz (maximum compression)
  # tar -cJf db-backup-$(date +%Y%m%d).tar.xz /var/lib/mysql/
  
  Home Directory Backup (balanced):
  → bzip2 (good compression, acceptable speed)
  # tar -cjf home-backup.tar.bz2 /home/username/
  
  Software Source Code (distribution):
  → xz (smallest download)
  # tar -cJf myapp-1.0.tar.xz myapp/
  
  Quick Config Backup (speed critical):
  → gzip (fastest)
  # tar -czf etc-backup.tar.gz /etc/

File type matters:

  Already compressed (images, video, executables):
  • Little benefit from any compression
  • Use gzip (fastest, minimal gain anyway)
  
  Text files (logs, configs, source code):
  • Compress very well
  • Consider xz (70-80% reduction possible)
  
  Mixed content:
  • Use bzip2 (balanced)

Storage vs CPU trade-off:

  If storage is expensive and CPU is cheap:
  → Use XZ (save storage at CPU cost)
  
  If CPU is expensive and storage is cheap:
  → Use gzip (save CPU time)
  
  If both matter:
  → Use bzip2 (balanced)

Verification:
  cat sizes.txt
  # Should show all four archive sizes

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your archiving work..."
    echo ""
    
    # Check 1: Basic tar
    print_color "$CYAN" "[1/$total] Checking basic tar archive..."
    if [ -f "/tmp/archive-lab/website.tar" ]; then
        if file /tmp/archive-lab/website.tar | grep -q "tar archive"; then
            print_color "$GREEN" "  ✓ Uncompressed tar archive created"
            ((score++))
        else
            print_color "$RED" "  ✗ website.tar is not a valid tar archive"
        fi
    else
        print_color "$RED" "  ✗ website.tar not created"
    fi
    echo ""
    
    # Check 2: Gzip compression
    print_color "$CYAN" "[2/$total] Checking gzip compression..."
    if [ -f "/tmp/archive-lab/configs.tar.gz" ]; then
        if file /tmp/archive-lab/configs.tar.gz | grep -q "gzip"; then
            print_color "$GREEN" "  ✓ Gzip-compressed archive created"
            ((score++))
        else
            print_color "$RED" "  ✗ configs.tar.gz is not gzip compressed"
        fi
    else
        print_color "$RED" "  ✗ configs.tar.gz not created"
    fi
    echo ""
    
    # Check 3: Bzip2 compression
    print_color "$CYAN" "[3/$total] Checking bzip2 compression..."
    if [ -f "/tmp/archive-lab/logs.tar.bz2" ]; then
        if file /tmp/archive-lab/logs.tar.bz2 | grep -q "bzip2"; then
            print_color "$GREEN" "  ✓ Bzip2-compressed archive created"
            ((score++))
        else
            print_color "$RED" "  ✗ logs.tar.bz2 is not bzip2 compressed"
        fi
    else
        print_color "$RED" "  ✗ logs.tar.bz2 not created"
    fi
    echo ""
    
    # Check 4: XZ compression
    print_color "$CYAN" "[4/$total] Checking xz compression..."
    if [ -f "/tmp/archive-lab/test-data.tar.xz" ]; then
        if file /tmp/archive-lab/test-data.tar.xz | grep -q "XZ"; then
            print_color "$GREEN" "  ✓ XZ-compressed archive created"
            ((score++))
        else
            print_color "$RED" "  ✗ test-data.tar.xz is not xz compressed"
        fi
    else
        print_color "$RED" "  ✗ test-data.tar.xz not created"
    fi
    echo ""
    
    # Check 5: Extraction
    print_color "$CYAN" "[5/$total] Checking archive extraction..."
    if [ -d "/tmp/archive-lab/backup/extracted/configs" ]; then
        if [ -f "/tmp/archive-lab/backup/extracted/configs/app.conf" ]; then
            print_color "$GREEN" "  ✓ Archives extracted correctly"
            ((score++))
        else
            print_color "$RED" "  ✗ Expected files not found in extraction"
        fi
    else
        print_color "$RED" "  ✗ Archives not extracted to backup/extracted/"
    fi
    echo ""
    
    # Check 6: Comparison
    print_color "$CYAN" "[6/$total] Checking compression comparison..."
    if [ -f "/tmp/archive-lab/sizes.txt" ]; then
        if [ -f "/tmp/archive-lab/website.tar.gz" ] && \
           [ -f "/tmp/archive-lab/website.tar.bz2" ] && \
           [ -f "/tmp/archive-lab/website.tar.xz" ]; then
            print_color "$GREEN" "  ✓ All compression methods compared"
            ((score++))
        else
            print_color "$RED" "  ✗ Not all compression versions created"
        fi
    else
        print_color "$RED" "  ✗ Comparison file sizes.txt not found"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You now understand:"
        echo "  • Creating tar archives"
        echo "  • Gzip, bzip2, and xz compression"
        echo "  • Extracting archives safely"
        echo "  • Comparing compression trade-offs"
        echo "  • When to use each compression method"
        echo ""
        echo "You're ready to backup and archive like a pro!"
    elif [ $score -ge 4 ]; then
        print_color "$YELLOW" "STATUS: ⚠ GOOD PROGRESS ($score/$total)"
        echo ""
        echo "You're getting it! Review the missed sections."
    else
        print_color "$YELLOW" "STATUS: ⚠ NEEDS PRACTICE ($score/$total)"
        echo ""
        echo "Keep practicing - archiving is a fundamental skill!"
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

This lab teaches tar archiving and compression - essential skills for
backups, software distribution, and system administration.


TAR FUNDAMENTALS
─────────────────────────────────────────────────────────────────
tar (Tape ARchive) bundles files into a single archive.

Key flags:
  -c  Create archive
  -x  Extract archive
  -t  List contents (table)
  -f  File (specify archive name)
  -v  Verbose (show progress)
  -C  Change directory

Basic syntax:
  tar -cf archive.tar files/    # Create
  tar -xf archive.tar           # Extract
  tar -tf archive.tar           # List


COMPRESSION OPTIONS
─────────────────────────────────────────────────────────────────
tar supports three compression methods:

  Gzip (-z):     .tar.gz or .tgz
  Bzip2 (-j):    .tar.bz2 or .tbz2
  XZ (-J):       .tar.xz or .txz

Comparison:
                Speed       Compression    CPU      Memory
  ───────────────────────────────────────────────────────────
  Gzip (-z)     Fast        Good (60%)     Low      Low
  Bzip2 (-j)    Medium      Better (65%)   Medium   Medium
  XZ (-J)       Slow        Best (70%)     High     High


CREATING ARCHIVES
─────────────────────────────────────────────────────────────────
Uncompressed:
  tar -cf backup.tar /data/

Gzip (most common):
  tar -czf backup.tar.gz /data/

Bzip2 (better compression):
  tar -cjf backup.tar.bz2 /data/

XZ (best compression):
  tar -cJf backup.tar.xz /data/

With verbose output:
  tar -czvf backup.tar.gz /data/


EXTRACTING ARCHIVES
─────────────────────────────────────────────────────────────────
Safe extraction:
  1. List contents first:
     tar -tf archive.tar.gz
  
  2. Create extraction directory:
     mkdir extraction/
  
  3. Extract to directory:
     tar -xf archive.tar.gz -C extraction/

tar auto-detects compression:
  tar -xf file.tar.gz    # Works!
  tar -xf file.tar.bz2   # Works!
  tar -xf file.tar.xz    # Works!


WHEN TO USE EACH COMPRESSION
─────────────────────────────────────────────────────────────────
Use Gzip when:
  ✓ Speed is critical
  ✓ Frequent compression/decompression
  ✓ Universal compatibility needed
  ✓ Web serving (fast decompression)

Use Bzip2 when:
  ✓ Balance of size and speed needed
  ✓ Long-term archives
  ✓ Moderate storage constraints

Use XZ when:
  ✓ Maximum compression needed
  ✓ One-time compression, rare extraction
  ✓ Bandwidth is expensive
  ✓ Software distribution


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Remember the flags:
   -c create, -x extract, -t list, -f file
   -z gzip, -j bzip2, -J xz

2. Always list before extracting:
   tar -tf archive.tar.gz

3. Use -C to extract to specific directory:
   tar -xf file.tar.gz -C /destination/

4. Compression is optional:
   tar auto-detects on extraction

5. Common exam tasks:
   • Backup /etc/ to compressed archive
   • Extract specific files from archive
   • Create archive with specific compression
   • Compare compression efficiency

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    rm -rf /tmp/archive-lab 2>/dev/null || true
    echo "  ✓ All lab files removed"
}

# Execute the main framework
main "$@"
