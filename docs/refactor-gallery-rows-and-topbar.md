# Give the galleries the row layout and shell the prototype specified

> Replace the plans gallery's card grid with the row list, in-flight band, and sticky topbar specified by the prototype, and bring the artifacts, prototypes, and social galleries onto the same shell.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Replaced `.gallery-grid` card rules with the prototype's row grid in `plans-gallery.html`; added `.glyph`, `.r-title`, `.r-meta`, `.r-date` and in-progress status colour rules; deleted `.view-toggle`, `.view-btn`, both toggle buttons, and the view-switching JavaScript.
- Added the in-flight band: `[data-status="in-progress"]` rows get a left border and step-progress bar drawn from `data-steps-done` / `data-steps-total`, with server-rendered `N / M steps` text that survives JavaScript being off.
- Updated the card emitter in all three byte-identical build scripts (`docs/plans/build-index.sh`, `scripts/build-plans-index.sh`, `kit/plugins/plan-agent/hooks/build-index.sh`) to the row shape; added step counting from plan HTML.
- Mirrored the new card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md`.
- Brought artifacts and prototypes galleries onto the row layout; replaced `prototypes-gallery.html`'s pre-503 token block (including `--subtle: #9ca3af` at 2.5:1 contrast) with the shared palette.
- Replaced the hardcoded dark palette in `social-media-tools/templates/gallery.html` with the shared token set, dark rules, theme toggle, and topbar.
- Added the sticky topbar to `plans-gallery.html` and `prototypes-gallery.html` with five tabs (Home, Plans, Prototypes, Artifacts, Social), per-collection counts read from disk, `aria-current="page"` on the active tab, counts sourced from the resolved `plansDirectory`.
- Shipped `tests/plugins/test-gallery-row-layout.mjs` and `tests/plugins/test-build-index-parity.mjs`; regenerated all four indexes; bumped plan-agent to `7.7.0` and social-media-tools to `2.21.0`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Row layout, in-flight band, topbar | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Shared token set, theme toggle, row layout, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Shared token set, theme toggle, topbar | Modified |
| `docs/plans/build-index.sh` | Row card markup, step counts | Modified |
| `scripts/build-plans-index.sh` | Same edit, byte-identical copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Same edit, byte-identical copy | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Row card markup without status glyph | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Row card markup | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card heredoc kept in step | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Objective-verification test | Created |
| `tests/plugins/test-build-index-parity.mjs` | Checksum guard for the three build-script copies | Created |

## How it works

PR #503 (`refactor-plan-and-gallery-design`) rebuilt the plan-document shell and adopted the prototype's design tokens, but kept the gallery's layout as a 2-up card grid. This plan closes that gap.

The in-flight step bar was enabled by data already present in every rendered plan HTML since PR #503: each plan carries one `class="step-card"` per step and `class="step-card completed"` on each done step. The build scripts count both to derive `done / total` with no new spec field, emitting them as `data-steps-done` / `data-steps-total` attributes. The bar itself is drawn client-side from these attributes; the `N / M steps` text is server-rendered so it remains readable with JavaScript off.

Rows are bare anchors laid out as grid items directly inside `#galleryGrid` rather than inside `<ul><li>` wrappers. The merge driver (`scripts/merge-plans-index.mjs:35`) splices over everything between the first and last card using `CARD_RE = /<a class="gallery-card"[\s\S]*?<\/a>/g`. A `<li>` tag between cards would be destroyed by the first concurrent merge and stay destroyed until the next regeneration, so no container element appears between cards.

The topbar counts come from the filesystem rather than from parsing sibling `index.html` files: the four generators run in arbitrary order and a parse would read whatever indexes happened to be stale. Each count is `ls *.html | grep -v index.html | wc -l` on the relevant directory. The Plans count reads from the resolved `plansDirectory` (from settings), not a hardcoded `docs/plans`, so a project that moves its plans directory gets the correct count and correct tab links.

`prototypes-gallery.html` still used `--subtle: #9ca3af`, which measures 2.5:1 on white — a live WCAG AA failure. The topbar required touching it anyway; the token block was replaced with the shared palette in the same change.

The media gallery keeps its image-card layout (rows do not suit thumbnails); only the shell changes — shared tokens, light mode, theme toggle, and the topbar with Social marked current.

A note from the completion report: the plan shipped as plan-agent 7.7.0, not 7.6.0 — PR #505 took 7.6.0 on main while this branch was open.

## How to use it

The row layout is delivered automatically on the next regeneration of any gallery index. Run `bash docs/plans/build-index.sh` to update `docs/plans/index.html`.

The sticky topbar links the five collection pages. Tab counts are computed from the filesystem at regeneration time and reflect whatever is on disk.

The theme toggle in every gallery is shared: a `plan-theme` preference stored on one gallery page is honoured by all four.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
- Prototype: docs/prototypes/plans-site-redesign.html
- Previous plan: [refactor-plan-and-gallery-design.md](refactor-plan-and-gallery-design.md)
