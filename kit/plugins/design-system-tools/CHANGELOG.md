# Changelog

## 0.3.0 — 2026-10-30 — one plugin for the whole DESIGN.md workflow

### Added

- **`customize-design`** — the rebrand skill generalized from oncue-app's repo-only
  `.claude/skills/customize-design`. Step 0 discovers the token file, its dark scopes, the
  build command and the Markdown mirrors by grep and confirms them once; Path A rebrands every
  scope, Path B lays a brand sheet over a few sections. `scripts/contrast.mjs` reads SCSS
  `direction-*` mixins, plain CSS `:root` / dark scopes, or a DESIGN.md `colors:` map, and
  prints the same eight ratios the repo script printed (fixtures for both, under `fixtures/`).
  `scripts/scaffold.mjs` writes the seven-token direction in three scopes plus a starter
  `DESIGN.md` for a project with no tokens, darkening a too-light brand colour until it
  measures. Both scripts are dependency-free and tested with `node --test`.
- **`align-design-md`** — compares `DESIGN.md`'s frontmatter and prose with each component's
  style block, prints a drift table (including a control under a stated size floor, which it
  reports and never changes), and on confirmation rewrites the record and every mirror.
  `references/drift-checklist.md` fixes what counts as drift so two runs agree.

### Changed

- **`from-design-md`** carries the lessons of the 2026-10-30 OnCue publish: the static route
  always ships a one-line `components/bundle.js` namespace stub (the page renders no preview
  without it); `type.families` values are capped at 200 characters; heading ceilings are read
  from the rendered page's computed `font-size`, never from a regex over vendor CSS; the index
  is re-read before every publish after the first; `meta.note` records uncommitted sources;
  and the cover and previews are checked in both themes through colour-scheme emulation. Its
  `scripts/contrast.test.mjs` is ported from the user-level copy of the skill.
- The three skills run in the order align, customize, publish; `customize-design` hands off
  to `/design-system-tools:from-design-md` by name.

## v0.2.0 — 2026-10-26 — drop the bin/ wrapper for claude.ai compatibility

### Changed

- **Removed the top-level `bin/` directory.** claude.ai-hosted marketplaces
  refuse to install any plugin that ships one ("Plugin contains a top-level
  bin/ directory"), which left the plugin stuck at its last synced version.
  Claude Code now substitutes `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}`
  into skill, command, and agent markdown at load time (verified on 2.1.304),
  so the bare-name wrapper the Bash tool's old expansion guard required is
  obsolete: from-design-md now runs `node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs"`.

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
