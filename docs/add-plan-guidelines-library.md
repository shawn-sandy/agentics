# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replace the implementation-plan skill's prescriptive HTML rulebook with a four-document guidelines library and a markdown-spec pipeline that renders plans via a bundled build script.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-plan-guidelines-library](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created a four-document guidelines library under `skills/implementation-plan/guidelines/` covering planning principles, section catalog, right-sizing profiles, and writing style.
- Rewrote `implementation-plan/SKILL.md` so the agent authors a small markdown spec and renders it with `build-plan-html.mjs` rather than hand-filling a 2 000-line HTML skeleton.
- Rewrote `reference/SKELETON.md` as a spec starter whose headings and step markers match exactly what `parseSpecMarkdown()` accepts.
- Updated smoke tests that pinned retired placeholder prose and bumped `plan-agent` to 2.19.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Falsifiable done, what/why/verify, scope discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section menu with purpose, triggers, and exact spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Minimal/standard/deep depth profiles and calibration table | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Rewritten around explore, read guidelines, author spec, render, deliver | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Copyable spec starter in the parser's exact format | Modified |
| `tests/plugins/test-goal-prompt.sh` | SKILL assertion checks derived goal-prompt contract | Modified |
| `tests/plugins/test-resources-section.sh` | Resources guidance assertion repointed to guidelines and spec skeleton | Modified |
| `kit/plugins/plan-agent/README.md` | Structure tree and component section reflect the pipeline | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 2.19.0, description updated | Modified |

## How it works

Phase 1 (plan-agent 2.18.0) shipped `build-plan-html.mjs`, a deterministic renderer that parses a small markdown plan spec and emits the full styled HTML plan. The skill, however, still instructed the agent to copy a 2 015-line HTML skeleton and fill placeholders by hand — roughly 60k tokens of pure mechanics per plan run.

Phase 2 inverts the authoring flow. Four guideline documents under `skills/implementation-plan/guidelines/` now carry the judgment the agent applies: `planning-principles.md` specifies falsifiable done criteria, `section-catalog.md` lists every section with its purpose and the exact spec syntax `parseSpecMarkdown()` accepts, `right-sizing.md` offers minimal/standard/deep depth profiles, and `writing-style.md` moves tone rules out of the workflow document.

`SKILL.md` was rewritten around a five-phase pipeline — explore, read guidelines, author spec, render, deliver — while preserving the Steps 0-8 orchestration intact. The skill now instructs the agent to run `node kit/plugins/plan-agent/scripts/build-plan-html.mjs <spec>.md` rather than filling any placeholder. It never directs the agent to hand-write plan HTML.

`reference/SKELETON.md` was rewritten as the spec starter. The old humanized-headings skeleton used headings the renderer's parser rejected; the new one mirrors `section-catalog.md`'s exact heading names and step markers so copying it produces a parseable spec.

Two smoke tests were updated. `test-goal-prompt.sh` previously grepped `SKILL.md` for the literal `{goal-prompt}` placeholder; it was repointed to assert the derived goal-prompt contract the renderer now owns. `test-resources-section.sh` was similarly repointed to the guidelines library and the spec skeleton. Both pass at 2.19.0.

## How to use it

```bash
# Run the implementation-plan skill (loads guidelines automatically)
claude --plugin-dir ./kit/plugins/plan-agent
# Then invoke:
# /plan-agent:implementation-plan

# Render a spec directly:
node kit/plugins/plan-agent/scripts/build-plan-html.mjs docs/plans/<slug>.md
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library](plans/add-plan-guidelines-library.md)
