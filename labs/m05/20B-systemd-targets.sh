#!/bin/bash
# labs/20B-systemd-targets.sh
# Lab: Managing Systemd Targets
# Difficulty: Beginner
# RHCSA Objective: Boot systems into different targets manually; set the default boot target

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Managing Systemd Targets"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="10-15 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Record the current default target so we can restore it
    systemctl get-default > /tmp/lab20b-original-default.txt 2>/dev/null || true

    echo "  ✓ Current default target saved to /tmp/lab20b-original-default.txt"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • What systemd is and its role as PID 1 / init system
  • The concept of a "unit" in systemd (service, socket, mount, target, etc.)
  • That targets group units together to represent a system state

Commands You'll Use:
  • systemctl get-default       - Display the current default boot target
  • systemctl set-default       - Change the default boot target persistently
  • systemctl isolate           - Switch to a different target on a running system
  • systemctl list-units        - List active units
  • systemctl list-dependencies - Show what a target pulls in

Files You'll Interact With:
  • /usr/lib/systemd/system/*.target   - Shipped target unit files (read-only)
  • /etc/systemd/system/default.target - Symlink pointing to the default target

KEY CONCEPT — What is a systemd target?
  A target (.target) is a unit type that represents a system state or milestone.
  Unlike a service, a target does NOT run a process itself — it pulls in other
  units via Wants= and Requires= dependencies. When all those dependencies are
  satisfied, the target is considered "active."

  Think of it as: "I want to be in state X. To get there, start units A, B, C."

Isolatable Targets (know these for the exam):
  emergency.target   - Minimal single-user shell, root filesystem read-only
  rescue.target      - Single-user shell, most filesystems mounted, no networking
  multi-user.target  - Full multi-user mode, networking, no GUI (server default)
  graphical.target   - Multi-user + graphical display manager
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're administering a RHEL server that was configured as a graphical workstation
but will be repurposed as a headless server. The GUI consumes unnecessary resources.
You need to reconfigure the default boot target and understand how to switch between
targets without rebooting.

BACKGROUND:
On this system, systemd controls which services start at boot by pulling them into
the active target. Changing the default target changes what gets started automatically.

OBJECTIVES:
  1. Display the current default systemd target. Then display the full dependency
     tree of multi-user.target to understand what units it pulls in.
     Command: systemctl list-dependencies multi-user.target

  2. Change the default boot target to multi-user.target (simulating removing
     the GUI from a server's default boot).
     Verify the change was applied by running get-default again.
     Also verify the symlink: ls -la /etc/systemd/system/default.target

  3. Inspect the rescue.target unit file to understand what makes it different
     from multi-user.target, specifically what ConditionPathExists and
     AllowIsolate directives do.
     Command: systemctl cat rescue.target

HINTS:
  • systemctl set-default creates a symlink at /etc/systemd/system/default.target
  • 'isolate' immediately switches the running system to a target — use carefully
  • rescue.target and emergency.target both have AllowIsolate=yes
  • All four main targets are isolatable; most other targets are not

SUCCESS CRITERIA:
  • systemctl get-default returns 'multi-user.target'
  • /etc/systemd/system/default.target symlinks to multi-user.target
  • You can describe the difference between rescue and emergency targets
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Display current default target and multi-user.target dependency tree
  ☐ 2. Set default target to multi-user.target, verify symlink
  ☐ 3. Inspect rescue.target unit file with 'systemctl cat'
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
A RHEL graphical workstation is being repurposed as a headless server.
You need to change its default boot target and understand the systemd
target hierarchy.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Inspect the current default target and the multi-user.target dependency tree

First find out what target this system boots into by default, then explore
what multi-user.target actually pulls in when it activates.

Requirements:
  • Show the current default target
  • Show the dependency tree of multi-user.target (look for --all flag for full tree)

Commands you might need:
  • systemctl get-default
  • systemctl list-dependencies multi-user.target
  • systemctl list-dependencies --all multi-user.target
EOF
}

validate_step_1() {
    # Observational step — verify systemctl is functional
    if systemctl get-default >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ systemctl is not responding — is systemd running?"
    return 1
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  systemctl get-default
  systemctl list-dependencies multi-user.target

Explanation:
  • systemctl get-default: reads the symlink at /etc/systemd/system/default.target
    and reports its target name
  • list-dependencies: shows the unit dependency tree. Units with ● are active.
  • --all: expands all levels of the tree (can be large)

Why this matters:
  Understanding that multi-user.target pulls in networking, login services,
  and other core daemons explains why switching to it from graphical.target
  still gives you a fully functional server — just without the display manager.

Verification:
  systemctl get-default
  # Returns: graphical.target (or whatever is currently set)

EOF
}

hint_step_2() {
    echo "  Use: systemctl set-default multi-user.target — then verify with get-default and ls -la"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Change the default boot target to multi-user.target

Set multi-user.target as the new default boot target. This change is persistent
across reboots. Do NOT use 'isolate' here — that would immediately drop you to
that target and disconnect active sessions if this were graphical.

Requirements:
  • Change default to multi-user.target using the correct systemctl subcommand
  • Verify with systemctl get-default
  • Inspect the symlink at /etc/systemd/system/default.target to understand
    how the default target is stored on disk

Commands you might need:
  • systemctl set-default multi-user.target
  • systemctl get-default
  • ls -la /etc/systemd/system/default.target
EOF
}

validate_step_2() {
    local current_default
    current_default=$(systemctl get-default 2>/dev/null)

    if [ "$current_default" != "multi-user.target" ]; then
        echo ""
        print_color "$RED" "✗ Default target is '$current_default' (expected 'multi-user.target')"
        echo "  Fix: systemctl set-default multi-user.target"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  systemctl set-default multi-user.target
  systemctl get-default
  ls -la /etc/systemd/system/default.target

Explanation:
  • set-default: creates/updates a symlink at /etc/systemd/system/default.target
    pointing to /usr/lib/systemd/system/multi-user.target
  • This symlink is what systemd reads at early boot to know the target state to reach
  • get-default: resolves the symlink and prints the target name
  • ls -la: you'll see something like:
      /etc/systemd/system/default.target -> /usr/lib/systemd/system/multi-user.target

Why this matters:
  The default target is just a symlink. That's it. systemctl set-default is simply
  a convenient wrapper around ln -sf. Knowing this helps you understand the file
  system layout and troubleshoot boot issues.

Verification:
  systemctl get-default
  # Expected: multi-user.target

EOF
}

hint_step_3() {
    echo "  Use: systemctl cat rescue.target — look for AllowIsolate= and the Wants= / Requires= lines"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Inspect the rescue.target unit file

Use 'systemctl cat' to display the full contents of rescue.target.
Identify what makes rescue.target different from multi-user.target:
  • What does AllowIsolate=yes do?
  • What does rescue.target Require/Want that multi-user.target does not?
  • Why is rescue.target used instead of emergency.target when you need
    a single-user shell with filesystems mounted?

Requirements:
  • Display the rescue.target unit file
  • Be able to explain AllowIsolate and the dependency differences

Commands you might need:
  • systemctl cat rescue.target
  • systemctl cat emergency.target   (for comparison)
  • systemctl cat multi-user.target
EOF
}

validate_step_3() {
    # Observational — verify the file is accessible
    if systemctl cat rescue.target >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ Could not read rescue.target — systemd may not be running correctly"
    return 1
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  systemctl cat rescue.target
  systemctl cat emergency.target

Key things you'll find in rescue.target:
  Description=Rescue Mode
  Documentation=man:systemd.special(7)
  Requires=sysinit.target rescue.service
  After=sysinit.target rescue.service
  AllowIsolate=yes

Explanation:
  • AllowIsolate=yes: this is what makes a target "isolatable" — it means you
    can use 'systemctl isolate rescue.target' to switch to it on a running system.
    Without this, isolate would be refused.
  • Requires=sysinit.target: rescue pulls in early system init (mounts, udev, etc.)
    This is why rescue.target has filesystems mounted, unlike emergency.target.
  • rescue.service: starts a special single-user login shell as root

Rescue vs Emergency:
  rescue.target    → sysinit.target runs → filesystems mounted → single-user shell
  emergency.target → almost nothing runs → root filesystem read-only → minimal shell
  Use rescue when: normal boot fails but you need filesystems accessible
  Use emergency when: even rescue fails, or you suspect filesystem corruption

Verification:
  systemctl show rescue.target | grep AllowIsolate
  # Expected: AllowIsolate=yes

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

    print_color "$CYAN" "[1/$total] Checking default target is multi-user.target..."
    local current_default
    current_default=$(systemctl get-default 2>/dev/null)
    if [ "$current_default" = "multi-user.target" ]; then
        print_color "$GREEN" "  ✓ Default target is multi-user.target"
        ((score++))
    else
        print_color "$RED" "  ✗ Default target is '$current_default' (expected 'multi-user.target')"
        print_color "$YELLOW" "  Fix: systemctl set-default multi-user.target"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking /etc/systemd/system/default.target symlink..."
    local symlink_target
    symlink_target=$(readlink /etc/systemd/system/default.target 2>/dev/null)
    if echo "$symlink_target" | grep -q "multi-user.target"; then
        print_color "$GREEN" "  ✓ Symlink correctly points to multi-user.target"
        ((score++))
    else
        print_color "$RED" "  ✗ Symlink points to: '$symlink_target'"
        print_color "$YELLOW" "  Fix: systemctl set-default multi-user.target"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Well done! You've correctly configured the default systemd target."
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

STEP 1: Inspect the current target and dependency tree
─────────────────────────────────────────────────────────────────
  systemctl get-default
  systemctl list-dependencies multi-user.target

  The dependency tree reveals everything multi-user.target depends on:
  networking, login services, audit daemons, etc.


STEP 2: Set default to multi-user.target
─────────────────────────────────────────────────────────────────
  systemctl set-default multi-user.target
  systemctl get-default
  ls -la /etc/systemd/system/default.target

  Under the hood, set-default runs:
    ln -sf /usr/lib/systemd/system/multi-user.target \
           /etc/systemd/system/default.target


STEP 3: Inspect rescue.target
─────────────────────────────────────────────────────────────────
  systemctl cat rescue.target


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Targets vs Services:
  A .service unit starts a process. A .target unit groups other units.
  When systemd boots, it activates the default target, which pulls in
  its dependencies (other targets and services), which pull in theirs,
  and so on — building the complete running system state.

The Four Isolatable Targets:
  emergency.target   Root FS read-only, almost nothing started
  rescue.target      Filesystems mounted, single-user shell
  multi-user.target  Full server mode, networking, no GUI
  graphical.target   multi-user + display manager

  "Isolatable" means AllowIsolate=yes in the unit file, which permits
  'systemctl isolate <target>' to immediately switch the running system.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using 'systemctl start multi-user.target' to change default
  Result: Works for current session only; default remains unchanged
  Fix: Use 'systemctl set-default' for persistence, 'isolate' for immediate switch

Mistake 2: Isolating to rescue.target accidentally on a live server
  Result: All non-essential services stop, users lose access
  Fix: Use 'isolate' only in maintenance windows or on local console

Mistake 3: Confusing rescue and emergency
  Result: Choosing wrong target during troubleshooting
  Fix: rescue = filesystems mounted; emergency = last resort, FS read-only


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Know all four systemctl subcommands: get-default, set-default, isolate, cat
2. The default.target symlink at /etc/systemd/system/ is the persistence mechanism
3. On the exam: set-default for "make this survive reboot", isolate for "switch now"
4. Boot into rescue/emergency from GRUB: append systemd.unit=rescue.target to kernel line

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    if [ -f /tmp/lab20b-original-default.txt ]; then
        original=$(cat /tmp/lab20b-original-default.txt)
        systemctl set-default "$original" 2>/dev/null || true
        rm -f /tmp/lab20b-original-default.txt
        echo "  ✓ Default target restored to: $original"
    else
        echo "  ✓ No backup found; skipping restore"
    fi
}

main "$@"
