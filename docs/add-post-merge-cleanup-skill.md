# Look inside the worktree before deleting it

> Adds `git-agent:post-merge-cleanup`, which removes merged branches and worktrees only after inspecting each for uncommitted work, detects squash-merged branches, and reports unregistered leftover directories.

<!-- generated:start -->

**Status:** Shipped 2026-10-31  **Plan:** [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` with a Safety Contract section stating four absolutes: never `git worktree remove --force`, never remove a dirty worktree, never `git branch -D` without a confirmed merged PR, never `rm` outside the worktrees root.
- Created `references/detection.md` defining dual-signal selection: a branch is cleanable when `git branch --merged origin/<default>` lists it **or** `gh pr list --head <branch> --state merged` returns a PR. Degrades to ancestry-only when `gh` is absent, and reports the list as known-incomplete.
- Added the default single-branch flow in SKILL.md: confirm cleanability, refuse when the cwd is inside the target worktree, inspect with `git status --porcelain`, stop on any non-empty output, then run `git worktree remove` + `git branch -d` (escalating to `-D` only with merged PR evidence).
- Created `references/sweep.md` for the repo-wide sweep: emits one table of branch/signal/worktree/dirty-count before any action, lists dirty worktrees as blocked, requires per-item or explicit batch approval.
- Created `references/stale-directories.md` for unregistered directories: requires size/file-count/recent-files printout, per-directory confirmation, containment check, and refusal of any path not produced by detection.
- Added `tests/plugins/test-post-merge-cleanup.sh` with a throwaway fixture repo, asserting the dirty-worktree gate, dual-signal detection, containment rules, portable commands, and forbidden-flag contract.
- Wired the test into `.github/workflows/check-plugin-versions.yml`; updated git-agent README and CHANGELOG.
- Bumped git-agent to **4.19.0** in `.claude-plugin/marketplace.json`; regenerated root README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` | Skill — activation, safety contract, single-branch flow | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` | Reference — dual-signal selection, degraded mode | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` | Reference — repo-wide sweep report and gates | Created |
| `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` | Reference — unregistered-directory evidence rules | Created |
| `tests/plugins/test-post-merge-cleanup.sh` | Smoke test — fixture repo, dirty-state gate, signal detection | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — new test step | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history — v4.19.0 | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — 4.18.0 → 4.19.0 | Modified |
| `README.md` | Root Plugin Reference Table (regenerated) | Modified |

## How it works

The skill's design hinge is that `git worktree remove` (without `--force`) already fails on a dirty tree. By inspecting first and delegating the refusal to git, the skill avoids reimplementing the dirty-state check — it just ensures the check runs before any delete, not after.

Dual-signal selection was the key technical finding of the plan: in this repo, `git branch --merged` finds 84 of the 380 cleanable branches (ancestry-merged only), while `gh pr list --state merged` finds all 318 squash-merged ones — 296 of which are invisible to the ancestry test. Selecting on ancestry alone would miss 78% of the real backlog. The union of both signals covers 380 branches; the degraded path (no `gh`) covers 84 and says so.

`-D` is permitted only when a merged PR was the qualifying signal. Ancestry-merged branches use `git branch -d`, which performs the same ancestry check git already knows. This keeps the most destructive flag behind a higher evidence bar.

The sweep report (behind an explicit flag) emits the full table before any action, lists dirty worktrees as blocked with their file lists, and requires per-item approval. Batch approval is a separate deliberate answer rather than the default, so the blast radius must be read before the question is asked.

Unregistered directories (under the worktrees root, absent from `git worktree list`, with a dangling or missing `.git` file) get a dedicated reference because `git status` cannot inspect them. The skill prints their size, file count, and most recently modified files before asking for per-directory confirmation.

## How to use it

**Skill:** activates on "clean up merged branches" or via `/git-agent:post-merge-cleanup`.

```
# Single branch
/git-agent:post-merge-cleanup feature/my-branch

# Repo-wide sweep (requires explicit flag)
/git-agent:post-merge-cleanup --sweep
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8a8a392f` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `86412c3a` | 2026-10-26 | fix(git-agent): finish post-merge-cleanup inside an app session's worktree (4.23.1) (#657) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-post-merge-cleanup-skill.md](plans/add-post-merge-cleanup-skill.md)
- Related: `docs/prompts/proposal-add-post-merge-cleanup.md` — the grounded proposal this plan executes
