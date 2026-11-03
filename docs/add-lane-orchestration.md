# Make the plan the dispatch contract

> Delivers lane-based parallel plan execution in four phases (plan-agent 9.14.0–9.17.0): lane parsing in the renderer, lane authoring in implementation-plan, a lane dispatcher in build, and a measured Workflow-engine pilot.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-lane-orchestration.md](plans/add-lane-orchestration.md)
**Type:** feature

## What shipped

- Added `### Lane: <name> (owns: ...; after: ...)` syntax to plan specs — declares which steps are independent and which files each lane owns.
- Updated `plan-spec.mjs` to parse lane headings into `sections.lanes` and re-emit them verbatim in `buildDigest()`, preserving byte-stability for lane-free plans.
- Extended `build-plan-html.mjs` with `--check` ownership rules (overlap, nesting, unknown `after:`, cyclic deps, unlaned steps) and `--lanes` JSON output; scoped the workflow file-count gate to lane-free specs only.
- Rendered lane surfaces in `plan-shell.mjs`: labeled chip per step, Lanes panel card with nav entry, one "Copy worker brief" row per lane in the More-ways drawer, and `plan-lanes` meta tag.
- Updated `implementation-plan/SKILL.md` with a lane-split pass in Step 2 and a lane-confirmation question in Align.
- Branched `build/SKILL.md` Step 2 on lane count: sequential path unchanged for zero/one lane or `--sequential`; for 2+ lanes dispatches one worktree-isolated Agent per lane, merges `--no-ff` in `after:` order, audits ownership via `git diff --name-only` before each merge.
- Added `references/dispatch-lanes.md` as the canonical dispatch contract (worker brief template, wave loop, failure modes, fresh-fork retry rule).
- Added `implement-workflow.mjs` as the Workflow-engine escalation for 6+ lanes or `workflow: always`.
- Added `tests/plan-lanes.test.mjs` and `tests/implement-workflow.test.mjs`.
- Shipped as four release commits (9.14.0–9.17.0) in one PR (#628); the 9.17.0 CHANGELOG entry carries measured pilot numbers.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Plan parser | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Shell/UI layer | Modified |
| `tests/plan-lanes.test.mjs` | Lane parser tests | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Authoring guidelines | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Authoring guidelines | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Authoring guidelines | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan template | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill | Modified |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Dispatch contract | Created |
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow escalation | Created |
| `tests/implement-workflow.test.mjs` | Workflow engine tests | Created |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Fleet skill | Modified |
| `kit/plugins/plan-agent/commands/fix.md` | Command | Modified |
| `kit/plugins/plan-agent/commands/refactor.md` | Command | Modified |
| `kit/plugins/plan-agent/agents/plan-reviewer-completeness.md` | Review agent | Modified |
| `kit/plugins/plan-agent/agents/plan-reviewer-risk.md` | Review agent | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

Before this feature, plans were instructions for a single agent working sequentially. After it, a plan that declares `### Lane:` groupings becomes a dispatch contract: independent groups of steps run in parallel worktree-isolated Sonnet agents, with the `lead` lane handling shared files (CHANGELOG, README, marketplace.json) in the main session.

The `--check` flag in the renderer validates the split at authoring time — overlapping `owns:` paths, nested globs across lanes, unknown `after:` references, cycles, and unlaned steps all exit 1 with the offending lane named. The `--lanes` flag emits JSON for the dispatcher to consume without hand-parsing Markdown.

The dispatch loop in `build/SKILL.md` Step 2 reads the lane graph, groups lanes into waves (all lanes whose `after:` prerequisites are already merged), launches up to `--max` (default 3, cap 5) Agent calls per wave in one message, and audits each completed branch with `git diff --name-only` against `owns:` before merging — self-reported LANE REPORTs are verified, not trusted. A failed lane re-dispatches from a fresh fork of the current plan branch; a merge conflict on a disjoint-ownership plan stops and asks rather than auto-resolving.

Backward compatibility is enforced by the lane-free fixture in `tests/plan-lanes.test.mjs`, which asserts zero bytes changed in the rendered HTML — no chip, no panel, no brief, no meta — against the pre-lane baseline.

The Phase 4 pilot measured the dispatch path against `--sequential` on the implement-workflow plan: dispatch used 466,207 worker tokens in 651 s for three lanes; sequential used substantially more total session tokens (the two figures are not the same measure) in 411 s for the same lanes.

## How to use it

Plans with `### Lane:` headings in `## Steps` are dispatched in parallel by `/plan-agent:build`. Use `plan-agent-render <spec> --check` to validate lane ownership before building. Pass `--sequential` to suppress dispatch on any plan. The "Copy worker brief" button in each plan's More-ways drawer gives the prompt text for manual dispatch.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c3514b7` | 2026-09-09 | docs(plan-agent): publish the pilot's --sequential figures and complete the lane plan (9.17.1) (#629) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `e6cc179` | 2026-09-09 | docs: add plan-agent lane orchestration proposal, plan, and design canvas (#627) |

<!-- generated:end -->

## References

- Plan: [add-lane-orchestration.md](plans/add-lane-orchestration.md)
