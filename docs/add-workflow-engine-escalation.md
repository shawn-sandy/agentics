# Ship the Workflow-engine escalation as the lane pilot

> Adds `implement-workflow.mjs` — a Workflow script that runs one worktree-isolated worker per lane with promise-ordered pipeline stages — and wires its selection into `build` behind `workflow: always`, `--workflow`, or six or more lanes.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` — a Workflow script with `export const meta` (name: `plan-implement-lanes`, phases: `Implement`, `Report`), one `agent()` call per non-lead lane with `isolation: 'worktree'` and `schema: LANE_REPORT`, wave ordering as a promise per lane (no barrier), and a `mergeOrder` return. Hard-stops with a named message when the Workflow tool is absent.
- Extended `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` with a `## Workflow engine (escalation)` section: selected on 2+ lanes by `workflow: always`, `--workflow`, or 6+ lanes; fewer than 2 lanes runs sequentially.
- Updated `kit/plugins/plan-agent/skills/build/SKILL.md`: added `[--workflow]` to the argument hint; extended the lanes bullet to name the Workflow engine path.
- Updated `kit/plugins/plan-agent/skills/build/references/invocation.md` with `--workflow` in the Rule 0 strip list and a valueless-flag bullet.
- Added `tests/implement-workflow.test.mjs` — parses the script as a workflow body, asserts the `LANE_REPORT` schema, wave ordering, selection gate documentation, `lead` skip, and no Node API or git calls.
- Bumped `plan-agent` to `9.17.0`; CHANGELOG entry carries the pilot's measured dispatch-vs-sequential figures.
- Regenerated `README.md` Plugin Reference Table and updated `docs/guides/how-to/plan-agent.md`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow script | Created |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Lane dispatch reference | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Invocation reference | Modified |
| `tests/implement-workflow.test.mjs` | Workflow script test | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `README.md` | Plugin Reference Table (generated) | Modified |
| `docs/guides/how-to/plan-agent.md` | How-to guide | Modified |

## How it works

Wave ordering is a promise per lane, not a barrier: each lane awaits the promises named in its `after:` array and then calls `agent()`, so a lane starts the moment its dependencies resolve. Dead workers resolve to null instead of rejecting the run.

The script never runs git. It returns `{ reports, mergeOrder }` — reports as `[{ name, after, report }]` and `mergeOrder` as the worker lane names topologically sorted by `after:`. The lead skill merges in that order using the same section-6 audit the Agent path uses, keeping one merge procedure for both engines.

The Workflow tool is probed for availability (never version-asserted), following the pattern `review-plan` uses. When absent, the skill prints a named message and stops, with a suggestion to re-run without `--workflow`.

This plan was the pilot run for the lane feature: the `script`, `wiring`, and `tests` lanes were dispatched in parallel (with `lead` running after all three merged), and the CHANGELOG entry carries the measured wall-clock and token comparison against a `--sequential` run.

## How to use it

```
/plan-agent:build docs/plans/my-plan.md --workflow
```

Or set `workflow: always` in the plan's frontmatter to always use the Workflow engine.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c3514b7` | 2026-09-09 | docs(plan-agent): publish the pilot's --sequential figures and complete the lane plan (9.17.1) (#629) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |

<!-- generated:end -->

## References

- Plan: [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
