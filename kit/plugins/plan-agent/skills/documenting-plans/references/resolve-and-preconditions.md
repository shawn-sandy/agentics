# Resolve the plan and check preconditions

Loaded at the start of a run. Covers Steps 0 through 2 — todos, plan-file
resolution, and the completed-and-30-days-old gate.

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

  Then invoke the `plan-agent:plan-status` skill via the `Skill` tool,
  passing the resolved plan path as the argument. Wait for it to complete.

  After `plan-status` finishes, re-read the plan file's frontmatter.
  - If `status: completed`, proceed to the age check below.
  - If still not `completed`, stop and tell the user:

    > "Plan not yet completed (status: `<x>`). Documentation should only be
    > generated for completed plans. Complete or continue
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
