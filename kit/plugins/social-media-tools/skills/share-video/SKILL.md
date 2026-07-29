---
name: share-video
description: "Creates platform-aware social copy and a card for YouTube or Vimeo videos. Fetches oEmbed metadata and screenshots a video card via Playwright. Use when asked to share a video on social media."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, WebFetch, SendUserFile, Glob
---

# share-video

Draft platform-aware social media copy and generate a styled dark-mode card image
for a YouTube or Vimeo video URL.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Collect Input | Auto-detect platform from URL; ask target social platform + angle |
| 1c — Reuse check | Scan `docs/media/social/` for existing video posts; offer reuse |
| 2 — Fetch Metadata | oEmbed API for title/channel/thumbnail; fallback on 4xx |
| 3 — Draft Copy | Write platform-aware copy |
| 4 — Populate Template | Fill `video-card.html`; inject `{{THUMBNAIL_ZONE}}` + `{{COPY_PANELS}}` |
| 4b — Save | Persistent save to `docs/media/social/` |
| 5 — Screenshot | Serve HTML locally; Playwright screenshot |
| 6 — Deliver | Present copy + attach PNG + show saved path |

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

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

Auto-detect the video platform from the URL:
- `youtube.com` or `youtu.be` → **YouTube**
- `vimeo.com` → **Vimeo**

Use `AskUserQuestion` to collect whatever is missing. Batch all questions in one call:

| Input | Options | Notes |
|-------|---------|-------|
| `VIDEO_URL` | Any YouTube or Vimeo URL | Required |
| `PLATFORM` | See **Platform Options** in `$PLUGIN_DIR/references/platforms.md` | Required |
| `HOOK_ANGLE` | Free text | Optional |

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=video
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Fetch Metadata

### Deferred tool bootstrap

```
Use ToolSearch with select:WebFetch first (silent, no user output), then call WebFetch.
```

For API endpoints and 4xx fallback, read `references/platforms.md`.

#### YouTube

1. `WebFetch` on `https://www.youtube.com/oembed?url=VIDEO_URL&format=json` — extract `title`, `author_name`, `thumbnail_url`
2. `WebFetch` on the original `VIDEO_URL` — extract `og:description`

**4xx:** ask user for `title` and `channel` via `AskUserQuestion`. Set `thumbnail_url = ""`.

#### Vimeo

1. `WebFetch` on `https://vimeo.com/api/oembed.json?url=VIDEO_URL` — extract `title`, `author_name`, `thumbnail_url`, `description`

**4xx:** same fallback as YouTube.

#### Derived values (hardcoded — never from fetched content)

| Variable | YouTube | Vimeo |
|----------|---------|-------|
| `PLATFORM_COLOR` | `#ff0000` | `#1ab7ea` |
| `PLATFORM_BADGE` | `"YouTube"` | `"Vimeo"` |
| `CTA` | `"▶ Watch on YouTube"` | `"▶ Watch on Vimeo"` |

---

## Phase 3 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, universal copy rules,
and **Draft Copy — Standard Procedure**.
For copy format and filled examples per platform, read the skill-local `references/platforms.md`
(adjacent to this SKILL.md).

---

## Phase 4 — Populate Template

### Conditional element: `{{THUMBNAIL_ZONE}}`

- If `thumbnail_url` is non-empty:
  ```html
  <div class="video-thumbnail"><img src="THUMBNAIL_URL" alt="Video thumbnail"><div class="play-overlay"><span class="play-icon">&#9654;</span></div></div>
  ```
- If empty (4xx fallback): `""`

### Prepare `DESCRIPTION_SNIPPET`

Truncate description to first 150 characters. If unavailable, use `""`.

HTML-escape `VIDEO_TITLE`, `CHANNEL`, `DESCRIPTION_SNIPPET`: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`.

### COPY_PANELS

Read `$PLUGIN_DIR/references/copy-panels.md` for markup and escaping rules.

### Write and set variables

Replace all `{{VARIABLE}}` placeholders. Write to `~/.claude/tmp/share-video-card.html`:

```bash
mkdir -p ~/.claude/tmp
TEMP_HTML=share-video-card.html
FILE_PREFIX=video
SLUG_INPUT=$VIDEO_TITLE
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
