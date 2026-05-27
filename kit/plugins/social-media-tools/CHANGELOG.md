# Changelog — social-media-tools

## v0.4.0 — 2026-05-27

Added persistent HTML storage, a copy-to-clipboard panel, reuse detection, and a media library skill.

- All 6 HTML templates updated: `flex-direction: column` layout so card and copy panel stack vertically; copy panel section appended below each card containing a `<textarea>` with the post text and a native-clipboard **Copy post** button (no external libraries — `navigator.clipboard.writeText()` with `document.execCommand` fallback)
- New `{{POST_COPY_TEXT}}` template variable (all 6 templates): textarea-safe escaped post copy (all platforms joined with `\n---\n`); documented in `skills/code-share/references/variables.md`
- `code-share`, `blog-share`, `video-share`, `github-code-share` skills: Phase 1c reuse check added — scans `docs/media/social/` for matching posts before generating; Phase 4b/5b persistent save added — writes populated HTML to `docs/media/social/{type}-{slug}-{date}.html` after generation; Deliver phase now surfaces the saved path
- `scan-for-shares` skill: Step 4b cross-reference — flags candidates whose slug matches an existing file in `docs/media/social/` with `[SAVED]`; background mode auto-skips SAVED candidates
- `media-library` skill (new): lists saved posts from `docs/media/social/` in a date/type/topic table; lets developers view post copy text or get the file path to open in a browser

## v0.3.0 — 2026-05-27

Extended the plugin to support three new content types beyond code changes.

- `blog-share` skill: generate social posts from a blog post URL or local `.md` file; fetches OG metadata via WebFetch; `READ_TIME` computed for local files only; relative paths resolved via `realpath`; all extracted text HTML-escaped before card substitution
- `video-share` skill: generate social posts from YouTube or Vimeo URLs; fetches title/channel/thumbnail via oEmbed API; graceful 4xx fallback to manual title/channel input; `PLATFORM_COLOR` hardcoded from URL detection only
- `github-code-share` skill: generate social posts for specific GitHub file or snippet URLs; public repos only; URL fragment (`#L10-L25`) parsed before WebFetch; code HTML-escaped before card substitution; mandatory `security-scrub` via temp file with explicit args
- `blog-card.html` template: headline + excerpt + conditional read-time badge + conditional tag chips footer (Option A conditional rendering)
- `video-card.html` template: conditional thumbnail zone with CSS play-button overlay + channel + platform badge
- `snippet-card.html` template: syntax-highlighted code card using CDN highlight.js (github-dark theme) with inline CSS fallback for offline use
- Updated `skills/code-share/references/variables.md` with variable tables for the three new card templates

## v0.2.0 — 2026-05-26

Added discovery and security-scrub layer upstream of the `code-share` skill.

- `scan-for-shares` skill: discovers shareable commits or codebase patterns in two modes — history mode (`git log` on current branch) and codebase mode (`--codebase <path>`); scores candidates, runs security scrub, presents multi-select review gate, writes `.claude/digests/code-digest-YYYY-MM-DD.md`
- `security-scrub` skill: standalone secret/credential scanner; detects HIGH/MEDIUM/LOW patterns across 20+ categories; masks values before reporting; emits structured `SCRUB RESULT` block for callers
- `/code-share:digest` command: interactive front-end for `scan-for-shares`
- `/code-share:digest-bg` command: fire-and-forget background variant via `agent-digest`
- `agent-digest` background agent: runs digest scan without user interaction; proactively reports output path on completion
- Scheduling note: GitHub Actions / cron / Claude routines can run `digest-bg` on a schedule; human review always required before posting

## v0.1.1 — 2026-05-26

- Auto-detect project context (git diff, recent commits, CHANGELOG) in Phase 1 before prompting
- Fix `$PLUGIN_DIR` derivation in Phase 5a — now explicitly set as `$(dirname "$TEMPLATES_DIR")`
- Rewrite skill description to ≤160 chars (two-sentence format)
- Remove non-standard `version` field from SKILL.md frontmatter
- Add explicit STOP boundary after Phase 6
- Add `README.md` to plugin root

## v0.1.0 — 2026-05-26

Initial release.

- `code-share` skill: draft platform-aware copy for LinkedIn, Twitter/X, and Bluesky
- Three dark-mode HTML card templates: `diff-card`, `feature-card`, `quote-card`
- Playwright-based screenshot pipeline with automatic port selection
- Fallback message with HTML path when Playwright screenshot is unavailable
- `find_free_port.py` helper script to avoid port collisions
