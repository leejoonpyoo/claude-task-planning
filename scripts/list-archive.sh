#!/bin/bash
# List archived planning tasks
# Usage: ./list-archive.sh [project-root] [search-term]
#
# Examples:
#   ./list-archive.sh                    # List all archives
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

ARCHIVE_DIR=".sisyphus/archive"

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
printf "%-35s %-10s %s\n" "ARCHIVE" "PHASES" "COMPLETED"
printf "%-35s %-10s %s\n" "-------" "------" "---------"

for ARCHIVE in "${ARCHIVES[@]}"; do
    ARCHIVE_NAME=$(basename "$ARCHIVE")

    # Extract completion time from .meta if available
    COMPLETED="-"
    if [ -f "${ARCHIVE}/.meta" ]; then
        source "${ARCHIVE}/.meta" 2>/dev/null || true
        if [ -n "$COMPLETED" ] && [ "$COMPLETED" != "" ]; then
            COMPLETED_DISPLAY="$COMPLETED"
        else
            COMPLETED_DISPLAY="-"
        fi
    else
        COMPLETED_DISPLAY="-"
    fi

    # Count phases from tracker.md
    PHASES_INFO="-"
    if [ -f "${ARCHIVE}/tracker.md" ]; then
        PHASES_COMPLETE=$(grep -c "\[x\]" "${ARCHIVE}/tracker.md" 2>/dev/null) || PHASES_COMPLETE=0
        PHASES_INCOMPLETE=$(grep -c "\[ \]" "${ARCHIVE}/tracker.md" 2>/dev/null) || PHASES_INCOMPLETE=0
        PHASES_TOTAL=$((PHASES_COMPLETE + PHASES_INCOMPLETE))
        if [ "$PHASES_TOTAL" -gt 0 ]; then
            PHASES_INFO="${PHASES_COMPLETE}/${PHASES_TOTAL}"
        fi
    fi

    printf "%-35s %-10s %s\n" "$ARCHIVE_NAME" "$PHASES_INFO" "$COMPLETED_DISPLAY"
done

echo ""
echo -e "${CYAN}Total: ${#ARCHIVES[@]} archived task(s)${NC}"
echo ""

# Show usage hints
echo "To view an archive:"
echo "  cat .sisyphus/archive/<archive-name>/tracker.md"
echo "  cat .sisyphus/archive/<archive-name>/findings.md"
echo "  cat .sisyphus/archive/<archive-name>/progress.md"
echo ""
echo "To search archives:"
echo "  /planning-with-files list <search-term>"
