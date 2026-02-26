---
description: Review plan files in a directory and rename any whose filenames don't match their intent
argument-hint: "[plans-directory-path] - omit to auto-detect"
allowed-tools: Read, Glob, AskUserQuestion, Bash, Edit, TodoWrite
---

# /plan-interview:review-rename-plans

Batch-review plan filenames in a directory, flag those that don't match their intent, and offer to rename them.

## Usage

```
/plan-interview:review-rename-plans                          # auto-detect plans directory
/plan-interview:review-rename-plans docs/plans               # specific directory
/plan-interview:review-rename-plans ~/.claude/plans           # global plans directory
```

## Instructions

### Step 0 — Create progress todos

Use `TodoWrite` to create todos for each step of this review (all `status: "pending"`):

- Resolve the plans directory
- Scan and evaluate plan filenames
- Present summary of findings
- Rename plans (if any need attention)

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve the plans directory

Find the directory to scan using the first match from this priority order:

1. **Explicit argument**: If `$ARGUMENTS` is provided, treat it as the directory path.
2. **Project `docs/plans/`**: Check whether `docs/plans/` exists in `$PWD`.
3. **Project `.claude/plans/`**: Check whether `.claude/plans/` exists in `$PWD`.
4. **Project settings**: Read `.claude/settings.json` in `$PWD`. If a `"plansDirectory"` key exists, use that path.
5. **Global default**: Fall back to `~/.claude/plans/`.

Once resolved, confirm the directory to the user:

> Reviewing plans in: `[resolved-path]`

If the directory does not exist or contains no `.md` files, tell the user and stop.

### Step 2 — Scan and evaluate plan filenames

Use `Glob` to find all `*.md` files in the resolved directory (non-recursive).

For **each** plan file:

1. **Read the file** using `Read`.

2. **Extract identifiers**:
   - The **filename** (without path or `.md` extension).
   - The **H1 heading** (first line matching `# ...`).

3. **Determine the plan's purpose**: Read enough of the content to form a one-sentence summary of what the plan intends to accomplish.

4. **Evaluate the filename** against these criteria:
   - **Descriptive**: Contains words that relate to the plan's goal or content.
     Good: `create-skill-reviewer-plugin`, `fix-marketplace-json-location`.
     Bad: `fuzzy-swimming-pearl`, `hidden-popping-moonbeam`.
   - **Not random**: Does not follow a random adjective-noun or adjective-verb-noun pattern with no connection to the plan's subject matter.
     Note: `add-dark-mode-toggle` is descriptive even though it contains adjectives — the key test is whether the words relate to the plan content.
   - **Not too generic**: Not a placeholder like `plan.md`, `untitled.md`, `draft.md`, `temp.md`, or `new-plan.md`.

5. **Evaluate the H1 heading**:
   - Does an H1 heading exist?
   - Does it describe the plan's purpose? (Good: `# Plan: Create 'skill-reviewer' Plugin`. Bad: `# Plan` alone, or missing entirely.)
   - Does it align with the filename? Flag misalignment only when the filename and heading refer to entirely different topics — not when they describe the same topic at different scopes.

6. **Classify** the plan as one of:
   - **Pass**: Both filename and heading are descriptive and aligned.
   - **Needs attention**: One or both are non-descriptive, generic, random, or misaligned. Record:
     - Which element(s) failed (filename, heading, or both)
     - Why (random pattern, too generic, misaligned, or missing)
     - A **suggested filename** in kebab-case derived from the plan's actual goal
     - A **suggested H1 heading** in `# Plan: [Description]` format (only if heading needs fixing)

### Step 3 — Present summary of findings

After evaluating all files, present a summary table:

```markdown
## Plan Filename Review

**Directory**: `[resolved-path]`
**Files scanned**: [count]
**Passing**: [count] | **Needs attention**: [count]

### Files Needing Attention

| # | Current Filename | Issue | Suggested Filename |
|---|------------------|-------|--------------------|
| 1 | `fuzzy-swimming-pearl.md` | Random — unrelated to content | `create-skill-reviewer-plugin.md` |
| 2 | `plan.md` | Too generic | `fix-auth-middleware-bug.md` |

### Passing Files

| Current Filename | Summary |
|------------------|---------|
| `create-skill-reviewer-plugin.md` | Creates a plugin for reviewing skills |
| `fix-marketplace-json-location.md` | Fixes marketplace.json path |
```

If **all** files pass, say so and stop:

> All [count] plan files have descriptive filenames. No renames needed.

If files need attention, proceed to Step 4.

### Step 4 — Rename plans interactively

For each plan that needs attention, ask the user via `AskUserQuestion`:

> **[current-filename.md]** — [one-sentence summary of plan intent]
>
> This filename [issue description]. Would you like to rename it?

Provide options:
- **Rename to `[suggested-name].md`** — Accept the suggested name
- **Skip** — Keep the current name
- (The user can also type a custom name via "Other")

If the user confirms a rename (suggested or custom):

1. **Rename the file** using `Bash` with `mv` (use the full paths).
2. **Update the H1 heading** if it was also flagged, using `Edit` to replace the old heading with the suggested one.
3. Report the rename: `Renamed: [old-name].md → [new-name].md`

If the user skips, move to the next file.

After processing all files, present a final summary:

```markdown
## Rename Summary

- **Renamed**: [count] files
- **Skipped**: [count] files

| Action | Old Name | New Name |
|--------|----------|----------|
| Renamed | `fuzzy-swimming-pearl.md` | `create-skill-reviewer-plugin.md` |
| Skipped | `plan.md` | _(kept as-is)_ |
```

---

Arguments: $ARGUMENTS
