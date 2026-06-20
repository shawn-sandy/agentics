---
name: documenting-plans
description: "Generates a prose reference doc from a completed plan. Inspects the codebase and git history to produce accurate, evidence-backed documentation. Use when the user asks to document a completed plan."
allowed-tools: Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite, Skill
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
disable-model-invocation: true
---

# Documenting Plans

Generate a developer-friendly prose document at `docs/<slug>.md` from a
completed plan file, reflecting what actually shipped by inspecting the codebase
and git history.

Follow these steps exactly.

## When not to use

Only runs on completed plans that are 30+ days old (based on `created` or
`modified` date in frontmatter). Use plan-status to set status before running.
Use plan-interview to stress-test the plan first, or review-rename-plans to
rename the plan file.

## Table of Contents

- [Step 0 — Create progress todos](#step-0--create-progress-todos)
- [Step 1 — Resolve plan file](#step-1--resolve-plan-file)
- [Step 2 — Ensure plan is completed and old enough](#step-2--ensure-plan-is-completed-and-old-enough)
- [Step 3 — Parse plan content](#step-3--parse-plan-content)
- [Step 4 — Derive output slug](#step-4--derive-output-slug)
- [Step 5 — Inspect shipped files](#step-5--inspect-shipped-files)
- [Step 6 — Collect git history](#step-6--collect-git-history)
- [Step 7 — Check target doc](#step-7--check-target-doc)
- [Step 8 — Synthesize and write the doc](#step-8--synthesize-and-write-the-doc)
- [Step 9 — Report](#step-9--report)

## Instructions

### Step 0 — Create progress todos

Before doing anything else, use `TodoWrite` to create todos for each step:

- Step 1: Resolve plan file
- Step 2: Ensure plan is completed
- Step 3: Parse plan content
- Step 4: Derive output slug
- Step 5: Inspect shipped files
- Step 6: Collect git history
- Step 7: Check target doc
- Step 8: Synthesize and write
- Step 9: Report

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve plan file

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
4. **Default fallback**: Glob `${PWD}/docs/plans/*.md`, sort by modification time,
   use the most recently modified file.

If no file is found via any method, tell the user and stop.

Announce the resolved file: `"Documenting plan: path/to/plan.md"`

### Step 2 — Ensure plan is completed and old enough

Read the plan file's YAML frontmatter — extract the YAML block between the
opening `---` and closing `---` delimiters. If the file has no frontmatter
delimiters, treat both `status` and dates as absent.

**Status check:**

- If `status: completed` (lowercase, exact match) is present, proceed to the
  age check below.
- If `status` is absent or any other value, tell the user:

  > "Plan status is `<value>`. Running plan-status first to verify completion."

  Then invoke the `plan-interview:plan-status` skill via the `Skill` tool,
  passing the resolved plan path as the argument. Wait for it to complete.

  After `plan-status` finishes, re-read the plan file's frontmatter.
  - If `status: completed`, proceed to the age check below.
  - If still not `completed`, stop and tell the user:

    > "Plan not yet completed (status: `<x>`). Documentation should only be
    > generated for completed plans. Run `plan-interview` or continue
    > implementation first."

**Age check (only reached when status is `completed`):**

Compute the plan's age using the `modified` date if present, otherwise
`created`. If neither date is in frontmatter, use `git log -1 --format="%cd" --date=short`
on the file.

- If the plan is 30+ days old, continue to Step 3.
- If the plan is less than 30 days old, stop and tell the user:

  > "This plan was completed recently (`<date>`). `documenting-plans` only
  > generates documentation for plans that are 30+ days old — giving time for
  > follow-up changes to settle. The plan will become eligible on `<date + 30d>`."

### Step 3 — Parse plan content

Read the plan file and extract:

- **H1 title**: first line matching `# ...` — strip leading `# ` and any `Plan:`
  prefix.
- **Frontmatter fields**: `created`, `modified`, `status`, `type`.
- **Body sections** (by `##` heading): `Context`, `Summary`, `Objective`,
  `Steps` (with nested `*Why:*` rationale lines), `Files to Create`,
  `Files to Modify`, `Next Steps`.
- **Backtick tokens**: extract inline backtick-wrapped tokens only — do not scan
  fenced code blocks (anything between ` ``` ` delimiters). Keep tokens that
  look like:
  - File paths: contain `/` or end in a known extension (`.ts`, `.tsx`, `.md`,
    `.json`, `.py`, `.js`, `.css`, `.scss`)
  - Named identifiers: PascalCase, camelCase, or kebab-case words matching
    command/skill naming patterns

  Examples: `` `kit/plugins/plan-interview/SKILL.md` ``, `` `plan-status` ``,
  `` `documenting-plans` ``

Also extract any explicit file lists from `## Files to Create` and
`## Files to Modify` sections — these supplement the backtick token set.

### Step 4 — Derive output slug

Slug = plan filename without the `.md` extension, verbatim.

Example: `docs/plans/add-documenting-plans-skill-to-plan-interview.md` → slug
`add-documenting-plans-skill-to-plan-interview` → output
`docs/add-documenting-plans-skill-to-plan-interview.md`.

Confirm via `AskUserQuestion`:

> "Generated doc will be written to `docs/<slug>.md`. Accept, or provide a
> different slug?"

Options: `Accept (docs/<slug>.md)`, `Rename (enter custom slug)`.

If the user chooses Rename, ask for the custom slug and use it for the remainder
of this run.

### Step 5 — Inspect shipped files

For each file-path token collected in Step 3:

1. Use `Glob` with the token as pattern to test whether the file exists at its
   planned path.
2. If not found, use `Grep` with the basename (filename without directory) to
   locate where it may have moved. Record the new path if found.
3. Use `Read` to read the first ~150 lines of each resolved file. Capture:
   - YAML frontmatter fields for `.md` skills/commands (`name`, `description`,
     `allowed-tools`, `argument-hint`)
   - Exported function and type names for `.ts`/`.js` files
   - Component name and primary props for `.tsx`/`.jsx` files
4. Build a file index entry for each token:

   ```
   { planned_path, actual_path, status, kind, exported_surface }
   ```

   Where `status` is one of: `Created`, `Modified`, `Relocated`, `Missing`.

For named identifier tokens (not file paths), use `Grep` to confirm they exist
in the codebase. Note the file(s) where they appear.

### Step 6 — Collect git history

Determine the time window from the plan frontmatter:

- `since` = `created` date from frontmatter, or fall back to:
  ```bash
  git log --follow --diff-filter=A --format="%cd" --date=short -- <plan-file> | tail -1
  ```
- `until` = `modified` date from frontmatter, or today's date if absent.

Collect commits touching the plan file and all resolved file paths from Step 5:

```bash
git log --since=<since> --until=<until> \
  --format="%h %ad %s" --date=short \
  -- <plan-file> <file1> <file2> ...
```

Cap at 20 most recent commits. If the result is empty (window too narrow or
dates inaccurate), re-run without `--since`/`--until` against the same
pathspecs, capped at 20.

Also collect the shipped date (last commit touching the plan file):

```bash
git log -1 --format="%cd" --date=short -- <plan-file>
```

### Step 7 — Check target doc

Check whether `docs/<slug>.md` already exists using `Glob`.

If it exists:

- `Read` the existing file.
- Ask via `AskUserQuestion`:

  > "`docs/<slug>.md` already exists. How should we proceed?"

  Options:
  - `Overwrite` — replace the entire file with a fresh generated doc.
  - `Refresh` — regenerate only the content between `<!-- generated:start -->`
    and `<!-- generated:end -->` markers; preserve all text outside the markers.
  - `Cancel` — stop without writing anything.

  If the user selects **Refresh** but the existing file has no markers, treat it
  as Overwrite.

If the file does not exist, proceed directly to Step 8.

### Step 8 — Synthesize and write the doc

Compose the document using the template below and write it via `Write` (new
file) or `Edit` (refresh mode — replace only between the markers).

**Dynamic plan link**: compute the plan link as a relative path from
`docs/<slug>.md` to the resolved plan file. Do not hardcode `./plans/`. For
example, if the plan is at `docs/plans/my-plan.md` and the output is at
`docs/my-plan.md`, the relative link is `plans/my-plan.md`. If the plan is at
`~/.claude/plans/my-plan.md`, use an absolute path or note it in the References
section.

**CHANGELOG citation**: if the plan references a plugin with a `CHANGELOG.md`,
locate the entry that corresponds to the shipped feature (by version or date)
and link to it from the "What shipped" section. Do not reproduce CHANGELOG text
verbatim — cite and link instead.

---

**Document template:**

```markdown
# <H1 title with "Plan:" prefix removed>

> <One-line summary — first sentence of Context / Summary / Objective, trimmed
> to ~160 characters.>

<!-- generated:start -->

**Status:** Shipped <YYYY-MM-DD> **Plan:** [<plan-filename>](relative-plan-link)
**Type:** <type or "feature">

## What shipped

<Bulleted list distilled from the plan's Objective and ## Steps, rewritten in
past tense. One bullet per major capability. Where a Step includes a _Why:_
rationale, fold it into the bullet as a brief parenthetical.>

<If a CHANGELOG entry exists for this feature, add a citation footer:>

> See [CHANGELOG v<version>](<relative-path-to-CHANGELOG.md>#<anchor>) for the
> authoritative feature list.

## Files changed

| Path              | Role            | Status  |
| ----------------- | --------------- | ------- |
| `path/to/file.md` | <inferred role> | Created |

<Populate from the Step 5 file index. Role is inferred from file kind and
exported surface (e.g., "Skill instructions", "Command wrapper", "Marketplace
entry"). Status: Created / Modified / Relocated / Missing.>

## How it works

<3–8 short paragraphs, one per plan Step, rewritten as a walk-through that
references the actual code paths from Step 5. Where plan Steps mention a "Why:"
rationale, fold it into the prose. Where actual code diverged from the plan,
note the divergence briefly. Use inline backticks for every file path and
identifier.>

## How to use it

<Include this section ONLY when user-facing surface exists — commands, skills,
public APIs, or components. Omit entirely for internal refactors, chores, and
infrastructure changes with no user-visible interface.>

<For skills: show the activation trigger (description field text), plus the
companion command if one exists.>

<For commands: show the invocation syntax, argument-hint, and 2–3 example
calls.>

<For library code: show the import path, primary exported symbol, and a minimal
usage example (if one exists in plan or code).>

## Commit history

| SHA       | Date       | Subject                                              |
| --------- | ---------- | ---------------------------------------------------- |
| `abc1234` | 2026-03-29 | feat(plan-interview): add update-plan-status command |

<Populate from Step 6 git log output. Up to 20 rows. If result was capped at 20,
append: "_Showing 20 of N commits — run `git log` for the full history._">

<!-- generated:end -->

## References

- Plan: [<plan-filename>](relative-plan-link)
- Related docs: <links to other docs/\*.md files discovered via Grep on
  keywords/slug, if any>
- Changelog: <link to plugin CHANGELOG entry if applicable>
```

---

After writing, confirm: `"Written to docs/<slug>.md"`

### Step 9 — Report

Output a summary table:

```text
| Field          | Value                                    |
|----------------|------------------------------------------|
| Output         | docs/<slug>.md                           |
| Plan           | docs/plans/<plan-file>.md                |
| Shipped date   | 2026-03-29                               |
| Files indexed  | 5 (4 found, 1 missing)                   |
| Commits        | 12 in window (2026-01-15 – 2026-03-29)   |
```

## Examples

```
/plan-interview:documenting-plans                                              # auto-detects from IDE or settings
/plan-interview:documenting-plans docs/plans/add-branch-agent-skill.md        # specific plan file
/plan-interview:documenting-plans ~/.claude/plans/my-feature.md               # absolute path
```
