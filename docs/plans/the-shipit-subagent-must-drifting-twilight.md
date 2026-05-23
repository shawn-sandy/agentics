# Plan: Add ExitPlanMode Permission to ship-autonomous Skill

## Context

When Plan Mode is active, the `ship-autonomous` skill cannot proceed because
committing, pushing, and opening PRs are mutations that are blocked in plan
mode. The skill needs to call `ExitPlanMode` at the start to exit plan mode
before any mutations run.

`ExitPlanMode` is a **deferred tool** — its schema is not loaded at session
start. The harness rules (`plugin-patterns.md`) require:
1. Both `ToolSearch` **and** `ExitPlanMode` listed in `allowed-tools`
2. A step that calls `ToolSearch` with `select:ExitPlanMode` before calling
   `ExitPlanMode`

Currently the skill's `allowed-tools` has neither, so the harness prompts the
user for permission mid-run (or blocks the skill entirely in plan mode).

## File to Modify

`/home/user/agentics/.claude/skills/ship-autonomous/SKILL.md`

## Changes

### 1. Frontmatter — add `ToolSearch` and `ExitPlanMode` to `allowed-tools`

Current line 7:
```
allowed-tools: Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(jq *), Skill, Read, Edit, Grep, Glob, TodoWrite, AskUserQuestion
```

New:
```
allowed-tools: Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(jq *), Skill, Read, Edit, Grep, Glob, TodoWrite, AskUserQuestion, ToolSearch, ExitPlanMode
```

### 2. Body — insert Step 0 before Step 1

Add a new `## Step 0: Exit Plan Mode` section immediately before
`## Step 1: Pre-flight Guards` (mirrors the pattern already used in
`agent-ship.md`):

```markdown
## Step 0: Exit Plan Mode

Call `ExitPlanMode` immediately and silently — always, unconditionally, before
any other action. This is a no-op when plan mode is already off, so it is safe
to call regardless. Committing, pushing, and opening a PR are mutations that
cannot proceed inside plan mode.

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode`
first to load its schema, then call `ExitPlanMode`. Both steps run silently
with no user-visible output.

---
```

## Verification

- Load the skill locally: `claude --plugin-dir ./kit/plugins/git-agent`
  (ship-autonomous lives in `.claude/skills/` so it's always active, no plugin
  flag needed)
- Activate plan mode (`/plan`) and then trigger the skill by saying "ship it"
- Confirm Step 0 runs without a permission prompt and plan mode is exited
  before the pre-flight guards run
- Confirm the rest of the ship flow completes normally
