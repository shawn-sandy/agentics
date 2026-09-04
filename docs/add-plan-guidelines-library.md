# Ship the guidelines library and markdown-first authoring for implementation-plan

> Phase 2 of guideline-driven plan generation: replaces the prescriptive 2,015-line HTML skeleton with a four-document guidelines library and Markdown-spec authoring rendered by the bundled `build-plan-html.mjs`.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created four guideline documents under `kit/plugins/plan-agent/skills/implementation-plan/guidelines/`:
  - `planning-principles.md` — falsifiable "done", what/why/verify per step, end-to-end verification
  - `section-catalog.md` — section menu with purpose, triggers, and exact spec syntax the renderer parses
  - `right-sizing.md` — minimal/standard/deep depth profiles and calibration table
  - `writing-style.md` — tone and plain-language rules
- Rewrote `implementation-plan` SKILL.md around explore → read guidelines → author spec → render → deliver, keeping Steps 0–8 orchestration intact
- Rewrote `reference/SKELETON.md` as a copyable spec starter using headings and step markers the renderer's parser accepts
- Updated `tests/plugins/test-goal-prompt.sh` and `tests/plugins/test-resources-section.sh` to match the new SKILL.md contract rather than retired placeholder syntax
- Bumped `plan-agent` to `2.19.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guideline — falsifiable done, what/why/verify | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guideline — section menu with spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guideline — depth profiles and calibration | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guideline — tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — rewritten around Markdown-spec pipeline | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter — copyable Markdown template the parser accepts | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — updated to check derived goal-prompt contract | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test — repointed to guidelines and spec skeleton | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — pipeline structure tree and component section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 2.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Plugin version registry — plan-agent bumped to `2.19.0` | Modified |

## How it works

Phase 1 (plan-agent 2.18.0, shipped earlier) delivered `build-plan-html.mjs`, a deterministic renderer that parses a small Markdown plan spec and emits the full styled, interactive, self-contained HTML plan with the exact DOM contract downstream tools depend on. The SKILL.md at that point still instructed Claude to copy the 2,015-line HTML skeleton and fill placeholders by hand — roughly 60k tokens of pure mechanics per plan run, plus high risk of introducing malformed HTML.

Phase 2 inverts the authoring flow. The guidelines library carries the judgment about what a good plan says. The Markdown spec carries the content for each plan. The renderer carries all presentation — CSS, JavaScript behaviors, SVG icons, meta tags, HTML escaping, and the sidebar nav. Claude owns the content; the renderer owns everything else.

The four guidelines documents are loaded progressively during plan authoring, not all up front. `planning-principles.md` is read before drafting any plan: it defines what makes "done" falsifiable, mandates a what/why/verify structure for every step, and requires end-to-end verification that walks the change as a user would. `section-catalog.md` is read when authoring: it lists every optional spec section, its purpose, the trigger conditions that earn it a place in the plan, and the exact syntax `parseSpecMarkdown()` accepts for that section. `right-sizing.md` is read after the objective is settled, before drafting: it provides minimal/standard/deep calibration profiles so the plan length matches the problem scope. `writing-style.md` is read during authoring for tone and plain-language guidance.

The rewritten SKILL.md preserves the full Steps 0–8 orchestration — issue ingestion, clarify, align, interview, tests, status gates, delivery, and the next-action menu — but changes the authoring medium. Where the previous SKILL.md told Claude to fill placeholders in a 2,015-line skeleton, the new version tells Claude to author a small Markdown spec guided by the library and render it with:

```bash
plan-agent-render <plan>.md -o <plan>.html
```

The `reference/SKELETON.md` was also rewritten. The old skeleton used humanized headings (e.g., "Context and Background") that the renderer's parser rejected, so copying it produced unparseable specs. The new skeleton uses the exact section names and step markers that `parseSpecMarkdown()` accepts, making copy-paste a safe starting point.

Two smoke tests required updating. `test-goal-prompt.sh` previously grepped SKILL.md for the literal string `{goal-prompt}` (a fill-in placeholder in the old skeleton). The new SKILL.md documents the derived goal-prompt computation contract, not a placeholder, so the grep pattern was updated. `test-resources-section.sh` previously searched for placeholder resource patterns; it was repointed to the guidelines directory and the spec skeleton.

The plan's own verification was self-referential: rendering `docs/plans/add-plan-guidelines-library.md` through `build-plan-html.mjs` was the acceptance test for the pipeline it shipped.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d7598ad` | 2026-08-17 | fix: screenshot output verification and plan Context completeness (#571) |
| `1b4f657` | 2026-08-06 | feat(plan-agent): red-green-verify plans (8.7.0) (#529) |
| `7ded3be` | 2026-08-05 | feat(plan-agent): phase checkpoints and a Decisions ledger for plan specs (8.6.0) (#528) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
- Proposal: `docs/proposals/plan-generation-from-markdown-guidelines.md`
- Related docs: `kit/plugins/plan-agent/skills/implementation-plan/guidelines/`, `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md`
