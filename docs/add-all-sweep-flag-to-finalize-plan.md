# Add `--all` sweep flag to finalize-plan

> Extends `/plan-agent:finalize-plan` with a `--all` sweep mode that discovers every non-completed plan, scores each with token evidence, and batch-confirms via one multi-select prompt.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep routing clause to `finalize-plan` Step 1, branching to a new `references/sweep-mode.md` reference file instead of the single-file flow
- Discovery stage (S1) greps plans directory for `plan-status` meta tags valued `todo` or `in-progress`, excluding `index.html` and never descending into `archive/`
- Non-interactive scoring stage (S2) reuses the existing token-evidence pass; token-less plans score 0% rather than prompting
- Batch confirmation (S3) via one `AskUserQuestion` with `multiSelect` — one prompt for all candidates, not one per plan
- Finalization (S4) applies the per-plan pipeline (Steps 3b/3c/5) only to user-selected plans, then delivers all updated files via a single `SendUserFile` (S5)
- Updated `argument-hint`, `description` frontmatter, README documentation, and marketplace version to `2.13.0`
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the flag to the SKILL.md contract, README docs, and marketplace version

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill contract — `--all` routing clause and sweep-mode reference | Modified |
| `kit/plugins/plan-agent/README.md` | User-facing docs — feature table row and sweep-mode usage examples | Modified |
| `.claude-plugin/marketplace.json` | Plugin version registry — bumped to `2.13.0` | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — pins flag contract, README docs, and version | Created |

## How it works

Before this change, `/plan-agent:finalize-plan` resolved exactly one plan file per invocation — either a named file or the most recently modified plan in the directory. Plans that were fully implemented but never marked completed could accumulate silently with no discovery path.

The `--all` flag adds a new routing branch at the top of Step 1. When `$ARGUMENTS` contains `--all`, the skill delegates immediately to `references/sweep-mode.md` (a dedicated reference file) rather than entering the single-file resolution path. This keeps the existing per-plan pipeline unchanged while adding a discovery layer on top of it.

The sweep runs in five stages. S1 discovers candidates by running `grep -lE` against the plans directory searching for a `plan-status` meta tag valued `todo` or `in-progress`. Two exclusions are hard-coded: `index.html` is never a candidate (it is a generated gallery, not a plan), and the search never descends into `archive/`.

S2 scores each candidate using the cheap token-evidence pass already defined in `references/evidence-analysis.md` Steps 2 and 3a. The scoring is non-interactive — if a plan has no recognizable implementation tokens it scores 0% rather than prompting the user mid-sweep. This keeps the pre-confirmation phase fast even for large plan directories.

S3 presents the scored candidates to the user as a single `AskUserQuestion` with a `multiSelect` widget. The key design decision here is one prompt for the entire batch: the previous per-plan finalize flow required one confirmation per plan, making a sweep of ten plans require ten confirmations. The multi-select reduces that to two answers (plan picker + criteria mode).

S4 runs the standard per-plan finalization pipeline (Steps 3b, 3c, and 5 from the existing skill) only for the plans the user selected. S5 delivers all updated plan files in a single `SendUserFile` call rather than one per plan.

The `tests/plugins/test-finalize-all-flag.sh` smoke test asserts that the SKILL.md routing clause is present, the sweep section exists with its `grep -lE` todo/in-progress discovery pattern, the `index.html` and `archive/` exclusions are documented, the multi-select batch confirmation is used, and that both the README and `marketplace.json` carry version `2.13.0`.

## How to use it

```bash
# Sweep all non-completed plans and batch-confirm
/plan-agent:finalize-plan --all

# Combine with --dir to target a non-default plans directory
/plan-agent:finalize-plan --all --dir path/to/plans
```

The sweep presents a scored candidate list, one multi-select prompt to pick which plans to finalize and choose the criteria mode, then finalizes only the selected ones.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7ded3be` | 2026-08-05 | feat(plan-agent): phase checkpoints and a Decisions ledger for plan specs (8.6.0) (#528) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
- Related docs: `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md`, `kit/plugins/plan-agent/README.md`
