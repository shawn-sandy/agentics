# Changelog

## v0.14.0 — 2026-05-30 — Add PostToolUse hook to auto-rebuild plans index

### Added

- **`hooks/rebuild-plans-index.py`** — PostToolUse hook that fires on every `Write|Edit` to a non-`index.html` `.html` file inside the configured plans directory. Calls `docs/plans/build-index.sh` to regenerate the gallery index automatically. Always exits 0 so index-rebuild failures never block plan writes.
- **`docs/plans/build-index.sh`** — self-contained shell entry point that regenerates `docs/plans/index.html` without Claude. Finds the `plans-gallery.html` template via the same plugin-discovery strategy as `plans-library`; falls back to a minimal embedded styled gallery if the template is unavailable.
- Registered `rebuild-plans-index.py` as a second `PostToolUse` entry in `hooks.json` with `Write|Edit` matcher and a 30-second timeout.

## v0.13.0 — 2026-05-31 — Add plans-library skill and gallery template

### Added

- **`plans-library` skill** — scans the configured `plansDirectory`, parses each plan's metadata, and writes a filterable HTML gallery (`index.html`) with status/type chips, title search, and grid/list views. Opened in the browser on completion.
- **`plans-gallery.html` template** — standalone gallery template with versioned cache path, JSON-safe title parsing, and an explicit `GENERATED_AT` timestamp.

### Fixed

- **`plans-library` xargs** — replaced `xargs ls -t` with `xargs -0 ls -t` (null-delimited) to handle plan paths that contain spaces.
- **`plans-library` template discovery** — versioned cached templates are now sorted by version descending (`sort -rV`) before `head -1`, making the selection deterministic when multiple cached versions exist.
- **`planning` Step 0 bootstrap wording** — clarified that the `ToolSearch(select:ExitPlanMode)` preflight runs as part of Step 0 (not before it); removed the contradictory "before any other action" phrase.
- **`planning` preflight echo** — moved the resolved-objective echo to after the Step 0 bootstrap so no user output precedes `ExitPlanMode`.

---

## v0.12.1 — 2026-05-30 — Fix section sign rendering

### Fixed

- Replaced `§` (section sign) characters with plain text ("Step N", "Steps N–M") across SKILL.md, README.md, and CHANGELOG.md to fix rendering issues in terminals and markdown viewers.

---

## v0.12.0 — 2026-05-30 — Codebase exploration, Grep, and browser fallback

### Added

- **Step 0b Explore** — new codebase research step after the self-bootstrap and before Clarify. Uses `Glob`, `Grep`, and `Read` to build context on entry points, existing patterns, tests, and configuration before drafting steps. Exploration depth scales with plan scope. Skipped by `--quick`.
- **`Grep`** added to `allowed-tools` — enables first-class codebase symbol and pattern search without permission prompts during exploration and plan drafting.
- **Step 8 browser fallback** — when the browser MCP server is unavailable (headless/web environments), falls back to `SendUserFile` with the file path, ensuring plan delivery always works.

### Changed

- **Description tightened** — first sentence shortened to fit within the ≤80-char guideline.

---

## v0.11.2 — 2026-05-30 — Add scope constraint: plans only, no implementation

### Added

- **Scope Constraint section** — explicit rule block inserted before the Workflow prohibiting the skill from editing source files or applying any change described in the plan's steps. The plan is the deliverable; implementation is a separate, user-initiated step. Addresses a case where the skill implemented a fix rather than writing a plan for it.

---

## v0.11.1 — 2026-05-30 — Fix: self-bootstrap out of harness plan mode

### Fixed

- **Step 0 self-bootstrap** — Added unconditional `ExitPlanMode` call as the first step of the workflow. When the harness enters plan mode on "planning"-keyword commands it forces `.md` output to a random-slug path, overriding the skill's `.html` guarantee. Calling `ExitPlanMode` immediately exits harness plan mode so the skill writes directly to disk as designed. Root cause: v0.8.0 removed `ExitPlanMode` from `allowed-tools` but left no escape hatch for harness-triggered plan mode.
- **`allowed-tools`**: added `ExitPlanMode`, `WebFetch`, `WebSearch`, `SendUserFile`.

---

## v0.11.0 — 2026-05-30 — Add plans-library skill and web research tools

### Added

- **`plans-library` skill** — scans every HTML plan in the plans directory, parses `<meta>` tags (`plan-status`, `plan-type`, `plan-created`) and `<title>`, populates a gallery template, writes `docs/plans/index.html`, and opens it in the browser. Filterable by status (todo / in-progress / completed) and type (feature / fix / refactor / docs / chore) with a title search box. Excludes `index.html` and `archive/` subdirectory.
- **`templates/plans-gallery.html`** — self-contained gallery template (no external CSS/JS/CDN) with light theme; grid and list views; client-side filtering.
- **`WebFetch`, `WebSearch`, `SendUserFile`** added to `allowed-tools` — enables research during Clarify (verifying APIs, checking library versions) and delivers the finished plan file to the user in Step 8 Open.

---

## v0.10.0 — 2026-05-30 — Add built-in structured interview step

### Added

- **Step 5b Interview** — new standard workflow step between Align and Commit. Analyzes plan content to classify complexity (short/medium/complex), detects UI signals, then runs 1–3 interview rounds via `AskUserQuestion` with dynamically generated questions. Round 1 (Technical & Trade-offs) always runs; Round 2a (UI/UX) and 2b (Accessibility) run for medium+ plans or when UI signals are detected; Round 3 (Edge Cases) runs for complex plans only. Post-interview summary offers to update the plan HTML before committing.
- **`--no-interview` flag** — skips Step 5b Interview for pre-validated or time-critical plans.

### Changed

- **`--quick` expanded** — now shorthand for `--no-clarify --no-align --no-interview` (previously only `--no-clarify --no-align`).

### Removed

- **`--interview` flag** — the external delegation to `plan-interview:plan-interview` after Step 8 is replaced by the built-in Step 5b step. The `plan-interview` plugin remains available as a standalone deep-interview tool.

---

## v0.9.0 — 2026-05-30 — Add mandatory Step 8 Open step with browser verification

### Added

- **Step 8 Open** — new mandatory final workflow step that opens the committed plan in a browser to confirm it renders correctly. Steps: find a free port via `python3 -c "import socket…"`, start `python3 -m http.server <port>` in the background from the plan's parent directory, load browser tools via `ToolSearch`, navigate to `http://localhost:<port>/<plan-filename>`, take and send a screenshot, report the URL to the user, and leave the server running. Cannot be skipped.
- **`allowed-tools` expanded** — added `ToolSearch`, `mcp__claude-in-chrome__tabs_context_mcp`, `mcp__claude-in-chrome__tabs_create_mcp`, `mcp__claude-in-chrome__navigate`, and `mcp__claude-in-chrome__computer` so browser automation tools are pre-approved and never prompt mid-run.

---

## v0.8.0 — 2026-05-30 — Remove plan-mode handshake; tighten skill consistency

### Changed

- **Remove `EnterPlanMode`/`ExitPlanMode` handshake** — the skill now writes its HTML plan file directly instead of entering harness plan mode, restoring its two output guarantees: `verb-target` kebab-case filename and self-contained `.html` output. Root cause: `EnterPlanMode` handed control to the harness, which forced markdown to a random-slug path, contradicting the skill's own "no plan mode for write operations" rule.
- **`--template` flag**: trimmed to `default` only in `argument-hint`; `minimal`, `adr`, and `spike` are documented as planned but not yet implemented.
- **Skeleton variants deleted**: `reference/SKELETON-minimal.md`, `reference/SKELETON-adr.md`, `reference/SKELETON-spike.md` removed — they were markdown files and violated the "always write HTML" rule. `reference/SKELETON.html` remains the sole supported skeleton.
- **`allowed-tools`** pruned: `EnterPlanMode`, `ExitPlanMode`, `ToolSearch`, `TodoWrite`, and `Grep` removed (dead weight after plan-mode removal or unreferenced in body).
- **Heading hierarchy**: body H1 (`# Plan Agent — Planning`) lowered to H2.
- **Freedom level**: `## Workflow` opens with "Follow these steps exactly." to prevent guardrail-skipping on a process-critical sequential skill.
- **Frontmatter description**: rewritten with capability statement, user-intent trigger, and scope-exclusion sentence (≤1024 chars, third person).
- **`$ARGUMENTS` clarifying note**: added to `Invocation & Arguments` explaining why this command-only construct is valid here.

---

## v0.7.1 — README: correct --template flag docs; fix planAgent.extraFrontmatter key

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## 0.7.0 — 2026-05-29

### Added

- **Copy prompt buttons**: each `<pre>` prompt block in the Next Steps (including Wish List items) and Unresolved Questions sections now has a "Copy prompt" button. Clicking copies the prompt text to the clipboard; the button shows "Copied ✓" for 2 seconds then reverts. Uses the Clipboard API with a textarea fallback for `file://` protocol. Hidden in print.
- `copyPrompt` global JS function added to `SKELETON.html` (outside the IIFE so inline `onclick` handlers can resolve it).
- `.copy-prompt-btn` CSS class: blue-accent pill matching the document design tokens; green `.copied` state mirrors existing completion colours.
- SKILL.md updated to mandate copy buttons on every prompt `<pre>` in generated plans and to warn against removing them when filling placeholders.

---

## 0.6.0 — 2026-05-29

### Added

- **Sticky sidebar navigation**: two-column layout (200px sidebar + content) with "On this page" section links; collapses to single-column on narrow viewports.
- **Scroll rail**: animated 3px progress indicator on the left edge of the sidebar tracks page scroll position in real time.
- **Scroll spy**: `IntersectionObserver`-powered active link highlighting (left-border indicator) in the sidebar as sections enter the viewport.
- **CSS step timeline**: vertical connector line with circle nodes on each step card; nodes turn green when all criteria are checked (via CSS `.step-card.completed`).
- **Step chips**: `<span class="step-chip">todo</span>` decorates each step action with a pill badge; turns green when the step card is marked complete.
- **localStorage persistence**: acceptance-criteria checkbox state saved to `localStorage` keyed by page title — survives page refresh.
- **Print styles**: sidebar, scroll rail, and step chips hidden in print; single-column layout.
- **Inline SVG icons**: Heroicons `<symbol>`/`<use>` pattern replaces emoji; zero external dependencies.
- **Pulsing in-progress dot**: status badge dot pulses when `data-status="in-progress"`; respects `prefers-reduced-motion`.
- **Accessibility baseline**: skip link, `aria-labelledby` on every section, `role="progressbar"` attributes, `aria-live="polite"` region for criteria announcements, `min-height: 44px` touch targets on nav links.
- **Tone guidance in SKILL.md**: writing-style addendum encouraging rallying-statement objectives and imperative-verb step actions.

### Changed

- `SKELETON.html`: professional document aesthetic — white page, white header with a single 3px blue accent stripe, "Implementation Plan" doc-type label above the plan title.
- Sections rendered as flat ruled document sections separated by `border-top` lines (no card shadows or rounded corners).
- `<div class="section-card">` elements converted to `<section>` with `id` and `aria-labelledby` for improved semantics.
- Step number badges simplified to a plain grey circle (no gradient).
- Criteria items styled as individual bordered rows.
- Progress bar thinned to 6px with a solid blue fill.
- `--radius: 4px` throughout for a sharper document feel.

---

## 0.5.0 — 2026-05-28

### Added

- **HTML output** (default): the `planning` skill now writes every plan as a self-contained `.html` file — no markdown, no external dependencies.
  - Rich layout: status badge, objective highlight card, numbered step cards with expandable *Verify* disclosures, interactive acceptance-criteria checkboxes with live progress bar, collapsible Next Steps and Unresolved Questions sections.
  - **Wish List subsection**: blue-sky / visionary ideas in `next-steps` are automatically labelled `🔭 Wish List` and rendered with a distinct dashed-border, muted-colour treatment so they read as non-committal aspirations.
  - Plan metadata stored in `<meta>` tags (`plan-status`, `plan-type`, `plan-created`, `plan-repo`) for machine readability.
  - Minimal inline JavaScript (progress bar on checkbox change); fully functional without JS.
- `reference/SKELETON.html`: new bundled HTML plan template replacing `SKELETON.md` — all required sections pre-wired with placeholders in `{curly braces}`.

### Changed

- **Step 2 Create**: plan filename extension changed from `.md` to `.html`.
- **Step 3 Frontmatter**: metadata now stored in HTML `<meta>` tags instead of YAML frontmatter.
- **Step 7 Status**: status updates now edit `<html data-status="…">` and the badge element instead of YAML.
- `validate-plan-filename.py` hook updated to accept both `.html` (primary) and `.md` (legacy) plan files; `_is_completed` now reads `<meta name="plan-status" content="completed">` for HTML files.

### Fixed (in this release)

- Status `<html data-status="…">` attribute is on the `<html>` element (not `<body>`); SKILL.md Step 7 and CHANGELOG wording corrected to match the skeleton.
- SKILL.md Step 7 now instructs updating **both** `<html data-status>` and `<meta name="plan-status">` so CSS badge colour and the hook's completion check stay in sync.
- SKILL.md Step 3 no longer mentions a redundant `<script type="application/json" id="plan-meta">` block; `<meta>` tags are the sole metadata channel.
- SKELETON.html `<ul class="next-steps-list">` changed to `<div>` — `<details>` and `<div>` are not valid `<ul>` children per HTML spec.
- SKILL.md HTML Output Requirements now mandates HTML-escaping all user-supplied placeholder values (`&`, `<`, `>`, `"`, `'`).
- SKILL.md frontmatter description updated from "plan-mode frontmatter" to "HTML metadata".
- SKILL.md Step 7 cross-plugin note clarifies that `plan-interview:plan-status` operates on `.md`/YAML only and should not be used for HTML plans until updated.
- README.md updated to reflect HTML output, `SKELETON.html`, `.html` hook firing, and HTML metadata (replacing YAML frontmatter references).

---

## 0.3.0 — 2026-05-28

### Added

- **Hook extensibility** — `validate-plan-filename.py` now reads `planAgent.additionalVerbs`, `planAgent.additionalStopWords`, and `planAgent.additionalPlaceholders` from `.claude/settings.json` (project first, then global). Domain-specific verbs and custom extensions can be merged with the hardcoded sets without editing the Python source.
- **Plan templates** (`--template default|minimal|adr|spike`) — three new skeleton variants: `SKELETON-minimal.md` (Context + Steps + Criteria only), `SKELETON-adr.md` (Architecture Decision Record), `SKELETON-spike.md` (time-boxed investigation). Template selected at Step 2 Create.
- **`--no-clarify` flag** — skips Step 1 Clarify independently of Step 5 Align.
- **`--no-align` flag** — skips Step 5 Align independently of Step 1 Clarify.
- **`--priority` flag** (`low|medium|high|critical`) — writes `priority:` to plan frontmatter without requiring settings config.
- **`planAgent.extraFrontmatter` config** — project or global `.claude/settings.json` can inject arbitrary key-value pairs (e.g. `team`, `milestone`) into every plan's YAML frontmatter after the standard fields.

### Changed (non-breaking)

- `--quick` is now purely opt-in. The previous heuristic that auto-applied `--quick` for objectives ≥ 8 words with concrete names has been removed. `--quick` is documented as shorthand for `--no-clarify --no-align`.
- `argument-hint` updated to include all new flags.
- `classify_filename()` signature now accepts optional `verbs`, `stop_words`, and `placeholders` parameters (all default to module-level constants — backwards-compatible).

## 0.2.0 — 2026-05-27

### Changed (BREAKING)

- **Plugin renamed** `plan-mode` → `plan-agent`. Install id is now `plan-agent@agentics-kit`.
- **Skill renamed** `authoring-plans` → `author`. Explicit invocation is now `/plan-agent:author <objective>`.
- **Activation model changed**: `author` skill is now manual-invoke only (`disable-model-invocation: true`). It no longer auto-activates on planning intent — use `/plan-agent:author` explicitly.

### Added

- `$ARGUMENTS` parsing: reads a free-text objective plus flags (`--quick`, `--type`, `--dir`, `--interview`) from the invocation line.
- Smart `--type` inference from the leading verb of the objective when the flag is absent.
- Smart `--quick` inference for detailed, specific objectives.
- `EnterPlanMode` entry — the skill flips the session into real plan mode on invocation.
- `EnterPlanMode` added to `allowed-tools`.
- `--interview` flag: after the plan is written, optionally runs `plan-interview:plan-interview` before `ExitPlanMode`.

### Unchanged

- `validate-plan-filename` hook — logic, exit codes, and `hooks.json` registration are identical. Only the stderr citation was updated to reference `plan-agent` `/plan-agent:author`.
- Full Steps 0–7 workflow body, Required Structure, Writing Style, and Skeleton sections.

## 0.1.0 — 2026-05-27

### Added

- `authoring-plans` skill: auto-activating Plan Mode conventions covering the full Steps 0–7 workflow, required plan structure, and writing style
- `reference/SKELETON.md`: bundled plan skeleton with all required sections and per-step *Why*/*Verify* structure
- `validate-plan-filename.py` hook: `PostToolUse` enforcement of `verb-target` kebab-case plan filenames — rejects non-conforming names at write time (exit 2), skips `status: completed` plans
- `hooks.json`: registers the filename hook on `Write|Edit` events with a 5-second timeout
- Resolves `plansDirectory` from project `.claude/settings.json` first, global `~/.claude/settings.json` second, `docs/plans` as final fallback
