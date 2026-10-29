# Reference the Markdown spec in plan prompts

> Points the implement, goal, and workflow prompts at the `.md` spec instead of the rendered `.html`, cutting prompt tokens by 10–20×, and renders a `## Next Steps` section into HTML as collapsible copy-prompt cards.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [reference-md-spec-in-plan-prompts](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Updated `implementation-plan/SKILL.md` to pass the `.md` spec path to the implement, goal, and workflow prompts instead of the `.html` file path
- Extended `scripts/lib/plan-spec.mjs` to parse the `## Next Steps` section into structured prompt objects
- Added Next Steps rendering to `scripts/lib/plan-shell.mjs`: a collapsible `<details>` section per step with a copy-prompt button wired to the clipboard API
- Updated `scripts/build-plan-html.mjs` to thread the parsed Next Steps into the shell
- Synced the bundled renderer copies in `kit/plugins/plan-agent/scripts/` byte-identical
- Updated `SKELETON.html` and `SKELETON.md` to include the `## Next Steps` section template
- Updated `section-catalog.md` with the Next Steps section spec
- Bumped plan-agent to 2.21.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — spec path references | Modified |
| `scripts/lib/plan-spec.mjs` | Script — Next Steps parsing | Modified |
| `scripts/lib/plan-shell.mjs` | Script — Next Steps rendering | Modified |
| `scripts/build-plan-html.mjs` | Script — Next Steps wiring | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Reference — Next Steps spec | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Template — Next Steps placeholder | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Template — Next Steps placeholder | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 2.21.0 | Modified |

## How it works

The implement, goal, and workflow prompts previously received the full rendered `.html` of the plan as context — an inflated representation that includes navigation chrome, step cards, progress bars, and inline styles. The Markdown spec carries the same information with none of the presentation overhead, cutting prompt token usage by 10–20× on a typical plan.

The change is mechanical in `SKILL.md`: every instruction that read `<plan-slug>.html` now reads `<plan-slug>.md`. The spec parser already handled all the structured sections; no new parsing was required for the prompt references themselves.

The `## Next Steps` section is a first-class addition to the plan format. Each Next Step is a fenced prompt block in the Markdown — the section heading gives the step name and the block body is the prompt text. The spec parser extracts these into a `nextSteps` array on the parsed plan object. The shell renders each item as a `<details>` card with a `<button>` that copies the prompt to the clipboard, giving implementers a one-click way to hand a next-step prompt to Claude without manually copying Markdown.

The copy button uses `navigator.clipboard.writeText` with a no-op fallback on `document.execCommand` for environments where the Clipboard API is gated. The card collapses by default to keep the plan page scannable; the `<summary>` shows the step title.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts](plans/reference-md-spec-in-plan-prompts.md)
