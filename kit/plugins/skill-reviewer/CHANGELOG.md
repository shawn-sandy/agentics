# Changelog



## v2.5.1 — 2026-08-10 — the plugin's hook actually registers

### Fixed

- **`hooks.json` was never read.** It sits at the plugin root, which is not a
  discovery path — the documented one is `hooks/hooks.json`. Measured with a
  controlled A/B: identical deliberately-corrupt JSON is reported by
  `claude plugin validate` at `hooks/hooks.json` ("At runtime this breaks the
  entire plugin load") and passes unread at the plugin root. `plugin.json` now
  declares `"hooks": "./hooks.json"` explicitly, which is the same mechanism by
  which plugins pointing at a non-standard hooks filename do fire.
- Consequence for this plugin: the `PostToolUse` hook that warns when a
  SKILL.md `description:` exceeds the skill-listing budget was not firing for
  installed users. Its logic is unchanged.

## v2.5.0 — 2026-08-02 — Two dead script invocations become `bin/` commands

### Fixed

- **The documented invocation could never run — for anybody, at any permission
  level.** Claude Code's Bash tool refuses any command whose text contains
  `${VAR}` or `$VAR`, erroring with `Contains expansion` because it cannot
  statically resolve the expansion. The refusal fires *before* permission rules
  are consulted, so no `allowed-tools` entry, `tools:` grant, or permission rule
  can rescue it — a prefix rule like ``Bash(python3 "${CLAUDE_PLUGIN_ROOT}/...":*)``
  can never match, because the command is rejected before rule matching begins.
  `${CLAUDE_PLUGIN_ROOT}` compounds this: it is a config-file substitution for
  `hooks.json`, MCP/LSP, and monitor commands, and is not exported into the Bash
  tool's environment, so it would expand to empty even if the guard allowed it.
- **The fix is a `bin/` wrapper invoked by bare name.** Claude Code adds a
  plugin's `bin/` directory to the Bash tool's `PATH`, so a bundled script is
  callable as a bare command containing no `$` at all. The wrapper resolves its
  own location via `dirname "$0"` — legal, because the expansion guard inspects
  only the command text passed to the Bash tool, not what the shell then runs.
  A literal absolute path could not ship instead: the install path differs per
  machine.
- **Guarded by `tests/plugins/test-no-shell-expansion.sh`,** a repo-wide check
  that fails on any documented interpreter invocation carrying an expansion, on
  any bundled script invoked via a braced expansion in command position, on a
  wrapper that loses its exec bit or its target, and on `bin` falling off the
  `dist/` KEEP allowlist.

### Changed

- `auditing-allowed-tools`: the session scan is now `skill-reviewer-scan-tools <jsonl-path>`.
- `/check-description`: now `skill-reviewer-measure-description <file>`. This
  second site had no interpreter prefix — it invoked
  `"${CLAUDE_PLUGIN_ROOT}/scripts/measure-description.sh"` directly — so it was
  invisible to a scan that looks for `python3`/`node`/`bash` and was found only
  when the new test's command-position pattern was written.

## v2.4.0 — 2026-07-30 — Drop "Follow these steps exactly" from `optimizing-skill-frontmatter`

### Changed

- **`optimizing-skill-frontmatter` drops its "Follow these steps exactly."
  line.** The numbered `## Step N` headings already impose the order, and this
  skill is the rubric other skills are measured against — it should not model a
  process reminder it would flag elsewhere.
- **The `disable-model-invocation: false` prohibition is untouched**, as is the
  rest of Step 4b. This skill rewrites other skills' frontmatter, so a dropped
  prohibition would propagate a defect into every file it touches.

### Testing

- **Baseline recorded and reproduced before the prune** (`ed6b854`). The skill
  was run headless against a fixture SKILL.md with a deliberately over-budget,
  trigger-less description and no `disable-model-invocation` line; the recorded
  manifest asserts it never writes the forbidden `false` value and never
  destroys the file it is editing. It reproduced exactly after the prune.
- Guarded by `tests/plugins/test-imperative-pruning.sh`, now wired into
  `check-plugin-versions.yml`.

## v2.3.0 — 2026-07-29 — Split `optimizing-skill-frontmatter` into a core plus references

### Changed

- **`optimizing-skill-frontmatter` is now a 579-word core plus four reference
  files, down from 3,131 words in a single body.** A SKILL.md body is paid in full
  every time the skill fires, and this was the largest monolithic skill in the
  repo — while also being the rubric every other skill is measured against, so it
  was violating the progressive-disclosure advice it teaches.
  - `references/description-rules.md` — Rules 1–5, Rule 2b, worked examples A and
    B, and the Step 4 edit order
  - `references/invocation-control.md` — the Step 4b classification table,
    confirmation options, and grep-then-`Edit` apply rules
  - `references/measurement.md` — the Step 2, 5, and 6 measuring loops
  - `references/budget-advisory.md` — the `skillListingBudgetFraction` advisory,
    the installed-skills table, and the `/doctor` guidance
- Dropped a pointer to `references/best-practices.md`, which never resolved from
  this skill's directory (the file lives under `reviewing-skills`).

Behaviour, `description:`, `allowed-tools:`, and `disable-model-invocation: true`
are unchanged. `tests/plugins/test-remaining-skill-splits.sh` pins the core
ceiling, the reference wiring, and the untouched frontmatter.

## v2.2.9 — 2026-07-28 — Collapse the plan-mode guard to one line

- `optimizing-skill-frontmatter` replaces its `ExitPlanMode` preamble with the
  canonical one-line guard. Its Step 4b classification table still lists an
  `ExitPlanMode` Step 0 as a workflow signal — that reference is unchanged.

## v2.2.8 — 2026-07-20 — Refresh the skill-splitting example

### Fixed

- `reviewing-skills/references/best-practices.md`: the multi-skill directory example named `agentic-memory-doctor`, which no longer exists — renamed to `agentic-memory-management` to match memory-tools v4.0.0.

---

## v2.2.7 — 2026-07-16 — State one description budget, not two

### Fixed

- `scripts/measure-description.sh`, `commands/check-description.md`: the enforced threshold is now 200 chars, matching the rule in `optimizing-skill-frontmatter`. It previously warned at 160 while the rule said 200, which made compliant skills look like failures. 160 remains documented as a conservative advisory target for ~50 installed skills.

---

## v2.2.5 — 2026-06-05 — Use portable paths for asset references

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/skill-reviewer` path instead of an author-specific home directory.
- `auditing-allowed-tools`: invoke `session_tool_scan.py` via `${CLAUDE_PLUGIN_ROOT}` instead of a manually constructed absolute path.

---

## v2.2.3 — 2026-06-01 — Add ExitPlanMode error handling

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success

## v2.2.2 — README: update hook output example to budget-aware phrasing; sync usage docs

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

All notable changes to the `skill-reviewer` plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow [Semantic Versioning](https://semver.org/).

## [2.2.1] - 2026-05-28

### Changed

- **Default total-length target lowered 256 → 200** — `optimizing-skill-frontmatter` now targets ≤200 chars (down from ≤256). Budget math updated: 8,000 ÷ 200 = 40 skills (was ÷ 256 ≈ 31). Advisory table top row updated to `≤40 | ~200 chars`.
- **Step 2 / Step 6 threshold unified on 200** — resolves prior inconsistency where Step 2 (skip rule) used ≤256 and Step 6 (status logic) used ≤160. Both now agree on ≤200.
- `plugin-patterns.md` "Total budget" bullet updated from ≤256 to ≤200.
- `marketplace.json` description updated to reference 200-char format.

## [2.2.0] - 2026-05-27

### Added

- **Three-part description format** — `optimizing-skill-frontmatter` now produces descriptions with three components: short description (≤80 chars), capability sentence, and trigger phrase. The short description is always Sentence 1 so it survives aggressive budget truncation (~100 skills installed).
- **Rule 1 updated** — length target changed from ≤160 chars to ≤256 chars total; new sub-constraint of ≤80 chars for the first sentence (short description).
- **Rule 2 updated** — three-part format replaces two-sentence format. Fixed order: short description → capability → trigger.
- **Rule 2b extended** — generates missing short description by compressing the first `## Overview` sentence to ≤80 chars and prepending as Sentence 1. All three missing-component cases now handled independently.
- **Step 2 skip rule updated** — SKIP requires all three components present, total ≤256, and short description ≤80 chars. Any missing component or length violation triggers REWRITE.
- **Step 5 verification updated** — now measures first sentence length separately in addition to total length; flags both total-only and short-only violations.
- **Budget advisory table updated** — new ≤31 skills / ~256 chars row; ~100 skills / ~80 chars row explains short-description survival guarantee.

### Changed

- `optimizing-skill-frontmatter` frontmatter `description:` updated to three-part format (188 chars; short description = 38 chars).
- Overview and "Why 160 chars?" section renamed to "Why three-part format?" with updated budget math.
- `plugin-patterns.md` Skill Description Format bullet updated to document three-part format and ≤256-char total budget.
- `marketplace.json` description updated to reference three-part 256-char format.

## [2.1.0] - 2026-05-26

### Added

- **Two-sentence description format** — `optimizing-skill-frontmatter` now requires and produces descriptions with both a capability sentence *and* a trigger phrase, aligning with Anthropic's authoring checklist ("Description includes both what the Skill does and when to use it"). A trigger-only description (≤160 chars but missing the capability component) is now a REWRITE candidate, not a SKIP.
- **Rule 2 rewritten** — targets two-sentence format (capability first, trigger second per Pattern 1 in best-practices). Either order accepted; preferred: `[Capability.] Use when the user asks to [trigger].`
- **Rule 2b (new)** — generates a missing capability sentence from the skill body's `## Overview` section when only a trigger phrase is present; generates a missing trigger phrase when only capability is present.
- **Rule 5 updated** — explicitly excludes capability sentences from stripping. "Implementation-detail sentences" are no longer removed from descriptions — they are the required capability component.
- **Worked example B** — new example demonstrating Rule 2b: adding a capability sentence to a trigger-only description (131 → 136 chars).
- **`reviewing-skills` Dimension 1** — new check: description should contain a capability statement, not only "Use when…". Missing capability → Warning → 1 pt instead of 2 pts.
- **`reviewing-skills` Quick Reference Checklist** — new item: "Description contains a capability statement (not only the trigger phrase)."
- **`references/best-practices.md`** — added `Capability statement` row to the Description Field requirements table; replaced old single-sentence Trigger phrase examples with three named patterns (Pattern 1: two-sentence recommended; Pattern 2: trigger-first; Pattern 3: explicit phrases fallback).

### Changed

- `optimizing-skill-frontmatter` description updated to self-demonstrate the two-sentence format: `"Trims SKILL.md descriptions to ≤160 chars and tunes disable-model-invocation. Use when the user asks to optimize SKILL.md frontmatter."` (was trigger-only, 131 chars)
- Skip rule tightened: SKIP now requires both trigger AND capability; trigger-only descriptions are REWRITE regardless of char count
- `plugin-patterns.md` "Skill Activation" bullet — removed "WHEN (not what)" guidance that contradicted Anthropic's own checklist; replaced with "Skill Description Format" covering the two-sentence pattern
- `plugin-patterns.md` code example updated to show two-sentence description format
- Worked example A retitled (was "Worked example"); updated After to 159-char two-sentence format

## [2.0.0] - 2026-05-12

### BREAKING

- Skill renamed from `optimizing-skill-descriptions` → `optimizing-skill-frontmatter`. Update any saved invocations from `/skill-reviewer:optimizing-skill-descriptions` to `/skill-reviewer:optimizing-skill-frontmatter`.

### Added

- **Step 4b: Tune invocation control** — after applying description edits, classifies each touched SKILL.md as workflow or advisory using `allowed-tools` and `description:` verb heuristics, then recommends and (on confirmation) applies the correct `disable-model-invocation` value. Confident and ambiguous cases both go through `AskUserQuestion` before any change is written. Never writes `disable-model-invocation: false` — omit-the-field convention is preserved for advisory skills.

### Changed

- Skill `name:` frontmatter: `optimizing-skill-descriptions` → `optimizing-skill-frontmatter`
- Skill `description:` updated to cover both `description` trimming and `disable-model-invocation` tuning (132 chars)
- Overview and "When not to use" sections updated to reflect the broader frontmatter scope
- Table of Contents adds Step 4b entry
- `scripts/measure-description.sh` WARNING strings now point to `/skill-reviewer:optimizing-skill-frontmatter`
- `commands/check-description.md` updated to reference new skill name
- `README.md` skill list entry #4, sample WARNING line, directory tree, and closing usage hint updated

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
