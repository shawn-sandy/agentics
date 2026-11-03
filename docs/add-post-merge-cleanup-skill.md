# Look Inside the Worktree Before Deleting It

> Merged branches pile up with their worktrees, and the existing tool for clearing them force-removes whatever uncommitted work is sitting inside. This adds a skill that looks first and deletes second, so nothing gets destroyed without someone saying yes.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Added a `post-merge-cleanup` skill to git-agent with a Safety Contract as its first section: never `git worktree remove --force`, never remove a worktree whose `git status --porcelain` is non-empty, never `git branch -D` without a confirmed merged PR, and never `rm` a path outside the worktrees root.
- Implemented dual-signal branch selection in `references/detection.md`: a branch is cleanable when `git branch --merged origin/<default>` lists it OR `gh pr list --head <branch> --state merged` returns a PR. On this repo that finds 380 cleanable branches vs. 84 from ancestry alone (squash-merge replays commits with different SHAs, making 296 branches invisible to ancestry).
- Added graceful degradation: when `gh` is unavailable the skill runs on ancestry alone and states the list is incomplete, never silently narrowing scope.
- Added a repo-wide sweep in `references/sweep.md` behind an explicit flag, with a table report showing qualifying signal, worktree path, and dirty-file count before any action, and per-item approval with batch approval as a deliberate non-default.
- Documented unregistered-directory handling in `references/stale-directories.md` with evidence requirements (no git registration, no admin directory, dangling or missing `.git` file), size/file count display, and a per-directory confirmation with containment check.
- Added `tests/plugins/test-post-merge-cleanup.sh` using a throwaway fixture repo, and bumped git-agent to 4.19.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Skill — activation, safety contract, default single-branch flow | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | Reference — dual-signal selection, degraded mode, read-only inventory | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | Reference — repo-wide sweep report and its gates | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | Reference — unregistered-directory evidence rules and removal rails | Created |
| `tests/plugins/test-post-merge-cleanup.sh` | Test — fixture-repo objective test plus contract greps | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — new test step | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs — skill added to Skills table | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — v4.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — git-agent 4.18.0 to 4.19.0 | Modified |
| `README.md` | Root docs — Plugin Reference Table regenerated | Modified |

## How it works

The skill's design hinge is git's own dirty-tree refusal. An unforced `git worktree remove` already fails on a dirty tree, so checking for uncommitted work first and delegating the central safety property to git means no reimplementation is needed. `git status --porcelain` is run against every candidate worktree; any non-empty output — untracked, staged, or unstaged — blocks removal and reports the files. Gating on any dirty state rather than untracked-only means committed edits are reported clearly instead of hitting git's refusal as a confusing failure.

Branch selection cannot rely on commit ancestry alone because git-agent squash-merges. A squash merge replays a branch's changes as one new commit with a different SHA, so the branch's own commits never become ancestors of `main`. Measured on this repo: 84 ancestry-merged branches vs. 318 with merged PRs in the union of 380 cleanable branches. The dual-signal approach takes either signal; `git branch -D` is permitted only where a merged PR supplies positive evidence, and `git branch -d` is used for ancestry-merged branches (which git's ancestry check accepts).

The progressive-disclosure structure follows the precedent from `skills/ship/references/`: a lean `SKILL.md` contains the safety contract and default single-branch flow, while three reference files carry the sweep logic, detection details, and stale-directory handling. This keeps the core contract where a reader and a model both hit it first.

The test builds a throwaway fixture repo under `mktemp -d` with a `trap` cleanup on exit. It creates an ancestry-merged and a squash-merged branch, each with a worktree, leaving one worktree holding an uncommitted file. The test asserts: the dirty worktree and its file survive the cleanup run untouched; the clean worktree is removed; the squash-merged branch is detected as cleanable; paths outside the worktrees root are rejected; and no forbidden flag (`--force`, bare `-D`) appears inside a fenced code block in the skill sources. The prose prohibition naming those flags must not fail the test.

Self-deletion is mitigated by an explicit cwd check in the default flow: the skill refuses to remove the worktree it is currently running inside.

## How to use it

```bash
/git-agent:post-merge-cleanup <branch>   # single-branch default flow
/git-agent:post-merge-cleanup --sweep    # repo-wide sweep with report
```

The skill inspects each candidate worktree before asking for approval. Dirty worktrees are listed as blocked with their file lists; clean ones proceed on per-item confirmation.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
