---
name: blog-share
description: "Creates social media copy and a dark-mode card for a blog post. Formats content for LinkedIn, Twitter, and Bluesky with appropriate tone and length. Use when asked to share or post a blog post on LinkedIn, Twitter, or Bluesky."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, WebFetch, SendUserFile, Glob
---

# blog-share

Draft platform-aware social media copy and generate a styled dark-mode card image
for a blog post URL or local markdown file.

## Quick Reference

| Phase | Action |
|-------|--------|
| 1 — Collect Input | Detect URL vs local file; resolve relative paths; ask platform + tone |
| 1c — Reuse check | Scan `docs/media/social/` for existing blog posts; offer reuse |
| 2 — Fetch Metadata | WebFetch OG tags (URL) or Read front matter (local); HTML-escape all values |
| 3 — Draft Copy | Write platform-aware copy; store as `POST_COPY_TEXT_RAW` |
| 4 — Populate Template | Fill `blog-card.html`; inject conditional elements + `{{COPY_PANELS}}` |
| 4b — Save | Write HTML to `docs/media/social/blog-{slug}-{date}.html` |
| 5 — Screenshot | Serve HTML locally; Playwright screenshot to PNG |
| 6 — Deliver | Present copy in fenced block + attach PNG + show saved path |

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
| `PLATFORM` | LinkedIn, Twitter/X, Bluesky, All sites | Required — "All sites" drafts and embeds all three |
| `TONE` | Professional, Casual, Punchy | Default: Professional (LinkedIn), Punchy (Twitter/Bluesky) |
| `HOOK_ANGLE` | Free text | Optional — e.g. "focus on the architecture section" |

---

## Phase 1c — Reuse Check

After collecting inputs, check for existing saved blog posts before generating anything new:

```bash
MEDIA_DIR="${PWD}/docs/media/social"
existing=$(ls "$MEDIA_DIR"/blog-*.html 2>/dev/null | sort -r | head -5)
```

If `$existing` is non-empty, show the list and use `AskUserQuestion` to ask:
> "Found existing blog post(s). Reuse one or generate a new one?"

If user picks **reuse**:
1. Read the chosen file
2. Extract the post text from every `<textarea class="post-copy-text">…</textarea>` — one for a single-site card, three for an All-sites card
3. Present each in a fenced code block labeled with its preceding `copy-label`
4. Tell the user the file path
5. **STOP.**

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

Draft all three platform variants in the chosen tone. **Single site:** store them joined with `\n---\n` as `POST_COPY_TEXT_RAW` (Phase 4 → one copy panel). **All sites:** keep each variant separate (`LINKEDIN_COPY`, `TWITTER_COPY`, `BLUESKY_COPY`) for one panel per platform.

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

### Substitute `{{COPY_PANELS}}`

Escape each platform's copy (textarea-safe, in order: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`), then build the copy panel HTML for `{{COPY_PANELS}}`. The template defines the shared `copyPost(id, btn)` function — do not re-add it. Full reference: `../code-share/references/variables.md`.

- **Single site** — one panel, content = `POST_COPY_TEXT_RAW` escaped:
  ```html
  <div class="copy-panel">
    <p class="copy-label">Social media post</p>
    <textarea readonly class="post-copy-text" id="post-copy">ESCAPED_COPY</textarea>
    <button class="copy-btn" onclick="copyPost('post-copy', this)">Copy post</button>
  </div>
  ```
- **All sites** — three of the above with ids `post-copy-linkedin`/`post-copy-twitter`/`post-copy-bluesky`, labels `LinkedIn`/`Twitter/X`/`Bluesky`, each holding only that platform's escaped copy, buttons `onclick="copyPost('post-copy-<site>', this)"`.

### Substitute and write

Replace all `{{VARIABLE}}` placeholders in the template. Write the result to:
```bash
mkdir -p ~/.claude/tmp
# Write via Write tool to ~/.claude/tmp/blog-share-card.html
```

---

## Phase 4b — Persistent Save

Save the same populated HTML to `docs/media/social/`:

```bash
MEDIA_DIR="${PWD}/docs/media/social"
mkdir -p "$MEDIA_DIR"
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | \
       sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SAVE_PATH="$MEDIA_DIR/blog-${SLUG}-${DATE}.html"
# Write the populated HTML to $SAVE_PATH using the Write tool
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

1. `## [Platform] Copy` heading — for **All sites**, use `## Copy — all sites` with three labeled sub-blocks
2. Copy in fenced code block — one block per platform for All sites
3. Character count `[NNN / max chars]` per block — warn if over limit (1,500 / 280 / 300)
4. Attach `~/.claude/tmp/blog-share-card.png` via `SendUserFile` (if screenshot succeeded)
5. Saved HTML path: `docs/media/social/blog-{slug}-{date}.html`
6. Note: "Open the saved HTML in a browser to view the card and use the **Copy** button(s)."

**STOP.** Do not run any further commands after delivering.
