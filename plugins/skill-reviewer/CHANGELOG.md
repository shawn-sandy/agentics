# Changelog

All notable changes to the `skill-reviewer` plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow [Semantic Versioning](https://semver.org/).

---

## [1.0.1] - 2026-02-25

### Changed

- `SKILL.md` — replaced H1 title with H2 (frontmatter `name` serves as machine-readable title)
- `SKILL.md` — added table of contents (file is 101 lines, over the >100-line threshold)
- `SKILL.md` — added `Follow these steps exactly.` to Overview (freedom level now explicit)

## [1.0.0] - 2026-02-25

### Added

- `reviewing-skills` skill — structured 5-dimension audit of SKILL.md files against Anthropic's Claude Code skill authoring best practices
- Scoring rubric: frontmatter validity, body quality, structure & progressive disclosure, anti-pattern detection, discoverability (2 pts each, max 10)
- Graded report output: Excellent (9-10), Good (6-8), Needs Work (3-5), Rewrite (0-2)
- Fix generation: auto-corrects frontmatter errors; flags body issues with inline `<!-- SUGGESTION -->` comments
- Live guidelines fetch from platform docs URL with silent fallback to static reference
- Two-confirmation write guard before overwriting files on disk
- `references/best-practices.md` — detailed criteria with good/bad examples and naming convention tables
- `references/audit-steps.md` — complete Steps 3-6 workflow including scoring rubric, report format, and write confirmation
- Quick reference checklist in SKILL.md for rapid pre-audit assessment
