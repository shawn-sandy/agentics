# Changelog — social-media-tools

## v2.15.0 — 2026-07-02 — save-artifact: save HTML Artifact pages for sharing

### Added

- **`save-artifact` skill** — copies a chosen HTML Artifact page into
  `${CLAUDE_PLUGIN_ROOT}/artifacts/` under a dated `<name>-YYYY-MM-DD.html`
  filename and reports the saved path. Resolves the source from an explicit
  path or by asking; guards against an unset `CLAUDE_PLUGIN_ROOT` (errors
  rather than writing elsewhere) and appends a numeric suffix on filename
  collision. Note: the plugin cache is wiped on reinstall/update, so saved
  artifacts are not durable — documented in the skill.
- **`tests/plugins/test-save-artifact.sh`** — objective smoke test covering the
  copy, collision, and unset-guard paths.

## v2.14.0 — 2026-07-02 — export-session: session transcripts to Markdown

### Added

- **`export-session` skill** — converts a Claude Code session JSONL transcript into a Markdown
  file under `{plansDirectory}/sessions/` (YAML frontmatter + user/Claude turns, harness noise
  filtered) via a bundled `export_session.py` script, so sessions can be reused as reference and
  educational material. Trigger with `/export-session` or by asking to export/save/archive a
  session as Markdown.

## v2.13.0 — 2026-07-01 — write-guide: dynamic output via section library and archetypes

### Changed

- **`write-guide` output is now topic-shaped, not template-shaped** — the fixed 12-section
  skeleton is reframed as a section library (`references/skeleton.md`): the author assembles each
  guide from it, adding, dropping, reordering, or blending sections to fit the topic. The enforced
  contract is the invariant spine (provenance callout → body → Quick reference → Cross-references),
  the six discipline rules, and a depth bar (≥1 verbatim-quoted primary source + ≥1 worked example
  per guide) — never a fixed section sequence.
- **Discovery surfaces reframed** — the root `CLAUDE.md` plugin table and this plugin's README no
  longer advertise a "fixed 12-section skeleton"; both now describe the section library and
  archetype starting points.

### Added

- **Five archetypes as non-binding starting points** (`references/exemplars.md`) —
  `system-explainer` and `rule-deep-dive` (the original two, grounded in real exemplars) plus
  `how-to` (task tutorial), `concept-explainer` (mental-model builder), and `change-recap`
  (what changed and why). Each gives a suggested section set and a "what to steal" note, with
  explicit permission to deviate; a per-archetype picker table with a most-specific-wins
  starting-point heuristic replaces the old binary rule-vs-system choice.
- **"Select a starting archetype" workflow step** in SKILL.md, between Structure and the
  verification steps — pick the closest archetype, then assemble the body from the section
  library; the archetype is a starting shape, not a contract.
- **Change-recap boundary** — SKILL.md now routes plan-completion documentation to
  `plan-interview:documenting-plans`; `change-recap` guides tell the story of a change for readers.

## v2.12.3 — 2026-06-27 — Order media library newest-first by card date, not mtime

### Fixed

- **`media-library` ordering** — the media gallery now sorts cards newest-first by the trailing `-YYYY-MM-DD` in each card filename instead of filesystem modification time (`ls -t`). Because `git checkout` resets every file's mtime to the same checkout time, the mtime sort was unreliable; sorting by the date embedded in the filename is deterministic and matches the visible card date.

## v2.12.2 — 2026-06-20 — write-guide reads plansDirectory via Claude settings precedence

### Fixed

- **`write-guide` directory resolution** — the `<plansDirectory>/guides/` target now reads `plansDirectory` following Claude Code's settings precedence (project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`); the `docs/guides/` → `docs/` fallbacks are unchanged.

## v2.12.1 — 2026-06-18 — Surface write-guide in discovery; backfill #328 description optimization

### Changed

- **`write-guide` surfaced in discovery surfaces** — the skill shipped in v2.12.0 but was missing
  from the marketplace `description` and the root `CLAUDE.md` plugin table. Both now mention it, so
  it is discoverable from the marketplace listing and the session-loaded capability index, matching
  how every other skill in this plugin is documented.
- **Skill descriptions optimized to the three-part ≤200-char format** — backfills the version bump
  and changelog entry that should have accompanied PR #328, which rewrote the `share-explanation`
  and `write-guide` skill frontmatter `description:` fields to the canonical
  `[short ≤80 chars] [capability] Use when…` shape. No behavior change; metadata/discovery only.

---

## v2.12.0 — 2026-06-17 — write-guide: long-form internal explainer guides

### Added

- `write-guide` skill: writes a long-form internal developer guide (system, rule, concept, or
  saved memory) to `docs/` following a fixed 12-section skeleton, modeled on two canonical exemplars
  — a broad system explainer and a narrow single-rule deep-dive. Output is a `verb-target`
  kebab-case Markdown file with verified facts throughout.
- Six enforced discipline rules in the skill: WebFetch-verify every external URL before pasting,
  Read/Grep-verify every on-disk fact, treat memory contents as frozen-in-time, quote primary
  sources verbatim, mark uncertainty rather than fabricate, and attach a "per-user, not in this
  repo" disclaimer to `~/.claude/...` paths and `[[memory wikilinks]]`.
- `skills/write-guide/references/skeleton.md`: the 12-section template, verbatim, with a
  section-by-section intent table.
- `skills/write-guide/references/tone-rules.md`: nine tone rules and the six discipline rules,
  each expanded with a worked example drawn from the exemplars.
- `skills/write-guide/references/exemplars.md`: synopsis of the two exemplar archetypes (broad
  explainer vs. single-rule deep-dive) and a picker for which to model.

---

## v2.11.0 — 2026-06-09 — share-react: component preview, implementation, and props card

### Added

- `share-react` skill: shares a React component (`.tsx`/`.jsx` path, IDE selection, or paste) as one
  dark-mode card combining a static rendered preview (up to 3 states), the implementation code, and
  a full typed props table (name, type, required, default, description) parsed from TS Props/propTypes
  with JSX-usage inference fallback.
- `templates/react-card.html`: four-zone card template (header, raw skill-authored preview pane,
  highlighted implementation, semantic props table) reusing the snippet-card design system and
  `--card-width` token.
- `skills/share-react/references/props-extraction.md`: authoritative props-table parsing and
  rendering rules.
- `social-share` router rule: `.tsx`/`.jsx` selections and paths now dispatch to `share-react`
  (above the generic selection rule).
- `tests/social-media-tools/`: react-card smoke test, registration test, and E2E run README.

---

## v2.10.0 — 2026-06-06 — Instructional voice: teach, don't just promote

### Changed

- **Instructional Voice doctrine** added to `references/platforms.md` as the unconditional
  default for every card-generating skill — every post now leads with a concrete, teachable
  takeaway about agentic development. The SOCIAL.md tone setting adjusts register only and
  can never disable the takeaway.
- **Follow CTA → Learn-More CTA**: the closing line is reframed as a learn-more invitation
  ("more breakdowns like this on my feed"), never a hard sell. On Twitter/X (280) and
  Bluesky (300), the takeaway wins and the learn-more line is dropped when budget is tight.
- **Post arc**: hook → takeaway/lesson → learn-more (replaces hook → insight → CTA).
- **Per-platform copy formats** in the shared `references/platforms.md` now name a takeaway
  or lesson element for every platform.
- **Draft phases** of `share-code`, `share-selection`, `share-github`, `share-session`,
  `share-project`, and `share-explanation` updated to require a concrete, applicable takeaway
  and reference the Instructional Voice doctrine.
- **share-blog** and **share-video** skill-local `references/platforms.md` rewritten: LinkedIn
  and Substack structures lead with a lesson; example CTAs are learn-more framed.
- **share-scan** scoring tables (`interesting-patterns.md`) judge shareability primarily by
  teaching value ("does this illustrate an agentic-dev lesson?").
- **share-project** tone guide (`topics.md`) reframed: each topic leads with the technique or
  principle behind the update, with learn-more CTAs.
- **share-init** now offers "Instructional / Educational" as the recommended tone option; the
  generated SOCIAL.md documents the instructional register.
- **social-config.md** documents the new tone option and notes the teaching-first voice
  applies regardless of tone.
- **README.md** updated to describe the teaching-first voice and the new tone.

---

## v2.9.2 — 2026-06-05 — Use portable plugin root for asset lookup

### Fixed

- Replaced hardcoded `~/devbox/agentics/...` author-specific paths with the portable `${CLAUDE_PLUGIN_ROOT}` substitution (braced form, which Claude Code inline-substitutes into skill content — the unbraced form is only guaranteed in hook/MCP/LSP subprocess environments) in the "Locate Plugin Assets" step of all 10 share skills (`share-code`, `share-init`, `share-project`, `share-explanation`, `share-video`, `share-selection`, `social-share`, `share-github`, `share-blog`, `share-session`). The `~/.claude` discovery `find` calls remain as fallbacks.
- `README.md`: local-development example now uses the repo-relative `./kit/plugins/social-media-tools` path instead of an author-specific home directory.

---

## v2.9.1 — 2026-06-04 — Enforce all platforms and broaden share-explanation scope

### Fixed

- `platforms.md`: added explicit "always offer all five options, never filter" rule so skills cannot selectively hide platforms in AskUserQuestion.
- `share-init`: added missing Substack platform option and canonical token mapping.
- `share-explanation`: broadened description and intro scope from "plugin components" to any project file, component, or concept.

---

## v2.9.0 — 2026-06-04 — Open gallery images in a native dialog modal

### Changed

- "View image" control changed from an `<a target="_blank">` anchor to a `<button>` that opens the card's PNG in a native `<dialog>` modal overlay, keeping the user in the gallery.
- Added `<dialog id="imgDialog">` element to `gallery.html` with a close button, backdrop click, and Escape-to-close support; native `<dialog>` provides focus trapping and focus restoration automatically.
- Dialog image receives meaningful `alt` text from the card's `data-topic` attribute.
- Updated `.open-img-link` CSS to reset button defaults so the control renders identically to the previous link.
- Open/close animations gated behind `prefers-reduced-motion: reduce`.
- Updated `media-library/SKILL.md` Step 3 to emit `<button>` markup with `data-img` and `data-topic` attributes instead of anchor markup.

---

## v2.8.0 — 2026-06-03 — Expand share-explanation to entire project codebase

### Changed

- `share-explanation` Phase 2: replaced single-plugin skill/command scan with a five-tier
  lookup rooted at `$GIT_ROOT`: (1) skill by dir name, (2) command by filename, (3) any
  source file by base name, (4) function/class/symbol grep, (5) keyword grep. Searches all
  tracked files (`.md`, `.py`, `.js`, `.ts`, `.mjs`, `.sh`, `.json`) across the project.
- Phase 3: synthesis structure now adapts to `TARGET_TYPE` — skills/commands get the
  six-section workflow breakdown; files, functions, and concepts get a five-section code
  explanation (purpose, how-it-works, patterns, dependencies, usage example).
- "Not found" error message no longer hard-codes plugin skill listing.
- Search excludes `archive/`, `node_modules/`, `.git/`, `dist/`, `build/` to avoid noise.

---

## v2.7.0 — 2026-06-03 — Add "View image" link to media library gallery cards

### Added

- Gallery cards now show a "View image" link below each card that opens the PNG screenshot directly in a new browser tab.
- New `.gallery-card-wrap` container wraps each card and its image link so the filter JS hides both together.
- New `.open-img-link` CSS rule in `gallery.html` for the image link styling.

### Changed

- `applyFilters()` in `gallery.html` now targets `.gallery-card-wrap` for show/hide, reading `data-type` and `data-topic` from the inner `.gallery-card`.

---

## v2.6.4 — 2026-06-03 — Slug normalization and rule 8 clarity

### Fixed

- `share-explanation` Phase 6: normalize `TARGET_NAME` (or `TARGET_RAW` for concept targets) through the same slug pipeline (lowercase, slug-safe chars, 30-char cap) using `printf` instead of `echo` to avoid edge cases with leading `-n` and escape sequences.
- `social-share` router rule 8 "Extra flags" cell: reworded to explicitly state that `EXTRA_FLAGS` = `$ARGUMENTS` with only the `--platform=...` token removed; all other text and flags (including `--tone`, query text) are forwarded as-is.

---

## v2.6.3 — 2026-06-03 — Fix share-explanation routing and defaults

### Fixed

- `social-share` router rule 8: strip `--platform=...` from `$ARGUMENTS` before using as `EXTRA_FLAGS` so Phase 3's prepended `--platform` flag is never duplicated.
- `share-explanation` Phase 5: spell out concrete variable-resolution steps — `PLATFORM`/`TONE` are set from `DEFAULT_PLATFORM`/`DEFAULT_TONE` (Phase 0b) before prompting via `AskUserQuestion`.
- `share-explanation` Phase 6: derive `TARGET_SLUG` from `TARGET_RAW` for concept targets where `TARGET_NAME` is empty, preventing `explain--YYYY-MM-DD` filenames.

---

## v2.6.2 — 2026-06-03 — Rename explain-codebase to share-explanation

### Changed

- Renamed `explain-codebase` skill directory to `share-explanation` and updated `name:` frontmatter to `share-explanation` to align with the `share-*` plugin naming convention.
- `social-share` router rule 8: updated dispatch target from `explain-codebase` to `share-explanation`.

---

## v2.6.1 — 2026-06-03 — Fix explain-codebase review findings

### Fixed

- `explain-codebase` Phase 2: concept targets now derive `TARGET_NAME` from `TARGET_RAW` slug — previously `SLUG_INPUT` built an empty name for concept queries
- `explain-codebase`: moved reuse-check from Phase 1c to Phase 5b so both `TARGET_NAME` and `PLATFORM` are resolved before the check runs; reuse path no longer produces blank platform headings
- `explain-codebase` Phase 6: `{{ATTRIBUTION}}` in `quote-card.html` now maps to plugin/project name instead of a raw file path
- `social-share` rule 8: added guard to exclude session-context phrases (`my session`, `session recap`, etc.) so "explain my session" correctly falls through to the session rule (rule 9)

---

## v2.6.0 — 2026-06-03 — Add explain-codebase skill

### Added

- `explain-codebase` skill: answers natural-language questions ("how does share-session work?") by reading source SKILL.md and reference files, synthesizing a structured developer-friendly explanation (Core Purpose, Activation Conditions, Workflow Phases, Key Patterns, Important Files, Invocation), then delivering platform-aware social copy and a dark-mode card image following the full share-* pipeline (security scrub → copy → feature-card or quote-card template → persistent save → screenshot → deliver).
- `social-share` router: added rule 8 routing `explain`, `how does`, `how do`, `how it works`, `what is`, `what does`, `describe` queries to `explain-codebase`; renumbered former rules 8–10 to 9–11.

---

## v2.5.2 — 2026-06-02 — Fix element screenshot falling back to full page

### Fixed

- `references/rendering-pipeline.md`: added `browser_snapshot` step between page-load wait and screenshot. `browser_take_screenshot`'s `target` accepts either an element `ref` from a prior snapshot or a CSS selector, but CSS selector-only targeting is unreliable — without a prior snapshot the tool may fall back to a full-viewport capture if the element is not yet rendered. The snapshot step ensures the page is fully loaded before capture. Also clarified that card templates use a plain `<div class="card">` (no semantic role), so the snapshot may not return a named `ref` — in that case, pass `".card"` as a CSS selector directly to `target`. Also added `mcp__plugin_playwright_playwright__browser_snapshot` to the ToolSearch selector in Step 3 so it is callable in deferred-tool environments. Affects all 7 skills that delegate to this pipeline.

---

## v2.5.0 — 2026-06-02 — Add SOCIAL.md project sharing config

### Added

- `share-init` skill: analyzes the project and generates a `SOCIAL.md` file with default platform, tone, hashtags, focus areas, audience, and avoid patterns
- `references/social-config.md`: documents the `SOCIAL.md` format and how each skill consumes it
- `social-share` router: loads `SOCIAL.md` in Phase 0b and uses `DEFAULT_PLATFORM` in Phase 3
- `share-code`: loads `SOCIAL.md` for default platform, tone, hashtags, focus areas, and audience
- `share-project`: loads `SOCIAL.md` for defaults and uses project identity, focus areas, and audience in copy drafting
- `share-scan`: loads `SOCIAL.md` focus areas for score boosting and avoid patterns for candidate filtering

---

## v2.4.3 — 2026-06-02 — Optimize skill descriptions to three-part format

### Changed

- Rewrote `description` fields in nine skills (`media-library`, `share-blog`, `share-code`, `share-github`, `share-project`, `share-selection`, `share-session`, `share-video`, `social-share`) to the three-part format (short label ≤80 chars + capability sentence + trigger phrase, total ≤200 chars) for improved skill discoverability.

---

## v2.4.2 — 2026-06-01 — Add ExitPlanMode error handling

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success

## v2.4.1 — 2026-06-01 — Widen card templates to 1024px with pipeline and accessibility fixes

### Changed

- All 7 card templates (blog, diff, feature, quote, session, snippet, video): widened from fixed pixel widths to `min(1024px, 100%)` for better social sharing fidelity.
- `references/rendering-pipeline.md`: added `browser_resize` to the Playwright ToolSearch selector so the resize step is callable in deferred-tool environments.

### Fixed

- `docs/media/social/feature-plan-agent-posttooluse-hook-auto-rebuild-2026-06-01.html`: guarded clipboard fallback `done()` behind a successful `execCommand('copy')` to avoid false "Copied ✓" on failure; changed `<p class="copy-label">` to `<label for="post-copy">` for textarea accessibility.

---

## v2.4.0 — 2026-05-31 — Centralize user gate inside security-scrub

### Added

- `security-scrub`: added Step 6 (User Gate) — after emitting the SCRUB RESULT block, the skill now gates based on severity: BLOCKED hard-stops with no Continue option; WARN and PASS-with-LOW present an `AskUserQuestion`; clean PASS auto-proceeds without prompting. All callers get consistent gating behavior automatically.
- `security-scrub`: added `AskUserQuestion` to `allowed-tools`.

### Changed

- `share-session`: removed the redundant post-scrub `AskUserQuestion` gate (previously added in v2.3.2) and the "BLOCKED = hard stop" documentation from Phase 2 — both are now enforced inside `security-scrub`. Callers now check the `GATE RESULT` line instead of parsing `SCRUB RESULT` themselves.

---

## v2.3.2 — 2026-05-30 — Prompt to continue after security scrub

### Fixed

- `share-session` skill: added user confirmation prompt after security scrub passes, so users can opt out before card generation begins.

---

## v2.3.1 — 2026-05-30 — Fix section sign rendering

### Fixed

- Replaced `§` (section sign) in references/variables.md with plain text to fix rendering issues.

---

## v2.3.0 — 2026-05-29

Media library skill now generates an interactive HTML page as its primary action.

- `media-library` skill: restructured to generate and open a filterable HTML page
  in the browser as the default behavior — no intermediate markdown table or
  interactive menu; the page lists all saved cards with clickable links that open
  each card directly; optional follow-up step for extracting copy text on request
- `templates/gallery.html`: enhanced with type filter chips (All, Diff, Feature,
  Quote, Blog, Snippet, Video, Project, Session), a search box for filtering by
  topic or type, a grid/list view toggle, visible-count indicator when filtering,
  responsive mobile layout, and `data-type`/`data-topic` attributes on card
  entries for client-side filtering; title changed to "Media Library"

## v2.2.0 — 2026-05-29

Add visual gallery viewer for saved social cards.

- `templates/gallery.html` (new): dark-mode responsive grid template matching the
  existing card design language; displays PNG thumbnails with color-coded type badges,
  humanized topics, and dates; works on `file://` protocol with no JS dependencies;
  `<img onerror>` fallback shows card type text when PNG is missing
- `media-library` skill: added **View gallery** option to the interactive menu —
  scans `docs/media/social/` for saved cards, populates the gallery template, writes
  `docs/media/social/index.html`, and opens it in the default browser; gallery is
  generated on demand, not on every card save
- Updated skill description to include gallery viewing as a trigger

## v2.1.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## v2.1.0 — 2026-05-29

Add Substack Notes as a fourth share platform; consolidate platform list into
shared reference to reduce duplication.

- Added Substack (500 chars, thoughtful/newsletter tone) to the canonical platform
  table in `references/platforms.md`
- Consolidated platform options, copy variant storage convention, draft procedure,
  and default per-platform copy formats into `references/platforms.md` — skills now
  reference the shared file instead of duplicating the platform list inline
- Added Substack copy format sections to `share-blog/references/platforms.md` and
  `share-video/references/platforms.md` with examples
- Updated all share skill descriptions for activation matching
- Updated `references/copy-panels.md` to render four per-site panels in "All sites"
  mode, with a cross-reference note for adding new platforms
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
