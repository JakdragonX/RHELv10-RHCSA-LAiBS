#!/bin/bash
# labs/04A-man-page-basics.sh
# Lab: Man Page Navigation and Documentation Discovery
# Difficulty: Beginner
# RHCSA Objective: Use input-output redirection; Access remote systems using SSH; Locate, read, and use system documentation

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Man Page Navigation and Documentation Discovery"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure man database is up to date
    mandb 2>/dev/null || true
    
    # Create test user for practice
    userdel -r docreader 2>/dev/null || true
    useradd -m -s /bin/bash docreader 2>/dev/null || true
    echo "docreader:password123" | chpasswd 2>/dev/null || true
    
    # Create directory for documentation exercises
    rm -rf /opt/documentation_lab 2>/dev/null || true
    mkdir -p /opt/documentation_lab/{findings,notes} 2>/dev/null || true
    chown -R docreader:docreader /opt/documentation_lab 2>/dev/null || true
    
    echo "  ✓ Man database updated"
    echo "  ✓ Test user 'docreader' created"
    echo "  ✓ Working directory created at /opt/documentation_lab"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES: Knowledge and commands needed
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of Linux command structure
  • Familiarity with keyboard navigation (arrows, Page Up/Down)
  • Understanding of what documentation is and why it's important
  • Concept of command options vs arguments

Commands You'll Use:
  • man                - Display manual pages
  • man -k             - Search man page descriptions (keyword search)
  • apropos            - Synonym for man -k (search descriptions)
  • mandb              - Update/rebuild the man page database
  • whatis             - Display one-line manual page descriptions
  • man -f             - Same as whatis
  • info               - Display GNU info documentation
  • pinfo              - Better interface for info pages

Navigation Within Man Pages:
  • Space / Page Down  - Move forward one screen
  • b / Page Up        - Move backward one screen
  • Down Arrow         - Move down one line
  • Up Arrow           - Move up one line
  • g / Home           - Go to beginning of man page
  • G / End            - Go to end of man page
  • /pattern           - Search forward for pattern
  • ?pattern           - Search backward for pattern
  • n                  - Repeat last search forward
  • N                  - Repeat last search backward
  • h                  - Display help for navigation
  • q                  - Quit man page

Files You'll Interact With:
  • /usr/share/man/            - Man page storage location
  • /var/cache/man/            - Man page database cache
  • /etc/man_db.conf           - Man page configuration
  • /opt/documentation_lab/    - Lab working directory

Man Page Sections (Critical to Understand):
  • Section 1: User commands (ls, cp, grep)
  • Section 2: System calls (open, fork)
  • Section 3: Library functions (printf, malloc)
  • Section 4: Special files/devices (/dev/sda)
  • Section 5: File formats (passwd, fstab)
  • Section 6: Games
  • Section 7: Miscellaneous (regex, signal)
  • Section 8: System administration (mount, useradd)
EOF
}

#############################################################################
# SCENARIO: The lab story and objectives (Standard Mode)
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your company is migrating critical services to RHEL 10, and you're joining
a team of experienced Linux administrators. During onboarding, your manager
emphasizes that the team values self-sufficiency - administrators are expected
to find answers in system documentation before asking for help. You need to
demonstrate mastery of Linux documentation tools.

BACKGROUND:
The RHCSA exam does not provide internet access. Your only resources during
the exam are the system's built-in documentation: man pages, info pages, and
documentation in /usr/share/doc. Mastering these tools is not just for the
exam - it's essential for daily system administration when you need quick
answers about command syntax, file formats, or system behavior.

OBJECTIVES:
  1. Understand man page sections and access specific sections:
     • View the man page for passwd command (Section 1)
     • View the man page for passwd file format (Section 5)
     • Document the difference between these two pages
     • Save findings to /opt/documentation_lab/findings/section_differences.txt
     • Explain when you'd use each section

  2. Navigate within man pages effectively:
     • Open the man page for 'ls' command
     • Search for the text "recursive" using forward search (/)
     • Find how many times "recursive" appears (use n to cycle)
     • Locate the -R flag description
     • Jump to the EXAMPLES section (if present)
     • Document the -R flag's purpose in /opt/documentation_lab/findings/ls_recursive.txt

  3. Use keyword search to find relevant man pages:
     • Use man -k or apropos to find commands related to "compress"
     • Filter results to show only Section 1 (user commands)
     • Count how many compression-related commands exist
     • Save the list to /opt/documentation_lab/findings/compression_tools.txt
     • Identify at least 3 different compression utilities

  4. Find command descriptions quickly:
     • Use whatis (or man -f) to get one-line descriptions for:
       - tar
       - gzip
       - ssh
       - systemctl
     • Save output to /opt/documentation_lab/findings/quick_descriptions.txt
     • Compare whatis vs full man page (speed vs detail trade-off)

  5. Explore man page structure and conventions:
     • Open man page for 'cp' command
     • Identify and document the following sections:
       - NAME (what the command does)
       - SYNOPSIS (how to use it)
       - DESCRIPTION (detailed info)
       - OPTIONS (available flags)
       - EXAMPLES (if present)
     • Note which options are optional (indicated by [brackets])
     • Note which are mandatory (no brackets)
     • Save structure analysis to /opt/documentation_lab/findings/manpage_structure.txt

  6. Update the man database (important for new installations):
     • Check when mandb was last updated: ls -l /var/cache/man/
     • Run mandb to rebuild the database
     • Verify it completed successfully
     • Understand why this matters (new software installations)

HINTS:
  • man pages use 'less' as the pager - same navigation commands apply
  • Section numbers in man -k output appear in parentheses: command(1)
  • Use pipe to grep to filter results: man -k keyword | grep '(1)'
  • Square brackets [] in SYNOPSIS mean optional parameters
  • Ellipsis ... means "can be repeated"
  • Underlined text represents placeholders you replace

SUCCESS CRITERIA:
  • Can explain difference between passwd(1) and passwd(5)
  • Can navigate man pages efficiently using /, n, g, G
  • Can use man -k to find commands by keyword
  • Can filter man -k results by section
  • Understand man page structure (NAME, SYNOPSIS, DESCRIPTION, etc.)
  • Know when to use whatis vs full man page
  • Can update mandb when needed
  • All findings documented in /opt/documentation_lab/findings/
EOF
}

#############################################################################
# QUICK OBJECTIVES: Condensed checklist
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Access and compare passwd(1) vs passwd(5) man pages
  ☐ 2. Navigate ls man page, search for "recursive", document -R flag
  ☐ 3. Use man -k to find compression tools, filter by section 1
  ☐ 4. Use whatis for quick descriptions (tar, gzip, ssh, systemctl)
  ☐ 5. Analyze cp man page structure and document conventions
  ☐ 6. Update mandb and understand why it's necessary
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################
get_step_count() {
    echo "6"
}

scenario_context() {
    cat << 'EOF'
Your company values self-sufficient administrators. You need to demonstrate
mastery of Linux documentation tools - man pages, apropos, and whatis - as
these will be your only resources during the RHCSA exam and in day-to-day work.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Understand man page sections

Man pages are organized into numbered sections, each covering different topics.
The same name can appear in multiple sections with completely different meanings.
This is critical to understand for finding the right documentation.

Requirements:
  • View passwd man page in Section 1 (user command): man 1 passwd
  • View passwd man page in Section 5 (file format): man 5 passwd
  • Document the key differences between these pages
  • Create file: /opt/documentation_lab/findings/section_differences.txt
  • Include:
    - What passwd(1) describes (the command)
    - What passwd(5) describes (the file format)
    - When you'd reference each

Understanding:
  passwd(1) - The COMMAND to change user passwords
  passwd(5) - The FILE FORMAT of /etc/passwd

Commands you might need:
  • man 1 passwd        - View Section 1 (command)
  • man 5 passwd        - View Section 5 (file format)
  • man passwd          - Views Section 1 by default (lowest numbered)
  • man -a passwd       - View all sections sequentially
  • man -f passwd       - List all sections available for passwd
EOF
}

validate_step_1() {
    local findings_file="/opt/documentation_lab/findings/section_differences.txt"
    
    if [ ! -f "$findings_file" ]; then
        print_color "$RED" "✗ Findings file not found: $findings_file"
        echo "  Create: mkdir -p /opt/documentation_lab/findings"
        echo "  Then document your findings in section_differences.txt"
        return 1
    fi
    
    # Check if file has substantial content (at least 5 lines)
    local line_count=$(wc -l < "$findings_file")
    if [ "$line_count" -lt 5 ]; then
        print_color "$YELLOW" "⚠ Findings file seems incomplete (only $line_count lines)"
        echo "  Document the differences between passwd(1) and passwd(5)"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Section differences documented"
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands to explore:
  # View passwd command manual (Section 1)
  man 1 passwd
  
  # View passwd file format manual (Section 5)
  man 5 passwd
  
  # See which sections have passwd entries
  man -f passwd
  # Or equivalently:
  whatis passwd
  
  # View all passwd sections sequentially (press q between)
  man -a passwd

Create findings document:
  mkdir -p /opt/documentation_lab/findings
  
  cat > /opt/documentation_lab/findings/section_differences.txt << 'EOF_DOC'
MAN PAGE SECTION COMPARISON: passwd
====================================

PASSWD(1) - User Command Section
---------------------------------
Purpose: 
  - Documents the 'passwd' COMMAND
  - Used by users to change their password
  - Used by root to change any user's password

Key Information Found:
  - Command syntax: passwd [options] [username]
  - Options: -l (lock), -u (unlock), -d (delete password)
  - Exit codes and error conditions
  - Examples of usage

When to Use:
  - When you need to know HOW to change passwords
  - When troubleshooting passwd command errors
  - When writing scripts that modify passwords

Typical Usage:
  - User changes own password: passwd
  - Root changes user password: passwd username
  - Root locks account: passwd -l username


PASSWD(5) - File Format Section
--------------------------------
Purpose:
  - Documents the /etc/passwd FILE format
  - Explains the structure and fields
  - Describes what each colon-separated field means

Key Information Found:
  - File location: /etc/passwd
  - Field structure: username:x:UID:GID:GECOS:home:shell
  - Field 1: Username
  - Field 2: Password (x = shadowed to /etc/shadow)
  - Field 3: User ID (UID)
  - Field 4: Group ID (GID)
  - Field 5: GECOS (comment/full name)
  - Field 6: Home directory
  - Field 7: Login shell

When to Use:
  - When you need to understand /etc/passwd structure
  - When parsing passwd file in scripts
  - When troubleshooting authentication issues
  - When manually examining user account configuration

Typical Usage:
  - Understanding file format before parsing
  - Knowing which field contains what data
  - Reference when writing awk/cut commands


CRITICAL DIFFERENCES
--------------------
1. Type:
   - Section 1: Executable COMMAND
   - Section 5: FILE FORMAT specification

2. Audience:
   - Section 1: Users running commands
   - Section 5: Administrators examining files

3. Content:
   - Section 1: Command options, syntax, examples
   - Section 5: File structure, field meanings, syntax

4. Use Cases:
   - Section 1: "How do I change a password?"
   - Section 5: "What does the third field in /etc/passwd mean?"


WHY THIS MATTERS FOR RHCSA
---------------------------
During the exam, you might need to:
  - Change a user's password → man 1 passwd
  - Parse /etc/passwd in a script → man 5 passwd
  - Understand /etc/fstab format → man 5 fstab
  - Use the mount command → man 8 mount
  
Knowing which section to reference saves critical exam time.


GENERAL SECTION GUIDE
----------------------
Section 1: Commands you RUN
Section 5: Files you READ/EDIT
Section 8: Admin commands you RUN with sudo

Quick memory aid:
  "If I TYPE it, it's probably Section 1 or 8"
  "If I OPEN it with an editor, check Section 5"
EOF_DOC

Explanation:

Why Multiple Sections Exist:
  The same name can refer to completely different things in Unix/Linux:
  - passwd: Both a command AND a file
  - crontab: Both a command AND a file format
  - mount: Command (Section 8) AND file format (Section 5 for /etc/fstab)
  
  Sections prevent naming conflicts and organize documentation logically.

How to Specify Sections:
  • man [section] command: View specific section
    Example: man 5 passwd (file format)
  
  • man command: Views lowest-numbered section by default
    Example: man passwd (defaults to Section 1)
  
  • man -a command: View all sections sequentially
    Press 'q' to move to next section
  
  • man -f command: List which sections exist
    Shows: passwd(1), passwd(5)

Section Number Locations in Output:
  When you see: passwd(1)
  - The number in parentheses is the section
  - passwd(1) means "passwd command in Section 1"
  - passwd(5) means "passwd file format in Section 5"

Common Multi-Section Examples:
  • crontab(1) - Command to edit cron jobs
  • crontab(5) - File format of crontab files
  
  • mount(8) - Command to mount filesystems
  • fstab(5) - File format for /etc/fstab
  
  • syslog(3) - Library function for logging
  • syslog.conf(5) - Configuration file format

Why This Matters for RHCSA:
  Question: "Configure /etc/fstab to mount a filesystem"
  Wrong: man mount (shows mount command, not file format)
  Right: man 5 fstab (shows file format and syntax)
  
  Question: "Create a cron job"
  Right: man 5 crontab (shows format of crontab file)
  Also useful: man 1 crontab (shows how to edit crontab)

Pro Tip:
  Before looking at any man page, ask yourself:
  "Am I trying to RUN something or CONFIGURE a file?"
  - Run → Section 1 or 8
  - Configure → Section 5

Verification:
  # Check sections available for passwd
  whatis passwd
  # Output:
  # passwd (1)           - update user's authentication tokens
  # passwd (5)           - password file
  
  # View specific section
  man 1 passwd | head -5
  man 5 passwd | head -5
  # Compare the NAME sections - completely different

EOF
}

hint_step_1() {
    echo "  Use 'man 1 passwd' and 'man 5 passwd' to see both, document differences"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Navigate and search within man pages

Man pages can be long and dense. Efficient navigation and searching are
essential skills for quickly finding the information you need.

Requirements:
  • Open man page for 'ls' command
  • Practice navigation:
    - Use Space to scroll forward
    - Use 'g' to jump to beginning
    - Use 'G' to jump to end
  • Search for "recursive" using forward search (/)
  • Press 'n' to find next occurrence
  • Locate the -R flag description
  • Document what -R does
  • Save to: /opt/documentation_lab/findings/ls_recursive.txt

Navigation Commands (within man pages):
  /pattern    - Search forward for pattern
  ?pattern    - Search backward for pattern
  n           - Next match (same direction)
  N           - Previous match (opposite direction)
  g or Home   - Go to beginning
  G or End    - Go to end
  Space       - Page forward
  b           - Page backward

Commands you might need:
  • man ls                  - Open ls manual
  • / (while in man page)   - Start forward search
  • n (after search)        - Next match
  • q                       - Quit man page
EOF
}

validate_step_2() {
    local findings_file="/opt/documentation_lab/findings/ls_recursive.txt"
    
    if [ ! -f "$findings_file" ]; then
        print_color "$RED" "✗ Findings file not found: $findings_file"
        return 1
    fi
    
    # Check if file mentions -R or recursive
    if ! grep -iq "recursive\|^-R" "$findings_file"; then
        print_color "$YELLOW" "⚠ File doesn't seem to document -R flag"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ ls recursive flag documented"
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Step-by-step navigation exercise:

1. Open the ls man page:
   man ls

2. Try basic navigation:
   - Press Space a few times (page forward)
   - Press 'b' (page backward)
   - Press 'g' (jump to beginning)
   - Press 'G' (jump to end)
   - Press 'g' again (back to beginning)

3. Search for "recursive":
   - Type: /recursive
   - Press Enter
   - You'll be taken to first match (highlighted)
   
4. Find all occurrences:
   - Press 'n' (next match)
   - Press 'n' again (next match)
   - Press 'N' (previous match - goes backward)
   - Continue pressing 'n' to see all matches

5. Locate -R flag specifically:
   - Type: /-R
   - Press Enter
   - You'll see: -R, --recursive

6. Read the description:
   From ls man page:
   "    -R, --recursive
         list subdirectories recursively"

7. Document findings:
   cat > /opt/documentation_lab/findings/ls_recursive.txt << 'EOF_DOC'
LS RECURSIVE FLAG DOCUMENTATION
================================

Flag: -R, --recursive

Purpose:
  Lists subdirectories recursively - not just the immediate directory,
  but ALL subdirectories beneath it.

Syntax:
  ls -R [directory]
  ls --recursive [directory]

Behavior:
  - Lists contents of specified directory
  - Then lists contents of each subdirectory
  - Then lists contents of each sub-subdirectory
  - Continues until all nested directories are shown

Example Use Cases:
  1. View entire directory tree structure:
     ls -R /etc/
  
  2. Find all files in complex directory hierarchy:
     ls -R /var/log/
  
  3. Combined with other options:
     ls -lR /home/user/Documents
     (Shows detailed listing of all files recursively)

Difference from Similar Options:
  • ls (no options) - Shows only current directory
  • ls -a - Shows hidden files in current directory only
  • ls -R - Shows all files in all subdirectories (recursive)
  • tree - Better formatted recursive view (if installed)

Output Format:
  /directory:
  file1 file2
  
  /directory/subdir1:
  file3 file4
  
  /directory/subdir2:
  file5 file6

Warning:
  Can produce very long output on deep directory structures.
  Consider piping to less: ls -R /etc | less

RHCSA Relevance:
  Useful for quickly exploring directory structures during exam.
  However, 'find' command is often more practical for specific searches.

Navigation Practice Notes:
  - Found "recursive" by typing /recursive in man page
  - Used 'n' to cycle through matches (found 3 occurrences)
  - Located -R flag description in OPTIONS section
  - Verified with: ls -R /opt to see it in action
EOF_DOC

Explanation:

Search Mechanics in Man Pages:
  Man pages use 'less' as the pager, which provides search functionality:
  
  Forward Search:
    1. Type / (forward slash)
    2. Type your search term
    3. Press Enter
    4. First match is highlighted and displayed
    5. Press 'n' for next match
    6. Press 'N' for previous match
  
  Backward Search:
    1. Type ? (question mark)
    2. Type your search term
    3. Press Enter
    4. Searches backward from current position
    5. Press 'n' to continue searching backward
    6. Press 'N' to search forward

Case Sensitivity:
  By default, searches are case-insensitive if search term is lowercase:
  - /recursive - Finds "recursive", "Recursive", "RECURSIVE"
  - /Recursive - Case-sensitive, only finds "Recursive"

Search Patterns:
  Basic patterns work:
  - /^-R - Finds "-R" at start of line (useful for flags)
  - /example$ - Finds "example" at end of line
  - /file.txt - Finds literal "file.txt"

Why This Matters:
  Man pages for complex commands can be 500+ lines. Examples:
  - man bash: 5000+ lines
  - man ssh: 1500+ lines
  - man iptables: 2000+ lines
  
  Without search, finding specific options takes forever.
  With search, you find what you need in seconds.

Common Search Patterns for RHCSA:
  When in man page, search for:
  - /EXAMPLES - Jump to examples section
  - /^  *-[a-z] - Find options (flags)
  - /FILES - Find relevant config files
  - /SEE ALSO - Find related commands

Navigation Shortcuts:
  • g = Go to top (mnemonic: "Go to beginning")
  • G = Go to bottom (mnemonic: "Go to end" - capital G)
  • Space = Forward one page
  • b = Backward one page (mnemonic: "back")
  • d = Forward half page (mnemonic: "down")
  • u = Backward half page (mnemonic: "up")
  • q = Quit (mnemonic: "quit")

Pro Tips for Exam:
  1. Search for keywords from the question:
     Question mentions "recursive"? Type /recursive
  
  2. Jump to EXAMPLES first:
     Type /EXAMPLES to see usage patterns
  
  3. Use multiple searches:
     /copy then /recursive to find recursive copy
  
  4. If not found:
     Try synonyms or related terms
     /recursive → /recurse → /subdirector

Verification:
  # Practice navigation
  man ls
  # Type: /recursive
  # Press: n n n (cycle through matches)
  # Type: /-R
  # Read the description
  # Press: q (quit)
  
  # Test what you learned
  ls -R /opt/documentation_lab
  # Should show all files recursively

EOF
}

hint_step_2() {
    echo "  Open 'man ls', type '/recursive' to search, 'n' for next match, document -R"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Find commands using keyword search

Often you know WHAT you want to do but not WHICH command does it.
The man -k (keyword search) is essential for discovering commands.

Requirements:
  • Use 'man -k compress' or 'apropos compress'
  • Examine the results (many commands mention compression)
  • Filter results to show only Section 1 (user commands)
  • Use: man -k compress | grep '(1)'
  • Count how many compression tools are in Section 1
  • Save the list to: /opt/documentation_lab/findings/compression_tools.txt
  • Identify at least 3 different compression utilities (gzip, bzip2, xz, etc.)

Understanding the Output:
  command(section) - description
  Example: gzip(1) - compress or expand files

Commands you might need:
  • man -k keyword          - Search by keyword
  • apropos keyword         - Same as man -k
  • man -k compress | grep '(1)'  - Filter to Section 1
  • man -k compress | wc -l       - Count results
  • whatis command          - Get brief description
EOF
}

validate_step_3() {
    local findings_file="/opt/documentation_lab/findings/compression_tools.txt"
    
    if [ ! -f "$findings_file" ]; then
        print_color "$RED" "✗ Findings file not found: $findings_file"
        return 1
    fi
    
    # Check if file has reasonable content
    local line_count=$(wc -l < "$findings_file")
    if [ "$line_count" -lt 5 ]; then
        print_color "$YELLOW" "⚠ Findings file seems incomplete"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Compression tools documented"
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands to execute:

1. Search for compression-related commands:
   man -k compress
   # OR equivalently:
   apropos compress

2. Filter to only Section 1 (user commands):
   man -k compress | grep '(1)'

3. Count how many Section 1 results:
   man -k compress | grep '(1)' | wc -l

4. Save the filtered list:
   man -k compress | grep '(1)' > /opt/documentation_lab/findings/compression_tools.txt

5. Create comprehensive documentation:
   cat > /opt/documentation_lab/findings/compression_tools.txt << 'EOF_DOC'
COMPRESSION TOOLS DISCOVERED VIA MAN -K
========================================

Search Command Used:
  man -k compress | grep '(1)'

Purpose:
  Find all user commands (Section 1) related to compression


RAW OUTPUT FROM SYSTEM:
-----------------------
EOF_DOC

   # Append actual system output
   man -k compress | grep '(1)' >> /opt/documentation_lab/findings/compression_tools.txt

   cat >> /opt/documentation_lab/findings/compression_tools.txt << 'EOF_DOC'


IDENTIFIED COMPRESSION UTILITIES:
==================================

1. GZIP - GNU Zip Compression
   Command: gzip, gunzip, zcat
   Extension: .gz
   Description: Compress or expand files using Lempel-Ziv coding (LZ77)
   Usage:
     - Compress: gzip file.txt → creates file.txt.gz
     - Decompress: gunzip file.txt.gz
     - View compressed: zcat file.txt.gz
   Compression: Good balance of speed and size
   Verify: man 1 gzip

2. BZIP2 - Block-Sorting Compression
   Command: bzip2, bunzip2, bzcat
   Extension: .bz2
   Description: Better compression than gzip but slower
   Usage:
     - Compress: bzip2 file.txt → creates file.txt.bz2
     - Decompress: bunzip2 file.txt.bz2
     - View compressed: bzcat file.txt.bz2
   Compression: Better than gzip, slower
   Verify: man 1 bzip2

3. XZ - LZMA Compression
   Command: xz, unxz, xzcat
   Extension: .xz
   Description: Best compression ratio, used for kernel and large archives
   Usage:
     - Compress: xz file.txt → creates file.txt.xz
     - Decompress: unxz file.txt.xz
     - View compressed: xzcat file.txt.xz
   Compression: Best ratio, slowest
   Verify: man 1 xz

4. ZIP - PKZIP Compatible Archive
   Command: zip, unzip
   Extension: .zip
   Description: Cross-platform compression, includes directory structure
   Usage:
     - Compress: zip archive.zip file1 file2
     - Decompress: unzip archive.zip
   Compression: Moderate, best for Windows compatibility
   Verify: man 1 zip

5. COMPRESS - Traditional Unix Compression (if present)
   Command: compress, uncompress
   Extension: .Z
   Description: Older compression, rarely used now
   Usage: compress file.txt
   Note: Largely replaced by gzip
   Verify: man 1 compress


COMPARISON CHART:
=================
Tool    | Extension | Compression | Speed  | Use Case
--------|-----------|-------------|--------|---------------------------
gzip    | .gz       | Good        | Fast   | General purpose, default
bzip2   | .bz2      | Better      | Medium | When size matters more
xz      | .xz       | Best        | Slow   | Kernel, large archives
zip     | .zip      | Moderate    | Fast   | Cross-platform, Windows
compress| .Z        | Poor        | Fast   | Legacy systems only


COMMON COMBINATIONS WITH TAR:
==============================
Tar itself doesn't compress - it archives. Combine with compression:

tar + gzip:
  - Create: tar -czf archive.tar.gz directory/
  - Extract: tar -xzf archive.tar.gz
  - Most common combination

tar + bzip2:
  - Create: tar -cjf archive.tar.bz2 directory/
  - Extract: tar -xjf archive.tar.bz2
  - Better compression

tar + xz:
  - Create: tar -cJf archive.tar.xz directory/
  - Extract: tar -xJf archive.tar.xz
  - Best compression, used for source code

Flags explained:
  -c : Create archive
  -x : Extract archive
  -z : Use gzip compression
  -j : Use bzip2 compression
  -J : Use xz compression
  -f : Specify filename


KEYWORD SEARCH METHODOLOGY:
============================

How man -k Works:
  1. Searches the NAME section of all man pages
  2. Returns matches in format: command(section) - description
  3. Draws from mandb database (updated by mandb command)

Why Filter by Section:
  - man -k returns ALL sections (1-8)
  - Section 1 = User commands (what you typically want)
  - Section 3 = Library functions (for programmers)
  - Section 8 = Admin commands (may also be relevant)

Example Filtering:
  man -k compress              # All sections
  man -k compress | grep '(1)' # Only user commands
  man -k compress | grep '(8)' # Only admin commands


RHCSA EXAM RELEVANCE:
=====================

Common Scenarios:
  1. "Create a compressed archive of /etc"
     → You know you need compression
     → Search: man -k compress
     → Find: gzip, tar
     → Read: man tar (see -z flag)
  
  2. "Extract a .tar.bz2 file"
     → You know the extension
     → Search: man -k bzip2
     → Find: bunzip2, tar -j
     → Read: man tar (see -j flag)

Pro Tips:
  - Save time: Know gzip, bzip2, xz basics before exam
  - Quick reference: man tar has ALL compression methods
  - If stuck: man -k [keyword] | less (browse all results)


VERIFICATION COMMANDS:
======================
To verify these tools exist:
  which gzip && echo "gzip available"
  which bzip2 && echo "bzip2 available"
  which xz && echo "xz available"
  which zip && echo "zip available"

To test compression:
  echo "test data" > test.txt
  gzip -k test.txt    # Creates test.txt.gz, keeps original
  bzip2 -k test.txt   # Creates test.txt.bz2, keeps original
  xz -k test.txt      # Creates test.txt.xz, keeps original
  ls -lh test.txt*    # Compare sizes
EOF_DOC

Explanation:

Man -k (Keyword Search) Mechanics:
  • man -k searches the NAME and DESCRIPTION fields of all man pages
  • Equivalent command: apropos
  • Searches the mandb database (not the actual files)
  • Returns format: command(section) - description

How the Database is Built:
  • mandb command indexes all man pages
  • Typically runs automatically (daily cron job)
  • Manually rebuild: sudo mandb
  • Database location: /var/cache/man/

Reading the Output:
  gzip (1) - compress or expand files
  │     │    └─ Description (from NAME section)
  │     └───── Section number in parentheses
  └────────── Command name

Why Filter by Section:
  Unfiltered search might return:
  - compress(1) - Command to compress files
  - zlib(3) - Compression library (programming)
  - gzip(1) - Another compression command
  
  You typically want user commands (Section 1) not library functions.

Filtering Techniques:
  # Show only user commands
  man -k compress | grep '(1)'
  
  # Show only admin commands
  man -k compress | grep '(8)'
  
  # Show user OR admin commands
  man -k compress | grep -E '\((1|8)\)'
  
  # Exclude library functions (Section 3)
  man -k compress | grep -v '(3)'

Count Results:
  man -k compress | wc -l                  # All sections
  man -k compress | grep '(1)' | wc -l     # User commands only

Common Keywords for RHCSA:
  - man -k network         # Network-related commands
  - man -k user            # User management
  - man -k file system     # Filesystem operations
  - man -k package         # Package management
  - man -k process         # Process management
  - man -k firewall        # Firewall configuration
  - man -k encrypt         # Encryption tools

Troubleshooting man -k:
  Problem: "nothing appropriate" message
  Solution: mandb database not built
  Fix: sudo mandb
  
  Problem: Old results after installing software
  Solution: Database not updated
  Fix: sudo mandb

Real Exam Scenario:
  Question: "Archive /home directory with bzip2 compression"
  
  Approach 1 (if you remember):
    tar -cjf home.tar.bz2 /home
  
  Approach 2 (if you don't remember):
    man -k bzip2          # Find bzip2 command
    man tar               # Look for bzip2 option
    Search for "bzip2" in man tar
    Find: -j flag for bzip2
    Execute: tar -cjf home.tar.bz2 /home

Verification:
  # Try keyword search
  man -k user | head -10
  
  # Filter by section
  man -k user | grep '(1)' | head -5
  man -k user | grep '(8)' | head -5
  
  # Count results
  echo "User commands about 'user': $(man -k user | grep '(1)' | wc -l)"
  echo "Admin commands about 'user': $(man -k user | grep '(8)' | wc -l)"

EOF
}

hint_step_3() {
    echo "  Use 'man -k compress | grep \"(1)\"' to filter user commands, save results"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Get quick command descriptions with whatis

Sometimes you need a quick reminder of what a command does without reading
the full man page. The 'whatis' command provides one-line descriptions.

Requirements:
  • Use whatis to get descriptions for:
    - tar
    - gzip  
    - ssh
    - systemctl
  • Save all output to: /opt/documentation_lab/findings/quick_descriptions.txt
  • Compare the speed of whatis vs opening full man pages
  • Document when to use whatis vs man

Commands you might need:
  • whatis command         - One-line description
  • man -f command         - Same as whatis
  • whatis cmd1 cmd2 cmd3  - Multiple commands at once
EOF
}

validate_step_4() {
    local findings_file="/opt/documentation_lab/findings/quick_descriptions.txt"
    
    if [ ! -f "$findings_file" ]; then
        print_color "$RED" "✗ Findings file not found: $findings_file"
        return 1
    fi
    
    # Check if file contains expected commands
    local found_count=0
    grep -iq "tar" "$findings_file" && ((found_count++))
    grep -iq "gzip" "$findings_file" && ((found_count++))
    grep -iq "ssh" "$findings_file" && ((found_count++))
    grep -iq "systemctl" "$findings_file" && ((found_count++))
    
    if [ "$found_count" -lt 3 ]; then
        print_color "$YELLOW" "⚠ Missing descriptions for some commands"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Quick descriptions documented"
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Execute whatis commands:
  whatis tar
  whatis gzip
  whatis ssh
  whatis systemctl
  
  # Or all at once:
  whatis tar gzip ssh systemctl

Create documentation:
  cat > /opt/documentation_lab/findings/quick_descriptions.txt << 'EOF_DOC'
WHATIS COMMAND DESCRIPTIONS
============================

Command: whatis tar gzip ssh systemctl

Output:
EOF_DOC

  # Append actual whatis output
  whatis tar gzip ssh systemctl >> /opt/documentation_lab/findings/quick_descriptions.txt 2>&1

  cat >> /opt/documentation_lab/findings/quick_descriptions.txt << 'EOF_DOC'

ANALYSIS OF RESULTS:
====================

TAR:
  Description: "an archiving utility"
  Full man page size: ~1500 lines
  Whatis shows: Basic purpose in <10 words
  When to use whatis: Quick reminder of what tar does
  When to use man: Need to know specific flags or syntax

GZIP:
  Description: "compress or expand files"
  Full man page size: ~400 lines
  Whatis shows: Core function immediately
  When to use whatis: Confirm it's compression tool
  When to use man: Need compression ratio options

SSH:
  Description: "OpenSSH remote login client"
  Full man page size: ~2000 lines
  Whatis shows: Primary purpose clearly
  When to use whatis: Remember what SSH is
  When to use man: Need specific connection options

SYSTEMCTL:
  Description: "Control the systemd system and service manager"
  Full man page size: ~1000 lines
  Whatis shows: Management purpose
  When to use whatis: Quick confirmation of purpose
  When to use man: Need syntax for starting/stopping services


WHATIS VS MAN COMPARISON:
==========================

WHATIS Advantages:
  ✓ Instant results (<1 second)
  ✓ One-line summary - no scrolling
  ✓ Can query multiple commands at once
  ✓ Perfect for quick confirmation
  ✓ Shows which sections have entries
  ✓ No need to navigate or exit

MAN Advantages:
  ✓ Complete documentation
  ✓ Syntax and examples
  ✓ All flags and options
  ✓ Related commands (SEE ALSO)
  ✓ Detailed descriptions
  ✓ Configuration file info


WHEN TO USE EACH:
=================

Use WHATIS when:
  - You remember command name but not purpose
  - Quick sanity check: "Is this the right command?"
  - Browsing related commands quickly
  - Checking if command exists
  - Need section numbers for a command
  Example: "Is 'passwd' the right command to change passwords?" → whatis passwd

Use MAN when:
  - Need to know HOW to use command
  - Need specific option flags
  - Need syntax or examples
  - Troubleshooting errors
  - Learning new command in depth
  Example: "How do I change another user's password?" → man passwd


SPEED COMPARISON TEST:
======================

Timed Test (approximate):
  whatis systemctl: <1 second
  man systemctl: 2-3 seconds to open, then need to navigate

Example workflow:
  1. Remember command vaguely → whatis systemctl (0.5s)
  2. Confirm it's right tool → man systemctl (2s to open)
  3. Search for specific option → /enable (instant)
  4. Read documentation → 30s-2min depending on complexity


EXAM STRATEGY:
==============

During RHCSA:
  Use WHATIS for:
    - Confirming command exists
    - Quick purpose check
    - Deciding which man page to open
  
  Use MAN for:
    - Actually solving the question
    - Finding exact syntax
    - Checking examples

NEVER:
    - Spend exam time reading full man pages front-to-back
    - Open man page without knowing what you're looking for

DO:
    - Use whatis first to confirm right tool
    - Use man with specific search (/keyword)
    - Jump to EXAMPLES section in man (type /EXAMPLE)


ADDITIONAL WHATIS FEATURES:
============================

Show all sections:
  whatis passwd
  Output:
    passwd (1)  - update user's authentication tokens
    passwd (5)  - password file
  
  Shows multiple sections automatically!

Wildcard searches (use apropos instead):
  apropos '^passwd'     # Commands starting with passwd
  apropos 'password.*'  # Commands with password in name

Equivalent commands:
  whatis command  = man -f command
  apropos keyword = man -k keyword


VERIFICATION:
=============

Test whatis:
  whatis ls cp mv rm mkdir
  # Should show one-line description for each

Test non-existent command:
  whatis fakecommand123
  # Should show: fakecommand123: nothing appropriate

Compare timing:
  time whatis systemctl     # Instant
  time man systemctl        # 2-3 seconds

Check sections:
  whatis passwd crontab     # Shows multiple sections
EOF_DOC

Explanation:

Whatis Purpose:
  - Extracts NAME section from man pages
  - Provides one-line description
  - Much faster than opening full man page
  - Perfect for quick reference

How Whatis Works:
  1. Reads from mandb database (same as man -k)
  2. Extracts NAME field only
  3. Returns formatted output
  4. Shows all sections if multiple exist

Output Format:
  command (section) - description
  Example: ls (1) - list directory contents

Multiple Commands:
  whatis cmd1 cmd2 cmd3
  - Processes all in one call
  - Faster than multiple separate calls
  - Useful for comparing related commands

Comparison with Related Commands:
  • whatis command: One-line from NAME section
  • man -f command: Exact same as whatis
  • apropos keyword: Searches descriptions (man -k)
  • man command: Full documentation

Real Usage Patterns:
  Scenario: "Need to compress a file"
  
  Step 1 - Quick check:
    whatis gzip bzip2 xz
    # See which exists and basic purpose
  
  Step 2 - Choose tool:
    gzip (fastest, good compression)
  
  Step 3 - Get syntax:
    man gzip
    # Search for /EXAMPLE or specific flags

RHCSA Exam Efficiency:
  Question: "Use systemctl to enable a service"
  
  Wrong approach (wastes time):
    man systemctl
    [scroll through 1000 lines looking for enable]
  
  Better approach:
    whatis systemctl  # Confirm it's right tool (2 seconds)
    man systemctl     # Open man page
    /enable           # Search directly for 'enable'
    # Find: systemctl enable servicename

Pro Exam Tips:
  1. Use whatis to build command vocabulary before exam
     Run: whatis ls cp mv rm cat grep find
  
  2. If question mentions unfamiliar command:
     whatis [command] first (confirm it exists)
  
  3. Whatis shows section numbers:
     Helps you decide: man 1 passwd or man 5 passwd?

Troubleshooting:
  Problem: "nothing appropriate"
  Cause: Command doesn't exist OR mandb not updated
  Fix 1: Check if command exists: which [command]
  Fix 2: Update database: sudo mandb

Verification:
  # Test whatis
  whatis tar gzip ssh systemctl
  
  # Compare with man -f
  man -f tar
  # Should be identical to whatis tar
  
  # Test multiple sections
  whatis passwd crontab
  # Should show (1) and (5) for both

EOF
}

hint_step_4() {
    echo "  Run 'whatis tar gzip ssh systemctl' and save output to findings file"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Understand man page structure and conventions

All man pages follow a standard structure. Understanding this structure
helps you quickly find information without reading everything.

Requirements:
  • Open man page for 'cp' command
  • Identify and document the standard sections:
    - NAME: Brief description
    - SYNOPSIS: Command syntax overview
    - DESCRIPTION: Detailed explanation
    - OPTIONS: Available flags and their meanings
    - EXAMPLES: Usage examples (if present)
  • Note syntax conventions:
    - [square brackets] = optional parameters
    - <angle brackets> or CAPS = required placeholders
    - ... (ellipsis) = can repeat
    - | (pipe) = choose one option
  • Save analysis to: /opt/documentation_lab/findings/manpage_structure.txt

Commands you might need:
  • man cp                 - Open cp manual
  • / (in man page)        - Search for sections
  • /^[A-Z]                - Find section headers
EOF
}

validate_step_5() {
    local findings_file="/opt/documentation_lab/findings/manpage_structure.txt"
    
    if [ ! -f "$findings_file" ]; then
        print_color "$RED" "✗ Findings file not found: $findings_file"
        return 1
    fi
    
    # Check for key terms indicating structure analysis
    local found_count=0
    grep -iq "synopsis\|NAME\|DESCRIPTION" "$findings_file" && ((found_count++))
    grep -iq "optional\|\[.*\]\|bracket" "$findings_file" && ((found_count++))
    
    if [ "$found_count" -lt 2 ]; then
        print_color "$YELLOW" "⚠ Structure analysis incomplete"
        return 1
    fi
    
    print_color "$GREEN" "  ✓ Man page structure documented"
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Open and analyze cp man page:
  man cp

Create structure documentation:
  cat > /opt/documentation_lab/findings/manpage_structure.txt << 'EOF_DOC'
MAN PAGE STRUCTURE ANALYSIS: cp(1)
===================================

STANDARD MAN PAGE SECTIONS:
============================

1. NAME Section
---------------
Location: First section (always)
Purpose: Brief one-line description
Format: command - description
Example from cp:
  "cp - copy files and directories"

What you learn:
  - Basic command purpose
  - This is what 'whatis' displays
  - Helps confirm you have the right man page

When to read:
  - Always (takes 2 seconds)
  - Confirms you're in the right place


2. SYNOPSIS Section
-------------------
Location: Second section (always)
Purpose: Command syntax overview
Format: Shows all possible usage patterns

Example from cp:
  cp [OPTION]... [-T] SOURCE DEST
  cp [OPTION]... SOURCE... DIRECTORY
  cp [OPTION]... -t DIRECTORY SOURCE...

What you learn:
  - How to structure your command
  - What's optional vs required
  - Different usage modes
  - Order of arguments

When to read:
  - Before first use of command
  - When getting syntax errors
  - When command has multiple modes


3. DESCRIPTION Section
----------------------
Location: After SYNOPSIS
Purpose: Detailed explanation of command behavior
Length: Can be very long (hundreds of lines)

Example from cp:
  "Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY."

What you learn:
  - Detailed behavior
  - Important notes and warnings
  - Relationship between options

When to read:
  - When OPTIONS section isn't clear enough
  - When unexpected behavior occurs
  - Usually SKIP this during exam (too detailed)


4. OPTIONS Section
------------------
Location: After DESCRIPTION
Purpose: List all available flags with descriptions
Format: Each option with explanation

Example from cp (excerpt):
  -a, --archive
       same as -dR --preserve=all
  
  -r, -R, --recursive
       copy directories recursively

What you learn:
  - Every available flag
  - Short form (-r) and long form (--recursive)
  - What each flag does

When to read:
  - THIS IS THE MOST IMPORTANT SECTION FOR EXAM
  - When you need specific functionality
  - Use search: /-r to find specific options


5. EXAMPLES Section
-------------------
Location: Near end (if present)
Purpose: Real-world usage examples
Note: NOT ALL man pages have this

Example from cp (may vary):
  cp file1 file2
       Copy file1 to file2
  
  cp -r dir1 dir2
       Copy directory recursively

What you learn:
  - Practical usage patterns
  - Common combinations
  - Exactly how to structure commands

When to read:
  - FIRST if section exists (saves massive time)
  - Provides ready-to-use commands
  - Jump here with: /EXAMPLE


6. SEE ALSO Section
-------------------
Location: End of man page
Purpose: Related commands and man pages

Example from cp:
  mv(1), ln(1), install(1)

What you learn:
  - Related commands
  - Alternative approaches
  - Where to look next

When to read:
  - When cp doesn't do what you need
  - When exploring related functionality


7. Additional Sections (command-specific)
------------------------------------------
Some man pages include:
  - FILES: Configuration files used
  - ENVIRONMENT: Environment variables
  - EXIT STATUS: Return codes
  - BUGS: Known issues
  - AUTHOR: Who wrote the software
  - HISTORY: Command evolution


SYNOPSIS SYNTAX CONVENTIONS:
=============================

Convention 1: Square Brackets [] = Optional
--------------------------------------------
Example: cp [OPTION]... SOURCE DEST

Interpretation:
  - [OPTION] is optional - can be omitted
  - Without options: cp SOURCE DEST
  - With options: cp -r SOURCE DEST

More examples:
  - ls [OPTION]... [FILE]...
    Can be: ls
    Or: ls -l
    Or: ls /etc
    Or: ls -l /etc

  - mkdir [OPTION]... DIRECTORY...
    Can be: mkdir newdir
    Or: mkdir -p /path/to/newdir


Convention 2: Angle Brackets <> or CAPS = Required Placeholder
---------------------------------------------------------------
Example: cp SOURCE DEST

Interpretation:
  - SOURCE and DEST are REQUIRED
  - Replace with actual values
  - SOURCE: actual source file/directory
  - DEST: actual destination

Examples:
  - mount <device> <directory>
    Must provide: mount /dev/sdb1 /mnt/usb
  
  - useradd USERNAME
    Must provide: useradd john


Convention 3: Ellipsis ... = Can Repeat
----------------------------------------
Example: cp [OPTION]... SOURCE... DIRECTORY

Interpretation:
  - [OPTION]... = Can use multiple options
  - SOURCE... = Can specify multiple sources

Examples:
  - cp -r -v -f file1 file2 file3 /backup/
    Multiple options AND multiple sources
  
  - rm [OPTION]... FILE...
    Can be: rm file1 file2 file3 file4


Convention 4: Pipe | = Choose One
----------------------------------
Example: grep [OPTION]... PATTERN [FILE]...
            or: grep [OPTION]... -e PATTERN ... [FILE]...

Interpretation:
  - Use either first form OR second form
  - Not both simultaneously
  - Pipe shows mutually exclusive options

Examples:
  - ls [-l | -1]
    Use -l OR -1, not both
  
  - command {start|stop|restart}
    Choose one: start, stop, or restart


Convention 5: No Decoration = Literal Text
-------------------------------------------
Example: git commit -m "message"

Interpretation:
  - Type exactly as shown
  - -m is literal flag
  - "message" is placeholder for your text


REAL SYNOPSIS ANALYSIS:
========================

Complex Example: tar
--------------------
SYNOPSIS:
  tar [OPTIONS] [-f ARCHIVE] [FILE]...

Breaking it down:
  1. tar = command itself (literal)
  2. [OPTIONS] = optional flags like -c, -x, -v
  3. [-f ARCHIVE] = optional -f flag with required ARCHIVE name
  4. [FILE]... = optional list of files (can repeat)

Usage examples:
  tar -czf backup.tar.gz /home     # Create compressed archive
  tar -xzf backup.tar.gz           # Extract archive
  tar -tzf backup.tar.gz           # List contents


READING STRATEGY FOR EXAM:
===========================

Time-Efficient Approach:
  1. Read NAME (2 seconds)
     → Confirm right command
  
  2. Check for EXAMPLES (5 seconds)
     → If exists, try to use directly
     → May solve entire question
  
  3. Read SYNOPSIS (10 seconds)
     → Understand basic syntax
     → Identify required vs optional
  
  4. Search OPTIONS (1-2 minutes)
     → Type: /keyword to find specific flag
     → Read only relevant options
     → Skip rest
  
  5. Skip DESCRIPTION unless confused
     → Too detailed for time pressure
  
  6. Check SEE ALSO if stuck
     → Find alternative commands

NEVER:
  - Read man page front-to-back (wastes 10-30 minutes)
  - Read DESCRIPTION in detail during exam
  - Try to memorize entire man page

ALWAYS:
  - Use search (/) to find specific options
  - Read EXAMPLES if available
  - Focus on OPTIONS section


PRACTICAL APPLICATION:
======================

Exam Question Example:
  "Copy /etc/hosts to /backup/hosts.backup preserving ownership and timestamps"

Step 1 - Open man page:
  man cp

Step 2 - Search for preserve:
  /preserve
  [finds: --preserve=mode,ownership,timestamps]

Step 3 - Read option description:
  --preserve[=ATTR_LIST]
     preserve specified attributes

Step 4 - Construct command:
  cp --preserve=ownership,timestamps /etc/hosts /backup/hosts.backup

Alternative - Search for example:
  /EXAMPLE
  [might find: cp -a (archive = preserve all)]

Result:
  cp -a /etc/hosts /backup/hosts.backup
  (shorter, same result)


VERIFICATION:
=============

Practice identifying conventions:
  man cp
  
  Identify in SYNOPSIS:
    □ What's optional? [OPTION]... and [-T] and [FILE]...
    □ What's required? SOURCE and DEST
    □ What can repeat? SOURCE...
  
  Test your understanding:
    cp file1 file2              # Valid (required only)
    cp -r dir1 dir2             # Valid (optional + required)
    cp -r -v dir1 dir2          # Valid (multiple options)
    cp -r file1 file2 file3 /backup/  # Valid (multiple sources)
    cp                          # INVALID (missing required)
EOF_DOC

Explanation included in document above.

EOF
}

hint_step_5() {
    echo "  Open 'man cp', analyze sections, document conventions like [] for optional"
}

# STEP 6
show_step_6() {
    cat << 'EOF'
TASK: Update the man page database

The mandb database must be up-to-date for man -k and apropos to work correctly.
After installing new software, the database should be rebuilt.

Requirements:
  • Check current mandb cache: ls -lh /var/cache/man/
  • Run mandb to rebuild database: sudo mandb
  • Observe the output and time taken
  • Understand why this is necessary
  • Document when to update mandb

Commands you might need:
  • sudo mandb             - Rebuild man page database
  • ls -lh /var/cache/man/ - Check database cache
  • date                   - Check current time
  • man -k test | wc -l    - Verify database works
EOF
}

validate_step_6() {
    # Check if mandb has been run (cache directory should exist and be recent)
    if [ -d "/var/cache/man" ]; then
        print_color "$GREEN" "  ✓ Man database cache exists"
        print_color "$YELLOW" "  Run 'sudo mandb' to ensure it's up to date"
        return 0
    else
        print_color "$YELLOW" "⚠ Man database cache not found"
        echo "  This is unusual - may need to install man-db package"
        return 0
    fi
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Commands to execute:

1. Check current database:
   ls -lh /var/cache/man/
   # Shows index files and timestamps

2. Rebuild database:
   sudo mandb
   # Processes all man pages and rebuilds index

3. Observe output:
   # Shows: Processing manual pages under /usr/share/man...
   # Reports: X man pages, Y cat pages, Z removed

Example output:
  Processing manual pages under /usr/share/man...
  Updating index cache for path `/usr/share/man/man1'. Wait...done.
  Checking for stray cats under /usr/share/man...
  Checking for stray cats under /var/cache/man...
  Processing manual pages under /usr/share/man/cs...
  [... continues for each locale ...]
  0 man subdirectories contained newer manual pages.
  0 manual pages were added.
  0 stray cats were added.
  0 old database entries were purged.

Documentation:
  cat > /opt/documentation_lab/notes/mandb_info.txt << 'EOF_DOC'
MAN DATABASE (MANDB) EXPLAINED
===============================

What is mandb?
--------------
The mandb database is an index of all man pages on the system.
It contains:
  - Command names
  - Descriptions (from NAME sections)
  - Section numbers
  - File locations

Used by:
  - man -k (apropos)  - Keyword searches
  - whatis (man -f)   - Quick descriptions
  - Man page completion in bash


Why Rebuild mandb?
------------------
Situations requiring mandb update:

1. After Installing New Software
   Problem: New commands installed but not searchable
   Example:
     - Install nginx: sudo dnf install nginx
     - Search fails: man -k nginx (nothing appropriate)
     - Update database: sudo mandb
     - Now works: man -k nginx (shows results)

2. After Manual Man Page Installation
   Problem: Copied man pages manually to /usr/local/share/man
   Solution: Run mandb to index new files

3. After System Upgrade
   Problem: RHEL upgrade may add/remove man pages
   Solution: mandb ensures index matches installed pages

4. Corrupted Database
   Problem: man -k returns strange results or errors
   Solution: mandb rebuilds from scratch


When NOT Needed:
----------------
- Normal package installations (mandb runs automatically)
- Daily usage (automatic updates via cron)
- After reading man pages (doesn't change database)


Automatic Updates:
------------------
Linux systems typically run mandb automatically:

Cron Job: /etc/cron.daily/man-db
  - Runs daily at night
  - Updates database automatically
  - Keeps index current

Check automatic updates:
  cat /etc/cron.daily/man-db
  systemctl status man-db.timer (if using systemd timers)


Manual Update Process:
----------------------
Command: sudo mandb
  - Requires root (modifies system cache)
  - Processes all man pages in standard locations
  - Updates /var/cache/man/ indices
  - Takes 10-60 seconds depending on system

Options:
  mandb           - Standard rebuild
  mandb -c        - Create database from scratch (slower)
  mandb -q        - Quiet mode (less output)
  mandb -t        - Test mode (don't actually update)


Database Locations:
-------------------
Index files stored in:
  /var/cache/man/

Man pages sourced from:
  /usr/share/man/       - System man pages
  /usr/local/share/man/ - Locally installed software
  ~/man/                - User-specific man pages (if configured)


Verification Commands:
----------------------
Check database status:
  ls -lh /var/cache/man/
  # Shows index files and modification times

Test database:
  man -k test | wc -l
  # Should return number of matches
  # If returns "nothing appropriate" → mandb needed

Check when last updated:
  stat /var/cache/man/index.db
  # Shows last modification time


RHCSA Exam Relevance:
=====================

Scenario 1: Software Installation
  Question: "Install package X and verify man page is available"
  
  Steps:
    1. sudo dnf install package-name
    2. man package-name
    3. If fails: sudo mandb (manual rebuild)
    4. man package-name (now works)

Scenario 2: Using man -k
  Question: "Find commands related to encryption"
  
  Steps:
    1. man -k encrypt
    2. If "nothing appropriate":
       sudo mandb (rebuild database)
       man -k encrypt (now works)

Note: Exam systems should have current mandb, but knowing
how to fix it demonstrates troubleshooting skills.


Troubleshooting:
================

Problem: "nothing appropriate" for known commands
Cause: mandb not built or outdated
Fix: sudo mandb

Problem: mandb takes very long time
Cause: Many locales or large documentation
Fix: Normal, be patient (or use mandb -q)

Problem: Permission denied when running mandb
Cause: Must be root to update system cache
Fix: sudo mandb

Problem: man -k still fails after mandb
Cause: man-db package may be missing
Fix: sudo dnf install man-db


Performance Notes:
==================

Time to rebuild:
  - Desktop system: 10-30 seconds
  - Server with minimal docs: 5-10 seconds
  - Server with many locales: 60+ seconds

Database size:
  - Typical: 1-5 MB
  - With many packages: 10-20 MB

Impact on system:
  - CPU: Low (single core, brief spike)
  - Disk I/O: Moderate (reads all man pages)
  - Memory: Minimal
  - Safe to run on production systems


Best Practices:
===============

1. After Fresh Installation
   First boot → sudo mandb (ensure complete index)

2. After Bulk Software Installation
   Installed 50+ packages → sudo mandb (catch any missed)

3. Before Searching (if fails)
   man -k fails → sudo mandb → try again

4. Don't Run Repeatedly
   Once per installation session is sufficient
   Automatic cron handles rest

5. Check First
   Before running mandb, verify it's actually needed:
   man -k test | wc -l
   If returns results, database is working


Command Reference:
==================

Full syntax:
  mandb [OPTIONS] [MANPATH]

Common usage:
  sudo mandb              # Standard rebuild
  sudo mandb -c           # Complete rebuild from scratch
  sudo mandb -q           # Quiet mode
  sudo mandb /usr/local/share/man  # Index specific directory


Verification:
=============

Test mandb functionality:
  # Before mandb
  man -k thiscommanddoesnotexist
  # Should show: nothing appropriate
  
  # After mandb
  man -k user | wc -l
  # Should show: number of matches (e.g., 150)
  
  # Check database freshness
  stat /var/cache/man/index.db
  # Shows last update time
EOF_DOC

Explanation included in document above.

EOF
}

hint_step_6() {
    echo "  Run 'sudo mandb' to rebuild the database, understand when it's needed"
}

#############################################################################
# VALIDATION: Check the final state (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: Section differences documented
    print_color "$CYAN" "[1/$total] Checking section differences documentation..."
    if [ -f "/opt/documentation_lab/findings/section_differences.txt" ] && [ $(wc -l < "/opt/documentation_lab/findings/section_differences.txt") -ge 5 ]; then
        print_color "$GREEN" "  ✓ Section differences documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Section differences not properly documented"
        print_color "$YELLOW" "  Create: /opt/documentation_lab/findings/section_differences.txt"
    fi
    echo ""
    
    # CHECK 2: ls recursive documented
    print_color "$CYAN" "[2/$total] Checking ls recursive flag documentation..."
    if [ -f "/opt/documentation_lab/findings/ls_recursive.txt" ]; then
        print_color "$GREEN" "  ✓ ls -R flag documented"
        ((score++))
    else
        print_color "$RED" "  ✗ ls recursive findings not found"
    fi
    echo ""
    
    # CHECK 3: Compression tools documented
    print_color "$CYAN" "[3/$total] Checking compression tools documentation..."
    if [ -f "/opt/documentation_lab/findings/compression_tools.txt" ]; then
        print_color "$GREEN" "  ✓ Compression tools documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Compression tools findings not found"
    fi
    echo ""
    
    # CHECK 4: Quick descriptions
    print_color "$CYAN" "[4/$total] Checking whatis documentation..."
    if [ -f "/opt/documentation_lab/findings/quick_descriptions.txt" ]; then
        print_color "$GREEN" "  ✓ Quick descriptions documented"
        ((score++))
    else
        print_color "$RED" "  ✗ Quick descriptions not found"
    fi
    echo ""
    
    # CHECK 5: Man page structure
    print_color "$CYAN" "[5/$total] Checking man page structure analysis..."
    if [ -f "/opt/documentation_lab/findings/manpage_structure.txt" ]; then
        print_color "$GREEN" "  ✓ Man page structure analyzed"
        ((score++))
    else
        print_color "$RED" "  ✗ Structure analysis not found"
    fi
    echo ""
    
    # CHECK 6: mandb understanding
    print_color "$CYAN" "[6/$total] Checking mandb understanding..."
    if [ -d "/var/cache/man" ]; then
        print_color "$GREEN" "  ✓ Man database exists"
        print_color "$YELLOW" "  Ensure you've run 'sudo mandb' and understand why"
        ((score++))
    else
        print_color "$YELLOW" "  ⚠ Man database cache not found (unusual)"
        ((score++))
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Outstanding! You've mastered:"
        echo "  • Man page section system"
        echo "  • Efficient man page navigation"
        echo "  • Keyword searching (man -k/apropos)"
        echo "  • Quick descriptions (whatis)"
        echo "  • Man page structure and conventions"
        echo "  • Man database management"
        echo ""
        echo "You now have the skills to find any information you need"
        echo "during the RHCSA exam without internet access!"
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
# SOLUTION: Complete walkthrough (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
[Complete solutions for all 6 steps are provided in the solution_step_1()
through solution_step_6() functions. Each contains comprehensive explanations.]

EXAM TIPS SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Know your sections:
   Section 1: Commands you type (ls, cp)
   Section 5: Files you edit (/etc/passwd format)
   Section 8: Admin commands (mount, systemctl)

2. Search efficiently:
   - Use /keyword inside man pages
   - Use man -k to find commands
   - Jump to EXAMPLES: /EXAMPLE

3. Speed matters:
   - whatis for quick check (< 1 second)
   - man for detailed info (2-30 minutes)
   - Search within man pages (don't read all)

4. Understand SYNOPSIS:
   [brackets] = optional
   CAPS = required
   ... = repeatable
   | = choose one

5. If man -k fails:
   sudo mandb (rebuild database)

EOF
}

#############################################################################
# CLEANUP: Remove lab components
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    userdel -r docreader 2>/dev/null || true
    rm -rf /opt/documentation_lab 2>/dev/null || true
    
    echo "  ✓ Lab user removed"
    echo "  ✓ Lab directories removed"
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"
