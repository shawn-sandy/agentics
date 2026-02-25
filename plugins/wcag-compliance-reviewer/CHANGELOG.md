# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2026-02-25

### Changed

- `SKILL.md` — replaced H1 title with H2 (frontmatter `name` serves as machine-readable title)
- `SKILL.md` — added 12-entry table of contents (file is 318 lines, over the >100-line threshold)
- `SKILL.md` — added `Follow these steps exactly.` to Review Process preamble (freedom level now explicit)

## [1.0.0] - 2026-02-24

### Added

- Initial release as a Claude Code plugin
- `wcag-compliance-reviewer` skill for reviewing HTML/CSS and React/TypeScript code against WCAG 2.1 Level AA standards
- `references/wcag-aa-guidelines.md` — complete WCAG 2.1 AA success criteria reference
- `references/common-violations.md` — before/after code examples for common violations
- `references/testing-guide.md` — automated testing tools and setup instructions
- `scripts/check_wcag.py` — static analysis script catching ~30% of accessibility issues
- Plugin manifest (`.claude-plugin/plugin.json`)
- Registered in agentics-kit marketplace
