# Look inside the worktree before deleting it

> Adds a `post-merge-cleanup` skill to git-agent that inspects each worktree for uncommitted work before removing it, detects squash-merged branches that commit-ancestry cannot see, and reports unregistered leftover directories instead of silently ignoring them.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` with a four-absolute Safety Contract: never `--force`, never remove a dirty worktree, never `branch -D` without a confirmed merged PR, never `rm` outside the worktrees root.
- Created `references/detection.md` defining dual-signal selection: a branch is cleanable when either `git branch --merged origin/<default>` lists it or `gh pr list --head <branch> --state merged` returns a PR; degrades gracefully to ancestry-only when `gh` is absent or unauthenticated.
- Created `references/sweep.md` for the repo-wide `--all` sweep: emits a table of branch, qualifying signal, worktree path, and dirty-file count before any action; lists dirty worktrees as blocked; requires per-item approval, with batch approval as a deliberate separate answer.
- Created `references/stale-directories.md` for the `--dirs` pass: unregistered directories require evidence of non-registration before `rm`, plus per-directory confirmation and a containment check against the worktrees root.
- Added `tests/plugins/test-post-merge-cleanup.sh` with a fixture repo proving a dirty worktree survives, and negative tests for all forbidden-flag patterns.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- Updated `kit/plugins/git-agent/README.md` Skills table and root `README.md` Plugin Reference Table.
- Bumped git-agent from 4.18.0 to 4.19.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Activation, safety contract, single-branch flow | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | Dual-signal selection, degraded mode, read-only inventory | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | Repo-wide sweep report and gates | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | Unregistered-directory evidence rules and removal rails | Created |
| `tests/plugins/test-post-merge-cleanup.sh` | Fixture-repo objective test plus contract greps | Created |
| `.github/workflows/check-plugin-versions.yml` | New test step added | Modified |
| `kit/plugins/git-agent/README.md` | Skill added to Skills table | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.18.0 → 4.19.0 | Modified |
| `README.md` | Plugin Reference Table regenerated | Modified |

## How it works

The design hinge is git's own unforced `git worktree remove` behavior: without `--force`, git refuses to remove a worktree whose `git status --porcelain` is non-empty. The skill delegates its central safety property to git by checking for uncommitted work first — and by never passing `--force`, it ensures git's refusal is always reachable. The previous external command `commit-commands:clean_gone` ran `git worktree remove --force` plus `git branch -D` unattended, which would have destroyed 16 untracked files across 9 of 19 worktrees when measured on this repo on 2026-08-15.

Dual-signal branch selection exists because ancestry alone is insufficient for squash-merge workflows. `git branch --merged origin/main` can only see branches whose commits became ancestors of the default branch. A squash merge replays a branch's changes as one new commit with a new SHA, so squash-merged branches never appear in the ancestry list. In this repo, 84 of 380 cleanable branches were ancestry-merged; the other 296 required the PR signal from `gh pr list --head <branch> --state merged`. Selection takes either signal; the union is what is actually safe to clean. When `gh` is absent or unauthenticated, the skill degrades to the ancestry test alone and states explicitly that the list is incomplete so users are not misled by a silently narrow result.

The `--force` (`-f`) flag and bare `branch -D` are prohibited in every fenced code block in the skill sources. The safety contract in `SKILL.md` is permitted to name these flags in prose (a rule that forbids a flag must be able to say its name), but the test in `test-post-merge-cleanup.sh` differentiates: it greps only fenced code blocks for the forbidden patterns, so prose prohibitions naming the flag do not trip the check. `-D` is reachable only for a squash-merged branch whose merged PR has been positively confirmed; ancestry-merged branches always use `-d` and accept git's refusal.

Self-deletion is blocked by an explicit cwd check in Step 3: if the current working directory is inside the target worktree, the skill stops and tells the user to invoke it from outside. The recommended pattern is to pass the branch name as an explicit target from the main checkout after stepping out. The `--all` sweep and `--dirs` pass are separated from the default single-branch flow via progressive disclosure into `references/sweep.md` and `references/stale-directories.md`, keeping `SKILL.md` focused on the common case.

The fixture test in `tests/plugins/test-post-merge-cleanup.sh` builds a throwaway repo under `mktemp -d` with a `trap` cleanup on exit. It creates an ancestry-merged branch and a squash-merged branch each with a worktree, leaves one worktree holding an uncommitted file, and asserts the documented flow leaves that worktree and file intact while removing the clean one. It also asserts paths outside the worktrees root are rejected and that no forbidden flag appears in any fenced code block in the skill sources.

## How to use it

```bash
# Clean the current branch and its worktree (inspect first, delete on explicit yes)
/git-agent:post-merge-cleanup

# Clean a named branch from outside its worktree
/git-agent:post-merge-cleanup my-feature-branch

# Repo-wide sweep: inventory report, then per-item approval
/git-agent:post-merge-cleanup --all

# Unregistered-directory pass only
/git-agent:post-merge-cleanup --dirs
```

The skill never touches `--force` and never deletes a branch with `-D` unless a merged PR was the qualifying signal. Every destructive action requires an explicit yes. A dirty worktree is reported with its file list and left untouched.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
