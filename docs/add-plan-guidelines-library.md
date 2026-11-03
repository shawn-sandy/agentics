# Ship the guidelines library and markdown-first authoring for implementation-plan

> Phase 2 of guideline-driven plan generation: replaces the 85 KB HTML skeleton with four advisory documents and a markdown spec authoring flow rendered by `build-plan-html.mjs`.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Introduced a four-document guidelines library under `skills/implementation-plan/guidelines/` covering planning principles, section catalog, right-sizing profiles, and writing style.
- Rewrote `implementation-plan/SKILL.md` to author a Markdown spec and render it with `build-plan-html.mjs` (now invoked as `plan-agent-render`) — no more hand-copying HTML skeletons.
- Replaced `reference/SKELETON.md` with a spec starter whose headings and step markers match the parser's accepted syntax exactly.
- Updated smoke tests (`test-goal-prompt.sh`, `test-resources-section.sh`) to assert the derived goal-prompt contract rather than retired HTML placeholders.
- Bumped plan-agent to 2.19.0 in `marketplace.json` with a matching CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Planning principles — falsifiable done, what/why/verify, scope discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section menu with purpose, triggers, and exact spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Minimal/standard/deep depth profiles and calibration table | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill entrypoint — rewritten around explore, read guidelines, author spec, render, deliver | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Copyable spec starter in the parser's exact format | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — asserts derived goal-prompt contract | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test — Resources guidance repointed to guidelines and spec skeleton | Modified |
| `kit/plugins/plan-agent/README.md` | Structure tree and component section reflect the pipeline | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 2.19.0 | Modified |

## How it works

Before this change, `implementation-plan` instructed the agent to copy a 2,015-line HTML skeleton and fill placeholders by hand — roughly 60,000 tokens of pure mechanics per plan run. Phase 1 (plan-agent 2.18.0) shipped `build-plan-html.mjs`, which parses a small markdown spec and emits the full styled HTML. Phase 2 (this plan) completes the inversion: guidelines carry judgment, the spec carries content, and the renderer carries presentation.

The four guideline documents in `kit/plugins/plan-agent/skills/implementation-plan/guidelines/` are loaded by the agent progressively as each stage of plan authoring requires them. `planning-principles.md` lays out falsifiable acceptance criteria, the what/why/verify pattern for every step, and scope discipline. `section-catalog.md` is the exact syntax reference — the section headings listed there are matched literally by `parseSpecMarkdown`. `right-sizing.md` maps plan shapes to minimal, standard, or deep depth profiles. `writing-style.md` covers tone, the objective vs. glance distinction, and plain-language rules.

`SKILL.md` was rewritten around five stages: explore the request, read the relevant guidelines, author the markdown spec, render it with `plan-agent-render <plan>.md -o <plan>.html`, and deliver. The skill no longer references HTML templates at all. The render step is deterministic — exit 0 means a well-formed plan; exit 1 prints the exact required section that is missing, which the agent then fixes and re-renders.

`reference/SKELETON.md` became the copyable spec starter. The old skeleton used humanized headings the parser rejected, so copying it would produce an unparseable spec. The new version matches the section catalog exactly — `## Steps` with numbered items carrying `Why:` and `Verify:` markers, not prose paragraphs.

The smoke tests were updated to drop assertions on `{goal-prompt}` and resource placeholder strings that no longer appear in `SKILL.md`, replacing them with assertions on the derived goal-prompt contract and on the guidelines library paths now documented in the skill.

## How to use it

Load the plugin and invoke the skill:

```bash
claude --plugin-dir ./kit/plugins/plan-agent
/plan-agent:implementation-plan <objective>
```

The skill reads the relevant guidelines for each stage, authors a spec in `docs/plans/`, and renders it. To render a spec manually:

```bash
plan-agent-render docs/plans/<slug>.md -o docs/plans/<slug>.html
```

The `reference/SKELETON.md` is the starting point for any plan spec. Copy it, fill in the frontmatter and sections, then render.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
