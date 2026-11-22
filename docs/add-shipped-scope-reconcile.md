# Reconcile a plan against what actually shipped

> `finalize-plan` only ever asked whether each planned thing was built, so a plan that grew scope during implementation was marked completed while its published artifact still described the original scope. Step 3d asks the other direction and routes the answer into sections the renderer already handles; done means unplanned work and changed approaches reach the shared page.

<!-- generated:start -->

**Status:** Shipped 2026-08-30 **Plan:** [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
**Type:** feature

## What shipped

- Added `### 3d — Reconcile against what shipped` to `references/evidence-analysis.md`: derives the commit range from `git log --follow` with an `...HEAD` fallback; buckets work into unplanned (shipped but not in the plan) and differently built (changed approach); routes unplanned work to `## Steps` as `Unplanned:` entries, changed approaches to `## Decisions`.
- Updated `references/write-completions.md`: added `5c2` writing unplanned steps under a trailing `### Phase: Unplanned` in phased specs (so the phase gate does not count them as unfinished); added `5d2` routing changed approaches to `## Decisions`; scoped `5d`'s removal rule so it cannot discard reconcile output on the happy path.
- Updated `finalize-plan/SKILL.md` to name Step 3d and 5c2/5d2 so the model reaches them.
- Added `tests/plugins/test-plan-reconcile.sh` (11 checks).
- Bumped plan-agent 9.10.1 → 9.11.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Step 3d, commit range, bucketing | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | 5c2, 5d2, scoped 5d | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Names 3d and 5c2/5d2 | Modified |
| `kit/plugins/plan-agent/README.md` | Reconcile description | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.11.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.10.1 → 9.11.0 | Modified |
| `tests/plugins/test-plan-reconcile.sh` | 11-check objective test | Created |

## How it works

Evidence comes from git, not `gh` — the spec's own commit history is precise because this repo commits the plan file alongside the change it describes. Step 3d derives the shipped commit range from `git log --follow -- <spec>.md` with an `...HEAD` fallback when the spec commit has not landed yet.

Work found in the diff but not in the plan is bucketed as "unplanned" and written as `[x] Unplanned: <description>` steps in `## Steps`. In phased specs these land under a trailing `### Phase: Unplanned` heading so `5a0`'s phase gate does not count them as unfinished work. Work that was built differently is routed to `## Decisions`, not to the red-dotted `## Completion Report`.

No change to `build-plan-html.mjs`, `plan-spec.mjs`, or `plan-shell.mjs` was required — all four buckets route into sections the renderer already handles.

## How to use it

```
/plan-agent:finalize-plan docs/plans/<spec>.md
```

The reconcile step fires automatically as Step 3d. Run `finalize-plan` after a plan lands to have the published artifact describe what was actually built rather than only what was planned.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3263bbc9` | 2026-08-30 | feat(plan-agent): reconcile finalize-plan against what actually shipped (9.11.0) |

<!-- generated:end -->

## References

- Plan: [add-shipped-scope-reconcile.md](plans/add-shipped-scope-reconcile.md)
