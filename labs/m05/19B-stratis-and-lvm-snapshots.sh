#!/bin/bash
# labs/19B-stratis-and-lvm-snapshots.sh
# Lab: Managing Stratis Volumes and LVM Snapshots
# Difficulty: Intermediate
# RHCSA Objective: Create and manage Stratis storage pools, filesystems,
#                  and snapshots; create and restore LVM snapshots

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Managing Stratis Volumes and LVM Snapshots"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-45 minutes"

#############################################################################
# SETUP: Idempotent environment preparation
#
# We create:
#   /dev/loop82 — 8GiB image for Stratis (minimum pool size is ~4GiB per fs)
#   /dev/loop83 — 2GiB image for the LVM snapshot portion
#
# Why 8GiB for Stratis?
#   Stratis uses XFS under thin provisioning. Each Stratis filesystem
#   requires a minimum of 4GiB of pool space for its internal metadata
#   structures, even if the actual data is tiny. Going below this causes
#   stratisd to refuse filesystem creation.
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # ── Stratis teardown ──────────────────────────────────────────────────
    systemctl start stratisd 2>/dev/null || true

    # Unmount any Stratis filesystems first
    umount /mnt/stratisdata   2>/dev/null || true
    umount /mnt/stratis-snap  2>/dev/null || true

    # Destroy filesystems and pool if they exist
    stratis filesystem destroy labpool labdata     2>/dev/null || true
    stratis filesystem destroy labpool labsnap     2>/dev/null || true
    stratis pool destroy labpool                   2>/dev/null || true

    # ── LVM teardown ─────────────────────────────────────────────────────
    umount /mnt/lvm-snap      2>/dev/null || true
    umount /mnt/lvsnap        2>/dev/null || true
    lvremove -f /dev/vgsnap/lvorigin  2>/dev/null || true
    lvremove -f /dev/vgsnap/lvsnap    2>/dev/null || true
    vgremove -f vgsnap                2>/dev/null || true
    pvremove -f /dev/loop83           2>/dev/null || true

    # ── Loopback teardown ────────────────────────────────────────────────
    losetup -d /dev/loop82 2>/dev/null || true
    losetup -d /dev/loop83 2>/dev/null || true

    rm -f /tmp/lab-stratis.img /tmp/lab-snap.img

    # Remove mount points
    rm -rf /mnt/stratisdata /mnt/stratis-snap /mnt/lvm-snap /mnt/lvsnap

    # Remove fstab entries from previous runs
    sed -i '/# RHCSA-STRATIS-LAB/d' /etc/fstab
    sed -i '/# RHCSA-SNAP-LAB/d'    /etc/fstab

    # ── Create fresh simulated disks ─────────────────────────────────────
    echo "  Creating disk images (this may take a moment)..."
    dd if=/dev/zero of=/tmp/lab-stratis.img bs=1M count=8192 status=none
    dd if=/dev/zero of=/tmp/lab-snap.img    bs=1M count=2048 status=none

    losetup /dev/loop82 /tmp/lab-stratis.img
    losetup /dev/loop83 /tmp/lab-snap.img

    # ── Ensure stratisd is installed and running ──────────────────────────
    if ! rpm -q stratisd stratis-cli &>/dev/null; then
        echo "  Installing stratisd and stratis-cli (requires network)..."
        dnf install -y stratisd stratis-cli &>/dev/null
    fi
    systemctl enable --now stratisd 2>/dev/null || true

    # ── Create mount points ───────────────────────────────────────────────
    mkdir -p /mnt/stratisdata /mnt/stratis-snap /mnt/lvm-snap

    echo "  ✓ Cleaned up any previous lab attempts"
    echo "  ✓ /dev/loop82 (8GiB) — Stratis disk"
    echo "  ✓ /dev/loop83 (2GiB) — LVM snapshot disk"
    echo "  ✓ stratisd service running"
    echo "  ✓ Mount points ready"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of thin provisioning (storage allocated on demand, not upfront)
  • Familiarity with /etc/fstab persistent mounts and mount options
  • Basic LVM knowledge (pvcreate, vgcreate, lvcreate) from Lab 19A
  • Concept of a snapshot: a point-in-time copy of a volume's state

Commands You'll Use:
  • stratis pool create       - Create a Stratis storage pool from a block device
  • stratis pool list         - Display all Stratis pools and their used/free space
  • stratis filesystem create - Create a thin-provisioned filesystem inside a pool
  • stratis filesystem list   - Display Stratis filesystems and their UUIDs
  • stratis filesystem snapshot - Create a snapshot of a Stratis filesystem
  • stratis filesystem destroy  - Remove a Stratis filesystem or snapshot
  • stratis pool destroy        - Remove a Stratis pool
  • lvcreate -s               - Create an LVM snapshot of an existing LV
  • lvconvert --merge         - Merge (restore) an LVM snapshot back into its origin
  • mount -o ro               - Mount a volume read-only

Files You'll Interact With:
  • /etc/fstab                          - Persistent mount configuration
  • /dev/stratis/labpool/labdata        - Stratis filesystem device path
  • /dev/stratis/labpool/labsnap        - Stratis snapshot device path
  • /dev/vgsnap/lvorigin               - LVM origin volume
  • /dev/vgsnap/lvsnap                 - LVM snapshot volume

Key Concepts to Understand Before Starting:
  • Stratis thin provisioning: the pool reports a large virtual size per
    filesystem, but actual disk space is only consumed as data is written.
    This means 'df' will NOT accurately reflect pool usage — always use
    'stratis pool list' to monitor real pool consumption.
  • LVM snapshots use Copy-on-Write (COW): when a block in the origin
    volume is modified after the snapshot is taken, the original block is
    copied into the snapshot before the modification is written. The
    snapshot only stores DIFFERENCES from the origin, not a full copy.
EOF
}

#############################################################################
# SCENARIO (Standard Mode)
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your organization is evaluating Stratis as a modern replacement for raw LVM
for certain workloads. You've been asked to provision a Stratis-backed
filesystem for an application, configure it for persistent mounting, and
demonstrate snapshot capabilities. You'll also contrast this with LVM's
own snapshot mechanism on a separate disk.

BACKGROUND:
Two disks have been provisioned: /dev/loop82 (8GiB) for the Stratis work
and /dev/loop83 (2GiB) for the LVM snapshot work. The stratisd daemon is
already running. All Stratis commands must be run as root.

OBJECTIVES:
  1. Create a Stratis pool named 'labpool' using /dev/loop82.

  2. Create a Stratis filesystem named 'labdata' inside 'labpool'.

  3. Mount 'labdata' persistently at /mnt/stratisdata.
     Requirements:
       • Use the filesystem UUID (not the device path) in fstab.
       • Mount options must include: x-systemd.requires=stratisd.service
       • Add the comment '# RHCSA-STRATIS-LAB' to the fstab line.
       • Verify with: mount -a

  4. Write a test file to /mnt/stratisdata, then create a Stratis snapshot
     of 'labdata' named 'labsnap'.
     After creating the snapshot: delete the test file from /mnt/stratisdata
     to simulate accidental data loss.

  5. Mount the snapshot 'labsnap' read-only at /mnt/stratis-snap and
     verify you can access the test file that was deleted from the origin.

  6. Using /dev/loop83, build a minimal LVM stack:
       • PV: /dev/loop83
       • VG: vgsnap
       • LV: lvorigin (size: 500MiB, formatted XFS, mounted at /mnt/lvm-snap)
     Write a test file to /mnt/lvm-snap, then take an LVM snapshot named
     'lvsnap' with 200MiB of COW space.
     Simulate data loss by deleting the test file from /mnt/lvm-snap.

  7. Restore the LVM snapshot by merging it back into the origin volume
     using lvconvert --merge. Verify the test file is recovered.

HINTS:
  • Stratis filesystem UUIDs: use 'stratis filesystem list' — the UUID
    column is what goes in fstab, formatted as: UUID=<value>
  • Stratis fstab options field: defaults,x-systemd.requires=stratisd.service
  • Stratis snapshot mount: use the device path, not UUID —
    /dev/stratis/labpool/labsnap — mounted with 'ro' option.
  • LVM snapshot syntax: lvcreate -s -n lvsnap -L 200M /dev/vgsnap/lvorigin
  • lvconvert --merge requires the origin LV to be UNMOUNTED first.
    After merging, the snapshot LV is automatically removed.
  • Stratis pool space: monitor with 'stratis pool list', not 'df'.

SUCCESS CRITERIA:
  • 'stratis pool list' shows labpool on /dev/loop82
  • 'stratis filesystem list' shows labdata and labsnap in labpool
  • /mnt/stratisdata is mounted persistently (UUID + systemd option in fstab)
  • /mnt/stratis-snap is mounted and contains the recovered test file
  • 'lvs' shows lvorigin in vgsnap at ~500MiB
  • After merge: test file is recovered in /mnt/lvm-snap, snapshot LV is gone
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. stratis pool create labpool /dev/loop82
  ☐ 2. stratis filesystem create labpool labdata
  ☐ 3. Mount labdata persistently via UUID + x-systemd.requires=stratisd.service
  ☐ 4. Write test file → snapshot labdata as labsnap → delete test file
  ☐ 5. Mount labsnap read-only at /mnt/stratis-snap, verify file accessible
  ☐ 6. Build LVM stack on loop83 → write test file → lvcreate -s (lvsnap)
  ☐ 7. lvconvert --merge to restore origin, verify file recovered
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "7"
}

scenario_context() {
    cat << 'EOF'
You are provisioning Stratis-backed storage for an application and
demonstrating snapshot recovery — first with Stratis, then contrasting
with LVM's Copy-on-Write snapshot mechanism. Two simulated disks are
available: /dev/loop82 (Stratis, 8GiB) and /dev/loop83 (LVM, 2GiB).
EOF
}

# ── STEP 1 ──────────────────────────────────────────────────────────────────
show_step_1() {
    cat << 'EOF'
TASK: Create a Stratis pool named 'labpool' using /dev/loop82

A Stratis pool is the equivalent of an LVM Volume Group — it's the raw
storage layer that filesystems are carved from. Unlike LVM, you do NOT
run pvcreate first; stratis handles device initialization itself.

The stratisd daemon must be running before any stratis commands will work.
Verify with: systemctl is-active stratisd

Requirements:
  • Pool name: labpool
  • Block device: /dev/loop82
  • Verify with: stratis pool list

Commands you might need:
  • stratis pool create labpool /dev/loop82
  • stratis pool list
EOF
}

validate_step_1() {
    if ! stratis pool list 2>/dev/null | grep -q 'labpool'; then
        echo ""
        print_color "$RED" "✗ Stratis pool 'labpool' does not exist"
        echo "  Ensure stratisd is running: systemctl start stratisd"
        echo "  Then try: stratis pool create labpool /dev/loop82"
        return 1
    fi
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  stratis pool create labpool /dev/loop82

Explanation:
  • stratis pool create: initializes the block device and registers it
    with stratisd as a named pool. No separate pvcreate step is needed —
    Stratis handles its own device metadata.
  • labpool: the pool name. Referenced in all subsequent filesystem and
    snapshot commands.
  • /dev/loop82: the backing device. You can list multiple devices here
    to create a pool spanning several disks.

Key difference from LVM:
  In LVM you explicitly manage three layers: PV → VG → LV.
  In Stratis the PV equivalent is handled internally; you only interact
  with pool and filesystem layers. This is why Stratis is described as
  a "Volume Managing Filesystem" rather than just a volume manager.

Verification:
  stratis pool list
  # Expected: labpool listed with Total Physical showing ~8 GiB

EOF
}

# ── STEP 2 ──────────────────────────────────────────────────────────────────
hint_step_2() {
    echo "  stratis filesystem create takes the pool name first, then the filesystem name."
}

show_step_2() {
    cat << 'EOF'
TASK: Create a Stratis filesystem named 'labdata' inside 'labpool'

A Stratis filesystem is the equivalent of an LVM Logical Volume + mkfs in
one step. Stratis always uses XFS internally. The filesystem is thin
provisioned — it presents a large virtual size (1 TiB by default) but only
consumes pool space as data is actually written.

IMPORTANT: Do NOT use 'df' to check available space in a Stratis pool.
Because of thin provisioning, df will show the virtual size (1 TiB), not
the actual pool consumption. Always use 'stratis pool list' instead.

Requirements:
  • Pool: labpool
  • Filesystem name: labdata
  • Verify with: stratis filesystem list

Commands you might need:
  • stratis filesystem create labpool labdata
  • stratis filesystem list
  • stratis pool list   (monitor actual pool space used)
EOF
}

validate_step_2() {
    if ! stratis filesystem list 2>/dev/null | grep -q 'labdata'; then
        echo ""
        print_color "$RED" "✗ Stratis filesystem 'labdata' does not exist in labpool"
        echo "  Try: stratis filesystem create labpool labdata"
        return 1
    fi
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  stratis filesystem create labpool labdata

Explanation:
  • stratis filesystem create: creates a thin-provisioned XFS filesystem
    inside the pool. Stratis formats the underlying XFS itself — you do
    not run mkfs separately.
  • labpool: which pool to allocate from.
  • labdata: the filesystem name. This determines the device path:
    /dev/stratis/labpool/labdata

Thin provisioning explained:
  The filesystem appears to have 1 TiB of space (df will report this),
  but the pool only physically has 8 GiB. Stratis allocates real blocks
  from the pool on demand as data is written. If the pool fills up,
  ALL filesystems in that pool become read-only simultaneously — this is
  why monitoring with 'stratis pool list' is critical in production.

Verification:
  stratis filesystem list
  # Expected: labdata listed under labpool with a UUID and device path

  stratis pool list
  # Physical Used column should increase slightly (Stratis XFS metadata overhead)

EOF
}

# ── STEP 3 ──────────────────────────────────────────────────────────────────
hint_step_3() {
    echo "  Get the UUID from 'stratis filesystem list'. The mount option x-systemd.requires=stratisd.service is mandatory for Stratis in fstab."
}

show_step_3() {
    cat << 'EOF'
TASK: Mount 'labdata' persistently at /mnt/stratisdata via /etc/fstab

Stratis has a specific fstab requirement that plain LVM mounts do not:
the mount must declare a dependency on stratisd.service. Without this,
systemd may attempt to mount the Stratis filesystem before the stratisd
daemon has started, causing a boot failure.

You must also use the filesystem UUID (not the device path) because Stratis
device paths under /dev/stratis/ are only created after stratisd activates
the pool — at fstab processing time the path may not yet exist.

Requirements:
  • Mount point: /mnt/stratisdata
  • Device identifier: UUID=<uuid from stratis filesystem list>
  • Filesystem type: xfs
  • Options: defaults,x-systemd.requires=stratisd.service
  • dump/pass: 0 0
  • Comment: # RHCSA-STRATIS-LAB on the same fstab line
  • Verify: mount -a  then  df -h /mnt/stratisdata

Commands you might need:
  • stratis filesystem list          (find the UUID)
  • blkid /dev/stratis/labpool/labdata  (alternative UUID lookup)
  • vim /etc/fstab
  • mount -a
  • df -h /mnt/stratisdata
EOF
}

validate_step_3() {
    # Check fstab has the stratisd dependency option
    if ! grep -q 'RHCSA-STRATIS-LAB' /etc/fstab; then
        echo ""
        print_color "$RED" "✗ No fstab entry with '# RHCSA-STRATIS-LAB' comment found"
        echo "  Add a line like:"
        echo "  UUID=<uuid>  /mnt/stratisdata  xfs  defaults,x-systemd.requires=stratisd.service  0 0  # RHCSA-STRATIS-LAB"
        return 1
    fi

    if ! grep 'RHCSA-STRATIS-LAB' /etc/fstab | grep -q 'x-systemd.requires=stratisd.service'; then
        echo ""
        print_color "$RED" "✗ fstab entry found but missing 'x-systemd.requires=stratisd.service' mount option"
        echo "  This option is required for Stratis filesystems to mount correctly at boot."
        return 1
    fi

    if ! mountpoint -q /mnt/stratisdata 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /mnt/stratisdata is not currently mounted"
        echo "  Try: mount -a"
        return 1
    fi

    # Confirm it's actually a Stratis-backed XFS filesystem
    local fs_type
    fs_type=$(findmnt -n -o FSTYPE /mnt/stratisdata 2>/dev/null)
    if [[ "$fs_type" != "xfs" ]]; then
        echo ""
        print_color "$RED" "✗ Filesystem at /mnt/stratisdata reports type '${fs_type}' (expected xfs)"
        return 1
    fi

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Step 1 — Get the UUID:
  stratis filesystem list
  # Note the UUID column value, e.g.: a1b2c3d4-...

  Or alternatively:
  blkid /dev/stratis/labpool/labdata

Step 2 — Add to fstab:
  UUID=<your-uuid>  /mnt/stratisdata  xfs  defaults,x-systemd.requires=stratisd.service  0 0  # RHCSA-STRATIS-LAB

Step 3 — Verify:
  mount -a
  df -h /mnt/stratisdata

Explanation of the fstab fields:
  • UUID=...: stable identifier. Stratis device paths (/dev/stratis/...)
    are only available after stratisd activates the pool, so they cannot
    be used reliably in fstab. The UUID survives reboots and pool
    re-imports.
  • xfs: Stratis always presents XFS. Specifying 'auto' also works but
    being explicit is better practice and clearer for the exam grader.
  • x-systemd.requires=stratisd.service: tells systemd's mount unit
    generator to add an ordering/dependency relationship so the mount
    only runs AFTER stratisd is active. Without this, the mount unit
    may be activated before the pool's block devices are visible.
  • 0 0: same reasoning as LVM — XFS doesn't use fsck, skip both.

Why UUID over device path:
  /dev/stratis/labpool/labdata is a symlink created by stratisd at
  runtime. At early boot, when fstab is processed, stratisd may not
  have run yet and the path won't exist. UUID lookup via libblkid works
  independently of stratisd and will find the device once it appears.

EOF
}

# ── STEP 4 ──────────────────────────────────────────────────────────────────
hint_step_4() {
    echo "  Write any file to /mnt/stratisdata first, then snapshot, then delete the file."
}

show_step_4() {
    cat << 'EOF'
TASK: Write a test file, snapshot 'labdata', then simulate data loss

This step demonstrates the core use case for snapshots: capturing a known-
good state before a risky change, or recovering from accidental deletion.

A Stratis snapshot is a metadata copy of the filesystem at a point in time.
It is NOT a full data copy — it records which blocks the filesystem was
using at snapshot time. As either the origin or the snapshot is modified,
differences are tracked separately.

IMPORTANT: A snapshot is NOT a backup. If the pool is destroyed, both
the origin and all its snapshots are lost. Use snapshots for short-term
recovery only.

Requirements:
  1. Write a test file to /mnt/stratisdata:
       echo "snapshot test data" > /mnt/stratisdata/testfile.txt

  2. Create a snapshot of 'labdata' named 'labsnap' in 'labpool':
       stratis filesystem snapshot labpool labdata labsnap

  3. Simulate data loss — delete the test file from the ORIGIN:
       rm /mnt/stratisdata/testfile.txt

  4. Verify the file is gone from the origin:
       ls /mnt/stratisdata/

Commands you might need:
  • stratis filesystem snapshot labpool labdata labsnap
  • stratis filesystem list   (snapshot appears as a separate filesystem entry)
EOF
}

validate_step_4() {
    # Check snapshot exists
    if ! stratis filesystem list 2>/dev/null | grep -q 'labsnap'; then
        echo ""
        print_color "$RED" "✗ Stratis snapshot 'labsnap' does not exist"
        echo "  Try: stratis filesystem snapshot labpool labdata labsnap"
        return 1
    fi

    # Check that the test file has been removed from origin (simulating data loss)
    if [[ -f /mnt/stratisdata/testfile.txt ]]; then
        echo ""
        print_color "$YELLOW" "⚠ testfile.txt still exists in /mnt/stratisdata"
        echo "  Delete it to simulate data loss: rm /mnt/stratisdata/testfile.txt"
        return 1
    fi

    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Commands (in order):
  echo "snapshot test data" > /mnt/stratisdata/testfile.txt
  stratis filesystem snapshot labpool labdata labsnap
  rm /mnt/stratisdata/testfile.txt

Explanation:
  • Writing the test file first ensures there is data in the filesystem
    at snapshot time. The snapshot captures the filesystem state including
    this file.
  • stratis filesystem snapshot <pool> <origin> <snapshot-name>:
    creates a new, independent Stratis filesystem whose initial content
    mirrors the origin at this exact moment.
  • Deleting testfile.txt from the origin simulates an accident. The
    origin filesystem no longer has the file — but the snapshot still
    holds the blocks that contained it.

How Stratis snapshots differ from LVM snapshots:
  LVM snapshots use Copy-on-Write and grow as the origin changes.
  Stratis snapshots create a divergent filesystem — after creation, the
  snapshot and the origin are independent. Modifying the snapshot does
  NOT affect the origin, and modifying the origin does NOT affect the
  snapshot. This is more like a filesystem clone than a COW mirror.

Verification:
  stratis filesystem list
  # Both labdata and labsnap should appear under labpool

  ls /mnt/stratisdata/
  # testfile.txt should NOT be present (simulated data loss)

EOF
}

# ── STEP 5 ──────────────────────────────────────────────────────────────────
hint_step_5() {
    echo "  Mount the snapshot using its device path (/dev/stratis/labpool/labsnap), not its UUID, and add the 'ro' option."
}

show_step_5() {
    cat << 'EOF'
TASK: Mount snapshot 'labsnap' read-only and verify file recovery

Mounting a Stratis snapshot is done by its device path rather than UUID.
Because we mount it read-only (ro), we cannot accidentally modify or corrupt
the snapshot data during inspection.

Unlike an LVM snapshot merge (which we'll do in Step 7), Stratis does not
have a built-in merge operation. Recovery from a Stratis snapshot means
manually copying files from the mounted snapshot back to the origin —
or promoting the snapshot to become the new active filesystem.

Requirements:
  • Mount: /dev/stratis/labpool/labsnap → /mnt/stratis-snap
  • Mount option: ro  (read-only)
  • Filesystem type: xfs
  • Verify testfile.txt is accessible in /mnt/stratis-snap/

Commands you might need:
  • mount -o ro -t xfs /dev/stratis/labpool/labsnap /mnt/stratis-snap
  • ls /mnt/stratis-snap/
  • cat /mnt/stratis-snap/testfile.txt
  • cp /mnt/stratis-snap/testfile.txt /mnt/stratisdata/  (recovery)
EOF
}

validate_step_5() {
    # Check snapshot is mounted
    if ! mountpoint -q /mnt/stratis-snap 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /mnt/stratis-snap is not mounted"
        echo "  Try: mount -o ro -t xfs /dev/stratis/labpool/labsnap /mnt/stratis-snap"
        return 1
    fi

    # Check mount is read-only
    local mount_opts
    mount_opts=$(findmnt -n -o OPTIONS /mnt/stratis-snap 2>/dev/null)
    if ! echo "$mount_opts" | grep -q '\bro\b'; then
        echo ""
        print_color "$YELLOW" "⚠ /mnt/stratis-snap is not mounted read-only (options: ${mount_opts})"
        echo "  Remount: umount /mnt/stratis-snap && mount -o ro -t xfs /dev/stratis/labpool/labsnap /mnt/stratis-snap"
        return 1
    fi

    # Check the test file is accessible in the snapshot
    if [[ ! -f /mnt/stratis-snap/testfile.txt ]]; then
        echo ""
        print_color "$RED" "✗ testfile.txt not found in /mnt/stratis-snap"
        echo "  Ensure the snapshot was created AFTER writing the test file."
        echo "  If needed: umount /mnt/stratis-snap && stratis filesystem destroy labpool labsnap"
        echo "  Then redo step 4: write file → snapshot → delete from origin."
        return 1
    fi

    return 0
}

solution_step_5() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  mount -o ro -t xfs /dev/stratis/labpool/labsnap /mnt/stratis-snap

Verify recovery:
  ls /mnt/stratis-snap/
  # testfile.txt should be present

  cat /mnt/stratis-snap/testfile.txt
  # Output: snapshot test data

  # To actually recover the file to the origin:
  cp /mnt/stratis-snap/testfile.txt /mnt/stratisdata/

Explanation:
  • -o ro: mounts the snapshot read-only. This prevents any accidental
    modification of the snapshot during inspection. Stratis snapshots,
    unlike LVM snapshots, are fully independent filesystems — writing
    to them permanently changes them, which defeats the recovery purpose.
  • -t xfs: explicit filesystem type. Required because the /dev/stratis/
    device path is a symlink and some systems may not auto-detect the type.
  • /dev/stratis/labpool/labsnap: use the device path for snapshot mounts,
    not the UUID. The snapshot's UUID is separate from the origin's UUID
    and is listed in 'stratis filesystem list'.

Stratis recovery workflow summary:
  1. Mount snapshot read-only
  2. Copy needed files back to the origin filesystem
  3. Unmount and optionally destroy the snapshot when done
  (There is no merge/rollback operation in Stratis — manual copy is the
  recovery method. This is an important distinction from LVM.)

EOF
}

# ── STEP 6 ──────────────────────────────────────────────────────────────────
hint_step_6() {
    echo "  lvcreate -s creates a snapshot. The -L size here is the COW space, NOT the snapshot's data size."
}

show_step_6() {
    cat << 'EOF'
TASK: Build an LVM stack on /dev/loop83, then take a COW snapshot

This step contrasts LVM's snapshot mechanism against Stratis snapshots.
LVM snapshots use Copy-on-Write (COW): when the origin volume's blocks
change, the OLD content is copied into the snapshot space first. The
snapshot only records changes — it does not duplicate the entire volume.

COW space sizing matters: if the snapshot's COW space fills completely
(because too many blocks in the origin changed), the snapshot becomes
INVALID and is automatically removed by LVM. Size it generously.

Requirements:
  Build the LVM stack:
    • PV: /dev/loop83
    • VG: vgsnap
    • LV: lvorigin, size 500MiB, formatted XFS, mounted at /mnt/lvm-snap

  Prepare data and snapshot:
    1. Write a test file: echo "lvm snap test" > /mnt/lvm-snap/origin.txt
    2. Take a snapshot: lvcreate -s -n lvsnap -L 200M /dev/vgsnap/lvorigin
    3. Delete the test file from the origin: rm /mnt/lvm-snap/origin.txt

Commands you might need:
  • pvcreate /dev/loop83
  • vgcreate vgsnap /dev/loop83
  • lvcreate -n lvorigin -L 500M vgsnap
  • mkfs.xfs /dev/vgsnap/lvorigin
  • mount /dev/vgsnap/lvorigin /mnt/lvm-snap
  • lvcreate -s -n lvsnap -L 200M /dev/vgsnap/lvorigin
  • lvs   (snapshot shows origin LV in the Origin column)
EOF
}

validate_step_6() {
    # Check origin LV exists
    if ! lvs /dev/vgsnap/lvorigin >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ LV 'lvorigin' not found in vgsnap"
        echo "  Build the stack: pvcreate /dev/loop83 → vgcreate vgsnap /dev/loop83 → lvcreate -n lvorigin -L 500M vgsnap"
        return 1
    fi

    # Check snapshot LV exists
    if ! lvs /dev/vgsnap/lvsnap >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ LVM snapshot 'lvsnap' not found in vgsnap"
        echo "  Try: lvcreate -s -n lvsnap -L 200M /dev/vgsnap/lvorigin"
        return 1
    fi

    # Confirm lvsnap is actually a snapshot (has an origin)
    local snap_origin
    snap_origin=$(lvs --noheadings -o origin /dev/vgsnap/lvsnap 2>/dev/null | tr -d ' ')
    if [[ "$snap_origin" != "lvorigin" ]]; then
        echo ""
        print_color "$RED" "✗ 'lvsnap' does not appear to be a snapshot of 'lvorigin' (origin: '${snap_origin:-none}')"
        return 1
    fi

    # Check the test file was deleted (simulating data loss)
    if [[ -f /mnt/lvm-snap/origin.txt ]]; then
        echo ""
        print_color "$YELLOW" "⚠ origin.txt still exists in /mnt/lvm-snap — delete it to simulate data loss"
        echo "  rm /mnt/lvm-snap/origin.txt"
        return 1
    fi

    return 0
}

solution_step_6() {
    cat << 'EOF'

SOLUTION:
─────────
Build the LVM stack:
  pvcreate /dev/loop83
  vgcreate vgsnap /dev/loop83
  lvcreate -n lvorigin -L 500M vgsnap
  mkfs.xfs /dev/vgsnap/lvorigin
  mount /dev/vgsnap/lvorigin /mnt/lvm-snap

Write data, snapshot, simulate loss:
  echo "lvm snap test" > /mnt/lvm-snap/origin.txt
  lvcreate -s -n lvsnap -L 200M /dev/vgsnap/lvorigin
  rm /mnt/lvm-snap/origin.txt

Explanation of lvcreate -s:
  • -s (--snapshot): creates a snapshot instead of a new independent LV.
  • -n lvsnap: name of the snapshot LV.
  • -L 200M: the COW allocation — the amount of space reserved to store
    original blocks that get overwritten in the origin AFTER the snapshot
    is taken. This is NOT the total size of the snapshot's data; it's
    only the delta storage.
  • /dev/vgsnap/lvorigin: the origin LV to snapshot. The snapshot
    immediately reflects the origin's state at this exact moment.

COW space sizing rule of thumb:
  If you expect ~20% of the origin's blocks to change before you're done
  with the snapshot, allocate 20% of the origin's size. For a 500MiB
  origin where ~200MiB of data might change, 200MiB of COW is reasonable.
  If the COW space fills, LVM invalidates the snapshot automatically.

Verification:
  lvs
  # lvsnap shows lvorigin in the Origin column and a Data% usage

EOF
}

# ── STEP 7 ──────────────────────────────────────────────────────────────────
hint_step_7() {
    echo "  You must unmount lvorigin before merging. After lvconvert --merge, activate the LV and remount to verify recovery."
}

show_step_7() {
    cat << 'EOF'
TASK: Merge the LVM snapshot back into the origin to restore deleted data

LVM snapshot merging is a rollback operation: the origin LV is reverted to
the state it was in when the snapshot was taken. Any changes made to the
origin AFTER the snapshot (including our deleted file) are discarded, and
the deleted file is restored.

After a successful merge, the snapshot LV is automatically removed by LVM.

Requirements:
  1. Unmount the origin: umount /mnt/lvm-snap
     (The origin LV must be inactive for merge to proceed)
  2. Run: lvconvert --merge /dev/vgsnap/lvsnap
  3. Reactivate the origin LV:
       lvchange -an /dev/vgsnap/lvorigin
       lvchange -ay /dev/vgsnap/lvorigin
  4. Remount: mount /dev/vgsnap/lvorigin /mnt/lvm-snap
  5. Verify: ls /mnt/lvm-snap/  — origin.txt should be back

Commands you might need:
  • umount /mnt/lvm-snap
  • lvconvert --merge /dev/vgsnap/lvsnap
  • lvchange -an /dev/vgsnap/lvorigin
  • lvchange -ay /dev/vgsnap/lvorigin
  • mount /dev/vgsnap/lvorigin /mnt/lvm-snap
  • ls /mnt/lvm-snap/
  • lvs   (lvsnap should be gone after merge)
EOF
}

validate_step_7() {
    # Check that the snapshot no longer exists (merge consumed it)
    if lvs /dev/vgsnap/lvsnap >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ LVM snapshot 'lvsnap' still exists — merge may not have completed"
        echo "  Ensure /mnt/lvm-snap is unmounted first, then:"
        echo "  lvconvert --merge /dev/vgsnap/lvsnap"
        echo "  Then reactivate: lvchange -an /dev/vgsnap/lvorigin && lvchange -ay /dev/vgsnap/lvorigin"
        return 1
    fi

    # Check origin is mounted
    if ! mountpoint -q /mnt/lvm-snap 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /mnt/lvm-snap is not mounted"
        echo "  Remount: mount /dev/vgsnap/lvorigin /mnt/lvm-snap"
        return 1
    fi

    # Check the recovered file is present
    if [[ ! -f /mnt/lvm-snap/origin.txt ]]; then
        echo ""
        print_color "$RED" "✗ origin.txt not found in /mnt/lvm-snap — merge may not have restored origin state"
        echo "  Check: lvs  (lvsnap should be absent after a successful merge)"
        return 1
    fi

    return 0
}

solution_step_7() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  umount /mnt/lvm-snap
  lvconvert --merge /dev/vgsnap/lvsnap
  lvchange -an /dev/vgsnap/lvorigin
  lvchange -ay /dev/vgsnap/lvorigin
  mount /dev/vgsnap/lvorigin /mnt/lvm-snap

Verify recovery:
  ls /mnt/lvm-snap/
  # origin.txt should be present again

  cat /mnt/lvm-snap/origin.txt
  # Output: lvm snap test

  lvs
  # lvsnap is gone — it was consumed by the merge operation

Explanation:
  • umount: required because lvconvert --merge cannot operate on an
    actively mounted LV. The merge writes the snapshot's COW data back
    into the origin blocks.
  • lvconvert --merge /dev/vgsnap/lvsnap: initiates the merge. LVM
    copies the snapshot's recorded "original" blocks back over the
    changed blocks in the origin, effectively rolling the origin back
    in time to the snapshot point.
  • lvchange -an / -ay: deactivates then reactivates the origin LV.
    This forces the Device Mapper to reload the LV's mapping, which
    is sometimes necessary for the merge to fully take effect before
    remounting.
  • After the merge completes, the snapshot LV (lvsnap) is automatically
    deleted by LVM. You don't need to run lvremove.

Why the origin must be unmounted:
  The merge modifies the block mapping of the origin LV itself.
  If the filesystem were mounted, the kernel's VFS cache would have
  stale inode and block data that doesn't match what LVM just wrote —
  resulting in filesystem corruption. Always unmount before merging.

EOF
}

#############################################################################
# VALIDATE (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=7

    echo "Checking your configuration..."
    echo ""

    # CHECK 1: Stratis pool exists
    print_color "$CYAN" "[1/$total] Checking Stratis pool 'labpool'..."
    if stratis pool list 2>/dev/null | grep -q 'labpool'; then
        print_color "$GREEN" "  ✓ Stratis pool 'labpool' exists"
        ((score++))
    else
        print_color "$RED" "  ✗ Stratis pool 'labpool' not found"
        print_color "$YELLOW" "  Fix: stratis pool create labpool /dev/loop82"
    fi
    echo ""

    # CHECK 2: Stratis filesystem labdata exists
    print_color "$CYAN" "[2/$total] Checking Stratis filesystem 'labdata'..."
    if stratis filesystem list 2>/dev/null | grep -q 'labdata'; then
        print_color "$GREEN" "  ✓ Stratis filesystem 'labdata' exists in labpool"
        ((score++))
    else
        print_color "$RED" "  ✗ Stratis filesystem 'labdata' not found"
        print_color "$YELLOW" "  Fix: stratis filesystem create labpool labdata"
    fi
    echo ""

    # CHECK 3: Persistent fstab mount with stratisd dependency
    print_color "$CYAN" "[3/$total] Checking persistent fstab mount for labdata..."
    local fstab_ok=true
    if ! grep -q 'RHCSA-STRATIS-LAB' /etc/fstab; then
        print_color "$RED" "  ✗ No fstab entry with '# RHCSA-STRATIS-LAB' comment"
        print_color "$YELLOW" "  Fix: Add UUID=<uuid>  /mnt/stratisdata  xfs  defaults,x-systemd.requires=stratisd.service  0 0  # RHCSA-STRATIS-LAB"
        fstab_ok=false
    fi
    if $fstab_ok && ! grep 'RHCSA-STRATIS-LAB' /etc/fstab | grep -q 'x-systemd.requires=stratisd.service'; then
        print_color "$RED" "  ✗ fstab entry missing 'x-systemd.requires=stratisd.service'"
        fstab_ok=false
    fi
    if $fstab_ok && ! mountpoint -q /mnt/stratisdata 2>/dev/null; then
        print_color "$RED" "  ✗ /mnt/stratisdata is not mounted"
        print_color "$YELLOW" "  Fix: mount -a"
        fstab_ok=false
    fi
    if $fstab_ok; then
        print_color "$GREEN" "  ✓ fstab entry correct and /mnt/stratisdata is mounted"
        ((score++))
    fi
    echo ""

    # CHECK 4: Stratis snapshot labsnap exists
    print_color "$CYAN" "[4/$total] Checking Stratis snapshot 'labsnap'..."
    if stratis filesystem list 2>/dev/null | grep -q 'labsnap'; then
        print_color "$GREEN" "  ✓ Stratis snapshot 'labsnap' exists"
        ((score++))
    else
        print_color "$RED" "  ✗ Stratis snapshot 'labsnap' not found"
        print_color "$YELLOW" "  Fix: stratis filesystem snapshot labpool labdata labsnap"
    fi
    echo ""

    # CHECK 5: Snapshot mounted read-only with test file accessible
    print_color "$CYAN" "[5/$total] Checking snapshot mount at /mnt/stratis-snap..."
    if mountpoint -q /mnt/stratis-snap 2>/dev/null; then
        local snap_opts
        snap_opts=$(findmnt -n -o OPTIONS /mnt/stratis-snap 2>/dev/null)
        if echo "$snap_opts" | grep -q '\bro\b' && [[ -f /mnt/stratis-snap/testfile.txt ]]; then
            print_color "$GREEN" "  ✓ Snapshot mounted read-only and testfile.txt is accessible"
            ((score++))
        elif ! echo "$snap_opts" | grep -q '\bro\b'; then
            print_color "$RED" "  ✗ Snapshot is mounted but NOT read-only"
            print_color "$YELLOW" "  Fix: umount /mnt/stratis-snap && mount -o ro -t xfs /dev/stratis/labpool/labsnap /mnt/stratis-snap"
        else
            print_color "$RED" "  ✗ Snapshot mounted but testfile.txt not found"
            print_color "$YELLOW" "  Ensure snapshot was taken AFTER writing testfile.txt"
        fi
    else
        print_color "$RED" "  ✗ /mnt/stratis-snap is not mounted"
        print_color "$YELLOW" "  Fix: mount -o ro -t xfs /dev/stratis/labpool/labsnap /mnt/stratis-snap"
    fi
    echo ""

    # CHECK 6: LVM snapshot taken (lvsnap exists OR merge already done)
    print_color "$CYAN" "[6/$total] Checking LVM origin volume 'lvorigin' in vgsnap..."
    if lvs /dev/vgsnap/lvorigin >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ LV 'lvorigin' exists in vgsnap"
        ((score++))
    else
        print_color "$RED" "  ✗ LV 'lvorigin' not found in vgsnap"
        print_color "$YELLOW" "  Fix: pvcreate /dev/loop83 && vgcreate vgsnap /dev/loop83 && lvcreate -n lvorigin -L 500M vgsnap"
    fi
    echo ""

    # CHECK 7: LVM snapshot merged and file recovered
    print_color "$CYAN" "[7/$total] Checking LVM snapshot merge and file recovery..."
    local snap_gone=false
    local file_recovered=false
    ! lvs /dev/vgsnap/lvsnap >/dev/null 2>&1 && snap_gone=true
    [[ -f /mnt/lvm-snap/origin.txt ]] && file_recovered=true

    if $snap_gone && $file_recovered; then
        print_color "$GREEN" "  ✓ Snapshot merged, lvsnap removed, origin.txt recovered"
        ((score++))
    elif ! $snap_gone; then
        print_color "$RED" "  ✗ LVM snapshot 'lvsnap' still exists — merge not yet run"
        print_color "$YELLOW" "  Fix: umount /mnt/lvm-snap && lvconvert --merge /dev/vgsnap/lvsnap"
        print_color "$YELLOW" "       Then: lvchange -an /dev/vgsnap/lvorigin && lvchange -ay /dev/vgsnap/lvorigin && mount /dev/vgsnap/lvorigin /mnt/lvm-snap"
    else
        print_color "$RED" "  ✗ Snapshot merged but origin.txt not found in /mnt/lvm-snap"
        print_color "$YELLOW" "  Ensure the snapshot was taken AFTER writing origin.txt, and remount if needed."
    fi
    echo ""

    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've successfully completed all Stratis and"
        echo "LVM snapshot objectives. You understand both storage paradigms."
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

STEP 1: Create Stratis pool
─────────────────────────────────────────────────────────────────
  systemctl start stratisd
  stratis pool create labpool /dev/loop82

Verification:
  stratis pool list
  # labpool listed with ~8 GiB total physical


STEP 2: Create Stratis filesystem
─────────────────────────────────────────────────────────────────
  stratis filesystem create labpool labdata

Verification:
  stratis filesystem list
  # labdata listed with UUID and device path /dev/stratis/labpool/labdata


STEP 3: Persistent fstab mount
─────────────────────────────────────────────────────────────────
  # Get UUID:
  stratis filesystem list

  # Add to /etc/fstab:
  UUID=<your-uuid>  /mnt/stratisdata  xfs  defaults,x-systemd.requires=stratisd.service  0 0  # RHCSA-STRATIS-LAB

  mount -a

Verification:
  mountpoint /mnt/stratisdata && echo "mounted"


STEP 4: Write test file, snapshot, simulate loss
─────────────────────────────────────────────────────────────────
  echo "snapshot test data" > /mnt/stratisdata/testfile.txt
  stratis filesystem snapshot labpool labdata labsnap
  rm /mnt/stratisdata/testfile.txt

Verification:
  stratis filesystem list   # labsnap present
  ls /mnt/stratisdata/      # testfile.txt absent


STEP 5: Mount snapshot read-only and verify recovery
─────────────────────────────────────────────────────────────────
  mount -o ro -t xfs /dev/stratis/labpool/labsnap /mnt/stratis-snap
  cat /mnt/stratis-snap/testfile.txt
  # Output: snapshot test data

  # Optional: recover file to origin
  cp /mnt/stratis-snap/testfile.txt /mnt/stratisdata/


STEP 6: LVM stack, snapshot, simulate loss
─────────────────────────────────────────────────────────────────
  pvcreate /dev/loop83
  vgcreate vgsnap /dev/loop83
  lvcreate -n lvorigin -L 500M vgsnap
  mkfs.xfs /dev/vgsnap/lvorigin
  mount /dev/vgsnap/lvorigin /mnt/lvm-snap
  echo "lvm snap test" > /mnt/lvm-snap/origin.txt
  lvcreate -s -n lvsnap -L 200M /dev/vgsnap/lvorigin
  rm /mnt/lvm-snap/origin.txt


STEP 7: Merge LVM snapshot to restore origin
─────────────────────────────────────────────────────────────────
  umount /mnt/lvm-snap
  lvconvert --merge /dev/vgsnap/lvsnap
  lvchange -an /dev/vgsnap/lvorigin
  lvchange -ay /dev/vgsnap/lvorigin
  mount /dev/vgsnap/lvorigin /mnt/lvm-snap

Verification:
  ls /mnt/lvm-snap/    # origin.txt is back
  lvs                  # lvsnap is gone


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Stratis vs LVM Snapshots — the critical difference:
  LVM snapshots are COW mirrors: blocks modified in the origin after
  snapshot creation are preserved in the snapshot's COW space. The
  snapshot is a dependent sibling of the origin — it tracks deltas.
  Merging an LVM snapshot REVERTS the origin to its snapshotted state.

  Stratis snapshots are independent clones: after creation the snapshot
  and origin diverge completely. There is no merge operation. Recovery
  means manually copying files from the snapshot back to the origin.
  This makes Stratis snapshots more useful for "branch and experiment"
  workflows and less useful for simple rollback scenarios.

Thin Provisioning — why 'df' lies on Stratis:
  Stratis presents each filesystem with a virtual 1 TiB size. 'df' reads
  this virtual size from the XFS superblock. The actual disk consumption
  lives at the pool level and is only visible via 'stratis pool list'.
  In production, set up monitoring against pool usage, not df output.

The x-systemd.requires mount option:
  systemd generates mount units from /etc/fstab at boot. Without this
  option, systemd may schedule the mount unit to run in parallel with
  (or before) stratisd.service, causing a race condition where the
  Stratis devices don't exist yet when the mount is attempted. The
  x-systemd.requires option inserts an explicit ordering constraint.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using /dev/stratis/... path in fstab instead of UUID
  Result: Boot failure — the device path only exists after stratisd
          activates, which happens after fstab processing.
  Fix:    Use UUID= from 'stratis filesystem list' or blkid.

Mistake 2: Omitting x-systemd.requires=stratisd.service in fstab
  Result: Intermittent mount failures at boot (race condition).
  Fix:    Always include this option for any Stratis filesystem in fstab.

Mistake 3: Trying to merge an LVM snapshot while origin is mounted
  Result: lvconvert refuses with "Logical volume is in use"
  Fix:    umount first, then merge, then reactivate with lvchange -an/-ay.

Mistake 4: COW space too small for LVM snapshot
  Result: LVM prints "snapshot is invalid" and auto-removes the snapshot.
  Fix:    Recreate with larger -L. Monitor COW usage with: lvs -o snap_percent


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Stratis requires stratisd to be running. If stratis commands fail with
   a connection error, check: systemctl status stratisd

2. For any Stratis fstab entry: UUID + xfs + x-systemd.requires=stratisd.service
   Forgetting any one of these three elements will cost you the objective.

3. LVM snapshot merge requires: unmount → merge → deactivate → activate → remount.
   The deactivate/activate cycle (lvchange -an/-ay) is easy to forget
   under exam pressure — include it as a habit.

4. Know which snapshot type supports merge/rollback (LVM only) vs. which
   requires manual file copy for recovery (Stratis). The exam may ask
   you to describe the difference or demonstrate one or the other.

5. stratis pool list is your space monitor for Stratis — not df.
   If a Stratis task asks you to verify available space, use pool list.

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    systemctl start stratisd 2>/dev/null || true

    umount /mnt/stratisdata   2>/dev/null || true
    umount /mnt/stratis-snap  2>/dev/null || true
    umount /mnt/lvm-snap      2>/dev/null || true

    stratis filesystem destroy labpool labsnap  2>/dev/null || true
    stratis filesystem destroy labpool labdata  2>/dev/null || true
    stratis pool destroy labpool                2>/dev/null || true

    lvremove -f /dev/vgsnap/lvsnap   2>/dev/null || true
    lvremove -f /dev/vgsnap/lvorigin 2>/dev/null || true
    vgremove -f vgsnap               2>/dev/null || true
    pvremove -f /dev/loop83          2>/dev/null || true

    losetup -d /dev/loop82 2>/dev/null || true
    losetup -d /dev/loop83 2>/dev/null || true

    rm -f /tmp/lab-stratis.img /tmp/lab-snap.img
    rm -rf /mnt/stratisdata /mnt/stratis-snap /mnt/lvm-snap

    sed -i '/# RHCSA-STRATIS-LAB/d' /etc/fstab
    sed -i '/# RHCSA-SNAP-LAB/d'    /etc/fstab

    echo "  ✓ Stratis pool, filesystems, and snapshots removed"
    echo "  ✓ LVM snapshot, origin LV, VG, and PV removed"
    echo "  ✓ Loopback devices detached and image files removed"
    echo "  ✓ Mount points and fstab entries cleaned"
}

# Execute the main framework
main "$@"
