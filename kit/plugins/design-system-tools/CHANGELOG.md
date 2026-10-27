# Changelog

## v0.2.0 — 2026-10-26 — drop the bin/ wrapper for claude.ai compatibility

### Changed

- **Removed the top-level `bin/` directory.** claude.ai-hosted marketplaces
  refuse to install any plugin that ships one ("Plugin contains a top-level
  bin/ directory"), which left the plugin stuck at its last synced version.
  Claude Code now substitutes `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}`
  into skill, command, and agent markdown at load time (verified on 2.1.304),
  so the bare-name wrapper the Bash tool's old expansion guard required is
  obsolete: from-design-md now runs `node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs"`.

## 0.1.0 — 2026-09-28

### Added

- **`from-design-md`** — publishes a repository's `DESIGN.md` and the stylesheets behind it as a
  claude.ai Design System artifact: `tokens.json` in every theme, a README brand book, static
  component previews and a cover. It defers to the Design System type's own `SKILL.md` and
  references for every file shape, and adds the DESIGN.md mapping. Re-syncs an existing system
  when given its URL. Verifies the publish against the remote file listing before reporting.
- **`scripts/contrast.mjs`** — WCAG 2 contrast for colour-token pairs in every theme of a
  `tokens.json`, following `{alias}` values and first-theme fallback, floored to two decimals.
  Invoked as the bare command `bin/design-system-contrast`, because the Bash tool refuses a
  command that contains `$VAR`.
