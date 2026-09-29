---
status: in-progress
type: feature
created: 2026-09-28
repo-name: agentics
---

# Plan: Add the design-system-tools plugin

## Context

A Design System artifact on claude.ai ("Astro Kit",
<https://claude.ai/artifact/HKxyaqURmUX9WE4G8TiiW4>) was built by hand from
`shawn-sandy/astro-basics` `DESIGN.md` at `3641a47`: tokens in two themes, a README brand book,
six static component previews and a cover. The steps were captured as a loose user skill at
`~/.claude/skills/design-system-from-design-md/`. The user asked for it to be a plugin in this
marketplace instead.

The Design System artifact type ships its own `SKILL.md` and `artifact-type/reference/*.md` inside
every system. Those define every file shape and the publish call, so the plugin skill stays thin
and defers to them; it only covers the DESIGN.md mapping and the choices that made Astro Kit work.

## Objective

Ship `design-system-tools` 0.1.0 with one skill, `from-design-md`, registered in the marketplace,
documented like every other plugin, and covered by a test that runs under `tests/run-all.sh`.

## Steps

1. Create `kit/plugins/design-system-tools/` with `.claude-plugin/plugin.json`, `README.md`, `CHANGELOG.md`, `skills/from-design-md/SKILL.md`, `skills/from-design-md/scripts/contrast.mjs` and a `bin/design-system-contrast` wrapper. Why: skills in this repo ship inside a plugin, and the Bash tool refuses a `$VAR` path, so the script is reached by bare name through `bin/`. Verify: `claude --plugin-dir ./kit/plugins/design-system-tools` lists `design-system-tools:from-design-md`.
2. Register the plugin in `.claude-plugin/marketplace.json` at 0.1.0 with no `version` in `plugin.json`. Why: version lives only in the marketplace for relative-path plugins. Verify: the `marketplace` and `versions` stages of `bash scripts/verify.sh` pass.
3. Add `tests/plugins/test-design-system-tools.mjs` covering the contrast maths and the plugin wiring, and add the skill to `WRITE_HEAVY` in `tests/plugins/test-exitplanmode-guard.sh`. Why: the script is the one piece of real logic, and the guard must survive later cleanups. Verify: `node tests/plugins/test-design-system-tools.mjs` passes.
4. Update the root `README.md` counts, install lists, Plugins section and How-To table, regenerate the Plugin Reference Table with `node scripts/build-readme-table.mjs`, and add the plugin to `.claude/settings.json` `enabledPlugins`. Why: derived counts and lists go stale otherwise. Verify: `node scripts/build-readme-table.mjs --check` exits 0.
5. Add `docs/guides/how-to/design-system-tools.md`, its row in `docs/guides/how-to/README.md`, and an Unreleased entry in the root `CHANGELOG.md`. Why: every plugin has a how-to guide and a changelog line. Verify: the new guide's link resolves from both indexes.

## Tests

> Tier: 1 (code-touching)

### Objective-Verification Test

- **File:** `tests/plugins/test-design-system-tools.mjs`
- **Type:** smoke test
- **Asserts:** the marketplace registers `design-system-tools` with an `X.Y.Z` version and a source path that holds `skills/from-design-md/SKILL.md`, the skill carries the plan-mode guard verbatim, `plugin.json` has no `version`, and the documented `design-system-contrast` command runs by bare name from `bin/` on PATH.
- **Run:** `node tests/plugins/test-design-system-tools.mjs`

### Unit Tests

- **File:** `tests/plugins/test-design-system-tools.mjs`
- **Targets:** `resolve()` and `ratio()` in `skills/from-design-md/scripts/contrast.mjs`
- **Key cases:** black on white is 21:1 in hex and `rgb()`; aliases resolve per theme; a missing theme falls back to the first; a 4.478 ratio floors to 4.47; circular aliases, unknown tokens and translucent colours throw.

## Acceptance Criteria

- [ ] `/plugin install design-system-tools@agentics-kit` resolves to a plugin whose only skill is `from-design-md`.
- [ ] The skill's description is at most 200 characters with a first sentence of at most 80.
- [ ] `bash scripts/verify.sh` exits 0.
- [ ] No count in `README.md` or `docs/guides/how-to/README.md` still says 11 plugins or 66 skills.

## Verification

Run `bash scripts/verify.sh` from the repo root and confirm every stage passes or reports a named
skip. Then load the plugin with `claude --plugin-dir ./kit/plugins/design-system-tools` and confirm
the skill is listed.

## Next Steps

- Run the skill end to end:
  ```text
  With design-system-tools installed, run /design-system-tools:from-design-md on
  ~/repos/astro-basics. It should create a new Design System artifact from DESIGN.md and the SCSS
  tokens, publish it, verify the published file list, and report what did not come across. Compare
  the result with https://claude.ai/artifact/HKxyaqURmUX9WE4G8TiiW4 and note differences.
  ```
