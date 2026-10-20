# How do I... mcp-tools

Diagnoses and fixes MCP server setup issues — starting with the Playwright MCP Chromium build mismatch.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install mcp-tools@agentics-kit`

## fix-playwright-mcp

Ends the endless "install Chromium" prompts caused by the Playwright plugin's unpinned `@latest` MCP server.

- **Command** — `/mcp-tools:fix-playwright-mcp`
- **Say it instead** — Command-only; natural language does not trigger it.
- **What happens** — Diagnoses five signals (plugin state, existing user-scope server, installed Chromium builds, npx cache drift, system Chrome) and reports them before proposing anything; a healthy setup — plugin off, server pinned, its browser ready — is reported and nothing further is asked. The recommended fix disables the plugin, adds a user-scope server pinned to the current `@playwright/mcp` release with `--browser chrome`, and renames the `mcp__plugin_playwright_*` permission rules to `mcp__playwright__*`. `~/.claude/settings.json` is backed up first, and every change is re-read before success is reported.
- **Watch out** — The repinned tools only appear in new sessions, and the pin is deliberate: upgrading to a newer `@playwright/mcp` later is a re-run of this skill, not an automatic drift. It never edits the plugin's cached `.mcp.json`, which plugin updates overwrite.
