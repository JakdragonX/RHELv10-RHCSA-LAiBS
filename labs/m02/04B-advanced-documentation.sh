#!/bin/bash
# labs/04B-advanced-documentation.sh
# Lab: Advanced Man Page Searching and Info Documentation
# Difficulty: Intermediate
# RHCSA Objective: Locate, read, and use system documentation

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Advanced Man Page Searching and Info Documentation"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure man database is current
    mandb 2>/dev/null || true
    
    # Create test user
    userdel -r researcher 2>/dev/null || true
    useradd -m -s /bin/bash researcher 2>/dev/null || true
    echo "researcher:password123" | chpasswd 2>/dev/null || true
    
    # Create working directory
    rm -rf /opt/advanced_docs 2>/dev/null || true
    mkdir -p /opt/advanced_docs/{research,reference} 2>/dev/null || true
    chown -R researcher:researcher /opt/advanced_docs 2>/dev/null || true
    
    echo "  ✓ Man database updated"
    echo "  ✓ Test user 'researcher' created"
    echo "  ✓ Working directory created"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Commands You'll Use:
  • apropos -a         - Search with AND logic
  • apropos -e         - Exact match search
  • man -K             - Search within man page content
  • man -w             - Show man page file location
  • info               - Read GNU Info documentation
  • /usr/share/doc/    - Package documentation

Info Navigation:
  • Space    - Next screen
  • n        - Next node
  • p        - Previous node
  • u        - Up level
  • q        - Quit
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You need to configure services without internet access. Master advanced
documentation search to find information from system docs alone.

OBJECTIVES:
  1. Use apropos -a for AND logic searches
  2. Use apropos -e for exact matches
  3. Use man -K to search within man pages
  4. Find man page file locations
  5. Navigate info pages
  6. Explore /usr/share/doc

All findings saved to /opt/advanced_docs/
EOF
}

objectives_quick() {
    cat << 'EOF'
  ☐ 1. apropos -a for AND searches
  ☐ 2. apropos -e for exact matches
  ☐ 3. man -K for content search
  ☐ 4. man -w for file locations
  ☐ 5. Navigate info pages
  ☐ 6. Explore /usr/share/doc
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() { echo "6"; }

scenario_context() {
    echo "Master advanced documentation search techniques."
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Use AND logic with apropos

Find commands dealing with BOTH "network" AND "interface".

Requirements:
  • Compare: apropos network (broad)
  • With: apropos -a network interface (focused)
  • Save findings to: /opt/advanced_docs/research/network_tools.txt

Example:
  apropos network | wc -l          # Many results
  apropos -a network interface | wc -l  # Fewer, focused results
EOF
}

validate_step_1() {
    [ -f "/opt/advanced_docs/research/network_tools.txt" ] && \
    [ $(wc -l < "/opt/advanced_docs/research/network_tools.txt") -ge 5 ]
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
# Compare searches
apropos network | wc -l
# Shows 100+ results

apropos -a network interface | wc -l
# Shows 10-20 focused results

# View results
apropos -a network interface

# Save findings
mkdir -p /opt/advanced_docs/research
apropos -a network interface > /opt/advanced_docs/research/network_tools.txt

# Add notes
cat >> /opt/advanced_docs/research/network_tools.txt << 'DOC'

Key commands found:
- ip: Modern interface configuration
- nmcli: NetworkManager CLI
- ifconfig: Legacy tool (deprecated)

AND logic (-a) focuses results by requiring ALL keywords.
DOC

EXPLANATION:
  • apropos keyword: Searches descriptions
  • -a flag: AND logic (all keywords must match)
  • More focused than single keyword
  • Better than piping to grep

Common patterns:
  apropos -a disk partition
  apropos -a user password
  apropos -a network configure
EOF
}

hint_step_1() {
    echo "  Use: apropos -a network interface"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Use exact match searching

Find commands that start with "user" exactly.

Requirements:
  • Use: apropos -e '^user'
  • ^ means "starts with"
  • Compare with: apropos user (finds "username", "userspace", etc.)
  • Save to: /opt/advanced_docs/research/user_commands.txt

Example:
  apropos user           # Finds partial matches
  apropos -e '^user'     # Only commands starting with "user"
EOF
}

validate_step_2() {
    [ -f "/opt/advanced_docs/research/user_commands.txt" ] && \
    [ $(wc -l < "/opt/advanced_docs/research/user_commands.txt") -ge 3 ]
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
# Partial match (many results)
apropos user

# Exact match (focused)
apropos -e '^user'

# Save findings
apropos -e '^user' > /opt/advanced_docs/research/user_commands.txt

# Add documentation
cat >> /opt/advanced_docs/research/user_commands.txt << 'DOC'

Commands found starting with "user":
- useradd: Create new user
- userdel: Delete user
- usermod: Modify user
- userdbctl: User database control (systemd)

Regex patterns:
  ^user  - Starts with "user"
  user$  - Ends with "user"
  ^user.*mod - Starts with user, contains mod
DOC

EXPLANATION:
  • -e enables regex/exact matching
  • ^ = starts with
  • $ = ends with
  • .* = any characters
  
Useful patterns:
  apropos -e '^net'     # Commands starting with "net"
  apropos -e 'config$'  # Commands ending with "config"
EOF
}

hint_step_2() {
    echo "  Use: apropos -e '^user'"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Search within man page content

Use man -K to search INSIDE all man pages for specific text.

Requirements:
  • Use: man -K "configuration file"
  • This searches actual man page content (slow!)
  • Press 'q' to skip pages you don't want
  • Find at least 2 relevant man pages
  • Save to: /opt/advanced_docs/research/config_pages.txt

Warning: This is SLOW but very powerful when you don't know the command name.

Example:
  man -K "force unmount"  # Finds umount, fusermount, etc.
EOF
}

validate_step_3() {
    [ -f "/opt/advanced_docs/research/config_pages.txt" ]
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
# Search all man pages (SLOW - be patient!)
man -K "configuration file"
# Press 'q' to skip through results
# Press Ctrl+C to stop search

# Document findings
cat > /opt/advanced_docs/research/config_pages.txt << 'DOC'
MAN -K SEARCH RESULTS
=====================

Search term: "configuration file"

Pages found:
1. sshd_config(5) - SSH daemon configuration
   Location: /etc/ssh/sshd_config
   
2. httpd.conf(5) - Apache config (if installed)
   Location: /etc/httpd/conf/httpd.conf
   
3. rsyslog.conf(5) - System logging config
   Location: /etc/rsyslog.conf

WHY man -K IS USEFUL:
- Don't need to know exact command name
- Searches ALL man page text
- Finds related commands you didn't know existed
-When to use:
  * You know what you want to do but not the command
  * Looking for config file locations
  * Finding all commands related to a concept

DOWNSIDE:
- Very slow (searches thousands of pages)
- Can take 30+ seconds
- Use Ctrl+C to stop if taking too long

BETTER ALTERNATIVES (if you know more):
- apropos with keywords
- grep through /usr/share/doc
- Check package documentation
DOC

EXPLANATION:
  • man -K: Searches full text of ALL man pages
  • -K (capital): Full content search
  • -k (lowercase): Same as apropos (descriptions only)
  
Use cases:
  • "I need to configure X but don't know the command"
  • "Where is the config file for Y?"
  • "What commands deal with Z concept?"

Example searches:
  man -K "network interface"
  man -K "user password"
  man -K "mount options"
EOF
}

hint_step_3() {
    echo "  Use: man -K 'configuration file' (be patient, it's slow!)"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Find man page file locations

Use man -w to see where man page files are actually stored.

Requirements:
  • Find location of: ls, systemctl, passwd
  • Use: man -w command
  • Use: man -wa passwd (shows ALL sections)
  • Note: Files are compressed (.gz)
  • Save to: /opt/advanced_docs/research/manpage_locations.txt

Example:
  man -w ls           # Shows: /usr/share/man/man1/ls.1.gz
  man -wa passwd      # Shows ALL sections of passwd
EOF
}

validate_step_4() {
    [ -f "/opt/advanced_docs/research/manpage_locations.txt" ]
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
# Find single man page
man -w ls
# Output: /usr/share/man/man1/ls.1.gz

# Find all sections
man -wa passwd
# Output: /usr/share/man/man1/passwd.1.gz
#         /usr/share/man/man5/passwd.5.gz

# Document findings
cat > /opt/advanced_docs/research/manpage_locations.txt << 'DOC'
MAN PAGE FILE LOCATIONS
=======================

Command: man -w COMMAND

Results:
--------
ls:
  /usr/share/man/man1/ls.1.gz
  Section 1: User commands
  
systemctl:
  /usr/share/man/man1/systemctl.1.gz
  Section 1: User commands
  
passwd (multiple sections):
  /usr/share/man/man1/passwd.1.gz  - passwd command
  /usr/share/man/man5/passwd.5.gz  - /etc/passwd file format

FILE FORMAT:
  /usr/share/man/man[section]/command.[section].gz
  
  Example: ls.1.gz
    - ls = command name
    - 1 = section number
    - .gz = gzip compressed

SECTIONS:
  1: User commands
  5: File formats
  8: System admin commands

WHY THIS MATTERS:
- Understand man page organization
- Can view raw files if needed: zcat /path/to/man.gz
- Troubleshoot missing man pages
- Create custom man pages in same format

VIEW RAW:
  zcat /usr/share/man/man1/ls.1.gz | less
  # Shows the unformatted man page source
DOC

EXPLANATION:
  • man -w: Shows file location
  • man -wa: Shows ALL sections
  • .gz extension: Compressed with gzip
  • Section numbers in filename and path
  
View raw man page:
  zcat $(man -w ls) | less
  # Decompress and view source

Man page sections:
  1: User commands
  2: System calls
  3: Library functions
  4: Special files
  5: File formats
  6: Games
  7: Miscellaneous
  8: Admin commands
  9: Kernel routines
EOF
}

hint_step_4() {
    echo "  Use: man -w ls, man -wa passwd"
}

# STEP 5
show_step_5() {
    cat << 'EOF'
TASK: Navigate GNU Info documentation

Info pages provide more detailed docs for GNU utilities than man pages.

Requirements:
  • Open: info coreutils
  • Navigate using: n (next), p (previous), u (up)
  • Find the 'ls' section
  • Compare: info ls vs man ls
  • Save comparison to: /opt/advanced_docs/research/info_vs_man.txt

Navigation:
  Space      - Next screen
  Backspace  - Previous screen
  n          - Next node
  p          - Previous node
  u          - Up to parent
  Tab        - Next hyperlink
  Enter      - Follow link
  q          - Quit
EOF
}

validate_step_5() {
    [ -f "/opt/advanced_docs/research/info_vs_man.txt" ]
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
# Open info for coreutils
info coreutils
# Navigate with: n, p, u, Tab, Enter, q

# View specific command
info ls
# Often more detailed than man page

# Create comparison document
cat > /opt/advanced_docs/research/info_vs_man.txt << 'DOC'
INFO vs MAN PAGES
=================

Tested with: ls command

MAN PAGE (man ls):
------------------
- Concise, focused documentation
- Organized by OPTIONS, DESCRIPTION, EXAMPLES
- Quick reference style
- Traditional Unix format
- Works for all commands

INFO PAGE (info ls):
--------------------
- More detailed explanations
- Hyperlinked navigation
- Organized hierarchically
- Better examples and context
- Only for GNU utilities

KEY DIFFERENCES:
----------------
Format:
  man: Flat, scrollable document
  info: Hierarchical, node-based

Navigation:
  man: Space, arrows, /search, q
  info: n/p/u, Tab/Enter, q

Detail Level:
  man: Concise reference
  info: Tutorial + reference

Coverage:
  man: All Unix/Linux commands
  info: Primarily GNU tools

WHEN TO USE WHICH:
------------------
Use man when:
  - Quick option reference
  - Non-GNU commands
  - Just need syntax
  
Use info when:
  - Learning new GNU tool
  - Need detailed examples
  - Want conceptual explanations
  - Following tutorial-style docs

RHCSA RELEVANCE:
----------------
Exam likely uses man pages (more universal), but knowing
info exists shows documentation awareness.

GNU tools with good info pages:
  - coreutils (ls, cp, mv, etc.)
  - bash
  - tar
  - grep, sed, awk
  - gzip

NAVIGATION REMINDER:
  n: next node
  p: previous node
  u: up one level
  l: last visited
  Tab: next hyperlink
  Enter: follow hyperlink
  q: quit
DOC

EXPLANATION:
  • Info: GNU's documentation system
  • More detailed than man for GNU tools
  • Hierarchical organization
  • Hyperlinked navigation
  
Common GNU tools:
  info coreutils  # ls, cp, mv, mkdir, etc.
  info bash       # Bash shell
  info tar        # tar command
  info grep       # grep command

Info is especially good for:
  - Complex GNU utilities
  - Learning new tools
  - Understanding concepts
  - Following tutorials
EOF
}

hint_step_5() {
    echo "  Use: info coreutils, navigate with n/p/u, compare with man ls"
}

# STEP 6
show_step_6() {
    cat << 'EOF'
TASK: Explore package documentation

/usr/share/doc contains READMEs, examples, and additional docs.

Requirements:
  • List: ls /usr/share/doc
  • Pick a package (bash, systemd, openssh-server, etc.)
  • Explore: README, examples/ subdirectory
  • Find example configuration files
  • Save findings to: /opt/advanced_docs/reference/package_docs.txt

Example:
  ls /usr/share/doc/bash/
  cat /usr/share/doc/bash/README
  ls /usr/share/doc/openssh/examples/
EOF
}

validate_step_6() {
    [ -d "/opt/advanced_docs/reference" ] && \
    [ $(ls -1 /opt/advanced_docs/reference 2>/dev/null | wc -l) -gt 0 ]
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
# List available packages
ls /usr/share/doc | head -20

# Explore bash documentation
ls -la /usr/share/doc/bash*/

# View README files
find /usr/share/doc/bash* -name "README*" -exec cat {} \;

# Find example configs
find /usr/share/doc -name "*.conf.example" -o -name "examples" -type d

# Document findings
cat > /opt/advanced_docs/reference/package_docs.txt << 'DOC'
PACKAGE DOCUMENTATION EXPLORATION
==================================

Location: /usr/share/doc/

Packages Explored:
------------------

1. BASH (/usr/share/doc/bash-*)
   Files found:
   - README: General information
   - CHANGES: Version history
   - FAQ: Frequently asked questions
   - examples/: Sample scripts
   
   Useful for: Learning bash features, finding script examples

2. SYSTEMD (/usr/share/doc/systemd/)
   Files found:
   - README: Systemd overview
   - examples/: Unit file examples
   - Documentation links
   
   Useful for: Creating custom services, understanding systemd

3. OPENSSH (/usr/share/doc/openssh-server/)
   Files found:
   - README: SSH server info
   - sshd_config.example: Example configuration
   
   Useful for: SSH server configuration examples

COMMON FILE TYPES:
------------------
- README / README.md: Package overview
- INSTALL: Installation instructions
- CHANGES / ChangeLog: Version history
- LICENSE / COPYING: License information
- examples/: Sample configurations
- *.conf.example: Example config files

WHY THIS MATTERS:
-----------------
- Man pages don't always have full examples
- Configuration examples save time
- READMEs explain package-specific details
- Some packages have extensive docs here

RHCSA USE CASES:
----------------
Task: "Configure SSH server to disable root login"
Steps:
  1. Check man sshd_config for options
  2. Look at /usr/share/doc/openssh*/sshd_config.example
  3. See working examples with explanations
  4. Apply to /etc/ssh/sshd_config

Task: "Create a systemd service"
Steps:
  1. Check man systemd.service
  2. Look at /usr/share/doc/systemd/examples/
  3. Copy and modify example unit file
  4. Place in /etc/systemd/system/

FINDING EXAMPLES:
-----------------
# Find all example configs
find /usr/share/doc -name "*.example" -o -name "*.sample"

# Find README files
find /usr/share/doc -name "README*"

# Find examples directories
find /usr/share/doc -type d -name "examples"

# Search for specific topic
grep -r "disable root" /usr/share/doc/openssh* 2>/dev/null
DOC

# Create reference for common packages
cat > /opt/advanced_docs/reference/useful_doc_locations.txt << 'DOC'
QUICK REFERENCE: USEFUL DOC LOCATIONS
======================================

Network:
  /usr/share/doc/NetworkManager/
  /usr/share/doc/openssh*/
  /usr/share/doc/firewalld/

System:
  /usr/share/doc/systemd/
  /usr/share/doc/bash*/
  /usr/share/doc/coreutils/

Security:
  /usr/share/doc/selinux-policy/
  /usr/share/doc/sudo/
  /usr/share/doc/pam*/

Storage:
  /usr/share/doc/lvm2/
  /usr/share/doc/mdadm/
  /usr/share/doc/nfs-utils/
DOC

EXPLANATION:
  • /usr/share/doc: Package documentation directory
  • Each package has its own subdirectory
  • Contains files not in man pages
  • Often has practical examples
  
Typical structure:
  /usr/share/doc/[package]/
    ├── README
    ├── CHANGES
    ├── LICENSE
    ├── examples/
    │   ├── config1.conf.example
    │   └── config2.conf.example
    └── ...

Best practices:
  1. Check man pages first (quick reference)
  2. Check /usr/share/doc for examples
  3. Check /etc/ for default configs
  4. Combine all three for full understanding
EOF
}

hint_step_6() {
    echo "  Explore: ls /usr/share/doc, find README and examples"
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=6
    
    echo "Checking your research..."
    echo ""
    
    for i in {1..6}; do
        print_color "$CYAN" "[$i/$total] Checking step $i..."
        if validate_step_$i 2>/dev/null; then
            print_color "$GREEN" "  ✓ Step $i complete"
            ((score++))
        else
            print_color "$RED" "  ✗ Step $i incomplete"
        fi
        echo ""
    done
    
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You've mastered:"
        echo "  • apropos -a for focused searches"
        echo "  • apropos -e for exact matching"
        echo "  • man -K for desperate searches"
        echo "  • man -w for file locations"
        echo "  • info page navigation"
        echo "  • /usr/share/doc exploration"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total)"
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTIONS
==================

See individual solution_step_N() functions for detailed solutions.

QUICK REFERENCE:
----------------
1. AND logic:     apropos -a network interface
2. Exact match:   apropos -e '^user'
3. Content search: man -K "configuration file"
4. File location: man -w ls, man -wa passwd
5. Info pages:    info coreutils, navigate with n/p/u
6. Package docs:  ls /usr/share/doc, find READMEs and examples

KEY TAKEAWAYS:
--------------
• apropos -a: Focused searches (AND logic)
• man -K: When desperate (searches all content)
• info: Better than man for GNU tools
• /usr/share/doc: Examples not in man pages

EXAM STRATEGY:
--------------
1. Start with: apropos [keywords]
2. If too many results: apropos -a [key1] [key2]
3. Still stuck: man -K "what you want to do"
4. Need examples: check /usr/share/doc/[package]/
5. GNU tool: try info [command]
EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up..."
    userdel -r researcher 2>/dev/null || true
    rm -rf /opt/advanced_docs 2>/dev/null || true
    echo "  ✓ Cleanup complete"
}

# Execute
main "$@"
