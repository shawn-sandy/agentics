# Add plan authoring to the build skill

> Replaces the build skill's no-plan dead end with a proposal chain — when no plan exists, build offers to discover or author one rather than stopping, making plan-first development the path of least resistance.

<!-- generated:start -->

**Status:** Shipped 2026-07-27 **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Replaced the no-plan dead end in `build` with a discovery-and-proposal chain (slash command invocation only).
- Added discovery offer showing up to 3 matching candidates from `docs/plans/`.
- Pinned `model: opus` for the proposal pass to ensure high-quality plan generation.
- Bumped plan-agent to 5.0.0 (MAJOR) due to argument format and activation behavior change.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

Previously, invoking `/plan-agent:build` without an existing plan would produce a hard stop: "No plan found. Create one first." This left new implementers stranded with no guidance on what to do next.

The new flow: when `build` is invoked without a matching plan, it first searches `docs/plans/` for plans whose names semantically match the request (up to 3 candidates). If candidates are found, the user can select one or choose "none of these." If no candidates are found or the user declines, `build` offers to invoke `build-proposal` to draft a new plan — this handoff is only available from the slash command path (not the background agent), since it requires interactive confirmation.

The `model: opus` pin on the proposal pass reflects the difference in task: `build` executing a known plan runs fine on the session model, but generating a novel implementation plan benefits from Opus's stronger reasoning.

The MAJOR version bump signals the changed argument contract: `build` now accepts an optional first argument for the plan stem, and its activation behavior changed for the no-plan case.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
