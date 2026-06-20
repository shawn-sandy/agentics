---
description: Review plan filenames and offer to rename files whose names don't match their intent
argument-hint: [plan-file-or-directory] - omit to scan docs/plans/ or configured plansDirectory
allowed-tools: Read, Glob, Bash, Edit, AskUserQuestion, TodoWrite, Skill
---

# /plan-interview:review-rename-plans

Review plan files and rename any whose filename doesn't match the plan's intent.

## Usage

```
/plan-interview:review-rename-plans                          # scan project plans directory
/plan-interview:review-rename-plans docs/plans/my-plan.md    # review a single file
/plan-interview:review-rename-plans docs/plans/              # scan a specific directory
```

## Instructions

### Step 1 — Resolve the target

Determine what to review based on `$ARGUMENTS`:

1. **Specific file**: If `$ARGUMENTS` points to a `.md` file, review that single file.
2. **Specific directory**: If `$ARGUMENTS` points to a directory, glob `*.md` files from it.
3. **No argument — settings `plansDirectory`**: Read the `"plansDirectory"` key following Claude Code's settings precedence — project-local `.claude/settings.local.json`, then project `.claude/settings.json`, then global `~/.claude/settings.json`. If set, glob `*.md` files from that path.
4. **No argument — fallback**: Glob `*.md` files from `${PWD}/docs/plans/`.

If no plan files are found via any method, tell the user and stop.

Tell the user how many plan files were found and where (e.g., "Found 12 plan files in `docs/plans/`").

### Step 2 — Review each plan file

For each plan file, perform this analysis:

1. **Extract identifiers**:
   - Filename without path or `.md` extension
   - H1 heading (first line matching `# ...`)

2. **Determine the plan's purpose**: Read enough of the file to form a one-sentence summary of what it intends to accomplish.

3. **Evaluate the filename** against these criteria:
   - **Descriptive**: Contains words that relate to the plan's goal or content.
     Good: `create-skill-reviewer-plugin`, `fix-marketplace-json-location`.
     Bad: `fuzzy-swimming-pearl`, `hidden-popping-moonbeam`.
   - **Not random**: Does not follow a random adjective-noun or adjective-verb-noun pattern with no connection to the plan's subject matter.
     Note: `add-dark-mode-toggle` is descriptive even though it contains adjectives — the key test is whether the words relate to the plan content.
   - **Not too generic**: Not a placeholder like `plan.md`, `untitled.md`, `draft.md`, `temp.md`, or `new-plan.md`.
   - **Verb-led**: Starts with an imperative verb. Good: `add-dark-mode-toggle`,
     `fix-auth-redirect`, `create-skill-reviewer-plugin`. Bad:
     `branch-agent-append-date-suffix` (noun-led), `auth-module-changes`
     (noun-led). Common verbs: `add`, `fix`, `create`, `build`, `implement`,
     `update`, `refactor`, `migrate`, `configure`, `remove`, `enable`,
     `disable`, `move`, `rename`, `extract`, `deploy`, `document`, `integrate`.

4. **Evaluate the H1 heading**:
   - Does an H1 heading exist?
   - Does it describe the plan's purpose?
     Good: `# Plan: Create 'skill-reviewer' Plugin`.
     Bad: `# Plan` alone, or missing entirely.
   - Does it align with the filename? Flag misalignment only when the filename and heading refer to entirely different topics — not when they describe the same topic at different scopes.

5. **Record the result** as one of:
   - **Pass**: Both filename and heading are descriptive and aligned.
   - **Needs attention**: One or both are non-descriptive, generic, or misaligned. Record:
     - Which element(s) failed (filename, heading, or both)
     - Why (random pattern, too generic, misaligned, not verb-led, or missing)
     - A **suggested filename** in kebab-case derived from the plan's goal — must
       start with an imperative verb (e.g., `add-`, `fix-`, `create-`)
     - A **suggested H1 heading** in `# Plan: [Description]` format

### Step 3 — Present the review summary

After reviewing all files, present findings in two groups:

**Files that pass** — show a brief count (e.g., "9 of 12 plans have descriptive names").

**Files that need attention** — show a detailed table:

```markdown
## Plan Name Review

**X of Y plans need attention:**

| # | Current Filename | Issue | Suggested Name |
|---|------------------|-------|----------------|
| 1 | `fuzzy-swimming-pearl.md` | Random — unrelated to content | `create-skill-reviewer-plugin.md` |
| 2 | `plan.md` | Too generic | `refactor-auth-module.md` |
| 3 | `fix-bug.md` | Heading misaligned with content | `fix-login-redirect-loop.md` |
```

If all files pass, congratulate the user and stop.

### Step 4 — Offer to rename

If any files need attention, ask the user via `AskUserQuestion`:

*"Would you like me to rename the flagged plan files to the suggested names?"*

Options:
- **Rename all** — rename all flagged files
- **Pick individually** — go through each file one at a time
- **Skip** — leave everything as-is

**If "Rename all"**: For each flagged file, use Bash `git mv` to rename (preserving git history). If the H1 heading was also flagged, update it using `Edit`.

**If "Pick individually"**: For each flagged file, ask via `AskUserQuestion` whether to rename it, showing the current and suggested name. Include an option to provide a custom name. Rename confirmed files using `git mv` and update headings with `Edit` as needed.

**If "Skip"**: End without changes.

After renaming, show a summary of what was changed:

```markdown
## Renames Applied

| Original | New Name |
|----------|----------|
| `fuzzy-swimming-pearl.md` | `create-skill-reviewer-plugin.md` |
| `plan.md` | `refactor-auth-module.md` |
```

### Step 5 — Generate HTML for renamed files

After the "Renames Applied" summary, automatically generate an HTML view for
every file that was successfully renamed.

**5a — Migrate stale HTML artifacts**

For each renamed file, check whether `<old-basename>.html` exists in the same
directory:

```bash
# example: old path was docs/plans/fuzzy-swimming-pearl.md
ls docs/plans/fuzzy-swimming-pearl.html 2>/dev/null
```

If the stale `.html` exists, rename it to match the new basename using
`git mv` to preserve history:

```bash
git mv docs/plans/fuzzy-swimming-pearl.html docs/plans/create-skill-reviewer-plugin.html
```

Fallback if `git mv` fails (file not tracked): `mv` the file then `git add` the
new path and `git rm` the old path.

**5b — Choose theme once**

Ask the user once via `AskUserQuestion` which theme to apply to all regenerated
HTML files:

- **Default** — neutral grays and white, blue accent
- **Developer** — dark charcoal header, green accent (terminal-inspired)
- **Document** — warm off-white background, sepia/brown accent
- **Minimal** — pure white background, black text, no accent color

**5c — Generate HTML per renamed file**

For each renamed file, invoke the `markdown-to-html` skill, passing the new path,
the chosen theme, and `--background` to suppress all prompts (overwrite, browser open):

```
Skill(skill: "plan-interview:markdown-to-html", args: "<new-path> --theme=<chosen> --background --mode=plan")
```

**5d — Report HTML output**

After all invocations complete, append an "HTML Generated" section to the
summary:

```markdown
## HTML Generated

| Plan File | HTML Output | Theme |
|-----------|-------------|-------|
| `create-skill-reviewer-plugin.md` | `create-skill-reviewer-plugin.html` | developer |
| `refactor-auth-module.md` | `refactor-auth-module.html` | developer |
```

---

Arguments: $ARGUMENTS
