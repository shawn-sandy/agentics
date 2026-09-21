# A Plan-Backlog Fleet Skill for plan-agent

> Adds `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one isolated worktree subagent per selected `status: todo` plan, each running `build` then `ship-autonomous` to a green PR.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` — a dispatch-only skill that issues one `Agent` call per selected plan with `isolation: "worktree"` and `run_in_background: true`, chaining `plan-agent:build` into `git-agent:ship-autonomous`.
- A multi-select `AskUserQuestion` picker (capped at four options, suppressed count stated) replaces a two-question confirm-the-count flow; the selected plans are themselves the confirmation.
- Five blast-radius guards: mandatory confirmation naming PR count, `--max` defaulting to 3, `status: completed` plans excluded even when named explicitly, dirty-tree stop, and headless cancellation.
- Base branch resolved at runtime via `git symbolic-ref --short refs/remotes/origin/HEAD`; asks when `origin/HEAD` is unset rather than hardcoding `main`.
- Fleet stops at green PRs — no `gh pr merge`; the `Merging` section routes to `/git-agent:merge` and notes that the repo's merge drivers already resolve the two conflict types sibling PRs produce.
- Bumped `plan-agent` to `9.3.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry and README update.
- Added `tests/plugins/test-build-fleet.sh` with 7 checks covering frontmatter, `allowed-tools`, plan-mode guard, dispatch-only objective, blast-radius guards, and README/CHANGELOG registration.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Skill contract — dispatch-only fleet runner | Created |
| `tests/plugins/test-build-fleet.sh` | Smoke test — 7 structural checks | Created |
| `.claude-plugin/marketplace.json` | `plan-agent` bumped to `9.3.0` | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | `9.3.0` entry | Modified |
| `kit/plugins/plan-agent/README.md` | Features table row and component section | Modified |
| `README.md` | Regenerated Plugin Reference Table | Modified |

## How it works

The skill is deliberately thin. Four of the five subsystems described in the 2026-08-14 usage report already existed: `plan-agent:build` (per-plan implementation through all acceptance gates), `git-agent:ship-autonomous` (commit, PR, CI, autofix, review triage, gated merge), the `Agent` tool's `isolation: "worktree"` (creates the worktree and removes it when unchanged), and the repo's merge drivers (`scripts/merge-marketplace.mjs`, `scripts/merge-plans-index.mjs`). The only missing piece was a dispatcher.

The skill collects candidates by reusing `build`'s plans-directory resolution logic — non-flag tokens in `$ARGUMENTS` are an explicit list; otherwise every `*.md` spec with `status: todo` is discovered, excluding `archive/` and `artifacts/`. Discovery is `todo`-only by design: `in-progress` plans are mid-flight work that may have partial state, and dispatching them in parallel worktrees risks conflicts against that state.

After candidate collection, the skill resolves the remote default branch via `git symbolic-ref --short refs/remotes/origin/HEAD`. If `origin/HEAD` is unset (an unconfigured remote), it asks rather than defaulting to `main`. This value is interpolated into every agent prompt so the worktree forks from the correct base.

The multi-select picker presents at most four candidates (the `AskUserQuestion` cap), stating how many were suppressed. Ticking a plan is both selection and confirmation — there is no second "confirm the PR count" question. Explicit cancellation, ticking nothing, and headless runs all cancel rather than default-dispatching.

Each `Agent` call receives `isolation: "worktree"` and `run_in_background: true`. The harness creates and manages the worktree, removing it if the agent exits without a net change. The agent's prompt chains `plan-agent:build` into `git-agent:ship-autonomous` by name — the skill contains no implementation of either.

The fleet stops at green PRs and routes merging to `/git-agent:merge`. The skill contains no `gh pr merge` call. Dependency-ordered merging is explicitly out of scope: a background subagent cannot answer `ship-autonomous`'s merge gate, and auto-merging siblings is the one step in the chain with no cheap undo.

During implementation, driving the skill against a `master`-only fixture confirmed the hardcoded `origin/main` would have killed every agent on line 1. The base-branch resolution fix was added as Step 7 of the plan after this was found.

## How to use it

```text
/plan-agent:build-fleet
/plan-agent:build-fleet --max 5
/plan-agent:build-fleet docs/plans/fix-login.md docs/plans/add-cache.md
```

A bare invocation discovers all `status: todo` plans and presents the picker. Explicit plan paths skip discovery. `--max N` overrides the default concurrency cap of 3. After all agents complete, a summary reports which PRs are open and ready for the human merge step.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
