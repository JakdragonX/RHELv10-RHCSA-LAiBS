#!/bin/bash
# labs/19-lvm-logical-volumes.sh
# Lab: Managing LVM Logical Volumes
# Difficulty: Intermediate
# RHCSA Objective: Create and manage logical volumes

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing LVM Logical Volumes"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-40 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
# We create two loopback devices to simulate physical disks so the lab can
# run without requiring dedicated hardware partitions. This mirrors real disk
# behavior closely enough for exam prep purposes.
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Tear down any previous attempt artifacts
    lvremove -f /dev/vglab/lvdata  2>/dev/null || true
    lvremove -f /dev/vglab/lvbackup 2>/dev/null || true
    vgremove -f vglab               2>/dev/null || true
    pvremove -f /dev/loop80         2>/dev/null || true
    pvremove -f /dev/loop81         2>/dev/null || true

    # Detach previous loopback devices if they exist
    losetup -d /dev/loop80 2>/dev/null || true
    losetup -d /dev/loop81 2>/dev/null || true

    # Unmount any leftover mounts
    umount /mnt/lvdata   2>/dev/null || true
    umount /mnt/lvbackup 2>/dev/null || true

    # Remove leftover image files
    rm -f /tmp/lab-disk0.img /tmp/lab-disk1.img

    # Remove mount points
    rm -rf /mnt/lvdata /mnt/lvbackup

    # Remove any fstab entries from a previous run
    sed -i '/# RHCSA-LVM-LAB/d' /etc/fstab

    # Create two 2GiB sparse image files to act as our "disks"
    dd if=/dev/zero of=/tmp/lab-disk0.img bs=1M count=2048 status=none
    dd if=/dev/zero of=/tmp/lab-disk1.img bs=1M count=2048 status=none

    # Attach them as loopback block devices
    losetup /dev/loop80 /tmp/lab-disk0.img
    losetup /dev/loop81 /tmp/lab-disk1.img

    # Create mount points
    mkdir -p /mnt/lvdata /mnt/lvbackup

    echo "  ✓ Cleaned up any previous lab attempts"
    echo "  ✓ Simulated disks available at /dev/loop80 and /dev/loop81"
    echo "  ✓ Mount points created at /mnt/lvdata and /mnt/lvbackup"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic understanding of block devices and filesystems (mkfs, mount)
  • Familiarity with /etc/fstab and persistent mounts
  • Understanding of what "storage layers" means (physical → group → logical)
  • Basic partitioning concepts (though we use raw devices here, not partitions)

Commands You'll Use:
  • pvcreate   - Initialize a block device as an LVM Physical Volume (PV)
  • pvs        - Display summary info about Physical Volumes
  • pvdisplay  - Display detailed info about Physical Volumes
  • vgcreate   - Create a Volume Group (VG) from one or more PVs
  • vgs        - Display summary info about Volume Groups
  • vgdisplay  - Display detailed info about Volume Groups (including extent size)
  • vgextend   - Add a PV to an existing VG
  • vgreduce   - Remove a PV from a VG
  • lvcreate   - Create a Logical Volume (LV) inside a VG
  • lvs        - Display summary info about Logical Volumes
  • lvextend   - Grow a Logical Volume (and optionally its filesystem)
  • pvmove     - Move extents from one PV to another within a VG
  • mkfs.xfs   - Create an XFS filesystem on a block device
  • xfs_growfs - Grow an XFS filesystem to fill its Logical Volume
  • mount      - Mount a filesystem

Files You'll Interact With:
  • /etc/fstab            - Persistent mount configuration
  • /dev/vglab/lvdata     - LVM-generated symlink to your logical volume
  • /dev/mapper/vglab-lvdata - Device Mapper path (same device, different name)
  • /dev/loop80, /dev/loop81 - Simulated physical disks for this lab
EOF
}

#############################################################################
# SCENARIO (Standard Mode)
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You are the Linux administrator at a manufacturing company. A new application
requires a dedicated, flexible storage volume that can be resized without
downtime as data grows. Your manager has asked you to provision that storage
using LVM so future expansion is straightforward.

BACKGROUND:
Two new disks have been added to the system (/dev/loop80 and /dev/loop81).
You must build LVM storage on top of them, mount it persistently, then
demonstrate you can expand it — and later remove one of the underlying
disks from the volume group cleanly.

OBJECTIVES:
  1. Initialize /dev/loop80 as an LVM Physical Volume (PV).

  2. Create a Volume Group named 'vglab' from /dev/loop80.
     Use a custom extent size of 8MiB.

  3. Create a Logical Volume named 'lvdata' inside 'vglab'.
     Size: exactly 500MiB.

  4. Format 'lvdata' with an XFS filesystem.

  5. Mount 'lvdata' persistently at /mnt/lvdata using the device path
     /dev/vglab/lvdata (not the UUID). Add the comment
     '# RHCSA-LVM-LAB' on the same line as the fstab entry (appended
     after the options field is fine — see the hint below).
     Verify it survives a 'mount -a'.

  6. Extend 'lvdata' to 900MiB total, growing the XFS filesystem
     in the same operation (use the -r flag with lvextend).

  7. Add /dev/loop81 as a second PV and extend 'vglab' to include it.

  8. Use pvmove to migrate all extents off /dev/loop80, then remove
     /dev/loop80 from 'vglab' with vgreduce.

HINTS:
  • pvcreate, vgcreate, lvcreate all require root/sudo.
  • Extent size is set at VG creation time with: vgcreate -s 8M
  • lvcreate size flag: -L 500M (uppercase L = absolute size)
  • 'lvextend -r' resizes the filesystem automatically — no separate xfs_growfs needed.
  • fstab line format:  /dev/vglab/lvdata  /mnt/lvdata  xfs  defaults  0 0  # RHCSA-LVM-LAB
  • After pvmove completes, run 'pvs' and confirm /dev/loop80 shows 0 used extents before vgreduce.
  • Device Mapper names (/dev/dm-0, /dev/dm-1) are NOT persistent — always
    reference volumes via /dev/vglab/lvdata or /dev/mapper/vglab-lvdata.

SUCCESS CRITERIA:
  • 'pvs' shows /dev/loop81 in vglab, /dev/loop80 removed (or showing 0 extents then gone)
  • 'lvs' shows lvdata at 900MiB
  • 'df -h /mnt/lvdata' shows ~900MiB XFS filesystem mounted
  • /etc/fstab contains the /dev/vglab/lvdata entry with the RHCSA-LVM-LAB comment
  • 'vgdisplay vglab' shows PE Size of 8.00 MiB
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. pvcreate /dev/loop80
  ☐ 2. vgcreate -s 8M vglab /dev/loop80
  ☐ 3. lvcreate -n lvdata -L 500M vglab
  ☐ 4. mkfs.xfs /dev/vglab/lvdata
  ☐ 5. Mount persistently at /mnt/lvdata via /etc/fstab (with # RHCSA-LVM-LAB comment)
  ☐ 6. lvextend -r -L 900M /dev/vglab/lvdata
  ☐ 7. pvcreate /dev/loop81 && vgextend vglab /dev/loop81
  ☐ 8. pvmove /dev/loop80 && vgreduce vglab /dev/loop80
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "8"
}

scenario_context() {
    cat << 'EOF'
You are provisioning flexible LVM storage for a new application. Two simulated
disks are available at /dev/loop80 and /dev/loop81. You will build LVM layers
on top of them, mount the result persistently, resize it online, then
demonstrate safe removal of one underlying disk.
EOF
}

# ── STEP 1 ──────────────────────────────────────────────────────────────────
show_step_1() {
    cat << 'EOF'
TASK: Initialize /dev/loop80 as an LVM Physical Volume

LVM requires that you "stamp" a block device before LVM tools will recognize
it. The pvcreate command writes LVM metadata to the beginning of the device,
marking it as a Physical Volume (PV).

Requirements:
  • Target device: /dev/loop80
  • Verify with: pvs

Commands you might need:
  • pvcreate /dev/loop80
  • pvs               - confirm the PV appears
  • pvdisplay         - see extended PV metadata
EOF
}

validate_step_1() {
    if ! pvs /dev/loop80 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ /dev/loop80 is not recognized as a Physical Volume"
        echo "  Try: pvcreate /dev/loop80"
        return 1
    fi
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  pvcreate /dev/loop80

Explanation:
  • pvcreate: writes an LVM label and metadata area to the device header.
    Without this step, vgcreate will refuse to add the device to a VG.
  • /dev/loop80: our simulated first disk (loopback-backed image file).

Why this matters:
  Every LVM stack starts here. On real hardware you'd run this against
  /dev/sdb, /dev/nvme1n1, etc. — but the command is identical.

Verification:
  pvs
  # Expected: /dev/loop80 listed with a VG column of "" (not yet in a group)

EOF
}

# ── STEP 2 ──────────────────────────────────────────────────────────────────
hint_step_2() {
    echo "  Use the -s flag with vgcreate to set a custom extent size."
}

show_step_2() {
    cat << 'EOF'
TASK: Create Volume Group 'vglab' from /dev/loop80 with an 8MiB extent size

A Volume Group (VG) is the pool of storage built from one or more PVs.
Logical Volumes are carved out of this pool in units called extents.
The extent size is set once at VG creation — it cannot be changed later
without destroying the VG.

Requirements:
  • VG name: vglab
  • Source PV: /dev/loop80
  • Extent size: 8MiB  (flag: -s 8M)
  • Verify with: vgdisplay vglab  (look for "PE Size" line)

Commands you might need:
  • vgcreate -s 8M vglab /dev/loop80
  • vgs
  • vgdisplay vglab
EOF
}

validate_step_2() {
    if ! vgs vglab >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Volume Group 'vglab' does not exist"
        echo "  Try: vgcreate -s 8M vglab /dev/loop80"
        return 1
    fi

    local pe_size
    pe_size=$(vgdisplay vglab 2>/dev/null | awk '/PE Size/ {print $3}')
    # vgdisplay reports in MiB; value should be 8.00
    if [[ "$pe_size" != "8.00" ]]; then
        echo ""
        print_color "$RED" "✗ Extent size is '${pe_size} MiB' — expected 8.00 MiB"
        echo "  The extent size cannot be changed after creation."
        echo "  Remove the VG and recreate: vgremove vglab && vgcreate -s 8M vglab /dev/loop80"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  vgcreate -s 8M vglab /dev/loop80

Explanation:
  • vgcreate: creates a new Volume Group.
  • -s 8M: sets the Physical Extent (PE) size to 8 MiB. All LVs in this VG
    will allocate storage in 8 MiB chunks. Larger extent sizes reduce
    metadata overhead on very large VGs; smaller sizes allow finer-grained
    allocation.
  • vglab: the name you're assigning to this VG. Names must be unique on
    the system — this is what you'll reference in every subsequent lvcreate
    and lvextend command.
  • /dev/loop80: the PV(s) to include at creation time. You can list
    multiple PVs here separated by spaces.

Why this matters:
  Extent size is permanent for the lifetime of the VG. On the RHCSA exam,
  you may be told to use a specific extent size — set it here or you'll
  have to destroy and recreate the entire VG.

Verification:
  vgdisplay vglab | grep "PE Size"
  # Expected: PE Size   8.00 MiB

EOF
}

# ── STEP 3 ──────────────────────────────────────────────────────────────────
hint_step_3() {
    echo "  Use -n for the LV name and -L for the absolute size."
}

show_step_3() {
    cat << 'EOF'
TASK: Create a Logical Volume named 'lvdata' of exactly 500MiB inside 'vglab'

A Logical Volume (LV) is what you actually format and mount. It lives inside
the VG and its size is expressed as a count of extents (or a human-friendly
size that LVM rounds to the nearest extent boundary).

Requirements:
  • LV name: lvdata
  • VG: vglab
  • Size: 500MiB  (-L 500M)
  • Verify with: lvs

Commands you might need:
  • lvcreate -n lvdata -L 500M vglab
  • lvs
  • lvdisplay /dev/vglab/lvdata
EOF
}

validate_step_3() {
    if ! lvs /dev/vglab/lvdata >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ Logical Volume 'lvdata' does not exist in vglab"
        echo "  Try: lvcreate -n lvdata -L 500M vglab"
        return 1
    fi

    # LVM may round to extent boundary — accept 496–512M range
    local lv_size_mb
    lv_size_mb=$(lvs --noheadings --units m -o lv_size /dev/vglab/lvdata 2>/dev/null | tr -d ' m')
    lv_size_mb=${lv_size_mb%.*}  # truncate decimal

    if [[ -z "$lv_size_mb" ]] || (( lv_size_mb < 496 || lv_size_mb > 520 )); then
        echo ""
        print_color "$RED" "✗ lvdata size is ${lv_size_mb}MiB — expected ~500MiB"
        echo "  Try: lvremove -f /dev/vglab/lvdata && lvcreate -n lvdata -L 500M vglab"
        return 1
    fi

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  lvcreate -n lvdata -L 500M vglab

Explanation:
  • lvcreate: creates a new Logical Volume.
  • -n lvdata: sets the LV name. This determines the device path:
    /dev/vglab/lvdata  and  /dev/mapper/vglab-lvdata
    Both paths point to the same underlying Device Mapper device.
  • -L 500M: absolute size. LVM will round UP to the nearest extent
    boundary (8 MiB in our case), so you may see 504 MiB reported — that
    is correct behavior.
  • vglab: which VG to allocate from.

  Alternative size flag — lowercase -l:
    -l 62       means "62 extents" (62 × 8MiB = 496MiB)
    -l 100%FREE means "use all remaining free extents in the VG"
    Knowing both flags is useful for the RHCSA exam.

Verification:
  lvs
  # Expected: lvdata in vglab, ~500.00m

EOF
}

# ── STEP 4 ──────────────────────────────────────────────────────────────────
hint_step_4() {
    echo "  Use mkfs.xfs — Stratis always uses XFS too, so it's worth learning well."
}

show_step_4() {
    cat << 'EOF'
TASK: Format 'lvdata' with an XFS filesystem

An LV is just a raw block device until you put a filesystem on it. XFS is the
default filesystem in RHEL and is what the RHCSA exam expects unless told
otherwise. It supports online growth (but NOT shrinking).

Requirements:
  • Target: /dev/vglab/lvdata
  • Filesystem type: XFS
  • Verify with: blkid /dev/vglab/lvdata

Commands you might need:
  • mkfs.xfs /dev/vglab/lvdata
  • blkid /dev/vglab/lvdata   - confirms TYPE="xfs" and shows UUID
EOF
}

validate_step_4() {
    local fs_type
    fs_type=$(blkid -o value -s TYPE /dev/vglab/lvdata 2>/dev/null)
    if [[ "$fs_type" != "xfs" ]]; then
        echo ""
        print_color "$RED" "✗ /dev/vglab/lvdata does not have an XFS filesystem (found: '${fs_type:-none}')"
        echo "  Try: mkfs.xfs /dev/vglab/lvdata"
        return 1
    fi
    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  mkfs.xfs /dev/vglab/lvdata

Explanation:
  • mkfs.xfs: writes XFS metadata (superblock, inode tables, journal) to
    the block device. After this, the device has a filesystem UUID and can
    be mounted.
  • /dev/vglab/lvdata: the LVM symlink — functionally identical to
    /dev/mapper/vglab-lvdata or /dev/dm-X, but the LVM path is persistent
    and human-readable, making it the safe choice for scripts and fstab.

Why XFS:
  XFS is the RHEL default since RHEL 7. It handles large files and parallel
  I/O well. Key exam constraint: XFS can only grow, never shrink. If you
  need shrink capability, use EXT4 instead.

Verification:
  blkid /dev/vglab/lvdata
  # Expected output includes: TYPE="xfs"

EOF
}

# ── STEP 5 ──────────────────────────────────────────────────────────────────
hint_step_5() {
    echo "  Use /dev/vglab/lvdata (not UUID) in fstab. End the line with  # RHCSA-LVM-LAB"
}

show_step_5() {
    cat << 'EOF'
TASK: Mount 'lvdata' persistently at /mnt/lvdata via /etc/fstab

Mounting manually with 'mount' does not survive a reboot. /etc/fstab is the
system's persistent mount table — entries here are processed at boot by
systemd's mount generator.

Requirements:
  • Mount point: /mnt/lvdata  (already created by lab setup)
  • Device: /dev/vglab/lvdata  (use the LVM path, NOT the UUID for this task)
  • Filesystem type: xfs
  • Options: defaults
  • dump/pass: 0 0
  • The fstab line must end with the comment: # RHCSA-LVM-LAB
  • After editing fstab, run 'mount -a' to verify the entry is valid
  • Verify with: df -h /mnt/lvdata

Commands you might need:
  • vim /etc/fstab   (or nano, echo >>)
  • mount -a         - processes fstab entries not yet mounted
  • df -h /mnt/lvdata
EOF
}

validate_step_5() {
    # Check fstab entry exists with the required comment marker
    if ! grep -q 'RHCSA-LVM-LAB' /etc/fstab; then
        echo ""
        print_color "$RED" "✗ No fstab entry with '# RHCSA-LVM-LAB' comment found"
        echo "  Add a line like:"
        echo "  /dev/vglab/lvdata  /mnt/lvdata  xfs  defaults  0 0  # RHCSA-LVM-LAB"
        return 1
    fi

    # Check it's actually mounted
    if ! mountpoint -q /mnt/lvdata 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /mnt/lvdata is not currently mounted"
        echo "  Try: mount -a"
        return 1
    fi

    # Confirm it's XFS
    local fs_type
    fs_type=$(findmnt -n -o FSTYPE /mnt/lvdata 2>/dev/null)
    if [[ "$fs_type" != "xfs" ]]; then
        echo ""
        print_color "$RED" "✗ Filesystem at /mnt/lvdata is '${fs_type}', expected 'xfs'"
        return 1
    fi

    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command (append to /etc/fstab):
  echo '/dev/vglab/lvdata  /mnt/lvdata  xfs  defaults  0 0  # RHCSA-LVM-LAB' >> /etc/fstab

Then verify:
  mount -a
  df -h /mnt/lvdata

Explanation of fstab fields (space or tab separated):
  Field 1 — Device:      /dev/vglab/lvdata
    The LVM symlink. Persistent across reboots because it's tied to the
    VG/LV name, not a transient device number like /dev/dm-0.
  Field 2 — Mount point: /mnt/lvdata
  Field 3 — FS type:     xfs
  Field 4 — Options:     defaults
    Expands to: rw, suid, dev, exec, auto, nouser, async — standard settings.
  Field 5 — dump:        0  (dump utility — leave 0, rarely used today)
  Field 6 — pass:        0  (fsck order at boot — 0 = skip, which is correct
    for XFS because xfs_repair is not run by fsck automatically anyway)

Why not UUID here?
  LVM device paths are already stable and human-readable. UUIDs are more
  important for plain partitions where the /dev path can change depending
  on disk enumeration order. Both approaches work; the exam may specify
  which to use — read carefully.

Verification:
  findmnt /mnt/lvdata
  # Should show SOURCE=/dev/mapper/vglab-lvdata and FSTYPE=xfs

EOF
}

# ── STEP 6 ──────────────────────────────────────────────────────────────────
hint_step_6() {
    echo "  lvextend -r handles the filesystem resize — no separate xfs_growfs needed."
}

show_step_6() {
    cat << 'EOF'
TASK: Extend 'lvdata' to 900MiB total, growing the XFS filesystem in place

One of LVM's key advantages is online resizing. XFS supports growth while
the filesystem is mounted and in use.

Requirements:
  • New size: 900MiB total  (NOT +900MiB — use -L 900M for absolute size)
  • Resize the XFS filesystem in the same command using the -r flag
  • Do NOT unmount /mnt/lvdata first — demonstrate the online resize
  • Verify with: df -h /mnt/lvdata  (should show ~900MiB)

Commands you might need:
  • lvextend -r -L 900M /dev/vglab/lvdata
  • lvs    - confirm new LV size
  • df -h /mnt/lvdata  - confirm filesystem reflects new size
EOF
}

validate_step_6() {
    local lv_size_mb
    lv_size_mb=$(lvs --noheadings --units m -o lv_size /dev/vglab/lvdata 2>/dev/null | tr -d ' m')
    lv_size_mb=${lv_size_mb%.*}

    if [[ -z "$lv_size_mb" ]] || (( lv_size_mb < 880 || lv_size_mb > 920 )); then
        echo ""
        print_color "$RED" "✗ lvdata size is ${lv_size_mb}MiB — expected ~900MiB"
        echo "  Try: lvextend -r -L 900M /dev/vglab/lvdata"
        return 1
    fi

    # Confirm filesystem also grew (not just the block device)
    local fs_size_mb
    fs_size_mb=$(df -BM /mnt/lvdata 2>/dev/null | awk 'NR==2 {gsub(/M/,"",$2); print $2}')
    if [[ -z "$fs_size_mb" ]] || (( fs_size_mb < 800 )); then
        echo ""
        print_color "$RED" "✗ Filesystem at /mnt/lvdata shows only ${fs_size_mb}MiB — filesystem may not have been resized"
        echo "  Try: xfs_growfs /mnt/lvdata  (or re-run: lvextend -r -L 900M /dev/vglab/lvdata)"
        return 1
    fi

    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  lvextend -r -L 900M /dev/vglab/lvdata

Explanation:
  • lvextend: grows the Logical Volume block device.
  • -r (--resizefs): after extending the LV, automatically runs the
    appropriate filesystem resize tool. For XFS that is xfs_growfs; for
    EXT4 it would be resize2fs. Without -r, you would need to run
    xfs_growfs /mnt/lvdata manually afterward — the block device would be
    900MiB but the filesystem would still report the old size.
  • -L 900M: sets the ABSOLUTE target size. If you used '+900M' instead,
    it would ADD 900MiB on top of the current 500MiB, giving you ~1400MiB.
    Know the difference — the exam may use either form.

Why online resize matters:
  Production filesystems can't always be unmounted. LVM + XFS allows you
  to grow storage without any service interruption. This is a core reason
  why RHEL defaults to LVM during installation.

Verification:
  df -h /mnt/lvdata
  # Expected: Size column shows ~900M

  lvs
  # Expected: lvdata shows ~900.00m

EOF
}

# ── STEP 7 ──────────────────────────────────────────────────────────────────
hint_step_7() {
    echo "  pvcreate the new disk first, then vgextend to add it to the existing VG."
}

show_step_7() {
    cat << 'EOF'
TASK: Initialize /dev/loop81 as a PV and add it to 'vglab'

When a VG runs low on space, you add more capacity by: (1) creating a new PV
on a new disk, then (2) extending the VG to include that PV.

Requirements:
  • Initialize /dev/loop81 as a PV: pvcreate
  • Add it to vglab: vgextend
  • Verify with: pvs  (both loop80 and loop81 should appear in vglab)
                 vgs  (VFree should increase)

Commands you might need:
  • pvcreate /dev/loop81
  • vgextend vglab /dev/loop81
  • pvs
  • vgs
EOF
}

validate_step_7() {
    if ! pvs /dev/loop81 >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ /dev/loop81 is not a Physical Volume"
        echo "  Try: pvcreate /dev/loop81"
        return 1
    fi

    local pv_vg
    pv_vg=$(pvs --noheadings -o vg_name /dev/loop81 2>/dev/null | tr -d ' ')
    if [[ "$pv_vg" != "vglab" ]]; then
        echo ""
        print_color "$RED" "✗ /dev/loop81 is not a member of 'vglab' (current VG: '${pv_vg:-none}')"
        echo "  Try: vgextend vglab /dev/loop81"
        return 1
    fi

    return 0
}

solution_step_7() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  pvcreate /dev/loop81
  vgextend vglab /dev/loop81

Explanation:
  • pvcreate /dev/loop81: same as step 1, but for the second disk. Every
    device must be initialized as a PV before a VG will accept it.
  • vgextend vglab /dev/loop81: tells the VG to incorporate the new PV's
    extents into its free pool. No data is moved — you've simply expanded
    the available address space.

Verification:
  pvs
  # Both /dev/loop80 and /dev/loop81 should show vglab in the VG column

  vgs
  # VFree should now be ~1.1GiB larger than before (the size of loop81)

EOF
}

# ── STEP 8 ──────────────────────────────────────────────────────────────────
hint_step_8() {
    echo "  pvmove with no destination argument moves extents automatically. Run pvs after to confirm 0 used extents on loop80."
}

show_step_8() {
    cat << 'EOF'
TASK: Migrate extents off /dev/loop80 and remove it from 'vglab'

This procedure demonstrates how to decommission a failing or retiring disk
without downtime. Extents are moved to other PVs in the VG, then the
emptied PV is removed.

Requirements:
  • Use pvmove to relocate all extents from /dev/loop80 to /dev/loop81
  • Confirm /dev/loop80 shows 0 used PEs in 'pvs' output
  • Use vgreduce to remove /dev/loop80 from vglab
  • Verify with: pvs  (loop80 should no longer list vglab)

IMPORTANT: This will only succeed if /dev/loop81 has sufficient free space
to absorb the extents from /dev/loop80. Since our LV is only 900MiB and
each disk is 2GiB, there should be plenty of room.

Commands you might need:
  • pvmove /dev/loop80            (auto-selects destination)
  • pvmove /dev/loop80 /dev/loop81  (explicit destination)
  • pvs                           (confirm PUsed=0 for loop80)
  • vgreduce vglab /dev/loop80
EOF
}

validate_step_8() {
    # Check loop80 is no longer in vglab (either removed from VG or pvmove complete)
    local pv_vg
    pv_vg=$(pvs --noheadings -o vg_name /dev/loop80 2>/dev/null | tr -d ' ')

    if [[ "$pv_vg" == "vglab" ]]; then
        # Still in VG — check if extents were at least moved
        local pused
        pused=$(pvs --noheadings -o pv_used /dev/loop80 2>/dev/null | tr -d ' ')
        echo ""
        print_color "$RED" "✗ /dev/loop80 is still in vglab (PUsed: ${pused:-unknown})"
        if [[ "$pused" == "0" ]]; then
            echo "  pvmove appears complete. Run: vgreduce vglab /dev/loop80"
        else
            echo "  Run: pvmove /dev/loop80  then  vgreduce vglab /dev/loop80"
        fi
        return 1
    fi

    # Verify the LV is still accessible (data integrity check)
    if ! mountpoint -q /mnt/lvdata 2>/dev/null; then
        echo ""
        print_color "$YELLOW" "⚠ /mnt/lvdata is no longer mounted — re-mount it: mount /mnt/lvdata"
        return 1
    fi

    return 0
}

solution_step_8() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  pvmove /dev/loop80
  pvs                          # confirm loop80 shows 0 used extents
  vgreduce vglab /dev/loop80

Explanation:
  • pvmove /dev/loop80: reads all extent data from loop80 and writes it
    to other PVs in the same VG (loop81 in our case). This is a live
    operation — the LV and its mounted filesystem remain online throughout.
    It can take significant time on large/busy real disks.
    You can also specify the destination explicitly:
      pvmove /dev/loop80 /dev/loop81
  • pvs: after pvmove completes, the PUsed column for loop80 should show 0.
    Do NOT run vgreduce until this is confirmed — vgreduce will refuse to
    remove a PV that still holds extents.
  • vgreduce vglab /dev/loop80: removes the now-empty PV from the VG.
    The disk is no longer part of the pool. You can then pvremove it and
    physically remove it from the server.

Why this matters:
  pvmove is how you safely retire disks in production without downtime.
  Combined with LVM snapshots, it's also how storage migrations happen
  without quiescing applications.

Verification:
  pvs
  # /dev/loop80 should either be absent from the list, or show no VG
  lvs
  # lvdata should still exist and show ~900MiB — data survived the move
  df -h /mnt/lvdata
  # Filesystem still mounted and accessible

EOF
}

#############################################################################
# VALIDATE (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=8

    echo "Checking your configuration..."
    echo ""

    # CHECK 1: PV on loop80 or loop81 exists (at least one PV was created)
    print_color "$CYAN" "[1/$total] Checking Physical Volumes..."
    if pvs /dev/loop81 >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ /dev/loop81 is a valid Physical Volume"
        ((score++))
    else
        print_color "$RED" "  ✗ /dev/loop81 is not a Physical Volume"
        print_color "$YELLOW" "  Fix: pvcreate /dev/loop81"
    fi
    echo ""

    # CHECK 2: VG vglab exists with 8MiB extent size
    print_color "$CYAN" "[2/$total] Checking Volume Group 'vglab'..."
    if vgs vglab >/dev/null 2>&1; then
        local pe_size
        pe_size=$(vgdisplay vglab 2>/dev/null | awk '/PE Size/ {print $3}')
        if [[ "$pe_size" == "8.00" ]]; then
            print_color "$GREEN" "  ✓ Volume Group 'vglab' exists with 8MiB extent size"
            ((score++))
        else
            print_color "$RED" "  ✗ VG 'vglab' exists but extent size is ${pe_size} MiB (expected 8.00)"
            print_color "$YELLOW" "  Fix: vgremove vglab && vgcreate -s 8M vglab /dev/loop81"
        fi
    else
        print_color "$RED" "  ✗ Volume Group 'vglab' does not exist"
        print_color "$YELLOW" "  Fix: vgcreate -s 8M vglab /dev/loop81"
    fi
    echo ""

    # CHECK 3: LV lvdata exists
    print_color "$CYAN" "[3/$total] Checking Logical Volume 'lvdata'..."
    if lvs /dev/vglab/lvdata >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Logical Volume 'lvdata' exists in vglab"
        ((score++))
    else
        print_color "$RED" "  ✗ Logical Volume 'lvdata' not found in vglab"
        print_color "$YELLOW" "  Fix: lvcreate -n lvdata -L 900M vglab"
    fi
    echo ""

    # CHECK 4: XFS filesystem on lvdata
    print_color "$CYAN" "[4/$total] Checking XFS filesystem on lvdata..."
    local fs_type
    fs_type=$(blkid -o value -s TYPE /dev/vglab/lvdata 2>/dev/null)
    if [[ "$fs_type" == "xfs" ]]; then
        print_color "$GREEN" "  ✓ XFS filesystem found on /dev/vglab/lvdata"
        ((score++))
    else
        print_color "$RED" "  ✗ No XFS filesystem on lvdata (found: '${fs_type:-none}')"
        print_color "$YELLOW" "  Fix: mkfs.xfs /dev/vglab/lvdata"
    fi
    echo ""

    # CHECK 5: Persistent fstab entry with comment marker
    print_color "$CYAN" "[5/$total] Checking /etc/fstab persistent entry..."
    if grep -q 'RHCSA-LVM-LAB' /etc/fstab && mountpoint -q /mnt/lvdata 2>/dev/null; then
        print_color "$GREEN" "  ✓ fstab entry found and /mnt/lvdata is mounted"
        ((score++))
    else
        if ! grep -q 'RHCSA-LVM-LAB' /etc/fstab; then
            print_color "$RED" "  ✗ No fstab entry with '# RHCSA-LVM-LAB' comment"
            print_color "$YELLOW" "  Fix: echo '/dev/vglab/lvdata  /mnt/lvdata  xfs  defaults  0 0  # RHCSA-LVM-LAB' >> /etc/fstab"
        else
            print_color "$RED" "  ✗ fstab entry present but /mnt/lvdata is not mounted"
            print_color "$YELLOW" "  Fix: mount -a"
        fi
    fi
    echo ""

    # CHECK 6: LV size is ~900MiB
    print_color "$CYAN" "[6/$total] Checking lvdata size (~900MiB)..."
    local lv_size_mb
    lv_size_mb=$(lvs --noheadings --units m -o lv_size /dev/vglab/lvdata 2>/dev/null | tr -d ' m')
    lv_size_mb=${lv_size_mb%.*}
    if [[ -n "$lv_size_mb" ]] && (( lv_size_mb >= 880 && lv_size_mb <= 920 )); then
        print_color "$GREEN" "  ✓ lvdata is ${lv_size_mb}MiB (~900MiB as required)"
        ((score++))
    else
        print_color "$RED" "  ✗ lvdata is ${lv_size_mb:-unknown}MiB (expected ~900MiB)"
        print_color "$YELLOW" "  Fix: lvextend -r -L 900M /dev/vglab/lvdata"
    fi
    echo ""

    # CHECK 7: loop81 is in vglab
    print_color "$CYAN" "[7/$total] Checking /dev/loop81 is a member of vglab..."
    local pv81_vg
    pv81_vg=$(pvs --noheadings -o vg_name /dev/loop81 2>/dev/null | tr -d ' ')
    if [[ "$pv81_vg" == "vglab" ]]; then
        print_color "$GREEN" "  ✓ /dev/loop81 is part of vglab"
        ((score++))
    else
        print_color "$RED" "  ✗ /dev/loop81 is not in vglab (VG: '${pv81_vg:-none}')"
        print_color "$YELLOW" "  Fix: pvcreate /dev/loop81 && vgextend vglab /dev/loop81"
    fi
    echo ""

    # CHECK 8: loop80 has been removed from vglab
    print_color "$CYAN" "[8/$total] Checking /dev/loop80 removed from vglab..."
    local pv80_vg
    pv80_vg=$(pvs --noheadings -o vg_name /dev/loop80 2>/dev/null | tr -d ' ')
    if [[ "$pv80_vg" != "vglab" ]]; then
        print_color "$GREEN" "  ✓ /dev/loop80 has been removed from vglab (pvmove + vgreduce complete)"
        ((score++))
    else
        local pused
        pused=$(pvs --noheadings -o pv_used /dev/loop80 2>/dev/null | tr -d ' ')
        print_color "$RED" "  ✗ /dev/loop80 is still in vglab (PUsed: ${pused:-unknown})"
        print_color "$YELLOW" "  Fix: pvmove /dev/loop80 && vgreduce vglab /dev/loop80"
    fi
    echo ""

    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've successfully completed all LVM objectives."
        echo "You can now create, extend, and safely decommission LVM storage."
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
# SOLUTION (Standard Mode)
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Initialize /dev/loop80 as a Physical Volume
─────────────────────────────────────────────────────────────────
Command:
  pvcreate /dev/loop80

Explanation:
  Writes LVM metadata to the device. No filesystem is created —
  pvcreate just stamps the disk so LVM can recognize and manage it.

Verification:
  pvs
  # /dev/loop80 listed with empty VG column


STEP 2: Create Volume Group 'vglab' with 8MiB extent size
─────────────────────────────────────────────────────────────────
Command:
  vgcreate -s 8M vglab /dev/loop80

Explanation:
  -s 8M sets the Physical Extent size. Every allocation in this VG
  will be a multiple of 8MiB. Extent size cannot be changed after
  VG creation.

Verification:
  vgdisplay vglab | grep "PE Size"
  # PE Size   8.00 MiB


STEP 3: Create Logical Volume 'lvdata' at 500MiB
─────────────────────────────────────────────────────────────────
Command:
  lvcreate -n lvdata -L 500M vglab

Explanation:
  -n lvdata  sets the name; -L 500M sets the size. LVM rounds up to
  the nearest extent boundary (504MiB at 8MiB extents is expected).

Verification:
  lvs
  # lvdata in vglab, ~500.00m


STEP 4: Format with XFS
─────────────────────────────────────────────────────────────────
Command:
  mkfs.xfs /dev/vglab/lvdata

Verification:
  blkid /dev/vglab/lvdata
  # TYPE="xfs"


STEP 5: Persistent mount via /etc/fstab
─────────────────────────────────────────────────────────────────
Command:
  echo '/dev/vglab/lvdata  /mnt/lvdata  xfs  defaults  0 0  # RHCSA-LVM-LAB' >> /etc/fstab
  mount -a

Explanation:
  The 6 fstab fields: device  mountpoint  fstype  options  dump  pass
  Pass=0 skips fsck, which is correct for XFS (use xfs_repair manually
  when needed).

Verification:
  df -h /mnt/lvdata
  # Shows ~500MiB XFS mounted at /mnt/lvdata


STEP 6: Extend lvdata to 900MiB with filesystem resize
─────────────────────────────────────────────────────────────────
Command:
  lvextend -r -L 900M /dev/vglab/lvdata

Explanation:
  -r runs xfs_growfs automatically after the block device is extended.
  Without -r the LV block device would grow but the filesystem would
  still report the old size.

Verification:
  df -h /mnt/lvdata
  # Size column shows ~900M


STEP 7: Add /dev/loop81 to vglab
─────────────────────────────────────────────────────────────────
Commands:
  pvcreate /dev/loop81
  vgextend vglab /dev/loop81

Verification:
  pvs
  # Both loop80 and loop81 show vglab in VG column


STEP 8: Migrate extents off loop80 and remove it
─────────────────────────────────────────────────────────────────
Commands:
  pvmove /dev/loop80
  pvs                          # confirm PUsed=0 for loop80
  vgreduce vglab /dev/loop80

Explanation:
  pvmove reads extents from the source PV and writes them to other
  PVs in the VG. The filesystem at /mnt/lvdata remains accessible
  throughout. vgreduce then evicts the now-empty PV from the VG.

Verification:
  pvs
  # loop80 no longer lists vglab
  df -h /mnt/lvdata
  # Data still intact


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The LVM Storage Stack:
  Physical Volume (PV) → Volume Group (VG) → Logical Volume (LV) → Filesystem
  Each layer adds abstraction. PVs are raw devices. The VG pools their
  extents. LVs carve named allocations from that pool. The filesystem
  provides files and directories on top of the LV.

Device Mapper vs LVM Symlinks:
  /dev/dm-0, /dev/dm-1, etc. are created by the kernel's Device Mapper
  subsystem. These numbers are NOT persistent — they depend on the order
  devices are activated at boot. Never use them in fstab or scripts.
  /dev/vglab/lvdata and /dev/mapper/vglab-lvdata are both stable symlinks
  that resolve to the correct dm-X device regardless of boot order.

XFS vs EXT4 in LVM context:
  XFS: online growth only (no shrink), xfs_growfs, default in RHEL.
  EXT4: online growth AND offline shrink, resize2fs.
  Both work with lvextend -r, but the underlying resize tool differs.
  The exam will not ask you to shrink XFS — it is not possible.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using -L +900M instead of -L 900M in lvextend
  Result: LV grows to ~1400MiB (500 + 900) instead of 900MiB total.
  Fix:    lvreduce cannot be used on XFS. You'd need to recreate the LV.
  Prevention: -L sets ABSOLUTE size; -L + sets RELATIVE (additive) size.

Mistake 2: Forgetting -r in lvextend
  Result: df still shows old filesystem size even though lvs shows new LV size.
  Fix:    xfs_growfs /mnt/lvdata
  Why:    lvextend only extends the block device. -r (or a manual xfs_growfs)
          is required to expand the filesystem metadata to use the new space.

Mistake 3: Running vgreduce before pvmove completes
  Result: vgreduce refuses with "Physical volume '/dev/loop80' still in use"
  Fix:    Wait for pvmove to finish, verify with pvs (PUsed=0), then vgreduce.

Mistake 4: Referencing /dev/dm-X in fstab
  Result: System may fail to mount at boot if device numbering changes.
  Fix:    Always use /dev/vglab/lvdata or /dev/mapper/vglab-lvdata paths.


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Read the objective carefully — if told to use a specific extent size,
   set it during vgcreate. You cannot change it without destroying the VG.

2. Always verify with lvs, vgs, and pvs after each step. One wrong flag
   costs you points and time.

3. The -r flag on lvextend is a time-saver on the exam. Without it you
   must remember to run xfs_growfs or resize2fs manually — an easy step
   to forget under pressure.

4. For fstab: test with 'mount -a' BEFORE moving on. A bad fstab entry
   can prevent boot on the exam system.

5. Know both size flags: -L 500M (absolute) and -l 100%FREE (all free
   extents). The exam may use either phrasing in the objective.

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    lvremove -f /dev/vglab/lvdata   2>/dev/null || true
    lvremove -f /dev/vglab/lvbackup 2>/dev/null || true
    vgremove -f vglab                2>/dev/null || true
    pvremove -f /dev/loop80          2>/dev/null || true
    pvremove -f /dev/loop81          2>/dev/null || true

    umount /mnt/lvdata   2>/dev/null || true
    umount /mnt/lvbackup 2>/dev/null || true

    losetup -d /dev/loop80 2>/dev/null || true
    losetup -d /dev/loop81 2>/dev/null || true

    rm -f /tmp/lab-disk0.img /tmp/lab-disk1.img
    rm -rf /mnt/lvdata /mnt/lvbackup

    sed -i '/# RHCSA-LVM-LAB/d' /etc/fstab

    echo "  ✓ All lab components removed"
    echo "  ✓ fstab entries cleaned"
    echo "  ✓ Loopback devices detached and image files removed"
}

# Execute the main framework
main "$@"
