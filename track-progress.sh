#!/bin/bash
# track-progress.sh
# RHCSA Lab Progress Tracker

# Determine script directory and progress file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR="."
PROGRESS_FILE="${SCRIPT_DIR}/lab_progress.txt"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Record a lab result
record_result() {
    local lab_name="$1"
    local score="$2"
    local total="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local percentage=$((score * 100 / total))
    
    # Create file if it doesn't exist
    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "# RHCSA Lab Progress Tracker" > "$PROGRESS_FILE"
        echo "# Format: TIMESTAMP | LAB_NAME | SCORE | TOTAL | PERCENTAGE | STATUS" >> "$PROGRESS_FILE"
        echo "# ============================================================================" >> "$PROGRESS_FILE"
    fi
    
    # Determine status
    local status
    if [ $score -eq $total ]; then
        status="PASSED"
    else
        status="INCOMPLETE"
    fi
    
    # Append result
    echo "$timestamp | $lab_name | $score/$total | ${percentage}% | $status" >> "$PROGRESS_FILE"
}

# Show progress summary
show_summary() {
    if [ ! -f "$PROGRESS_FILE" ]; then
        print_color "$YELLOW" "No lab attempts recorded yet."
        echo "Complete a lab with --validate to start tracking progress."
        return
    fi
    
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║              RHCSA LAB PROGRESS SUMMARY                       ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Get unique labs
    local labs=$(grep -v '^#' "$PROGRESS_FILE" | cut -d'|' -f2 | sort -u)
    
    if [ -z "$labs" ]; then
        print_color "$YELLOW" "No lab attempts recorded yet."
        return
    fi
    
    local total_labs=0
    local passed_labs=0
    
    while IFS= read -r lab; do
        lab=$(echo "$lab" | xargs)  # Trim whitespace
        [ -z "$lab" ] && continue  # Skip empty lines
        ((total_labs++))
        
        # Get latest attempt for this lab
        local latest=$(grep "$lab" "$PROGRESS_FILE" | tail -1)
        local score=$(echo "$latest" | cut -d'|' -f3 | xargs)
        local percentage=$(echo "$latest" | cut -d'|' -f4 | xargs)
        local status=$(echo "$latest" | cut -d'|' -f5 | xargs)
        local attempts=$(grep -c "$lab" "$PROGRESS_FILE")
        
        # Color code based on status
        if [ "$status" = "PASSED" ]; then
            print_color "$GREEN" "✓ $lab"
            ((passed_labs++))
        else
            print_color "$YELLOW" "⚠ $lab"
        fi
        
        echo "    Latest: $score ($percentage) | Attempts: $attempts"
        echo ""
    done <<< "$labs"
    
    # Overall statistics
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "OVERALL PROGRESS"
    echo "  Total Labs Attempted: $total_labs"
    echo "  Labs Passed: $passed_labs"
    
    if [ $total_labs -gt 0 ]; then
        local pass_rate=$((passed_labs * 100 / total_labs))
        echo "  Pass Rate: ${pass_rate}%"
    fi
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Show detailed history for a specific lab
show_lab_history() {
    local lab_name="$1"
    
    if [ ! -f "$PROGRESS_FILE" ]; then
        print_color "$RED" "No progress file found."
        return
    fi
    
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD" "History for: $lab_name"
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local results=$(grep "$lab_name" "$PROGRESS_FILE" | grep -v '^#')
    
    if [ -z "$results" ]; then
        print_color "$YELLOW" "No attempts found for this lab."
        return
    fi
    
    printf "%-20s | %-8s | %-10s | %-10s\n" "TIMESTAMP" "SCORE" "PERCENTAGE" "STATUS"
    echo "------------------------------------------------------------------------"
    
    while IFS='|' read -r timestamp lab score percentage status; do
        timestamp=$(echo "$timestamp" | xargs)
        score=$(echo "$score" | xargs)
        percentage=$(echo "$percentage" | xargs)
        status=$(echo "$status" | xargs)
        
        if [ "$status" = "PASSED" ]; then
            printf "${GREEN}%-20s | %-8s | %-10s | %-10s${NC}\n" "$timestamp" "$score" "$percentage" "$status"
        else
            printf "${YELLOW}%-20s | %-8s | %-10s | %-10s${NC}\n" "$timestamp" "$score" "$percentage" "$status"
        fi
    done <<< "$results"
    echo ""
}

# Show labs that need retry (not passed)
show_retry_needed() {
    if [ ! -f "$PROGRESS_FILE" ]; then
        print_color "$YELLOW" "No lab attempts recorded yet."
        return
    fi
    
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║              LABS NEEDING RETRY                               ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    local labs=$(grep -v '^#' "$PROGRESS_FILE" | cut -d'|' -f2 | sort -u)
    local found_incomplete=false
    
    while IFS= read -r lab; do
        lab=$(echo "$lab" | xargs)
        [ -z "$lab" ] && continue
        
        local latest=$(grep "$lab" "$PROGRESS_FILE" | tail -1)
        local status=$(echo "$latest" | cut -d'|' -f5 | xargs)
        local score=$(echo "$latest" | cut -d'|' -f3 | xargs)
        local percentage=$(echo "$latest" | cut -d'|' -f4 | xargs)
        
        if [ "$status" != "PASSED" ]; then
            found_incomplete=true
            print_color "$YELLOW" "⚠ $lab"
            echo "    Latest Score: $score ($percentage)"
            echo ""
        fi
    done <<< "$labs"
    
    if [ "$found_incomplete" = false ]; then
        print_color "$GREEN" "✓ All attempted labs have been passed!"
        echo ""
        echo "Great work! Try some new labs to continue learning."
    fi
}

# Usage information
show_usage() {
    cat << EOF
RHCSA Lab Progress Tracker

SYNOPSIS:
    ./track-progress.sh [OPTION] [LAB_NAME]

OPTIONS:
    --summary, -s          Show overall progress summary (default)
    --history, -h LAB      Show attempt history for specific lab
    --retry, -r            Show labs that need retry (not passed)
    --help                 Show this help message

EXAMPLES:
    ./track-progress.sh --summary
    ./track-progress.sh --history "Basic User Management"
    ./track-progress.sh --retry

AUTOMATIC TRACKING:
    Lab results are automatically recorded when you run:
    sudo ./labs/XX-lab-name.sh --validate

FILES:
    lab_progress.txt       Progress tracking data

EOF
}

# Main execution
# IMPORTANT: Handle --record first (called by lab-runner.sh)
if [ "${1:-}" = "--record" ]; then
    shift
    record_result "$@"
    exit 0
fi

# Then handle user-facing commands
case "${1:-}" in
    --summary|-s|"")
        show_summary
        ;;
    --history|-h)
        if [ -z "${2:-}" ]; then
            print_color "$RED" "ERROR: Lab name required"
            echo "Usage: $0 --history \"Lab Name\""
            exit 1
        fi
        show_lab_history "$2"
        ;;
    --retry|-r)
        show_retry_needed
        ;;
    --help)
        show_usage
        ;;
    *)
        print_color "$RED" "Unknown option: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac