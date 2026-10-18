# Formalize the merge? shorthand as a git-agent skill + prompt hook

> Promotes the `merge?` shorthand from a private memory note to a `git-agent` skill with a deterministic `UserPromptSubmit` hook, making it reliable on any machine with the plugin installed.

<!-- generated:start -->

**Status:** Shipped 2026-07-20  **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/skills/merge/SKILL.md` — checks PR readiness, runs the project's lint script before merging, asks for explicit merge approval even when everything is green, and merges with `--match-head-commit <headRefOid>` to prevent landing commits that arrived after verification.
- Added `kit/plugins/git-agent/hooks/merge-shorthand.py` — `UserPromptSubmit` script that matches `^\s*merge\?\s*$` (case-insensitive) and emits `additionalContext` routing to the merge skill; exits silently on every other prompt.
- Added `kit/plugins/git-agent/hooks.json` — wires the hook script, mirroring the `plan-agent/hooks.json` precedent.
- Added `tests/plugins/test-merge-shorthand.sh` with positive cases (`merge?`, surrounding whitespace, `MERGE?`) and negative cases (near-misses that must stay silent).
- Bumped `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` with CHANGELOG entry and README update.
- Retired the `feedback_merge_behavior` memory note body to a one-line pointer at `git-agent:merge`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill instructions | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | UserPromptSubmit hook | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |

## How it works

The hook uses an anchored regex (`^\s*merge\?\s*$`) so prose containing the word "merge" never triggers it — only the literal 6-character prompt does. The skill checks `gh pr view --json state,mergeable,statusCheckRollup`, runs the project's lint script (the first non-`fix`, non-`watch` `lint*` script detected), skips lint with a note when none exists, and refuses to merge on lint failure without auto-fixing.

Explicit merge approval is required via `AskUserQuestion` even when checks are green — green checks alone never authorize a merge. The merge is pinned to the verified commit with `--match-head-commit <headRefOid>` so commits arriving after verification cannot be silently included. Branch deletion is deliberately excluded from the skill; that requires a separate decision.

## How to use it

Type `merge?` as the entire prompt to trigger the hook, or invoke directly as `/git-agent:merge`.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
