# Reference the markdown spec in plan prompts and render Next Steps again

> Point the derived implement, goal, and workflow prompts at the plan's Markdown spec instead of the rendered HTML (cutting ~90% of the tokens an implementing agent spends reading the plan), and restore the Next Steps section that the markdown-first renderer had been skipping.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to parse `## Next Steps` into a `nextSteps` key returned beside `sections` (bullets → `summary`/`desc`/`prompt` items; bullet-less content → prose); the extract-digest-parse round-trip over committed plans stays byte-stable.
- Rendered the Next Steps section as collapsible `<details>` cards with Copy-prompt buttons and a filtered sidebar nav entry, matching the legacy markup; plans without the section render neither card nor nav entry.
- Added a `mdPath` render option and wired the CLI to pass the real spec path; the plan-implement, plan-goal, and plan-workflow meta tags and visible rows now reference the `.md` spec path (with a `.html` → `.md` fallback); added a `plan-md` meta tag and a Spec row in the More-ways drawer.
- Rewrote the copy-button `buildImplementPrompt()` to walk the markdown-first loop: read the spec, insert `[x]` step markers, flip criteria to `- [x]`, set `status: completed`, then re-render the sibling HTML — explicitly forbidding hand-edits to the HTML.
- Mirrored shell changes into `reference/SKELETON.html` and documented the new behaviour in `SKELETON.md`, `section-catalog.md`, and `SKILL.md`.
- Synced the byte-identical bundled copies under `kit/plugins/plan-agent/scripts/`; bumped plan-agent to 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | mdPath option; plan-md meta; Next Steps card + nav filter; CLI spec path | Modified |
| `scripts/lib/plan-spec.mjs` | `## Next Steps` parsed into nextSteps key | Modified |
| `scripts/lib/plan-shell.mjs` | nextStepsBlock template, plan-md meta tag, Spec drawer row, markdown-first buildImplementPrompt | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Next Steps catalog entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Spec-path prompts, plan-md meta, Next Steps cards documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Spec-path prompt pins, plan-md meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Pins the new self-contained copy-button JS | Modified |

## How it works

Since the markdown-first rewrite (plan-agent 2.18–2.20) the `.md` spec is the source of truth: progress state lives in checkbox syntax in the spec, and hand-editing the rendered HTML is forbidden. But the three derived prompts (implement, goal, workflow) still pointed at the `.html` file — 10–20× larger than the spec because of CSS, JavaScript, and SVG chrome. The workflow prompt multiplied the waste by briefing every subagent with the HTML.

The fix threads a `mdPath` option through `build-plan-html.mjs` and `plan-shell.mjs`. The CLI passes the real spec file path; the template functions substitute it into the `plan-implement`, `plan-goal`, and `plan-workflow` meta tag contents. A `.html` → `.md` fallback handles plans rendered without a known spec path.

The copy-button `buildImplementPrompt()` received the same update. The old function predated markdown-first and told agents to mark steps done in the HTML (inviting the `checked`-attribute edits the architecture forbids). The new function walks the five-step markdown-first loop: read the spec by path, insert `[x]` step markers at the completed steps, flip `- [ ]` criteria to `- [x]`, update `status:` to `completed`, then re-render the sibling HTML. The HTML ends up fully checked and marked complete without a direct HTML edit.

`## Next Steps` was already handled by the shell's CSS, icon, and `copyPrompt()` JavaScript — only the parsing and rendering wiring was missing. `parseSpecMarkdown` now extracts it into a `nextSteps` key returned outside `sections`, so it does not enter the content round-trip comparison. The renderer emits collapsible `<details>` items with `<pre>` prompt blocks and Copy-prompt buttons, matching what legacy hand-written plans had rendered.

The section-catalog and SKELETON were updated so authors know the syntax for `## Next Steps` bullets and the `copyPrompt()` behavior, keeping the template and the renderer consistent.

## How to use it

This change is transparent to plan authors. Rendered HTML plans automatically expose the correct spec path in the Implement, Goal, and Workflow prompts. Clicking the Copy button in any of those prompts gives an implementing agent instructions that correctly edit the spec and re-render.

To use Next Steps in a plan, add a `## Next Steps` section with bullet items whose sub-bullets carry a `prompt` code fence. The rendered plan shows a collapsible card per item with a Copy-prompt button.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
