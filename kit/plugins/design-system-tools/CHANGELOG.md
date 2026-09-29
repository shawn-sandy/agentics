# Changelog

## 0.1.0 — 2026-09-28

### Added

- **`from-design-md`** — publishes a repository's `DESIGN.md` and the stylesheets behind it as a
  claude.ai Design System artifact: `tokens.json` in every theme, a README brand book, static
  component previews and a cover. It defers to the Design System type's own `SKILL.md` and
  references for every file shape, and adds the DESIGN.md mapping. Re-syncs an existing system
  when given its URL. Verifies the publish against the remote file listing before reporting.
- **`scripts/contrast.mjs`** — WCAG 2 contrast for colour-token pairs in every theme of a
  `tokens.json`, following `{alias}` values and first-theme fallback, floored to two decimals.
  Invoked as the bare command `bin/design-system-contrast`, because the Bash tool refuses a
  command that contains `$VAR`.
