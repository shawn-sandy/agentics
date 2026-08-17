# Changelog

## 0.2.2 — 2026-08-17 — sync-rules verifies its copies

### Changed

- **`sync-rules` verifies every copy before declaring done**: a new step
  re-runs `diff -q` source-vs-destination per copied file and treats any
  mismatch as a loud failure, and a setup bullet tells the agent to resolve
  the plugin root to an absolute path first — a literal
  `${CLAUDE_PLUGIN_ROOT}` in a Bash call is refused by the tool, so the
  documented command otherwise never runs.

## 0.2.1 — 2026-08-14 — css-generator computes its contrast ratios

### Fixed

- **`agents/css-generator.md` wrote contrast ratios it never calculated.** The
  agent extracts colors from images — already approximations — then documented
  each pair "with contrast ratios," with nothing telling it to compute one.
  Pairing an approximate color with an eyeballed ratio compounds two guesses
  into a number a reader treats as fact, and a token doc claiming 4.6:1 on a
  pair that measures 3.9:1 is worse than one claiming nothing, because it ends
  the inquiry at the wrong answer. Ratios must now be computed from resolved
  sRGB values with the arithmetic shown, or marked `UNVERIFIED` — called out
  specifically for `color-mix()` and `light-dark()`, whose resolved value is
  never the authored one.

## 0.2.0 — 2026-07-17 — Scope both agents and make ts-commenter findable

### Changed

- **`agents/code-comments.md` renamed to `agents/ts-commenter.md`** to match its `name: ts-commenter` field. The registered agent name is unchanged — it was already `ts-commenter` — so invocation is unaffected; only the file was hard to locate.
- **`ts-commenter`'s description now leads with a trigger.** It was a capability blurb ("TypeScript documentation specialist that generates...") with no WHEN, so the agent would not reliably activate. It now states when to use it, which is the difference between an agent that exists and one that gets used.

### Fixed

- **`ts-commenter` declared no `tools:` at all**, so a JSDoc writer inherited Bash, WebFetch, and Agent. It is now scoped to `Read, Edit, Glob, Grep`.
- **`css-generator` declared `MultiEdit`, a tool that no longer exists in Claude Code** — a phantom grant that silently degraded any behaviour depending on it. Its tool list is now `Read, Write, Edit, Bash, WebFetch`, and it declares an explicit `model: sonnet` rather than leaving tier selection to inheritance.
- `skills/sync-rules/rules/typescript-jsdoc.md` referred to the agent as `code-comments`; it now names `ts-commenter`.

## 0.1.1 — 2026-07-16 — Trim sync-rules description to budget

### Fixed

- `skills/sync-rules/SKILL.md`: description reduced from 258 chars — the worst offender in the repo — to within the 200-char total and 80-char first-sentence budget.

## 0.1.0 — 2026-07-13

- Initial release.
- Agents: `ts-commenter` (JSDoc documentation), `css-generator` (design-token extraction).
- Skill: `sync-rules` — installs bundled team rules into `~/.claude/rules/` with per-file confirmation.
- Bundled rules: `plan-mode.md` (+ `reference/SKELETON.md`), `component-driven-ui.md`, `typescript-jsdoc.md`, `review-bot-loops.md`.
