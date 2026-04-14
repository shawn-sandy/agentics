---
name: Add documenting-plans skill to plan-interview
status: todo
type: feature
created: 2026-04-14
modified: 2026-04-14
---

# Plan: Add `documenting-plans` Skill + Command to `plan-interview`

> Rename suggestion: `add-documenting-plans-skill-to-plan-interview.md`

## Context

The `plan-interview` plugin owns the plan lifecycle (interview → deep-grill → status → hygiene) but there is no skill that converts a **completed** plan into developer-facing documentation. `plan-status` confirms "done" and flips frontmatter, but produces no prose; `CHANGELOG.md` files are hand-maintained. This gap means shipped work lives in the plan file — buried in `docs/plans/` alongside unfinished plans — and developers have no curated reference describing what actually landed, where it lives, and how to use it.

This plan adds a sibling skill + companion command, `documenting-plans`, that reads a completed plan, cross-checks it against the current codebase and git history, and writes a structured prose document to `docs/<slug>.md`.

## Objective

Ship a new skill + command pair in the `plan-interview` plugin that:

1. Accepts a plan file (explicit arg / IDE open / settings fallback / latest).
2. Auto-runs `plan-status` logic when the plan is not yet `completed`; aborts if status cannot be brought to `completed`.
3. Extracts the plan's title, sections, and backtick-cited file paths.
4. Inspects each cited file (Glob + Read) and collects a scoped `git log` window for the plan + referenced files.
5. Writes `docs/<slug>.md` from a fixed template with regenerate-safe markers.
6. Offers overwrite / refresh / cancel when the target doc already exists.

## Files to Create

1. `kit/plugins/plan-interview/skills/documenting-plans/SKILL.md`
2. `kit/plugins/plan-interview/commands/documenting-plans.md`

## Files to Modify

1. `.claude-plugin/marketplace.json` — bump `plan-interview` from `1.12.0` → `1.13.0` (MINOR: new skill + command)
2. `kit/plugins/plan-interview/CHANGELOG.md` — prepend `## [1.13.0] - 2026-04-14` entry
3. `kit/plugins/plan-interview/README.md` — add Components table rows and a "Document Completed Plans" usage section

## Reuse (do not duplicate)

All reused logic lives in `kit/plugins/plan-interview/skills/plan-status/SKILL.md`. Reference by section, do not copy the text:

| Concern | Location |
|---|---|
| Plan-file resolution priority chain | Step 1 (user arg → IDE → settings `plansDirectory` → latest fallback) |
| Completion evidence scoring | Step 4 (backtick token extraction + Glob/Grep) |
| Frontmatter status-update procedure | Step 7 |
| Git dates for created/modified | Step 2 (`git log --follow --diff-filter=A`) |

## Steps

1. **Create skill directory and SKILL.md**
   - Path: `kit/plugins/plan-interview/skills/documenting-plans/SKILL.md`
   - Frontmatter: `name: documenting-plans`, `allowed-tools: Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite, Skill`
   - `description` must: start with "Use when the user asks to…", include synonyms ("generate docs", "document a plan", "turn a plan into docs"), and explicitly disambiguate from `plan-status`, `plan-interview`, and `review-rename-plans` via "Does not…" clauses.
   - *Why:* The description is the skill's activation surface. Nearest-neighbor skills in the same plugin share vocabulary — without explicit exclusions, this skill will be mis-activated on "check status" or "review plan" prompts. `Bash` is narrowed to `Bash(git *)` because every shell call in this skill is a git command — narrower scope is safer and satisfies the `auditing-allowed-tools` skill. `Skill` is added so Step 2 can invoke `plan-interview:plan-status` as a subroutine.

2. **Author the SKILL.md body — 10-step sequence**
   - Step 0: `TodoWrite` seeds todos for Steps 1–9.
   - Step 1: Resolve plan file using the exact chain from `plan-status` Step 1.
   - Step 2: Gate on `status: completed`. If not, invoke `plan-interview:plan-status` via the `Skill` tool with the resolved plan path as argument. Resume only if the plan file's frontmatter now reads `status: completed`. If plan-status could not promote to completed, stop with: `"Plan not yet completed (status: <x>). Documentation should only be generated for completed plans. Run plan-interview or continue implementation first."`
   - Step 3: Parse plan — H1 title; frontmatter `created`/`modified`/`status`/`type`; body sections (Context, Objective, Steps with `*Why:*`, Files to Create/Modify); backtick tokens (reuse `plan-status` Step 4 extraction rules).
   - Step 4: Derive output slug — use the plan filename without the `.md` extension, verbatim. No prefix-stripping. Confirm via `AskUserQuestion` ("Generated doc will be written to `docs/<slug>.md`. Accept, or provide a different slug?") so users can override on a per-run basis.
   - Step 5: Inspect shipped files — for each token, `Glob` for existence, `Grep` basename if relocated, `Read` first ~150 lines to capture public surface. Build index `{planned_path, actual_path, kind, exported_surface}`.
   - Step 6: Collect `git log --since=<created> --until=<modified or today> --format="%h %ad %s" --date=short -- <plan-file> <indexed-files...>` capped at 20 commits; also `git log -1 --format="%ad" --date=short -- <plan-file>` for the shipped-date badge.
   - Step 7: If `docs/<slug>.md` exists, `AskUserQuestion` → overwrite / refresh / cancel. Refresh mode regenerates only content between `<!-- generated:start -->` / `<!-- generated:end -->` markers.
   - Step 8: Synthesize and `Write` (or `Edit`) using the template below.
   - Step 9: Report summary table: output path, plan link, shipped date, files indexed, commits in window.
   - *Why:* Numbered `## Step N` sections with TodoWrite Step 0 matches the in-plugin authoring convention (`plan-interview`, `plan-status`, `deep-grill`).

3. **Define the generated-doc template** (embedded in SKILL.md Step 8 guidance)
   - Sections in order: H1 title → blockquote summary → `<!-- generated:start -->` → Status/Plan/Type badge → "What shipped" (bulleted capabilities from Objective + Steps, past tense) → "Files changed" table (Path / Role / Status with Created/Modified/Relocated/Missing) → "How it works" prose walkthrough (one short paragraph per plan Step) → "How to use it" (conditionally included when public surface exists) → "Commit history" table → `<!-- generated:end -->` → "References" (plan link, related docs, changelog mentions).
   - **CHANGELOG handling**: the "What shipped" section must cite the plugin CHANGELOG entry range rather than reproduce it verbatim. Example footer: *"See [plan-interview CHANGELOG §1.13.0](../kit/plugins/plan-interview/CHANGELOG.md#1130) for the authoritative feature list."* This avoids drift between the CHANGELOG and the generated doc.
   - **Plan link must be computed dynamically**: the "Plan:" badge and "References" plan link are built from `path.relative(dirname(output_doc), resolved_plan_path)`, not a hardcoded `./plans/` prefix. This keeps the link correct even when `plansDirectory` points outside `docs/plans/`.
   - *Why:* Deterministic markers make refresh mode safe; conditional "How to use it" keeps infrastructure/refactor docs from carrying empty sections; CHANGELOG citation prevents duplicated ownership of the "what shipped" narrative; dynamic link paths survive non-default `plansDirectory` settings.

4. **Create the companion command**
   - Path: `kit/plugins/plan-interview/commands/documenting-plans.md`
   - Frontmatter: `description`, `argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"`, `allowed-tools` mirroring the skill.
   - Body: thin wrapper listing Steps 0–9 with a final "Arguments: $ARGUMENTS" line — mirrors `commands/plan-interview.md` and `commands/plan-status.md`.
   - *Why:* Command provides explicit slash-invocation with path arg; skill remains the single source of truth for the logic.

5. **Bump marketplace version**
   - Edit `.claude-plugin/marketplace.json`: change the `plan-interview` entry's `"version"` from `"1.12.0"` to `"1.13.0"`.
   - *Why:* MINOR bump per `.claude/rules/marketplace.md` — new skill + command added, backwards-compatible.

6. **Add CHANGELOG entry**
   - Prepend `## [1.13.0] - 2026-04-14` to `kit/plugins/plan-interview/CHANGELOG.md` describing: new skill + command, auto-gate via plan-status delegation, three-source synthesis (plan body + live code + git log), doc template sections, refresh-mode markers.
   - *Why:* Repo convention requires CHANGELOG entries for every version bump.

7. **Update plugin README**
   - Insert command + skill rows into the Components table.
   - Add a "Document Completed Plans" usage section after "Plan Status" with example invocation.
   - *Why:* README is the discovery surface for users browsing the plugin.

8. **Validate and commit**
   - JSON-lint: `node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json'))"`.
   - Run `/plugin-dev:plugin-validator` against `kit/plugins/plan-interview`.
   - Commit all changes (SKILL.md, command, marketplace.json, CHANGELOG.md, README.md, **this plan file**) in a single commit. Message: `feat(kit/plugins/plan-interview): add documenting-plans skill (1.13.0)`.
   - *Why:* `.claude/settings.json` auto-validates marketplace.json; repo convention requires plan files to ship alongside the code.

## Verification

1. **Happy path:** Invoke `/plan-interview:documenting-plans docs/plans/add-plan-status-skill-to-plan-interview.md` (already `status: completed`). Confirm:
   - Gate is skipped.
   - Proposed slug is confirmed via prompt.
   - Files index resolves every backtick token to an existing path.
   - `docs/plan-status-skill-to-plan-interview.md` is written with all sections populated.
   - Commit table rows match `git log` output for the plan's date window.

2. **Refresh mode:** Re-invoke the same command; choose `refresh`; hand-edit a paragraph outside the markers; regenerate; confirm the hand-edit survives.

3. **Gate path:** Invoke against a plan with `status: todo`. Verify inline plan-status runs and either promotes to `completed` (with evidence) or halts with an informative message.

4. **Relocated-file path:** Temporarily rename a file cited in a test plan; re-run; confirm the Files-changed table marks it "Relocated" with the new path.

5. **Zero-signal path:** Pick a plan with no backtick file paths; confirm the skill asks the user how to proceed (inherited from `plan-status` Step 4 fallback).

6. **JSON validity:** Run the node JSON-lint command in Step 8 after bumping `marketplace.json`.

7. **Plugin structure:** Run `/plugin-dev:plugin-validator kit/plugins/plan-interview`; expect no new violations.

## Next Steps (out of scope)

- A hook or scheduled task that auto-refreshes generated docs when underlying files change.
- Cross-plan documentation (e.g., generate a shipped-features index across all `docs/*.md`).
- Filter commit window by files-touched intersection instead of a flat window (noise reduction for long-lived plans).
- A `--skip-status-check` command flag to bypass plan-status delegation when the user just ran it.
- **Docs index/registry**: a `docs/README.md` or auto-generated TOC listing every generated doc, so a flat `docs/` directory does not become opaque as docs accumulate.
- **`git log` pathspec chunking**: plans that reference many files could exceed argv length; chunk the pathspec list or fall back to a date-filtered repo-wide log.
- **Merge Step 5 + Step 6 into one "discover shipped artifacts" step** using `git log --name-only` as the authoritative file list, with Read used only to annotate role/surface. Removes the reconciliation ambiguity between plan-cited files and git-changed files.
- **Drop "Relocated" detection** in the Files-changed table — list truly-missing cited files as "Missing" and skip the repo-wide Grep sweep. Re-introduce if users request it.

## Unresolved Questions

None — all four original design decisions (output location, completion gate, inspection depth, form factor) plus the four Round 1 decisions (delegation model, doc placement, refresh scope, slug strategy) are locked in.

## Interview Summary

Conducted via `plan-interview:plan-interview` on 2026-04-14 before implementation.

### Key Decisions Confirmed (Round 1)

- **Plan-status delegation** → invoke as a subroutine via the `Skill` tool (`plan-interview:plan-status <plan-path>`), not inline copy or reference-by-path.
- **Output location** → flat `docs/<slug>.md`. No `docs/shipped/` or `docs/<type>/` subfolder for v1.
- **Refresh mode** → overwrite everything inside `<!-- generated:start -->` / `<!-- generated:end -->` markers; preserve text outside. No diff-and-prompt reconciliation.
- **Slug derivation** → plan filename without `.md`, verbatim. No prefix-stripping.

### Plan Naming Review

| Element | Current | Issue | Suggested |
|---|---|---|---|
| Filename | `sprightly-twirling-walrus.md` | Random adjective-verb-noun, unrelated to content | `add-documenting-plans-skill-to-plan-interview.md` |
| H1 heading | `# Plan: Add documenting-plans Skill + Command to plan-interview` | — | _(passes)_ |

Rename deferred to post-approval (plan mode forbids `mv`). Execute immediately after `ExitPlanMode` is approved.

### Open Risks & Concerns

- CHANGELOG/doc overlap — addressed by the CHANGELOG-citation rule added to Step 3.
- Relative plan-link correctness — addressed by the dynamic-path computation rule added to Step 3.
- `git log` pathspec length risk — moved to Next Steps for future mitigation.
- `Bash` tool scope — narrowed to `Bash(git *)` in Step 1.
- No docs index/registry — moved to Next Steps.

### Recommended Amendments (applied)

1. Step 2 body rewritten to invoke `plan-interview:plan-status` via the `Skill` tool.
2. Step 4 slug rule simplified to "filename verbatim".
3. Step 3 template: CHANGELOG citation rule added; dynamic plan-link path rule added.
4. Step 1 `allowed-tools` narrowed: `Bash` → `Bash(git *)`; `Skill` added.
5. Next Steps extended with: docs index, git-log pathspec chunking, Step 5+6 merge, Relocated-detection drop.

### Simplification Opportunities (not applied — recorded for awareness)

- **Merge Step 5 + Step 6** using `git log --name-only` as the authoritative file list (moved to Next Steps).
- **Drop "Relocated" detection** for v1 (moved to Next Steps).
- **Defer refresh mode to v1.1** — ship overwrite-only in v1.0 to reduce complexity. *Not applied*: the user's Round 1 answer explicitly chose the marker-based refresh model, so it stays in v1.0.
