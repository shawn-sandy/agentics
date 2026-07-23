# Changelog

All notable changes to the `artifact-tools` plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-07-23

### Added

- `/artifact-tools:team-recap` — publishes a detailed, visual session recap for
  the whole team, engineers and non-engineers in one document. A third framing
  wrapper over `session-artifact` alongside `product-doc`: an at-a-glance stat
  strip, one card per change, mermaid diagrams for anything whose structure or
  flow changed, a before/after table of changed rules and defaults, decisions
  with the options that were rejected, learnings, open items, files touched, and
  a glossary of internal terms. Diagrams are `<pre class="mermaid">` blocks —
  rendered natively by artifacts, and the only option available, since the
  artifact CSP blocks external scripts and assets. Filing matches `product-doc`
  (the `.claude/artifacts/` inbox and the `docs/artifacts/` gallery via
  `social-media-tools:save-artifact`, with a collision-safe local copy as
  fallback). Its republish key is `team-artifact-url:`, distinct from
  `artifact-url:` and `product-artifact-url:` because all three commands share
  one session record. A wrapper rather than a new skill so the blocking scrub
  gate is never duplicated.

### Changed

- `session-artifact` no longer reuses the extractor's `<date>-<slug>-<id>.md`
  filename for the committed session record. That name carries the session id,
  which repos enforcing a `verb-target` plan-filename convention reject — the
  write lands and a hook then blocks, forcing a mid-run rename. The record is
  now named after the work (`add-team-recap-command-session.md`), and an
  existing one is found by grepping `session-id:` in its frontmatter rather than
  by reconstructing the filename an earlier run chose. Applies to all three
  recap writers, which share the record; `product-doc`'s republish-key table was
  updated to match and now points at the same frontmatter lookup.

### Fixed

- `/artifact-tools:team-recap` files its own rendered HTML into the gallery,
  wrapped into a standalone document (the render targets an artifact frame that
  supplies `<!doctype>`/`<head>`/`<body>`). Filing the *published* page instead
  gives diagrams that render offline, but only by committing the multi-megabyte
  mermaid runtime that publishing injects — which repo static analysis reads as
  first-party source; on this repo that produced eight high-severity CodeQL
  alerts, none in the recap. The filed page's diagram blocks show as text, with a
  footer line pointing at the artifact URL where they render. The fetch-back path
  is kept as an opt-in the user has to ask for, with its costs stated up front,
  including a scrub that reports MEDIUM matches from the library's minified
  grammar tables.

## [1.4.0] - 2026-07-22

### Added

- `/artifact-tools:product-doc` — publishes a session recap aimed at the product
  team and non-engineering stakeholders rather than at code reviewers. It runs
  the existing `session-artifact` skill with three framing overrides
  (non-engineer audience, acronyms spelled out; Learnings replaced by a
  release-note section set — Features, Bug fixes, Decisions, Logic and behavior
  changes, Implementation plan details, Known gaps and follow-ups, each dropped
  when empty). Two sources feed the same document: the session transcript by
  default, or a pull request when given `#453`, a PR URL, or `--pr 453` — read
  from `gh pr view`, the changed-file list, the commit bodies, and the review
  discussion,
  falling back to session mode when `gh` or a GitHub remote is missing. PR mode
  keeps its own `pr-<number>.md` record, so re-running against a PR updates the
  same page as that PR evolves. The
  rendered HTML is filed in the shared artifacts gallery — `.claude/artifacts/`
  inbox, published to `docs/artifacts/` via `social-media-tools:save-artifact`,
  degrading to a collision-safe unpublished inbox copy when that skill is absent
  — rather than living only in the plans tree. The recap's republish key is
  `product-artifact-url:`, deliberately not the `artifact-url:` that
  `session-artifact` uses: both share one record per session, so a shared key
  would republish the product recap over an existing reviewer recap's page.
  Otherwise nothing downstream changes —
  extraction, the blocking scrub gate, the saved `.md`, the HTML render,
  publishing, and the marker check all stay the skill's. A wrapper rather than a
  fifth skill so the scrub gate is never duplicated.

## [1.3.0] - 2026-07-19

### Added

- All four skills now fetch their published artifact URL back and assert an
  expected marker before reporting success — the plan title (`plan-artifact`),
  the diff's first changed filename (`diff-artifact`), the recap `<title>`
  (`session-artifact`), and the prompt H1 or every card title in library mode
  (`prompt-artifact`). A returned URL was never evidence the page rendered: a
  blank artifact returns one too, and publishing is outward-facing and hard to
  reverse. On a missing marker the skill reports the failure with the URL
  instead of reporting success.

- `WebFetch` added to each of the four skills' `allowed-tools:`, loaded via
  `ToolSearch` with `select:WebFetch`. An undeclared tool would stall the new
  check on a permission prompt.

## [1.2.1] - 2026-07-15

### Fixed

- `references/titles.md` claimed a Markdown artifact's title could be set with a
  `title:` frontmatter key. It cannot. The renderer does not parse frontmatter —
  it emits the YAML as a visible heading of body text — and with no `<title>` in
  the document the title falls back to the source filename, extension included.
  Every title rule in the file was satisfiable and the title was still wrong, so
  the guidance now states the one mechanism that works: an HTML `<title>`.

- `session-artifact` published the recap `.md` directly, which made it the only
  skill subject to the above: recaps shipped titled `<slug>.md` with their
  frontmatter rendered on the page. It now publishes an HTML render carrying the
  `<title>`, while the `.md` under `{plansDirectory}/sessions/` stays the
  committed record and the home of `artifact-url:`. `diff-artifact`,
  `plan-artifact`, and `prompt-artifact` already published HTML and were never
  affected.

- `session-artifact`'s republish note implied `url` mattered only across
  sessions. Because the render lands on a new scratchpad path every run and a
  differing `file_path` always claims a new URL, `url` is required on every
  republish; the step now says so.

## [1.2.0] - 2026-07-15

### Added

- `prompt-artifact` — publishes prompts saved by `plan-agent:write-prompt` as
  claude.ai artifacts, in two modes. Default (single) publishes one prompt `.md`,
  resolved from an argument or picked via `AskUserQuestion`, and records the
  returned URL in the file's `artifact-url:` frontmatter. `--library` publishes
  one gallery covering every saved prompt — a card per prompt with type chips,
  `<details>` bodies, and `type` filter chips following the `plans-library`
  idiom — tracking its URL in a committed `$PROMPTS_DIR/.artifact-url` sidecar,
  since a gallery has no source `.md` to hold frontmatter. Both modes gate on
  `social-media-tools:security-scrub` (a finding in any prompt stops the whole
  library publish), render a verbatim copy-to-clipboard button per prompt, and
  fall back to `.claude/artifacts/` when publishing is unavailable. Titles follow
  `references/titles.md`, as the other three skills do.

## [1.1.0] - 2026-07-15

### Added

- `references/titles.md` — shared artifact-title rules, read by all three skills
  at the point each one sets or checks a title. Titles are bare subjects in
  sentence case, around 60 characters, derived from the artifact's content rather
  than the user's phrasing, stable across republishes, and never placeholders.
- `session-artifact` — the extractor now writes a `title:` frontmatter field, so
  a readable title survives even if the recap step does not refine it.

### Fixed

- `session-artifact` — the extractor derived its title by slicing the first user
  message to 80 characters, producing mid-word truncations such as
  "ensure that the plugins in the artifact-tool always gen". Titles are now
  trimmed on a word boundary. The `Session export` placeholder is gone: with no
  user turn, the title comes from the session's first turn instead.
- `session-artifact` — a first turn that is one oversized token (a URL, a path, a
  hash) is now kept whole rather than sliced mid-token. Width is a target; not
  cutting mid-word is the rule.

### Changed

- `diff-artifact`, `plan-artifact`, `session-artifact` — ad-hoc title guidance in
  each skill replaced by a pointer to `references/titles.md`. `plan-artifact`
  checks the subject of the title `plan-agent` generated and routes any fix
  through the `.md` spec, since hand-edits to plan HTML are overwritten on the
  next rebuild. The renderer's hardcoded `Plan: ` prefix is unreachable from the
  spec, so the check exempts it rather than demanding an impossible fix.

## [1.0.0] - 2026-07-14

### Added

- Initial release — three skills that publish work as live claude.ai artifacts.
- `diff-artifact` — builds an annotated diff walkthrough from a branch, commit
  range, or PR number: sticky changed-files sidebar with add/del counts,
  per-hunk margin annotations, severity labels (critical/warn/note) with a
  legend, and adaptive light/dark theming. Caps per-file annotations and
  summarizes the overflow to stay under the 16 MiB artifact cap.
- `session-artifact` — turns a session transcript into a reviewer-first recap
  (Summary, Decisions, Learnings, Files touched) saved under
  `{plansDirectory}/sessions/` and published as Markdown. Bundles its own
  `export_session.py` so the plugin has no cross-plugin install dependency.
- `plan-artifact` — publishes plan-agent HTML plans and republishes them to the
  same URL across sessions.
- Blocking `security-scrub` gate before every publish in `diff-artifact` and
  `session-artifact`; a `BLOCKED` verdict is a hard stop with no override.
  `diff-artifact` gates twice — once on the raw diff, then again on the rendered
  page, since annotations can quote file context the diff never contained.
- `diff-artifact` measures the rendered page against the 16 MiB cap and demotes
  files to summary rows until it fits — the file/hunk budget alone cannot bound
  a single very large hunk.
- `diff-artifact` keys its inbox copy by branch/PR/range rather than by date, so
  a republish the next day still finds the recorded URL, and writes that copy
  before publishing so the fallback exists even when publishing fails.
- `artifact-url:` write-back on every skill, so a later session can republish to
  the same claude.ai page instead of minting a new one — as frontmatter in the
  `session-artifact` recap and the `plan-artifact` plan spec, and as an HTML
  comment in the `diff-artifact` inbox page.
- Local-HTML fallback on every skill for when publishing is unavailable
  (no claude.ai login, or a Pro/Max account where sharing is restricted).
