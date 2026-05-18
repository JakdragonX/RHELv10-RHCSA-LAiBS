#!/bin/bash
# labs/21C-kernel-update.sh
# Lab: Updating the Kernel and Managing Installed Kernel Versions
# Difficulty: Beginner
# RHCSA Objective: Update software packages including the kernel; manage kernel versions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Updating the Kernel and Managing Kernel Versions"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="10-15 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # This lab is primarily observational/conceptual — no system state to reset.
    # We verify that dnf and rpm are functional and /boot is accessible.

    echo "  ✓ No destructive setup required for this lab"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • What a kernel is and why you would update it (security fixes, hardware support)
  • That RHEL keeps multiple kernel versions installed simultaneously as a safety net
  • Basic familiarity with dnf package management

Commands You'll Use:
  • uname -r          - Display the currently running kernel version
  • rpm -q kernel     - List all installed kernel packages
  • dnf list kernel   - Show installed and available kernel versions
  • dnf update kernel - Install the latest available kernel (keeps old ones)
  • ls /boot/         - View kernel images and initramfs files installed on disk
  • grubby --default-kernel - Show which kernel will boot by default

Files You'll Interact With:
  • /boot/vmlinuz-*    - Kernel image files
  • /boot/initramfs-*  - Initial RAM filesystem for each kernel
  • /etc/dnf/dnf.conf  - DNF configuration including installonly_limit
  • /boot/loader/entries/*.conf - BLS entries controlling GRUB2 menu (one per kernel)

KEY CONCEPT — Why Linux keeps old kernels:
  Unlike application packages, kernels are NOT replaced on update — they are
  ADDED alongside the existing kernel. This means:
  - If the new kernel panics or has a driver regression, you boot the old one
  - GRUB2 automatically adds a menu entry for each installed kernel
  - The oldest kernel is removed only when the installonly_limit is reached
  RHEL defaults to keeping 3 kernels (installonly_limit=3 in /etc/dnf/dnf.conf)
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
Your security team has flagged that a RHEL server may be running an outdated
kernel with known CVEs. You need to check the current kernel version, identify
what is installed and available, understand how RHEL manages multiple kernel
versions, and know how to perform a kernel update safely.

BACKGROUND:
RHEL's kernel update process is deliberately conservative. Old kernels are
retained so that a bad update can be reversed simply by selecting a previous
kernel at boot — no package rollback required.

OBJECTIVES:
  1. Identify the currently running kernel version using uname. Then list all
     installed kernel packages using rpm. Compare these — are there multiple
     kernels installed? Check /boot/ to see the corresponding files on disk.

  2. Inspect /etc/dnf/dnf.conf and locate the installonly_limit setting.
     Understand what this value controls and what the recommended range is.
     Also examine /boot/loader/entries/ to see how many GRUB2 boot entries
     currently exist (one per installed kernel).

  3. Use 'dnf list kernel' to see installed vs. available kernel versions.
     Then show the command you would use to update the kernel, and explain
     what happens on the system after the update completes (without actually
     running the update — it requires a network connection and download time).
     Use grubby --default-kernel to confirm which kernel is set as the default.

HINTS:
  • rpm -q kernel lists ONLY installed kernel packages (not running)
  • uname -r shows the RUNNING kernel (may differ from the latest installed)
  • dnf update kernel and dnf install kernel both work — dnf is smart enough
    to not remove old kernels when installonly packages are involved
  • After a kernel update, a reboot is required to use the new kernel

SUCCESS CRITERIA:
  • You can state the running kernel version from uname -r
  • You can list all installed kernel versions from rpm -q kernel
  • You understand what installonly_limit controls
  • You know the dnf command to update the kernel
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Identify running kernel (uname -r), list installed kernels (rpm -q kernel), inspect /boot/
  ☐ 2. Inspect installonly_limit in /etc/dnf/dnf.conf; count BLS entries in /boot/loader/entries/
  ☐ 3. Run 'dnf list kernel'; confirm default boot kernel with grubby --default-kernel
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
Security has flagged a potentially outdated kernel. You need to assess the
current kernel state, understand RHEL's multi-kernel retention policy, and
know how to safely perform a kernel update.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Identify the running kernel and all installed kernel versions

Use uname to find the running kernel, rpm to list all installed kernels,
and inspect /boot/ to see the corresponding files on disk.

Requirements:
  • Get the running kernel version with uname -r
  • List all installed kernel RPMs with rpm -q kernel
  • List /boot/ and identify vmlinuz-* and initramfs-* files
  • Note whether the running kernel matches the newest installed kernel

Commands you might need:
  • uname -r
  • rpm -q kernel
  • ls -lh /boot/vmlinuz-*
  • ls -lh /boot/initramfs-*
EOF
}

validate_step_1() {
    # Observational — verify uname and rpm are functional
    if uname -r >/dev/null 2>&1 && rpm -q kernel >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ uname or rpm is not responding"
    return 1
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  uname -r
  rpm -q kernel
  ls -lh /boot/vmlinuz-*
  ls -lh /boot/initramfs-*

Explanation:
  • uname -r: reports the version string of the CURRENTLY RUNNING kernel.
    This is read from the kernel itself (not from any file on disk).
  • rpm -q kernel: queries the RPM database for ALL installed packages named
    'kernel'. Each installed version appears on its own line. You may see
    multiple versions if previous updates have been applied.
  • /boot/vmlinuz-<version>: the compressed kernel image for each installed
    kernel. GRUB2 loads this into memory at boot.
  • /boot/initramfs-<version>.img: the initial RAM filesystem for each kernel.
    This is a temporary root filesystem that loads the modules needed to mount
    the real root filesystem during early boot.

Key observation:
  If uname -r shows a different (older) version than the newest entry in
  rpm -q kernel, the system has a newer kernel installed but not yet booted
  into. A reboot is required to switch to the new kernel.

Verification:
  uname -r
  rpm -q kernel
  # Compare — if they differ, you have an update pending a reboot

EOF
}

hint_step_2() {
    echo "  grep installonly /etc/dnf/dnf.conf — find the retention limit"
    echo "  ls /boot/loader/entries/ — count the BLS entries"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Inspect the kernel retention policy and GRUB2 boot entries

Locate and read the installonly_limit setting in dnf.conf, which controls
how many kernel versions RHEL keeps installed. Then count the GRUB2 boot
entries in /boot/loader/entries/ — there should be one per installed kernel,
plus potentially a rescue entry.

Requirements:
  • Find installonly_limit in /etc/dnf/dnf.conf
  • Understand what happens when the limit is reached
  • Count and display the BLS entries in /boot/loader/entries/

Commands you might need:
  • grep installonly /etc/dnf/dnf.conf
  • cat /etc/dnf/dnf.conf
  • ls /boot/loader/entries/
  • cat /boot/loader/entries/<entry>.conf   (examine one entry)
EOF
}

validate_step_2() {
    # Observational — verify dnf.conf and /boot/loader/entries/ are readable
    if [ -f /etc/dnf/dnf.conf ] && ls /boot/loader/entries/*.conf >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ Cannot read /etc/dnf/dnf.conf or /boot/loader/entries/"
    return 1
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  grep installonly /etc/dnf/dnf.conf
  ls /boot/loader/entries/
  cat /boot/loader/entries/$(ls /boot/loader/entries/ | grep -v rescue | head -1)

Key findings:
  • installonly_limit=3 (RHEL default): DNF will keep the 3 most recent kernel
    versions installed. When a 4th is installed, the oldest is automatically
    removed — its RPM is uninstalled and its /boot/ files are deleted.
  • /boot/loader/entries/: one .conf file per installed kernel, named with
    the machine-id and kernel version. Each file is a BLS entry describing
    what GRUB2 should show in its menu and which kernel/initramfs to load.

installonly_limit recommendations:
  Default (3): appropriate for most servers. Provides two rollback options.
  Increase to 4-5: only if you frequently test kernels or need more rollback depth.
  Never set to 0: this disables the limit (unlimited kernels accumulate in /boot/).
  /boot is typically a small partition — running out of space there will break
  future kernel installs and can prevent boot.

Rescue entry:
  You may also see an entry named *-rescue-*.conf. This is a special boot entry
  created during OS installation with a fixed kernel snapshot for recovery purposes.
  It is NOT updated by dnf and does NOT count toward installonly_limit.

Verification:
  grep installonly /etc/dnf/dnf.conf
  # Expected: installonly_limit=3
  ls /boot/loader/entries/ | wc -l
  # Number of GRUB2 menu entries (kernels + rescue)

EOF
}

hint_step_3() {
    echo "  dnf list kernel — shows installed vs available"
    echo "  grubby --default-kernel — shows what boots next"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Check available kernel updates and identify the default boot kernel

Use dnf list to see what kernel versions are installed and what is available
in the repository. Then use grubby to confirm which kernel is set as the
default for the next boot.

IMPORTANT: Do NOT run 'dnf update kernel' unless you intend to actually update.
The goal here is to know the command and understand what it does.

Requirements:
  • Run dnf list kernel to see installed and available versions
  • Show the command used to update the kernel (for knowledge, not execution)
  • Run grubby --default-kernel to see the current default boot kernel

Commands you might need:
  • dnf list kernel
  • grubby --default-kernel
  • grubby --info=ALL   (shows info for all installed kernels)
EOF
}

validate_step_3() {
    # Check that grubby can find a default kernel — confirms BLS integration
    if grubby --default-kernel >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ grubby --default-kernel failed — grubby may not be installed"
    echo "  Install: dnf install grubby"
    return 1
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  dnf list kernel
  grubby --default-kernel
  grubby --info=ALL

Explanation:
  • dnf list kernel: shows all installed kernel versions (marked @System)
    and any newer version available in enabled repositories.
    If a newer version is listed under 'Available Packages', an update is pending.
  • The command to update the kernel is: dnf update kernel
    (dnf install kernel also works — for installonly packages, DNF adds the new
    version rather than replacing the old one)
  • After dnf update kernel completes:
      1. New kernel RPM and associated packages (kernel-core, kernel-modules) install
      2. New vmlinuz-* and initramfs-*.img appear in /boot/
      3. A new BLS entry is created in /boot/loader/entries/
      4. grub2-mkconfig is run automatically (via a DNF plugin)
      5. The new kernel becomes the default in GRUB2
      6. A REBOOT IS REQUIRED to actually run the new kernel
  • grubby --default-kernel: prints the full path to the kernel image that
    GRUB2 will boot by default on the next restart.
  • grubby --info=ALL: shows details for every installed kernel including
    the kernel path, initramfs path, and boot arguments.

Why 'dnf update' instead of 'dnf upgrade':
  Both work. 'upgrade' is an alias for 'update' in modern DNF. The distinction
  (upgrade removes obsoletes, update does not) was a legacy yum behavior;
  DNF treats them identically by default.

Verification:
  grubby --default-kernel
  # Expected: /boot/vmlinuz-<newest-installed-version>

  rpm -q kernel
  # All installed kernel versions

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

    print_color "$CYAN" "[1/$total] Verifying uname -r and rpm -q kernel are functional..."
    local running_kernel
    running_kernel=$(uname -r 2>/dev/null)
    local installed_kernels
    installed_kernels=$(rpm -q kernel 2>/dev/null | wc -l)
    if [ -n "$running_kernel" ] && [ "$installed_kernels" -gt 0 ]; then
        print_color "$GREEN" "  ✓ Running kernel: $running_kernel"
        print_color "$GREEN" "  ✓ Installed kernel packages: $installed_kernels"
        ((score++))
    else
        print_color "$RED" "  ✗ Could not determine running or installed kernel versions"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking installonly_limit in /etc/dnf/dnf.conf..."
    if grep -q "installonly_limit" /etc/dnf/dnf.conf 2>/dev/null; then
        local limit
        limit=$(grep "installonly_limit" /etc/dnf/dnf.conf | head -1)
        print_color "$GREEN" "  ✓ Found: $limit"
        ((score++))
    else
        print_color "$RED" "  ✗ installonly_limit not found in /etc/dnf/dnf.conf"
        print_color "$YELLOW" "  Check: cat /etc/dnf/dnf.conf"
    fi
    echo ""

    print_color "$CYAN" "[3/$total] Checking grubby --default-kernel is functional..."
    local default_kernel
    default_kernel=$(grubby --default-kernel 2>/dev/null)
    if [ -n "$default_kernel" ]; then
        print_color "$GREEN" "  ✓ Default kernel: $default_kernel"
        ((score++))
    else
        print_color "$RED" "  ✗ grubby --default-kernel returned nothing"
        print_color "$YELLOW" "  Install grubby if missing: dnf install grubby"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "You understand how RHEL manages kernel versions and updates."
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

STEP 1: Identify running and installed kernels
─────────────────────────────────────────────────────────────────
  uname -r
  rpm -q kernel
  ls -lh /boot/vmlinuz-*
  ls -lh /boot/initramfs-*


STEP 2: Inspect kernel retention policy
─────────────────────────────────────────────────────────────────
  grep installonly /etc/dnf/dnf.conf
  ls /boot/loader/entries/
  cat /boot/loader/entries/<entry>.conf


STEP 3: Check available updates and default boot kernel
─────────────────────────────────────────────────────────────────
  dnf list kernel
  grubby --default-kernel
  grubby --info=ALL

  # Command to update (know it, understand what it does):
  dnf update kernel


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Why Kernels Are Not Replaced On Update:
  Normal DNF package updates replace the old version with the new one.
  Kernels are declared as 'installonly' packages in DNF, which changes this
  behavior: new kernel versions are ADDED alongside existing ones. The old
  kernel remains bootable until it ages out past installonly_limit.
  This is a deliberate safety mechanism — if a kernel update causes a panic
  or loses support for a driver, you can recover by selecting the old kernel
  from the GRUB2 menu at boot without any package management steps.

What Happens During 'dnf update kernel':
  1. New kernel RPM (and kernel-core, kernel-modules, kernel-modules-extra) install
  2. /boot/vmlinuz-<new> and /boot/initramfs-<new>.img are created
  3. A new BLS entry is written to /boot/loader/entries/
  4. DNF calls grub2-mkconfig automatically via a post-install script
  5. The new kernel becomes the GRUB2 default
  6. If installonly_limit would be exceeded, the oldest kernel RPM is removed
     (its /boot/ files and BLS entry are deleted too)
  7. A REBOOT is required to actually run the new kernel

uname -r After Update (Before Reboot):
  uname -r still shows the OLD kernel version. The running kernel cannot be
  replaced in place — the new kernel is only activated on next boot.
  This is normal and expected. 'rpm -q kernel' will show the new version
  while uname -r still shows the old one until reboot.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Confusing uname -r with the newest installed kernel
  Result: Thinking the system is up to date when an update hasn't been rebooted into
  Fix: Compare uname -r with 'rpm -q kernel | sort -V | tail -1'

Mistake 2: Setting installonly_limit too low (e.g., 2)
  Result: Only one rollback option if the newest kernel fails
  Fix: Keep at 3 or higher for production systems

Mistake 3: /boot runs out of space
  Result: kernel install fails; system may not boot after a partial install
  Fix: Monitor /boot with 'df -h /boot'; increase installonly_limit only if
       you're actively managing /boot capacity


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Know the update command: dnf update kernel (or dnf install kernel — both work)
2. Know that a reboot is required after kernel update — uname -r won't change until then
3. installonly_limit is in /etc/dnf/dnf.conf — know where it is and what it does
4. rpm -q kernel lists all installed kernel versions — useful for verifying updates
5. After update: grubby --default-kernel confirms the new kernel is set as default

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    echo "  ✓ No system state was modified by this lab — nothing to clean up"
}

main "$@"
