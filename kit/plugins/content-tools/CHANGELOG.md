# Changelog

## 1.1.0 — 2026-07-29

### Changed

- **`artifact-to-post` is now a 571-word core plus two new plugin-level
  references, down from 1,408 words in a single body.** They sit beside the
  existing `content-config.md` and `mdx-safety.md`, matching this plugin's
  established `$SKILL_DIR/../../references/` convention rather than adding a
  second per-skill one.
  - `references/source-resolution.md` — the Phase 1 source table, the claude.ai
    refusal text, and the "It skips nothing else." Markdown-source rule
  - `references/post-assembly.md` — Phases 4–10 in full
- The core keeps Phase 0's asset locating, the Phase 2 security-scrub gate
  verbatim (including its `write nothing and end the turn` stop), Phase 3's
  config contract, and every `## Phase N` heading in order.

Behaviour, `description:`, and `allowed-tools:` are unchanged.

## 1.0.2 — 2026-07-28

- `artifact-to-post` replaces its four-line `ExitPlanMode` preamble with the
  canonical one-line guard. Behaviour is unchanged.

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
