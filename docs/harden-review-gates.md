# Harden review gates across four gap areas

> Closes four gaps identified in the 2026-08-21 usage-insights report: five new adversarial-review defect classes, billing-block detection in merge, a stale-checkout guard in resolve-plan, and a sync of team-defaults review-bot rules.

<!-- generated:start -->

**Status:** Shipped 2026-08-21  **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Updated `kit/plugins/git-agent/skills/pr-agent/SKILL.md` Step 4.7 and `kit/plugins/git-agent/skills/ship/references/self-review.md` — added five new adversarial defect classes (g)–(k) to both files, kept byte-identical. Classes cover: async error swallowing, missing null/undefined guards, off-by-one in loops, untested code paths introduced by the diff, and broken error messages referencing removed symbols.
- Updated `kit/plugins/git-agent/skills/merge/SKILL.md` Step 2 — added never-dispatched / billing-block detection: if every CI job completed in under 5 s with no test output, report the block rather than treating the run as green or red.
- Updated `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` — added stale-checkout guard: before reading plan files, verify that `git status` shows a clean HEAD matching the plan's recorded commit; if not, fetch and reset. (Not added to `build/SKILL.md`, which is at the 596/600-word ceiling.)
- Updated `kit/plugins/team-defaults/skills/sync-rules/references/review-bot-loops.md` — synced with the maintainer's current version: added Hard default behavior, Triage section, and the replies-are-for-humans rule.
- Added `tests/review-gates.test.mjs` — asserts the five new defect classes appear in both `pr-agent/SKILL.md` and `self-review.md`, billing-block detection is in `merge/SKILL.md`, stale-checkout guard is in `resolve-plan.md`, and review-bot-loops contains the Hard default and Triage sections.
- Bumped `git-agent`, `plan-agent`, and `team-defaults` versions in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Self-review reference | Modified |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Plan resolution reference | Modified |
| `kit/plugins/team-defaults/skills/sync-rules/references/review-bot-loops.md` | Review-bot rules | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/team-defaults/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |
| `tests/review-gates.test.mjs` | Gate tests | Created |

## How it works

The 133-session usage report found that 115 sessions involving buggy code had at least one defect that none of the existing adversarial-review classes would catch. The five new classes target the most common missed patterns: async errors that are caught and silently dropped, missing null guards on values that look safe but can be undefined at call sites, loop boundary errors, code paths the diff introduces but no test covers, and error messages that reference a function or variable removed elsewhere in the same PR.

Both `pr-agent/SKILL.md` and `self-review.md` carry the defect list because they serve different callers: `pr-agent` is invoked interactively, while `self-review.md` is loaded by background flows that bypass the skill entry point. Keeping them byte-identical ensures a fix to the list lands in both places atomically.

The billing-block heuristic avoids a false green/red: GitHub Actions bills by wall-clock time, so a quota-blocked run resolves all jobs in seconds. Checking for "completed in under 5 s with no test output" catches this pattern before the merge skill acts on the result.

The stale-checkout guard addresses a class of ghost failures where `resolve-plan` reads plan files from a worktree that hasn't been updated since the last push, producing decisions based on stale state. The guard is placed in `resolve-plan.md` rather than `build/SKILL.md` to stay within the word ceiling.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
