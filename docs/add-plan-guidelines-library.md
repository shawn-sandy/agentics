# Ship the Guidelines Library and Markdown-First Authoring for Implementation Plans

> Plan authors stop hand-typing 85 KB of HTML — the agent writes a small markdown spec guided by a judgment-based guidelines library, and a bundled script renders the styled interactive plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Introduced a four-document guidelines library under `skills/implementation-plan/guidelines/` covering planning principles, section catalog, right-sizing profiles, and writing style — replacing the prescriptive 2,015-line HTML skeleton with judgment-based guidance the agent loads on demand.
- Rewrote `skills/implementation-plan/SKILL.md` around a markdown-spec pipeline: the agent now explores, reads guidelines, authors a small spec, and renders it via `build-plan-html.mjs`, eliminating hand-filled placeholder prose from every plan run.
- Updated `reference/SKELETON.md` to serve as a copyable spec starter whose headings and step markers exactly match what `parseSpecMarkdown()` accepts, preventing parse failures from the prior humanized-heading skeleton.
- Updated smoke tests (`test-goal-prompt.sh`, `test-resources-section.sh`) to assert against the new pipeline contracts rather than retired placeholder strings, and bumped plan-agent to 2.19.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guideline — falsifiable done, scope discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guideline — section menu with exact spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guideline — depth profiles and calibration table | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guideline — tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Core skill — rewritten around markdown pipeline | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter — parser-compatible headings | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — SKILL.md goal-prompt contract | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test — resources assertion | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — updated structure tree | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 2.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent at 2.19.0 | Modified |

## How it works

Before this change, `implementation-plan/SKILL.md` instructed the agent to copy a 2,015-line HTML skeleton and fill roughly 60k tokens of placeholders by hand on every plan run. The skeleton contained all presentation logic, so every plan consumed context on mechanics rather than content.

Phase 2 inverts this. Four guideline documents under `guidelines/` now carry the judgment the agent needs: `planning-principles.md` defines falsifiable acceptance criteria and scope discipline; `section-catalog.md` provides a menu of available plan sections with the exact spec syntax `parseSpecMarkdown()` accepts; `right-sizing.md` offers depth profiles keyed to plan size; and `writing-style.md` carries tone and plain-language rules. These files are loaded via progressive disclosure — only what the plan needs, not everything at once.

`SKILL.md` now instructs the agent to author a small markdown spec and render it with the bundled `build-plan-html.mjs` script. The five-step pipeline (explore, read guidelines, author spec, render, deliver) replaces the skeleton-copying flow while preserving the Step 0–8 orchestration: issue ingestion, clarify, align, interview, tests, status gates, delivery, and the next-action menu are unchanged.

`reference/SKELETON.md` was rewritten as a copyable starter whose headings and `N. [x] step` markers parse cleanly. The old skeleton used humanized headings (`## What we're building`, etc.) that `parseSpecMarkdown()` rejected, so anyone who copied it received an unparseable spec. The new skeleton's headings match `section-catalog.md` exactly.

The smoke tests pinned retired placeholder prose (`{goal-prompt}`, resource placeholders) that no longer appears in SKILL.md. Both tests were updated to assert the new contracts: `test-goal-prompt.sh` checks the derived goal-prompt contract, and `test-resources-section.sh` asserts the guidelines and skeleton are referenced. The version bump to 2.19.0 satisfies the CI guard that fails any plugin-touching PR whose version does not exceed the base branch.

## How to use it

Run `/plan-agent:implementation-plan` as before. The agent will load the appropriate guidelines for the plan's size and type, author a spec in the `build-plan-html.mjs` format, and render the HTML plan. To render a plan manually:

```bash
node kit/plugins/plan-agent/scripts/build-plan-html.mjs docs/plans/<slug>.md
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
