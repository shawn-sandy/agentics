# Add merge shorthand skill to git-agent

> Adds a `merge` skill with a `UserPromptSubmit` hook so typing "merge?" in any session triggers a pre-merge check and confirmation rather than requiring the full slash-command invocation.

<!-- generated:start -->

**Status:** Shipped 2026-07-20 **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/skills/merge/SKILL.md` with the full merge workflow.
- Added a `UserPromptSubmit` hook that matches `^\s*merge\?\s*$` (case-insensitive) and invokes the merge skill.
- Merge uses `--match-head-commit` and never `--delete-branch` (branch deletion is a separate explicit action).
- Asks before merging even when all checks are green — no silent auto-merge.
- Bumped git-agent to 4.4.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge skill | Created |
| `kit/plugins/git-agent/hooks/` | UserPromptSubmit hook | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |

## How it works

The `UserPromptSubmit` hook intercepts the user's typed message before it reaches the model. When the message matches the simple regex `^\s*merge\?\s*$` (any capitalization, optional surrounding whitespace), the hook routes to the merge skill instead.

The merge skill itself is designed around a "look before you merge" principle: it checks the current branch state, verifies all pre-conditions, and presents what will be merged before asking for confirmation. Even a clean green-CI branch asks for explicit approval.

The `--match-head-commit` flag ensures the merge includes exactly the commits the user reviewed, guarding against a race where someone else pushed to the target branch between the check and the merge. Branch deletion is explicitly excluded — it is treated as a distinct destructive action that should be a separate decision.

## How to use it

```
merge?
```

Or invoke directly:

```
/git-agent:merge
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
