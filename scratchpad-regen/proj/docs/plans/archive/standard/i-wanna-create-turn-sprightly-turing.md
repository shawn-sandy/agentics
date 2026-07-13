# Plan: Add Background Subagents to git-agent Plugin

## Context

The `git-agent` plugin currently exposes 4 skills (`branch-agent`, `commit-agent`, `pr-agent`, `ship`) that run synchronously in the foreground — the user has to wait for them to complete before continuing. The user wants fire-and-forget operation: say "create a commit" or "ship it" and have the work happen in a background subagent while they keep coding in the main session.

This plan adds **3 new background agents** to the plugin alongside the existing skills, mirroring the dual pattern already used by the `code-review` plugin (skill for direct invocation, agent for delegated/background use). `branch-agent` is intentionally excluded — branch creation is a synchronous setup step (you need to be ON the new branch before continuing), so backgrounding it has no benefit.

**Outcome:** Users can dispatch `commit`, `pr`, and `ship` operations as background subagents. The main session is freed up immediately; the subagent reports completion when done.

## Scope

| Skill | Convert to background agent? | Reasoning |
|---|---|---|
| `commit-agent` | ✅ Yes — `agent-commit` | Discrete, fire-and-forget. |
| `pr-agent` | ✅ Yes — `agent-pr` | Runs end-to-end without input; PR summary writing benefits from backgrounding. |
| `ship` | ✅ Yes — `agent-ship` | Full pipeline; explicit user request for background ship. |
| `branch-agent` | ❌ No | Synchronous by nature; keep skill only. |

Skills are **not** removed — they remain the synchronous path. Agents are the asynchronous/delegated path.

## Files to Create

### 1. `kit/plugins/git-agent/agents/agent-commit.md`

Background commit agent. Frontmatter:

```yaml
---
name: agent-commit
description: >
  Background git commit agent. Stages all working-tree changes and creates a
  conventional commit message without user interaction. Use when delegating
  commit creation to a subagent so the main session can continue working,
  when the user asks to "commit in the background", "commit and keep going",
  or when an orchestration agent needs to checkpoint progress. Does not push
  or create PRs — use agent-pr or agent-ship for those.
tools: Bash, Read, Grep, Glob
model: sonnet
maxTurns: 10
background: true
---
```

Body mirrors `kit/plugins/git-agent/skills/commit-agent/SKILL.md` step-by-step (guards → stage → analyze diff → conventional commit), but rewritten to be self-contained (agents start with no conversation context). Remove the `ExitPlanMode` step — agents don't run in plan mode by default.

### 2. `kit/plugins/git-agent/agents/agent-pr.md`

Background PR-creation agent. Frontmatter:

```yaml
---
name: agent-pr
description: >
  Background pull-request creation agent. Pushes the current branch if needed
  and opens a GitHub PR with an auto-generated summary. Use when delegating PR
  creation to a subagent, when the user asks to "open a PR in the background",
  "create an MR summary while I work", or when an orchestration agent finishes
  a feature and needs review. Does not commit changes — use agent-commit first.
tools: Bash, Read, Grep, Glob
model: sonnet
maxTurns: 12
background: true
---
```

Body mirrors `kit/plugins/git-agent/skills/pr-agent/SKILL.md` (guards → detect base → check existing PR → push if needed → create PR), self-contained.

### 3. `kit/plugins/git-agent/agents/agent-ship.md`

Background full-pipeline ship agent. Frontmatter:

```yaml
---
name: agent-ship
description: >
  Background end-to-end ship agent. Stages, commits, pushes, and opens a PR/MR
  in one autonomous flow (GitHub via gh, GitLab via glab). Use when the user
  asks to "ship it in the background", "ship and keep working", or "land my
  work without blocking me". Skip if the user wants step-by-step control —
  delegate to agent-commit and agent-pr individually instead.
tools: Bash, Read, Grep, Glob
model: sonnet
maxTurns: 20
background: true
---
```

Body mirrors `kit/plugins/git-agent/skills/ship/SKILL.md` 8-step pipeline, self-contained.

## Files to Modify

### 4. `kit/plugins/git-agent/README.md`

Add a new "Subagents (background mode)" section after the existing "Skills" section. Document the 3 new agents, their trigger phrases, and the skill-vs-agent decision matrix:

- **Use the skill** when you want the work to complete before continuing.
- **Use the agent** when you want to fire-and-forget and keep working.

Note the caveat: when running in background, the working tree is committed/pushed as it exists at agent invocation time — further edits made in the main session may or may not be included depending on timing.

### 5. `kit/plugins/git-agent/CHANGELOG.md`

Add an entry for the next version bump:

```
## 3.5.0

- Added `agent-commit`, `agent-pr`, and `agent-ship` background subagents
  for fire-and-forget git workflows. Existing skills unchanged.
```

### 6. `.claude-plugin/marketplace.json`

Bump `git-agent` version `3.4.0` → `3.5.0` (MINOR — new components added per `.claude/rules/marketplace.md`). Add `subagents` and `background` to the tags array.

## Existing Patterns to Reuse

- **Agent frontmatter schema** — copy from `kit/plugins/code-review/agents/agent-code-reviewer.md` (uses `background: true`, bounded `maxTurns`, scoped `tools`).
- **Skill bodies as source of truth** — the agent prompts are derived from the existing `SKILL.md` step lists. Don't reinvent the workflows; lift them and remove plan-mode hooks.
- **Trigger phrasing in description** — follow the trigger-phrase pattern used in every existing git-agent skill description ("Use when the user asks to...").

## Critical Files

| Path | Action |
|---|---|
| `kit/plugins/git-agent/agents/agent-commit.md` | CREATE |
| `kit/plugins/git-agent/agents/agent-pr.md` | CREATE |
| `kit/plugins/git-agent/agents/agent-ship.md` | CREATE |
| `kit/plugins/git-agent/README.md` | EDIT — add subagents section |
| `kit/plugins/git-agent/CHANGELOG.md` | EDIT — add 3.5.0 entry |
| `.claude-plugin/marketplace.json` | EDIT — bump version, add tags |
| `kit/plugins/git-agent/skills/*/SKILL.md` | UNCHANGED |

## Verification

1. **Structural check** — `ls kit/plugins/git-agent/agents/` shows all 3 new agent files.
2. **Frontmatter check** — each agent has valid YAML frontmatter with `name`, `description`, `tools`, `background: true`.
3. **Marketplace JSON validity** — the existing post-edit hook in `.claude/settings.json` will auto-validate `marketplace.json`; ensure version is `3.5.0` and the entry is otherwise unchanged.
4. **Local plugin load** — run `claude --plugin-dir ./kit/plugins/git-agent` and confirm the 3 new agents appear alongside the 4 existing skills.
5. **Live commit test** — in a throwaway branch with a small change, ask Claude "commit this in the background" and verify: (a) the main session returns control immediately, (b) the agent runs, (c) a conventional commit lands, (d) completion is reported back to the main session.
6. **Live ship test** — same pattern with "ship it in the background" on a branch that has unpushed commits and no existing PR. Verify push + PR creation completes without blocking.
7. **Skill regression** — confirm direct invocation of the existing `commit-agent`, `pr-agent`, and `ship` skills still works synchronously and is unchanged.

## Resolved Design Decisions

**Invocation model.** Agents are dispatched via the parent Claude calling `Agent(subagent_type="agent-commit" | "agent-pr" | "agent-ship", ...)`. The trigger phrases in each agent's `description` field tell the parent Claude when to dispatch. No slash command, no skill-trigger conflict — skills keep their existing triggers; agents activate when the parent recognizes "in the background", "while I work", "fire and forget", "keep working", etc.

**Background semantics.** `background: true` in the agent frontmatter follows the same semantics as `kit/plugins/code-review/agents/agent-code-reviewer.md`. The parent dispatches the agent and continues the main session; the agent reports back on completion. This is the existing in-repo pattern — no new framework behavior is required.

**Working-tree snapshot.** The agent commits/ships whatever is in the working tree at the moment it starts running. Edits made in the main session after dispatch may or may not be included depending on timing. This is the inherent fire-and-forget tradeoff and is documented in the README caveat (file #4 above). No staging-snapshot helper is built — adds complexity without removing the underlying race.

## Out of Scope

- Converting `branch-agent` (kept synchronous by design).
- Concurrency/lock handling for simultaneous git operations from multiple agents — single agent at a time is assumed.
- Updating `.claude/rules/` documentation — not required for this change.
