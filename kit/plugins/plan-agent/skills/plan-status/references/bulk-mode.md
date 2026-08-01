## Bulk mode (directory / `--all`)

When `$ARGUMENTS` names a directory or contains `--all`, process every `*.md`
plan in that directory in one pass with a summary-first, bulk-approval UX
(instead of per-file confirmation). Resolve the directory as: explicit argument
→ `plansDirectory` setting → `${PWD}/docs/plans/`. `--force` re-analyzes files
that already have a `status`.

Create TodoWrite progress todos, then run:

1. **Discover** — glob `*.md`; announce `"Found N plan files in [dir]"`; stop if zero.
2. **Triage** — read the first 10 lines of each file and bucket it:

   | Group | Condition | Default action |
   |-------|-----------|----------------|
   | A | No frontmatter | Analyze + add frontmatter |
   | B | Frontmatter, no `status` | Analyze + add `status` |
   | C | `status: todo`/`in-progress` | Skip unless `--force` |
   | D | `status: completed` | Skip unless `--force` |
   | E | `status: draft` | Skip unless `--force` |
   | F | Non-canonical `status`/`type` | Always process — normalize |

   Group F normalizes legacy values: `implemented`→`completed`, `ready`→`in-progress`,
   `proposed`→`draft`, `artifact`→`completed`; legacy `type: standard`/`artifact`
   are re-inferred in step 5. Present a triage summary and get bulk approval via
   `AskUserQuestion` ("Proceed / Cancel") before touching anything.
3. **Git dates (batch)** — one shell loop over the processing set applying the
   same date rules as Step 2 (empty created → today; modified == created → omit).
4. **Evidence (batch)** — score each file exactly as Step 4, but with a
   **stricter token filter**: include only paths with project prefixes
   (`plugins/`, `src/`, `.claude/`, `docs/`, `tests/`) or code extensions, and
   PascalCase/camelCase identifiers >3 chars; exclude version strings, JSON value
   fragments, API routes, and git refs. A file with no qualifying tokens gets
   provisional `todo` flagged `no signals` — do not prompt per file.
5. **Type (batch)** — classify completed files with the Step 5 rules; always
   re-infer legacy `type: standard`/`artifact`.
6. **Summary + approval** — output a results table (file, status, type, tokens,
   evidence %, dates, flags) plus aggregated stats. Flags: `no signals`,
   `docs plan` (token scoring may be off), `normalized` (Group F). Ask via
   `AskUserQuestion`: "Write all" / "Override some, then write" / "Export only"
   / "Cancel". For overrides, ask one question per group (normalized, type
   mismatches, review-flagged, no-signals, or specific file numbers), then
   confirm the final count.
7. **Write** — only on confirmation, applying the Step 7 field rules. Hybrid
   write: prepend YAML via a `Bash` loop for files without frontmatter; use
   `Edit` for files that already have it. Emit progress every 10 files and a
   final `updated / skipped / errors` summary.
