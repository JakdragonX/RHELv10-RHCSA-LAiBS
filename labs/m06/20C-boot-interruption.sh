#!/bin/bash
# labs/20C-boot-interruption.sh
# Lab: Boot Interruption, Recovery Targets, and GRUB2 Runtime Editing
# Difficulty: Advanced
# RHCSA Objective: Interrupt the boot process to gain access to a system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Boot Interruption and Recovery Targets"
LAB_DIFFICULTY="Advanced"
LAB_TIME_ESTIMATE="20-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Create a test service to simulate a "broken" startup service.
    # Type=simple is used intentionally: unlike Type=oneshot, a simple service
    # that exits non-zero immediately is held in 'failed' state by systemd and
    # produces a journal entry with the exit code — which is what we want the
    # student to find and diagnose.
    cat > /etc/systemd/system/lab20c-broken.service << 'SVCEOF'
[Unit]
Description=Lab 20C Simulated Broken Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/false

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload 2>/dev/null || true
    systemctl enable lab20c-broken.service 2>/dev/null || true
    # Start it so it actually executes, fails, and lands in 'failed' state
    # with a journal entry. '|| true' prevents setup from aborting on the
    # expected non-zero exit.
    systemctl start lab20c-broken.service 2>/dev/null || true

    # Save the current default target
    systemctl get-default > /tmp/lab20c-original-default.txt 2>/dev/null || true

    echo "  ✓ Simulated broken service created and enabled: lab20c-broken.service"
    echo "  ✓ Original default target saved"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Labs 20A and 20B (GRUB2 config and systemd targets) — this builds on both
  • Understanding of systemd unit files: [Unit], [Service], [Install] sections
  • What 'rd.break' does at the kernel cmdline level
  • The difference between a live system rescue and a GRUB2 runtime edit

Commands You'll Use:
  • systemctl                 - Query and control systemd
  • journalctl -xb            - View logs from the current boot
  • systemctl --failed        - List failed units
  • systemd-analyze blame     - Show which services slow down boot
  • systemd-analyze critical-chain - Show the critical boot path

Files You'll Interact With:
  • /etc/systemd/system/lab20c-broken.service  - The simulated broken service
  • /etc/systemd/system/*.wants/               - Symlinks enabling services for targets
  • /proc/cmdline                              - Kernel parameters for the current boot

IMPORTANT — THIS LAB IS MOSTLY CONCEPTUAL:
  Steps 1 and 2 are hands-on. Step 3 (actual GRUB2 runtime editing and
  rd.break usage) requires a reboot and physical/console access. The solution
  section provides the full procedure you MUST know for the exam — study it
  even if you cannot perform it in this environment.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A RHEL server won't fully boot due to a misconfigured service. You need to:
(a) diagnose the failure using systemd tooling on the running system,
(b) understand how to boot into a recovery target from GRUB2 when a system
    won't boot at all, and
(c) know the rd.break technique for resetting the root password — a classic
    RHCSA exam task.

BACKGROUND:
In a real exam scenario you may be given a machine that can't complete normal
boot. You'll need to interrupt GRUB2, add a kernel parameter, and use the
resulting environment to fix the issue and continue boot.

OBJECTIVES:
  1. Identify the failed service (lab20c-broken.service) using systemctl and
     journalctl. Understand what caused it to fail and how to mask a service
     to prevent it from blocking boot.
     Mask the service: systemctl mask lab20c-broken.service

  2. Examine /proc/cmdline to see what kernel parameters the system booted with.
     Then use systemd-analyze blame and systemd-analyze critical-chain to
     understand boot performance and dependency chains.

  3. [CONCEPTUAL + PROCEDURE] Study and be able to reproduce the full procedure
     for resetting the root password using rd.break at the GRUB2 prompt.
     This is a frequent RHCSA exam task. The solution section contains the
     complete step-by-step procedure.

HINTS:
  • 'systemctl --failed' shows all units in a failed state
  • 'journalctl -u lab20c-broken.service' shows logs specific to that unit
  • Masking a service creates a symlink to /dev/null, preventing ANY start
  • rd.break interrupts boot before the root filesystem is mounted read-write

SUCCESS CRITERIA:
  • lab20c-broken.service is masked (symlinked to /dev/null)
  • You can recite the rd.break password reset procedure from memory
  • /proc/cmdline output is displayed and you can identify each parameter
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Identify and mask the failed lab20c-broken.service
  ☐ 2. Display /proc/cmdline; run systemd-analyze blame and critical-chain
  ☐ 3. [Study] rd.break root password reset procedure (see --solution)
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
A RHEL server has a misconfigured service blocking boot. You need to diagnose
the failure, mask the broken service, and study the boot interruption procedure
used for root password resets on the RHCSA exam.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Diagnose and mask the failing service

A service called 'lab20c-broken.service' has been enabled but always fails.
Identify it, inspect why it fails, and mask it so it cannot be started by
any means (manual or automatic).

Requirements:
  • Find the failed service using systemctl
  • Read its logs with journalctl
  • Mask it using systemctl mask

Commands you might need:
  • systemctl --failed
  • systemctl status lab20c-broken.service
  • journalctl -u lab20c-broken.service
  • systemctl mask lab20c-broken.service
  • ls -la /etc/systemd/system/lab20c-broken.service   (after masking)
EOF
}

validate_step_1() {
    # Check if the service is masked (symlink to /dev/null)
    local link_target
    link_target=$(readlink /etc/systemd/system/lab20c-broken.service 2>/dev/null)

    if [ "$link_target" = "/dev/null" ]; then
        return 0
    fi

    echo ""
    print_color "$RED" "✗ lab20c-broken.service is not masked (symlink target: '$link_target')"
    echo "  Fix: systemctl mask lab20c-broken.service"
    return 1
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  systemctl --failed
  systemctl status lab20c-broken.service
  journalctl -u lab20c-broken.service --no-pager
  systemctl mask lab20c-broken.service

Explanation:
  • systemctl --failed: lists all units currently in a failed state with exit codes
  • journalctl -u <unit>: shows logs specifically from that unit across all boots
  • systemctl mask: creates a symlink from the unit file to /dev/null
    This is stronger than 'disable' — masked services cannot be started even manually

After masking, check:
  ls -la /etc/systemd/system/lab20c-broken.service
  # Expected: /etc/systemd/system/lab20c-broken.service -> /dev/null

Why mask instead of disable?
  'disable' removes the WantedBy symlink from multi-user.target.wants/ so it
  won't start automatically, but 'systemctl start' would still work.
  'mask' overwrites the unit file path with a /dev/null symlink — any attempt
  to start it (auto or manual) fails immediately with "masked".

Verification:
  systemctl status lab20c-broken.service
  # Expected: Loaded: masked (/dev/null; bad)

EOF
}

hint_step_2() {
    echo "  cat /proc/cmdline to see boot params; systemd-analyze blame to see slowest services"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Inspect kernel boot parameters and analyze boot performance

Display the kernel parameters the system was started with via /proc/cmdline.
Then use systemd-analyze to identify slow-starting services and view the
critical dependency chain for reaching the current target.

Requirements:
  • Display /proc/cmdline and identify each parameter's purpose
  • Run systemd-analyze blame (top services by startup time)
  • Run systemd-analyze critical-chain (the slowest path to current target)

Commands you might need:
  • cat /proc/cmdline
  • systemd-analyze blame
  • systemd-analyze critical-chain
  • systemd-analyze time          (total boot time summary)
EOF
}

validate_step_2() {
    # Observational — verify /proc/cmdline is readable
    if cat /proc/cmdline >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ Cannot read /proc/cmdline"
    return 1
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  cat /proc/cmdline
  systemd-analyze time
  systemd-analyze blame
  systemd-analyze critical-chain

/proc/cmdline explained:
  This virtual file shows EXACTLY what the kernel was given at boot.
  Typical RHEL output looks like:
    BOOT_IMAGE=(hd0,gpt2)/vmlinuz-5.14... root=/dev/mapper/rhel-root ro
    crashkernel=auto resume=/dev/... rhgb quiet

  • BOOT_IMAGE: path to the kernel within GRUB's filesystem view
  • root=: device containing the root filesystem
  • ro: mount root read-only initially (systemd will remount rw)
  • rhgb: Red Hat Graphical Boot (Plymouth splash screen)
  • quiet: suppress most kernel log messages during boot

systemd-analyze blame:
  Lists services sorted by how long they took to initialize. Useful for
  identifying services slowing down boot time.

systemd-analyze critical-chain:
  Shows the single longest dependency chain — the path that determines the
  minimum possible boot time. Services in this chain are candidates for
  optimization.

Verification:
  cat /proc/cmdline
  # You should see the parameters listed above

EOF
}

hint_step_3() {
    echo "  This step is conceptual — read the solution with --solution for the full rd.break procedure"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: [CONCEPTUAL] Root password reset using rd.break

This step covers the procedure for interrupting boot at the GRUB2 menu to
reset the root password. This IS on the RHCSA exam. You should be able to
perform this from memory.

The scenario: you have a RHEL system where the root password is unknown.
You have physical access (or console access). Walk through the procedure:

  1. How do you access the GRUB2 boot menu?
  2. What key do you press to edit the boot entry?
  3. What parameter do you add to the kernel line, and where?
  4. What do you do once you're in the rd.break initramfs shell?
  5. Why must you relabel the SELinux filesystem before rebooting?

Write out the steps (or just run --solution to study the answer).

NOTE: This cannot be validated automatically in a running system.
The validator will pass this step to allow you to proceed.
EOF
}

validate_step_3() {
    # This step is conceptual — auto-pass but print a reminder
    echo ""
    print_color "$YELLOW" "  ℹ Step 3 is conceptual. Review the --solution output to study the rd.break procedure."
    echo "  Marking as passed — make sure you can perform this from memory before the exam."
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION: rd.break Root Password Reset (Full Procedure)
─────────────────────────────────────────────────────────────────

WHEN YOU'D USE THIS:
  Root password unknown, system is otherwise functional, you have console access.

STEP-BY-STEP:

1. INTERRUPT GRUB2:
   Reboot the system. When the GRUB2 menu appears, press [Esc] or hold
   [Shift] (on some systems) to prevent autoboot. If it boots too fast,
   reset mid-boot to force GRUB2 to display the menu.

2. EDIT THE BOOT ENTRY:
   Select the kernel entry and press [e] to edit.

3. ADD rd.break TO THE KERNEL LINE:
   Find the line starting with 'linux' (or 'linuxefi' on UEFI).
   Navigate to the END of that line.
   Append:  rd.break
   The line will look like:
     linux /vmlinuz-... root=... ro rhgb quiet rd.break

   You may also want to add: enforcing=0
   (disables SELinux enforcement — simplifies the process but less secure)

4. BOOT THE EDITED ENTRY:
   Press Ctrl+X (or F10) to boot with the modified parameters.
   The system will stop in the initramfs (rd.break) shell — a minimal
   environment BEFORE the real root filesystem is mounted read-write.

5. REMOUNT ROOT READ-WRITE:
   mount -o remount,rw /sysroot

6. CHROOT INTO THE REAL ROOT:
   chroot /sysroot

7. CHANGE THE ROOT PASSWORD:
   passwd root
   (enter new password twice)

8. TRIGGER SELINUX RELABEL ON NEXT BOOT:
   touch /.autorelabel
   This is CRITICAL. The passwd command modifies /etc/shadow. Without
   relabeling, SELinux will deny access to the file because its security
   context is now wrong (it was modified outside the normal SELinux context).

9. EXIT AND REBOOT:
   exit        # exits the chroot
   exit        # exits the initramfs shell
   # System will reboot, run SELinux relabel (takes a few minutes), then boot normally

WHY /.autorelabel?
   SELinux assigns security labels (contexts) to every file. When you modify
   /etc/shadow from outside the running system, the label may be wrong.
   /.autorelabel tells the init system to run 'restorecon -r /' on the next
   boot to fix all file contexts. Without this, SELinux will block logins
   even with the correct password.

ALTERNATIVE — enforcing=0 approach:
   If you add 'enforcing=0' to the kernel line AND use rd.break, you don't
   need /.autorelabel because SELinux is not enforcing. However, this is
   less clean and not preferred for exam conditions unless relabeling fails.

FULL COMMAND SEQUENCE (in the rd.break shell):
─────────────────────────────────────────────
  mount -o remount,rw /sysroot
  chroot /sysroot
  passwd root
  touch /.autorelabel
  exit
  exit

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=2

    echo "Checking your configuration..."
    echo ""

    print_color "$CYAN" "[1/$total] Checking lab20c-broken.service is masked..."
    local link_target
    link_target=$(readlink /etc/systemd/system/lab20c-broken.service 2>/dev/null)
    if [ "$link_target" = "/dev/null" ]; then
        print_color "$GREEN" "  ✓ lab20c-broken.service is masked (→ /dev/null)"
        ((score++))
    else
        print_color "$RED" "  ✗ Service is not masked (link: '$link_target')"
        print_color "$YELLOW" "  Fix: systemctl mask lab20c-broken.service"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking /proc/cmdline is readable (boot param inspection)..."
    if cat /proc/cmdline >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ /proc/cmdline accessible"
        echo "  Current boot parameters: $(cat /proc/cmdline)"
        ((score++))
    else
        print_color "$RED" "  ✗ Cannot read /proc/cmdline"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Hands-on objectives complete! Make sure you also study the rd.break"
        echo "procedure in --solution — it is a guaranteed RHCSA exam topic."
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

STEP 1: Diagnose and mask the failing service
─────────────────────────────────────────────────────────────────
  systemctl --failed
  systemctl status lab20c-broken.service
  journalctl -u lab20c-broken.service --no-pager
  systemctl mask lab20c-broken.service

  After masking:
  ls -la /etc/systemd/system/lab20c-broken.service
  # /etc/systemd/system/lab20c-broken.service -> /dev/null


STEP 2: Inspect boot parameters and analyze boot
─────────────────────────────────────────────────────────────────
  cat /proc/cmdline
  systemd-analyze time
  systemd-analyze blame
  systemd-analyze critical-chain


STEP 3: rd.break Root Password Reset
─────────────────────────────────────────────────────────────────
[At GRUB2 menu - press e to edit]
  Append 'rd.break' to the end of the 'linux' line
  Press Ctrl+X to boot

[In the rd.break initramfs shell]
  mount -o remount,rw /sysroot
  chroot /sysroot
  passwd root
  touch /.autorelabel
  exit
  exit


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mask vs Disable:
  disable: removes the .wants/ symlink; service won't autostart but CAN be started manually
  mask:    replaces the unit path with /dev/null symlink; NOTHING can start it

rd.break — What it actually does:
  rd.break is a dracut (initramfs generator) hook that causes the initramfs
  to drop to a shell before switching to the real root. At this point:
  - /sysroot contains the real root filesystem, mounted read-only
  - SELinux is active but the real system's policy isn't fully loaded
  - systemd has not yet started (PID 1 is still the initramfs shell)
  This is why you need: mount -o remount,rw /sysroot (to write the new password)
  and chroot /sysroot (to run passwd against the real /etc/shadow)

/proc/cmdline vs GRUB2:
  /proc/cmdline is a kernel interface — it shows exactly what the kernel
  received at boot time. It persists for the life of the running kernel.
  It is NOT a file you edit; it's a read-only window into boot state.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Forgetting touch /.autorelabel after rd.break passwd change
  Result: SELinux denies login even with correct new password
  Fix: Reboot into rd.break again, chroot, touch /.autorelabel, reboot

Mistake 2: Forgetting to remount /sysroot rw before chroot
  Result: passwd fails with "Authentication token manipulation error"
  Fix: mount -o remount,rw /sysroot BEFORE chroot

Mistake 3: Disabling instead of masking a problem service
  Result: Service can still be started manually, or another unit starts it
  Fix: Use 'mask' for services that should never run under any circumstances


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. rd.break + passwd + touch /.autorelabel is a near-certain RHCSA exam task
2. Know the FULL sequence: rd.break → remount → chroot → passwd → autorelabel → exit × 2
3. Use 'systemctl --failed' immediately when troubleshooting any boot issue
4. journalctl -xb shows logs from the current boot with explanatory text (-x flag)
5. Mask > disable when a service must never run; disable for normal deactivation

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    systemctl unmask lab20c-broken.service 2>/dev/null || true
    systemctl disable lab20c-broken.service 2>/dev/null || true
    rm -f /etc/systemd/system/lab20c-broken.service 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
    rm -f /tmp/lab20c-original-default.txt 2>/dev/null || true

    echo "  ✓ lab20c-broken.service removed"
    echo "  ✓ systemd daemon reloaded"
}

main "$@"
