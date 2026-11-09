# Reconcile a plan against what actually shipped

> Add a reconcile step to `finalize-plan` that records work shipped but unplanned and work built differently into the plan spec, so a published artifact describes what was built rather than only what was imagined.

<!-- generated:start -->

**Status:** Shipped 2026-08-30  **Plan:** [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
**Type:** feature

## What shipped

- Added `### 3d — Reconcile against what shipped` to `finalize-plan/references/evidence-analysis.md`, deriving the shipped commit range from the spec's own git history and bucketing findings into "unplanned" and "built differently" categories.
- Added `5c2` and `5d2` sub-steps to `references/write-completions.md`: unplanned work is written as a `[x]` step under a trailing `### Phase: Unplanned` section; a changed approach is written to `## Decisions`.
- Scoped `5d`'s removal rule so it cannot discard reconcile output on a clean run.
- Named steps 3d, 5c2, and 5d2 explicitly in `finalize-plan/SKILL.md` so the model reaches the reference files that define them.
- Added `tests/plugins/test-plan-reconcile.sh` with 11 retention checks covering each rule.
- Bumped plan-agent to 9.11.0 with a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Step 3d reconcile rule | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Steps 5c2 and 5d2, scoped 5d | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Names 3d and 5c2/5d2 | Modified |
| `kit/plugins/plan-agent/README.md` | User-facing description update | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.11.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.10.1 → 9.11.0 | Modified |
| `tests/plugins/test-plan-reconcile.sh` | 11 retention checks | Created |

## How it works

Before this change, `finalize-plan` only asked whether each planned thing was built. A plan that grew scope during implementation would be marked completed while its published artifact still described only the original scope — the under-reporting was silent and public.

Step 3d uses `git log --follow` with an `...HEAD` fallback to derive the commit range from the spec's own git history. It then buckets each commit's diff into two categories: files touched but never mentioned in the plan ("unplanned"), and plan steps whose implementation diverged from what was written ("built differently").

Unplanned work is written as an already-done `[x]` step into `## Steps` (or into a trailing `### Phase: Unplanned` in phased specs, so the phase-gate counter doesn't treat them as unfinished). Changed approaches go to `## Decisions` rather than `## Completion Report`, because the completion report's CSS renders every entry with a red dot — correct for defects, misleading for valid divergences.

The `5d` removal rule was scoped so that a fully verified plan keeps its reconcile findings. Previously, `5d`'s "remove the report and add nothing" instruction described the clean-run state precisely enough that it could silently discard everything 3d wrote on the happy path.

The test file writes these rules as retention greps rather than live-run assertions, consistent with the existing `test-exitplanmode-guard.sh` pattern.

## How to use it

The reconcile step runs automatically as part of `/plan-agent:finalize-plan`. No separate invocation is needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `3263bbc9` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |

<!-- generated:end -->

## References

- Plan: [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
- Related: `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md`
