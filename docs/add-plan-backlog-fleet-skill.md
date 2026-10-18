# A plan-backlog fleet skill for plan-agent

> Adds `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each building to a green PR.

<!-- generated:start -->

**Status:** Shipped 2026-08-14  **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` — a dispatch-only skill that issues one `Agent` call per selected `todo` plan with `isolation: "worktree"` and `run_in_background: true`, chaining `plan-agent:build` into `git-agent:ship-autonomous`.
- Added blast-radius guards: mandatory multi-select confirmation, `--max` (default 3), `status: completed` exclusion, dirty-tree stop, and headless-run cancel.
- Fleet ends at green PRs; merging is routed to `/git-agent:merge` — the skill contains no `gh pr merge`.
- Base branch resolved at runtime from `git symbolic-ref --short refs/remotes/origin/HEAD` (asks rather than guessing when unset).
- Added `tests/plugins/test-build-fleet.sh` with structural smoke checks.
- Bumped `plan-agent` to `9.3.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Skill instructions | Created |
| `tests/plugins/test-build-fleet.sh` | Smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |

## How it works

`build-fleet` is a pure dispatcher — it restates nothing from `build` or `ship-autonomous`. Each worker Agent receives a fully substituted prompt chaining both skills, runs in an isolated worktree (created by the harness, not by `git worktree add`), and closes with a green PR or reports what blocked it.

The multi-select picker shows up to 4 candidates (the `AskUserQuestion` ceiling) with the suppressed count noted; ticking the boxes serves as both selection and PR-count confirmation. An explicit `--plans` argument skips the picker.

The two conflicts sibling PRs produce in this repo (`marketplace.json` semver and gallery `index.html` cards) are already handled by registered merge drivers, so the fleet does not need dependency-ordered merging. Merging the resulting PRs remains a human step via `/git-agent:merge`.

## How to use it

Invoke as `/plan-agent:build-fleet` to open a picker over all `status: todo` plans, or pass `--plans <paths>` to target specific plans. Use `--max <n>` (default 3, cap 5) to control concurrency.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
