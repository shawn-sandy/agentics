# Make the plan the dispatch contract

> Delivers lane parsing in the renderer, lane authoring in `implementation-plan`, a lane dispatcher in `build`, and a Workflow-engine pilot — one phase per PR, each with its own minor version bump (9.14.0–9.17.0).

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-lane-orchestration](plans/add-lane-orchestration.md)
**Type:** feature

## What shipped

- Added `### Lane: <name>` grouping level to the plan spec renderer so steps declare their own lanes
- Updated `implementation-plan` to author laned plans with per-lane dependency edges expressed as `after:` references
- Added lane dispatcher to `build`: detects laned plans and selects between sequential and Workflow-engine execution
- Shipped `implement-workflow.mjs` — a Workflow script running one worktree-isolated worker per lane with `after:` edges as promise-ordered pipeline stages
- Wired lane selection behind `workflow: always`, `--workflow`, or six or more lanes
- Added static test suite authoring three worker lanes plus `lead`
- Four PRs, four minor bumps: 9.14.0 (renderer), 9.15.0 (implementation-plan authoring), 9.16.0 (dispatcher), 9.17.0 (Workflow pilot)

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Lane authoring — `after:` edges, lane sections | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Lane dispatcher — workflow selection | Modified |
| `kit/plugins/plan-agent/scripts/implement-workflow.mjs` | Workflow engine — lane pilot script | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 9.14.0–9.17.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — four phase entries | Modified |

## How it works

A plan today is something one agent reads top to bottom — steps are a flat list with no declared parallelism. After this change, a plan can declare `### Lane: <name>` sections that group independent steps. The renderer parses these sections and the build skill uses them as the dispatch contract.

The lane dispatcher in `build` checks a plan for lane declarations and routes accordingly. Plans with fewer than two `### Lane:` headings (or with `workflow: never` / `--sequential`) run sequentially unchanged. Plans with two or more lanes use the lane dispatch path in `references/dispatch-lanes.md`. Among laned plans, `workflow: always`, `--workflow`, or six or more lanes escalates execution to `implement-workflow.mjs` via the Workflow tool.

`implement-workflow.mjs` maps each lane to one worktree-isolated `agent()` call with `isolation: "worktree"`. The `after:` dependency edges are expressed as promise ordering: a pipeline stage blocks until all its upstream stages resolve. This lets independent lanes run concurrently while dependent ones wait, all within the Workflow engine's fault-tolerance model.

Old plans render byte-for-byte unchanged — the lane parser is additive and the renderer falls through to sequential execution when no lane sections exist.

## How to use it

Lane authoring in a plan spec:

```markdown
### Lane: data-model
Steps that set up the database schema...

### Lane: api (after: data-model)
Steps that implement the API layer...

### Lane: ui (after: api)
Steps that build the UI...
```

Dispatch selection:
```
/plan-agent:build --workflow              # force Workflow engine
/plan-agent:build                         # auto-selects based on lane count
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d7a4be2` | 2026-09-09 | feat(plan-agent): lane orchestration pilot (9.17.0) |

<!-- generated:end -->

## References

- Plan: [add-lane-orchestration](plans/add-lane-orchestration.md)
- Design: `docs/designs/add-lane-orchestration`
