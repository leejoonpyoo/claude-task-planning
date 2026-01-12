#!/bin/bash
# Check if all phases in current task's task_plan.md are complete
# Exit 0 if complete or no active task, exit 1 if incomplete
# Used by Stop hook to verify task completion

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

CURRENT_DIR=".planning/current"

# Find active task folder
TASK_FOLDER=""
if [ -d "$CURRENT_DIR" ]; then
    TASK_FOLDER=$(find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
fi

if [ -z "$TASK_FOLDER" ] || [ ! -d "$TASK_FOLDER" ]; then
    # No active planning task - that's OK
    exit 0
fi

PLAN_FILE="${TASK_FOLDER}/task_plan.md"
FOLDER_NAME=$(basename "$TASK_FOLDER")

if [ ! -f "$PLAN_FILE" ]; then
    echo "WARNING: task_plan.md not found in ${TASK_FOLDER}"
    exit 0
fi

echo "=== Task Completion Check: ${FOLDER_NAME} ==="
echo ""

# Count phases by status
TOTAL=$(grep -c "### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
COMPLETE=$(grep -c "Status:\*\* complete" "$PLAN_FILE" 2>/dev/null || echo "0")
IN_PROGRESS=$(grep -c "Status:\*\* in_progress" "$PLAN_FILE" 2>/dev/null || echo "0")
PENDING=$(grep -c "Status:\*\* pending" "$PLAN_FILE" 2>/dev/null || echo "0")

# Default to 0 if empty
: "${TOTAL:=0}"
: "${COMPLETE:=0}"
: "${IN_PROGRESS:=0}"
: "${PENDING:=0}"

echo "Total phases:   $TOTAL"
echo "Complete:       $COMPLETE"
echo "In progress:    $IN_PROGRESS"
echo "Pending:        $PENDING"
echo ""

# Check if linked to Taskmaster
TASK_ID=""
if [ -f "${TASK_FOLDER}/.taskinfo" ]; then
    source "${TASK_FOLDER}/.taskinfo" 2>/dev/null || true
    if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "" ]; then
        echo "Taskmaster Task ID: $TASK_ID"
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
