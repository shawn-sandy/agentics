# Reference the markdown spec in plan prompts and render Next Steps again

> Implementing agents were being briefed with the 60–120 KB rendered HTML when the 5–10 KB markdown spec carries strictly more information — and the old copy-b...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Parse `## Next Steps` in parseSpecMarkdown into a `nextSteps` key returned beside `sections` (bullets → summary/desc/...
- Render the Next Steps section card (collapsible details items with Copy-prompt buttons, matching the legacy markup) p...
- Point the implement, goal, and workflow prompts at the markdown spec path — new `mdPath` render option, CLI passes th...
- Rewrite the copy-button buildImplementPrompt() to walk the markdown-first loop: read the spec, insert `[x]` step mark...
- Mirror the shell changes into reference/SKELETON.html and document the new behavior in SKELETON.md, section-catalog.m...
- Sync the byte-identical bundled copies under kit/plugins/plan-agent/scripts/, update the pinned tests, and bump plan-...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | prompts use the spec path; plan-md meta; Next Steps card ... | Modified |
| `scripts/lib/plan-spec.mjs` | parse ## Next Steps into a nextSteps key beside sections ... | Modified |
| `scripts/lib/plan-shell.mjs` | next-steps chrome + nav entry, nextStepsBlock template, p... | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Next Steps catalog entry; removed from the markdown-only ... | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | spec-path prompts, plan-md meta, Next Steps cards documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | spec-path prompt pins, plan-md meta, Next Steps parse/ren... | Modified |
| `tests/plugins/test-extractor-wiring.sh` | pins the new self-contained copy-button JS | Modified |

## How it works

Point the derived implement/goal/workflow prompts at the plan's markdown spec instead of the rendered HTML (cutting ~90% of the tokens an implementing agent spends reading the plan), keep the HTML plan fully updated — steps checked and marked complete — via explicit spec-edit + re-render instructions, and render the `## Next Steps` section into the HTML plan as legacy plans had it.

Since the markdown-first rewrite (2.18–2.20) the `.md` spec is the source of truth: all progress state is checkbox syntax in the spec, and hand-editing the rendered HTML is forbidden. But the three derived prompts still pointed at the `.html` file (10–20× the spec's size, mostly CSS/JS/SVG chrome), and the copy-button prompt told agents to read "a self-contained HTML file" and "mark it done in the plan" — inviting exactly the `checked`-attribute edits the architecture bans. The workflow prompt m...

The implementation proceeded through these steps: Parse `## Next Steps` in parseSpecMarkdown into a `nextSteps` key returned beside `sections` (bullets → summary/desc/...; Render the Next Steps section card (collapsible details items with Copy-prompt buttons, matching the legacy markup) p...; Point the implement, goal, and workflow prompts at the markdown spec path — new `mdPath` render option, CLI passes th...; Rewrite the copy-button buildImplementPrompt() to walk the markdown-first loop: read the spec, insert `[x]` step mark...; Mirror the shell changes into reference/SKELETON.html and document the new behavior in SKELETON.md, section-catalog.m....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
