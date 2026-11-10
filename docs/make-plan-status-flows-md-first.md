# Make plan status and checkbox flows Markdown-first

> Points finalize-plan and implementation-plan's status and checkbox gates at the Markdown spec, replacing byte-for-byte frozen-string HTML surgery with spec edits and a lossless re-render via build-plan-html.mjs.

<!-- generated:start -->

**Status:** Shipped 2026-07-12 **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to read `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate `progress` return key, carrying state in the spec without disturbing the content sections the extract-digest-parse round-trip compares.
- Updated `plan-shell.mjs` and `build-plan-html.mjs` to render progress state — checked inputs, completed step cards, initial progress bar, derived `cc1`–`cc3` completion checklist, and the report list — from the spec rather than from frozen strings in the HTML.
- Synced all three bundled renderer copies under `kit/plugins/plan-agent/scripts/` byte-for-byte with the repo-root sources (marketplace installs run the bundled copy; a parity test pins the identity).
- Rewrote `finalize-plan/SKILL.md` around spec mode: edit frontmatter status, flip checkboxes and step markers in the Markdown, append the Completion Report section, and re-render; falls back to legacy HTML edits only for plans that have no sibling spec.
- Updated `implementation-plan/SKILL.md` Steps 6 and 8 to flip state in the spec and re-render, and documented the checkbox syntax in `section-catalog.md` and `SKELETON.md`.
- Replaced the byte-for-byte frozen-string test in `test-build-plan-html.mjs` with behavioral progress assertions, bumped plan-agent to 2.20.0, updated README and CHANGELOG.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Parses checkbox state and Completion Report into progress key | Modified |
| `scripts/lib/plan-shell.mjs` | Progress-aware criteria/progress/completion blocks; frozen strings demoted | Modified |
| `scripts/build-plan-html.mjs` | Wires progress through rendering; derives cc1–cc3, all-complete, report list | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Spec mode edits the Markdown and re-renders; legacy fallback for old plans | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 6 and Step 8 gates flip state in spec | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Checkbox syntax and Completion Report section documented | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Criteria start as unchecked checkbox bullets | Modified |
| `kit/plugins/plan-agent/README.md` | md-first finalize-plan and pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Progress-state tests replace frozen-string pin | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Pins the md/html argument hint and spec-mode contract | Modified |

## How it works

Phases 1 and 2 of the plan-generation-from-markdown proposal made the Markdown spec the authored source of truth and shipped a deterministic renderer, but progress state still lived only in the HTML. `finalize-plan` performed literal find/replace surgery on the `todo` step chip and the report-empty sentence — three frozen strings pinned byte-for-byte. Re-rendering a spec reset all progress, making every status edit an attribute-surgery exercise.

The fix is to carry completion state in the spec's checkbox syntax. `parseSpecMarkdown` now returns a `progress` key alongside the existing content sections; the key holds the checked/unchecked state of every criterion bullet, every step marker, and the full Completion Report section. The content sections themselves are unchanged, so the extract-digest-parse round-trip property holds.

`plan-shell.mjs` and `build-plan-html.mjs` consume the `progress` key to render every derived completion representation mechanically: checked `<input>` elements, the `completed` class on finished step cards, the initial progress bar width from `done / total`, the `cc1`–`cc3` completion checklist flags, the `all-complete` sentinel, and the Completion Report list. None of these representations are written by hand any more.

`finalize-plan/SKILL.md` now operates in two modes. When a sibling `.md` spec exists (the default for plans created after Phase 1), spec mode applies: edit frontmatter `status`, flip criterion and step checkbox syntax in the Markdown, append the `## Completion Report` section, then re-render via `build-plan-html.mjs`. Legacy HTML mode is preserved for plans without a spec, pending the Phase 4 backfill.

`implementation-plan/SKILL.md` Steps 6 and 8 — the gates that mark a step started and a step complete during plan execution — now flip the spec's checkbox syntax and re-render rather than editing HTML attributes and class names directly. The `section-catalog.md` and `SKELETON.md` files document the syntax so newly authored plans start with unchecked criterion bullets from the first render.

The frozen-string test was the last reader of the byte-for-byte contracts. Replacing it with behavioral progress assertions was the final step that retired those contracts completely.

## How to use it

`/plan-agent:finalize-plan` — marks a plan complete by editing the Markdown spec and re-rendering. For plans with a sibling spec, no HTML editing is needed; the renderer derives every completion representation from the checkbox state.

`/plan-agent:implementation-plan` — Steps 6 and 8 during plan execution now flip checkboxes in the spec rather than editing HTML attributes. No change to invocation syntax.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a5197d0` | 2026-07-12 | feat(plan-agent): markdown-first status and checkbox flows (Phase 3, 2.20.0) (#389) |
| `deb99af` | 2026-07-12 | feat(plan-agent): Markdown-spec-to-HTML plan renderer with round-trip tests (2.18.0) (#387) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
