# Add mcp-tools plugin with fix-playwright-mcp skill

> `mcp-tools` is a new plugin (0.1.0) with one command-only skill, `fix-playwright-mcp`, that diagnoses and fixes the drift between `@playwright/mcp@latest` NPX installs and the system Chromium build.

<!-- generated:start -->

**Status:** Shipped 2026-10-20 **Plan:** [add-mcp-tools-plugin.md](plans/add-mcp-tools-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/mcp-tools/` with `.claude-plugin/plugin.json`, `README.md`, `CHANGELOG.md`, and `skills/fix-playwright-mcp/SKILL.md` carrying the plan-mode guard, a worked diagnosis example, and a backup-and-restore verification path.
- Registered `mcp-tools` in `.claude-plugin/marketplace.json` at `0.1.0` (no `version` in `plugin.json`).
- Added `tests/plugins/test-mcp-tools.mjs` covering marketplace wiring, missing manifest version, command-only activation, and the guard.
- Added `fix-playwright-mcp` to the `WRITE_HEAVY` list in `tests/plugins/test-exitplanmode-guard.sh`.
- Updated the root `README.md` counts, tree, install list, `enabledPlugins` example, Plugins section, and How-To table; regenerated the Plugin Reference Table.
- Added `docs/guides/how-to/mcp-tools.md`, its row in `docs/guides/how-to/README.md`, and an Unreleased entry in the root `CHANGELOG.md`.
- Added `mcp-tools` to `.claude/settings.json` `enabledPlugins`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/mcp-tools/skills/fix-playwright-mcp/SKILL.md` | Skill instructions | Created |
| `kit/plugins/mcp-tools/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/mcp-tools/README.md` | Plugin documentation | Created |
| `kit/plugins/mcp-tools/CHANGELOG.md` | Version history | Created |
| `tests/plugins/test-mcp-tools.mjs` | Smoke test | Created |
| `docs/guides/how-to/mcp-tools.md` | How-to guide | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `docs/guides/how-to/README.md` | How-to index | Modified |
| `README.md` | Plugin Reference Table | Modified |
| `CHANGELOG.md` | Root changelog | Modified |
| `.claude/settings.json` | Plugin enablement | Modified |
| `tests/plugins/test-exitplanmode-guard.sh` | Guard registration | Modified |

## How it works

The official Playwright MCP plugin starts its server with `npx @playwright/mcp@latest`. Each release of `@playwright/mcp` is built on a different Playwright version, which requires a different Chromium build. When a new release ships, the server wants a browser build that is not installed, so every session prompts to download Chromium, and `~/.npm/_npx` accumulates one cached copy per release.

`fix-playwright-mcp` detects this drift by checking which `@playwright/mcp` version NPX would run versus the installed Chromium build, then pins a user-scope MCP server configuration to a specific version and points it at the system Chrome binary (which updates itself). The skill never edits the plugin cache's `.mcp.json` and never hardcodes a pin version — it resolves the current stable release at run time.

The skill is command-only (`disable-model-invocation: true`) and requires explicit invocation.

## How to use it

```
/mcp-tools:fix-playwright-mcp
```

Command-only activation. Diagnoses the `@playwright/mcp` drift, recommends a fix, applies it after confirmation, and verifies every change by re-reading the written config. After the fix, new sessions get working `mcp__playwright__*` tools with no browser-install prompt.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `82227d62` | 2026-10-20 | feat(mcp-tools): add plugin with fix-playwright-mcp skill (0.1.0) (#655) |

<!-- generated:end -->

## References

- Plan: [add-mcp-tools-plugin.md](plans/add-mcp-tools-plugin.md)
