# Give the galleries the row layout and shell the prototype specified

> PR #503 gave the plans gallery the prototype's colours but left its card grid in place, so the shipped page still does not look like the design that was signed off. This swaps the 2-up cards for the prototype's dense row list, adds an in-flight step-progress bar, and puts one sticky topbar across all four galleries.

<!-- generated:start -->

**Status:** Shipped 2026-08-01  **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Added `tests/plugins/test-build-index-parity.mjs` — a checksum guard asserting the three byte-identical build-script copies hash identically, catching any divergence before it ships.
- Rebuilt the layout in `plans-gallery.html` to the prototype's row grid (`grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem`), added status-colour rules, dropped `.view-toggle`, both toggle buttons, and the view-switching JavaScript outright.
- Added in-flight band styling — `border-left: 2px solid var(--signal)` on `[data-status="in-progress"]` cards, a JavaScript-drawn segmented `.bar` from `data-steps-done`/`data-steps-total`, and server-rendered `N / M steps` text that survives with JavaScript off.
- Changed the card emitter in all three byte-identical build scripts to the row shape: an `aria-hidden` glyph (`✓` / `○`) with a visually-hidden `.sr-only` status-text sibling, `.r-title`, `.r-meta` (type · effort), `.r-date`, and `data-steps-done`/`data-steps-total` on in-progress cards.
- Mirrored the new card heredoc into `plans-library/SKILL.md` to keep `test-index-card-count.mjs` green.
- Brought `build-artifacts-index.sh` and `build-prototypes-index.sh` onto the row layout; replaced the retired-token palette in `prototypes-gallery.html` (fixing its WCAG AA failure); unified `social-media-tools/templates/gallery.html` onto the shared token set and added light mode.
- Added the sticky topbar to `plans-gallery.html` and `prototypes-gallery.html`: five tabs (Home, Plans, Prototypes, Artifacts, Social), per-collection counts read from disk, `aria-current="page"` on the active tab, and the topbar reads the resolved `plansDirectory` rather than a fixed `docs/plans`.
- Added the same topbar to `social-media-tools/templates/gallery.html` and updated `media-library/SKILL.md` to substitute the count variables.
- Added `tests/plugins/test-gallery-row-layout.mjs` — objective-verification test for splice constraints, step-count derivation, accessibility requirements, and topbar correctness.
- Bumped plan-agent to 7.7.0 (planned as 7.6.0; PR #505 took that slot) and social-media-tools to 2.21.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Plans gallery template — row layout, in-flight band, topbar | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Prototypes gallery template — shared token set, theme toggle, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Social gallery template — shared token set, theme toggle, topbar | Modified |
| `docs/plans/build-index.sh` | Plans build script — row card markup, step counts | Modified |
| `scripts/build-plans-index.sh` | Repo build script — byte-identical to above | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Hook build script — byte-identical to above | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Artifacts build script — row card markup without status glyph | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Prototypes build script — row card markup | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Plans library skill — card heredoc kept in step | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Media library skill — topbar count variables | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Objective test — splice constraints, a11y, topbar | Created |
| `tests/plugins/test-build-index-parity.mjs` | Unit test — three build-script checksum guard | Created |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent → 7.7.0, social-media-tools → 2.21.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 7.7.0 entry | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Changelog — 2.21.0 entry | Modified |

## How it works

The card format for all gallery indexes is constrained by `scripts/merge-plans-index.mjs`, the git merge driver for generated index files. Its `CARD_RE` (`/<a class="gallery-card"[\s\S]*?<\/a>/g`) splices the union of matched cards over the region between the first and last card during concurrent merges. This means `<a class="gallery-card"` must remain the leading attribute pair on every card, no card may contain a nested `<a>`, and the counts the driver rewrites must follow `COUNT_RE`'s pattern (`<p>` or `<span>` immediately followed by digits and the word `items`, `plans`, or `artifacts`). The new row layout satisfies all three constraints: cards are bare anchors with no `<li>` wrapper and no nested links.

The in-flight step bar addresses a data-availability concern from the previous plan. `build-index.sh` already reads each plan's rendered HTML to extract meta tags; since plan-agent 7.5.0 every plan carries `class="step-card"` per step and `class="step-card completed"` on each done step. The new build script counts both (`class="step-card` with a following space or quote for the total; `class="step-card completed"` for done) and emits them as `data-steps-done`/`data-steps-total`. A small inline script draws the segmented bar client-side; the `N / M steps` text is server-rendered and remains visible with JavaScript disabled.

The status glyph uses `aria-hidden="true"` plus a visually-hidden `.sr-only` sibling (`<span class="sr-only">completed</span>` etc.) rather than an `aria-label` on the anchor. This is because `aria-label` on the anchor overrides the row's full text content, making the announced content diverge from what is visible.

The retired-token fix in `prototypes-gallery.html` removes `--subtle: #9ca3af`, which measures 2.5:1 on white — a live WCAG AA failure present since before PR #503. The social media gallery gains light mode for the first time; its previously hardcoded dark-only GitHub palette is replaced with the shared token set.

The topbar counts are read from the filesystem (counting `*.html` minus `index.html` in each collection directory) rather than from parsing sibling index files, because the four generators run in arbitrary order and a stale parse would produce wrong counts. All tab hrefs use `os.path.relpath` between each target index and the page being generated, so the topbar is correct regardless of where the gallery is served from. The plans count reads from the resolved `plansDirectory` rather than a fixed `docs/plans`.

The Completion Report implementation note: `status` is selected off `[data-status]` attributes rather than class names (`s-completed`, `s-in-progress`, `s-todo`) because `CARD_RE` matches the class attribute's closing quote — a second class in the attribute would make every card invisible to the merge driver.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
