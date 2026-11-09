# A plan-backlog fleet skill for plan-agent

> Adds `plan-agent:build-fleet`, a dispatch-only skill that fans `build` and `ship-autonomous` across every todo plan in parallel, one isolated worktree agent per plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` as a pure dispatcher: collects `status: todo` candidates, presents up to four in a `multiSelect` picker (stating how many were suppressed), then issues one `Agent` call per selected plan with `isolation: "worktree"` and `run_in_background: true`, each running `plan-agent:build` then `git-agent:ship-autonomous`.
- Added blast-radius guardrails: mandatory confirmation naming the PR count, `--max` defaulting to 3, completed plans excluded even if named explicitly, dirty-tree stop, headless cancellation.
- Fleet stops at green PRs; merging is routed to `/git-agent:merge` and documents that the repo's existing merge drivers resolve sibling-PR conflicts automatically.
- Base branch is resolved at runtime via `git symbolic-ref --short refs/remotes/origin/HEAD`, with a fallback ask when `origin/HEAD` is unset.
- Added `tests/plugins/test-build-fleet.sh` with 7 checks: frontmatter, `allowed-tools`, plan-mode guard, dispatch-only objective, blast-radius guards, README/CHANGELOG registration, and picker contract.
- Bumped plan-agent to **9.3.0** in `.claude-plugin/marketplace.json`; added CHANGELOG entry and updated README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Skill instructions — dispatcher | Created |
| `tests/plugins/test-build-fleet.sh` | Smoke test — 7 structural checks | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — 9.2.0 → 9.3.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `README.md` | Root Plugin Reference Table (regenerated) | Modified |

## How it works

`build-fleet` is a dispatcher that restates nothing about the actual work. Step 1 reads the plans directory (using the same resolution logic as `build`), filters to `status: todo`, resolves the base branch, and presents up to four candidates in a single `multiSelect` question. The ticked boxes are themselves the PR-count confirmation; there is no second "are you sure?" prompt.

Each selected plan gets one `Agent` call with `isolation: "worktree"` — the harness creates the worktree and removes it when unchanged, replacing a manual `git worktree add` / cleanup cycle. The agent prompt chains `plan-agent:build` into `git-agent:ship-autonomous`, so every gate and verification step those skills define is inherited automatically rather than restated.

The fleet stops at green PRs. Dependency-ordered merging was deliberately left out: a background agent cannot answer `ship-autonomous`'s merge gate, and auto-merging N sibling PRs is the one step with no cheap undo. The Merging section routes to `/git-agent:merge` and notes that `scripts/merge-marketplace.mjs` and `scripts/merge-plans-index.mjs` already auto-resolve the two conflicts sibling PRs produce in this repo.

A runtime `origin/HEAD` resolution was added after a `master`-only fixture showed the original hardcoded `origin/main` killed all agents on their first step. When `origin/HEAD` is unset, the skill asks rather than guessing.

## How to use it

**Skill:** activates on "implement a plan backlog in parallel" or via `/plan-agent:build-fleet`.

```
# Fan out across up to 3 todo plans (default max)
/plan-agent:build-fleet

# Fan out from a specific plans directory
/plan-agent:build-fleet --dir ~/.claude/plans

# Override the default 3-plan cap
/plan-agent:build-fleet --max 5
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
