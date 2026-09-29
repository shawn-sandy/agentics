# Harden Review Gates

> Closes four gaps identified in the 2026-08-21 usage-insights report: five defect classes missing from adversarial review, no billing-block detection in the merge skill, no stale-checkout guard before implementation, and a bundled review rule lagging its source.

<!-- generated:start -->

**Status:** Shipped 2026-08-23 **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Added five defect classes (pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, scripts that do not abort) to both adversarial review copies: `git-agent/skills/pr-agent/SKILL.md` Step 4.7 and `git-agent/skills/ship/references/self-review.md`
- Mirrored the same five classes into `code-review/skills/code-review-agent/references/review-checklist.md` section 2
- Added a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2: when the workflow list is empty or every job produced no log, the merge skill reports the block instead of calling CI green
- Added a stale-checkout guard to `plan-agent/skills/build/references/resolve-plan.md` beside the existing dirty-tree guard
- Synced `team-defaults/skills/sync-rules/rules/review-bot-loops.md` to the maintainer's current version (added Hard default, full Triage section, replies-are-for-humans rule)
- Bumped `git-agent`, `code-review`, `plan-agent`, and `team-defaults` with CHANGELOG entries
- Added `tests/review-gates.test.mjs` asserting all five changes against the shipped files

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR-agent skill — Step 4.7 adversarial checklist extended with five defect classes | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Ship self-review reference — same five defect classes, kept byte-identical to pr-agent | Modified |
| `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` | Code-review checklist — five classes mirrored under "Potential Bugs" section 2 | Modified |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge skill — Step 2 dispatch check for billing-blocked CI | Modified |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Build resolve-plan reference — stale-checkout guard added to Step 1 pre-flight | Modified |
| `kit/plugins/git-agent/skills/build/references/resolve-plan.md` | Build resolve-plan reference (git-agent copy) | Missing |
| `tests/review-gates.test.mjs` | Test — asserts all five changes against real shipped files | Created |

## How it works

The 2026-08-21 insights report analysed 4,736 messages across 652 sessions and identified code-review as the second most common session goal (133 sessions) driven by 115 buggy-code friction events. Its evidence pointed at four specific gaps in this marketplace.

The adversarial pre-PR review added in git-agent 4.19.3 checked six defect classes, but the five classes that actually escaped to bot reviewers in the observed sessions — pagination tie-breakers (off-by-one on cursor-based results), unvalidated `parseInt` (NaN propagation), stale derived state (cached values not invalidated on source change), timezone-dependent dates (UTC/local mismatch), and scripts that do not abort on failure (missing `set -e` or equivalent) — were not among them. A grep across `git-agent/` and `code-review/` returned zero hits for all five. The adversarial checklist in `pr-agent/SKILL.md` Step 4.7 and its copy in `ship/references/self-review.md` were extended with these five, and a test asserts the two prompt blocks remain byte-identical so they cannot drift apart.

The `agent-code-reviewer` subagent that Step 4.7 dispatches to reads `review-checklist.md` — a separate file in the `code-review` plugin. Without mirroring the same five classes there, the dispatcher and the dispatched agent would be checking different defects. The classes were added under the existing `### 2. Potential Bugs` section in the checklist.

Billing-block detection existed in `ship-autonomous/references/ci-autofix.md` but not in the `merge` skill. The report counted at least eight sessions spent re-diagnosing the same block. The merge skill reads CI checks thoroughly but never asked "did any job dispatch at all?" A dispatch check was added to Step 2: when the workflow list is empty or every job produced no log, the skill now reports the block and never calls it green. This is the same rule already written in `plan-agent`'s red-green-verify guidance, now present in the plugin that actually acts on CI failures.

Stale-checkout detection was added to `plan-agent`'s `build` pre-flight via `resolve-plan.md`. The `build/SKILL.md` core is at its 600-word progressive-disclosure ceiling (asserted by `tests/plugins/test-progressive-disclosure.sh`), so the guard could not go into the core. The core already delegates Steps 0–1 to `resolve-plan.md`, meaning the guard is read at the right moment at zero core cost. The stale-checkout guard sits inside the Step 1 pre-flight, ahead of plans-directory resolution, beside the existing dirty-tree guard.

The bundled `review-bot-loops.md` in `team-defaults` had drifted behind the maintainer's own copy. The Triage section was entirely missing — including the "drop findings already fixed" rule that the report identified as the most requested already-applied guard. The bundled copy was synced forward; `diff ~/.claude/rules/review-bot-loops.md <bundled>` now exits 0.

The test at `tests/review-gates.test.mjs` asserts each of the five changes against the real shipped files: both adversarial-review prompts contain all five new defect classes and are identical to each other; `merge/SKILL.md` contains the never-dispatched rule; `resolve-plan.md` carries the freshness guard and the core does not; the bundled `review-bot-loops.md` contains the Triage heading and the drop-already-applied sentence. Each assertion fails if the corresponding edit is reverted.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `9d6f4b3` | 2026-08-23 | refactor: retire the unused team-defaults plugin (0.2.3) (#599) |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `eab3545` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
