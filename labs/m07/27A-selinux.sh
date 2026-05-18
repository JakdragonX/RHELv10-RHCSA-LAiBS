#!/bin/bash
# labs/27A-selinux.sh
# Lab: SELinux File Contexts, Booleans, and Troubleshooting
# Difficulty: Intermediate
# RHCSA Objective: List and identify SELinux file and process contexts;
#                  restore default file contexts; manage SELinux booleans

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

LAB_NAME="SELinux File Contexts, Booleans, and Troubleshooting"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="25-30 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."

    # Ensure SELinux tools are available
    if ! rpm -q policycoreutils-python-utils >/dev/null 2>&1; then
        echo "  Installing SELinux management tools..."
        dnf install -y policycoreutils-python-utils >/dev/null 2>&1 || true
    fi

    # Clean up any previous lab attempt
    rm -rf /tmp/lab27a 2>/dev/null || true
    rm -rf /var/www/html/lab27a 2>/dev/null || true

    # Create a directory outside the web root to simulate a misconfigured file
    mkdir -p /tmp/lab27a
    echo "lab SELinux test content" > /tmp/lab27a/index.html

    # Create the target directory in the web root (correct location)
    mkdir -p /var/www/html/lab27a

    # Remove any previous semanage fcontext entry for our path
    semanage fcontext -d "/var/www/html/lab27a(/.*)?" 2>/dev/null || true

    echo "  ✓ Created /tmp/lab27a/index.html (wrong SELinux context)"
    echo "  ✓ Created /var/www/html/lab27a/ (correct web root location)"
    echo "  ✓ System ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • That SELinux enforces mandatory access control via context labels
  • Basic understanding of what a web server (httpd) does and where it serves files

The Three-Part Context Label:
  Every file, process, and port has a label in the format:
    user:role:type

  For the RHCSA, only the TYPE matters. You will see it everywhere:
    ls -Z /var/www/html        → httpd_sys_content_t
    ps -eZ | grep httpd        → httpd_t
    semanage port -l | grep http → http_port_t

  The SELinux policy contains rules like:
    "allow httpd_t httpd_sys_content_t : file { read open getattr }"
  This means: the httpd process (type httpd_t) is allowed to read files
  labeled httpd_sys_content_t. If your web file has the wrong type, httpd
  cannot read it — even if Unix permissions are correct.

Commands You'll Use:
  • ls -Z              - Show SELinux context of files
  • ps -eZ             - Show SELinux context of processes
  • getenforce         - Show current SELinux mode (Enforcing/Permissive)
  • setenforce 0/1     - Switch between Permissive and Enforcing (runtime)
  • restorecon         - Restore file context to what the policy says it should be
  • semanage fcontext  - Set the policy rule for what context a path should have
  • getsebool / setsebool - Read and set boolean switches
  • semanage boolean -l  - List booleans with descriptions

Files You'll Interact With:
  • /etc/sysconfig/selinux     - Persistent SELinux mode (Enforcing/Permissive/Disabled)
  • /var/log/audit/audit.log   - Raw SELinux denial messages (AVC entries)
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
A web file was created in /tmp/lab27a/ instead of /var/www/html/lab27a/.
When it gets copied to the web root, httpd will refuse to serve it because
the file carries the wrong SELinux context from /tmp. You need to fix the
context, enable a related boolean, and understand the troubleshooting workflow.

OBJECTIVES:
  1. Inspect SELinux contexts. Use ls -Z to compare the context of files in
     /tmp/lab27a/ versus files in /var/www/html/. Note the difference in
     the type field. Run getenforce to confirm SELinux is Enforcing.

  2. Copy /tmp/lab27a/index.html to /var/www/html/lab27a/. Check its context
     with ls -Z — it will have the wrong context from /tmp (user_tmp_t or
     similar). Use restorecon to fix it to httpd_sys_content_t.
     Verify the context is now correct.

  3. Use semanage fcontext to add a persistent policy rule so that anything
     placed in /var/www/html/lab27a/ always gets the correct context:
       semanage fcontext -a -t httpd_sys_content_t "/var/www/html/lab27a(/.*)?"
     Then run restorecon -Rv /var/www/html/lab27a/ to apply the rule.

  4. Find and enable the SELinux boolean that allows httpd to connect to the
     network (httpd_can_network_connect). Use getsebool to check its current
     state, then enable it persistently with setsebool -P.

HINTS:
  • ls -Z file      shows context; the type is the third field after the colons
  • restorecon -v   shows what it changed; -R makes it recursive
  • semanage fcontext -l | grep /var/www  shows the current policy rules for web paths
  • setsebool -P makes the boolean change persistent across reboots; without -P it resets
  • semanage boolean -l | grep httpd_can_network_connect shows the boolean description

SUCCESS CRITERIA:
  • /var/www/html/lab27a/index.html has context type httpd_sys_content_t
  • A semanage fcontext rule exists for /var/www/html/lab27a
  • httpd_can_network_connect boolean is set to on
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. ls -Z /tmp/lab27a/ vs /var/www/html/ — note the type difference; getenforce
  ☐ 2. Copy index.html to web root; restorecon to fix context to httpd_sys_content_t
  ☐ 3. semanage fcontext -a for /var/www/html/lab27a; restorecon -Rv to apply
  ☐ 4. getsebool httpd_can_network_connect; setsebool -P httpd_can_network_connect on
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
A web file was created in the wrong location and carries the wrong SELinux
context. You need to fix it with restorecon, make the fix persistent with
semanage fcontext, and enable a boolean for httpd network access.
EOF
}

# STEP 1: Inspect contexts
show_step_1() {
    cat << 'EOF'
CONCEPT: Reading SELinux Context Labels
───────────────────────────────────────
Add -Z to most commands to see SELinux context:
  ls -Z /var/www/html
  # Output: system_u:object_r:httpd_sys_content_t:s0 index.html
  #                           ^^^^^^^^^^^^^^^^^^^^
  #                           This is the TYPE — the only part that matters

  ps -eZ | grep httpd
  # Output: system_u:system_r:httpd_t:s0   httpd
  #                           ^^^^^^
  #                           The httpd process runs as type httpd_t

The policy rule connecting them:
  httpd_t (the process) is allowed to read httpd_sys_content_t (the files)
  If the file has a different type, httpd cannot read it.

───────────────────────────────────────
TASK: Compare contexts and check SELinux mode

Requirements:
  • Run ls -Z /tmp/lab27a/   and note the type (likely user_tmp_t)
  • Run ls -Z /var/www/html/ and note the type (httpd_sys_content_t)
  • Run getenforce to confirm mode is Enforcing

Commands you might need:
  • ls -Z /tmp/lab27a/
  • ls -Z /var/www/html/
  • getenforce
  • cat /etc/sysconfig/selinux   (shows persistent mode setting)
EOF
}

validate_step_1() {
    # Observational — verify SELinux is enforcing and tools work
    if ! getenforce | grep -qi "enforcing"; then
        echo ""
        print_color "$RED" "✗ SELinux is not in Enforcing mode (got: $(getenforce))"
        echo "  This lab requires Enforcing mode: setenforce 1"
        return 1
    fi
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
ls -Z /tmp/lab27a/
# → unconfined_u:object_r:user_tmp_t:s0 index.html
#                          ^^^^^^^^^^^^
#                          Wrong type — httpd cannot read this

ls -Z /var/www/html/
# → system_u:object_r:httpd_sys_content_t:s0 (existing files)
#                      ^^^^^^^^^^^^^^^^^^^^
#                      Correct type for web content

getenforce
# → Enforcing

cat /etc/sysconfig/selinux | grep ^SELINUX=
# → SELINUX=enforcing   (persistent setting; survives reboot)

Key distinction between modes:
  Enforcing:  SELinux actively blocks denials AND logs them
  Permissive: SELinux only logs denials, does NOT block — useful for testing
  Disabled:   SELinux is off entirely (requires reboot to change; avoid this)

  setenforce 0  → switch to Permissive right now (runtime only)
  setenforce 1  → switch to Enforcing right now (runtime only)
  /etc/sysconfig/selinux → set SELINUX= for persistent mode after reboot

EOF
}

hint_step_2() {
    echo "  cp /tmp/lab27a/index.html /var/www/html/lab27a/"
    echo "  ls -Z /var/www/html/lab27a/   (note the wrong context)"
    echo "  restorecon -v /var/www/html/lab27a/index.html"
}

# STEP 2: restorecon
show_step_2() {
    cat << 'EOF'
CONCEPT: restorecon — Restoring the Correct Context
────────────────────────────────────────────────────
When a file is copied, it inherits the context of its SOURCE. When a file
is moved, it keeps its original context. Either way, the result can be
a file with the wrong context for its new location.

restorecon reads the SELinux policy to find what context the file SHOULD
have based on its path, then applies that context:

  restorecon -v /path/to/file    # fix one file (-v = verbose, shows changes)
  restorecon -Rv /path/to/dir/   # fix everything recursively in a directory

Important: restorecon only works if a policy rule exists for that path.
For standard locations like /var/www/html, the rules are already in the
default policy. For custom directories, you need semanage fcontext first
(covered in step 3).

────────────────────────────────────────────────────
TASK: Copy the file and fix its context with restorecon

Requirements:
  • Copy /tmp/lab27a/index.html to /var/www/html/lab27a/
  • Run ls -Z to observe the wrong context it inherited from /tmp
  • Run restorecon -v on the file to correct it
  • Verify with ls -Z that it now shows httpd_sys_content_t

Commands you might need:
  • cp /tmp/lab27a/index.html /var/www/html/lab27a/
  • ls -Z /var/www/html/lab27a/index.html
  • restorecon -v /var/www/html/lab27a/index.html
  • ls -Z /var/www/html/lab27a/index.html   (verify)
EOF
}

validate_step_2() {
    if [ ! -f /var/www/html/lab27a/index.html ]; then
        echo ""
        print_color "$RED" "✗ /var/www/html/lab27a/index.html does not exist"
        echo "  Fix: cp /tmp/lab27a/index.html /var/www/html/lab27a/"
        return 1
    fi

    local context
    context=$(ls -Z /var/www/html/lab27a/index.html 2>/dev/null | awk '{print $1}')
    if ! echo "$context" | grep -q "httpd_sys_content_t"; then
        echo ""
        print_color "$RED" "✗ File context is '$context' (expected httpd_sys_content_t)"
        echo "  Fix: restorecon -v /var/www/html/lab27a/index.html"
        return 1
    fi

    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
cp /tmp/lab27a/index.html /var/www/html/lab27a/

ls -Z /var/www/html/lab27a/index.html
# → unconfined_u:object_r:user_tmp_t:s0  index.html  (wrong — inherited from /tmp)

restorecon -v /var/www/html/lab27a/index.html
# → Relabeled /var/www/html/lab27a/index.html from ... user_tmp_t ... to ... httpd_sys_content_t

ls -Z /var/www/html/lab27a/index.html
# → system_u:object_r:httpd_sys_content_t:s0  index.html  (correct)

One thing to remember:
  copy = inherits destination directory's context? NO — it inherits source context.
  move = keeps original context.
  In both cases, restorecon fixes it.

  Alternatively: cp --preserve=context copies AND preserves the source context,
  which is the wrong behaviour here. The default cp without that flag is actually
  what causes the problem in the first place.

EOF
}

hint_step_3() {
    echo "  semanage fcontext -a -t httpd_sys_content_t \"/var/www/html/lab27a(/.*)?\" "
    echo "  restorecon -Rv /var/www/html/lab27a/"
    echo "  semanage fcontext -l -C   (shows only your custom changes)"
}

# STEP 3: semanage fcontext
show_step_3() {
    cat << 'EOF'
CONCEPT: semanage fcontext — Making Context Rules Persistent
─────────────────────────────────────────────────────────────
restorecon reads from the SELinux policy database to know what context
to apply. semanage fcontext writes rules INTO that database.

The two-step workflow for a non-default directory:
  1. semanage fcontext -a -t TYPE "PATH_PATTERN"   → writes the rule
  2. restorecon -Rv /path/                          → applies the rule to disk

Without step 1, restorecon has no rule to follow for your custom path and
will either do nothing or apply a default that may still be wrong.

The path pattern uses regex:
  "/var/www/html/lab27a(/.*)?"
  means: the directory itself AND anything inside it (the /.*  part)

Useful semanage fcontext flags:
  -a     add a new rule
  -m     modify an existing rule
  -d     delete a rule
  -l     list all rules
  -l -C  list only rules that differ from the default (your changes)

─────────────────────────────────────────────────────────
TASK: Add a persistent context rule and apply it

Requirements:
  • Add a semanage fcontext rule for /var/www/html/lab27a and its contents
    using type httpd_sys_content_t
  • Run restorecon -Rv to apply the rule to the directory
  • Verify with semanage fcontext -l -C that your rule appears

Commands you might need:
  • semanage fcontext -a -t httpd_sys_content_t "/var/www/html/lab27a(/.*)?"
  • restorecon -Rv /var/www/html/lab27a/
  • semanage fcontext -l -C
  • semanage fcontext -l | grep lab27a
EOF
}

validate_step_3() {
    # Check semanage fcontext rule exists for the path
    if ! semanage fcontext -l 2>/dev/null | grep -q "lab27a"; then
        echo ""
        print_color "$RED" "✗ No semanage fcontext rule found for /var/www/html/lab27a"
        echo "  Fix: semanage fcontext -a -t httpd_sys_content_t \"/var/www/html/lab27a(/.*)?\" "
        return 1
    fi

    # Check the file still has the correct context after the rule was applied
    local context
    context=$(ls -Z /var/www/html/lab27a/index.html 2>/dev/null | awk '{print $1}')
    if ! echo "$context" | grep -q "httpd_sys_content_t"; then
        echo ""
        print_color "$RED" "✗ Context on index.html is still wrong after semanage — did you run restorecon?"
        echo "  Fix: restorecon -Rv /var/www/html/lab27a/"
        return 1
    fi

    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
semanage fcontext -a -t httpd_sys_content_t "/var/www/html/lab27a(/.*)?"
restorecon -Rv /var/www/html/lab27a/
semanage fcontext -l -C

One thing to remember:
  semanage fcontext only writes to the POLICY DATABASE — it does not
  touch the filesystem at all. restorecon reads the database and applies
  it to the actual files. You need both steps.

  The regex pattern /var/www/html/lab27a(/.*)? means:
    /var/www/html/lab27a     the directory itself
    (/.*)?                   optionally: a slash followed by anything
    This covers the dir and all files/subdirs inside it.

  To check what rule currently applies to a path:
    matchpathcon /var/www/html/lab27a/index.html
    # → the expected context according to policy

EOF
}

hint_step_4() {
    echo "  getsebool httpd_can_network_connect"
    echo "  setsebool -P httpd_can_network_connect on"
    echo "  -P makes it persistent; without -P it resets on reboot"
}

# STEP 4: Booleans
show_step_4() {
    cat << 'EOF'
CONCEPT: SELinux Booleans
──────────────────────────
Booleans are on/off switches that enable or disable specific parts of the
SELinux policy without writing custom rules. They're the first thing to
check when a standard service isn't working as expected.

List booleans:
  getsebool -a                      all booleans and current values
  getsebool httpd_can_network_connect   one specific boolean
  semanage boolean -l               list with descriptions (more useful)
  semanage boolean -l -C            list only non-default settings

Set a boolean:
  setsebool httpd_can_network_connect on     runtime only (resets on reboot)
  setsebool -P httpd_can_network_connect on  persistent (writes to policy)

Always use -P unless you're just testing temporarily.

──────────────────────────────────────────────────────────
TASK: Check and enable the httpd_can_network_connect boolean

Requirements:
  • Check its current state with getsebool
  • Read its description with: semanage boolean -l | grep httpd_can_network_connect
  • Enable it persistently with setsebool -P
  • Verify it is now on with getsebool

Commands you might need:
  • getsebool httpd_can_network_connect
  • semanage boolean -l | grep httpd_can_network
  • setsebool -P httpd_can_network_connect on
  • getsebool httpd_can_network_connect
EOF
}

validate_step_4() {
    local val
    val=$(getsebool httpd_can_network_connect 2>/dev/null | awk '{print $NF}')

    if [ "$val" = "on" ]; then
        return 0
    fi

    echo ""
    print_color "$RED" "✗ httpd_can_network_connect is '$val' (expected on)"
    echo "  Fix: setsebool -P httpd_can_network_connect on"
    return 1
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────
getsebool httpd_can_network_connect
# → httpd_can_network_connect --> off

semanage boolean -l | grep httpd_can_network_connect
# → httpd_can_network_connect  (off  ,  off)  Allow httpd to connect to the network

setsebool -P httpd_can_network_connect on

getsebool httpd_can_network_connect
# → httpd_can_network_connect --> on

One thing to remember:
  -P writes the setting to /etc/selinux/targeted/modules/active/booleans.local
  Without -P, the setting lives only in memory and reverts on reboot.
  On the exam, always use -P unless the question specifically says "runtime only".

  semanage boolean -l -C shows only booleans you've changed from their default.
  Useful for auditing what you've modified on a system.

EOF
}

#############################################################################
# VALIDATION (Standard Mode)
#############################################################################
validate() {
    local score=0
    local total=3

    echo "Checking your SELinux configuration..."
    echo ""

    print_color "$CYAN" "[1/$total] Checking /var/www/html/lab27a/index.html has httpd_sys_content_t..."
    if [ -f /var/www/html/lab27a/index.html ]; then
        local ctx
        ctx=$(ls -Z /var/www/html/lab27a/index.html 2>/dev/null | awk '{print $1}')
        if echo "$ctx" | grep -q "httpd_sys_content_t"; then
            print_color "$GREEN" "  ✓ Context: $ctx"
            ((score++))
        else
            print_color "$RED" "  ✗ Context is '$ctx' (expected httpd_sys_content_t)"
            print_color "$YELLOW" "  Fix: restorecon -v /var/www/html/lab27a/index.html"
        fi
    else
        print_color "$RED" "  ✗ /var/www/html/lab27a/index.html does not exist"
        print_color "$YELLOW" "  Fix: cp /tmp/lab27a/index.html /var/www/html/lab27a/"
    fi
    echo ""

    print_color "$CYAN" "[2/$total] Checking semanage fcontext rule exists for /var/www/html/lab27a..."
    if semanage fcontext -l 2>/dev/null | grep -q "lab27a"; then
        print_color "$GREEN" "  ✓ semanage fcontext rule found for lab27a"
        ((score++))
    else
        print_color "$RED" "  ✗ No semanage fcontext rule for /var/www/html/lab27a"
        print_color "$YELLOW" "  Fix: semanage fcontext -a -t httpd_sys_content_t \"/var/www/html/lab27a(/.*)?\" "
    fi
    echo ""

    print_color "$CYAN" "[3/$total] Checking httpd_can_network_connect boolean is on..."
    local bval
    bval=$(getsebool httpd_can_network_connect 2>/dev/null | awk '{print $NF}')
    if [ "$bval" = "on" ]; then
        print_color "$GREEN" "  ✓ httpd_can_network_connect is on"
        ((score++))
    else
        print_color "$RED" "  ✗ httpd_can_network_connect is '$bval'"
        print_color "$YELLOW" "  Fix: setsebool -P httpd_can_network_connect on"
    fi
    echo ""

    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"

    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "SELinux context management and booleans configured correctly."
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

STEP 1 — Inspect contexts:
  ls -Z /tmp/lab27a/          # → user_tmp_t  (wrong for web content)
  ls -Z /var/www/html/        # → httpd_sys_content_t  (correct)
  getenforce                  # → Enforcing

STEP 2 — Copy and fix with restorecon:
  cp /tmp/lab27a/index.html /var/www/html/lab27a/
  ls -Z /var/www/html/lab27a/index.html   # shows wrong context (inherited from /tmp)
  restorecon -v /var/www/html/lab27a/index.html
  ls -Z /var/www/html/lab27a/index.html   # now shows httpd_sys_content_t

STEP 3 — Make context persistent with semanage:
  semanage fcontext -a -t httpd_sys_content_t "/var/www/html/lab27a(/.*)?"
  restorecon -Rv /var/www/html/lab27a/
  semanage fcontext -l -C                 # confirm your rule appears

STEP 4 — Enable boolean:
  getsebool httpd_can_network_connect     # check current state
  setsebool -P httpd_can_network_connect on
  getsebool httpd_can_network_connect     # confirm: on


TROUBLESHOOTING WORKFLOW (when SELinux might be blocking something)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Test if SELinux is the cause:
     setenforce 0    (switch to Permissive)
     <retry the operation>
     setenforce 1    (switch back to Enforcing)
   If it works in Permissive but not Enforcing: SELinux is the issue.

2. Find the denial in the audit log:
     grep AVC /var/log/audit/audit.log | tail -5
   AVC entries contain: the process context (scontext=), the file context
   (tcontext=), and the access that was denied (e.g. { read open }).

3. Get human-readable advice:
     grep AVC /var/log/audit/audit.log | tail -5 > /tmp/avc.log
     sealert -a /tmp/avc.log
   sealert reads the AVC messages and suggests the exact commands to fix it.

4. Also check:
     journalctl | grep sealert    (summary messages with fix suggestions)


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. semanage fcontext then restorecon — always this order, never reversed
2. Always use -P with setsebool for persistence
3. The type is the only context field that matters for RHCSA
4. copy = inherits source context; move = keeps original context
5. semanage fcontext -l -C and semanage boolean -l -C show only your changes
6. touch /.autorelabel → relabels the ENTIRE filesystem on next boot (nuclear option)

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."

    rm -rf /tmp/lab27a 2>/dev/null || true
    rm -rf /var/www/html/lab27a 2>/dev/null || true
    semanage fcontext -d "/var/www/html/lab27a(/.*)?" 2>/dev/null || true
    setsebool -P httpd_can_network_connect off 2>/dev/null || true

    echo "  ✓ Lab files removed"
    echo "  ✓ semanage fcontext rule removed"
    echo "  ✓ httpd_can_network_connect restored to off"
}

main "$@"
