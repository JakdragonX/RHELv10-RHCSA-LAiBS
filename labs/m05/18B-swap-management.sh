#!/bin/bash
# m05/18B-swap-management.sh
# Lab: Managing Swap Space
# Difficulty: Intermediate
# RHCSA Objective: Configure swap partitions and swap files

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing Swap Space"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="15-20 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Disable any existing lab swap
    swapoff /dev/lab-swap 2>/dev/null || true
    swapoff /swapfile 2>/dev/null || true
    
    # Remove previous swap entries from fstab
    sed -i '/\/swapfile/d' /etc/fstab 2>/dev/null || true
    sed -i '/lab-swap/d' /etc/fstab 2>/dev/null || true
    
    # Remove previous swap files
    rm -f /swapfile 2>/dev/null || true
    
    # Clean up loop devices
    for loop in $(losetup -j /var/lab-disks/swap-disk.img 2>/dev/null | cut -d: -f1); do
        losetup -d "$loop" 2>/dev/null || true
    done
    
    # Create virtual disk for swap partition (1GB)
    mkdir -p /var/lab-disks
    rm -f /var/lab-disks/swap-disk.img 2>/dev/null || true
    truncate -s 1G /var/lab-disks/swap-disk.img
    
    # Attach loop device
    LOOP=$(losetup -f --show /var/lab-disks/swap-disk.img)
    echo "$LOOP" > /tmp/.lab-swap-loop
    
    echo "  ✓ Created virtual disk at $LOOP"
    echo "  ✓ Cleaned up previous swap configurations"
    echo "  ✓ System ready for swap configuration"
    echo ""
    echo "Virtual disk available: $LOOP (1GB)"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of virtual memory and swap space
  • Purpose of swap in Linux systems
  • Difference between swap partitions and swap files
  • How to check current swap usage
  • Persistent swap configuration

Commands You'll Use:
  • swapon     - Enable swap space
  • swapoff    - Disable swap space
  • mkswap     - Set up a Linux swap area
  • free       - Display amount of free and used memory
  • fdisk      - Create swap partition
  • fallocate  - Preallocate space for swap file
  • chmod      - Set permissions on swap file

Files You'll Interact With:
  • /etc/fstab  - Persistent swap configuration
  • /proc/swaps - Currently active swap spaces

Reference Material:
  • man swapon
  • man mkswap
  • man fstab
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF
SCENARIO:
Your company's application server is experiencing occasional memory pressure during
peak loads. The infrastructure team has requested that you configure swap space to
prevent out-of-memory issues. You need to implement both a swap partition and a
swap file for flexibility.

BACKGROUND:
The server has:
  • A new disk available at $LOOP (1GB) for dedicated swap partition
  • Existing root filesystem with space for a swap file
  • Current swap configuration: $(free -h | grep Swap | awk '{print $2}')

The team wants:
  • 512MB swap partition on $LOOP (persistent across reboots)
  • 256MB swap file at /swapfile (persistent across reboots)
  • Both swap spaces active simultaneously

OBJECTIVES:
  1. Create a 512MB swap partition on $LOOP
     • Use fdisk to create partition with swap type
     • Initialize with mkswap
     • Activate immediately

  2. Configure swap partition for persistent activation
     • Add to /etc/fstab using UUID
     • Verify with swapon -a

  3. Create a 256MB swap file at /swapfile
     • Use fallocate to create file
     • Set correct permissions (600)
     • Initialize and activate

  4. Configure swap file for persistent activation
     • Add to /etc/fstab
     • Verify both swap spaces are active

HINTS:
  • In fdisk, partition type 82 (Linux swap) or type 19 (Linux swap)
  • After creating swap, run 'mkswap' before 'swapon'
  • Use 'blkid' to get UUID for fstab entry
  • Swap files must have 600 permissions (security requirement)
  • Use 'free -h' to verify total swap space
  • 'swapon --show' displays all active swap

SUCCESS CRITERIA:
  • 512MB swap partition created and active
  • 256MB swap file created and active
  • Both configured in /etc/fstab
  • Total swap: ~768MB (512MB + 256MB)
  • All swap persists after 'swapoff -a' followed by 'swapon -a'
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF
  ☐ 1. Create 512MB swap partition on $LOOP and activate
  ☐ 2. Add swap partition to /etc/fstab (using UUID)
  ☐ 3. Create 256MB swap file at /swapfile and activate
  ☐ 4. Add swap file to /etc/fstab and verify persistence
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################

get_step_count() {
    echo "4"
}

scenario_context() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF
Your server needs swap space to handle memory pressure during peak loads.
You'll create a 512MB swap partition on $LOOP and a 256MB swap file,
both configured to activate automatically at boot.
EOF
}

# STEP 1: Create swap partition
show_step_1() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF
TASK: Create a 512MB swap partition on $LOOP

Swap partitions provide dedicated disk space for virtual memory. Unlike swap files,
they're slightly faster and can be used for hibernation.

Requirements:
  • Use fdisk to create a 512MB partition
  • Set partition type to 'Linux swap' (type 82 or 19)
  • Run partprobe after fdisk
  • Initialize with mkswap
  • Activate with swapon

Commands you might need:
  • fdisk $LOOP
    Within fdisk:
      n  - New partition
      +512M  - Size specification
      t  - Change partition type
      82 or 19  - Linux swap type
      w  - Write changes
  • partprobe $LOOP
  • mkswap ${LOOP}p1  - Initialize swap area
  • swapon ${LOOP}p1  - Activate swap
  • swapon --show     - Verify swap is active
  • free -h           - Check total swap

Partition size calculation:
  • First sector: default (usually 2048)
  • Last sector: +512M (creates 512MB partition)
EOF
}

validate_step_1() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    sleep 1
    partprobe "$LOOP" 2>/dev/null || true
    sleep 1
    
    # Check partition exists
    if ! lsblk "$LOOP" 2>/dev/null | grep -qE "├─|└─" && ! [ -b "${LOOP}p1" ]; then
        echo ""
        print_color "$RED" "✗ No partition found on $LOOP"
        echo "  Try: fdisk $LOOP (n, +512M, t, 82, w)"
        echo "  Then: partprobe $LOOP"
        return 1
    fi
    
    # Check partition type
    if ! fdisk -l "$LOOP" 2>/dev/null | grep -i swap; then
        echo ""
        print_color "$YELLOW" "⚠ Partition may not be set to swap type"
        echo "  Try: fdisk $LOOP, then 't' to change type to 82 or 19"
    fi
    
    # Check if mkswap was run (look for swap signature)
    if ! blkid "${LOOP}p1" 2>/dev/null | grep -q 'TYPE="swap"'; then
        echo ""
        print_color "$RED" "✗ Partition not initialized as swap"
        echo "  Try: mkswap ${LOOP}p1"
        return 1
    fi
    
    # Check if swap is active
    if ! swapon --show | grep -q "${LOOP}p1"; then
        echo ""
        print_color "$RED" "✗ Swap partition not active"
        echo "  Try: swapon ${LOOP}p1"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF

SOLUTION:
─────────
Commands:
  fdisk $LOOP
  # Inside fdisk:
  n       # New partition
  p       # Primary (default)
  1       # Partition number 1
  [Enter] # Default first sector
  +512M   # Size: 512 megabytes
  t       # Change partition type
  82      # Linux swap type (or use 19)
  w       # Write changes
  
  partprobe $LOOP           # Update kernel
  mkswap ${LOOP}p1         # Initialize swap area
  swapon ${LOOP}p1         # Activate swap

Explanation:
  • n: Creates new partition
  • +512M: Specifies partition size (512 megabytes)
  • t: Changes partition type
  • 82 or 19: Linux swap partition type codes
  • mkswap: Writes swap metadata to partition
  • swapon: Activates the swap space

Why set partition type:
  While Linux doesn't strictly require type 82/19, setting it:
    • Documents the partition's purpose
    • Helps automated tools identify swap partitions
    • Follows best practices for system administration

Verification:
  swapon --show
  # Should show ${LOOP}p1 with SIZE around 512M
  
  free -h
  # Swap total should increase by ~512M

EOF
}

hint_step_1() {
    echo "  fdisk: n, +512M, t, 82, w"
    echo "  Then: partprobe, mkswap, swapon"
}

# STEP 2: Add swap partition to fstab
show_step_2() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << 'EOF'
TASK: Configure swap partition for persistent activation

Add the swap partition to /etc/fstab so it activates automatically at boot.
Using UUID ensures the swap works even if device names change.

Requirements:
  • Get UUID of swap partition with blkid
  • Add entry to /etc/fstab using UUID
  • Format: UUID=xxx none swap defaults 0 0
  • Test with: swapoff -a; swapon -a

Commands you might need:
  • blkid | grep swap  - Find swap partition UUID
  • echo "UUID=xxx none swap defaults 0 0" >> /etc/fstab
  • findmnt --verify   - Check fstab syntax
  • swapoff -a         - Disable all swap
  • swapon -a          - Enable all swap from fstab

/etc/fstab format for swap:
  UUID=xxx  none  swap  defaults  0  0
  │         │     │     │         │  └─ fsck pass (always 0 for swap)
  │         │     │     │         └─ dump flag (always 0 for swap)
  │         │     │     └─ mount options
  │         │     └─ filesystem type
  │         └─ mount point (always 'none' or 'swap' for swap)
  └─ device identifier
EOF
}

validate_step_2() {
    # Check if fstab has swap entry
    if ! grep "swap" /etc/fstab | grep -v "^#" | grep -q .; then
        echo ""
        print_color "$RED" "✗ No swap entry in /etc/fstab"
        echo "  Add: UUID=xxx none swap defaults 0 0"
        echo "  Get UUID: blkid | grep swap"
        return 1
    fi
    
    # Check if swap partition's UUID is in fstab
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    local swap_uuid=$(blkid "${LOOP}p1" 2>/dev/null | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)
    
    if [ -n "$swap_uuid" ] && ! grep -q "$swap_uuid" /etc/fstab; then
        echo ""
        print_color "$YELLOW" "⚠ Swap partition UUID not found in fstab"
        echo "  Expected UUID: $swap_uuid"
        echo "  Check: grep swap /etc/fstab"
    fi
    
    # Test if swapon -a works
    swapoff -a 2>/dev/null
    if ! swapon -a 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ 'swapon -a' failed - check fstab syntax"
        echo "  Try: findmnt --verify"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF

SOLUTION:
─────────
Commands:
  # Get the UUID
  blkid ${LOOP}p1
  # Copy the UUID value from output
  
  # Add to fstab (replace xxx with actual UUID)
  echo "UUID=xxx  none  swap  defaults  0  0" >> /etc/fstab
  
  # Example with command substitution:
  UUID=\$(blkid ${LOOP}p1 | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)
  echo "UUID=\$UUID  none  swap  defaults  0  0" >> /etc/fstab
  
  # Verify
  findmnt --verify
  
  # Test
  swapoff -a
  swapon -a
  swapon --show

Explanation:
  • UUID: Universally unique identifier for the partition
  • none or swap: No mount point needed for swap
  • swap: Filesystem type
  • defaults: Standard swap options
  • 0 0: No dump, no fsck (not applicable to swap)

Why use UUID:
  Device names (/dev/loop0p1) can change between reboots.
  UUIDs remain constant and uniquely identify the partition.

Verification:
  cat /etc/fstab | grep swap
  swapon --show
  # Should show swap partition active

EOF
}

hint_step_2() {
    echo "  Get UUID: blkid | grep swap"
    echo "  Add to fstab: UUID=xxx none swap defaults 0 0"
}

# STEP 3: Create swap file
show_step_3() {
    cat << 'EOF'
TASK: Create a 256MB swap file at /swapfile

Swap files are more flexible than swap partitions - they can be created, resized,
or removed without repartitioning. They're perfect for temporary swap needs.

Requirements:
  • Create 256MB file at /swapfile using fallocate
  • Set permissions to 600 (security requirement)
  • Initialize with mkswap
  • Activate with swapon

Commands you might need:
  • fallocate -l 256M /swapfile  - Create 256MB file
  • chmod 600 /swapfile          - CRITICAL: secure permissions
  • mkswap /swapfile             - Initialize swap area
  • swapon /swapfile             - Activate swap
  • swapon --show                - Verify both swaps active

Security note:
  Swap files must be 600 (read/write for root only). World-readable swap
  could leak sensitive data that was paged out from memory.
EOF
}

validate_step_3() {
    # Check if swap file exists
    if [ ! -f /swapfile ]; then
        echo ""
        print_color "$RED" "✗ Swap file /swapfile does not exist"
        echo "  Try: fallocate -l 256M /swapfile"
        return 1
    fi
    
    # Check permissions
    local perms=$(stat -c %a /swapfile 2>/dev/null)
    if [ "$perms" != "600" ]; then
        echo ""
        print_color "$RED" "✗ Incorrect permissions on /swapfile (got $perms, need 600)"
        echo "  Fix: chmod 600 /swapfile"
        return 1
    fi
    
    # Check if initialized as swap
    if ! file /swapfile | grep -q swap; then
        echo ""
        print_color "$RED" "✗ /swapfile not initialized as swap"
        echo "  Try: mkswap /swapfile"
        return 1
    fi
    
    # Check if active
    if ! swapon --show | grep -q "/swapfile"; then
        echo ""
        print_color "$RED" "✗ Swap file not active"
        echo "  Try: swapon /swapfile"
        return 1
    fi
    
    # Check size (should be around 256MB)
    local size=$(du -m /swapfile 2>/dev/null | awk '{print $1}')
    if [ -z "$size" ] || [ "$size" -lt 250 ] || [ "$size" -gt 260 ]; then
        echo ""
        print_color "$YELLOW" "⚠ Swap file size is $size MB (expected ~256MB)"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  fallocate -l 256M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile

Explanation:
  • fallocate -l 256M: Preallocates 256MB file (instant)
  • chmod 600: Sets read/write for root only (security!)
  • mkswap: Writes swap metadata to file
  • swapon: Activates the swap file

Why 600 permissions are critical:
  Swap contains memory pages from all processes, including:
    • Passwords before encryption
    • Decrypted sensitive data
    • Private keys
    • Session tokens
  
  If readable by others, attackers could extract this data from swap.

Verification:
  swapon --show
  # Should show both partition and file
  
  free -h
  # Total swap should be ~768MB (512+256)

EOF
}

hint_step_3() {
    echo "  Create: fallocate -l 256M /swapfile"
    echo "  Secure: chmod 600 /swapfile"
    echo "  Initialize: mkswap /swapfile"
    echo "  Activate: swapon /swapfile"
}

# STEP 4: Add swap file to fstab and verify
show_step_4() {
    cat << 'EOF'
TASK: Configure swap file for persistent activation and verify

Add the swap file to /etc/fstab and verify that all swap persists.

Requirements:
  • Add /swapfile to /etc/fstab
  • Format: /swapfile none swap defaults 0 0
  • Test by disabling all swap then re-enabling
  • Verify total swap is ~768MB

Commands you might need:
  • echo "/swapfile none swap defaults 0 0" >> /etc/fstab
  • findmnt --verify
  • swapoff -a   - Disable all swap
  • swapon -a    - Enable all from fstab
  • swapon --show - Show all active swap
  • free -h       - Check total swap amount
EOF
}

validate_step_4() {
    # Check if swapfile in fstab
    if ! grep "/swapfile" /etc/fstab | grep -v "^#" | grep -q .; then
        echo ""
        print_color "$RED" "✗ /swapfile not in /etc/fstab"
        echo "  Add: /swapfile none swap defaults 0 0"
        return 1
    fi
    
    # Test swapon -a
    swapoff -a 2>/dev/null
    sleep 1
    if ! swapon -a 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ 'swapon -a' failed"
        echo "  Check: findmnt --verify"
        return 1
    fi
    
    # Check both swaps are active
    local swap_count=$(swapon --show | tail -n +2 | wc -l)
    if [ "$swap_count" -lt 2 ]; then
        echo ""
        print_color "$YELLOW" "⚠ Expected 2 swap spaces, found $swap_count"
        echo "  Check: swapon --show"
    fi
    
    # Check total swap size (should be around 768MB)
    local total_swap=$(free -m | grep Swap | awk '{print $2}')
    if [ -z "$total_swap" ] || [ "$total_swap" -lt 700 ]; then
        echo ""
        print_color "$YELLOW" "⚠ Total swap is ${total_swap}MB (expected ~768MB)"
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  echo "/swapfile  none  swap  defaults  0  0" >> /etc/fstab
  findmnt --verify
  
  # Test persistence
  swapoff -a
  swapon -a
  swapon --show
  free -h

Explanation:
  • /swapfile: Direct path (swap files don't need UUID)
  • none: No mount point for swap
  • swap: Type
  • defaults: Standard options
  • 0 0: No dump, no fsck

Final verification:
  After adding both swap configurations to fstab:
    1. swapoff -a disables all swap
    2. swapon -a re-enables from fstab
    3. Both partition and file should reactivate
    4. Total swap should be partition + file (~768MB)

Verification:
  swapon --show
  # NAME          TYPE      SIZE
  # /dev/loop0p1  partition 512M
  # /swapfile     file      256M
  
  free -h
  # Swap total should show ~768M

EOF
}

hint_step_4() {
    echo "  Add to fstab: /swapfile none swap defaults 0 0"
    echo "  Test: swapoff -a; swapon -a"
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=4
    
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    partprobe "$LOOP" 2>/dev/null || true
    sleep 1
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: Swap partition created and active
    print_color "$CYAN" "[1/$total] Checking swap partition..."
    local check1_ok=1
    
    if ! [ -b "${LOOP}p1" ] && ! lsblk "$LOOP" 2>/dev/null | grep -qE "├─|└─"; then
        print_color "$RED" "  ✗ No partition on $LOOP"
        check1_ok=0
    elif ! blkid "${LOOP}p1" 2>/dev/null | grep -q 'TYPE="swap"'; then
        print_color "$RED" "  ✗ Partition not initialized as swap"
        check1_ok=0
    elif ! swapon --show | grep -q "${LOOP}p1"; then
        print_color "$RED" "  ✗ Swap partition not active"
        check1_ok=0
    fi
    
    if [ $check1_ok -eq 1 ]; then
        local size=$(swapon --show | grep "${LOOP}p1" | awk '{print $3}')
        print_color "$GREEN" "  ✓ Swap partition active ($size)"
        ((score++))
    fi
    echo ""
    
    # CHECK 2: Swap partition in fstab
    print_color "$CYAN" "[2/$total] Checking swap partition in fstab..."
    if grep "swap" /etc/fstab | grep -v "^#" | grep -q .; then
        print_color "$GREEN" "  ✓ Swap entry in fstab"
        ((score++))
    else
        print_color "$RED" "  ✗ No swap in fstab"
    fi
    echo ""
    
    # CHECK 3: Swap file created and active
    print_color "$CYAN" "[3/$total] Checking swap file..."
    local check3_ok=1
    
    if [ ! -f /swapfile ]; then
        print_color "$RED" "  ✗ /swapfile does not exist"
        check3_ok=0
    else
        local perms=$(stat -c %a /swapfile)
        if [ "$perms" != "600" ]; then
            print_color "$RED" "  ✗ Wrong permissions ($perms, need 600)"
            check3_ok=0
        elif ! file /swapfile | grep -q swap; then
            print_color "$RED" "  ✗ Not initialized as swap"
            check3_ok=0
        elif ! swapon --show | grep -q "/swapfile"; then
            print_color "$RED" "  ✗ Swap file not active"
            check3_ok=0
        fi
    fi
    
    if [ $check3_ok -eq 1 ]; then
        local size=$(swapon --show | grep "/swapfile" | awk '{print $3}')
        print_color "$GREEN" "  ✓ Swap file active ($size)"
        ((score++))
    fi
    echo ""
    
    # CHECK 4: Both persist via fstab
    print_color "$CYAN" "[4/$total] Checking persistent configuration..."
    swapoff -a 2>/dev/null
    sleep 1
    if swapon -a 2>/dev/null; then
        local count=$(swapon --show | tail -n +2 | wc -l)
        if [ "$count" -ge 2 ]; then
            local total=$(free -m | grep Swap | awk '{print $2}')
            print_color "$GREEN" "  ✓ Both swaps persistent (total: ${total}MB)"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ Only $count swap found (expected 2)"
        fi
    else
        print_color "$RED" "  ✗ 'swapon -a' failed"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! Swap configuration complete:"
        swapon --show
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
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
    LOOP=$(cat /tmp/.lab-swap-loop 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF
COMPLETE SOLUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Create swap partition (512MB)
─────────────────────────────────────────────────────────────────
  fdisk $LOOP
  n; p; 1; [Enter]; +512M; t; 82; w
  partprobe $LOOP
  mkswap ${LOOP}p1
  swapon ${LOOP}p1

STEP 2: Add to fstab
─────────────────────────────────────────────────────────────────
  UUID=\$(blkid ${LOOP}p1 | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)
  echo "UUID=\$UUID  none  swap  defaults  0  0" >> /etc/fstab

STEP 3: Create swap file (256MB)
─────────────────────────────────────────────────────────────────
  fallocate -l 256M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile

STEP 4: Add swap file to fstab
─────────────────────────────────────────────────────────────────
  echo "/swapfile  none  swap  defaults  0  0" >> /etc/fstab
  swapoff -a
  swapon -a

VERIFICATION:
─────────────────────────────────────────────────────────────────
  swapon --show
  free -h

KEY CONCEPTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What is swap:
  Virtual memory on disk. When RAM is full, inactive memory pages are
  moved to swap. Prevents out-of-memory kills but much slower than RAM.

Swap partition vs swap file:
  Partition:
    ✓ Slightly faster (contiguous disk space)
    ✓ Can be used for hibernation
    ✗ Set at creation, hard to resize
  
  File:
    ✓ Easy to create/remove/resize
    ✓ No repartitioning needed
    ✓ Flexible for temporary needs
    ✗ Slightly slower

How much swap:
  • RAM ≤ 2GB: 2× RAM
  • RAM 2-8GB: = RAM
  • RAM > 8GB: 8GB minimum
  • This lab: 768MB for demonstration

Security:
  Swap files MUST be 600 permissions. Swap contains decrypted memory
  from all processes, including passwords, keys, and sensitive data.

fstab format for swap:
  UUID=xxx  none  swap  defaults  0  0
  /swapfile none  swap  defaults  0  0

COMMON MISTAKES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Forgetting partprobe: ${LOOP}p1 doesn't appear
2. Wrong permissions: chmod 600 BEFORE mkswap
3. Not running mkswap: swapon fails
4. Using /dev/loopX instead of UUID in fstab

EXAM TIPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Swap partition: fdisk → partprobe → mkswap → swapon → fstab
2. Swap file: fallocate → chmod 600 → mkswap → swapon → fstab
3. Verify: swapon --show, free -h
4. Test fstab: swapoff -a; swapon -a

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    swapoff -a 2>/dev/null || true
    swapoff /swapfile 2>/dev/null || true
    
    sed -i '/\/swapfile/d' /etc/fstab 2>/dev/null || true
    sed -i '/swap/d' /etc/fstab 2>/dev/null || true
    
    rm -f /swapfile 2>/dev/null || true
    
    if [ -f /tmp/.lab-swap-loop ]; then
        LOOP=$(cat /tmp/.lab-swap-loop)
        losetup -d "$LOOP" 2>/dev/null || true
    fi
    
    for loop in $(losetup -j /var/lab-disks/swap-disk.img 2>/dev/null | cut -d: -f1); do
        losetup -d "$loop" 2>/dev/null || true
    done
    
    rm -f /var/lab-disks/swap-disk.img 2>/dev/null || true
    rm -f /tmp/.lab-swap-loop 2>/dev/null || true
    rmdir /var/lab-disks 2>/dev/null || true
    
    echo "  ✓ Cleanup complete"
}

main "$@"
