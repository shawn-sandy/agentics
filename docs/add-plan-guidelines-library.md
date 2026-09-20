# Ship the guidelines library and markdown-first authoring for implementation-plan

> Plan authors stop hand-typing 85 KB of HTML — the agent writes a small markdown spec guided by a judgment-based guidelines library, and a bundled script rend...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Author the four guideline documents under skills/implementation-plan/guidelines/
- Rewrite SKILL.md around the markdown-spec pipeline while keeping workflow Steps 0-8 intact
- Rewrite reference/SKELETON.md as the spec starter
- Update the smoke tests that pinned retired placeholder prose and bump the plugin to 2.19.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | falsifiable done, what/why/verify, scope discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | section menu with purpose, triggers, and exact spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | minimal/standard/deep depth profiles and calibration table | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | tone and plain-language rules moved out of the workflow doc | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | rewritten around explore, read guidelines, author spec, render, deliver | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | now the copyable spec starter in the parser's exact format | Modified |
| `tests/plugins/test-goal-prompt.sh` | SKILL assertion checks the derived goal-prompt contract, not a placeholder | Modified |
| `tests/plugins/test-resources-section.sh` | Resources guidance assertion repointed to the guidelines and spec skeleton | Modified |
| `kit/plugins/plan-agent/README.md` | structure tree and component section reflect the pipeline | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 2.19.0, description updated | Modified |

## How it works

Implement Phase 2 of the guideline-driven plan generation proposal: replace the implementation-plan skill's prescriptive HTML rulebook with a four-document guidelines library and rewrite SKILL.md so the agent authors a Markdown spec and renders it with the bundled build-plan-html.mjs.

Phase 1 (plan-agent 2.18.0) shipped the deterministic renderer: build-plan-html.mjs parses a small markdown plan spec and emits the full styled HTML plan with the exact DOM contract downstream tools depend on. The skill, however, still instructed the agent to copy a 2,015-line HTML skeleton and fill placeholders by hand — roughly 60k tokens of pure mechanics per plan run. Phase 2 (this plan) inverts the authoring flow per docs/proposals/plan-generation-from-markdown-guidelines.md: guidelines carry the judgment, the spec carries the content, the renderer carries the presentation.

The implementation proceeded through the following steps: Author the four guideline documents under skills/implementation-plan/guidelines/ Why: the prescriptive Required Structure rulebook becomes advisory judgment the agent applies per plan, loaded via progressive disclosure Verify: all four files exist and section-catalog.md matches the syntax parseSpecMarkdown() actually accepts.; Rewrite SKILL.md around the markdown-spec pipeline while keeping workflow Steps 0-8 intact Why: the authoring medium changes but issue ingestion, clarify, align, interview, tests, status gates, delivery, and the next-action menu orchestrate content that is unchanged Verify: SKILL.md documents the render command, keeps the Step 8 menu contracts, and never tells the agent to hand-write plan HTML.; Rewrite reference/SKELETON.md as the spec starter Why: the old humanized-headings skeleton used headings the renderer's parser rejects, so copying it would produce unparseable specs Verify: the skeleton's headings and step markers match the section catalog exactly.; Update the smoke tests that pinned retired placeholder prose and bump the plugin to 2.19.0 Why: test-goal-prompt.sh and test-resources-section.sh grepped SKILL.md for {goal-prompt} and resource placeholders that the renderer now owns Verify: the full tests/plugins suite passes and marketplace.json carries 2.19.0..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
