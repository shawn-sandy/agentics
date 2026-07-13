---
status: completed
type: artifact
created: 2026-02-26
---

# Plan: Add review-rename-plans Command to plan-interview Plugin

## Context

Plan files in `docs/plans/` can accumulate with random or non-descriptive names (e.g., `fuzzy-swimming-pearl.md`) that obscure their purpose. The existing `plan-interview` command already validates plan names during its full interview flow (Step 2), but there is no lightweight, focused way to batch-review plan filenames without running a full interview.

## Goal

Add a new `review-rename-plans` command to the `plan-interview` plugin that:

1. Scans a plans directory (or reviews a single file) for naming issues
2. Evaluates whether each filename is descriptive of its content
3. Checks H1 heading alignment
4. Presents a summary table of findings
5. Offers to rename flagged files using `git mv` (preserving history)

## Changes

### New file

- `plugins/plan-interview/commands/review-rename-plans.md` — command definition with frontmatter, usage docs, and step-by-step instructions

### Modified files

- `plugins/plan-interview/.claude-plugin/plugin.json` — version bump 1.2.0 → 1.3.0
- `.claude-plugin/marketplace.json` — version sync 1.2.0 → 1.3.0
- `plugins/plan-interview/CHANGELOG.md` — new 1.3.0 entry
- `plugins/plan-interview/README.md` — add new command to components table and usage section

## Command behavior

### Resolution priority

1. Explicit file argument → review that single file
2. Explicit directory argument → scan that directory
3. `.claude/settings.json` `plansDirectory` → scan configured path
4. Fallback → scan `docs/plans/` relative to `$PWD`

### Evaluation criteria

- **Descriptive**: filename contains words related to the plan's goal
- **Not random**: not an adjective-noun pattern unrelated to content
- **Not generic**: not `plan.md`, `untitled.md`, `draft.md`, etc.
- **H1 heading**: exists, describes purpose, aligns with filename

### Rename modes

- **Rename all** — batch rename all flagged files
- **Pick individually** — interactive per-file confirmation with custom name option
- **Skip** — leave everything as-is

## Version bump

- Type: MINOR (new command, backward compatible)
- From: 1.2.0
- To: 1.3.0
