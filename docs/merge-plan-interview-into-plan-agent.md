# Merge plan-interview into plan-agent

> Folds the plan-interview plugin into plan-agent 4.0.0, carrying over five skills while retiring four that were superseded, reducing the marketplace from 13 to 12 plugins.

<!-- generated:start -->

**Status:** Shipped 2026-07-17 **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Carried `documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`, and the `ExitPlanMode` hook from plan-interview into plan-agent 4.0.0.
- Retired `plan-interview`, `plan-to-html`, `plan-hygiene`, and `review-rename-plans` as superseded by plan-agent capabilities.
- Updated `.claude/rules/marketplace.md` to reflect the removal.
- Updated `CLAUDE.md` plugin count from 13 to 12.
- Updated `.claude/settings.json` and the plugin registry.
- Updated `tests/publish/smoke-clean-dist.sh` and `tests/publish/test-dist-transforms.mjs`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/` (many skills) | Plugin with new skills | Modified |
| `.claude/rules/marketplace.md` | Rules | Modified |
| `CLAUDE.md` | Documentation | Modified |
| `.claude/settings.json` | Settings | Modified |
| `tests/publish/smoke-clean-dist.sh` | Test | Modified |
| `tests/publish/test-dist-transforms.mjs` | Test | Modified |

## How it works

plan-interview and plan-agent had been growing in overlapping directions: plan-agent's build/finalize/status workflow naturally encompassed the interview-style planning that plan-interview provided. Rather than maintaining two separate plugins with cross-references, the valuable skills from plan-interview were folded directly into plan-agent as a MAJOR version bump.

The five carried-over skills — `documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`, and the `ExitPlanMode` hook — all had clear homes in plan-agent's skill organization. The four retired skills (`plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans`) were either renamed or superseded by plan-agent's existing capabilities.

This consolidation reduces cognitive overhead for users who now have a single plugin for the full plan lifecycle: authoring, interviewing, reviewing, tracking, and documenting.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
