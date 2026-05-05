# Ship-Autonomous Skill

> An orchestrating skill that chains branch creation, commit, PR opening, CI polling, and a bounded autofix loop into a single supervised end-to-end shipping flow.

<!-- generated:start -->

**Status:** Shipped 2026-04-17 &nbsp;**Plan:** [ship-autonomous-skill.md](plans/ship-autonomous-skill.md)
**Type:** artifact

## What shipped

- Created `.claude/skills/ship-autonomous/SKILL.md` — an orchestrating skill that delegates to `git-agent:branch-agent`, `git-agent:commit-agent`, and `git-agent:pr-agent` via the `Skill` tool, adding CI polling via `gh pr checks --watch` and a bounded 3-iteration autofix loop for allow-listed failure classes (lint, typecheck, peer-deps).
- Added a PostToolUse hook to `.claude/settings.json` that warns whenever uncommitted plan files exist in `docs/plans/` after any `Write` or `Edit` operation (orthogonal to `plan-interview:plan-hygiene`, which handles randomly-named files).
- Renamed the plan file from `piped-wibbling-stroustrup.md` to `ship-autonomous-skill.md` per `.claude/rules/plan-hygiene.md`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `.claude/skills/ship-autonomous/SKILL.md` | Skill instructions — autonomous ship orchestration | Created |
| `.claude/settings.json` | Project settings — PostToolUse hook for uncommitted plan files | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Orchestration target — delegated for branch creation | Referenced |
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Orchestration target — delegated for commit + autofix commits | Referenced |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Orchestration target — delegated for PR creation | Referenced |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Pattern reference — pre-flight guards and STOP clause | Referenced |
| `kit/plugins/plan-interview/hooks.json` | Pattern reference — PostToolUse hook shape | Referenced |
| `.claude/rules/plan-hygiene.md` | Naming rule — enforced by plan rename on commit | Referenced |

## How it works

**Pre-flight (Step 1)** runs four guards before any mutation. `git status --porcelain` confirms there are uncommitted changes — if the tree is clean the skill stops immediately with "Nothing to ship." `git ls-files --others --modified --exclude-standard docs/plans/` surfaces uncommitted plan files and asks the user to include, stash, or abort. `git branch --show-current` checks for a detached HEAD — if empty, the skill stops with "Cannot ship: repository is in detached HEAD state." `gh auth status` verifies GitHub CLI authentication. Only when all four guards pass does execution continue.

**Branching (Step 2)** is fully delegated to `git-agent:branch-agent`. When the current branch is `main`, `master`, or the repository default, the skill invokes `branch-agent` via the `Skill` tool, which auto-generates a `<type>/<scope>-<desc>` name from uncommitted working-tree changes and creates the branch from `origin/HEAD` with no upstream tracking. If the user is already on a feature branch, the step is skipped.

**Committing (Step 3)** is delegated to `git-agent:commit-agent`, preserving its conventional-commit scope-selection logic and its STOP-on-pre-commit-hook-failure contract. The skill deliberately does not reproduce this logic inline; delegation keeps the two skills in sync as `commit-agent` evolves.

**PR creation (Step 4)** is delegated to `git-agent:pr-agent` (v3.3.2+), which handles the merged-PR false-positive scenario, generates a Summary/Changes body from `git log base..HEAD`, pushes if no upstream exists, and opens the PR. The skill parses the returned PR URL (last line containing `https://github.com/.../pull/`) for use in CI polling.

**CI polling (Step 5)** blocks on `gh pr checks --watch --fail-fast=false <pr-url>` until all checks reach a terminal state, then parses `gh pr checks <pr-url> --json name,state,conclusion` to identify failures.

**Autofix loop (Step 6)** is capped at 3 iterations, tracked via `TodoWrite`. Each iteration fetches failing check logs with `gh run view <run-id> --log-failed` and classifies the failure against an explicit allow-list: `lint` failures trigger the project's `lint --fix` script; `typecheck` failures apply minimal TypeScript fixes without loosening types or introducing `any`/`as unknown`; `peer-deps` failures run `npm install` / `pnpm install` and commit only if the diff is lockfile-only. Any failure class outside this list causes the skill to escalate to the user and stop. After each successful fix, changes are committed via `commit-agent` (new commit, not amend) and CI is re-polled. On hitting the 3-iteration cap the skill comments on the PR summarizing the attempts and escalates.

**Review request (Step 7)** fires when all checks are green: `gh pr ready` (if the PR was opened as draft) and a comment `"CI green, ready for review"`. Using a comment rather than assigning reviewers avoids guessing who should review and works without CODEOWNERS.

**PostToolUse hook** extends the existing `Write|Edit` hook in `.claude/settings.json` with a shell check that outputs a warning whenever `git ls-files --others --modified --exclude-standard docs/plans/` reports uncommitted plan files. This keeps plan-hygiene visible in real time without blocking the workflow.

## How to use it

The skill lives at `.claude/skills/ship-autonomous/SKILL.md` and is loaded from the project's `.claude/` directory — it is not packaged as a plugin.

**Activation triggers** (from the skill description):

- "autonomously ship"
- "ship and watch CI"
- "auto-fix CI failures"
- "ship it and fix what breaks"

Load it by starting Claude Code from the project root — `.claude/skills/` is auto-discovered.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `428cdaa` | 2026-05-01 | refactor(kit/plugins): conditional ExitPlanMode detection — skip if not in plan mode |
| `40e2d3c` | 2026-04-24 | Merge branch 'main' into feat/ship-autonomous-skill |
| `1297bff` | 2026-04-24 | feat(kit/plugins/git-agent): extend ExitPlanMode Step 0 to commit-agent, pr-agent, and ship (v3.3.3) |
| `f941749` | 2026-04-17 | feat(kit/plugins/git-agent): append YYYY-MM-DD date suffix to branch-agent branches (3.4.0) |
| `13233ae` | 2026-04-17 | feat(ship-autonomous): update status to completed and add metadata |
| `594f157` | 2026-04-14 | feat: add ship-autonomous skill with ci-polling and autofix loop |
| `ad52353` | 2026-04-14 | fix(kit/plugins/git-agent): pr-agent no longer stops on merged PRs (3.3.2) |
| `7740d93` | 2026-04-14 | fix(kit/plugins/git-agent): branch-agent always exits plan mode on entry (3.3.1) |

<!-- generated:end -->

## References

- Plan: [ship-autonomous-skill.md](plans/ship-autonomous-skill.md)
- Related docs: [`add-ship-skill-to-git-agent.md`](add-ship-skill-to-git-agent.md) — the earlier single-shot `ship` skill this builds on
