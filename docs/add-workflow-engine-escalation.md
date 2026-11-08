# Ship the Workflow-engine escalation as the lane pilot

> Adds the Workflow-engine escalation path for laned plans, selectable via `workflow: always`, `--workflow`, or 6+ lanes, using a promise-ordered pipeline per lane.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
**Type:** feature

## What shipped

- Added `implement-workflow.mjs` — a Workflow script that runs one worktree-isolated Sonnet worker per lane, with `after:` edges expressed as promise-ordered pipeline stages (so each lane starts the moment its dependencies finish, rather than waiting on a global barrier).
- Wired the new script into the `build` skill's selection gate: triggered by `workflow: always`, the `--workflow` flag, or 6+ lanes; below 2 lanes the sequential path runs regardless of frontmatter.
- Added `--workflow` to the `argument-hint` in `build/SKILL.md` and a matching `## Workflow engine (escalation)` section in `dispatch-lanes.md` covering the selection rule, the probe-not-assert pattern for tool availability, and the hard-stop message when the Workflow tool is absent.
- Added `tests/implement-workflow.test.mjs` — a static test suite that parses `implement-workflow.mjs` as a workflow body and asserts the `LANE_REPORT` schema, promise-ordered wave edges, `isolation: 'worktree'`, the `lead`-skip rule, the `mergeOrder` return, and that the script names all three selectors and forbids `Date.now`/`Math.random`.
- Bumped plan-agent to 9.17.0, with the pilot's measured dispatch-vs-sequential wall-clock and token figures in the CHANGELOG entry (the plan was itself the pilot run).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow engine script | Created |
| `tests/implement-workflow.test.mjs` | Static test suite for the workflow script | Created |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Workflow engine escalation section | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Selection clause and `--workflow` flag | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | `--workflow` flag documentation | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.17.0 version bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.17.0 entry with pilot numbers | Modified |

## How it works

`implement-workflow.mjs` mirrors the shape of `review-workflow.mjs` already used by `review-plan`. It exports a pure literal `meta` block (name `plan-implement-lanes`, phases `Implement` and `Report`), reads `args.planPath`, `args.planBranch`, `args.workerModel`, and `args.lanes` — an array of `{ name, owns, after, brief }` — and throws a named error when any required key is absent.

Wave ordering uses a `Map` from lane name to Promise. Each lane's promise first awaits the promises of every lane listed in its `after:` field, then calls `agent()` with `isolation: 'worktree'` and `schema: LANE_REPORT`. The `LANE_REPORT` schema requires `lane`, `branch`, `steps_done`, `verify`, `files_changed`, and `blocked`. Lanes named `lead` are skipped — the lead runs the script, not a worker. A dead worker resolves to null rather than rejecting the run.

After all promises settle, the script returns `{ reports, mergeOrder }` where `mergeOrder` is a topological sort of worker lane names by `after:` edges. The caller (the `build` skill's dispatch path) merges lanes in that order using the same section-6 audit procedure as the Agent dispatcher, so there is one merge procedure for both engines.

The selection gate in `dispatch-lanes.md` probes for the Workflow tool's availability at runtime (never asserts a version), following the same pattern as `review-plan` Step 3. When the tool is absent, the skill prints a named hard-stop message and returns rather than falling through silently.

`tests/implement-workflow.test.mjs` reuses `review-plan-workflow.test.mjs`'s `check()` helper and `AsyncFunction` parse trick verbatim. It asserts the script parses as a workflow body, the `LANE_REPORT` schema shape, wave ordering derived from `after:` edges, the `isolation: 'worktree'` call argument, the `lead`-skip rule, and that the selection gate's three selectors are documented in the header comment. It also verifies the script uses none of `Date.now`, `Math.random`, `new Date(`, or `require`.

## How to use it

The escalation is selected automatically when a laned plan has 6 or more lanes. It can also be forced on any 2+-lane plan:

```
/plan-agent:build docs/plans/my-plan.md --workflow       # force Workflow engine
/plan-agent:build docs/plans/my-plan.md --sequential     # force Agent dispatcher
/plan-agent:build docs/plans/my-plan.md                  # auto (frontmatter or lane count)
```

`workflow: always` in the plan frontmatter selects the engine the same way `--workflow` does. `--sequential` and `--workflow` together is an error.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `c3514b7` | 2026-09-09 | docs(plan-agent): publish the pilot's --sequential figures and complete the lane plan (9.17.1) (#629) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
- Related: [kit/plugins/plan-agent/CHANGELOG.md](../kit/plugins/plan-agent/CHANGELOG.md)
- Related: [kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs](../kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs) — the template this workflow mirrors
