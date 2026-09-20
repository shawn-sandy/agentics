# Merge plan-interview into plan-agent

> Fold plan-interview into plan-agent v4.0.0 (plan-agent wins every overlap), then de-register and delete plan-interview.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copy the carry-over components from plan-interview into plan-agent preserving directory shape: skills documenting-pla...
- Rewrite every `plan-interview:` namespace reference and intra-plugin path in the copied files to `plan-agent:` — skil...
- Fold update-plan-status's bulk mode into the moved plan-status skill as a directory/all flag, then delete the standal...
- Merge the ExitPlanMode nudge hook from plan-interview/hooks.json into plan-agent/hooks.json as a new PostToolUse matc...
- Repoint plan-agent's internal handoffs to the now-local skills: finalize-plan/SKILL.md (plan-interview:plan-status be...
- De-register plan-interview from marketplace.json by removing its plugin object, bump plan-agent version to 4.0.0, and...
- Delete the kit/plugins/plan-interview/ directory in full.
- Add a Removed Plugins row to .claude/rules/marketplace.md recording plan-interview, 2026-07-17, merged into plan-agen...
- Update CLAUDE.md by deleting the plan-interview plugin-table row, folding its surviving capabilities into the plan-ag...
- Remove plan-interview@agentics-kit from enabledPlugins in .claude/settings.json.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude-plugin/marketplace.json` | de-register plan-interview, bump plan-agent to 4.0.0 | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins row | Modified |
| `.claude/settings.json` | drop plan-interview from enabledPlugins | Modified |
| `CLAUDE.md` | plugin table 13 to 12 rows | Modified |
| `kit/plugins/plan-agent/README.md` | replace plan-interview pairing section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry with migration map | Modified |
| `tests/publish/smoke-clean-dist.sh` | drop plan-interview from roster | Modified |
| `tests/publish/test-dist-transforms.mjs` | remove plan-interview README block | Modified |
| `tests/plugins/test-save-pdf.sh` | update plan-interview origin comment | Modified |

## How it works

Fold the `plan-interview` plugin into `plan-agent` (bumped to v4.0.0), carrying over only the capabilities plan-agent lacks and dropping every redundant overlap, then de-register and delete `plan-interview` and update all repo touchpoints.

The marketplace ships two planning plugins that already operate as one system split by file format. The decision-complete proposal at [docs/proposals/merge-plan-interview-into-plan-agent.md](../proposals/merge-plan-interview-into-plan-agent.md) locks three decisions: **(1)** full merge into `plan-agent` v4.0.0, **(2)**

The implementation proceeded through these steps: Copy the carry-over components from plan-interview into plan-agent preserving directory shape: skills documenting-pla...; Rewrite every `plan-interview:` namespace reference and intra-plugin path in the copied files to `plan-agent:` — skil...; Fold update-plan-status's bulk mode into the moved plan-status skill as a directory/all flag, then delete the standal...; Merge the ExitPlanMode nudge hook from plan-interview/hooks.json into plan-agent/hooks.json as a new PostToolUse matc...; Repoint plan-agent's internal handoffs to the now-local skills: finalize-plan/SKILL.md (plan-interview:plan-status be....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/423
