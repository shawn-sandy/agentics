# Add merge? Shorthand Skill

> Formalizes the `merge?` typing shorthand as a `git-agent` skill with a deterministic `UserPromptSubmit` hook, replacing a private memory note with an installable, verifiable plugin component.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/merge/SKILL.md` — the merge-readiness skill: checks PR state, runs the project's lint script before merging, requires explicit user approval even when everything is green, and merges with `--match-head-commit <headRefOid>` to prevent landing commits that arrived after verification.
- Created `kit/plugins/git-agent/hooks/merge-shorthand.py` — a `UserPromptSubmit` hook that matches the anchored regex `^\s*merge\?\s*$` (case-insensitive) and emits `additionalContext` routing to `git-agent:merge`; exits 0 silently on every other prompt.
- Added the `merge-shorthand.py` entry to `kit/plugins/git-agent/hooks.json` under `UserPromptSubmit`, using `${CLAUDE_PLUGIN_ROOT}` for portability.
- Created `tests/plugins/test-merge-shorthand.sh` asserting exact-match triggering, whitespace tolerance, case-insensitivity, and silence on all near-miss inputs.
- Bumped `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry and README update.
- Retired the `feedback_merge_behavior` memory note to a one-line pointer at `git-agent:merge`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill contract — PR readiness check, lint gate, approval prompt, merge | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | `UserPromptSubmit` hook — anchored regex router | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — `UserPromptSubmit` entry for `merge-shorthand.py` | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test — hook trigger, near-miss silence, SKILL.md contract | Created |
| `.claude-plugin/marketplace.json` | `git-agent` bumped to `4.4.0` | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | `v4.4.0` entry | Modified |
| `kit/plugins/git-agent/README.md` | `merge` skill and `merge?` shorthand documentation | Modified |

## How it works

Before this change, typing `merge?` relied on a private memory note (`feedback-merge-behavior`) — model-discretion recall that was invisible to other machines and unverifiable. The behavior existed only where that memory note had been established.

The formalization has two parts. The skill (`SKILL.md`) owns all the logic: it is explicitly invocable as `/git-agent:merge` independently of the shorthand. The hook (`merge-shorthand.py`) owns the ergonomic trigger.

The hook reads the prompt JSON from stdin and checks the `prompt` field against `^\s*merge\?\s*$` (case-insensitive, `re.IGNORECASE`). On a match it emits an `additionalContext` JSON object instructing Claude to run the `git-agent:merge` skill. On any non-match it writes nothing and exits 0 — silence is the correct output for the vast majority of prompts. The anchored regex ensures that phrases like "please merge?", "merge? now", or "how do merges work" pass through untouched.

The skill's readiness gate runs `gh pr view --json state,mergeable,statusCheckRollup,reviewDecision,headRefOid`. If the PR is `MERGEABLE` and all required checks pass, the skill detects the project's lint script (matching non-`fix`, non-`watch` `lint*` entries in `package.json`) and runs it before asking for approval. Lint failure stops the run — the skill never auto-`--fix`es, because fixed files would change the PR head without being part of the reviewed commit. When no lint script is found, the skill skips with a one-line note.

Even with everything green, the skill asks for explicit approval via `AskUserQuestion` before merging. The merge command is `gh pr merge --squash --match-head-commit <headRefOid>` — the `--match-head-commit` flag pins the merge to the commit verified during the readiness check, so commits arriving between verification and merge cause the command to fail rather than land silently. The skill never passes `--delete-branch`; branch deletion is a separate yes.

The `hooks.json` file is the first one in the `git-agent` plugin. It follows the structure established by `kit/plugins/plan-agent/hooks.json`, using `${CLAUDE_PLUGIN_ROOT}` in the command path and a 5-second timeout.

## How to use it

Type `merge?` as a standalone prompt (case-insensitive, surrounding whitespace accepted) to trigger the hook, or invoke the skill directly:

```text
merge?
MERGE?
/git-agent:merge
```

The skill runs the PR readiness check, displays the result, asks for approval, and merges with a pinned head commit. If checks are failing or the PR is not mergeable, it reports the status and asks rather than acting.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
