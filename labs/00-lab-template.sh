#!/bin/bash
# labs/XX-lab-name.sh
# Lab: [Descriptive Lab Name]
# Difficulty: [Beginner|Intermediate|Advanced]
# RHCSA Objective: [Specific exam objective this covers]

# Source the lab framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lab-runner.sh"

# Lab metadata
LAB_NAME="[Descriptive Lab Name]"
LAB_DIFFICULTY="[Beginner|Intermediate|Advanced]"
LAB_TIME_ESTIMATE="[X-Y minutes]"

#############################################################################
# SETUP: Idempotent environment preparation
# Purpose: Clean up any previous attempts and set starting conditions
# This ensures the lab can be run multiple times without conflicts
#############################################################################
setup_lab() {
    echo "Preparing lab environment..."
    
    # TODO: Remove any users, groups, files, or configurations from previous attempts
    # Ensure that there are no dependencies or other bizarre system states
    # (unless the lab specifically requires the user to install dependencies)
    # Use '2>/dev/null || true' to suppress errors if resources don't exist
    
    # Example cleanup commands:
    # userdel -r testuser 2>/dev/null || true
    # groupdel testgroup 2>/dev/null || true
    # rm -rf /path/to/test/dir 2>/dev/null || true
    # systemctl stop testservice 2>/dev/null || true
    # systemctl disable testservice 2>/dev/null || true
    
    echo "  ✓ Cleaned up any previous lab attempts"
    echo "  ✓ System ready for fresh lab start"
}

#############################################################################
# PREREQUISITES: Knowledge and commands needed
# Purpose: Tell users what they should know and what tools they'll use
# Note: Use reference material as much as possible, do not attempt to 
#       recreate documentation for things you're not certain about
#############################################################################
prerequisites() {
    cat << 'EOF'
Knowledge Requirements:
  • [Concept 1 they should understand]
  • [Concept 2 they should understand]
  • [Concept 3 if applicable]

Commands You'll Use:
  • command1  - Brief description of what it does
  • command2  - Brief description of what it does
  • command3  - Brief description of what it does

Files You'll Interact With:
  • /path/to/file1 - What this file contains/controls
  • /path/to/file2 - What this file contains/controls
EOF
}

#############################################################################
# SCENARIO: The lab story and objectives (Standard Mode)
# Purpose: Present the real-world scenario and what needs to be accomplished
#############################################################################
scenario() {
    cat << 'EOF'
SCENARIO:
[2-3 sentences describing the business/technical context and why this task 
matters. Make it realistic - something a sysadmin would actually encounter.]

BACKGROUND:
[1-2 sentences providing additional context, constraints, or requirements
that frame the work to be done.]

OBJECTIVES:
  1. [First task to complete - be specific about requirements]
     [Include any specific values, names, IDs that must be used]
  
  2. [Second task with details such as:
     • Specific values (UIDs, GIDs, ports, paths, permissions)
     • Required flags or configuration options
     • Expected end state or behavior]
  
  3. [Third task - be explicit about what "done" looks like]
     [Continue numbering for additional objectives...]

HINTS:
  • [Helpful tip about a common flag or approach]
  • [Reminder about a key concept or gotcha]
  • [Verification technique they can use]

SUCCESS CRITERIA:
  • [How users can manually verify their work]
  • [What the end state should look like]
  • [Commands they can run to check their configuration]
EOF
}

#############################################################################
# QUICK OBJECTIVES: Condensed checklist for quick reference
# Purpose: Allow users to see objectives without scrolling through full scenario
# This is shown with --objectives flag for quick reference during work
#############################################################################
objectives_quick() {
    cat << 'EOF'
  ☐ 1. [Brief task 1 description with key details]
  ☐ 2. [Brief task 2 description with key details]
  ☐ 3. [Brief task 3 description with key details]
  ☐ 4. [Additional tasks if applicable]
EOF
}

#############################################################################
# INTERACTIVE MODE SUPPORT (Optional but recommended)
# Purpose: Allow step-by-step guided completion with immediate feedback
# Users can type commands directly and get validated after each step
#############################################################################

# Return the number of steps in interactive mode
get_step_count() {
    echo "3"  # Change this to match your number of steps
}

# Context shown once at the start of interactive mode
scenario_context() {
    cat << 'EOF'
[2-3 sentences of context - same as the SCENARIO section above but 
without the full objectives list since those will be shown step-by-step]
EOF
}

# STEP 1
show_step_1() {
    cat << 'EOF'
TASK: [Short, clear description of what to accomplish in this step]

[More detailed explanation of the requirement and why it matters]

Requirements:
  • [Specific requirement 1 - be explicit about values]
  • [Specific requirement 2 - include paths, IDs, etc.]
  • [Any constraints or special conditions]

Commands you might need:
  • command1 - What it does
  • command2 - How to verify your work
EOF
}

validate_step_1() {
    # Return 0 for success, 1 for failure
    # IMPORTANT: Check the END STATE only, not the command used
    # Multiple approaches should work if they achieve the same result
    
    # Example validation pattern:
    # if ! getent group testgroup >/dev/null 2>&1; then
    #     echo ""
    #     print_color "$RED" "✗ Group 'testgroup' does not exist"
    #     echo "  Try: groupadd testgroup"
    #     return 1
    # fi
    #
    # local gid=$(getent group testgroup | cut -d: -f3)
    # if [ "$gid" != "3000" ]; then
    #     echo ""
    #     print_color "$RED" "✗ Group GID is $gid (expected 3000)"
    #     echo "  Try: groupdel testgroup && groupadd -g 3000 testgroup"
    #     return 1
    # fi
    
    # If all checks pass:
    return 0
}

solution_step_1() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  [the exact command to run]

Explanation:
  • [flag/option 1]: [what it does and why you need it]
  • [flag/option 2]: [what it does and why you need it]
  • [argument]: [what this specifies]

Why this matters:
  [1-2 sentences about the concept or real-world application]

Verification:
  [command to verify it worked]
  # Expected output: [what they should see]

EOF
}

hint_step_2() {
    echo "  [Brief hint about the approach for step 2]"
}

# STEP 2
show_step_2() {
    cat << 'EOF'
TASK: [Step 2 description]

[Detailed explanation...]

Requirements:
  • [Requirement 1]
  • [Requirement 2]

Commands you might need:
  • command1 - Description
EOF
}

validate_step_2() {
    # Add validation logic for step 2
    # Follow same pattern as validate_step_1
    
    return 0
}

solution_step_2() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  [command]

Explanation:
  [breakdown of flags and options]

Verification:
  [how to check]

EOF
}

hint_step_3() {
    echo "  [Brief hint about the approach for step 3]"
}

# STEP 3
show_step_3() {
    cat << 'EOF'
TASK: [Step 3 description]

Requirements:
  • [Requirement 1]
  • [Requirement 2]
EOF
}

validate_step_3() {
    # Add validation logic for step 3
    
    return 0
}

solution_step_3() {
    cat << 'EOF'

SOLUTION:
─────────
Command:
  [command]

Explanation:
  [breakdown]

Verification:
  [how to verify]

EOF
}

# Add more steps as needed (show_step_4, validate_step_4, solution_step_4, etc.)
# Remember to update get_step_count() to match total number of steps

#############################################################################
# VALIDATION: Check the final state (Standard Mode)
# Purpose: Verify all objectives are met, provide specific feedback
# Important: Check OUTCOMES not METHODS - multiple commands can achieve same result
#############################################################################
validate() {
    local score=0
    local total=3  # Match number of essential checks
    
    echo "Checking your configuration..."
    echo ""
    
    # CHECK 1: [What you're checking]
    print_color "$CYAN" "[1/$total] Checking [resource/configuration]..."
    if [[ condition to check end state ]]; then
        print_color "$GREEN" "  ✓ [Success message - what is correctly configured]"
        ((score++))
    else
        print_color "$RED" "  ✗ [What's wrong - be specific]"
        print_color "$YELLOW" "  Fix: [suggested command that would resolve the issue]"
    fi
    echo ""
    
    # CHECK 2: [What you're checking]
    print_color "$CYAN" "[2/$total] Checking [resource/configuration]..."
    # Example validation:
    # if systemctl is-active myservice >/dev/null 2>&1; then
    #     print_color "$GREEN" "  ✓ Service 'myservice' is running"
    #     ((score++))
    # else
    #     print_color "$RED" "  ✗ Service 'myservice' is not running"
    #     print_color "$YELLOW" "  Fix: systemctl start myservice"
    # fi
    echo ""
    
    # CHECK 3: [What you're checking]
    print_color "$CYAN" "[3/$total] Checking [resource/configuration]..."
    # Add validation logic...
    echo ""
    
    # Add more checks as needed, incrementing total variable
    
    # Final results
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "FINAL SCORE: $score/$total"
    
    if [ $score -eq $total ]; then
        print_color "$GREEN" "STATUS: ✓ PASSED"
        echo ""
        echo "Excellent work! You've successfully completed all objectives."
    else
        print_color "$YELLOW" "STATUS: ⚠ INCOMPLETE ($score/$total checks passed)"
        echo ""
        echo "Review the feedback above and try again."
        echo "Run with --solution to see detailed steps."
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Export for progress tracking (REQUIRED for tracking to work)
    export VALIDATION_SCORE=$score
    export VALIDATION_TOTAL=$total

    # Return exit code based on score
    [ $score -eq $total ]
}

#############################################################################
# SOLUTION: Complete walkthrough with explanations (Standard Mode)
# Purpose: Teach concepts, not just provide answers
# Include: commands, explanations, verification steps, and concepts
#############################################################################
solution() {
    cat << 'EOF'
COMPLETE SOLUTION WALKTHROUGH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: [Task description]
─────────────────────────────────────────────────────────────────
Command:
  [exact command with all flags and arguments]

Explanation:
  [Break down each flag/option and what it does]
  • flag1: [purpose]
  • flag2: [purpose]
  • argument: [what it specifies]

Why this works:
  [Explain the underlying concept - what's happening behind the scenes]

Verification:
  [command to verify it worked]
  # Expected output: [what they should see]


STEP 2: [Task description]
─────────────────────────────────────────────────────────────────
Command:
  [exact command]

Explanation:
  [Detailed breakdown of the command and its components]

Verification:
  [verification command]


STEP 3: [Task description]
─────────────────────────────────────────────────────────────────
Command:
  [command]

Explanation:
  [breakdown]

Verification:
  [how to check it worked]


CONCEPTUAL UNDERSTANDING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Key Concept 1]:
  [2-3 sentences explaining the concept and why it matters in real-world
  system administration. Include how it relates to the exam objectives.]

[Key Concept 2]:
  [Explanation with examples. Connect to practical scenarios.]

[File Structure or System Behavior]:
  [How things work under the hood. What files are modified, what the
  system does in response to the commands, etc.]


COMMON MISTAKES & TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mistake 1: [Common error that users make]
  Result: [What happens when this error occurs]
  Fix: [How to correct it - include the exact command]

Mistake 2: [Another common error]
  Result: [What happens]
  Fix: [Solution with commands]

Mistake 3: [If applicable]
  Result: [Impact]
  Fix: [Resolution]


EXAM TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [Tip about this topic specifically for the RHCSA exam]
2. [Another exam-relevant tip - verification strategies, time-savers]
3. [How to quickly verify your work during the exam]
4. [Common exam scenario variations to watch for]

EOF
}

#############################################################################
# CLEANUP: Remove lab components
# Purpose: Allow users to reset the system to pre-lab state
# This is optional but helpful for users who want a clean slate
#############################################################################
cleanup_lab() {
    echo "Cleaning up lab environment..."
    
    # TODO: Remove all resources created during the lab
    # This should mirror what you did in setup_lab to ensure complete cleanup
    
    # Example cleanup commands:
    # userdel -r testuser 2>/dev/null || true
    # groupdel testgroup 2>/dev/null || true
    # rm -rf /path/to/test/dir 2>/dev/null || true
    # systemctl stop testservice 2>/dev/null || true
    # systemctl disable testservice 2>/dev/null || true
    # rm -f /etc/systemd/system/testservice.service 2>/dev/null || true
    # systemctl daemon-reload
    
    echo "  ✓ All lab components removed"
}

# Execute the main framework
main "$@"