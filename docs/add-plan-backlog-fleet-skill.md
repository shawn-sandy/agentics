# A plan-backlog fleet skill for plan-agent

> The 2026-08-14 usage report proposed spawning a subagent per backlog plan, each in its own worktree, shipping concurrently. Four of the five subsystems that...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Write `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` as a dispatch-only skill: collect candidates by reusing `build`'s plans-directory resolution by reference, then issue one `Agent` call per plan carrying `isolation: "worktree"` and `run_in_background: true`, whose prompt chains `plan-agent:build` into `git-agent:ship-autonomous`.
- Add the blast-radius guards to the Guardrails section — a mandatory confirmation naming how many pull requests will open, `--max` defaulting to 3, `status: completed` plans excluded even when named explicitly, a dirty-tree stop, and a headless run that cancels rather than defaulting.
- End the fleet at green PRs and route merging to `/git-agent:merge`, documenting that the repo's two merge drivers already resolve the conflicts sibling PRs produce.
- Register the skill — bump plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, add the README Features row and component section, and regenerate the root table with `node scripts/build-readme-table.mjs`.
- Add `tests/plugins/test-build-fleet.sh` covering the frontmatter contract, `allowed-tools`, the verbatim plan-mode guard, the dispatch-only objective, the blast-radius guards, and README plus CHANGELOG registration.
- Replace Step 2's "dispatch all, dispatch a subset, or cancel" with a real picker — one `multiSelect` `AskUserQuestion` over the newest four candidates, stating how many were suppressed, where the ticked boxes are themselves the PR-count confirmation and an explicit plan list skips the picker.
- Resolve the base branch from `git symbolic-ref --short refs/remotes/origin/HEAD` in Step 1 and carry the value into every agent prompt, asking rather than guessing when `origin/HEAD` is unset, and document `todo`-only discovery as deliberate.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | the dispatcher | Created |
| `.claude-plugin/marketplace.json` | plan-agent 9.2.0 to 9.3.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.3.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Features table row and component section | Modified |
| `README.md` | regenerated Plugin Reference Table | Modified |
| `tests/plugins/test-build-fleet.sh` | structural smoke test | Created |

## How it works

Add `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each running `build` then `ship-autonomous` to a green PR.

The 2026-08-14 usage report (`~/.claude/usage-data/report-2026-08-14-071004.html`) proposed "Parallel Worktree Fleets For Plan Backlogs": instead of shipping one plan at a time, spawn a subagent per backlog plan, each in an isolated git worktree, each implementing, verifying, opening a PR, and triaging review comments concurrently, with a supervisor watching CI and merging in dependency order. Four of the five subsystems that idea describes already ship here. `plan-agent:build` implements one plan through its acceptance, end-to-end, and completion gates. `git-agent:ship-autonomous` handles commit, PR, CI subscription, bounded autofix, review triage, and a gated merge. The `Agent` tool's `isolation: "worktree"` creates the worktree and removes it when unchanged, which replaces both `git worktree add` and the cleanup pass. And `scripts/merge-marketplace.mjs` plus `scripts/merge-plans-index.mjs` already auto-resolve the two conflicts sibling PRs in this repo actually produce — `marketplace.json` keeps the higher semver, gallery `index.html` files union their cards. So the missing piece is a dispatcher. A fifth implementation of the ship loop would drift from the solo path the moment either skill changed, which is the failure this plan is shaped to avoid: the skill delegates by name and restates nothing. The fifth subsystem — dependency-ordered merging — is deliberately out of scope. A background subagent cannot answer `ship-autonomous`'s merge gate, and auto-merging N sibling PRs is the one step in the chain with no cheap undo. The fleet stops at green PRs and merging stays a human step.

The implementation proceeded through the following steps: Write `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` as a dispatch-only skill: collect candidates by reusing `build`'s plans-directory resolution by reference, then issue one `Agent` call per plan carrying `isolation: "worktree"` and `run_in_background: true`, whose prompt chains `plan-agent:build` into `git-agent:ship-autonomous`. Why: those two skills already own every gate, every verification, and every autofix, so restating any of it guarantees drift the first time either changes. Verify: the file names both skills, contains `isolation: "worktree"`, and contains no `git worktree add` invocation outside a prohibition.; Add the blast-radius guards to the Guardrails section — a mandatory confirmation naming how many pull requests will open, `--max` defaulting to 3, `status: completed` plans excluded even when named explicitly, a dirty-tree stop, and a headless run that cancels rather than defaulting. Why: N agents open N pull requests against a shared remote, which is outward-facing and not undoable by editing a file, and worktrees fork from the base branch so uncommitted parent-tree work silently does not travel with them. Verify: all five guards appear in the Guardrails section and the headless branch cancels rather than picking a default.; End the fleet at green PRs and route merging to `/git-agent:merge`, documenting that the repo's two merge drivers already resolve the conflicts sibling PRs produce. Why: a background agent cannot answer `ship-autonomous`'s merge gate, and auto-merging siblings is the one step with no cheap undo. Verify: the skill contains no `gh pr merge` and its Merging section names `/git-agent:merge`.; Register the skill — bump plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, add the README Features row and component section, and regenerate the root table with `node scripts/build-readme-table.mjs`. Why: the CI version guard fails any PR whose changed plugin does not exceed the base branch, and the root table is generated rather than hand-edited. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` prints OK for every changed plugin.; Add `tests/plugins/test-build-fleet.sh` covering the frontmatter contract, `allowed-tools`, the verbatim plan-mode guard, the dispatch-only objective, the blast-radius guards, and README plus CHANGELOG registration. Why: the only regression this skill can realistically suffer is someone inlining work `build` or `ship-autonomous` already does, and that is invisible to every existing test. Verify: the script reports 6 of 6 checks passed.; Replace Step 2's "dispatch all, dispatch a subset, or cancel" with a real picker — one `multiSelect` `AskUserQuestion` over the newest four candidates, stating how many were suppressed, where the ticked boxes are themselves the PR-count confirmation and an explicit plan list skips the picker. Why: "a subset" named no mechanism, and `AskUserQuestion` renders at most four options, a ceiling that almost never binds because `--max` is 3; asking a second time to confirm a count the user just enumerated by hand is friction without consent value. Verify: `tests/plugins/test-build-fleet.sh` check 7 passes, and the skill carries no second confirm-the-count question..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
