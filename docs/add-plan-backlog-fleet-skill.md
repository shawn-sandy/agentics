# Add plan-backlog fleet skill to plan-agent

> `plan-agent:build-fleet` is a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each running `build` then `ship-autonomous` to a green PR, without restating a single step of the skills it delegates to.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build-fleet/SKILL.md`: collects candidates by reusing `build`'s plans-directory resolution, presents a `multiSelect` picker of up to four newest candidates (stating suppressed count), and dispatches one `Agent` call per selected plan with `isolation: "worktree"` and `run_in_background: true`.
- Added blast-radius guardrails: mandatory confirmation naming the PR count, `--max` defaulting to 3, `status: completed` plans excluded, dirty-tree stop, headless-cancel rather than default.
- Fleet ends at green PRs; merging stays a human step via `/git-agent:merge`; the two repo merge drivers already auto-resolve `marketplace.json` and gallery index conflicts.
- Added the base-branch resolution via `git symbolic-ref --short refs/remotes/origin/HEAD` so the skill works in `master` or `develop` repos.
- Added `tests/plugins/test-build-fleet.sh` covering the frontmatter contract, `allowed-tools`, plan-mode guard, dispatch-only objective, blast-radius guards, and README/CHANGELOG registration.
- Bumped `plan-agent` to `9.3.0` with CHANGELOG entry, README Features row and component section, and regenerated root Plugin Reference Table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Dispatch skill | Created |
| `tests/plugins/test-build-fleet.sh` | Smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `README.md` | Plugin Reference Table | Modified |

## How it works

`build-fleet` delegates entirely by name, calling no git or PR commands itself. Each agent prompt chains `plan-agent:build` into `git-agent:ship-autonomous` for the selected plan. The harness `isolation: "worktree"` creates a worktree and removes it when unchanged — no `git worktree add` in the skill.

A `multiSelect` `AskUserQuestion` presents at most four candidates (the newest by `created:` date, with the suppressed count stated). The ticked boxes are both the selection and the PR-count confirmation — no second confirmation prompt is needed. `--max` caps the concurrent agent count (default 3), and the headless path cancels rather than defaulting.

The fleet never merges pull requests on its own initiative. The repo's `scripts/merge-marketplace.mjs` and `scripts/merge-plans-index.mjs` merge drivers auto-resolve the two conflicts sibling PRs produce (`marketplace.json` keeps the higher semver; gallery index files union their cards).

## How to use it

```
/plan-agent:build-fleet
/plan-agent:build-fleet --max 5
```

Presents a plan picker over all `status: todo` plans. After confirmation it dispatches one worktree agent per selected plan. Each agent implements the plan and opens a PR; the fleet stops at green PRs.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `9871dd92` | 2026-08-14 | Add build-fleet: ship a plan backlog in parallel, one worktree agent per plan (#554) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
