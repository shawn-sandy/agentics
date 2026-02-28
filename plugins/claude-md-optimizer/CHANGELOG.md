# Changelog

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
