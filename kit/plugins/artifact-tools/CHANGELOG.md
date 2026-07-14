# Changelog

All notable changes to the `artifact-tools` plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
