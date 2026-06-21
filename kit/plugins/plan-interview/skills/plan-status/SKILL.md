---
name: plan-status
description: "Writes lifecycle status into a plan file's frontmatter. Inspects the codebase and git history to set accurate dates and completion state. Use when the user asks to check or update a plan's status."
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

## Plan Status

Determine whether a plan has been implemented by inspecting the codebase, then
write the lifecycle status and dates into the plan file's YAML frontmatter.

Follow these steps exactly.

## When not to use

Does not stress-test, validate, or critique plan content — use plan-interview for that.

## Table of Contents

- [Step 0 — Create progress todos](#step-0--create-progress-todos)
- [Step 1 — Resolve plan file](#step-1--resolve-plan-file)
- [Step 2 — Get file dates from git](#step-2--get-file-dates-from-git)
- [Step 3 — Read existing frontmatter](#step-3--read-existing-frontmatter)
- [Step 4 — Analyze codebase for implementation evidence](#step-4--analyze-codebase-for-implementation-evidence)
- [Step 5 — Type classification](#step-5--type-classification-only-when-status-resolves-to-completed)
- [Step 6 — Present findings and confirm](#step-6--present-findings-and-confirm)
- [Step 7 — Update plan file frontmatter](#step-7--update-plan-file-frontmatter)

## Instructions

### Step 0 — Create progress todos

Before doing anything else, use `TodoWrite` to create todos for each step:

- Step 1: Resolve plan file
- Step 2: Get file dates from git
- Step 3: Read existing frontmatter
- Step 4: Analyze codebase for implementation evidence
- Step 5: Artifact check (if applicable)
- Step 6: Present findings and confirm
- Step 7: Update plan file frontmatter

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve plan file

Use the first match from this priority order:

1. **User message**: If a file path appears in the user's message, use it
   directly.
2. **Currently open file**: If no path was given, check whether a `.md` file is
   currently open in the IDE. If it looks like a plan (contains headings like
   `## Implementation`, `## Plan`, `## Steps`, `## Context`, or `## Summary`),
   use it.
3. **Settings `plansDirectory`**: Read the `"plansDirectory"` key following
   Claude Code's settings precedence — project-local `.claude/settings.local.json`,
   then project `.claude/settings.json`, then global `~/.claude/settings.json`. Use
   the first that sets it; glob `*.md` files from that path and use the most
   recently modified file.
4. **Default fallback**: Glob `${PWD}/docs/plans/*.md`, sort by modification
   time, use the most recently modified file.

If no file is found via any method, tell the user and stop.

Announce the resolved file: `"Checking plan status: path/to/plan.md"`

### Step 2 — Get file dates from git

Use `Bash` to run git commands. Do not use `stat` — it is not cross-platform.

**Created date** (first in order that succeeds):

```bash
git log --follow --diff-filter=A --format="%cd" --date=short -- <file> | tail -1
```

If the command returns empty (file not tracked by git), use today's date as the
created date.

**Modified date**:

```bash
git log -1 --format="%cd" --date=short -- <file>
```

If the modified date equals the created date, treat `modified` as absent (omit
it from frontmatter).

### Step 3 — Read existing frontmatter

Read the plan file and parse its YAML frontmatter if present.

- If a `status` field already exists, surface the current value to the user and
  ask via `AskUserQuestion`: _"This plan already has status `[value]`. Would
  you like to re-analyze the codebase or keep the current status?"_
  - If the user chooses to keep it, skip Steps 4–5 and go directly to Step 6
    to confirm whether to update the dates.
  - If the user chooses to re-analyze, continue from Step 4.
- If no frontmatter or no `status` field exists, continue from Step 4.

**Type**: Type is classified in **Step 5 only**, and only when status resolves
to `completed`. Do not infer or write `type` during this step.

### Step 4 — Analyze codebase for implementation evidence

**Extract inline backtick tokens only** from the plan body. Do not scan fenced
code block content (anything between ` ``` ` delimiters). Look for tokens that
appear to be:

- File paths: contain `/` or end in a known extension (`.ts`, `.tsx`, `.md`,
  `.json`, `.py`, `.js`, `.css`, `.scss`)
- Named identifiers: PascalCase or camelCase words, kebab-case names that match
  command/skill naming patterns

Examples of tokens to extract: `` `plugins/plan-interview/SKILL.md` ``,
`` `plan-status` ``, `` `FooComponent` ``, `` `commands/plan-status.md` ``

If **no inline backtick tokens** are found in the plan body, skip codebase
analysis entirely. Instead, ask the user via `AskUserQuestion`:

> "No extractable implementation signals found in this plan (no backtick-quoted
> file paths or names). Please set the status manually."

Offer options (default: `todo`): `todo`, `in-progress`, `completed`, `draft`. Use the
user-selected value as the status and proceed to Step 6.

**For each extracted token**, check both:

1. Use `Glob` to test whether it matches an existing file path in the project
2. Use `Grep` to test whether it appears as an identifier in the codebase (for
   named identifiers)

**Score the results:**

- 0% of tokens found → status = `todo`
- 1–79% of tokens found → status = `in-progress`
- 80%+ of tokens found → status = `completed`

### Step 5 — Type classification _(only when status resolves to `completed`)_

Infer content type from the plan's filename, H1 heading, and first 200 words
of body text. Apply the first matching rule:

| Signal | Inferred type |
|--------|---------------|
| Filename starts with `fix-`, `bugfix-`, or H1/body contains "bug", "fix", "patch", "regression" | `fix` |
| Filename starts with `refactor-`, `restructure-`, `simplify-`, or H1/body contains "refactor", "restructure", "simplify" | `refactor` |
| Filename starts with `document-`, `add-docs-`, `update-readme-`, or H1/body contains "documentation", "readme", "guide", "changelog" | `docs` |
| Filename starts with `bump-`, `rename-`, `update-version-`, `cleanup-`, or H1/body contains "chore", "housekeeping", "version bump", "rename" | `chore` |
| Default (no strong signal or filename starts with `add-`, `create-`, `implement-`, `build-`) | `feature` |

If the file already has a valid content type (`feature`, `fix`, `refactor`,
`docs`, `chore`), keep it.

### Step 6 — Present findings and confirm

Output a summary table in the chat:

```text
| Field    | Value                         |
|----------|-------------------------------|
| File     | docs/plans/my-feature.md      |
| Status   | in-progress                   |
| Type     | feature                       |
| Created  | 2026-01-15                    |
| Modified | 2026-03-26                    |
| Evidence | 3/5 tokens found in codebase  |
```

List found tokens (with file or grep match) and missing tokens separately.

Then ask via `AskUserQuestion`:

> "Should I update this plan file's YAML frontmatter with status `[value]`?"

**Do NOT write to the file unless the user confirms.**

### Step 7 — Update plan file frontmatter

Only on user confirmation.

If the file has no existing YAML frontmatter, insert a new block at the very
top of the file:

```yaml
---
status: in-progress
type: feature
created: 2026-01-15
modified: 2026-03-26
---
```

If the file already has YAML frontmatter, update or add only the `status`,
`type`, `created`, and `modified` fields. Preserve all other existing fields
exactly as they are. Never rename or remove existing fields.

Rules:

- Omit `modified` if it equals `created`
- Use `Edit` tool for all file writes
- After writing, confirm to the user: `"Frontmatter updated in path/to/plan.md"`
