# Changelog

## v3.1.3 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/memory-tools` path instead of an author-specific home directory.

---

## v3.1.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## [3.1.0] - 2026-05-20

### Changed

- `agentic-memory-doctor`: Added an explicit **optimization principle** near the top of `SKILL.md` — "keep only rules that change Claude's behavior vs. built-in defaults; tighten load-bearing rules to crisp imperatives."
- `agentic-memory-doctor`: Added **Default-restating rules** as a 4th hygiene item in Dimension 5 (`references/audit-steps.md`). Includes a concrete definition and examples; existing 0 / 1 / 2+ scoring scale is unchanged.
- `agentic-memory-doctor`: Added two new transformation bullets to Step 5 — "cut default-restating rules" and "tighten kept rules to crisp imperatives" — so the principle is enforced during the in-chat rewrite.
- `agentic-memory-doctor`: Added a Step 4 callout instructing the model to name "default-restating rules" by phrase when they drive a Dimension 5 deduction, so the audit report and the rewrite use consistent vocabulary.

## [3.0.0] - 2026-05-10

### BREAKING CHANGE

- Primary skill renamed from `memory-doctor` to `agentic-memory-doctor`. New invocation: `memory-tools:agentic-memory-doctor`.
- Existing `@import` references to `skills/memory-doctor/SKILL.md` will break — update to `skills/agentic-memory-doctor/SKILL.md`.

### Migration

1. Find and update any `@import` references in your CLAUDE.md:
   - Old: `@<plugin-dir>/skills/memory-doctor/SKILL.md`
   - New: `@<plugin-dir>/skills/agentic-memory-doctor/SKILL.md`
   - Find references with: `grep -rn 'skills/memory-doctor/SKILL.md' .`

## [2.0.1] - 2026-05-07

### Changed

- Added "Does NOT..." scope boundary to `path-rules-advisor` description clarifying it does not update CLAUDE.md or memory entries (use memory-doctor for that)

## [2.0.0] - 2026-05-04

### BREAKING CHANGE

- Plugin renamed from `claude-md-optimizer` to `memory-tools`.
- Primary skill renamed from `md-optimizer` to `memory-doctor`. New invocation: `memory-tools:memory-doctor`.
- Existing `@import` references to `skills/claude-md-optimizer/SKILL.md` will break — update to `skills/memory-doctor/SKILL.md`.

### Migration

1. `/plugin uninstall claude-md-optimizer@agentics-kit`
2. `/plugin install memory-tools@agentics-kit`
3. Find and update any `@import` references in your CLAUDE.md:
   - Old: `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md`
   - New: `@<plugin-dir>/skills/memory-doctor/SKILL.md`
   - Find references with: `grep -rn 'skills/claude-md-optimizer/SKILL.md' .`
4. Update `--plugin-dir` paths in any local scripts or `CLAUDE.local.md` from `kit/plugins/claude-md-optimizer` to `kit/plugins/memory-tools`.

### Added

- `Grep` added to `memory-doctor` `allowed-tools`; Step 2 secret scan now uses `Grep -nE` with exact patterns and reports line numbers (no more eyeball-matching on long files)
- Step 2 `@import` scan now reads each imported file (one level deep) and reports effective line count; imports exceeding 500 lines are skipped with a warning
- Plan-mode pre-check at top of skill: defers Steps 5–6 writes if system indicates plan mode is active
- Step 5 and Step 6 prompts now use `AskUserQuestion` for explicit Yes/No gating (replaces prose questions that could be misread as already-confirmed)
- When Progressive Disclosure scores ≤ 1, Step 4 Top 3 now recommends invoking `memory-tools:path-rules-advisor` as the preferred delegation path; inline flow kept as fallback
- Step 4 and Step 5 include `path-rules-advisor` delegation recommendation

### Changed

- Frontmatter `name` changed from `md-optimizer` to `memory-doctor`
- Frontmatter `description` tightened to two sentences; adds "diagnose" and "project memory file" terminology
- Step 1 priority clarified: when both `CLAUDE.md` and `.claude/CLAUDE.md` exist, root takes priority and alternate location is noted as skipped
- Operational rules paragraph (audit scope, opt-in steps, memory load order) moved from `references/audit-steps.md` Notes section to top of `SKILL.md` so Claude sees them before Step 3 triggers a Read
- `references/audit-steps.md` Notes section removed (content now in `SKILL.md` or covered by Dimension 6)
- `path-rules-advisor`: cross-reference updated from `claude-md-optimizer` to `memory-doctor`
- Self-reference `@import` path updated to `skills/memory-doctor/SKILL.md`

## [1.6.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.5.0] — 2026-02-27

### Changed

- Refactored SKILL.md to follow three-level progressive disclosure pattern
- Extracted Step 3 dimension scoring rubrics, example output, and notes to `references/audit-steps.md`
- Added explicit freedom level statement to skill body
- Added scope boundary to frontmatter description (excludes SKILL.md files and commands)

## [1.4.0] - 2026-02-25

### Fixed

- `claude-md-optimizer` skill: renamed `name` from `claude-md-optimizer` to `md-optimizer` — the `claude` substring is reserved and prohibited in skill names (breaking: skill reference changes from `claude-md-optimizer:claude-md-optimizer` to `claude-md-optimizer:md-optimizer`)
- `claude-md-optimizer` skill: replaced `$ARGUMENTS` and `$PWD` variable references in Step 1 with prose descriptions — these variables only expand in command files, not skills
- `path-rules-advisor` skill: replaced all `$ARGUMENTS` and `$PWD` variable references with prose descriptions for the same reason
- Both skills: added Table of Contents (required for files exceeding 100 lines)

## [1.3.0] - 2026-02-24

### Added

- Step 5: Offers to generate `.claude/rules/` files for each section extracted during optimization
- Step 5: Shows `@import` callout (after the CLAUDE.md block) for referencing the optimizer in any project
- Step 5: Checks for `.claude/rules/` directory existence; prompts to create if missing
- Dimension 4: Added `paths:` frontmatter glob examples and brace expansion patterns from official docs
- Step 4: Added standing recommendation to use Step 5 rule-file generation when Progressive Disclosure scores ≤ 1
- path-rules-advisor: Added brace expansion examples within Rule file format section
- Notes: Added official memory docs URL and self-referencing `@import` usage tip

### Changed

- Step 5: Removed `## Suggested Move to Separate Files` block — replaced by rule-file offer flow

## [1.2.0] - 2026-02-24

### Added

- New skill `path-rules-advisor`: analyzes project and CLAUDE.md to recommend and generate path-specific rule files in `.claude/rules/`
- Supports direct creation via `$ARGUMENTS` (path pattern + description) or analysis mode (no argument)

## [1.1.0] - 2026-02-24

### Added

- Step 1: Added `$PWD/.claude/CLAUDE.md` as a 3rd priority location (between primary project and global user)
- Step 2: Added `@import` scan as a 5th metric — lists any `@path/to/file` references found
- Dimension 4: Expanded Progressive Disclosure to name both delegation mechanisms: `.claude/rules/*.md` (with `paths:` frontmatter support) and external docs via `@import`
- Tips: Added memory load order bullet (project rules → project memory → user memory → project local)
- Tips: Added `/init` command tip for bootstrapping CLAUDE.md from codebase context
- Tips: Added `@path/to/file` import syntax tip
- Tips: Added `.claude/rules/*.md` modular rules tip with `paths:` frontmatter note

### Fixed

- Dimension 6 and Tips: Corrected local override filename from `CLAUDE.md.local` to `CLAUDE.local.md` (official Claude Code convention)
- Tips: Added note that Claude Code auto-adds `CLAUDE.local.md` to `.gitignore`

## [1.0.0] - 2026-02-23

### Added

- Initial release: 6-step CLAUDE.md audit skill with 6-dimension scoring rubric
