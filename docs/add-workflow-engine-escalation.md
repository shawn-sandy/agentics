# Add workflow engine escalation

> Adds automatic escalation to the Workflow engine in `implement-workflow.mjs`: plans with 6+ lanes or an explicit `workflow: always` directive use the Workflow engine; smaller plans continue to use sequential agent dispatch.

<!-- generated:start -->

**Status:** Shipped 2026-09-09 **Plan:** [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
**Type:** feature

## What shipped

- Added selection logic to `implement-workflow.mjs`: Workflow engine is used when `workflow: always` is set in plan frontmatter, when `--workflow` flag is passed, or when the plan has 6 or more lanes.
- Plans below the threshold continue to use sequential (non-Workflow) agent dispatch.
- Created `tests/implement-workflow.test.mjs`.
- Bumped plan-agent to 9.17.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/implement-workflow.mjs` | Workflow engine selection | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Selection criteria | Modified |
| `tests/implement-workflow.test.mjs` | Escalation tests | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The Workflow engine (`implement-workflow.mjs` using the `Workflow` tool) carries significant overhead: it spawns a new process, initializes isolated worktrees per lane, and requires the Workflow tool to be available in the session. For a plan with 2–3 lanes, the overhead exceeds the benefit — sequential dispatch finishes faster.

The 6-lane threshold is empirical: below 6 lanes, sequential dispatch with `Agent(isolation: "worktree")` calls is faster end-to-end. At 6 or more lanes, the parallel execution savings outweigh the Workflow startup cost.

The `workflow: always` frontmatter directive and `--workflow` CLI flag allow explicit opt-in for plans below the threshold. This is useful for plans where lanes have high token cost per step (e.g., each step requires a large context load) even if there are fewer than 6 lanes.

The selection logic runs at the start of `build`, before any agents are dispatched, so the overhead of evaluating the plan spec is incurred only once.

## How to use it

```
/plan-agent:build               # auto-selects based on lane count
/plan-agent:build --workflow    # force Workflow engine
```

Or in plan frontmatter:
```yaml
workflow: always
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
