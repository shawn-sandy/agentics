# Changelog

All notable changes to the `agent-reviewer` plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

## [1.0.1] - 2026-05-07

### Changed

- Collapsed `reviewing-agents` skill description from multi-line YAML block to single-line inline string starting with "Use when..." for reliable auto-activation

## [1.0.0] - 2026-05-06

### Added

- `reviewing-agents` skill -- structured 5-dimension audit of Claude Code subagent definition files against official best practices
- Scoring rubric: frontmatter compliance, tool configuration, description quality, system prompt quality, security & isolation (2 pts each, max 10)
- Graded report output: Excellent (9-10), Good (6-8), Needs Work (3-5), Rewrite (0-2)
- Fix generation: presents diff first, then offers inline comments or direct application
- Plugin agent detection: flags silently-ignored fields (permissionMode, hooks, mcpServers) -- suppressed for marketplace repos
- Background agent safety checks: flags unrestricted mutation tools
- Golden template comparison for new agent files with no git history
- Edge case handling: empty body, non-YAML frontmatter, mixed tools+disallowedTools, duplicate YAML keys
- Regression risk check: optional git-based comparison against last committed version
- `references/best-practices.md` -- comprehensive agent definition criteria aligned with https://code.claude.com/docs/en/sub-agents
- `references/audit-steps.md` -- complete Steps 3-6 workflow including scoring rubric, report format, fix generation, and write confirmation
