---
name: planning-with-files
version: "4.0.0"
description: Sisyphus 실행 컨텍스트 관리. Prometheus 전략 계획과 보완하여 작업 중 상태를 추적. 5+ 단계 복잡한 작업에 사용.
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
          command: "echo '[planning-with-files] Ready. Commands: start <name>, done, list'"
  PreToolUse:
    - matcher: "Write|Edit|Bash"
      hooks:
        - type: command
          command: "cat .sisyphus/active/*/tracker.md 2>/dev/null | head -30 || true"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "echo '[planning-with-files] File updated. Update tracker.md if phase complete.'"
  Stop:
    - hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/check-complete.sh"
---

# Planning with Files

Manus 스타일의 "working memory on disk" 구현. Prometheus 전략 계획과 보완하여 실행 중 컨텍스트를 관리.

## Prometheus와의 관계

| 도구 | 역할 | 산출물 |
|------|------|--------|
| **Prometheus** | 전략적 계획 (Why, What) | `.sisyphus/plans/{task}.md` |
| **planning-with-files** | 실행 컨텍스트 (Where, How) | `.sisyphus/active/{task}/` |

```
Prometheus = 설계도 (참조용, 상세)
planning-with-files = 현장 일지 (작업용, 가벼움)
```

## Commands

```bash
/planning-with-files start <name>   # 실행 컨텍스트 생성
/planning-with-files done           # 완료 및 아카이브
/planning-with-files list           # 아카이브 목록
```

## Folder Structure

```
.sisyphus/
├── plans/                    # Prometheus 전략 계획 (READ 참조)
│   └── {task}.md            # 상세하고 변경 적음
│
├── drafts/                   # Prometheus 초안
│   └── {task}.md
│
├── active/                   # 현재 실행 중 (planning-with-files)
│   └── {task}/
│       ├── tracker.md       # 가벼운 상태 추적
│       ├── findings.md      # 연구/발견
│       └── progress.md      # 세션 로그
│
└── archive/                  # 완료된 작업
    └── YYYY-MM-DD_{task}/
```

## File Purposes

| File | Purpose | When to Update |
|------|---------|----------------|
| `tracker.md` | Phase 상태, 간단한 결정 | Phase 완료 시 |
| `findings.md` | 연구, 발견, 기술 노트 | 발견 즉시 (2-Action Rule) |
| `progress.md` | 세션 로그, 테스트 결과, 에러 | 지속적으로 |

## Workflow

### With Prometheus (Recommended)

```
1. /prometheus auth-system
   → 인터뷰 진행
   → .sisyphus/plans/auth-system.md 생성 (상세 계획)

2. /planning-with-files start auth-system
   → .sisyphus/plans/auth-system.md 감지
   → .sisyphus/active/auth-system/ 생성
   → tracker.md에 plan 참조 링크 포함
   → findings.md, progress.md 생성

3. Work on task...
   → 2개 작업마다 findings.md 업데이트
   → phase 완료 시 tracker.md 업데이트
   → 에러 발생 시 progress.md에 기록

4. /planning-with-files done
   → .sisyphus/archive/2026-01-25_auth-system/ 이동
   → plans/auth-system.md는 유지 (레퍼런스)
```

### Standalone (Without Prometheus)

```
1. /planning-with-files start quick-fix
   → .sisyphus/active/quick-fix/ 생성
   → tracker.md (기본 템플릿), findings.md, progress.md 생성

2. Work on task...

3. /planning-with-files done
   → 아카이브
```

## The Core Pattern

```
Context Window = RAM (volatile, limited)
Filesystem = Disk (persistent, unlimited)

→ Anything important gets written to disk.
```

## Critical Rules

### 1. The 2-Action Rule
> "After every 2 view/browser/search operations, IMMEDIATELY save key findings to findings.md."

### 2. Read Before Decide
Before major decisions, read tracker.md and findings.md. This keeps goals in your attention window.

### 3. Update After Act
After completing any phase:
- Mark phase status in tracker.md: `in_progress` → `complete`
- Log actions in progress.md
- Note files created/modified

### 4. Log ALL Errors
Every error goes in progress.md. This prevents repetition.

```markdown
## Errors
| Timestamp | Error | Resolution |
|-----------|-------|------------|
| 14:30 | FileNotFoundError | Created default config |
```

### 5. Never Repeat Failures
```
if action_failed:
    next_action != same_action
```

## The 3-Strike Error Protocol

```
ATTEMPT 1: Diagnose & Fix
  → Read error carefully
  → Identify root cause
  → Apply targeted fix

ATTEMPT 2: Alternative Approach
  → Same error? Try different method
  → NEVER repeat exact same failing action

ATTEMPT 3: Broader Rethink
  → Question assumptions
  → Search for solutions
  → Update the plan

AFTER 3 FAILURES: Escalate to User
```

## The 5-Question Reboot Test

| Question | Answer Source |
|----------|---------------|
| Where am I? | Current phase in tracker.md |
| Where am I going? | Remaining phases |
| What's the goal? | plans/{task}.md or tracker.md |
| What have I learned? | findings.md |
| What have I done? | progress.md |

## When to Use

**Use for:**
- Multi-step tasks (5+ steps)
- Research-heavy work
- Tasks spanning many tool calls
- After `/prometheus` planning

**Skip for:**
- Simple questions
- Single-file edits
- Quick lookups

## Templates

Templates in `${CLAUDE_PLUGIN_ROOT}/templates/`:

- [templates/tracker.md](templates/tracker.md) — Phase tracking (lightweight)
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
| Use TodoWrite for persistence | Create tracker.md file |
| State goals once and forget | Re-read plan before decisions |
| Hide errors and retry silently | Log errors to progress.md |
| Start executing immediately | Create context files FIRST |
| Repeat failed actions | Track attempts, mutate approach |
| Duplicate Prometheus plan | Reference it in tracker.md |
