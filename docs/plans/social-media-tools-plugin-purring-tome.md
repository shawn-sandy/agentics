# Fix: `social-media-tools` skills fail when run by a background agent

## Context

The `social-media-tools` plugin generates dark-mode social cards (PNG + HTML) and
platform copy. Its router skill (`social-share`) and the `-bg` commands
(`social-share-bg`, `session-bg`) all funnel card generation through a background
subagent — `agent-social-share` — which invokes the target `share-*` skill in
non-interactive mode.

**Symptom:** card generation fails (no PNG, or blog/github/video fetch fails) when
run via a background agent, while invoking a `share-*` skill directly in the
foreground works.

### Root cause (confirmed)

Subagent tool grants are **not transitive across `Skill` invocations** — this is
documented in `docs/add-background-mode-product-plans.md:40`:

> "the tool list was widened … because subagent tool grants are not transitive
> across `Skill` invocations — the inner skill's `Write` and `Edit` calls would be
> blocked without the wider grant."

A background subagent can only call tools listed in its own `tools:` frontmatter.
When it invokes a skill via `Skill`, the inner skill's tool calls are gated by the
**agent's** allowlist, not the skill's `allowed-tools`.

`agent-social-share` (`kit/plugins/social-media-tools/agents/agent-social-share.md:10`)
declares:

```
tools: Skill, Bash, Read, Write, Glob, Grep, ToolSearch, SendUserFile
```

But every card-producing `share-*` skill it invokes requires tools that are **absent**
from that list:

- **Playwright MCP screenshot tools** — all 7 card skills (`share-code`,
  `share-session`, `share-blog`, `share-github`, `share-video`, `share-selection`,
  `share-project`) read `references/rendering-pipeline.md`, which calls
  `mcp__plugin_playwright_playwright__browser_navigate`,
  `…__browser_take_screenshot`, and `…__browser_wait_for` to render the card PNG.
  Blocked → **no PNG is produced** (the core deliverable).
- **WebFetch** — `share-blog`, `share-github`, `share-video` fetch their source.
  Blocked → those three skills can't retrieve content.

Because the `social-share` router *always* dispatches to `agent-social-share`
(even from a foreground invocation, per Phase 4 of its SKILL.md), card generation
is broken on every router-routed path. It only works when a user triggers a
`share-*` skill directly on the main thread, where Playwright/WebFetch are available.

`agent-digest` → `share-scan` is **not affected**: `share-scan` only uses
`Bash, Read, Grep, Glob, Write, Skill` (+ `AskUserQuestion`, skipped in background),
all of which `agent-digest` already grants.

## Approach

Widen the `tools:` allowlist of `agent-social-share` to include the screenshot and
fetch tools its invoked skills require — mirroring the precedent set by
`agent-product-plans`. No skill logic changes are needed; the `--background`
non-interactive paths already exist and work.

### Change

**File:** `kit/plugins/social-media-tools/agents/agent-social-share.md` (frontmatter `tools:` line)

From:
```
tools: Skill, Bash, Read, Write, Glob, Grep, ToolSearch, SendUserFile
```
To (add WebFetch + the three Playwright MCP tools):
```
tools: Skill, Bash, Read, Write, Glob, Grep, ToolSearch, SendUserFile, WebFetch, mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_wait_for
```

Notes:
- `AskUserQuestion` is intentionally **excluded** — background skips it, and granting
  it risks a hung prompt off the main thread.
- The Playwright tool names match exactly what `references/rendering-pipeline.md:36`
  already hardcodes, keeping the two in sync.
- The Playwright MCP itself is a pre-existing external dependency (not bundled in
  this plugin's `plugin.json`); this fix does not change provisioning, only ensures
  the subagent is *permitted* to call it. The existing rendering-pipeline "fallback"
  text still covers the case where Playwright is genuinely unavailable.

### Documentation / metadata (per `.claude/rules/marketplace.md`)

This is a bug fix → **PATCH** bump for `social-media-tools`:

1. Bump `version` for the `social-media-tools` entry in
   `.claude-plugin/marketplace.json` (current → next patch).
2. Add a `CHANGELOG.md` entry under `kit/plugins/social-media-tools/` describing the
   fix (background card generation blocked by missing Playwright/WebFetch grants).
3. Commit message: `fix(kit/plugins/social-media-tools): grant background agent screenshot + fetch tools`
4. Include this plan file in the commit.

## Verification

1. **Static check** — confirm the four added tool names in `agent-social-share.md`
   exactly match the names used in `references/rendering-pipeline.md` (Playwright) and
   the `WebFetch` calls in `share-blog`/`share-github`/`share-video`.
2. **JSON validity** — `.claude/settings.json` auto-validates `marketplace.json` on
   write; ensure no syntax error after the version bump.
3. **End-to-end (manual, requires Playwright MCP installed):**
   - Load the plugin: `claude --plugin-dir ./kit/plugins/social-media-tools`
   - Run `/social-media-tools:social-share-bg share my latest commit` (routes to
     `share-code` via the background agent).
   - Expect the agent to emit
     `SOCIAL-SHARE: DONE skill=share-code platform=all png=<path> html=<path>` with a
     **non-empty `png=`** path, and a PNG present at that path. Before the fix, the
     screenshot step is blocked and `png=` is empty / the run errors.
   - Run `/social-media-tools:session-bg` → expect a `share-session` card PNG.
   - Run `/social-media-tools:social-share-bg https://<some-blog-url>` → expect the
     `share-blog` WebFetch to succeed (no permission block).
4. **Regression** — `/social-media-tools:digest-bg` still completes
   (`agent-digest`/`share-scan` path was already correct and unchanged).

## Out of scope

- Provisioning/declaring the Playwright MCP as a formal plugin dependency (separate
  enhancement; the rendering pipeline already documents a manual fallback).
- The `social-share-bg` → `social-share` skill → `Agent` dispatch hop: the skill
  retains its own `allowed-tools` (incl. `Agent`) when invoked from a command, so
  dispatch itself is not the failure point — the failure is downstream in the
  subagent's tool grants.
