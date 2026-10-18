# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan, giving implementers latitude to optimize for the outcome rather than follow steps mechanically.

<!-- generated:start -->

**Status:** Shipped 2026-06-18  **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` to `reference/SKELETON.html` — always emitted, no flag required.
- Added a collapsible `.plan-goal` `<details>` block (purple `--purple*` tokens) between the implement and workflow rows in the skeleton, with a `copyGoal()` clipboard helper mirroring `copyWorkflow()`.
- Updated `implementation-plan/SKILL.md` to compute `{goal-prompt}` in Step 2 and emit the `plan-goal` meta tag in Step 3 for every plan.
- Bumped `plan-agent` to `2.6.0` in `.claude-plugin/marketplace.json` with CHANGELOG entry and README update.
- Added `tests/plugins/test-goal-prompt.sh` asserting the meta tag, markup, CSS, DOM order (`implement → goal → workflow`), and SKILL.md contract.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML plan skeleton | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Created |

## How it works

Every HTML plan now renders three execution framings side by side: implement (strict step execution), goal (outcome-driven latitude), and workflow (parallel subagent orchestration). All three are wired through the same three surfaces — a `<meta>` tag in `<head>`, a visible/collapsible row in the body, and a Step 2 computation that derives the prompt text from the plan's objective.

The goal prompt instructs the implementer to "Achieve this goal: … use the plan as reference, but optimize for the outcome." This is the explicit inverse of the implement prompt's strict step-following contract — it grants latitude to deviate when a better path to the same result exists.

The `copyGoal()` helper mirrors `copyWorkflow()` exactly, and the `.plan-goal` block uses the same CSS hidden-when-completed and print-hidden rules as its siblings, so the rendering is consistent across all three.

## How to use it

Generated HTML plans include a purple "Pursue as goal" disclosure row. Click it to expand and copy the goal prompt, then paste it into a new session as the starting instruction.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `4147530` | 2026-08-26 | fix(plan-agent): stop artifact-mode renders leaking local paths (9.7.1) (#602) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `daa72b9` | 2026-08-23 | build-feature: add product content, stories, metrics, rollout, and publishing (#593) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
