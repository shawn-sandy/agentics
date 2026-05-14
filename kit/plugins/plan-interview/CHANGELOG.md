# Changelog

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
