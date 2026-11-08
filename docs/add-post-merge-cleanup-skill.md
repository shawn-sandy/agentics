# Look inside the worktree before deleting it

> Adds a `post-merge-cleanup` skill to git-agent that removes merged branches and their worktrees only after inspecting each for uncommitted work, detecting squash-merged branches, and reporting unregistered leftover directories.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` with a Safety Contract section stating four absolutes: never `git worktree remove --force`, never remove a worktree whose `git status --porcelain` is non-empty, never `git branch -D` without a confirmed merged PR, and never `rm` a path outside the worktrees root.
- Created `references/detection.md` defining dual-signal selection: a branch is cleanable when `git branch --merged origin/<default>` lists it **or** `gh pr list --head <branch> --state merged` returns a PR; degrades to ancestry-only when `gh` is absent, stating the list is known-incomplete (measured at 84 ancestry-merged vs 318 merged-PR-only in this repo).
- Created `references/sweep.md` with the repo-wide sweep report format: one table of branch/signal/worktree/dirty-file-count before any action, dirty worktrees as blocked rows with file lists, per-item approval required (batch approval never the default).
- Created `references/stale-directories.md` with evidence rules for unregistered directories (absent from `git worktree list`, no admin directory under `.git/worktrees/<name>`, dangling or missing `.git` file), printing size/file-count/recently-modified before each per-directory confirmation.
- Added `tests/plugins/test-post-merge-cleanup.sh` using a throwaway fixture repo; asserts the dirty-worktree gate, clean-worktree removal, squash-merged detection, path containment, portable `find` commands, and the forbidden-flag contract.
- Wired the test into `.github/workflows/check-plugin-versions.yml`; bumped git-agent to 4.19.0; updated `kit/plugins/git-agent/README.md` and CHANGELOG; regenerated root `README.md` with `scripts/build-readme-table.mjs`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Skill instructions — safety contract and default single-branch flow | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | Dual-signal selection and degraded mode | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | Repo-wide sweep report and gates | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | Unregistered-directory evidence rules and removal rails | Created |
| `tests/plugins/test-post-merge-cleanup.sh` | Fixture-repo objective test and contract greps | Created |
| `.github/workflows/check-plugin-versions.yml` | Added test step | Modified |
| `kit/plugins/git-agent/README.md` | Skills table | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.19.0 | Modified |
| `README.md` | Plugin Reference Table (regenerated) | Modified |

## How it works

The existing external `commit-commands:clean_gone` command runs `git worktree remove --force` plus `git branch -D` in one unattended loop with no user gate, which measured against this repo on 2026-08-15 would destroy 16 untracked files across 9 of 19 worktrees. The design hinge is git's own `git worktree remove` default refusal on a dirty tree: by checking for uncommitted work first and delegating the safety property to git rather than reimplementing it, the skill avoids `--force` entirely.

Branch selection cannot rely on commit ancestry because git-agent squash-merges. A squash merge replays a branch's changes as one new commit with a different SHA, so the branch's own commits never become ancestors of `main`. Measured at 395 local branches: 84 are ancestry-merged, 318 have a merged PR, and 296 of those are invisible to the ancestry test — selecting on ancestry alone finds 22% of the real backlog. `detection.md` therefore takes either signal, and `-D` is permitted only where a confirmed merged PR supplies positive evidence.

The default single-branch flow in `SKILL.md` runs in this order: confirm the branch is cleanable by either signal, refuse when the cwd is inside the target worktree (self-deletion guard), inspect with `git status --porcelain` and stop with the file list when output is non-empty, then on approval run `git worktree remove <path>` followed by `git branch -d` or `-D` depending on the qualifying signal.

The repo-wide sweep in `references/sweep.md` is behind an explicit flag. It emits the full report table first, marks dirty worktrees as blocked alongside their file lists, and requires per-item approval; batch approval is a separate deliberate answer, never the default.

Unregistered directories in `references/stale-directories.md` require a stricter gate: three conditions (absent from `git worktree list`, no admin directory, dangling `.git`) must all hold before the directory is even offered for removal, and removal requires printing size, file count, and recently modified files plus a per-directory confirmation and a containment check against the worktrees root.

## How to use it

Activation trigger (description field): removes merged branches and their worktrees after inspecting for uncommitted work. Use when the user asks to clean up merged branches.

```
/git-agent:post-merge-cleanup                           # single cleanable branch (auto-detected)
/git-agent:post-merge-cleanup my-feature-branch        # explicit branch
/git-agent:post-merge-cleanup --sweep                  # repo-wide sweep with report
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `86412c3` | 2026-10-26 | fix(git-agent): finish post-merge-cleanup inside an app session's worktree (4.23.1) (#657) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
- Changelog: `kit/plugins/git-agent/CHANGELOG.md` — v4.19.0 entry
- Related: `docs/prompts/proposal-add-post-merge-cleanup.md`
