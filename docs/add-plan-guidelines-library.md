# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replaces the implementation-plan skill's prescriptive HTML rulebook with a four-document guidelines library and a markdown-spec pipeline rendered by the bundled `build-plan-html.mjs`.

<!-- generated:start -->

**Status:** Shipped 2026-07-12  **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Added four guideline documents under `skills/implementation-plan/guidelines/`: `planning-principles.md`, `section-catalog.md`, `right-sizing.md`, and `writing-style.md`.
- Rewrote `SKILL.md` around a five-step pipeline: explore, read guidelines, author spec, render, deliver — no more hand-filling of a 2,015-line HTML skeleton.
- Rewrote `reference/SKELETON.md` as the copyable spec starter in `parseSpecMarkdown`'s exact format (the old humanized-headings skeleton would have produced unparseable specs).
- Updated `tests/plugins/test-goal-prompt.sh` and `tests/plugins/test-resources-section.sh` to check the renderer-derived contracts rather than placeholder strings.
- Bumped `plan-agent` to `2.19.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Authoring guidelines | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section syntax catalog | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Depth profiles | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Tone and style rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan spec starter | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

Phase 1 (plan-agent 2.18.0) shipped the deterministic renderer: `build-plan-html.mjs` parses a small Markdown spec and emits the full styled HTML plan. Phase 2 (this plan) inverts the authoring flow: the agent writes a compact Markdown spec guided by the guidelines library and calls the renderer to produce the HTML.

The guidelines are loaded via progressive disclosure: the agent reads only the sections relevant to the current plan's characteristics, avoiding the ~60k token cost of the old inline HTML rulebook. `section-catalog.md` documents the exact syntax `parseSpecMarkdown()` accepts, so it is the authoritative spec grammar. `right-sizing.md` gives three depth profiles (minimal, standard, deep) with calibration tables so the agent can choose the right level of detail.

The skeleton serves as the copyable starting point; its headings and step markers match the catalog exactly, so filling it in always produces parseable specs.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
