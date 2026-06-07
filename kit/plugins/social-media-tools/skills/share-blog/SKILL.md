---
name: share-blog
description: "Creates platform-aware social copy and a dark-mode card for a blog post. Fetches OG tags, populates blog-card.html, and screenshots via Playwright. Use when asked to share a blog post on social media."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, WebFetch, SendUserFile, Glob
---

# share-blog

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

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
[ -n "${CLAUDE_PLUGIN_ROOT}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/templates" ] && \
  echo "${CLAUDE_PLUGIN_ROOT}/templates"
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
| `PLATFORM` | See **Platform Options** in `$PLUGIN_DIR/references/platforms.md` | Required |
| `TONE` | Professional, Casual, Punchy | Default: Professional (LinkedIn), Punchy (Twitter/Bluesky) |
| `HOOK_ANGLE` | Free text | Optional |

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=blog
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

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

Read `$PLUGIN_DIR/references/platforms.md` for character limits, universal copy rules,
and **Draft Copy — Standard Procedure**.
For copy format and filled examples per platform, read the skill-local `references/platforms.md`
(adjacent to this SKILL.md).

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

Replace all `{{VARIABLE}}` placeholders. Write to `~/.claude/tmp/share-blog-card.html`:

```bash
mkdir -p ~/.claude/tmp
TEMP_HTML=share-blog-card.html
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
