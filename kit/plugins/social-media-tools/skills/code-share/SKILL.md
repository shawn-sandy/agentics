---
name: code-share
description: "Generates social media copy and a dark-mode card image for LinkedIn, Twitter/X, or Bluesky. Use when asked to write a post, tweet, or share a code change."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, SendUserFile
---

# code-share

Draft platform-aware social media copy and generate a styled dark-mode card image for LinkedIn, Twitter/X, or Bluesky.

## Quick Reference

| Phase | Action |
|-------|--------|
| 1 — Clarify | Auto-detect from git; ask platform + tone (context found) or all three inputs (no context) |
| 2 — Draft | Write platform-aware copy |
| 3 — Pick template | diff → diff-card, feature → feature-card, insight → quote-card |
| 4 — Populate | Read template, substitute `{{VARIABLES}}` |
| 5 — Screenshot | Serve HTML locally, Playwright screenshot to PNG |
| 6 — Deliver | Present copy in fenced block + attach PNG |

---

## Phase 1 — Clarify

### Step 1a — Auto-detect content context

Run these commands silently before asking the user anything:

```bash
git diff HEAD~1 --stat 2>/dev/null | head -20
git log --oneline -5 2>/dev/null
head -30 CHANGELOG.md 2>/dev/null
```

Use the results to pre-populate inputs:
- Non-empty diff stat → auto-select `diff-card`
- Commit with `feat:` prefix or version bump → auto-select `feature-card`
- If context is found, summarise it in one sentence, then only ask for **platform** and **tone**
- If no context is found, ask for all three inputs

### Step 1b — Collect remaining inputs

Use `AskUserQuestion` to collect whatever Step 1a did not resolve. Batch all questions in a single call.

Required inputs:
- **Platform**: LinkedIn, Twitter/X, or Bluesky
- **Content type** (only if not auto-detected above):
  - Diff / rule change / config update → `diff-card`
  - Release / feature announcement / version bump → `feature-card`
  - Insight / opinion / quote / thought leadership → `quote-card`
- **Tone**: Professional (default for LinkedIn), Casual, Punchy (default for Twitter/X and Bluesky)

---

## Phase 2 — Draft Copy

| Platform | Max Length | Style |
|----------|-----------|-------|
| LinkedIn | 1,500 chars | Narrative paragraphs; story arc (hook → insight → CTA); 2–4 hashtags at end |
| Twitter/X | 280 chars | One punchy sentence or a tight two-liner; no hashtag bloat |
| Bluesky | 300 chars | Conversational, same brevity as Twitter |

Present the drafted copy to the user in a fenced code block labeled with the platform name before proceeding.

---

## Phase 3 — Pick Template and Locate It

Select the card template:

- `diff-card.html` — code changes, rule updates, config diffs, PR descriptions
- `feature-card.html` — releases, new features, version announcements, changelogs
- `quote-card.html` — insights, opinions, pull quotes, thought leadership

Locate the `templates/` directory — try paths in order, stop at first hit:

```bash
# 1. Local dev checkout
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"

# 2. Claude Code plugin install dir
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1

# 3. Plugin cache dir (marketplace install)
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Set the chosen template path as `TEMPLATE_FILE=$TEMPLATES_DIR/<chosen>-card.html`.

If no directory is found, output: "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 4 — Populate Template

Read `TEMPLATE_FILE`. Replace every `{{VARIABLE}}` placeholder with content derived from the user's context and the Phase 2 copy.

For variable reference, read: `references/variables.md` (adjacent to this SKILL.md).

After substitution, write the populated HTML to `~/.claude/tmp/code-share-card.html`:

```bash
mkdir -p ~/.claude/tmp
```

---

## Phase 5 — Screenshot

### 5a — Get a free port

Derive `PLUGIN_DIR` from `TEMPLATES_DIR` (set in Phase 3), then run the helper:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
python3 "$PLUGIN_DIR/scripts/find_free_port.py"
```

Capture the printed integer as `$PORT`.

### 5b — Start HTTP server and capture PID

Run as a single compound command so `$!` is in scope:

```bash
cd ~/.claude/tmp && python3 -m http.server $PORT & SERVER_PID=$!; echo "PID:$SERVER_PID"
```

Parse the `PID:N` line to capture `SERVER_PID`.

### 5c — Playwright screenshot

Load tools via ToolSearch:
```
select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_wait_for
```

Then:
1. Navigate to `http://localhost:$PORT/code-share-card.html`
2. Wait for `networkidle` or 2000ms
3. Call `browser_take_screenshot` with `path: ~/.claude/tmp/code-share-card.png` to write directly to disk

### 5d — Kill server

```bash
kill $SERVER_PID 2>/dev/null || true
```

### 5e — Fallback

If Playwright tools are unavailable or the screenshot fails, tell the user:
> "Screenshot could not be generated. The populated HTML is at `~/.claude/tmp/code-share-card.html` — open it in a browser to screenshot manually."

---

## Phase 6 — Deliver

1. **Platform label** as a markdown heading (e.g., `## LinkedIn Copy`)
2. Copy in a fenced code block
3. Character count: `[NNN / max chars]` — warn if over limit
4. Attach `~/.claude/tmp/code-share-card.png` via `SendUserFile` (if screenshot succeeded)
5. HTML path for reference: `~/.claude/tmp/code-share-card.html`

**STOP.** Do not run further git commands, open browsers, or take any action beyond delivering the copy and card image.
