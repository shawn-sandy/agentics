# Reconcile a Plan Against What Actually Shipped

> `finalize-plan` only ever asked whether each planned thing was built, so a plan that grew scope during implementation was marked completed while its published artifact still described the original scope. Step 3d asks the other direction and routes the answer into sections the renderer already handles; done means unplanned work and changed approaches reach the shared page.

<!-- generated:start -->

**Status:** Shipped 2026-08-30  **Plan:** [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
**Type:** feature

## What shipped

- Added `### 3d — Reconcile against what shipped` to `references/evidence-analysis.md`, deriving the shipped commit range from the spec's own `git log --follow` history with a default-branch fallback, and bucketing findings into: shipped-but-unplanned work and changed approaches.
- Added `5c2` and `5d2` to `references/write-completions.md`: `5c2` writes unplanned work as an `Unplanned:` step (under a trailing `### Phase: Unplanned` in phased specs so the phase gate does not count it as unfinished), and `5d2` routes changed approaches to `## Decisions`, not the red-dotted `## Completion Report`. Scoped `5d`'s removal rule so it cannot discard reconcile output on the happy path.
- Updated `finalize-plan/SKILL.md` to name Step 3d and 5c2/5d2 so the model reaches the new reference steps.
- Added `tests/plugins/test-plan-reconcile.sh` with 11 checks written before the implementation (test-first to assert what is required, not what happened to be written).
- Bumped plan-agent to 9.11.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Reference — Step 3d, commit range, bucketing table | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Reference — 5c2, 5d2, and scoped 5d removal | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill — names 3d and 5c2/5d2 for model routing | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — user-facing description | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 9.11.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 9.10.1 to 9.11.0 | Modified |
| `tests/plugins/test-plan-reconcile.sh` | Test — 11-check objective verification | Created |

## How it works

`finalize-plan` already resolves the plan, scores evidence from the codebase, writes a `## Completion Report`, re-renders, and republishes to the `artifact-url:`. All of that answers one direction: was each planned thing built? The reconcile step asks the other direction and routes answers into sections the renderer already handles, so no renderer change is required.

Step 3d is an observation step added between 3c and Step 4 (the confirmation the user answers). It derives the shipped commit range from `git log --follow -- <spec path>` — reliable because this repo commits the plan file alongside the change it describes. When the spec commit has not landed yet, the fallback is the default-branch range. The step buckets the diff into two categories: work that was shipped but never mentioned in the plan, and work that was built differently than the plan described.

Unplanned work is written by `5c2` as a `[x]` step — the step list is what a reader treats as the record of what was built, so a prose note would be invisible. In a phased spec these steps land under a trailing `### Phase: Unplanned` heading, so `5a0`'s phase gate does not count them as unfinished when deciding whether to refuse `status: completed`.

Changed approaches are written by `5d2` to `## Decisions`. The `## Completion Report` was explicitly rejected for this: every entry there renders with a red dot (`.report-list dt::before`), which reads as a defect. Work that shipped correctly but differently is not a defect.

`5d`'s existing removal rule described exactly the state a clean run with extra scope lands in — "remove the report and add nothing" — so unscoped it would discard the reconcile output on the happy path. Scoping `5d` to its own section means it only removes the Completion Report under its own conditions, not under 5c2's or 5d2's conditions.

The test was written first to assert requirements rather than implementation. `bash tests/plugins/test-plan-reconcile.sh` reports 11 failures against a bare repo before any code changes, then exits 0 after all changes land. The test greps for specific strings in each skill file — the only practical assertion for prose-only changes.

No file under `kit/plugins/plan-agent/scripts/` was modified, confirming the feature required no renderer change.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |

<!-- generated:end -->

## References

- Plan: [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
