# Template Variable Reference

All templates live in `kit/plugins/social-media-tools/templates/`. Each HTML file has a
comment block at the top listing its variables and an example.

## Contents

- [diff-card.html](#diff-cardhtml)
- [feature-card.html](#feature-cardhtml)
- [quote-card.html](#quote-cardhtml)
- [blog-card.html](#blog-cardhtml)
- [video-card.html](#video-cardhtml)
- [snippet-card.html](#snippet-cardhtml)
- [session-card.html](#session-cardhtml)

---

## diff-card.html

| Variable | Description |
|----------|-------------|
| `{{FILENAME}}` | File path or rule name being changed (e.g., `plan-mode.md`) |
| `{{BADGE}}` | Short label shown top-right (e.g., `v3.4.1`, `feat`, `fix`) |
| `{{HUNK_1_HEADER}}` | First hunk header text (e.g., `@@ Workflow Step 3 @@`) |
| `{{HUNK_1_ROWS}}` | HTML `<tr>` rows for the first hunk — see row format below |
| `{{HUNK_2_HEADER}}` | Second hunk header — omit entire second hunk `<tr>` block if unused |
| `{{HUNK_2_ROWS}}` | HTML `<tr>` rows for the second hunk |
| `{{STAT_ADD}}` | Addition count integer (e.g., `12`) |
| `{{STAT_DEL}}` | Deletion count integer (e.g., `3`) |
| `{{WORKFLOW_SUMMARY}}` | One-line summary shown in the footer stat bar |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

### Row format

```html
<tr class="add"><td class="ln">+</td><td class="code">  added line content</td></tr>
<tr class="del"><td class="ln">-</td><td class="code">  removed line content</td></tr>
<tr class="ctx"><td class="ln"> </td><td class="code">  context line</td></tr>
```

Inline highlights inside `<td class="code">`:

```html
<span class="hl-add">added word</span>
<span class="hl-del">removed word</span>
```

---

## feature-card.html

| Variable | Description |
|----------|-------------|
| `{{TITLE}}` | Main headline (e.g., `code-share plugin v0.1.0`) |
| `{{SUBTITLE}}` | Supporting line (e.g., `Now in the agentics marketplace`) |
| `{{BADGE}}` | Short label for top badge and footer (e.g., `New Plugin`) |
| `{{BULLETS}}` | HTML `<li>` elements — one per key feature, no wrapping `<ul>` needed |
| `{{FOOTER_NOTE}}` | Footer left side (e.g., `github.com/shawn-sandy/agentics`) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

### Bullet format

```html
<li>Draft LinkedIn, Twitter/X, and Bluesky copy in one command</li>
<li>Generates styled dark-mode visual cards via Playwright</li>
```

---

## quote-card.html

| Variable | Description |
|----------|-------------|
| `{{CONTEXT}}` | Small tag line at top (e.g., `Developer Insight`, `Claude Code`) |
| `{{QUOTE}}` | The pull quote — no surrounding quotes needed; template adds them |
| `{{ATTRIBUTION}}` | Author or source (e.g., `Shawn Sandy`, `@shawnsandy`) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

---

## blog-card.html

> Used by `share-blog` skill. All text values must be HTML-escaped before substitution.

### Static variables

| Variable | Description |
|----------|-------------|
| `{{TITLE}}` | Blog post headline (HTML-escaped) |
| `{{EXCERPT}}` | Short description or first paragraph, truncated to 280 chars (HTML-escaped) |
| `{{AUTHOR}}` | Author name (HTML-escaped) — empty string if not found |
| `{{DATE}}` | Publication date formatted as `MMM D, YYYY` (HTML-escaped) — empty string if not found |
| `{{SOURCE_DOMAIN}}` | Hostname of the source URL with `www.` stripped (HTML-escaped) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

### Conditional element variables

The skill injects a full HTML element **or an empty string `""`** — do not use CSS tricks.

| Variable | Inject when | HTML to inject |
|----------|-------------|----------------|
| `{{READ_TIME_BADGE}}` | `READ_TIME` is non-empty (local .md files only) | `<span class="read-time">N min read</span>` |
| `{{TAGS_FOOTER}}` | At least one tag exists | `<div class="card-footer"><span class="tag">tag1</span>...</div>` — each tag value HTML-escaped |

---

## video-card.html

> Used by `share-video` skill. `PLATFORM_COLOR` must come from the hardcoded map in the
> skill — never from fetched content.

### Static variables

| Variable | Description |
|----------|-------------|
| `{{VIDEO_TITLE}}` | Video title (HTML-escaped) |
| `{{CHANNEL}}` | Channel or creator name from oEmbed `author_name` (HTML-escaped) |
| `{{PLATFORM_BADGE}}` | `"YouTube"` or `"Vimeo"` (hardcoded by skill from URL detection) |
| `{{PLATFORM_COLOR}}` | `#ff0000` (YouTube) or `#1ab7ea` (Vimeo) — hardcoded by skill, never user-sourced |
| `{{DESCRIPTION_SNIPPET}}` | First 150 chars of video description (HTML-escaped) — empty string if unavailable |
| `{{CTA}}` | `"▶ Watch on YouTube"` or `"▶ Watch on Vimeo"` (hardcoded by skill) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

### Conditional element variable

| Variable | Inject when | HTML to inject |
|----------|-------------|----------------|
| `{{THUMBNAIL_ZONE}}` | `thumbnail_url` is non-empty | `<div class="video-thumbnail"><img src="URL" alt="Video thumbnail"><div class="play-overlay"><span class="play-icon">&#9654;</span></div></div>` |

---

## snippet-card.html

> Used by `share-github` skill. `{{CODE_LINES}}` **must** be HTML-escaped before
> substitution — unescaped code breaks card rendering.

### HTML-escape order (mandatory)

Apply to `CODE_LINES` in this exact order:
1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

### Variables

| Variable | Description |
|----------|-------------|
| `{{FILENAME}}` | File basename, e.g. `auth.ts` (HTML-escaped) |
| `{{LANGUAGE}}` | **Lowercase hljs alias** for the `<code>` class attribute: `typescript`, `python`, `go`, `csharp`, `cpp`, `bash`, etc. |
| `{{LANGUAGE_COLOR}}` | Hex colour from `language-map.md` (e.g. `#3178c6`) — hardcoded, never user-sourced |
| `{{CODE_LINES}}` | HTML-escaped code content |
| `{{LINE_RANGE}}` | e.g. `"L10–L25"` or `"lines 1–80"` |
| `{{REPO_SLUG}}` | `"owner/repo"` (HTML-escaped) |
| `{{GITHUB_URL}}` | Original GitHub URL with fragment stripped |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

### Notes

- The `{{LANGUAGE}}` variable fills both the display badge text and the `language-{{LANGUAGE}}`
  CSS class on the `<code>` element. Pass the lowercase hljs alias (`typescript`), not the
  display name (`TypeScript`).
- `LANGUAGE_COLOR` is sourced exclusively from `references/language-map.md` (plugin-root
  shared reference) — never from fetched content or user input.

---

## session-card.html

> Used by `share-session`. Content-first layout: a narrative + accomplishment bullets are the
> hero; token/activity metrics are a compact secondary strip. All text values must be
> HTML-escaped before substitution.

| Variable | Description |
|----------|-------------|
| `{{TITLE}}` | `session recap · YYYY-MM-DD` (HTML-escaped) |
| `{{MODEL}}` | Model badge, e.g. `sonnet-4-6` (HTML-escaped) |
| `{{NARRATIVE}}` | 1–2 sentence summary of what the session accomplished (HTML-escaped; ≤240 chars) |
| `{{ACCOMPLISHMENTS}}` | `<li>` items (3–5), one per accomplishment, no wrapping `<ul>`; each item's text HTML-escaped |
| `{{TOTAL_TOKENS}}` | Total tokens with commas (e.g. `42,180`) |
| `{{DURATION}}` | Session duration (e.g. `47 min`) |
| `{{CACHE_HIT_RATE}}` | Cache hit rate (e.g. `44.2%`) |
| `{{FILES_CHANGED}}` | Files-changed count (git, session window) |
| `{{COMMITS}}` | Commits in the session window |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

### Accomplishment item format

Build `{{ACCOMPLISHMENTS}}` the same way as `feature-card.html`'s `{{BULLETS}}`: HTML-escape
each bullet's text, wrap each in `<li>…</li>`, and concatenate (no surrounding `<ul>`).

```html
<li>Added a content summary to the share-session card</li>
<li>Enriched session_usage.py with file + tool signals</li>
```

### HTML-escape order (mandatory)

Apply to every text value in this exact order:
1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`
