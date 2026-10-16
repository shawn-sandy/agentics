# Add phase checkpoints to implementation plans

> Adds `### Phase:` headings and a `## Decisions` section to the plan spec format, makes the build skill phase-aware with a `--continue` flag, and makes `finalize-plan` refuse to complete a plan with unfinished phases.

<!-- generated:start -->

**Status:** Shipped 2026-08-05 **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Added `### Phase: <name>` heading support to `parseSpecMarkdown` with a `phases` key in the result.
- Added `## Decisions` section to plan specs for recording architectural choices.
- Made `build` phase-aware: stops at phase boundaries, offers Compact/Stop/Continue options, uses `--continue` to resume.
- Made `finalize-plan` refuse to mark a plan completed when any phase has unfinished steps.
- Marked `workflow: never` in plans with 4+ steps that edit the same file (to prevent conflicting parallel edits).
- Bumped plan-agent to 8.6.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Spec parser | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Build script | Modified |
| `kit/plugins/plan-agent/scripts/` (bundled copies) | Bundled copies | Modified |
| `kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md` | Phase checkpoint rules | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/` | Finalize references | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

Phases divide a plan into logical milestones that can be reviewed and confirmed before proceeding. A `### Phase: RED` heading groups steps into a phase; the parser returns phases alongside the flat step list.

When `build` encounters a phase boundary, it stops and presents three options: Compact (summarize what happened and continue), Stop (exit and return control to the user), or Continue (proceed to the next phase). The `--continue` flag allows resuming from the last phase boundary in headless mode.

The `## Decisions` section records architectural choices that were made during the plan's creation or implementation — choices that future readers need context for. Unlike `## Steps`, decisions don't have checkboxes and aren't evaluated for completeness.

`finalize-plan` checks that every `### Phase:` boundary has all its steps checked before marking the plan `completed`. A plan with phases but unfinished phase steps returns `INCOMPLETE` rather than `COMPLETED`.

The `workflow: never` note prevents parallel builds on plans where multiple steps edit the same file — the parallel workers would conflict on the shared file.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
