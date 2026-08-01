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

### Step 1 — Resolve plan file (or route to bulk mode)

**Bulk-mode routing:** If `$ARGUMENTS` names a directory, or contains `--all`,
follow [Bulk mode](references/bulk-mode.md) instead of the single-file
steps below. Otherwise continue with the single-file priority order.

Use the first match from this priority order:

1. **Argument**: If a file path appears in `$ARGUMENTS` or the user's message,
   use it directly.
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

- If the existing `status` is `artifact` (legacy format), inform the user:
  _"This plan uses the legacy `artifact` status. It will be normalized to
  `status: completed`."_ Treat the status as `completed` for the remainder of
  the flow and continue to Step 5 so the content type is classified.
- If a `status` field already exists (and is not the legacy `artifact`),
  surface the current value to the user and
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

Examples of tokens to extract: `` `plugins/plan-agent/SKILL.md` ``,
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
