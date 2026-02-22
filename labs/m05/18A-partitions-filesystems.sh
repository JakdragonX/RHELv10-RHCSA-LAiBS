#!/bin/bash
# m05/18A-partitions-filesystems.sh
# Lab: Managing Partitions and Filesystems
# Difficulty: Intermediate
# RHCSA Objective: Create and configure file systems (partitions, mount points, /etc/fstab)

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing Partitions and Filesystems"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="20-30 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Unmount any existing test mounts
    umount /mnt/data 2>/dev/null || true
    umount /mnt/backup 2>/dev/null || true
    
    # Remove fstab entries from previous attempts
    sed -i '/\/mnt\/data/d' /etc/fstab 2>/dev/null || true
    sed -i '/\/mnt\/backup/d' /etc/fstab 2>/dev/null || true
    sed -i '/LABEL=DATA/d' /etc/fstab 2>/dev/null || true
    sed -i '/LABEL=BACKUP/d' /etc/fstab 2>/dev/null || true
    
    # Remove directories
    rm -rf /mnt/data /mnt/backup 2>/dev/null || true
    
    # Remove any existing loop devices FIRST (fixes "Resource busy" issue)
    for loop in $(losetup -j /var/lab-disks/disk1.img 2>/dev/null | cut -d: -f1); do
        losetup -d "$loop" 2>/dev/null || true
    done
    for loop in $(losetup -j /var/lab-disks/disk2.img 2>/dev/null | cut -d: -f1); do
        losetup -d "$loop" 2>/dev/null || true
    done
    
    # Also try generic cleanup
    losetup -D 2>/dev/null || true
    
    # Create virtual disk files (2GB each)
    mkdir -p /var/lab-disks
    rm -f /var/lab-disks/disk1.img /var/lab-disks/disk2.img 2>/dev/null || true
    
    truncate -s 2G /var/lab-disks/disk1.img
    truncate -s 2G /var/lab-disks/disk2.img
    
    # Attach loop devices using --show to get device name immediately
    LOOP1=$(losetup -f --show /var/lab-disks/disk1.img)
    LOOP2=$(losetup -f --show /var/lab-disks/disk2.img)
    
    # Store loop device names for validation
    echo "$LOOP1" > /tmp/.lab-loop1
    echo "$LOOP2" > /tmp/.lab-loop2
    
    echo "  ✓ Created virtual disks at $LOOP1 and $LOOP2"
    echo "  ✓ Cleaned up any previous lab attempts"
    echo "  ✓ System ready for fresh lab start"
    echo ""
    echo "Virtual disks available:"
    echo "  - $LOOP1 (2GB)"
    echo "  - $LOOP2 (2GB)"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of block devices and partitions
  • GPT vs MBR partition table differences
  • Filesystem types (XFS, ext4) and their characteristics
  • Mount points and the Linux filesystem hierarchy
  • /etc/fstab format and purpose
  • UUID and label-based mounting

Commands You'll Use:
  • lsblk       - List block devices and their mount points
  • fdisk       - Partition manipulation (interactive)
  • partprobe   - Inform kernel of partition table changes
  • mkfs.xfs    - Create XFS filesystem
  • mkfs.ext4   - Create ext4 filesystem
  • blkid       - Display block device attributes (UUID, labels)
  • xfs_admin   - Modify XFS filesystem parameters
  • mount       - Mount filesystems temporarily
  • umount      - Unmount filesystems
  • findmnt     - Verify mount configurations

Files You'll Interact With:
  • /etc/fstab  - Persistent mount configuration file
  • /dev/loop*  - Loop block devices (virtual disks for this lab)

Reference Material:
  • man fdisk
  • man fstab(5)
  • man mount(8)
  • man xfs_admin(8)
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    cat << EOF
SCENARIO:
Your organization is deploying a new application server that requires dedicated
storage for application data and backup storage. You need to prepare the storage
infrastructure by creating properly configured partitions and filesystems that
will persist across reboots.

BACKGROUND:
The server has two additional disks available:
  • $LOOP1 (2GB) - for application data
  • $LOOP2 (2GB) - for backup storage

The application team has specified that data must be mounted at /mnt/data and
backups at /mnt/backup. They've also requested that mounts use labels rather
than device paths for better maintainability during hardware changes.

OBJECTIVES:
  1. Create GPT partition and XFS filesystem on $LOOP1
     • Partition the entire disk
     • Label filesystem as "DATA"
     • Create mount point /mnt/data

  2. Configure persistent mount for DATA
     • Add to /etc/fstab using LABEL=DATA
     • Test with mount -a

  3. Create GPT partition and ext4 filesystem on $LOOP2
     • Partition the entire disk
     • Label filesystem as "BACKUP"
     • Create mount point /mnt/backup

  4. Configure persistent mount for BACKUP
     • Add to /etc/fstab using LABEL=BACKUP

  5. Verify all mounts work correctly
     • Test unmount and remount via fstab

HINTS:
  • Use 'lsblk' frequently to check your progress
  • In fdisk: 'g' creates GPT table, 'n' creates partition, 'w' writes changes
  • ALWAYS run 'partprobe /dev/loopX' after fdisk!
  • Remember partition suffix: ${LOOP1}p1 not ${LOOP1}1
  • Use 'blkid' to verify labels
  • Test fstab with 'findmnt --verify' before 'mount -a'

SUCCESS CRITERIA:
  • Both partitions created with GPT partition tables
  • XFS filesystem labeled "DATA" mounted at /mnt/data
  • ext4 filesystem labeled "BACKUP" mounted at /mnt/backup
  • Both mounts configured in /etc/fstab using labels
  • All mounts persist after 'umount' followed by 'mount -a'
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    cat << EOF
  ☐ 1. Create GPT partition + XFS (label: DATA) on $LOOP1
  ☐ 2. Add DATA to /etc/fstab, mount at /mnt/data
  ☐ 3. Create GPT partition + ext4 (label: BACKUP) on $LOOP2
  ☐ 4. Add BACKUP to /etc/fstab, mount at /mnt/backup
  ☐ 5. Verify both work with 'mount -a'
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################

get_step_count() {
    echo "5"
}

scenario_context() {
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    cat << EOF
Your organization needs dedicated storage for application data and backups.
You have two disks available: $LOOP1 and $LOOP2 (each 2GB).
You'll create partitions, filesystems, and configure persistent mounts.
EOF
}

# STEP 1: Create GPT partition and XFS filesystem on first disk
show_step_1() {
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF
TASK: Create GPT partition on $LOOP1 and format with XFS labeled "DATA"

Modern systems use GPT (GUID Partition Table) instead of legacy MBR. You'll create
a single partition using the entire disk, then format it with XFS and set a label.

Requirements:
  • Use fdisk to create GPT partition table on $LOOP1
  • Create one partition using all available space
  • Run 'partprobe $LOOP1' after fdisk to update kernel
  • Create XFS filesystem with label "DATA"
  • Create mount point /mnt/data

Commands you might need:
  • fdisk $LOOP1
    Within fdisk:
      g  - Create new GPT partition table
      n  - Create new partition (accept all defaults)
      w  - Write changes and exit
  • partprobe $LOOP1    - Force kernel to re-read partition table (CRITICAL!)
  • mkfs.xfs -L DATA ${LOOP1}p1  - Create XFS with label
  • mkdir -p /mnt/data   - Create mount point
  • lsblk $LOOP1         - Verify partition exists
  • blkid ${LOOP1}p1     - Verify filesystem and label
EOF
}

validate_step_1() {
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    
    # Give kernel a moment to settle
    sleep 1
    partprobe "$LOOP1" 2>/dev/null || true
    sleep 1
    
    # Check if partition exists (more flexible checking)
    local part_exists=0
    if [ -b "${LOOP1}p1" ]; then
        part_exists=1
    elif lsblk "$LOOP1" 2>/dev/null | grep -qE "├─|└─"; then
        part_exists=1
    fi
    
    if [ $part_exists -eq 0 ]; then
        echo ""
        print_color "$RED" "✗ No partition found on $LOOP1"
        echo "  Expected to see ${LOOP1}p1"
        echo "  Try: fdisk $LOOP1 (use 'g', 'n', 'w')"
        echo "  Then: partprobe $LOOP1"
        return 1
    fi
    
    # Check partition type (should be GPT)
    if ! fdisk -l "$LOOP1" 2>/dev/null | grep -q "Disklabel type: gpt"; then
        echo ""
        print_color "$RED" "✗ Disk $LOOP1 does not have GPT partition table"
        echo "  Try: fdisk $LOOP1, then use 'g' to create GPT table"
        return 1
    fi
    
    # Check if filesystem exists
    sleep 1
    if ! blkid "${LOOP1}p1" 2>/dev/null | grep -q 'TYPE="xfs"'; then
        echo ""
        print_color "$RED" "✗ No XFS filesystem found on ${LOOP1}p1"
        echo "  Try: mkfs.xfs -L DATA ${LOOP1}p1"
        return 1
    fi
    
    # Check if label is set
    if ! blkid "${LOOP1}p1" 2>/dev/null | grep -q 'LABEL="DATA"'; then
        echo ""
        print_color "$RED" "✗ Filesystem label is not set to 'DATA'"
        echo "  Fix: xfs_admin -L DATA ${LOOP1}p1"
        return 1
    fi
    
    # Check if mount point exists
    if [ ! -d /mnt/data ]; then
        echo ""
        print_color "$RED" "✗ Mount point /mnt/data does not exist"
        echo "  Try: mkdir -p /mnt/data"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    
    cat << EOF

SOLUTION:
─────────
Commands:
  fdisk $LOOP1
  # Inside fdisk:
  g       # Create GPT partition table
  n       # New partition
  [Enter] # Default partition number (1)
  [Enter] # Default first sector
  [Enter] # Default last sector (entire disk)
  w       # Write and exit
  
  partprobe $LOOP1              # Update kernel partition table
  mkfs.xfs -L DATA ${LOOP1}p1  # Create XFS with label
  mkdir -p /mnt/data            # Create mount point

Explanation:
  • g: Creates GPT partition table (supports >2TB, 128 partitions max)
  • n: Creates new partition with default values (uses entire disk)
  • partprobe: Forces kernel to re-read partition table without reboot
    (Critical for loop devices and newly created partitions)
  • mkfs.xfs -L DATA: Creates XFS filesystem with label "DATA"
  • mkdir -p: Creates mount point directory

Why partprobe matters:
  After fdisk modifies the partition table, the kernel needs to be informed.
  Without partprobe, the partition may not appear in /dev/ immediately.
  This is especially important with loop devices.

Verification:
  lsblk $LOOP1
  # Should show ${LOOP1}p1 as a partition
  
  blkid ${LOOP1}p1
  # Should show TYPE="xfs" LABEL="DATA"

EOF
}

hint_step_1() {
    echo "  fdisk: 'g' for GPT, 'n' for partition, 'w' to save"
    echo "  Don't forget: partprobe after fdisk!"
}

# STEP 2: Configure persistent mount for DATA
show_step_2() {
    cat << 'EOF'
TASK: Add DATA filesystem to /etc/fstab for persistent mounting

/etc/fstab defines which filesystems mount automatically at boot. You'll add an
entry using the label (not device path) for better reliability.

Requirements:
  • Add entry to /etc/fstab using LABEL=DATA
  • Mount point: /mnt/data
  • Filesystem type: xfs
  • Options: defaults
  • Dump: 0, Pass: 0
  • Test with 'mount -a' to verify

Commands you might need:
  • echo "LABEL=DATA /mnt/data xfs defaults 0 0" >> /etc/fstab
  • findmnt --verify  - Check fstab syntax
  • mount -a          - Mount all from fstab
  • df -h /mnt/data   - Verify mount

/etc/fstab format:
  LABEL=DATA  /mnt/data  xfs  defaults  0  0
  │           │          │    │         │  └─ fsck pass (0=skip)
  │           │          │    │         └─ dump flag (0=no backup)
  │           │          │    └─ mount options
  │           │          └─ filesystem type
  │           └─ mount point
  └─ device identifier
EOF
}

validate_step_2() {
    # Check if fstab entry exists
    if ! grep -q "LABEL=DATA" /etc/fstab; then
        echo ""
        print_color "$RED" "✗ No fstab entry found for LABEL=DATA"
        echo "  Add: LABEL=DATA /mnt/data xfs defaults 0 0"
        return 1
    fi
    
    # Verify entry format
    local fstab_line=$(grep "LABEL=DATA" /etc/fstab | grep -v "^#")
    if ! echo "$fstab_line" | grep -q "/mnt/data"; then
        echo ""
        print_color "$RED" "✗ fstab entry doesn't specify /mnt/data mount point"
        return 1
    fi
    
    if ! echo "$fstab_line" | grep -q "xfs"; then
        echo ""
        print_color "$RED" "✗ fstab entry doesn't specify xfs filesystem type"
        return 1
    fi
    
    # Check if mounted
    if ! mountpoint -q /mnt/data; then
        echo ""
        print_color "$YELLOW" "⚠ /mnt/data is not currently mounted"
        echo "  Test: mount -a"
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  echo "LABEL=DATA  /mnt/data  xfs  defaults  0  0" >> /etc/fstab
  findmnt --verify
  mount -a
  df -h /mnt/data

Explanation:
  • LABEL=DATA: Uses label (more reliable than /dev paths)
  • /mnt/data: Mount point location
  • xfs: Filesystem type
  • defaults: Standard options (rw,suid,dev,exec,auto,nouser,async)
  • 0 0: No dump backup, no fsck check

Verification:
  grep DATA /etc/fstab
  findmnt /mnt/data
  # Should show LABEL=DATA as source

EOF
}

hint_step_2() {
    echo "  Format: LABEL=DATA /mnt/data xfs defaults 0 0"
}

# STEP 3: Create GPT partition and ext4 on second disk
show_step_3() {
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    cat << EOF
TASK: Create GPT partition on $LOOP2 and format with ext4 labeled "BACKUP"

Repeat the process for the backup disk, but using ext4 filesystem instead of XFS.

Requirements:
  • Create GPT partition table on $LOOP2
  • Create one partition using entire disk
  • Run partprobe after fdisk
  • Create ext4 filesystem with label "BACKUP"
  • Create mount point /mnt/backup

Commands you might need:
  • fdisk $LOOP2 (use 'g', 'n', 'w')
  • partprobe $LOOP2
  • mkfs.ext4 -L BACKUP ${LOOP2}p1
  • mkdir -p /mnt/backup
  • blkid ${LOOP2}p1
EOF
}

validate_step_3() {
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    sleep 1
    partprobe "$LOOP2" 2>/dev/null || true
    sleep 1
    
    # Check partition exists
    local part_exists=0
    if [ -b "${LOOP2}p1" ]; then
        part_exists=1
    elif lsblk "$LOOP2" 2>/dev/null | grep -qE "├─|└─"; then
        part_exists=1
    fi
    
    if [ $part_exists -eq 0 ]; then
        echo ""
        print_color "$RED" "✗ No partition found on $LOOP2"
        echo "  Try: fdisk $LOOP2 (g, n, w), then partprobe $LOOP2"
        return 1
    fi
    
    # Check GPT
    if ! fdisk -l "$LOOP2" 2>/dev/null | grep -q "Disklabel type: gpt"; then
        echo ""
        print_color "$RED" "✗ Disk $LOOP2 does not have GPT partition table"
        return 1
    fi
    
    # Check ext4 filesystem
    sleep 1
    if ! blkid "${LOOP2}p1" 2>/dev/null | grep -q 'TYPE="ext4"'; then
        echo ""
        print_color "$RED" "✗ No ext4 filesystem found on ${LOOP2}p1"
        echo "  Try: mkfs.ext4 -L BACKUP ${LOOP2}p1"
        return 1
    fi
    
    # Check label
    if ! blkid "${LOOP2}p1" 2>/dev/null | grep -q 'LABEL="BACKUP"'; then
        echo ""
        print_color "$RED" "✗ Filesystem label is not 'BACKUP'"
        echo "  Fix: tune2fs -L BACKUP ${LOOP2}p1"
        return 1
    fi
    
    # Check mount point
    if [ ! -d /mnt/backup ]; then
        echo ""
        print_color "$RED" "✗ Mount point /mnt/backup does not exist"
        echo "  Try: mkdir -p /mnt/backup"
        return 1
    fi
    
    return 0
}

solution_step_3() {
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    cat << EOF

SOLUTION:
─────────
Commands:
  fdisk $LOOP2
  g       # GPT table
  n       # New partition
  [Enter] # Defaults
  [Enter]
  [Enter]
  w       # Write
  
  partprobe $LOOP2
  mkfs.ext4 -L BACKUP ${LOOP2}p1
  mkdir -p /mnt/backup

Explanation:
  Same process as step 1, but with ext4 instead of XFS.

Verification:
  lsblk $LOOP2
  blkid ${LOOP2}p1

EOF
}

hint_step_3() {
    echo "  Same as step 1: fdisk, partprobe, mkfs.ext4"
}

# STEP 4: Configure persistent mount for BACKUP
show_step_4() {
    cat << 'EOF'
TASK: Add BACKUP filesystem to /etc/fstab

Add the second mount configuration to fstab, using the same format as DATA.

Requirements:
  • Add entry using LABEL=BACKUP
  • Mount point: /mnt/backup
  • Filesystem type: ext4
  • Options: defaults
  • Dump and pass: 0 0

Commands you might need:
  • echo "LABEL=BACKUP /mnt/backup ext4 defaults 0 0" >> /etc/fstab
  • findmnt --verify
EOF
}

validate_step_4() {
    # Check fstab entry
    if ! grep -q "LABEL=BACKUP" /etc/fstab; then
        echo ""
        print_color "$RED" "✗ No fstab entry for LABEL=BACKUP"
        echo "  Add: LABEL=BACKUP /mnt/backup ext4 defaults 0 0"
        return 1
    fi
    
    local fstab_line=$(grep "LABEL=BACKUP" /etc/fstab | grep -v "^#")
    if ! echo "$fstab_line" | grep -q "/mnt/backup"; then
        echo ""
        print_color "$RED" "✗ fstab entry doesn't specify /mnt/backup"
        return 1
    fi
    
    if ! echo "$fstab_line" | grep -q "ext4"; then
        echo ""
        print_color "$RED" "✗ fstab entry doesn't specify ext4"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  echo "LABEL=BACKUP  /mnt/backup  ext4  defaults  0  0" >> /etc/fstab
  findmnt --verify

Verification:
  grep BACKUP /etc/fstab

EOF
}

hint_step_4() {
    echo "  Format: LABEL=BACKUP /mnt/backup ext4 defaults 0 0"
}

# STEP 5: Test all mounts
show_step_5() {
    cat << 'EOF'
TASK: Verify both filesystems mount correctly from /etc/fstab

Test that everything works by unmounting and remounting via fstab.

Requirements:
  • Unmount both /mnt/data and /mnt/backup
  • Use 'mount -a' to mount all from fstab
  • Verify both are mounted

Commands you might need:
  • umount /mnt/data /mnt/backup
  • mount -a
  • df -h | grep /mnt
  • findmnt | grep /mnt
EOF
}

validate_step_5() {
    # Check both are mounted
    if ! mountpoint -q /mnt/data; then
        echo ""
        print_color "$RED" "✗ /mnt/data is not mounted"
        echo "  Try: mount -a"
        return 1
    fi
    
    if ! mountpoint -q /mnt/backup; then
        echo ""
        print_color "$RED" "✗ /mnt/backup is not mounted"
        echo "  Try: mount -a"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  umount /mnt/data /mnt/backup
  mount -a
  df -h | grep /mnt

Explanation:
  This simulates boot. systemd reads /etc/fstab and mounts all filesystems.

Verification:
  mount | grep /mnt
  # Both should show as mounted

EOF
}

hint_step_5() {
    echo "  Unmount both, then: mount -a"
}

#############################################################################
# VALIDATION: Standard Mode
#############################################################################
validate() {
    local score=0
    local total=5
    
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    # Force partition table refresh
    partprobe "$LOOP1" 2>/dev/null || true
    partprobe "$LOOP2" 2>/dev/null || true
    sleep 1
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: First disk complete
    print_color "$CYAN" "[1/$total] Checking $LOOP1 partition and XFS filesystem..."
    local check1_ok=1
    
    if ! lsblk "$LOOP1" 2>/dev/null | grep -qE "├─|└─" && ! [ -b "${LOOP1}p1" ]; then
        print_color "$RED" "  ✗ No partition on $LOOP1"
        check1_ok=0
    elif ! fdisk -l "$LOOP1" 2>/dev/null | grep -q "Disklabel type: gpt"; then
        print_color "$RED" "  ✗ Not using GPT"
        check1_ok=0
    elif ! blkid "${LOOP1}p1" 2>/dev/null | grep -q 'TYPE="xfs"'; then
        print_color "$RED" "  ✗ No XFS filesystem"
        check1_ok=0
    elif ! blkid "${LOOP1}p1" 2>/dev/null | grep -q 'LABEL="DATA"'; then
        print_color "$RED" "  ✗ Missing label 'DATA'"
        check1_ok=0
    elif [ ! -d /mnt/data ]; then
        print_color "$RED" "  ✗ Mount point /mnt/data missing"
        check1_ok=0
    fi
    
    if [ $check1_ok -eq 1 ]; then
        print_color "$GREEN" "  ✓ Partition + XFS + label correct"
        ((score++))
    fi
    echo ""
    
    # CHECK 2: fstab for DATA
    print_color "$CYAN" "[2/$total] Checking /etc/fstab entry for DATA..."
    if grep -q "LABEL=DATA" /etc/fstab && \
       grep "LABEL=DATA" /etc/fstab | grep -q "/mnt/data" && \
       grep "LABEL=DATA" /etc/fstab | grep -q "xfs"; then
        print_color "$GREEN" "  ✓ Correct fstab entry"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or incorrect fstab entry"
    fi
    echo ""
    
    # CHECK 3: Second disk complete
    print_color "$CYAN" "[3/$total] Checking $LOOP2 partition and ext4 filesystem..."
    local check3_ok=1
    
    if ! lsblk "$LOOP2" 2>/dev/null | grep -qE "├─|└─" && ! [ -b "${LOOP2}p1" ]; then
        print_color "$RED" "  ✗ No partition on $LOOP2"
        check3_ok=0
    elif ! fdisk -l "$LOOP2" 2>/dev/null | grep -q "Disklabel type: gpt"; then
        print_color "$RED" "  ✗ Not using GPT"
        check3_ok=0
    elif ! blkid "${LOOP2}p1" 2>/dev/null | grep -q 'TYPE="ext4"'; then
        print_color "$RED" "  ✗ No ext4 filesystem"
        check3_ok=0
    elif ! blkid "${LOOP2}p1" 2>/dev/null | grep -q 'LABEL="BACKUP"'; then
        print_color "$RED" "  ✗ Missing label 'BACKUP'"
        check3_ok=0
    elif [ ! -d /mnt/backup ]; then
        print_color "$RED" "  ✗ Mount point /mnt/backup missing"
        check3_ok=0
    fi
    
    if [ $check3_ok -eq 1 ]; then
        print_color "$GREEN" "  ✓ Partition + ext4 + label correct"
        ((score++))
    fi
    echo ""
    
    # CHECK 4: fstab for BACKUP
    print_color "$CYAN" "[4/$total] Checking /etc/fstab entry for BACKUP..."
    if grep -q "LABEL=BACKUP" /etc/fstab && \
       grep "LABEL=BACKUP" /etc/fstab | grep -q "/mnt/backup" && \
       grep "LABEL=BACKUP" /etc/fstab | grep -q "ext4"; then
        print_color "$GREEN" "  ✓ Correct fstab entry"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or incorrect fstab entry"
    fi
    echo ""
    
    # CHECK 5: Both mounted
    print_color "$CYAN" "[5/$total] Checking if filesystems are mounted..."
    if mountpoint -q /mnt/data && mountpoint -q /mnt/backup; then
        print_color "$GREEN" "  ✓ Both filesystems mounted"
        ((score++))
    else
        if ! mountpoint -q /mnt/data; then
            print_color "$RED" "  ✗ /mnt/data not mounted"
        fi
        if ! mountpoint -q /mnt/backup; then
            print_color "$RED" "  ✗ /mnt/backup not mounted"
        fi
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! Storage infrastructure is production-ready!"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Remember: partprobe after fdisk!"
        echo "Run with --solution to see detailed steps."
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
    LOOP1=$(cat /tmp/.lab-loop1 2>/dev/null || echo "/dev/loop0")
    LOOP2=$(cat /tmp/.lab-loop2 2>/dev/null || echo "/dev/loop1")
    
    cat << EOF
COMPLETE SOLUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Partition $LOOP1 + Create XFS
─────────────────────────────────────────────────────────────────
  fdisk $LOOP1
  g; n; [Enter x3]; w
  partprobe $LOOP1
  mkfs.xfs -L DATA ${LOOP1}p1
  mkdir -p /mnt/data

STEP 2: Add DATA to fstab
─────────────────────────────────────────────────────────────────
  echo "LABEL=DATA /mnt/data xfs defaults 0 0" >> /etc/fstab
  mount -a

STEP 3: Partition $LOOP2 + Create ext4
─────────────────────────────────────────────────────────────────
  fdisk $LOOP2
  g; n; [Enter x3]; w
  partprobe $LOOP2
  mkfs.ext4 -L BACKUP ${LOOP2}p1
  mkdir -p /mnt/backup

STEP 4: Add BACKUP to fstab
─────────────────────────────────────────────────────────────────
  echo "LABEL=BACKUP /mnt/backup ext4 defaults 0 0" >> /etc/fstab

STEP 5: Test
─────────────────────────────────────────────────────────────────
  umount /mnt/data /mnt/backup
  mount -a
  df -h | grep /mnt

KEY POINTS:
• partprobe is CRITICAL after fdisk for loop devices
• Use labels (not /dev paths) in fstab
• Test with mount -a before rebooting
• GPT: g, n, w in fdisk

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    umount /mnt/data 2>/dev/null || true
    umount /mnt/backup 2>/dev/null || true
    
    sed -i '/\/mnt\/data/d' /etc/fstab 2>/dev/null || true
    sed -i '/\/mnt\/backup/d' /etc/fstab 2>/dev/null || true
    sed -i '/LABEL=DATA/d' /etc/fstab 2>/dev/null || true
    sed -i '/LABEL=BACKUP/d' /etc/fstab 2>/dev/null || true
    
    rm -rf /mnt/data /mnt/backup 2>/dev/null || true
    
    if [ -f /tmp/.lab-loop1 ]; then
        LOOP1=$(cat /tmp/.lab-loop1)
        losetup -d "$LOOP1" 2>/dev/null || true
    fi
    
    if [ -f /tmp/.lab-loop2 ]; then
        LOOP2=$(cat /tmp/.lab-loop2)
        losetup -d "$LOOP2" 2>/dev/null || true
    fi
    
    for loop in $(losetup -j /var/lab-disks/disk1.img 2>/dev/null | cut -d: -f1); do
        losetup -d "$loop" 2>/dev/null || true
    done
    for loop in $(losetup -j /var/lab-disks/disk2.img 2>/dev/null | cut -d: -f1); do
        losetup -d "$loop" 2>/dev/null || true
    done
    
    rm -f /var/lab-disks/disk1.img /var/lab-disks/disk2.img 2>/dev/null || true
    rm -f /tmp/.lab-loop1 /tmp/.lab-loop2 2>/dev/null || true
    rmdir /var/lab-disks 2>/dev/null || true
    
    echo "  ✓ Cleanup complete"
}

main "$@"
