#!/bin/bash
# labs/29A-nfs-autofs.sh
# Lab: NFS Server Setup, Manual Mount, and autofs Configuration
# Difficulty: Intermediate
# RHCSA Objective: Mount NFS shares and configure autofs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="NFS Server Setup, Manual Mount, and autofs"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="30-35 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Install required packages
    if ! rpm -q nfs-utils >/dev/null 2>&1; then
        echo "  Installing nfs-utils..."
        dnf install -y nfs-utils >/dev/null 2>&1 || true
    fi
    if ! rpm -q autofs >/dev/null 2>&1; then
        echo "  Installing autofs..."
        dnf install -y autofs >/dev/null 2>&1 || true
    fi

    # Clean up previous lab state
    umount /mnt/lab29a 2>/dev/null || true
    umount /data/nfsfiles 2>/dev/null || true
    systemctl stop autofs 2>/dev/null || true

    # Remove previous lab autofs config entries
    sed -i '/lab29a/d' /etc/auto.master 2>/dev/null || true
    rm -f /etc/auto.lab29a 2>/dev/null || true

    # Remove previous NFS export
    sed -i '/lab29nfs/d' /etc/exports 2>/dev/null || true

    # Stop NFS server if it was running for the lab
    # (don't stop if it was already running before)

    # Create the NFS export directory and some content
    rm -rf /srv/lab29nfs 2>/dev/null || true
    mkdir -p /srv/lab29nfs
    echo "NFS lab file — served from localhost" > /srv/lab29nfs/lab-content.txt
    echo "Second file for testing" > /srv/lab29nfs/readme.txt
    chmod 755 /srv/lab29nfs

    # Create client mount points
    mkdir -p /mnt/lab29a
    mkdir -p /data

    echo "  ✓ Created /srv/lab29nfs with sample files"
    echo "  ✓ Created mount points /mnt/lab29a and /data"
    echo "  ✓ nfs-utils and autofs installed"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • systemctl for managing services (nfs-server, autofs)
  • Basic understanding of filesystems and mount points
  • /etc/fstab concept (autofs is similar but automatic)

What NFS Is:
  NFS (Network File System) lets a server share a directory over the
  network, and clients mount it as if it were a local directory.

  This lab runs BOTH server and client on the same machine (localhost)
  to avoid needing two VMs. The concept is identical on separate machines.

What autofs Is:
  autofs mounts filesystems ON DEMAND — only when you access the mount
  point directory. If idle, it automatically unmounts after a timeout.
  This is more efficient than /etc/fstab mounts, which mount at boot
  regardless of whether anyone uses them.

  /etc/fstab mount:   always mounted, from boot until shutdown
  autofs mount:       mounted when accessed, unmounted when idle

Files You'll Interact With:
  • /etc/exports           - NFS server: what directories to share and to whom
  • /etc/auto.master       - autofs: which directories autofs manages
  • /etc/auto.*            - autofs: per-directory mount detail files
  • /etc/auto.misc         - autofs: example file with syntax reference

Commands You'll Use:
  • exportfs -av          - Apply /etc/exports without restarting nfs-server
  • showmount -e localhost - List NFS exports visible from this host
  • mount server:/share /mnt  - Manual NFS mount
  • umount /mnt           - Unmount
  • systemctl             - Manage nfs-server and autofs services
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A team directory needs to be shared via NFS and automatically mounted
on client machines. You will configure this machine as both the NFS
server (exporting /srv/lab29nfs) and the NFS client (mounting via autofs).

OBJECTIVES:
  1. Configure the NFS server. Add /srv/lab29nfs to /etc/exports so it is
     accessible from localhost with read-write permissions. Start nfs-server
     and apply the export. Verify with showmount -e localhost.

  2. Mount the NFS share manually to confirm it works. Mount localhost:/srv/lab29nfs
     to /mnt/lab29a and verify you can read the files inside. Then unmount it.

  3. Configure autofs to automatically mount the share. In /etc/auto.master,
     add a line pointing to /data as the managed directory with
     /etc/auto.lab29a as the map file. In /etc/auto.lab29a, add an entry
     that mounts localhost:/srv/lab29nfs at /data/nfsfiles. Start autofs and
     trigger the mount by accessing /data/nfsfiles.

  4. Verify the autofs mount. After accessing /data/nfsfiles, run
     mount | grep nfsfiles to confirm it is mounted. Read one of the files
     to confirm the content is from the NFS server.

HINTS:
  • /etc/exports format: /path  client(options)
    Example: /srv/lab29nfs  localhost(rw,sync,no_root_squash)
  • exportfs -av applies exports without restarting the service
  • autofs map file format: mountpoint  options  server:/path
    Example: nfsfiles  -rw  localhost:/srv/lab29nfs
  • After editing auto.master, restart autofs: systemctl restart autofs
  • Access /data/nfsfiles to trigger the mount (cd /data/nfsfiles or ls)
  • Check /etc/auto.misc for syntax examples

SUCCESS CRITERIA:
  • showmount -e localhost shows /srv/lab29nfs in the export list
  • autofs is running and /data/nfsfiles mounts on access
  • Files from /srv/lab29nfs are readable at /data/nfsfiles
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Add /srv/lab29nfs to /etc/exports; start nfs-server; showmount -e localhost
  ☐ 2. mount localhost:/srv/lab29nfs /mnt/lab29a; ls; umount /mnt/lab29a
  ☐ 3. Edit /etc/auto.master and /etc/auto.lab29a; systemctl restart autofs
  ☐ 4. Access /data/nfsfiles to trigger mount; verify with mount | grep nfsfiles
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
Configure this machine as both NFS server and client. The server exports
/srv/lab29nfs; autofs will mount it automatically at /data/nfsfiles when accessed.
EOF
}

# STEP 1: NFS server
show_step_1() {
    cat << 'EOF'
CONCEPT: /etc/exports — Defining NFS Shares
────────────────────────────────────────────
The NFS server reads /etc/exports to know what to share and who can access it.
Each line has this format:
  /path/to/share   client(options)

  client can be:
    localhost         this machine only
    192.168.1.100     one specific host
    192.168.1.0/24    an entire subnet
    *                 anyone (use with caution)

  Common options:
    rw          read-write access
    ro          read-only access
    sync        write to disk before responding (safer, slower)
    async       respond before writing (faster, less safe)
    no_root_squash  allow root on the client to act as root on the share
                    (default is root_squash: root becomes 'nobody')

After editing /etc/exports:
  exportfs -av       apply changes without restarting nfs-server
  exportfs -r        re-export all directories (refresh)

────────────────────────────────────────────
TASK: Configure and start the NFS server

Requirements:
  • Add this line to /etc/exports:
      /srv/lab29nfs  localhost(rw,sync,no_root_squash)
  • Enable and start nfs-server
  • Run exportfs -av to apply the export
  • Verify with: showmount -e localhost

Commands you might need:
  • echo '/srv/lab29nfs  localhost(rw,sync,no_root_squash)' >> /etc/exports
  • systemctl enable --now nfs-server
  • exportfs -av
  • showmount -e localhost
EOF
}

validate_step_1() {
    # Check /etc/exports has the entry
    if ! grep -q "lab29nfs" /etc/exports 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /srv/lab29nfs not found in /etc/exports"
        echo "  Fix: echo '/srv/lab29nfs  localhost(rw,sync,no_root_squash)' >> /etc/exports"
        return 1
    fi

    # Check nfs-server is running
    if ! systemctl is-active nfs-server >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ nfs-server is not running"
        echo "  Fix: systemctl enable --now nfs-server && exportfs -av"
        return 1
    fi

    # Check it's actually exported
    if ! showmount -e localhost 2>/dev/null | grep -q "lab29nfs"; then
        echo ""
        print_color "$RED" "✗ /srv/lab29nfs is not showing in showmount output"
        echo "  Fix: exportfs -av"
        return 1
    fi

    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
echo '/srv/lab29nfs  localhost(rw,sync,no_root_squash)' >> /etc/exports
systemctl enable --now nfs-server
exportfs -av
showmount -e localhost
# → Export list for localhost:
# → /srv/lab29nfs localhost

One thing to remember:
  exportfs -av applies the /etc/exports changes to the running nfs-server
  without a full service restart. The 'a' means all exports, 'v' is verbose.
  You still need nfs-server running first — exportfs doesn't start it.

  no_root_squash is needed here because we're mounting as root on the
  same machine. Without it, the root user on the client gets mapped to the
  unprivileged 'nobody' user on the server, which can cause permission issues.
  In production, evaluate whether this is appropriate for your security model.

Verification:
  showmount -e localhost
  cat /var/lib/nfs/etab   (shows active NFS exports with full options)

EOF
}

hint_step_2() {
    echo "  mount localhost:/srv/lab29nfs /mnt/lab29a"
    echo "  ls /mnt/lab29a"
    echo "  umount /mnt/lab29a"
}

# STEP 2: Manual mount
show_step_2() {
    cat << 'EOF'
CONCEPT: Mounting NFS Shares Manually
──────────────────────────────────────
Before setting up autofs, always verify the NFS share works with a manual
mount. If the manual mount fails, autofs will fail too — and manual mount
gives clearer error messages.

NFS mount syntax:
  mount server:/remote/path /local/mount/point
  mount -t nfs server:/path /mnt   (explicit filesystem type)
  mount -o rw,vers=4 server:/path /mnt  (with options)

  server can be a hostname or IP address.
  For this lab: localhost or 127.0.0.1

After mounting:
  mount | grep nfsfiles  (confirm it's in the mount table)
  df -h /mnt/lab29a      (show mount info)

──────────────────────────────────────────────────────
TASK: Manually mount and verify the NFS share

Requirements:
  • Mount localhost:/srv/lab29nfs to /mnt/lab29a
  • Read the files inside to confirm they come from the NFS server
  • Unmount /mnt/lab29a when done (autofs will manage this going forward)

Commands you might need:
  • mount localhost:/srv/lab29nfs /mnt/lab29a
  • ls -l /mnt/lab29a
  • cat /mnt/lab29a/lab-content.txt
  • mount | grep lab29a
  • umount /mnt/lab29a
EOF
}

validate_step_2() {
    # This step is observational — we just check that autofs isn't in the way
    # The real validation for the NFS work is in step 3/4
    # We verify they at least attempted the mount by checking if nfs-server is up
    if ! systemctl is-active nfs-server >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ nfs-server is not running — complete step 1 first"
        return 1
    fi
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
mount localhost:/srv/lab29nfs /mnt/lab29a
ls -l /mnt/lab29a
# → lab-content.txt  readme.txt

cat /mnt/lab29a/lab-content.txt
# → NFS lab file — served from localhost

mount | grep lab29a
# → localhost:/srv/lab29nfs on /mnt/lab29a type nfs4 (rw,...)

umount /mnt/lab29a

One thing to remember:
  If the mount command hangs, NFS is not reachable. Check:
    systemctl status nfs-server
    showmount -e localhost
    firewall-cmd --list-services  (nfs should be allowed if firewall is active)
  
  On RHEL, firewalld blocks NFS by default. For this lab on localhost,
  it should work without firewall changes because localhost traffic
  bypasses zone rules. On a separate client machine, you would need:
    firewall-cmd --add-service=nfs --permanent
    firewall-cmd --reload

Verification:
  # After umount, nothing should show for lab29a:
  mount | grep lab29a    # → (empty)

EOF
}

hint_step_3() {
    echo "  /etc/auto.master: add line:  /data  /etc/auto.lab29a"
    echo "  /etc/auto.lab29a: add line:  nfsfiles  -rw  localhost:/srv/lab29nfs"
    echo "  systemctl restart autofs"
    echo "  ls /data/nfsfiles   (triggers the mount)"
}

# STEP 3: autofs configuration
show_step_3() {
    cat << 'EOF'
CONCEPT: autofs — Two-File Configuration
──────────────────────────────────────────
autofs uses two layers of configuration:

  /etc/auto.master  → the master map: tells autofs WHICH directories to manage
  /etc/auto.*       → detail map files: tells autofs WHAT to mount where

auto.master format:
  /managed/dir    /etc/auto.mapfile   [options]

  /data            the directory autofs will manage
  /etc/auto.lab29a  the file that defines what gets mounted inside /data

auto.lab29a (the map file) format:
  mountpoint   options   server:/remote/path

  nfsfiles    -rw    localhost:/srv/lab29nfs

  This means: when /data/nfsfiles is accessed, mount localhost:/srv/lab29nfs
  there with read-write permissions.

Important behaviour:
  • /data itself must exist, but /data/nfsfiles does NOT need to exist —
    autofs creates and manages the subdirectory automatically.
  • Accessing /data/nfsfiles triggers the mount (ls, cd, cat a file)
  • After a timeout (default 5 minutes idle), autofs unmounts it again

Check /etc/auto.misc for example syntax — this file ships with autofs
and is the fastest reference during an exam.

──────────────────────────────────────────────────────
TASK: Configure autofs to manage /data/nfsfiles

Requirements:
  • Add to /etc/auto.master:   /data   /etc/auto.lab29a
  • Create /etc/auto.lab29a with: nfsfiles  -rw  localhost:/srv/lab29nfs
  • Enable and restart autofs
  • Access /data/nfsfiles to trigger the mount

Commands you might need:
  • echo '/data  /etc/auto.lab29a' >> /etc/auto.master
  • echo 'nfsfiles  -rw  localhost:/srv/lab29nfs' > /etc/auto.lab29a
  • systemctl enable --now autofs
  • systemctl restart autofs
  • ls /data/nfsfiles    (triggers mount)
EOF
}

validate_step_3() {
    # Check auto.master has the entry
    if ! grep -q "auto.lab29a" /etc/auto.master 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /etc/auto.master does not reference /etc/auto.lab29a"
        echo "  Fix: echo '/data  /etc/auto.lab29a' >> /etc/auto.master"
        return 1
    fi

    # Check map file exists and has the entry
    if [ ! -f /etc/auto.lab29a ]; then
        echo ""
        print_color "$RED" "✗ /etc/auto.lab29a does not exist"
        echo "  Fix: echo 'nfsfiles  -rw  localhost:/srv/lab29nfs' > /etc/auto.lab29a"
        return 1
    fi

    if ! grep -q "lab29nfs" /etc/auto.lab29a 2>/dev/null; then
        echo ""
        print_color "$RED" "✗ /etc/auto.lab29a does not contain the nfsfiles entry"
        echo "  Fix: echo 'nfsfiles  -rw  localhost:/srv/lab29nfs' > /etc/auto.lab29a"
        return 1
    fi

    # Check autofs is running
    if ! systemctl is-active autofs >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ autofs is not running"
        echo "  Fix: systemctl restart autofs"
        return 1
    fi

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
# Add to auto.master (append so existing entries are preserved):
echo '/data  /etc/auto.lab29a' >> /etc/auto.master

# Create the map file:
echo 'nfsfiles  -rw  localhost:/srv/lab29nfs' > /etc/auto.lab29a

# Start/restart autofs:
systemctl enable --now autofs
# or if already running:
systemctl restart autofs

# Trigger the mount by accessing the path:
ls /data/nfsfiles

One thing to remember:
  The managed directory (/data) must exist before autofs can use it.
  The subdirectory (/data/nfsfiles) must NOT exist — autofs creates and
  manages it. If you manually mkdir /data/nfsfiles, autofs will refuse
  to mount there (it protects existing directories).

  The map file path (/etc/auto.lab29a) can be named anything. The name
  after /etc/auto. is just convention. What matters is that auto.master
  references the correct path.

  For the home directory wildcard pattern (lesson 29.4):
    *    -rw    nfsserver:/home/ldap/&
    The * matches any user, & substitutes the matched value.
    So accessing /home/alice triggers a mount of nfsserver:/home/ldap/alice

Verification:
  cat /etc/auto.master | grep lab29a
  cat /etc/auto.lab29a

EOF
}

hint_step_4() {
    echo "  ls /data/nfsfiles   (triggers the autofs mount)"
    echo "  mount | grep nfsfiles   (confirms it mounted)"
    echo "  cat /data/nfsfiles/lab-content.txt"
}

# STEP 4: Verify autofs mount
show_step_4() {
    cat << 'EOF'
TASK: Verify the autofs mount is working

Access /data/nfsfiles to trigger the automount, then confirm the mount
happened and that the NFS content is accessible.

Requirements:
  • Access /data/nfsfiles (ls, cd, or cat a file)
  • Run mount | grep nfsfiles to confirm it is mounted
  • Read /data/nfsfiles/lab-content.txt — content should match the server file
  • Run systemctl status autofs to see autofs activity

Commands you might need:
  • ls /data/nfsfiles
  • mount | grep nfsfiles
  • cat /data/nfsfiles/lab-content.txt
  • systemctl status autofs
EOF
}

validate_step_4() {
    # Trigger the mount
    ls /data/nfsfiles >/dev/null 2>&1 || true
    sleep 2

    # Check if the mount happened
    if mount | grep -q "nfsfiles"; then
        return 0
    fi

    # Try to diagnose
    echo ""
    if ! systemctl is-active autofs >/dev/null 2>&1; then
        print_color "$RED" "✗ autofs is not running"
        echo "  Fix: systemctl restart autofs"
    elif ! grep -q "auto.lab29a" /etc/auto.master 2>/dev/null; then
        print_color "$RED" "✗ /etc/auto.master does not reference auto.lab29a"
    elif ! systemctl is-active nfs-server >/dev/null 2>&1; then
        print_color "$RED" "✗ nfs-server is not running — autofs cannot mount from it"
        echo "  Fix: systemctl start nfs-server && exportfs -av"
    else
        print_color "$RED" "✗ /data/nfsfiles did not mount after access"
        echo "  Try: systemctl restart autofs && ls /data/nfsfiles"
        echo "  Check logs: journalctl -u autofs | tail -20"
    fi
    return 1
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
ls /data/nfsfiles
# → lab-content.txt  readme.txt   (triggers mount)

mount | grep nfsfiles
# → localhost:/srv/lab29nfs on /data/nfsfiles type nfs4 (rw,...)

cat /data/nfsfiles/lab-content.txt
# → NFS lab file — served from localhost

systemctl status autofs
# → Active: active (running)
# Look for mount activity in the journal: journalctl -u autofs -f

One thing to remember:
  If /data/nfsfiles appears empty even after access, autofs may have
  failed silently. Check: journalctl -u autofs | tail -30
  Common causes:
    - nfs-server not running
    - Wrong path in auto.lab29a
    - autofs not restarted after editing auto.master

  autofs vs /etc/fstab for NFS:
    fstab: mount at boot, always present, fails boot if server unreachable
    autofs: mount on demand, server unreachable = just an error when accessed
    For home dirs on a network: always autofs. For critical data mounts:
    fstab with nofail option if the server might be unavailable.

Verification:
  mount | grep nfsfiles   # → shows the active mount
  cat /data/nfsfiles/lab-content.txt  # → server content is readable

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=3

    echo "Checking your NFS and autofs configuration..."
    echo ""

    print_color "$CYAN" "[1/$total] Checking NFS server export is active..."
    if systemctl is-active nfs-server >/dev/null 2>&1 && \
       showmount -e localhost 2>/dev/null | grep -q "lab29nfs"; then
        print_color "$GREEN" "  ✓ nfs-server running and /srv/lab29nfs exported"
        ((score++))
    else
        ! systemctl is-active nfs-server >/dev/null 2>&1 && \
            print_color "$RED" "  ✗ nfs-server is not running"
        ! showmount -e localhost 2>/dev/null | grep -q "lab29nfs" && \
            print_color "$RED" "  ✗ /srv/lab29nfs not showing in exports"
        print_color "$YELLOW" "  Fix: systemctl enable --now nfs-server && exportfs -av"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking autofs configuration files..."
    if grep -q "auto.lab29a" /etc/auto.master 2>/dev/null && \
       [ -f /etc/auto.lab29a ] && \
       grep -q "lab29nfs" /etc/auto.lab29a 2>/dev/null && \
       systemctl is-active autofs >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ auto.master and auto.lab29a correctly configured; autofs running"
        ((score++))
    else
        ! grep -q "auto.lab29a" /etc/auto.master 2>/dev/null && \
            print_color "$RED" "  ✗ /etc/auto.master does not reference auto.lab29a"
        [ ! -f /etc/auto.lab29a ] && \
            print_color "$RED" "  ✗ /etc/auto.lab29a does not exist"
        ! systemctl is-active autofs >/dev/null 2>&1 && \
            print_color "$RED" "  ✗ autofs is not running"
        print_color "$YELLOW" "  Fix: see step 3 solution"
    fi
    echo ""

    print_color "$CYAN" "[3/$total] Verifying autofs mounts /data/nfsfiles on access..."
    ls /data/nfsfiles >/dev/null 2>&1 || true
    sleep 2
    if mount | grep -q "nfsfiles"; then
        print_color "$GREEN" "  ✓ /data/nfsfiles is mounted via autofs"
        ((score++))
    else
        print_color "$RED" "  ✗ /data/nfsfiles did not mount on access"
        print_color "$YELLOW" "  Check: journalctl -u autofs | tail -20"
        print_color "$YELLOW" "  Fix: systemctl restart autofs && ls /data/nfsfiles"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "NFS server and autofs configured successfully."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above. Run with --solution for detailed steps."
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
COMPLETE SOLUTION REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — Configure NFS server:
  echo '/srv/lab29nfs  localhost(rw,sync,no_root_squash)' >> /etc/exports
  systemctl enable --now nfs-server
  exportfs -av
  showmount -e localhost   # → /srv/lab29nfs localhost

STEP 2 — Manual NFS mount (verify it works):
  mount localhost:/srv/lab29nfs /mnt/lab29a
  ls /mnt/lab29a             # → lab-content.txt  readme.txt
  cat /mnt/lab29a/lab-content.txt
  umount /mnt/lab29a

STEP 3 — Configure autofs:
  echo '/data  /etc/auto.lab29a' >> /etc/auto.master
  echo 'nfsfiles  -rw  localhost:/srv/lab29nfs' > /etc/auto.lab29a
  systemctl restart autofs
  ls /data/nfsfiles           # triggers the mount

STEP 4 — Verify:
  mount | grep nfsfiles       # → mounted
  cat /data/nfsfiles/lab-content.txt


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

autofs Configuration Summary:
  /etc/auto.master:
    /managed/dir    /etc/auto.mapfile
    /data           /etc/auto.lab29a

  /etc/auto.lab29a:
    mountpoint      options         server:/path
    nfsfiles        -rw             localhost:/srv/lab29nfs

  Result: accessing /data/nfsfiles mounts localhost:/srv/lab29nfs there.

Home Directory Wildcard Pattern (lesson 29.4):
  In /etc/auto.master:
    /home/ldap      /etc/auto.ldaphome
  In /etc/auto.ldaphome:
    *               -rw             nfsserver:/home/ldap/&

  The * matches ANY name accessed under /home/ldap.
  The & in the server path substitutes the matched name.
  Accessing /home/ldap/alice mounts nfsserver:/home/ldap/alice.

/etc/auto.misc — Built-in Syntax Reference:
  This file ships with autofs and contains commented examples.
  On the exam, cat /etc/auto.misc for a quick syntax reminder.


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. /etc/auto.master → which dirs autofs manages; /etc/auto.* → what mounts where
2. The autofs subdirectory must NOT pre-exist — autofs creates and owns it
3. Always restart autofs after editing auto.master or map files
4. Manual mount first to confirm NFS works before debugging autofs
5. showmount -e server confirms what the server is exporting
6. journalctl -u autofs is your first stop when autofs isn't mounting
7. cat /etc/auto.misc for syntax examples during the exam

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    # Unmount if mounted
    umount /data/nfsfiles 2>/dev/null || true

    # Stop autofs
    systemctl stop autofs 2>/dev/null || true

    # Remove autofs config entries
    sed -i '/auto.lab29a/d' /etc/auto.master 2>/dev/null || true
    rm -f /etc/auto.lab29a 2>/dev/null || true

    # Remove NFS export
    sed -i '/lab29nfs/d' /etc/exports 2>/dev/null || true
    exportfs -av 2>/dev/null || true

    # Remove lab directories
    rm -rf /srv/lab29nfs 2>/dev/null || true
    rm -rf /mnt/lab29a 2>/dev/null || true

    echo "  ✓ NFS export removed"
    echo "  ✓ autofs config cleaned up"
    echo "  ✓ Lab directories removed"
    echo ""
    echo "  NOTE: nfs-server service was left in its pre-lab state."
    echo "  If it was not running before this lab, stop it:"
    echo "    systemctl disable --now nfs-server"
}

main "$@"
