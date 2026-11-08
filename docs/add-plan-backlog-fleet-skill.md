# A plan-backlog fleet skill for plan-agent

> Adds `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each running `build` then `ship-autonomous` to a green PR.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` as a dispatch-only skill that delegates entirely to `plan-agent:build` and `git-agent:ship-autonomous` via harness worktree isolation (`isolation: "worktree"`, `run_in_background: true`); no `git worktree add` or `gh pr merge` anywhere in the skill.
- Added a Guardrails section with five blast-radius protections: mandatory confirmation naming the PR count, `--max` defaulting to 3, `status: completed` plans excluded, dirty-tree stop, and headless-run cancellation.
- Added a `multiSelect` `AskUserQuestion` picker over the newest four `todo` candidates (stating the suppressed count), so the confirmation is the picker itself, not a second question.
- Resolved the base branch at runtime from `git symbolic-ref --short refs/remotes/origin/HEAD`, falling back to asking the user when `origin/HEAD` is unset, so the skill works in `master` or `develop` repos.
- Fleet stops at green PRs; merging stays a human step via `/git-agent:merge`, documented explicitly.
- Added `tests/plugins/test-build-fleet.sh` with 7 checks covering frontmatter, `allowed-tools`, the plan-mode guard, dispatch delegation, the five blast-radius guards, README/CHANGELOG registration, and the `multiSelect` picker contract.
- Bumped plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`; added CHANGELOG entry and README rows.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Skill instructions — dispatcher | Created |
| `tests/plugins/test-build-fleet.sh` | Structural smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace version (plan-agent 9.3.0) | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `README.md` | Root Plugin Reference Table (regenerated) | Modified |

## How it works

The four subsystems `build-fleet` relies on already existed: `plan-agent:build` implements one plan end-to-end, `git-agent:ship-autonomous` handles commit/PR/CI/review/merge-gate, `Agent` with `isolation: "worktree"` creates and cleans up worktrees, and the two merge drivers auto-resolve the conflicts sibling PRs produce in this repo. `build-fleet` adds only the dispatcher layer.

The skill opens with candidate collection — globbing the plans directory for `status: todo` files — then presents a `multiSelect` picker over the newest four, stating how many were suppressed. The confirmed selection is both the plan list and the blast-radius acknowledgement; there is no second confirm-the-count question.

Each agent prompt carries the resolved base branch name (not a hardcoded `origin/main`) and chains `plan-agent:build` into `git-agent:ship-autonomous`. Because the `Agent` harness creates the worktree and removes it when unchanged, the dispatcher never calls `git worktree add` or `git worktree remove` directly.

The fleet finishes when each subagent reports a green PR. The skill contains no `gh pr merge` call; merging stays a deliberate human step via `/git-agent:merge`, because a background agent cannot answer `ship-autonomous`'s merge gate and auto-merging siblings is the one step with no cheap undo.

## How to use it

```
/plan-agent:build-fleet               # presents picker over up to 4 todo plans, --max 3 default
/plan-agent:build-fleet --max 5       # raise the per-run cap
/plan-agent:build-fleet path/to/a.md path/to/b.md   # explicit list skips the picker
```

Activation trigger (description field): dispatches one worktree agent per `status: todo` plan in the backlog. Use when asked to build or ship multiple plans concurrently.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — v9.3.0 entry
