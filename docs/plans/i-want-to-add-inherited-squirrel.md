# Plan: Extend code-share Plugin for Blog, Video, and GitHub Code Snippet Social Posts

## Context

The existing `code-share` plugin (`kit/plugins/social-media-tools/`) generates LinkedIn/Twitter/Bluesky posts for **local code commits and diffs**. The user wants to extend this capability to cover three additional content types:

- **Blog posts** — given a URL or local markdown file, generate platform copy + styled card
- **Videos** — given a YouTube or Vimeo URL, generate platform copy + video preview card
- **GitHub code file/snippet** — given a GitHub file URL (optionally with a line range `#L10-L25`), fetch the raw code, security-scrub it, and generate a copy + syntax-highlighted card

Platforms remain LinkedIn, Twitter/X, and Bluesky (matching existing code-share scope).

These fit naturally in the existing plugin (`social-media-tools/`) which already has the screenshot pipeline, card template system, and platform-aware copy workflow.

---

## New Files

### 1. `kit/plugins/social-media-tools/skills/blog-share/SKILL.md`

**Frontmatter:**
```yaml
name: blog-share
description: "Generates social media copy and a styled card image for a blog post URL or local markdown file. Use when the user asks to share a blog post, article, or write-up on LinkedIn, Twitter, or Bluesky."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, WebFetch, SendUserFile
```

**Workflow (6 phases, mirrors code-share):**

**Phase 1 — Collect Input**
- Detect URL vs. local file path. If URL: starts with `http://` or `https://`. If local: `.md`, `.mdx`, or `.markdown` extension.
- Batch `AskUserQuestion` for: `SOURCE` (if not provided), `PLATFORM` (LinkedIn/Twitter/X/Bluesky), `TONE` (Professional/Casual/Punchy), optional `HOOK_ANGLE`.

**Phase 2 — Fetch Metadata**
- Use `ToolSearch` with `select:WebFetch` first (silent bootstrap — `WebFetch` is a deferred tool).
- **URL source:** `WebFetch` the URL → extract: `og:title`, `og:description`, `article:author`, `article:published_time`, `article:tag` (up to 5), hostname as `SOURCE_DOMAIN` (strip `www.`). Do NOT compute `READ_TIME` for URL sources — leave blank.
- **Local file:** `Read` → extract YAML front matter (`title`, `author`, `date`, `tags`, `description`) and first non-heading paragraph as excerpt. Compute `READ_TIME` = word count / 200 wpm (clean text, no tag stripping needed).

**Phase 3 — Draft Copy**
- LinkedIn (1,500 char): hook line → 3 numbered key takeaways → personal commentary → CTA with link → 3–4 hashtags
- Twitter/X (280 char): hook sentence naming the key insight + URL + 1–2 hashtags
- Bluesky (300 char): "Just read [TITLE] by [AUTHOR] — [one key observation]. Worth your time if you [relevant condition]."
- Present draft in fenced block; wait for approval.

**Phase 4 — Populate Template**
- Locate `TEMPLATES_DIR` using the same three-path probe as code-share. `TEMPLATE_FILE=$TEMPLATES_DIR/blog-card.html`.
- Substitute: `{{TITLE}}`, `{{EXCERPT}}`, `{{AUTHOR}}`, `{{DATE}}`, `{{SOURCE_DOMAIN}}`, `{{READ_TIME}}` (empty string if URL source), `{{TAGS}}` (as `<span class="tag">` chips; omit `.card-footer` entirely if no tags).
- Write to `~/.claude/tmp/blog-share-card.html`.

**Phase 5 — Screenshot**
- Identical to code-share Phase 5: `find_free_port.py` → `http.server $PORT` → Playwright navigate/screenshot → kill server.
- Output: `~/.claude/tmp/blog-share-card.png`

**Phase 6 — Deliver**
- Platform label heading + fenced copy + char count + `SendUserFile` PNG + HTML path.

---

### 2. `kit/plugins/social-media-tools/skills/blog-share/references/platforms.md`

Platform formatting rules with filled-in examples for all three platforms. Keeps SKILL.md body under 500 lines and makes rules user-tunable without editing the skill.

---

### 3. `kit/plugins/social-media-tools/skills/video-share/SKILL.md`

**Frontmatter:**
```yaml
name: video-share
description: "Generates social media copy and a styled card image for a YouTube or Vimeo video URL. Use when the user asks to share a video, post about a talk, or promote video content on LinkedIn, Twitter, or Bluesky."
allowed-tools: AskUserQuestion, Write, Bash, ToolSearch, WebFetch, SendUserFile
```

**Workflow (6 phases):**

**Phase 1 — Collect Input**
- Auto-detect platform from URL: `youtube.com`/`youtu.be` → YouTube; `vimeo.com` → Vimeo.
- Batch `AskUserQuestion` for: `VIDEO_URL` (if not provided), `PLATFORM`, optional `HOOK_ANGLE`.

**Phase 2 — Fetch Metadata**
- `ToolSearch` with `select:WebFetch` first (silent bootstrap).
- **YouTube:** `WebFetch` on `https://www.youtube.com/oembed?url=VIDEO_URL&format=json` → extract `title`, `author_name`, `thumbnail_url`. If response is 4xx (private/deleted video): ask user to supply title and channel manually via `AskUserQuestion` and skip `thumbnail_url`. Second `WebFetch` on the original video URL → extract `og:description`.
- **Vimeo:** `WebFetch` on `https://vimeo.com/api/oembed.json?url=VIDEO_URL` → extract `title`, `author_name`, `thumbnail_url`, `description`. If response is 4xx: ask user for title and channel.
- Set `PLATFORM_COLOR`: `#ff0000` (YouTube) or `#1ab7ea` (Vimeo). Set `CTA`: "▶ Watch on YouTube/Vimeo".

**Phase 3 — Draft Copy**
- LinkedIn (1,500 char): why-watch narrative + key insight from description + "Watch ▶ [URL]" CTA + 2–3 hashtags
- Twitter/X (280 char): punchy hook + "Watch ▶ [URL]"
- Bluesky (300 char): quick take + link

**Phase 4 — Populate Template**
- `TEMPLATE_FILE=$TEMPLATES_DIR/video-card.html`.
- Substitute: `{{VIDEO_TITLE}}`, `{{CHANNEL}}`, `{{PLATFORM_BADGE}}`, `{{PLATFORM_COLOR}}`, `{{DESCRIPTION_SNIPPET}}` (first 150 chars of description), `{{THUMBNAIL_URL}}` (empty string if unavailable — template hides the thumbnail zone when blank), `{{CTA}}`.
- Write to `~/.claude/tmp/video-share-card.html`.

**Phases 5 & 6** — same as blog-share, output: `video-share-card.{html,png}`.

---

### 4. `kit/plugins/social-media-tools/skills/video-share/references/platforms.md`

Platform formatting rules + oEmbed endpoint reference table:

| Platform | oEmbed endpoint |
|----------|----------------|
| YouTube | `https://www.youtube.com/oembed?url={URL}&format=json` |
| Vimeo | `https://vimeo.com/api/oembed.json?url={URL}` |

Note: oEmbed returns no `description` field. A second `WebFetch` on the video page URL is required to get `og:description`.

---

### 5. `kit/plugins/social-media-tools/skills/github-code-share/SKILL.md`

**Frontmatter:**
```yaml
name: github-code-share
description: "Fetches a code file or snippet from a GitHub URL and generates a social post with a syntax-highlighted card. Use when the user asks to share a specific file, function, or code snippet from a GitHub repository."
allowed-tools: AskUserQuestion, Write, Bash, ToolSearch, WebFetch, Skill, SendUserFile
```

Note: `Write` is needed for both the security-scrub temp file (Phase 3) and the HTML card (Phase 5). `Skill` is needed to call `security-scrub`.

**Workflow (6 phases):**

**Phase 1 — Parse GitHub URL**

Accept GitHub blob URLs only: `https://github.com/{owner}/{repo}/blob/{branch}/{path}`.

**Parse the fragment first, before any WebFetch call** — URL fragments (`#L10-L25`) are never sent to the server:
1. If the URL contains `#L`, split on `#` and extract the line range string.
   - `#L10` → `LINE_START=10`, `LINE_END=10`
   - `#L10-L25` → `LINE_START=10`, `LINE_END=25`
2. Strip the `#...` fragment from the URL before using it in any subsequent step.

Then extract: `OWNER`, `REPO`, `BRANCH`, `FILE_PATH` from the path segments.
Derive `FILENAME` = basename of `FILE_PATH` (e.g., `auth.ts`).
Derive `LANGUAGE` from file extension using `references/language-map.md`.

This skill only works with **public repositories**. If WebFetch later returns a 4xx, tell the user "This may be a private repository — this skill only supports public repos" and STOP.

Ask for `PLATFORM` and optional `HOOK_ANGLE` via `AskUserQuestion`.

**Phase 2 — Fetch Raw Code**
- `ToolSearch` with `select:WebFetch` first (silent bootstrap).
- Convert blob URL to raw URL: `https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}/{FILE_PATH}`.
- `WebFetch` the raw URL. If 4xx response: surface the private-repo error from Phase 1 and STOP.
- If `LINE_START`/`LINE_END` are set: extract only lines `LINE_START` through `LINE_END` from the content (1-indexed).
- If no line range: cap at the first 80 lines; notify the user that only the first 80 lines are shown.

**Phase 3 — Security Scrub**

`security-scrub` uses `Grep` which operates on files, not inline text. Write the extracted snippet to a temp file first:

```
Write the snippet to ~/.claude/tmp/scrub-input.txt
```

Then call `Skill(skill: "code-share:security-scrub")` — the skill will read from that path.

Parse the returned `SCRUB RESULT` block:
- `SCRUB RESULT: BLOCKED` or `ALLOWLIST verdict: BLOCKED` → tell the user what was found (masked values), and STOP. Do not proceed.
- `SCRUB RESULT: WARN` → surface the warning and ask the user to confirm before continuing.
- `SCRUB RESULT: PASS` → continue silently.

**Phase 4 — Draft Copy**
- LinkedIn (1,500 char): context framing ("Here's [LANGUAGE] code from [OWNER/REPO] that...") + what the code does + key design decision or insight + CTA linking to file + hashtags
- Twitter/X (280 char): "[LANGUAGE] snippet worth seeing → [what it does in one phrase] — [GitHub URL]"
- Bluesky (300 char): similar brevity to Twitter

**Phase 5 — Populate Template**
- `TEMPLATE_FILE=$TEMPLATES_DIR/snippet-card.html`.
- **HTML-escape all code content before substitution**: replace `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`. This is mandatory — unescaped code will break the card's HTML rendering.
- Substitute: `{{FILENAME}}`, `{{LANGUAGE}}`, `{{LANGUAGE_COLOR}}` (from language-map.md), `{{CODE_LINES}}` (HTML-escaped), `{{LINE_RANGE}}` (e.g., "L10–L25" or "full file, first 80 lines"), `{{REPO_SLUG}}` (e.g., "owner/repo"), `{{GITHUB_URL}}`.
- Write to `~/.claude/tmp/github-code-share-card.html`.
- Run screenshot pipeline → `~/.claude/tmp/github-code-share-card.png`.

**Phase 6 — Deliver** — same pattern as other skills.

---

### 6. `kit/plugins/social-media-tools/skills/github-code-share/references/language-map.md`

File extension → display name + badge color map for 20+ common languages. Used in Phase 1 to set `LANGUAGE` and `LANGUAGE_COLOR`.

Example entries: `.ts` → TypeScript / `#3178c6`, `.py` → Python / `#3572A5`, `.go` → Go / `#00ADD8`, `.rs` → Rust / `#dea584`, `.js` → JavaScript / `#f1e05a`, `.rb` → Ruby / `#701516`, `.java` → Java / `#b07219`, `.cs` → C# / `#178600`.

---

### 7. `kit/plugins/social-media-tools/templates/blog-card.html`

Dark-mode card, same GitHub color scheme (`#0d1117` bg, `#161b22` surface, `#388bfd` accent).

**Variables:** `{{TITLE}}`, `{{EXCERPT}}`, `{{AUTHOR}}`, `{{DATE}}`, `{{SOURCE_DOMAIN}}`, `{{READ_TIME}}`, `{{TAGS}}`

**Layout:**
- Header (`#0d1117`): "Blog Post" label left + `{{SOURCE_DOMAIN}}` pill right + `{{READ_TIME}}` badge (hidden if empty)
- Body (`#161b22`, padding 28px 32px): large `{{TITLE}}` h1 (24px, 700), `{{EXCERPT}}` paragraph (14px, muted, max 3 lines, green left border accent matching existing card style)
- Meta row (border-top): `{{AUTHOR}}` left · `{{DATE}}` right, both 12px muted
- Footer (`#0d1117`): `{{TAGS}}` as chips (bg: `rgba(56,139,253,0.12)`, color `#79c0ff`, border-radius 20px); entire footer omitted if `{{TAGS}}` is empty

---

### 8. `kit/plugins/social-media-tools/templates/video-card.html`

Dark-mode video preview card.

**Variables:** `{{VIDEO_TITLE}}`, `{{CHANNEL}}`, `{{PLATFORM_BADGE}}`, `{{PLATFORM_COLOR}}`, `{{DESCRIPTION_SNIPPET}}`, `{{THUMBNAIL_URL}}`, `{{CTA}}`

**Layout:**
- Thumbnail zone (height 180px, hidden via `display:none` when `{{THUMBNAIL_URL}}` is empty): `<img src="{{THUMBNAIL_URL}}">` object-fit cover + centered ▶ play-button overlay (pure CSS/Unicode, no external assets — works offline)
- Body (padding 20px 24px): platform badge (bg: `{{PLATFORM_COLOR}}` at 20% opacity, border `{{PLATFORM_COLOR}}`), `{{CHANNEL}}` muted, `{{VIDEO_TITLE}}` h2 (18px 700), `{{DESCRIPTION_SNIPPET}}` (13px muted, 2-line clamp)
- Footer: `{{CTA}}` button (bg `{{PLATFORM_COLOR}}`, white text, 12px 20px padding, border-radius 6px)

---

### 9. `kit/plugins/social-media-tools/templates/snippet-card.html`

Dark-mode code snippet card with syntax highlighting. Uses **CDN-linked highlight.js** — the Playwright browser renders the page fully including external CSS/JS, so CDN assets load correctly during screenshot.

**Variables:** `{{FILENAME}}`, `{{LANGUAGE}}`, `{{LANGUAGE_COLOR}}`, `{{CODE_LINES}}` (pre-HTML-escaped by skill), `{{LINE_RANGE}}`, `{{REPO_SLUG}}`, `{{GITHUB_URL}}`

**Layout:**
- Header (`#161b22`, padding 16px 24px): `{{FILENAME}}` in monospace left + `{{LANGUAGE}}` badge (`{{LANGUAGE_COLOR}}` bg) right
- Code block (`#0d1117`, padding 20px 24px): highlight.js loaded from CDN with `github-dark` theme; `<pre><code class="language-{{LANGUAGE}}">{{CODE_LINES}}</code></pre>`; font-size 13px, overflow-x auto, max-height 400px
- Footer (`#161b22`, border-top): `{{REPO_SLUG}}` left (12px muted), `{{LINE_RANGE}}` center + `{{GITHUB_URL}}` right (12px accent)

**CDN references in `<head>`:**
```html
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script>hljs.highlightAll();</script>
```

---

## Files to Update

### `kit/plugins/social-media-tools/.claude-plugin/plugin.json`
- Update `description`: "Draft platform-aware social media copy and generate dark-mode cards for code changes, GitHub code snippets, blog posts, and videos — for LinkedIn, Twitter/X, and Bluesky"
- Add `keywords`: `"blog"`, `"video"`, `"youtube"`, `"github"`, `"code-snippet"`

### `/.claude-plugin/marketplace.json`
- Bump `code-share` version: `"0.2.0"` → `"0.3.0"` (MINOR: 3 new skills added)
- Update description: include blog/video/GitHub snippet
- Add tags: `"blog"`, `"video"`, `"youtube"`, `"github-snippet"`

### `kit/plugins/social-media-tools/skills/code-share/references/variables.md`
- Append variable tables for `blog-card.html`, `video-card.html`, and `snippet-card.html` to keep all template variable contracts in one canonical location.

### `kit/plugins/social-media-tools/CHANGELOG.md`
Prepend v0.3.0 entry:
```
## [0.3.0] — 2026-05-26
### Added
- `blog-share` skill: social posts from blog URLs or local markdown (WebFetch OG metadata); READ_TIME only computed for local files
- `video-share` skill: social posts from YouTube/Vimeo URLs (oEmbed API) with 4xx fallback to manual input
- `github-code-share` skill: social posts for specific GitHub file/snippet URLs (raw fetch + security-scrub + snippet-card); public repos only; HTML-escapes code before card substitution; URL fragment parsed before WebFetch
- `blog-card.html` template: headline + excerpt + author/date + tag chips
- `video-card.html` template: thumbnail + play overlay + channel + platform badge (thumbnail zone hidden when unavailable)
- `snippet-card.html` template: syntax-highlighted code card via CDN highlight.js (github-dark theme)
```

### `kit/plugins/social-media-tools/README.md`
- Add 3 new skills to components table
- Add `blog-card`, `video-card`, `snippet-card` to Card Types table
- Expand Plugin Structure tree
- Add usage examples for each new skill

---

## Files Unchanged

| File | Reason |
|------|--------|
| `skills/code-share/SKILL.md` | Unchanged — still handles local git commits/diffs |
| `skills/scan-for-shares/SKILL.md` | Unchanged — git history scanning, code-only |
| `skills/security-scrub/SKILL.md` | Reused by `github-code-share` via Skill call |
| `templates/diff-card.html` | Unchanged — diff use case stays separate |
| `templates/feature-card.html` | Unchanged |
| `templates/quote-card.html` | Unchanged |
| `commands/digest.md` | Unchanged |
| `commands/digest-bg.md` | Unchanged |
| `agents/agent-digest.md` | Unchanged |
| `scripts/find_free_port.py` | Reused by all 3 new skills |

---

## Tool Summary Per New Skill

| Tool | blog-share | video-share | github-code-share |
|------|-----------|-------------|-------------------|
| `WebFetch` | OG metadata | oEmbed API | Raw GitHub file |
| `Read` | Local .md files | — | — |
| `Write` | HTML card | HTML card | Scrub temp file + HTML card |
| `Bash` | Screenshot pipeline | Screenshot pipeline | Screenshot pipeline |
| `Skill` | — | — | Call security-scrub |
| `AskUserQuestion` | Platform + tone | Platform + angle | Platform + angle |
| `ToolSearch` | Load WebFetch | Load WebFetch | Load WebFetch |
| `SendUserFile` | PNG card | PNG card | PNG card |

---

## Stress-Test Fixes Applied

| # | Fix |
|---|-----|
| 1 | Phase 5 of `github-code-share` explicitly HTML-escapes `&`, `<`, `>`, `"` before `{{CODE_LINES}}` substitution |
| 2 | Phase 1 of `github-code-share` parses `#L10-L25` fragment from URL string before any WebFetch call |
| 3 | Phase 3 of `github-code-share` writes snippet to `~/.claude/tmp/scrub-input.txt` before calling security-scrub; `Write` added to allowed-tools |
| 4 | `snippet-card.html` uses CDN highlight.js with `github-dark` theme — Playwright fetches CDN assets during screenshot |
| 5 | Phase 1 of `github-code-share` explicitly states public-repos-only; Phase 2 stops on 4xx with a clear error message |
| 6 | Phase 2 of `video-share` handles oEmbed 4xx by falling back to `AskUserQuestion` for manual title/channel input |
| 7 | `READ_TIME` omitted for URL sources in `blog-share`; only computed for local `.md` files |
| 8 | `skills/code-share/references/variables.md` added to Files to Update |

---

## Verification

1. **Skill activation** — Trigger with natural language:
   - "Share this blog post: [URL]" → `blog-share` activates
   - "Write a tweet about this YouTube video: [URL]" → `video-share` activates
   - "Post about this GitHub file: https://github.com/owner/repo/blob/main/src/auth.ts#L10-L25" → `github-code-share` activates

2. **WebFetch pipeline** — Confirm `blog-share` extracts OG title + description from a real URL; confirm `video-share` hits YouTube oEmbed and gets `title` + `author_name`

3. **Security scrub integration** — Confirm `github-code-share` writes to temp file, calls `security-scrub`, and blocks on HIGH findings

4. **HTML escaping** — Test with a TypeScript file containing `Array<string>` and `a > b` — card must render correctly without broken HTML

5. **URL fragment parsing** — Test with `https://github.com/.../file.ts#L10-L25` — skill must extract lines 10–25 only

6. **oEmbed fallback** — Test `video-share` with a private or deleted YouTube URL — skill must ask for manual input rather than failing silently

7. **Card rendering** — Open each new HTML template in a browser; verify highlight.js CDN loads and colors code; verify thumbnail zone hides correctly when `{{THUMBNAIL_URL}}` is empty

8. **Screenshot pipeline end-to-end** — One full run per new skill: populate → serve → Playwright screenshot → PNG delivered

9. **Existing skills unaffected** — Run `code-share` on a local git diff; confirm behavior unchanged

10. **Marketplace validation** — Run `/validate-plugin code-share` after changes; confirm no JSON errors in `marketplace.json`

---

## Implementation Order

1. `templates/blog-card.html`
2. `templates/video-card.html`
3. `templates/snippet-card.html` (with CDN highlight.js)
4. `skills/blog-share/references/platforms.md`
5. `skills/video-share/references/platforms.md`
6. `skills/github-code-share/references/language-map.md`
7. `skills/blog-share/SKILL.md`
8. `skills/video-share/SKILL.md`
9. `skills/github-code-share/SKILL.md`
10. `skills/code-share/references/variables.md` (append new card variable tables)
11. `kit/plugins/social-media-tools/.claude-plugin/plugin.json`
12. `/.claude-plugin/marketplace.json`
13. `CHANGELOG.md`
14. `README.md`
