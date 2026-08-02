# Add `--all` sweep flag to finalize-plan

> Extends `/plan-agent:finalize-plan` with a `--all` mode that discovers every non-completed plan in the plans directory and batch-finalizes selected ones.

<!-- generated:start -->

**Status:** Shipped 2026-07-02 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to `/plan-agent:finalize-plan` — discovers plans with a `<meta name="plan-status">` tag valued `todo` or `in-progress` across the plans directory, excluding `index.html` and `archive/` subdirectory (non-plan HTML without the tag is never a candidate).
- Scored candidates non-interactively with the cheap token-evidence pass from the existing Steps 2/3a; token-less plans score 0% rather than prompting, and plans at 80%+ evidence are flagged as "done but not marked".
- Replaced per-plan confirmation with a single two-question `AskUserQuestion` — a multi-select plan picker plus one criteria mode for the whole batch — so the user confirms once for the entire sweep.
- Ran the expensive per-criterion verification, the objective-verification test, and the status writes only on user-selected plans, reusing the existing single-plan pipeline steps (Why: Steps 2–5 are already a reusable per-plan pipeline; only discovery, confirmation, and delivery differ).
- Delivered all updated plan files in a single `SendUserFile` call with a per-plan summary instead of one call per plan.
- Updated `argument-hint` frontmatter to `[plan-file.md|.html] [--all] [--dir <path>]` and skill `description` to include the sweep clause.
- Added a README feature table row, usage example, and sweep-mode paragraph in the `finalize-plan` section so the flag is discoverable without reading the skill body.
- Bumped `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry.
- Added `tests/plugins/test-finalize-all-flag.sh` to pin the flag to the SKILL.md contract, README docs, and marketplace version so they cannot silently diverge.

> See [CHANGELOG v2.13.0](../kit/plugins/plan-agent/CHANGELOG.md#2130--all-sweep-flag-on-finalize-plan-2026-07-02) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions — adds `--all` routing clause and sweep section in `references/sweep-mode.md` | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | Sweep-mode reference — S1 through S5 replacing Steps 2–6 for the `--all` path | Created |
| `kit/plugins/plan-agent/README.md` | Plugin README — feature table row, usage block, and sweep-mode paragraph | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Objective smoke test — pins sweep to SKILL.md contract, README, and marketplace version | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — version bumped to `2.13.0`, description updated | Modified |

## How it works

`finalize-plan`'s Step 1 now checks `$ARGUMENTS` for `--all` before doing any file resolution. When the flag is present, Step 1 routes the entire run to `references/sweep-mode.md`, whose S1–S5 steps replace the normal Steps 2–6 as the top-level flow.

**S1 — Discovery.** The sweep uses `grep -lE` to find every `.html` file under the plans directory that carries a `<meta name="plan-status">` tag whose `content` is `todo` or `in-progress`. Files without the tag (generic HTML, gallery indexes) are never candidates. `index.html` and anything under `archive/` are always excluded.

**S2 — Non-interactive scoring.** Each candidate is scored with the same token-evidence pass from the single-plan evidence step: backtick tokens from the plan body are resolved against the codebase, and the hit rate drives an evidence percentage. No `AskUserQuestion` fires during this phase — plans with no tokens score 0% rather than stalling. Plans at 80%+ evidence are labelled "done but not marked" in the candidate table.

**S3 — Batch confirmation.** One `AskUserQuestion` with `multiSelect` shows the full candidate table sorted by evidence percentage. The user picks which plans to finalize and chooses a single criteria mode for the whole batch. This replaces the per-plan prompt in the single-file flow — one interaction for any number of plans.

**S4 — Selective finalization.** Only the user-selected plans proceed through the expensive Steps 3b (per-criterion verification) and 3c (objective-verification test run). The status writes, `## Completion Report` section, and acceptance-criteria tick-offs from the existing single-plan pipeline apply to each selected plan in sequence.

**S5 — Single delivery.** All updated plan files are bundled into one `SendUserFile` call with a per-plan summary row, rather than delivering files one at a time.

## How to use it

`finalize-plan` is a manual-invoke skill (`disable-model-invocation: true`). Trigger it as a command:

```
/plan-agent:finalize-plan                          # single-plan mode (resolves from IDE or settings)
/plan-agent:finalize-plan add-dark-mode.md         # specific plan
/plan-agent:finalize-plan --all                    # sweep mode — discovers all non-completed plans
/plan-agent:finalize-plan --all --dir ~/my-plans   # sweep a custom plans directory
```

In sweep mode the skill presents a table of candidates with evidence percentages and a multi-select prompt. Select the plans you want finalized, choose a criteria mode, and the skill runs full verification only on the selection.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e274327` | 2026-08-01 | refactor(plan-agent): split five skills into cores plus references (#505) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
- Changelog: [plan-agent v2.13.0](../kit/plugins/plan-agent/CHANGELOG.md#2130--all-sweep-flag-on-finalize-plan-2026-07-02)
