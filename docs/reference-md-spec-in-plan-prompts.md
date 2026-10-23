# Reference the markdown spec in plan prompts and render Next Steps again

> Points the derived implement/goal/workflow prompts at the plan's markdown spec instead of the rendered HTML, cutting ~90% of the tokens an implementing agent spends reading the plan, and restores the `## Next Steps` section as collapsible cards in rendered HTML plans.

<!-- generated:start -->

**Status:** Shipped 2026-07-13 **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Parsed `## Next Steps` in `parseSpecMarkdown` into a `nextSteps` key returned alongside `sections`, preserving the extract-digest-parse round-trip.
- Rendered Next Steps as collapsible `<details>` items with Copy-prompt buttons and a filtered sidebar nav entry.
- Pointed the implement, goal, and workflow prompts at the markdown spec path via a new `mdPath` render option; emitted the path as a `plan-md` meta tag and a Spec drawer row.
- Rewrote the copy-button `buildImplementPrompt()` to walk the markdown-first loop (read spec → insert `[x]` markers → flip criteria → set `status: completed` → re-render), forbidding HTML `checked`-attribute edits.
- Mirrored all changes into `reference/SKELETON.html`, `SKELETON.md`, `section-catalog.md`, `SKILL.md`, and the bundled `kit/plugins/plan-agent/scripts/` copies.
- Bumped `plan-agent` to `2.21.0`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Spec parser | Modified |
| `scripts/lib/plan-shell.mjs` | HTML renderer | Modified |
| `scripts/build-plan-html.mjs` | Build script | Modified |
| `kit/plugins/plan-agent/scripts/` (3 files) | Bundled copies | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Plan skeleton | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec template | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |

## How it works

The three derived prompts (implement, goal, workflow) previously pointed at the `.html` rendered plan — 60–120 KB of CSS, JS, and SVG that dwarfs the 5–10 KB spec. Switching them to the `.md` spec reduces the token budget a subagent spends reading the plan by ~90%, and multiplies that saving for the workflow prompt which briefs every parallel subagent.

The old copy-button prompt also invited `checked`-attribute edits on the HTML, which the markdown-first architecture forbids. The new `buildImplementPrompt()` describes the markdown-first completion loop explicitly: read the spec by path, insert step markers, flip criteria checkboxes, set `status: completed`, then run `node build-plan-html.mjs` — so the HTML ends up checked and marked complete from a re-render, never from hand-editing.

The `## Next Steps` section was a casualty of the markdown-first rewrite in 2.18: the CSS, icon, and `copyPrompt()` JS still existed in the shell, but the parsing and rendering wiring was never connected. This plan connected it, restoring collapsible Next Steps cards with paste-ready prompts that legacy hand-written plans always had.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
- Changelog: [plan-agent CHANGELOG v2.21.0](../kit/plugins/plan-agent/CHANGELOG.md)
