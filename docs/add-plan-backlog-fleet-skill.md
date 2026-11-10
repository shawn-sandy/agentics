# A plan-backlog fleet skill for plan-agent

> Adds `plan-agent:build-fleet`, a dispatch-only skill that fans `plan-agent:build` + `git-agent:ship-autonomous` across a plan backlog — one isolated worktree subagent per `status: todo` plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` — dispatches one `Agent` call per selected plan using `isolation: "worktree"` and `run_in_background: true`, chaining `plan-agent:build` into `git-agent:ship-autonomous`.
- Added blast-radius guardrails: mandatory `multiSelect` confirmation picker, `--max 3` default, `status: completed` exclusion, dirty-tree stop, headless cancellation.
- Runtime base-branch resolution via `git symbolic-ref --short refs/remotes/origin/HEAD` — never hardcodes `main`.
- Fleet stops at green PRs; merging routes to `/git-agent:merge`, never happens automatically.
- Added `tests/plugins/test-build-fleet.sh` — 7 checks covering frontmatter, `allowed-tools`, plan-mode guard, dispatch-only objective, blast-radius guards, and README/CHANGELOG registration.
- Bumped plan-agent from 9.2.0 to 9.3.0 in `.claude-plugin/marketplace.json`.
- Updated `kit/plugins/plan-agent/README.md` and `CHANGELOG.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Dispatch-only fleet skill | Created |
| `tests/plugins/test-build-fleet.sh` | Structural smoke test (7 checks) | Created |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 9.3.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.3.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Features table row and component section | Modified |
| `README.md` | Regenerated Plugin Reference Table | Modified |

## How it works

**The skill dispatches; it does not implement.** `build-fleet` restates nothing from `plan-agent:build` or `git-agent:ship-autonomous`. Every completion gate, browser verification, commit, PR, CI autofix, and review triage belongs to those skills. If either changes, the fleet inherits the change automatically.

**Base branch resolved at runtime.** Step 1 runs `git symbolic-ref --short refs/remotes/origin/HEAD` to find the remote's default branch. When `origin/HEAD` is unset, the skill asks rather than guessing `main`. The resolved name is passed into every agent prompt so worktrees fork from the correct branch.

**Discovery selects `status: todo` only.** Unlike `build`, which also accepts `in-progress`, the fleet deliberately excludes in-progress plans — they usually have a branch and a half-finished tree, and a fleet agent would fork a second one from the base branch and redo work. Name an in-progress plan explicitly to override.

**The picker is the confirmation.** Step 2 presents a `multiSelect` `AskUserQuestion` over the newest four candidates (stating how many were suppressed), sorted by `created:` date. The ticked boxes are both the selection and the PR-count confirmation — a second confirm-the-count question is omitted as friction without consent value. An explicit plan list in `$ARGUMENTS` skips the picker outright.

**Blast-radius guardrails.** N agents open N pull requests against a shared remote; there is no cheap undo. Guardrails: `--max 3` (default), no dispatch without the Step 2 confirmation, `status: completed` plans excluded even when named explicitly, dirty-tree stop (uncommitted work in the parent tree does not travel into a worktree fork), headless run cancels rather than defaulting.

**Fleet stops at green PRs.** Merging stays a human step via `/git-agent:merge`. The repo's two merge drivers (`scripts/merge-marketplace.mjs` and `scripts/merge-plans-index.mjs`) already auto-resolve the conflicts sibling PRs produce — marketplace.json keeps the higher semver, gallery index.html files union their cards.

## How to use it

```
/plan-agent:build-fleet
```

With explicit plans:
```
/plan-agent:build-fleet docs/plans/add-foo.md docs/plans/add-bar.md
```

Limit concurrency:
```
/plan-agent:build-fleet --max 2
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
