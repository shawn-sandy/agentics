# Add Pre-PR Adversarial Review

> Every git-agent flow that opens a PR now runs a single-pass adversarial review of `git diff <base>...HEAD` before `gh pr create`, in a fresh-context subagent where possible and as an inline cold re-read in background agents.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- Added Step 4.7 to `skills/pr-agent/SKILL.md` spawning the review subagent (`code-review:agent-code-reviewer` else `general-purpose`); confirmed findings become a `fix:` commit + re-push (post-push only, never amend); unconfirmed findings go in the PR body's `## Review Notes`; `Agent` added to `allowed-tools`.
- Upgraded `skills/ship/SKILL.md` Step 4.5 from a four-check inline list to a subagent dispatch; extracted the six-point checklist and dispatch instructions into new `references/self-review.md`; `--no-review` opt-out kept.
- Updated `skills/ship-autonomous/SKILL.md` Step 4 to name the adversarial review (inherits via its `pr-agent` invocation rather than duplicating the logic).
- Added the inline report-only variant to `agents/agent-pr.md` and `agents/agent-ship.md`: cold re-read with the same six-point checklist, findings in `## Review Notes`; `disallowedTools` denies edits; a proven secret stops the flow and is never named in a PR body.
- Bumped git-agent to 4.19.3 in `.claude-plugin/marketplace.json`; added CHANGELOG v4.19.3 entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Step 4.7 — review subagent dispatch | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Step 4.5 — subagent dispatch with opt-out | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Six-point checklist and dispatch instructions | Created |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Step 4 — names the adversarial review | Modified |
| `kit/plugins/git-agent/agents/agent-pr.md` | Inline report-only variant | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Inline report-only variant | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.19.3 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.19.3 entry | Modified |

## How it works

The 2026-08 usage analysis ranked bots-as-QA as the number-one friction: first implementations ship with provable defects (no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth/role/key lookups) that only get caught by PR review bots, costing 2–6 review rounds per PR. The core insight is that the author of a diff is the worst-placed reviewer of it — knowing what an edit was *meant* to do makes a no-op edit read like a fix — so the review must run in a context with no memory of the implementation.

For interactive skills (`ship` and `pr-agent`), Step 4.5/4.7 spawns a fresh-context subagent: preferring `code-review:agent-code-reviewer` and falling back to `general-purpose`. The subagent receives the raw `git diff <base>...HEAD` with no implementation context. Confirmed findings become a `fix:` commit and re-push (never amend, because the PR has already been pushed at this point in `pr-agent`, or is about to be); unconfirmed findings go into the PR body under `## Review Notes`.

For background agents (`agent-pr.md` and `agent-ship.md`), there is no `Agent` tool available, so the review runs inline as a cold re-read of the diff against the same six-point checklist. The `disallowedTools` list denies any editing tool, keeping the agent in report-only mode. If a proven secret is detected, the flow stops and the secret is never written into the PR body.

`ship-autonomous` inherits the review through its `pr-agent` delegation rather than duplicating it — the core logic lives in one place and both skills stay in sync automatically.

The review is single-pass everywhere. No flow loops the review or has a re-review step.

## How to use it

The review runs automatically as part of every PR-opening flow. No user action required.

```
/git-agent:ship               # runs review as Step 4.5 before pr create; --no-review to skip
/git-agent:ship-autonomous    # inherits via pr-agent delegation
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `eab3545` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
- Changelog: `kit/plugins/git-agent/CHANGELOG.md` — v4.19.3 entry
