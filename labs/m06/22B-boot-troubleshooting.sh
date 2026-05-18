#!/bin/bash
# labs/22B-boot-troubleshooting.sh
# Lab: Boot Troubleshooting — debug-shell.service and Root Password Recovery
# Difficulty: Advanced
# RHCSA Objective: Interrupt the boot process to gain access to a system; use troubleshooting modes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Boot Troubleshooting — debug-shell and Root Password Recovery"
LAB_DIFFICULTY="Advanced"
LAB_TIME_ESTIMATE="20-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Ensure debug-shell is not already enabled from a previous run
    systemctl disable debug-shell.service 2>/dev/null || true
    systemctl stop debug-shell.service 2>/dev/null || true

    # Create a lab user whose password we will "lose" (locked account)
    userdel -r labrecovery 2>/dev/null || true
    useradd -m -s /bin/bash labrecovery
    # Lock the account to simulate a lost password
    passwd -l labrecovery >/dev/null 2>&1

    echo "  ✓ debug-shell.service is disabled (clean starting state)"
    echo "  ✓ Created locked user 'labrecovery' (simulates lost password)"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Lab 20C (rd.break procedure) — this lab extends that knowledge
  • The difference between init=/bin/bash and rd.break as recovery methods
  • What TTY (teletypewriter) sessions are and how to switch between them
  • That debug-shell.service opens a passwordless root shell — a security risk

Commands You'll Use:
  • systemctl enable --now   - Enable and immediately start a unit
  • systemctl disable --now  - Disable and immediately stop a unit
  • systemctl status         - Show unit state and recent journal entries
  • chvt / Ctrl+Alt+F<N>    - Switch between virtual terminals (TTYs)
  • passwd                   - Change a user's password
  • passwd -l / -u           - Lock / unlock an account

Files You'll Interact With:
  • /usr/lib/systemd/system/debug-shell.service - The debug shell unit file
  • /dev/tty9                                   - TTY9 where debug shell appears

TWO ROOT RECOVERY METHODS — know both:

  Method 1: rd.break (covered in Lab 20C)
    Add 'rd.break' to the kernel line in GRUB2.
    Drops to initramfs shell BEFORE the real root is mounted.
    Requires: mount -o remount,rw /sysroot → chroot /sysroot → passwd → /.autorelabel

  Method 2: init=/bin/bash (this lab — conceptual)
    Add 'init=/bin/bash' to the kernel line in GRUB2.
    Boots the kernel but replaces systemd with a bare bash shell as PID 1.
    Root filesystem is initially read-only — must remount: mount -o remount,rw /
    After changes: exec /usr/lib/systemd/systemd (NOT 'exit' or 'reboot')
    Why exec instead of exit: bash IS PID 1. 'exit' would cause a kernel panic
    because PID 1 must never terminate. exec REPLACES the bash process with
    systemd, making systemd PID 1 without leaving an orphaned parent.

  When to use which:
    rd.break → preferred; SELinux context is safer; initramfs provides more tools
    init=/bin/bash → simpler kernel line edit; useful when rd.break is unavailable
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A server is experiencing intermittent boot failures that are hard to diagnose
because the failure happens before a login prompt appears. You need to enable
the debug-shell service so a root shell is available on TTY9 during the next
boot for diagnostics. After diagnostics, you must disable it immediately —
a passwordless root shell is a critical security exposure.
Additionally, the 'labrecovery' user account has a locked password and needs
to be unlocked with a new password set.

BACKGROUND:
debug-shell.service is a legitimate Red Hat diagnostic tool, but it creates
a root shell accessible to anyone with physical or console access — no
password required. It must be treated like leaving a terminal logged in as
root: acceptable only under controlled conditions and immediately cleaned up.

OBJECTIVES:
  1. Inspect the debug-shell.service unit file using systemctl cat. Note what
     TTY it runs on and what command it executes. Then enable and start it.
     Verify it is active using systemctl status.

  2. On a system with a graphical or multi-TTY environment, you would switch
     to TTY9 (Ctrl+Alt+F9) to access the shell. Since this is a server/VM,
     use systemctl status debug-shell.service to confirm the shell process
     is running. Then disable and stop the service immediately to simulate
     completing the diagnostic window.
     Verify it is inactive after stopping.

  3. The 'labrecovery' user account is locked. Unlock it and set its password
     to 'Tr0ubl3sh00t!' using passwd. Verify the account is usable by
     checking its status with passwd -S labrecovery.

HINTS:
  • systemctl cat debug-shell.service — read the unit file before enabling
  • systemctl enable --now enables AND starts in one command
  • systemctl disable --now disables AND stops in one command
  • passwd -u labrecovery unlocks; then passwd labrecovery sets a new password
  • passwd -S <user> shows account status (P=usable, L=locked, NP=no password)

SUCCESS CRITERIA:
  • debug-shell.service is currently inactive/disabled
  • 'labrecovery' account is unlocked with password set (passwd -S shows 'P')
  • You can describe both init=/bin/bash and rd.break and when to use each
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Inspect debug-shell.service with systemctl cat; enable --now and verify active
  ☐ 2. Disable --now debug-shell.service; verify it is inactive
  ☐ 3. Unlock 'labrecovery' and set password 'Tr0ubl3sh00t!'; verify with passwd -S
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
A server has intermittent early-boot failures. You need to enable the debug
shell for a diagnostic window, then immediately disable it. You also need to
recover a locked user account.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Inspect and enable debug-shell.service

Read the debug-shell unit file to understand what it does, then enable
and start it. The --now flag handles both in a single command.

Requirements:
  • Use systemctl cat to read the unit file before enabling
  • Enable AND start the service with a single systemctl command
  • Verify it is active (running) using systemctl status

Commands you might need:
  • systemctl cat debug-shell.service
  • systemctl enable --now debug-shell.service
  • systemctl status debug-shell.service
  • systemctl is-active debug-shell.service
EOF
}

validate_step_1() {
    if systemctl is-active debug-shell.service >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ debug-shell.service is not active"
    echo "  Fix: systemctl enable --now debug-shell.service"
    return 1
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  systemctl cat debug-shell.service
  systemctl enable --now debug-shell.service
  systemctl status debug-shell.service

What systemctl cat shows:
  [Unit]
  Description=Early root shell on /dev/tty9 FOR DEVELOPMENT/DEBUGGING ONLY
  ...
  [Service]
  ExecStart=-/bin/bash
  StandardInput=tty
  TTYPath=/dev/tty9
  Type=idle

Key observations from the unit file:
  • ExecStart=-/bin/bash: the '-' prefix means systemd ignores a non-zero exit
    code from this process (bash exiting is not treated as a service failure)
  • TTYPath=/dev/tty9: the shell appears on virtual terminal 9
  • Type=idle: the service waits until all other services have started before
    opening the shell — this is so boot diagnostics don't interfere with normal startup

--now flag behavior:
  'enable --now' = 'enable' (create the .wants/ symlink) + 'start' (activate now)
  'disable --now' = 'disable' (remove the .wants/ symlink) + 'stop' (deactivate now)
  Without --now: enable/disable only affects next boot; the current state is unchanged.

Verification:
  systemctl is-active debug-shell.service
  # Expected: active

EOF
}

hint_step_2() {
    echo "  Use: systemctl disable --now debug-shell.service"
    echo "  Then: systemctl is-active debug-shell.service  (should return 'inactive')"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Disable and stop debug-shell.service

After a diagnostic window, the debug shell MUST be disabled immediately.
A passwordless root shell on any TTY is a critical security exposure —
anyone with physical or remote console access can use it without credentials.

Requirements:
  • Disable AND stop the service with a single systemctl command
  • Verify it is inactive using systemctl is-active
  • Verify it is also disabled (won't start on next boot) using systemctl is-enabled

Commands you might need:
  • systemctl disable --now debug-shell.service
  • systemctl is-active debug-shell.service
  • systemctl is-enabled debug-shell.service
EOF
}

validate_step_2() {
    if systemctl is-active debug-shell.service >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ debug-shell.service is still active — it must be stopped"
        echo "  Fix: systemctl disable --now debug-shell.service"
        return 1
    fi

    if systemctl is-enabled debug-shell.service 2>/dev/null | grep -q "enabled"; then
        echo ""
        print_color "$RED" "✗ debug-shell.service is stopped but still enabled (will start on next boot)"
        echo "  Fix: systemctl disable debug-shell.service"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  systemctl disable --now debug-shell.service
  systemctl is-active debug-shell.service
  systemctl is-enabled debug-shell.service

Explanation:
  • disable --now: removes the .wants/ symlink (prevent future autostart) AND
    stops the currently running service in one atomic operation.
  • is-active: returns 'active' or 'inactive'. Used in scripts for conditional logic.
  • is-enabled: returns 'enabled', 'disabled', or 'static'. 'disabled' means
    it won't start automatically; 'static' means it has no [Install] section
    and is controlled by another unit's dependency.

Security note — when debug-shell must be used:
  1. Enable it only in a controlled maintenance window
  2. Ensure no untrusted personnel have console/IPMI access during that window
  3. Disable it immediately when done — before the next login session
  4. Check the journal afterward: journalctl -u debug-shell.service

Verification:
  systemctl is-active debug-shell.service
  # Expected: inactive
  systemctl is-enabled debug-shell.service
  # Expected: disabled

EOF
}

hint_step_3() {
    echo "  Unlock: passwd -u labrecovery"
    echo "  Set password: passwd labrecovery"
    echo "  Verify: passwd -S labrecovery  (look for 'P' status)"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Unlock the 'labrecovery' account and set a new password

The account is currently locked (passwd -l was used during setup).
Unlock it and set the password to: Tr0ubl3sh00t!

Requirements:
  • Verify the account is currently locked: passwd -S labrecovery
  • Unlock the account: passwd -u labrecovery
  • Set the password to 'Tr0ubl3sh00t!'
  • Verify the account is now usable: passwd -S labrecovery (status should be 'P')

Commands you might need:
  • passwd -S labrecovery           - Show account status
  • passwd -u labrecovery           - Unlock the account
  • passwd labrecovery              - Set a new password interactively
  • echo 'Tr0ubl3sh00t!' | passwd --stdin labrecovery  - Non-interactive alternative
EOF
}

validate_step_3() {
    # Check the account is not locked — passwd -S shows 'P' for usable
    local status
    status=$(passwd -S labrecovery 2>/dev/null | awk '{print $2}')

    if [ "$status" = "P" ]; then
        return 0
    fi

    echo ""
    if [ "$status" = "L" ]; then
        print_color "$RED" "✗ Account 'labrecovery' is still locked (status: L)"
        echo "  Fix: passwd -u labrecovery && passwd labrecovery"
    elif [ "$status" = "NP" ]; then
        print_color "$RED" "✗ Account 'labrecovery' has no password set (status: NP)"
        echo "  Fix: passwd labrecovery"
    else
        print_color "$RED" "✗ Could not determine status of 'labrecovery' account"
        echo "  Check: passwd -S labrecovery"
    fi
    return 1
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  passwd -S labrecovery
  # Shows: labrecovery L ... (L = Locked)

  passwd -u labrecovery
  # Unlocks by removing the '!' prefix from the password hash in /etc/shadow

  passwd labrecovery
  # Enter: Tr0ubl3sh00t!
  # Confirm: Tr0ubl3sh00t!

  passwd -S labrecovery
  # Should now show: labrecovery P ... (P = Password set, usable)

Explanation:
  • passwd -S <user>: shows account status. The second field is the key:
    P = password set and usable
    L = locked (! prefix in /etc/shadow password hash)
    NP = no password (empty hash field)
  • passwd -l <user>: locks by prepending '!' to the password hash in /etc/shadow.
    The hash is preserved — unlocking with -u restores it exactly.
  • passwd -u <user>: removes the '!' — the old password hash is restored.
    If you want to force a NEW password, run passwd <user> after unlocking.

Connecting this to root password recovery (init=/bin/bash):
  The same problem (locked or unknown root password) on a server without console
  access is solved by the boot recovery procedure. From a bare bash shell
  (init=/bin/bash) or chroot (rd.break), you run 'passwd root' — which works
  the same way as above, but directly on /etc/shadow with the filesystem remounted rw.

  The critical difference between the two methods:
  rd.break → you're in initramfs; root filesystem is at /sysroot; need chroot
  init=/bin/bash → you're already in the real root; just remount rw and run passwd

Verification:
  passwd -S labrecovery
  # Expected: labrecovery P <date> 0 99999 7 -1 (P = usable)

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

    print_color "$CYAN" "[1/$total] Checking debug-shell.service is inactive and disabled..."
    local is_active is_enabled
    is_active=$(systemctl is-active debug-shell.service 2>/dev/null)
    is_enabled=$(systemctl is-enabled debug-shell.service 2>/dev/null)

    if [ "$is_active" = "inactive" ] && [ "$is_enabled" = "disabled" ]; then
        print_color "$GREEN" "  ✓ debug-shell.service is inactive and disabled"
        ((score++))
    elif [ "$is_active" = "active" ]; then
        print_color "$RED" "  ✗ debug-shell.service is still active"
        print_color "$YELLOW" "  Fix: systemctl disable --now debug-shell.service"
    elif [ "$is_enabled" = "enabled" ]; then
        print_color "$RED" "  ✗ debug-shell.service is stopped but still enabled (will start at boot)"
        print_color "$YELLOW" "  Fix: systemctl disable debug-shell.service"
    else
        print_color "$GREEN" "  ✓ debug-shell.service is inactive and disabled"
        ((score++))
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking 'labrecovery' account is unlocked with password set..."
    local acct_status
    acct_status=$(passwd -S labrecovery 2>/dev/null | awk '{print $2}')

    if [ "$acct_status" = "P" ]; then
        print_color "$GREEN" "  ✓ 'labrecovery' account is usable (status: P)"
        ((score++))
    elif [ "$acct_status" = "L" ]; then
        print_color "$RED" "  ✗ 'labrecovery' account is still locked (status: L)"
        print_color "$YELLOW" "  Fix: passwd -u labrecovery && passwd labrecovery"
    else
        print_color "$RED" "  ✗ 'labrecovery' status is '$acct_status' (expected P)"
        print_color "$YELLOW" "  Fix: passwd labrecovery"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Well done! You can manage debug-shell safely and recover locked accounts."
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

STEP 1: Inspect and enable debug-shell
─────────────────────────────────────────────────────────────────
  systemctl cat debug-shell.service
  systemctl enable --now debug-shell.service
  systemctl status debug-shell.service


STEP 2: Disable and stop debug-shell
─────────────────────────────────────────────────────────────────
  systemctl disable --now debug-shell.service
  systemctl is-active debug-shell.service    # → inactive
  systemctl is-enabled debug-shell.service   # → disabled


STEP 3: Unlock labrecovery and set password
─────────────────────────────────────────────────────────────────
  passwd -S labrecovery                      # → L (locked)
  passwd -u labrecovery
  passwd labrecovery                         # enter: Tr0ubl3sh00t!
  passwd -S labrecovery                      # → P (usable)


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

init=/bin/bash vs rd.break (Full Comparison):

  rd.break:
    • Where: added to kernel 'linux' line in GRUB2 editor
    • When it fires: inside the initramfs, BEFORE switching to real root
    • Real root location: /sysroot (read-only initially)
    • Steps: mount -o remount,rw /sysroot → chroot /sysroot → passwd root
             → touch /.autorelabel → exit → exit
    • SELinux: /.autorelabel required because chroot modifies /etc/shadow
      outside the normal SELinux context

  init=/bin/bash:
    • Where: added to kernel 'linux' line in GRUB2 editor
    • When it fires: after the kernel loads the real root; bash replaces systemd as PID 1
    • Real root location: / (read-only initially)
    • Steps: mount -o remount,rw / → passwd root → touch /.autorelabel
             → exec /usr/lib/systemd/systemd
    • SELinux: /.autorelabel required for same reason
    • Critical difference: use 'exec /usr/lib/systemd/systemd' to exit, NOT
      'exit' or 'reboot'. bash IS PID 1 — if it exits, the kernel panics.
      exec REPLACES the bash process image with systemd, maintaining PID 1.

debug-shell.service Security Model:
  The service is intentionally designed with no authentication — it exists
  for emergency recovery when the normal authentication stack may be broken.
  This means: console/IPMI/iDRAC access = root access when debug-shell is active.
  On cloud VMs, ensure the cloud provider's serial console access is restricted
  before enabling this service.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using 'exit' or 'reboot' after init=/bin/bash recovery
  Result: Kernel panic (bash was PID 1; it must not exit)
  Fix: Use 'exec /usr/lib/systemd/systemd' to hand off PID 1 cleanly

Mistake 2: Leaving debug-shell.service enabled after troubleshooting
  Result: Passwordless root shell available on TTY9 at next boot
  Fix: Always use 'disable --now' immediately after the diagnostic window

Mistake 3: Forgetting touch /.autorelabel after passwd in recovery
  Result: SELinux denies login even with correct password
  Fix: Reboot into recovery again, chroot, touch /.autorelabel, exit

Mistake 4: Confusing passwd -u with passwd -d
  passwd -u: unlocks (restores hash)
  passwd -d: deletes password (sets to NP/empty — passwordless login)
  Never use -d on a production account unless passwordless login is intended


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Know BOTH recovery methods: rd.break AND init=/bin/bash
2. init=/bin/bash exit sequence: exec /usr/lib/systemd/systemd (not exit, not reboot)
3. rd.break exit sequence: exit (from chroot) → exit (from initramfs) → autoboot
4. Both require: touch /.autorelabel for SELinux context correction
5. debug-shell: enable --now to start; disable --now to clean up; always on TTY9
6. passwd -S <user>: P=usable, L=locked, NP=no password — know all three

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    systemctl disable --now debug-shell.service 2>/dev/null || true
    userdel -r labrecovery 2>/dev/null || true

    echo "  ✓ debug-shell.service disabled and stopped"
    echo "  ✓ labrecovery user removed"
}

main "$@"
