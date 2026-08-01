# Gather evidence from the plan, the codebase, and git

Loaded once the plan passes the preconditions gate. Covers Steps 3 through 7 —
parsing the plan, deriving the slug, inspecting shipped files, collecting git
history, and checking the target doc.

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

  Examples: `` `kit/plugins/plan-agent/SKILL.md` ``, `` `plan-status` ``,
  `` `documenting-plans` ``

Also extract any explicit file lists from `## Files to Create` and
`## Files to Modify` sections — these supplement the backtick token set.

### Step 4 — Derive output slug

Slug = plan filename without the `.md` extension, verbatim.

Example: `docs/plans/add-documenting-plans-skill-to-plan-agent.md` → slug
`add-documenting-plans-skill-to-plan-agent` → output
`docs/add-documenting-plans-skill-to-plan-agent.md`.

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
