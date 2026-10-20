# Changelog — mcp-tools

## 0.1.0 — 2026-10-20

### Added

- Initial release with one command-only skill, `fix-playwright-mcp`: diagnoses the
  Playwright MCP Chromium build mismatch caused by the official plugin's unpinned
  `npx @playwright/mcp@latest` server, then — on the recommended path — disables the
  plugin, adds a user-scope server pinned to the current release with
  `--browser chrome`, renames the `mcp__plugin_playwright_*` permission rules to
  `mcp__playwright__*`, and verifies every change by re-reading it, with a settings
  backup and restore path.
