# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replaced the implementation-plan skill's 2,015-line HTML skeleton with a four-document guidelines library and a markdown-spec pipeline, cutting plan authoring from ~60k tokens of manual HTML to a small spec rendered by `build-plan-html.mjs`.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created four guideline documents under `kit/plugins/plan-agent/skills/implementation-plan/guidelines/`: `planning-principles.md`, `section-catalog.md`, `right-sizing.md`, and `writing-style.md` (advisory judgment the agent applies per plan, loaded via progressive disclosure rather than prescriptive rules).
- Rewrote `skills/implementation-plan/SKILL.md` around the markdown-spec pipeline: explore → read guidelines → author spec → render with `build-plan-html.mjs` → deliver; removed all placeholder-filling and skeleton-copying instructions while keeping the Steps 0–8 orchestration intact.
- Rewrote `reference/SKELETON.md` as the copyable spec starter whose headings and step markers match the section catalog and the parser's accepted syntax exactly (the old skeleton used headings the renderer's `parseSpecMarkdown()` would reject).
- Updated `tests/plugins/test-goal-prompt.sh` and `tests/plugins/test-resources-section.sh` to assert the derived goal-prompt contract and guidelines/skeleton rather than retired placeholder strings.
- Bumped plan-agent to 2.19.0 in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Falsifiable done criteria, what/why/verify discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section menu with purpose, triggers, and exact spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Depth profiles (minimal/standard/deep) and calibration table | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill rewritten around markdown-spec pipeline | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter matching parser's accepted format | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test updated to assert spec-pipeline contract | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test repointed to guidelines and skeleton | Modified |
| `kit/plugins/plan-agent/README.md` | Structure tree and component section updated | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 2.19.0 | Modified |

## How it works

Phase 1 of this work (plan-agent 2.18.0) shipped the deterministic renderer: `build-plan-html.mjs` parses a compact markdown plan spec and emits fully styled HTML with the exact DOM contract downstream tools depend on. Phase 2 (this change) inverted the authoring flow so the agent writes the spec rather than a 2,015-line HTML skeleton.

The four guideline files each own one concern. `planning-principles.md` establishes what makes a step verifiable. `section-catalog.md` is the canonical menu: for every section the renderer recognises it gives the purpose, the triggers that earn it, and the exact spec syntax `parseSpecMarkdown()` accepts — authors consult it rather than guessing. `right-sizing.md` provides three depth profiles (minimal, standard, deep) with a calibration table so an agent can pick appropriate plan depth for a given task. `writing-style.md` moves the tone rules that previously lived inline in the workflow document into a standalone reference.

`SKILL.md` was rewritten to a five-stage pipeline: explore the task, read the applicable guidelines, author a markdown spec, render it with `build-plan-html.mjs`, deliver. The Steps 0–8 orchestration — issue ingestion, clarify, align, interview, test design, status gates, and the next-action menu — was kept intact because the authoring medium changed but the content workflow did not.

`reference/SKELETON.md` was rewritten to match the section catalog exactly. The previous skeleton used human-readable headings that `parseSpecMarkdown()` rejected, meaning copying it produced an unparseable spec. The new skeleton is a drop-in spec starter.

Note that a fifth guidelines file, `red-green-verify.md`, appears in the guidelines directory and was not listed in the original plan's Files section — it was added in a subsequent change.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
