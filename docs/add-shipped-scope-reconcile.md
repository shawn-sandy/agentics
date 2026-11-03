# Reconcile a plan against what actually shipped

> Adds a reconcile step to `finalize-plan` that compares the plan against its shipped commits and records work that was shipped but unplanned, or built differently, into the spec so the published artifact describes what was built rather than only what was imagined.

<!-- generated:start -->

**Status:** Shipped 2026-08-30  **Plan:** [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
**Type:** feature

## What shipped

- Added `### 3d — Reconcile against what shipped` to `finalize-plan/references/evidence-analysis.md`: derives the shipped commit range from `git log --follow` on the spec file with an `...HEAD` fallback, buckets commits into *unplanned* and *changed approach* categories.
- Added `5c2` and `5d2` to `references/write-completions.md`: unplanned work is written as a `[x]` step (under `### Phase: Unplanned` in phased specs); a changed approach is written to `## Decisions` rather than the red-dotted `## Completion Report`.
- Scoped `5d`'s removal rule so it cannot discard reconcile output on the happy path.
- Updated `finalize-plan/SKILL.md` to name Step 3d and 5c2/5d2 so the model reaches them.
- Updated plugin README and added the 9.11.0 CHANGELOG entry.
- Added `tests/plugins/test-plan-reconcile.sh` (11 checks).
- Bumped `plan-agent` to `9.11.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Evidence analysis reference | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Completion write reference | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-plan-reconcile.sh` | Smoke test | Created |

## How it works

Before this change, `finalize-plan` only answered whether each planned thing was built, leaving unplanned work and changed approaches silently absent from the published artifact. The fix routes the two new buckets into sections the renderer already handles — no changes to `build-plan-html.mjs`, `plan-spec.mjs`, or `plan-shell.mjs` were needed.

Step 3d uses the spec file's own git history as the evidence source: `git log --follow` on the `.md` file gives a precise commit range because this repo commits the plan file alongside the change it describes. The fallback (`...HEAD`) covers specs whose commits have not landed yet.

Unplanned work is written as an already-done `[x]` step rather than prose, because the step list is what readers treat as the record of what was built. In phased specs these steps land under a trailing `### Phase: Unplanned` so the phase gate at 5a0 does not count them as unfinished. A changed approach routes to `## Decisions` because the `## Completion Report`'s red-dot rendering reads as a defect, which a different-but-valid approach is not.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |

<!-- generated:end -->

## References

- Plan: [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
