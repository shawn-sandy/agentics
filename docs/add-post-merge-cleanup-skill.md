# Add post-merge cleanup skill to git-agent

> Adds `git-agent:post-merge-cleanup`, a safe branch and worktree pruner that removes merged branches and stale worktree directories only after verifying they carry no uncommitted work.

<!-- generated:start -->

**Status:** Shipped 2026-08-15  **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` — the main skill that identifies merged branches and orphaned worktrees, inspects each for uncommitted work, and removes only what is safe to remove.
- Added `references/detection.md` — documents the dual-signal detection strategy: ancestry-merge check combined with `gh pr list --state merged` for squash-merged branches.
- Added `references/sweep.md` — the removal contract: never `--force`, never remove a dirty worktree, never `-D` without a confirmed merged PR, never `rm` outside the worktrees root.
- Added `references/stale-directories.md` — logic for handling directories under the worktrees root that are not registered with `git worktree list`.
- Added `tests/plugins/test-post-merge-cleanup.sh` with structural smoke checks.
- Updated `.github/workflows/check-plugin-versions.yml`, `git-agent/README.md`, and `CHANGELOG.md`.
- Bumped `git-agent` to `4.19.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Skill instructions | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | Detection strategy | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | Removal safety contract | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | Stale directory handling | Created |
| `tests/plugins/test-post-merge-cleanup.sh` | Smoke test | Created |
| `.github/workflows/check-plugin-versions.yml` | CI configuration | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

The skill uses a dual-signal approach to identify merged branches. The primary signal is ancestry: `git branch --merged` finds branches fully contained in the current HEAD. The secondary signal is `gh pr list --state merged` which catches squash-merged branches where the branch tip is not an ancestor of HEAD. When `gh` is unavailable the skill degrades gracefully to the ancestry-only check and notes the degradation.

For each candidate branch the skill checks the associated worktree (if any) for uncommitted changes before removing anything. The safety contract is enforced by reference: `git branch -D` is never used without a merged-PR signal, `rm -rf` on a worktree directory only runs after `git worktree remove` succeeds, and dirty worktrees are always skipped and reported rather than forced.

Stale directories — paths under the worktrees root that appear in the filesystem but not in `git worktree list` — are reported but never auto-removed, since their provenance is unknown.

## How to use it

```
/git-agent:post-merge-cleanup
```

The skill lists candidates and asks for confirmation before removing anything.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
