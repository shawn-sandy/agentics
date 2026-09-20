# Reference the markdown spec in plan prompts and render Next Steps again

> Implementing agents were being briefed with the 60–120 KB rendered HTML when the 5–10 KB markdown spec carries strictly more information — and the old copy-b...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Parse `## Next Steps` in parseSpecMarkdown into a `nextSteps` key returned beside `sections` (bullets → summary/desc/prompt items, bullet-less content → prose).
- Render the Next Steps section card (collapsible details items with Copy-prompt buttons, matching the legacy markup) plus a filtered sidebar nav entry.
- Point the implement, goal, and workflow prompts at the markdown spec path — new `mdPath` render option, CLI passes the real spec path, `.html` → `.md` fallback — and emit it as the `plan-md` meta tag plus a Spec drawer row.
- Rewrite the copy-button buildImplementPrompt() to walk the markdown-first loop: read the spec, insert `[x]` step markers, flip criteria to `- [x]`, set `status: completed`, then re-render the sibling HTML — never hand-edit it.
- Mirror the shell changes into reference/SKELETON.html and document the new behavior in SKELETON.md, section-catalog.md, and SKILL.md.
- Sync the byte-identical bundled copies under kit/plugins/plan-agent/scripts/, update the pinned tests, and bump plan-agent to 2.21.0 with a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | prompts use the spec path; plan-md meta; Next Steps card + nav filter; CLI passes the real spec path | Modified |
| `scripts/lib/plan-spec.mjs` | parse ## Next Steps into a nextSteps key beside sections (round-trip stays byte-stable) | Modified |
| `scripts/lib/plan-shell.mjs` | next-steps chrome + nav entry, nextStepsBlock template, plan-md meta tag, Spec drawer row, markdown-first buildImplementPrompt | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Next Steps catalog entry; removed from the markdown-only group | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | spec-path prompts, plan-md meta, Next Steps cards documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | spec-path prompt pins, plan-md meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | pins the new self-contained copy-button JS | Modified |

## How it works

Point the derived implement/goal/workflow prompts at the plan's markdown spec instead of the rendered HTML (cutting ~90% of the tokens an implementing agent spends reading the plan), keep the HTML plan fully updated — steps checked and marked complete — via explicit spec-edit + re-render instructions, and render the `## Next Steps` section into the HTML plan as legacy plans had it.

Since the markdown-first rewrite (2.18–2.20) the `.md` spec is the source of truth: all progress state is checkbox syntax in the spec, and hand-editing the rendered HTML is forbidden. But the three derived prompts still pointed at the `.html` file (10–20× the spec's size, mostly CSS/JS/SVG chrome), and the copy-button prompt told agents to read "a self-contained HTML file" and "mark it done in the plan" — inviting exactly the `checked`-attribute edits the architecture bans. The workflow prompt multiplied the waste by briefing every subagent with the HTML. Separately, the markdown-first renderer skipped `## Next Steps`, a section legacy hand-written plans rendered as collapsible cards with paste-ready prompts — the CSS, icon, and `copyPrompt()` JS never left the shell, only the parsing and rendering wiring was missing.

The implementation proceeded through the following steps: Parse `## Next Steps` in parseSpecMarkdown into a `nextSteps` key returned beside `sections` (bullets → summary/desc/prompt items, bullet-less content → prose). Why: the extract → digest → parse round trip over committed plans must stay byte-stable, so the section travels like `progress` does — outside `sections`. Verify: node tests/plugins/test-build-plan-html.mjs — the round-trip check still passes and the new Next Steps parse test passes.; Render the Next Steps section card (collapsible details items with Copy-prompt buttons, matching the legacy markup) plus a filtered sidebar nav entry. Why: legacy hand-written plans carried this section and the shell still ships its CSS, icon, and copyPrompt() JS — only wiring was missing. Verify: render a spec with a `## Next Steps` section and confirm the card, `<pre>` prompt, and nav entry appear; a spec without the section renders neither.; Point the implement, goal, and workflow prompts at the markdown spec path — new `mdPath` render option, CLI passes the real spec path, `.html` → `.md` fallback — and emit it as the `plan-md` meta tag plus a Spec drawer row. Why: the spec is 10–20× smaller than the rendered HTML and is where progress updates land; the workflow prompt briefs every subagent with the file, so the saving multiplies. Verify: rendered head carries `plan-implement`/`plan-goal`/`plan-workflow` contents ending in `.md` and a `plan-md` meta tag.; Rewrite the copy-button buildImplementPrompt() to walk the markdown-first loop: read the spec, insert `[x]` step markers, flip criteria to `- [x]`, set `status: completed`, then re-render the sibling HTML — never hand-edit it. Why: the old instructions predate markdown-first and invited HTML `checked`-attribute edits; the re-render step is what keeps the HTML plan checked and marked complete exactly as before. Verify: the rendered plan's JS contains the five-step instructions referencing the spec path, and tests/plugins/test-extractor-wiring.sh check 2 passes.; Mirror the shell changes into reference/SKELETON.html and document the new behavior in SKELETON.md, section-catalog.md, and SKILL.md. Why: the skeleton is the versioned template the shell was extracted from and the docs are what authors follow — drift between them and the renderer is a defect. Verify: bash tests/plugins/test-humanized-skeleton.sh and bash tests/plugins/test-goal-prompt.sh pass; section-catalog.md documents the Next Steps syntax.; Sync the byte-identical bundled copies under kit/plugins/plan-agent/scripts/, update the pinned tests, and bump plan-agent to 2.21.0 with a CHANGELOG entry. Why: a test enforces bundled-copy identity, the old prompt strings were pinned by tests, and marketplace versioning is manual per the repo rules. Verify: node tests/plugins/test-build-plan-html.mjs reports the byte-identity check passing and marketplace.json says 2.21.0..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
