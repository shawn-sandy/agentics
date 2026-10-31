# Make plan status and checkbox flows Markdown-first

> Carries plan progress state in the Markdown spec's checkbox syntax so finalize-plan and implementation-plan no longer do HTML attribute surgery — a re-render now regenerates every completion representation from the source of truth.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [make-plan-status-flows-md-first](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `scripts/lib/plan-spec.mjs` to parse `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate `progress` key
- Taught `plan-shell.mjs` and `build-plan-html.mjs` to render progress state — checked inputs, completed step cards, initial progress bar, derived cc1–cc3, all-complete, and the report list — from spec data
- Synced the bundled renderer copies under `kit/plugins/plan-agent/scripts/` byte-identical
- Rewrote `finalize-plan/SKILL.md` to edit the Markdown spec and re-render when a sibling spec exists; legacy HTML fallback retained for plans without a spec
- Updated `implementation-plan/SKILL.md` Step 6 and Step 8 to flip state in the spec; removed all HTML attribute-editing instructions
- Replaced byte-for-byte frozen-string test assertions with behavioral progress assertions
- Bumped plan-agent to 2.20.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Script — progress state parsing | Modified |
| `scripts/lib/plan-shell.mjs` | Script — progress-aware rendering | Modified |
| `scripts/build-plan-html.mjs` | Script — progress wiring | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill — spec-mode editing | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — spec-mode gates | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Reference — checkbox syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Template — unchecked criteria | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Smoke test — progress assertions | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — spec-mode contract | Modified |

## How it works

Phases 1–2 of the plan-generation-from-markdown proposal made the Markdown spec the authored source of truth and shipped the deterministic renderer. Phase 3 (this plan) carries state. Before this change, progress lived only in the HTML: `finalize-plan` did literal find/replace on `todo` step chips and report-empty sentences, keeping three frozen strings pinned byte-for-byte. Re-rendering a spec reset all progress.

Carrying progress in the spec's `- [x]` checkbox syntax makes re-rendering lossless. The renderer reads the checked/unchecked state from the Markdown and derives every HTML representation — checked inputs, a completed step card, a progress bar percentage, the cc1–cc3 completion criteria, and the report list — mechanically. A frontmatter `status: completed` flip plus a checkbox tick is all it takes to complete a step; the HTML follows from the renderer.

`finalize-plan` now edits the Markdown spec when a sibling `.md` spec exists and re-renders. The legacy HTML-edit path survives as a fallback for plans created before the spec convention, so no existing plan breaks.

The frozen-string test assertions, which were the last readers of the old byte-for-byte contracts, are replaced with behavioral progress assertions: given a spec with mixed checkbox state, the rendered HTML shows the right checked/unchecked inputs, step card state, and progress bar.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first](plans/make-plan-status-flows-md-first.md)
