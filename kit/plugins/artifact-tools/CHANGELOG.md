# Changelog

All notable changes to the `artifact-tools` plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.11.0] - 2026-08-02

### Fixed

- **The documented invocation could never run — for anybody, at any permission
  level.** Claude Code's Bash tool refuses any command whose text contains
  `${VAR}` or `$VAR`, erroring with `Contains expansion` because it cannot
  statically resolve the expansion. The refusal fires *before* permission rules
  are consulted, so no `allowed-tools` entry, `tools:` grant, or permission rule
  can rescue it — a prefix rule like ``Bash(python3 "${CLAUDE_PLUGIN_ROOT}/...":*)``
  can never match, because the command is rejected before rule matching begins.
  `${CLAUDE_PLUGIN_ROOT}` compounds this: it is a config-file substitution for
  `hooks.json`, MCP/LSP, and monitor commands, and is not exported into the Bash
  tool's environment, so it would expand to empty even if the guard allowed it.
- **The fix is a `bin/` wrapper invoked by bare name.** Claude Code adds a
  plugin's `bin/` directory to the Bash tool's `PATH`, so a bundled script is
  callable as a bare command containing no `$` at all. The wrapper resolves its
  own location via `dirname "$0"` — legal, because the expansion guard inspects
  only the command text passed to the Bash tool, not what the shell then runs.
  A literal absolute path could not ship instead: the install path differs per
  machine.
- **Guarded by `tests/plugins/test-no-shell-expansion.sh`,** a repo-wide check
  that fails on any documented interpreter invocation carrying an expansion, on
  any bundled script invoked via a braced expansion in command position, on a
  wrapper that loses its exec bit or its target, and on `bin` falling off the
  `dist/` KEEP allowlist.

### Changed

- `session-artifact`: now `artifact-export-session <transcript.jsonl> <dir>`.
  The wrapper is name-prefixed because `social-media-tools` bundles a script
  with the identical basename (`export_session.py`); both plugins can be enabled
  at once, and `bin/` entries share one `PATH`.

## [1.10.1] - 2026-08-01

### Changed

- **`prompt-artifact` points at the renamed skill.** `plan-agent` renamed its
  `write-prompt` skill to `prompt` in 8.0.0, so the SKILL.md body, the empty-state
  message, and `references/prompt-resolution.md` now name `/plan-agent:prompt`.
  Prompt-directory resolution is unchanged — it still has to match that skill's
  precedence exactly or the two disagree about where prompts live.


## [1.10.0] - 2026-08-01

### Changed

- **The three recap commands say the workflow once instead of three times.**
  `eng-recap`, `team-recap`, and `product-doc` were three framings of one
  workflow: `eng-recap` and `team-recap` alone shared 168 identical lines, all
  three shared 68, and the set ran to 6,190 words. The shared workflow — source
  modes and PR gathering, the blocking `security-scrub` gate, the diff budget,
  page build, the SVG-inlining destination, and the republish-record protocol —
  now lives once in `references/recap-core.md`.
  - Each command is reduced to what actually differs: audience, section list,
    favicon, inbox stem, and republish key. They are 496, 496, and 419 words,
    each under the 500-word framing cap, and any two share at most 16 identical
    lines, down from 168.
  - The diff budget is opt-in. `eng-recap` opts in — it is the only recap that
    reads diff hunks; its two siblings keep reading commit bodies.
  - `product-doc` gains the page-build requirements (mermaid diagrams,
    theme-awareness, `overflow-x` containers) and the SVG-inlining destination
    it never had, because they now come from the shared workflow.
  - Republish keys are unchanged and still one per command: `eng-artifact-url:`,
    `team-artifact-url:`, `product-artifact-url:`, with `artifact-url:` still
    reserved for `session-artifact`. A shared key would silently republish one
    recap over another's URL, so `tests/plugins/test-recap-command-dedupe.sh`
    now asserts the assignments per file rather than counting key names across
    files.
  - `tests/plugins/test-artifact-tools.sh` checks 8, 8b, and 9 now assert the
    gh preflight, the PR gather block, and the 20-file diff cap against
    `references/recap-core.md` — the file that owns them after this change —
    and additionally assert that every command loads the core and that none
    keeps a second copy.

## [1.9.0] - 2026-07-29

### Changed

- **`diff-artifact` and `prompt-artifact` are now 566- and 583-word cores plus
  six new plugin-level references, down from 1,527 and 1,867 words in single
  bodies.** They sit beside the existing `titles.md`, matching this plugin's
  `${CLAUDE_PLUGIN_ROOT}/references/` convention.
  - `references/diff-sources.md` — mode table, default-branch resolution, and the
    PR-mode degradation script
  - `references/diff-page.md` — severity table, cap-and-summarize budget, page
    requirements, and the 16 MiB shrink loop
  - `references/diff-publishing.md` — durable-copy keying, publish and URL
    recording, failure fallback
  - `references/prompt-resolution.md` — mode table, the `PROMPTS_DIR` resolver,
    and single/library prompt resolution
  - `references/prompt-page.md` — page requirements, the six-value escaping
    table, and the copy button with its three failure modes
  - `references/prompt-publishing.md` — the URL-record table, the `.artifact-url`
    sidecar, and the fallback
- **Both blocking `security-scrub` gates stay in the cores**, ahead of the
  `select:Artifact` publish bootstrap — including `diff-artifact`'s second rescan
  of the rendered page in Step 5. So do both render-verification steps and every
  `## Step N — ` heading. `tests/plugins/test-remaining-skill-splits.sh` asserts
  the gate is in the *core* by line order, not merely somewhere under the plugin.

`description:` and `allowed-tools:` are unchanged for both skills, and behaviour
is unchanged. Word counts here and in the other four plugins' entries are measured
with a locale-independent counter; `wc -w` disagrees by up to 23 words on these
files because a standalone em dash is a word in a UTF-8 locale and not in C.

## [1.8.0] - 2026-07-29

### Added

- **A fifth `proposal` filter chip in `prompt-artifact`'s library gallery.** The
  skill globs `$PROMPTS_DIR/*.md` but hard-coded its chips to four literal
  types, so `plan-agent:build-proposal`'s saved proposal prompts would have
  rendered as cards no filter could reach. A type with no saved prompts still
  gets its chip — an absent chip reads as a broken filter, an empty one reads as
  an empty category.

### Changed

- **The frontmatter reader tolerates unknown keys.** Proposal prompts carry
  `status:`, `modified:`, and `generated-sha:`; `modified:` now renders beside
  `created:` in the metadata row and anything else is dropped silently. An
  unrecognized key must never abort the read or blank a card.
- **Long bodies scroll inside their own card.** Proposal prompts run roughly 3x
  longer than anything the gallery had rendered before; the existing `<details>`
  collapse handles the length, and an `overflow-x: auto` `<pre>` keeps a wide
  markdown table from widening the page at mobile width. No type-specific CSS.

## [1.7.3] - 2026-07-28

### Changed

- **Plan-mode guard reduced to one line** — the four publish skills each carried a
  four-line block explaining plan mode, why writes are mutations, and how to
  `ToolSearch` for the deferred `ExitPlanMode`. All four now carry the canonical
  one-line guard instead. The guard itself is unchanged in effect; only the
  explanation is gone.

## [1.7.2] - 2026-07-27

### Fixed

- All three PR-mode recap commands (`eng-recap`, `team-recap`, `product-doc`)
  resolve the target repository from the pull request itself rather than from
  the local checkout. Argument-less `gh repo view` means "view current repo", so
  a PR URL pointing at another repository paired a foreign PR number with the
  local owner/name and read review threads off the wrong repo — returning
  nothing, or an unrelated local PR that happened to share the number, either
  way corrupting Decisions and Open items. `gh pr view --json url` returns the
  PR's canonical URL, which is always on its base repo — the same repo its
  review threads live on — and `$NUM`, `$OWNER`, and `$REPO` now all derive from
  that one value. `gh pr view` exposes no `baseRepository` field, so the URL is
  the available source. Verified against a cross-repository PR URL from a
  checkout of a different repo.
- The `reviewThreads` query reports its own truncation. Both connections are
  bounded (100 threads, 20 comments each) and requested neither `pageInfo` nor
  cursors, so on a PR past either cap the commands treated a first page as the
  whole list and unresolved findings vanished silently from Open items / Known
  gaps / Review follow-ups. The query now returns `truncated` and per-thread
  `more_comments`, and all three commands must surface either in the recap —
  matching the "report what you did not read" rule `eng-recap`'s diff budget
  already carries, and the truncation check the `git-agent:merge` skill applies
  to the same connection.
- The bad-reference note now says the first `gh pr view` fails, not "the first
  line" — the first line of the block is the `PR=` assignment, which cannot
  fail.

### Added

- `tests/plugins/test-artifact-tools.sh` asserts the three PR-mode commands
  gather a pull request identically: commit bodies via `--json commits`, a
  `reviewThreads` query carrying `isResolved` and `hasNextPage`, truncation
  surfaced to the reader, owner/repo derived from the PR rather than
  argument-less `gh repo view`, and no `git fetch` / `git log` / `headRefName`
  in the executable lines. This is the guard the plugin was missing — the drift
  it now catches went unnoticed across two commands until a review found it.
  The check strips comment lines before asserting, because the comments
  legitimately name `headRefName` and `git fetch` while explaining why they are
  not used, and a substring check cannot tell an explanation from an
  instruction. Both new assertions were verified to fail against a
  deliberately reintroduced regression, not merely to pass as written.

## [1.7.1] - 2026-07-27

### Fixed

- `/artifact-tools:team-recap` and `/artifact-tools:product-doc` gather PR
  commit bodies through `gh pr view --json commits` instead of fetching
  `headRefName` and running `git log` across it. `headRefName` is only a branch
  name — for a fork-backed PR, a deleted head branch, or a PR URL pointing at
  another repository, that ref does not exist on this origin, so the fetch
  failed with stderr discarded and the `git log` produced nothing. Both commands
  say the commit bodies should lead the recap, and both were silently dropping
  them. The API call needs no fetch and no local ref.
- `/artifact-tools:team-recap` and `/artifact-tools:product-doc` read inline
  review threads with their resolution status via a `reviewThreads` GraphQL
  query. The previous `--json comments,reviews` payload carried neither: it
  holds top-level issue comments and each review's own state and body, not the
  inline thread comments and not whether anyone resolved them — so "Open items
  from unresolved review threads" (team-recap) and "Known gaps from unresolved
  review threads" (product-doc) had no source, and the instruction to file a
  resolved finding under Decisions instead was undecidable. Both now sort each
  thread on `isResolved` rather than guessing from comment text.

Both fixes were made in `/artifact-tools:eng-recap` (1.7.0) first; this
backports them so the three PR-mode commands gather identically.

## [1.7.0] - 2026-07-27

### Added

- `/artifact-tools:eng-recap` — the fourth framing over `session-artifact` (and
  the third recap *command*, after `product-doc` and `team-recap`), written
  for the engineer who has to touch the code next. Where `team-recap` leads every
  section with a plain-language statement and glosses every internal name so a
  non-engineer can follow, this one inverts that rule deliberately: it leads with
  the technical fact, assumes the vocabulary, carries no glossary, and spends the
  reclaimed space on detail. Eight sections — At a glance (stat strip),
  Architecture and code paths, Decisions, Tradeoffs and rejected options,
  Learnings, Tests and verification, Review follow-ups and tech debt, Files
  touched. Tradeoffs and Learnings are kept distinct on purpose: a tradeoff is a
  decision that was weighed, a learning is a dead end that was walked.
- `eng-recap` is the first recap command to read **diff hunks** in PR mode. Its
  siblings prefer commit bodies because those carry the *why*, which is all a
  stakeholder needs; an engineering reader is the one case where the hunks carry
  real signal — a changed signature, a new invariant, an error path. That read is
  capped at 20 files (matching `diff-artifact`'s budget so the plugin carries one
  number rather than two), falls back to `--name-only` beyond it, and must report
  how many files were summarized rather than read, so a partial read is never
  mistaken for a complete one. Commit bodies still lead for the *why*.
- Both modes are guarded by the same `gh` + GitHub-remote preflight the sibling
  commands use, falling back to session mode and naming the missing piece.
  Session mode files under the stem `eng-recap`, PR mode under `pr-<number>-eng`,
  and the republish URL lives under `eng-artifact-url:` — the fourth distinct key
  on the shared per-session record, alongside `artifact-url:`,
  `product-artifact-url:`, and `team-artifact-url:`.
- `tests/plugins/test-artifact-tools.sh` grew a check asserting `eng-recap`
  documents a numeric diff cap, a `--name-only` fallback past it, and the
  summarized-file report; its republish-key map and PR-mode command count now
  cover the new command.

## [1.6.0] - 2026-07-23

### Added

- `/artifact-tools:team-recap` accepts a pull request as its source — `#455`, a
  PR URL, or `--pr 455` — alongside the existing session modes, using the same
  contract `product-doc` already ships: a preflight that requires both `gh` and a
  GitHub remote and falls back to session mode (naming the missing piece) rather
  than emitting shell errors, then `gh pr view`, the changed-file list, the
  commit bodies, and the review discussion gathered into one brief. Commit bodies
  are preferred over the diff because they carry the *why*. Diagrams are drawn
  only where the diff shows structure or flow actually moved, and Learnings is
  expected to be empty — a PR records what shipped, never what was tried and
  abandoned. PR mode files under the stem `pr-<number>-recap` and keeps its
  republish URL in `pr-<number>.md` under `team-artifact-url:`, so re-running
  against the same PR updates the same page as it evolves. That record is shared
  with `product-doc`'s `product-artifact-url:`; the two keys sit side by side.

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

- `/artifact-tools:team-recap` files a gallery copy whose diagrams render and
  which still ships zero JavaScript, by inlining mermaid's *rendered SVG* rather
  than the runtime that produces it. Filing the published page fetched back also
  gives working diagrams, but only by committing the multi-megabyte minified
  mermaid library that publishing injects — which repo static analysis reads as
  first-party source; on this repo that produced eight high-severity CodeQL
  alerts, none of them in the recap. The command now documents the capture: strip
  the claude.ai `frame-runtime` block, serve the page over `127.0.0.1` (`file://`
  is blocked), read the rendered `svg` elements out of the browser pane and POST
  them back same-origin rather than through the transcript, then swap each
  `<pre class="mermaid">` block for its SVG and wrap the result into a standalone
  document. The captured diagram carries mermaid's baked-in palette and cannot
  follow the viewer's theme, so its container gets a fixed light card that reads
  correctly on both grounds. Falling back to plain-text diagram blocks is the
  documented behaviour when no browser is available; the fetch-back path is an
  opt-in with its costs stated first, including a scrub that reports MEDIUM
  matches from the library's grammar tables.

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
