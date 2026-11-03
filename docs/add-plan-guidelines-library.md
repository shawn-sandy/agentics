# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replaces the implementation-plan skill's prescriptive HTML rulebook with a four-document guidelines library and rewrites SKILL.md so the agent authors a Markdown spec rendered by the bundled `build-plan-html.mjs`.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-plan-guidelines-library](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created four guideline documents under `skills/implementation-plan/guidelines/`: `planning-principles.md`, `section-catalog.md`, `right-sizing.md`, `writing-style.md`
- Rewrote `implementation-plan/SKILL.md` around: explore → read guidelines → author spec → render → deliver; Steps 0–8 orchestration intact
- Rewrote `reference/SKELETON.md` as the spec starter in the renderer's exact format (headings and step markers matching `section-catalog.md`)
- Updated `tests/plugins/test-goal-prompt.sh` and `tests/plugins/test-resources-section.sh` to assert the new skill contracts
- Bumped `plan-agent` to `2.19.0` with CHANGELOG entry and marketplace description update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guidelines — falsifiable done, what/why/verify, scope discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guidelines — section menu with purpose, triggers, spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guidelines — minimal/standard/deep depth profiles | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guidelines — tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — markdown-first pipeline, no HTML authoring | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter — copyable template in parser format | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — updated goal-prompt assertions | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test — updated resource assertions | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 2.19.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 2.19.0 entry | Modified |

## How it works

Phase 1 (plan-agent 2.18.0) shipped `build-plan-html.mjs` — a deterministic renderer that parses a small Markdown plan spec and emits the full styled HTML. Phase 2 (this plan) inverts the authoring flow: instead of instructing the agent to copy a 2,015-line HTML skeleton and fill placeholders by hand (~60k tokens per plan run), the agent authors a compact Markdown spec guided by the guidelines library, then calls the renderer.

The four guidelines encode the judgments that previously lived in the SKILL.md rulebook:
- `planning-principles.md`: falsifiable done criteria, the what/why/verify step structure, scope discipline
- `section-catalog.md`: the full section menu with purpose, activation triggers, and the exact spec syntax the renderer's parser accepts
- `right-sizing.md`: three depth profiles (minimal, standard, deep) with a calibration table
- `writing-style.md`: tone and plain-language rules previously embedded in the workflow doc

SKILL.md now describes a five-stage pipeline: explore the request, read the relevant guidelines (loaded on demand via progressive disclosure), author the Markdown spec, render via `node kit/plugins/plan-agent/scripts/build-plan-html.mjs <spec>`, and deliver. The model never writes HTML directly.

`reference/SKELETON.md` is the copyable spec starter — its headings and step markers match `section-catalog.md` exactly so copying it produces a spec the parser accepts without modification.

## How to use it

```
/plan-agent:implementation-plan <topic>  # authors Markdown spec, renders to HTML automatically
```

The guidelines are loaded by the skill on demand — they are not always-present context.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library](plans/add-plan-guidelines-library.md)
- Proposal: `docs/proposals/plan-generation-from-markdown-guidelines.md`
