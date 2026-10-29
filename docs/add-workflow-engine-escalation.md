# Ship the Workflow-engine escalation as the lane pilot

> Adds `implement-workflow.mjs` — a Workflow script running one worktree-isolated Sonnet worker per lane with `after:` edges as pipeline stages — wired into `build` behind `workflow: always`, `--workflow`, or six or more lanes.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-workflow-engine-escalation](plans/add-workflow-engine-escalation.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/scripts/implement-workflow.mjs` — Workflow tool script; one `agent()` call per lane, `after:` edges expressed as promise-ordered `pipeline()` stages
- Wired into `build/SKILL.md`: `workflow: always` in plan frontmatter, `--workflow` CLI flag, or ≥6 lanes triggers escalation
- Test suite authored as three worker lanes (`data-model`, `api`, `ui`) plus `lead` coordinator
- Static tests assert the script structure, lane-to-agent mapping, and `pipeline()` stage ordering
- Bumped `plan-agent` with CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/implement-workflow.mjs` | Workflow script — lane pilot | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill — workflow escalation routing | Modified |
| `tests/plugins/test-implement-workflow.sh` | Smoke test — script structure and routing | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |

## How it works

The `build` skill previously ran every step sequentially in a single context window. For plans with many independent steps, this wastes time and often hits context limits. `implement-workflow.mjs` replaces the inner execution loop for laned plans with a parallel Workflow engine run.

The script receives the plan's lane map as its input. Each lane becomes one `agent()` call: a Sonnet worker that implements only that lane's steps in an isolated `isolation: "worktree"` environment. The `after:` dependency edges from the lane declarations become `pipeline()` ordering: lanes with no `after:` run in parallel in the first stage; lanes with `after: [lane-a]` run after stage 1 completes. The Workflow engine handles fault tolerance — a failed lane does not cancel independent parallel lanes.

Escalation from `build` to the Workflow engine is controlled by three triggers: `workflow: always` in the plan frontmatter (author-specified), the `--workflow` CLI flag (user override), or automatic escalation when the plan has six or more lanes. Plans with two to five lanes still use the lane dispatch path (`references/dispatch-lanes.md`) rather than the Workflow engine; only plans with fewer than two lanes continue truly sequential execution.

## How to use it

```
/plan-agent:build --workflow              # force Workflow engine for any laned plan
/plan-agent:build                         # auto-escalates at 6+ lanes
```

Plan frontmatter override:
```yaml
workflow: always   # always use Workflow engine for this plan
workflow: never    # never escalate (default for most plans)
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d7a4be2` | 2026-09-09 | feat(plan-agent): workflow engine escalation pilot (9.17.0) |

<!-- generated:end -->

## References

- Plan: [add-workflow-engine-escalation](plans/add-workflow-engine-escalation.md)
