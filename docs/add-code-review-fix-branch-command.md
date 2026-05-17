# Add `/code-review:fix-branch` slash command

> Packages the "diff branch, classify findings, apply fixes autonomously, retry once" workflow as a reusable slash command in the `code-review` plugin, bumping it to v3.3.0.

<!-- generated:start -->

**Status:** Shipped 2026-05-13  **Plan:** [add-code-review-fix-branch-command.md](plans/add-code-review-fix-branch-command.md)
**Type:** artifact

## What shipped

- Created `kit/plugins/code-review/commands/fix-branch.md` — the new `/code-review:fix-branch` command with a seven-step body (Steps 0–6), a concrete four-tier severity rubric (blocking/major/minor/unfixable), delegation to `skill-reviewer:reviewing-skills` and `agent-reviewer:reviewing-agents` for specialised file types, and a 2-iteration fix loop (no `AskUserQuestion` in `allowed-tools`; `Skill` included).
- Updated `kit/plugins/code-review/README.md` — added a `## Commands` section above the existing `## Review Checklist Overview` section, listing `/code-review:fix-branch` with its argument hint and a usage example.
- Prepended a `## [3.3.0] - 2026-05-13` entry to `kit/plugins/code-review/CHANGELOG.md` describing the new command under `### Added`.
- Bumped `code-review` version from `3.2.1` to `3.3.0` (MINOR — new command added) in `.claude-plugin/marketplace.json`.

> CHANGELOG citation — `kit/plugins/code-review/CHANGELOG.md`, `## [3.3.0] - 2026-05-13`: "`fix-branch` command (`/code-review:fix-branch`) — reviews all branch changes vs the default branch, classifies findings as blocking/major/minor/unfixable using a concrete severity rubric, applies fixes autonomously via `Edit`/`Write`, retries once (cap = 2), and leaves fixes uncommitted with a summary pointing to `git diff` and `/git-agent:commit-agent`."

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/commands/fix-branch.md` | Command wrapper | Created |
| `kit/plugins/code-review/README.md` | Plugin README | Modified |
| `kit/plugins/code-review/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The command begins with a pre-flight check (Step 0): it refuses to run if the working tree has uncommitted changes (`git diff --quiet HEAD`), ensuring that any edits applied by the command are isolated and easy to review. It then resolves the base branch via `git symbolic-ref refs/remotes/origin/HEAD`, falling back to `main` then `master`, or accepting an explicit base branch from `$ARGUMENTS`. The merge base is computed with `git merge-base`.

Step 1 enumerates changes using `git log` and `git diff --name-only` on the merge-base range. If the diff is empty, the command exits immediately with "Branch is clean — nothing to review."

Step 2 reviews each changed file against four criteria simultaneously: repo rules from `.claude/rules/*.md`, project conventions from `CLAUDE.md`/`CLAUDE.local.md`, frontmatter validation (name length, description length, required fields), and — for plan files — the plan's own verification section. The verification parser matches any heading whose text contains "verif" (case-insensitive) and also extracts inline `<em>Verify:</em>` snippets from list items. For files matching `**/SKILL.md`, the `skill-reviewer:reviewing-skills` skill is invoked via the `Skill` tool and its findings merged. Files under `**/agents/*.md` are delegated to `agent-reviewer:reviewing-agents` the same way.

Step 3 classifies every finding into one of four tiers: **blocking** (fails validation or verification, broken JSON), **major** (behaviour change without doc update, missing `ToolSearch` for deferred tools), **minor** (typo, style, description over 160 chars), or **unfixable** (requires human judgment — ambiguous renames, missing domain knowledge).

Step 4 applies fixes for blocking, major, and minor findings autonomously via `Edit` or `Write`, never prompting the user. Unfixable findings are accumulated for the final report. After editing, only previously-failing verification commands are re-run.

Step 5 retries once (cap = 2 total iterations) if new findings surface after the first round of fixes.

Step 6 reports: a table of iterations, findings, fixes, and remaining issues; a list of unfixable items with file path, line range, and a "needs human review" note; and a one-line summary directing the user to `git diff` and `/git-agent:commit-agent`.

## How to use it

**Invocation:**
```
/code-review:fix-branch
/code-review:fix-branch main
/code-review:fix-branch origin/develop
```

The optional argument overrides the auto-detected base branch. Without it, the command resolves the remote default branch automatically.

**Example workflow:**
1. Make changes on a feature branch.
2. Run `/code-review:fix-branch` — it diffs vs the default branch, fixes blocking/major/minor issues, and prints a summary.
3. Review the changes with `git diff`.
4. Commit with `/git-agent:commit-agent` (or manually).

**Dirty working tree** — if uncommitted changes exist when the command is invoked, it stops immediately with: `ERROR: working tree has uncommitted changes. Commit or stash first so review fixes are isolated.`

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `37557c2` | 2026-05-13 | feat: add /code-review:fix-branch command |
| `1f3bf66` | 2026-05-13 | fix: address code review feedback on fix-branch command and skill docs |

<!-- generated:end -->

## References

- Plan: [add-code-review-fix-branch-command.md](plans/add-code-review-fix-branch-command.md)
- Related docs: [add-code-reviewer-agent.md](add-code-reviewer-agent.md), [add-complexity-rating-code-review-skill.md](add-complexity-rating-code-review-skill.md), [add-breaking-change-regression-detection.md](add-breaking-change-regression-detection.md)
