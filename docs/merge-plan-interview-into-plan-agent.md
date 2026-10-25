# Merge plan-interview into plan-agent

> Folds `plan-interview` into `plan-agent` v4.0.0, carrying over the five unique capabilities (`documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`, `plan-maintenance`) and dropping every redundant overlap, then de-registers and deletes `plan-interview`.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [merge-plan-interview-into-plan-agent](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Ported five unique skills from `plan-interview` into `plan-agent`: `documenting-plans`, `markdown-to-html` (with assets, reference, scripts), `plan-status`, `deep-grill`, and `plan-maintenance`
- Ported the `plan-documenter` agent and six commands: `documenting-plans.md`, `plan-maintenance.md`, `markdown-to-html.md`, `plan-status.md`, `update-plan-status.md`, `deep-grill.md`
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json`
- Folded `update-plan-status`'s bulk mode into `plan-status` as a directory/`--all` flag; dropped the standalone command
- Updated all `plan-interview:` namespace references across the repo to `plan-agent:`
- De-registered `plan-interview` from `marketplace.json`; deleted `kit/plugins/plan-interview/`
- Added the Removed Plugins row to `.claude/rules/marketplace.md`
- Updated `CLAUDE.md` from 13 plugins to 12; dropped the `plan-interview` row
- Bumped plan-agent to 4.0.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/` | Destination for ported skills | Modified |
| `kit/plugins/plan-interview/` | Source plugin — deleted | Deleted |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 4.0.0, plan-interview removed | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins row | Modified |
| `.claude/settings.json` | Drop plan-interview from enabledPlugins | Modified |
| `CLAUDE.md` | Plugin table — 12 rows | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — merged skills | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 4.0.0 with migration map | Modified |
| `tests/publish/smoke-clean-dist.sh` | Smoke test — 12-plugin roster | Modified |
| `tests/publish/test-dist-transforms.mjs` | Transform test — plan-interview block removed | Modified |

## How it works

The marketplace shipped two planning plugins that already operated as one system split by file format — `plan-agent` owned HTML generation and implementation, and `plan-interview` owned interviewing, documenting, and maintenance. Users had to know which plugin covered which workflow.

Decision: full merge into `plan-agent` v4.0.0, with plan-agent winning every overlap seam. Dropped components (`plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans`) are covered by plan-agent's built-in interview, `review-plan` team, and `validate-plan-filename` hook. Only the five unique capabilities were ported.

All `plan-interview:` namespace references across skills, commands, agents, hooks, and cross-links were rewritten to `plan-agent:`. The CHANGELOG 4.0.0 entry carries a migration mapping table (old command → new command) for users who had both plugins installed. The ExitPlanMode nudge hook references the built-in Step 5b interview rather than the now-deleted plugin.

`plan-interview` source is recoverable from git history. The Removed Plugins row in `.claude/rules/marketplace.md` records the removal reason and serves as the guard against re-adding it.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent](plans/merge-plan-interview-into-plan-agent.md)
