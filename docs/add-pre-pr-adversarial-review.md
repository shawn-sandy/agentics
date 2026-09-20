# Add Pre-PR Adversarial Review

> Usage analysis found the top friction is first implementations shipping with real defects — no-op edits, vacuous test assertions, self-introduced regressions...

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- `skills/pr-agent/SKILL.md` — new Step 4.7 spawning the review subagent
- `skills/ship/SKILL.md` + `references/self-review.md` — Step 4.5
- `skills/ship-autonomous/SKILL.md` — opens its PR by invoking
- `agents/agent-pr.md`, `agents/agent-ship.md` — inline report-only
- Housekeeping — marketplace.json 4.19.2 → 4.19.3, CHANGELOG v4.19.3

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `skills/pr-agent/SKILL.md` | Skill instructions | Modified |
| `skills/ship/SKILL.md` | Skill instructions | Modified |
| `references/self-review.md` | Documentation | Modified |
| `skills/ship-autonomous/SKILL.md` | Skill instructions | Modified |
| `test-skill-split-git-social.sh` | Shell script | Modified |
| `agents/agent-pr.md` | Documentation | Modified |
| `agents/agent-ship.md` | Documentation | Modified |

## How it works

Every git-agent flow that opens a PR runs a single-pass adversarial review of `git diff <base>...HEAD` before `gh pr create` — fresh-context subagent in the interactive skills, inline cold re-read in the background agents — against one shared six-point checklist.

The 2026-08 usage analysis ranks bots-as-QA as the #1 friction: first implementations ship with provable defects (no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth/role/key lookups) that only get caught by PR review bots, costing 2–6 review rounds per PR. The author of a diff is the worst-placed reviewer of it — knowing what an edit was

The implementation proceeded through the following steps: `skills/pr-agent/SKILL.md`: new Step 4; `skills/ship/SKILL.md` + `references/self-review.md`: Step 4; `skills/ship-autonomous/SKILL.md`: opens its PR by invoking; `agents/agent-pr.md`, `agents/agent-ship.md`: inline report-only; Housekeeping: marketplace.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
