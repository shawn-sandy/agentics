---
status: completed
modified: 2026-08-14
type: feature
created: 2026-08-14
repo-name: agentics
glance: The 2026-08-14 usage report proposed spawning a subagent per backlog plan, each in its own worktree, shipping concurrently. Four of the five subsystems that needs already exist — build, ship-autonomous, harness worktree isolation, and the merge drivers — so the missing piece is a dispatcher, not a pipeline. Done when /plan-agent:build-fleet fans build out across every todo plan without restating a single step of the skills it calls.
---

# Plan: A plan-backlog fleet skill for plan-agent

## Objective

Add `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each running `build` then `ship-autonomous` to a green PR.

## Context

The 2026-08-14 usage report (`~/.claude/usage-data/report-2026-08-14-071004.html`) proposed "Parallel Worktree Fleets For Plan Backlogs": instead of shipping one plan at a time, spawn a subagent per backlog plan, each in an isolated git worktree, each implementing, verifying, opening a PR, and triaging review comments concurrently, with a supervisor watching CI and merging in dependency order.

Four of the five subsystems that idea describes already ship here. `plan-agent:build` implements one plan through its acceptance, end-to-end, and completion gates. `git-agent:ship-autonomous` handles commit, PR, CI subscription, bounded autofix, review triage, and a gated merge. The `Agent` tool's `isolation: "worktree"` creates the worktree and removes it when unchanged, which replaces both `git worktree add` and the cleanup pass. And `scripts/merge-marketplace.mjs` plus `scripts/merge-plans-index.mjs` already auto-resolve the two conflicts sibling PRs in this repo actually produce — `marketplace.json` keeps the higher semver, gallery `index.html` files union their cards.

So the missing piece is a dispatcher. A fifth implementation of the ship loop would drift from the solo path the moment either skill changed, which is the failure this plan is shaped to avoid: the skill delegates by name and restates nothing.

The fifth subsystem — dependency-ordered merging — is deliberately out of scope. A background subagent cannot answer `ship-autonomous`'s merge gate, and auto-merging N sibling PRs is the one step in the chain with no cheap undo. The fleet stops at green PRs and merging stays a human step.

## Files

- kit/plugins/plan-agent/skills/build-fleet/SKILL.md (new) — the dispatcher
- .claude-plugin/marketplace.json (modified) — plan-agent 9.2.0 to 9.3.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 9.3.0 entry
- kit/plugins/plan-agent/README.md (modified) — Features table row and component section
- README.md (modified) — regenerated Plugin Reference Table
- tests/plugins/test-build-fleet.sh (new) — structural smoke test

## Steps

1. [x] Write `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` as a dispatch-only skill: collect candidates by reusing `build`'s plans-directory resolution by reference, then issue one `Agent` call per plan carrying `isolation: "worktree"` and `run_in_background: true`, whose prompt chains `plan-agent:build` into `git-agent:ship-autonomous`. Why: those two skills already own every gate, every verification, and every autofix, so restating any of it guarantees drift the first time either changes. Verify: the file names both skills, contains `isolation: "worktree"`, and contains no `git worktree add` invocation outside a prohibition.
2. [x] Add the blast-radius guards to the Guardrails section — a mandatory confirmation naming how many pull requests will open, `--max` defaulting to 3, `status: completed` plans excluded even when named explicitly, a dirty-tree stop, and a headless run that cancels rather than defaulting. Why: N agents open N pull requests against a shared remote, which is outward-facing and not undoable by editing a file, and worktrees fork from the base branch so uncommitted parent-tree work silently does not travel with them. Verify: all five guards appear in the Guardrails section and the headless branch cancels rather than picking a default.
3. [x] End the fleet at green PRs and route merging to `/git-agent:merge`, documenting that the repo's two merge drivers already resolve the conflicts sibling PRs produce. Why: a background agent cannot answer `ship-autonomous`'s merge gate, and auto-merging siblings is the one step with no cheap undo. Verify: the skill contains no `gh pr merge` and its Merging section names `/git-agent:merge`.
4. [x] Register the skill — bump plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, add the README Features row and component section, and regenerate the root table with `node scripts/build-readme-table.mjs`. Why: the CI version guard fails any PR whose changed plugin does not exceed the base branch, and the root table is generated rather than hand-edited. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` prints OK for every changed plugin.
5. [x] Add `tests/plugins/test-build-fleet.sh` covering the frontmatter contract, `allowed-tools`, the verbatim plan-mode guard, the dispatch-only objective, the blast-radius guards, and README plus CHANGELOG registration. Why: the only regression this skill can realistically suffer is someone inlining work `build` or `ship-autonomous` already does, and that is invisible to every existing test. Verify: the script reports 6 of 6 checks passed.

6. [x] Replace Step 2's "dispatch all, dispatch a subset, or cancel" with a real picker — one `multiSelect` `AskUserQuestion` over the newest four candidates, stating how many were suppressed, where the ticked boxes are themselves the PR-count confirmation and an explicit plan list skips the picker. Why: "a subset" named no mechanism, and `AskUserQuestion` renders at most four options, a ceiling that almost never binds because `--max` is 3; asking a second time to confirm a count the user just enumerated by hand is friction without consent value. Verify: `tests/plugins/test-build-fleet.sh` check 7 passes, and the skill carries no second confirm-the-count question.

7. [x] Resolve the base branch from `git symbolic-ref --short refs/remotes/origin/HEAD` in Step 1 and carry the value into every agent prompt, asking rather than guessing when `origin/HEAD` is unset, and document `todo`-only discovery as deliberate. Why: driving the skill against a `master`-only fixture showed the hardcoded `origin/main` would kill all five agents on line 1 of their prompts, and `git-agent:ship-autonomous` — the skill this one chains into — already detects the default branch rather than assuming it. Verify: re-drive the same fixture and confirm the run resolves `origin/HEAD`, reports it unset, and asks for a branch instead of dispatching against `origin/main`.

## Tests

- Objective-verification test — `tests/plugins/test-build-fleet.sh` check 4, "OBJECTIVE: dispatches to build + ship-autonomous, never reimplements them", asserts the skill delegates to both named skills, uses harness worktree isolation, hand-rolls no `git worktree add`, and inlines no `gh pr merge`. It failed on its first run against a draft whose prohibition line was indistinguishable from a use, which confirms the assertion is not tautological.
- Structural — the same script's checks 1, 2, 3, 5, 6, and 7 cover the frontmatter contract, `allowed-tools` completeness, the verbatim plan-mode guard, the five blast-radius guards, README plus CHANGELOG registration, and the plan picker's `multiSelect` mode, four-option ceiling, suppressed count, and three cancel paths.
- Existing suite, extended by construction — `tests/plugins/test-description-budget.sh` asserts every shipped SKILL.md fits 200 total and 80 first-sentence characters, which now covers `build-fleet` at 187 and 74; `tests/plugins/test-exitplanmode-guard.sh` covers the guard format.

## Acceptance Criteria

- [x] `/plan-agent:build-fleet` resolves to a skill that dispatches one subagent per selected plan
- [x] The skill restates no step of `build` or `ship-autonomous`
- [x] Worktrees come from the harness rather than from `git worktree add`
- [x] Dispatch is impossible without an explicit confirmation naming the PR count
- [x] The fleet is chosen plan by plan from a picker, not merely approved as a block
- [x] The base branch is resolved at runtime, so the skill works in a `master` or `develop` repo
- [x] The fleet never merges a pull request on its own initiative
- [x] plan-agent's marketplace version exceeds `origin/main`
- [x] `tests/plugins/test-build-fleet.sh` passes

## Verification

Run all four and confirm each exits 0: `bash tests/plugins/test-build-fleet.sh`, `bash tests/plugins/test-description-budget.sh`, `bash tests/plugins/test-exitplanmode-guard.sh`, and `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`. All four passed on 2026-08-14.

## Next Steps

- Dependency-ordered merging — the fleet stops at green PRs and merging is a human step; a supervisor that merges a batch in an order minimizing conflicts is the one part of the original proposal deliberately left out.

```text
In the agentics repo, look at kit/plugins/git-agent/skills/merge and kit/plugins/plan-agent/skills/build-fleet. Propose, but do not implement, how a supervisor could merge a set of sibling PRs in dependency order — deciding the order from the files each PR touches, rebasing PRs that go BEHIND, and still requiring one human approval for the batch rather than one per PR. Say explicitly what could go wrong, and whether the repo's existing merge drivers make the whole thing unnecessary.
```
