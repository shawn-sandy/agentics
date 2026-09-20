# Harden Review Gates

> Close the four gaps so the review gates in this marketplace catch the defect classes that actually escape, and so CI and checkout state are never silently as...

<!-- generated:start -->

**Status:** Shipped 2026-08-23  **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Add checks (g)–(k) to the adversarial review checklist — in both live (the gate exists but is aimed away from the observed leak.)
- Mirror the same five classes into the code-review checklist — at (`agent-code-reviewer` is the subagent Step 4.7 dispatches to; the)
- Add a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2 — — when (removes eight-plus sessions of repeated re-diagnosis.)
- Add a stale-checkout guard to the `plan-agent:build` pre-flight — , in (implementation is where a stale checkout turns into a false premise.)
- Sync `team-defaults/skills/sync-rules/rules/review-bot-loops.md` — forward (the shipped copy is a stale subset; the missing Triage section is)
- Bump `git-agent`, `code-review`, `plan-agent`, and `team-defaults` — in (a CI guard fails the PR if a touched plugin's version does not exceed)

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Close the four gaps so the review gates in this marketplace catch the defect classes that actually escape, and so CI and checkout state are never silently assumed.

The 2026-08-21 Claude Code insights report (`~/.claude/usage-data/report.html`, 4,736 messages over 652 sessions) named code-review response as the second-most common session goal at 133 sessions, driven by 115 buggy-code friction events. Its evidence points at four specific gaps in this marketplace:

The implementation proceeded through these steps: Add checks (g)–(k) to the adversarial review checklist: in both live; Mirror the same five classes into the code-review checklist: at; Add a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2: when; Add a stale-checkout guard to the `plan-agent:build` pre-flight: , in; Sync `team-defaults/skills/sync-rules/rules/review-bot-loops.md`: forward.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
