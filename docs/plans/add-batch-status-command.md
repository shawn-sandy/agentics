# Plan: Add `batch-status` command to plan-interview plugin

## Context

The plan-status skill processes one plan file at a time through an 8-step
interactive workflow (resolve file, analyze codebase, confirm, write
frontmatter). With 81 of 85 plan files lacking YAML frontmatter, running
plan-status individually is impractical — each file requires 3-5 user
interactions. A batch command provides a summary-first, bulk-approval UX that
processes an entire directory in 2-3 interactions total.

## Changes

### 1. Create `commands/batch-status.md`

New command file at
`plugins/plan-interview/commands/batch-status.md`.

**Frontmatter:**

- `description`: Process multiple plan files — analyze codebase evidence and
  add/update YAML frontmatter in bulk
- `argument-hint`: `[directory-path] [--force]` — omit directory to use
  plansDirectory setting; `--force` re-analyzes files with existing status
- `allowed-tools`: Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite

  > Note: `Bash` is required for batch git date collection and bulk
  > frontmatter inserts (Step 7 hybrid write strategy).

**Steps:**

1. **Step 0 — Create progress todos.** TodoWrite for Steps 1-7.

2. **Step 1 — Resolve directory and discover files.**
   Priority: `$ARGUMENTS` path > `.claude/settings.json` plansDirectory >
   `~/.claude/settings.json` > `docs/plans/` fallback. Glob all `*.md` files.
   Announce count: `"Found N plan files in [directory]"`. Stop if zero.

3. **Step 2 — Triage files into groups.** Read first 10 lines of each file to
   check for frontmatter. Classify into:
   - **A: No frontmatter** — will analyze and add
   - **B: Frontmatter, no status** — will analyze and add status
   - **C: Has status (todo/in-progress)** — skip unless `--force`
   - **D: Completed** — skip unless `--force`
   - **E: Legacy `status: artifact`** — always process (normalize)

   Present triage summary table. Ask: "Proceed with analyzing N files?"

4. **Step 3 — Get git dates (batch).** Run git log commands for all files in a
   shell loop (one Bash call, not one per file). Same rules as plan-status:
   `--follow --diff-filter=A` for created, `-1` for modified. Omit modified if
   it equals created. Use today if file untracked.

5. **Step 4 — Analyze codebase evidence (batch).** For each file: read content,
   extract inline backtick tokens (skip fenced code blocks), check via
   Glob/Grep. Score: 0% = `todo`, 1-79% = `in-progress`, 80%+ = `completed`.
   **Key batch difference:** zero-signal files default to `todo` (flagged as
   "no signals") — no per-file prompt.

   **Stricter token filter (batch-specific):** Unlike single-file plan-status,
   batch mode applies a tighter extraction filter to avoid noisy scores:
   - Only extract file paths with project-relevant prefixes (`plugins/`,
     `src/`, `.claude/`, `docs/`, `tests/`) or known extensions
   - Only extract identifiers in PascalCase or camelCase longer than 3 chars
   - Skip tokens that look like: version strings (`"1.0.0"`), JSON values
     (`"license": "MIT"`), API routes (`GET /api/...`), git refs (`HEAD~1`),
     whitespace, or single-word generic terms

6. **Step 5 — Type classification (batch).** For completed files:
   >= 30 days since modified → default `type: artifact`. Otherwise → default
   `type: standard`. Legacy artifact files → `type: artifact` automatically.
   No per-file prompt — user can override in Step 6.

7. **Step 6 — Present summary and get approval.** Output full results table
   with columns: #, File, Status, Type, Tokens, Evidence%, Created, Modified,
   Flags. Then aggregated stats (completed/in-progress/todo counts, flag
   counts). Ask how to proceed:
   - "Write all" — apply frontmatter to all files as shown
   - "Write, but let me override some" — category shortcuts + file numbers
   - "Export only" — output markdown table, no writes
   - "Cancel"

   **Flags to include in the table:**
   - `30d+ old` — completed plan modified 30+ days ago (auto-classified as
     artifact)
   - `no signals` — no qualifying tokens found; defaulted to `todo`
   - `docs plan` — title contains "document", "readme", "guide", "enhance",
     or similar; scoring may be inaccurate — review recommended

   **Override category shortcuts (when "Write, but let me override some"):**
   Ask: "Which group would you like to override?"
   - "Auto-artifacts" — review all plans auto-classified as `type: artifact`
     (30d+ flag)
   - "Review-flagged" — review all plans with `docs plan` flag
   - "No-signals" — set status for all zero-signal files at once
   - "Specific files" — enter file numbers from the table above

8. **Step 7 — Write frontmatter.** Apply same rules as plan-status Step 7:
   insert new frontmatter block or update existing. Include `type` only for
   completed plans. Normalize legacy artifact. Omit modified if equals created.

   **Hybrid write strategy:**
   - Files **without** existing frontmatter (81 files): use `Bash` to prepend
     the YAML block in a single shell script call rather than 81 Edit calls
   - Files **with** existing frontmatter (4 files): use `Edit` tool to
     update/add fields precisely, preserving other existing fields

   Output progress every 10 files. Final summary at end.

### 2. Update README

**File:** `plugins/plan-interview/README.md`

- Add `batch-status` row to the Components table
- Add usage example: `/plan-interview:batch-status docs/plans/`
- Add `--force` flag documentation

### 3. Add CHANGELOG entry

**File:** `plugins/plan-interview/CHANGELOG.md`

```
## [1.12.0] - 2026-03-29

### Added

- New `batch-status` command — processes multiple plan files in a directory,
  analyzing codebase evidence and writing YAML frontmatter in bulk with
  summary-first approval instead of per-file confirmation
```

### 4. Bump marketplace version

**File:** `.claude-plugin/marketplace.json`

- Change `plan-interview` version from `"1.11.0"` to `"1.12.0"`

## Files to modify

| File                                                | Change                          |
| --------------------------------------------------- | ------------------------------- |
| `plugins/plan-interview/commands/batch-status.md`   | New file — command definition   |
| `plugins/plan-interview/README.md`                  | Add batch-status documentation  |
| `plugins/plan-interview/CHANGELOG.md`               | v1.12.0 entry                   |
| `.claude-plugin/marketplace.json`                   | Version bump 1.11.0 -> 1.12.0  |

## Verification

1. Load plugin: `claude --plugin-dir ~/devbox/agentics/plugins/plan-interview`
2. Run: `/plan-interview:batch-status docs/plans/`
   - Should discover ~82 plan files
   - Triage should show ~78 in Group A (no frontmatter), ~1 in Group B, ~3 in
     Group D (completed)
   - Analysis should produce a summary table with per-file status/type
   - "Write all" should add frontmatter to all processed files
3. Run again without `--force`: should report all files already processed
4. Run with `--force`: should re-analyze all files
5. Verify legacy artifact normalization: manually set `status: artifact` on a
   test file, run batch-status, confirm it normalizes to
   `status: completed` + `type: artifact`

## Next Steps

- Add `batch-status` as a skill (auto-activation) if batch operations prove to
  be frequently needed
- Add a `--dry-run` flag that does analysis + summary without the write step
- Integrate with plan-hygiene to flag random filenames during batch processing
  (currently flags only, does not rename — that remains plan-hygiene's job)
