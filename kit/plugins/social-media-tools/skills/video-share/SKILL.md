---
name: video-share
description: "Creates social media copy and a card for a YouTube or Vimeo video. Formats video content for LinkedIn, Twitter, and Bluesky with platform-appropriate messaging. Use when asked to share a video or promote a talk on LinkedIn, Twitter, or Bluesky."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, WebFetch, SendUserFile, Glob
---

# video-share

Draft platform-aware social media copy and generate a styled dark-mode card image
for a YouTube or Vimeo video URL.

## Quick Reference

| Phase | Action |
|-------|--------|
| 1 — Collect Input | Auto-detect platform from URL; ask target social platform + angle |
| 1c — Reuse check | Scan `docs/media/social/` for existing video posts; offer reuse |
| 2 — Fetch Metadata | oEmbed API for title/channel/thumbnail; fallback on 4xx |
| 3 — Draft Copy | Write platform-aware copy; store as `POST_COPY_TEXT_RAW` |
| 4 — Populate Template | Fill `video-card.html`; inject `{{THUMBNAIL_ZONE}}` + `{{POST_COPY_TEXT}}` |
| 4b — Save | Write HTML to `docs/media/social/video-{slug}-{date}.html` |
| 5 — Screenshot | Serve HTML locally; Playwright screenshot to PNG |
| 6 — Deliver | Present copy in fenced block + attach PNG + show saved path |

---

## Phase 1 — Collect Input

Auto-detect the video platform from the URL:
- `youtube.com` or `youtu.be` → **YouTube**
- `vimeo.com` → **Vimeo**

Use `AskUserQuestion` to collect whatever is missing. Batch all questions in one call:

| Input | Options | Notes |
|-------|---------|-------|
| `VIDEO_URL` | Any YouTube or Vimeo URL | Required |
| `PLATFORM` | LinkedIn, Twitter/X, Bluesky | Target social platform for the post |
| `HOOK_ANGLE` | Free text | Optional — e.g. "focus on the implementation at 12:00" |

---

## Phase 1c — Reuse Check

After collecting inputs, check for existing saved video posts:

```bash
MEDIA_DIR="${PWD}/docs/media/social"
existing=$(ls "$MEDIA_DIR"/video-*.html 2>/dev/null | sort -r | head -5)
```

If `$existing` is non-empty, show the list and use `AskUserQuestion` to ask:
> "Found existing video post(s). Reuse one or generate a new one?"

If user picks **reuse**: extract post text from `<textarea class="post-copy-text" id="post-copy">…</textarea>`, present it, show file path, **STOP.**

---

## Phase 2 — Fetch Metadata

### Deferred tool bootstrap

`WebFetch` is a deferred tool — its schema is not loaded at session start.

```
Use ToolSearch with select:WebFetch first (silent, no user output), then call WebFetch.
```

### YouTube

1. `WebFetch` on `https://www.youtube.com/oembed?url=VIDEO_URL&format=json`
   - Extract: `title`, `author_name` (channel name), `thumbnail_url`
2. `WebFetch` on the original `VIDEO_URL`
   - Extract: `og:description` from the page HTML (oEmbed response does not include description)

**4xx response (private / deleted / age-restricted):**
- Use `AskUserQuestion` to ask for `title` and `channel` manually
- Set `thumbnail_url = ""` — proceed without thumbnail

### Vimeo

1. `WebFetch` on `https://vimeo.com/api/oembed.json?url=VIDEO_URL`
   - Extract: `title`, `author_name`, `thumbnail_url`, `description`

**4xx response:** same fallback as YouTube — ask user for title and channel.

### Derived values

Set these from hardcoded values only — never from fetched content or user input:

| Variable | YouTube | Vimeo |
|----------|---------|-------|
| `PLATFORM_COLOR` | `#ff0000` | `#1ab7ea` |
| `PLATFORM_BADGE` | `"YouTube"` | `"Vimeo"` |
| `CTA` | `"▶ Watch on YouTube"` | `"▶ Watch on Vimeo"` |

---

## Phase 3 — Draft Copy

Read `references/platforms.md` for the exact format and filled examples.

| Platform | Max | Tone default |
|----------|-----|------|
| LinkedIn | 1,500 chars | Professional |
| Twitter/X | 280 chars | Punchy |
| Bluesky | 300 chars | Conversational |

Present the draft in a fenced code block labelled with the platform name.
Wait for user approval before proceeding.

Store all platform variants as `POST_COPY_TEXT_RAW` (join with `\n---\n`). Used in Phase 4 for the copy panel.

---

## Phase 4 — Populate Template

### Locate TEMPLATES_DIR

Same three-path probe as `code-share`:

```bash
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Set `TEMPLATE_FILE=$TEMPLATES_DIR/video-card.html`. If not found, output the
"Templates not found" message and **STOP**.

### Conditional element substitution (Option A)

**`{{THUMBNAIL_ZONE}}`**
- If `thumbnail_url` is non-empty: inject the full thumbnail block:
  ```html
  <div class="video-thumbnail"><img src="THUMBNAIL_URL" alt="Video thumbnail"><div class="play-overlay"><span class="play-icon">&#9654;</span></div></div>
  ```
- If empty (4xx fallback): `""`

### Prepare DESCRIPTION_SNIPPET

Truncate the description to the first 150 characters. If no description is available,
use an empty string.

HTML-escape `VIDEO_TITLE`, `CHANNEL`, `DESCRIPTION_SNIPPET` before substitution:
`&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`.

### Substitute `{{POST_COPY_TEXT}}`

Apply textarea-safe escaping to `POST_COPY_TEXT_RAW` (in this order): `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`. Store as `POST_COPY_TEXT` and include in template substitution.

### Substitute and write

Replace all `{{VARIABLE}}` placeholders. Write to:
```bash
mkdir -p ~/.claude/tmp
# Write via Write tool to ~/.claude/tmp/video-share-card.html
```

---

## Phase 4b — Persistent Save

```bash
MEDIA_DIR="${PWD}/docs/media/social"
mkdir -p "$MEDIA_DIR"
SLUG=$(echo "$VIDEO_TITLE" | tr '[:upper:]' '[:lower:]' | \
       sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SAVE_PATH="$MEDIA_DIR/video-${SLUG}-${DATE}.html"
# Write the populated HTML to $SAVE_PATH using the Write tool
```

---

## Phase 5 — Screenshot

Same pipeline as `code-share`:

1. `python3 $PLUGIN_DIR/scripts/find_free_port.py` → `$PORT`
2. `cd ~/.claude/tmp && python3 -m http.server $PORT & SERVER_PID=$!; echo "PID:$SERVER_PID"`
3. ToolSearch for Playwright tools: `select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_wait_for`
4. Navigate → wait → screenshot to `~/.claude/tmp/video-share-card.png`
5. `kill $SERVER_PID 2>/dev/null || true`

**Fallback:** if Playwright unavailable, tell the user the HTML path for manual screenshot.

---

## Phase 6 — Deliver

1. `## [Platform] Copy` heading
2. Copy in fenced code block with character count `[NNN / max]`
3. Attach `~/.claude/tmp/video-share-card.png` via `SendUserFile`
4. Saved HTML path: `docs/media/social/video-{slug}-{date}.html`
5. Note: "Open the saved HTML in a browser to view the card and use the **Copy post** button."

**STOP.**
