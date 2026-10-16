# A plan-backlog fleet skill for plan-agent

> Adds `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each running `build` then `ship-autonomous` to a green PR.

<!-- generated:start -->

**Status:** Shipped 2026-08-14  **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` — a dispatch-only skill that delegates entirely to `plan-agent:build` and `git-agent:ship-autonomous` via the harness `Agent` tool with `isolation: "worktree"` and `run_in_background: true`.
- The skill collects candidates by reusing `build`'s plans-directory resolution (by reference, not by restatement), presents a `multiSelect` `AskUserQuestion` over the newest four candidates (stating how many were suppressed), and accepts an explicit plan list as an alternative to the picker.
- Added five blast-radius guards in the Guardrails section: mandatory confirmation naming the PR count, `--max` defaulting to 3, `status: completed` plans excluded even when named explicitly, dirty-tree stop, and headless-run cancellation.
- Base branch is resolved at runtime via `git symbolic-ref --short refs/remotes/origin/HEAD` — the skill asks rather than guessing when `origin/HEAD` is unset, and never hardcodes `origin/main`.
- Merging stops at green PRs and routes to `/git-agent:merge`; the skill contains no `gh pr merge` call. The Merging section documents that the repo's two merge drivers already resolve the conflicts sibling PRs produce.
- Bumped `plan-agent` to `9.3.0` in `.claude-plugin/marketplace.json`, added the CHANGELOG entry, added the README Features row and component section, regenerated the root README table with `node scripts/build-readme-table.mjs`.
- Added `tests/plugins/test-build-fleet.sh` covering frontmatter contract, `allowed-tools`, verbatim plan-mode guard, dispatch-only objective, blast-radius guards, README and CHANGELOG registration, and the picker's `multiSelect` mode.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Skill instructions | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README | Modified |
| `README.md` | Root plugin reference table | Modified |
| `tests/plugins/test-build-fleet.sh` | Smoke test | Created |

## How it works

Four of the five subsystems needed to parallelize a plan backlog already existed before this skill: `plan-agent:build` implements one plan end-to-end through its acceptance and completion gates; `git-agent:ship-autonomous` handles commit, PR, CI subscription, bounded autofix, review triage, and a gated merge; the `Agent` tool's `isolation: "worktree"` creates and cleans up isolated git worktrees; and `scripts/merge-marketplace.mjs` plus `scripts/merge-plans-index.mjs` already auto-resolve the two conflicts sibling PRs in this repo produce.

The only missing piece was a dispatcher. `build-fleet` is purely that: it collects candidates and issues one `Agent` call per plan. It restates nothing from `build` or `ship-autonomous` — any duplication would drift from the solo path the moment either skill changed.

Each agent prompt chains both skills: `plan-agent:build` implements the plan, then `git-agent:ship-autonomous` takes the result to a green PR. The `isolation: "worktree"` harness parameter creates a fresh worktree for each agent, so concurrent agents don't share working-tree state. Worktrees that complete with no changes are removed automatically by the harness.

The blast-radius guards exist because N agents open N pull requests against a shared remote — an action that is outward-facing and not undoable by editing a file. The `--max 3` default limits the blast radius to a reviewable batch. The dirty-tree stop prevents the user's uncommitted work from appearing to travel to the worktrees (it does not — worktrees fork from the base branch — but the stop makes that explicit rather than silently surprising).

The picker uses `multiSelect` with at most four options because `AskUserQuestion` caps at four options and `--max` is 3, so the ceiling almost never binds in practice. The ticked boxes themselves constitute the PR-count confirmation, avoiding a second redundant confirmation question.

The base-branch resolution via `git symbolic-ref --short refs/remotes/origin/HEAD` makes the skill work in repos where the default branch is `master` or `develop`, not just `main`. A hardcoded `origin/main` was found to kill all agents on line 1 of their prompts in a `master`-only fixture during development.

Dependency-ordered merging is deliberately out of scope. A background agent cannot answer `ship-autonomous`'s merge gate, and auto-merging N sibling PRs is the one step in the chain with no cheap undo. The fleet stops at green PRs; `/git-agent:merge` handles the merge step.

## How to use it

```text
/plan-agent:build-fleet
/plan-agent:build-fleet --max 5
/plan-agent:build-fleet docs/plans/add-feature-a.md docs/plans/add-feature-b.md
```

A bare invocation shows the newest four `status: todo` plans in a multi-select picker. Ticking the plans you want to ship and confirming starts one subagent per selected plan in an isolated worktree. Each subagent implements the plan and opens a PR; review and merge remain human steps via `/git-agent:merge`.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
