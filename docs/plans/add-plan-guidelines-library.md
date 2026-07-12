---
status: completed
type: feature
created: 2026-07-12
glance: Plan authors stop hand-typing 85 KB of HTML — the agent writes a small markdown spec guided by a judgment-based guidelines library, and a bundled script renders the styled interactive plan. We'll know it worked when the skill's own smoke tests pass and this very plan renders from its markdown source.
workflow: false
---

# Plan: Ship the guidelines library and markdown-first authoring for implementation-plan

## Objective

Implement Phase 2 of the guideline-driven plan generation proposal: replace the implementation-plan skill's prescriptive HTML rulebook with a four-document guidelines library and rewrite SKILL.md so the agent authors a Markdown spec and renders it with the bundled build-plan-html.mjs.

## Context

Phase 1 (plan-agent 2.18.0) shipped the deterministic renderer: build-plan-html.mjs parses a small markdown plan spec and emits the full styled HTML plan with the exact DOM contract downstream tools depend on. The skill, however, still instructed the agent to copy a 2,015-line HTML skeleton and fill placeholders by hand — roughly 60k tokens of pure mechanics per plan run. Phase 2 (this plan) inverts the authoring flow per docs/proposals/plan-generation-from-markdown-guidelines.md: guidelines carry the judgment, the spec carries the content, the renderer carries the presentation.

## Files

- kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md (new) — falsifiable done, what/why/verify, scope discipline
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md (new) — section menu with purpose, triggers, and exact spec syntax
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md (new) — minimal/standard/deep depth profiles and calibration table
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md (new) — tone and plain-language rules moved out of the workflow doc
- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — rewritten around explore, read guidelines, author spec, render, deliver
- kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md (modified) — now the copyable spec starter in the parser's exact format
- tests/plugins/test-goal-prompt.sh (modified) — SKILL assertion checks the derived goal-prompt contract, not a placeholder
- tests/plugins/test-resources-section.sh (modified) — Resources guidance assertion repointed to the guidelines and spec skeleton
- kit/plugins/plan-agent/README.md (modified) — structure tree and component section reflect the pipeline
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 2.19.0 entry
- .claude-plugin/marketplace.json (modified) — plan-agent bumped to 2.19.0, description updated

## Steps

1. Author the four guideline documents under skills/implementation-plan/guidelines/ Why: the prescriptive Required Structure rulebook becomes advisory judgment the agent applies per plan, loaded via progressive disclosure Verify: all four files exist and section-catalog.md matches the syntax parseSpecMarkdown() actually accepts.
2. Rewrite SKILL.md around the markdown-spec pipeline while keeping workflow Steps 0-8 intact Why: the authoring medium changes but issue ingestion, clarify, align, interview, tests, status gates, delivery, and the next-action menu orchestrate content that is unchanged Verify: SKILL.md documents the render command, keeps the Step 8 menu contracts, and never tells the agent to hand-write plan HTML.
3. Rewrite reference/SKELETON.md as the spec starter Why: the old humanized-headings skeleton used headings the renderer's parser rejects, so copying it would produce unparseable specs Verify: the skeleton's headings and step markers match the section catalog exactly.
4. Update the smoke tests that pinned retired placeholder prose and bump the plugin to 2.19.0 Why: test-goal-prompt.sh and test-resources-section.sh grepped SKILL.md for {goal-prompt} and resource placeholders that the renderer now owns Verify: the full tests/plugins suite passes and marketplace.json carries 2.19.0.

## Tests

Tier 1 — This plan changes application code
- Objective: the markdown-first pipeline authors and renders valid plans. File: tests/plugins/test-build-plan-html.mjs; Type: smoke; Asserts: parseSpecMarkdown and the renderer round-trip every committed plan and reject malformed specs; Run: node tests/plugins/test-build-plan-html.mjs
- Integration: skill contracts survive the rewrite. File: tests/plugins/test-goal-prompt.sh; Targets: SKILL.md goal-prompt contract, skeleton drawer rows; Key cases: derived prompt format documented, plan-goal meta and copyGoal wiring present
- Integration: Step 8 menu unchanged. File: tests/plugins/test-step8-review-option.sh; Targets: SKILL.md next-action menu; Key cases: adaptive option swap, review foreground/background flows, graceful Agent Teams fallback

## Acceptance Criteria

- The guidelines library exists with planning-principles, section-catalog, right-sizing, and writing-style documents
- SKILL.md instructs authoring a markdown spec and rendering via build-plan-html.mjs, and contains no placeholder-filling or skeleton-copying instructions
- reference/SKELETON.md parses cleanly when its placeholders are filled with real content
- Every test in tests/plugins/ passes
- marketplace.json lists plan-agent at 2.19.0 with a matching CHANGELOG entry

## Verification

Render this plan's own markdown source with node kit/plugins/plan-agent/scripts/build-plan-html.mjs docs/plans/add-plan-guidelines-library.md and confirm it exits 0 and produces the styled sibling HTML — the pipeline the plan ships is the pipeline that built the plan. Then run the tests/plugins suite end to end and confirm zero failures.
