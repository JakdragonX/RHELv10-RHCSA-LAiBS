#!/bin/bash
# labs/26A-time-service.sh
# Lab: Configuring Time Service — timedatectl, chrony, and hwclock
# Difficulty: Beginner
# RHCSA Objective: Configure time service clients; set timezone and NTP synchronization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="Configuring Time Service"
LAB_DIFFICULTY="Beginner"
LAB_TIME_ESTIMATE="20-25 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Back up chrony.conf if not already done
    if [ ! -f /etc/chrony.conf.lab-backup ]; then
        cp /etc/chrony.conf /etc/chrony.conf.lab-backup 2>/dev/null || true
    fi

    # Ensure chrony is installed and running as a baseline
    if ! rpm -q chrony >/dev/null 2>&1; then
        echo "  Installing chrony..."
        dnf install -y chrony >/dev/null 2>&1 || true
    fi
    systemctl enable --now chronyd 2>/dev/null || true

    echo "  ✓ chrony installed and running"
    echo "  ✓ /etc/chrony.conf backed up"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Basic systemctl usage (start, stop, enable, status)
  • Understanding that Linux maintains two clocks: hardware and system

The Two Clocks:
  Hardware clock (RTC): battery-powered, runs when the system is off.
    Lives on the motherboard. Read/written with hwclock.

  System clock: kernel's in-memory clock, set at boot from the hardware
    clock, then kept accurate by NTP. Read/written with date or timedatectl.

  At boot:  hardware clock → system clock (hwclock --hctosys)
  To save:  system clock → hardware clock (hwclock --systohc)

Commands You'll Use:
  • timedatectl         - The primary tool for managing time and timezone
  • date                - Display or format time; use for scripting, not setting
  • hwclock             - Read and sync the hardware clock
  • chronyc sources     - Show NTP sources chrony is syncing with
  • chronyc tracking    - Show how well chrony is synchronized
  • systemctl           - Manage the chronyd service

Files You'll Interact With:
  • /etc/chrony.conf    - chrony NTP client/server configuration
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A newly provisioned RHEL server has no timezone configured and NTP
synchronization is not verified. Before putting it into production you
need to set the correct timezone, confirm NTP is working, and understand
how to update the chrony configuration if a custom NTP server is required.

OBJECTIVES:
  1. Use timedatectl to inspect the current time configuration. Set the
     timezone to America/New_York. Verify the change with timedatectl status.

  2. Confirm that NTP synchronization is active. Use chronyc sources to
     see which NTP servers chrony is syncing with and interpret the output.
     Identify what the * symbol means in the sources list.

  3. Add a backup NTP server to /etc/chrony.conf. Add the line:
       server time.cloudflare.com iburst
     Restart chronyd and verify with chronyc sources that the new server
     appears in the source list.

  4. Use date to print the current time in two custom formats:
       date +"%A %d %B %Y"     (e.g. Monday 18 May 2026)
       date +"%H:%M:%S"        (e.g. 14:32:07)

HINTS:
  • timedatectl list-timezones | grep America lists available US timezones
  • chronyc sources output: * = current sync source, + = acceptable, ? = unreachable
  • After editing chrony.conf, always restart chronyd for changes to take effect
  • date format strings: %A=weekday %d=day %B=month %Y=year %H=hour %M=min %S=sec

SUCCESS CRITERIA:
  • timedatectl status shows timezone as America/New_York
  • NTP service (chronyd) is active and synchronized
  • /etc/chrony.conf contains the Cloudflare server line
  • chronyc sources shows the new server in the list
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. timedatectl set-timezone America/New_York; verify with timedatectl status
  ☐ 2. chronyc sources — confirm sync source (*) and understand output columns
  ☐ 3. Add 'server time.cloudflare.com iburst' to /etc/chrony.conf; restart chronyd
  ☐ 4. date +"%A %d %B %Y" and date +"%H:%M:%S"
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
A new RHEL server needs its timezone set, NTP verified, and a custom NTP
server added to the chrony configuration before going into production.
EOF
}

# STEP 1: timedatectl timezone
show_step_1() {
    cat << 'EOF'
CONCEPT: timedatectl
────────────────────
timedatectl is the single tool for managing all time-related settings on
a systemd-based system. Running it with no arguments (or 'status') shows
a summary:

  timedatectl status
  # Output includes:
  #   Local time:    Mon 2026-05-18 14:32:07 EDT
  #   Universal time: Mon 2026-05-18 18:32:07 UTC
  #   RTC time:      Mon 2026-05-18 18:32:07       ← hardware clock
  #   Time zone:     America/New_York (EDT, -0400)
  #   NTP service:   active
  #   NTP synchronized: yes

Useful subcommands:
  timedatectl list-timezones          list all available timezone names
  timedatectl set-timezone Zone/City  change the timezone
  timedatectl set-ntp true/false      enable or disable NTP sync

────────────────────────────────────────────
TASK: Set the timezone to America/New_York

Requirements:
  • Run timedatectl status and note the current timezone
  • Set the timezone to America/New_York
  • Verify the change with timedatectl status

Commands you might need:
  • timedatectl status
  • timedatectl list-timezones | grep America
  • timedatectl set-timezone America/New_York
EOF
}

validate_step_1() {
    local tz
    tz=$(timedatectl show --property=Timezone --value 2>/dev/null)

    if [ "$tz" = "America/New_York" ]; then
        return 0
    fi

    echo ""
    print_color "$RED" "✗ Timezone is '$tz' (expected America/New_York)"
    echo "  Fix: timedatectl set-timezone America/New_York"
    return 1
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
timedatectl status                          # note current timezone
timedatectl list-timezones | grep America   # find available US timezones
timedatectl set-timezone America/New_York
timedatectl status                          # verify

One thing to remember:
  Timezone names are case-sensitive and use the Region/City format from
  the tz database. America/New_York, not "EST" or "Eastern". The full
  list is also available at /usr/share/zoneinfo/ — each file there is
  a valid timezone name relative to that directory.

  Setting the timezone with timedatectl updates the symlink at
  /etc/localtime → /usr/share/zoneinfo/America/New_York
  and writes the name to /etc/timezone.

Verification:
  timedatectl status | grep "Time zone"
  # Expected: Time zone: America/New_York (EDT, -0400)

EOF
}

hint_step_2() {
    echo "  Run: chronyc sources"
    echo "  Look for a line starting with * — that is the current sync source"
}

# STEP 2: chronyc sources
show_step_2() {
    cat << 'EOF'
CONCEPT: Verifying NTP Synchronization with chronyc
────────────────────────────────────────────────────
chronyd is the NTP daemon on RHEL. After it starts, it reaches out to
configured NTP pool servers and synchronizes the system clock. You can
inspect its current state with two commands:

  chronyc sources      — list NTP sources and their status
  chronyc tracking     — show synchronization statistics

The 'sources' output has these columns:
  S  Name/IP         Stratum  Poll  Reach  LastRx  Last sample

The S (status) column is the most important:
  *   = currently selected sync source (only one at a time)
  +   = acceptable alternative source
  -   = not selected but reachable
  ?   = unreachable / not yet contacted
  x   = marked as a falseticker (bad time)

Stratum indicates how far the server is from a reference clock:
  1 = atomic clock or GPS (highest accuracy)
  2 = synchronized to a stratum 1 server
  ... and so on. Lower stratum = more authoritative.

────────────────────────────────────────────────────
TASK: Verify NTP synchronization and read the sources output

Requirements:
  • Run chronyc sources and identify the current sync source (*)
  • Note the stratum of your sync source
  • Run chronyc tracking and find the "System time" offset line

Commands you might need:
  • chronyc sources
  • chronyc sources -v    (verbose, adds column headers)
  • chronyc tracking
  • timedatectl status    (also shows NTP synchronized: yes/no)
EOF
}

validate_step_2() {
    # Check that NTP is enabled and chronyd is running
    local ntp_active
    ntp_active=$(timedatectl show --property=NTP --value 2>/dev/null)

    if ! systemctl is-active chronyd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ chronyd is not running"
        echo "  Fix: systemctl enable --now chronyd"
        return 1
    fi

    if [ "$ntp_active" != "yes" ]; then
        echo ""
        print_color "$RED" "✗ NTP is not enabled in timedatectl"
        echo "  Fix: timedatectl set-ntp true"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
chronyc sources -v     # -v adds column headers for readability
chronyc tracking
timedatectl status

Reading chronyc sources output:
  ^* 2.rhel.pool.ntp.org   2   6   377   123   +1.234ms  ±0.456ms

  ^*  = selected sync source (^ means it's a pool server)
  2   = stratum (synchronized to a stratum 1 server)
  6   = poll interval (2^6 = 64 seconds between queries)
  377 = reach register (binary: all 8 recent polls succeeded = 0b11111111)
  123 = last received response, 123 seconds ago
  +1.234ms = offset from reference time

A Reach value of 377 (octal, meaning all 8 bits set) means chrony has
successfully received a response in each of the last 8 poll intervals —
the source is fully reachable and reliable.

If chronyc shows no * source yet:
  It can take a minute or two after chronyd starts to select a source.
  Run 'chronyc waitsync' to block until synchronization is achieved.

Verification:
  timedatectl status | grep "NTP synchronized"
  # Expected: NTP synchronized: yes

EOF
}

hint_step_3() {
    echo "  Add to /etc/chrony.conf: server time.cloudflare.com iburst"
    echo "  Then: systemctl restart chronyd"
    echo "  Then: chronyc sources   (may take ~30 seconds for new source to appear)"
}

# STEP 3: Editing chrony.conf
show_step_3() {
    cat << 'EOF'
CONCEPT: /etc/chrony.conf — Configuring NTP Sources
─────────────────────────────────────────────────────
chrony reads its NTP source configuration from /etc/chrony.conf.
The two most common source directives are:

  pool pool.ntp.org iburst        → use a pool of servers (DNS rotates IPs)
  server time.example.com iburst  → use a single specific server

The iburst option permits a burst of packets when first connecting, which
gets synchronization to a useful state much faster than the default slow
ramp-up. Always use iburst in client configurations.

You can mix pool and server lines. chrony will query all of them and
select the best source(s) based on accuracy and reachability.

After any change to /etc/chrony.conf:
  systemctl restart chronyd

The existing pool line (pool 2.rhel.pool.ntp.org iburst) handles normal
synchronization. You are adding a second source as a backup.

─────────────────────────────────────────────────────
TASK: Add a backup NTP server to chrony.conf

Requirements:
  • Open /etc/chrony.conf and add this line (after the existing pool line):
      server time.cloudflare.com iburst
  • Restart chronyd to apply the change
  • Run chronyc sources to confirm the new server appears in the list
    (it may show ? initially — that is normal while it is being contacted)

Commands you might need:
  • vi /etc/chrony.conf
  • echo 'server time.cloudflare.com iburst' >> /etc/chrony.conf
  • systemctl restart chronyd
  • chronyc sources
EOF
}

validate_step_3() {
    if ! grep -q "time.cloudflare.com" /etc/chrony.conf 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ 'time.cloudflare.com' not found in /etc/chrony.conf"
        echo "  Fix: echo 'server time.cloudflare.com iburst' >> /etc/chrony.conf"
        echo "       systemctl restart chronyd"
        return 1
    fi

    if ! grep -q "iburst" <(grep "time.cloudflare.com" /etc/chrony.conf 2>/dev/null); then
        echo ""
        print_color "$RED" "✗ The cloudflare entry exists but is missing 'iburst'"
        echo "  Fix: edit /etc/chrony.conf and add iburst to the server line"
        return 1
    fi

    if ! systemctl is-active chronyd >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ chronyd is not running after the config change"
        echo "  Fix: systemctl restart chronyd"
        return 1
    fi

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
echo 'server time.cloudflare.com iburst' >> /etc/chrony.conf
systemctl restart chronyd
chronyc sources

Verify the line was added:
  grep cloudflare /etc/chrony.conf
  # Expected: server time.cloudflare.com iburst

One thing to remember:
  Changes to /etc/chrony.conf have no effect until chronyd is restarted.
  This is the same pattern as most system daemons: edit the config file,
  then restart the service. The new source will initially show ? in
  chronyc sources while chrony probes it; within about 30 seconds it
  should show + or - (or * if it becomes the best source).

  The difference between pool and server:
    pool  → DNS name that resolves to multiple IPs; chrony picks several
    server → single specific host; chrony uses exactly that host

NTP server configuration (for reference — not required in this lab):
  To make THIS system serve time to others, add to /etc/chrony.conf:
    allow 192.168.1.0/24     ← allow clients on this subnet
  Then open the firewall:
    firewall-cmd --permanent --add-service=ntp
    firewall-cmd --reload

Verification:
  grep cloudflare /etc/chrony.conf    # → server time.cloudflare.com iburst
  systemctl is-active chronyd         # → active
  chronyc sources                     # → cloudflare entry appears

EOF
}

hint_step_4() {
    echo "  date +\"%A %d %B %Y\"   and   date +\"%H:%M:%S\""
    echo "  Quotes are needed when the format string contains spaces"
}

# STEP 4: date formatting
show_step_4() {
    cat << 'EOF'
CONCEPT: date Format Strings
─────────────────────────────
date +FORMAT prints the current time using a format string where each
% code is replaced with a time component:

  %A   full weekday name     (Monday)
  %a   short weekday name    (Mon)
  %d   day of month          (05, 18)
  %B   full month name       (January, May)
  %b   short month name      (Jan, May)
  %Y   four-digit year       (2026)
  %y   two-digit year        (26)
  %H   hour, 24-hour         (00–23)
  %M   minute                (00–59)
  %S   second                (00–59)
  %s   Unix timestamp        (seconds since 1970-01-01)

Quotes are required when the format string contains spaces:
  date +"%A %d %B %Y"    ← correct (quoted)
  date +%A %d %B %Y      ← wrong (%d %B %Y become separate arguments)

date is useful for generating timestamps in scripts and log entries.
Use timedatectl (not date) when you actually need to set the system time.

─────────────────────────────────────────────────────
TASK: Print the current time in two formats

Requirements:
  • Run: date +"%A %d %B %Y"
    Expected output like: Monday 18 May 2026
  • Run: date +"%H:%M:%S"
    Expected output like: 14:32:07
  • Write a one-liner that creates a log entry with a timestamp:
    echo "Service started at $(date +"%Y-%m-%d %H:%M:%S")" > /tmp/lab26a-timestamp.txt
    cat /tmp/lab26a-timestamp.txt
EOF
}

validate_step_4() {
    # Check the timestamp file was created as instructed
    if [ ! -f /tmp/lab26a-timestamp.txt ]; then
        echo ""
        print_color "$RED" "✗ /tmp/lab26a-timestamp.txt not found"
        echo "  Run: echo \"Service started at \$(date +\"%Y-%m-%d %H:%M:%S\")\" > /tmp/lab26a-timestamp.txt"
        return 1
    fi

    if ! grep -q "Service started at" /tmp/lab26a-timestamp.txt; then
        echo ""
        print_color "$RED" "✗ /tmp/lab26a-timestamp.txt does not contain 'Service started at'"
        echo "  Contents: $(cat /tmp/lab26a-timestamp.txt)"
        return 1
    fi

    return 0
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
date +"%A %d %B %Y"
date +"%H:%M:%S"
echo "Service started at $(date +"%Y-%m-%d %H:%M:%S")" > /tmp/lab26a-timestamp.txt
cat /tmp/lab26a-timestamp.txt

One thing to remember:
  The ISO 8601 format %Y-%m-%d %H:%M:%S is the most useful for log files
  and scripts because it sorts correctly as a string (alphabetical sort =
  chronological sort). The human-readable formats are fine for display but
  break string sorting.

  date is read-only for display. To actually change the system time, use:
    timedatectl set-time "2026-05-18 14:32:00"
  But on a system with NTP active, manual time-setting is usually blocked —
  NTP will immediately correct it. Disable NTP first if you need to set
  time manually: timedatectl set-ntp false

Verification:
  cat /tmp/lab26a-timestamp.txt
  # Expected: Service started at 2026-05-18 14:32:07

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=4

    echo "Checking your time configuration..."
    echo ""

    print_color "$CYAN" "[1/$total] Checking timezone is set to America/New_York..."
    local tz
    tz=$(timedatectl show --property=Timezone --value 2>/dev/null)
    if [ "$tz" = "America/New_York" ]; then
        print_color "$GREEN" "  ✓ Timezone: $tz"
        ((score++))
    else
        print_color "$RED" "  ✗ Timezone is '$tz' (expected America/New_York)"
        print_color "$YELLOW" "  Fix: timedatectl set-timezone America/New_York"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking NTP is active (chronyd running)..."
    local ntp_sync
    ntp_sync=$(timedatectl show --property=NTP --value 2>/dev/null)
    if systemctl is-active chronyd >/dev/null 2>&1 && [ "$ntp_sync" = "yes" ]; then
        print_color "$GREEN" "  ✓ chronyd is active and NTP is enabled"
        ((score++))
    else
        ! systemctl is-active chronyd >/dev/null 2>&1 && \
            print_color "$RED" "  ✗ chronyd is not running"
        [ "$ntp_sync" != "yes" ] && \
            print_color "$RED" "  ✗ NTP not enabled (timedatectl shows NTP: no)"
        print_color "$YELLOW" "  Fix: systemctl enable --now chronyd && timedatectl set-ntp true"
    fi
    echo ""

    print_color "$CYAN" "[3/$total] Checking /etc/chrony.conf contains Cloudflare server with iburst..."
    if grep -q "time.cloudflare.com" /etc/chrony.conf 2>/dev/null && \
       grep "time.cloudflare.com" /etc/chrony.conf | grep -q "iburst"; then
        print_color "$GREEN" "  ✓ Cloudflare NTP server configured with iburst"
        ((score++))
    else
        print_color "$RED" "  ✗ time.cloudflare.com iburst not found in /etc/chrony.conf"
        print_color "$YELLOW" "  Fix: echo 'server time.cloudflare.com iburst' >> /etc/chrony.conf"
        print_color "$YELLOW" "       systemctl restart chronyd"
    fi
    echo ""

    print_color "$CYAN" "[4/$total] Checking /tmp/lab26a-timestamp.txt was created..."
    if [ -f /tmp/lab26a-timestamp.txt ] && grep -q "Service started at" /tmp/lab26a-timestamp.txt; then
        print_color "$GREEN" "  ✓ Timestamp file created: $(cat /tmp/lab26a-timestamp.txt)"
        ((score++))
    else
        print_color "$RED" "  ✗ /tmp/lab26a-timestamp.txt missing or incorrect"
        print_color "$YELLOW" "  Fix: echo \"Service started at \$(date +'%Y-%m-%d %H:%M:%S')\" > /tmp/lab26a-timestamp.txt"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Time service is correctly configured."
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

STEP 1: Set timezone
─────────────────────────────────────────────────────────────────
  timedatectl status
  timedatectl set-timezone America/New_York
  timedatectl status


STEP 2: Verify NTP synchronization
─────────────────────────────────────────────────────────────────
  systemctl status chronyd
  chronyc sources -v
  chronyc tracking

  The * in chronyc sources marks the currently selected sync source.
  Reach=377 (all 8 recent polls successful) means the source is healthy.


STEP 3: Add a custom NTP server
─────────────────────────────────────────────────────────────────
  echo 'server time.cloudflare.com iburst' >> /etc/chrony.conf
  systemctl restart chronyd
  chronyc sources


STEP 4: date format strings
─────────────────────────────────────────────────────────────────
  date +"%A %d %B %Y"
  date +"%H:%M:%S"
  echo "Service started at $(date +"%Y-%m-%d %H:%M:%S")" > /tmp/lab26a-timestamp.txt


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Time Source Hierarchy (Boot Sequence):
  1. System powers on → reads hardware clock (RTC) for initial time
  2. Kernel sets system clock from hardware clock
  3. chronyd starts → contacts NTP pool → adjusts system clock
  4. chronyd runs continuously, making small adjustments to stay accurate

  hwclock --hctosys  → copy hardware clock TO system clock (done at boot)
  hwclock --systohc  → copy system clock TO hardware clock (save NTP time)

The 1000-Second Rule:
  If the difference between the system clock and NTP time exceeds 1000
  seconds (~16 minutes), chronyd refuses to synchronize automatically.
  This prevents accidental large jumps. To force sync across a large gap:
    chronyc makestep          ← force an immediate time step
  Or restart chronyd with 'makestep' in the config (already there on RHEL).

Stratum:
  stratum 1  → directly connected to atomic clock / GPS
  stratum 2  → synced to a stratum 1 server
  stratum N  → synced to a stratum N-1 server
  stratum 10 → conventional value for a local fallback clock
  stratum 16 → indicates the server considers itself unsynchronized

  When you sync to a stratum 2 pool, your system is stratum 3. If you
  configure your system as an NTP server (allow directive + firewall),
  it advertises stratum 3 to its clients.


COMMON MISTAKES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: Editing /etc/chrony.conf without restarting chronyd
  Result: New sources don't appear; old config remains active in memory
  Fix: systemctl restart chronyd after every config change

Mistake 2: Using 'date' to set system time instead of timedatectl
  Result: Works momentarily, but NTP corrects it within seconds
  Fix: timedatectl set-ntp false first if manual time-setting is needed,
       or just use timedatectl set-time "YYYY-MM-DD HH:MM:SS"

Mistake 3: Timezone abbreviations instead of Region/City names
  Result: timedatectl set-timezone EST → error or wrong timezone
  Fix: timedatectl list-timezones | grep America to find the correct name


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. timedatectl is the primary time tool — status, set-timezone, set-ntp
2. chronyc sources confirms synchronization; look for the * symbol
3. /etc/chrony.conf: pool = multiple servers, server = single server, iburst = fast start
4. Always restart chronyd after editing its config
5. date is for display and script timestamps, not for setting time
6. hwclock --systohc saves current system time to hardware clock

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    # Restore chrony.conf
    if [ -f /etc/chrony.conf.lab-backup ]; then
        cp /etc/chrony.conf.lab-backup /etc/chrony.conf
        rm -f /etc/chrony.conf.lab-backup
        systemctl restart chronyd 2>/dev/null || true
        echo "  ✓ /etc/chrony.conf restored"
    fi

    rm -f /tmp/lab26a-timestamp.txt 2>/dev/null || true
    echo "  ✓ Timestamp file removed"
    echo ""
    echo "  NOTE: Timezone is still set to America/New_York."
    echo "  To restore your original timezone:"
    echo "    timedatectl set-timezone <your-timezone>"
    echo "    timedatectl list-timezones | grep <region> to find it"
}

main "$@"
