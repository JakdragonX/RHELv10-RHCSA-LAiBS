#!/bin/bash
# labs/21A-kernel-modules.sh
# Lab: Kernel Module Inspection and Manual Loading
# Difficulty: Intermediate
# RHCSA Objective: List and identify kernel module capabilities; load and unload kernel modules

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Kernel Module Inspection and Manual Loading"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="15-20 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Remove any leftover lab modprobe config from a previous attempt
    rm -f /etc/modprobe.d/lab21a.conf 2>/dev/null || true

    # Unload the lab target module if it was manually loaded previously.
    # 'vfat' is used because it is nearly always present as a module but not
    # loaded by default on a server, making it safe to load/unload repeatedly.
    # If vfat is already in use (e.g., mounted filesystem), modprobe -r will
    # refuse — that is fine, we just ensure we're not in a broken state.
    modprobe -r vfat 2>/dev/null || true

    echo "  ✓ Cleared any previous lab modprobe config"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • What a kernel module is (a driver or feature loaded into the kernel at runtime)
  • The difference between built-in kernel support and loadable modules
  • That modules are stored as .ko files under /lib/modules/$(uname -r)/

Commands You'll Use:
  • lsmod        - List currently loaded kernel modules and their dependencies
  • modinfo      - Show metadata about a specific module (path, params, aliases)
  • modprobe     - Load a module (and its dependencies) into the kernel
  • modprobe -r  - Remove/unload a module from the kernel
  • lspci -k     - List PCI devices and the kernel module driving each one
  • dmesg        - View the kernel ring buffer (useful for confirming module load events)

Files You'll Interact With:
  • /etc/modprobe.d/         - Drop-in directory for persistent module load options
  • /usr/lib/udev/rules.d/   - System udev rules controlling automatic module loading
  • /lib/modules/$(uname -r)/ - Where module .ko files live on disk

KEY CONCEPT — lsmod output columns:
  Module        Size      Used by
  vfat          24576     0
  fat           90112     1 vfat

  • Module:   name of the loaded module
  • Size:     memory footprint in bytes
  • Used by:  reference count + names of modules that depend on this one
              A count of 0 means nothing depends on it — safe to unload.
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A colleague reports that a USB FAT32 drive is not mounting correctly on a
server. You suspect the vfat kernel module is not loaded. Your task is to
inspect the currently loaded modules, gather information about the vfat
module, load it manually, and then configure it to load automatically with
a specific parameter on future boots.

BACKGROUND:
On RHEL servers, modules for filesystems like vfat are not loaded until
needed. systemd-udevd handles this automatically when hardware is plugged in,
but you can also load modules manually for testing or pre-configuration.

OBJECTIVES:
  1. Use lsmod to view all currently loaded modules, then pipe the output
     to grep to check whether 'vfat' is already loaded.
     Then use lspci -k to see which modules are bound to your PCI devices.

  2. Use modinfo to inspect the vfat module. Identify its full path on disk,
     its description, and whether it has any loadable parameters (parms:).
     Also confirm what modules it depends on (depends:).

  3. Load the vfat module manually using modprobe. Verify it is loaded
     with lsmod, and confirm the kernel logged the event using dmesg.

  4. Create a persistent modprobe configuration in /etc/modprobe.d/lab21a.conf
     that sets the vfat module option 'utf8=1' (enables UTF-8 filename
     support). Verify the file is correctly formed.

HINTS:
  • lsmod | grep vfat — checks if the module is loaded
  • modinfo vfat — you don't need the .ko extension or full path
  • modprobe dependencies are resolved automatically
  • dmesg | tail -20 — shows the most recent kernel messages
  • /etc/modprobe.d/ files use the format: options <module> <param>=<value>

SUCCESS CRITERIA:
  • vfat module is loaded (visible in lsmod output)
  • /etc/modprobe.d/lab21a.conf exists and contains: options vfat utf8=1
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Use lsmod and lspci -k to inspect currently loaded modules
  ☐ 2. Use modinfo vfat to identify path, description, params, and dependencies
  ☐ 3. Load vfat with modprobe and confirm via lsmod and dmesg
  ☐ 4. Create /etc/modprobe.d/lab21a.conf with: options vfat utf8=1
EOF
}

#############################################################################
# INTERACTIVE MODE
#############################################################################
get_step_count() {
    echo "4"
}

scenario_context() {
    cat << 'EOF'
A USB FAT32 drive is not mounting correctly on a server. You need to inspect,
manually load, and persistently configure the vfat kernel module.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Inspect currently loaded kernel modules

Use lsmod to list all loaded modules and check whether 'vfat' is present.
Then use lspci -k to see which modules are currently bound to detected PCI devices.

Requirements:
  • Run lsmod and interpret the three output columns
  • Use grep to filter for vfat specifically
  • Run lspci -k and note the 'Kernel driver in use:' and
    'Kernel modules:' fields for at least one device

Commands you might need:
  • lsmod
  • lsmod | grep vfat
  • lspci -k
EOF
}

validate_step_1() {
    # Observational — verify lsmod is functional
    if lsmod >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ lsmod is not responding — something is seriously wrong with the kernel interface"
    return 1
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  lsmod
  lsmod | grep vfat
  lspci -k

Explanation:
  • lsmod reads from /proc/modules and formats the output as three columns:
    Module name, memory size in bytes, and reference count + dependent modules
  • lsmod | grep vfat: if this returns nothing, the module is not currently loaded
  • lspci -k: the -k flag adds driver binding info to each PCI device entry.
    'Kernel driver in use' = the module currently managing that device.
    'Kernel modules' = all modules that COULD drive the device (loaded or not).

Why this matters:
  lspci -k is your first diagnostic tool when a PCI device isn't working —
  if 'Kernel driver in use' is blank, no module has claimed the device.

Verification:
  lsmod | grep vfat
  # If empty: module is not loaded (expected at this point)
  # If present: it was already loaded, proceed to step 2

EOF
}

hint_step_2() {
    echo "  Use: modinfo vfat — look for the 'depends:', 'filename:', and 'parms:' fields"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Inspect the vfat module with modinfo

Use modinfo to display all available metadata about the vfat module.
You do not need the full path or .ko extension — modinfo resolves it
from /lib/modules/$(uname -r)/ automatically.

Requirements:
  • Identify the full path to the vfat .ko file (filename: field)
  • Note what modules vfat depends on (depends: field)
  • Check whether vfat has any configurable parameters (parms: field)

Commands you might need:
  • modinfo vfat
  • modinfo vfat | grep -E 'filename|depends|parms'
EOF
}

validate_step_2() {
    # Observational — verify modinfo can find the module
    if modinfo vfat >/dev/null 2>&1; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ modinfo cannot find the vfat module"
    echo "  This module may not be available on this system."
    echo "  Check: find /lib/modules/\$(uname -r) -name 'vfat*'"
    return 1
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  modinfo vfat
  modinfo vfat | grep -E 'filename|depends|parms'

Key fields in modinfo output:
  • filename:  Full path to the .ko file on disk.
               e.g. /lib/modules/5.14.0-427.el9.x86_64/kernel/fs/fat/vfat.ko.xz
  • depends:   Comma-separated list of modules vfat requires.
               vfat depends on 'fat' — modprobe will load fat automatically.
  • parms:     Configurable parameters. For vfat you may see:
               utf8:UTF8 allows non-ASCII characters in filenames (int)
  • alias:     Alternative names the kernel uses to find this module
               (e.g. fs-vfat means it's the handler for vfat filesystems)

Why this matters:
  Before loading or configuring a module, modinfo tells you exactly what
  it does, what it depends on, and what you can tune — without having to
  load it first or search through documentation.

Verification:
  modinfo vfat | grep depends
  # Expected: depends: fat
  # This tells you modprobe will automatically pull in fat when you load vfat

EOF
}

hint_step_3() {
    echo "  Use: modprobe vfat — then check lsmod | grep -E 'vfat|fat' and dmesg | tail -10"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Manually load the vfat module and confirm the kernel logged it

Use modprobe to load vfat. modprobe automatically resolves and loads
the 'fat' dependency first. Verify both modules appear in lsmod and
check dmesg to see the kernel's record of the load event.

Requirements:
  • Load vfat using modprobe (no flags needed for a basic load)
  • Confirm vfat AND fat appear in lsmod (fat is a dependency)
  • Check dmesg for evidence the module was loaded

Commands you might need:
  • modprobe vfat
  • lsmod | grep -E 'vfat|fat'
  • dmesg | tail -20
EOF
}

validate_step_3() {
    if lsmod | grep -q "^vfat"; then
        return 0
    fi
    echo ""
    print_color "$RED" "✗ vfat module is not loaded"
    echo "  Fix: modprobe vfat"
    return 1
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Commands:
  modprobe vfat
  lsmod | grep -E 'vfat|fat'
  dmesg | tail -20

Explanation:
  • modprobe vfat: loads vfat and automatically loads 'fat' first since
    vfat depends on it. modprobe reads the dependency graph from
    /lib/modules/$(uname -r)/modules.dep to determine load order.
  • lsmod | grep -E 'vfat|fat': you should now see both modules.
    The 'Used by' column for fat will show '1 vfat' because vfat depends on it.
  • dmesg | tail -20: the kernel ring buffer will show a message when a new
    module is loaded, including its name and any initialization output.

modprobe vs insmod:
  insmod loads a single .ko file by path with no dependency resolution.
  modprobe loads by name and handles the full dependency chain.
  Always use modprobe unless you have a specific reason for insmod.

To unload (for reference):
  modprobe -r vfat
  # This also unloads 'fat' if nothing else depends on it.
  # modprobe -r will REFUSE to unload if the module is in use (e.g., a vfat
  # filesystem is mounted) — this is a safety mechanism, not an error.

Verification:
  lsmod | grep vfat
  # Expected: vfat  24576  0
  #           fat   90112  1 vfat

EOF
}

hint_step_4() {
    echo "  Create /etc/modprobe.d/lab21a.conf with the line: options vfat utf8=1"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Create a persistent modprobe configuration for vfat

Manually loading a module with modprobe does not persist across reboots.
To set module options persistently, create a configuration file in
/etc/modprobe.d/. The file must use the .conf extension and follow the
format: options <module_name> <param>=<value>

Requirements:
  • Create /etc/modprobe.d/lab21a.conf
  • The file must contain exactly: options vfat utf8=1
  • The file must be readable (standard permissions are fine)

Commands you might need:
  • echo 'options vfat utf8=1' > /etc/modprobe.d/lab21a.conf
  • cat /etc/modprobe.d/lab21a.conf
EOF
}

validate_step_4() {
    if [ ! -f /etc/modprobe.d/lab21a.conf ]; then
        echo ""
        print_color "$RED" "✗ /etc/modprobe.d/lab21a.conf does not exist"
        echo "  Fix: echo 'options vfat utf8=1' > /etc/modprobe.d/lab21a.conf"
        return 1
    fi

    if ! grep -q "options vfat utf8=1" /etc/modprobe.d/lab21a.conf; then
        echo ""
        print_color "$RED" "✗ /etc/modprobe.d/lab21a.conf exists but does not contain 'options vfat utf8=1'"
        echo "  Contents: $(cat /etc/modprobe.d/lab21a.conf)"
        echo "  Fix: echo 'options vfat utf8=1' > /etc/modprobe.d/lab21a.conf"
        return 1
    fi

    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  echo 'options vfat utf8=1' > /etc/modprobe.d/lab21a.conf
  cat /etc/modprobe.d/lab21a.conf

Explanation:
  • /etc/modprobe.d/: drop-in directory for modprobe configuration.
    Any file here ending in .conf is read by modprobe when loading modules.
  • 'options vfat utf8=1': tells modprobe to pass utf8=1 to the vfat module
    every time it is loaded, whether manually or by systemd-udevd.
  • The counterpart for modules that should always load (regardless of hardware
    events) is /etc/modules-load.d/ — put the module name alone in a .conf
    file there and it will be loaded at boot by systemd-modules-load.service.

/etc/modprobe.d/ vs /etc/modules-load.d/:
  /etc/modprobe.d/<name>.conf   → sets OPTIONS for a module when it loads
  /etc/modules-load.d/<name>.conf → tells systemd to LOAD the module at boot

  These serve different purposes and are often used together:
  modules-load.d ensures the module loads; modprobe.d ensures it loads correctly.

Verification:
  cat /etc/modprobe.d/lab21a.conf
  # Expected: options vfat utf8=1

  # To test the parameter takes effect (reload the module):
  modprobe -r vfat && modprobe vfat
  dmesg | tail -10
  # Look for any vfat initialization messages confirming utf8 mode

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

    print_color "$CYAN" "[1/$total] Checking vfat module is loaded..."
    if lsmod | grep -q "^vfat"; then
        print_color "$GREEN" "  ✓ vfat module is loaded"
        # Also note whether fat dependency is present
        if lsmod | grep -q "^fat"; then
            echo "  ✓ fat dependency also loaded (as expected)"
        fi
        ((score++))
    else
        print_color "$RED" "  ✗ vfat module is not loaded"
        print_color "$YELLOW" "  Fix: modprobe vfat"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking /etc/modprobe.d/lab21a.conf for 'options vfat utf8=1'..."
    if grep -q "options vfat utf8=1" /etc/modprobe.d/lab21a.conf 2>/dev/null; then
        print_color "$GREEN" "  ✓ Persistent modprobe config is correctly set"
        ((score++))
    else
        print_color "$RED" "  ✗ /etc/modprobe.d/lab21a.conf missing or incorrect"
        print_color "$YELLOW" "  Fix: echo 'options vfat utf8=1' > /etc/modprobe.d/lab21a.conf"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Well done! You can inspect, load, and persistently configure kernel modules."
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

STEP 1: Inspect loaded modules
─────────────────────────────────────────────────────────────────
  lsmod
  lsmod | grep vfat       # check if already loaded
  lspci -k                # see PCI devices and their bound modules


STEP 2: Inspect vfat module metadata
─────────────────────────────────────────────────────────────────
  modinfo vfat
  modinfo vfat | grep -E 'filename|depends|parms'

  Key findings:
    depends: fat           → modprobe will load fat automatically
    parms: utf8            → configurable at load time


STEP 3: Load vfat and confirm
─────────────────────────────────────────────────────────────────
  modprobe vfat
  lsmod | grep -E 'vfat|fat'
  dmesg | tail -20


STEP 4: Create persistent module option config
─────────────────────────────────────────────────────────────────
  echo 'options vfat utf8=1' > /etc/modprobe.d/lab21a.conf
  cat /etc/modprobe.d/lab21a.conf


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The Module Loading Pipeline:
  Hardware detected → kernel uevents → systemd-udevd → reads /usr/lib/udev/rules.d/
  → determines correct module → modprobe → loads module + dependencies → /proc/modules

  For manual or persistent loading outside of hardware events:
  /etc/modules-load.d/  → module names to load unconditionally at boot
  /etc/modprobe.d/      → options/parameters for modules when they load

modprobe Dependency Resolution:
  Module dependencies are pre-computed at kernel install time and stored in
  /lib/modules/$(uname -r)/modules.dep. modprobe reads this file to determine
  load order. You never need to manually load dependencies — modprobe handles it.

modprobe -r Safety:
  modprobe -r will refuse to unload a module whose reference count is non-zero.
  A count > 0 means something (another module or an active mount) is using it.
  This prevents kernel instability from unloading modules that are in use.


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Using insmod instead of modprobe
  Result: insmod fails if a dependency isn't already loaded; no auto-resolution
  Fix: Use modprobe for all normal module management

Mistake 2: Putting module names in /etc/modprobe.d/ instead of /etc/modules-load.d/
  Result: Module is never loaded at boot (modprobe.d sets OPTIONS, not load order)
  Fix: Use /etc/modules-load.d/<name>.conf with just the module name on a line

Mistake 3: Forgetting modprobe -r won't work if a filesystem is mounted
  Result: ERROR: Module vfat is in use
  Fix: Unmount the filesystem first, then run modprobe -r vfat


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. lsmod, modinfo, modprobe are the three core module management commands
2. modinfo <module> — always check this before loading to understand dependencies
3. Persistent options → /etc/modprobe.d/; persistent loading → /etc/modules-load.d/
4. lspci -k is your diagnostic tool for PCI devices with no driver bound

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    rm -f /etc/modprobe.d/lab21a.conf 2>/dev/null || true
    modprobe -r vfat 2>/dev/null || true

    echo "  ✓ Removed /etc/modprobe.d/lab21a.conf"
    echo "  ✓ Unloaded vfat module (if not in use)"
}

main "$@"
