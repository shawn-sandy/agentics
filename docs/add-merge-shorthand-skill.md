# Add merge skill and merge? prompt hook to git-agent

> `git-agent:merge` is a PR-readiness skill with a deterministic `UserPromptSubmit` hook that routes the literal prompt `merge?` to it — replacing a 50-day-old private memory note with a versioned, verifiable plugin.

<!-- generated:start -->

**Status:** Shipped 2026-07-20 **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/skills/merge/SKILL.md`: runs `gh pr view --json state,mergeable,statusCheckRollup`, detects and runs the project's lint script (non-`fix`, non-`watch`) before merging, asks for explicit merge approval even when everything is green, and merges with `--match-head-commit <headRefOid>`. Never uses `--delete-branch`.
- Added `kit/plugins/git-agent/hooks/merge-shorthand.py` — a `UserPromptSubmit` script with an anchored regex (`^\s*merge\?\s*$`, case-insensitive) that emits `additionalContext` routing to the merge skill, silently exiting 0 on all other prompts.
- Added `kit/plugins/git-agent/hooks.json` wiring the hook via `${CLAUDE_PLUGIN_ROOT}`, mirroring the `plan-agent` hooks precedent.
- Added `tests/plugins/test-merge-shorthand.sh` asserting the trigger boundaries and skill contract (MERGEABLE gate, lint gate, no `--delete-branch`, ask-when-not-ready).
- Bumped `git-agent` from 4.3.0 to `4.4.0` in `.claude-plugin/marketplace.json` and added the CHANGELOG, README, and CLAUDE.md plugin-table entries.
- Retired the `feedback_merge_behavior` memory note, replacing its body with a pointer to `git-agent:merge`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge-readiness skill | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | UserPromptSubmit hook script | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `CLAUDE.md` | Plugin table | Modified |

## How it works

The `UserPromptSubmit` hook runs on every prompt. It reads the hook JSON from stdin and exits silently for all prompts except the anchored match `^\s*merge\?\s*$` (case-insensitive, surrounding whitespace allowed). On a match, it emits `additionalContext` instructing Claude to run the `git-agent:merge` skill.

The merge skill checks PR readiness before acting: it queries `gh pr view` for state, mergeability, and status checks. If the PR is MERGEABLE with passing required checks, it looks for a lint script (non-`fix`, non-`watch`) and runs it. Lint failure stops the skill and surfaces the failures — it never auto-fixes. When lint is green, the skill shows the check summary, review decision, and unresolved-thread count, then asks for explicit merge approval via `AskUserQuestion`. On approval it merges with `--match-head-commit <headRefOid>` to guard against commits that arrive between verification and merge. It never deletes the branch.

## How to use it

```
merge?
```

Typing `merge?` as a bare prompt triggers the hook and runs the readiness check. The skill is also directly invocable as `/git-agent:merge`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `4a8d6bb1` | 2026-07-20 | feat(git-agent): add merge skill and merge? prompt hook (#441) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
