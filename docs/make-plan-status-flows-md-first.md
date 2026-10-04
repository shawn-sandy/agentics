# Make plan status and checkbox flows Markdown-first

> Completing a plan used to mean careful find-and-replace surgery on 84 KB of HTML. Now every status flip and checkbox tick is a one-line Markdown edit and the renderer redraws the page — cheaper, safer, and impossible to get half-right.

<!-- generated:start -->

**Status:** Shipped 2026-07-12  **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `plan-spec.mjs`'s `parseSpecMarkdown` to read `- [x]` criteria bullets, `[x]` step markers, and `## Completion Report` sections into a `progress` return key, separate from the content sections (so re-rendering a spec is lossless).
- Taught `plan-shell.mjs` and `build-plan-html.mjs` to render every completion representation from the progress key: checked input elements, completed step cards with done chips, the initial progress bar, derived `cc1`–`cc3` criteria state, the all-complete flag, and the report list.
- Synced the bundled renderer copies under `kit/plugins/plan-agent/scripts/` byte-identically with the repo-root sources.
- Rewrote `finalize-plan/SKILL.md` around spec mode: edits frontmatter status, flips checkbox bullets, adds step markers, writes the Completion Report section, and re-renders — with a legacy HTML fallback for plans without a sibling spec.
- Updated `implementation-plan/SKILL.md` Steps 6 and 8 to flip state in the spec and re-render, removing all instructions to edit HTML attributes or step-card classes directly.
- Replaced byte-for-byte frozen-string tests in `test-build-plan-html.mjs` with behavioural progress assertions; bumped plan-agent to 2.20.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/lib/plan-spec.mjs` | Spec parser — progress key for checkbox state and Completion Report | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer — progress-aware criteria, progress bar, completion blocks | Modified |
| `scripts/build-plan-html.mjs` | Build script — wires progress through rendering | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize skill — spec-mode edits and re-render, legacy fallback | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Implementation skill — Steps 6 and 8 flip spec state | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section catalog — checkbox syntax and Completion Report | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton — criteria start as unchecked checkbox bullets | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README — md-first finalize and pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite — progress assertions replace frozen-string pins | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Finalize test — md/html hint and spec-mode contract | Modified |

## How it works

Phases 1–2 of the plan-generation-from-markdown proposal made the Markdown spec the authored source of truth and shipped a deterministic renderer. But progress state still lived only in the generated HTML: `finalize-plan` did literal `find` and `replace` on frozen strings like the `todo` step chip and the report-empty sentence, and re-rendering a spec reset all progress. Three frozen strings were pinned byte-for-byte and every status edit was an attribute-surgery exercise.

The fix carries progress state in the spec itself using standard Markdown checkbox syntax (`- [x]`, `- [ ]`) for criteria and step markers, plus a `## Completion Report` freeform section. `parseSpecMarkdown` in `plan-spec.mjs` now returns a `progress` key alongside the existing content sections, parsing all three syntaxes without touching the content key (so `extractSections`'s round-trip property is preserved).

`plan-shell.mjs` and `build-plan-html.mjs` use the progress key to derive every HTML representation that was previously hand-written: checked `<input>` elements for each criterion, the `step-card completed` class and done chip for completed steps, the progress bar's initial fill percentage, the `cc1`–`cc3` completion-checklist state, the all-complete flag, and the Completion Report list. Re-rendering is now lossless — nothing is lost when the HTML is regenerated from the spec.

`finalize-plan/SKILL.md` is the main former consumer of frozen strings. The spec-mode rewrite tells it to edit `status:` in frontmatter, flip `- [ ]` bullets to `- [x]`, add `[x]` step markers, write the `## Completion Report` section, and call `node scripts/build-plan-html.mjs` to regenerate. For plans that predate the Markdown spec (legacy plans), the old HTML-surgery path is kept as a fallback.

`implementation-plan/SKILL.md` Steps 6 and 8 previously contained instructions to set the `checked` attribute on criteria inputs and to add/remove `completed` classes on step cards in the HTML. Those instructions are removed; both steps now flip the equivalent checkbox in the spec and re-render.

The test suite change retires the three frozen-string constants from `plan-shell.mjs`'s exports and replaces the `byte-for-byte` pin in `test-build-plan-html.mjs` with behavioural assertions: mixed checkbox state drives all six derived completion representations without breaking the round-trip property.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
