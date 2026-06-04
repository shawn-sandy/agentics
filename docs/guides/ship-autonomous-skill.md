# Ship-Autonomous Skill

> End-to-end autonomous shipping workflow that chains branch creation, commit, PR, CI polling, and a bounded autofix loop into a single supervised flow.

<!-- generated:start -->

**Status:** Shipped 2026-04-17  **Plan:** [ship-autonomous-skill.md](plans/ship-autonomous-skill.md)
**Type:** artifact

## What shipped

- Added `.claude/skills/ship-autonomous/SKILL.md` — an orchestrating skill that chains the existing `git-agent` primitives (`branch-agent`, `commit-agent`, `pr-agent`) with a new CI-polling and autofix loop, all in strict seven-step order.
- Implemented a bounded **autofix loop** (max 3 iterations) that classifies CI failures into allow-listed classes (`lint`, `typecheck`, `peer-deps`) and applies targeted fixes; any unrecognised failure class escalates to the user immediately.
- Added a **PostToolUse hook** to `.claude/settings.json` that warns whenever uncommitted plan files exist in `docs/plans/` after a `Write` or `Edit` tool call, encouraging plan files to be committed alongside related changes.
- Delegated branching to `git-agent:branch-agent` (only when on the default branch), committing to `git-agent:commit-agent`, and PR creation to `git-agent:pr-agent`, reusing their battle-tested logic without duplication.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/skills/ship-autonomous/SKILL.md` | Orchestrating skill — full seven-step workflow | Created |
| `.claude/settings.json` | Project hooks config — added uncommitted-plan-file warning hook | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Delegated skill — auto-generates feature branch | Referenced |
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Delegated skill — conventional commit | Referenced |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Delegated skill — push + PR creation | Referenced |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Pattern reference — pre-flight guards & STOP clause | Referenced |

## How it works

**Step 1 — Pre-flight guards.** Before any mutation, the skill checks four conditions: (1) the working tree must be dirty (`git status --porcelain`); (2) if uncommitted plan files exist in `docs/plans/`, the user is asked via `AskUserQuestion` whether to include them, stash them, or abort; (3) the repository must not be in detached HEAD state; and (4) `gh auth status` must succeed. Any failed check stops the skill immediately.

**Step 2 — Branch.** If the current branch is the default branch (`main`/`master` or whatever `origin/HEAD` resolves to), the skill delegates to `git-agent:branch-agent`. That skill auto-generates a `<type>/<scope>-<desc>-YYYY-MM-DD` slug from the working tree diff (the date suffix is always appended so branches sort chronologically) and creates a new branch from `origin/HEAD --no-track`. If a feature branch is already checked out, the skill continues without branching.

**Step 3 — Commit.** The skill delegates to `git-agent:commit-agent`, which stages all changes, analyses the diff, writes a conventional commit message, and commits. If the pre-commit hook fails, the error is propagated verbatim and the skill stops — `--no-verify` is never used.

**Step 4 — Open PR.** `git-agent:pr-agent` first checks for an existing open PR (`gh pr view --json state,url`) and stops immediately if one is already open. If the last PR was merged, closed, or none exists, it then pushes the branch (sets upstream with `-u` if not yet tracked), generates a Summary/Changes body from `git log base..HEAD`, and opens the PR via `gh pr create`. The resulting PR URL is captured for subsequent steps.

**Step 5 — Poll CI.** `gh pr checks <pr-url> --watch --fail-fast=false` blocks until all checks reach a terminal state. The structured JSON output is then retrieved and parsed with `jq`. If all conclusions are `SUCCESS` or `SKIPPED`, the skill jumps straight to Step 7. `CANCELLED` or `TIMED_OUT` conclusions escalate to the user.

**Step 6 — Autofix loop.** Up to three fix-push cycles are tracked via `TodoWrite`. Each cycle fetches the failing run's log (`gh run view <run-id> --log-failed`) and classifies it: `lint` errors trigger the project's lint-fix script; `typecheck` errors get minimal TypeScript fixes (no `any`, no type loosening); `peer-deps` errors run the package manager's install and verify the diff is lockfile-only. Any other failure class escalates immediately. After each successful fix, `git-agent:commit-agent` creates a new commit (never amends), `git push` re-syncs, and Step 5 re-polls. At the three-iteration cap a PR comment is posted and the skill stops.

**Step 7 — Request review.** When all checks are green, `gh pr ready` marks the PR out of draft if needed, and a `gh pr comment` posts "CI is green — ready for review." The PR URL is printed and the skill stops unconditionally.

**PostToolUse hook.** Orthogonal to the skill itself, the hook added to `.claude/settings.json` runs after every `Write` or `Edit` tool call. It checks `git ls-files --others --modified --exclude-standard docs/plans/` and prints a warning if any untracked or modified plan files are found, reminding the user to commit plan files alongside related changes (per `.claude/rules/plan-hygiene.md`).

## How to use it

The skill activates automatically when the user asks to autonomously ship, ship and watch CI, auto-fix CI failures, or ship it and fix what breaks.

**Automatic activation examples:**
- "ship this autonomously"
- "ship and watch CI"
- "ship it and fix what breaks"
- "auto-fix CI failures on this PR"

**Allowed tools declared in frontmatter:**

```yaml
allowed-tools: Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(jq *), Skill, Read, Edit, Grep, Glob, TodoWrite, AskUserQuestion
```

The skill is installed at `.claude/skills/ship-autonomous/SKILL.md` (not packaged as a plugin), following the precedent of `.claude/skills/validate-plugin/`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `594f157` | 2026-04-14 | feat: add ship-autonomous skill with ci-polling and autofix loop |
| `13233ae` | 2026-04-17 | feat(ship-autonomous): update status to completed and add metadata |
| `f941749` | 2026-04-17 | feat(kit/plugins/git-agent): append YYYY-MM-DD date suffix to branch-agent branches (3.4.0) |
| `40e2d3c` | 2026-04-24 | Merge branch 'main' into feat/ship-autonomous-skill |
| `1297bff` | 2026-04-24 | feat(kit/plugins/git-agent): extend ExitPlanMode Step 0 to commit-agent, pr-agent, and ship (v3.3.3) |
| `428cdaa` | 2026-05-01 | refactor(kit/plugins): conditional ExitPlanMode detection — skip if not in plan mode |

<!-- generated:end -->

## References

- Plan: [ship-autonomous-skill.md](plans/ship-autonomous-skill.md)
- Delegated skills: [`kit/plugins/git-agent/skills/branch-agent/SKILL.md`](../kit/plugins/git-agent/skills/branch-agent/SKILL.md), [`kit/plugins/git-agent/skills/commit-agent/SKILL.md`](../kit/plugins/git-agent/skills/commit-agent/SKILL.md), [`kit/plugins/git-agent/skills/pr-agent/SKILL.md`](../kit/plugins/git-agent/skills/pr-agent/SKILL.md)
- Skill file: [`.claude/skills/ship-autonomous/SKILL.md`](../.claude/skills/ship-autonomous/SKILL.md)
