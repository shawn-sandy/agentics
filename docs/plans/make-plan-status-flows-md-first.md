---
status: completed
type: refactor
created: 2026-07-12
glance: Completing a plan used to mean careful find-and-replace surgery on 84 KB of HTML. Now every status flip and checkbox tick is a one-line Markdown edit and the renderer redraws the page — cheaper, safer, and impossible to get half-right.
---

# Plan: Make plan status and checkbox flows Markdown-first

## Objective

Point `finalize-plan` and the implementation-plan status/checkbox gates at the Markdown spec — checkbox flips plus frontmatter edits plus a re-render via `build-plan-html.mjs` — and retire the byte-for-byte frozen-string contracts that HTML surgery depended on (Phase 3 of the plan-generation-from-markdown proposal).

## Context

Phases 1–2 made the Markdown spec the authored source of truth and shipped the deterministic renderer, but progress state still lived in the HTML only: finalize-plan did literal find/replace on the `todo` step chip and the report-empty sentence, and re-rendering a spec reset all progress. That kept three frozen strings pinned byte-for-byte and made every status edit an attribute-surgery exercise. Carrying state in the spec's checkbox syntax (as the proposal specifies) makes re-rendering lossless and lets the renderer derive every completion representation mechanically.

## Files

- scripts/lib/plan-spec.mjs (modified) — parse checkbox state and the Completion Report section into a progress key
- scripts/lib/plan-shell.mjs (modified) — progress-aware criteria/progress/completion blocks; frozen strings demoted to internal
- scripts/build-plan-html.mjs (modified) — wire progress through rendering; derive cc1–cc3, all-complete, report list
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (modified) — byte-identical bundled copy
- kit/plugins/plan-agent/scripts/lib/plan-spec.mjs (modified) — byte-identical bundled copy
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (modified) — byte-identical bundled copy
- kit/plugins/plan-agent/skills/finalize-plan/SKILL.md (modified) — spec mode edits the md and re-renders; legacy mode keeps HTML edits
- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — Step 6 and Step 8 gates flip state in the spec
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md (modified) — checkbox syntax and Completion Report section
- kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md (modified) — criteria start as unchecked checkbox bullets
- kit/plugins/plan-agent/README.md (modified) — md-first finalize-plan and pipeline docs
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 2.20.0 entry
- .claude-plugin/marketplace.json (modified) — plan-agent 2.19.0 → 2.20.0
- tests/plugins/test-build-plan-html.mjs (modified) — progress-state tests replace the byte-for-byte frozen-string pin
- tests/plugins/test-finalize-all-flag.sh (modified) — pins the md/html argument hint and the spec-mode contract

## Steps

1. [x] Extend parseSpecMarkdown in scripts/lib/plan-spec.mjs to read `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate progress return key Why: completion state must travel in the spec without disturbing the content sections that the extract-digest-parse round-trip compares Verify: node tests/plugins/test-build-plan-html.mjs passes the new progress parsing cases and the existing round-trip property.
2. [x] Teach plan-shell.mjs and build-plan-html.mjs to render progress state — checked inputs, completed step cards, initial progress bar, derived completion checklist, and the report list Why: the renderer must emit every representation finalize-plan used to write by hand so tools never touch the HTML Verify: rendering a spec with mixed checkbox state shows checked/unchecked inputs, a done chip, a 50% progress bar, and derived cc1–cc3 state.
3. [x] Sync the bundled renderer copies under kit/plugins/plan-agent/scripts/ Why: marketplace installs run the bundled copy and a parity test pins it byte-identical to the repo-root sources Verify: the plugin-bundled-copies parity test passes.
4. [x] Rewrite finalize-plan SKILL.md around spec mode — frontmatter status, checkbox flips, step markers, Completion Report, explicit re-render — with a legacy HTML fallback for plans without a spec Why: finalize-plan was the main frozen-string consumer; md-first editing retires the byte-for-byte find/replace contract Verify: tests/plugins/test-finalize-all-flag.sh passes, including the new spec-mode assertions.
5. [x] Update implementation-plan SKILL.md Step 6 and Step 8 gates to flip state in the spec and re-render, and document the syntax in section-catalog.md and SKELETON.md Why: the authoring skill must stop writing HTML attributes now that re-rendering is lossless Verify: SKILL.md contains no instructions to edit checked attributes or step-card classes in the HTML.
6. [x] Replace the byte-for-byte frozen-string test with behavioral progress assertions, bump plan-agent to 2.20.0, and update README and CHANGELOG Why: the contracts retire only when nothing reads them — tests pinning the bytes were the last reader Verify: the full plugin test suite passes and marketplace.json matches the CHANGELOG top entry.

## Tests

Tier 1 — This plan changes application code
- Objective: a spec carrying checkbox state renders to HTML whose progress, step, criteria, and completion-checklist markup all reflect that state, and re-extracts to identical content sections. File: tests/plugins/test-build-plan-html.mjs; Type: smoke; Asserts: md-carried state drives every derived completion representation without breaking the round-trip; Run: node tests/plugins/test-build-plan-html.mjs
- Unit: parseSpecMarkdown progress parsing. File: tests/plugins/test-build-plan-html.mjs; Targets: parseSpecMarkdown; Key cases: mixed [x]/[ ] criteria, step markers, Completion Report entries, malformed report bullets
- Integration: finalize-plan skill contract. File: tests/plugins/test-finalize-all-flag.sh; Targets: finalize-plan SKILL.md; Key cases: md/html argument hint, spec-mode section, legacy fallback, version parity

## Acceptance Criteria

- [x] parseSpecMarkdown returns progress state (steps, criteria, report) without changing the content sections object
- [x] The renderer derives checked inputs, completed step cards, the initial progress bar, cc1–cc3, all-complete, and the report list from the spec
- [x] finalize-plan edits the Markdown spec and re-renders when a sibling spec exists, and only falls back to HTML edits for legacy plans
- [x] implementation-plan Step 6 and Step 8 gates contain no HTML attribute-editing instructions
- [x] No exported frozen-string constants remain in plan-shell.mjs and no test pins them byte-for-byte
- [x] All plugin test suites pass and plan-agent ships as 2.20.0

## Verification

Run node tests/plugins/test-build-plan-html.mjs, node tests/plugins/test-extract-plan-spec.mjs, node tests/plugins/test-backfill-digest.mjs, and bash tests/plugins/test-finalize-all-flag.sh — all green. Then exercise the flow end to end exactly as a tool would: flip a criterion bullet in this very spec, re-render with node scripts/build-plan-html.mjs, and confirm the rendered HTML's checkbox, progress bar, and completion checklist follow the Markdown.

## Completion Report

- Legacy plans without a sibling spec — still finalized via direct HTML edits by design; Phase 4 backfill will retire that path
