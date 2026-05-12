# Changelog

All notable changes to the `skill-reviewer` plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow [Semantic Versioning](https://semver.org/).

## [1.9.0] - 2026-05-12

### Changed

- `disable-model-invocation: true` on `optimizing-skill-descriptions` — manual invocation only via `/skill-reviewer:optimizing-skill-descriptions`; no longer auto-triggers on intent match.

## [1.8.1] - 2026-05-12

### Changed

- Renamed `optimizing-descriptions` skill to `optimizing-skill-descriptions` (directory + `name` frontmatter). Invoke as `/skill-reviewer:optimizing-skill-descriptions`. Updated README, `check-description.md`, and `scripts/measure-description.sh` to reference the new name.

## [1.8.0] - 2026-05-11

### Added

- **`hooks.json`** — PostToolUse hook warns when a SKILL.md `description:` exceeds the 160-char skill-listing budget. Fires on `Write|Edit|MultiEdit`, skips non-SKILL.md files and paths outside the current git repo, deduplicates via `/tmp` hash cache so it only fires when the `description:` line actually changes.
- **`commands/check-description.md`** — `/skill-reviewer:check-description [path-or-glob]` slash command for on-demand batch measurement of one or many SKILL.md files.
- **`scripts/measure-description.sh`** — shared POSIX script (single source of truth for both hook and command). Handles missing `description:`, multi-line/folded YAML block scalars, exact character counting, and emits `OK:`/`WARNING:`/`ERROR:` output.
- **`tests/fixtures/skill-description-hook/`** — bash test harness (`run.sh`) with 5 fixture SKILL.md files: exactly-160 (OK), exactly-161 (WARNING), 200 chars (WARNING), missing description (ERROR), multi-line scalar (WARNING).

## [1.7.0] - 2026-05-11

### Added

- **`optimizing-descriptions` skill** — Rewrites `description:` frontmatter across SKILL.md files to ≤160 characters while preserving activation accuracy. Relocates negative-scope clauses to `## When not to use` body sections. Includes a worked example and a skip rule for already-compliant descriptions.

### Changed

- Trimmed all 28 skill descriptions across the marketplace to ≤160 chars
- Relocated negative-scope clauses (“Does not cover X”) from descriptions into `## When not to use` body sections in 22 skills

## [1.6.2] - 2026-05-07

### Changed

- Reordered `reviewing-skills` and `planning-skills` skill descriptions to start with “Use when...” for reliable auto-activation

## [1.6.1] - 2026-05-07

### Changed

- Trimmed marketplace tags: removed `running-tests`, `session-audit`, and `claude-code` — these describe internal implementation details rather than user-searchable intents

## [1.6.0] - 2026-04-11

### Added

- **`auditing-allowed-tools` skill** — Audits a SKILL.md to recommend (or patch)
  the minimal `allowed-tools` frontmatter it needs so users aren’t prompted for
  permission mid-run. Also parses Claude Code session JSONL transcripts to
  report what tools Claude actually invoked during a session, and can
  cross-reference a skill’s declared `allowed-tools` against real session usage.
- **Three operating modes**: static SKILL.md audit, session tool-usage scan,
  and skill ↔ session cross-reference.
- **Selection picker** — when no target is specified, globs `**/SKILL.md` under
  `$PWD` and lets the user pick via `AskUserQuestion`. Handoff from
  `reviewing-skills` is supported via conversation context.
- **Three apply modes** for patching `allowed-tools`: add missing only, replace
  with minimal set, or report-only.
- **`scripts/session_tool_scan.py`** — standalone Python 3 script (no deps)
  that streams JSONL line-by-line, tolerates truncated final lines in
  active sessions, aggregates subagent transcripts on request, and suggests
  restricted `Bash(<cli> *)` entries when only one CLI family is observed.

---

## [1.5.0] - 2026-04-09

### Changed

- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

---

## [1.4.0] - 2026-03-03

### Added

- **`running-tests` skill** — Adaptive skill that identifies changed files (via git or user input), finds related test files using naming conventions, detects the test framework, runs tests via Bash, and reports pass/fail/error counts
- **Missing test detection** — identifies source files with no test file and provides conventional test file path suggestions (file-level advisory)
- **`references/test-runner-guide.md`** — per-framework lookup tables for naming conventions, detection signals, run commands, result parsing, and missing test advisory templates

---

## [1.3.0] - 2026-03-03

### Added

- **Step 2c: Regression Risk Check** — optional git-based comparison against last committed version
- **Comparison matrix** with 6 fields classified as BREAKING | WARNING | INFO:
  - `name:` change (BREAKING)
  - Trigger phrase removal from `description:` (BREAKING)
  - Activation intent degradation — `Use when...` clause absent or <3 original keywords survive (WARNING)
  - Reference file removal (WARNING)
  - >30% line reduction (WARNING)
  - New anti-patterns introduced (INFO)
- **Regression Risk section** in audit report — after Scores table, before Grade; does not affect 1–10 score
- **Quick Reference Checklist** — new Regression Risk block (6 items)
- Graceful skip: auto-skipped if not in git, file untracked, or user opts out
- Step 5 BREAKING warning — prepends advisory note before optimized version offer when BREAKING findings exist

---

## [1.2.0] - 2026-02-27

### Added

- **Workflow patterns** in `best-practices.md` — four new content patterns with examples: checklist workflow, feedback loop, template pattern (strict vs. flexible), and conditional workflow
- **Token budget consciousness** section in `best-practices.md` — concise vs. verbose example; guidance on challenging each paragraph
- **Script quality anti-patterns** in `best-practices.md` and `audit-steps.md` — five new checks: assumed installs, unqualified MCP tool references, voodoo constants, script punts to Claude on error, verbose over-explanation
- **MCP Tool References** section in `best-practices.md` — `ServerName:tool_name` format requirement with bad/good examples
- **Evaluation-driven development** section in `best-practices.md` — evaluation structure, iterative refinement cycle (Claude A → Claude B → observe → refine)
- **Feedback loop check** added to Dimension 3 (Structure) in `audit-steps.md` — Suggestion if absent in iterative/quality-critical skills
- **Script detection rule** in `audit-steps.md` Dimension 4 — defines when script-related checks apply (`scripts/` folder or bash/python code blocks with external tool invocations)
- New checklist items in `SKILL.md` Quick Reference: checklist workflow, no-options-without-default, assumed installs, feedback loop, Scripts section (MCP format, magic numbers, error handling, install instructions)

### Changed

- **Scoring threshold (backward-incompatible):** Body Quality Dimension 2 Ideal threshold changed from `<400 lines` to `<500 lines`, aligning with official Anthropic documentation (“under 500 lines for optimal performance”). Skills in the 400–499 line range now score 2/2 instead of the previous 1/2 — existing audits will show higher scores.
- `audit-steps.md` — removed `400–499 Warning` tier from line count; simplified to two bands: `<500` (Ideal) and `≥500` (Error)
- `audit-steps.md` — updated Dimension 2 scoring: 2pts threshold is now `<500 lines AND <3,000 words` (was `<400`)
- `audit-steps.md` Step 4 report template — updated `code.claude.com` → `platform.claude.com` in Guidelines Source line
- `best-practices.md` line count table — updated to reflect `<500` Ideal threshold; removed 400–499 Acceptable band
- `best-practices.md` TOC — added entries for all new sections
- `SKILL.md` live fetch URL — corrected `code.claude.com` → `platform.claude.com`
- `README.md` — updated scoring dimension table to reflect new anti-patterns (script checks, MCP format, assumed installs) and threshold change note

## [1.1.0] - 2026-02-26

### Added

- `planning-skills` skill — guided workflow for planning, designing, and scaffolding new Claude Code skills from scratch
- `references/design-patterns.md` — comprehensive reference for four Anthropic design patterns (Sequential, Orchestrator, Iterative, Adaptive) with decision tree and combination guidance
- Design pattern identification in the `reviewing-skills` audit (Sequential, Orchestrator, Iterative, Adaptive)
- Word count check (5,000-word threshold per Anthropic’s guide) alongside existing line count check
- Folder structure validation (kebab-case naming, SKILL.md casing, scripts/references/assets subdirectories)
- Three-level progressive disclosure assessment (frontmatter → body → linked files)
- Skill Pack documentation and validation guidance
- New anti-patterns: wrong SKILL.md casing, hardcoded absolute paths, non-kebab-case folders, exceeding 5,000 words

### Changed

- `best-practices.md` — expanded with Anthropic guide criteria: three-level progressive disclosure, folder structure rules, design patterns section, skill packs, word count thresholds
- `audit-steps.md` — enriched Dimensions 2–4 with word count, folder structure, SKILL.md casing, and new anti-pattern checks; report format now includes word count, folder structure, and design pattern
- `reviewing-skills` SKILL.md — Step 2 now measures word count, folder structure, and design pattern; Quick Reference Checklist expanded with new checks

## [1.0.1] - 2026-02-25

### Changed

- `SKILL.md` — replaced H1 title with H2 (frontmatter `name` serves as machine-readable title)
- `SKILL.md` — added table of contents (file was at the 100-line threshold; TOC required at ≥100 lines)
- `SKILL.md` — added `Follow these steps exactly.` to Overview (freedom level now explicit)

## [1.0.0] - 2026-02-25

### Added

- `reviewing-skills` skill — structured 5-dimension audit of SKILL.md files against Anthropic’s Claude Code skill authoring best practices
- Scoring rubric: frontmatter validity, body quality, structure & progressive disclosure, anti-pattern detection, discoverability (2 pts each, max 10)
- Graded report output: Excellent (9-10), Good (6-8), Needs Work (3-5), Rewrite (0-2)
- Fix generation: auto-corrects frontmatter errors; flags body issues with inline `<!-- SUGGESTION -->` comments
- Live guidelines fetch from platform docs URL with silent fallback to static reference
- Two-confirmation write guard before overwriting files on disk
- `references/best-practices.md` — detailed criteria with good/bad examples and naming convention tables
- `references/audit-steps.md` — complete Steps 3-6 workflow including scoring rubric, report format, and write confirmation
- Quick reference checklist in SKILL.md for rapid pre-audit assessment
