# Add Pre-PR Adversarial Review

> Usage analysis found the top friction is first implementations shipping with real defects — no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth lookups — caught only by PR review bots at 2-6 rounds per PR. This adds a mandatory single-pass adversarial review of the branch diff to every git-agent flow that opens a PR.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- Added a new Step 4.7 to `skills/pr-agent/SKILL.md` that spawns a fresh-context review subagent (`code-review:agent-code-reviewer`, or `general-purpose` as fallback) to review `git diff <base>...HEAD` against a six-point checklist before `gh pr create`; confirmed findings become a `fix:` commit and re-push, unconfirmed ones go in the PR body's `## Review Notes`.
- Upgraded `skills/ship/SKILL.md`'s Step 4.5 from a four-check inline list to the subagent dispatch, and extracted the six-point checklist into `references/self-review.md` where it is shared verbatim.
- Updated `skills/ship-autonomous/SKILL.md` so it names the adversarial review in its Step 4 rather than duplicating it (the core was at the 600-word ceiling enforced by `test-skill-split-git-social.sh`).
- Added the inline report-only variant to `agents/agent-pr.md` and `agents/agent-ship.md`: cold re-read of the diff with the same checklist, findings in `## Review Notes` and the final report, no Agent tool and `disallowedTools` denying edits so the background agent cannot modify files. A proven secret stops the flow before any PR body is written.
- Bumped git-agent to 4.19.3 and added a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill — new Step 4.7, subagent dispatch | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill — Step 4.5 upgraded to subagent dispatch | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Reference — six-point checklist | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Skill — Step 4 names the adversarial review | Modified |
| `kit/plugins/git-agent/agents/agent-pr.md` | Agent — inline cold re-read variant with six checks | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Agent — inline cold re-read variant with six checks | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — git-agent 4.19.2 to 4.19.3 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — v4.19.3 entry | Modified |

## How it works

The author of a diff is the worst-placed reviewer of it — knowing what an edit was meant to do makes a no-op edit read like a fix. The review therefore runs in a context with no memory of the implementation. Interactive skills spawn a fresh-context subagent; background agents perform an inline cold re-read. Both use the same six-point checklist from `references/self-review.md`, ensuring consistent coverage regardless of the flow.

For interactive flows (`pr-agent`, `ship`), the new Step 4.7 sits between Step 4.5 (pre-push checks) and Step 5 (PR creation). The subagent is `code-review:agent-code-reviewer` when available, falling back to `general-purpose`. Confirmed findings trigger a `fix:` commit with a re-push before `gh pr create` — post-push, never amend, per the repo's commit protocol. Unconfirmed findings are collected in the PR body under `## Review Notes` so reviewers see what the author already considered.

`ship-autonomous/SKILL.md` calls `pr-agent` to open its PR and therefore inherits Step 4.7 automatically. Its Step 4 simply names the adversarial review rather than duplicating the logic — the core skill was already at the 600-word ceiling enforced by `test-skill-split-git-social.sh`, so duplication was not possible anyway.

Background agents (`agent-pr.md`, `agent-ship.md`) use a report-only variant: `disallowedTools` denies all edit tools, so the agent can only read and report. Findings go in `## Review Notes` and the final report. A proven secret — any credential, token, or key identified in the diff — stops the flow entirely and is never included in a PR body.

The design guarantees single-pass everywhere. No flow loops the review: one pass per PR, with findings routed to either a fix commit or review notes.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
