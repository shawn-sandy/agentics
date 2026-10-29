# Reference the Markdown Spec in Plan Prompts and Render Next Steps Again

> Implementing agents were being briefed with the 60–120 KB rendered HTML when the 5–10 KB markdown spec carries strictly more information — and the old copy-button prompt invited the HTML hand-edits the markdown-first architecture forbids. After this change every derived prompt points at the spec, agents tick progress in the spec and re-render, and the Next Steps follow-up cards render in the HTML again.

<!-- generated:start -->

**Status:** Shipped 2026-07-13  **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Rewired the implement, goal, and workflow prompts to reference the plan's `.md` spec path instead of the rendered HTML, cutting the token cost agents pay to read a plan by 90% (the HTML is 10–20× the spec's size, mostly CSS/JS/SVG chrome).
- Added a `plan-md` meta tag and a Spec row in the More-ways drawer so agents and users can always locate the canonical spec path from a rendered plan.
- Rewrote the copy-button `buildImplementPrompt()` to follow the markdown-first loop: read spec, insert `[x]` step markers, set `status: completed`, then re-render the sibling HTML — forbidding the `checked`-attribute hand-edits the old instructions invited.
- Implemented parsing and rendering of `## Next Steps` sections: the parser extracts them into a `nextSteps` key (beside `sections`), and the renderer produces collapsible cards with paste-ready prompts and Copy-prompt buttons, plus a sidebar nav entry — matching the format legacy hand-written plans had.
- Verified round-trip byte-stability: `extractSections(render(spec))` over committed plans still deep-equals the spec's sections.
- Synced byte-identical bundled copies under `kit/plugins/plan-agent/scripts/`, updated pinned tests, and bumped `plan-agent` to 2.21.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/build-plan-html.mjs` | Canonical renderer — prompts use spec path, CLI passes real spec path | Modified |
| `scripts/lib/plan-spec.mjs` | Spec parser — parse `## Next Steps` into `nextSteps` key | Modified |
| `scripts/lib/plan-shell.mjs` | HTML shell — next-steps chrome, nav entry, `plan-md` meta tag, Spec drawer row, markdown-first `buildImplementPrompt` | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Reference template — plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Skeleton spec — Next Steps bullet/fence syntax documented | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section catalog — Next Steps catalog entry, removed from markdown-only group | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill definition — spec-path prompts, plan-md meta, Next Steps cards documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite — spec-path prompt pins, plan-md meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Shell test — pins new self-contained copy-button JS | Modified |

## How it works

The markdown-first architecture treats the `.md` spec as the single source of truth for a plan's state: checkboxes, status, and progress all live in the spec, and the HTML is derived output. Before this change, however, the three derived prompts (`plan-implement`, `plan-goal`, `plan-workflow`) still pointed at the `.html` file. Every implementing agent therefore loaded the rendered HTML — which can be 60–120 KB of CSS, JavaScript, and SVG chrome — instead of the 5–10 KB spec that carries all the information. The workflow prompt compounded this by briefing every subagent with the HTML, multiplying the waste.

The fix adds an `mdPath` render option to `scripts/build-plan-html.mjs`. When the CLI renders a plan it passes the real spec path, and the renderer emits that path in the `plan-implement`, `plan-goal`, and `plan-workflow` meta tags as well as in a new `plan-md` meta tag and a Spec row in the More-ways drawer. Any existing HTML without an explicit spec path falls back to replacing `.html` with `.md`, so already-rendered plans are immediately improved without a re-render.

The copy-button `buildImplementPrompt()` function in `scripts/lib/plan-shell.mjs` was rewritten from scratch to follow the markdown-first update loop: read the spec by path, insert `[x]` markers on completed steps, flip criteria to `- [x]`, set `status: completed` in frontmatter, and then re-render the sibling HTML. The old instructions predated the markdown-first rewrite and told agents to "mark it done in the plan" while pointing at an HTML file — inviting exactly the `checked`-attribute edits the architecture bans.

`## Next Steps` section support required changes at two levels. In `scripts/lib/plan-spec.mjs`, `parseSpecMarkdown` was extended to extract a `nextSteps` key alongside the existing `sections` key; bullets are parsed into `{summary, desc, prompt}` items, and fenced-code blocks inside bullets become the paste-ready prompts. The extract-digest-parse round trip over committed plans stays byte-stable because `nextSteps` travels outside `sections`, the same way `progress` does. In `scripts/lib/plan-shell.mjs`, a `nextStepsBlock` template renders each item as a collapsible `<details>` element with a `<pre>` prompt block and a Copy-prompt button, exactly matching the markup legacy hand-written plans used. A matching sidebar nav entry appears only when the section is present.

The bundled copies under `kit/plugins/plan-agent/scripts/` are held byte-identical to their repo-root originals by a test assertion in `tests/plugins/test-build-plan-html.mjs`. This change syncs all three bundled files and updates the test's pinned strings for the new prompt format and the new extractor-wiring test.

## How to use it

When viewing a rendered plan, the More-ways drawer now shows a **Spec** row linking to the `.md` source. The **Implement** button's prompt instructs the implementing agent to read the spec, tick steps with `[x]`, set `status: completed`, and re-render — never to edit the HTML directly. If a plan spec includes a `## Next Steps` section, the rendered plan shows each follow-up as a collapsible card with a **Copy prompt** button that pastes a ready-to-use task description.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
