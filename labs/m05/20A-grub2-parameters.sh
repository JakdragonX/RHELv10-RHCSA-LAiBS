#!/bin/bash
# labs/20A-grub2-parameters.sh
# Lab: GRUB2 Runtime and Persistent Parameters
# Difficulty: Intermediate
# RHCSA Objective: Interrupt the boot process to gain access to a system; modify the system bootloader

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="GRUB2 Runtime and Persistent Parameters"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="15-20 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Backup grub defaults if not already backed up
    if [ ! -f /etc/default/grub.lab-backup ]; then
        cp /etc/default/grub /etc/default/grub.lab-backup 2>/dev/null || true
    fi

    # Remove any previous lab-added kernel args from /etc/default/grub
    sed -i 's/ quiet_lab_test//' /etc/default/grub 2>/dev/null || true

    echo "  ✓ Original /etc/default/grub backed up to /etc/default/grub.lab-backup"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • What a bootloader is and why it exists (BIOS/UEFI → GRUB2 → kernel → init)
  • The difference between runtime (temporary) and persistent (permanent) changes
  • Basic familiarity with /etc/default/grub file structure

Commands You'll Use:
  • grub2-mkconfig   - Regenerates /boot/grub2/grub.cfg from configuration sources
  • grep             - Searches file contents
  • cat              - Displays file contents
  • diff             - Compares two files

Files You'll Interact With:
  • /etc/default/grub              - Primary user-editable GRUB2 configuration
  • /boot/grub2/grub.cfg           - The ACTUAL config GRUB2 reads at boot (auto-generated)
  • /boot/loader/entries/          - BLS (Boot Loader Specification) drop-in config files (RHEL 9.2+)

NOTE ON RHEL 9.2+ BLS CONFIG:
  Since RHEL 9.2, GRUB_ENABLE_BLSCFG=true is set by default in /etc/default/grub.
  This means per-kernel boot options live in /boot/loader/entries/*.conf, NOT in
  /etc/default/grub directly. grub2-mkconfig still reads /etc/default/grub for
  global settings (timeout, menu style) but defers kernel cmdline to BLS entries.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A junior admin accidentally removed the 'quiet' kernel parameter from the production
server's GRUB configuration, causing the console to flood with boot messages. Your task
is to inspect the current GRUB configuration, understand the relationship between
/etc/default/grub and /boot/grub2/grub.cfg, add a custom kernel parameter persistently,
and regenerate the bootloader config correctly.

BACKGROUND:
On RHEL 9+, the Boot Loader Specification (BLS) changes where per-kernel cmdline options
are stored. You need to understand both /etc/default/grub (global config) and
/boot/loader/entries/ (per-kernel config) to make correct persistent changes.

OBJECTIVES:
  1. Display the current contents of /etc/default/grub and identify the GRUB_CMDLINE_LINUX
     line. Note what kernel parameters are currently set.

  2. Identify the active BLS entry file in /boot/loader/entries/ for the currently
     running kernel. Display its contents and note the 'options' line.

  3. Add the kernel parameter 'quiet_lab_test' to GRUB_CMDLINE_LINUX in /etc/default/grub,
     then regenerate /boot/grub2/grub.cfg using grub2-mkconfig.
     Verify the parameter appears in the regenerated grub.cfg.

HINTS:
  • Use 'uname -r' to find your current kernel version for locating the BLS entry
  • grep is your friend: grep CMDLINE /etc/default/grub
  • The BLS entry filename usually contains the kernel version string
  • grub2-mkconfig requires root and the -o flag to specify output file

SUCCESS CRITERIA:
  • You can explain the difference between /etc/default/grub and /boot/grub2/grub.cfg
  • The string 'quiet_lab_test' appears in /etc/default/grub on GRUB_CMDLINE_LINUX
  • The string 'quiet_lab_test' appears in /boot/grub2/grub.cfg after regeneration
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Display /etc/default/grub and identify GRUB_CMDLINE_LINUX
  ☐ 2. Locate and display the BLS entry for the running kernel in /boot/loader/entries/
  ☐ 3. Add 'quiet_lab_test' to GRUB_CMDLINE_LINUX and regenerate grub.cfg
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
A junior admin has disrupted boot verbosity settings on a production server.
You need to inspect the GRUB2 configuration structure and make a persistent
kernel parameter change through the correct workflow.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Inspect the GRUB2 default configuration file

Display the contents of /etc/default/grub. Identify and note the value
of the GRUB_CMDLINE_LINUX variable — this is where persistent kernel
parameters for ALL kernels are defined globally.

Requirements:
  • Display the file (cat or grep)
  • Locate the GRUB_CMDLINE_LINUX line specifically

Commands you might need:
  • cat /etc/default/grub
  • grep CMDLINE /etc/default/grub
EOF
}

validate_step_1() {
    # Step 1 is observational — we verify the file is readable and CMDLINE exists
    if grep -q "GRUB_CMDLINE_LINUX" /etc/default/grub 2>/dev/null; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ /etc/default/grub does not contain GRUB_CMDLINE_LINUX — file may be missing or malformed"
    return 1
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  cat /etc/default/grub
  # or more targeted:
  grep GRUB_CMDLINE_LINUX /etc/default/grub

Explanation:
  • /etc/default/grub is the human-editable source file for GRUB2 global settings
  • GRUB_CMDLINE_LINUX: parameters passed to the kernel for ALL boot entries
  • GRUB_CMDLINE_LINUX_DEFAULT: parameters passed only for the default (non-recovery) entry
  • This file is NOT read directly by GRUB2 at boot — it's a source for grub2-mkconfig

Why this matters:
  Editing /etc/default/grub without running grub2-mkconfig has ZERO effect at boot.
  The actual file GRUB2 reads is /boot/grub2/grub.cfg, which is auto-generated.

Verification:
  grep GRUB_CMDLINE_LINUX /etc/default/grub
  # Should show something like: GRUB_CMDLINE_LINUX="crashkernel=auto resume=... rhgb quiet"

EOF
}

hint_step_2() {
    echo "  Use 'uname -r' to get your kernel version, then look for a matching filename in /boot/loader/entries/"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Locate and inspect the BLS configuration entry for the running kernel

Since RHEL 9.2, GRUB_ENABLE_BLSCFG=true causes per-kernel boot options to be
stored in /boot/loader/entries/ as individual .conf files (Boot Loader Specification).

Requirements:
  • Find the .conf file in /boot/loader/entries/ matching your running kernel
  • Display the file and locate the 'options' line
  • Note how this relates to what you saw in /etc/default/grub

Commands you might need:
  • uname -r                        - Shows running kernel version
  • ls /boot/loader/entries/        - Lists BLS entry files
  • cat /boot/loader/entries/<file> - Display entry contents
EOF
}

validate_step_2() {
    # Check that BLS entries directory exists and has at least one entry
    if ls /boot/loader/entries/*.conf >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ No BLS entries found in /boot/loader/entries/ — this may not be a RHEL 9.2+ system"
    echo "  Check: ls /boot/loader/entries/"
    return 1
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  uname -r
  ls /boot/loader/entries/
  cat /boot/loader/entries/$(ls /boot/loader/entries/ | grep $(uname -r) | head -1)

Explanation:
  • uname -r: prints the running kernel release string (e.g., 5.14.0-427.el9.x86_64)
  • BLS entry files are named like: <machine-id>-<kernel-version>.conf
  • The 'options' line in the .conf is what gets written into grub.cfg for that kernel
  • It typically inherits from GRUB_CMDLINE_LINUX at mkconfig time, but can be edited directly

Why this matters:
  BLS separates per-kernel boot options from global GRUB settings. This makes it safer
  to update kernels without overwriting custom boot parameters.

Verification:
  grep "^options" /boot/loader/entries/*.conf
  # Expected: options root=... ro crashkernel=auto rhgb quiet <any custom params>

EOF
}

hint_step_3() {
    echo "  Edit /etc/default/grub with vi or sed, then run: grub2-mkconfig -o /boot/grub2/grub.cfg"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Add a persistent kernel parameter and regenerate GRUB2 configuration

Add the parameter 'quiet_lab_test' to the GRUB_CMDLINE_LINUX line in
/etc/default/grub, then regenerate the GRUB2 configuration file so the
change takes effect on next boot.

Requirements:
  • Modify GRUB_CMDLINE_LINUX in /etc/default/grub to include 'quiet_lab_test'
  • Run grub2-mkconfig to write the new config to /boot/grub2/grub.cfg
  • Verify the parameter appears in the generated grub.cfg

Commands you might need:
  • vi /etc/default/grub               - Edit the file
  • grub2-mkconfig -o /boot/grub2/grub.cfg  - Regenerate config
  • grep quiet_lab_test /boot/grub2/grub.cfg - Verify the change
EOF
}

validate_step_3() {
    # Check /etc/default/grub has the parameter
    if ! grep -q "quiet_lab_test" /etc/default/grub 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ 'quiet_lab_test' not found in /etc/default/grub"
        echo "  Edit GRUB_CMDLINE_LINUX in /etc/default/grub to include it"
        return 1
    fi

    # Check /boot/grub2/grub.cfg has the parameter (meaning mkconfig was run)
    if ! grep -q "quiet_lab_test" /boot/grub2/grub.cfg 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ 'quiet_lab_test' not found in /boot/grub2/grub.cfg"
        print_color "$YELLOW" "  Did you run: grub2-mkconfig -o /boot/grub2/grub.cfg ?"
        return 1
    fi

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  # Edit the file — find the GRUB_CMDLINE_LINUX line and append the parameter inside the quotes
  vi /etc/default/grub
    # Change: GRUB_CMDLINE_LINUX="... quiet"
    # To:     GRUB_CMDLINE_LINUX="... quiet quiet_lab_test"

  # Regenerate the GRUB2 config
  grub2-mkconfig -o /boot/grub2/grub.cfg

  # Verify
  grep quiet_lab_test /boot/grub2/grub.cfg

Explanation:
  • vi /etc/default/grub: edits the source configuration
  • grub2-mkconfig: reads /etc/default/grub + BLS entries + other sources and
    writes a unified /boot/grub2/grub.cfg that GRUB2 actually parses at boot
  • -o /boot/grub2/grub.cfg: specifies the output file (UEFI systems may use
    /boot/efi/EFI/redhat/grub.cfg — check with 'ls /boot/efi' if unsure)

Why this matters:
  Forgetting to run grub2-mkconfig is the #1 mistake on the RHCSA exam for this topic.
  The change in /etc/default/grub does NOTHING until mkconfig is run.

Verification:
  grep quiet_lab_test /boot/grub2/grub.cfg
  # Should appear on a 'linux' line within a menuentry block

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

    print_color "$CYAN" "[1/$total] Checking /etc/default/grub for 'quiet_lab_test'..."
    if grep -q "quiet_lab_test" /etc/default/grub 2>/dev/null; then
        print_color "$GREEN" "  ✓ Parameter found in /etc/default/grub"
        ((score++))
    else
        print_color "$RED" "  ✗ 'quiet_lab_test' not in /etc/default/grub"
        print_color "$YELLOW" "  Fix: Edit GRUB_CMDLINE_LINUX in /etc/default/grub to include 'quiet_lab_test'"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking /boot/grub2/grub.cfg for 'quiet_lab_test' (mkconfig was run)..."
    if grep -q "quiet_lab_test" /boot/grub2/grub.cfg 2>/dev/null; then
        print_color "$GREEN" "  ✓ Parameter found in /boot/grub2/grub.cfg"
        ((score++))
    else
        print_color "$RED" "  ✗ 'quiet_lab_test' not in /boot/grub2/grub.cfg"
        print_color "$YELLOW" "  Fix: grub2-mkconfig -o /boot/grub2/grub.cfg"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You understand the GRUB2 config pipeline."
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

STEP 1: Inspect /etc/default/grub
─────────────────────────────────────────────────────────────────
Command:
  cat /etc/default/grub

Key line to find:
  GRUB_CMDLINE_LINUX="crashkernel=auto resume=/dev/... rhgb quiet"

This file is the source of truth for global GRUB2 settings, but it is
NOT read directly by GRUB2 — it feeds into grub2-mkconfig.


STEP 2: Find the BLS Entry for Your Kernel
─────────────────────────────────────────────────────────────────
Commands:
  uname -r
  ls /boot/loader/entries/
  cat /boot/loader/entries/<matching-file>.conf

The 'options' line here is the per-kernel cmdline. Since GRUB_ENABLE_BLSCFG=true,
grub2-mkconfig merges global GRUB_CMDLINE_LINUX values into these BLS entries
when generating grub.cfg.


STEP 3: Add the Kernel Parameter and Regenerate
─────────────────────────────────────────────────────────────────
Commands:
  vi /etc/default/grub
    # Append 'quiet_lab_test' inside the GRUB_CMDLINE_LINUX quotes

  grub2-mkconfig -o /boot/grub2/grub.cfg

  grep quiet_lab_test /boot/grub2/grub.cfg


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The GRUB2 Config Pipeline:
  /etc/default/grub  ──┐
  /boot/loader/entries/ ──┤─→  grub2-mkconfig  →  /boot/grub2/grub.cfg  →  GRUB2 reads this at boot
  /etc/grub.d/ scripts ──┘

  Never hand-edit /boot/grub2/grub.cfg — it will be overwritten by the next
  kernel update or grub2-mkconfig run.

GRUB_ENABLE_BLSCFG=true (RHEL 9.2+):
  Kernel-specific cmdline now lives in /boot/loader/entries/*.conf.
  You can edit the BLS entry directly for a one-kernel change, or edit
  /etc/default/grub for a change that applies to all kernels going forward.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Editing /etc/default/grub but not running grub2-mkconfig
  Result: Changes have no effect at next boot
  Fix: Always follow edits with: grub2-mkconfig -o /boot/grub2/grub.cfg

Mistake 2: Hand-editing /boot/grub2/grub.cfg directly
  Result: Changes work once but get overwritten on next kernel update
  Fix: Always edit source files (/etc/default/grub or BLS entries)

Mistake 3: Wrong output path for UEFI systems
  Result: grub2-mkconfig writes to wrong location
  Fix: Check 'ls /boot/efi/EFI/redhat/' — UEFI systems may need:
       grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Always run grub2-mkconfig after editing /etc/default/grub — this is tested
2. Know both paths: /boot/grub2/grub.cfg (BIOS) and /boot/efi/EFI/redhat/grub.cfg (UEFI)
3. Runtime (temporary) changes: press 'e' at GRUB menu, edit 'linux' line, Ctrl+X to boot
4. Persistent changes: /etc/default/grub → grub2-mkconfig → grub.cfg

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    # Restore original grub defaults
    if [ -f /etc/default/grub.lab-backup ]; then
        cp /etc/default/grub.lab-backup /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
        rm -f /etc/default/grub.lab-backup
        echo "  ✓ /etc/default/grub restored from backup"
        echo "  ✓ grub.cfg regenerated"
    else
        # Remove the lab param if backup not found
        sed -i 's/ quiet_lab_test//' /etc/default/grub 2>/dev/null || true
        grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
        echo "  ✓ Removed quiet_lab_test from /etc/default/grub"
    fi
}

main "$@"
