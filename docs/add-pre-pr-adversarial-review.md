# Add Pre-PR Adversarial Review

> Adds a mandatory single-pass adversarial review of the branch diff before `gh pr create` in every git-agent flow that opens a PR, run in a fresh-context subagent (interactive) or inline cold re-read (background agents).

<!-- generated:start -->

**Status:** Shipped 2026-10-31  **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- Added `Step 4.7` to `skills/pr-agent/SKILL.md`: spawns a review subagent (`code-review:agent-code-reviewer` when available, else `general-purpose`) against `git diff <base>...HEAD`; confirmed findings become a `fix:` commit + re-push (post-push, so never amend); unconfirmed findings go in the PR body's `## Review Notes` section.
- Upgraded `skills/ship/SKILL.md` Step 4.5 from a four-check inline list to the six-point checklist subagent dispatch; created `references/self-review.md` with the checklist, dispatch procedure, and `--no-review` opt-out.
- Updated `skills/ship-autonomous/SKILL.md` Step 4 to name the adversarial review by reference (since ship-autonomous opens its PR by invoking `pr-agent`, it inherits Step 4.7 without duplication).
- Added inline report-only review variant to `agents/agent-pr.md` and `agents/agent-ship.md`: cold re-read with the same six-point checklist; `disallowedTools` denies edits; findings in `## Review Notes`; a proven secret stops the flow and is never named in a PR body.
- Bumped git-agent to **4.19.3** in `.claude-plugin/marketplace.json`; added CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill — Step 4.7 review subagent | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill — Step 4.5 upgraded to subagent dispatch | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Reference — checklist, dispatch, opt-out | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Skill — Step 4 names the review | Modified |
| `kit/plugins/git-agent/agents/agent-pr.md` | Agent — inline report-only review | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Agent — inline report-only review | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — 4.19.2 → 4.19.3 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history — v4.19.3 | Modified |

## How it works

The motivating finding (from the 2026-08 usage analysis) was that bots-as-QA was the #1 friction: first implementations shipped with provable defects (no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth lookups) caught only at PR review, costing 2–6 rounds per PR. The author of a diff is the worst-placed reviewer because knowing what an edit was *meant* to do makes a no-op read like a fix.

The design applies two variants of the same six-point checklist. In interactive skills (`pr-agent`, `ship`), a fresh-context subagent gets the diff and the checklist with no memory of the implementation. Confirmed findings become a `fix:` commit pushed before the PR is opened — never an amend, since the base commit may already be known to the remote. Unconfirmed findings are preserved in `## Review Notes` in the PR body so reviewers see what was considered.

In background agents (`agent-pr`, `agent-ship`), the `Agent` tool is not available and `disallowedTools` prevents file edits, so the review is an inline cold re-read using the same checklist. A proven secret stops the flow and is never named in the PR body (since the PR body is public).

`ship-autonomous` was kept to a single pointer to the review rather than duplicating the six-point checklist, because the skill's core was already at the 600-word ceiling of the progressive-disclosure test. Since `ship-autonomous` calls `pr-agent` to open its PR, it inherits Step 4.7 without needing its own copy.

## How to use it

The review runs automatically before `gh pr create` in all five PR-opening flows. To skip it:

```
/git-agent:ship --no-review
```

The six-point checklist covers: no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth/role/key lookups, hardcoded credentials, and scope creep relative to the plan.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8a8a392f` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `3056b570` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `5e1b3c2a` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `56a2ea36` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |
| `eab35454` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
