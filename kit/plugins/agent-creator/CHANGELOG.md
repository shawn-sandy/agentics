# Changelog

## [1.1.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.0.0] - 2026-03-08

### Added

- `generating-agents` skill — guided workflow to scaffold Claude Code agents
  - Supports both new plugin creation and adding agents to existing plugins
  - Curated tool presets (read-only, code-editor, full-access)
  - Progressive disclosure for advanced agent configuration
  - Structured system prompt template (Role, Behavior, Workflow, Output, Scope)
  - Post-generation validation (frontmatter, tools, structure)
  - Conditional marketplace registration
- `references/agent-schema.md` — complete agent frontmatter schema reference
