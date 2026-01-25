#!/bin/bash
# Check if all phases in current task's tracker.md are complete
# Exit 0 if complete or no active task, exit 1 if incomplete
# Used by Stop hook to verify task completion

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

ACTIVE_DIR=".sisyphus/active"

# Find active task folder
TASK_FOLDER=""
if [ -d "$ACTIVE_DIR" ]; then
    TASK_FOLDER=$(find "$ACTIVE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
fi

if [ -z "$TASK_FOLDER" ] || [ ! -d "$TASK_FOLDER" ]; then
    # No active planning task - that's OK
    exit 0
fi

TRACKER_FILE="${TASK_FOLDER}/tracker.md"
FOLDER_NAME=$(basename "$TASK_FOLDER")

if [ ! -f "$TRACKER_FILE" ]; then
    echo "WARNING: tracker.md not found in ${TASK_FOLDER}"
    exit 0
fi

echo "=== Task Completion Check: ${FOLDER_NAME} ==="
echo ""

# Count phases by checkbox status
COMPLETE=$(grep -c "\[x\]" "$TRACKER_FILE" 2>/dev/null || echo "0")
INCOMPLETE=$(grep -c "\[ \]" "$TRACKER_FILE" 2>/dev/null || echo "0")
TOTAL=$((COMPLETE + INCOMPLETE))

# Default to 0 if empty
: "${TOTAL:=0}"
: "${COMPLETE:=0}"
: "${INCOMPLETE:=0}"

echo "Total phases:   $TOTAL"
echo "Complete:       $COMPLETE"
echo "Incomplete:     $INCOMPLETE"
echo ""

# Check if linked to Prometheus plan
if [ -f "${TASK_FOLDER}/.meta" ]; then
    source "${TASK_FOLDER}/.meta" 2>/dev/null || true
    if [ "$HAS_PROMETHEUS_PLAN" = "true" ]; then
        echo "Prometheus Plan: $PROMETHEUS_PLAN"
        echo ""
    fi
fi

# Check completion
if [ "$COMPLETE" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo "ALL PHASES COMPLETE"
    echo ""
    echo "Ready to archive. Run: /planning-with-files done"
    exit 0
else
    echo "TASK NOT COMPLETE"
    echo ""
    echo "Continue working until all phases are complete."
    echo "Current task: ${FOLDER_NAME}"
    exit 1
fi
