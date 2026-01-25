#!/bin/bash
# Initialize planning files for a new task
# Usage: ./init-session.sh <task-name> [project-root]
#
# Integrates with Prometheus plans in .sisyphus/plans/

set -e

TASK_NAME="${1:-}"
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
if [ -z "$TASK_NAME" ]; then
    echo -e "${RED}Error: Task name required${NC}"
    echo "Usage: $0 <task-name> [project-root]"
    echo ""
    echo "Examples:"
    echo "  $0 auth-system       # Create context for auth-system task"
    echo "  $0 quick-fix         # Standalone task"
    exit 1
fi

cd "$PROJECT_ROOT"

# Check for Prometheus plan
PROMETHEUS_PLAN=".sisyphus/plans/${TASK_NAME}.md"
PLAN_REFERENCE=""
HAS_PROMETHEUS_PLAN=false

if [ -f "$PROMETHEUS_PLAN" ]; then
    HAS_PROMETHEUS_PLAN=true
    PLAN_REFERENCE="**Strategic Plan:** ../plans/${TASK_NAME}.md"
    echo -e "${GREEN}Prometheus plan detected: ${PROMETHEUS_PLAN}${NC}"
else
    echo -e "${BLUE}Standalone mode: No Prometheus plan found${NC}"
fi

# Create folder structure
ACTIVE_DIR=".sisyphus/active/${TASK_NAME}"

if [ -d "$ACTIVE_DIR" ]; then
    echo -e "${YELLOW}Warning: ${ACTIVE_DIR} already exists${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -rf "$ACTIVE_DIR"
fi

mkdir -p "$ACTIVE_DIR"
mkdir -p ".sisyphus/archive"
mkdir -p ".sisyphus/plans"
mkdir -p ".sisyphus/drafts"

echo -e "${BLUE}Creating planning files in ${ACTIVE_DIR}...${NC}"

# Generate tracker.md
cat > "${ACTIVE_DIR}/tracker.md" << EOF
# Task: ${TASK_NAME}

${PLAN_REFERENCE}
**Started:** ${TIMESTAMP}
**Current Phase:** Phase 1

## Goal
[한 문장으로 최종 상태 설명]

## Phases
- [ ] Phase 1: Discovery — in_progress
- [ ] Phase 2: Implementation — pending
- [ ] Phase 3: Verification — pending
- [ ] Phase 4: Delivery — pending

## Quick Decisions
| Decision | Rationale |
|----------|-----------|
|          |           |

## Errors
| Error | Resolution |
|-------|------------|
|       |            |

---
*Update after completing each phase*
EOF

# Generate findings.md
cat > "${ACTIVE_DIR}/findings.md" << EOF
# Findings: ${TASK_NAME}

**Task:** ${TASK_NAME}
**Started:** ${TIMESTAMP}
${PLAN_REFERENCE}

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

## Visual/Browser Findings
-

---
*Update after every 2 view/browser/search operations (2-Action Rule)*
EOF

# Generate progress.md
cat > "${ACTIVE_DIR}/progress.md" << EOF
# Progress Log: ${TASK_NAME}

**Started:** ${TIMESTAMP}
${PLAN_REFERENCE}

## Session: ${DATE}

### Phase 1: Discovery
- **Status:** in_progress
- **Started:** ${TIMESTAMP}
- Actions taken:
  -
- Files created/modified:
  -

### Phase 2: Implementation
- **Status:** pending
- Actions taken:
  -
- Files created/modified:
  -

### Phase 3: Verification
- **Status:** pending
- Actions taken:
  -

### Phase 4: Delivery
- **Status:** pending
- Actions taken:
  -

## Test Results
| Test | Expected | Actual | Status |
|------|----------|--------|--------|
|      |          |        |        |

## Error Log
| Timestamp | Error | Attempt | Resolution |
|-----------|-------|---------|------------|
|           |       | 1       |            |

## 5-Question Reboot Check
| Question | Answer |
|----------|--------|
| Where am I? | Phase 1 |
| Where am I going? | Phases 2-4 |
| What's the goal? | See tracker.md |
| What have I learned? | See findings.md |
| What have I done? | See above |

---
*Update after completing each phase or encountering errors*
EOF

# Create .meta file to track task metadata
cat > "${ACTIVE_DIR}/.meta" << EOF
TASK_NAME=${TASK_NAME}
HAS_PROMETHEUS_PLAN=${HAS_PROMETHEUS_PLAN}
PROMETHEUS_PLAN=${PROMETHEUS_PLAN}
CREATED=${TIMESTAMP}
EOF

echo ""
echo -e "${GREEN}Planning initialized!${NC}"
echo ""
echo "Files created:"
echo "  - ${ACTIVE_DIR}/tracker.md"
echo "  - ${ACTIVE_DIR}/findings.md"
echo "  - ${ACTIVE_DIR}/progress.md"
echo ""

if [ "$HAS_PROMETHEUS_PLAN" = true ]; then
    echo -e "${GREEN}Linked to Prometheus plan: ${PROMETHEUS_PLAN}${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Review tracker.md and set the goal"
echo "  2. Start working on Phase 1"
echo "  3. Update findings.md as you discover things"
echo "  4. Run '/planning-with-files done' when complete"
