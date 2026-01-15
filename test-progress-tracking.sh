#!/bin/bash
# test-progress-tracking.sh
# Test if progress tracking is working

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Progress Tracking Test"
echo "═══════════════════════════════════════════════════════"
echo ""

# Find where this script is
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
echo ""

# Test 1: Check for required files
echo "[1] Checking for required files..."
echo ""

if [ -f "$SCRIPT_DIR/lab-runner.sh" ]; then
    echo -e "${GREEN}✓${NC} lab-runner.sh found"
else
    echo -e "${RED}✗${NC} lab-runner.sh NOT found"
    echo "   Expected at: $SCRIPT_DIR/lab-runner.sh"
fi

if [ -f "$SCRIPT_DIR/track-progress.sh" ]; then
    echo -e "${GREEN}✓${NC} track-progress.sh found"
else
    echo -e "${RED}✗${NC} track-progress.sh NOT found"
    echo "   Expected at: $SCRIPT_DIR/track-progress.sh"
fi

echo ""

# Test 2: Check lab-runner.sh for proper tracking code
echo "[2] Checking lab-runner.sh tracking code..."
echo ""

if grep -q 'framework_dir.*BASH_SOURCE' "$SCRIPT_DIR/lab-runner.sh" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} lab-runner.sh has NEW tracking code (uses BASH_SOURCE)"
    TRACKING_CODE="NEW"
elif grep -q 'SCRIPT_DIR.*track-progress' "$SCRIPT_DIR/lab-runner.sh" 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} lab-runner.sh has OLD tracking code (uses SCRIPT_DIR)"
    echo "   This might not work correctly!"
    TRACKING_CODE="OLD"
else
    echo -e "${RED}✗${NC} lab-runner.sh has NO tracking code"
    TRACKING_CODE="NONE"
fi

echo ""

# Test 3: Manually test track-progress.sh
echo "[3] Testing track-progress.sh manually..."
echo ""

if [ -f "$SCRIPT_DIR/track-progress.sh" ]; then
    echo "Running: bash track-progress.sh --record 'Test Lab' 5 6"
    
    # Run the command and capture output
    OUTPUT=$(bash "$SCRIPT_DIR/track-progress.sh" --record "Test Lab" 5 6 2>&1)
    RESULT=$?
    
    if [ $RESULT -eq 0 ]; then
        echo -e "${GREEN}✓${NC} track-progress.sh executed successfully"
    else
        echo -e "${RED}✗${NC} track-progress.sh failed with exit code: $RESULT"
        echo "Output: $OUTPUT"
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping (track-progress.sh not found)"
fi

echo ""

# Test 4: Check if progress file was created
echo "[4] Checking for lab_progress.txt..."
echo ""

if [ -f "$SCRIPT_DIR/lab_progress.txt" ]; then
    echo -e "${GREEN}✓${NC} lab_progress.txt exists"
    echo ""
    echo "File location: $SCRIPT_DIR/lab_progress.txt"
    echo ""
    echo "Recent entries:"
    tail -3 "$SCRIPT_DIR/lab_progress.txt" | grep -v '^#'
else
    echo -e "${YELLOW}⚠${NC} lab_progress.txt doesn't exist yet"
    echo "   This is normal if you haven't validated a lab yet"
fi

echo ""

# Test 5: Find a lab and check if it exports variables
echo "[5] Checking if labs export validation variables..."
echo ""

SAMPLE_LAB=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f ! -name "lab-runner.sh" ! -name "track-progress.sh" ! -name "test-progress-tracking.sh" ! -name "diagnose-tracking.sh" | head -1)

if [ -n "$SAMPLE_LAB" ]; then
    LAB_NAME=$(basename "$SAMPLE_LAB")
    echo "Checking: $LAB_NAME"
    echo ""
    
    if grep -q "export VALIDATION_SCORE" "$SAMPLE_LAB" && \
       grep -q "export VALIDATION_TOTAL" "$SAMPLE_LAB"; then
        echo -e "${GREEN}✓${NC} Lab exports VALIDATION_SCORE and VALIDATION_TOTAL"
    else
        echo -e "${RED}✗${NC} Lab does NOT export validation variables"
        echo ""
        echo "Your lab needs these lines in validate() function:"
        echo "    export VALIDATION_SCORE=\$score"
        echo "    export VALIDATION_TOTAL=\$total"
    fi
else
    echo -e "${YELLOW}⚠${NC} No lab files found to check"
fi

echo ""

# Test 6: Simulate what happens during validation
echo "[6] Simulating lab validation tracking..."
echo ""

if [ "$TRACKING_CODE" = "NEW" ] && [ -f "$SCRIPT_DIR/track-progress.sh" ]; then
    echo "Simulating: A lab just finished validation with score 6/6"
    echo ""
    
    # Set the variables that a lab would export
    export LAB_NAME="Test Simulation Lab"
    export VALIDATION_SCORE=6
    export VALIDATION_TOTAL=6
    
    # Simulate what lab-runner.sh does
    framework_dir="$SCRIPT_DIR"
    tracker_path="${framework_dir}/track-progress.sh"
    
    echo "Framework dir: $framework_dir"
    echo "Tracker path: $tracker_path"
    echo "Tracker exists: $([ -f "$tracker_path" ] && echo "YES" || echo "NO")"
    echo ""
    
    if [ -f "$tracker_path" ]; then
        echo "Calling: bash '$tracker_path' --record '$LAB_NAME' '$VALIDATION_SCORE' '$VALIDATION_TOTAL'"
        bash "$tracker_path" --record "$LAB_NAME" "$VALIDATION_SCORE" "$VALIDATION_TOTAL"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Tracking call succeeded"
            
            # Check if it was actually recorded
            if grep -q "Test Simulation Lab" "$SCRIPT_DIR/lab_progress.txt" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} Entry was written to lab_progress.txt"
            else
                echo -e "${RED}✗${NC} Entry NOT found in lab_progress.txt"
            fi
        else
            echo -e "${RED}✗${NC} Tracking call failed"
        fi
    else
        echo -e "${RED}✗${NC} tracker_path not found"
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping (prerequisites not met)"
fi

echo ""

# Summary
echo "═══════════════════════════════════════════════════════"
echo "  Summary & Recommendations"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ "$TRACKING_CODE" = "OLD" ]; then
    echo -e "${YELLOW}⚠ ACTION REQUIRED:${NC}"
    echo "  Your lab-runner.sh uses OLD tracking code."
    echo "  Replace it with the NEW version that uses BASH_SOURCE."
    echo ""
elif [ "$TRACKING_CODE" = "NONE" ]; then
    echo -e "${RED}✗ PROBLEM:${NC}"
    echo "  Your lab-runner.sh has no tracking code at all."
    echo "  You need to update lab-runner.sh."
    echo ""
fi

if [ ! -f "$SCRIPT_DIR/track-progress.sh" ]; then
    echo -e "${RED}✗ PROBLEM:${NC}"
    echo "  track-progress.sh is missing!"
    echo "  Make sure it's in the same directory as lab-runner.sh"
    echo ""
fi

echo "To test with an actual lab:"
echo "  1. DEBUG_LAB=1 sudo ./13-awk-sed.sh --validate"
echo "  2. ./track-progress.sh --summary"
echo ""

if [ -f "$SCRIPT_DIR/lab_progress.txt" ]; then
    echo "Your progress file is at:"
    echo "  $SCRIPT_DIR/lab_progress.txt"
    echo ""
fi
