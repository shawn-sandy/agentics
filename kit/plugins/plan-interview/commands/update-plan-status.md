---
description: Process multiple plan files in a directory — analyze codebase evidence and add/update YAML frontmatter in bulk with summary-first approval
argument-hint: "[directory-path] [--force] — omit directory to use plansDirectory setting; --force re-analyzes files with existing status"
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite
---

# Update Plan Status

Process multiple plan files in a directory — analyze codebase evidence for
each file and add/update YAML frontmatter in bulk. Uses a summary-first,
bulk-approval UX instead of per-file confirmation.

## Instructions

### Step 0 — Create progress todos

Before doing anything else, use `TodoWrite` to create todos for each step:

- Step 1: Resolve directory and discover files
- Step 2: Triage files into processing groups
- Step 3: Get git dates (batch)
- Step 4: Analyze codebase evidence (batch)
- Step 5: Type classification (batch)
- Step 6: Present summary and get approval
- Step 7: Write frontmatter

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve directory and discover files

Resolve which directory to scan using this priority order:

1. **Argument**: If `$ARGUMENTS` contains a directory path (not `--force`),
   use it.
2. **Project-level config**: Read `.claude/settings.json`. If a
   `"plansDirectory"` key exists, use that path.
3. **Global config**: Read `~/.claude/settings.json`. Same logic as above.
4. **Default fallback**: Use `docs/plans/` relative to `$PWD`.

Also check `$ARGUMENTS` for the `--force` flag. When present, re-analyze all
files including those with existing `status` fields.

Glob all `*.md` files in the resolved directory. Announce:
`"Found N plan files in [directory]"`

If zero files found, tell the user and stop.

### Step 2 — Triage files into groups

Read the first 10 lines of each file to check for YAML frontmatter. Classify
every file into one of six groups:

| Group | Condition | Default action |
|-------|-----------|----------------|
| A | No frontmatter | Analyze and add frontmatter |
| B | Frontmatter, no `status` field | Analyze and add `status` |
| C | `status: todo` or `status: in-progress` | Skip (unless `--force`) |
| D | `status: completed` | Skip (unless `--force`) |
| E | `status: draft` | Skip (unless `--force`) |
| F | Non-canonical `status` or `type` value | Always process — normalize |

**Group F detection:** A file belongs to Group F if its frontmatter contains:

- A non-canonical `status` value (anything other than `todo`,
  `in-progress`, `completed`, `draft`). Common legacy values:
  - `implemented` → normalize to `completed`
  - `ready` → normalize to `in-progress`
  - `proposed` → normalize to `draft`
  - `artifact` → normalize to `completed`
- A non-canonical `type` value (`standard` or `artifact`). These legacy
  lifecycle values are replaced with inferred content types in Step 5.

Present a triage summary:

```
Plan file triage (N files in docs/plans/):

  Group                       Count  Action
  ──────────────────────────  ─────  ──────────────────────────────────
  A  No frontmatter              80  Will analyze + add frontmatter
  B  Frontmatter, no status       1  Will analyze + add status
  C  Has status (todo/wip)        0  Skip (use --force to re-analyze)
  D  Completed                    3  Skip (use --force to re-analyze)
  E  Draft                        0  Skip (use --force to re-analyze)
  F  Non-canonical values         3  Will normalize status/type

  Processing: 84 files
  Skipping:    3 files
```

Then ask via `AskUserQuestion`:

> "Proceed with analyzing N files? No files will be modified until you
> approve the results."

Options: "Yes, proceed" / "Cancel"

If cancelled, stop.

### Step 3 — Get git dates (batch)

Run git date commands for all files in the processing set using a single
Bash shell loop (not one call per file):

```bash
for f in file1.md file2.md ...; do
  created=$(git log --follow --diff-filter=A --format="%cd" --date=short -- "$f" 2>/dev/null | tail -1)
  modified=$(git log -1 --format="%cd" --date=short -- "$f" 2>/dev/null)
  echo "$f|${created}|${modified}"
done
```

Apply the same rules as single-file plan-status:

- If `created` is empty (file not tracked by git), use today's date
- If `modified` equals `created`, treat `modified` as absent (omit from
  frontmatter)

Store all results in memory for use in Steps 5–7.

### Step 4 — Analyze codebase evidence (batch)

For each file in the processing set:

1. Read the file content.
2. Extract inline backtick tokens from the plan body. Skip all content inside
   fenced code blocks (anything between ` ``` ` delimiters).

**Stricter token filter (batch-specific):** Unlike single-file `plan-status`,
batch mode uses a tighter filter to avoid noisy scores across many files:

- **Include** file paths with project-relevant prefixes (`plugins/`, `src/`,
  `.claude/`, `docs/`, `tests/`) or known code extensions (`.ts`, `.tsx`,
  `.md`, `.json`, `.py`, `.js`, `.css`, `.scss`)
- **Include** identifiers in PascalCase or camelCase longer than 3 characters
- **Exclude** version strings (e.g., `"1.0.0"`, `1.2.3`)
- **Exclude** JSON value fragments (e.g., `"license": "MIT"`)
- **Exclude** API routes (e.g., `GET /api/...`, `DELETE /api/...`)
- **Exclude** git refs (e.g., `HEAD~1`, `origin/main`)
- **Exclude** whitespace, punctuation-only tokens, and single generic words

3. For each qualifying token, check:
   - `Glob` to test whether it matches an existing file path
   - `Grep` to test whether it appears as an identifier in the codebase

4. Score the results:
   - 0% of tokens found → status = `todo`
   - 1–79% of tokens found → status = `in-progress`
   - 80%+ of tokens found → status = `completed`

**Zero-signal files (batch-specific):** If a file has no qualifying tokens
after filtering, assign provisional status `todo` and flag as `no signals`.
Do NOT prompt per-file — the user can override in Step 6.

### Step 5 — Type classification (batch)

Run this step for all files that scored `completed` in Step 4, all Group F
files with normalized status `completed`, and any file being re-analyzed via
`--force` that has `status: completed`.

Infer content type from the plan's filename, H1 heading, and first 200 words
of body text. Apply the first matching rule:

| Signal | Inferred type |
|--------|---------------|
| Filename starts with `fix-`, `bugfix-`, or H1/body contains "bug", "fix", "patch", "regression" | `fix` |
| Filename starts with `refactor-`, `restructure-`, `simplify-`, or H1/body contains "refactor", "restructure", "simplify", "reorganize" | `refactor` |
| Filename starts with `document-`, `add-docs-`, `update-readme-`, or H1/body contains "documentation", "readme", "guide", "changelog" | `docs` |
| Filename starts with `bump-`, `rename-`, `update-version-`, `cleanup-`, or H1/body contains "chore", "housekeeping", "version bump", "dependency", "rename" | `chore` |
| Default (no strong signal or filename starts with `add-`, `create-`, `implement-`, `build-`) | `feature` |

**Handling existing non-canonical type values:** If a file already has
`type: standard` or `type: artifact` (legacy lifecycle values from Group F),
always re-infer the content type using the rules above — do not preserve the
legacy value.

If a file already has a valid content type (`feature`, `fix`, `refactor`,
`docs`, `chore`) and is not in Group F, keep it and skip (unless `--force`).

All type assignments are overridable in Step 6.

### Step 6 — Present summary and get approval

Output a results table:

```
Batch Status Analysis — 83 files processed

 #  File                                  Status        Type      Tokens  Evidence  Created     Modified    Flags
──  ────────────────────────────────────  ────────────  ────────  ──────  ────────  ──────────  ──────────  ────────────
 1  add-allowed-tools-recommendation.md   completed     feature   8/8     100%      2026-03-26  —
 2  add-argument-support.md               in-progress   —         3/7     43%       2026-02-15  2026-03-01
 3  implement-marketplace-api.md          todo          —         0/5     0%        2026-01-20  —
 4  document-plugin-version-bump.md       completed     docs      5/5     100%      2026-03-15  —           docs plan
 5  fix-login-redirect.md                 completed     fix       6/6     100%      2026-01-10  —
 6  bump-marketplace-version.md           completed     chore     4/4     100%      2026-02-20  —           normalized
...
```

**Flags:**

- `no signals` — no qualifying tokens found after filtering; defaulted to
  `todo`
- `docs plan` — plan title contains "document", "readme", "guide", "enhance",
  or similar documentation terms; token-based scoring may be inaccurate —
  review recommended
- `normalized` — status or type was non-canonical and has been normalized
  (Group F). Shows the old → new mapping in the details.

After the table, output aggregated stats:

```
Summary:
  completed:    52 files (32 feature, 8 fix, 5 chore, 4 docs, 3 refactor)
  in-progress:  18 files
  todo:         11 files (6 no-signals)
  draft:         2 files
  Total:        83 files

Flags:
  normalized (Group F):        3 files
  docs plan (review):          6 files
  no signals (defaulted todo): 6 files
```

Ask via `AskUserQuestion`:

> "How would you like to proceed?"

Options:
- "Write all" — apply frontmatter as shown
- "Override some, then write" — review specific groups before writing
- "Export only" — output results table, no file writes
- "Cancel"

**If "Override some, then write":**

Ask: "Which group would you like to override?"

Options:
- "Normalized" — review plans whose status or type was auto-normalized
  (Group F); confirm or override each
- "Type mismatches" — review plans whose inferred content type may be wrong;
  set each to `feature`, `fix`, `refactor`, `docs`, or `chore`
- "Review-flagged" — review plans with `docs plan` flag; set status manually
- "No-signals" — set status for all zero-signal files at once
- "Specific files" — enter file numbers from the table above

For group overrides, ask one question per group covering all flagged files.
For specific-file overrides, ask for the number(s) and the desired status
(and type, if completed).

After all overrides are collected, confirm the final count before writing:

> "Ready to write frontmatter to N files. Confirm?"

### Step 7 — Write frontmatter

Only on user confirmation.

Apply the same field rules as single-file `plan-status`:

- Include `type` only when `status` is `completed`. Valid content type values:
  `feature`, `fix`, `refactor`, `docs`, `chore`. Omit `type` for `todo`,
  `in-progress`, and `draft`.
- Omit `modified` if it equals `created`.
- Preserve all other existing frontmatter fields exactly as-is.
- When normalizing Group F files:
  - Non-canonical `status` values: write the canonical equivalent
    (`implemented` → `completed`, `ready` → `in-progress`,
    `proposed` → `draft`, `artifact` → `completed`).
  - Non-canonical `type` values (`standard`, `artifact`): replace with
    the inferred content type from Step 5.

**Hybrid write strategy:**

- Files **without** existing frontmatter: use `Bash` to prepend the YAML
  block. Run all inserts in a single shell loop:

  ```bash
  insert_frontmatter() {
    local file="$1" header="$2"
    { printf '%s\n\n' "$header"; cat "$file"; } > "$file.tmp" && mv "$file.tmp" "$file"
    echo "Updated: $file"
  }

  insert_frontmatter "docs/plans/file1.md" "---
  status: todo
  created: 2026-01-15
  ---"

  insert_frontmatter "docs/plans/file2.md" "---
  status: completed
  type: feature
  created: 2026-03-01
  ---"
  # ... one call per file
  ```

- Files **with** existing frontmatter: use `Edit` tool to update/add only the
  `status`, `type` (when completed), `created`, and `modified` fields.
  Preserve all other fields.

Output a progress message every 10 files. Final summary:

```
Batch status complete:
  81 files updated
   0 files skipped
   0 errors
```

After writing, confirm: `"Batch frontmatter update complete."`

## Examples

```
/plan-interview:update-plan-status                          # uses plansDirectory setting or docs/plans/
/plan-interview:update-plan-status docs/plans/              # specific directory
/plan-interview:update-plan-status ~/.claude/plans/         # absolute path
/plan-interview:update-plan-status docs/plans/ --force      # re-analyze files with existing status
```
