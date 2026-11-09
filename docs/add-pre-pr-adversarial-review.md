# Add pre-PR adversarial review to all PR-opening flows

> Inserts a self-review checkpoint into every git-agent PR-opening path so confirmed defects are fixed before `gh pr create` runs, and unconfirmed findings land in the PR body rather than being silently dropped.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- All five PR-opening flows — `pr-agent`, `ship`, `ship-autonomous`, `agent-pr`, and `agent-ship` — now run adversarial self-review before calling `gh pr create`.
- Interactive skills (`pr-agent`, `ship`) spawn a fresh-context subagent (`code-review:agent-code-reviewer` if available, else `general-purpose`) with the diff and a 6-point checklist.
- Background-mode flows (`ship-autonomous`, `agent-pr`, `agent-ship`) perform an inline cold re-read of the diff against the same checklist without spawning a subagent.
- `pr-agent` Step 4.7: confirmed findings produce a `fix:` commit and re-push before the PR opens; unconfirmed findings are appended to the PR body under `## Review Notes`.
- Added `ship/references/self-review.md` documenting the 6-point checklist and the confirmed/unconfirmed disposition logic.
- Bumped `git-agent` to `4.19.3` (patch) in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR skill | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Self-review contract | Created |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Autonomous ship skill | Modified |
| `kit/plugins/git-agent/agents/agent-pr.md` | Agent prompt | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Agent prompt | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

The pre-PR review runs a 6-point checklist against the diff: correctness (logic errors, off-by-ones), security (injection, credential exposure), test coverage gaps, API contract changes, error handling, and documentation drift. Each finding is classified as confirmed or unconfirmed.

Interactive skills spawn a subagent with no prior context so the review is genuinely independent — the subagent cannot be anchored by the implementation decisions already in the session. Background flows use an inline re-read instead, since spawning interactive agents in a headless context is not reliable.

Confirmed findings always block the PR: the skill commits a `fix:` patch and re-pushes before opening the PR. Unconfirmed findings (plausible but not traced to a definite failure) are surfaced in the PR body under `## Review Notes` so human reviewers can make the final call without the findings disappearing.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `3056b57` | 2026-09-28 | (post-ship commits) |
| `5e1b3c2` | 2026-09-26 | (post-ship commits) |
| `9277c9f` | 2026-09-18 | (post-ship commits) |
| `56a2ea3` | 2026-09-11 | (post-ship commits) |
| `eab3545` | 2026-09-03 | (post-ship commits) |
| `3e849ec` | 2026-08-23 | fix(review-gates): close four gaps found in the usage-insights report (#598) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
