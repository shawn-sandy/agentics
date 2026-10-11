# Add plan backlog fleet skill

> Adds `build-fleet` to plan-agent, a dispatch skill that runs one isolated worktree agent per `todo` plan up to a configurable maximum, chains build → ship-autonomous, and uses a `multiSelect` picker for batch selection.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` dispatching one `Agent(isolation: "worktree")` per todo plan.
- Each agent chains `build` → `ship-autonomous` (never `gh pr merge`).
- `--max` defaults to 3, hard-capped at 5 for cost control.
- `multiSelect` picker with max 4 plans — the user reviews the selection before dispatch.
- Base branch resolved from `origin/HEAD` (not hardcoded `origin/main`).
- Bumped plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Fleet skill | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

`build-fleet` solves the "backlog of todo plans" problem: when 10+ plans are ready to implement, dispatching them one at a time is slow. The skill uses `Agent(isolation: "worktree")` to run each plan in its own isolated git worktree, so multiple plans can be implemented concurrently without file conflicts.

The chain `build → ship-autonomous` means each worker agent both implements the plan and opens a PR for review. The `gh pr merge` step is deliberately absent — all PRs land in the queue for human review, never auto-merged.

The `--max` cap at 5 (default 3) prevents runaway costs. Each agent runs at full token cost; 5 simultaneous agents on a large plan backlog could burn a significant budget quickly. The multiSelect picker forces the user to consciously select which 1–4 plans to dispatch, preventing "fleet everything" accidents.

Resolving the base branch from `origin/HEAD` rather than hardcoding `origin/main` handles repositories where the default branch has a different name (e.g., `master` or `develop`).

## How to use it

```
/plan-agent:build-fleet
/plan-agent:build-fleet --max 2
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
