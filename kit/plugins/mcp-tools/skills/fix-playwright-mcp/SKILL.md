---
name: fix-playwright-mcp
description: "Fixes Playwright MCP Chromium build mismatches from an unpinned @latest server. Pins the server and points it at system Chrome. Use when the user runs /mcp-tools:fix-playwright-mcp."
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, AskUserQuestion, ToolSearch, ExitPlanMode
---

# Fix Playwright MCP

## Overview

The official Playwright plugin starts its MCP server with `npx @playwright/mcp@latest`.
Each release of `@playwright/mcp` is built on a different Playwright version, and each
Playwright version drives one specific Chromium build. When a new release ships, the
server wants a Chromium build that is not installed: every session prompts to download
a browser, `~/.npm/_npx` accumulates one cached copy per release, and the server can
fail to connect at session start. The durable fix is a user-scope server pinned to one
version and pointed at the system Chrome, which updates itself — nothing to download,
ever.

## When not to use

- Playwright *test* failures in a project (`@playwright/test`, `playwright.config.*`) —
  this skill never touches a project's own Playwright install or browser downloads.
- MCP servers other than Playwright failing to connect.

## Steps

### Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

### Step 1 — Diagnose (read-only)

Collect all five signals before concluding anything. The browser cache is
`~/Library/Caches/ms-playwright` on macOS and `~/.cache/ms-playwright` on Linux.

1. **Plugin state** — grep `~/.claude/settings.json` (and the project's
   `.claude/settings.json` when present) for an `enabledPlugins` key matching
   `"playwright@`. Record the exact key and its value.
2. **Existing server** — `claude mcp get playwright`. Record whether a user-scope
   server already exists and whether its command pins an exact version
   (`@playwright/mcp@0.0.83`) or floats (`@latest` or no tag).
3. **Installed Chromium builds** — list `chromium-*` directories in the browser cache.
4. **Drift evidence** —
   `ls -d ~/.npm/_npx/*/node_modules/@playwright/mcp 2>/dev/null | wc -l`.
   More than a couple means repeated `@latest` re-downloads.
5. **System Chrome** — macOS: `/Applications/Google Chrome.app` exists; Linux:
   `which google-chrome google-chrome-stable chromium`.

**Healthy exit:** the plugin key is absent or `false` AND a `playwright` server exists
whose command pins an exact version. Report that nothing needs fixing and stop.

Report the findings in this format before proposing anything (a worked example):

```text
Playwright MCP diagnosis
- Plugin: playwright@claude-plugins-official = true (runs npx @playwright/mcp@latest)
- User-scope server: none
- Installed Chromium builds: 1217 (matches this repo's @playwright/test 1.59.1)
- npx cache copies of @playwright/mcp: 31 — repeated @latest re-downloads
- System Chrome: /Applications/Google Chrome.app present
Verdict: version drift — @latest wants a Chromium build that is not installed.
```

### Step 2 — Choose the fix

Ask with `AskUserQuestion`, recommendation first:

1. **Pin + system Chrome (recommended)** — disable the plugin, add a user-scope server
   pinned to the current `@playwright/mcp` release with `--browser chrome`. Requires
   system Chrome from signal 5.
2. **Disable the plugin only** — no replacement server; rely on other browser tooling.
3. **Report only** — change nothing.

### Step 3 — Apply

Back up first:
`cp ~/.claude/settings.json ~/.claude/settings.json.fix-playwright-backup`.

Both fixes:

- Edit `~/.claude/settings.json`: set the plugin key found in Step 1 to `false`.
- Never edit the plugin's cached `.mcp.json` — plugin updates overwrite it.

Pin + system Chrome only:

- If Step 1 found an existing unpinned `playwright` server, remove it first:
  `claude mcp remove playwright -s user`.
- Resolve the current release: `npm view @playwright/mcp version`.
- Add the server with the **literal resolved version** written into the command —
  never a shell variable, which the Bash tool rejects:
  `claude mcp add playwright -s user -- npx @playwright/mcp@<resolved> --browser chrome`
- Rename permission rules: in every settings file that carries them, replace the
  plugin's tool prefix (`mcp__plugin_playwright_<server>__`, derived from the key found
  in Step 1) with `mcp__playwright__`. The server added above is named `playwright`, so
  its tools are `mcp__playwright__browser_navigate` and so on.

### Step 4 — Verify, then report

1. `python3 -m json.tool ~/.claude/settings.json > /dev/null` parses.
2. The plugin key reads `false` — re-read the file; do not trust the edit.
3. Pin fix only: `claude mcp get playwright` shows the pinned version and
   `--browser chrome`, and `grep -c mcp__plugin_playwright ~/.claude/settings.json`
   reports 0.
4. **If any check fails:** restore the backup
   (`cp ~/.claude/settings.json.fix-playwright-backup ~/.claude/settings.json`),
   report which check failed, and stop — do not retry blind.

On success, tell the user:

- The new tools are named `mcp__playwright__*` and appear in **new** sessions only.
- Where the settings backup lives, so they can delete it once satisfied.
- The pin is deliberate: when they want a newer `@playwright/mcp`, re-running this
  skill repins to the then-current release.
- Optionally, stale `~/.npm/_npx` copies of `@playwright/mcp` can be deleted to
  reclaim disk. Deleting is destructive: list the matching directories and get
  explicit approval before removing anything, and keep the copy matching the pinned
  version.
