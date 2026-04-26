# Ship-Autonomous Skill

> End-to-end autonomous shipping workflow that chains branch creation, commit, PR, CI polling, and a bounded autofix loop into one supervised flow, composing existing `git-agent` skills without reimplementing them.

<!-- generated:start -->

**Status:** Shipped 2026-04-17  **Plan:** [ship-autonomous-skill.md](plans/ship-autonomous-skill.md)
**Type:** artifact

## What shipped

- Created `.claude/skills/ship-autonomous/SKILL.md` — an orchestrating skill that composes `git-agent:branch-agent`, `git-agent:commit-agent`, and `git-agent:pr-agent` via the `Skill` tool (avoids duplicating branch-name generation, commit-message logic, and merged-PR handling already battle-tested in those skills).
- Implemented a 7-step workflow: pre-flight guards → branch → commit → PR → CI poll → autofix loop → request review, with a hard STOP after Step 7.
- Added a bounded autofix loop (max 3 iterations) covering three allow-listed CI failure classes — `lint` (runs the project's `--fix` script), `typecheck` (applies minimal TS fixes without loosening types), and `peer-deps` (re-runs the package manager against the lockfile). Any other failure class escalates to the user immediately.
- Added a `PostToolUse` hook entry to `.claude/settings.json` that fires on every `Write`/`Edit` and warns when uncommitted plan files exist in `docs/plans/` (orthogonal to the random-filename check in `plan-hygiene`).
- Skill located at `.claude/skills/ship-autonomous/` (matches the existing `.claude/skills/validate-plugin/` precedent) — not packaged as a plugin, so no `plugin.json` or marketplace entry is needed.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `.claude/skills/ship-autonomous/SKILL.md` | Orchestrating skill — 7-step autonomous ship workflow | Created |
| `.claude/settings.json` | PostToolUse hook — uncommitted plan-file warning | Modified |
| `docs/plans/ship-autonomous-skill.md` | Plan file (renamed from `piped-wibbling-stroustrup.md` per plan-hygiene) | Created/Renamed |

Referenced (not modified by this plan):

| Path | Role |
| --- | --- |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Delegated for Step 2 (branch creation) |
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Delegated for Step 3 and autofix fix-commits |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Delegated for Step 4 (PR creation) |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Pattern reference for pre-flight guards and STOP clause |

## How it works

**Step 1 — Pre-flight guards.** Before any mutation, `ship-autonomous` runs `git status --porcelain` (stops with "Nothing to ship" if clean), checks `git ls-files --others --modified docs/plans/` for uncommitted plan files (asks include/stash/abort via `AskUserQuestion`), confirms a non-detached HEAD, and verifies `gh auth status`. All four must pass or the skill stops.

**Step 2 — Branch.** The skill detects the current branch via `git symbolic-ref refs/remotes/origin/HEAD`. If on the default branch (`main`/`master`), it delegates to `git-agent:branch-agent` with no arguments — that skill auto-generates a `<type>/<scope>-<desc>` slug from the working-tree diff and creates a branch from `origin/HEAD --no-track`. If already on a feature branch, the skill stays on it.

**Step 3 — Commit.** `git-agent:commit-agent` is invoked to stage all changes, analyze the diff, and write a conventional commit message. If the pre-commit hook fails, the failure is propagated verbatim and the skill stops — `--no-verify` is never used.

**Step 4 — PR.** `git-agent:pr-agent` pushes the branch (setting the upstream if needed), handles the merged-PR false-positive introduced in v3.3.2, generates a Summary/Changes body from `git log base..HEAD`, and opens the PR via `gh pr create`. The skill captures the returned PR URL for use in subsequent steps.

**Step 5 — CI poll.** `gh pr checks <pr-url> --watch --fail-fast=false` blocks until every check reaches a terminal state. The skill then reads structured results via `gh pr checks --json name,state,conclusion,workflowName | jq`. If all conclusions are `SUCCESS` or `SKIPPED`, it jumps to Step 7. `CANCELLED`/`TIMED_OUT` conclusions escalate immediately.

**Step 6 — Autofix loop.** Up to 3 iterations, each tracked as a TodoWrite entry labelled `autofix-iteration-N`. For each failing check, the log is fetched via `gh run view <run-id> --log-failed` and classified by keyword signatures (`eslint`/lint, `TS`/`tsc`, `ERESOLVE`/peer-dep). Allow-listed fixes are applied, then `git-agent:commit-agent` commits the fix as a new commit (never amend — preserves audit trail), `git push` re-sends it, and Step 5 re-polls. Anything outside the allow-list, or iteration 4, triggers a PR comment and a hard STOP.

**Step 7 — Request review.** When CI is green, `gh pr ready` marks the PR non-draft and `gh pr comment` posts "CI is green — ready for review." The PR URL is output and the skill stops. No reviewer is guessed — the repo may not have CODEOWNERS.

## How to use it

The skill activates automatically when the user asks to autonomously ship, ship and watch CI, auto-fix CI failures, or ship it and fix what breaks.

**Activation trigger:**
> Use when the user asks to autonomously ship, ship and watch CI, auto-fix CI failures, or ship it and fix what breaks. Chains branch creation (if needed), commit, PR, CI polling, and a bounded autofix loop into one supervised flow.

Example phrasings:
- `Ship this autonomously.`
- `Ship it and fix what breaks.`
- `Ship and watch CI.`
- `Auto-fix CI failures and get this merged.`

The skill is available whenever `.claude/skills/ship-autonomous/SKILL.md` is present in the project (no plugin installation required).

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
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
- Related docs: [add-ship-skill-to-git-agent.md](add-ship-skill-to-git-agent.md)
