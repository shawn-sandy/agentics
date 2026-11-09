# Add Pre-PR Adversarial Review

> Every git-agent flow that opens a PR runs a single-pass adversarial review of `git diff <base>...HEAD` before `gh pr create` — fresh-context subagent in interactive skills, inline cold re-read in background agents — against one shared six-point checklist.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-pre-pr-adversarial-review](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- Added Step 4.7 to `git-agent/skills/pr-agent/SKILL.md` — spawns `code-review:agent-code-reviewer` (fallback: `general-purpose`) as a fresh-context subagent; confirmed findings become a `fix:` commit + re-push; unconfirmed findings go in the PR body's `## Review Notes`
- Upgraded `ship/SKILL.md` Step 4.5 from a four-check inline list to the six-point checklist with subagent dispatch; references `ship/references/self-review.md`
- `ship-autonomous/SKILL.md` inherits the review by invoking `pr-agent` (no duplication of the checklist)
- Added inline report-only variant to `agents/agent-pr.md` and `agents/agent-ship.md` — cold re-read with the same checklist, no `Agent` tool, no edits in background agents
- Bumped `git-agent` to `4.19.3` with CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill — Step 4.7 adversarial review subagent | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill — Step 4.5 upgraded to six-point checklist | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Reference — six-point checklist, dispatch procedure | Created |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Skill — inherits review via pr-agent | Modified |
| `kit/plugins/git-agent/agents/agent-pr.md` | Background agent — inline cold re-read variant | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Background agent — inline cold re-read variant | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — git-agent 4.19.3 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history — v4.19.3 entry | Modified |

## How it works

The author of a diff is the worst-placed reviewer of it: knowing what an edit was meant to do makes a no-op edit read like a fix. The review must run in a context with no memory of the implementation.

In interactive skills (`pr-agent`, `ship`), Step 4.7 spawns a fresh-context subagent that reads only `git diff <base>...HEAD` and applies the six-point checklist. Confirmed findings trigger a `fix:` commit and re-push before `gh pr create` — the PR never opens with a known defect. Unconfirmed findings land in `## Review Notes` in the PR body.

Background agents (`agent-pr`, `agent-ship`) use an inline cold re-read: the same checklist, but no `Agent` tool call (disallowed tools deny edits), so findings are report-only. A proven secret in the diff stops the flow entirely and is never named in a PR body.

`ship-autonomous` inherits the review by delegating to `pr-agent` — the review lives in one place, not N copies.

The review is a single pass everywhere. No flow loops it.

## How to use it

The adversarial review fires automatically before every `gh pr create` call in `pr-agent`, `ship`, and `ship-autonomous`. No user action required.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review](plans/add-pre-pr-adversarial-review.md)
