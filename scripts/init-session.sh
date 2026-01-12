#!/bin/bash
# Initialize planning files for a new task
# Usage: ./init-session.sh <task-name-or-id> [project-root]
#
# Examples:
#   ./init-session.sh 16              # Taskmaster task ID
#   ./init-session.sh auth-refactor   # Standalone task name

set -e

TASK_INPUT="${1:-}"
PROJECT_ROOT="${2:-.}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if input provided
if [ -z "$TASK_INPUT" ]; then
    echo -e "${RED}Error: Task name or ID required${NC}"
    echo "Usage: $0 <task-name-or-id> [project-root]"
    echo ""
    echo "Examples:"
    echo "  $0 16              # Taskmaster task ID"
    echo "  $0 auth-refactor   # Standalone task name"
    exit 1
fi

cd "$PROJECT_ROOT"

# Detect if Taskmaster is available
TASKMASTER_AVAILABLE=false
TASKMASTER_FILE=".taskmaster/tasks/tasks.json"
if [ -f "$TASKMASTER_FILE" ]; then
    TASKMASTER_AVAILABLE=true
fi

# Determine if input is a task ID (numeric) or task name
IS_TASK_ID=false
TASK_ID=""
TASK_TITLE=""
TASK_DESCRIPTION=""
TASK_DEPENDENCIES=""
TASK_SUBTASKS=""
FOLDER_NAME=""

if [[ "$TASK_INPUT" =~ ^[0-9]+$ ]]; then
    IS_TASK_ID=true
    TASK_ID="$TASK_INPUT"
    FOLDER_NAME="task-${TASK_ID}"

    if [ "$TASKMASTER_AVAILABLE" = true ]; then
        echo -e "${BLUE}Taskmaster detected. Fetching task ${TASK_ID} info...${NC}"

        # Extract task info from tasks.json using jq or python
        if command -v jq &> /dev/null; then
            # Try to find task in any tag context
            TASK_JSON=$(jq -r --arg id "$TASK_ID" '
                to_entries[] | .value.tasks[]? |
                select(.id == ($id | tonumber))
            ' "$TASKMASTER_FILE" 2>/dev/null | head -1)

            if [ -n "$TASK_JSON" ] && [ "$TASK_JSON" != "null" ]; then
                TASK_TITLE=$(echo "$TASK_JSON" | jq -r '.title // empty')
                TASK_DESCRIPTION=$(echo "$TASK_JSON" | jq -r '.description // empty')
                TASK_DEPENDENCIES=$(echo "$TASK_JSON" | jq -r '.dependencies | if . then map(tostring) | join(", ") else "" end')
                TASK_SUBTASKS=$(echo "$TASK_JSON" | jq -r '.subtasks | if . and length > 0 then map("\(.id): \(.title)") | join("\n") else "" end')
                echo -e "${GREEN}Found task: ${TASK_TITLE}${NC}"
            else
                echo -e "${YELLOW}Warning: Task ${TASK_ID} not found in Taskmaster${NC}"
            fi
        elif command -v python3 &> /dev/null; then
            TASK_INFO=$(python3 -c "
import json
import sys
try:
    with open('$TASKMASTER_FILE') as f:
        data = json.load(f)
    for tag, content in data.items():
        if 'tasks' in content:
            for task in content['tasks']:
                if task.get('id') == $TASK_ID:
                    print(task.get('title', ''))
                    print('---SEPARATOR---')
                    print(task.get('description', ''))
                    print('---SEPARATOR---')
                    deps = task.get('dependencies', [])
                    print(', '.join(map(str, deps)) if deps else '')
                    print('---SEPARATOR---')
                    subtasks = task.get('subtasks', [])
                    if subtasks:
                        for st in subtasks:
                            print(f\"{st.get('id')}: {st.get('title')}\")
                    sys.exit(0)
except Exception as e:
    pass
" 2>/dev/null)
            if [ -n "$TASK_INFO" ]; then
                TASK_TITLE=$(echo "$TASK_INFO" | sed -n '1p')
                TASK_DESCRIPTION=$(echo "$TASK_INFO" | sed -n '/---SEPARATOR---/,/---SEPARATOR---/{//!p}' | head -1)
                # Parse other fields if needed
                echo -e "${GREEN}Found task: ${TASK_TITLE}${NC}"
            fi
        else
            echo -e "${YELLOW}Warning: jq or python3 not found. Cannot fetch task details.${NC}"
        fi

        # Set Taskmaster status to in-progress
        if command -v task-master &> /dev/null; then
            echo -e "${BLUE}Setting task ${TASK_ID} status to in-progress...${NC}"
            task-master set-status --id="$TASK_ID" --status=in-progress 2>/dev/null || true
        fi
    else
        echo -e "${YELLOW}Taskmaster not found. Running in standalone mode with task-${TASK_ID} folder.${NC}"
    fi
else
    # Non-numeric: standalone mode
    FOLDER_NAME="$TASK_INPUT"
    TASK_TITLE="$TASK_INPUT"
    echo -e "${BLUE}Standalone mode: Creating planning for '${TASK_INPUT}'${NC}"
fi

# Create folder structure
PLANNING_DIR=".planning/current/${FOLDER_NAME}"

if [ -d "$PLANNING_DIR" ]; then
    echo -e "${YELLOW}Warning: ${PLANNING_DIR} already exists${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -rf "$PLANNING_DIR"
fi

mkdir -p "$PLANNING_DIR"
mkdir -p ".planning/archive"

echo -e "${BLUE}Creating planning files in ${PLANNING_DIR}...${NC}"

# Generate task_plan.md
cat > "${PLANNING_DIR}/task_plan.md" << EOF
# Task Plan: ${TASK_TITLE:-$FOLDER_NAME}

EOF

# Add Taskmaster reference section if linked
if [ "$IS_TASK_ID" = true ] && [ "$TASKMASTER_AVAILABLE" = true ]; then
    cat >> "${PLANNING_DIR}/task_plan.md" << EOF
## Taskmaster Reference
- **Task ID:** ${TASK_ID}
- **Title:** ${TASK_TITLE}
- **Dependencies:** ${TASK_DEPENDENCIES:-None}
- **Status:** in-progress

EOF
    if [ -n "$TASK_SUBTASKS" ]; then
        cat >> "${PLANNING_DIR}/task_plan.md" << EOF
### Subtasks (Reference)
$(echo "$TASK_SUBTASKS" | sed 's/^/- /')

EOF
    fi
fi

cat >> "${PLANNING_DIR}/task_plan.md" << EOF
## Goal
${TASK_DESCRIPTION:-[Describe the end state]}

## Current Phase
Phase 1

## Phases

### Phase 1: Requirements & Discovery
- [ ] Understand requirements
- [ ] Identify constraints
- [ ] Document in findings.md
- **Status:** in_progress

### Phase 2: Planning & Structure
- [ ] Define approach
- [ ] Create structure if needed
- **Status:** pending

### Phase 3: Implementation
- [ ] Execute the plan
- [ ] Test incrementally
- **Status:** pending

### Phase 4: Testing & Verification
- [ ] Verify requirements met
- [ ] Document test results
- **Status:** pending

### Phase 5: Delivery
- [ ] Review outputs
- [ ] Deliver to user
- **Status:** pending

## Decisions Made
| Decision | Rationale |
|----------|-----------|
|          |           |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |
EOF

# Generate findings.md
cat > "${PLANNING_DIR}/findings.md" << EOF
# Findings & Decisions

## Task: ${TASK_TITLE:-$FOLDER_NAME}
EOF

if [ "$IS_TASK_ID" = true ] && [ -n "$TASK_DESCRIPTION" ]; then
    cat >> "${PLANNING_DIR}/findings.md" << EOF

## Description (from Taskmaster)
${TASK_DESCRIPTION}
EOF
fi

cat >> "${PLANNING_DIR}/findings.md" << EOF

## Requirements
-

## Research Findings
-

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
|          |           |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
|       |            |

## Resources
-

---
*Update after every 2 view/browser/search operations*
EOF

# Generate progress.md
cat > "${PLANNING_DIR}/progress.md" << EOF
# Progress Log

## Task: ${TASK_TITLE:-$FOLDER_NAME}
EOF

if [ "$IS_TASK_ID" = true ]; then
    cat >> "${PLANNING_DIR}/progress.md" << EOF
- **Taskmaster ID:** ${TASK_ID}
EOF
fi

cat >> "${PLANNING_DIR}/progress.md" << EOF
- **Started:** ${TIMESTAMP}

## Session: ${DATE}

### Phase 1: Requirements & Discovery
- **Status:** in_progress
- **Started:** ${TIMESTAMP}
- Actions taken:
  -
- Files created/modified:
  -

### Phase 2: Planning & Structure
- **Status:** pending
- Actions taken:
  -
- Files created/modified:
  -

## Test Results
| Test | Input | Expected | Actual | Status |
|------|-------|----------|--------|--------|
|      |       |          |        |        |

## Error Log
| Timestamp | Error | Attempt | Resolution |
|-----------|-------|---------|------------|
|           |       | 1       |            |

## 5-Question Reboot Check
| Question | Answer |
|----------|--------|
| Where am I? | Phase 1 |
| Where am I going? | Phases 2-5 |
| What's the goal? | ${TASK_TITLE:-$FOLDER_NAME} |
| What have I learned? | See findings.md |
| What have I done? | See above |

---
*Update after completing each phase or encountering errors*
EOF

# Create .taskinfo file to track task metadata
cat > "${PLANNING_DIR}/.taskinfo" << EOF
TASK_INPUT=${TASK_INPUT}
TASK_ID=${TASK_ID}
FOLDER_NAME=${FOLDER_NAME}
IS_TASK_ID=${IS_TASK_ID}
TASKMASTER_AVAILABLE=${TASKMASTER_AVAILABLE}
CREATED=${TIMESTAMP}
EOF

echo ""
echo -e "${GREEN}Planning initialized!${NC}"
echo ""
echo "Files created:"
echo "  - ${PLANNING_DIR}/task_plan.md"
echo "  - ${PLANNING_DIR}/findings.md"
echo "  - ${PLANNING_DIR}/progress.md"
echo ""
if [ "$IS_TASK_ID" = true ] && [ "$TASKMASTER_AVAILABLE" = true ]; then
    echo -e "${GREEN}Taskmaster task ${TASK_ID} set to in-progress${NC}"
fi
echo ""
echo "Next steps:"
echo "  1. Review task_plan.md"
echo "  2. Start working on Phase 1"
echo "  3. Update findings.md as you discover things"
echo "  4. Run '/planning-with-files done' when complete"
