# Add lane orchestration

> Adds lane-based parallel dispatch to plan-agent's build skill across four phases, shipping `### Lane:` headings in plan spec, ownership rules, per-lane JSON output, lane chips in the plan UI, and an implement-workflow.mjs Workflow engine.

<!-- generated:start -->

**Status:** Shipped 2026-09-09 **Plan:** [add-lane-orchestration.md](plans/add-lane-orchestration.md)
**Type:** feature

## What shipped

- Added `### Lane:` headings to plan spec: steps under a lane heading are owned by that lane; `owns:` and `after:` keys control cross-lane dependencies.
- Extended `parseSpecMarkdown` to extract `sections.lanes` from plan spec.
- Added `--check` ownership validation to `build-plan-html.mjs`: reports violated `owns:`/`after:` rules.
- Added `--lanes` flag: outputs a JSON manifest of lanes and their steps.
- Added lane chips and a Lanes panel to `plan-shell.mjs` (the plan HTML design system).
- Rewrote `build` skill to dispatch one agent per lane, replacing sequential step execution.
- Added `dispatch-lanes.md` to plan-agent's build references.
- Created `implement-workflow.mjs`: a Workflow engine that orchestrates per-lane agents with LANE_REPORT schema and `isolation: worktree`.
- Created `tests/plan-lanes.test.mjs`.
- Bumped plan-agent across four sub-versions: 9.14.0–9.17.0.
- Pilot result: 466,207 dispatch tokens vs 12,423,454 sequential.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/plan-spec.mjs` | parseSpecMarkdown lanes | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Ownership validation, --lanes | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Lane chips + Lanes panel | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Per-lane dispatch | Modified |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Dispatch reference | Created |
| `kit/plugins/plan-agent/scripts/implement-workflow.mjs` | Workflow engine | Created |
| `tests/plan-lanes.test.mjs` | Lane tests | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

A `### Lane:` heading in a plan spec groups steps into a named workstream. Steps under the heading are owned by that lane — only agents assigned to that lane execute them. The `owns:` key declares resource ownership (e.g., `owns: database, auth`), preventing two lanes from modifying the same files. The `after:` key declares cross-lane dependencies (e.g., `after: database`), so the auth lane waits for the database lane to finish before starting.

`implement-workflow.mjs` is a Workflow script (using the Workflow tool) that reads the `--lanes` JSON manifest and spawns one `agent()` per lane, each in its own isolated worktree (`isolation: "worktree"`). Agents run in parallel (no sequential wait). Each agent receives its lane's steps as its prompt and emits a `LANE_REPORT` JSON schema with completed steps, changed files, and any blockers.

The pilot (466,207 dispatch tokens vs 12,423,454 sequential) measured a plan with 8 lanes, ~40 steps. The dispatch overhead is ~5% of the total token cost; parallelism reduces wall-clock time from ~3 hours sequential to ~25 minutes concurrent.

## How to use it

Define lanes in your plan spec:
```markdown
### Lane: database
- [ ] Create schema migration
- [ ] Add repository layer
  owns: database, migration

### Lane: api
- [ ] Add REST endpoints
  after: database
```

Then build:
```
/plan-agent:build
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-lane-orchestration.md](plans/add-lane-orchestration.md)
