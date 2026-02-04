#!/bin/bash
# labs/m04/16C-systemd-tmpfiles.sh
# Lab: Managing Temporary Files with systemd-tmpfiles
# Difficulty: Intermediate
# RHCSA Objective: 16.5 - Managing temporary files

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing Temporary Files with systemd-tmpfiles"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="35-45 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure systemd-tmpfiles service components are present
    systemctl daemon-reload
    
    # Create lab directory
    mkdir -p /opt/lab-tmpfiles
    
    # Clean up any previous lab configurations
    rm -f /etc/tmpfiles.d/lab-*.conf 2>/dev/null || true
    rm -f /run/tmpfiles.d/lab-*.conf 2>/dev/null || true
    
    # Clean up previous lab directories and files
    rm -rf /run/lab-app 2>/dev/null || true
    rm -rf /var/lib/lab-data 2>/dev/null || true
    rm -rf /tmp/lab-cache 2>/dev/null || true
    rm -rf /run/lab-service 2>/dev/null || true
    
    # Remove test user if exists
    userdel -r appuser 2>/dev/null || true
    
    # Create test user for tmpfiles configuration
    useradd -r -s /sbin/nologin appuser 2>/dev/null || true
    
    echo "  ✓ Previous lab configurations removed"
    echo "  ✓ Lab directories cleaned"
    echo "  ✓ Test user (appuser) created"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of systemd basics
  • Familiarity with file permissions and ownership
  • Knowledge of temporary file locations (/tmp, /run, /var/tmp)
  • Understanding of system services

Commands You'll Use:
  • systemd-tmpfiles --create - Create files/directories from configs
  • systemd-tmpfiles --clean - Clean up old temporary files
  • systemd-tmpfiles --remove - Remove files/directories
  • systemctl status systemd-tmpfiles-clean.timer - Check cleanup timer
  • systemctl status systemd-tmpfiles-setup.service - Check setup service

Files You'll Interact With:
  • /usr/lib/tmpfiles.d/ - System-provided tmpfiles configurations
  • /etc/tmpfiles.d/ - Administrator-created configurations (priority)
  • /run/tmpfiles.d/ - Runtime configurations
  • /tmp/ - Temporary files (cleared on reboot in some configs)
  • /run/ - Runtime data (cleared on reboot)
  • /var/tmp/ - Temporary files (preserved across reboots)

Key Concepts:
  • systemd-tmpfiles manages temporary file creation and cleanup
  • Configuration files use specific type codes (d, D, L, etc.)
  • Files in /etc/tmpfiles.d/ override /usr/lib/tmpfiles.d/
  • Age-based automatic cleanup prevents disk space issues
  • systemd-tmpfiles-clean.timer runs cleanup periodically

Reference Material:
  • man tmpfiles.d - Configuration file format
  • man systemd-tmpfiles - Command usage
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're managing a RHEL 10 server running multiple applications that create
temporary files and runtime directories. Applications need specific directories
created at boot with proper permissions, and old temporary files must be
cleaned up automatically to prevent disk space issues.

BACKGROUND:
The systemd-tmpfiles mechanism provides a robust way to manage temporary files,
runtime directories, and automated cleanup. It replaces old init scripts and
manual cron jobs for temporary file management. Understanding tmpfiles.d is
essential for the RHCSA exam and real-world system administration.

OBJECTIVES:
  1. Explore existing tmpfiles configuration
     • View system-provided tmpfiles configurations
     • Check systemd-tmpfiles services and timers
     • Understand tmpfiles.d type codes
     • View cleanup timer schedule
     • Learn configuration file priority
     
  2. Create runtime directory for an application
     • Create config: /etc/tmpfiles.d/lab-app.conf
     • Create directory: /run/lab-app
     • Owner: appuser:appuser
     • Permissions: 0755
     • Type: d (create directory if needed)
     • Test with systemd-tmpfiles --create
     
  3. Create persistent data directory with cleanup
     • Create config: /etc/tmpfiles.d/lab-data.conf
     • Create directory: /var/lib/lab-data
     • Owner: root:root
     • Permissions: 0750
     • Type: D (create and clean old files)
     • Age: Files older than 30 days are removed
     • Test creation and understand cleanup behavior
     
  4. Create temporary cache with automatic cleanup
     • Create config: /etc/tmpfiles.d/lab-cache.conf
     • Create directory: /tmp/lab-cache
     • Permissions: 1777 (sticky bit)
     • Type: D (create and clean)
     • Age: 7 days (7d)
     • Understand cleanup behavior (note: actual cleanup testing
       requires files to naturally age due to ctime limitations)

HINTS:
  • Type codes: d=create dir, D=create+clean, z=set permissions
  • Age format: 7d (7 days), 12h (12 hours), 30d (30 days)
  • Use - for "no age limit" or when age doesn't apply
  • Format: Type Path Mode User Group Age Argument
  • systemd-tmpfiles --create applies configurations
  • systemd-tmpfiles --clean removes old files based on age
  • Note: Cleanup checks atime, mtime, AND ctime (most recent wins)

SUCCESS CRITERIA:
  • All three tmpfiles configurations created correctly
  • Directories created with proper ownership and permissions
  • systemd-tmpfiles commands execute successfully
  • Configuration files follow proper syntax
  • Can verify configurations with systemd-tmpfiles --create
  • Understand cleanup behavior (actual testing requires natural aging)
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Explore existing tmpfiles.d configuration
  ☐ 2. Create runtime directory (/run/lab-app)
  ☐ 3. Create persistent directory with cleanup (/var/lib/lab-data)
  ☐ 4. Create temp cache with age-based cleanup (/tmp/lab-cache)
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "4"
}

scenario_context() {
    cat << 'EOF'
You're configuring systemd-tmpfiles to manage temporary directories and
automated cleanup for applications on a RHEL server.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Explore existing tmpfiles configuration and understand the system

Before creating configurations, understand how systemd-tmpfiles works
and examine existing configurations.

Requirements:
  • View system tmpfiles configurations
  • Check systemd-tmpfiles services and timers
  • Understand the cleanup schedule
  • Learn tmpfiles.d type codes
  • Understand configuration file locations

Questions to explore:
  • What tmpfiles configurations exist on the system?
  • When does automatic cleanup run?
  • What are the common type codes?
  • What's the configuration file format?
  • What's the priority order for configuration files?

Key commands to use:
  ls /usr/lib/tmpfiles.d/
  ls /etc/tmpfiles.d/
  cat /usr/lib/tmpfiles.d/tmp.conf
  systemctl status systemd-tmpfiles-clean.timer
  systemctl list-timers systemd-tmpfiles-clean.timer
  man tmpfiles.d

Common type codes to know:
  d - Create directory if doesn't exist
  D - Create directory and clean old files
  L - Create symlink
  z - Set ownership/permissions (don't create)
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  View configs: ls /usr/lib/tmpfiles.d/"
    echo "  Check timer: systemctl status systemd-tmpfiles-clean.timer"
    echo "  Read example: cat /usr/lib/tmpfiles.d/tmp.conf"
    echo "  Learn codes: man tmpfiles.d"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
View system tmpfiles configurations:
  ls -l /usr/lib/tmpfiles.d/

Shows system-provided configurations like:
  - tmp.conf (manages /tmp cleanup)
  - systemd.conf (systemd runtime directories)
  - x11.conf (X11 temporary files)

View administrator configurations:
  ls -l /etc/tmpfiles.d/

This directory is where you create custom configs.
Files here override /usr/lib/tmpfiles.d/ with same name.

View runtime configurations:
  ls -l /run/tmpfiles.d/

Check an example configuration:
  cat /usr/lib/tmpfiles.d/tmp.conf

Shows entries like:
  # Clear tmp directories separately
  D /tmp 1777 root root 10d
  D /var/tmp 1777 root root 30d

Check cleanup timer:
  systemctl status systemd-tmpfiles-clean.timer
  systemctl list-timers systemd-tmpfiles-clean.timer

Shows when cleanup will next run.

Check cleanup service:
  systemctl status systemd-tmpfiles-clean.service

View setup service:
  systemctl status systemd-tmpfiles-setup.service

This runs at boot to create directories.

Understanding tmpfiles.d format:

Basic syntax:
  Type Path Mode User Group Age Argument

Example:
  d /run/myapp 0755 myuser mygroup -

Breaking it down:
  d           - Type code (create directory)
  /run/myapp  - Path to create
  0755        - Permissions (octal)
  myuser      - Owner
  mygroup     - Group
  -           - Age (- means no cleanup based on age)

Common type codes:

d - Create directory
    Example: d /run/app 0755 root root -
    Creates directory if it doesn't exist
    Does NOT remove old files

D - Create directory and clean old files
    Example: D /tmp/cache 1777 root root 7d
    Creates directory if needed
    Removes files older than 7 days

L - Create symlink
    Example: L /run/current -> /run/app-1.2.3
    Creates symbolic link

z - Adjust ownership/permissions only
    Example: z /var/lib/app 0750 appuser appgroup -
    Sets ownership and permissions
    Does NOT create if missing

x - Ignore path (exclude from cleanup)
    Example: x /tmp/important
    Prevents cleanup of this path

r - Remove path
    Example: r /tmp/oldfile
    Removes file or directory

R - Recursively remove path
    Example: R /tmp/olddir
    Removes directory and contents

Age format:

Age specifications:
  7d     - 7 days
  12h    - 12 hours
  30d    - 30 days
  1w     - 1 week
  -      - No age limit (never clean)
  0      - Clean immediately

Age applies to:
  - D type (directory with cleanup)
  - Files inside the directory
  - Based on atime, mtime, AND ctime (most recent)

Configuration file priority:

Priority order (highest to lowest):
  1. /etc/tmpfiles.d/*.conf
  2. /run/tmpfiles.d/*.conf
  3. /usr/lib/tmpfiles.d/*.conf

If same filename in multiple locations:
  - /etc/tmpfiles.d/ wins
  - Lower priority files ignored
  - Use this to override system configs

Naming convention:
  - Files must end in .conf
  - Processed in lexical order
  - Use numeric prefixes for ordering
    Example: 10-myapp.conf, 20-database.conf

systemd-tmpfiles services:

systemd-tmpfiles-setup.service:
  - Runs at boot
  - Creates directories and files
  - Sets permissions
  - Part of boot process

systemd-tmpfiles-clean.service:
  - Runs periodically
  - Cleans old files based on age
  - Triggered by timer

systemd-tmpfiles-clean.timer:
  - Runs cleanup service
  - Default: 15 minutes after boot, then daily
  - Prevents disk space issues

View timer schedule:
  systemctl cat systemd-tmpfiles-clean.timer

Shows:
  [Timer]
  OnBootSec=15min
  OnUnitActiveSec=1d

Meaning:
  - Runs 15 min after boot
  - Then runs daily (1d)

Manual tmpfiles operations:

Create directories/files:
  systemd-tmpfiles --create

This processes all configs and creates directories.

Clean old files:
  systemd-tmpfiles --clean

Removes files older than specified age.

Remove specific config:
  systemd-tmpfiles --remove --prefix=/run/myapp

Test configuration:
  systemd-tmpfiles --create --prefix=/run/myapp

Creates only paths starting with /run/myapp.

Common tmpfiles.d use cases:

Use case 1: Application runtime directory
  d /run/myapp 0755 myappuser myappgroup -
  Creates runtime directory at boot

Use case 2: Cache with automatic cleanup
  D /var/cache/myapp 0750 root root 30d
  Creates cache, removes files older than 30 days

Use case 3: Temporary workspace
  D /tmp/myapp 1777 root root 1d
  Sticky bit, cleaned daily

Use case 4: Symlink for current version
  L /opt/app/current - - - - /opt/app/v2.1.0
  Always points to current version

Temporary file locations:

/tmp/:
  - Cleared on reboot (typical)
  - Short-term temporary files
  - World-writable (1777)
  - Often has 10-day cleanup

/run/:
  - Always cleared on reboot
  - Runtime data
  - Services, PIDs, sockets
  - RAM-based (tmpfs)

/var/tmp/:
  - Preserved across reboots
  - Longer-term temporary files
  - Often has 30-day cleanup

EOF
}

hint_step_2() {
    echo "  Create: /etc/tmpfiles.d/lab-app.conf"
    echo "  Format: d /run/lab-app 0755 appuser appuser -"
    echo "  Apply: systemd-tmpfiles --create --prefix=/run/lab-app"
    echo "  Verify: ls -ld /run/lab-app"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create runtime directory for an application

Create a tmpfiles configuration to automatically create an application
runtime directory.

Requirements:
  • Create file: /etc/tmpfiles.d/lab-app.conf
  • Type: d (create directory)
  • Path: /run/lab-app
  • Mode: 0755
  • Owner: appuser
  • Group: appuser
  • Age: - (no cleanup)
  
  • After creating config, apply it with:
    systemd-tmpfiles --create --prefix=/run/lab-app
  
  • Verify directory was created
  • Check ownership and permissions

Configuration line format:
  d /run/lab-app 0755 appuser appuser -

Explanation:
  d         - Create directory if doesn't exist
  /run/lab-app - Path to create
  0755      - Permissions (rwxr-xr-x)
  appuser   - Owner user
  appuser   - Owner group
  -         - No age-based cleanup

The /run directory is cleared on reboot, so this ensures
the directory is recreated at boot time.
EOF
}

validate_step_2() {
    local failures=0
    
    # Check if config file exists
    if [ ! -f /etc/tmpfiles.d/lab-app.conf ]; then
        echo ""
        print_color "$RED" "✗ /etc/tmpfiles.d/lab-app.conf not found"
        ((failures++))
        return 1
    fi
    
    # Check config file contains correct entry
    if ! grep -qE "^d[[:space:]]+/run/lab-app[[:space:]]+0?755[[:space:]]+appuser[[:space:]]+appuser" /etc/tmpfiles.d/lab-app.conf; then
        echo ""
        print_color "$RED" "✗ Configuration entry incorrect or missing"
        echo "  Expected: d /run/lab-app 0755 appuser appuser -"
        echo "  Your file contains:"
        cat /etc/tmpfiles.d/lab-app.conf
        ((failures++))
    fi
    
    # Try to create the directory using tmpfiles
    systemd-tmpfiles --create --prefix=/run/lab-app >/dev/null 2>&1
    
    # Check if directory was created
    if [ ! -d /run/lab-app ]; then
        echo ""
        print_color "$RED" "✗ Directory /run/lab-app was not created"
        echo "  Run: systemd-tmpfiles --create --prefix=/run/lab-app"
        ((failures++))
    fi
    
    # Check ownership
    if [ -d /run/lab-app ]; then
        local owner=$(stat -c '%U' /run/lab-app)
        local group=$(stat -c '%G' /run/lab-app)
        
        if [ "$owner" != "appuser" ]; then
            echo ""
            print_color "$RED" "✗ Directory owner is $owner (expected appuser)"
            ((failures++))
        fi
        
        if [ "$group" != "appuser" ]; then
            echo ""
            print_color "$RED" "✗ Directory group is $group (expected appuser)"
            ((failures++))
        fi
    fi
    
    # Check permissions
    if [ -d /run/lab-app ]; then
        local perms=$(stat -c '%a' /run/lab-app)
        if [ "$perms" != "755" ]; then
            echo ""
            print_color "$RED" "✗ Directory permissions are $perms (expected 755)"
            ((failures++))
        fi
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Create the tmpfiles configuration
───────────────────────────────────────────
sudo vi /etc/tmpfiles.d/lab-app.conf

Add this line:

d /run/lab-app 0755 appuser appuser -

Step 2: Save the file
─────────────────────
ESC, then :wq

Step 3: Apply the configuration
────────────────────────────────
sudo systemd-tmpfiles --create --prefix=/run/lab-app

This creates the directory immediately.

Step 4: Verify the directory
─────────────────────────────
ls -ld /run/lab-app

Should show:
  drwxr-xr-x. 2 appuser appuser 40 Feb  3 14:23 /run/lab-app

Check with stat:
  stat /run/lab-app

Understanding the configuration:

Entry breakdown:
  d /run/lab-app 0755 appuser appuser -

  d - Type code
      Creates directory if it doesn't exist
      Won't create parent directories (use d+ for that)
      Won't remove old files
  
  /run/lab-app - Absolute path
      Must be absolute path
      /run is runtime directory (tmpfs)
      Cleared on reboot
  
  0755 - Permissions
      Owner: rwx (read, write, execute)
      Group: r-x (read, execute)
      Other: r-x (read, execute)
  
  appuser - Owner user
      Must exist on system
      Created in lab setup
  
  appuser - Owner group
      Must exist on system
      Can be different from user
  
  - - No age limit
      Directory won't be removed based on age
      Contents also won't be cleaned
      Use D instead of d for cleanup

Why use tmpfiles for /run directories:

Problem:
  - /run is tmpfs (RAM-based)
  - Cleared on every reboot
  - Applications need directories to exist

Solution:
  - tmpfiles.d creates them at boot
  - systemd-tmpfiles-setup.service runs early
  - Directories ready before apps start

Alternative approaches:

Wrong approach:
  mkdir /run/lab-app
  chown appuser:appuser /run/lab-app
  
  Problem: Lost on reboot!

Right approach:
  tmpfiles.d configuration
  
  Benefit: Recreated automatically

When directory is created:

At boot time:
  systemd-tmpfiles-setup.service runs
  Processes all .conf files
  Creates directories

Manual creation:
  systemd-tmpfiles --create
  Or with --prefix to target specific paths

Testing the configuration:

View what would be created:
  systemd-tmpfiles --create --dry-run

Create only specific prefix:
  systemd-tmpfiles --create --prefix=/run/lab-app

Remove and recreate:
  rm -rf /run/lab-app
  systemd-tmpfiles --create --prefix=/run/lab-app

Common mistakes:

Mistake 1: Wrong permissions format
  Wrong: d /run/lab-app rwxr-xr-x appuser appuser -
  Right: d /run/lab-app 0755 appuser appuser -
  
  Use octal notation, not symbolic

Mistake 2: Relative path
  Wrong: d run/lab-app 0755 appuser appuser -
  Right: d /run/lab-app 0755 appuser appuser -
  
  Must be absolute path

Mistake 3: User doesn't exist
  Error: Failed to resolve user 'nonexistent'
  Fix: Create user first or use existing user

Mistake 4: Forgetting to apply
  Create config file
  Nothing happens!
  
  Must run: systemd-tmpfiles --create

EOF
}

hint_step_3() {
    echo "  Create: /etc/tmpfiles.d/lab-data.conf"
    echo "  Format: D /var/lib/lab-data 0750 root root 30d"
    echo "  Type D enables cleanup of old files"
    echo "  Apply: systemd-tmpfiles --create --prefix=/var/lib/lab-data"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Create persistent data directory with automatic cleanup

Create a configuration for a persistent directory that automatically
removes files older than 30 days.

Requirements:
  • Create file: /etc/tmpfiles.d/lab-data.conf
  • Type: D (create directory and enable cleanup)
  • Path: /var/lib/lab-data
  • Mode: 0750
  • Owner: root
  • Group: root
  • Age: 30d (30 days)
  
  • Apply the configuration
  • Verify directory creation
  • Understand cleanup behavior

Configuration line:
  D /var/lib/lab-data 0750 root root 30d

Key difference from previous step:
  • Type D (not d) enables age-based cleanup
  • Files older than 30 days will be removed
  • When systemd-tmpfiles-clean.service runs
  • Based on atime, mtime, AND ctime (most recent wins)

The D type:
  • Creates directory if doesn't exist (like d)
  • Also removes files older than specified age
  • Cleanup runs via systemd-tmpfiles-clean.timer
  • Default: 15 min after boot, then daily
EOF
}

validate_step_3() {
    local failures=0
    
    # Check if config file exists
    if [ ! -f /etc/tmpfiles.d/lab-data.conf ]; then
        echo ""
        print_color "$RED" "✗ /etc/tmpfiles.d/lab-data.conf not found"
        ((failures++))
        return 1
    fi
    
    # Check config file contains correct entry with type D and age
    if ! grep -qE "^D[[:space:]]+/var/lib/lab-data[[:space:]]+0?750[[:space:]]+root[[:space:]]+root[[:space:]]+30d" /etc/tmpfiles.d/lab-data.conf; then
        echo ""
        print_color "$RED" "✗ Configuration entry incorrect or missing"
        echo "  Expected: D /var/lib/lab-data 0750 root root 30d"
        echo "  Your file contains:"
        cat /etc/tmpfiles.d/lab-data.conf
        ((failures++))
    fi
    
    # Try to create the directory
    systemd-tmpfiles --create --prefix=/var/lib/lab-data >/dev/null 2>&1
    
    # Check if directory was created
    if [ ! -d /var/lib/lab-data ]; then
        echo ""
        print_color "$RED" "✗ Directory /var/lib/lab-data was not created"
        ((failures++))
    fi
    
    # Check permissions
    if [ -d /var/lib/lab-data ]; then
        local perms=$(stat -c '%a' /var/lib/lab-data)
        if [ "$perms" != "750" ]; then
            echo ""
            print_color "$RED" "✗ Directory permissions are $perms (expected 750)"
            ((failures++))
        fi
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Create the tmpfiles configuration
───────────────────────────────────────────
sudo vi /etc/tmpfiles.d/lab-data.conf

Add this line:

D /var/lib/lab-data 0750 root root 30d

Step 2: Save the file
─────────────────────
ESC, then :wq

Step 3: Apply the configuration
────────────────────────────────
sudo systemd-tmpfiles --create --prefix=/var/lib/lab-data

Step 4: Verify the directory
─────────────────────────────
ls -ld /var/lib/lab-data

Should show:
  drwxr-x---. 2 root root 40 Feb  3 14:25 /var/lib/lab-data

Understanding Type D vs Type d:

Type d (no cleanup):
  d /run/lab-app 0755 appuser appuser -
  
  Behavior:
    - Creates directory if missing
    - Does NOT remove old files
    - Age field should be -
    - Directory persists indefinitely

Type D (with cleanup):
  D /var/lib/lab-data 0750 root root 30d
  
  Behavior:
    - Creates directory if missing
    - Removes files older than 30 days
    - Age field specifies threshold
    - Automatic cleanup via timer

When cleanup happens:

Cleanup service:
  systemd-tmpfiles-clean.service
  
  Triggered by:
    systemd-tmpfiles-clean.timer
  
  Schedule:
    - 15 minutes after boot
    - Then once per day
    
  Check schedule:
    systemctl list-timers systemd-tmpfiles-clean.timer

What gets cleaned:

Files in the directory:
  - Regular files
  - Based on atime, mtime, AND ctime (most recent wins)
  - Older than specified age (30d)
  - Subdirectories also checked

What doesn't get cleaned:
  - The directory itself
  - Files newer than 30 days
  - Files being actively used

Age calculation:

Age specifications:
  30d - 30 days
  1w  - 1 week (7 days)
  12h - 12 hours
  7d  - 7 days
  
  Based on: The most recent of atime, mtime, or ctime
  Current time - most_recent_timestamp > age threshold

IMPORTANT: How systemd-tmpfiles calculates age
───────────────────────────────────────────────

systemd-tmpfiles checks THREE timestamps:
  - atime (access time)
  - mtime (modification time)
  - ctime (change time)

It uses the MOST RECENT of these three.

For a file to be cleaned:
  ALL three timestamps must be older than threshold

This prevents accidental deletion of files that were
recently accessed, modified, OR had metadata changed.

Understanding cleanup safety:

Safe defaults:
  - Only removes files older than threshold
  - Won't remove actively used files
  - Directory itself never removed
  - Runs predictably via timer

Use cases for Type D:

Use case 1: Log rotation area
  D /var/log/app-archive 0750 root root 90d
  Old archived logs auto-deleted after 90 days

Use case 2: Cache directory
  D /var/cache/myapp 0755 appuser appgroup 14d
  Cache cleaned every 2 weeks

Use case 3: Temporary work area
  D /tmp/build 0755 builder builder 7d
  Old build artifacts cleaned weekly

Use case 4: User temporary space
  D /var/tmp/users 1777 root root 30d
  Shared temp space with automatic cleanup

Permissions explained:

0750 breakdown:
  Owner (root): rwx (7) - read, write, execute
  Group (root): r-x (5) - read, execute
  Other:        --- (0) - no access

Why 0750:
  - Only root can write
  - Root group can read
  - Others cannot access
  - Secure for system data

Alternative permissions:

0755 - World-readable:
  D /var/lib/public-data 0755 root root 30d

1777 - Sticky bit temp:
  D /tmp/shared 1777 root root 7d

0700 - Owner only:
  D /root/temp 0700 root root 14d

Configuration file best practices:

Add comments:
  # Application data directory with 30-day retention
  D /var/lib/lab-data 0750 root root 30d

Group related entries:
  # Lab data directories
  D /var/lib/lab-data 0750 root root 30d
  d /var/lib/lab-config 0755 root root -

Use descriptive filenames:
  lab-data.conf (not just data.conf)

EOF
}

hint_step_4() {
    echo "  Create: /etc/tmpfiles.d/lab-cache.conf"
    echo "  Format: D /tmp/lab-cache 1777 root root 7d"
    echo "  Note: Cleanup testing requires files to naturally age"
    echo "  The configuration is what matters for the exam"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Create temporary cache with age-based cleanup

Create a cache directory with automatic cleanup configuration.

Requirements:
  • Create file: /etc/tmpfiles.d/lab-cache.conf
  • Type: D (create and clean)
  • Path: /tmp/lab-cache
  • Mode: 1777 (sticky bit for shared temp space)
  • Owner: root
  • Group: root
  • Age: 7d (7 days)
  
  • Apply configuration to create directory
  • Verify directory creation and permissions
  • Understand cleanup behavior

Configuration line:
  D /tmp/lab-cache 1777 root root 7d

The sticky bit (1777):
  - Anyone can create files
  - Only owner can delete their own files
  - Common for /tmp directories

IMPORTANT NOTE: Cleanup testing limitation
────────────────────────────────────────────
systemd-tmpfiles cleanup checks atime, mtime, AND ctime,
using the MOST RECENT of these three timestamps.

You cannot simulate old files with touch -d because:
  - touch -d sets mtime to the past
  - BUT also sets ctime to NOW
  - systemd-tmpfiles sees recent ctime
  - File won't be cleaned

Real cleanup works because naturally created files have
all timestamps aging together over time.

For the exam: Know how to create the configuration correctly.
Actual cleanup testing requires files to age naturally (days/weeks).
EOF
}

validate_step_4() {
    local failures=0
    
    # Check if config file exists
    if [ ! -f /etc/tmpfiles.d/lab-cache.conf ]; then
        echo ""
        print_color "$RED" "✗ /etc/tmpfiles.d/lab-cache.conf not found"
        ((failures++))
        return 1
    fi
    
    # Check config file contains correct entry
    if ! grep -qE "^D[[:space:]]+/tmp/lab-cache[[:space:]]+1?777[[:space:]]+root[[:space:]]+root[[:space:]]+7d" /etc/tmpfiles.d/lab-cache.conf; then
        echo ""
        print_color "$RED" "✗ Configuration entry incorrect or missing"
        echo "  Expected: D /tmp/lab-cache 1777 root root 7d"
        echo "  Your file contains:"
        cat /etc/tmpfiles.d/lab-cache.conf
        ((failures++))
    fi
    
    # Try to create the directory
    systemd-tmpfiles --create --prefix=/tmp/lab-cache >/dev/null 2>&1
    
    # Check if directory was created
    if [ ! -d /tmp/lab-cache ]; then
        echo ""
        print_color "$RED" "✗ Directory /tmp/lab-cache was not created"
        ((failures++))
        return 1
    fi
    
    # Check permissions (should be 1777)
    if [ -d /tmp/lab-cache ]; then
        local perms=$(stat -c '%a' /tmp/lab-cache)
        if [ "$perms" != "1777" ]; then
            echo ""
            print_color "$RED" "✗ Directory permissions are $perms (expected 1777)"
            ((failures++))
        fi
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    # Note: We do NOT test actual cleanup because of the ctime limitation
    # The configuration being correct is what matters for the exam
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1: Create the tmpfiles configuration
───────────────────────────────────────────
sudo vi /etc/tmpfiles.d/lab-cache.conf

Add this line:

D /tmp/lab-cache 1777 root root 7d

Step 2: Save the file
─────────────────────
ESC, then :wq

Step 3: Apply the configuration
────────────────────────────────
sudo systemd-tmpfiles --create --prefix=/tmp/lab-cache

Step 4: Verify directory creation
──────────────────────────────────
ls -ld /tmp/lab-cache

Should show:
  drwxrwxrwt. 2 root root 40 Feb  3 14:30 /tmp/lab-cache
  
Note the 't' at the end - that's the sticky bit.

Understanding cleanup behavior:

IMPORTANT: systemd-tmpfiles cleanup limitation
────────────────────────────────────────────────

systemd-tmpfiles --clean checks THREE timestamps:
  - atime (access time)
  - mtime (modification time)
  - ctime (change time)

It uses the MOST RECENT of these three timestamps.

Why touch -d doesn't work for testing:
  touch -d "10 days ago" file.txt
  
  This sets: mtime to 10 days ago
  But also sets: ctime to NOW (when you ran the command)
  
  Result: systemd-tmpfiles sees ctime is recent, won't delete

Real-world cleanup works because:
  - Files created 10 days ago have ALL timestamps old
  - Natural aging affects all three timestamps
  - No manual timestamp manipulation

How cleanup actually works in production:

Day 0: User creates /tmp/lab-cache/data.txt
  atime: Feb 1
  mtime: Feb 1
  ctime: Feb 1

Day 7: Cleanup runs
  atime: Feb 1 (7 days old)
  mtime: Feb 1 (7 days old)
  ctime: Feb 1 (7 days old)
  Most recent: Feb 1 (7 days old)
  Result: File NOT deleted (exactly 7d, not > 7d)

Day 8: Cleanup runs
  All timestamps: Feb 1 (8 days old)
  Most recent: Feb 1 (8 days old)
  Result: File IS deleted (8 days > 7 days)

For the exam:
  You need to know:
  ✓ How to create the configuration
  ✓ Type D enables cleanup
  ✓ Age format (7d, 30d, etc.)
  ✓ Cleanup happens automatically via timer
  
  You do NOT need to:
  ✗ Actually wait 7 days to test
  ✗ Manipulate timestamps
  ✗ Prove cleanup works in exam time

The configuration is what the exam tests, not waiting a week.

Understanding the sticky bit (1777):

Permission breakdown:
  1777
  ││└┴─ Others: rwx (7)
  │└─── Group: rwx (7)
  └──── Owner: rwx (7)
  
  Leading 1: Sticky bit

Sticky bit behavior:
  - Anyone can create files
  - Anyone can read files
  - Only owner can delete their own files
  - Prevents users from deleting others' files

Why use sticky bit:
  - Common for /tmp and shared temp directories
  - Allows collaboration
  - Prevents malicious deletion
  - Same as /tmp itself

Verify sticky bit:
  ls -ld /tmp/lab-cache
  # Shows 't' at end: drwxrwxrwt

Understanding cleanup timing:

Automatic cleanup:
  Via: systemd-tmpfiles-clean.timer
  Schedule: 15 min after boot, then daily
  
  View schedule:
    systemctl list-timers systemd-tmpfiles-clean.timer

Manual cleanup:
  Run immediately:
    systemd-tmpfiles --clean
  
  Specific prefix:
    systemd-tmpfiles --clean --prefix=/tmp/lab-cache

What cleanup does:

Process:
  1. Reads all tmpfiles.d configurations
  2. Finds entries with Type D
  3. Checks files in those directories
  4. Compares most recent timestamp to threshold
  5. Removes files where all timestamps are old enough

Safety:
  - Only removes regular files
  - Won't remove directories
  - Won't remove the configured directory itself
  - Based on most recent of atime/mtime/ctime

Real-world use cases:

Use case 1: Build cache
  D /var/cache/build 0755 builder builder 7d
  Old build artifacts cleaned weekly

Use case 2: Download temp area
  D /tmp/downloads 1777 root root 1d
  Downloaded files cleaned daily

Use case 3: Session data
  D /var/lib/sessions 0750 www-data www-data 12h
  Old sessions cleaned every 12 hours

Use case 4: Log staging
  D /var/log/staging 0750 root root 3d
  Logs cleaned after 3 days

Age field values:

Common ages:
  7d   - 7 days (1 week)
  14d  - 14 days (2 weeks)
  30d  - 30 days (1 month)
  1h   - 1 hour
  12h  - 12 hours
  1d   - 1 day

Special values:
  -    - No age limit (never clean)
  0    - Clean immediately (all files)

Verification for exam:

What you CAN verify:
  ✓ Configuration file created correctly
  ✓ Directory exists with correct permissions
  ✓ Sticky bit is set (1777)
  ✓ Type D is used (not d)
  ✓ Age is specified (7d)

What you DON'T need to verify:
  ✗ Actual cleanup works (time limitation)
  ✗ Files are deleted after 7 days
  
The configuration is what the exam tests, not waiting a week.

Common mistakes:

Mistake 1: Using type d instead of D
  Wrong: d /tmp/cache 1777 root root 7d
  Right: D /tmp/cache 1777 root root 7d
  
  Type d doesn't clean, even with age specified

Mistake 2: Forgetting sticky bit
  Wrong: D /tmp/cache 0777 root root 7d
  Right: D /tmp/cache 1777 root root 7d
  
  Without sticky bit, users can delete others' files

Mistake 3: Wrong age format
  Wrong: D /tmp/cache 1777 root root 7
  Right: D /tmp/cache 1777 root root 7d
  
  Must include unit: d, h, w

Mistake 4: Expecting touch -d to work for testing
  Problem: Changes ctime to NOW
  Reality: Can't simulate old files this way
  Solution: Trust the configuration, cleanup works in production

Configuration file best practices:

Add comments:
  # Temporary cache with 7-day retention
  D /tmp/lab-cache 1777 root root 7d

Group related entries:
  # Lab temporary directories
  D /tmp/lab-cache 1777 root root 7d
  D /tmp/lab-work 1777 root root 1d

Use descriptive filenames:
  lab-cache.conf (not just cache.conf)

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=7
    
    echo "Checking your systemd-tmpfiles configuration..."
    echo ""
    
    # CHECK 1: lab-app.conf exists
    print_color "$CYAN" "[1/$total] Checking lab-app.conf..."
    if [ -f /etc/tmpfiles.d/lab-app.conf ]; then
        if grep -qE "^d[[:space:]]+/run/lab-app[[:space:]]+0?755[[:space:]]+appuser[[:space:]]+appuser" /etc/tmpfiles.d/lab-app.conf; then
            print_color "$GREEN" "  ✓ Configuration file correct"
            ((score++))
        else
            print_color "$RED" "  ✗ Configuration exists but incorrect"
        fi
    else
        print_color "$RED" "  ✗ /etc/tmpfiles.d/lab-app.conf not found"
    fi
    echo ""
    
    # CHECK 2: /run/lab-app directory created correctly
    print_color "$CYAN" "[2/$total] Checking /run/lab-app directory..."
    systemd-tmpfiles --create --prefix=/run/lab-app >/dev/null 2>&1
    if [ -d /run/lab-app ]; then
        local owner=$(stat -c '%U:%G' /run/lab-app)
        local perms=$(stat -c '%a' /run/lab-app)
        if [ "$owner" = "appuser:appuser" ] && [ "$perms" = "755" ]; then
            print_color "$GREEN" "  ✓ Directory created with correct ownership and permissions"
            ((score++))
        else
            print_color "$RED" "  ✗ Directory exists but ownership ($owner) or permissions ($perms) incorrect"
        fi
    else
        print_color "$RED" "  ✗ Directory /run/lab-app not created"
    fi
    echo ""
    
    # CHECK 3: lab-data.conf exists with type D
    print_color "$CYAN" "[3/$total] Checking lab-data.conf..."
    if [ -f /etc/tmpfiles.d/lab-data.conf ]; then
        if grep -qE "^D[[:space:]]+/var/lib/lab-data[[:space:]]+0?750[[:space:]]+root[[:space:]]+root[[:space:]]+30d" /etc/tmpfiles.d/lab-data.conf; then
            print_color "$GREEN" "  ✓ Configuration file correct (type D with 30d age)"
            ((score++))
        else
            print_color "$RED" "  ✗ Configuration exists but incorrect"
            echo "  Expected: D /var/lib/lab-data 0750 root root 30d"
        fi
    else
        print_color "$RED" "  ✗ /etc/tmpfiles.d/lab-data.conf not found"
    fi
    echo ""
    
    # CHECK 4: /var/lib/lab-data directory created
    print_color "$CYAN" "[4/$total] Checking /var/lib/lab-data directory..."
    systemd-tmpfiles --create --prefix=/var/lib/lab-data >/dev/null 2>&1
    if [ -d /var/lib/lab-data ]; then
        local perms=$(stat -c '%a' /var/lib/lab-data)
        if [ "$perms" = "750" ]; then
            print_color "$GREEN" "  ✓ Directory created with correct permissions"
            ((score++))
        else
            print_color "$RED" "  ✗ Directory permissions are $perms (expected 750)"
        fi
    else
        print_color "$RED" "  ✗ Directory /var/lib/lab-data not created"
    fi
    echo ""
    
    # CHECK 5: lab-cache.conf exists
    print_color "$CYAN" "[5/$total] Checking lab-cache.conf..."
    if [ -f /etc/tmpfiles.d/lab-cache.conf ]; then
        if grep -qE "^D[[:space:]]+/tmp/lab-cache[[:space:]]+1?777[[:space:]]+root[[:space:]]+root[[:space:]]+7d" /etc/tmpfiles.d/lab-cache.conf; then
            print_color "$GREEN" "  ✓ Configuration file correct (sticky bit and 7d age)"
            ((score++))
        else
            print_color "$RED" "  ✗ Configuration exists but incorrect"
            echo "  Expected: D /tmp/lab-cache 1777 root root 7d"
        fi
    else
        print_color "$RED" "  ✗ /etc/tmpfiles.d/lab-cache.conf not found"
    fi
    echo ""
    
    # CHECK 6: /tmp/lab-cache directory with sticky bit
    print_color "$CYAN" "[6/$total] Checking /tmp/lab-cache directory..."
    systemd-tmpfiles --create --prefix=/tmp/lab-cache >/dev/null 2>&1
    if [ -d /tmp/lab-cache ]; then
        local perms=$(stat -c '%a' /tmp/lab-cache)
        if [ "$perms" = "1777" ]; then
            print_color "$GREEN" "  ✓ Directory created with sticky bit (1777)"
            ((score++))
        else
            print_color "$RED" "  ✗ Directory permissions are $perms (expected 1777)"
        fi
    else
        print_color "$RED" "  ✗ Directory /tmp/lab-cache not created"
    fi
    echo ""
    
    # CHECK 7: Understanding of cleanup behavior
    print_color "$CYAN" "[7/$total] Verifying cleanup configuration..."
    if [ -f /etc/tmpfiles.d/lab-cache.conf ] && [ -d /tmp/lab-cache ]; then
        local has_type_d=$(grep -E "^D[[:space:]]" /etc/tmpfiles.d/lab-cache.conf)
        local has_age=$(grep -E "7d" /etc/tmpfiles.d/lab-cache.conf)
        
        if [ -n "$has_type_d" ] && [ -n "$has_age" ]; then
            print_color "$GREEN" "  ✓ Cleanup configuration correct (Type D with 7d age)"
            echo "    Note: Actual cleanup testing requires files to age naturally"
            echo "    The configuration is what matters for the exam"
            ((score++))
        else
            print_color "$RED" "  ✗ Cleanup configuration incomplete"
        fi
    else
        print_color "$RED" "  ✗ Cannot verify cleanup - missing config or directory"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've mastered systemd-tmpfiles:"
        echo "  • Creating tmpfiles.d configurations"
        echo "  • Using type d for directory creation"
        echo "  • Using type D for cleanup-enabled directories"
        echo "  • Setting proper permissions and ownership"
        echo "  • Understanding age-based automatic cleanup"
        echo "  • Configuring sticky bit for shared directories"
        echo ""
        echo "You're ready for RHCSA tmpfiles questions!"
    elif [ $score -ge 5 ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED (Good Understanding)"
        echo ""
        echo "Good work! Review the missing pieces to strengthen your knowledge."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback and try again."
        echo "Use --interactive mode for step-by-step guidance."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -ge 5 ]
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

See detailed solutions in each step's solution output above.

KEY CONCEPTS FOR EXAM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cleanup timestamp behavior:
  systemd-tmpfiles checks atime, mtime, AND ctime
  Uses the MOST RECENT of these three
  All three must be old for cleanup to work
  Cannot simulate with touch -d (updates ctime to NOW)

EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical skills for RHCSA:

1. Configuration location: /etc/tmpfiles.d/
2. Type codes: d (create), D (create+clean)
3. Format: Type Path Mode User Group Age
4. Apply configs: systemd-tmpfiles --create
5. Age format: 7d, 30d, 12h

Common patterns:
  Runtime dir:     d /run/app 0755 user group -
  Cleanup dir:     D /tmp/cache 1777 root root 7d
  Persistent dir:  D /var/lib/data 0750 root root 30d

Type codes to know:
  d - Create directory (no cleanup)
  D - Create directory with age-based cleanup
  L - Create symlink
  z - Set permissions only

Quick reference:
  Create: systemd-tmpfiles --create
  Clean:  systemd-tmpfiles --clean
  Prefix: systemd-tmpfiles --create --prefix=/path
  Verify: ls -ld /path

Remember:
  • Use D for cleanup, d for persistent
  • Sticky bit (1777) for shared temp
  • Age in days (7d, 30d)
  • Apply with --create after editing
  • Cleanup uses most recent timestamp (atime/mtime/ctime)

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove tmpfiles configurations
    rm -f /etc/tmpfiles.d/lab-app.conf 2>/dev/null || true
    rm -f /etc/tmpfiles.d/lab-data.conf 2>/dev/null || true
    rm -f /etc/tmpfiles.d/lab-cache.conf 2>/dev/null || true
    
    # Remove created directories
    rm -rf /run/lab-app 2>/dev/null || true
    rm -rf /var/lib/lab-data 2>/dev/null || true
    rm -rf /tmp/lab-cache 2>/dev/null || true
    
    # Remove test user
    userdel -r appuser 2>/dev/null || true
    
    # Remove lab directory
    rm -rf /opt/lab-tmpfiles 2>/dev/null || true
    
    echo "  ✓ Tmpfiles configurations removed"
    echo "  ✓ Created directories removed"
    echo "  ✓ Test user removed"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
