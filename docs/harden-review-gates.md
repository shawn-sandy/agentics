# Harden Review Gates

> Close the four gaps so the review gates in this marketplace catch the defect classes that actually escape, and so CI and checkout state are never silently as...

<!-- generated:start -->

**Status:** Shipped 2026-08-23  **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Add checks (g)–(k) to the adversarial review checklist — in both live copies — `git-agent/skills/pr-agent/SKILL.md` Step 4.7 and `git-agent/skills/ship/references/self-review.md`.
- Mirror the same five classes into the code-review checklist — at `code-review/skills/code-review-agent/references/review-checklist.md`, section 2.
- Add a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2 — when the workflow list is empty or every job produced no log, report the block and never call it green.
- Add a stale-checkout guard to the `plan-agent:build` pre-flight — , in `skills/build/references/resolve-plan.md` beside the existing dirty-tree guard.
- Sync `team-defaults/skills/sync-rules/rules/review-bot-loops.md` — forward to the maintainer's current version.
- Bump `git-agent`, `code-review`, `plan-agent`, and `team-defaults` — in `.claude-plugin/marketplace.json` and add a CHANGELOG entry to each.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `git-agent/skills/pr-agent/SKILL.md` | Skill instructions | Modified |
| `git-agent/skills/ship/references/self-review.md` | Skill file | Modified |
| `code-review/skills/code-review-agent/references/review-checklist.md` | Skill file | Modified |
| `git-agent/skills/merge/SKILL.md` | Skill instructions | Modified |
| `skills/build/references/resolve-plan.md` | Skill file | Modified |
| `build/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-progressive-disclosure.sh` | Test suite | Modified |
| `resolve-plan.md` | Documentation | Modified |
| `test-progressive-disclosure.sh` | Shell script | Modified |
| `team-defaults/skills/sync-rules/rules/review-bot-loops.md` | Skill file | Modified |

## How it works

Close the four gaps so the review gates in this marketplace catch the defect classes that actually escape, and so CI and checkout state are never silently assumed.

The 2026-08-21 Claude Code insights report (`~/.claude/usage-data/report.html`, 4,736 messages over 652 sessions) named code-review response as the second-most common session goal at 133 sessions, driven by 115 buggy-code friction events. Its evidence points at four specific gaps in this marketplace: 1. The adversarial pre-PR review added in git-agent 4.19.3 checks six defect

The implementation proceeded through the following steps: Add checks (g)–(k) to the adversarial review checklist: in both live; Mirror the same five classes into the code-review checklist: at; Add a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2: when; Add a stale-checkout guard to the `plan-agent:build` pre-flight: , in; Sync `team-defaults/skills/sync-rules/rules/review-bot-loops.md`: forward; Bump `git-agent`, `code-review`, `plan-agent`, and `team-defaults`: in.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
