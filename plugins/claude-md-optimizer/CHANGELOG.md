# Changelog

## [1.4.0] - 2026-02-25

### Fixed

- Dimension 1: Removed unverifiable "instruction slot" numbers; reframed context paragraph around general context management principles
- Notes: Corrected memory hierarchy to match official Claude Code docs (managed policy → project memory → project rules → user memory → project local → auto memory)
- Dimension 4: Replaced incorrect `@import` keyword with correct `@path/to/file` import syntax
- Notes: Replaced `@import` self-reference advice with proper plugin installation guidance
- path-rules-advisor: Fixed Mode B Step 7 replacement format from H1 heading to bullet reference

### Changed

- Step 5: Removed promotional self-reference callout from optimization workflow (moved install guidance to Notes)
- README: Added `path-rules-advisor` skill to Skills table with activation triggers and usage examples for both modes
- Skill descriptions: Broadened activation triggers — added "check" and "analyze" to claude-md-optimizer; added "extract" and "move" to path-rules-advisor
- path-rules-advisor Mode A Step 1: Added handling for natural-language `$ARGUMENTS` from intent-based activation
- Step 2: Clarified instruction counting methodology (top-level bullets only, ignore code blocks)
- Step 5: Added `.env` extraction guidance when secrets are redacted

### Added

- Dimension 3/4: Added clarifying note distinguishing D3 (content relevance) from D4 (structural delegation)
- Keywords: Added "audit" and "rules" to plugin.json for better discoverability

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
