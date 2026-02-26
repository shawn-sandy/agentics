# Plan: Add 'review-rename-plans' Command to plan-interview Plugin

## Context

The plan-interview plugin already validates a single plan's filename during an interview (Step 2). However, there is no way to batch-review all plan files in a directory and rename the ones whose filenames don't match their intent. Users accumulate plan files over time — some auto-generated with random names — and need a quick way to audit and fix them.

## Goal

Add a new `review-rename-plans` command to the `plan-interview` plugin that scans a plans directory, evaluates each plan's filename against its content, and offers to rename mismatched files interactively.

## Scope

- **New command file**: `plugins/plan-interview/commands/review-rename-plans.md`
- **Version bump**: 1.2.0 → 1.3.0 (MINOR — new command, backward compatible)
- **Updated files**: `plugin.json`, `marketplace.json`, `CHANGELOG.md`, `README.md`

## Implementation

### Command behavior

1. **Resolve the plans directory** using a priority order:
   - Explicit `$ARGUMENTS` path
   - `docs/plans/` in current project
   - `.claude/plans/` in current project (plansDirectory from settings)
   - `~/.claude/plans/` (global default)

2. **Scan** the directory for `*.md` files

3. **For each plan file**:
   - Read the file content
   - Extract the H1 heading and determine the plan's purpose
   - Evaluate the filename against descriptiveness criteria (same rules as plan-interview Step 2)
   - Classify as **pass** or **needs attention**

4. **Present a summary table** of all plans with their status

5. **For plans needing attention**, offer to rename interactively:
   - Show current name, issue, and suggested name
   - Ask user to confirm each rename
   - Perform the rename (file + H1 heading) on confirmation

### Tools needed

- `Read`, `Glob` — scan and read plan files
- `AskUserQuestion` — confirm renames
- `Bash` — execute `mv` for file renames
- `Edit` — update H1 headings
- `TodoWrite` — track progress

## Version bump

- `plugins/plan-interview/.claude-plugin/plugin.json`: 1.2.0 → 1.3.0
- `.claude-plugin/marketplace.json` plan-interview entry: 1.2.0 → 1.3.0
