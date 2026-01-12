#!/bin/bash
# List archived planning tasks
# Usage: ./list-archive.sh [project-root] [search-term]
#
# Examples:
#   ./list-archive.sh                    # List all archives
#   ./list-archive.sh . task-16          # Search for task-16
#   ./list-archive.sh . auth             # Search for "auth"

set -e

PROJECT_ROOT="${1:-.}"
SEARCH_TERM="${2:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

cd "$PROJECT_ROOT"

ARCHIVE_DIR=".planning/archive"

# Check if archive directory exists
if [ ! -d "$ARCHIVE_DIR" ]; then
    echo -e "${YELLOW}No archive found at ${ARCHIVE_DIR}${NC}"
    echo "No tasks have been archived yet."
    exit 0
fi

# Get list of archived tasks
if [ -n "$SEARCH_TERM" ]; then
    ARCHIVES=($(find "$ARCHIVE_DIR" -mindepth 1 -maxdepth 1 -type d -name "*${SEARCH_TERM}*" 2>/dev/null | sort -r))
    echo -e "${BLUE}Searching archives for: ${SEARCH_TERM}${NC}"
else
    ARCHIVES=($(find "$ARCHIVE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r))
    echo -e "${BLUE}All archived tasks:${NC}"
fi

echo ""

if [ ${#ARCHIVES[@]} -eq 0 ]; then
    if [ -n "$SEARCH_TERM" ]; then
        echo -e "${YELLOW}No archives found matching '${SEARCH_TERM}'${NC}"
    else
        echo -e "${YELLOW}No archived tasks found${NC}"
    fi
    exit 0
fi

# Display archives
printf "%-30s %-15s %-10s %s\n" "ARCHIVE" "TASK ID" "PHASES" "COMPLETED"
printf "%-30s %-15s %-10s %s\n" "-------" "-------" "------" "---------"

for ARCHIVE in "${ARCHIVES[@]}"; do
    ARCHIVE_NAME=$(basename "$ARCHIVE")

    # Extract info from .taskinfo if available
    TASK_ID="-"
    COMPLETED="-"
    if [ -f "${ARCHIVE}/.taskinfo" ]; then
        source "${ARCHIVE}/.taskinfo" 2>/dev/null || true
        if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "" ]; then
            TASK_ID_DISPLAY="$TASK_ID"
        else
            TASK_ID_DISPLAY="-"
        fi
        if [ -n "$COMPLETED" ] && [ "$COMPLETED" != "" ]; then
            COMPLETED_DISPLAY="$COMPLETED"
        else
            COMPLETED_DISPLAY="-"
        fi
    else
        TASK_ID_DISPLAY="-"
        COMPLETED_DISPLAY="-"
    fi

    # Count phases
    PHASES_INFO="-"
    if [ -f "${ARCHIVE}/task_plan.md" ]; then
        PHASES_COMPLETE=$(grep -c "Status:\*\* complete" "${ARCHIVE}/task_plan.md" 2>/dev/null || echo "0")
        PHASES_TOTAL=$(grep -c "### Phase" "${ARCHIVE}/task_plan.md" 2>/dev/null || echo "0")
        PHASES_INFO="${PHASES_COMPLETE}/${PHASES_TOTAL}"
    fi

    printf "%-30s %-15s %-10s %s\n" "$ARCHIVE_NAME" "$TASK_ID_DISPLAY" "$PHASES_INFO" "$COMPLETED_DISPLAY"
done

echo ""
echo -e "${CYAN}Total: ${#ARCHIVES[@]} archived task(s)${NC}"
echo ""

# Show usage hints
echo "To view an archive:"
echo "  cat .planning/archive/<archive-name>/task_plan.md"
echo "  cat .planning/archive/<archive-name>/findings.md"
echo "  cat .planning/archive/<archive-name>/progress.md"
echo ""
echo "To search archives:"
echo "  /planning-with-files list <search-term>"
