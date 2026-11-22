# Reference the markdown spec in plan prompts

> Implementing agents were briefed with the 60–120 KB rendered HTML when the 5–10 KB markdown spec carries strictly more information — and the old copy-button prompt invited HTML hand-edits the markdown-first architecture forbids. After this change every derived prompt points at the spec, agents tick progress in the spec and re-render, and Next Steps cards render in the HTML again.

<!-- generated:start -->

**Status:** Shipped 2026-07-13 **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Updated `scripts/build-plan-html.mjs`: added `mdPath` render option; CLI passes the real spec path; derived prompts (`plan-implement`, `plan-goal`, `plan-workflow`) reference `.md` instead of `.html`; emits `plan-md` meta tag and a Spec drawer row.
- Updated `scripts/lib/plan-spec.mjs`: parses `## Next Steps` into a `nextSteps` key beside `sections`; round-trip byte-stable.
- Updated `scripts/lib/plan-shell.mjs`: `nextStepsBlock` template with collapsible cards and Copy-prompt buttons; filtered sidebar nav entry for Next Steps; markdown-first `buildImplementPrompt()` instructs reading the spec, inserting `[x]` markers, flipping criteria, setting `status: completed`, and re-rendering — never hand-editing the HTML.
- Synced bundled copies under `kit/plugins/plan-agent/scripts/`.
- Updated `implementation-plan/reference/SKELETON.html` and `SKELETON.md`, `section-catalog.md`, and `implementation-plan/SKILL.md`.
- Updated `tests/plugins/test-build-plan-html.mjs`: spec-path prompt pins, `plan-md` meta, Next Steps parse/render coverage.
- Updated `tests/plugins/test-extractor-wiring.sh`: pins the new self-contained copy-button JS.
- Bumped plan-agent to 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | mdPath, spec-path prompts, plan-md meta | Modified |
| `scripts/lib/plan-spec.mjs` | nextSteps parse | Modified |
| `scripts/lib/plan-shell.mjs` | nextStepsBlock, markdown-first copy-button | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | plan-md meta, Spec row, markdown-first JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Next Steps syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Next Steps catalog entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Spec-path prompts documented | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Spec-path pins, Next Steps coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Markdown-first JS pin | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 2.21.0 | Modified |

## How it works

**Spec-path prompts**: Every derived prompt (`plan-implement`, `plan-goal`, `plan-workflow`) now names the `.md` spec rather than the `.html` file. The spec is 10–20× smaller and contains more information (progress state lives in its checkboxes, not in the HTML). The workflow prompt briefs every subagent with the file, so the token saving multiplies.

**Markdown-first copy-button**: The `buildImplementPrompt()` function in the rendered HTML now walks the markdown-first loop: read the spec by path, insert `[x]` step markers, flip `- [x]` criteria, set `status: completed` in frontmatter, then re-render the sibling HTML. The old instructions invited `checked`-attribute edits on the HTML, which the markdown-first architecture forbids.

**Next Steps render**: `## Next Steps` is parsed into a `nextSteps` key (outside `sections`, to keep the round-trip byte-stable) and rendered as collapsible `<details>` cards with paste-ready prompts and Copy buttons. The sidebar nav gets a filtered entry for the section.

## How to use it

The changes are automatic — plans rendered from this version forward reference the spec in their prompts and render Next Steps cards when the section is present.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-13 | feat(plan-agent): reference md spec in plan prompts, render Next Steps (2.21.0) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
