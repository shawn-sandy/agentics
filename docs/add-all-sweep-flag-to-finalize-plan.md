# Add `--all` sweep flag to finalize-plan

> Adds a `--all` sweep mode to the finalize-plan skill, discovering every non-completed plan and batch-finalizing selected ones in one pass.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` routing clause to `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md`, enabling sweep discovery via `grep -lE` for plans with `todo`/`in-progress` status, excluding `index.html` and `archive/` (so non-plan HTML is never a candidate).
- Added a `## Sweep mode (--all)` section with cheap non-interactive scoring (token-evidence pass), batch confirmation via one multi-select `AskUserQuestion`, and a single `SendUserFile` delivery — reusing the existing per-plan pipeline rather than duplicating it.
- Updated `argument-hint` and `description` frontmatter to document the `--all` invocation form.
- Documented the flag in `kit/plugins/plan-agent/README.md` with a feature table row, usage example, and sweep-mode paragraph.
- Added a `2.13.0` CHANGELOG entry and bumped `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json`.
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the flag to the SKILL.md contract, README docs, and marketplace version across seven checks.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions — routing clause and sweep mode section | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — table row and usage example | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — version 2.13.0 | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — contract and docs assertions | Created |

## How it works

The `finalize-plan` skill previously resolved exactly one plan file per invocation. When `--all` is passed in Step 1, the skill takes a separate routing branch: it discovers candidates by running `grep -lE` for plans whose `plan-status` meta tag holds a `todo` or `in-progress` value, explicitly skipping `index.html` and any file under `archive/` to avoid non-plan HTML.

Each candidate is scored cheaply using the existing token-evidence pass from Steps 2 and 3a — without triggering the full per-criterion verification prompts. Plans with no matching tokens score 0% and are included in the candidate list but naturally fall to the bottom.

A single `AskUserQuestion` with `multiSelect` presents all candidates sorted by evidence score and asks the user to select which plans to finalize and which criteria mode to apply. Only the user-selected plans proceed through Steps 3b, 3c, and 5 (the per-plan verification and completion path). This keeps confirmation to one prompt regardless of how many candidates are found, which is the core ergonomic improvement over running finalize-plan repeatedly.

After all selected plans are finalized, the skill emits a single `SendUserFile` delivery with a summary. The smoke test at `tests/plugins/test-finalize-all-flag.sh` asserts all seven structural invariants: the routing clause, sweep section, discovery command, multi-select confirmation, batch delivery, README coverage, and marketplace version.

## How to use it

`finalize-plan` is activated by its description: "Marks a plan as completed. Verifies codebase evidence, ticks acceptance criteria, and re-renders the HTML; --all sweeps unmarked plans."

```
/plan-agent:finalize-plan --all           # sweep all non-completed plans
/plan-agent:finalize-plan my-plan.md      # single-plan mode (unchanged)
```

The `--all` flag also accepts a `--dir <path>` override for non-default plan directories.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
