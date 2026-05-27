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
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Collect Input | Detect URL vs local file; resolve relative paths; ask platform + tone |
| 1c — Reuse check | Scan `docs/media/social/` for existing blog posts; offer reuse |
| 2 — Fetch Metadata | WebFetch OG tags (URL) or Read front matter (local); HTML-escape all values |
| 3 — Draft Copy | Write platform-aware copy |
| 4 — Populate Template | Fill `blog-card.html`; inject conditional elements + `{{COPY_PANELS}}` |
| 4b — Save | Persistent save to `docs/media/social/` |
| 5 — Screenshot | Serve HTML locally; Playwright screenshot |
| 6 — Deliver | Present copy + attach PNG + show saved path |

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Derive:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
```

If not found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Collect Input

Detect the source type:
- **URL**: starts with `http://` or `https://`
- **Local file**: ends with `.md`, `.mdx`, or `.markdown`

If the user provides a **relative path**, resolve it:
```bash
realpath "$USER_PATH" 2>/dev/null || echo "$PWD/$USER_PATH"
```

Use `AskUserQuestion` to collect whatever is missing. Batch all questions in one call:

| Input | Options | Notes |
|-------|---------|-------|
| `SOURCE` | URL or file path | Required |
| `PLATFORM` | LinkedIn, Twitter/X, Bluesky, All sites | Required |
| `TONE` | Professional, Casual, Punchy | Default: Professional (LinkedIn), Punchy (Twitter/Bluesky) |
| `HOOK_ANGLE` | Free text | Optional |

---

## Phase 1c — Reuse Check

```
FILE_PREFIX=blog
Read $PLUGIN_DIR/references/reuse-check.md and follow its procedure.
```

---

## Phase 2 — Fetch Metadata

### Deferred tool bootstrap

```
Use ToolSearch with select:WebFetch first (silent, no user output), then call WebFetch.
```

Both steps happen silently.

### URL source

Call `WebFetch` on `SOURCE`. Extract:

| Variable | Source |
|----------|--------|
| `TITLE` | `<meta property="og:title">` → `<title>` fallback |
| `EXCERPT` | `<meta property="og:description">` → first `<p>`, truncated to 280 chars |
| `AUTHOR` | `<meta property="article:author">` → `""` if not found |
| `DATE` | `<meta property="article:published_time">` → `MMM D, YYYY` → `""` if not found |
| `SOURCE_DOMAIN` | Hostname, strip `www.` |
| `TAGS` | `<meta property="article:tag">`, up to 5 |
| `READ_TIME` | `""` — do not compute for URL sources |

### Local file source

Call `Read` on the resolved absolute path. Extract:

| Variable | Source |
|----------|--------|
| `TITLE` | YAML front matter `title:` → first `# H1` |
| `EXCERPT` | YAML `description:` → first non-heading paragraph, truncated to 280 chars |
| `AUTHOR` | YAML `author:` → `""` |
| `DATE` | YAML `date:` → `MMM D, YYYY` → `""` |
| `SOURCE_DOMAIN` | YAML `site:` or `url:` hostname → `"local file"` |
| `TAGS` | YAML `tags:` array, up to 5 |
| `READ_TIME` | Word count of body (excl. front matter + headings) / 200 wpm, rounded |

### HTML-escape all extracted values

Before any template substitution, apply to every text value:
1. `&` → `&amp;` (must be first)
2. `<` → `&lt;`
3. `>` → `&gt;`

---

## Phase 3 — Draft Copy

For character limits and universal copy rules, read `$PLUGIN_DIR/references/platforms.md`.
For copy format and filled examples per platform, read `references/platforms.md`.

Present drafted copy in a fenced code block labelled with the platform name. Wait for approval.

- **Single site:** store joined with `\n---\n` as `POST_COPY_TEXT_RAW`
- **All sites:** keep separate (`LINKEDIN_COPY`, `TWITTER_COPY`, `BLUESKY_COPY`)

---

## Phase 4 — Populate Template

### Conditional element substitution

**`{{READ_TIME_BADGE}}`**
- If `READ_TIME` is non-empty: `<span class="read-time">N min read</span>`
- If empty: `""`

**`{{TAGS_FOOTER}}`**
- If `TAGS` has at least one value:
  ```html
  <div class="card-footer"><span class="tag">tag1</span><span class="tag">tag2</span></div>
  ```
  (each tag value HTML-escaped)
- If no tags: `""`

### COPY_PANELS

Read `$PLUGIN_DIR/references/copy-panels.md` for markup and escaping rules.

### Write and set variables

Replace all `{{VARIABLE}}` placeholders. Write to `~/.claude/tmp/blog-share-card.html`:

```bash
mkdir -p ~/.claude/tmp
TEMP_HTML=blog-share-card.html
FILE_PREFIX=blog
SLUG_INPUT=$TITLE
```

---

## Phase 4b — Persistent Save

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

---

## Phase 5 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 6 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.
