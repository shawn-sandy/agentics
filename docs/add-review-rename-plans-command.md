# Add review-rename-plans Command to plan-interview Plugin

> Adds a `review-rename-plans` command that batch-reviews plan filenames for descriptiveness and offers to rename flagged files using `git mv`, preserving history.

<!-- generated:start -->

**Status:** Shipped 2026-02-26   **Plan:** [add-review-rename-plans-command.md](plans/add-review-rename-plans-command.md)   **Type:** artifact

## What shipped

- New `kit/plugins/plan-interview/commands/review-rename-plans.md` — lightweight focused command to scan a plans directory (or single file) for naming issues without running a full plan interview.
- Evaluates filenames on four criteria: descriptive (words relate to goal), not random (not an adjective-noun pattern unrelated to content), not generic (not `plan.md`, `draft.md`), and H1 heading alignment.
- Three rename modes: **Rename all** (batch rename all flagged), **Pick individually** (interactive per-file with custom name option), **Skip** (leave as-is).
- Renames use `git mv` to preserve file history.
- `plan-interview` plugin bumped from `1.2.0` → `1.3.0`.

> See [CHANGELOG §1.3.0](../kit/plugins/plan-interview/CHANGELOG.md#130---2026-02-26) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/commands/review-rename-plans.md` | Command definition — review-rename-plans | Created |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 1.2.0 → 1.3.0 | Modified |

## How it works

The command resolves its target using a priority chain: explicit file argument, explicit directory argument, `plansDirectory` from `.claude/settings.json`, or the fallback `docs/plans/` relative to `$PWD`. For a directory target it scans all `.md` files.

For each file the command reads enough content to summarize the plan's purpose, then evaluates the filename and H1 heading. The same heuristics as the plan-interview Step 2 name validation apply — context-based judgement rather than regex, with the same key distinction: `add-dark-mode-toggle` passes (words relate to content) while `fuzzy-swimming-pearl` fails (words have no connection). It produces a summary table of all findings before offering any renames.

Renames use `git mv <old-path> <new-path>` to keep file history intact. In **Rename all** mode, all flagged files are renamed in one pass. In **Pick individually** mode, the user confirms each file and can provide a custom name instead of the suggestion.

## How to use it

```
/plan-interview:review-rename-plans
/plan-interview:review-rename-plans docs/plans/
/plan-interview:review-rename-plans docs/plans/fuzzy-swimming-pearl.md
```

Output example:

```
| File | Issue | Suggested Name |
|------|-------|----------------|
| fuzzy-swimming-pearl.md | Random — unrelated to content | create-skill-reviewer-plugin.md |
| hidden-popping-moonbeam.md | Random — unrelated | add-plan-name-validation-to-interview.md |

Rename: [Rename all] [Pick individually] [Skip]
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-review-rename-plans-command.md](plans/add-review-rename-plans-command.md)
- Changelog: [CHANGELOG §1.3.0](../kit/plugins/plan-interview/CHANGELOG.md#130---2026-02-26)
