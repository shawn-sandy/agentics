# Reference the markdown spec in plan prompts and render Next Steps again

> Point derived implement/goal/workflow prompts at the plan's markdown spec instead of the rendered HTML, cutting ~90% of the tokens an implementing agent spends reading the plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [reference-md-spec-in-plan-prompts](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Derived implement, goal, and workflow prompts now reference the plan's `.md` spec path instead of the rendered `.html` file, reducing briefing size by 10–20×.
- A `plan-md` meta tag and a Spec row in the More-ways drawer expose the spec path from every rendered HTML plan.
- The copy-button `buildImplementPrompt()` was rewritten to the markdown-first loop: read spec, insert `[x]` markers, flip criteria, set `status: completed`, then re-render — never hand-edit the HTML.
- The `## Next Steps` section now renders into HTML plans as collapsible cards with paste-ready prompts and Copy-prompt buttons, matching the legacy hand-written plan layout.
- The extract → digest → parse → render → re-extract round trip over committed plans remains byte-stable.
- Bundled script copies under `kit/plugins/plan-agent/scripts/` are byte-identical to the root `scripts/` copies; plan-agent bumped to 2.21.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/build-plan-html.mjs` | Plan renderer — prompts use spec path; CLI passes real spec path | Modified |
| `scripts/lib/plan-spec.mjs` | Spec parser — `## Next Steps` parsed into `nextSteps` key | Modified |
| `scripts/lib/plan-shell.mjs` | HTML shell — next-steps chrome, nav entry, `plan-md` meta, Spec drawer row, markdown-first `buildImplementPrompt` | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Template — `plan-md` meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Template — Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Docs — Next Steps catalog entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Docs — spec-path prompts, `plan-md` meta, Next Steps cards | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Registry — plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Tests — spec-path prompt pins, `plan-md` meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Tests — pins the new self-contained copy-button JS | Modified |

## How it works

**Parsing Next Steps.** `scripts/lib/plan-spec.mjs` was extended so `parseSpecMarkdown` extracts the `## Next Steps` section into a dedicated `nextSteps` key returned alongside `sections`. Bullets become summary/description/prompt items; bullet-less content becomes prose. The section travels outside `sections` — the same pattern used for `progress` — so the extract → digest → parse round trip stays byte-stable over committed plans.

**Rendering Next Steps cards.** `scripts/lib/plan-shell.mjs` gains a `nextStepsBlock` template that emits collapsible `<details>` items with `<pre>` prompt blocks and Copy-prompt buttons, exactly matching the markup from legacy hand-written plans. A filtered sidebar nav entry appears only when the section is present; specs without `## Next Steps` render neither the card nor the nav entry. The CSS, icon, and `copyPrompt()` JS were already in the shell and just needed wiring.

**Pointing prompts at the spec.** The `build-plan-html.mjs` CLI passes the real `.md` spec path as a new `mdPath` render option. The three derived prompts — implement, goal, and workflow — are rewritten to reference this path instead of the `.html` file. A `<meta name="plan-md">` tag and a Spec row in the More-ways drawer expose the path in the rendered page, making it machine-readable for subagents that inspect the HTML head.

**Markdown-first copy-button.** The old `buildImplementPrompt()` predated markdown-first and instructed agents to edit the HTML directly — exactly the `checked`-attribute edits the architecture bans. The replacement walks five steps: read the spec, insert `[x]` step markers, flip acceptance criteria to `- [x]`, set `status: completed`, then re-render the sibling HTML via the bundled renderer. The HTML plan ends up checked and marked complete without any hand-editing.

**Skeleton and docs sync.** Changes were mirrored into `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` and `SKELETON.md`, keeping them in sync with the rendered output. `section-catalog.md` was updated to document the `## Next Steps` syntax, and `SKILL.md` was updated to describe spec-path prompts and the Next Steps card behavior.

**Bundled copy identity and version bump.** A test enforces that the three script files under `kit/plugins/plan-agent/scripts/` are byte-identical to the root `scripts/` copies. The old prompt strings pinned by tests were updated, and plan-agent was bumped to 2.21.0 with a matching CHANGELOG entry.

## How to use it

Render any plan spec that contains a `## Next Steps` section:

```bash
node scripts/build-plan-html.mjs docs/plans/<name>.md
```

The rendered HTML will include: a `plan-md` meta tag naming the spec path, a Spec row in the More-ways drawer, implement/goal/workflow meta tags ending in `.md` instead of `.html`, and collapsible Next Steps cards with Copy-prompt buttons.

The copy-button implement prompt in every plan now instructs the five-step markdown-first loop: read the spec, tick `[x]` markers, flip criteria, set `status: completed`, re-render.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts](plans/reference-md-spec-in-plan-prompts.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 2.21.0 entry
