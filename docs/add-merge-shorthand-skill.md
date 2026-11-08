# Formalize the merge? shorthand as a git-agent skill + prompt hook

> Adds a `merge` skill to the `git-agent` plugin and a `UserPromptSubmit` hook that deterministically routes the literal prompt `merge?` to that skill — replacing a 50-day-old memory note with a verifiable, machine-portable implementation.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- `kit/plugins/git-agent/skills/merge/SKILL.md` — merge-readiness skill: runs `gh pr view --json state,mergeable,statusCheckRollup`, detects and runs the project's lint script (non-`fix`, non-`watch`), asks for explicit approval before merging with `--match-head-commit <headRefOid>`, never uses `--delete-branch`
- `kit/plugins/git-agent/hooks/merge-shorthand.py` — `UserPromptSubmit` hook with anchored regex `^\s*merge\?\s*$` (case-insensitive); emits `additionalContext` routing to `git-agent:merge`, exits 0 silently on every other prompt
- `kit/plugins/git-agent/hooks.json` — hook wiring via `${CLAUDE_PLUGIN_ROOT}`, mirroring `plan-agent/hooks.json` structure
- `tests/plugins/test-merge-shorthand.sh` — smoke test: hook fires on exact `merge?`, surrounding whitespace, `MERGE?`; stays silent on `merge`, `please merge?`, `merge? now`, mid-sentence occurrences; hooks.json validity; SKILL.md contract assertions
- `git-agent` bumped to `4.4.0` in `.claude-plugin/marketplace.json`
- v4.4.0 CHANGELOG entry, README and CLAUDE.md plugin table updated
- `feedback_merge_behavior` memory note body replaced with a one-line pointer to `git-agent:merge`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill instructions — merge readiness check, lint gate, approval, merge | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | Hook script — UserPromptSubmit anchored regex routing | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — ${CLAUDE_PLUGIN_ROOT} reference | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test — trigger/silence cases, JSON validity, contract assertions | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — git-agent 4.4.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes — v4.4.0 entry | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation — merge skill and shorthand | Modified |

## How it works

The hook's anchored regex `^\s*merge\?\s*$` matches only when the entire prompt is `merge?` (with optional surrounding whitespace, case-insensitive). This prevents the hook from firing on natural language prompts that happen to contain "merge?" mid-sentence — a risk the plan identified explicitly and mitigated by design.

The skill's merge sequence has three safety layers: (1) `gh pr view` checks MERGEABLE state and required check rollup before any local action, (2) the project's lint script runs before merging (detected as the first non-`fix`, non-`watch` `lint*` script), (3) `AskUserQuestion` asks for explicit approval even when everything is green — green checks alone never authorize a merge. The merge itself uses `--match-head-commit <headRefOid>` so it fails rather than landing commits that arrived after verification.

The deliberate omission of `--delete-branch` reflects the plan's principle that branch deletion is a separate decision. The test asserts `! grep -q -- '--delete-branch'` in SKILL.md.

Hooks live in `kit/plugins/git-agent/hooks/` with a `hooks.json` wiring file at the plugin root, following the precedent set by `plan-agent/hooks.json`. The `${CLAUDE_PLUGIN_ROOT}` variable in `hooks.json` resolves to the plugin's installed directory at runtime.

## How to use it

```
merge?                                   # shorthand — routes to git-agent:merge via hook
/git-agent:merge                         # explicit invocation
```

Both paths run the same skill: check PR readiness → run lint if present → ask for explicit approval → merge with `--match-head-commit`. On non-green checks the skill prints the status summary and asks before acting.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
- Proposal: `docs/proposals/formalize-merge-shorthand.md` — activation decision (skill + hook) locked 2026-07-20
