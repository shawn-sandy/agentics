# Reconcile a plan against what actually shipped

> Add a reconcile step to `finalize-plan` that compares a plan against the commits that actually shipped it, recording unplanned work and changed approaches in the spec so the published plan artifact describes what was built.

<!-- generated:start -->

**Status:** Shipped 2026-08-30  **Plan:** [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
**Type:** feature

## What shipped

- Extended `finalize-plan/references/evidence-analysis.md` with `### 3d — Reconcile against what shipped`, a new observation step that derives the shipped commit range from the plan's git history and buckets commits into four categories: planned and shipped, planned and missing, unplanned, and built differently
- Extended `finalize-plan/references/write-completions.md` with steps `5c2` and `5d2` that route unplanned work as `[x]` steps under a `### Phase: Unplanned` section in `## Steps`, and changed approaches to `## Decisions`
- Scoped step 5d's removal rule so it cannot discard reconcile findings on a clean pass
- Updated `finalize-plan/SKILL.md` to reference steps 3d and 5c2/5d2
- Added `tests/plugins/test-plan-reconcile.sh` with 11 assertions covering all reconcile buckets
- Bumped plan-agent to 9.11.0 (MINOR — new behaviour) with README and CHANGELOG updates

> See [CHANGELOG v9.11.0](../kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Step 3d added | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Steps 5c2, 5d2, scoped 5d | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | References 3d and 5c2/5d2 | Modified |
| `kit/plugins/plan-agent/README.md` | Reconcile behaviour documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.11.0 entry | Modified |
| `.claude-plugin/marketplace.json` | 9.10.1 → 9.11.0 | Modified |
| `tests/plugins/test-plan-reconcile.sh` | 11-assertion test | Created |

## How it works

The reconcile step (3d) runs after `finalize-plan` has collected evidence and before the confirmation prompt (Step 4). It derives the shipped commit range from the spec's own git history using `git log --follow` on the plan file, with an `...HEAD` fallback when the spec commit has not yet landed. It then buckets each commit path into four categories based on whether the path appears in the plan's `## Steps` section.

Unplanned work — files and commits that appear in git but were never mentioned in the spec — is written into `## Steps` as already-done `[x]` entries. In phased specs they land under a trailing `### Phase: Unplanned` section so step 5a0's phase gate does not count them as unfinished work. Changed approaches — where the implementation diverged from the plan — are written to `## Decisions`, not to the red-dotted `## Completion Report`, since work that shipped cleanly is not a defect.

Step 5d's removal rule, which previously removed the completion report and replaced it with nothing, was scoped to its own conditional so it cannot inadvertently discard the unplanned and changed-approach writes on a clean pass.

The existing spec parser (`plan-spec.mjs`), renderer (`build-plan-html.mjs`), and shell (`plan-shell.mjs`) were not modified — the four buckets all route into sections these already recognise.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
- Changelog: [plan-agent CHANGELOG](../kit/plugins/plan-agent/CHANGELOG.md)
- Related: [kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md](../kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md)
