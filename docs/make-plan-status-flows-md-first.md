# Make plan status and checkbox flows Markdown-first

> Completing a plan used to mean careful find-and-replace surgery on 84 KB of HTML; now every status flip and checkbox tick is a one-line Markdown edit and the renderer redraws the page.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [make-plan-status-flows-md-first](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to read `- [x]` criteria bullets, `[x]` step markers, and `## Completion Report` sections into a separate `progress` return key.
- Taught `plan-shell.mjs` and `build-plan-html.mjs` to derive every completion representation — checked inputs, completed step cards, progress bar, cc1–cc3, all-complete, and report list — directly from the spec's checkbox state.
- Synced the bundled renderer copies under `kit/plugins/plan-agent/scripts/` to be byte-identical to the repo-root sources.
- Rewrote `finalize-plan/SKILL.md` to edit the Markdown spec and re-render when a sibling spec exists, with a legacy HTML-edit fallback for plans without one.
- Updated `implementation-plan/SKILL.md` Steps 6 and 8 so progress state is carried in the spec's checkbox syntax rather than written as HTML attributes.
- Replaced the byte-for-byte frozen-string tests with behavioral progress assertions, bumped `plan-agent` to 2.20.0, and updated README and CHANGELOG.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/lib/plan-spec.mjs` | Spec parser — progress key | Modified |
| `scripts/lib/plan-shell.mjs` | HTML renderer — progress-aware blocks | Modified |
| `scripts/build-plan-html.mjs` | Build entry point | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize skill — spec mode | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Implementation skill | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Checkbox syntax docs | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Version manifest | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Progress-state tests | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Finalize contract test | Modified |

## How it works

**Progress key added to `parseSpecMarkdown`.** The parser now reads `- [x]` criteria bullets, `[x]` step markers at the top of each step block, and entries in a `## Completion Report` section into a separate `progress` object returned alongside the existing content sections. The content sections themselves are unchanged, so the extract-digest-parse round-trip still compares equal.

**Renderer derives all completion representations.** `plan-shell.mjs` was extended to accept `progress` and emit every piece of completion UI mechanically: checked/unchecked `<input>` elements on criteria, a `done` chip on completed step cards, an initial progress bar fill percentage, and the derived cc1–cc3 state for the completion checklist. The `build-plan-html.mjs` entry point wires `progress` through the rendering call. Re-rendering a spec with checkbox state is now lossless — no progress is lost on a re-render.

**Bundled copies synced.** `kit/plugins/plan-agent/scripts/` holds byte-identical copies of the repo-root renderer sources. Both `build-plan-html.mjs` and `plan-shell.mjs` were re-copied after every change, and the existing parity test (`tests/plugins/test-build-plan-html.mjs`) pins them.

**`finalize-plan` rewritten around spec mode.** When a sibling `.md` spec exists alongside the plan's `.html` file, `finalize-plan` now edits the Markdown — flipping the frontmatter `status:`, ticking criterion and step checkboxes, appending the Completion Report section — then re-renders via `build-plan-html.mjs`. Plans without a sibling spec continue to receive direct HTML edits (legacy mode), so no existing plan breaks.

**`implementation-plan` checkbox gates.** Steps 6 and 8 in `implementation-plan/SKILL.md` were updated to flip state in the spec and re-render, rather than writing `checked` attributes or step-card classes into the HTML. The `section-catalog.md` guideline and `SKELETON.md` skeleton document the checkbox syntax so new plans are authored correctly from the start.

**Frozen-string tests retired.** `tests/plugins/test-build-plan-html.mjs` previously pinned three literal strings byte-for-byte, making them the last reader of a contract that had already been superseded. Those assertions were replaced with behavioral tests that render a spec carrying mixed checkbox state and assert the resulting HTML reflects that state correctly. `tests/plugins/test-finalize-all-flag.sh` was extended to cover the new spec-mode contract and the legacy fallback.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first](plans/make-plan-status-flows-md-first.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 2.20.0 entry
