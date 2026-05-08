# Changelog

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
