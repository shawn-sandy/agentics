# A plan-backlog fleet skill for plan-agent

> Adds `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each running `build` then `ship-autonomous` to a green PR.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-plan-backlog-fleet-skill](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` — dispatch-only skill delegating to `plan-agent:build` then `git-agent:ship-autonomous` via `Agent` with `isolation: "worktree"` and `run_in_background: true`
- Blast-radius guards: mandatory multi-select picker (top 4 candidates, suppressed-count reported), `--max` defaulting to 3, `completed` plans excluded, dirty-tree stop, headless run cancels rather than defaulting
- Fleet stops at green PRs; merging routed to `/git-agent:merge`, not automated
- Base branch resolved at runtime via `git symbolic-ref --short refs/remotes/origin/HEAD`
- Created `tests/plugins/test-build-fleet.sh` — 7 checks covering frontmatter, allowed-tools, plan-mode guard, dispatch-only objective, blast-radius guards, picker mode
- Bumped `plan-agent` to `9.3.0` with CHANGELOG entry, README Features row, and root README table regenerated

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Skill — fleet dispatcher | Created |
| `tests/plugins/test-build-fleet.sh` | Smoke test — 7 checks | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 9.3.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 9.3.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — build-fleet Features row and section | Modified |

## How it works

`build-fleet` is intentionally a dispatcher, not an implementation. It issues one `Agent` call per selected plan, carries `isolation: "worktree"` so each worker gets a clean git worktree, and runs in the background. The agent prompt chains `plan-agent:build` into `git-agent:ship-autonomous` — those two skills already own every gate, every verification, and every autofix. Restating any of it in `build-fleet` would create a drift surface the moment either sibling changed.

The blast-radius guards matter because N agents open N pull requests against a shared remote. Before dispatch: a `multiSelect` `AskUserQuestion` presents at most four candidates with a count of suppressed plans; the ticked boxes serve as both plan selection and PR-count confirmation (no second prompt). The dirty-tree check runs before any dispatch. Headless runs cancel rather than guessing.

The fleet deliberately stops at green PRs. A background agent cannot answer `ship-autonomous`'s merge gate, and auto-merging N sibling PRs is the one step in the chain with no cheap undo. `/git-agent:merge` handles each PR after the user reviews the fleet's outputs.

The repo's two merge drivers — `scripts/merge-marketplace.mjs` and `scripts/merge-plans-index.mjs` — already auto-resolve the conflicts sibling PRs produce: `marketplace.json` keeps the higher semver, gallery `index.html` files union their cards.

## How to use it

```
/plan-agent:build-fleet                  # pick from backlog, dispatch one worker per plan
/plan-agent:build-fleet --max 5          # override default max of 3
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill](plans/add-plan-backlog-fleet-skill.md)
