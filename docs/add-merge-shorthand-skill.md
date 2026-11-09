# Formalize the merge? shorthand as a git-agent skill + prompt hook

> Adds a `merge` skill to `git-agent` and a `UserPromptSubmit` hook that deterministically routes the literal prompt `merge?` to that skill, replacing an unreliable 50-day-old memory note.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/merge/SKILL.md` — checks PR readiness via `gh pr checks` (all required checks must be `SUCCESS` or `SKIPPED`), reads `mergeable` and `mergeStateStatus` from `gh pr view`, requires explicit `AskUserQuestion` approval even on green checks, and merges with `gh pr merge --squash --match-head-commit <headRefOid>` to pin to the verified commit. Never uses `--delete-branch`.
- Created `kit/plugins/git-agent/hooks/merge-shorthand.py` — reads hook JSON from stdin, matches `^\s*merge\?\s*$` (case-insensitive), and emits `additionalContext` routing to `git-agent:merge`; exits 0 silently on every other prompt.
- Created `kit/plugins/git-agent/hooks.json` — wires the `UserPromptSubmit` hook via `${CLAUDE_PLUGIN_ROOT}`, following the `plan-agent/hooks.json` precedent.
- Created `tests/plugins/test-merge-shorthand.sh` — asserts the hook fires on `merge?`, ` merge? ` (whitespace), and `MERGE?`; stays silent on `merge`, `please merge?`, `merge? now`, and prose containing "merge?" mid-sentence; validates hooks.json JSON and SKILL.md contract.
- Bumped `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json`; added a `v4.4.0` CHANGELOG entry; documented in `README.md` and root `CLAUDE.md`.
- Retired the `feedback_merge_behavior` memory note to a pointer at `git-agent:merge`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill — PR readiness check and merge flow | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | Hook script — anchored `merge?` regex routing | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — `UserPromptSubmit` entry | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test — hook boundaries and skill contract | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — git-agent 4.4.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — v4.4.0 entry | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs | Modified |

## How it works

The previous behavior depended on the model recalling a private memory note (`feedback-merge-behavior`) — model-discretion recall that is invisible to other machines and unverifiable. This plan formalizes the behavior into two deterministic layers.

The hook (`merge-shorthand.py`) runs on every prompt submission before the model sees the message. Its anchored regex `^\s*merge\?\s*$` (case-insensitive) fires only on the exact shorthand with optional surrounding whitespace — not on prose containing "merge?" mid-sentence, not on "please merge?", not on "merge? now". When it matches, it injects `additionalContext` routing the session to run `git-agent:merge`. This routing is deterministic and does not depend on model recall.

The skill itself is the single reviewable home for the merge logic. It reads `mergeable` and `mergeStateStatus` from `gh pr view` and runs `gh pr checks --required` to confirm all required checks are `SUCCESS` or `SKIPPED`. It requires an explicit yes before merging. Merge is pinned to `--match-head-commit <headRefOid>` so commits that arrive after verification don't land silently. `--delete-branch` is explicitly absent — branch deletion is a separate concern and a separate yes.

The over-broad-hook risk was mitigated by the anchored regex and asserted by the smoke test's negative cases, which confirm that typing "merge" without a question mark, prepending words, or appending words all produce no hook output.

## How to use it

```
merge?                        # type exactly this at the prompt — hook routes to the skill
/git-agent:merge              # explicit invocation
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8a8a392f` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `da54ec10` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
- Related: `docs/proposals/formalize-merge-shorthand.md` — decision-complete proposal
- Related: `kit/plugins/plan-agent/hooks.json` — hook wiring precedent
