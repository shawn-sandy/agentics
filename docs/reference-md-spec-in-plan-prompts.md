# Reference the Markdown spec in plan prompts and render Next Steps again

> Points the implement, goal, and workflow prompts at the plan's Markdown spec instead of the rendered HTML, rewrites the copy-button to the markdown-first loop, and re-wires the Next Steps section rendering.

<!-- generated:start -->

**Status:** Shipped 2026-07-13  **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Updated `scripts/lib/plan-spec.mjs` — parses `## Next Steps` into a `nextSteps` key returned beside `sections` (bullet items → summary/desc/prompt, bullet-less content → prose); round-trip stays byte-stable.
- Updated `scripts/lib/plan-shell.mjs` — `nextStepsBlock` template, filtered sidebar nav entry for Next Steps, `plan-md` meta tag, Spec drawer row, markdown-first `buildImplementPrompt()` (reads spec, inserts `[x]` step markers, flips criteria to `- [x]`, sets `status: completed`, then re-renders).
- Updated `scripts/build-plan-html.mjs` — prompts use the spec path via new `mdPath` render option; CLI passes the real spec path; `.html` → `.md` fallback.
- Synced `kit/plugins/plan-agent/scripts/` copies byte-identical to repo-root sources.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` — `plan-md` meta tag, Spec drawer row, markdown-first copy-button JS.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` — Next Steps bullet/fence syntax.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` — Next Steps catalog entry.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` — spec-path prompts, `plan-md` meta, Next Steps cards documented.
- Updated `tests/plugins/test-build-plan-html.mjs` — spec-path prompt pins, `plan-md` meta, Next Steps parse/render coverage.
- Updated `tests/plugins/test-extractor-wiring.sh` — pins the new self-contained copy-button JS.
- Bumped plan-agent to `2.21.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `scripts/lib/plan-spec.mjs` | Plan spec parser | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer shell | Modified |
| `scripts/build-plan-html.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled spec parser | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled renderer shell | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled renderer | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Plan skeleton | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section catalog | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Renderer test | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Extractor wiring test | Modified |

## How it works

Since the markdown-first rewrite (plan-agent 2.18–2.20), the `.md` spec is the source of truth: all progress state is checkbox syntax in the spec. But the three derived prompts still pointed at the `.html` file — 10–20× the spec's size, mostly CSS/JS/SVG chrome — and the copy-button prompt told agents to "mark it done in the plan" by editing HTML `checked` attributes, which the markdown-first architecture forbids.

The fix changes all three prompts (`plan-implement`, `plan-goal`, `plan-workflow`) to reference the `.md` spec path. The spec is smaller and contains strictly more information (HTML is a lossy render of it). For the workflow prompt this saving multiplies: every subagent gets the file, so pointing at the spec saves tokens proportional to the subagent count.

The copy-button `buildImplementPrompt()` is rewritten to the markdown-first loop: read the spec → insert `[x]` step markers → flip criteria to `- [x]` → set `status: completed` → re-render the sibling HTML. This keeps the HTML plan checked and fully updated after an implementing session, while making the spec the single source the agent writes to.

The Next Steps section previously parsed by legacy hand-written plans was never re-wired after the markdown-first rewrite. The fix parses `## Next Steps` into a `nextSteps` key (outside `sections` so the round-trip stays byte-stable) and renders it as collapsible cards with paste-ready prompts and Copy-prompt buttons, matching the legacy markup's CSS/icon/JS that the shell never removed.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
