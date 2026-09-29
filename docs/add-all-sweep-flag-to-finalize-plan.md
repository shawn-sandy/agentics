# Add `--all` sweep flag to finalize-plan

> Adds a `--all` sweep mode to `/plan-agent:finalize-plan` that discovers every non-completed plan, scores each with token-evidence, batch-confirms via multi-select, and finalizes only the selected plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to `finalize-plan` that discovers all non-completed plans in one pass
- Sweep discovery uses `grep -lE` on `plan-status` meta tags valued `todo` or `in-progress`, excluding `index.html` and never descending into `archive/`
- Candidates are scored non-interactively using the existing cheap token-evidence pass (token-less plans score 0%)
- Single batch confirmation via one `AskUserQuestion` multi-select prompt covers all candidates
- Per-criterion verification and the objective test run only on user-selected plans
- Updated `argument-hint` in SKILL.md frontmatter to document `--all` and `--dir <path>` flags
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the flag contract across SKILL.md, README, and marketplace
- Bumped `plan-agent` to `2.13.0` in marketplace with matching CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill contract — Step 1 routing clause and sweep-mode reference | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | Full `--all` sweep flow (S1–S5) | Created |
| `kit/plugins/plan-agent/README.md` | Feature table row, usage example, sweep-mode descriptions | Modified |
| `.claude-plugin/marketplace.json` | Version bumped to `2.13.0`; description updated | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test enforcing the sweep contract across all four files | Created |

## How it works

`finalize-plan` is invoked as `/plan-agent:finalize-plan`. Without arguments it resolves the most recently modified plan; with a filename argument it finalizes that single plan. The `--all` flag changes Step 1: instead of resolving a single file, the skill routes immediately to `references/sweep-mode.md` and its S1–S5 sweep replaces the normal Steps 2–6 as the top-level flow.

In sweep mode (S1) the skill runs a `grep -lE` scan for any HTML file carrying a `plan-status` meta tag valued `todo` or `in-progress`. The scan explicitly excludes `index.html` and never descends into `archive/`, so generated gallery files and archived plans are never treated as sweep candidates.

Each discovered candidate is scored using the same cheap token-evidence pass from Steps 2/3a of the single-plan flow — file tokens and identifiers from the plan are searched in the codebase. Plans whose tokens cannot be located score 0%. This scoring runs non-interactively: no per-plan prompts interrupt the batch.

After scoring, a single `AskUserQuestion` call presents all candidates as a multi-select picker, sorted by evidence score, alongside a choice of criteria mode. Only plans the user selects proceed through the expensive per-criterion verification (Steps 3b/3c) and the final HTML re-render and delivery (Steps 5/6). Deselected plans are left untouched.

The test at `tests/plugins/test-finalize-all-flag.sh` pins seven assertions: the `--all` routing clause appears in SKILL.md, the sweep reference exists, discovery uses `grep -lE` for the `todo`/`in-progress` values, `index.html` and `archive/` are excluded, multi-select batch confirmation is present, the README documents the flag, and the marketplace version is `2.13.0`.

## How to use it

```text
# Finalize a single plan (existing behavior)
/plan-agent:finalize-plan add-dark-mode.md

# Sweep all non-completed plans in the default plans directory
/plan-agent:finalize-plan --all

# Sweep a different plans directory
/plan-agent:finalize-plan --all --dir path/to/plans
```

After running `--all`, the skill presents a scored table of candidates. Select the plans to finalize; only those are edited and re-rendered.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `a2b4016` | 2026-09-13 | feat(plan-agent): build-proposal chooses an approach before it authors (9.18.0) (#634) |
| `77aa33e` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `37cc607` | 2026-08-30 | docs(plan-agent): reconcile skill total and dispatch hook count (9.10.2) (#612) |
| `88a686a` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `6d6bfeb` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |
| `be304fd` | 2026-08-26 | feat(plan-agent): publish-hub — bundle a plan and its related HTML into one hub artifact (9.8.0) (#603) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
