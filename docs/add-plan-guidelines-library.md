# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replaces the implementation-plan skill's prescriptive HTML rulebook with a four-document guidelines library and rewrites SKILL.md so the agent authors a Markdown spec rendered by `build-plan-html.mjs`.

<!-- generated:start -->

**Status:** Shipped 2026-07-12 **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created four guidelines documents under `skills/implementation-plan/guidelines/`: `planning-principles.md`, `section-catalog.md`, `right-sizing.md`, and `writing-style.md`.
- Rewrote `implementation-plan/SKILL.md` around the markdown-spec pipeline: explore → read guidelines → author spec → render via `build-plan-html.mjs` → deliver.
- Rewrote `reference/SKELETON.md` as the copyable spec starter in the parser's exact format.
- Updated smoke tests (`test-goal-prompt.sh`, `test-resources-section.sh`) that pinned retired placeholder prose.
- Bumped `plan-agent` to `2.19.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guidelines: scope and done criteria | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guidelines: section menu with syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guidelines: depth profiles | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guidelines: tone rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter template | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

Phase 1 shipped `build-plan-html.mjs`, a deterministic renderer that parses a small Markdown spec and emits the full styled HTML plan. Phase 2 (this plan) inverted the authoring flow: rather than instructing the model to copy-and-fill an 85 KB HTML skeleton, the skill now tells the model to author a compact Markdown spec guided by the guidelines library, then render it.

The guidelines library carries the judgment that was previously baked into one giant SKILL.md: `planning-principles.md` covers falsifiable done criteria and scope discipline; `section-catalog.md` is the section menu with purpose, triggers, and exact spec syntax; `right-sizing.md` has three depth profiles and a calibration table; `writing-style.md` has tone and plain-language rules.

The SKELETON.md was rewritten with headings and step markers that the renderer's parser actually accepts, so copying it produces a parseable spec rather than the unparse-able humanized-heading skeleton it replaced.

## How to use it

Invoke `/plan-agent:implementation-plan` as before. The pipeline now authors a compact `.md` spec in a single pass and renders it to the styled HTML plan in one `node build-plan-html.mjs` call.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
- Changelog: [plan-agent CHANGELOG v2.19.0](../kit/plugins/plan-agent/CHANGELOG.md)
