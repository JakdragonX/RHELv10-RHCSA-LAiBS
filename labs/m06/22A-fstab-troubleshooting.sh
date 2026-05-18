#!/bin/bash
# labs/22A-fstab-troubleshooting.sh
# Lab: Filesystem Troubleshooting — Breaking and Fixing /etc/fstab
# Difficulty: Intermediate
# RHCSA Objective: Diagnose and correct file permission problems; troubleshoot fstab issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Filesystem Troubleshooting — Breaking and Fixing /etc/fstab"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Restore any previous backup first to start clean
    if [ -f /etc/fstab.lab-backup ]; then
        cp /etc/fstab.lab-backup /etc/fstab
    else
        cp /etc/fstab /etc/fstab.lab-backup
    fi

    # Create the lab loop device image and mount point
    rm -f /tmp/lab22a.img 2>/dev/null || true
    rm -rf /mnt/lab22a 2>/dev/null || true

    # Detach any previous lab loop device
    losetup -j /tmp/lab22a.img 2>/dev/null | cut -d: -f1 | xargs -r losetup -d 2>/dev/null || true

    # Create a small ext4 image we can safely add to fstab
    dd if=/dev/zero of=/tmp/lab22a.img bs=1M count=32 status=none
    mkfs.ext4 -F -L lab22a /tmp/lab22a.img >/dev/null 2>&1

    # Set up the loop device
    LOOP_DEV=$(losetup --find --show /tmp/lab22a.img)
    mkdir -p /mnt/lab22a

    echo "  ✓ Created 32MB ext4 image at /tmp/lab22a.img (loop: $LOOP_DEV)"
    echo "  ✓ Created mount point /mnt/lab22a"
    echo "  ✓ Original /etc/fstab backed up to /etc/fstab.lab-backup"
    echo ""
    echo "  LAB LOOP DEVICE: $LOOP_DEV"
    echo "  You will need this value. Run 'losetup -j /tmp/lab22a.img' to find it again."
    echo ""
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • What /etc/fstab is and how it controls filesystem mounts at boot
  • The six fields of an fstab entry: device, mount point, fstype, options, dump, pass
  • That a bad fstab entry can prevent the system from booting normally
  • Basic understanding of loop devices (a file used as a block device)

Commands You'll Use:
  • mount -a        - Attempt to mount all entries in /etc/fstab not yet mounted
  • findmnt --verify - Validate /etc/fstab syntax without actually mounting
  • findmnt         - Show currently mounted filesystems in tree format
  • losetup         - Manage loop devices (associate files with /dev/loopN)
  • blkid           - Show block device attributes including UUID and LABEL
  • umount          - Unmount a filesystem

Files You'll Interact With:
  • /etc/fstab             - Filesystem table — defines what mounts at boot
  • /etc/fstab.lab-backup  - Backup created by lab setup (your safety net)
  • /tmp/lab22a.img        - Loop device image created by this lab
  • /mnt/lab22a/           - Mount point for the lab filesystem

THE SIX FSTAB FIELDS (memorize these):
  <device>  <mountpoint>  <fstype>  <options>  <dump>  <pass>

  device:     What to mount. Can be device path (/dev/sda1), UUID=..., or LABEL=...
  mountpoint: Where to mount it (must exist as a directory)
  fstype:     Filesystem type: ext4, xfs, tmpfs, nfs, etc.
  options:    Mount options. 'defaults' means rw,suid,dev,exec,auto,nouser,async
  dump:       0 = don't back up with dump utility (almost always 0)
  pass:       fsck order: 0=skip, 1=root filesystem only, 2=check after root
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A junior admin attempted to add a new filesystem entry to /etc/fstab on a
production server but introduced a typo in the device field. If the server
reboots, it will fail to mount that filesystem and drop into emergency mode.
Your task is to: add a correct fstab entry for a lab filesystem, verify it,
then intentionally introduce a bad entry and use diagnostic tools to catch
the error before it causes a boot failure.

BACKGROUND:
The lab setup created a 32MB ext4 filesystem on a loop device at /tmp/lab22a.img
mounted at /mnt/lab22a. The loop device path (e.g. /dev/loop0) was printed
during setup — run 'losetup -j /tmp/lab22a.img' to find it again.

OBJECTIVES:
  1. Find the loop device for /tmp/lab22a.img using losetup, then add a valid
     fstab entry for it in /etc/fstab. The entry must use LABEL=lab22a as the
     device field (not the loop path). Mount point: /mnt/lab22a, type: ext4,
     options: defaults, dump: 0, pass: 2.
     Test with: mount -a and findmnt --verify

  2. Verify the filesystem is mounted at /mnt/lab22a using findmnt.
     Then create a file inside it: touch /mnt/lab22a/lab-marker.txt
     Confirm the file exists.

  3. Now intentionally break the fstab entry: change LABEL=lab22a to
     LABEL=doesnotexist in /etc/fstab. Run findmnt --verify to observe the
     error it reports. Then run mount -a and observe the failure.
     Fix the entry by restoring the correct LABEL. Verify with findmnt --verify
     that no errors are reported before moving on.

HINTS:
  • losetup -j /tmp/lab22a.img — shows which /dev/loopN is associated with the image
  • blkid /dev/loopN — shows the LABEL and UUID of the filesystem on that device
  • findmnt --verify prints warnings and errors; exit code 0 means no errors
  • mount -a only mounts entries not already mounted — umount first if needed
  • A bad fstab entry that makes it to reboot drops the system into emergency.target

SUCCESS CRITERIA:
  • /etc/fstab contains a valid entry for LABEL=lab22a mounted at /mnt/lab22a
  • findmnt --verify exits with code 0 (no errors)
  • /mnt/lab22a/lab-marker.txt exists
  • The broken entry you introduced in step 3 has been corrected
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Add a valid fstab entry (LABEL=lab22a /mnt/lab22a ext4 defaults 0 2); test with mount -a
  ☐ 2. Verify mount with findmnt; create /mnt/lab22a/lab-marker.txt
  ☐ 3. Break fstab (LABEL=doesnotexist), observe findmnt --verify error, then fix it
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "3"
}

scenario_context() {
    cat << 'EOF'
A bad fstab entry on a production server will cause a boot failure. You need
to add a correct entry, verify it, deliberately break it to understand the
diagnostic tools, and then fix it — building the muscle memory for real incidents.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Add a valid /etc/fstab entry for the lab filesystem

Find the loop device, confirm its LABEL, then add the correct fstab entry.

Requirements:
  • Use LABEL=lab22a as the device field (NOT the /dev/loopN path)
  • Mount point: /mnt/lab22a
  • Filesystem type: ext4
  • Options: defaults
  • Dump: 0, Pass: 2
  • Run 'mount -a' to mount it without rebooting
  • Run 'findmnt --verify' to confirm no syntax errors

Commands you might need:
  • losetup -j /tmp/lab22a.img       - Find the loop device path
  • blkid /dev/loopN                 - Confirm the LABEL is 'lab22a'
  • vi /etc/fstab                    - Edit the fstab
  • mount -a                         - Mount all unmounted fstab entries
  • findmnt --verify                 - Check fstab syntax
EOF
}

validate_step_1() {
    # Check that a valid lab22a entry exists in fstab
    if ! grep -q "lab22a" /etc/fstab 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ No entry containing 'lab22a' found in /etc/fstab"
        echo "  Add: LABEL=lab22a  /mnt/lab22a  ext4  defaults  0  2"
        return 1
    fi

    # Check that findmnt --verify passes (exit 0)
    if ! findmnt --verify >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ findmnt --verify reports errors in /etc/fstab"
        echo "  Run: findmnt --verify"
        echo "  Fix the reported errors before proceeding"
        return 1
    fi

    # Check that /mnt/lab22a is actually mounted
    if ! findmnt /mnt/lab22a >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ /mnt/lab22a is not currently mounted"
        echo "  Fix: mount -a"
        return 1
    fi

    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  # Find the loop device
  losetup -j /tmp/lab22a.img

  # Confirm the LABEL (replace loopN with your actual device)
  blkid /dev/loopN

  # Add the entry to fstab
  echo 'LABEL=lab22a  /mnt/lab22a  ext4  defaults  0  2' >> /etc/fstab

  # Test without rebooting
  mount -a

  # Verify syntax
  findmnt --verify

Explanation:
  • LABEL=lab22a: using a label instead of /dev/loopN is important because
    loop device numbers are not stable — /dev/loop0 today may be /dev/loop3
    after a reboot with different devices attached. Labels and UUIDs are stable.
  • mount -a: reads fstab and mounts any entry not already mounted. This is
    the safe way to test a new fstab entry without rebooting.
  • findmnt --verify: parses fstab and reports syntax errors, missing mount
    points, unknown filesystem types, and other problems. Exit code 0 = clean.
  • Pass field '2': tells fsck to check this filesystem after the root
    filesystem (pass 1). Root is always checked first; all others use 2.

Why LABEL over path:
  If you wrote /dev/loop0 in fstab and rebooted with a USB drive attached,
  the USB might claim /dev/loop0 and your entry would mount the wrong device —
  or fail entirely. LABEL and UUID refer to the filesystem itself, not a slot.

Verification:
  findmnt /mnt/lab22a
  # Should show: TARGET        SOURCE      FSTYPE OPTIONS
  #              /mnt/lab22a   /dev/loopN  ext4   rw,...

EOF
}

hint_step_2() {
    echo "  findmnt /mnt/lab22a confirms it's mounted; then: touch /mnt/lab22a/lab-marker.txt"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Verify the mount and create a file on the new filesystem

Confirm the filesystem is mounted at the correct location, then create a
marker file on it to prove the filesystem is writable.

Requirements:
  • Verify the mount using findmnt (not just 'ls /mnt/lab22a')
  • Create the file: /mnt/lab22a/lab-marker.txt
  • Confirm the file exists

Commands you might need:
  • findmnt /mnt/lab22a
  • findmnt -T /mnt/lab22a    (finds the mount covering a path)
  • touch /mnt/lab22a/lab-marker.txt
  • ls -l /mnt/lab22a/
EOF
}

validate_step_2() {
    if [ ! -f /mnt/lab22a/lab-marker.txt ]; then
        echo ""
        print_color "$RED" "✗ /mnt/lab22a/lab-marker.txt does not exist"
        if ! findmnt /mnt/lab22a >/dev/null 2>&1; then
            echo "  /mnt/lab22a is not mounted — run: mount -a"
        else
            echo "  Filesystem is mounted but file is missing — run: touch /mnt/lab22a/lab-marker.txt"
        fi
        return 1
    fi
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  findmnt /mnt/lab22a
  touch /mnt/lab22a/lab-marker.txt
  ls -l /mnt/lab22a/

Explanation:
  • findmnt /mnt/lab22a: shows detailed mount info for that specific point.
    More reliable than 'df' or 'mount | grep' because it reads the kernel's
    actual mount table, not just fstab.
  • touch: creates an empty file if it doesn't exist, or updates its timestamp
    if it does. Writing to /mnt/lab22a proves the filesystem is mounted
    read-write and is actually our ext4 image (not just an empty directory).

Verification:
  ls -l /mnt/lab22a/
  # Expected: lab-marker.txt (and a lost+found directory from mkfs.ext4)

EOF
}

hint_step_3() {
    echo "  Change LABEL=lab22a to LABEL=doesnotexist in /etc/fstab, then run findmnt --verify"
    echo "  After observing the error, change it back and verify again"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Deliberately break fstab, diagnose with findmnt --verify, then fix it

This step builds the diagnostic reflex: always run findmnt --verify after
editing fstab, before rebooting.

Requirements:
  • Edit /etc/fstab: change LABEL=lab22a to LABEL=doesnotexist
  • Unmount /mnt/lab22a first so mount -a can attempt the mount
  • Run findmnt --verify — observe and note the error message
  • Run mount -a — observe the failure
  • Fix the entry back to LABEL=lab22a
  • Run findmnt --verify again — confirm it exits cleanly (no errors)

Commands you might need:
  • umount /mnt/lab22a
  • vi /etc/fstab             (change the LABEL)
  • findmnt --verify          (observe the error)
  • mount -a                  (observe the failure)
  • vi /etc/fstab             (fix it back)
  • findmnt --verify          (confirm clean)
  • mount -a                  (remount)
EOF
}

validate_step_3() {
    # After fixing, fstab should again contain the correct label
    if ! grep -q "LABEL=lab22a" /etc/fstab 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /etc/fstab does not contain 'LABEL=lab22a'"
        echo "  The broken entry has not been corrected yet"
        echo "  Fix: edit /etc/fstab and restore LABEL=lab22a"
        return 1
    fi

    if ! findmnt --verify >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ findmnt --verify still reports errors"
        echo "  Run: findmnt --verify"
        return 1
    fi

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  # Unmount so mount -a can attempt to re-mount it
  umount /mnt/lab22a

  # Break it
  sed -i 's/LABEL=lab22a/LABEL=doesnotexist/' /etc/fstab

  # Diagnose
  findmnt --verify
  # You will see an error like:
  #   [E] cannot find source /dev/disk/by-label/doesnotexist

  mount -a
  # You will see: mount: /mnt/lab22a: can't find LABEL=doesnotexist

  # Fix it
  sed -i 's/LABEL=doesnotexist/LABEL=lab22a/' /etc/fstab

  # Verify clean
  findmnt --verify
  mount -a

Explanation:
  • findmnt --verify catches the error BEFORE mount -a fails. This is the
    key habit: verify syntax first, mount second, reboot last.
  • The error from mount -a is clear but happens at runtime. If this were
    a real boot scenario, the system would drop to emergency.target instead
    of printing a friendly message.
  • sed -i: edits the file in place. Useful for scripted fixes, but always
    verify afterward — a typo in the sed pattern can corrupt fstab.

What happens at boot with a bad fstab entry:
  systemd attempts to mount all fstab entries during early boot.
  If a required mount fails (any entry without 'nofail' or 'noauto' options),
  systemd drops to emergency.target — a minimal root shell. Recovery requires
  remounting root read-write and editing fstab from that shell.

The 'nofail' option:
  Adding 'nofail' to the options field tells systemd to ignore mount failures
  for that entry. Useful for non-critical external drives (e.g., USB, NAS).
  Never use nofail for filesystems that applications depend on at boot.

Verification:
  findmnt --verify
  # Expected: (no output or warnings) — exit code 0

  findmnt /mnt/lab22a
  # Should show the filesystem mounted again after mount -a

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=3

    echo "Checking your configuration..."
    echo ""

    print_color "$CYAN" "[1/$total] Checking /etc/fstab contains a valid LABEL=lab22a entry..."
    if grep -q "LABEL=lab22a" /etc/fstab 2>/dev/null; then
        print_color "$GREEN" "  ✓ LABEL=lab22a entry present in /etc/fstab"
        ((score++))
    else
        print_color "$RED" "  ✗ No LABEL=lab22a entry in /etc/fstab"
        print_color "$YELLOW" "  Fix: Add 'LABEL=lab22a  /mnt/lab22a  ext4  defaults  0  2' to /etc/fstab"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking findmnt --verify reports no errors..."
    if findmnt --verify >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ findmnt --verify passes cleanly"
        ((score++))
    else
        print_color "$RED" "  ✗ findmnt --verify reports errors in /etc/fstab"
        print_color "$YELLOW" "  Run: findmnt --verify"
        findmnt --verify 2>&1 | sed 's/^/    /'
    fi
    echo ""

    print_color "$CYAN" "[3/$total] Checking /mnt/lab22a/lab-marker.txt exists..."
    if [ -f /mnt/lab22a/lab-marker.txt ]; then
        print_color "$GREEN" "  ✓ /mnt/lab22a/lab-marker.txt exists"
        ((score++))
    else
        if ! findmnt /mnt/lab22a >/dev/null 2>&1; then
            print_color "$RED" "  ✗ /mnt/lab22a is not mounted — run: mount -a"
        else
            print_color "$RED" "  ✗ lab-marker.txt is missing — run: touch /mnt/lab22a/lab-marker.txt"
        fi
        print_color "$YELLOW" "  Fix: mount -a && touch /mnt/lab22a/lab-marker.txt"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent! You can safely edit and verify /etc/fstab changes."
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

STEP 1: Add a valid fstab entry
─────────────────────────────────────────────────────────────────
  losetup -j /tmp/lab22a.img          # find the loop device
  blkid /dev/loopN                    # confirm LABEL=lab22a

  echo 'LABEL=lab22a  /mnt/lab22a  ext4  defaults  0  2' >> /etc/fstab

  mount -a
  findmnt --verify


STEP 2: Verify mount and create marker file
─────────────────────────────────────────────────────────────────
  findmnt /mnt/lab22a
  touch /mnt/lab22a/lab-marker.txt
  ls -l /mnt/lab22a/


STEP 3: Break, diagnose, and fix
─────────────────────────────────────────────────────────────────
  umount /mnt/lab22a
  sed -i 's/LABEL=lab22a/LABEL=doesnotexist/' /etc/fstab
  findmnt --verify                    # observe: cannot find source
  mount -a                            # observe: can't find LABEL=doesnotexist
  sed -i 's/LABEL=doesnotexist/LABEL=lab22a/' /etc/fstab
  findmnt --verify                    # confirm: no errors
  mount -a                            # remount


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The fstab Edit → Verify → Mount → Reboot Workflow:
  1. Edit /etc/fstab
  2. findmnt --verify    ← catch syntax errors BEFORE mounting
  3. mount -a            ← test mounting without rebooting
  4. findmnt <path>      ← confirm the filesystem is actually mounted
  5. reboot              ← only after all above pass

  Skipping any of these steps, especially step 2, is how admins end up
  with systems that won't boot and require console/iDRAC/KVM recovery.

Device Identification Methods (fstab column 1):
  /dev/sda1           → fragile (device order can change on reboot)
  UUID=<uuid>         → stable, survives device reordering
  LABEL=<label>       → stable and human-readable, but labels must be unique
  Use UUID or LABEL; never /dev/sdX for anything that must survive a reboot.

Emergency Recovery from a Bad fstab (What to do if you didn't verify):
  At the emergency.target shell:
    mount -o remount,rw /          # remount root read-write
    vi /etc/fstab                  # fix the bad entry
    exit                           # systemd will retry mounting and continue boot


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Not running findmnt --verify before rebooting
  Result: System drops to emergency.target on next boot
  Fix: Always verify before rebooting; use nofail for non-critical mounts

Mistake 2: Using /dev/loopN as the fstab device field
  Result: Different loop number on next boot = wrong mount or mount failure
  Fix: Always use LABEL= or UUID= for stable device references

Mistake 3: Forgetting to run mount -a after editing fstab
  Result: Thinking the entry works because there's no error — but it was never tested
  Fix: mount -a mounts unmounted entries; if it fails, the reboot would have failed too


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. findmnt --verify after EVERY fstab edit — this is the exam-safe habit
2. mount -a to test without rebooting — always do this before the exam timer runs out
3. Know the six fstab fields in order: device mountpoint fstype options dump pass
4. Pass field: 0=skip fsck, 1=root only, 2=after root (use 2 for non-root filesystems)
5. Emergency recovery: remount -o remount,rw / → fix fstab → exit

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    # Unmount if mounted
    umount /mnt/lab22a 2>/dev/null || true

    # Restore original fstab
    if [ -f /etc/fstab.lab-backup ]; then
        cp /etc/fstab.lab-backup /etc/fstab
        rm -f /etc/fstab.lab-backup
        echo "  ✓ /etc/fstab restored from backup"
    fi

    # Detach loop device
    losetup -j /tmp/lab22a.img 2>/dev/null | cut -d: -f1 | xargs -r losetup -d 2>/dev/null || true

    # Remove image and mount point
    rm -f /tmp/lab22a.img 2>/dev/null || true
    rm -rf /mnt/lab22a 2>/dev/null || true

    echo "  ✓ Loop device detached"
    echo "  ✓ Lab image and mount point removed"
}

main "$@"
