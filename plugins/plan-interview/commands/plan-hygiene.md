---
description: Scan plan directories for randomly-named files and rename them to descriptive kebab-case names based on content headings
allowed-tools:
  - Glob
  - Read
  - Bash
  - AskUserQuestion
argument-hint: "[directory-path] (optional, uses plansDirectory setting by default)"
---

# Plan File Hygiene

Scan plan directories for files with random non-descriptive names and rename them to descriptive kebab-case names derived from their content headings.

## Directories to Scan

1. **Primary**: Read `plansDirectory` from `.claude/settings.json` (e.g., `docs/planning`)
2. **Additional**: Also scan `openspec/plans/` and `project-docs/06-implementation-plans/`
3. **Override**: If `$ARGUMENTS` is provided, scan only that directory instead

## Random Name Detection

A filename (without `.md`) is "random" if ALL are true:
- Has exactly 2-3 hyphens (3-4 words like `precious-knitting-tulip`)
- Does NOT start with a number
- None of the words are software terms: `fix`, `add`, `refactor`, `implement`, `update`, `create`, `remove`, `delete`, `migrate`, `test`, `review`, `configure`, `optimize`, `debug`, `setup`, `build`, `rename`, `extract`, `revert`, `enable`, `disable`, `pr`, `api`, `ui`, `css`, `auth`, `db`, `nav`, `form`, `crud`, `order`, `event`, `client`, `product`, `modal`, `dialog`, `table`, `page`, `route`, `schema`, `role`, `layout`, `style`, `config`, `hook`, `middleware`, `service`, `component`, `wrapper`, `list`, `view`, `edit`, `index`, `plan`, `spec`, `feature`, `bug`, `chore`, `docs`, `release`, `security`, `performance`, `plugin`, `agent`, `skill`, `command`, `workflow`, `deploy`, `npm`, `git`, `code`

If none found, report "All plan files have descriptive names." and stop.

## Name Generation

1. Read first 10 lines of each detected file
2. Extract first `# Plan: ...` or `# ...` heading
3. Convert to kebab-case: lowercase, spaces to hyphens, strip special chars, collapse hyphens, max 60 chars at word boundary, append `.md`
4. If name exists, append `-v2` (increment as needed)
5. No heading found? Skip file, note in output

## Approval Flow

**IMPORTANT: ALWAYS ask the user for permission before performing any renames. Never rename files automatically.**

1. Present a markdown table of proposals:

```
| # | Directory | Current Name | Proposed Name |
|---|-----------|-------------|---------------|
| 1 | docs/planning/ | fancy-forging-flamingo.md | add-insights-guardrails-to-claude-md.md |
```

2. Use AskUserQuestion with options: "Rename all", "Select specific", "Cancel".
3. If the user selects "Cancel", stop immediately without making any changes.
4. If the user selects "Select specific", ask which files to rename before proceeding.
5. Do NOT proceed to execution without explicit user approval.

## Execution

Only after receiving explicit user approval:

1. `git mv [old] [new]` for each approved rename (fallback: `mv` + `git add`)
2. Commit: `chore: rename plan files to descriptive conventions`
3. Display summary table with status per file
4. If all fail, do NOT commit

## Examples

```
/plan-hygiene                    # Scans plansDirectory + additional dirs
/plan-hygiene docs/planning      # Scans only docs/planning
/plan-hygiene openspec/plans     # Scans only openspec/plans
```
