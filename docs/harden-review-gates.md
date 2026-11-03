# Harden Review Gates

> Closes four gaps identified in the 2026-08-21 insights report: adds five report-identified defect classes to the adversarial review checklist, adds a billing-block dispatch check to `merge`, adds a stale-checkout guard to `plan-agent:build`, and syncs the bundled `review-bot-loops` rule forward.

<!-- generated:start -->

**Status:** Shipped 2026-08-23  **Plan:** [harden-review-gates](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Added five defect classes (pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, scripts that do not abort) to the adversarial review checklist in both `ship/references/self-review.md` and `pr-agent/SKILL.md` Step 4.7, keeping the two copies byte-identical
- Mirrored the same five classes into `code-review/skills/code-review-agent/references/review-checklist.md` section 2
- Added a dispatch check to `merge/SKILL.md` Step 2: when the workflow list is empty or every job produced no log, `merge` reports the block and never calls CI green
- Added a stale-checkout guard to `plan-agent/skills/build/references/resolve-plan.md` before plans-directory resolution
- Synced `team-defaults/skills/sync-rules/rules/review-bot-loops.md` forward to the maintainer's current version (adds Hard default, Triage section, replies-are-for-humans rule)
- Bumped git-agent, code-review, plan-agent, and team-defaults
- Created `tests/review-gates.test.mjs` asserting all five invariants

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Reference — five new defect classes | Modified |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill — five new defect classes (copy) | Modified |
| `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` | Reference — five new defect classes | Modified |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill — never-dispatched billing-block check | Modified |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Reference — stale-checkout guard | Modified |
| `kit/plugins/team-defaults/skills/sync-rules/rules/review-bot-loops.md` | Rule — synced to current version | Modified |
| `tests/review-gates.test.mjs` | Smoke test — all five invariants | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — version bumps | Modified |

## How it works

The 2026-08-21 usage report (4,736 messages, 652 sessions) named code-review response as the second-most common session goal at 133 sessions, driven by 115 buggy-code friction events. It identified four specific gaps.

The adversarial pre-PR review checklist (added in git-agent 4.19.3) checked six defect classes, but the five that actually escaped to bot reviewers were not among them. The classes are now named explicitly in both copies of the checklist and in the code-review agent's own checklist, ensuring the subagent that `ship` dispatches reads the same defect list as the pre-PR gate.

The billing-block detection gap caused at least eight sessions of re-diagnosing the same condition. `merge` already reads check results thoroughly but asked only whether jobs passed or failed, never whether any job dispatched at all. The added Step 2 check keys on an empty workflow list or all-jobs-with-no-log, which is the observable signature of a quota block.

The stale-checkout guard belongs in `resolve-plan.md` beside the existing dirty-tree guard rather than in `build/SKILL.md`, because the core is at its progressive-disclosure word ceiling. The guard runs as part of Step 1 pre-flight before any plans-directory resolution.

The `review-bot-loops.md` rule in `team-defaults` had drifted from the maintainer's current version — it was missing the Hard default, the Triage section (including "drop findings already fixed"), and the replies-are-for-humans rule. The sync brings the bundled copy current.

`review-gates.test.mjs` fails if any edit is reverted: it asserts both adversarial-review prompts contain all five defect classes, both copies are identical, `merge` carries the never-dispatched rule, `resolve-plan.md` carries the freshness guard while the core does not, and the bundled `review-bot-loops.md` contains the Triage heading.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates](plans/harden-review-gates.md)
