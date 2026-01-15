#!/bin/bash
# lab-runner.sh
# RHCSA Lab Framework - Main Runner Script

# NOTE: We use 'set -uo pipefail' but NOT 'set -e' because validation checks
# need to gracefully handle non-existent users/files without exiting
set -uo pipefail

# Color codes for better readability
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color
readonly BOLD='\033[1m'

# Global variables
LAB_NAME=""
LAB_DIFFICULTY=""
LAB_OBJECTIVES=""
LAB_TIME_ESTIMATE=""
INTERACTIVE_MODE=false

# Helper function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo ""
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║ $1"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

print_section() {
    echo ""
    print_color "$BOLD" "=== $1 ==="
    echo ""
}

print_step_header() {
    local step_num=$1
    local total_steps=$2
    echo ""
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD$CYAN" "  STEP $step_num of $total_steps"
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Check if running with appropriate privileges
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        print_color "$RED" "ERROR: This lab requires root privileges."
        print_color "$YELLOW" "Please run with: sudo $0 $*"
        exit 1
    fi
}

# Phase 1: Initial Setup Logic
run_setup() {
    print_header "PHASE 1: Initial Setup"
    
    print_color "$YELLOW" "This will prepare your system for the lab by:"
    echo "  • Cleaning up any previous lab attempts"
    echo "  • Creating necessary starting conditions"
    echo "  • Ensuring idempotent environment setup"
    echo ""
    
    if [ "$(type -t setup_lab)" = "function" ]; then
        setup_lab
        print_color "$GREEN" "✓ Setup completed successfully!"
    else
        print_color "$YELLOW" "⚠ No setup function defined for this lab"
    fi
}

# Phase 2: Display Prerequisites
show_prerequisites() {
    print_header "PHASE 2: Prerequisites"
    
    if [ "$(type -t prerequisites)" = "function" ]; then
        prerequisites
    else
        echo "• Root or sudo access"
        echo "• RHEL 8/9 or compatible distribution"
        echo "• Basic command line familiarity"
    fi
    echo ""
}

# Phase 3: Display Scenario
show_scenario() {
    print_header "PHASE 3: Lab Scenario"
    
    if [ "$(type -t scenario)" = "function" ]; then
        scenario
    else
        print_color "$RED" "ERROR: No scenario function defined"
        exit 1
    fi
    
    echo ""
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "When ready, validate your work with:"
    print_color "$GREEN" "  sudo $0 --validate"
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Quick objectives reference
show_objectives() {
    print_header "Quick Reference - Objectives"
    
    if [ "$(type -t objectives_quick)" = "function" ]; then
        objectives_quick
    else
        if [ "$(type -t scenario)" = "function" ]; then
            scenario | grep -A 100 "OBJECTIVES:" | grep -B 100 -m 1 "^$" || scenario
        else
            print_color "$YELLOW" "Run the lab without flags to see full scenario"
        fi
    fi
    echo ""
}

# Phase 4: Validation
run_validation() {
    print_header "PHASE 4: Validation"
    
    if [ "$(type -t validate)" = "function" ]; then
        # Disable exit-on-error for validation to allow graceful failure checking
        set +e
        validate
        local validation_exit=$?
        set -e
        
        # Track progress if validation function exported score variables
        if [ -n "${VALIDATION_SCORE:-}" ] && [ -n "${VALIDATION_TOTAL:-}" ]; then
            # Find lab-runner.sh location (where this framework is)
            local framework_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            local tracker_path="${framework_dir}/track-progress.sh"
            
            # Always show tracking debug info
            echo ""
            print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_color "$CYAN" "📊 Progress Tracking"
            print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            if [ "${DEBUG_LAB:-}" = "1" ]; then
                echo "DEBUG: Framework dir: $framework_dir"
                echo "DEBUG: Tracker path: $tracker_path"
                echo "DEBUG: Tracker exists: $([ -f "$tracker_path" ] && echo "YES" || echo "NO")"
                echo "DEBUG: LAB_NAME: $LAB_NAME"
                echo "DEBUG: VALIDATION_SCORE: $VALIDATION_SCORE"
                echo "DEBUG: VALIDATION_TOTAL: $VALIDATION_TOTAL"
                echo ""
            fi
            
            # Check if tracker exists
            if [ -f "$tracker_path" ]; then
                # Call track-progress.sh with proper path (DON'T suppress errors)
                echo "Recording progress..."
                if bash "$tracker_path" --record "$LAB_NAME" "$VALIDATION_SCORE" "$VALIDATION_TOTAL"; then
                    # Show confirmation with actual file location
                    print_color "$GREEN" "✓ Progress recorded successfully"
                    echo "  Location: ${framework_dir}/lab_progress.txt"
                    echo "  View progress: ./track-progress.sh --summary"
                else
                    print_color "$YELLOW" "⚠ Failed to record progress (exit code: $?)"
                    echo "  This won't affect your lab results."
                    if [ "${DEBUG_LAB:-}" != "1" ]; then
                        echo "  Run with DEBUG_LAB=1 to see details."
                    fi
                fi
            else
                print_color "$YELLOW" "⚠ Progress tracker not found"
                echo "  Expected: $tracker_path"
                echo "  Progress will not be recorded."
                echo ""
                echo "  To enable tracking:"
                echo "    1. Make sure track-progress.sh is in the same directory as lab-runner.sh"
                echo "    2. Expected location: $framework_dir"
            fi
            print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        else
            # Lab didn't export variables
            if [ "${DEBUG_LAB:-}" = "1" ]; then
                echo ""
                print_color "$YELLOW" "⚠ DEBUG: Lab did not export VALIDATION_SCORE/VALIDATION_TOTAL"
                echo "  Progress tracking requires these exports in validate() function:"
                echo "    export VALIDATION_SCORE=\$score"
                echo "    export VALIDATION_TOTAL=\$total"
            fi
        fi
        
        return $validation_exit
    else
        print_color "$RED" "ERROR: No validation function defined"
        exit 1
    fi
    echo ""
}

# Phase 5: Solution
show_solution() {
    print_header "PHASE 5: Solution Guide"
    
    if [ "$(type -t solution)" = "function" ]; then
        solution
    else
        print_color "$RED" "ERROR: No solution function defined"
        exit 1
    fi
    echo ""
}

# Interactive Mode - Enhanced with command execution
run_interactive() {
    print_header "Interactive Mode - Step by Step"
    
    if [ "$(type -t get_step_count)" != "function" ]; then
        print_color "$RED" "ERROR: This lab doesn't support interactive mode yet"
        print_color "$YELLOW" "Run without --interactive flag for standard mode"
        exit 1
    fi
    
    local total_steps=$(get_step_count)
    
    print_color "$CYAN" "This lab has $total_steps steps. You'll complete them one at a time."
    echo ""
    print_color "$YELLOW" "HOW IT WORKS:"
    echo "  • Read the task description"
    echo "  • Type your command(s) directly at the prompt"
    echo "  • Type 'done' when you've completed the step"
    echo "  • The system will validate your work"
    echo ""
    print_color "$CYAN" "SPECIAL COMMANDS:"
    echo "  • done       - Validate current step"
    echo "  • skip       - Skip to next step"
    echo "  • solution   - Show the solution"
    echo "  • hint       - Show a hint (if available)"
    echo "  • exit       - Exit interactive mode"
    echo ""
    
    read -p "Press ENTER to begin..." -r
    
    # Run setup first
    run_setup
    echo ""
    
    # Show prerequisites
    show_prerequisites
    
    # Present context once
    if [ "$(type -t scenario_context)" = "function" ]; then
        print_header "Lab Context"
        scenario_context
        echo ""
    fi
    
    # Loop through each step
    for ((step=1; step<=total_steps; step++)); do
        print_step_header "$step" "$total_steps"
        
        if [ "$(type -t show_step_$step)" = "function" ]; then
            "show_step_$step"
        else
            print_color "$RED" "ERROR: Step $step not defined"
            exit 1
        fi
        
        echo ""
        print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Interactive command loop for this step
        local step_complete=false
        while [ "$step_complete" = false ]; do
            # Show prompt
            print_color "$GREEN" "┌─[Step $step/$total_steps]"
            read -r -p "└─# " user_input
            
            case "$user_input" in
                done)
                    # Validate the step
                    echo ""
                    if [ "$(type -t validate_step_$step)" = "function" ]; then
                        set +e
                        if "validate_step_$step"; then
                            print_color "$GREEN" "✓ Step $step completed successfully!"
                            step_complete=true
                            
                            # Show hint for next step if available
                            if [ $step -lt $total_steps ] && [ "$(type -t hint_step_$((step+1)))" = "function" ]; then
                                echo ""
                                print_color "$CYAN" "💡 Hint for next step:"
                                "hint_step_$((step+1))"
                            fi
                            
                            echo ""
                            if [ $step -lt $total_steps ]; then
                                read -p "Press ENTER to continue to step $((step+1))..." -r
                            fi
                        else
                            print_color "$RED" "✗ Step $step validation failed"
                            echo ""
                            print_color "$YELLOW" "Try again, or type 'solution' for help"
                        fi
                        set -e
                    else
                        print_color "$YELLOW" "⚠ No validation defined for step $step"
                        step_complete=true
                    fi
                    ;;
                    
                skip)
                    print_color "$YELLOW" "⚠ Skipping step $step"
                    step_complete=true
                    ;;
                    
                solution)
                    echo ""
                    if [ "$(type -t solution_step_$step)" = "function" ]; then
                        "solution_step_$step"
                    else
                        print_color "$YELLOW" "No detailed solution available for this step"
                    fi
                    echo ""
                    ;;
                    
                hint)
                    echo ""
                    if [ "$(type -t hint_step_$step)" = "function" ]; then
                        "hint_step_$step"
                    else
                        print_color "$YELLOW" "No hint available for this step"
                    fi
                    echo ""
                    ;;
                    
                exit)
                    print_color "$YELLOW" "Exiting interactive mode"
                    exit 0
                    ;;
                    
                "")
                    # Empty input, just show prompt again
                    ;;
                    
                *)
                    # Execute the command
                    echo ""
                    set +e
                    eval "$user_input"
                    local cmd_exit=$?
                    set -e
                    
                    if [ $cmd_exit -ne 0 ]; then
                        print_color "$YELLOW" "Command exited with code $cmd_exit"
                    fi
                    echo ""
                    ;;
            esac
        done
    done
    
    # Final completion message
    echo ""
    print_header "Lab Complete!"
    print_color "$GREEN" "Congratulations! You've completed all steps."
    echo ""
    print_color "$CYAN" "You can run the full validation with:"
    print_color "$GREEN" "  sudo $0 --validate"
    echo ""
}

# Cleanup function
run_cleanup() {
    print_header "Lab Cleanup"
    
    if [ "$(type -t cleanup_lab)" = "function" ]; then
        cleanup_lab
        print_color "$GREEN" "✓ Lab environment cleaned up"
    else
        print_color "$YELLOW" "⚠ No cleanup function defined"
    fi
}

# Display usage information
show_usage() {
    cat << EOF
RHCSA Lab Framework - Usage Guide

SYNOPSIS:
    sudo ./lab-name.sh [OPTION]

OPTIONS:
    (no option)         Run complete lab workflow (setup + scenario)
    --interactive, -i   Step-by-step guided mode with validation after each task
    --validate, -v      Validate your completed work
    --solution, -s      Display the solution guide
    --objectives, -o    Show quick objectives checklist
    --cleanup, -c       Clean up lab environment
    --help, -h          Display this help message

WORKFLOW (Standard Mode):
    1. Run the lab script without options to see the scenario
    2. Complete the objectives manually on your system
    3. Run with --validate to check your work
    4. Use --solution if you need help

WORKFLOW (Interactive Mode):
    1. Run with --interactive flag
    2. Complete each step one at a time
    3. Get immediate feedback after each step
    4. Proceed when validation passes

EXAMPLES:
    sudo ./01-user-management.sh           # Standard mode (exam-style)
    sudo ./01-user-management.sh -i        # Interactive mode (learning)
    sudo ./01-user-management.sh -v        # Check your work
    ./01-user-management.sh -o             # Quick objectives list
    sudo ./01-user-management.sh -s        # View solution

DEBUG MODE:
    DEBUG_LAB=1 sudo ./lab-name.sh -v      # Show debug info for tracking

EOF
}

# Main execution logic
main() {
    local mode="${1:-scenario}"
    
    case "$mode" in
        --setup)
            check_privileges "$@"
            run_setup
            ;;
        --interactive|-i)
            check_privileges "$@"
            INTERACTIVE_MODE=true
            run_interactive
            ;;
        --validate|-v)
            check_privileges "$@"
            run_validation
            ;;
        --solution|-s)
            show_solution
            ;;
        --objectives|-o)
            show_objectives
            ;;
        --cleanup|-c)
            check_privileges "$@"
            run_cleanup
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            check_privileges "$@"
            run_setup
            show_prerequisites
            show_scenario
            ;;
    esac
}

# If this script is being sourced by a lab, don't run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    print_color "$RED" "ERROR: This is a framework script, not a standalone lab."
    echo "Please run a specific lab script instead."
    echo ""
    echo "Example: sudo ./labs/01-user-management.sh"
    exit 1
fi
