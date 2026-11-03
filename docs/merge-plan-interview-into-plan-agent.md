# Merge plan-interview into plan-agent

> Fold plan-interview into plan-agent v4.0.0 (plan-agent wins every overlap), then de-register and delete plan-interview.

<!-- generated:start -->

**Status:** Shipped 2026-07-17  **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Ported five unique capabilities from `plan-interview` into `plan-agent`, preserving directory shape: skills `documenting-plans`, `markdown-to-html` (with assets, reference, and scripts), `plan-status`, and `deep-grill`; commands `documenting-plans.md`, `plan-maintenance.md`, `markdown-to-html.md`, `plan-status.md`, and `deep-grill.md`; and the `agents/plan-documenter.md` subagent.
- Rewrote every `plan-interview:` namespace reference in the copied files to `plan-agent:` (skills, commands, the plan-documenter agent, and cross-links).
- Folded `update-plan-status`'s bulk mode into the moved `plan-status` skill as a directory/all flag, then deleted the standalone `update-plan-status` command.
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json` as a new PostToolUse matcher.
- Repointed internal handoffs in `finalize-plan/SKILL.md` and `review-plan/SKILL.md` to the now-local skills.
- De-registered `plan-interview` from `marketplace.json`, bumped plan-agent to 4.0.0, deleted `kit/plugins/plan-interview/` in full, recorded the removal in `.claude/rules/marketplace.md`, updated `CLAUDE.md` (13 → 12 plugins), removed `plan-interview@agentics-kit` from `.claude/settings.json`, and repointed three test files.
- Added a 4.0.0 entry to `plan-agent/CHANGELOG.md` with a `plan-interview`→`plan-agent` migration mapping table; updated `plan-agent/README.md` to replace the Optional plan-interview pairing section.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/` | Destination for carried-over components | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Ported documenting-plans skill | Created |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Ported markdown-to-html skill | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Ported plan-status skill (with bulk flag) | Created |
| `kit/plugins/plan-agent/skills/deep-grill/SKILL.md` | Ported deep-grill skill | Created |
| `kit/plugins/plan-agent/hooks.json` | ExitPlanMode nudge hook added | Modified |
| `.claude-plugin/marketplace.json` | plan-interview removed, plan-agent bumped to 4.0.0 | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins row for plan-interview | Modified |
| `.claude/settings.json` | plan-interview removed from enabledPlugins | Modified |
| `CLAUDE.md` | Plugin table 13 → 12 rows | Modified |
| `kit/plugins/plan-agent/README.md` | plan-interview pairing section replaced | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry with migration map | Modified |
| `tests/publish/smoke-clean-dist.sh` | plan-interview removed from PLUGINS array | Modified |
| `tests/publish/test-dist-transforms.mjs` | plan-interview transform repointed | Modified |
| `tests/plugins/test-save-pdf.sh` | Origin comment updated | Modified |

## How it works

The marketplace previously shipped two planning plugins that operated as one system split by file format: `plan-interview` handled the conversational interview and documentation flows, while `plan-agent` handled implementation planning. A capability audit found that plan-agent's built-in Step 5b interview, `review-plan` team, and `validate-plan-filename` hook covered every `plan-interview` capability except five: `documenting-plans` (structured plan writeup), `markdown-to-html` (rendering), `plan-status` (status tracking), `deep-grill` (node-by-node decision review), and the ExitPlanMode nudge.

The merge follows three decisions locked in the proposal: full merge into plan-agent, de-register plus delete plan-interview (source recoverable from git history), and plan-agent wins every overlap seam. The dropped capabilities — `plan-interview` (the conversational interview), `plan-to-html`, `plan-hygiene`, and `review-rename-plans` — were all covered by existing plan-agent features.

Carrying over `deep-grill` specifically was deliberate: its node-by-node decision walk is a distinct review mode from the `review-plan` team lens, not a subset of it.

The namespace rewrite (`plan-interview:` → `plan-agent:`) was applied exhaustively to skills, commands, agents, and hooks. The CHANGELOG 4.0.0 entry and README migration map intentionally retain `plan-interview:` text as documentation of the old→new mapping.

The ExitPlanMode hook merger preserves the nudge behaviour: after a user exits plan mode, the hook fires a message pointing at plan-agent's built-in interview (`Step 5b`) rather than the deleted plugin's command.

The test changes were broader than the plan listed: `tests/plugins/test-command-delegation.sh` also hardcoded moved command paths and was repointed, as were live cross-references in `kit/plugins/README.md`, `product-plans/`, and `social-media-tools/write-guide`. Historical CHANGELOG entries were left intact as accurate history.

## How to use it

Uninstall the old plugin and ensure plan-agent is at 4.0.0 or later:
```text
/plugin uninstall plan-interview@agentics-kit
/plugin install plan-agent@agentics-kit
```

Command mapping:
| Old | New |
| --- | --- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
