# Merge plan-interview into plan-agent

> Folds plan-interview into plan-agent v4.0.0, carrying over documenting-plans, plan-maintenance, markdown-to-html, plan-status, deep-grill, and the ExitPlanMode hook; drops all redundant overlaps; de-registers and deletes plan-interview.

<!-- generated:start -->

**Status:** Shipped 2026-07-17  **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied carry-over skills from plan-interview into plan-agent: `documenting-plans`, `markdown-to-html` (with assets, reference, scripts), `plan-status`, `deep-grill`; plus the `plan-documenter` agent and the `plan-maintenance`, `documenting-plans`, `markdown-to-html`, `plan-status`, `update-plan-status`, and `deep-grill` commands.
- Rewrote all `plan-interview:` namespace references in copied files to `plan-agent:`; merged `update-plan-status` bulk mode into plan-status as a `--all` flag and deleted the standalone command.
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json` as a new PostToolUse matcher.
- Repointed `finalize-plan/SKILL.md` and `review-plan/SKILL.md` internal handoffs to the now-local skills.
- De-registered plan-interview from `.claude-plugin/marketplace.json`; bumped plan-agent to `4.0.0`.
- Added the plan-interview removal row to `.claude/rules/marketplace.md`.
- Updated `CLAUDE.md` to 12 plugins with no plan-interview row; removed plan-interview from `.claude/settings.json` `enabledPlugins`.
- Updated `tests/publish/smoke-clean-dist.sh`, `tests/publish/test-dist-transforms.mjs`, and `tests/plugins/test-save-pdf.sh`; repointed live cross-references in `kit/plugins/README.md`, `product-plans/`, and `social-media-tools/`.
- Deleted `kit/plugins/plan-interview/` in full.
- Added CHANGELOG 4.0.0 entry with plan-interview → plan-agent migration mapping table; updated `kit/plugins/plan-agent/README.md`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/documenting-plans/` | Skill (carried over) | Created |
| `kit/plugins/plan-agent/skills/markdown-to-html/` | Skill (carried over) | Created |
| `kit/plugins/plan-agent/skills/plan-status/` | Skill (carried over) | Created |
| `kit/plugins/plan-agent/skills/deep-grill/` | Skill (carried over) | Created |
| `kit/plugins/plan-agent/agents/plan-documenter.md` | Agent (carried over) | Created |
| `kit/plugins/plan-agent/hooks.json` | Plugin hooks | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/` | Plugin source | Deleted |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `.claude/rules/marketplace.md` | Removed plugins table | Modified |
| `CLAUDE.md` | Plugin table | Modified |
| `.claude/settings.json` | Enabled plugins | Modified |
| `tests/publish/smoke-clean-dist.sh` | Smoke test | Modified |
| `tests/publish/test-dist-transforms.mjs` | Transform test | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

The marketplace shipped two planning plugins that already operated as one system split by file format. `plan-agent` handled planning and generation; `plan-interview` handled documentation, status tracking, and rendering. The merge brings all capabilities under one plugin and one namespace.

The carry-over rule applied decision 3 from the proposal: plan-agent wins every overlap seam. Components with no plan-agent counterpart (`documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`) were ported. Components that duplicated existing plan-agent functionality (`plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans`) were dropped.

The bulk status update that previously lived in a separate `update-plan-status` command was folded into the moved `plan-status` skill as an `--all` flag, consolidating two overlapping commands into one.

The ExitPlanMode nudge hook was unique to plan-interview and had no counterpart. It was merged into plan-agent's `hooks.json` as a PostToolUse matcher, reworded to point at plan-agent's built-in Step 5b interview.

plan-interview's source is deleted but recoverable from git history, following the same pattern as the six prior plugin removals. The Removed Plugins table in `.claude/rules/marketplace.md` records it as a confirmation gate against re-addition.

## How to use it

Skills previously at `/plan-interview:*` are now at `/plan-agent:*`:

| Old command | New command |
|-------------|-------------|
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
