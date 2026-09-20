# Look inside the worktree before deleting it

> Merged branches pile up with their worktrees, and the existing tool for clearing them force-removes whatever uncommitted work is sitting inside. This adds a...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Create `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` with frontmatter (`name`, `description`, `allowed-t...
- Write `references/detection.md` defining dual-signal selection: a branch is cleanable when `git branch --merged origi...
- Add the default single-branch flow to `SKILL.md`: confirm the branch is cleanable by either signal, refuse when the c...
- Write `references/sweep.md` defining the repo-wide sweep behind an explicit flag: emit one table of branch, qualifyin...
- Write `references/stale-directories.md`: a directory is unregistered only when it is absent from `git worktree list`,...
- Add `tests/plugins/test-post-merge-cleanup.sh` following the shape of `tests/plugins/test-scope-guard.sh`: build a th...
- Wire the test into `.github/workflows/check-plugin-versions.yml` as its own step matching the existing `run: bash tes...
- Regenerate the root `README.md` Plugin Reference Table with `node scripts/build-readme-table.mjs`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | activation, the safety contract, and the default single-b... | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | dual-signal selection, the degraded mode, and the read-on... | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | the repo-wide sweep report and its gates | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | unregistered-directory evidence rules and removal rails | Created |
| `tests/plugins/test-post-merge-cleanup.sh` | fixture-repo objective test plus contract greps | Created |
| `.github/workflows/check-plugin-versions.yml` | run the new test in CI | Modified |
| `kit/plugins/git-agent/README.md` | add the skill to the Skills table | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | bump git-agent 4.18.0 to 4.19.0 | Modified |
| `README.md` | Plugin Reference Table, regenerated via the canonical gen... | Modified |

## How it works

Add a `post-merge-cleanup` skill to git-agent that removes merged branches and their worktrees only after inspecting each worktree for uncommitted work, detects squash-merged branches that commit-ancestry cannot see, and reports unregistered leftover directories instead of ignoring them.

`kit/plugins/git-agent/skills/merge/SKILL.md:183` deliberately declines branch deletion — "Never pass `--delete-branch`. Branch deletion is a separate destructive action that needs its own explicit yes." Nothing has ever filled that seam, so the job falls to `commit-commands:clean_gone`, an external command

The implementation proceeded through these steps: Create `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` with frontmatter (`name`, `description`, `allowed-t...; Write `references/detection.md` defining dual-signal selection: a branch is cleanable when `git branch --merged origi...; Add the default single-branch flow to `SKILL.md`: confirm the branch is cleanable by either signal, refuse when the c...; Write `references/sweep.md` defining the repo-wide sweep behind an explicit flag: emit one table of branch, qualifyin...; Write `references/stale-directories.md`: a directory is unregistered only when it is absent from `git worktree list`,....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/564
