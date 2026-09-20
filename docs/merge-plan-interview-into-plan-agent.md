# Merge plan-interview into plan-agent

> Fold plan-interview into plan-agent v4.0.0 (plan-agent wins every overlap), then de-register and delete plan-interview.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copy the carry-over components from plan-interview into plan-agent preserving directory shape: skills documenting-plans, markdown-to-html (with its assets, reference, scripts), plan-status, and deep-grill; commands documenting-plans.md, plan-maintenance.md, markdown-to-html.md, plan-status.md, update-plan-status.md, deep-grill.md; and agents/plan-documenter.md.
- Rewrite every `plan-interview:` namespace reference and intra-plugin path in the copied files to `plan-agent:` — skill bodies, command bodies, the plan-documenter agent, and cross-links between the moved skills.
- Fold update-plan-status's bulk mode into the moved plan-status skill as a directory/all flag, then delete the standalone update-plan-status command just copied.
- Merge the ExitPlanMode nudge hook from plan-interview/hooks.json into plan-agent/hooks.json as a new PostToolUse matcher, rewording its message to point at plan-agent's built-in Step 5b interview.
- Repoint plan-agent's internal handoffs to the now-local skills: finalize-plan/SKILL.md (plan-interview:plan-status becomes plan-agent:plan-status) and review-plan/SKILL.md (conversational stress-test note points at the local skill or built-in interview).
- De-register plan-interview from marketplace.json by removing its plugin object, bump plan-agent version to 4.0.0, and extend plan-agent's description and tags to cover the absorbed documenting, maintenance, markdown-to-html, and status capabilities.
- Delete the kit/plugins/plan-interview/ directory in full.
- Add a Removed Plugins row to .claude/rules/marketplace.md recording plan-interview, 2026-07-17, merged into plan-agent 4.0.0, source recoverable from git history.
- Update CLAUDE.md by deleting the plan-interview plugin-table row, folding its surviving capabilities into the plan-agent row, and changing the 13-plugins count to 12.
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

The marketplace ships two planning plugins that already operate as one system split by file format. The decision-complete proposal at [docs/proposals/merge-plan-interview-into-plan-agent.md](../proposals/merge-plan-interview-into-plan-agent.md) locks three decisions: **(1)** full merge into `plan-agent` v4.0.0, **(2)** de-register + delete `plan-interview` (recoverable from git history, matching

The implementation proceeded through the following steps: Copy the carry-over components from plan-interview into plan-agent preserving directory shape: skills documenting-plans, markdown-to-html (with its assets, reference, scripts), plan-status, and deep-grill; commands documenting-plans.md, plan-maintenance.md, markdown-to-html.md, plan-status.md, update-plan-status.md, deep-grill.md; and agents/plan-documenter.md. Why: these have no plan-agent counterpart and decision 3 ports only unique capability — deep-grill is kept for its node-by-node decision walk, a mode the review-plan team does not cover. Verify: `ls kit/plugins/plan-agent/skills/` shows documenting-plans, markdown-to-html, plan-status, and deep-grill, and the agent plus commands exist under plan-agent.; Rewrite every `plan-interview:` namespace reference and intra-plugin path in the copied files to `plan-agent:` — skill bodies, command bodies, the plan-documenter agent, and cross-links between the moved skills. Why: invocations and internal links must resolve under the new plugin namespace. Verify: `grep -rn "plan-interview:" kit/plugins/plan-agent/` returns nothing except the intentional CHANGELOG migration note.; Fold update-plan-status's bulk mode into the moved plan-status skill as a directory/all flag, then delete the standalone update-plan-status command just copied. Why: one status skill with a bulk flag beats two commands doing the same job. Verify: plan-status SKILL.md documents the bulk flag and `kit/plugins/plan-agent/commands/update-plan-status.md` does not exist.; Merge the ExitPlanMode nudge hook from plan-interview/hooks.json into plan-agent/hooks.json as a new PostToolUse matcher, rewording its message to point at plan-agent's built-in Step 5b interview. Why: the post-plan-mode nudge is unique and must survive the deletion. Verify: plan-agent/hooks.json contains an ExitPlanMode matcher referencing the built-in interview and `python3 -c "import json; json.load(open('kit/plugins/plan-agent/hooks.json'))"` exits 0.; Repoint plan-agent's internal handoffs to the now-local skills: finalize-plan/SKILL.md (plan-interview:plan-status becomes plan-agent:plan-status) and review-plan/SKILL.md (conversational stress-test note points at the local skill or built-in interview). Why: the old cross-plugin handoffs now resolve in-plugin. Verify: `grep -rn "plan-interview" kit/plugins/plan-agent/skills/` returns nothing.; De-register plan-interview from marketplace.json by removing its plugin object, bump plan-agent version to 4.0.0, and extend plan-agent's description and tags to cover the absorbed documenting, maintenance, markdown-to-html, and status capabilities. Why: MAJOR bump since a plugin is absorbed and the plan-interview namespace is removed. Verify: `python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); assert 'plan-interview' not in [p['name'] for p in m['plugins']]; assert next(p for p in m['plugins'] if p['name']=='plan-agent')['version']=='4.0.0'"` exits 0 and the jq hook reports marketplace.json valid..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/423
