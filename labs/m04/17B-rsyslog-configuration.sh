#!/bin/bash
# labs/m04/17B-rsyslog-configuration.sh
# Lab: Working with rsyslog
# Difficulty: Intermediate
# RHCSA Objective: 17.4 - Configuring rsyslog

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lab-runner.sh"

# Lab metadata
LAB_NAME="Working with rsyslog"
LAB_DIFFICULTY="Intermediate"
LAB_TIME_ESTIMATE="40-50 minutes"

#############################################################################
# SETUP
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # Ensure rsyslog is installed
    if ! rpm -q rsyslog >/dev/null 2>&1; then
        dnf install -y rsyslog >/dev/null 2>&1
    fi
    
    # Ensure rsyslog is running
    systemctl enable --now rsyslog >/dev/null 2>&1
    
    # Clean up any previous lab configurations
    rm -f /etc/rsyslog.d/lab-*.conf 2>/dev/null || true
    rm -f /var/log/lab-*.log 2>/dev/null || true
    
    # Restore rsyslog to default state
    systemctl restart rsyslog >/dev/null 2>&1
    
    # Generate some test log entries
    logger -p user.info "Lab 17B: Setup - Test INFO message"
    logger -p user.notice "Lab 17B: Setup - Test NOTICE message"
    logger -p user.warning "Lab 17B: Setup - Test WARNING message"
    logger -p user.err "Lab 17B: Setup - Test ERROR message"
    logger -p authpriv.info "Lab 17B: Setup - Auth info message"
    logger -p cron.info "Lab 17B: Setup - Cron info message"
    
    # Create a test application script that generates logs
    mkdir -p /opt/lab-rsyslog
    cat > /opt/lab-rsyslog/test-app.sh << 'EOF'
#!/bin/bash
# Test application that generates various log messages
while true; do
    logger -t lab-app -p local0.info "Application operational check"
    sleep 30
done
EOF
    chmod +x /opt/lab-rsyslog/test-app.sh
    
    echo "  ✓ rsyslog package installed"
    echo "  ✓ rsyslog service running"
    echo "  ✓ Previous lab configurations removed"
    echo "  ✓ Test log entries generated"
    echo "  ✓ Test application created"
    echo "  ✓ Environment ready"
}

#############################################################################
# PREREQUISITES
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • Understanding of syslog concepts (facilities and priorities)
  • Familiarity with log file locations
  • Basic text editing skills
  • Understanding of file permissions

Commands You'll Use:
  • logger - Generate syslog messages
  • systemctl - Manage rsyslog service
  • tail, grep - View and search log files
  • ls - List log files

Files You'll Interact With:
  • /etc/rsyslog.conf - Main rsyslog configuration
  • /etc/rsyslog.d/ - Drop-in configuration directory
  • /var/log/messages - General system log
  • /var/log/secure - Authentication log
  • /var/log/cron - Cron job log
  • /var/log/maillog - Mail system log

Key Concepts:
  • rsyslog uses facility and priority to route messages
  • Configuration uses facility.priority format
  • Multiple facilities can be combined
  • Log files are plain text (unlike journald)
  • rsyslog can forward logs to remote systems
  • Facilities identify message source (kern, mail, cron, etc.)
  • Priorities indicate severity (emerg through debug)

Reference Material:
  • man rsyslog.conf - Configuration format
  • man rsyslogd - The rsyslog daemon
  • man logger - Generate log messages
EOF
}

#############################################################################
# SCENARIO
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
You're managing a RHEL 10 server that runs multiple services and applications.
Different teams need access to specific log files for their services. You need
to configure rsyslog to separate logs by application, set up custom log files,
and ensure critical messages are captured separately.

BACKGROUND:
While journald handles binary logging, rsyslog provides traditional plain-text
logging with powerful filtering and routing capabilities. Understanding rsyslog
is essential for the RHCSA exam and is still widely used in production for its
simplicity, remote logging capabilities, and easy log parsing.

OBJECTIVES:
  1. Understand rsyslog configuration and default log routing
     • Examine /etc/rsyslog.conf structure
     • Understand facility.priority syntax
     • Identify where different log types go
     • Understand the relationship with journald
     • View current log files and their purposes
     
  2. Create custom log routing rules
     • Configure a custom log file for local0 facility
     • Route specific priorities to dedicated files
     • Configure mail-related logs to separate file
     • Test rules with logger command
     • Verify logs are being written correctly
     
  3. Implement advanced filtering and separation
     • Create a critical messages log (crit and higher)
     • Exclude specific facilities from general logs
     • Configure application-specific logging
     • Use multiple selectors in single rule
     • Understand rule precedence and processing
     
  4. Configure log file properties and test thoroughly
     • Set appropriate permissions on log files
     • Test all configured rules
     • Verify no messages are lost
     • Understand log file rotation integration
     • Generate test messages across all configurations

HINTS:
  • rsyslog.conf uses facility.priority action format
  • Facilities: kern, user, mail, daemon, auth, authpriv, cron, local0-7
  • Priorities: debug, info, notice, warning, err, crit, alert, emerg
  • Use semicolon to separate multiple rules
  • Use none to exclude a facility
  • Changes require rsyslog restart
  • Test with logger command

SUCCESS CRITERIA:
  • Understand rsyslog configuration syntax
  • Custom log files created and receiving messages
  • Critical messages separated to dedicated file
  • Application logs isolated from system logs
  • All rules tested and verified working
  • Log files have appropriate permissions
EOF
}

#############################################################################
# QUICK OBJECTIVES
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. Understand rsyslog configuration and default routing
  ☐ 2. Create custom log routing rules
  ☐ 3. Implement advanced filtering and separation
  ☐ 4. Configure log properties and test thoroughly
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT
#############################################################################

get_step_count() {
    echo "4"
}

scenario_context() {
    cat << 'EOF'
You're configuring rsyslog to separate logs by application and priority,
making it easier for different teams to find relevant information.
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: Understand rsyslog configuration and default log routing

Explore how rsyslog is configured and where different logs go by default.

Requirements:
  • Examine the main rsyslog configuration file
    - Understand the MODULES section
    - Understand the RULES section
    - Identify default log file destinations
  
  • Understand the facility.priority syntax
    - What facilities are available
    - What priorities are available
    - How the dot (.) operator works
  
  • Explore /var/log directory
    - Identify major log files
    - Understand which logs go where
    - View sample entries from different logs
  
  • Understand rsyslog's relationship with journald
    - How rsyslog receives messages from journald
    - Whether journald forwards to rsyslog or vice versa
  
  • Generate test messages and track them
    - Use logger to create messages
    - Find where they appear
    - Understand the routing logic

Questions to answer:
  • Where does rsyslog.conf define log routing?
  • What does "*.info;mail.none;authpriv.none;cron.none" mean?
  • Where do auth messages go by default?
  • Where do cron messages go by default?
  • How does rsyslog integrate with journald?

Files to examine:
  /etc/rsyslog.conf
  /etc/rsyslog.d/
  /var/log/messages
  /var/log/secure
  /var/log/cron
  /var/log/maillog

Research before starting:
  man rsyslog.conf (read the SELECTORS section)
  man logger (understand how to generate test messages)
EOF
}

validate_step_1() {
    # Exploratory step, always pass
    return 0
}

hint_step_1() {
    echo "  Main config: cat /etc/rsyslog.conf"
    echo "  Rules section: grep -A 20 '#### RULES ####' /etc/rsyslog.conf"
    echo "  List logs: ls -lh /var/log/"
    echo "  View log: tail /var/log/messages"
    echo "  Test logging: logger -p user.info 'Test message'"
    echo "  Find message: grep 'Test message' /var/log/messages"
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────

View main rsyslog configuration:
  cat /etc/rsyslog.conf

Or view without comments:
  grep -v "^#" /etc/rsyslog.conf | grep -v "^$"

Understanding the structure:

MODULES section:
  Loads input modules to receive log messages
  
  imjournal - Receives from systemd journal
  imuxsock  - Receives from local syslog socket
  imklog    - Receives from kernel (if enabled)

RULES section:
  Defines where different messages go
  Format: facility.priority   destination

Example rules from default config:

*.info;mail.none;authpriv.none;cron.none    /var/log/messages

Breaking this down:
  *.info           - All facilities, priority info and higher
  mail.none        - EXCEPT mail facility
  authpriv.none    - EXCEPT authpriv facility  
  cron.none        - EXCEPT cron facility
  /var/log/messages - Destination file

This means: Log everything at info level or higher to /var/log/messages,
but exclude mail, authpriv, and cron (they go elsewhere).

authpriv.*                                  /var/log/secure

Breaking this down:
  authpriv.*       - All authpriv messages, all priorities
  /var/log/secure  - Destination file

This means: All authentication messages go to /var/log/secure

mail.*                                      -/var/log/maillog

Breaking this down:
  mail.*           - All mail facility messages
  -/var/log/maillog - Destination (minus disables sync)

The "-" prefix means async writes (better performance).

cron.*                                      /var/log/cron

Breaking this down:
  cron.*           - All cron messages
  /var/log/cron    - Destination file

Understanding facility.priority syntax:

Facility (message source):
  kern     - Kernel messages
  user     - User-level messages
  mail     - Mail system
  daemon   - System daemons
  auth     - Authentication (deprecated, use authpriv)
  authpriv - Authentication and authorization
  syslog   - Syslog internal messages
  lpr      - Printer subsystem
  cron     - Cron daemon
  local0-7 - Reserved for custom use

Priority (severity level):
  emerg    - Emergency (0) - System unusable
  alert    - Alert (1) - Immediate action needed
  crit     - Critical (2) - Critical conditions
  err      - Error (3) - Error conditions
  warning  - Warning (4) - Warning conditions
  notice   - Notice (5) - Normal but significant
  info     - Info (6) - Informational
  debug    - Debug (7) - Debug messages

Priority operators:

.priority    - This priority and higher
.=priority   - Exactly this priority only
.!priority   - Not this priority
.*          - All priorities
.none       - No messages (exclude this facility)

Examples:

mail.err        - Mail errors and higher (err, crit, alert, emerg)
mail.=err       - Only mail errors
mail.!err       - Mail messages except errors
mail.*          - All mail messages
mail.none       - No mail messages (exclusion)

Exploring /var/log directory:

List log files:
  ls -lh /var/log/

Common log files:

/var/log/messages:
  General system log
  Most system messages go here
  Excludes mail, auth, cron

/var/log/secure:
  Authentication and authorization
  SSH logins, su, sudo
  User authentication failures

/var/log/cron:
  Cron job execution
  Scheduled task logs

/var/log/maillog:
  Mail system logs
  Postfix, sendmail, etc.

/var/log/boot.log:
  Boot process messages
  Startup services

View sample log entries:

/var/log/messages:
  tail /var/log/messages

Shows general system activity.

/var/log/secure:
  tail /var/log/secure

Shows authentication events.

/var/log/cron:
  tail /var/log/cron

Shows cron execution.

Understanding rsyslog and journald relationship:

Check rsyslog.conf for imjournal:
  grep imjournal /etc/rsyslog.conf

Shows:
  module(load="imjournal"
         StateFile="imjournal.state")

This means:
  - rsyslog reads from systemd journal
  - Journal is the primary collector
  - rsyslog processes journal entries
  - rsyslog writes to traditional log files

The flow:
  Applications/Services → journald → rsyslog → /var/log files

Generate test messages:

Test user facility:
  logger -p user.info "Test INFO message"
  logger -p user.warning "Test WARNING message"
  logger -p user.err "Test ERROR message"

Find them:
  grep "Test" /var/log/messages

All should appear because user.* goes to messages.

Test authpriv facility:
  logger -p authpriv.info "Test auth message"

Find it:
  grep "Test auth" /var/log/secure

Should appear in secure, NOT in messages.

Test cron facility:
  logger -p cron.info "Test cron message"

Find it:
  grep "Test cron" /var/log/cron

Should appear in cron log only.

Understanding rule precedence:

Rules are processed top to bottom.
First matching rule determines destination.

If you have:
  mail.err     /var/log/mail-errors.log
  mail.*       /var/log/maillog

Then:
  - Mail errors go to BOTH files
  - Other mail messages go only to maillog

Order matters for exclusions:
  *.info;mail.none   /var/log/messages
  mail.*             /var/log/maillog

This works correctly because mail is excluded from messages.

Checking drop-in configurations:

List drop-in files:
  ls /etc/rsyslog.d/

These are processed in alphabetical order.
Configuration can be split across multiple files.

Viewing active configuration:

Check syntax:
  rsyslogd -N1

Shows any configuration errors.

Verify rsyslog is running:
  systemctl status rsyslog

Should show active (running).

Key takeaways:

1. Facility identifies message source
2. Priority indicates severity
3. Rules route messages to files
4. Multiple selectors can be combined
5. Exclusions use .none
6. rsyslog receives from journald
7. Test with logger command

EOF
}

hint_step_2() {
    echo "  Create file: /etc/rsyslog.d/lab-custom.conf"
    echo "  Format: facility.priority  /path/to/logfile"
    echo "  Restart: systemctl restart rsyslog"
    echo "  Test: logger -p local0.info 'Test message'"
    echo "  Verify: tail /var/log/your-logfile.log"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: Create custom log routing rules

Configure rsyslog to route specific messages to custom log files.

Your mission:
  Create a new rsyslog configuration file that routes messages
  from the local0 facility to a dedicated log file.

Requirements:
  • Create a new configuration file in /etc/rsyslog.d/
    - Name it appropriately (e.g., lab-local0.conf)
    - Use proper rsyslog syntax
  
  • Configure routing for local0 facility
    - All local0 messages (all priorities)
    - Destination: /var/log/lab-local0.log
  
  • Configure routing for mail facility
    - All mail messages
    - Destination: /var/log/lab-mail.log
    - Ensure mail is excluded from /var/log/messages
  
  • Restart rsyslog service to apply changes
  
  • Test your configuration
    - Generate local0 test messages
    - Generate mail test messages  
    - Verify messages appear in correct files
    - Verify messages DON'T appear in wrong files

Configuration syntax:
  facility.priority    destination

Examples:
  local0.*             /var/log/myapp.log
  mail.warning         /var/log/mail-warnings.log

Important notes:
  • Configuration files in /etc/rsyslog.d/ should end in .conf
  • Rules are processed in alphabetical order
  • Test syntax before restarting: rsyslogd -N1
  • Always restart rsyslog after config changes
  • Log files are created automatically if they don't exist

Testing strategy:
  1. Create configuration
  2. Check syntax
  3. Restart service
  4. Generate test messages with logger
  5. Verify with tail and grep
  6. Check for errors in /var/log/messages
EOF
}

validate_step_2() {
    local failures=0
    
    # Check if custom config exists
    if ! ls /etc/rsyslog.d/lab-*.conf >/dev/null 2>&1; then
        echo ""
        print_color "$RED" "✗ No lab configuration file found in /etc/rsyslog.d/"
        echo "  Create a .conf file with your custom rules"
        ((failures++))
        return 1
    fi
    
    # Check for local0 rule
    local has_local0=false
    for conf in /etc/rsyslog.d/lab-*.conf; do
        if grep -q "local0\.\*.*\/var\/log\/.*\.log" "$conf" 2>/dev/null; then
            has_local0=true
            break
        fi
    done
    
    if ! $has_local0; then
        echo ""
        print_color "$RED" "✗ No local0 routing rule found"
        echo "  Add: local0.*  /var/log/lab-local0.log"
        ((failures++))
    fi
    
    # Generate test message and check if it appears
    logger -p local0.info "Lab 17B validation test - local0"
    sleep 1
    
    # Find any log file that should contain local0 messages
    local local0_log=$(grep -l "Lab 17B validation test - local0" /var/log/lab-*.log 2>/dev/null | head -1)
    
    if [ -z "$local0_log" ]; then
        echo ""
        print_color "$RED" "✗ Test message not found in any lab log file"
        echo "  Did you restart rsyslog?"
        echo "  Check: systemctl status rsyslog"
        ((failures++))
    else
        print_color "$GREEN" "  ✓ local0 messages being logged to $local0_log"
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────

Step 1: Create configuration file
──────────────────────────────────
Create new file in /etc/rsyslog.d/:
  sudo vi /etc/rsyslog.d/lab-custom.conf

Add the following rules:

# Custom log routing for lab

# Route all local0 messages to dedicated file
local0.*                                    /var/log/lab-local0.log

# Route all mail messages to dedicated file
mail.*                                      /var/log/lab-mail.log

Save and exit.

Step 2: Check syntax
────────────────────
Verify configuration is valid:
  sudo rsyslogd -N1

Should show:
  rsyslogd: version X, config validation run (level 1), master config /etc/rsyslog.conf
  rsyslogd: End of config validation run. Bye.

If errors appear, fix them before proceeding.

Step 3: Restart rsyslog
───────────────────────
Apply the configuration:
  sudo systemctl restart rsyslog

Verify service restarted successfully:
  systemctl status rsyslog

Should show: active (running)

If failed, check logs:
  journalctl -u rsyslog -n 20

Step 4: Test local0 routing
────────────────────────────
Generate test messages:
  logger -p local0.info "Test local0 INFO message"
  logger -p local0.warning "Test local0 WARNING message"
  logger -p local0.err "Test local0 ERROR message"

Verify they appear in correct file:
  tail /var/log/lab-local0.log

Should show your test messages.

Verify they DON'T appear in messages:
  grep "Test local0" /var/log/messages

Should return nothing (excluded by default).

Step 5: Test mail routing
──────────────────────────
Generate mail test messages:
  logger -p mail.info "Test mail INFO message"
  logger -p mail.err "Test mail ERROR message"

Verify in mail log:
  tail /var/log/lab-mail.log

Should show your test messages.

Also check default maillog:
  tail /var/log/maillog

Your messages should appear here too (mail.* in default config).

Understanding what you created:

Configuration file location:
  /etc/rsyslog.d/lab-custom.conf

Why this location:
  - /etc/rsyslog.conf includes files from /etc/rsyslog.d/
  - Keeps custom config separate from system config
  - Easier to manage and remove
  - Processed in alphabetical order

Rule 1: local0.*  /var/log/lab-local0.log

  local0.*         - All messages from local0 facility
  /var/log/...     - Destination file

This captures ALL local0 messages regardless of priority.

Rule 2: mail.*  /var/log/lab-mail.log

  mail.*           - All mail facility messages
  /var/log/...     - Destination file

Note: Mail messages now go to TWO files:
  1. /var/log/lab-mail.log (your custom config)
  2. /var/log/maillog (default config)

This is because both rules match mail messages.

Understanding message flow:

When logger generates local0.info:
  1. Message received by rsyslog
  2. Checked against all rules
  3. Matches: local0.* → /var/log/lab-local0.log
  4. Written to that file
  5. Processing continues
  6. No other rules match (local0 excluded from messages)

When logger generates mail.info:
  1. Message received by rsyslog
  2. Matches: mail.* → /var/log/lab-mail.log (written)
  3. Matches: mail.* → /var/log/maillog (written)
  4. Both rules execute

Advanced routing examples:

Priority-specific routing:

Route only errors:
  local0.err                              /var/log/local0-errors.log

Route warnings and higher:
  local0.warning                          /var/log/local0-warnings.log

Route everything except debug:
  local0.*;local0.!debug                  /var/log/local0-nodebug.log

Multiple facilities to one file:

Route both local0 and local1:
  local0,local1.*                         /var/log/local-apps.log

Route user and daemon:
  user,daemon.*                           /var/log/user-daemon.log

Exclusion patterns:

Exclude local0 from messages:
  *.info;mail.none;authpriv.none;cron.none;local0.none  /var/log/messages

Complex filtering:

Route mail errors to separate file:
  mail.err                                /var/log/mail-errors.log
  mail.*;mail.!err                        /var/log/mail-other.log

First line: Only errors
Second line: Everything except errors

File naming conventions:

Good names:
  application-name.log
  facility-priority.log
  service-errors.log

Avoid:
  Names with spaces
  Names without .log extension

Log file permissions:

New log files created by rsyslog typically:
  -rw------- (600) root:root

Or:
  -rw-r----- (640) root:adm

Check permissions:
  ls -l /var/log/lab-local0.log

Change if needed:
  sudo chmod 644 /var/log/lab-local0.log

Troubleshooting:

Configuration not working:

1. Check syntax:
   sudo rsyslogd -N1

2. Check service status:
   systemctl status rsyslog

3. Check for errors:
   journalctl -u rsyslog -n 50

4. Verify file was created:
   ls -l /var/log/lab-local0.log

5. Test with logger:
   logger -p local0.info "Test"
   tail /var/log/lab-local0.log

Messages not appearing:

1. Wrong facility?
   Check logger -p matches your rule

2. Service not restarted?
   systemctl restart rsyslog

3. Permission issue?
   rsyslog can't write to directory

4. Rule precedence?
   Earlier rule might be catching messages

Real-world use cases:

Application logging:
  local0.*                                /var/log/myapp.log

Separates app logs from system logs.

Error aggregation:
  *.err                                   /var/log/all-errors.log

All errors in one place.

Security monitoring:
  authpriv.*                              /var/log/auth.log
  authpriv.warning                        /var/log/auth-warnings.log

Separate auth logs by severity.

Service-specific:
  daemon.info                             /var/log/daemons.log

All daemon messages together.

EOF
}

hint_step_3() {
    echo "  Critical rule: *.crit  /var/log/critical.log"
    echo "  Exclude from messages: Add facility.none to messages rule"
    echo "  Multiple selectors: Use semicolon to separate"
    echo "  Test: logger -p user.crit 'Critical test'"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: Implement advanced filtering and separation

Create sophisticated log routing rules with multiple selectors and exclusions.

Your goals:
  Configure rsyslog to separate critical messages and implement
  advanced filtering patterns.

Requirements:
  • Create a critical messages log
    - Capture ALL facilities at priority crit and higher
    - Include: crit, alert, emerg (priorities 0-2)
    - Destination: /var/log/lab-critical.log
    - Should capture system-wide critical events
  
  • Modify messages log to exclude your custom facilities
    - Update the default *.info rule
    - Exclude local0 (already has its own log)
    - Ensure other facilities still log normally
    - Avoid duplicate entries
  
  • Create an application-specific log configuration
    - Use local1 facility for a test application
    - Route to /var/log/lab-application.log
    - Include only info level and higher
    - Exclude debug messages

Advanced selector syntax to use:
  • Multiple facilities: facility1,facility2.priority
  • Multiple selectors: selector1;selector2
  • Exclusions: facility.none
  • Exact priority: facility.=priority
  • Priority ranges: facility.priority (includes higher)

Testing requirements:
  • Generate critical messages from different facilities
  • Verify they appear in critical log
  • Verify non-critical messages excluded
  • Test exclusion from messages log
  • Generate local1 messages at different priorities
  • Verify debug messages excluded

Research topics:
  How to combine multiple selectors
  How to exclude facilities from existing rules
  How to filter by exact priority match
  How exclusions work with multiple rules

This step tests your understanding of:
  - Complex selector syntax
  - Rule precedence
  - Multiple destination routing
  - Exclusion patterns
EOF
}

validate_step_3() {
    local failures=0
    
    # Check for critical log rule
    local has_critical=false
    if grep -r "^\*\.crit.*\/var\/log\/.*\.log" /etc/rsyslog.d/ >/dev/null 2>&1; then
        has_critical=true
    fi
    
    if ! $has_critical; then
        echo ""
        print_color "$RED" "✗ No critical messages rule found"
        echo "  Add: *.crit  /var/log/lab-critical.log"
        ((failures++))
    fi
    
    # Test critical logging
    logger -p user.crit "Lab 17B validation - critical test"
    sleep 1
    
    if [ -f /var/log/lab-critical.log ]; then
        if grep -q "Lab 17B validation - critical test" /var/log/lab-critical.log; then
            print_color "$GREEN" "  ✓ Critical messages being logged"
        else
            echo ""
            print_color "$RED" "✗ Critical log exists but test message not found"
            ((failures++))
        fi
    else
        echo ""
        print_color "$RED" "✗ Critical log file not created"
        ((failures++))
    fi
    
    # Check for local1 rule
    local has_local1=false
    if grep -r "local1\.\*.*\/var\/log\/.*\.log" /etc/rsyslog.d/ >/dev/null 2>&1 || \
       grep -r "local1\.info.*\/var\/log\/.*\.log" /etc/rsyslog.d/ >/dev/null 2>&1; then
        has_local1=true
    fi
    
    if ! $has_local1; then
        echo ""
        print_color "$YELLOW" "⚠ No local1 application log rule found"
        echo "  Consider adding: local1.info  /var/log/lab-application.log"
    fi
    
    if [ $failures -gt 0 ]; then
        return 1
    fi
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────

Step 1: Edit your configuration file
─────────────────────────────────────
Edit existing configuration:
  sudo vi /etc/rsyslog.d/lab-custom.conf

Add these additional rules:

# Critical messages from all facilities
*.crit                                      /var/log/lab-critical.log

# Application logging using local1
local1.info                                 /var/log/lab-application.log

Save the file.

Step 2: Modify default messages rule (optional)
────────────────────────────────────────────────
To exclude your custom facilities from /var/log/messages,
you would need to modify /etc/rsyslog.conf.

However, for the lab, you can create an override:

Add to /etc/rsyslog.d/lab-custom.conf:

# Override messages to exclude custom facilities
*.info;mail.none;authpriv.none;cron.none;local0.none;local1.none  /var/log/messages

This prevents duplicate logging.

Note: In production, you'd typically edit the main config,
but drop-in files can override with proper precedence.

Step 3: Restart rsyslog
───────────────────────
Apply changes:
  sudo systemctl restart rsyslog

Verify:
  systemctl status rsyslog

Step 4: Test critical message logging
──────────────────────────────────────
Generate critical messages from different facilities:

  logger -p user.crit "User CRITICAL message"
  logger -p kern.crit "Kernel CRITICAL message"
  logger -p daemon.alert "Daemon ALERT message"
  logger -p mail.emerg "Mail EMERGENCY message"

Verify in critical log:
  tail /var/log/lab-critical.log

Should show all test messages (crit, alert, emerg).

Test that lower priorities are excluded:
  logger -p user.err "User ERROR message"
  logger -p user.warning "User WARNING message"

Check critical log:
  tail /var/log/lab-critical.log

These should NOT appear (err=3, warning=4, both < crit).

Step 5: Test application logging
─────────────────────────────────
Generate local1 messages at different priorities:

  logger -p local1.debug "App DEBUG message"
  logger -p local1.info "App INFO message"
  logger -p local1.warning "App WARNING message"
  logger -p local1.err "App ERROR message"

Check application log:
  tail /var/log/lab-application.log

Should show: info, warning, err
Should NOT show: debug (excluded by .info selector)

Step 6: Verify exclusions
──────────────────────────
Check that local0 messages don't appear in messages:
  logger -p local0.info "Local0 test"
  grep "Local0 test" /var/log/messages

Should return nothing (excluded).

Check they DO appear in correct file:
  grep "Local0 test" /var/log/lab-local0.log

Should show the message.

Understanding the rules:

Rule 1: *.crit  /var/log/lab-critical.log

  *           - All facilities
  .crit       - Priority crit and higher (crit, alert, emerg)
  destination - Critical log file

This creates a system-wide critical messages log.

Priorities captured:
  0 - emerg
  1 - alert
  2 - crit

Priorities excluded:
  3 - err
  4 - warning
  5 - notice
  6 - info
  7 - debug

Rule 2: local1.info  /var/log/lab-application.log

  local1      - Local1 facility only
  .info       - Priority info and higher
  destination - Application log

Captures from local1:
  info (6) and higher: notice, warning, err, crit, alert, emerg

Excludes from local1:
  debug (7)

Advanced selector patterns:

Multiple facilities, same priority:

  mail,daemon,cron.err                    /var/log/services-err.log

Captures errors from mail, daemon, and cron only.

Multiple selectors with semicolon:

  mail.err;daemon.warning                 /var/log/mixed.log

Captures:
  - Mail errors and higher
  - Daemon warnings and higher

Exclusion patterns:

Exclude specific facility:
  *.info;mail.none                        /var/log/no-mail.log

Captures all info+ messages except mail.

Exclude multiple facilities:
  *.info;mail.none;cron.none;local0.none  /var/log/filtered.log

Exact priority matching:

Only errors (not higher):
  *.=err                                  /var/log/exactly-err.log

Captures only priority 3, excludes crit/alert/emerg.

Negation:

Everything except info:
  *.!info                                 /var/log/not-info.log

Or:
  *.*;*.!info                             /var/log/not-info.log

Complex filtering examples:

Separate error severities:

  # Emergency and alert only
  *.=emerg;*.=alert                       /var/log/urgent.log
  
  # Critical only
  *.=crit                                 /var/log/critical-only.log
  
  # Errors only
  *.=err                                  /var/log/errors-only.log

Application error tracking:

  # All application errors
  local0.err;local1.err;local2.err        /var/log/app-errors.log

Security monitoring:

  # Authentication and critical from all
  authpriv.*;*.crit                       /var/log/security.log

Understanding rule precedence:

Rules are processed in order:
  1. /etc/rsyslog.conf (main config)
  2. /etc/rsyslog.d/*.conf (alphabetically)

Later rules can add additional destinations.

Example:
  File: /etc/rsyslog.conf
    mail.*                                /var/log/maillog

  File: /etc/rsyslog.d/lab-custom.conf
    mail.err                              /var/log/mail-errors.log

Result:
  - All mail goes to maillog
  - Mail errors ALSO go to mail-errors.log
  - Mail errors appear in both files

Testing strategy for complex rules:

1. Test each priority level:
   for p in emerg alert crit err warning notice info debug; do
     logger -p user.$p "Test $p"
   done

2. Check which file they appear in:
   grep "Test" /var/log/lab-*.log

3. Verify exclusions work:
   grep "Test debug" /var/log/lab-application.log
   # Should be empty if info+ rule excludes debug

4. Check for duplicates:
   grep "Test emerg" /var/log/lab-critical.log
   grep "Test emerg" /var/log/messages
   # Might appear in both (normal if not excluded)

Real-world advanced configurations:

Separate logs by severity:

  *.emerg                                 /var/log/emergency.log
  *.alert                                 /var/log/alert.log
  *.crit                                  /var/log/critical.log
  *.err                                   /var/log/error.log

Everything else to messages.

Application suite logging:

  # App suite uses local0-local3
  local0,local1,local2,local3.*           /var/log/app-suite.log
  
  # But separate errors
  local0,local1,local2,local3.err         /var/log/app-suite-errors.log

Service-specific with priorities:

  # HTTP server (daemon facility)
  daemon.err                              /var/log/httpd-errors.log
  daemon.*;daemon.!err                    /var/log/httpd.log

Errors go to one file, everything else to another.

Common mistakes:

Mistake 1: Wrong selector separator
  Wrong: mail.err,daemon.err /var/log/file.log
  Right: mail.err;daemon.err /var/log/file.log

Use semicolon, not comma (comma is for facilities).

Mistake 2: Forgetting to restart
  Changes don't take effect until restart

Mistake 3: Conflicting exclusions
  *.info;mail.none /var/log/messages
  mail.* /var/log/maillog
  
  Both rules active - mail goes to maillog, not messages.

Mistake 4: Order matters
  More specific rules should come before general rules
  in some cases.

EOF
}

hint_step_4() {
    echo "  Set permissions: chmod 640 /var/log/lab-*.log"
    echo "  Test all: Create script with multiple logger calls"
    echo "  Verify no dupes: Check same message in multiple files"
    echo "  Check rotation: ls /etc/logrotate.d/"
}

# STEP 4
show_step_4() {
    cat << 'EOF'
TASK: Configure log file properties and test thoroughly

Finalize your rsyslog configuration with proper permissions and comprehensive testing.

Requirements:
  • Set appropriate permissions on all custom log files
    - Decide who should read these logs
    - Set ownership and permissions
    - Consider security implications
  
  • Create comprehensive test script
    - Generate messages across all facilities
    - Test all priority levels
    - Verify routing to correct files
    - Check for unexpected duplicates
  
  • Verify configuration completeness
    - All rules working as expected
    - No messages being lost
    - No syntax errors in config
    - Service running without errors
  
  • Understand logrotate integration
    - Check if custom logs need rotation config
    - Understand how rsyslog and logrotate work together
    - Know where rotation configs go

Testing strategy:
  Create a test script that generates messages for:
    - All priority levels (emerg through debug)
    - Multiple facilities (user, local0, local1, mail)
    - Critical messages that should appear in critical log
    - Application messages that should appear in app log
    - Messages that should be excluded from messages log

Verification checklist:
  □ Critical messages in /var/log/lab-critical.log
  □ Local0 messages in /var/log/lab-local0.log
  □ Local1 messages in /var/log/lab-application.log
  □ Mail messages in /var/log/lab-mail.log
  □ Local0/local1 NOT in /var/log/messages (if configured)
  □ Debug messages NOT in application log
  □ All log files have correct permissions
  □ No errors in rsyslog service status
  □ Configuration syntax valid

File permissions guidance:
  • 600 (rw-------): Only root can read - most secure
  • 640 (rw-r-----): Root writes, group can read
  • 644 (rw-r--r--): World-readable - less secure
  
  Common pattern: 640 with group 'adm' for sysadmins

After this step, you should have a complete, tested,
production-ready rsyslog configuration.
EOF
}

validate_step_4() {
    local score=0
    local total=4
    
    echo "Performing comprehensive validation..."
    echo ""
    
    # Test 1: Critical logging works
    logger -p user.crit "Final validation - critical"
    sleep 1
    if [ -f /var/log/lab-critical.log ] && grep -q "Final validation - critical" /var/log/lab-critical.log; then
        print_color "$GREEN" "  ✓ Critical logging working"
        ((score++))
    else
        print_color "$RED" "  ✗ Critical logging not working"
    fi
    
    # Test 2: local0 logging works
    logger -p local0.info "Final validation - local0"
    sleep 1
    if ls /var/log/lab-*.log 2>/dev/null | xargs grep -l "Final validation - local0" >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Local0 logging working"
        ((score++))
    else
        print_color "$RED" "  ✗ Local0 logging not working"
    fi
    
    # Test 3: Check permissions on at least one custom log
    if ls /var/log/lab-*.log >/dev/null 2>&1; then
        local perm=$(stat -c "%a" $(ls /var/log/lab-*.log | head -1))
        if [[ "$perm" =~ ^(600|640|644)$ ]]; then
            print_color "$GREEN" "  ✓ Log file permissions configured"
            ((score++))
        else
            print_color "$YELLOW" "  ⚠ Log file permissions may need adjustment ($perm)"
        fi
    fi
    
    # Test 4: rsyslog service healthy
    if systemctl is-active rsyslog >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ rsyslog service running"
        ((score++))
    else
        print_color "$RED" "  ✗ rsyslog service not running"
    fi
    
    echo ""
    echo "Validation score: $score/$total"
    
    [ $score -ge 3 ]
}

solution_step_4() {
    cat << 'EOF'

SOLUTION:
─────────

Step 1: Set log file permissions
─────────────────────────────────
Set appropriate permissions on custom logs:

  sudo chmod 640 /var/log/lab-critical.log
  sudo chmod 640 /var/log/lab-local0.log
  sudo chmod 640 /var/log/lab-application.log
  sudo chmod 640 /var/log/lab-mail.log

Set ownership (optional, usually root:root or root:adm):
  sudo chown root:adm /var/log/lab-*.log

Verify:
  ls -l /var/log/lab-*.log

Should show: -rw-r----- 1 root adm

This allows:
  - Root to read/write
  - Adm group to read
  - Others cannot access

Step 2: Create comprehensive test script
─────────────────────────────────────────
Create test script:
  vi /tmp/test-rsyslog.sh

Add content:

#!/bin/bash
# Comprehensive rsyslog testing script

echo "Testing rsyslog configuration..."

# Test critical messages (should go to lab-critical.log)
echo "Generating critical messages..."
logger -p user.crit "TEST: User critical message"
logger -p daemon.alert "TEST: Daemon alert message"
logger -p kern.emerg "TEST: Kernel emergency message"

# Test local0 (should go to lab-local0.log)
echo "Generating local0 messages..."
logger -p local0.info "TEST: Local0 info message"
logger -p local0.warning "TEST: Local0 warning message"
logger -p local0.err "TEST: Local0 error message"

# Test local1 application (should go to lab-application.log)
echo "Generating local1 messages..."
logger -p local1.debug "TEST: Local1 debug message (should be filtered)"
logger -p local1.info "TEST: Local1 info message"
logger -p local1.warning "TEST: Local1 warning message"
logger -p local1.err "TEST: Local1 error message"

# Test mail (should go to lab-mail.log and maillog)
echo "Generating mail messages..."
logger -p mail.info "TEST: Mail info message"
logger -p mail.err "TEST: Mail error message"

# Test regular user messages (should go to messages)
echo "Generating user messages..."
logger -p user.info "TEST: User info message"
logger -p user.notice "TEST: User notice message"

echo ""
echo "Wait 2 seconds for logs to be written..."
sleep 2

echo ""
echo "Checking results..."
echo ""

Make executable:
  chmod +x /tmp/test-rsyslog.sh

Run it:
  /tmp/test-rsyslog.sh

Step 3: Verify test results
────────────────────────────
Check critical log:
  echo "=== Critical Log ==="
  grep "TEST:" /var/log/lab-critical.log

Should show:
  - User critical
  - Daemon alert
  - Kernel emergency

Check local0 log:
  echo "=== Local0 Log ==="
  grep "TEST:" /var/log/lab-local0.log

Should show all local0 messages.

Check application log:
  echo "=== Application Log ==="
  grep "TEST:" /var/log/lab-application.log

Should show:
  - info, warning, err
  - NOT debug (filtered out)

Verify debug was filtered:
  grep "debug" /var/log/lab-application.log

Should be empty or not show your test message.

Check mail log:
  echo "=== Mail Log ==="
  grep "TEST:" /var/log/lab-mail.log

Should show mail messages.

Check messages log:
  echo "=== Messages Log ==="
  grep "TEST:" /var/log/messages

Should show user.info and user.notice.
Should NOT show local0 or local1 (if configured to exclude).

Step 4: Verify no duplicates where unwanted
────────────────────────────────────────────
Check if local0 appears in messages:
  grep "Local0" /var/log/messages

Should be empty if exclusion configured.

Check if critical messages appear in correct file:
  grep "critical" /var/log/lab-critical.log
  grep "alert" /var/log/lab-critical.log
  grep "emerg" /var/log/lab-critical.log

All should show test messages.

Step 5: Verify rsyslog service health
──────────────────────────────────────
Check service status:
  systemctl status rsyslog

Should show: active (running)

Check for errors:
  journalctl -u rsyslog -n 50

Should not show syntax errors or write failures.

Verify configuration syntax:
  sudo rsyslogd -N1

Should complete without errors.

Step 6: Understanding logrotate integration
────────────────────────────────────────────
Check existing logrotate configs:
  ls /etc/logrotate.d/

View syslog rotation config:
  cat /etc/logrotate.d/syslog

Shows how /var/log/messages, etc. are rotated.

Custom logs may need rotation config:

Create /etc/logrotate.d/lab-logs:

  /var/log/lab-*.log {
      daily
      rotate 7
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root adm
      sharedscripts
      postrotate
          /usr/bin/systemctl reload rsyslog > /dev/null 2>&1 || true
      endscript
  }

This ensures your custom logs:
  - Rotate daily
  - Keep 7 days of history
  - Compress old logs
  - Recreate with correct permissions
  - Reload rsyslog after rotation

Understanding file permissions:

600 (-rw-------):
  Owner: read, write
  Group: none
  Other: none
  
  Most secure, only root can read.

640 (-rw-r-----):
  Owner: read, write
  Group: read
  Other: none
  
  Common for system logs.
  Root writes, sysadmins (adm group) can read.

644 (-rw-r--r--):
  Owner: read, write
  Group: read
  Other: read
  
  World-readable.
  Less secure, but sometimes needed.

Recommended: 640 with group adm
  sudo chmod 640 /var/log/lab-*.log
  sudo chown root:adm /var/log/lab-*.log

This allows system administrators to read logs
without being root.

Creating automated monitoring:

Script to check log health:

#!/bin/bash
# Check rsyslog health

echo "Checking rsyslog configuration..."

# Check service
if ! systemctl is-active rsyslog >/dev/null; then
    echo "ERROR: rsyslog not running"
    exit 1
fi

# Check syntax
if ! rsyslogd -N1 >/dev/null 2>&1; then
    echo "ERROR: rsyslog syntax errors"
    exit 1
fi

# Check log files exist
for log in /var/log/lab-*.log; do
    if [ ! -f "$log" ]; then
        echo "WARNING: $log does not exist"
    fi
done

# Check recent activity
for log in /var/log/lab-*.log; do
    if [ -f "$log" ]; then
        age=$(stat -c %Y "$log")
        now=$(date +%s)
        diff=$((now - age))
        
        if [ $diff -gt 86400 ]; then
            echo "WARNING: $log not updated in 24h"
        fi
    fi
done

echo "Health check complete"

Production considerations:

1. Log retention:
   Balance disk space vs. compliance requirements

2. Permissions:
   Secure sensitive logs (auth, security)

3. Rotation:
   Configure before logs grow too large

4. Monitoring:
   Alert if logs stop being written

5. Remote logging:
   Consider forwarding critical logs to central server

6. Performance:
   Async writes for high-volume logs

7. Storage:
   Dedicated partition for /var/log

Final verification commands:

List all custom logs:
  ls -lh /var/log/lab-*.log

Check sizes:
  du -sh /var/log/lab-*.log

View recent entries from all:
  tail -n 5 /var/log/lab-*.log

Count messages per log:
  for log in /var/log/lab-*.log; do
      echo "$log: $(wc -l < $log) lines"
  done

Search across all custom logs:
  grep "ERROR" /var/log/lab-*.log

Monitor live:
  tail -f /var/log/lab-critical.log

If everything works:
  - Critical messages in critical log
  - Application messages in app log
  - Custom facilities in custom logs
  - Proper exclusions from messages
  - Correct permissions
  - Service healthy
  - No errors in journalctl

Then your rsyslog configuration is complete and production-ready!

EOF
}

#############################################################################
# VALIDATION
#############################################################################
validate() {
    local score=0
    local total=5
    
    echo "Checking your rsyslog configuration..."
    echo ""
    
    # CHECK 1: rsyslog service is running
    print_color "$CYAN" "[1/$total] Checking rsyslog service..."
    if systemctl is-active rsyslog >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ rsyslog service is running"
        ((score++))
    else
        print_color "$RED" "  ✗ rsyslog service is not running"
    fi
    echo ""
    
    # CHECK 2: Custom configuration exists
    print_color "$CYAN" "[2/$total] Checking custom configuration..."
    if ls /etc/rsyslog.d/lab-*.conf >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Custom rsyslog configuration found"
        ((score++))
    else
        print_color "$RED" "  ✗ No custom configuration in /etc/rsyslog.d/"
    fi
    echo ""
    
    # CHECK 3: Test local0 logging
    print_color "$CYAN" "[3/$total] Testing custom facility logging..."
    logger -p local0.info "Lab 17B final validation - $(date)"
    sleep 1
    if ls /var/log/lab-*.log 2>/dev/null | xargs grep -l "Lab 17B final validation" >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Custom facility logging working"
        ((score++))
    else
        print_color "$RED" "  ✗ Custom facility logging not working"
        echo "  Check: tail /var/log/lab-*.log"
    fi
    echo ""
    
    # CHECK 4: Test critical logging
    print_color "$CYAN" "[4/$total] Testing critical message logging..."
    logger -p user.crit "Lab 17B critical test - $(date)"
    sleep 1
    if [ -f /var/log/lab-critical.log ] && grep -q "Lab 17B critical test" /var/log/lab-critical.log; then
        print_color "$GREEN" "  ✓ Critical message logging working"
        ((score++))
    else
        print_color "$YELLOW" "  ⚠ Critical logging not configured or not working"
    fi
    echo ""
    
    # CHECK 5: Configuration syntax valid
    print_color "$CYAN" "[5/$total] Checking configuration syntax..."
    if rsyslogd -N1 >/dev/null 2>&1; then
        print_color "$GREEN" "  ✓ Configuration syntax valid"
        ((score++))
    else
        print_color "$RED" "  ✗ Configuration has syntax errors"
        echo "  Run: rsyslogd -N1 to see errors"
    fi
    echo ""
    
    # Additional information
    echo "Configuration summary:"
    if ls /etc/rsyslog.d/lab-*.conf >/dev/null 2>&1; then
        echo "  Custom config files:"
        ls /etc/rsyslog.d/lab-*.conf | sed 's/^/    /'
    fi
    if ls /var/log/lab-*.log >/dev/null 2>&1; then
        echo "  Custom log files:"
        ls -lh /var/log/lab-*.log | awk '{print "    " $9 " (" $5 ")"}'
    fi
    echo ""
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've mastered rsyslog configuration:"
        echo "  • Understanding facility and priority syntax"
        echo "  • Creating custom log routing rules"
        echo "  • Implementing advanced filtering"
        echo "  • Configuring log file properties"
        echo ""
        echo "You're ready for RHCSA rsyslog questions!"
    elif [ $score -ge 3 ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED (Good Understanding)"
        echo ""
        echo "Good work! Review the missing pieces to strengthen your knowledge."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback and try again."
        echo "Use --interactive mode for step-by-step guidance."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total
    
    [ $score -ge 3 ]
}

#############################################################################
# SOLUTION
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

See detailed solutions in each step's solution output above.

EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Critical skills for RHCSA:

Configuration syntax:
  facility.priority  /path/to/logfile

Example:
  local0.*           /var/log/myapp.log
  *.crit             /var/log/critical.log
  mail.err           /var/log/mail-errors.log

Key commands:
  Edit config:   vi /etc/rsyslog.d/custom.conf
  Check syntax:  rsyslogd -N1
  Restart:       systemctl restart rsyslog
  Test logging:  logger -p facility.priority "message"
  View logs:     tail /var/log/logfile

Facilities:
  kern, user, mail, daemon, auth, authpriv, cron, local0-7

Priorities (high to low severity):
  emerg(0) alert(1) crit(2) err(3) warning(4) notice(5) info(6) debug(7)

Common patterns:
  *.crit         - All critical and higher
  mail.*         - All mail messages
  *.info;mail.none - All info+ except mail
  local0,local1.* - Both facilities

Remember:
  • Config in /etc/rsyslog.d/*.conf
  • Restart rsyslog after changes
  • Test with logger command
  • Check syntax with rsyslogd -N1
  • Lower priority number = MORE severe

EOF
}

#############################################################################
# CLEANUP
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # Remove custom configurations
    rm -f /etc/rsyslog.d/lab-*.conf 2>/dev/null || true
    
    # Remove custom log files
    rm -f /var/log/lab-*.log 2>/dev/null || true
    
    # Remove test application
    rm -rf /opt/lab-rsyslog 2>/dev/null || true
    
    # Restart rsyslog to clear custom config
    systemctl restart rsyslog 2>/dev/null || true
    
    echo "  ✓ Custom configurations removed"
    echo "  ✓ Custom log files removed"
    echo "  ✓ Test application removed"
    echo "  ✓ rsyslog restarted with default config"
    echo "  ✓ Lab cleanup complete"
}

# Execute the main framework
main "$@"
