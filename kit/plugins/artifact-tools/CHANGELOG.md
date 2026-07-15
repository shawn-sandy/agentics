# Changelog

All notable changes to the `artifact-tools` plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
