# Add shipped scope reconcile

> Adds a reconcile step to finalize-plan (step 3d) that compares what was planned against what was implemented, promotes unplanned work to checked steps, and records approach changes as a Decisions section.

<!-- generated:start -->

**Status:** Shipped 2026-08-30 **Plan:** [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
**Type:** feature

## What shipped

- Added step 3d to `evidence-analysis.md`: scope reconciliation between planned steps and implemented code.
- Added steps 5c2 and 5d2 to `write-completions.md`: write unplanned steps and Decisions section.
- Unplanned work (code changes with no matching plan step) becomes a `[x]` step under `### Phase: Unplanned`.
- Approach changes (planned one way, implemented another) become entries in `## Decisions`.
- Created `tests/test-plan-reconcile.sh`.
- Bumped plan-agent to 9.11.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Evidence analysis step 3d | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Write completions 5c2/5d2 | Modified |
| `tests/test-plan-reconcile.sh` | Reconcile tests | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

Step 3d reads the git diff between the PR branch and main, then matches each changed file against the plan's steps. A step is matched when the diff touches a file listed in the step's scope, or when the step's description matches the commit message. Unmatched diff hunks — code changes with no plan step — are collected as unplanned work.

Unplanned work is recorded as pre-checked steps under `### Phase: Unplanned` in the completed plan, not silently dropped. This keeps the plan's "what shipped" section honest: the plan was supposed to do X, but Y also happened.

The Decisions section records approach divergences: where the plan said "use approach A" and the implementation used "approach B". This is the institutional memory for why the plan changed — useful when a future developer asks "why didn't we just do X?"

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
