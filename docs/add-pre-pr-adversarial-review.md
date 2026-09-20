# Add Pre-PR Adversarial Review

> Usage analysis found the top friction is first implementations shipping with real defects — no-op edits, vacuous test assertions, self-introduced regressions...

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- `skills/pr-agent/SKILL.md` — — new Step 4
- `skills/ship/SKILL.md` + `references/self-review.md` — — Step 4
- `skills/ship-autonomous/SKILL.md` — — opens its PR by invoking
- `agents/agent-pr.md`, `agents/agent-ship.md` — — inline report-only
- Housekeeping — — marketplace

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Every git-agent flow that opens a PR runs a single-pass adversarial review of `git diff <base>...HEAD` before `gh pr create` — fresh-context subagent in the interactive skills, inline cold re-read in the background agents — against one shared six-point checklist.

The 2026-08 usage analysis ranks bots-as-QA as the #1 friction: first implementations ship with provable defects (no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth/role/key lookups) that only get caught by PR review bots, costing 2–6 review rounds per PR. The

The implementation proceeded through these steps: `skills/pr-agent/SKILL.md`: new Step 4; `skills/ship/SKILL.md` + `references/self-review.md`: Step 4; `skills/ship-autonomous/SKILL.md`: opens its PR by invoking; `agents/agent-pr.md`, `agents/agent-ship.md`: inline report-only; Housekeeping: marketplace.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
