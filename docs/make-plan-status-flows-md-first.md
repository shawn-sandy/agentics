# Make plan status and checkbox flows Markdown-first

> Completing a plan used to mean careful find-and-replace surgery on 84 KB of HTML. Now every status flip and checkbox tick is a one-line Markdown edit and the...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extend parseSpecMarkdown in scripts/lib/plan-spec.mjs to read `- [x]` criteria bullets, `[x]` step markers, and a `##...
- Teach plan-shell.mjs and build-plan-html.mjs to render progress state — checked inputs, completed step cards, initial...
- Sync the bundled renderer copies under kit/plugins/plan-agent/scripts/
- Rewrite finalize-plan SKILL.md around spec mode — frontmatter status, checkbox flips, step markers, Completion Report...
- Update implementation-plan SKILL.md Step 6 and Step 8 gates to flip state in the spec and re-render, and document the...
- Replace the byte-for-byte frozen-string test with behavioral progress assertions, bump plan-agent to 2.20.0, and upda...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | parse checkbox state and the Completion Report section in... | Modified |
| `scripts/lib/plan-shell.mjs` | progress-aware criteria/progress/completion blocks; froze... | Modified |
| `scripts/build-plan-html.mjs` | wire progress through rendering; derive cc1–cc3, all-comp... | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | spec mode edits the md and re-renders; legacy mode keeps ... | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 6 and Step 8 gates flip state in the spec | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | checkbox syntax and Completion Report section | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | criteria start as unchecked checkbox bullets | Modified |
| `kit/plugins/plan-agent/README.md` | md-first finalize-plan and pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | progress-state tests replace the byte-for-byte frozen-str... | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | pins the md/html argument hint and the spec-mode contract | Modified |

## How it works

Point `finalize-plan` and the implementation-plan status/checkbox gates at the Markdown spec — checkbox flips plus frontmatter edits plus a re-render via `build-plan-html.mjs` — and retire the byte-for-byte frozen-string contracts that HTML surgery depended on (Phase 3 of the plan-generation-from-markdown proposal).

Phases 1–2 made the Markdown spec the authored source of truth and shipped the deterministic renderer, but progress state still lived in the HTML only: finalize-plan did literal find/replace on the `todo` step chip and the report-empty sentence, and re-rendering a spec reset all progress. That kept three frozen strings pinned byte-for-byte and made every status edit an attribute-surgery exercise. Carrying state in the spec's checkbox syntax (as the proposal specifies) makes re-rendering lossless...

The implementation proceeded through these steps: Extend parseSpecMarkdown in scripts/lib/plan-spec.mjs to read `- [x]` criteria bullets, `[x]` step markers, and a `##...; Teach plan-shell.mjs and build-plan-html.mjs to render progress state — checked inputs, completed step cards, initial...; Sync the bundled renderer copies under kit/plugins/plan-agent/scripts/ Why: marketplace installs run the bundled copy...; Rewrite finalize-plan SKILL.md around spec mode — frontmatter status, checkbox flips, step markers, Completion Report...; Update implementation-plan SKILL.md Step 6 and Step 8 gates to flip state in the spec and re-render, and document the....

- Legacy plans without a sibling spec — still finalized via direct HTML edits by design; Phase 4 backfill will retire that path

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
