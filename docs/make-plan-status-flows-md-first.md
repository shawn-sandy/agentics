# Make plan status and checkbox flows Markdown-first

> Moves all plan progress state — checkbox flips, step markers, and the Completion Report — into the Markdown spec so that re-rendering is lossless and tools never need to perform byte-for-byte HTML surgery.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` to read `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate `progress` return key
- Updated `plan-shell.mjs` and `build-plan-html.mjs` to render progress state: checked inputs, completed step cards, initial progress bar, derived completion checklist, and the report list
- Synced all three changes byte-identically into the bundled copies under `kit/plugins/plan-agent/scripts/`
- Rewrote `finalize-plan/SKILL.md` around spec-mode editing: frontmatter status, checkbox flips, step markers, Completion Report, and explicit re-render; kept an HTML-edit fallback for legacy plans without a spec
- Updated `implementation-plan/SKILL.md` Steps 6 and 8 to flip state in the spec and re-render instead of writing HTML attributes directly
- Documented checkbox syntax and the Completion Report section in `section-catalog.md` and `SKELETON.md`
- Replaced the byte-for-byte frozen-string test assertions with behavioral progress assertions
- Bumped plan-agent to 2.20.0 and updated `README.md`, `CHANGELOG.md`, and `marketplace.json`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Parse checkbox state and Completion Report into progress key | Modified |
| `scripts/lib/plan-shell.mjs` | Progress-aware rendering; frozen strings demoted to internal | Modified |
| `scripts/build-plan-html.mjs` | Wire progress through rendering | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Spec-mode edits the md and re-renders; legacy fallback kept | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Steps 6 and 8 flip state in the spec | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Checkbox syntax and Completion Report section | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Criteria start as unchecked checkbox bullets | Modified |
| `kit/plugins/plan-agent/README.md` | Md-first finalize-plan and pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Progress-state tests replace frozen-string pin | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Pins md/html argument hint and spec-mode contract | Modified |

## How it works

Phases 1 and 2 of the plan-generation-from-markdown proposal made the Markdown spec the authored source of truth and shipped a deterministic renderer. However, progress state still lived only in the HTML: `finalize-plan` performed literal find/replace on the `todo` step chip and the report-empty sentence, and re-rendering a spec reset all progress. This kept three frozen strings pinned byte-for-byte and made every status edit an attribute-surgery exercise.

This refactor carries state in the spec's checkbox syntax instead. `parseSpecMarkdown` in `plan-spec.mjs` now returns a separate `progress` key alongside the existing content sections, containing checked/unchecked states for criteria bullets (`- [x]`), step markers (`[x]`), and a parsed `## Completion Report` section. The content sections object is unchanged, so the extract-digest-parse round-trip that validates spec fidelity continues to pass.

The renderer (`build-plan-html.mjs` + `plan-shell.mjs`) uses the progress key to derive every completion representation: checked checkbox inputs, completed step cards with a `done` chip, the initial progress bar percentage, the cc1–cc3 derived completion checklist states, and the report list. Tools previously wrote these representations by hand into the HTML; now they write a checkbox in the Markdown and call the renderer.

`finalize-plan/SKILL.md` was rewritten around this spec-mode path. When a sibling `.md` spec exists, the skill edits the spec (frontmatter `status:`, checkbox flips, `## Completion Report` entries) and re-renders rather than surgically modifying HTML attributes. The legacy HTML-edit path is kept as a fallback for plans that pre-date the spec format.

`implementation-plan/SKILL.md` Steps 6 and 8 were updated in parallel: the gates that previously instructed writing HTML `checked` attributes and step-card classes now instruct flipping the matching checkbox in the spec and calling the renderer. The skill no longer contains any HTML attribute-editing instructions.

The three exported frozen-string constants that `finalize-plan` previously consumed were demoted to internal symbols in `plan-shell.mjs`, and the tests that pinned them byte-for-byte were replaced with behavioral assertions: given a spec with mixed checkbox state, the rendered HTML must show the correct checked inputs, progress bar, and completion checklist.

## How to use it

Flip a criterion bullet in a plan spec from `- [ ]` to `- [x]` and run `node scripts/build-plan-html.mjs <spec-path>`. The rendered HTML's checkbox, progress bar, and completion checklist will reflect the change without any HTML editing.

To finalize a plan that has a sibling spec, invoke `/plan-agent:finalize-plan`. The skill will edit the spec's frontmatter and checkboxes and re-render; legacy plans without a spec still receive direct HTML edits.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
