# Changelog — social-media-tools

## v2.1.0 — 2026-05-29

Add Substack Notes as a fourth share platform across all card-generating skills.

- Added Substack (500 chars, thoughtful/newsletter tone) to the canonical platform
  table in `references/platforms.md`
- Updated all share skills (`share-code`, `share-blog`, `share-video`, `share-github`,
  `share-selection`, `share-project`, `share-session`) to include Substack in
  descriptions, platform options, and copy variant lists
- Added Substack copy format sections to `share-blog/references/platforms.md` and
  `share-video/references/platforms.md` with examples
- Updated `social-share` router to detect Substack platform phrases
- Updated `share-scan` digest platform list to include Substack
- Updated `references/copy-panels.md` to render four per-site panels in "All sites" mode
- Added `substack` tag to marketplace entry

## v2.0.0 — 2026-05-29

BREAKING CHANGE: Remove background dispatch layer.

- Deleted commands: `social-share-bg`, `digest-bg`, `session-bg`
- Deleted agents: `agent-social-share`, `agent-digest`
- Deleted reference: `non-interactive-mode.md`
- `social-share` router now invokes target skills directly via `Skill(...)` instead of
  dispatching a background agent; `allowed-tools` simplified to `Bash, Read, Write, Skill`
- Removed `--background` flag and non-interactive skip rules from all share skills
- `share-scan`: removed `--background` flag, automatic PASS inclusion, and background review gate bypass
- `media-library`: removed background catalog-snapshot path and `SOCIAL-SHARE: DONE` completion line
- `share-session`: removed `BG_MODE` variable, background content-reconstruction path, and `SOCIAL-SHARE: DONE` completion line
- Reduced permission surface on the router: no more `Agent`, `ToolSearch`, `ExitPlanMode`, or `WebFetch` in the dispatch layer
- Individual share skills still use Playwright for interactive screenshots via `rendering-pipeline.md`

## v1.3.1 — 2026-05-29

Fix background card generation. The `agent-social-share` background subagent invoked
the `share-*` skills via `Skill`, but subagent tool grants are not transitive across
`Skill` invocations — so the inner skills' card-rendering and fetch calls were blocked,
and no PNG (or blog/GitHub/video fetch) succeeded in background mode.

- `agent-social-share` agent: widened `tools:` to add `WebFetch` (needed by
  `share-blog`, `share-github`, `share-video`) and the three Playwright screenshot
  tools used by every card skill's rendering pipeline
  (`mcp__plugin_playwright_playwright__browser_navigate`, `…__browser_take_screenshot`,
  `…__browser_wait_for`). `AskUserQuestion` is intentionally still excluded — background
  runs skip it. Mirrors the precedent set by `agent-product-plans`.
- No skill logic changed; the `--background` non-interactive paths were already correct.
- `agent-social-share`: added a Step 1b Playwright preflight. For card-generating skills
  (every target except `media-library`), the agent now probes for the screenshot tool via
  `ToolSearch` before invoking the skill; if Playwright is unavailable it proceeds (HTML +
  copy are still produced) but reports the `DONE` line with an empty `png=` and an explicit
  `⚠ WARN` pointing to the HTML — so a missing screenshot is never silent.
- `agent-digest` / `share-scan` (digest path) was unaffected and is unchanged.
- README `Requirements`: added a note that the Playwright MCP is an external,
  non-bundled dependency (not declared in `plugin.json`), pointing to the
  rendering-pipeline manual fallback; formally declaring it is a planned enhancement.

## v1.3.0 — 2026-05-29

`share-session` now leads with a summary of **what the session accomplished** — a narrative
plus key highlights — instead of foregrounding token usage. Tokens, duration, and commit/file
counts move to a compact secondary stats strip.

- `share-session` skill: new Phase 1e builds a `NARRATIVE` (1–2 sentences) and 3–5
  `ACCOMPLISHMENTS` bullets. Interactive runs summarize from the live conversation context;
  `--background` runs reconstruct the summary from enriched `session_usage.py` signals (user
  prompts, assistant snippets, files touched, tool-use counts, git commit subjects). Security
  scrub now covers the full narrative + accomplishments text, not just the first prompt. Draft
  copy leads with outcomes; token/duration/cache figures become a single trailing stat line
  (still tokens-only, never dollars). Description + triggers updated ("what I worked on",
  "what I did today", "session summary")
- `session_usage.py`: emits five new bounded fields — `user_prompts[]`, `assistant_snippets[]`,
  `tool_use_counts{}`, `files_touched[]`, and `files_touched_count` — extracted in the existing
  single streaming pass; caps keep stdout small for multi-MB sessions. `first_user_prompt`
  retained for backward compatibility
- `session-card.html`: restructured to a content-first layout — narrative paragraph + arrow
  bullet list as the hero, with a compact `tokens · duration · cache hit · files · commits`
  strip beneath. Replaces the 8-tile metrics grid. New `{{NARRATIVE}}` and `{{ACCOMPLISHMENTS}}`
  variables; `{{SUMMARY}}`, `{{INPUT_TOKENS}}`, `{{OUTPUT_TOKENS}}`, `{{CACHE_READ}}` removed.
  Copy panels + clipboard script unchanged
- `references/variables.md`: documented the `session-card.html` variables (previously missing)
- `social-share` router (rule 8): added `session summary`, `what I worked on`, and `what I did
  today` so the new `share-session` trigger phrases dispatch correctly through the router

## v1.2.0 — 2026-05-29

New `share-session` skill — generate a dark-mode session recap card from the live
Claude Code session JSONL and post to LinkedIn, Twitter/X, or Bluesky.

- `share-session` skill: reads `$CLAUDE_CODE_SESSION_ID` + cwd to locate the session JSONL;
  runs `session_usage.py` for token counts (input, output, cache-read, cache-hit-rate),
  duration, model, and first user prompt; derives git commit + file-change counts for the
  session window; drafts tokens-only platform-aware copy (never dollar amounts); populates
  `session-card.html` dark-mode template; saves PNG to `docs/media/social/`
- `session_usage.py` script: defensive JSONL parser — streams line-by-line, tolerates
  truncated active sessions, coerces all token fields to `int` to guard against malformed
  values, resolves session path via `$CLAUDE_CODE_SESSION_ID` + cwd or falls back to newest
  `*.jsonl` in the project sessions directory
- `session-card.html` template: dark-mode 8-tile metrics card (total/input/output/cache
  tokens, cache hit rate, duration, files changed, commits) with copy panels
- `/social-media-tools:session-bg` command: fire-and-forget background command; dispatches
  `agent-social-share` with `TARGET_SKILL=share-session`; accepts `--platform`, `--tone`,
  and `--session=<id|path>` flags
- `social-share` router updated: new row 8 routes session/recap/tokens-today intent to
  `share-session` before the git-diff fallbacks

## v1.1.1 — 2026-05-29

README documentation sync — no behavior changes.

- Added missing **Components** sections for components already listed in the Features table
  and structure tree but undocumented in detail: `social-share` (router), `share-project`,
  `media-library`, `/social-media-tools:social-share-bg`, and `agent-social-share`
- Reworked the overview to reflect the current three-workflow scope (discovery pipeline,
  card generation pipeline, background router) and to note that no path auto-posts
- Updated the overview to mention selected/pasted code and project updates, matching the
  marketplace description

## v1.1.0 — 2026-05-28

Full background coverage: every skill except `security-scrub` (a sub-step utility) can now
run in the background, freeing the main session context while social cards or catalog
snapshots are generated.

- `media-library` skill: added `--background` non-interactive mode — when dispatched with
  `--background`, writes the saved-posts catalog table to
  `.claude/digests/media-library-YYYY-MM-DD.md` and emits a
  `SOCIAL-SHARE: DONE skill=media-library output=<path>` completion line instead of calling
  `AskUserQuestion`; interactive behavior (step 3 prompt) unchanged when invoked without
  `--background`; `Write` added to `allowed-tools`
- `social-share` router (rule 7, new): routes "browse", "library", "saved posts", "prior
  post", "media library", "my posts" intents to `media-library` in the background; rule sits
  above the git fallbacks so browsing requests never fall through to `share-code`
- `agent-social-share`: updated to document `media-library` as a valid `TARGET_SKILL` and
  relay the generic `output=<path>` completion form alongside the existing card form
- `references/non-interactive-mode.md`: reconciled the completion-line contract — added a
  generic file-output form (`output=<path>`) for file-producing skills, documented the
  digest chain's own flags and `Digest complete:` line as an intentional pre-contract variant
- README updated: documents full background coverage, all entry points, and the new
  `media-library --background` catalog-snapshot behavior; corrected stale pre-v1.0.0 skill
  names (`code-share` → `share-code`, `scan-for-shares` → `share-scan`, etc.) in the
  README Components and Features sections

---

## v1.0.1 — 2026-05-28

Plugin renamed from `code-share` to `social-media-tools` to match the directory name.
All commands now use the `/social-media-tools:*` prefix (e.g. `/social-media-tools:digest`).
Install with: `/plugin install social-media-tools@agentics-kit`

---

## v1.0.0 — 2026-05-28

**BREAKING:** All share-type skills renamed to `share-*` prefix for consistent naming.
Plugin name (`code-share`) and all commands unchanged.

| Old skill name | New skill name |
|---|---|
| `code-share` | `share-code` |
| `blog-share` | `share-blog` |
| `video-share` | `share-video` |
| `github-code-share` | `share-github` |
| `selection-share` | `share-selection` |
| `project-share` | `share-project` |
| `scan-for-shares` | `share-scan` |

- All internal dispatch calls (`social-share` router, `agent-social-share`, `agent-digest`, `digest.md`, `digest-bg.md`) updated to reference new skill names
- Temp card filenames updated to match (`share-blog-card.html`, etc.)
- Shared references (`variables.md`, `language-map.md`, `non-interactive-mode.md`, `platforms.md`) updated
- `media-library` SKILL.md skill name references updated
- `share-scan` references (`interesting-patterns.md`, `topics.md`) updated

---

## v0.9.0 — 2026-05-28

Added `social-share` router skill, `agent-social-share` background agent, `social-share-bg`
command, a shared non-interactive mode contract, and contextual follow CTAs across all share skills.

- `social-share` skill (new): auto-activating router that classifies a natural-language request
  into the right card workflow (github-code-share, video-share, blog-share, selection-share,
  project-share, or code-share) using first-match-wins rules; captures live session context
  (git state, IDE selection, pasted code) then dispatches in the background with smart defaults
  (`--platform=all`); returns a one-line ack immediately
- `agent-social-share` agent (new): background runner that receives a pre-classified target
  skill + flags, invokes the skill in non-interactive mode, and reports a `SOCIAL-SHARE: DONE`
  completion line; mirrors `agent-digest` pattern
- `/social-media-tools:social-share-bg` command (new): explicit entry point; delegates straight to the
  `social-share` skill which handles all classification and dispatch logic
- `references/non-interactive-mode.md` (new): shared reference defining the `--background` flag
  contract — skip rules for AskUserQuestion/copy-approval/WARN/long-file/4xx, smart defaults,
  and the machine-parseable `SOCIAL-SHARE: DONE` completion format
- All 6 card skills (`code-share`, `blog-share`, `github-code-share`, `selection-share`,
  `video-share`, `project-share`) updated with a `## Non-interactive mode` pointer and
  `(Interactive mode only)` guards on their AskUserQuestion and copy-approval lines; interactive
  behavior unchanged when invoked without `--background`
- New `## Follow CTA` rule in `references/platforms.md` (read by all share skills during
  their Draft Copy phase): close each post with a **topic-matched** follow line keyed to
  the post's keywords/hashtags, **varied every time** (a pattern bank to adapt, never a stock
  "follow me"), **generic with no `@handle`**, and dropped on Twitter/X and Bluesky when the
  character budget is tight (content wins)
- `blog-share` and `video-share` copy-format references updated with follow CTA examples
- `code-share`, `selection-share`, `github-code-share`, and `project-share` Draft Copy
  guidance clarified so the existing closing "CTA" is explicitly the topic-matched follow CTA

## v0.8.1 — 2026-05-28

Fixed generic `element` label in `references/rendering-pipeline.md` rendering pipeline reference.

## v0.8.0 — 2026-05-28

Added `selection-share` skill for turning selected/pasted code into objective-driven posts.

- `selection-share` skill (new): detects code the user highlighted in their IDE, has selected
  or open as a file, or pasted as a fenced block (provided via context); reads it, scrubs it
  for secrets via `security-scrub`, and drafts platform-aware copy shaped by a user
  **objective** (inferred from the prompt, asked only if absent) — distinct from `code-share`,
  which scans git history
- Auto-picks the card template from the content: diff-like text (`+`/`-` lines, `@@` hunk
  headers, or a ```` ```diff ```` fence) → `diff-card.html`; otherwise → `snippet-card.html`
- Selected-file handling: derives `FILENAME`/`LANGUAGE` from the real path/extension, declines
  non-code files (binary, lockfiles, minified bundles), and prompts for a region when a file
  exceeds the ~80-line snippet cap
- `references/language-map.md` (relocated): moved from
  `skills/github-code-share/references/language-map.md` to the plugin-root `references/` folder
  so both `github-code-share` and `selection-share` share it without a cross-skill pointer;
  `github-code-share` repointed to `$PLUGIN_DIR/references/language-map.md`

## v0.7.0 — 2026-05-27

Extracted shared card-pipeline logic into a plugin-root `references/` folder;
added reuse check to `project-share`.

- New `references/` folder at plugin root with 6 shared files: `rendering-pipeline.md`,
  `reuse-check.md`, `saving-and-delivery.md`, `copy-panels.md`, `variables.md`,
  `platforms.md` — each replacing inline duplicates across all 5 card skills
- All 5 card-generating skills (`code-share`, `blog-share`, `video-share`,
  `github-code-share`, `project-share`) rewritten to add **Phase 0: Locate plugin assets**
  and replace duplicated pipeline/save/deliver/reuse/COPY_PANELS/platform-table blocks
  with one-line pointers to `$PLUGIN_DIR/references/*.md`
- `project-share` gains a Phase 1c reuse check (was the only card skill lacking one);
  wired to the shared `references/reuse-check.md` with `FILE_PREFIX=project`
- `references/copy-panels.md` replaces the `## COPY_PANELS` section that was mislocated
  in `skills/code-share/references/variables.md`; per-template variable maps relocated to
  `references/variables.md` (the old `code-share/references/variables.md` now just points
  to the new locations)
- `blog-share/references/platforms.md` and `video-share/references/platforms.md` trimmed
  to skill-specific copy formats and examples; canonical limits now in `references/platforms.md`
- No cross-skill `../code-share/references/` pointers remain

## v0.6.0 — 2026-05-27

Added an "All sites" platform option that embeds an individually copyable post snippet per social site in the generated card.

- All 5 card-generating skills (`code-share`, `blog-share`, `video-share`, `github-code-share`, `project-share`): platform selection now offers **All sites** alongside LinkedIn / Twitter/X / Bluesky. Choosing it drafts all three variants in the chosen tone and embeds one copy panel per platform; single-site selection is unchanged.
- New `{{COPY_PANELS}}` template variable replaces `{{POST_COPY_TEXT}}` in all 6 HTML templates: holds one `<div class="copy-panel">` (single site) or three per-site panels (All sites), each with a unique textarea id (`post-copy-linkedin` / `-twitter` / `-bluesky`) and its own **Copy** button. The clipboard handler is now a shared `copyPost(id, btn)` function defined once per template; stacked panels are separated with a `.copy-panel + .copy-panel` margin rule.
- `media-library` and each skill's reuse check now extract copy by `class="post-copy-text"` (one or three textareas), labeling each by its `copy-label` — pre-0.6.0 single-panel files still read correctly.
- Updated `skills/code-share/references/variables.md` (documents `{{COPY_PANELS}}` with single- and all-sites markup) and `skills/project-share/references/topics.md`.

## v0.5.0 — 2026-05-27

Added `project-share` skill for topic-based social posts about a whole project or codebase.

- `project-share` skill (new): generates platform-aware social media copy and a dark-mode card for a project based on a topic — `features`, `bugs`, `changes`, or `release`; extracts metadata from `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `CHANGELOG.md`, and `README.md`; uses `feature-card.html` for features/release and `diff-card.html` for bugs/changes; follows the same screenshot pipeline as `code-share`; saves output to `docs/media/social/`
- `skills/project-share/references/topics.md` (new): tone guide, per-topic git extraction commands, card variable mapping, and project metadata priority table

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
- `/social-media-tools:digest` command: interactive front-end for `scan-for-shares`
- `/social-media-tools:digest-bg` command: fire-and-forget background variant via `agent-digest`
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
