# Formalize the merge? shorthand as a git-agent skill + prompt hook

> Adds a `merge` skill to `git-agent` and a `UserPromptSubmit` hook that deterministically routes the literal prompt `merge?` to that skill — replacing a 50-day-old memory note with a verifiable, cross-machine contract.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-merge-shorthand-skill](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/merge/SKILL.md` — merge-readiness skill: PR state check → lint gate → explicit approval → squash merge with `--match-head-commit`
- Created `kit/plugins/git-agent/hooks/merge-shorthand.py` — `UserPromptSubmit` hook with anchored regex `^\s*merge\?\s*$` (case-insensitive)
- Created `kit/plugins/git-agent/hooks.json` — hook wiring via `${CLAUDE_PLUGIN_ROOT}`, mirrors `plan-agent/hooks.json` structure
- Created `tests/plugins/test-merge-shorthand.sh` — smoke test covering all trigger cases and six near-miss negatives
- Bumped `git-agent` to `4.4.0` with CHANGELOG entry, README docs, and CLAUDE.md plugin table row updated
- Retired `feedback_merge_behavior` memory note — replaced body with pointer to `git-agent:merge`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill — merge readiness and execution | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | Hook script — `UserPromptSubmit` router | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — UserPromptSubmit entry | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test — trigger cases and near-miss negatives | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — git-agent 4.4.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history — v4.4.0 entry | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs — merge skill and shorthand | Modified |

## How it works

Typing `merge?` works through a Python `UserPromptSubmit` hook that fires before Claude sees the prompt. The hook reads the incoming prompt from stdin as JSON, tests it against the anchored regex `^\s*merge\?\s*$` (case-insensitive to handle `MERGE?`), and emits `additionalContext` instructing Claude to run `git-agent:merge` when it matches. On every other prompt it exits 0 silently.

The regex is anchored on both ends to prevent over-broad matching. Near-miss cases that stay silent: `merge` (no `?`), `please merge?`, `merge? now`, `can you merge this?`, and prose containing "merge?" mid-sentence. The test suite asserts all of these explicitly.

The `merge` skill itself runs a readiness check sequence: query `gh pr view --json state,mergeable,statusCheckRollup`; detect the project's first non-`fix`, non-`watch` lint script and run it before merging (lint failure stops and asks, never auto-fixes); on lint green, show the check summary and ask for explicit merge approval via `AskUserQuestion`; merge with `gh pr merge --squash --match-head-commit <headRefOid>`. The skill never passes `--delete-branch` — branch deletion is a separate decision.

## How to use it

```
merge?                                    # 6-character shorthand → routes to /git-agent:merge
/git-agent:merge                          # explicit invocation
```

The skill also activates when the user asks about PR readiness or merge eligibility.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill](plans/add-merge-shorthand-skill.md)
- Proposal: `docs/proposals/formalize-merge-shorthand.md`
