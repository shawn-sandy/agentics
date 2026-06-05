# Changelog

## v1.2.3 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/wcag-compliance-reviewer` path instead of an author-specific home directory.

---

## v1.2.2 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

All notable changes to this project will be documented in this file.

## [1.2.1] - 2026-05-07

### Changed

- Reordered `wcag-compliance-reviewer` skill description to start with "Use when..." for reliable auto-activation

## [1.2.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.1.0] - 2026-02-25

### Changed

- **Default standard upgraded from WCAG 2.1 to WCAG 2.2** across all plugin files
- `SKILL.md` — WCAG 2.2 is now the default review standard; 2.1 available on request
- `SKILL.md` — Systematic Review (Section 4) adds six new WCAG 2.2 AA criteria
- `SKILL.md` — Quick Reference Checklist includes WCAG 2.2 items
- `SKILL.md` — Section 4 Robust notes 4.1.1 Parsing as removed in WCAG 2.2
- `wcag-aa-guidelines.md` — corrected 2.4.11 from "Focus Appearance" to "Focus Not Obscured (Minimum)"
- `check_wcag.py` — focus outline removal upgraded from warning to error (2.4.7, 2.4.11)
- `common-violations.md` — added six new sections with before/after code examples for WCAG 2.2 criteria
- `testing-guide.md` — updated references to WCAG 2.2; manual testing checklist extended
- `README.md` — all WCAG 2.1 references updated to WCAG 2.2; new criteria added
- `plugin.json` and `marketplace.json` — version 1.1.0; descriptions and tags updated

### Added

- New WCAG 2.2 criteria in review process: Focus Not Obscured (2.4.11), Dragging Movements (2.5.7), Target Size (2.5.8), Consistent Help (3.2.6), Redundant Entry (3.3.7), Accessible Authentication (3.3.8)
- New violation examples: Target Size, Focus Not Obscured, Dragging Movements, Accessible Authentication, Redundant Entry, Consistent Help
- New Python checks: `target-size`, `dragging-movements` rules

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
