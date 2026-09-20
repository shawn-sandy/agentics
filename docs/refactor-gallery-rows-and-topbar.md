# Give the galleries the row layout and shell the prototype specified

> PR #503 gave the plans gallery the prototype's colours but left its card grid in place, so the shipped page still does not look like the design that was sign...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Add `tests/plugins/test-build-index-parity.mjs` asserting the three build-script copies (`docs/plans/build-index.sh`,...
- Rebuild the layout in `plans-gallery.html` — replace the `.gallery-grid` card rules with the prototype's row grid app...
- Give in-flight plans their band in the same template — style `.gallery-card[data-status="in-progress"]` with the prot...
- Change the card emitter in all three byte-identical build scripts to the row shape — `<span class="glyph" aria-hidden...
- Mirror the new card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md`.
- Bring the artifacts and prototypes galleries onto the row layout — update `build-artifacts-index.sh` to emit the row...
- Add the sticky topbar to `plans-gallery.html` and `prototypes-gallery.html` — the prototype's `.topbar` / `.topbar-in...
- Give the media library the same shell — replace the hardcoded dark palette in `kit/plugins/social-media-tools/templat...
- Add `tests/plugins/test-gallery-row-layout.mjs` asserting the objective end to end, then regenerate all four indexes.
- Bump `plan-agent` from 7.5.0 to 7.6.0 and `social-media-tools` from 2.20.1 to 2.21.0 in `.claude-plugin/marketplace.j...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | row layout, in-flight band, topbar; the view toggle deleted | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | shared token set, theme toggle, row layout, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | shared token set, theme toggle, topbar | Modified |
| `docs/plans/build-index.sh` | row card markup, step counts, cross-gallery counts | Modified |
| `scripts/build-plans-index.sh` | same edit, kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | same edit, kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | row card markup without a status glyph, cross-gallery counts | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | row card markup, cross-gallery counts | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | card heredoc kept in step with the build scripts | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | topbar variables in its gallery generator | Modified |
| `docs/plans/index.html` | regenerated | Modified |
| `docs/artifacts/index.html` | regenerated | Modified |
| `docs/prototypes/index.html` | regenerated | Modified |
| `docs/media/social/index.html` | regenerated | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | objective-verification test | Created |
| `tests/plugins/test-build-index-parity.mjs` | checksum guard for the three build-script copies | Created |
| `.claude-plugin/marketplace.json` | plan-agent 7.5.0 to 7.6.0, social-media-tools 2.20.1 to 2... | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.6.0 entry | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.21.0 entry | Modified |

## How it works

Replace the plans gallery's card grid with the row list, in-flight band, and sticky topbar specified by `docs/prototypes/plans-site-redesign.html`, and bring the artifacts, prototypes, and social galleries onto the same shell — without changing the `<a class="gallery-card">` splice unit that `scripts/merge-plans-index.mjs` depends on.

Commit `dd5c425` (PR #503) rebuilt the plan-document shell and adopted the prototype's design tokens in `kit/plugins/plan-agent/templates/plans-gallery.html`, but kept the gallery's layout. Its plan, `docs/plans/refactor-plan-and-gallery-design.md`, scoped step 8 to "Rebuild the **controls**" and listed only "search plus status segmented control, type and effort disclosure, client-side In-flight and month grouping" against that template. The layout was never attempted, so the shipped `docs/plans...

The implementation proceeded through these steps: Add `tests/plugins/test-build-index-parity.mjs` asserting the three build-script copies (`docs/plans/build-index.sh`,...; Rebuild the layout in `plans-gallery.html` — replace the `.gallery-grid` card rules with the prototype's row grid app...; Give in-flight plans their band in the same template — style `.gallery-card[data-status="in-progress"]` with the prot...; Change the card emitter in all three byte-identical build scripts to the row shape — `<span class="glyph" aria-hidden...; Mirror the new card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md`. Why: `tests/plugins/test-ind....

- Status is selected off `[data-status]`, not the prototype's `.s-completed` / `.s-in-progress` / `.s-todo` classes — `CARD_RE` matches the class attribute with its closing quote, so a second class in there makes every card invisible to the merge driver. The attribute selectors are equivalent in eff

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
