# Changelog

## 1.0.1 — 2026-07-22

### Fixed

- **`artifact-to-post` asserted, as a technical fact, that `WebFetch` cannot read claude.ai artifact URLs.** It can — `claude.ai/code/artifact/<uuid>` URLs are fetchable through the session login. The skill still refuses URLs, because it works from a saved file, but the stated reason was wrong and the handoff undersold what `social-media-tools:save-artifact` does (it now fetches the URL directly and scrubs it). Reworded to hand off for that reason instead.

## 1.0.0 — 2026-07-20

- Initial release.
- `artifact-to-post` skill: converts a local HTML artifact, pasted HTML, or a
  Markdown file into a draft MDX/Markdown post for a static site.
- `references/mdx-safety.md`: the four-rung fidelity ladder and the MDX/JSX
  escaping rules.
- `references/content-config.md`: the `CONTENT.md` project config schema and the
  two target-repo prerequisite checks.
