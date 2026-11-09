# Create the build-feature skill — feature docs that split into plans

> Adds a new `build-feature` skill to `plan-agent` that turns a feature idea into a team-readable feature doc at `docs/features/<slug>.md`, ending in a recommended breakdown into smaller sub-feature plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [create-build-feature-skill](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-feature/SKILL.md` — produces `docs/features/<slug>.md` covering context, users, goals, scope, and risks
- Feature doc ends with a recommended breakdown into sub-feature plans, each with a paste-ready `/plan-agent:implementation-plan` prompt
- A saved prompt is written for the planning layer to enable background plan authoring
- Bumped `plan-agent` with CHANGELOG entry and README update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Skill — feature doc authoring | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs | Modified |

## How it works

`build-feature` addresses the gap between a user's feature idea and an actionable implementation plan. A feature idea often scopes too broadly for a single plan — it involves multiple components, teams, or phases that benefit from separate plans tracked independently.

The skill interviews the user on context (what problem this solves), users (who benefits), goals (measurable outcomes), scope (in/out boundaries), and risks. From these, it authors `docs/features/<slug>.md` — a team-readable document in the `docs/features/` directory, separate from `docs/plans/`.

The feature doc closes with a recommended plan breakdown: each sub-feature or phase gets a brief description and a paste-ready `/plan-agent:implementation-plan` prompt with the sub-feature's objective pre-filled. This makes the transition from feature scoping to implementation planning a copy-paste operation rather than a fresh authoring task.

## How to use it

```
/plan-agent:build-feature <topic>        # author a feature doc with plan breakdown
```

The skill activates when the user asks to scope, plan, or document a feature at a high level before implementation.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill](plans/create-build-feature-skill.md)
