# Changelog


## v1.5.2 — 2026-08-14 — the measurement examples now actually run

### Fixed

- **The computed-style example was not valid JavaScript.** `getComputedStyle(el).color / .backgroundColor / .outlineColor`
  used `/` to mean "or", but parses as division followed by a property access —
  `SyntaxError: Unexpected token '.'`. In a step whose whole instruction is to
  paste raw tool output, an example that throws when pasted defeats the step.
  Rewritten as a real destructuring expression, fenced as `js`, with
  `getBoundingClientRect()` folded into the same object.
- **The `UNVERIFIED` condition nullified the static path added in 1.5.1.** It
  read "if you cannot reach a browser **or** resolve the values" — so a ratio
  correctly computed from resolved values with the arithmetic shown was still
  labelled unverified whenever no browser was around, which is every static
  file. Now requires *neither* to be available, the label names the actual
  reason, and it says outright that a resolved static calculation is verified.

## v1.5.1 — 2026-08-14 — wcag-check is not a contrast calculator

### Fixed

- **Step 4 named `wcag-check` as a way to obtain a measured ratio. It cannot
  produce one.** `scripts/check_wcag.py::_similar_lightness` averages RGB
  (`(r + g + b) // 3`) and returns a boolean for "both light or both dark",
  then emits *"Potential color contrast issue - verify 4.5:1 ratio"* — a prompt
  to go measure, phrased as a warning. It never resolves styles, never computes
  relative luminance, and never outputs a ratio, so the step demanding raw
  measurement output pointed at a tool that emits none. Step 4 now carries the
  WCAG relative-luminance formula to run under `Bash(python3 *)`, and says
  explicitly that `wcag-check` output must never be pasted as a measurement —
  its role is surfacing candidate pairs worth checking.
- Formula verified against reference values before shipping: 21.00:1 for
  black on white, 4.54:1 for `#767676` on white (the lightest passing grey),
  4.48:1 for `#777777` (the first failing one).

## v1.5.0 — 2026-08-14 — Contrast ratios get measured, not estimated

### Added

- **Review step 4, "Measured Values: Measure or Label."** Contrast ratios,
  computed sizes, and touch-target dimensions must now come from a tool run —
  computed styles via the browser MCP or Playwright, or `wcag-check` for a
  static file — with the raw output pasted into the finding before the
  conclusion. When no browser is reachable, the skill writes
  `UNVERIFIED — no browser` instead of substituting a source `grep`. Source CSS
  is not the rendered result: specificity, `color-mix()`, `light-dark()`,
  opacity, and blend modes all resolve at runtime, and two ratios this skill
  shipped were wrong for exactly that reason. Findings *without* a number
  (missing `alt`, unlabeled input, heading skip) remain genuine source
  readings and are unaffected.
- Steps renumbered: systematic review is now 5, severity 6, fixes 7, testing 8,
  summary 9. Table of contents follows.

### Fixed

- **`allowed-tools` was `Read` alone**, which made the skill structurally
  incapable of the verification it was asked to perform — it documents
  `wcag-check` as a shell command and `web_fetch` for live W3C guidelines while
  declaring neither, so both stalled on a permission prompt and the only
  reachable way to "verify contrast" was to eyeball a hex pair. Now declares
  `Grep`, `Glob`, `WebFetch`, `Bash(wcag-check *)`, `Bash(python3 *)`, and the
  `mcp__Claude_Browser__*` tools needed to read computed styles.

## v1.4.0 — 2026-08-02 — The checker command actually runs (this time)

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

- Both call sites — `skills/wcag-compliance-reviewer/SKILL.md` and the plugin
  `README.md` — now invoke `wcag-check <file>`.
- **v1.3.1 introduced this defect while claiming to fix it.** That release
  retargeted a cwd-relative path to
  `python3 "${CLAUDE_PLUGIN_ROOT}/skills/wcag-compliance-reviewer/scripts/check_wcag.py"`
  under the heading "The documented checker command actually runs". The path was
  correct; the spelling was fatal. It traded a command that worked from one
  directory for one that worked from none.

> **Upstream note:** `skills/wcag-compliance-reviewer/` is synced from
> [shawn-sandy/skills](https://github.com/shawn-sandy/skills), so the `SKILL.md`
> half of this fix will be reverted by the next sync unless the same change is
> made upstream. The `bin/wcag-check` wrapper and the plugin `README.md` sit
> outside `skills/` and survive a sync. **This mirroring is not done here** — it
> requires a commit to a repository outside this tree.

---
## v1.3.1 — 2026-08-02 — The documented checker command actually runs

### Fixed

- **`check_wcag.py`'s documented invocation could not work as written.** Both
  the skill and the README said `python scripts/check_wcag.py <file>`, which
  fails twice over: the path is cwd-relative, so it only resolved if you
  happened to be standing in the skill directory (the script actually lives at
  `skills/wcag-compliance-reviewer/scripts/check_wcag.py`), and `python` does
  not exist on a python3-only machine. Both call sites now use
  `python3 "${CLAUDE_PLUGIN_ROOT}/skills/wcag-compliance-reviewer/scripts/check_wcag.py"`,
  matching how every other shipped script in the kit is invoked. The script's
  own usage/help text was updated from `python` to `python3` to match.

> **Upstream note:** `skills/wcag-compliance-reviewer/` is synced from
> [shawn-sandy/skills](https://github.com/shawn-sandy/skills) (see v1.3.0), so
> the `SKILL.md` and `check_wcag.py` half of this fix will be reverted by the
> next sync unless the same change is made upstream. The plugin `README.md` sits
> outside `skills/` and is unaffected.

---

## v1.3.0 — 2026-07-26 — Skill content now canonical in shawn-sandy/skills

### Changed

- `skills/wcag-compliance-reviewer/` is now synced from the cross-platform
  [shawn-sandy/skills](https://github.com/shawn-sandy/skills) repository
  (Agent Skills format: adds `license: MIT` and author/version metadata).
  Edit the skill there, then re-sync; this copy is no longer the source of
  truth.

---

## v1.2.3 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/wcag-compliance-reviewer` path instead of an author-specific home directory.

---

## v1.2.2 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

All notable changes to this project will be documented in this file.

## [1.2.1] - 2026-05-07

### Changed

- Reordered `wcag-compliance-reviewer` skill description to start with "Use when..." for reliable auto-activation

## [1.2.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.1.0] - 2026-02-25

### Changed

- **Default standard upgraded from WCAG 2.1 to WCAG 2.2** across all plugin files
- `SKILL.md` — WCAG 2.2 is now the default review standard; 2.1 available on request
- `SKILL.md` — Systematic Review (Section 4) adds six new WCAG 2.2 AA criteria
- `SKILL.md` — Quick Reference Checklist includes WCAG 2.2 items
- `SKILL.md` — Section 4 Robust notes 4.1.1 Parsing as removed in WCAG 2.2
- `wcag-aa-guidelines.md` — corrected 2.4.11 from "Focus Appearance" to "Focus Not Obscured (Minimum)"
- `check_wcag.py` — focus outline removal upgraded from warning to error (2.4.7, 2.4.11)
- `common-violations.md` — added six new sections with before/after code examples for WCAG 2.2 criteria
- `testing-guide.md` — updated references to WCAG 2.2; manual testing checklist extended
- `README.md` — all WCAG 2.1 references updated to WCAG 2.2; new criteria added
- `plugin.json` and `marketplace.json` — version 1.1.0; descriptions and tags updated

### Added

- New WCAG 2.2 criteria in review process: Focus Not Obscured (2.4.11), Dragging Movements (2.5.7), Target Size (2.5.8), Consistent Help (3.2.6), Redundant Entry (3.3.7), Accessible Authentication (3.3.8)
- New violation examples: Target Size, Focus Not Obscured, Dragging Movements, Accessible Authentication, Redundant Entry, Consistent Help
- New Python checks: `target-size`, `dragging-movements` rules

## [1.0.1] - 2026-02-25

### Changed

- `SKILL.md` — replaced H1 title with H2 (frontmatter `name` serves as machine-readable title)
- `SKILL.md` — added 12-entry table of contents (file is 318 lines, over the >100-line threshold)
- `SKILL.md` — added `Follow these steps exactly.` to Review Process preamble (freedom level now explicit)

## [1.0.0] - 2026-02-24

### Added

- Initial release as a Claude Code plugin
- `wcag-compliance-reviewer` skill for reviewing HTML/CSS and React/TypeScript code against WCAG 2.1 Level AA standards
- `references/wcag-aa-guidelines.md` — complete WCAG 2.1 AA success criteria reference
- `references/common-violations.md` — before/after code examples for common violations
- `references/testing-guide.md` — automated testing tools and setup instructions
- `scripts/check_wcag.py` — static analysis script catching ~30% of accessibility issues
- Plugin manifest (`.claude-plugin/plugin.json`)
- Registered in agentics-kit marketplace
