# Changelog

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

- **§2 Create**: plan filename extension changed from `.md` to `.html`.
- **§3 Frontmatter**: metadata now stored in HTML `<meta>` tags instead of YAML frontmatter.
- **§7 Status**: status updates now edit `<html data-status="…">` and the badge element instead of YAML.
- `validate-plan-filename.py` hook updated to accept both `.html` (primary) and `.md` (legacy) plan files; `_is_completed` now reads `<meta name="plan-status" content="completed">` for HTML files.

### Fixed (in this release)

- Status `<html data-status="…">` attribute is on the `<html>` element (not `<body>`); SKILL.md §7 and CHANGELOG wording corrected to match the skeleton.
- SKILL.md §7 now instructs updating **both** `<html data-status>` and `<meta name="plan-status">` so CSS badge colour and the hook's completion check stay in sync.
- SKILL.md §3 no longer mentions a redundant `<script type="application/json" id="plan-meta">` block; `<meta>` tags are the sole metadata channel.
- SKELETON.html `<ul class="next-steps-list">` changed to `<div>` — `<details>` and `<div>` are not valid `<ul>` children per HTML spec.
- SKILL.md HTML Output Requirements now mandates HTML-escaping all user-supplied placeholder values (`&`, `<`, `>`, `"`, `'`).
- SKILL.md frontmatter description updated from "plan-mode frontmatter" to "HTML metadata".
- SKILL.md §7 cross-plugin note clarifies that `plan-interview:plan-status` operates on `.md`/YAML only and should not be used for HTML plans until updated.
- README.md updated to reflect HTML output, `SKELETON.html`, `.html` hook firing, and HTML metadata (replacing YAML frontmatter references).

---

## 0.3.0 — 2026-05-28

### Added

- **Hook extensibility** — `validate-plan-filename.py` now reads `planAgent.additionalVerbs`, `planAgent.additionalStopWords`, and `planAgent.additionalPlaceholders` from `.claude/settings.json` (project first, then global). Domain-specific verbs and custom extensions can be merged with the hardcoded sets without editing the Python source.
- **Plan templates** (`--template default|minimal|adr|spike`) — three new skeleton variants: `SKELETON-minimal.md` (Context + Steps + Criteria only), `SKELETON-adr.md` (Architecture Decision Record), `SKELETON-spike.md` (time-boxed investigation). Template selected at §2 Create.
- **`--no-clarify` flag** — skips §1 Clarify independently of §5 Align.
- **`--no-align` flag** — skips §5 Align independently of §1 Clarify.
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
- Full §0–§7 workflow body, Required Structure, Writing Style, and Skeleton sections.

## 0.1.0 — 2026-05-27

### Added

- `authoring-plans` skill: auto-activating Plan Mode conventions covering the full §0–§7 workflow, required plan structure, and writing style
- `reference/SKELETON.md`: bundled plan skeleton with all required sections and per-step *Why*/*Verify* structure
- `validate-plan-filename.py` hook: `PostToolUse` enforcement of `verb-target` kebab-case plan filenames — rejects non-conforming names at write time (exit 2), skips `status: completed` plans
- `hooks.json`: registers the filename hook on `Write|Edit` events with a 5-second timeout
- Resolves `plansDirectory` from project `.claude/settings.json` first, global `~/.claude/settings.json` second, `docs/plans` as final fallback
