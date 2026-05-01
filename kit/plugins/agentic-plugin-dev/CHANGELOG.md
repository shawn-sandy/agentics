# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-05-01

### Changed

- `plugin-creator` now self-exits plan mode instead of blocking execution
  and telling the user to exit manually
- Added `ExitPlanMode` to `plugin-creator` allowed-tools
- Replaced "Plan Mode Guard" with "Step 0: Exit Plan Mode (if active)"
- Renumbered subsequent steps (Disambiguation is now Step 1, etc.)

## [1.1.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.0.0] - 2026-03-13

### Added

- Skill: `plugin-creator` — scaffold complete Claude Code plugins with guided workflows
- Skill: `plugin-manager` — list, add, remove, update, and bump plugin entries in marketplace.json
- Skill: `plugin-validator` — validate plugin structure against the official Claude Code spec
- Reference files for plugin.json schema, component templates, marketplace schema, and validation rules
