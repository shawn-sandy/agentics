# Template Variable Reference

All templates live in `kit/plugins/social-media-tools/templates/`. Each HTML file has a comment block at the top listing its variables and an example.

---

## diff-card.html

| Variable | Description |
|----------|-------------|
| `{{FILENAME}}` | File path or rule name being changed (e.g., `plan-mode.md`) |
| `{{BADGE}}` | Short label shown top-right (e.g., `v3.4.1`, `feat`, `fix`) |
| `{{HUNK_1_HEADER}}` | First hunk header text (e.g., `@@ Workflow §3 @@`) |
| `{{HUNK_1_ROWS}}` | HTML `<tr>` rows for the first hunk — see row format below |
| `{{HUNK_2_HEADER}}` | Second hunk header — omit entire second hunk `<tr>` block if unused |
| `{{HUNK_2_ROWS}}` | HTML `<tr>` rows for the second hunk |
| `{{STAT_ADD}}` | Addition count integer (e.g., `12`) |
| `{{STAT_DEL}}` | Deletion count integer (e.g., `3`) |
| `{{WORKFLOW_SUMMARY}}` | One-line summary shown in the footer stat bar |

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

---

## blog-card.html

> Used by `blog-share` skill. All text values must be HTML-escaped before substitution.

### Static variables

| Variable | Description |
|----------|-------------|
| `{{TITLE}}` | Blog post headline (HTML-escaped) |
| `{{EXCERPT}}` | Short description or first paragraph, truncated to 280 chars (HTML-escaped) |
| `{{AUTHOR}}` | Author name (HTML-escaped) — empty string if not found |
| `{{DATE}}` | Publication date formatted as `MMM D, YYYY` (HTML-escaped) — empty string if not found |
| `{{SOURCE_DOMAIN}}` | Hostname of the source URL with `www.` stripped (HTML-escaped) |

### Conditional element variables

The skill injects a full HTML element **or an empty string `""`** — do not use CSS tricks.

| Variable | Inject when | HTML to inject |
|----------|-------------|----------------|
| `{{READ_TIME_BADGE}}` | `READ_TIME` is non-empty (local .md files only) | `<span class="read-time">N min read</span>` |
| `{{TAGS_FOOTER}}` | At least one tag exists | `<div class="card-footer"><span class="tag">tag1</span>...</div>` — each tag value HTML-escaped |

---

## video-card.html

> Used by `video-share` skill. `PLATFORM_COLOR` must come from the hardcoded map in the skill — never from fetched content.

### Static variables

| Variable | Description |
|----------|-------------|
| `{{VIDEO_TITLE}}` | Video title (HTML-escaped) |
| `{{CHANNEL}}` | Channel or creator name from oEmbed `author_name` (HTML-escaped) |
| `{{PLATFORM_BADGE}}` | `"YouTube"` or `"Vimeo"` (hardcoded by skill from URL detection) |
| `{{PLATFORM_COLOR}}` | `#ff0000` (YouTube) or `#1ab7ea` (Vimeo) — hardcoded by skill, never user-sourced |
| `{{DESCRIPTION_SNIPPET}}` | First 150 chars of video description (HTML-escaped) — empty string if unavailable |
| `{{CTA}}` | `"▶ Watch on YouTube"` or `"▶ Watch on Vimeo"` (hardcoded by skill) |

### Conditional element variable

| Variable | Inject when | HTML to inject |
|----------|-------------|----------------|
| `{{THUMBNAIL_ZONE}}` | `thumbnail_url` is non-empty | `<div class="video-thumbnail"><img src="URL" alt="Video thumbnail"><div class="play-overlay"><span class="play-icon">&#9654;</span></div></div>` |

---

## snippet-card.html

> Used by `github-code-share` skill. `{{CODE_LINES}}` **must** be HTML-escaped before substitution — unescaped code breaks card rendering.

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

### Notes

- The `{{LANGUAGE}}` variable fills both the display badge text and the `language-{{LANGUAGE}}` CSS class on the `<code>` element. Pass the lowercase hljs alias (`typescript`), not the display name (`TypeScript`).
- `LANGUAGE_COLOR` is sourced exclusively from `skills/github-code-share/references/language-map.md` — never from fetched content or user input.

---

## COPY_PANELS (all card types)

> Used by all five card-generating skills (`code-share`, `blog-share`, `video-share`, `github-code-share`, `project-share`). Supplies the copy panel markup in the saved HTML. Each template defines one shared `copyPost(id, btn)` function; every copy button calls it with its own textarea `id`.

| Field | Value |
|-------|-------|
| Variable | `{{COPY_PANELS}}` |
| Type | HTML — one or more `<div class="copy-panel">` blocks |
| Source | The drafted post copy from the Draft phase |
| Escaping | **Textarea-safe**, applied per variant in this order: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;` (do **not** escape `"`) |

### Single site — one panel (default, unchanged behavior)

Textarea content is all platform variants joined with `\n---\n`, then escaped:

```html
<div class="copy-panel">
  <p class="copy-label">Social media post</p>
  <textarea readonly class="post-copy-text" id="post-copy">ESCAPED_COPY</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy', this)">Copy post</button>
</div>
```

### All sites — three per-site panels

One panel per platform, each holding only that platform's escaped copy under a unique `id`:

```html
<div class="copy-panel">
  <p class="copy-label">LinkedIn</p>
  <textarea readonly class="post-copy-text" id="post-copy-linkedin">ESCAPED_LINKEDIN</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy-linkedin', this)">Copy LinkedIn post</button>
</div>
<div class="copy-panel">
  <p class="copy-label">Twitter/X</p>
  <textarea readonly class="post-copy-text" id="post-copy-twitter">ESCAPED_TWITTER</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy-twitter', this)">Copy Twitter/X post</button>
</div>
<div class="copy-panel">
  <p class="copy-label">Bluesky</p>
  <textarea readonly class="post-copy-text" id="post-copy-bluesky">ESCAPED_BLUESKY</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy-bluesky', this)">Copy Bluesky post</button>
</div>
```

### Notes

- Every panel keeps `class="post-copy-text"`, so reuse/extraction (`media-library` and each skill's reuse check) matches **by class** — one textarea for a single site, three for all sites — and labels each by its preceding `copy-label`.
- Content inside `<textarea>` is parsed as HTML character data: the browser decodes entities and shows raw text. Apply `&amp;` → `&lt;` → `&gt;`; do **not** escape `"`.
