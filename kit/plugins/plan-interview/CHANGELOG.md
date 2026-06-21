# Changelog

## v2.2.8 — 2026-06-20 — Standardize plans-directory resolution (Claude settings precedence)

### Fixed

- **Consistent plans-directory resolution** — every skill, command, and agent that resolves `plansDirectory` now follows Claude Code's settings precedence: project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`. Previously the local override layer was skipped and the **default fallback was the global `~/.claude/plans/` user folder**, which diverged from where plan-agent writes plans; the default is now `${PWD}/docs/plans`, so readers and writers agree. Touched: `plan-status`, `documenting-plans`, `markdown-to-html`, `deep-grill`, `plan-interview` skills; the `plan-status`, `update-plan-status`, `deep-grill`, `plan-interview`, `markdown-to-html`, `documenting-plans`, `review-rename-plans`, `plan-hygiene`, `plan-maintenance` commands; and the `plan-documenter` agent.

## v2.2.7 — 2026-06-07 — Add Save as PDF button to HTML plans

### Added

- `html-spec.md`: new "Save as PDF Button" section with markup, `.save-pdf-btn` CSS, and `savePDF()` JS function.
- `assets/scripts.js`: added `savePDF()` global function that calls `window.print()`.
- `SKILL.md`: Step 5 structure list now mentions the Save as PDF button.
- `html-spec.md`: updated Header element order, Page Structure skeleton, and `@media print` block to include the button.

---

## v2.2.6 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/plan-interview` path instead of an author-specific home directory.

---

## v2.2.4 — 2026-06-01 — Add ExitPlanMode error handling

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success

## v2.2.3 — 2026-06-01 — Minor wording corrections

### Fixed

- `plan-interview` skill: minor description wording corrections.

---

## v2.2.2 — 2026-05-30 — Fix section sign rendering

### Fixed

- Replaced `§` (section sign) in documenting-plans SKILL.md with plain text to fix rendering issues.

---

## v2.2.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## [2.2.0] - 2026-05-20

### Added

- **Plan-type router (Step 1.5)** — both the `plan-interview` skill and command now classify the
  resolved plan before starting the interview. When 2+ product-plan signals are detected (user
  stories, success metrics, business goals, stakeholder language, etc.), the user is asked to
  choose between the full cross-functional panel (`product-plans:plan-review-agents`) and the
  quick technical interview. Routing invokes the panel skill directly via `Skill` and stops.
- **`--quick` flag** — pass `--quick` to bypass the routing step and always run the technical
  interview immediately, without the classification prompt.

### Removed

- **Step 5.5** — the late-stage product-plan note appended to the summary has been removed.
  Detection and routing now happen at Step 1.5, before the interview begins.

## [2.1.1] - 2026-05-20

### Changed

- **Skill description narrowed** — `plan-interview` skill now explicitly scopes to technical
  implementation plans (code, files, APIs). The description advises users to reach for
  `product-plans:plan-review-agents` for product plans, PRDs, and feature proposals.
- **HTML artifact is now mandatory** — Step 6 always generates `<plan-stem>-interview.html`
  after the interview summary (regardless of whether the user saves findings to the plan file).
  This file is the shared living document: if `product-plans:plan-review-agents` is later run
  on the same plan, it detects this file and appends its panel findings to it.
- **Step 5.5 (product-plan scope check)** — after compiling the summary, the skill now scans
  for product-plan signals (user stories, success metrics, business goals, etc.). When 2+
  signals are found, a note is appended to the summary suggesting `plan-review-agents`.
- **README: "Which tool to use?" section** — new comparison table clarifying when to use
  `plan-interview` vs. `product-plans`.

## [2.1.0] - 2026-05-18

### Added

- **`plan-maintenance` command** — archive completed plans as browsable HTML, generate a
  directory index, and review variant/duplicate files. Three sub-workflows: `--variants`
  (consolidate `-alt`/`-revised`/`-v2` duplicates), `--archive` (convert completed 30d+
  plans to HTML in type-based folders under `docs/archive/`), `--index` (generate
  `docs/plans/README.md` with grouped tables). Use `--all` for the full cycle, `--background`
  for non-blocking rendering.
- **Group F status/type normalization** in `update-plan-status` — non-canonical status values
  (`implemented`, `ready`, `proposed`, `artifact`) are normalized to canonical values
  (`completed`, `in-progress`, `draft`). Non-canonical type values (`standard`, `artifact`)
  are replaced with inferred content types.

### Changed

- **`type` field reclaimed as content type** — `update-plan-status` now writes content types
  (`feature`, `fix`, `refactor`, `docs`, `chore`) instead of lifecycle states (`standard`,
  `artifact`). Existing plans are normalized via Group F on the next `--force` run.
- **`documenting-plans` eligibility** — changed from `type: artifact` to `status: completed`
  with 30+ day age. All completed plans that are old enough are now eligible regardless of
  type.
- **`plan-documenter` agent** — updated to match the new date-based eligibility criteria.

## [2.0.0] - 2026-05-18

### Breaking Changes

- **`plan-to-html` skill renamed to `markdown-to-html`** — all existing invocations of
  `Skill(skill: "plan-interview:plan-to-html", ...)` must be updated to
  `Skill(skill: "plan-interview:markdown-to-html", ...)`.
- **`/plan-interview:plan-to-html` command deprecated** — the command file now
  delegates to `markdown-to-html --mode=plan`. A backward-compat skill alias also
  remains at `skills/plan-to-html/SKILL.md` for `Skill(...)` callers. Both will be
  removed in a future major release.
- **`--setup` flag removed** — the `~/.claude/plan-to-html/` cache directory and
  one-time setup flow are eliminated. Theme CSS and JS are now bundled in
  `skills/markdown-to-html/assets/` and regenerated via `scripts/build-assets.sh`.

### Added

- **`skills/markdown-to-html/`** — renamed skill with broadened scope (plan + doc modes)
- **Render mode auto-detection** — plan mode (step cards, timeline, SVG diagram) activates
  automatically when source has `## Steps` or `status:` + `Plan:` H1; falls back to doc mode
- **`--mode=auto|plan|doc`** flag to force render mode
- **CSS step timeline** — vertical connector line + circle node per step via `::before`
  pseudo-elements; filled circle on completed steps
- **Status chip** — `<span class="step-chip">` real element (not `::after`) shows
  `todo` / `done`; freed both pseudo-elements for the timeline
- **Scroll rail** — `<div class="scroll-rail">` in sidebar tracks page scroll progress
  via `--scroll-pct` CSS custom property updated by JS
- **SVG section diagram** — auto-compact node graph when ≥2 sections present;
  geometry scales with section count; nodes link to sections on click
- **WCAG Level A** — skip link (`<a href="#main-content">`), `lang="en"`, `<title>`,
  each checkbox wrapped in `<label>`, `aria-current="true"` on active nav link,
  `aria-labelledby` on each `<section>`, `aria-live` step-status live region
- **`aria-current="true"`** on active sidebar `<a>` (SC 4.1.2)
- **`--list-themes`** flag — prints theme names and descriptions, then stops
- **`--mode=plan`** appended to all callers** — `plan-hygiene`, `review-rename-plans`,
  `plan-interview` SKILL.md now pass `--mode=plan` to prevent doc-mode regression
- **`scripts/build-assets.sh`** — awk-based extractor generates `assets/themes.css`
  and `assets/scripts.js` from `BUILD-EXTRACT` comment markers in `html-spec.md`
- **`skills/plan-to-html/SKILL.md`** — backward-compat alias that delegates to
  `markdown-to-html` with `--mode=plan`
- **`commands/markdown-to-html.md`** — new command file with updated flags and features
- **`reference/html-spec.md`** — comprehensive rewrite covering security, render modes,
  WCAG requirements, visuals (timeline, chips, rail, SVG), and updated JS features

### Security

- **Per-sink HTML encoding** for all user-controlled content (body text, attributes,
  SVG `<text>`) — prevents XSS (CWE-79)
- **URL allow-list** — only `http://`, `https://`, `mailto:`, `#` emit `<a href>`;
  all other schemes render as plain text
- **Theme allow-list** — validated before interpolation into `<body class="theme-…">`
- **Path traversal defense** (`realpath` + workspace boundary check) in Step 1

### Changed

- `reference/html-spec.md` is now the authoritative spec; `assets/` files are generated
  artifacts — always regenerate via `build-assets.sh` after spec changes
- Scroll-spy now sets both `class="active"` AND `aria-current="true"` on active nav links
- Progress bar retains custom `.progress-fill` div (native `<progress>` + `accent-color`
  discordant on dark themes)
- `prefers-reduced-motion` disables all transitions (step cards, progress fill, scroll rail)
- `Bash(mkdir *)` removed from `allowed-tools`; `Bash(realpath *)` added

## [1.22.1] - 2026-05-15

### Fixed

- `skills/plan-interview/SKILL.md` Step 6: HTML generation offer was nested
  inside the "confirm save findings" branch, so it was unreachable when the
  user declined to append the summary. Moved the `AskUserQuestion` for
  plan-to-html after both the confirm and decline branches, gated to
  `plan-review` mode only (skill reviews do not produce plan HTML).

### Changed

- `commands/plan-hygiene.md`, `commands/review-rename-plans.md`: Switched
  `plan-to-html` invocation flag from `--no-open` to `--background`. This is
  a user-visible behavior change: `--background` suppresses the theme-selection
  prompt in addition to skipping the browser open; callers no longer choose a
  theme for auto-generated HTML outputs from these commands (default theme is
  applied).
- `commands/plan-hygiene.md`, `commands/review-rename-plans.md`: Replaced the
  `git add <dir>/*.html` glob with explicit per-file `git add` for generated
  HTML outputs, reducing the risk of accidentally staging unrelated HTML files
  in the same directory.

## [1.22.0] - 2026-05-14

### Added

- `skills/plan-to-html/SKILL.md` frontmatter: `Agent` added to `allowed-tools`
  so the skill can spawn background agents
- `skills/plan-to-html/SKILL.md` Step 1: `--async` flag — when present, spawns
  a background `Agent` after theme resolution and returns immediately; the agent
  re-invokes the skill with `--background` to complete HTML generation without
  blocking the main thread
- `skills/plan-to-html/SKILL.md` Step 3: async dispatch block — after the theme
  is resolved (via flag, `--background` default, or `AskUserQuestion`), checks
  for `--async` and calls `Agent(run_in_background: true)` if set; combining
  `--async --theme=<value>` gives a fully hands-off fire-and-forget invocation
- `commands/plan-to-html.md`: `Agent` added to `allowed-tools`; `--async` flag
  documented in Arguments section with usage examples

## [1.21.0] - 2026-05-14

### Added

- `skills/plan-interview/SKILL.md` Step 2: fourth filename criterion "Verb-led" — flags
  filenames that don't start with an imperative verb and requires suggested names to be
  verb-led
- `skills/plan-interview/SKILL.md` Step 2: "Step structure" extraction point — counts
  steps missing a `*Verify:*` line
- `skills/plan-interview/SKILL.md` Step 5: optional "Step Structure" summary section
  showing count of incomplete steps and a corrected three-part example
- `skills/plan-interview/SKILL.md` Step 6: three-part format string required when writing
  or amending steps (`**[Action]** — [description]. *Why:* [rationale]. *Verify:* [confirmation criteria].`)
- `commands/review-rename-plans.md` Step 2: fourth filename criterion "Verb-led" — same
  rule as plan-interview, applied to batch filename review
- `commands/plan-hygiene.md` Name Generation: verb-led output check — if generated name is
  noun-led, the dominant action verb is extracted from the heading and prepended

## [1.20.0] - 2026-05-14

### Added

- `skills/plan-to-html/SKILL.md` Step 0.5: new `--setup` flag writes pre-built
  theme CSS and JavaScript to `~/.claude/plan-to-html/` for caching; future
  runs read these files directly instead of re-synthesizing CSS/JS from the spec
- `skills/plan-to-html/SKILL.md` Step 1: `--background` flag for fully
  non-interactive mode — auto-selects `default` theme, auto-overwrites existing
  output, implies `--no-open`; intended for batch or automated invocations
- `skills/plan-to-html/SKILL.md` Step 5: cache check reads
  `~/.claude/plan-to-html/themes.css` and `scripts.js` when present, skipping
  re-derivation of CSS/JS from the spec
- `commands/plan-to-html.md`: documented `--setup`, `--background`, `--theme`,
  and `--no-open` flags in the Arguments section with usage examples

## [1.19.0] - 2026-05-13

### Added

- `skills/plan-interview/SKILL.md` Step 2: after a user-confirmed rename,
  offers to generate HTML for the renamed plan via `plan-to-html --no-open`;
  `plan-to-html` prompts for a color theme before writing the `.html` file
- `skills/plan-interview/SKILL.md` Step 6: after a user-confirmed summary
  append, offers to generate or regenerate HTML so the artifact reflects the
  appended `## Interview Summary`; if an `.html` already exists, notes that
  `plan-to-html` will prompt to overwrite it; passes `--no-open` so no browser
  tab opens during the interview
- `Skill` added to `allowed-tools` in `skills/plan-interview/SKILL.md`
  frontmatter so both `plan-to-html` invocations run without a mid-skill
  permission prompt

## [1.18.0] - 2026-05-13

### Added

- `commands/review-rename-plans.md` now invokes the `plan-to-html` skill after
  each rename (new Step 5 — Generate HTML for renamed files):
  - Prompts for a theme once up-front (single `AskUserQuestion` across all
    files), then calls `plan-to-html` with `--no-open` per renamed file so
    the browser doesn't launch for each one
  - Stale `.html` files alongside a renamed `.md` are migrated with `git mv`
    before the new HTML is generated
  - `Skill` added to `allowed-tools` frontmatter
- `commands/plan-hygiene.md` now includes an HTML Generation section (Steps
  A–E) that runs after the rename batch:
  - Single up-front theme prompt reused across all renamed files
  - Calls `plan-to-html --no-open` per file; the browser is not opened during
    batch operation
  - Stale `.html` migration via `git mv` before regeneration
  - HTML files are committed in a separate commit from the renames, so git
    history stays clean
  - `Skill` added to `allowed-tools` frontmatter
- Two new `plan-to-html` flags wired in by both commands:
  - `--theme=<name>` — passes a pre-selected theme, skipping the interactive
    theme prompt inside the skill
  - `--no-open` — suppresses the browser-open step; used for batch runs to
    avoid opening a tab per file

## [1.17.0] - 2026-05-13

### Changed

- `plan-to-html` skill and command upgraded with richer interactive output,
  inspired by the "Unreasonable Effectiveness of HTML" approach:
  - **JavaScript allowed**: inline `<script>` block (no external dependencies)
    implements scroll-spy navigation and step completion tracking
  - **Scroll spy**: `IntersectionObserver` highlights the active sidebar section
    link as the user scrolls
  - **Step completion checkboxes**: each step card now has a checkbox; checked
    state persists in `localStorage` keyed by document title; progress bar updates
    dynamically as steps are checked
  - **Progress indicator**: thin horizontal bar in `<header>` initialized from
    plan status (5% todo → 50% in-progress → 100% completed) and updated live by
    step checkboxes
  - **Inline markdown rendering**: `**bold**`, `*italic*`, `` `code` ``,
    `[links](url)`, `~~strikethrough~~`, fenced code blocks, lists, and paragraph
    breaks are converted to proper HTML elements (applied after HTML-escaping)
  - **Step card hover**: subtle `box-shadow` lift and `translateY(-1px)` on hover;
    completed cards show `line-through` on the action text
  - **Print styles**: `@media print` block hides nav and progress bar, flattens
    layout, appends link hrefs, and removes card shadows for clean PDF export
  - **`scroll-behavior: smooth`** on `<html>` for anchor navigation
  - **Two new CSS variables** added to all four themes: `--color-card-bg` and
    `--color-code-bg` for step card and inline code backgrounds
  - **Inline code and fenced code blocks** styled with monospace font and theme-
    appropriate background (`<code>` and `<pre><code>` elements)
  - `html-spec.md` reorganized to include JavaScript Features, Markdown Rendering,
    Progress Indicator, and Print Styles sections

## [1.16.0] - 2026-05-12

### Changed

- `disable-model-invocation: true` on `deep-grill` — manual invocation only via `/plan-interview:deep-grill`; no longer auto-triggers on intent match.
- `disable-model-invocation: true` on `documenting-plans` — manual invocation only via `/plan-interview:documenting-plans`; no longer auto-triggers on intent match.

## [1.15.0] - 2026-05-11

### Added

- New `plan-to-html` skill and command — converts any plan markdown file into a
  rich, self-contained HTML document with sticky sidebar navigation, color-coded
  status badge, and three-line step cards (action / why / verify)
- Four selectable color themes: Default (neutral/blue), Developer (dark/green),
  Document (warm/sepia), Minimal (pure white/black)
- New `skills/plan-to-html/reference/html-spec.md` — companion reference file
  defining the HTML layout contract, semantic requirements (heading hierarchy,
  landmark elements, ≥4.5:1 contrast), theme CSS custom properties, and
  responsive breakpoint; keeps `SKILL.md` under 500 lines
- Overwrite prompt when the output `.html` file already exists
- Option to open the generated HTML in the browser after writing

## [1.14.6] - 2026-05-07

### Changed

- Collapsed `deep-grill` and `plan-interview` skill descriptions from multi-line YAML to single-line inline strings starting with "Use when..." for reliable auto-activation
- Converted `plan-documenter` agent `tools:` from YAML list format to inline CSV, matching all other agent definitions in the plugin

## [1.14.5] - 2026-04-20

### Changed

- Simplify all four skill descriptions to use the terse `(or agentic plan)`
  form instead of the verbose "The word 'agentic' is optional in the
  trigger" phrasing introduced in 1.14.4. Same activation behavior, shorter
  descriptions.

## [1.14.4] - 2026-04-20

### Fixed

- Clarify that "agentic" is an **optional** trigger keyword, not a scope
  declaration. Previous 1.14.3 phrasings like "including agentic plans and
  agentic workflows" read as if the skills specifically handle agentic
  plans. Reworded all four skill descriptions so existing triggers work
  unchanged and "agentic" is surfaced as an optional variant
  (e.g., "stress test this plan" and "stress test my agentic plan" both
  activate).

## [1.14.3] - 2026-04-20

### Added

- Accept "agentic" as an activation trigger across the `plan-interview`,
  `deep-grill`, `plan-status`, and `documenting-plans` skills so phrasings
  like "stress test my agentic plan" or "document my agentic plan" reliably
  match. Also added "agentic" to the marketplace tags, plugin keywords, and
  README trigger examples.

## [1.14.2] - 2026-04-20

### Fixed

- `plan-interview` skill now activates reliably for the unhyphenated phrasing
  "stress test" in addition to "stress-test". Expanded the SKILL.md
  description to surface common user phrasings ("stress test this plan",
  "stress test plan", "interview my plan", "pressure-test") so the skill
  matcher triggers consistently regardless of hyphenation.

## [1.14.1] - 2026-04-15

### Fixed

- Removed non-functional `permissionMode: bypassPermissions` from plan-documenter
  agent — plugin agents do not support this field per
  [official docs](https://code.claude.com/docs/en/plugins-reference)
- Removed `AskUserQuestion` from agent tools (not usable from agent context)
- Added "Permission model" section to README explaining interactive vs scheduled
  execution behavior
- Added "Limitations" section to agent file documenting plugin agent constraints
- Updated agent Step 5 to pass explicit slug and overwrite arguments to the
  documenting-plans skill, avoiding interactive prompts

## [1.14.0] - 2026-04-15

### Added

- New `plan-documenter` agent — batch scans the plans directory for completed
  plans that lack corresponding documentation in `docs/`, then invokes the
  `documenting-plans` skill for each one automatically
- Resolves plan directory from `.claude/settings.json` `plansDirectory` setting,
  falls back to `docs/plans/`
- Strict pre-filter: only processes plans with explicit `status: completed` in
  YAML frontmatter
- Processes alphabetically with partial progress reporting; subsequent runs skip
  already-documented plans
- Interactive batch operation — user approves permission prompts as they appear;
  for unattended runs, use remote triggers with an inline prompt
- Designed for scheduled weekly runs via Claude Code remote triggers

## [1.13.0] - 2026-04-14

### Added

- New `documenting-plans` skill and command — generates developer-friendly
  prose documentation at `docs/<slug>.md` from a completed plan file
- Automatically gates on `status: completed`; delegates to `plan-status` via
  the `Skill` tool to verify or promote completion when needed
- Synthesizes the doc from three sources: the plan body (Context, Objective,
  Steps with *Why:*, Files to Create/Modify), live code inspection of every
  backtick-cited file path, and a scoped `git log --since/--until` over the
  plan and its referenced files
- Output template includes: title + summary blockquote, shipped-date badge,
  "What shipped" capabilities list (with CHANGELOG citation), "Files changed"
  table (Created/Modified/Relocated/Missing), "How it works" prose walkthrough,
  optional "How to use it" (only when user-facing surface exists), commit
  history table, and a References section
- Refresh mode preserves hand-edited content outside `<!-- generated:start -->`
  / `<!-- generated:end -->` markers; overwrites content inside the markers
- Output slug derived from plan filename verbatim (no prefix-stripping);
  user confirms before writing
- Plan link in generated doc is computed as a relative path from the output
  file to the resolved plan — survives non-default `plansDirectory` settings

## [1.12.0] - 2026-03-29

### Added

- New `update-plan-status` command — processes multiple plan files in a directory,
  analyzing codebase evidence and writing YAML frontmatter in bulk with a
  summary-first, bulk-approval UX instead of per-file confirmation
- Stricter token filter in batch mode to avoid noisy scoring across many files
  (excludes version strings, JSON values, API routes, git refs)
- Three summary flags: `30d+ old` (auto-artifact), `no signals` (zero-signal
  files), `docs plan` (documentation-focused plans; review recommended)
- Category-based override shortcuts: Auto-artifacts, Review-flagged,
  No-signals, Specific files

## [1.11.0] - 2026-03-29

### Added

- New `type` frontmatter field for completed plans — values: `standard`
  (default) or `artifact` (valuable project documentation)
- Step 5 now always prompts the user to classify a completed plan as `standard`
  or `artifact`; plans 30+ days old show a contextual nudge toward `artifact`

### Changed

- `artifact` removed as a status value — now exists only as `type: artifact`
  on completed plans
- Status values simplified to three: `todo`, `in-progress`, `completed`
- Step 5 renamed from "Artifact check" to "Type classification"; sets `type`
  instead of changing status
- Step 6 summary table includes a `Type` row for completed plans
- Step 7 frontmatter writes now include `type` when status is `completed`
- Manual status prompt (zero-signal plans) no longer offers `artifact` as an
  option
- Legacy `status: artifact` plans are automatically normalized to
  `status: completed` + `type: artifact` when re-processed
- `commands/plan-status.md` updated to mirror all SKILL.md changes

## [1.10.0] - 2026-03-28

### Added

- New `deep-grill` skill — standalone deep grill session that walks each branch
  of a plan's design tree, asks focused questions at every decision node, and
  explores the codebase to resolve them. Can be invoked independently on any
  plan file at any time.
- New `deep-grill` command for explicit invocation via
  `/plan-interview:deep-grill [plan-file-path]`

### Changed

- Deep grill removed from plan-interview skill (was Step 4) — replaced with a
  callout directing users to the standalone `deep-grill` skill
- Plan-interview skill steps renumbered: former Steps 5–7 are now Steps 4–6
- Step 0 todo list updated to remove deep grill entry and reflect new numbering
- Summary template `Deep Grill Findings` section removed (standalone skill
  produces its own summary)

## [1.9.1] - 2026-03-26

### Changed

- Deep grill step (Step 4) is now optional — uses `AskUserQuestion` to prompt
  the user before starting; if declined, skips directly to Step 5
- Step 0 todo label updated to reflect optional status

## [1.9.0] - 2026-03-26

### Changed

- Deep grill promoted from optional Step 4.5 to mandatory Step 4 — now always
  runs after the structured interview rounds instead of requiring user opt-in
- Former Step 4 (Surface out-of-scope concerns) renumbered to Step 5
- Former Step 5 (Compile summary) renumbered to Step 6
- Former Step 6 (Offer to save findings) renumbered to Step 7
- Step 0 todo list updated to reflect new step numbering
- Summary template now always includes a **Deep Grill Findings** section

## [1.8.0] - 2026-03-26

### Added

- New `plan-status` skill and command — determines plan lifecycle status
  (`todo`, `in-progress`, `completed`, `artifact`) by inspecting the codebase
  for implementation evidence, then writes status and dates to plan YAML
  frontmatter
- Codebase analysis extracts inline backtick tokens from plan body, checks
  existence via `Glob`/`Grep`, and scores: 0% = todo, 1–79% = in-progress,
  80%+ = completed
- Artifact promotion prompt: plans completed 30+ days ago (by `modified` date)
  are offered `artifact` status to preserve them as project documentation
- Handles zero-signal plans (no backtick tokens) with a manual status prompt
- Zero `stat` dependency — date detection uses git log only, with current date
  as fallback for untracked files

## [1.7.0] - 2026-03-26

### Added

- SKILL.md files accepted as review targets in both the skill and command — skill detection runs automatically after file resolution in Step 1
- Step 2.5: Skill Tool Analysis (skill-review mode only) — scans skill instruction body for tool references, classifies each as Declared / Missing / Undeclared, and outputs a suggested `allowed-tools` line for the paired command file
- Step 6 in skill-review mode: offers to apply the `allowed-tools` recommendation directly to the paired command file
- `Grep` and `Bash` added to the command's `allowed-tools` frontmatter (both were already used but undeclared)

### Note

`allowed-tools` is not supported in SKILL.md files (skill frontmatter). The tool recommendation targets paired command files in `commands/`.

## [1.6.0] - 2026-03-26

### Added

- Optional deep grill step (Step 4.5) in the plan-interview skill — relentlessly walks every decision branch, provides recommended answers, and explores the codebase when answers can be found there. Findings feed into the Step 5 summary under a new **Deep Grill Findings** section.

## [1.5.0] - 2026-03-14

### Added

- PostToolUse hook on `ExitPlanMode` — prompts user to run plan-interview after exiting plan mode

## [1.4.0] - 2026-03-10

### Added

- New `plan-hygiene` command — batch scans plan directories for randomly-named files and renames them to descriptive kebab-case names based on content headings
- Rules section in README with copyable pre-commit plan hygiene rule

## [1.3.0] - 2026-02-26

### Added

- New `review-rename-plans` command — reviews plan filenames against their content and offers to rename files whose names don't match their intent, with support for single-file and batch modes

## [1.2.0] - 2026-02-26

### Added

- Plan name validation in Step 2 — checks whether the filename and H1 heading are descriptive and aligned with the plan's content, suggests better names when they are random or generic, and offers to rename the file

## [1.1.0] - 2026-02-24

### Added

- Add TodoWrite progress tracking (Step 0) to both `SKILL.md` and command file — creates todos for all interview steps upfront and marks each complete as it finishes

## [1.0.0] - Initial release

- Structured multi-round plan interview skill and command
- Rounds covering technical trade-offs, UI/UX, accessibility, and edge cases
- Out-of-scope concern detection and complexity check
- Option to append interview summary to the plan file
