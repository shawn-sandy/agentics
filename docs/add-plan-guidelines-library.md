# Add guidelines library and markdown-first authoring for implementation-plan

> Phase 2 of the guideline-driven plan generation proposal: the `implementation-plan` skill's prescriptive HTML rulebook is replaced by a four-document guidelines library and a markdown-spec-first authoring workflow, cutting roughly 60k tokens of pure mechanics per plan run.

<!-- generated:start -->

**Status:** Shipped 2026-07-12 **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Added four guideline documents under `skills/implementation-plan/guidelines/`:
  - `planning-principles.md` — falsifiable done, what/why/verify, scope discipline
  - `section-catalog.md` — section menu with purpose, triggers, and exact spec syntax
  - `right-sizing.md` — minimal/standard/deep depth profiles and calibration table
  - `writing-style.md` — tone and plain-language rules
- Rewrote `SKILL.md` around the markdown-spec pipeline (explore, read guidelines, author spec, render, deliver) while keeping workflow Steps 0–8 intact.
- Rewrote `reference/SKELETON.md` as the copyable spec starter in the parser's exact format (headings and step markers matching what `parseSpecMarkdown()` accepts).
- Updated `tests/plugins/test-goal-prompt.sh` and `tests/plugins/test-resources-section.sh` to match the new SKILL.md contracts.
- Bumped `plan-agent` to `2.19.0` with matching CHANGELOG entry and updated marketplace description.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guidelines | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guidelines | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guidelines | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guidelines | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |

## How it works

Phase 1 (plan-agent 2.18.0) shipped `build-plan-html.mjs`: a deterministic renderer that parses a small markdown plan spec and emits the full styled HTML plan with the exact DOM contract downstream tools depend on. Phase 2 inverts the authoring flow: instead of instructing the agent to copy a 2,015-line HTML skeleton and fill placeholders by hand (~60k tokens of pure mechanics), the guidelines carry the judgment, the spec carries the content, and the renderer carries the presentation.

The four guideline documents are progressive-disclosure references. `section-catalog.md` is the syntax contract — it matches what `parseSpecMarkdown()` actually accepts. `right-sizing.md` calibrates depth with three profiles (minimal/standard/deep) and a decision table. `planning-principles.md` encodes scope discipline and the falsifiable-done standard. `writing-style.md` holds tone and plain-language rules.

SKILL.md now instructs the agent to author a Markdown spec and run `node scripts/build-plan-html.mjs <spec>.md` to render it; it no longer contains any HTML skeleton-copying instructions.

## How to use it

The guidelines are automatically loaded by `implementation-plan` via progressive disclosure. The skill reads them when authoring a spec, applying section-catalog syntax, right-sizing depth, and writing-style rules to the plan being written.

```
/plan-agent:implementation-plan
```

Activated by description match on planning requests.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `5de9c6ab` | 2026-07-12 | feat(plan-agent): guidelines library + markdown-first SKILL.md rewrite (2.19.0) (#388) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
