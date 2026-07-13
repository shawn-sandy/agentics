# Generate HTML after plan rename via plan-to-html skill

> Extends both rename commands (`review-rename-plans` and `plan-hygiene`) to automatically invoke `plan-to-html` after every successful rename, migrating stale `.html` artifacts via `git mv` before regenerating (v1.18.0).

<!-- generated:start -->

**Status:** Shipped 2026-05-13  **Plan:** [add-html-output-to-rename-workflow.md](plans/add-html-output-to-rename-workflow.md)
**Type:** artifact

## What shipped

- Extended `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` to accept two optional flags in `$ARGUMENTS` after the path: `--theme=<default|developer|document|minimal>` (skips the theme `AskUserQuestion` when present) and `--no-open` (skips the browser-launch `AskUserQuestion`). This makes the skill safe to invoke in batch from another command without N prompts per file.
- Added a post-rename HTML step (new Step 5) to `kit/plugins/plan-interview/commands/review-rename-plans.md`: migrates stale `<old-basename>.html` via `git mv`, asks theme once via `AskUserQuestion`, then invokes `plan-interview:plan-to-html` per renamed file with `--theme=<chosen> --no-open`; appends an HTML summary table. `Skill` added to `allowed-tools`.
- Added an analogous post-commit HTML step to `kit/plugins/plan-interview/commands/plan-hygiene.md` (after the existing `chore: rename plan files…` commit): same stale-HTML migration, same single theme prompt, same per-file `Skill` invocation; stages and commits the regenerated `.html` files with `chore: regenerate plan HTML after rename`. `Skill` added to `allowed-tools`.
- Added `## [1.18.0] - 2026-05-13` CHANGELOG entry to `kit/plugins/plan-interview/CHANGELOG.md` naming both commands and the new post-rename HTML behaviour.
- Bumped `plan-interview` version (MINOR) in `.claude-plugin/marketplace.json`.
- Renamed the placeholder plan file from `i-want-to-add-sparkling-bonbon.md` to `add-html-output-to-rename-workflow.md` via `git mv`.

> CHANGELOG citation — `kit/plugins/plan-interview/CHANGELOG.md`, `## [1.18.0] - 2026-05-13`: "`commands/review-rename-plans.md` now invokes the `plan-to-html` skill after each rename (new Step 5 — Generate HTML for renamed files): prompts for a theme once up-front, calls `plan-to-html` with `--no-open` per renamed file, migrates stale `.html` files with `git mv`; `commands/plan-hygiene.md` includes an analogous HTML Generation section after the rename commit."

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/commands/review-rename-plans.md` | Command wrapper | Modified |
| `kit/plugins/plan-interview/commands/plan-hygiene.md` | Command wrapper | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `docs/plans/add-html-output-to-rename-workflow.md` | Plan file (renamed) | Modified |

## How it works

The core problem was that both rename commands previously ended at "renames applied" without generating or updating any HTML artifact. If a user had previously generated an `.html` file for a plan, renaming the plan left the old `.html` file with the old basename alongside the new `.md`, creating stale artifacts.

The solution has two parts: first, make `plan-to-html` non-interactive when invoked programmatically; second, call it from the rename commands with the captured flags.

The `plan-to-html` skill was extended to parse `--theme=<name>` and `--no-open` from `$ARGUMENTS` in its Step 1. When `--theme` is found, Step 3's `AskUserQuestion` is skipped and the supplied theme is used directly. When `--no-open` is found, Step 6's browser-launch prompt is suppressed. This makes the skill safe to call in a loop without prompting the user N times.

In `review-rename-plans.md`, a new Step 5 runs after the "Renames Applied" summary table. For each renamed file, it checks whether `<old-basename>.html` exists in the same directory; if so, it runs `git mv <old>.html <new>.html` (with a plain `mv` + `git add` fallback) to preserve history. Then it asks the theme once via `AskUserQuestion` (a single prompt across all renamed files), and calls the `Skill` tool for each file with `plan-interview:plan-to-html` and `--theme=<chosen> --no-open`. The final summary is updated to list each generated `.html`.

In `plan-hygiene.md`, the HTML step runs after the existing `chore: rename plan files to descriptive conventions` commit. Separating it from the rename commit ensures each concern lands in its own commit. The stale-HTML migration and theme-prompt pattern is identical to `review-rename-plans`. The regenerated `.html` files are staged and committed with `chore: regenerate plan HTML after rename`.

Both commands declare `Skill` in their `allowed-tools` frontmatter so the cross-skill invocation runs without a permission prompt.

## How to use it

The HTML generation is automatic — no extra flags needed when invoking the rename commands.

**`/plan-interview:review-rename-plans <path>`** — after renaming files, Step 5 prompts once:
> "Which theme would you like for the generated HTML?"
> Options: `Default` / `Developer` / `Document` / `Minimal`
Then generates `<new-basename>.html` alongside each renamed `.md`. Any stale `<old-basename>.html` is migrated first.

**`/plan-interview:plan-hygiene <path>`** — after the rename commit, the HTML step runs:
- Migrates any stale `.html` files via `git mv`
- Asks theme once
- Generates new `.html` files
- Commits them as `chore: regenerate plan HTML after rename`

**Direct `plan-to-html` with flags (non-interactive):**
```
Skill: plan-interview:plan-to-html
Args: docs/plans/my-plan.md --theme=developer --no-open
```
Produces `docs/plans/my-plan.html` with the developer theme, no prompts.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `bd738a9` | 2026-05-13 | feat(plugins/plan-interview): add html output to rename commands |
| `3dee2c2` | 2026-05-13 | chore(docs/plans): add status frontmatter to two plan files per coderabbit review |

<!-- generated:end -->

## References

- Plan: [add-html-output-to-rename-workflow.md](plans/add-html-output-to-rename-workflow.md)
- Related docs: [add-plan-to-html-skill-to-plan-interview.md](add-plan-to-html-skill-to-plan-interview.md), [add-review-rename-plans-command.md](add-review-rename-plans-command.md), [add-html-output-to-plan-interview-skill.md](add-html-output-to-plan-interview-skill.md)
