---
status: completed
type: feature
created: 2026-10-20
modified: 2026-10-20
repo-name: agentics
---

# Plan: Add the mcp-tools plugin

## Context

The official Playwright plugin starts its MCP server with `npx @playwright/mcp@latest`. Each
release of `@playwright/mcp` is built on a different Playwright version, and each Playwright
version drives one specific Chromium build. When a new release ships, the server wants a browser
build that is not installed: every session prompts to download Chromium, `~/.npm/_npx` accumulates
one cached copy per release (about 30 on this machine, spanning builds 1155–1247), and the server
can fail to connect at session start. The durable fix is a user-scope server pinned to one version
and pointed at the system Chrome, which updates itself.

The user asked for a plugin skill that detects and fixes this, chose a new `mcp-tools` plugin
(domain-container name, matching `artifact-tools`/`content-tools`), named-command activation
(`disable-model-invocation: true`), and a Playwright-specific scope.

## Objective

Ship `mcp-tools` 0.1.0 with one command-only skill, `fix-playwright-mcp`, registered in the
marketplace, documented like every other plugin, and covered by a test that runs under
`tests/run-all.sh`.

## Steps

1. Create `kit/plugins/mcp-tools/` with `.claude-plugin/plugin.json`, `README.md`, `CHANGELOG.md`, and `skills/fix-playwright-mcp/SKILL.md` carrying the plan-mode guard, a worked diagnosis example, and a backup-and-restore verification path. Why: the skill mutates `~/.claude/settings.json` and user-scope MCP config, so the repo's guard and verification-gate rules apply. Verify: `node tests/plugins/test-mcp-tools.mjs` passes and the guard test's Check 3 still passes.
2. Register the plugin in `.claude-plugin/marketplace.json` at 0.1.0 with no `version` in `plugin.json`. Why: version lives only in the marketplace for relative-path plugins. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.
3. Add `tests/plugins/test-mcp-tools.mjs` covering marketplace wiring, the missing manifest version, command-only activation, and the guard; add the skill to `WRITE_HEAVY` in `tests/plugins/test-exitplanmode-guard.sh`. Why: activation mode and the guard are the plugin's contract and must survive later edits. Verify: `node tests/plugins/test-mcp-tools.mjs` and `bash tests/plugins/test-exitplanmode-guard.sh` pass.
4. Update the root `README.md` counts, tree, install list, `enabledPlugins` example, Plugins section and How-To table, regenerate the Plugin Reference Table with `node scripts/build-readme-table.mjs`, and add the plugin to `.claude/settings.json` `enabledPlugins`. Why: derived counts and lists go stale otherwise. Verify: `node scripts/build-readme-table.mjs --check` exits 0 and no count still reads 13 plugins or 67 skills.
5. Add `docs/guides/how-to/mcp-tools.md`, its row and total in `docs/guides/how-to/README.md`, and an Unreleased entry in the root `CHANGELOG.md`. Why: every plugin has a how-to guide and a changelog line. Verify: the new guide's link resolves from both indexes.

## Tests

> Tier: 1 (code-touching)

### Objective-Verification Test

- **File:** `tests/plugins/test-mcp-tools.mjs`
- **Type:** smoke test
- **Asserts:** the marketplace registers `mcp-tools` with an `X.Y.Z` version and a source path that holds `skills/fix-playwright-mcp/SKILL.md`, `plugin.json` has no `version`, the skill is command-only (`disable-model-invocation: true`), and it carries the plan-mode guard verbatim.
- **Run:** `node tests/plugins/test-mcp-tools.mjs`

## Acceptance Criteria

- [x] `/plugin install mcp-tools@agentics-kit` resolves to a plugin whose only skill is `fix-playwright-mcp`.
- [x] The skill is command-only and its description is at most 200 characters with a first sentence of at most 80.
- [x] The skill never edits the plugin cache's `.mcp.json` and never hardcodes a pin version — it resolves the current release at run time.
- [x] `bash scripts/verify.sh` exits 0.
- [x] No count in `README.md` or `docs/guides/how-to/README.md` still says 13 plugins or 67 skills.

## Verification

Run `bash scripts/verify.sh` from the repo root and confirm every stage passes or reports a named
skip. Then load the plugin with `claude --plugin-dir ./kit/plugins/mcp-tools` and confirm
`/mcp-tools:fix-playwright-mcp` is listed as a command.

## Next Steps

- Run the fix for real on this machine:
  ```text
  With mcp-tools installed, run /mcp-tools:fix-playwright-mcp. It should report the
  @latest drift diagnosis, recommend pinning a user-scope playwright server driving
  system Chrome, apply the fix after confirmation, and verify every change by
  re-reading it. Confirm a new session gets working mcp__playwright__* tools with no
  browser-install prompt.
  ```
