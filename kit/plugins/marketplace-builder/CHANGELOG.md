# Changelog

All notable changes to the marketplace-builder plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.0.0] - 2026-03-06

### Added

- Initial release
- Repository evaluation with 5-dimension scoring (Repository Foundation, Project Documentation, Code Organization, Developer Experience, Marketplace Readiness)
- Marketplace infrastructure scaffolding (marketplace.json, plugin directories, SKILL.md stubs)
- CLAUDE.md minimal stub generation with section headings and TODO placeholders
- Starter .claude/rules/ file generation (plugin-patterns.md, marketplace.md)
- Official marketplace schema compliance (https://code.claude.com/docs/en/plugin-marketplaces)
- Reserved marketplace name validation
- Plugin source type documentation (relative, github, url, git-subdir, npm, pip)
- Per-file write confirmation before disk writes
- Quick reference checklist for rapid pre-assessment
