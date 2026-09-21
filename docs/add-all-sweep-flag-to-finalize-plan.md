# Add `--all` sweep flag to finalize-plan

> Add a `--all` sweep mode to the `finalize-plan` skill that discovers every non-completed plan in the plans directory, scores each with the existing token-evi...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Add sweep mode to `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` — a `--all` routing clause in Step 1 plus a `## Sweep mode (--all)` section (S1 discover via `grep -l` for a `plan-status` meta tag valued `todo`/`in-progress`, S2 cheap non-interactive scoring reusing Steps 2/3a token checks, S3 batch confirm via one two-question `AskUserQuestion` with `multiSelect`, S4 finalize selected plans via Steps 3b/3c/5, S5 single `SendUserFile` delivery). Update `argument-hint` and `description` frontmatter. —
- Document the flag in `kit/plugins/plan-agent/README.md` — feature table row, usage example, sweep-mode paragraph in both finalize-plan sections. —
- Add a `2.13.0` CHANGELOG entry and bump `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` (new behavior = minor), extending the marketplace description with the sweep clause. —
- Add `tests/plugins/test-finalize-all-flag.sh` pinning the flag to the SKILL.md contract, README docs, and marketplace version. —

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Test suite | Created |

## How it works

Add a `--all` sweep mode to the `finalize-plan` skill that discovers every non-completed plan in the plans directory, scores each with the existing token-evidence pass, batch-confirms via one multi-select prompt, and finalizes only the selected plans.

`/plan-agent:finalize-plan` is strictly single-plan: it resolves one filename (or the most recently modified plan) and finalizes it. Plans that are fully implemented but never marked completed accumulate silently in the plans directory — nothing discovers them. The user wants finalize-plan to be able to search for done-but-unmarked plans and mark them completed in one pass.

The implementation proceeded through the following steps: Add sweep mode to `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` — a `--all` routing clause in Step 1 plus a `## Sweep mode (--all)` section (S1 discover via `grep -l` for a `plan-status` meta tag valued `todo`/`in-progress`, S2 cheap non-interactive scoring reusing Steps 2/3a token checks, S3 batch confirm via one two-question `AskUserQuestion` with `multiSelect`, S4 finalize selected plans via Steps 3b/3c/5, S5 single `SendUserFile` delivery). Update `argument-hint` and `description` frontmatter. —; Document the flag in `kit/plugins/plan-agent/README.md` — feature table row, usage example, sweep-mode paragraph in both finalize-plan sections. —; Add a `2.13.0` CHANGELOG entry and bump `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` (new behavior = minor), extending the marketplace description with the sweep clause. —; Add `tests/plugins/test-finalize-all-flag.sh` pinning the flag to the SKILL.md contract, README docs, and marketplace version. —.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
