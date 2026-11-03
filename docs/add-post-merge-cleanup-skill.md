# Add post-merge cleanup skill

> Adds a `post-merge-cleanup` skill to git-agent that prunes stale worktrees and local branches after a merge, with a strict safety contract: no force-deletes, no rm outside the worktrees root, dual-signal detection, and a self-deletion guard.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` with the full cleanup flow.
- Safety contract: never `--force` delete a branch, never `-D` without a confirmed merged PR, never `rm` outside the worktrees root.
- Dual-signal branch selection: a branch qualifies for deletion only when both ancestry (merged into base) AND a merged PR exist for it.
- Self-deletion guard: the skill refuses to delete the currently checked-out branch or its worktree.
- Bumped git-agent to 4.19.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Cleanup skill core | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | Branch detection rules | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | Sweep procedure | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | Worktree directory pruning | Created |
| `tests/test-post-merge-cleanup.sh` | Cleanup tests | Created |
| `.github/workflows/check-plugin-versions.yml` | Version CI guard | Modified |
| `kit/plugins/git-agent/README.md` | Plugin readme | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

`post-merge-cleanup` is designed to be safe to run automatically after every merge. The dual-signal requirement — ancestry check AND merged PR — means a branch is never deleted unless both the git graph and GitHub agree it's merged. A branch that was rebased or cherry-picked onto main (so ancestry says merged) but whose PR was never merged (PR still open or closed without merge) is left alone.

The self-deletion guard checks `git branch --show-current` and `git worktree list` before any delete. If the branch or worktree being swept is the active one, the skill aborts with a clear message. This prevents the confusing state where a worktree deletes its own directory out from under itself.

The `rm` restriction means the skill only removes directories listed by `git worktree list` — it never calls `rm -rf` on a path it derived from branch name string manipulation, which could be fooled by branch names containing path separators.

## How to use it

```
/git-agent:post-merge-cleanup
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
