# Look inside the worktree before deleting it

> Merged branches pile up with their worktrees, and the existing tool for clearing them force-removes whatever uncommitted work is sitting inside. This adds a `post-merge-cleanup` skill that looks first and deletes second, so nothing gets destroyed without someone saying yes.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Added `post-merge-cleanup` skill to git-agent (4.18.0 → 4.19.0) with a Safety Contract as the first section: never `git worktree remove --force`, never remove a worktree whose `git status --porcelain` is non-empty, never `git branch -D` without a confirmed merged PR, and never `rm` a path outside the worktrees root.
- Added `references/detection.md`: dual-signal selection using both `git branch --merged` and `gh pr list --state merged`; selects 380 of 380 real candidates vs. 84 with ancestry alone; degrades gracefully when `gh` is unavailable.
- Added `references/sweep.md`: repo-wide sweep behind an explicit flag; emits a table of branch, qualifying signal, worktree path, and dirty-file count before any action; blocked worktrees listed with their file lists; batch approval is never the default.
- Added `references/stale-directories.md`: unregistered-directory evidence rules; prints size, file count, and recently modified files before any removal; containment check rejects paths outside the worktrees root.
- Added `tests/plugins/test-post-merge-cleanup.sh`: fixture-repo test asserting a worktree holding an uncommitted file survives cleanup untouched; dual-signal selection; dirty-state gate for all three porcelain states; forbidden-flag contract (no `--force` or bare `-D` in fenced code blocks).
- Wired the test into `.github/workflows/check-plugin-versions.yml`; updated `README.md` Skills table and `CHANGELOG.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Skill with Safety Contract | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | Dual-signal selection | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | Repo-wide sweep | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | Unregistered-directory rules | Created |
| `tests/plugins/test-post-merge-cleanup.sh` | Objective test | Created |
| `.github/workflows/check-plugin-versions.yml` | Test wiring | Modified |
| `kit/plugins/git-agent/README.md` | Skills table | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.18.0 → 4.19.0 | Modified |
| `README.md` | Plugin Reference Table regenerated | Modified |

## How it works

A branch is cleanable when either `git branch --merged origin/<default>` lists it **or** `gh pr list --head <branch> --state merged` returns a PR. The dual-signal approach catches squash-merged branches that commit-ancestry cannot see — in this repo 296 of 380 cleanable branches are invisible to the ancestry test alone.

Before removing any worktree, the skill runs `git status --porcelain` and stops with the full file list if output is non-empty for any reason (untracked, staged, or unstaged). Only after user approval does it run `git worktree remove` from outside the worktree, then `git branch -d`, escalating to `-D` only when a merged PR supplied the qualifying signal. The skill also refuses to remove the worktree it is currently running inside.

## How to use it

```
/git-agent:post-merge-cleanup [<branch>]
```

For a single branch: confirms cleanability, inspects the worktree, removes on approval. For the repo-wide sweep, pass `--sweep` (or the documented flag) to see the full inventory table before any action.

Pass `--check` to see the inventory without removing anything, and `.claude/no-scope-guard` to opt out of scope-guard enforcement in the same session.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e1e8840a` | 2026-08-15 | feat(git-agent): post-merge-cleanup skill — look inside the worktree before deleting it (4.19.0) |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
