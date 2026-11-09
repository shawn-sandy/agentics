# Add post-merge-cleanup skill to git-agent

> Adds a `post-merge-cleanup` skill to `git-agent` that removes merged branches and their worktrees only after inspecting each worktree for uncommitted work, detects squash-merged branches, and reports unregistered leftover directories.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-post-merge-cleanup-skill](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` — inspects worktrees before deleting, detects squash merges, reports unregistered directories
- Squash-merge detection: `git merge-base --is-ancestor` check since commit-ancestry cannot see squash merges; falls back to matching the merge commit's diff tree
- Unregistered leftover worktree directories are reported rather than silently ignored
- Bumped `git-agent` with CHANGELOG entry and README update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Skill — safe worktree and branch cleanup | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — git-agent bump | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs | Modified |

## How it works

Naive branch cleanup (`git branch -d && git worktree remove`) deletes worktrees without checking for work in progress. This skill looks inside the worktree first: runs `git status --porcelain` in each candidate, checks for untracked files, and pauses with a summary before any deletion when something is found.

Squash merges are invisible to commit ancestry: a squash-merged branch's tip is not reachable from `origin/main` via `git merge-base`. The skill detects these by comparing the squash commit's diff against the branch's diff — matching tree means the work landed, even though the branch commit is not in the ancestry chain.

Unregistered worktree directories (paths on disk that `git worktree list` does not know about) are reported in a table rather than silently ignored. These accumulate when worktrees are removed improperly or when an agent exits without cleanup.

## How to use it

```
/git-agent:post-merge-cleanup            # inspect and clean up merged branches and worktrees
```

The skill activates when the user asks to clean up merged branches, remove worktrees, or run post-merge housekeeping.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill](plans/add-post-merge-cleanup-skill.md)
