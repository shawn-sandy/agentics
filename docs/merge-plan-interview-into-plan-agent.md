# Merge plan-interview into plan-agent

> Fold plan-interview into plan-agent v4.0.0 (plan-agent wins every overlap), then de-register and delete plan-interview.

<!-- generated:start -->

**Status:** Shipped 2026-07-17 **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied carried-over components from plan-interview into plan-agent: `documenting-plans`, `markdown-to-html` (with assets, references, and scripts), `plan-status`, and `deep-grill` skills; matching commands; and the `plan-documenter` agent.
- Rewrote every `plan-interview:` namespace reference in the copied files to `plan-agent:`.
- Folded `update-plan-status`'s bulk mode into `plan-status` as a directory/all flag; deleted the standalone `update-plan-status` command.
- Merged the ExitPlanMode nudge hook from plan-interview's `hooks.json` into plan-agent's as a new PostToolUse matcher pointing at plan-agent's built-in Step 5b interview.
- Repointed plan-agent's internal handoffs (`finalize-plan`, `review-plan`) to the now-local skills.
- De-registered plan-interview from `marketplace.json`; bumped plan-agent to 4.0.0; extended plan-agent's description and tags.
- Deleted `kit/plugins/plan-interview/` in full (recoverable from git history).
- Added plan-interview row to `.claude/rules/marketplace.md` Removed Plugins table.
- Updated `CLAUDE.md`: removed plan-interview row, folded capabilities into plan-agent row, changed 13-plugins count to 12.
- Removed `plan-interview@agentics-kit` from `.claude/settings.json` `enabledPlugins`.
- Updated three test files: `smoke-clean-dist.sh` (12-plugin roster), `test-dist-transforms.mjs` (plan-interview assertion repointed), `test-save-pdf.sh` (comment updated).
- Added 4.0.0 CHANGELOG entry with plan-interview → plan-agent migration mapping table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/documenting-plans/` | Carried from plan-interview | Created |
| `kit/plugins/plan-agent/skills/markdown-to-html/` | Carried from plan-interview | Created |
| `kit/plugins/plan-agent/skills/plan-status/` | Carried + bulk flag | Created |
| `kit/plugins/plan-agent/skills/deep-grill/` | Carried from plan-interview | Created |
| `kit/plugins/plan-agent/agents/plan-documenter.md` | Carried from plan-interview | Created |
| `kit/plugins/plan-agent/hooks.json` | ExitPlanMode nudge hook | Modified |
| `kit/plugins/plan-interview/` | Deleted after merge | Deleted |
| `.claude-plugin/marketplace.json` | plan-interview removed, plan-agent 4.0.0 | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins row | Modified |
| `.claude/rules/removed-plugins.md` | plan-interview entry | Modified |
| `CLAUDE.md` | 12 plugins, plan-interview removed | Modified |
| `.claude/settings.json` | plan-interview removed from enabledPlugins | Modified |
| `tests/publish/smoke-clean-dist.sh` | 12-plugin roster | Modified |
| `tests/publish/test-dist-transforms.mjs` | Assertion repointed | Modified |
| `tests/plugins/test-save-pdf.sh` | Comment updated | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry + migration map | Modified |
| `kit/plugins/plan-agent/README.md` | Merged skills section | Modified |

## How it works

The two plugins had been operating as one split system: plan-interview handled documenting, HTML rendering, and status management; plan-agent handled authoring, reviewing, and implementation. The merge carries over only what plan-agent lacked: `documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`, the `plan-documenter` agent, and the ExitPlanMode nudge hook. Dropped as redundant: `plan-interview` (the original interview skill), `plan-to-html`, `plan-hygiene`, and `review-rename-plans`.

The ExitPlanMode hook was the trickiest piece: it nudged users toward plan-interview's interview after leaving plan mode. After the merge, the same nudge points at plan-agent's built-in Step 5b interview, keeping the behavior without the cross-plugin dependency.

## How to use it

Install plan-agent 4.0.0+ and uninstall plan-interview:

```
/plugin install plan-agent@agentics-kit
/plugin uninstall plan-interview@agentics-kit
```

Skill mapping from plan-interview to plan-agent:

| Old | New |
| --- | --- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-17 | refactor: merge plan-interview into plan-agent 4.0.0 — documenting-plans, markdown-to-html, plan-status, deep-grill, ExitPlanMode hook (#423) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
