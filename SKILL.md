---
name: planning-with-files
version: "3.0.0"
description: Implements Manus-style file-based planning for complex tasks. Creates task_plan.md, findings.md, and progress.md. Integrates with Taskmaster for task/phase synchronization. Use when starting complex multi-step tasks, research projects, or any task requiring >5 tool calls.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - WebSearch
hooks:
  SessionStart:
    - hooks:
        - type: command
          command: "echo '[planning-with-files] Ready. Commands: start [name|id], done, list'"
  PreToolUse:
    - matcher: "Write|Edit|Bash"
      hooks:
        - type: command
          command: "cat .planning/current/*/task_plan.md 2>/dev/null | head -30 || true"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "echo '[planning-with-files] File updated. If this completes a phase, update task_plan.md status.'"
  Stop:
    - hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/check-complete.sh"
---

# Planning with Files

Work like Manus: Use persistent markdown files as your "working memory on disk."

## Taskmaster Integration

This skill integrates with Taskmaster for seamless task management:

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Taskmaster Mode** | `start 16` (numeric) | Links to task ID, syncs status |
| **Standalone Mode** | `start auth-refactor` | Independent planning, no sync |
| **Auto-detect** | `.taskmaster/` exists? | Enables/disables integration |

## Commands

```bash
/planning-with-files start [name|id]   # Start new task
/planning-with-files done              # Complete & archive current task
/planning-with-files list              # List archived tasks
```

### Examples

```bash
# Taskmaster integration (numeric = task ID)
/planning-with-files start 16
# → Creates .planning/current/task-16/
# → Sets Taskmaster task 16 to in-progress
# → Includes task info in task_plan.md

# Standalone mode (non-numeric)
/planning-with-files start auth-refactor
# → Creates .planning/current/auth-refactor/
# → No Taskmaster interaction

# Complete current task
/planning-with-files done
# → Archives to .planning/archive/YYYY-MM-DD_task-16/
# → Sets Taskmaster task 16 to done (if linked)

# List past work
/planning-with-files list
# → Shows all archived tasks
```

## Folder Structure

```
.planning/
├── current/                    # Active work (one task at a time recommended)
│   └── task-16/               # or: auth-refactor/
│       ├── task_plan.md       # Phases, progress, decisions
│       ├── findings.md        # Research, discoveries
│       └── progress.md        # Session log
└── archive/                   # Completed work
    ├── 2026-01-10_task-15/
    └── 2026-01-08_api-design/
```

## File Purposes

| File | Purpose | When to Update |
|------|---------|----------------|
| `task_plan.md` | Phases, progress, decisions | After each phase |
| `findings.md` | Research, discoveries | After ANY discovery |
| `progress.md` | Session log, test results | Throughout session |

## Workflow with Taskmaster

```
1. task-master next
   → "Task 16 available"

2. /planning-with-files start 16
   → Creates .planning/current/task-16/
   → Taskmaster: task 16 → in-progress
   → task_plan.md includes task info

3. Work on task...
   → Update findings.md, progress.md

4. /planning-with-files done
   → Archives to .planning/archive/2026-01-12_task-16/
   → Taskmaster: task 16 → done
```

## Standalone Workflow

```
1. /planning-with-files start refactor-auth
   → Creates .planning/current/refactor-auth/

2. Work on task...

3. /planning-with-files done
   → Archives to .planning/archive/2026-01-12_refactor-auth/
```

## The Core Pattern

```
Context Window = RAM (volatile, limited)
Filesystem = Disk (persistent, unlimited)

→ Anything important gets written to disk.
```

## Critical Rules

### 1. Create Plan First
Never start a complex task without `task_plan.md`. Non-negotiable.

### 2. The 2-Action Rule
> "After every 2 view/browser/search operations, IMMEDIATELY save key findings to text files."

This prevents visual/multimodal information from being lost.

### 3. Read Before Decide
Before major decisions, read the plan file. This keeps goals in your attention window.

### 4. Update After Act
After completing any phase:
- Mark phase status: `in_progress` → `complete`
- Log any errors encountered
- Note files created/modified

### 5. Log ALL Errors
Every error goes in the plan file. This builds knowledge and prevents repetition.

```markdown
## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| FileNotFoundError | 1 | Created default config |
| API timeout | 2 | Added retry logic |
```

### 6. Never Repeat Failures
```
if action_failed:
    next_action != same_action
```
Track what you tried. Mutate the approach.

## The 3-Strike Error Protocol

```
ATTEMPT 1: Diagnose & Fix
  → Read error carefully
  → Identify root cause
  → Apply targeted fix

ATTEMPT 2: Alternative Approach
  → Same error? Try different method
  → Different tool? Different library?
  → NEVER repeat exact same failing action

ATTEMPT 3: Broader Rethink
  → Question assumptions
  → Search for solutions
  → Consider updating the plan

AFTER 3 FAILURES: Escalate to User
  → Explain what you tried
  → Share the specific error
  → Ask for guidance
```

## Read vs Write Decision Matrix

| Situation | Action | Reason |
|-----------|--------|--------|
| Just wrote a file | DON'T read | Content still in context |
| Viewed image/PDF | Write findings NOW | Multimodal → text before lost |
| Browser returned data | Write to file | Screenshots don't persist |
| Starting new phase | Read plan/findings | Re-orient if context stale |
| Error occurred | Read relevant file | Need current state to fix |
| Resuming after gap | Read all planning files | Recover state |

## The 5-Question Reboot Test

If you can answer these, your context management is solid:

| Question | Answer Source |
|----------|---------------|
| Where am I? | Current phase in task_plan.md |
| Where am I going? | Remaining phases |
| What's the goal? | Goal statement in plan |
| What have I learned? | findings.md |
| What have I done? | progress.md |

## When to Use This Pattern

**Use for:**
- Multi-step tasks (3+ steps)
- Research tasks
- Building/creating projects
- Tasks spanning many tool calls
- Anything requiring organization

**Skip for:**
- Simple questions
- Single-file edits
- Quick lookups

## Templates

Templates are in `${CLAUDE_PLUGIN_ROOT}/templates/`:

- [templates/task_plan.md](templates/task_plan.md) — Phase tracking
- [templates/findings.md](templates/findings.md) — Research storage
- [templates/progress.md](templates/progress.md) — Session logging

## Scripts

Helper scripts in `${CLAUDE_PLUGIN_ROOT}/scripts/`:

- `init-session.sh` — Initialize planning files
- `archive-task.sh` — Archive and complete task
- `list-archive.sh` — List archived tasks
- `check-complete.sh` — Verify all phases complete

## Advanced Topics

- **Manus Principles:** See [reference.md](reference.md)
- **Real Examples:** See [examples.md](examples.md)

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Use TodoWrite for persistence | Create task_plan.md file |
| State goals once and forget | Re-read plan before decisions |
| Hide errors and retry silently | Log errors to plan file |
| Stuff everything in context | Store large content in files |
| Start executing immediately | Create plan file FIRST |
| Repeat failed actions | Track attempts, mutate approach |
| Manually sync Taskmaster status | Use start/done commands |
