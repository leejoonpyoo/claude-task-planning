#!/bin/bash
# Archive current planning task
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

ACTIVE_DIR=".sisyphus/active"
ARCHIVE_DIR=".sisyphus/archive"

# Check if active directory exists
if [ ! -d "$ACTIVE_DIR" ]; then
    echo -e "${RED}Error: No active planning found at ${ACTIVE_DIR}${NC}"
    exit 1
fi

# Find active task folder(s)
TASK_FOLDERS=($(find "$ACTIVE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null))

if [ ${#TASK_FOLDERS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No task folder found in ${ACTIVE_DIR}${NC}"
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

TASK_NAME=$(basename "$TASK_FOLDER")

echo -e "${BLUE}Archiving task: ${TASK_NAME}${NC}"

# Create archive folder name: YYYY-MM-DD_{task}
ARCHIVE_NAME="${DATE}_${TASK_NAME}"
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

# Update .meta with completion time
if [ -f "${TASK_FOLDER}/.meta" ]; then
    echo "COMPLETED=${TIMESTAMP}" >> "${TASK_FOLDER}/.meta"
fi

# Move to archive
mv "$TASK_FOLDER" "$ARCHIVE_PATH"

echo -e "${GREEN}Archived to: ${ARCHIVE_PATH}${NC}"

# Clean up active directory if empty
rmdir "$ACTIVE_DIR" 2>/dev/null || true

echo ""
echo -e "${GREEN}Task archived successfully!${NC}"
echo ""
echo "Archive location: ${ARCHIVE_PATH}"
echo ""
echo "Files archived:"
ls -la "$ARCHIVE_PATH" 2>/dev/null | grep -E "\.md$|\.meta$" | awk '{print "  - " $NF}'
echo ""

# Show summary
if [ -f "${ARCHIVE_PATH}/tracker.md" ]; then
    PHASES_COMPLETE=$(grep -c "\[x\]" "${ARCHIVE_PATH}/tracker.md" 2>/dev/null || echo "0")
    PHASES_TOTAL=$(grep -c "\[ \]" "${ARCHIVE_PATH}/tracker.md" 2>/dev/null || echo "0")
    PHASES_TOTAL=$((PHASES_COMPLETE + PHASES_TOTAL))
    echo "Phases completed: ${PHASES_COMPLETE}/${PHASES_TOTAL}"
fi

echo ""
echo "To view archived tasks: /planning-with-files list"
