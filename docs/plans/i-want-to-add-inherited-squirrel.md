# Plan: Extend code-share Plugin for Blog, Video, and GitHub Code Snippet Social Posts

## Context

The existing `code-share` plugin (`kit/plugins/social-media-tools/`) generates LinkedIn/Twitter/Bluesky posts for **local code commits and diffs**. The user wants to extend this capability to cover three additional content types:

- **Blog posts** — given a URL or local markdown file, generate platform copy + styled card
- **Videos** — given a YouTube or Vimeo URL, generate platform copy + video preview card
- **GitHub code file/snippet** — given a GitHub file URL (optionally with a line range `#L10-L25`), fetch the raw code, security-scrub it, and generate a copy + syntax-highlighted card

Platforms remain LinkedIn, Twitter/X, and Bluesky (matching existing code-share scope). Blog and video content does not pass through `security-scrub` — these skills share URLs and metadata (title, excerpt, channel name), not raw executable code that could contain secrets.

These fit naturally in the existing plugin (`social-media-tools/`) which already has the screenshot pipeline, card template system, and platform-aware copy workflow.

**Scope note:** This release adds reactive sharing (user supplies the URL). Discovery for blog/video content (equivalent to `scan-for-shares` for code) is intentional v0.4.0 scope.

---

## New Files

### 1. `kit/plugins/social-media-tools/skills/blog-share/SKILL.md`

**Frontmatter:**
```yaml
name: blog-share
description: "Creates social media copy and a dark-mode card for a blog post or article. Use when asked to share or post a blog post on LinkedIn, Twitter, or Bluesky."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, WebFetch, SendUserFile
```

Description: 152 chars ✓

**Workflow (6 phases, mirrors code-share):**

**Phase 1 — Collect Input**
- Detect URL vs. local file path. If URL: starts with `http://` or `https://`. If local: `.md`, `.mdx`, or `.markdown` extension.
- If the user provides a relative path, resolve it to absolute before calling `Read`:
  ```bash
  realpath "$USER_PATH" 2>/dev/null || echo "$PWD/$USER_PATH"
  ```
- Batch `AskUserQuestion` for: `SOURCE` (if not provided), `PLATFORM` (LinkedIn/Twitter/X/Bluesky), `TONE` (Professional/Casual/Punchy), optional `HOOK_ANGLE`.

**Phase 2 — Fetch Metadata**
- `WebFetch` is a deferred tool. Use `ToolSearch` with `select:WebFetch` first (silent, no user output), then call `WebFetch`.
- **URL source:** `WebFetch` the URL → extract: `og:title`, `og:description`, `article:author`, `article:published_time`, `article:tag` (up to 5), hostname as `SOURCE_DOMAIN` (strip `www.`). Set `READ_TIME = ""` (do not compute for URL sources — requires complex HTML body parsing).
- **Local file:** `Read` the resolved absolute path → extract YAML front matter (`title`, `author`, `date`, `tags`, `description`) and first non-heading paragraph as excerpt. Compute `READ_TIME` = word count / 200 wpm, round to nearest minute.
- HTML-escape all extracted text values (`&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`) before use in template substitution.

**Phase 3 — Draft Copy**
- Read platform rules from `references/platforms.md`.
- LinkedIn (1,500 char): hook line → 3 numbered key takeaways → personal commentary → CTA with link → 3–4 hashtags
- Twitter/X (280 char): hook sentence naming the key insight + URL + 1–2 hashtags
- Bluesky (300 char): "Just read [TITLE] by [AUTHOR] — [one key observation]. Worth your time if you [relevant condition]."
- Present draft in fenced block; wait for approval.

**Phase 4 — Populate Template**
- Locate `TEMPLATES_DIR` using the same three-path probe as code-share. `TEMPLATE_FILE=$TEMPLATES_DIR/blog-card.html`.
- **Conditional element substitution (Option A):** the skill generates full HTML elements or empty strings — the template is purely static:
  - `{{READ_TIME_BADGE}}` = `'<span class="read-time">N min read</span>'` if non-empty, else `""`
  - `{{TAGS_FOOTER}}` = full `<div class="card-footer">` block with tag chips if tags exist, else `""`
  - Each tag value HTML-escaped before wrapping: `<span class="tag">{escaped_tag}</span>`
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
description: "Creates social media copy and a card for a YouTube or Vimeo video. Use when asked to share a video or promote a talk on LinkedIn, Twitter, or Bluesky."
allowed-tools: AskUserQuestion, Write, Bash, ToolSearch, WebFetch, SendUserFile
```

Description: 151 chars ✓

**Workflow (6 phases):**

**Phase 1 — Collect Input**
- Auto-detect platform from URL: `youtube.com`/`youtu.be` → YouTube; `vimeo.com` → Vimeo.
- Batch `AskUserQuestion` for: `VIDEO_URL` (if not provided), `PLATFORM`, optional `HOOK_ANGLE`.

**Phase 2 — Fetch Metadata**
- `WebFetch` is a deferred tool. Use `ToolSearch` with `select:WebFetch` first (silent bootstrap), then call `WebFetch`.
- **YouTube:** `WebFetch` on `https://www.youtube.com/oembed?url=VIDEO_URL&format=json` → extract `title`, `author_name`, `thumbnail_url`. If response is 4xx (private/deleted/age-restricted): skip thumbnail, ask user for `title` and `channel` via `AskUserQuestion` and continue. Second `WebFetch` on the original video URL → extract `og:description`.
- **Vimeo:** `WebFetch` on `https://vimeo.com/api/oembed.json?url=VIDEO_URL` → extract `title`, `author_name`, `thumbnail_url`, `description`. If response is 4xx: ask user for `title` and `channel`.
- Set `PLATFORM_COLOR` from hardcoded map only (never from fetched content or user input): `#ff0000` (YouTube), `#1ab7ea` (Vimeo). Set `CTA`: "▶ Watch on YouTube" or "▶ Watch on Vimeo".

**Phase 3 — Draft Copy**
- Read platform rules from `references/platforms.md` (includes oEmbed endpoint table).
- LinkedIn (1,500 char): why-watch narrative + key insight from description + "Watch ▶ [URL]" CTA + 2–3 hashtags
- Twitter/X (280 char): punchy hook + "Watch ▶ [URL]"
- Bluesky (300 char): quick take + link

**Phase 4 — Populate Template**
- `TEMPLATE_FILE=$TEMPLATES_DIR/video-card.html`.
- **Conditional element substitution (Option A):**
  - `{{THUMBNAIL_ZONE}}` = full `<div class="video-thumbnail">` block if `thumbnail_url` is non-empty, else `""`
- Substitute: `{{VIDEO_TITLE}}`, `{{CHANNEL}}`, `{{PLATFORM_BADGE}}`, `{{PLATFORM_COLOR}}`, `{{DESCRIPTION_SNIPPET}}` (first 150 chars), `{{THUMBNAIL_ZONE}}`, `{{CTA}}`.
- Write to `~/.claude/tmp/video-share-card.html`.

**Phases 5 & 6** — same as blog-share, output: `video-share-card.{html,png}`.

---

### 4. `kit/plugins/social-media-tools/skills/video-share/references/platforms.md`

Platform formatting rules + oEmbed endpoint reference table:

| Platform | oEmbed endpoint | Notes |
|----------|----------------|-------|
| YouTube | `https://www.youtube.com/oembed?url={URL}&format=json` | No `description` field — requires second WebFetch on video page for `og:description` |
| Vimeo | `https://vimeo.com/api/oembed.json?url={URL}` | Includes `description` field directly |

---

### 5. `kit/plugins/social-media-tools/skills/github-code-share/SKILL.md`

**Frontmatter:**
```yaml
name: github-code-share
description: "Fetches a GitHub file and generates social media copy with a syntax-highlighted card. Use when asked to share a code snippet or file from a GitHub repository."
allowed-tools: AskUserQuestion, Write, Bash, ToolSearch, WebFetch, Skill, SendUserFile
```

Description: 158 chars ✓. `Write` covers both the security-scrub temp file (Phase 3) and the HTML card (Phase 5). `Skill` invokes `security-scrub`.

**This skill supports public repositories only.** A 4xx response in Phase 2 means the repo is private or the file doesn't exist — stop with a clear error message.

**Workflow (6 phases):**

**Phase 1 — Parse GitHub URL**

Accept these URL forms:
- `https://github.com/{owner}/{repo}/blob/{branch}/{path}` — standard GitHub file view
- `https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` — raw URL (skip conversion in Phase 2)

**Parse the URL fragment first, before any WebFetch call.** URL fragments (`#L10-L25`) are never sent to the server — they must be extracted from the URL string:
1. If the URL contains `#L`, split on `#` and parse the line range:
   - `#L10` → `LINE_START=10`, `LINE_END=10`
   - `#L10-L25` → `LINE_START=10`, `LINE_END=25`
2. Store `LINE_START`/`LINE_END`, then strip the `#...` fragment from the URL before any further use.

Extract: `OWNER`, `REPO`, `BRANCH`, `FILE_PATH` from URL path segments.
Derive `FILENAME` = basename of `FILE_PATH` (e.g., `auth.ts`).
Derive `LANGUAGE` and `LANGUAGE_COLOR` from file extension using `references/language-map.md`.

Ask for `PLATFORM` and optional `HOOK_ANGLE` via `AskUserQuestion`.

**Phase 2 — Fetch Raw Code**
- `WebFetch` is a deferred tool. Use `ToolSearch` with `select:WebFetch` first (silent bootstrap), then call `WebFetch`.
- If input was a `github.com/blob/` URL: convert to `https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}/{FILE_PATH}`.
- If input was already a `raw.githubusercontent.com` URL: use as-is.
- `WebFetch` the raw URL. If 4xx response: output "This repository may be private or the file path is incorrect — this skill only supports public repositories." and **STOP**.
- If `LINE_START`/`LINE_END` are set: extract lines `LINE_START` through `LINE_END` (1-indexed).
- If no line range: cap at first 80 lines; tell the user "Showing lines 1–80. Use `#L10-L25` to share a specific range."

**Phase 3 — Security Scrub**

Write the extracted snippet to a temp file (required — `security-scrub` uses `Grep` which operates on files, not inline text):

```bash
mkdir -p ~/.claude/tmp
# Write snippet to temp file via Write tool
```

Use `Write` to write snippet content to `~/.claude/tmp/scrub-input.txt`.

Then invoke:
```
Skill(skill: "code-share:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Parse the returned `SCRUB RESULT` block:
- `SCRUB RESULT: BLOCKED` or `ALLOWLIST verdict: BLOCKED` → report masked findings to user and **STOP**
- `SCRUB RESULT: WARN` → surface the warning, ask user to confirm before continuing
- `SCRUB RESULT: PASS` → continue silently

**Phase 4 — Draft Copy**
- LinkedIn (1,500 char): context framing ("Here's [LANGUAGE] code from [OWNER/REPO] that...") + what the code does + key design decision or insight + CTA linking to file + hashtags
- Twitter/X (280 char): "[LANGUAGE] snippet worth seeing → [what it does in one phrase] — [GitHub URL]"
- Bluesky (300 char): similar brevity

**Phase 5 — Populate Template**
- `TEMPLATE_FILE=$TEMPLATES_DIR/snippet-card.html`.
- **HTML-escape all code content before substitution** — mandatory, unescaped code breaks card rendering:
  - `&` → `&amp;` (must be first)
  - `<` → `&lt;`
  - `>` → `&gt;`
  - `"` → `&quot;`
- Substitute: `{{FILENAME}}`, `{{LANGUAGE}}`, `{{LANGUAGE_COLOR}}`, `{{CODE_LINES}}` (HTML-escaped), `{{LINE_RANGE}}` (e.g., "L10–L25" or "lines 1–80"), `{{REPO_SLUG}}` (e.g., "owner/repo"), `{{GITHUB_URL}}` (original URL, fragment stripped).
- Write to `~/.claude/tmp/github-code-share-card.html`.
- Run screenshot pipeline → `~/.claude/tmp/github-code-share-card.png`.

**Phase 6 — Deliver** — same pattern as other skills.

---

### 6. `kit/plugins/social-media-tools/skills/github-code-share/references/language-map.md`

File extension → display name + badge color for 20+ languages. Used in Phase 1.

| Extension | Language | Color |
|-----------|----------|-------|
| `.ts`, `.tsx` | TypeScript | `#3178c6` |
| `.js`, `.jsx`, `.mjs` | JavaScript | `#f1e05a` |
| `.py` | Python | `#3572A5` |
| `.go` | Go | `#00ADD8` |
| `.rs` | Rust | `#dea584` |
| `.rb` | Ruby | `#701516` |
| `.java` | Java | `#b07219` |
| `.cs` | C# | `#178600` |
| `.cpp`, `.cc`, `.cxx` | C++ | `#f34b7d` |
| `.c` | C | `#555555` |
| `.swift` | Swift | `#F05138` |
| `.kt` | Kotlin | `#A97BFF` |
| `.sh`, `.bash` | Shell | `#89e051` |
| `.md`, `.mdx` | Markdown | `#083fa1` |
| `.json` | JSON | `#292929` |
| `.yaml`, `.yml` | YAML | `#cb171e` |
| *(unknown)* | Code | `#8b949e` |

---

### 7. `kit/plugins/social-media-tools/templates/blog-card.html`

Dark-mode card, same GitHub color scheme (`#0d1117` bg, `#161b22` surface, `#388bfd` accent).

**Static variables (always substituted):** `{{TITLE}}`, `{{EXCERPT}}`, `{{AUTHOR}}`, `{{DATE}}`, `{{SOURCE_DOMAIN}}`

**Conditional element variables (skill injects full element or `""`):** `{{READ_TIME_BADGE}}`, `{{TAGS_FOOTER}}`

**Layout:**
- Header (`#0d1117`): "Blog Post" label left + `{{SOURCE_DOMAIN}}` pill right + `{{READ_TIME_BADGE}}` (absent if empty)
- Body (`#161b22`, padding 28px 32px): `{{TITLE}}` h1 (24px, 700), `{{EXCERPT}}` paragraph (14px, muted, 3-line clamp, green left-border accent matching existing cards)
- Meta row (border-top): `{{AUTHOR}}` left · `{{DATE}}` right, 12px muted
- `{{TAGS_FOOTER}}` — entire `<div class="card-footer">` block, or nothing

---

### 8. `kit/plugins/social-media-tools/templates/video-card.html`

Dark-mode video preview card.

**Static variables:** `{{VIDEO_TITLE}}`, `{{CHANNEL}}`, `{{PLATFORM_BADGE}}`, `{{PLATFORM_COLOR}}`, `{{DESCRIPTION_SNIPPET}}`, `{{CTA}}`

**Conditional element variable:** `{{THUMBNAIL_ZONE}}` — full `<div class="video-thumbnail">` with `<img>` + ▶ overlay, or `""` when no thumbnail

**Layout:**
- `{{THUMBNAIL_ZONE}}` — when present: `<img src="URL">` object-fit cover (height 180px) + centered ▶ overlay (pure CSS/Unicode, no external assets)
- Body (padding 20px 24px): platform badge (bg `{{PLATFORM_COLOR}}` 20% opacity, border `{{PLATFORM_COLOR}}`), `{{CHANNEL}}` muted, `{{VIDEO_TITLE}}` h2 (18px 700), `{{DESCRIPTION_SNIPPET}}` (13px muted, 2-line clamp)
- Footer: `{{CTA}}` button (bg `{{PLATFORM_COLOR}}`, white, border-radius 6px)

---

### 9. `kit/plugins/social-media-tools/templates/snippet-card.html`

Dark-mode code card with syntax highlighting via **inline highlight.js** (no CDN dependency — minified bundle embedded in `<script>` tag so the card works offline).

**Static variables:** `{{FILENAME}}`, `{{LANGUAGE}}`, `{{LANGUAGE_COLOR}}`, `{{CODE_LINES}}` (pre-HTML-escaped by skill), `{{LINE_RANGE}}`, `{{REPO_SLUG}}`, `{{GITHUB_URL}}`

**Layout:**
- Header (`#161b22`, padding 16px 24px): `{{FILENAME}}` monospace left + `{{LANGUAGE}}` badge (`{{LANGUAGE_COLOR}}` bg) right
- Code block (`#0d1117`, padding 20px 24px): `<pre><code class="language-{{LANGUAGE}}">{{CODE_LINES}}</code></pre>`; highlight.js initialised inline; `github-dark` theme CSS also inlined; font-size 13px, overflow-x auto, max-height 400px
- Footer (`#161b22`, border-top): `{{REPO_SLUG}}` left (12px muted), `{{LINE_RANGE}}` centre + `{{GITHUB_URL}}` right (12px accent)

The common-languages highlight.js bundle (~45 KB minified) is inlined so no network call is needed during Playwright screenshot.

---

## Files to Update

### `kit/plugins/social-media-tools/.claude-plugin/plugin.json`
- Update `description`: "Draft platform-aware social media copy and generate dark-mode cards for code changes, GitHub code snippets, blog posts, and videos — for LinkedIn, Twitter/X, and Bluesky"
- Add `keywords`: `"blog"`, `"video"`, `"youtube"`, `"github"`, `"code-snippet"`

### `/.claude-plugin/marketplace.json`
- Bump `code-share` version: `"0.2.0"` → `"0.3.0"` (MINOR: 3 new skills added, no breaking changes)
- Update description: include blog/video/GitHub snippet
- Add tags: `"blog"`, `"video"`, `"youtube"`, `"github-snippet"`

### `kit/plugins/social-media-tools/skills/code-share/references/variables.md`
- Append variable tables for `blog-card.html`, `video-card.html`, and `snippet-card.html` to keep all template variable contracts in one canonical location.

### `kit/plugins/social-media-tools/CHANGELOG.md`
Prepend v0.3.0 entry:
```
## [0.3.0] — 2026-05-27
### Added
- `blog-share` skill: social posts from blog URLs or local markdown; READ_TIME computed for local files only; relative paths resolved via realpath; all extracted text HTML-escaped
- `video-share` skill: social posts from YouTube/Vimeo URLs via oEmbed API; 4xx fallback to manual title/channel input; PLATFORM_COLOR from hardcoded map only
- `github-code-share` skill: social posts for specific GitHub file/snippet URLs; public repos only; URL fragment parsed before WebFetch; code HTML-escaped before card substitution; security-scrub via temp file with explicit args
- `blog-card.html` template: headline + excerpt + conditional read-time badge + conditional tag chips footer
- `video-card.html` template: conditional thumbnail zone + play overlay + channel + platform badge
- `snippet-card.html` template: syntax-highlighted card with inline highlight.js (offline-safe, github-dark theme)
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
| `skills/code-share/SKILL.md` | Handles local git commits/diffs — unchanged |
| `skills/scan-for-shares/SKILL.md` | Git history scanning only — unchanged |
| `skills/security-scrub/SKILL.md` | Reused by `github-code-share` via Skill call |
| `templates/diff-card.html` | Diff use case stays separate |
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
| `Bash` | Path resolve + screenshot | Screenshot | Screenshot |
| `Skill` | — | — | Call security-scrub |
| `AskUserQuestion` | Platform + tone | Platform + angle | Platform + angle |
| `ToolSearch` | Load WebFetch | Load WebFetch | Load WebFetch |
| `SendUserFile` | PNG card | PNG card | PNG card |

---

## Stress-Test Fixes Applied (All 3 Rounds)

| # | Round | Fix |
|---|-------|-----|
| 1 | R1 | Phase 5 of `github-code-share` HTML-escapes `&`, `<`, `>`, `"` before `{{CODE_LINES}}` substitution — `&` first |
| 2 | R1 | Phase 1 of `github-code-share` parses `#L10-L25` fragment from URL string before any WebFetch call |
| 3 | R1 | Phase 3 of `github-code-share` writes snippet to `~/.claude/tmp/scrub-input.txt` via `Write`; `Write` added to allowed-tools |
| 4 | R1 | `snippet-card.html` uses inline highlight.js bundle (github-dark theme) |
| 5 | R1 | Phase 1 of `github-code-share` states public-repos-only; Phase 2 stops on 4xx with clear error |
| 6 | R1 | Phase 2 of `video-share` handles oEmbed 4xx with `AskUserQuestion` fallback |
| 7 | R1 | `READ_TIME` omitted for URL sources in `blog-share`; computed only for local `.md` files |
| 8 | R1 | `skills/code-share/references/variables.md` added to Files to Update |
| 9 | R2 | All 3 skill descriptions trimmed to ≤160 chars (152, 151, 158 respectively) |
| 10 | R2 | Template conditional rendering uses Option A: skill injects full HTML element or `""` |
| 11 | R2 | `{{TAGS}}` and all extracted text HTML-escaped in `blog-share` Phase 2 |
| 12 | R2 | `snippet-card.html` uses inline highlight.js bundle — no CDN dependency, offline-safe |
| 13 | R2 | `github-code-share` Phase 1 also accepts `raw.githubusercontent.com` URLs directly |
| 14 | R2 | Verification checklist includes `/skill-reviewer` audit step |
| 15 | R3 | `security-scrub` Skill call includes explicit `args`: `"Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing."` |
| 16 | R3 | `blog-share` Phase 1 resolves relative paths via `realpath` before calling `Read` |
| 17 | R3 | Concrete ≤160-char description text documented and applied |
| 18 | R3 | Template conditional rendering mechanism fully specified (Option A documented per-variable) |
| 19 | R3 | No-security-scrub rationale for blog/video stated explicitly in Context section |
| 20 | R3 | Blog/video discovery gap acknowledged as intentional v0.4.0 scope |

---

## Verification

1. **Skill activation** — trigger with natural language:
   - "Share this blog post: [URL]" → `blog-share` activates
   - "Write a tweet about this YouTube video: [URL]" → `video-share` activates
   - "Post about this GitHub file: https://github.com/owner/repo/blob/main/src/auth.ts#L10-L25" → `github-code-share` activates

2. **WebFetch pipeline** — `blog-share` extracts OG title + description from a real URL; `video-share` hits YouTube oEmbed and gets `title` + `author_name`

3. **Security scrub** — `github-code-share` writes to temp file, calls security-scrub with explicit args, blocks on HIGH findings

4. **HTML escaping** — test with TypeScript file containing `Array<string>` and `a > b` — card renders correctly

5. **URL fragment parsing** — test `https://github.com/.../file.ts#L10-L25` — extracts lines 10–25 only

6. **oEmbed fallback** — test `video-share` with a private YouTube URL — asks for manual input

7. **Conditional rendering** — blog card with no tags: footer absent entirely; video card with no thumbnail: thumbnail zone absent entirely

8. **Syntax highlighting** — open `snippet-card.html` in browser without internet — highlight.js colours code from inline bundle

9. **Screenshot pipeline** — one full end-to-end run per skill: populate → serve → Playwright screenshot → PNG delivered

10. **Existing skills unaffected** — run `code-share` on a local git diff; confirm unchanged behaviour

11. **`/skill-reviewer` audit** — run `/skill-reviewer:reviewing-skills` on each new SKILL.md; resolve any failures before committing

12. **Marketplace validation** — run `/validate-plugin code-share`; confirm no JSON errors in `marketplace.json`

---

## Implementation Order

1. `templates/blog-card.html`
2. `templates/video-card.html`
3. `templates/snippet-card.html` (inline highlight.js)
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
