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
   `which google-chrome google-chrome-stable`. Only branded Google Chrome counts —
   Playwright's `chrome` channel will not launch a distro `chromium`.

**Healthy exit:** the plugin key is absent or `false` in every settings file checked,
a `playwright` server exists whose command pins an exact version, AND the browser
that command selects is ready — system Chrome present for `--browser chrome` (also
the server's default), or the matching `chromium-*` build installed when the command
selects a bundled browser. Report that nothing is drifting; if the pin is behind the
current release (`npm view @playwright/mcp version`), offer to repin via Steps 2–4,
otherwise stop.

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

Back up first — every settings file Step 1 found the plugin key or playwright rules
in, user and project alike:
`cp ~/.claude/settings.json ~/.claude/settings.json.fix-playwright-backup`
(and the same `.fix-playwright-backup` suffix for a project `.claude/settings.json`).

Both fixes:

- Edit each settings file where Step 1 found the plugin key: set it to `false`.
- Never edit the plugin's cached `.mcp.json` — plugin updates overwrite it.

Pin + system Chrome only:

- If Step 1 found an existing `playwright` server at user scope — pinned or not —
  snapshot its record first (`claude mcp get playwright`; keep the full command,
  args, and env — it is the only copy once removed), then remove it:
  `claude mcp remove playwright -s user`. Adding over an existing name fails with
  "already exists".
- Resolve the current release: `npm view @playwright/mcp version`.
- Add the server with the **literal resolved version** written into the command —
  never a shell variable, which the Bash tool rejects:
  `claude mcp add playwright -s user -- npx @playwright/mcp@<resolved> --browser chrome`
- Rename permission rules: in every settings file that carries them, replace the
  plugin's tool prefix (`mcp__plugin_playwright_<server>__`, derived from the key found
  in Step 1) with `mcp__playwright__`. The server added above is named `playwright`, so
  its tools are `mcp__playwright__browser_navigate` and so on.

If any command in this step fails, go straight to the Step 4 restore path — never
continue half-applied.

### Step 4 — Verify, then report

1. `python3 -m json.tool <file> > /dev/null` parses, for every edited settings file.
2. The plugin key reads `false` in each file where Step 1 found it — re-read the
   files; do not trust the edits.
3. Pin fix only: `claude mcp get playwright` shows the pinned version and
   `--browser chrome`, and `grep -c mcp__plugin_playwright <file>` reports 0 for
   every edited settings file.
4. **If any check fails, or any Step 3 command failed:** restore every backup
   (`cp <file>.fix-playwright-backup <file>`), remove the server this run added
   (`claude mcp remove playwright -s user`), and if Step 3 removed an existing
   server, re-add it from its snapshot (`claude mcp add playwright -s user -- <the
   snapshotted command and args>`). Report which step failed and stop — do not
   retry blind.

On success, tell the user:

- The new tools are named `mcp__playwright__*` and appear in **new** sessions only.
- Where the settings backups live, so they can delete them once satisfied.
- The pin is deliberate: when they want a newer `@playwright/mcp`, re-running this
  skill repins to the then-current release.
- Optionally, stale `~/.npm/_npx` copies of `@playwright/mcp` can be deleted to
  reclaim disk. Deleting is destructive: list the matching directories and get
  explicit approval before removing anything, and keep the copy matching the pinned
  version.
