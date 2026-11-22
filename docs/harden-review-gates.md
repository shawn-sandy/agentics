# Harden review gates

> An insights report identified four specific gaps in this marketplace's review gates: five defect classes that escaped to bot reviewers were not on the adversarial checklist, billing-block detection lived in one skill only, nothing verified checkout freshness before implementation, and a bundled rule copy had drifted behind the maintainer's version.

<!-- generated:start -->

**Status:** Shipped 2026-08-21 **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Added checks (g)–(k) to the adversarial review checklist in both live copies — `git-agent/skills/pr-agent/SKILL.md` Step 4.7 and `git-agent/skills/ship/references/self-review.md`: pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, and scripts that do not abort on error.
- Mirrored the same five classes into `code-review/skills/code-review-agent/references/review-checklist.md` section 2 (Potential Bugs), so the subagent dispatched by Step 4.7 reads the same defect list.
- Added a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2: when the workflow list is empty or every job produced no log, the skill reports the billing block and never marks CI green.
- Added a stale-checkout guard to `plan-agent/skills/build/references/resolve-plan.md` beside the existing dirty-tree guard — checks whether the branch is behind `origin/<branch>` before implementation begins, without touching the 596-word core.
- Synced `team-defaults/skills/sync-rules/rules/review-bot-loops.md` forward to the maintainer's current version, adding the Hard default, the Triage section, the drop-already-applied rule, and the replies-are-for-humans constraint.
- Added `tests/review-gates.test.mjs`: asserts both adversarial-review prompts contain all five new defect classes and are identical to each other, `merge/SKILL.md` contains the never-dispatched rule, `resolve-plan.md` carries the freshness guard, and the bundled `review-bot-loops.md` contains the Triage heading and the drop-already-applied sentence.
- Bumped git-agent, code-review, plan-agent, and team-defaults.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Checks (g)–(k) added | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Checks (g)–(k) added | Modified |
| `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` | Five new defect classes | Modified |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Billing-block dispatch check | Modified |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Stale-checkout guard | Modified |
| `kit/plugins/team-defaults/skills/sync-rules/rules/review-bot-loops.md` | Synced to current | Modified |
| `tests/review-gates.test.mjs` | Gate drift assertions | Created |
| `.claude-plugin/marketplace.json` | Four plugin version bumps | Modified |

## How it works

**Adversarial checklist gaps**: The five defect classes added (g–k) are those identified in the insights report as having actually escaped to bot reviewers — pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, and scripts that don't abort. Both copies of the checklist are kept identical; `tests/review-gates.test.mjs` asserts byte-equality to prevent drift.

**Billing-block in merge**: `merge` reads CI check results before merging. When the workflow list is empty or every job completed in seconds with no log output, the skill now reports this as an `external-blocker` (billing block / quota) rather than treating absent CI as green.

**Stale-checkout guard**: Added to `resolve-plan.md` (a reference file loaded by `build` during Steps 0–1) rather than to `build/SKILL.md` itself, which was at the 596-word progressive-disclosure ceiling. The guard runs a `git fetch --dry-run` check before lane authoring begins.

**review-bot-loops drift**: The bundled copy had drifted from the maintainer's own `~/.claude/rules/review-bot-loops.md`. The synced version adds the Triage section — including the drop-already-applied rule — and the Hard default.

## How to use it

The improvements apply automatically for anyone with git-agent, code-review, plan-agent, and team-defaults installed. No invocation change needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-21 | feat: harden review gates — five defect classes, billing-block in merge, stale-checkout guard, sync review-bot-loops (four plugins bumped) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
