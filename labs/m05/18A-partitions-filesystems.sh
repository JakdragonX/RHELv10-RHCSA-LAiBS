#!/bin/bash
# labs/M05/18A-partitions-filesystems.sh
# Lab: Managing Partitions and Filesystems
# Difficulty: Intermediate
# RHCSA Objective: Create and configure file systems (partitions, mount points, /etc/fstab)

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing Partitions and Filesystems"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-35 minutes"

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
    
    # Remove any existing loop devices from previous attempts
    losetup -D 2>/dev/null || true
    
    # Create virtual disk files (2GB each)
    mkdir -p /var/lab-disks
    rm -f /var/lab-disks/disk1.img /var/lab-disks/disk2.img 2>/dev/null || true
    
    truncate -s 2G /var/lab-disks/disk1.img
    truncate -s 2G /var/lab-disks/disk2.img
    
    # Attach loop devices
    LOOP1=$(losetup -f)
    LOOP2=$(losetup -f)
    losetup "$LOOP1" /var/lab-disks/disk1.img
    losetup "$LOOP2" /var/lab-disks/disk2.img
    
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
    LOOP1=$(cat /tmp/.lab-loop1)
    LOOP2=$(cat /tmp/.lab-loop2)
    
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
  1. Create a GPT partition table on $LOOP1
     • Use the entire disk as a single partition
     • Set appropriate partition type for Linux filesystem

  2. Create an XFS filesystem on the $LOOP1 partition
     • Label the filesystem as "DATA"
     • Create mount point /mnt/data
     • Mount it temporarily to verify functionality

  3. Configure persistent mounting for /mnt/data
     • Add entry to /etc/fstab using LABEL=DATA
     • Use default mount options
     • Set dump and fsck values to 0 0
     • Verify with 'mount -a' before rebooting

  4. Create a GPT partition table on $LOOP2
     • Use the entire disk as a single partition

  5. Create an ext4 filesystem on the $LOOP2 partition
     • Label the filesystem as "BACKUP"
     • Create mount point /mnt/backup
     • Configure persistent mounting in /etc/fstab using the label
     • Mount and verify

HINTS:
  • Use 'lsblk' frequently to check your progress
  • In fdisk: 'g' creates GPT table, 'n' creates partition, 'w' writes changes
  • Remember to specify partition when creating filesystem (e.g., ${LOOP1}p1)
  • Use 'blkid' to verify labels were set correctly
  • Test fstab entries with 'findmnt --verify' before rebooting
  • Always use 'mount -a' to test fstab changes without rebooting

SUCCESS CRITERIA:
  • Both partitions created with GPT partition tables
  • XFS filesystem labeled "DATA" mounted at /mnt/data
  • ext4 filesystem labeled "BACKUP" mounted at /mnt/backup
  • Both mounts configured in /etc/fstab using labels
  • All mounts persist after 'umount' followed by 'mount -a'
  • No syntax errors in /etc/fstab (verify with findmnt --verify)
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    LOOP1=$(cat /tmp/.lab-loop1)
    LOOP2=$(cat /tmp/.lab-loop2)
    
    cat << EOF
  ☐ 1. Create GPT partition table on $LOOP1 with single partition
  ☐ 2. Create XFS filesystem labeled "DATA", mount at /mnt/data
  ☐ 3. Add DATA filesystem to /etc/fstab using label
  ☐ 4. Create GPT partition table on $LOOP2 with single partition
  ☐ 5. Create ext4 filesystem labeled "BACKUP", mount at /mnt/backup
  ☐ 6. Add BACKUP filesystem to /etc/fstab using label
  ☐ 7. Verify all mounts work with 'mount -a'
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################

get_step_count() {
    echo "7"
}

scenario_context() {
    LOOP1=$(cat /tmp/.lab-loop1)
    LOOP2=$(cat /tmp/.lab-loop2)
    
    cat << EOF
Your organization needs dedicated storage for application data and backups.
You have two disks available: $LOOP1 and $LOOP2 (each 2GB).
You'll create partitions, filesystems, and configure persistent mounts.
EOF
}

# STEP 1: Create GPT partition on first disk
show_step_1() {
    LOOP1=$(cat /tmp/.lab-loop1)
    
    cat << EOF
TASK: Create a GPT partition table on $LOOP1 with a single partition

Modern systems use GPT (GUID Partition Table) instead of the legacy MBR format.
GPT supports larger disks (>2TB), more partitions (128 vs 4), and better data
integrity with redundant partition tables.

Requirements:
  • Use fdisk to create GPT partition table on $LOOP1
  • Create one partition using all available space
  • Accept default partition type (Linux filesystem)
  • Write changes to disk

Commands you might need:
  • fdisk $LOOP1  - Enter interactive partition editor
    Within fdisk:
      g  - Create new GPT partition table (destroys existing data)
      n  - Create new partition (accept all defaults for full disk)
      w  - Write changes and exit
  • lsblk         - Verify partition was created
EOF
}

validate_step_1() {
    LOOP1=$(cat /tmp/.lab-loop1)
    
    # Check if partition exists
    if ! lsblk "$LOOP1" | grep -q "${LOOP1}p1"; then
        echo ""
        print_color "$RED" "✗ No partition found on $LOOP1"
        echo "  Expected to see ${LOOP1}p1"
        echo "  Try: fdisk $LOOP1"
        echo "       Then use 'g' to create GPT table, 'n' for new partition, 'w' to write"
        return 1
    fi
    
    # Check partition type (should be GPT)
    if ! fdisk -l "$LOOP1" 2>/dev/null | grep -q "Disklabel type: gpt"; then
        echo ""
        print_color "$RED" "✗ Disk $LOOP1 does not have GPT partition table"
        echo "  Found: $(fdisk -l $LOOP1 2>/dev/null | grep 'Disklabel type' | awk '{print $3}')"
        echo "  Try: fdisk $LOOP1, then use 'g' to create GPT table"
        return 1
    fi
    
    return 0
}

solution_step_1() {
    LOOP1=$(cat /tmp/.lab-loop1)
    
    cat << EOF

SOLUTION:
─────────
Commands:
  fdisk $LOOP1
  
  # Inside fdisk interactive prompt:
  g      # Create new GPT partition table
  n      # Create new partition
  [Enter] # Accept default partition number (1)
  [Enter] # Accept default first sector
  [Enter] # Accept default last sector (uses entire disk)
  w      # Write changes and exit

Explanation:
  • g: Creates a GPT partition table, replacing any existing partition scheme
  • n: Starts the new partition creation process
  • Default values: Use the entire disk as a single partition
  • w: Commits all changes to the disk

Why GPT matters:
  GPT is the modern standard replacing MBR. It stores partition data in multiple
  locations (providing redundancy), supports disks larger than 2TB, allows up to
  128 partitions, and uses CRC32 checksums for data integrity. UEFI systems
  require GPT for booting.

Verification:
  lsblk $LOOP1
  # Expected output: You should see ${LOOP1}p1 listed as a partition
  
  fdisk -l $LOOP1 | grep "Disklabel type"
  # Expected output: Disklabel type: gpt

EOF
}

hint_step_1() {
    echo "  Use fdisk interactively: 'g' for GPT, 'n' for new partition, 'w' to save"
}

# STEP 2: Create XFS filesystem with label
show_step_2() {
    LOOP1=$(cat /tmp/.lab-loop1)
    
    cat << EOF
TASK: Create an XFS filesystem labeled "DATA" on ${LOOP1}p1

XFS is RHEL's default filesystem since RHEL 7. It excels at handling large files
and high-performance workloads. The label allows you to reference the filesystem
by name rather than device path, which is more reliable when hardware changes.

Requirements:
  • Create XFS filesystem on ${LOOP1}p1
  • Set filesystem label to "DATA"
  • Create mount point directory /mnt/data
  • Temporarily mount the filesystem to verify it works

Commands you might need:
  • mkfs.xfs -L DATA ${LOOP1}p1  - Create XFS filesystem with label
  • mkdir -p /mnt/data            - Create mount point
  • mount ${LOOP1}p1 /mnt/data   - Mount filesystem temporarily
  • blkid ${LOOP1}p1              - Verify label was set
  • df -h /mnt/data               - Confirm filesystem is mounted
EOF
}

validate_step_2() {
    LOOP1=$(cat /tmp/.lab-loop1)
    
    # Check if filesystem exists
    if ! blkid "${LOOP1}p1" | grep -q 'TYPE="xfs"'; then
        echo ""
        print_color "$RED" "✗ No XFS filesystem found on ${LOOP1}p1"
        echo "  Try: mkfs.xfs -L DATA ${LOOP1}p1"
        return 1
    fi
    
    # Check if label is set
    if ! blkid "${LOOP1}p1" | grep -q 'LABEL="DATA"'; then
        echo ""
        print_color "$RED" "✗ Filesystem label is not set to 'DATA'"
        local current_label=$(blkid "${LOOP1}p1" | grep -o 'LABEL="[^"]*"' || echo "none")
        echo "  Current label: $current_label"
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
    
    # Check if mounted (temporarily for this step)
    if ! mountpoint -q /mnt/data; then
        echo ""
        print_color "$YELLOW" "⚠ Filesystem not currently mounted at /mnt/data"
        echo "  This is OK if you've already tested it and unmounted"
        echo "  If you haven't tested yet: mount ${LOOP1}p1 /mnt/data"
    fi
    
    return 0
}

solution_step_2() {
    LOOP1=$(cat /tmp/.lab-loop1)
    
    cat << EOF

SOLUTION:
─────────
Commands:
  mkfs.xfs -L DATA ${LOOP1}p1
  mkdir -p /mnt/data
  mount ${LOOP1}p1 /mnt/data
  df -h /mnt/data

Explanation:
  • mkfs.xfs: Creates an XFS filesystem
  • -L DATA: Sets the filesystem label to "DATA"
  • ${LOOP1}p1: The partition to format (p1 = partition 1)
  • mkdir -p: Creates directory, including parent directories if needed
  • mount: Attaches the filesystem to the directory tree

Why labels matter:
  Device names like /dev/loop0p1 can change between reboots, especially after
  hardware changes or adding new disks. Labels provide a persistent identifier
  that remains constant. Labels are also more human-readable and self-documenting
  in configuration files.

Verification:
  blkid ${LOOP1}p1
  # Expected output: Should show TYPE="xfs" and LABEL="DATA"
  
  lsblk -f
  # Expected output: Shows filesystem type and label for all devices
  
  df -h | grep /mnt/data
  # Expected output: Shows mounted filesystem with size and usage

EOF
}

hint_step_2() {
    echo "  Use mkfs.xfs with -L flag for the label, then mount to test"
}

# STEP 3: Configure persistent mount in fstab
show_step_3() {
    cat << 'EOF'
TASK: Add DATA filesystem to /etc/fstab for persistent mounting

/etc/fstab (filesystem table) is the configuration file that defines which
filesystems should be mounted automatically at boot. Each line represents one
filesystem with six fields separated by whitespace.

Requirements:
  • Add entry to /etc/fstab for the DATA filesystem
  • Use LABEL=DATA (not device path)
  • Mount point: /mnt/data
  • Filesystem type: xfs
  • Mount options: defaults
  • Dump frequency: 0 (no dump backup needed)
  • fsck pass number: 0 (no filesystem check at boot for non-root FS)

Commands you might need:
  • echo "LABEL=DATA /mnt/data xfs defaults 0 0" >> /etc/fstab
  • findmnt --verify  - Check fstab syntax before testing
  • umount /mnt/data  - Unmount current mount
  • mount -a          - Mount all filesystems defined in fstab
  • df -h /mnt/data   - Verify it mounted correctly

/etc/fstab format (6 fields):
  1. Device: LABEL=DATA (or UUID=xxx or /dev/xxx)
  2. Mount point: /mnt/data
  3. Filesystem type: xfs
  4. Options: defaults (rw, suid, dev, exec, auto, nouser, async)
  5. Dump: 0 (0=no backup, 1=backup with dump command)
  6. Pass: 0 (0=no fsck, 1=root FS, 2=other FS to check after root)
EOF
}

validate_step_3() {
    # Check if fstab entry exists
    if ! grep -q "LABEL=DATA" /etc/fstab; then
        echo ""
        print_color "$RED" "✗ No fstab entry found for LABEL=DATA"
        echo "  Add line: LABEL=DATA /mnt/data xfs defaults 0 0"
        echo "  Try: echo 'LABEL=DATA /mnt/data xfs defaults 0 0' >> /etc/fstab"
        return 1
    fi
    
    # Check if entry is formatted correctly (basic check)
    local fstab_line=$(grep "LABEL=DATA" /etc/fstab | grep -v "^#")
    if ! echo "$fstab_line" | grep -q "/mnt/data"; then
        echo ""
        print_color "$RED" "✗ fstab entry for DATA doesn't specify /mnt/data mount point"
        echo "  Current entry: $fstab_line"
        return 1
    fi
    
    if ! echo "$fstab_line" | grep -q "xfs"; then
        echo ""
        print_color "$RED" "✗ fstab entry doesn't specify xfs filesystem type"
        echo "  Current entry: $fstab_line"
        return 1
    fi
    
    # Verify with findmnt if possible
    if ! findmnt --verify --tab-file /etc/fstab 2>&1 | grep -q "0 parse errors" && \
       ! findmnt --verify --tab-file /etc/fstab 2>&1 | grep -q "Success"; then
        echo ""
        print_color "$YELLOW" "⚠ Warning: fstab may have syntax issues"
        echo "  Check with: findmnt --verify"
    fi
    
    # Check if currently mounted via fstab
    if ! mountpoint -q /mnt/data; then
        echo ""
        print_color "$YELLOW" "⚠ /mnt/data is not currently mounted"
        echo "  Test your fstab entry: umount /mnt/data 2>/dev/null; mount -a"
        return 1
    fi
    
    # Verify it's mounted with the label
    if ! findmnt /mnt/data | grep -q "LABEL=DATA"; then
        echo ""
        print_color "$YELLOW" "⚠ /mnt/data is mounted but not using LABEL=DATA"
        echo "  Current mount: $(findmnt -n -o SOURCE /mnt/data)"
        echo "  Unmount and remount using fstab: umount /mnt/data; mount -a"
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  # Add to fstab
  echo "LABEL=DATA  /mnt/data  xfs  defaults  0  0" >> /etc/fstab
  
  # Verify syntax
  findmnt --verify
  
  # Test the configuration
  umount /mnt/data
  mount -a
  df -h /mnt/data

Explanation:
  • LABEL=DATA: Identifies filesystem by label (more reliable than device paths)
  • /mnt/data: Where the filesystem will be accessible in the directory tree
  • xfs: Filesystem type (kernel uses this to load correct driver)
  • defaults: Shorthand for: rw,suid,dev,exec,auto,nouser,async
  • 0 0: First 0 = no dump backup, second 0 = no fsck at boot

Understanding fstab fields in detail:
  Field 4 (Options):
    • defaults = rw (read-write), suid (allow set-UID), dev (allow device files),
                 exec (allow executables), auto (mount at boot), nouser (only root
                 can mount), async (I/O is asynchronous)
  
  Field 5 (Dump):
    • 0 = Don't backup with dump utility
    • 1 = Backup with dump utility (rarely used anymore)
  
  Field 6 (Pass):
    • 0 = Don't check filesystem at boot
    • 1 = Check first (used only for root filesystem)
    • 2 = Check after filesystems with pass=1 (for other important filesystems)

Why mount -a is essential:
  'mount -a' reads /etc/fstab and mounts all filesystems marked with 'auto' option
  that aren't already mounted. This lets you test your fstab configuration without
  rebooting. If mount -a fails, fix the error before rebooting or your system
  may drop to emergency mode.

Verification:
  cat /etc/fstab | grep DATA
  # Expected output: LABEL=DATA /mnt/data xfs defaults 0 0
  
  findmnt /mnt/data
  # Expected output: Shows mount point with LABEL=DATA as source
  
  mount | grep /mnt/data
  # Expected output: Shows mounted filesystem with options

EOF
}

hint_step_3() {
    echo "  Format: LABEL=DATA /mnt/data xfs defaults 0 0"
    echo "  Test with: umount /mnt/data; mount -a"
}

# STEP 4: Create GPT partition on second disk
show_step_4() {
    LOOP2=$(cat /tmp/.lab-loop2)
    
    cat << EOF
TASK: Create a GPT partition table on $LOOP2 with a single partition

Now you'll repeat the partitioning process for the backup disk. This follows
the same procedure as step 1 but on a different disk.

Requirements:
  • Use fdisk to create GPT partition table on $LOOP2
  • Create one partition using all available space
  • Write changes to disk

Commands you might need:
  • fdisk $LOOP2  - Enter interactive partition editor
  • lsblk $LOOP2  - Verify partition was created
EOF
}

validate_step_4() {
    LOOP2=$(cat /tmp/.lab-loop2)
    
    if ! lsblk "$LOOP2" | grep -q "${LOOP2}p1"; then
        echo ""
        print_color "$RED" "✗ No partition found on $LOOP2"
        echo "  Try: fdisk $LOOP2 (use 'g', 'n', 'w')"
        return 1
    fi
    
    if ! fdisk -l "$LOOP2" 2>/dev/null | grep -q "Disklabel type: gpt"; then
        echo ""
        print_color "$RED" "✗ Disk $LOOP2 does not have GPT partition table"
        return 1
    fi
    
    return 0
}

solution_step_4() {
    LOOP2=$(cat /tmp/.lab-loop2)
    
    cat << EOF

SOLUTION:
─────────
Commands:
  fdisk $LOOP2
  g      # Create GPT table
  n      # New partition
  [Enter] # Default partition number
  [Enter] # Default first sector
  [Enter] # Default last sector
  w      # Write and exit

Explanation:
  Same process as step 1, just on a different disk. GPT allows you to create
  up to 128 partitions if needed, though we're only creating one here.

Verification:
  lsblk $LOOP2
  fdisk -l $LOOP2 | grep "Disklabel type"

EOF
}

hint_step_4() {
    echo "  Same as step 1: fdisk, then 'g', 'n', 'w'"
}

# STEP 5: Create ext4 filesystem with label
show_step_5() {
    LOOP2=$(cat /tmp/.lab-loop2)
    
    cat << EOF
TASK: Create an ext4 filesystem labeled "BACKUP" on ${LOOP2}p1

ext4 is the predecessor to XFS and still widely used. It's mature, reliable, and
has excellent data recovery tools. Unlike XFS, ext4 supports both growing and
shrinking filesystems.

Requirements:
  • Create ext4 filesystem on ${LOOP2}p1
  • Set filesystem label to "BACKUP"
  • Create mount point directory /mnt/backup

Commands you might need:
  • mkfs.ext4 -L BACKUP ${LOOP2}p1  - Create ext4 filesystem with label
  • mkdir -p /mnt/backup             - Create mount point
  • blkid ${LOOP2}p1                 - Verify label
EOF
}

validate_step_5() {
    LOOP2=$(cat /tmp/.lab-loop2)
    
    if ! blkid "${LOOP2}p1" | grep -q 'TYPE="ext4"'; then
        echo ""
        print_color "$RED" "✗ No ext4 filesystem found on ${LOOP2}p1"
        echo "  Try: mkfs.ext4 -L BACKUP ${LOOP2}p1"
        return 1
    fi
    
    if ! blkid "${LOOP2}p1" | grep -q 'LABEL="BACKUP"'; then
        echo ""
        print_color "$RED" "✗ Filesystem label is not set to 'BACKUP'"
        echo "  Fix: tune2fs -L BACKUP ${LOOP2}p1"
        return 1
    fi
    
    if [ ! -d /mnt/backup ]; then
        echo ""
        print_color "$RED" "✗ Mount point /mnt/backup does not exist"
        echo "  Try: mkdir -p /mnt/backup"
        return 1
    fi
    
    return 0
}

solution_step_5() {
    LOOP2=$(cat /tmp/.lab-loop2)
    
    cat << EOF

SOLUTION:
─────────
Commands:
  mkfs.ext4 -L BACKUP ${LOOP2}p1
  mkdir -p /mnt/backup

Explanation:
  • mkfs.ext4: Creates an ext4 filesystem
  • -L BACKUP: Sets the label to "BACKUP"
  
  ext4 vs XFS differences:
    • ext4: Can be shrunk and grown, better for smaller files, more mature tools
    • XFS: Can only be grown, better for large files, RHEL default since RHEL 7
    • Both are stable and production-ready

Verification:
  blkid ${LOOP2}p1
  lsblk -f | grep loop

EOF
}

hint_step_5() {
    echo "  Use mkfs.ext4 with -L flag, similar to mkfs.xfs earlier"
}

# STEP 6: Configure persistent mount for backup
show_step_6() {
    cat << 'EOF'
TASK: Add BACKUP filesystem to /etc/fstab for persistent mounting

Add the second mount to fstab, following the same format as the DATA mount.

Requirements:
  • Add entry to /etc/fstab for BACKUP filesystem
  • Use LABEL=BACKUP
  • Mount point: /mnt/backup
  • Filesystem type: ext4
  • Mount options: defaults
  • Dump and pass: 0 0

Commands you might need:
  • echo "LABEL=BACKUP /mnt/backup ext4 defaults 0 0" >> /etc/fstab
  • findmnt --verify
EOF
}

validate_step_6() {
    if ! grep -q "LABEL=BACKUP" /etc/fstab; then
        echo ""
        print_color "$RED" "✗ No fstab entry found for LABEL=BACKUP"
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
        print_color "$RED" "✗ fstab entry doesn't specify ext4 filesystem"
        return 1
    fi
    
    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  echo "LABEL=BACKUP  /mnt/backup  ext4  defaults  0  0" >> /etc/fstab
  findmnt --verify

Explanation:
  Same format as DATA entry, just different label, mount point, and filesystem type.

Verification:
  cat /etc/fstab | grep BACKUP
  # Expected output: LABEL=BACKUP /mnt/backup ext4 defaults 0 0

EOF
}

hint_step_6() {
    echo "  Format: LABEL=BACKUP /mnt/backup ext4 defaults 0 0"
}

# STEP 7: Test all mounts
show_step_7() {
    cat << 'EOF'
TASK: Verify both filesystems mount correctly from /etc/fstab

The final step is to ensure everything works together. You'll unmount both
filesystems and remount them using only the fstab configuration.

Requirements:
  • Unmount both /mnt/data and /mnt/backup
  • Use 'mount -a' to mount all filesystems from fstab
  • Verify both are mounted correctly
  • Check that they're using the label-based mounts

Commands you might need:
  • umount /mnt/data /mnt/backup
  • mount -a
  • df -h | grep /mnt
  • lsblk -f
  • findmnt | grep /mnt
EOF
}

validate_step_7() {
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
    
    # Verify they're using the correct labels
    if ! findmnt -n -o SOURCE /mnt/data | grep -q "LABEL=DATA\|/dev/loop.*p1"; then
        echo ""
        print_color "$YELLOW" "⚠ /mnt/data might not be mounted via label"
    fi
    
    if ! findmnt -n -o SOURCE /mnt/backup | grep -q "LABEL=BACKUP\|/dev/loop.*p1"; then
        echo ""
        print_color "$YELLOW" "⚠ /mnt/backup might not be mounted via label"
    fi
    
    return 0
}

solution_step_7() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  umount /mnt/data /mnt/backup
  mount -a
  df -h | grep /mnt
  lsblk -f

Explanation:
  • umount: Disconnects the filesystems from their mount points
  • mount -a: Reads /etc/fstab and mounts all entries with 'auto' option
  • df -h: Shows mounted filesystems with human-readable sizes
  • lsblk -f: Shows block devices with filesystem info

This simulates what happens at boot:
  During system boot, systemd reads /etc/fstab and mounts all filesystems.
  By unmounting and using 'mount -a', you verify your configuration works
  exactly as it will after a reboot.

Verification:
  mount | grep /mnt
  # Expected output: Both /mnt/data and /mnt/backup shown as mounted
  
  findmnt /mnt/data /mnt/backup
  # Expected output: Shows both mount points with their labels

EOF
}

hint_step_7() {
    echo "  Unmount both, then run 'mount -a' to test fstab"
}

#############################################################################
# VALIDATION: Standard Mode
#############################################################################
validate() {
    local score=0
    local total=7
    
    LOOP1=$(cat /tmp/.lab-loop1)
    LOOP2=$(cat /tmp/.lab-loop2)
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: GPT partition on loop1
    print_color "$CYAN" "[1/$total] Checking $LOOP1 partition..."
    if lsblk "$LOOP1" | grep -q "${LOOP1}p1" && \
       fdisk -l "$LOOP1" 2>/dev/null | grep -q "Disklabel type: gpt"; then
        print_color "$GREEN" "  ✓ GPT partition table created on $LOOP1"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or incorrect partition on $LOOP1"
        print_color "$YELLOW" "  Fix: fdisk $LOOP1, then 'g', 'n', 'w'"
    fi
    echo ""
    
    # CHECK 2: XFS filesystem with DATA label
    print_color "$CYAN" "[2/$total] Checking XFS filesystem..."
    if blkid "${LOOP1}p1" 2>/dev/null | grep -q 'TYPE="xfs"' && \
       blkid "${LOOP1}p1" 2>/dev/null | grep -q 'LABEL="DATA"'; then
        print_color "$GREEN" "  ✓ XFS filesystem with label 'DATA' created"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or incorrect XFS filesystem"
        print_color "$YELLOW" "  Fix: mkfs.xfs -L DATA ${LOOP1}p1"
    fi
    echo ""
    
    # CHECK 3: /mnt/data mount point exists
    print_color "$CYAN" "[3/$total] Checking /mnt/data mount point..."
    if [ -d /mnt/data ]; then
        print_color "$GREEN" "  ✓ Mount point /mnt/data exists"
        ((score++))
    else
        print_color "$RED" "  ✗ Mount point /mnt/data does not exist"
        print_color "$YELLOW" "  Fix: mkdir -p /mnt/data"
    fi
    echo ""
    
    # CHECK 4: fstab entry for DATA
    print_color "$CYAN" "[4/$total] Checking /etc/fstab entry for DATA..."
    if grep -q "LABEL=DATA" /etc/fstab && \
       grep "LABEL=DATA" /etc/fstab | grep -q "/mnt/data" && \
       grep "LABEL=DATA" /etc/fstab | grep -q "xfs"; then
        print_color "$GREEN" "  ✓ Correct fstab entry for DATA filesystem"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or incorrect fstab entry for DATA"
        print_color "$YELLOW" "  Fix: echo 'LABEL=DATA /mnt/data xfs defaults 0 0' >> /etc/fstab"
    fi
    echo ""
    
    # CHECK 5: ext4 filesystem with BACKUP label
    print_color "$CYAN" "[5/$total] Checking ext4 filesystem..."
    if blkid "${LOOP2}p1" 2>/dev/null | grep -q 'TYPE="ext4"' && \
       blkid "${LOOP2}p1" 2>/dev/null | grep -q 'LABEL="BACKUP"'; then
        print_color "$GREEN" "  ✓ ext4 filesystem with label 'BACKUP' created"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or incorrect ext4 filesystem"
        print_color "$YELLOW" "  Fix: mkfs.ext4 -L BACKUP ${LOOP2}p1"
    fi
    echo ""
    
    # CHECK 6: fstab entry for BACKUP
    print_color "$CYAN" "[6/$total] Checking /etc/fstab entry for BACKUP..."
    if grep -q "LABEL=BACKUP" /etc/fstab && \
       grep "LABEL=BACKUP" /etc/fstab | grep -q "/mnt/backup" && \
       grep "LABEL=BACKUP" /etc/fstab | grep -q "ext4"; then
        print_color "$GREEN" "  ✓ Correct fstab entry for BACKUP filesystem"
        ((score++))
    else
        print_color "$RED" "  ✗ Missing or incorrect fstab entry for BACKUP"
        print_color "$YELLOW" "  Fix: echo 'LABEL=BACKUP /mnt/backup ext4 defaults 0 0' >> /etc/fstab"
    fi
    echo ""
    
    # CHECK 7: Both filesystems mounted
    print_color "$CYAN" "[7/$total] Checking if filesystems are mounted..."
    local both_mounted=0
    if mountpoint -q /mnt/data && mountpoint -q /mnt/backup; then
        print_color "$GREEN" "  ✓ Both filesystems are mounted"
        ((score++))
        both_mounted=1
    else
        if ! mountpoint -q /mnt/data; then
            print_color "$RED" "  ✗ /mnt/data is not mounted"
        fi
        if ! mountpoint -q /mnt/backup; then
            print_color "$RED" "  ✗ /mnt/backup is not mounted"
        fi
        print_color "$YELLOW" "  Fix: mount -a"
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've successfully:"
        echo "  • Created GPT partitions on both disks"
        echo "  • Formatted with XFS and ext4 filesystems"
        echo "  • Set meaningful labels for easy identification"
        echo "  • Configured persistent mounts in /etc/fstab"
        echo ""
        echo "Your storage infrastructure is production-ready!"
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
        echo "Run with --solution to see detailed steps."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Export for progress tracking
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION: Standard Mode
#############################################################################
solution() {
    LOOP1=$(cat /tmp/.lab-loop1)
    LOOP2=$(cat /tmp/.lab-loop2)
    
    cat << EOF
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Create GPT partition on $LOOP1
─────────────────────────────────────────────────────────────────
Commands:
  fdisk $LOOP1
  g      # Create GPT partition table
  n      # Create new partition
  [Enter] # Accept default partition number (1)
  [Enter] # Accept default first sector
  [Enter] # Accept default last sector (uses entire disk)
  w      # Write changes and exit

Explanation:
  • g: Initializes a new GPT (GUID Partition Table) on the disk
    - GPT is the modern replacement for MBR
    - Supports disks >2TB and up to 128 partitions
    - More reliable with redundant partition tables
  • n: Starts new partition creation wizard
  • Defaults: Creates one partition using all available space
  • w: Commits all changes to disk and exits fdisk

Verification:
  lsblk $LOOP1
  # Should show ${LOOP1}p1 as a child of $LOOP1
  
  fdisk -l $LOOP1 | grep "Disklabel type"
  # Should show: Disklabel type: gpt


STEP 2: Create XFS filesystem labeled "DATA"
─────────────────────────────────────────────────────────────────
Commands:
  mkfs.xfs -L DATA ${LOOP1}p1
  mkdir -p /mnt/data
  mount ${LOOP1}p1 /mnt/data
  df -h /mnt/data

Explanation:
  • mkfs.xfs: Creates XFS filesystem (RHEL default since RHEL 7)
  • -L DATA: Sets filesystem label to "DATA"
    - Labels provide persistent naming independent of device paths
    - More reliable than /dev/sdX which can change
  • mkdir -p: Creates mount point directory
    - -p creates parent directories if needed
    - Won't error if directory already exists
  • mount: Temporarily attaches filesystem to directory tree
  • df -h: Shows disk space usage in human-readable format

Why XFS:
  XFS excels at:
    • Large files and high-performance workloads
    • Parallel I/O operations
    • Guaranteed data integrity with CoW (Copy-on-Write)
  Limitations:
    • Cannot be shrunk (only grown)
    • Requires careful planning of initial size

Verification:
  blkid ${LOOP1}p1
  # Should show: TYPE="xfs" LABEL="DATA" UUID="..."
  
  lsblk -f | grep DATA
  # Shows filesystem type, label, and mount point


STEP 3: Add DATA to /etc/fstab
─────────────────────────────────────────────────────────────────
Commands:
  echo "LABEL=DATA  /mnt/data  xfs  defaults  0  0" >> /etc/fstab
  findmnt --verify
  umount /mnt/data
  mount -a
  df -h /mnt/data

Explanation:
  /etc/fstab format (6 fields, whitespace-separated):
    1. LABEL=DATA     - Device identifier (label, UUID, or path)
    2. /mnt/data      - Mount point (where it appears in filesystem)
    3. xfs            - Filesystem type
    4. defaults       - Mount options (expands to: rw,suid,dev,exec,auto,nouser,async)
    5. 0              - Dump backup flag (0=don't backup)
    6. 0              - fsck pass (0=don't check, 1=root FS, 2=other FS)

  • findmnt --verify: Checks /etc/fstab syntax for errors
  • umount: Disconnects filesystem to test fstab mount
  • mount -a: Mounts all filesystems defined in fstab with 'auto' option

Why this matters:
  At boot, systemd-fstab-generator reads /etc/fstab and creates mount units.
  Testing with 'mount -a' simulates boot behavior without rebooting.
  Errors in fstab can prevent system boot (drops to emergency shell).

Verification:
  grep DATA /etc/fstab
  # Should show: LABEL=DATA /mnt/data xfs defaults 0 0
  
  findmnt /mnt/data
  # Should show mount with LABEL=DATA as source


STEP 4: Create GPT partition on $LOOP2
─────────────────────────────────────────────────────────────────
Commands:
  fdisk $LOOP2
  g      # GPT table
  n      # New partition
  [Enter] # Default partition number
  [Enter] # Default first sector
  [Enter] # Default last sector
  w      # Write and exit

Explanation:
  Identical process to step 1, just on the second disk.
  GPT partition tables are independent per disk.

Verification:
  lsblk $LOOP2
  fdisk -l $LOOP2


STEP 5: Create ext4 filesystem labeled "BACKUP"
─────────────────────────────────────────────────────────────────
Commands:
  mkfs.ext4 -L BACKUP ${LOOP2}p1
  mkdir -p /mnt/backup
  mount ${LOOP2}p1 /mnt/backup
  df -h /mnt/backup

Explanation:
  • mkfs.ext4: Creates ext4 filesystem
  • -L BACKUP: Sets label to "BACKUP"

Why ext4:
  ext4 characteristics:
    • Mature and extremely stable (default filesystem RHEL 3-6)
    • Can be both grown AND shrunk (unlike XFS)
    • Excellent tools: e2fsck, debugfs, dumpe2fs
    • Better for many small files
  
  When to use ext4 vs XFS:
    • ext4: Need to shrink filesystem, many small files, maximum compatibility
    • XFS: Large files, high performance I/O, streaming workloads, RHEL standard

Verification:
  blkid ${LOOP2}p1
  # Should show: TYPE="ext4" LABEL="BACKUP"


STEP 6: Add BACKUP to /etc/fstab
─────────────────────────────────────────────────────────────────
Commands:
  echo "LABEL=BACKUP  /mnt/backup  ext4  defaults  0  0" >> /etc/fstab
  findmnt --verify

Explanation:
  Same format as DATA entry:
    • LABEL=BACKUP: Uses label for device identification
    • /mnt/backup: Mount point
    • ext4: Filesystem type
    • defaults: Standard mount options
    • 0 0: No dump, no fsck

Verification:
  grep BACKUP /etc/fstab


STEP 7: Test all mounts
─────────────────────────────────────────────────────────────────
Commands:
  umount /mnt/data /mnt/backup
  mount -a
  df -h | grep /mnt
  lsblk -f

Explanation:
  • Unmount both filesystems to start clean
  • mount -a reads fstab and mounts everything
  • Verifies configuration works as it will at boot

This is the critical test:
  If mount -a succeeds, your configuration is correct.
  If it fails, you'll see specific error messages about what's wrong.
  Always test fstab changes before rebooting!

Verification:
  mount | grep /mnt
  # Should show both /mnt/data and /mnt/backup
  
  findmnt | grep /mnt
  # Shows detailed mount information including labels


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GPT vs MBR:
  MBR (Master Boot Record):
    • 1981 PC specification (outdated)
    • 512 bytes for boot information
    • Maximum 4 primary partitions
    • Maximum 2TB disk size
    • Legacy compatibility only
  
  GPT (GUID Partition Table):
    • Modern standard (2010+)
    • 32 sectors for partition data
    • Up to 128 partitions
    • Supports disks up to 8 ZiB (~9 billion TB)
    • Redundant partition tables for reliability
    • Required for UEFI boot
    • CRC32 checksums for data integrity

Filesystem Labels vs UUIDs vs Device Paths:
  Device paths (/dev/sda1):
    ✗ Can change when hardware topology changes
    ✗ Not self-documenting
    ✓ Direct and simple
  
  UUIDs (universally unique identifiers):
    ✓ Guaranteed unique across all systems
    ✓ Never change unless filesystem reformatted
    ✗ Not human-readable
    ✗ Hard to remember/type
  
  Labels (LABEL=DATA):
    ✓ Human-readable and self-documenting
    ✓ Persistent across hardware changes
    ✓ Easy to remember and type
    ✗ Must be unique per system (you manage this)
    ✓ Best practice for most scenarios

The /etc/fstab Process:
  1. System boots
  2. systemd-fstab-generator reads /etc/fstab
  3. Creates .mount units in /run/systemd/generator/
  4. systemd activates mount units in dependency order
  5. Filesystems become available

  This is why:
    • Syntax errors break boot (system drops to emergency shell)
    • 'mount -a' is essential for testing
    • You can also create native .mount units for finer control


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting to write changes in fdisk
  Result: Exit fdisk without seeing partitions created
  Fix: Always use 'w' to write changes before exiting
       Use 'q' only if you want to cancel without saving

Mistake 2: Creating filesystem on disk instead of partition
  Result: Running 'mkfs.xfs /dev/loop0' instead of '/dev/loop0p1'
  Fix: Always specify the partition number (p1, p2, etc.)
       Use 'lsblk' to verify correct device path

Mistake 3: Typos in /etc/fstab
  Result: System won't boot, drops to emergency shell
  Prevention: 
    • Use 'findmnt --verify' before rebooting
    • Test with 'mount -a' immediately after editing
    • Keep backup of working fstab: cp /etc/fstab /etc/fstab.backup
  Recovery:
    • Boot to emergency shell
    • Remount root as read-write: mount -o remount,rw /
    • Fix fstab: vi /etc/fstab
    • Reboot: systemctl reboot

Mistake 4: Wrong filesystem type in fstab
  Result: Mount fails with "wrong fs type" error
  Fix: Verify actual filesystem type with 'blkid /dev/xxx'
       Match TYPE value in fstab (xfs, ext4, vfat, etc.)

Mistake 5: Using absolute paths when filesystem not mounted
  Result: Writing to mount point directory instead of mounted filesystem
  Check: Always verify mount with 'df -h /mnt/data' or 'mountpoint /mnt/data'

Mistake 6: Not creating mount point directory
  Result: mount command fails with "mount point does not exist"
  Fix: mkdir -p /mnt/data (before mounting)


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always use GPT for new partitions (unless explicitly told to use MBR)
   • Command: 'g' in fdisk creates GPT
   • Most reliable and RHCSA-expected approach

2. Prefer labels over UUIDs in fstab for readability
   • Format: LABEL=NAME not /dev/sdX
   • Makes configuration self-documenting
   • Easier to verify during exam stress

3. ALWAYS test fstab before considering task complete
   • Sequence: umount → mount -a → verify
   • Better to catch errors now than during grading reboot
   • Use 'findmnt --verify' as extra safety check

4. Verification commands to know cold:
   • lsblk -f        # See all filesystems and mounts
   • blkid           # Show all block device attributes
   • df -h           # Show mounted filesystems and space
   • findmnt         # Detailed mount information
   • mount | grep    # Quick mount check

5. Time-savers during exam:
   • Use Tab completion for device paths
   • 'lsblk' before and after each major step
   • Keep a terminal with 'watch lsblk' running
   • Copy/paste UUIDs with mouse (if GUI available)

6. If reboot test fails during exam:
   • Don't panic - you have access to emergency shell
   • Remount root: mount -o remount,rw /
   • Fix and retry
   • This is recoverable!

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Unmount filesystems
    umount /mnt/data 2>/dev/null || true
    umount /mnt/backup 2>/dev/null || true
    
    # Remove fstab entries
    sed -i '/\/mnt\/data/d' /etc/fstab 2>/dev/null || true
    sed -i '/\/mnt\/backup/d' /etc/fstab 2>/dev/null || true
    sed -i '/LABEL=DATA/d' /etc/fstab 2>/dev/null || true
    sed -i '/LABEL=BACKUP/d' /etc/fstab 2>/dev/null || true
    
    # Remove mount points
    rm -rf /mnt/data /mnt/backup 2>/dev/null || true
    
    # Detach loop devices
    if [ -f /tmp/.lab-loop1 ]; then
        LOOP1=$(cat /tmp/.lab-loop1)
        losetup -d "$LOOP1" 2>/dev/null || true
    fi
    
    if [ -f /tmp/.lab-loop2 ]; then
        LOOP2=$(cat /tmp/.lab-loop2)
        losetup -d "$LOOP2" 2>/dev/null || true
    fi
    
    # Remove disk files
    rm -f /var/lab-disks/disk1.img /var/lab-disks/disk2.img 2>/dev/null || true
    rm -f /tmp/.lab-loop1 /tmp/.lab-loop2 2>/dev/null || true
    
    echo "  ✓ All lab components removed"
    echo "  ✓ System restored to pre-lab state"
}

# Execute the main framework
main "$@"
