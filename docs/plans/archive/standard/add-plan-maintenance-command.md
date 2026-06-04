---
status: todo
type: feature
created: 2026-05-18
---

# Plan: Add plan-maintenance command to manage docs/plans directory

## Context

The `docs/plans/` directory has grown to 155 files in a flat structure with no
subdirectories or index. Key problems:

- **64 completed plans** (41%) sit alongside active work, making the directory
  hard to scan
- **82 files (53%)** missing `type` frontmatter, **22 (14%)** missing
  frontmatter entirely
- **37 files (24%)** are duplicate/variant clusters (-alt, -revised, -v2,
  -review.html)
- **3 non-canonical status values** (`implemented`, `ready`, `proposed`)
  fragment filtering
- **3 HTML review artifacts** mixed in with source plans
- **No README/index** for discoverability

Existing tooling in the `plan-interview` plugin handles naming
(`plan-hygiene`), status analysis (`update-plan-status`), and documentation
generation (`documenting-plans`) well. The gap is **lifecycle management**:
archiving completed work, normalizing metadata, generating an index, and
surfacing variant clusters for review.

## Objective

Create a `plan-maintenance` command in the `plan-interview` plugin that
archives completed plans as self-contained HTML files (via `markdown-to-html`),
generates a README index, reviews variant/duplicate files, and normalizes
non-canonical status values — all in one invocation with user confirmation at
each stage.

## Steps

1. **Refactor `update-plan-status` to reclaim `type` as content type and add
   status normalization (Group F)** — two changes in one pass:
   - **Type refactor:** Replace the `standard`/`artifact` lifecycle values with
     content types: `feature|fix|refactor|docs|chore`. Step 5 already infers
     content type from filename/H1/first 200 words — change it to write that
     inference as the `type` value instead of `standard`/`artifact`. Remove the
     30-day age check from Step 5 (archive eligibility moves to
     `plan-maintenance`).
   - **Group F:** Add a sixth triage group that catches non-canonical status
     values (`implemented` -> `completed`, `ready` -> `in-progress`,
     `proposed` -> `draft`) and non-canonical type values (`standard` ->
     infer content type, `artifact` -> infer content type).
   - File: `kit/plugins/plan-interview/commands/update-plan-status.md`
   - *Why:* The `type` field was defined as content type in `plan-mode.md` but
     repurposed as lifecycle state by this command. Reclaiming it enables
     type-based folder archiving and aligns with the rule.
   - *Verify:* Read the updated file. Confirm: (a) Group F appears in the
     Step 2 table with both status and type normalization mappings; (b) Step 5
     writes content types (`feature`, `fix`, etc.) not lifecycle states; (c) no
     reference to `standard`/`artifact` remains except in Group F's
     normalization mapping.

2. **Create the `plan-maintenance` command** with three sub-workflows:
   archive, index, and variant review.
   - File: `kit/plugins/plan-interview/commands/plan-maintenance.md`
   - *Why:* These three operations are a single maintenance workflow the user
     runs periodically. Bundling them under one command with flags
     (`--archive`, `--index`, `--variants`, `--all`) keeps the interface simple.
   - *Verify:* The command file has valid frontmatter with `description` and
     `argument-hint`. Each sub-workflow section has clear step-by-step
     instructions with user confirmation gates.

   **Sub-workflow execution order for `--all`:**
   Variants → Archive → Index (consolidate first, archive the clean set,
   index the final state).

   **Sub-workflow A: Variant review (`--variants`)**
   - Detect variant patterns: `-alt`, `-revised`, `-v\d+`, `-review.html`
   - Detect semantic clusters: files sharing 3+ word prefix in filename
   - Present clusters with recommendations (keep canonical, archive rest)
   - For HTML artifacts already in `docs/plans/`: recommend deletion
     (`git rm`)
   - User picks per-cluster: apply, skip, or review individually
   - Commit: `chore(plans): consolidate N variant plan files`

   **Sub-workflow B: Archive (`--archive`)**
   - Scan `plansDirectory` for files with `status: completed` where
     `created` or `modified` date is 30+ days ago
   - Check if `docs/<slug>.md` reference doc exists (from `documenting-plans`)
   - Present archive candidates table (filename, type, created, has-doc)
   - On user confirmation:
     1. Determine target folder from `type` field:
        - `feature` -> `docs/archive/features/`
        - `fix` -> `docs/archive/fixes/`
        - `refactor` -> `docs/archive/refactors/`
        - `docs` -> `docs/archive/docs/`
        - `chore` -> `docs/archive/chores/`
        - missing/unknown -> `docs/archive/general/`
     2. `mkdir -p` the target folder
     3. For each candidate, invoke `markdown-to-html` skill with
        `--mode=plan` — renders HTML next to the source `.md` in
        `docs/plans/`
     4. Move the rendered `.html` from `docs/plans/` to
        `docs/archive/<type>/<slug>.html`
     5. `git rm` the source `.md` from `docs/plans/` (git history
        preserves the original markdown)
     6. Move any matching `-review.html` files to the same type folder
     7. Show progress: `"Rendering 12/33: slug.html"`
   - **Commit safety:** Stage all changes but defer the commit until all
     files are processed. If any render fails, report the error and let
     the user `git checkout -- .` to undo. Only commit on full success.
   - Commit: `chore(plans): archive N completed plans as HTML`
   - **`--background` flag:** When passed, spawn the rendering loop as a
     background agent (non-blocking). Default is foreground with progress
     output. When background mode is used with `--all`, the index
     sub-workflow runs inside the background agent after archive completes.

   **Sub-workflow C: Index (`--index`)**
   - Scan `plansDirectory` for all `*.md` files (exclude README.md)
   - Read frontmatter, group by status: in-progress first, then todo, draft
   - Also scan `docs/archive/` subdirectories for archived plan counts
   - Write `docs/plans/README.md` with:
     - `<!-- auto-generated by plan-maintenance -->` header
     - Active plans table (status, type, created, linked filename)
     - Archived section: count per type folder in `docs/archive/` with
       links to each subdirectory
     - "Last updated" timestamp
   - Commit: `docs(plans): regenerate plans index`

3. **Update the `documenting-plans` skill and `plan-documenter` agent** —
   change eligibility from `type: artifact` to `status: completed` with 30+
   day age in both files.
   - Files: `kit/plugins/plan-interview/skills/documenting-plans/SKILL.md`,
     `kit/plugins/plan-interview/agents/plan-documenter.md`
   - *Why:* The `type: artifact` value is being removed. Both the skill (which
     hard-checks `type: artifact` at Step 2, lines 73-107) and the agent
     (which delegates to the skill) need the same date-based eligibility.
   - *Verify:* Read both files. Confirm neither references `type: artifact`.
     The skill's Step 2 gate checks `status: completed` + date age. The
     agent's scan criteria match.

4. **Update plugin README** — add `plan-maintenance` command and document the
   `type` field change.
   - File: `kit/plugins/plan-interview/README.md`
   - *Why:* The README is the discoverability surface for plugin users.
   - *Verify:* The README's Components table includes `plan-maintenance` with
     its invocation syntax and flag descriptions. A note explains the `type`
     field now holds content types.

5. **Add CHANGELOG entry and bump version** — minor version bump (new command
   + type field change).
   - Files: `kit/plugins/plan-interview/CHANGELOG.md`,
     `.claude-plugin/marketplace.json`
   - *Why:* Adding a command is a minor bump per marketplace versioning rules.
     The type field change is backward-compatible (existing frontmatter is
     normalized via Group F on next `update-plan-status` run).
   - *Verify:* CHANGELOG has an entry under a new `## [2.1.0]` heading.
     `marketplace.json` version for `plan-interview` reads `"2.1.0"`.

6. **Run the full maintenance cycle** to validate the implementation.
   - *Why:* End-to-end test on real data surfaces edge cases that unit-level
     checks miss.
   - *Verify:*
     - `update-plan-status --force` completes without errors; non-canonical
       statuses are normalized; `standard`/`artifact` types are replaced with
       content types
     - `plan-maintenance --archive` presents candidates and archives on
       confirmation; `docs/archive/<type>/` folders contain rendered HTML
       files and source `.md` files are removed from `docs/plans/`
     - `plan-maintenance --index` generates `docs/plans/README.md` with correct
       grouping and archive summary per type
     - `plan-maintenance --variants` surfaces the known clusters (deep-grill x5,
       code-review x6, etc.)
     - All sub-workflows produce clean git commits

## Acceptance Criteria

- [ ] `update-plan-status --force` normalizes `implemented`/`ready`/`proposed`
      to canonical status values and replaces `standard`/`artifact` with
      inferred content types (`feature`, `fix`, `refactor`, `docs`, `chore`)
- [ ] `/plan-interview:plan-maintenance --archive` converts completed 30d+
      plans to HTML via `markdown-to-html`, stores them in type-based
      subdirectories under `docs/archive/`, and `git rm`s the source `.md`
- [ ] `/plan-interview:plan-maintenance --index` generates a grouped README.md
      in `docs/plans/` with active plans table and per-type archive counts
- [ ] `/plan-interview:plan-maintenance --variants` detects and presents
      variant clusters with actionable recommendations
- [ ] `/plan-interview:plan-maintenance --all` runs variants → archive → index
      sequentially with confirmation gates between each
- [ ] `/plan-interview:plan-maintenance --archive --background` spawns the
      rendering loop as a background agent
- [ ] Existing tools (`plan-hygiene`, `plan-status`, `documenting-plans`,
      `plan-documenter`) continue to work — archived plans are removed from
      `docs/plans/`, `documenting-plans` and `plan-documenter` use date-based
      eligibility
- [ ] `docs/archive/<type>/` folders contain browsable self-contained HTML
      files that can be opened directly in any browser
- [ ] Plugin version bumped to 2.1.0 in marketplace.json and CHANGELOG

## Verification

End-to-end validation on the real `docs/plans/` directory:

1. Run `update-plan-status --force` — confirm: (a) the 3 non-canonical status
   files are normalized, (b) `standard`/`artifact` types are replaced with
   content types, (c) all missing-frontmatter files get frontmatter added
2. Run `plan-maintenance --archive` — confirm eligible plans are converted to
   HTML in type-based folders (`docs/archive/features/`, `docs/archive/fixes/`,
   etc.) and source `.md` files are removed from `docs/plans/`
3. Open a sample HTML file from `docs/archive/features/` in a browser — confirm
   it renders with step cards, timeline, and status chips
4. Run `plan-maintenance --index` — confirm `docs/plans/README.md` is generated
   with correct active plan counts and per-type archive summaries
5. Run `plan-maintenance --variants` — confirm known clusters (deep-grill x5,
   code-review x6) are surfaced
6. After archiving, run `plan-hygiene` — confirm it scans only the reduced
   `docs/plans/` set and works as before
7. Verify `docs/plans/README.md` renders correctly on GitHub (tables, links)
8. Verify `docs/archive/` folder structure: each type folder exists only if it
   contains at least one HTML file

## Next Steps *(optional)*

- Automate monthly maintenance with scheduled-tasks:
  ```text
  Create a monthly scheduled task that runs
  /plan-interview:plan-maintenance --all on the agentics repo. The task
  should run on the 1st of each month, archive eligible plans, regenerate
  the index, and flag variant clusters in the output. Use the existing
  scheduled-tasks MCP infrastructure.
  ```

- Add a pre-commit hook to regenerate the index:
  ```text
  Create a PreCommit hook that detects when files in docs/plans/ are being
  committed and auto-runs plan-maintenance --index to keep the README.md
  current. The hook should be lightweight — only regenerate if plan files
  changed, not on every commit.
  ```

## Design Decisions (resolved)

- **Archive scope:** Completed plans 30+ days old. Recent completions stay
  active until they age past the threshold.
- **Archive format:** HTML-only via `markdown-to-html --mode=plan`. Source `.md`
  removed from `docs/plans/` (git history preserves originals).
- **Archive location:** `docs/archive/` — sibling to `docs/plans/`, not a
  subdirectory. Organized into type-based subfolders.
- **Folder structure:** By content type — `docs/archive/features/`,
  `docs/archive/fixes/`, `docs/archive/refactors/`, `docs/archive/docs/`,
  `docs/archive/chores/`, `docs/archive/general/` (fallback).
- **Type field reclaimed:** `type` field restored to its `plan-mode.md`
  meaning: `feature|fix|refactor|docs|chore`. The `standard`/`artifact`
  lifecycle values are dropped; archive eligibility uses date-based age
  instead.
- **Type inference tolerance:** Best-effort — ~10-15% misclassification is
  acceptable since archive folders are a convenience, not a contract.
- **Rendering mode:** Foreground with progress indicator by default
  (`"Rendering 12/33: slug.html"`). `--background` flag available for
  non-blocking rendering via background agent.
- **Sub-workflow order:** Variants → Archive → Index when using `--all`.
  Consolidate first, archive the clean set, index the final state.
- **Doc eligibility:** All completed 30d+ plans are eligible for
  `documenting-plans` — no type-based filtering.

## Interview Summary

### Key Decisions Confirmed

- Type inference tolerance: best-effort classification is acceptable; archive
  folders are a convenience, not a contract
- Rendering approach: foreground with progress by default, `--background` flag
  for non-blocking rendering via background agent
- Sub-workflow ordering: variants -> archive -> index (consolidate first,
  archive clean set, index final state)
- Documentation eligibility: all completed 30d+ plans are eligible — no
  type-based filtering

### Open Risks & Concerns

- `markdown-to-html` always writes output next to the source file — archive
  workflow must render-then-move (two-step), creating a dependency on this
  behavior
- Both `documenting-plans` skill AND `plan-documenter` agent need updating
  (both reference `type: artifact`)
- Background archive + sequential index creates a dependency — when using
  `--background` with `--all`, index generation must run inside the background
  agent after archive completes
- No rollback for partial rendering failures — mitigated by staging all changes
  and deferring the commit until all renders succeed

### Recommended Amendments (applied to plan)

- Added `plan-documenter` agent to Step 3 alongside the `documenting-plans` skill
- Clarified two-step render-then-move in archive sub-workflow (Steps B.3-B.4)
- Made background rendering opt-in via `--background` flag (default: foreground
  with progress)
- Added commit-safety note: stage all archive changes, only commit after all
  renders succeed
- Reordered sub-workflows: variants -> archive -> index
