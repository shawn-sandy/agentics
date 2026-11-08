# Retune the plan document design

> Reduce the plan document's presentation to one accent, two semantic states, cool neutrals, and two type roles — without changing a single byte of what `extractSections()` reads out of a rendered plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Retuned the three token blocks in `scripts/lib/plan-shell.mjs` (light `:root`, `[data-theme="dark"]`, and `prefers-color-scheme`) — collapsed six competing hues to one accent plus two states, replaced warm cream `#fcfcfa` with a cool neutral, resolved `--purple`/`--wish-*` to the accent family.
- Demoted `--mono` to code and data only: sans for title and section headings, `--prose` redefined to `var(--ui)`, `code.md` reduced to a tint with no border (eliminating the barcode effect on code-dense paragraphs).
- Retuned components exposed by the palette change — objective slab to lead statement, Implement row off moss and onto a neutral surface, header state before controls via CSS `order`, step actions to emphasised body weight.
- Fixed three defects surfaced by screenshots: `word-break: break-all` splitting words mid-token, nested file-tree entries inheriting `font-weight: 600`, and six hardcoded mono stack copies.
- Re-copied the edited shell to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` (enforced by byte-identity parity assertion in tests).
- Applied the same palette values to `plans-gallery.html` and `prototypes-gallery.html`.
- Re-rendered all 87 committed plans with `scripts/rerender-plans.mjs` and rebuilt the gallery index.
- Bumped plan-agent to 9.1.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Canonical HTML shell — palette tokens, type roles, component tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template — same palette so gallery does not clash with plan pages | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Prototypes gallery template — same palette | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 9.1.0 entry | Modified |
| `docs/plans/index.html` | Gallery index — rebuilt from updated gallery template | Modified |

## How it works

The 7.5.0 redesign added dark mode, a step rail, and contrast measurement, but left the page reading as loud rather than considered. Six hues competed — violet accent, moss, burnt-orange signal, red, and two purples — over a warm cream ground that belonged to none of them. The specific problem is that warm cream under cool violet is a known mismatch, and the mono stack was doing four jobs at once: 2.2rem headline, section headings, structural labels, and code.

The plan enforced a constraint-first approach: token *names* were left exactly as they are (they appear in 2,269 lines of tests and rules), only values moved. `--purple` and `--wish-*` were resolved to the accent family rather than deleted, removing two hues without touching any downstream rule. `--prose` was redefined to `var(--ui)` rather than removed.

Before editing any CSS, the WCAG maths in `test-plan-redesign.mjs` were run against the proposed light and dark token sets to verify all 26 measured color pairs cleared 4.5:1. The light and `prefers-color-scheme` dark blocks were then retuned in sync — the test asserts the two dark selectors define identical token names and values.

Type roles were simplified: sans for the title and section headings (eliminating the terminal-dump look), `code.md` reduced to a background tint with no border (eliminating the barcode effect in code-dense paragraphs). Component adjustments followed: the objective slab became a lead statement, the Implement row moved off moss, header state was placed before controls via CSS `order` without moving DOM nodes (the extractor and gallery both walk that markup).

Three defects found during screenshot review were fixed: `word-break: break-all` was replaced so long paths break at path boundaries; nested file-tree entries no longer inherit the directory row's `font-weight: 600`; and six hardcoded mono stack copies were consolidated to `var(--mono)`.

The re-render was necessary because ~100 plan files under `docs/plans/` are committed output — a shell change reaches them only when someone next writes that plan's spec. `scripts/rerender-plans.mjs` processed 87 of them (12 were review documents that do not satisfy the plan DOM contract and predated the 7.5.0 shell). `extractSections()` over each re-rendered file was verified to match its committed predecessor exactly — no semantic content changed.

> See [CHANGELOG v9.1.0](kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `b8cfa1f` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 9.1.0 entry
