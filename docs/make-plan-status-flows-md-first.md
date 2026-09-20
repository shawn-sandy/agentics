# Make plan status and checkbox flows Markdown-first

> Completing a plan used to mean careful find-and-replace surgery on 84 KB of HTML. Now every status flip and checkbox tick is a one-line Markdown edit and the...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extend parseSpecMarkdown in scripts/lib/plan-spec.mjs to read `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate progress return key
- Teach plan-shell.mjs and build-plan-html.mjs to render progress state — checked inputs, completed step cards, initial progress bar, derived completion checklist, and the report list
- Sync the bundled renderer copies under kit/plugins/plan-agent/scripts/
- Rewrite finalize-plan SKILL.md around spec mode — frontmatter status, checkbox flips, step markers, Completion Report, explicit re-render — with a legacy HTML fallback for plans without a spec
- Update implementation-plan SKILL.md Step 6 and Step 8 gates to flip state in the spec and re-render, and document the syntax in section-catalog.md and SKELETON.md
- Replace the byte-for-byte frozen-string test with behavioral progress assertions, bump plan-agent to 2.20.0, and update README and CHANGELOG

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | parse checkbox state and the Completion Report section into a progress key | Modified |
| `scripts/lib/plan-shell.mjs` | progress-aware criteria/progress/completion blocks; frozen strings demoted to internal | Modified |
| `scripts/build-plan-html.mjs` | wire progress through rendering; derive cc1–cc3, all-complete, report list | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | spec mode edits the md and re-renders; legacy mode keeps HTML edits | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 6 and Step 8 gates flip state in the spec | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | checkbox syntax and Completion Report section | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | criteria start as unchecked checkbox bullets | Modified |
| `kit/plugins/plan-agent/README.md` | md-first finalize-plan and pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | progress-state tests replace the byte-for-byte frozen-string pin | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | pins the md/html argument hint and the spec-mode contract | Modified |

## How it works

Point `finalize-plan` and the implementation-plan status/checkbox gates at the Markdown spec — checkbox flips plus frontmatter edits plus a re-render via `build-plan-html.mjs` — and retire the byte-for-byte frozen-string contracts that HTML surgery depended on (Phase 3 of the plan-generation-from-markdown proposal).

Phases 1–2 made the Markdown spec the authored source of truth and shipped the deterministic renderer, but progress state still lived in the HTML only: finalize-plan did literal find/replace on the `todo` step chip and the report-empty sentence, and re-rendering a spec reset all progress. That kept three frozen strings pinned byte-for-byte and made every status edit an attribute-surgery exercise. Carrying state in the spec's checkbox syntax (as the proposal specifies) makes re-rendering lossless and lets the renderer derive every completion representation mechanically.

The implementation proceeded through the following steps: Extend parseSpecMarkdown in scripts/lib/plan-spec.mjs to read `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate progress return key Why: completion state must travel in the spec without disturbing the content sections that the extract-digest-parse round-trip compares Verify: node tests/plugins/test-build-plan-html.mjs passes the new progress parsing cases and the existing round-trip property.; Teach plan-shell.mjs and build-plan-html.mjs to render progress state — checked inputs, completed step cards, initial progress bar, derived completion checklist, and the report list Why: the renderer must emit every representation finalize-plan used to write by hand so tools never touch the HTML Verify: rendering a spec with mixed checkbox state shows checked/unchecked inputs, a done chip, a 50% progress bar, and derived cc1–cc3 state.; Sync the bundled renderer copies under kit/plugins/plan-agent/scripts/ Why: marketplace installs run the bundled copy and a parity test pins it byte-identical to the repo-root sources Verify: the plugin-bundled-copies parity test passes.; Rewrite finalize-plan SKILL.md around spec mode — frontmatter status, checkbox flips, step markers, Completion Report, explicit re-render — with a legacy HTML fallback for plans without a spec Why: finalize-plan was the main frozen-string consumer; md-first editing retires the byte-for-byte find/replace contract Verify: tests/plugins/test-finalize-all-flag.sh passes, including the new spec-mode assertions.; Update implementation-plan SKILL.md Step 6 and Step 8 gates to flip state in the spec and re-render, and document the syntax in section-catalog.md and SKELETON.md Why: the authoring skill must stop writing HTML attributes now that re-rendering is lossless Verify: SKILL.md contains no instructions to edit checked attributes or step-card classes in the HTML.; Replace the byte-for-byte frozen-string test with behavioral progress assertions, bump plan-agent to 2.20.0, and update README and CHANGELOG Why: the contracts retire only when nothing reads them — tests pinning the bytes were the last reader Verify: the full plugin test suite passes and marketplace.json matches the CHANGELOG top entry..

- Legacy plans without a sibling spec — still finalized via direct HTML edits by design; Phase 4 backfill will retire that path

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
