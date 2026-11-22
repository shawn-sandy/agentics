# Add Pre-PR Adversarial Review

> First implementations ship with real defects — no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth lookups — caught only by PR review bots at 2–6 rounds per PR. This adds a mandatory single-pass adversarial review to every git-agent flow that opens a PR.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- Added Step 4.7 to `skills/pr-agent/SKILL.md` spawning a fresh-context review subagent (`code-review:agent-code-reviewer` or `general-purpose`) before `gh pr create`; confirmed findings become a `fix:` commit + re-push; unconfirmed ones go in the PR body's `## Review Notes`; `Agent` added to `allowed-tools`.
- Updated `skills/ship/SKILL.md` and added `references/self-review.md`: Step 4.5 upgraded to subagent dispatch with the six-point checklist; `--no-review` opt-out kept; amend-before-push procedure preserved.
- Updated `skills/ship-autonomous/SKILL.md`: inherits Step 4.7 by invoking `pr-agent`; Step 4 names the review without duplicating it.
- Updated `agents/agent-pr.md` and `agents/agent-ship.md`: inline report-only variant (no Agent tool, edits denied); cold re-read with the same six-point checklist; findings in `## Review Notes`; a proven secret stops the flow.
- Bumped git-agent 4.19.2 → 4.19.3 in `.claude-plugin/marketplace.json` with matching CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Step 4.7 subagent dispatch | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Adversarial review step | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Six-point checklist reference | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Inherited review | Modified |
| `kit/plugins/git-agent/agents/agent-pr.md` | Inline report-only review | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Inline report-only review | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.19.3 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.19.2 → 4.19.3 | Modified |

## How it works

Every git-agent flow that opens a PR now runs a single-pass adversarial review of `git diff <base>...HEAD` before `gh pr create`. Interactive skills use a fresh-context subagent where the flow can spawn one — the author's context is withheld so the reviewer cannot read the implementation intent into an ambiguous diff. Background agents use an inline cold re-read with the same six-point checklist.

The checklist covers: no-op edits (a change whose diff has no effect), vacuous assertions (a test that always passes), self-introduced regressions (a diff that breaks an existing passing test), unsafe auth/role lookups (a permission check that returns the wrong value on error), missing error paths, and secrets in content. Single pass — no flow loops the review.

Confirmed findings become a `fix:` commit + re-push (post-push only, never amend); unconfirmed ones land in `## Review Notes` in the PR body. A proven secret stops the flow entirely and is never named in the PR body.

## How to use it

The review runs automatically as part of every PR-opening flow: `/git-agent:ship`, `/git-agent:pr-agent`, `/git-agent:ship-autonomous`. Pass `--no-review` to the `ship` skill to skip it.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `324cc3c2` | 2026-08-19 | feat(git-agent): mandatory pre-PR adversarial review in all PR-opening flows (4.19.3) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
