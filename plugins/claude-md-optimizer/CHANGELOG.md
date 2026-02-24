# Changelog

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
