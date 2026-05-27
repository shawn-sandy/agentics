---
name: blog-share
description: "Creates social media copy and a dark-mode card for a blog post. Formats content for LinkedIn, Twitter, and Bluesky with appropriate tone and length. Use when asked to share or post a blog post on LinkedIn, Twitter, or Bluesky."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, WebFetch, SendUserFile
---

# blog-share

Draft platform-aware social media copy and generate a styled dark-mode card image
for a blog post URL or local markdown file.

## Quick Reference

| Phase | Action |
|-------|--------|
| 1 — Collect Input | Detect URL vs local file; resolve relative paths; ask platform + tone |
| 2 — Fetch Metadata | WebFetch OG tags (URL) or Read front matter (local); HTML-escape all values |
| 3 — Draft Copy | Write platform-aware copy per `references/platforms.md` |
| 4 — Populate Template | Fill `blog-card.html`; inject conditional elements as full HTML or `""` |
| 5 — Screenshot | Serve HTML locally; Playwright screenshot to PNG |
| 6 — Deliver | Present copy in fenced block + attach PNG |

---

## Phase 1 — Collect Input

Detect the source type:
- **URL**: starts with `http://` or `https://`
- **Local file**: ends with `.md`, `.mdx`, or `.markdown`

If the user provides a **relative path**, resolve it to absolute before calling `Read`:
```bash
realpath "$USER_PATH" 2>/dev/null || echo "$PWD/$USER_PATH"
```

Use `AskUserQuestion` to collect whatever is missing. Batch all questions in one call:

| Input | Options | Notes |
|-------|---------|-------|
| `SOURCE` | URL or file path | Required if not already provided |
| `PLATFORM` | LinkedIn, Twitter/X, Bluesky | Required |
| `TONE` | Professional, Casual, Punchy | Default: Professional (LinkedIn), Punchy (Twitter/Bluesky) |
| `HOOK_ANGLE` | Free text | Optional — e.g. "focus on the architecture section" |

---

## Phase 2 — Fetch Metadata

### Deferred tool bootstrap

`WebFetch` is a deferred tool — its schema is not loaded at session start.

```
Use ToolSearch with select:WebFetch first (silent, no user output), then call WebFetch.
```

Both steps happen silently.

### URL source

Call `WebFetch` on `SOURCE`. Extract from the returned HTML:

| Variable | Source |
|----------|--------|
| `TITLE` | `<meta property="og:title">` → `<title>` fallback |
| `EXCERPT` | `<meta property="og:description">` → first `<p>` element, truncated to 280 chars |
| `AUTHOR` | `<meta property="article:author">` → empty string if not found |
| `DATE` | `<meta property="article:published_time">` → format as `MMM D, YYYY` → empty string if not found |
| `SOURCE_DOMAIN` | Hostname of URL, strip `www.` prefix |
| `TAGS` | `<meta property="article:tag">` values, up to 5 |
| `READ_TIME` | Empty string — do not compute for URL sources |

### Local file source

Call `Read` on the resolved absolute path. Extract:

| Variable | Source |
|----------|--------|
| `TITLE` | YAML front matter `title:` → first `# H1` heading |
| `EXCERPT` | YAML front matter `description:` → first non-heading paragraph, truncated to 280 chars |
| `AUTHOR` | YAML front matter `author:` → empty string if not found |
| `DATE` | YAML front matter `date:` → format as `MMM D, YYYY` → empty string if not found |
| `SOURCE_DOMAIN` | YAML front matter `site:` or `url:` hostname → `"local file"` fallback |
| `TAGS` | YAML front matter `tags:` array, up to 5 items |
| `READ_TIME` | Word count of body text (excluding front matter and headings) / 200 wpm, rounded to nearest minute |

### HTML-escape all extracted values

Before any template substitution, apply to every text value:
1. `&` → `&amp;` (must be first)
2. `<` → `&lt;`
3. `>` → `&gt;`

---

## Phase 3 — Draft Copy

Read `references/platforms.md` for the exact format and a filled example for each platform.

| Platform | Max | Tone default |
|----------|-----|------|
| LinkedIn | 1,500 chars | Professional |
| Twitter/X | 280 chars | Punchy |
| Bluesky | 300 chars | Conversational |

Present the draft copy in a fenced code block labelled with the platform name.
Wait for user approval before proceeding.

---

## Phase 4 — Populate Template

### Locate TEMPLATES_DIR

Try these paths in order; stop at the first hit:

```bash
# 1. Local dev checkout
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"

# 2. Claude Code plugin install dir
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1

# 3. Plugin cache dir (marketplace install)
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Set `TEMPLATE_FILE=$TEMPLATES_DIR/blog-card.html`. If not found, output:
> "Templates not found. Install the plugin or load it with `--plugin-dir`."
and **STOP**.

### Conditional element substitution (Option A)

The template is purely static — the skill injects either a full HTML element or
an empty string `""`. Do not attempt CSS tricks:

**`{{READ_TIME_BADGE}}`**
- If `READ_TIME` is non-empty: `<span class="read-time">N min read</span>`
- If empty: `""`

**`{{TAGS_FOOTER}}`**
- If `TAGS` has at least one value: inject the full footer block with one `<span class="tag">` per tag (each value HTML-escaped):
  ```html
  <div class="card-footer"><span class="tag">tag1</span><span class="tag">tag2</span></div>
  ```
- If no tags: `""`

### Substitute and write

Replace all `{{VARIABLE}}` placeholders in the template. Write the result to:
```bash
mkdir -p ~/.claude/tmp
# Write via Write tool to ~/.claude/tmp/blog-share-card.html
```

---

## Phase 5 — Screenshot

### 5a — Get a free port

Derive `PLUGIN_DIR` from `TEMPLATES_DIR`, then:
```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
python3 "$PLUGIN_DIR/scripts/find_free_port.py"
```
Capture the printed integer as `$PORT`.

### 5b — Start HTTP server
```bash
cd ~/.claude/tmp && python3 -m http.server $PORT & SERVER_PID=$!; echo "PID:$SERVER_PID"
```
Parse `PID:N` to capture `SERVER_PID`.

### 5c — Playwright screenshot

Load tools via ToolSearch:
```
select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_wait_for
```

1. Navigate to `http://localhost:$PORT/blog-share-card.html`
2. Wait for `networkidle` or 2000ms
3. Screenshot to `~/.claude/tmp/blog-share-card.png`

### 5d — Kill server
```bash
kill $SERVER_PID 2>/dev/null || true
```

### 5e — Fallback

If Playwright is unavailable:
> "Screenshot could not be generated. The populated HTML is at `~/.claude/tmp/blog-share-card.html` — open it in a browser to screenshot manually."

---

## Phase 6 — Deliver

1. `## [Platform] Copy` heading
2. Copy in fenced code block
3. Character count: `[NNN / max chars]` — warn if over limit
4. Attach `~/.claude/tmp/blog-share-card.png` via `SendUserFile` (if screenshot succeeded)
5. HTML path: `~/.claude/tmp/blog-share-card.html`

**STOP.** Do not run any further commands after delivering.
