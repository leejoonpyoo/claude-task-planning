#!/bin/bash
# Archive current planning task and optionally update Taskmaster status
# Usage: ./archive-task.sh [project-root]

set -e

PROJECT_ROOT="${1:-.}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

cd "$PROJECT_ROOT"

CURRENT_DIR=".planning/current"
ARCHIVE_DIR=".planning/archive"

# Check if current directory exists
if [ ! -d "$CURRENT_DIR" ]; then
    echo -e "${RED}Error: No active planning found at ${CURRENT_DIR}${NC}"
    exit 1
fi

# Find active task folder(s)
TASK_FOLDERS=($(find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null))

if [ ${#TASK_FOLDERS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No task folder found in ${CURRENT_DIR}${NC}"
    exit 1
fi

if [ ${#TASK_FOLDERS[@]} -gt 1 ]; then
    echo -e "${YELLOW}Multiple active tasks found:${NC}"
    for i in "${!TASK_FOLDERS[@]}"; do
        echo "  $((i+1)). $(basename "${TASK_FOLDERS[$i]}")"
    done
    read -p "Which task to archive? (1-${#TASK_FOLDERS[@]}): " SELECTION
    if [[ ! "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt ${#TASK_FOLDERS[@]} ]; then
        echo -e "${RED}Invalid selection${NC}"
        exit 1
    fi
    TASK_FOLDER="${TASK_FOLDERS[$((SELECTION-1))]}"
else
    TASK_FOLDER="${TASK_FOLDERS[0]}"
fi

FOLDER_NAME=$(basename "$TASK_FOLDER")

# Read task metadata if available
TASK_ID=""
IS_TASK_ID=false
TASKMASTER_AVAILABLE=false

if [ -f "${TASK_FOLDER}/.taskinfo" ]; then
    source "${TASK_FOLDER}/.taskinfo"
fi

# Re-check Taskmaster availability
if [ -f ".taskmaster/tasks/tasks.json" ]; then
    TASKMASTER_AVAILABLE=true
fi

echo -e "${BLUE}Archiving task: ${FOLDER_NAME}${NC}"

# Create archive folder name
ARCHIVE_NAME="${DATE}_${FOLDER_NAME}"
ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"

# Check if archive already exists
if [ -d "$ARCHIVE_PATH" ]; then
    echo -e "${YELLOW}Warning: Archive ${ARCHIVE_NAME} already exists${NC}"
    COUNTER=1
    while [ -d "${ARCHIVE_PATH}-${COUNTER}" ]; do
        ((COUNTER++))
    done
    ARCHIVE_PATH="${ARCHIVE_PATH}-${COUNTER}"
    ARCHIVE_NAME="${ARCHIVE_NAME}-${COUNTER}"
fi

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Add completion timestamp to progress.md
if [ -f "${TASK_FOLDER}/progress.md" ]; then
    echo "" >> "${TASK_FOLDER}/progress.md"
    echo "---" >> "${TASK_FOLDER}/progress.md"
    echo "**Completed:** ${TIMESTAMP}" >> "${TASK_FOLDER}/progress.md"
fi

# Update .taskinfo with completion time
if [ -f "${TASK_FOLDER}/.taskinfo" ]; then
    echo "COMPLETED=${TIMESTAMP}" >> "${TASK_FOLDER}/.taskinfo"
fi

# Move to archive
mv "$TASK_FOLDER" "$ARCHIVE_PATH"

echo -e "${GREEN}Archived to: ${ARCHIVE_PATH}${NC}"

# Update Taskmaster status if linked
if [ "$IS_TASK_ID" = true ] && [ -n "$TASK_ID" ] && [ "$TASKMASTER_AVAILABLE" = true ]; then
    echo ""
    echo -e "${BLUE}Updating Taskmaster task ${TASK_ID} to done...${NC}"

    if command -v task-master &> /dev/null; then
        if task-master set-status --id="$TASK_ID" --status=done 2>/dev/null; then
            echo -e "${GREEN}Taskmaster task ${TASK_ID} marked as done${NC}"
        else
            echo -e "${YELLOW}Warning: Could not update Taskmaster status${NC}"
            echo "You may need to manually run: task-master set-status --id=${TASK_ID} --status=done"
        fi
    else
        echo -e "${YELLOW}task-master CLI not found. Please update status manually:${NC}"
        echo "  task-master set-status --id=${TASK_ID} --status=done"
    fi
fi

# Clean up current directory if empty
rmdir "$CURRENT_DIR" 2>/dev/null || true

echo ""
echo -e "${GREEN}Task archived successfully!${NC}"
echo ""
echo "Archive location: ${ARCHIVE_PATH}"
echo ""
echo "Files archived:"
ls -la "$ARCHIVE_PATH" 2>/dev/null | grep -E "\.md$|\.taskinfo$" | awk '{print "  - " $NF}'
echo ""

# Show summary
if [ -f "${ARCHIVE_PATH}/task_plan.md" ]; then
    PHASES_COMPLETE=$(grep -c "Status:\*\* complete" "${ARCHIVE_PATH}/task_plan.md" 2>/dev/null || echo "0")
    PHASES_TOTAL=$(grep -c "### Phase" "${ARCHIVE_PATH}/task_plan.md" 2>/dev/null || echo "0")
    echo "Phases completed: ${PHASES_COMPLETE}/${PHASES_TOTAL}"
fi

echo ""
echo "To view archived tasks: /planning-with-files list"
