# Make plan status and checkbox flows Markdown-first

> Point finalize-plan and implementation-plan's status and checkbox gates at the Markdown spec so every progress flip is a one-line edit followed by a re-render, retiring the byte-for-byte frozen-string HTML surgery they depended on.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to read `- [x]` criteria bullets, `[x]` step markers, and `## Completion Report` entries into a separate `progress` key returned alongside the existing content sections (round-trip remains byte-stable).
- Taught `plan-shell.mjs` and `build-plan-html.mjs` to render all progress representations — checked inputs, completed step cards, progress bar, derived `cc1`–`cc3` completion checklist, and the report list — from that `progress` key rather than from hand-written HTML.
- Rewrote `finalize-plan/SKILL.md` around spec-mode: it now edits the Markdown spec (frontmatter status, checkbox flips, step markers, Completion Report) and re-renders the sibling HTML, with a legacy HTML fallback for plans that have no `.md` spec.
- Updated `implementation-plan/SKILL.md` Steps 6 and 8 to flip state in the spec and re-render; removed all instructions to edit `checked` attributes or step-card classes in the HTML.
- Synced byte-identical bundled copies under `kit/plugins/plan-agent/scripts/`.
- Replaced the frozen-string test pins with behavioral progress assertions; bumped plan-agent to 2.20.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Spec parser — added `progress` key | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer — progress-aware markup | Modified |
| `scripts/build-plan-html.mjs` | Build entrypoint — wires progress through rendering | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Spec-mode finalization instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Steps 6 and 8 checkbox gate | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Checkbox syntax and Completion Report docs | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Criteria start as unchecked checkbox bullets | Modified |
| `kit/plugins/plan-agent/README.md` | Md-first finalize-plan and pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Progress-state tests replace frozen-string pins | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Pins md/html argument hint and spec-mode contract | Modified |

## How it works

Before this change, completion state lived only in the generated HTML. `finalize-plan` used literal find-and-replace on the `todo` step chip string and the empty-report sentence; re-rendering a spec from scratch reset all progress. This required three strings pinned byte-for-byte and made every status edit an attribute-surgery exercise — fragile and impossible to safely automate.

`parseSpecMarkdown` now reads checkbox syntax (`- [x]` / `- [ ]` on criteria bullets, `[x]` / `[ ]` on step markers) and the `## Completion Report` section into a `progress` key. This key is returned beside the existing `sections` object, which means it never enters the round-trip comparison and cannot break the extract-digest-parse cycle.

`plan-shell.mjs` and `build-plan-html.mjs` accept this `progress` key and use it to derive every completion representation that `finalize-plan` previously wrote by hand: checked/unchecked criterion inputs, the `done` step chip, the progress bar percentage, the `cc1`–`cc3` state for the completion checklist, and the items in the Completion Report list. Re-rendering a spec with mixed checkbox state now produces a fully correct HTML plan with no manual intervention.

`finalize-plan` was the main frozen-string consumer. Its SKILL.md was rewritten to operate in spec mode by default: it edits checkbox state and `status:` in the `.md` file, writes the Completion Report section, and re-renders the sibling `.html`. Plans that have no `.md` spec fall back to the old HTML-surgery path (still correct for legacy plans).

`implementation-plan`'s Steps 6 and 8 were updated to match: they now describe flipping checkbox syntax in the spec and re-rendering rather than setting `checked` attributes in the HTML. The frozen-string test assertions were replaced with behavioral checks that confirm the rendered HTML tracks the spec's checkbox state.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
