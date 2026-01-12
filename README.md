# Claude Task Planning

A Claude Code skill for Manus-style file-based planning with Taskmaster integration.

## What is this?

This skill implements **persistent planning files** as "working memory on disk" for complex tasks. Instead of relying solely on context windows (which are volatile and limited), important information is written to markdown files that persist across sessions.

### Key Features

- **File-based Planning**: `task_plan.md`, `findings.md`, `progress.md`
- **Taskmaster Integration**: Automatic status sync with [Taskmaster](https://github.com/eyaltoledano/claude-task-master)
- **Hybrid Mode**: Works standalone or linked to Taskmaster tasks
- **Archive System**: Completed tasks are archived with timestamps

## Installation

### Option 1: Copy to Claude skills folder

```bash
git clone https://github.com/YOUR_USERNAME/claude-task-planning.git
cp -r claude-task-planning ~/.claude/skills/planning-with-files
```

### Option 2: Symlink (recommended for development)

```bash
git clone https://github.com/YOUR_USERNAME/claude-task-planning.git
ln -s $(pwd)/claude-task-planning ~/.claude/skills/planning-with-files
```

## Usage

### Commands

```bash
# Start a new task (Taskmaster integration - numeric = task ID)
/planning-with-files start 16

# Start a standalone task (non-numeric = folder name)
/planning-with-files start auth-refactor

# Complete and archive current task
/planning-with-files done

# List archived tasks
/planning-with-files list
```

### Folder Structure

```
.planning/
├── current/                    # Active work
│   └── task-16/               # or: auth-refactor/
│       ├── task_plan.md       # Phases, progress, decisions
│       ├── findings.md        # Research, discoveries
│       └── progress.md        # Session log
└── archive/                   # Completed work
    ├── 2026-01-10_task-15/
    └── 2026-01-08_api-design/
```

## Workflow

### With Taskmaster

```
1. task-master next                  # Find next task
2. /planning-with-files start 16    # Creates files, sets in-progress
3. Work on task...                   # Update findings.md, progress.md
4. /planning-with-files done        # Archives, sets done
```

### Standalone

```
1. /planning-with-files start refactor-auth
2. Work on task...
3. /planning-with-files done
```

## File Purposes

| File | Purpose | When to Update |
|------|---------|----------------|
| `task_plan.md` | Phases, progress, decisions | After each phase |
| `findings.md` | Research, discoveries | After ANY discovery |
| `progress.md` | Session log, test results | Throughout session |

## Core Principles

### The 2-Action Rule
> After every 2 view/browser/search operations, IMMEDIATELY save key findings to files.

### Read Before Decide
Before major decisions, re-read the plan file to keep goals in your attention window.

### Log ALL Errors
Every error goes in the plan file. This prevents repetition and builds knowledge.

## Taskmaster Integration

When you start with a numeric ID (e.g., `start 16`):

1. **Auto-detect**: Checks for `.taskmaster/tasks/tasks.json`
2. **Fetch task info**: Pulls title, description, subtasks
3. **Set status**: Marks task as `in-progress`
4. **Include reference**: Adds Taskmaster info to `task_plan.md`

When you complete (`done`):

1. **Archive**: Moves to `.planning/archive/YYYY-MM-DD_task-16/`
2. **Sync status**: Marks Taskmaster task as `done`

## Requirements

- Claude Code CLI
- (Optional) [Taskmaster](https://github.com/eyaltoledano/claude-task-master) for task integration
- (Optional) `jq` or `python3` for parsing task info

## Credits

Based on [planning-with-files](https://github.com/OthmanAdi/planning-with-files) by OthmanAdi (MIT License).
Extended with Taskmaster integration and archive system.

## Integrates With

- [Claude Task Master](https://github.com/eyaltoledano/claude-task-master) - AI-powered task management for Claude Code

## License

MIT License
