# Claude Task Planning

A Claude Code skill for Manus-style file-based planning with Prometheus integration.

## What is this?

This skill implements **persistent planning files** as "working memory on disk" for complex tasks. Instead of relying solely on context windows (which are volatile and limited), important information is written to markdown files that persist across sessions.

Part of the **Sisyphus Multi-Agent System**.

### Key Features

- **File-based Planning**: `tracker.md`, `findings.md`, `progress.md`
- **Prometheus Integration**: Works with Prometheus strategic plans
- **Standalone Mode**: Can work independently without Prometheus
- **Archive System**: Completed tasks are archived with timestamps (`YYYY-MM-DD_{task}`)

## Installation

### Option 1: Copy to Claude skills folder

```bash
git clone https://github.com/leejoonpyoo/claude-task-planning.git
cp -r claude-task-planning ~/.claude/skills/planning-with-files
```

### Option 2: Symlink (recommended for development)

```bash
git clone https://github.com/leejoonpyoo/claude-task-planning.git
ln -s $(pwd)/claude-task-planning ~/.claude/skills/planning-with-files
```

## Usage

### Commands

```bash
/planning-with-files start <name>   # Start execution context
/planning-with-files done           # Complete and archive
/planning-with-files list           # List archived tasks
```

### Folder Structure

```
.sisyphus/
├── plans/                    # Prometheus strategic plans (READ reference)
│   └── {task}.md
├── drafts/                   # Prometheus drafts
│   └── {task}.md
├── active/                   # Current execution context (planning-with-files)
│   └── {task}/
│       ├── tracker.md       # Phase tracking (lightweight)
│       ├── findings.md      # Research, discoveries
│       └── progress.md      # Session log
└── archive/                  # Completed work
    └── YYYY-MM-DD_{task}/
```

## Workflow

### With Prometheus (Recommended)

```
1. /prometheus auth-system
   → Interview-based strategic planning
   → Creates .sisyphus/plans/auth-system.md

2. /planning-with-files start auth-system
   → Detects Prometheus plan
   → Creates .sisyphus/active/auth-system/
   → tracker.md references the plan

3. Work on task...
   → Update findings.md after discoveries
   → Update tracker.md after phase completion

4. /planning-with-files done
   → Archives to .sisyphus/archive/2026-01-25_auth-system/
```

### Standalone (Without Prometheus)

```
1. /planning-with-files start quick-fix
   → Creates .sisyphus/active/quick-fix/
   → tracker.md with default template

2. Work on task...

3. /planning-with-files done
   → Archives to .sisyphus/archive/2026-01-25_quick-fix/
```

## File Purposes

| File | Purpose | When to Update |
|------|---------|----------------|
| `tracker.md` | Phase tracking, quick decisions | After each phase |
| `findings.md` | Research, discoveries | After ANY discovery (2-Action Rule) |
| `progress.md` | Session log, test results | Throughout session |

## Prometheus vs planning-with-files

| Tool | Role | Output |
|------|------|--------|
| **Prometheus** | Strategic Planning (Why, What) | `.sisyphus/plans/{task}.md` |
| **planning-with-files** | Execution Context (Where, How) | `.sisyphus/active/{task}/` |

```
Prometheus = Blueprint (reference, detailed)
planning-with-files = Field Notes (working, lightweight)
```

## Core Principles

### The 2-Action Rule
> After every 2 view/browser/search operations, IMMEDIATELY save key findings to findings.md.

### Read Before Decide
Before major decisions, re-read tracker.md and findings.md to keep goals in your attention window.

### Log ALL Errors
Every error goes in progress.md. This prevents repetition and builds knowledge.

### Never Repeat Failures
```
if action_failed:
    next_action != same_action
```

## Requirements

- Claude Code CLI
- (Optional) Prometheus agent for strategic planning

## Credits

Based on [planning-with-files](https://github.com/OthmanAdi/planning-with-files) by OthmanAdi (MIT License).
Extended with Prometheus integration and Sisyphus system compatibility.

## License

MIT License
