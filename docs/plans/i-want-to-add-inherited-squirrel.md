# Plan: Extend code-share Plugin for Blog, Video, and GitHub Code Snippet Social Posts

## Context

The existing `code-share` plugin (`kit/plugins/social-media-tools/`) generates LinkedIn/Twitter/Bluesky posts for **local code commits and diffs**. The user wants to extend this capability to cover three additional content types:

- **Blog posts** — given a URL or local markdown file, generate platform copy + styled card
- **Videos** — given a YouTube or Vimeo URL, generate platform copy + video preview card
- **GitHub code file/snippet** — given a GitHub file URL (optionally with a line range), fetch the raw code, security-scrub it, and generate a copy + syntax-highlighted card

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
- **URL source:** `WebFetch` the URL → extract: `og:title`, `og:description`, `article:author`, `article:published_time`, `article:tag` (up to 5), hostname as `SOURCE_DOMAIN` (strip `www.`).
- **Local file:** `Read` → extract YAML front matter (`title`, `author`, `date`, `tags`, `description`) and first non-heading paragraph as excerpt.
- Estimate `READ_TIME` from word count / 200 wpm.

**Phase 3 — Draft Copy**
- LinkedIn (1,500 char): hook line → 3 numbered key takeaways → personal commentary → CTA with link → 3–4 hashtags
- Twitter/X (280 char): hook sentence naming the key insight + URL + 1–2 hashtags
- Bluesky (300 char): "Just read [TITLE] by [AUTHOR] — [one key observation]. Worth your time if you [relevant condition]."
- Present draft in fenced block; wait for approval.

**Phase 4 — Populate Template**
- Locate `TEMPLATES_DIR` using the same three-path probe as code-share. `TEMPLATE_FILE=$TEMPLATES_DIR/blog-card.html`.
- Substitute: `{{TITLE}}`, `{{EXCERPT}}`, `{{AUTHOR}}`, `{{DATE}}`, `{{SOURCE_DOMAIN}}`, `{{TAGS}}` (as `<span class="tag">` chips; omit `.card-footer` entirely if no tags).
- Write to `~/.claude/tmp/blog-share-card.html`.

**Phase 5 — Screenshot**
- Identical to code-share Phase 5: `find_free_port.py` → `http.server $PORT` → Playwright navigate/screenshot → kill server.
- Output: `~/.claude/tmp/blog-share-card.png`

**Phase 6 — Deliver**
- Platform label heading + fenced copy + char count + `SendUserFile` PNG + HTML path.

**Note on deferred tool:** `WebFetch` requires both `WebFetch` AND `ToolSearch` in `allowed-tools`. Document the two-step bootstrap in Phase 2.

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
- **YouTube:** `WebFetch` on `https://www.youtube.com/oembed?url=VIDEO_URL&format=json` → extract `title`, `author_name`, `thumbnail_url`. Second `WebFetch` on the video URL itself → extract `og:description`.
- **Vimeo:** `WebFetch` on `https://vimeo.com/api/oembed.json?url=VIDEO_URL` → extract `title`, `author_name`, `thumbnail_url`, `description`.
- Set `PLATFORM_COLOR`: `#ff0000` (YouTube) or `#1ab7ea` (Vimeo). Set `CTA`: "▶ Watch on YouTube/Vimeo".

**Phase 3 — Draft Copy**
- LinkedIn (1,500 char): why-watch narrative + key insight from description + "Watch ▶ [URL]" CTA + 2–3 hashtags
- Twitter/X (280 char): punchy hook + "Watch ▶ [URL]"
- Bluesky (300 char): quick take + link

**Phase 4 — Populate Template**
- `TEMPLATE_FILE=$TEMPLATES_DIR/video-card.html`.
- Substitute: `{{VIDEO_TITLE}}`, `{{CHANNEL}}`, `{{PLATFORM_BADGE}}`, `{{PLATFORM_COLOR}}`, `{{DESCRIPTION_SNIPPET}}` (first 150 chars of description), `{{THUMBNAIL_URL}}`, `{{CTA}}`.
- Write to `~/.claude/tmp/video-share-card.html`.

**Phases 5 & 6** — same as blog-share, output: `video-share-card.{html,png}`.

---

### 4. `kit/plugins/social-media-tools/skills/video-share/references/platforms.md`

Platform formatting rules + oEmbed endpoint reference table:

| Platform | oEmbed endpoint |
|----------|----------------|
| YouTube | `https://www.youtube.com/oembed?url={URL}&format=json` |
| Vimeo | `https://vimeo.com/api/oembed.json?url={URL}` |

---

### 5. `kit/plugins/social-media-tools/skills/github-code-share/SKILL.md`

**Frontmatter:**
```yaml
name: github-code-share
description: "Fetches a code file or snippet from a GitHub URL and generates a social post with a syntax-highlighted card. Use when the user asks to share a specific file, function, or code snippet from a GitHub repository."
allowed-tools: AskUserQuestion, Write, Bash, ToolSearch, WebFetch, Skill, SendUserFile
```

Note: `Skill` is needed to call `security-scrub` on the fetched code before sharing.

**Workflow (6 phases):**

**Phase 1 — Parse GitHub URL**
- Accept a GitHub blob URL: `https://github.com/{owner}/{repo}/blob/{branch}/{path}` optionally with `#L10-L25` or `#L10` fragment for line ranges.
- Parse: `OWNER`, `REPO`, `BRANCH`, `FILE_PATH`, optional `LINE_START`/`LINE_END`.
- Derive `FILENAME` = basename of `FILE_PATH` (e.g., `auth.ts`).
- Derive `LANGUAGE` from file extension (`.ts` → TypeScript, `.py` → Python, `.go` → Go, etc.).
- Ask for `PLATFORM` and optional `HOOK_ANGLE` via `AskUserQuestion`.

**Phase 2 — Fetch Raw Code**
- `ToolSearch` with `select:WebFetch` first (silent bootstrap).
- Convert blob URL to raw URL: `https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}/{FILE_PATH}`.
- `WebFetch` the raw URL to get file content.
- If `LINE_START`/`LINE_END` are set: extract only those lines from the content.
- If no line range: cap at the first 80 lines to keep card readable; notify the user.

**Phase 3 — Security Scrub**
- Call `Skill(skill: "code-share:security-scrub")` on the extracted code snippet.
- If result is `BLOCKED`: stop and tell the user what was found (masked). Do NOT proceed.
- If result is `WARN`: surface the warning and ask the user to confirm before continuing.
- If result is `PASS`: continue silently.

**Phase 4 — Draft Copy**
- LinkedIn (1,500 char): context framing ("Here's [LANGUAGE] code from [OWNER/REPO] that...") + what the code does + key design decision or insight + CTA linking to file + hashtags
- Twitter/X (280 char): "[LANGUAGE] snippet worth seeing → [what it does in one phrase] — [GitHub URL]"
- Bluesky (300 char): similar brevity to Twitter

**Phase 5 — Populate Template**
- `TEMPLATE_FILE=$TEMPLATES_DIR/snippet-card.html` (new template).
- Substitute: `{{FILENAME}}`, `{{LANGUAGE}}`, `{{CODE_LINES}}` (HTML-escaped code as `<pre><code>` content), `{{LINE_RANGE}}` (e.g., "L10–L25" or "full file"), `{{REPO_SLUG}}` (e.g., "owner/repo"), `{{GITHUB_URL}}`.
- Write to `~/.claude/tmp/github-code-share-card.html`.
- Run screenshot pipeline → `~/.claude/tmp/github-code-share-card.png`.

**Phase 6 — Deliver** — same pattern as other skills.

---

### 6. `kit/plugins/social-media-tools/skills/github-code-share/references/language-map.md`

File extension → display name + badge color map for 20+ common languages. Used in Phase 1 to set `LANGUAGE` and in Phase 5 for the card's language badge color.

---

### 7. `kit/plugins/social-media-tools/templates/blog-card.html`

Dark-mode card, same GitHub color scheme (`#0d1117` bg, `#161b22` surface, `#388bfd` accent).

**Variables:** `{{TITLE}}`, `{{EXCERPT}}`, `{{AUTHOR}}`, `{{DATE}}`, `{{SOURCE_DOMAIN}}`, `{{TAGS}}`

**Layout:**
- Header (`#0d1117`): "Blog Post" label left + `{{SOURCE_DOMAIN}}` pill right, read-time badge
- Body (`#161b22`, padding 28px 32px): large `{{TITLE}}` h1 (24px, 700), `{{EXCERPT}}` paragraph (14px, muted, max 3 lines)
- Meta row (border-top): `{{AUTHOR}}` left · `{{DATE}}` right, both 12px muted
- Footer (`#0d1117`): `{{TAGS}}` as chips (bg: `rgba(56,139,253,0.12)`, color `#79c0ff`, border-radius 20px)

---

### 8. `kit/plugins/social-media-tools/templates/video-card.html`

Dark-mode video preview card.

**Variables:** `{{VIDEO_TITLE}}`, `{{CHANNEL}}`, `{{PLATFORM_BADGE}}`, `{{PLATFORM_COLOR}}`, `{{DESCRIPTION_SNIPPET}}`, `{{THUMBNAIL_URL}}`, `{{CTA}}`

**Layout:**
- Thumbnail zone (height 180px): `<img src="{{THUMBNAIL_URL}}">` object-fit cover + centered ▶ play-button overlay (pure CSS, no external assets)
- Body (padding 20px 24px): platform badge (bg: `{{PLATFORM_COLOR}}` at 20% opacity, border `{{PLATFORM_COLOR}}`), `{{CHANNEL}}` muted, `{{VIDEO_TITLE}}` h2 (18px 700), `{{DESCRIPTION_SNIPPET}}` (13px muted, 2-line clamp)
- Footer: `{{CTA}}` button (bg `{{PLATFORM_COLOR}}`, white text, 12px 20px padding, border-radius 6px)

---

### 9. `kit/plugins/social-media-tools/templates/snippet-card.html`

Dark-mode syntax-aware code snippet card (distinct from `diff-card.html` which is for before/after diffs).

**Variables:** `{{FILENAME}}`, `{{LANGUAGE}}`, `{{LANGUAGE_COLOR}}`, `{{CODE_LINES}}`, `{{LINE_RANGE}}`, `{{REPO_SLUG}}`, `{{GITHUB_URL}}`

**Layout:**
- Header (`#161b22`, padding 16px 24px): `{{FILENAME}}` in monospace left + `{{LANGUAGE}}` badge (`{{LANGUAGE_COLOR}}`) right
- Code block (`#0d1117`, padding 20px 24px): `<pre><code class="language-{{LANGUAGE}}">{{CODE_LINES}}</code></pre>` in Consolas/monospace, font-size 13px, `#e6edf3` text, `#161b22` bg, overflow-x auto
- Footer (`#161b22`, border-top): `{{REPO_SLUG}}` left (12px muted), `{{LINE_RANGE}}` + `{{GITHUB_URL}}` right (12px accent, truncated)

Note: No external syntax-highlighting library — the code is rendered with the correct CSS color tokens. The card's purpose is visual appeal, not pixel-perfect syntax coloring.

---

## Files to Update

### `.claude-plugin/plugin.json`
- Update `description`: "Draft platform-aware social media copy and generate dark-mode cards for code changes, GitHub code snippets, blog posts, and videos — for LinkedIn, Twitter/X, and Bluesky"
- Add `keywords`: `"blog"`, `"video"`, `"youtube"`, `"github"`, `"code-snippet"`

### `/.claude-plugin/marketplace.json`
- Bump `code-share` version: `"0.2.0"` → `"0.3.0"` (MINOR: 3 new skills added)
- Update description: include blog/video/GitHub snippet
- Add tags: `"blog"`, `"video"`, `"youtube"`, `"github-snippet"`

### `CHANGELOG.md`
Prepend v0.3.0 entry:
```
## [0.3.0] — 2026-05-26
### Added
- `blog-share` skill: social posts from blog URLs or local markdown (WebFetch OG metadata)
- `video-share` skill: social posts from YouTube/Vimeo URLs (oEmbed API)
- `github-code-share` skill: social posts for specific GitHub file/snippet URLs (raw fetch + security-scrub + snippet-card)
- `blog-card.html` template: headline + excerpt + author/date + tag chips
- `video-card.html` template: thumbnail + play overlay + channel + platform badge
- `snippet-card.html` template: syntax-highlighted code snippet card
```

### `README.md`
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
| `Bash` | Screenshot pipeline | Screenshot pipeline | Screenshot pipeline |
| `Skill` | — | — | Call security-scrub |
| `AskUserQuestion` | Platform + tone | Platform + angle | Platform + angle |
| `Write` | HTML card | HTML card | HTML card |
| `ToolSearch` | Load WebFetch | Load WebFetch | Load WebFetch |
| `SendUserFile` | PNG card | PNG card | PNG card |

---

## Verification

1. **Skill activation** — Trigger with natural language:
   - "Share this blog post: [URL]" → `blog-share` activates
   - "Write a tweet about this YouTube video: [URL]" → `video-share` activates
   - "Post about this GitHub file: https://github.com/owner/repo/blob/main/src/auth.ts#L10-L25" → `github-code-share` activates

2. **WebFetch pipeline** — Confirm `blog-share` extracts OG title + description from a real URL; confirm `video-share` hits YouTube oEmbed and gets `title` + `author_name`

3. **Security scrub integration** — Confirm `github-code-share` calls `security-scrub` and blocks on HIGH findings

4. **Card rendering** — Open each new HTML template in a browser to verify layout; verify all `{{VARIABLES}}` are substituted correctly

5. **Screenshot pipeline end-to-end** — One full run per new skill: populate → serve → Playwright screenshot → PNG delivered

6. **Existing skills unaffected** — Run `code-share` on a local git diff; confirm behavior unchanged

7. **Marketplace validation** — Run `/validate-plugin code-share` after changes; confirm no JSON errors in `marketplace.json`

---

## Implementation Order

1. `templates/blog-card.html`
2. `templates/video-card.html`
3. `templates/snippet-card.html`
4. `skills/blog-share/references/platforms.md`
5. `skills/video-share/references/platforms.md`
6. `skills/github-code-share/references/language-map.md`
7. `skills/blog-share/SKILL.md`
8. `skills/video-share/SKILL.md`
9. `skills/github-code-share/SKILL.md`
10. `.claude-plugin/plugin.json`
11. `/.claude-plugin/marketplace.json`
12. `CHANGELOG.md`
13. `README.md`
