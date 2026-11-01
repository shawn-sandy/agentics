# Harden Review Gates

> Closes four gaps in the marketplace's review gates: missing defect classes in the adversarial review, no billing-block detection in merge, no checkout-freshness check before build, and a stale bundled review-bot-loops rule.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Added five defect classes (g)–(k) to both adversarial review prompt blocks — `git-agent/skills/pr-agent/SKILL.md` Step 4.7 and `git-agent/skills/ship/references/self-review.md` — covering pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, and scripts that do not abort on failure. Both blocks remain byte-identical to each other.
- Mirrored the same five classes into `code-review/skills/code-review-agent/references/review-checklist.md` section 2, so the subagent dispatched by the adversarial review reads the same checklist.
- Added a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2: when the workflow list is empty or every job produced no log, the merge skill reports the billing block and never calls it green.
- Added a stale-checkout guard to `plan-agent/skills/build/references/resolve-plan.md` beside the existing dirty-tree guard, so `build` checks checkout freshness before implementing.
- Synced `team-defaults/skills/sync-rules/rules/review-bot-loops.md` forward to the maintainer's current version, restoring the missing Hard default, the full Triage section (including "drop findings already fixed"), and the replies-are-for-humans rule.
- Bumped git-agent, code-review, plan-agent, and team-defaults in `.claude-plugin/marketplace.json` with CHANGELOG entries.
- Shipped `tests/review-gates.test.mjs` asserting all five new defect classes, byte-identical prompt blocks, the dispatch check, the freshness guard placement, and the synced rule file.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Adversarial review prompt | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Self-review prompt | Modified |
| `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` | Code review checklist | Modified |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge skill | Modified |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Build pre-flight | Modified |
| `tests/review-gates.test.mjs` | Objective test | Created |

## How it works

The five defect classes were identified from a usage report (4,736 messages over 652 sessions) showing 115 buggy-code friction events. Pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, and scripts without `set -e` were the classes that escaped to bot reviewers most often — and a grep across the marketplace returned zero hits for them.

The stale-checkout guard was placed in `resolve-plan.md` rather than `build/SKILL.md` because the core is at 596 words against a 600-word progressive-disclosure ceiling. The core delegates Steps 0–1 to `resolve-plan.md`, so the guard loads at the right moment with zero core cost.

The billing-block detection in the merge skill addresses a pattern of 8+ repeated diagnostic sessions. Previously, an empty CI job list could propagate through the check-reading logic as "no failures" rather than "never dispatched." The new gate surfaces the billing block explicitly before the "If any of these fails" paragraph.

The `review-bot-loops.md` sync was a file-copy operation: `team-defaults` bundles a copy for distribution, and the bundled copy had drifted behind the maintainer's own version, missing the Triage section that handles "drop findings already fixed."

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8a8a392f` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `da54ec10` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `5e1b3c2a` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `56a2ea36` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |
| `eab35454` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
