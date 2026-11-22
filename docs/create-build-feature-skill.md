# Add build-feature skill to plan-agent

> A new skill that turns a feature idea into a feature doc and a set of saved prompts — one per sub-feature — ready to hand off to implementation lanes.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build-feature/SKILL.md`: accepts a feature idea and produces a structured feature doc plus one saved prompt per sub-feature; Tier 0 scale-down gate routes small single-deliverable features to `implementation-plan` instead.
- Added `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md`: the canonical output shape for a feature doc — title, objective, sub-features table, acceptance criteria, and open questions.
- Tier 0 gate: if the feature idea can be expressed as a single implementation plan (≤ 2 sub-features, no cross-cutting concerns), `build-feature` redirects to `implementation-plan` with a note; it does not duplicate work.
- `build-proposal` unchanged — it retains its existing proposal → spec → plan flow.
- Updated `tests/plugins/test-exitplanmode-guard.sh`: widened the ExitPlanMode assertion to cover `build-feature`.
- Added `tests/plugins/test-build-feature.sh`: validates feature-doc shape, Tier 0 gate trigger, and saved-prompt filenames.
- Bumped plan-agent to 9.2.0; updated `README.md` skill table and `CHANGELOG.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Feature-doc skill | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | Output shape reference | Created |
| `tests/plugins/test-build-feature.sh` | Build-feature test suite | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | ExitPlanMode assertion widened | Modified |
| `kit/plugins/plan-agent/README.md` | Skill table entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.2.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 9.2.0 | Modified |

## How it works

`build-feature` runs in two passes. The first pass expands the feature idea into sub-features and checks the Tier 0 gate: a single implementation plan is simpler and cheaper than a feature doc, so small ideas are redirected immediately.

The second pass produces the feature doc and a saved prompt per sub-feature. Each saved prompt is a self-contained `/plan-agent:build` invocation pre-loaded with the sub-feature scope, its acceptance criteria, and a reference to the parent feature doc. Teams can run prompts independently or fan them out with the Workflow engine.

The dual-deliverable convergence (feature doc + saved prompts) is the core value: the feature doc is the shared reference for stakeholders; the saved prompts are the handoff to implementers.

## How to use it

```
/plan-agent:build-feature "Add OAuth login to the dashboard"
```

For a small feature that qualifies for Tier 0:

```
/plan-agent:build-feature "Fix the button alignment on mobile"
# → redirects to /plan-agent:implementation-plan
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-12 | feat(plan-agent): add build-feature skill with Tier 0 gate (9.2.0) (#546) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
