# Create build-feature skill

> Adds a `build-feature` skill to plan-agent that generates feature documentation at `docs/features/<slug>.md`, includes a Tier 0 quality gate, and optionally breaks down sub-features — distinct from `build-proposal` which generates implementation plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-feature/SKILL.md` for generating feature docs.
- Feature docs land at `docs/features/<slug>.md` (separate from `docs/plans/`).
- Tier 0 gate: the skill refuses to generate documentation for a feature that doesn't have at least one completed plan.
- Sub-feature breakdown is recommend-only (not gated) — for large features with multiple independent sub-components.
- Integrates with `plan-agent:prompt` for saving prompts via the existing prompt infrastructure.
- `build-proposal` byte-identical copy maintained in `scripts/`.
- Bumped plan-agent to 9.2.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Feature skill | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

`build-feature` serves a different purpose than `build-proposal`: proposals are forward-looking (here's what we plan to build), features are backward-looking (here's what we built and why it works). Feature docs are the external-facing documentation for something that has been implemented, written after the implementation is complete.

The Tier 0 gate prevents generating feature documentation before there's anything to document: at least one plan in `docs/plans/` with `status: completed` must match the feature's scope. This prevents aspirational feature docs that describe things that haven't shipped.

Sub-feature breakdown is recommend-only because it's frequently unnecessary — most features are standalone. When a feature genuinely decomposes into independent sub-features (e.g., "authentication" breaking into "login", "signup", "password reset"), the skill can suggest the split, but the user decides whether to pursue it.

## How to use it

```
/plan-agent:build-feature <feature-name>
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
