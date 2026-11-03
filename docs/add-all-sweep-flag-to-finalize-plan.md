# Add `--all` sweep flag to finalize-plan

> Adds a `--all` sweep mode to `finalize-plan` that discovers every non-completed plan, scores each with a token-evidence pass, batch-confirms via one multi-select prompt, and finalizes only selected plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-all-sweep-flag-to-finalize-plan](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep routing clause to `finalize-plan/SKILL.md`, enabling batch finalization of non-completed plans
- Sweep discovers plans via `grep -lE` for `todo`/`in-progress` status tags, excluding `index.html` and `archive/`
- Candidates are scored with the cheap token-evidence pass non-interactively (no prompt per plan)
- One `AskUserQuestion` multi-select prompt batch-confirms all candidates at once
- Single `SendUserFile` delivers all finalized plans
- Updated `argument-hint` and `description` frontmatter to document the flag
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the contract across four files
- Bumped `plan-agent` to `2.13.0` with CHANGELOG entry and marketplace description update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions — sweep routing, `--all` flag | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — feature table row, usage examples | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — version 2.13.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 2.13.0 entry | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — contract pinning | Created |

## How it works

`finalize-plan --all` enters a sweep mode that replaces the single-plan resolution path. The skill runs `grep -lE` over the plans directory to discover every file with a `plan-status` meta tag valued `todo` or `in-progress`, deliberately excluding `index.html` (a gallery page, not a plan) and the `archive/` directory.

Each candidate receives a cheap token-evidence score that reuses the existing single-plan Steps 2 and 3a checks: it scans the plan body for implementation-indicating tokens without opening expensive verification prompts. This keeps the sweep non-interactive at the discovery stage.

A single `AskUserQuestion` with `multiSelect` presents all scored candidates. The user picks which plans to finalize and which criteria mode to apply — one prompt total, not one per plan. Only the selected plans proceed through Steps 3b–5 (the expensive per-criterion verification and frontmatter update), and a single `SendUserFile` delivers the batch results.

The existing single-plan path is untouched: `finalize-plan` without `--all` resolves exactly one plan as before.

## How to use it

```
/plan-agent:finalize-plan --all           # sweep all non-completed plans
/plan-agent:finalize-plan                 # single-plan mode (unchanged)
```

The `--all` flag appears in `argument-hint` frontmatter, the README feature table, and the usage examples.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan](plans/add-all-sweep-flag-to-finalize-plan.md)
