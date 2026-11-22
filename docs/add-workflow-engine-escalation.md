# Ship the Workflow-engine escalation as the lane pilot

> The lane dispatcher runs every laned plan on the Agent tool today; this adds the Workflow-engine escalation for six-plus lanes or `workflow: always`, and it is the first plan ever authored with `### Lane:` headings — building it with the new dispatcher is the pilot run the lane feature has been waiting on.

<!-- generated:start -->

**Status:** Shipped 2026-09-09 **Plan:** [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs`: Workflow script with `export const meta` (`plan-implement-lanes`); promise-ordered wave execution via `after:` edges; `LANE_REPORT` schema (`lane`, `branch`, `steps_done`, `verify`, `files_changed`, `blocked`); skips lanes named `lead`; returns `{ reports, mergeOrder }` with topological sort; probes for Workflow tool availability rather than asserting a version; uses no git, no Node APIs, no `Date.now()`.
- Updated `references/dispatch-lanes.md`: `## Workflow engine (escalation)` section with selection rule, absence message, and inline `script` invocation pattern.
- Updated `skills/build/SKILL.md`: `[--workflow]` added to `argument-hint`; "2 or more lanes" bullet extended with Workflow engine clause (stayed under 600-word ceiling).
- Updated `references/invocation.md`: `--workflow` flag in Rule 0 strip list; flag bullet with error when combined with `--sequential`.
- Added `tests/implement-workflow.test.mjs`: parses as workflow body; meta name and phase; LANE_REPORT schema shape; wave ordering from `after:` edges; `lead` skipped; `mergeOrder` returned; selection gate documented; no forbidden Node APIs.
- Bumped plan-agent to 9.17.0 (this plan shipped as part of the lane orchestration PR).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow script | Created |
| `tests/implement-workflow.test.mjs` | Static test suite | Created |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Workflow engine section | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | `--workflow` flag and clause | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | `--workflow` flag entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 9.17.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.17.0 entry with pilot numbers | Modified |

## How it works

Wave ordering is a promise per lane, not a barrier: each lane awaits the promises its `after:` names and then calls `agent()`, so a lane starts the moment its dependencies finish. A dead worker resolves to `null` instead of rejecting the run.

The selection gate: `workflow: always`, `--workflow`, or 6+ lanes on a 2+-lane spec selects the Workflow engine; fewer than 2 lanes always runs sequentially and the Workflow engine is never offered. When the Workflow tool is absent in the session, `build` prints the documented absence message and stops rather than silently falling back.

The script never runs git. It returns `reports` and `mergeOrder`; the lead merges lane branches with the same section-6 audit used by the Agent dispatcher, so there is one merge procedure, not two.

The measured pilot: dispatch used 466,207 worker tokens in 651 s for the lane work; sequential used 12,423,454 tokens in 411 s for the lane work / 1,531 s for the whole session.

## How to use it

```
/plan-agent:build docs/plans/<spec>.md --workflow
```

Or set `workflow: always` in the spec frontmatter. Automatic selection at 6+ lanes requires no flag.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |

<!-- generated:end -->

## References

- Plan: [add-workflow-engine-escalation.md](plans/add-workflow-engine-escalation.md)
