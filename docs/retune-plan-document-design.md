# Retune the plan document design

> The 7.5.0 redesign left six competing hues and a monospaced headline on every plan page. This collapses the palette to one accent plus two semantic states and demotes `--mono` to code-only, re-rendering all committed plans without changing any extractable content.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Retuned the three token blocks in `scripts/lib/plan-shell.mjs` — light `:root`, `[data-theme="dark"]`, and `prefers-color-scheme` — collapsing six hues to one accent plus two semantic states, swapping warm cream `#fcfcfa` for a cool neutral ground that matches the violet accent.
- Demoted `--mono` to code and data only: title and section headings now use the sans stack; `--prose` redefined to `var(--ui)` so every existing prose rule keeps working; `code.md` reduced from fill-plus-border to a tint with no border, eliminating the barcode effect in code-dense plans.
- Retuned components exposed by the palette change: objective slab to a lead statement, Implement row off moss onto a neutral surface, header state ordered before controls via CSS `order` (no markup moves), step actions to emphasised body weight.
- Fixed three defects surfaced by screenshots: `word-break: break-all` splitting words mid-token in prompt rows, nested file-tree entries inheriting `font-weight: 600` from their directory row, six hardcoded mono-stack copies replaced with `var(--mono)`.
- Re-copied the edited shell to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` (byte-identical, held by test assertion).
- Applied the same token values to `kit/plugins/plan-agent/templates/plans-gallery.html` and `prototypes-gallery.html` so gallery and plan pages resolve the same `--paper` value.
- Re-rendered 87 committed plans via `scripts/rerender-plans.mjs` and rebuilt the gallery index; `extractSections()` over every re-rendered file matched its committed predecessor exactly.
- Bumped plan-agent to 9.1.0 in `.claude-plugin/marketplace.json`; added CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Canonical CSS shell; palette, type roles, component tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical copy of the canonical shell | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery index template; palette synced | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Prototypes gallery template; palette synced | Modified |
| `docs/plans/index.html` | Rebuilt gallery index | Generated |
| `.claude-plugin/marketplace.json` | plan-agent 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.1.0 entry | Modified |

## How it works

The 7.5.0 redesign fixed contrast and added dark palette, step rail, and Verify line visibility. What it left was a page that read as loud: a violet accent over warm cream `#fcfcfa` is the specific mismatch (cool accent, warm ground), and cream-plus-terracotta reads as machine-generated. Six competing hues — violet, moss, burnt-orange signal, red, and two purples — fought for the same eye without a dominant system.

Token names were kept exactly as-is; only values moved. The names are referenced by `tests/plugins/test-plan-redesign.mjs` and by 2,269 lines of rules, and renaming them would buy nothing the retune needed. `--purple` and `--wish-*` resolve to the accent family rather than being deleted, removing two hues from the page without touching any rule that uses them.

`--mono` carrying four jobs — 2.2rem headline, section headings, structural labels, and code — was the loudest problem. A monospaced headline makes the page read as a terminal dump. Meanwhile prose was Georgia, and the plan corpus carries 3,000+ inline code spans, producing a serif/mono collision on nearly every line of reading text. Demoting `--mono` to code-only with `--prose` redefined as `var(--ui)` eliminated both problems with zero rule deletions.

Three CSS fixes accompanied the palette work. `word-break: break-all` was splitting path tokens mid-character rather than at path boundaries. Nested file-tree entries were inheriting `font-weight: 600` from their parent directory row. Six hardcoded copies of the mono font stack could resolve to a different face than `var(--mono)` if the token were ever changed.

Both `scripts/lib/plan-shell.mjs` and its bundled copy at `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` are held byte-identical by a test assertion whose failure message is "drifted from scripts/…". Editing one side without re-copying both fails CI and ships a stale renderer to plugin installers. The galleries (`plans-gallery.html`, `prototypes-gallery.html`) carry their own palette copies; syncing them meant the gallery index and plan pages resolve the same `--paper` value.

The `scripts/rerender-plans.mjs` run re-rendered 87 of the ~100 committed plan files; 12 were unreadable because they are review documents predating the plan DOM contract. The `extractSections()` round-trip invariant — already asserted in `tests/plugins/test-build-plan-html.mjs` — confirmed no extractable content changed.

Two sibling galleries (`docs/artifacts/index.html`, `docs/media/social/index.html`) carry their own old palette copies and are out of scope; they belong to `artifact-tools` and `social-media-tools` respectively.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
