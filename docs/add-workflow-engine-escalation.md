# Ship the Workflow-engine escalation as the lane pilot

> Adds the Workflow-engine as the lane-build escalation path for plans with 6+ lanes or `workflow: always`, and serves as the first laned plan in the repo.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
**Type:** feature

## What shipped

- Added `implement-workflow.mjs` — a Workflow script that runs one worktree-isolated worker agent per lane, ordered by `after:` promise edges rather than a synchronous barrier (so faster lanes don't wait on slower peers).
- Wired the Workflow engine into `/plan-agent:build` behind three selection conditions: `workflow: always` in frontmatter, the `--workflow` CLI flag, or 6+ lanes in the plan spec.
- Added `--workflow` to the `argument-hint` and `dispatch-lanes.md` Workflow engine section explaining probe-based tool detection, the selection gate, and the hard-stop message when the Workflow tool is absent.
- Shipped `tests/implement-workflow.test.mjs` — a static parse-level suite asserting the script's shape, schema, wave ordering, selection gate, and no banned APIs (`Date.now`, `Math.random`, `require`).
- Bumped plan-agent to 9.17.0 and published the pilot's measured dispatch-versus-sequential wall-clock and token figures in the changelog.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow engine script | Created |
| `tests/implement-workflow.test.mjs` | Static parse suite | Created |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Lane dispatch reference | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill core | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Flag reference | Modified |

## How it works

`implement-workflow.mjs` mirrors the proven shape of `review-workflow.mjs`: an `export const meta` pure literal, a header comment that documents the selection contract, and wave ordering expressed as a `Map` from lane name to a promise. Each lane's promise awaits the promises of its `after:` dependencies, then calls `agent()` with `isolation: 'worktree'` and a `LANE_REPORT` JSON schema. A dead worker resolves to `null` rather than rejecting the run, so one stalled lane doesn't abort the others.

The script never runs git. It returns `{ reports, mergeOrder }` — the per-lane reports and a topological sort of the worker lane names — and leaves merging to the lead agent using the same section-6 audit the sequential Agent path uses. This means there is one merge procedure, not two.

Selection is probed rather than version-asserted: before calling the Workflow tool, `build` reads the spec frontmatter and the argument list and falls through to the sequential Agent dispatcher when conditions aren't met, or hard-stops with a named message when `--workflow` was explicit but the tool is absent in the session.

`tests/implement-workflow.test.mjs` reuses the `parsesAsWorkflowBody()` AsyncFunction trick from `tests/review-plan-workflow.test.mjs` to validate the script as a hybrid module (`export const meta` + top-level `return`), since `node --check` rejects that form.

## How to use it

The Workflow engine is selected automatically when a laned plan has 6 or more lanes, or explicitly via `workflow: always` in frontmatter or `--workflow` on the command line.

```
/plan-agent:build docs/plans/my-big-plan.md --workflow
/plan-agent:build docs/plans/my-big-plan.md   # auto-escalates at 6+ lanes
```

Pass `--sequential` instead to force the Agent dispatcher regardless of lane count. `--sequential` and `--workflow` together is an error.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `c3514b71` | 2026-09-09 | docs(plan-agent): publish the pilot's --sequential figures and complete the lane plan (9.17.1) (#629) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |

<!-- generated:end -->

## References

- Plan: [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
- Related: [add-lane-orchestration.md](add-lane-orchestration.md)
