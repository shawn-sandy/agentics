# Merge plan-interview into plan-agent

> Fold the `plan-interview` plugin into `plan-agent` v4.0.0, carrying over only the capabilities plan-agent lacked and dropping every redundant overlap, then de-register and delete `plan-interview`.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [merge-plan-interview-into-plan-agent](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Ported `documenting-plans`, `markdown-to-html`, `plan-status`, and `deep-grill` skills plus the `plan-documenter` agent and five commands into `kit/plugins/plan-agent/`.
- Folded `update-plan-status`'s bulk mode into `plan-status` as a directory/all flag and deleted the standalone command.
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json`.
- Repointed all internal handoffs from the `plan-interview:` namespace to `plan-agent:`.
- De-registered `plan-interview` from `marketplace.json`, bumped `plan-agent` to 4.0.0, and deleted the `kit/plugins/plan-interview/` directory.
- Added the `plan-interview` removal row to `.claude/rules/marketplace.md` and updated CLAUDE.md, `.claude/settings.json`, and all affected tests.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/` | Destination plugin — skills, commands, agents, hooks | Modified |
| `kit/plugins/plan-interview/` | Source plugin — deleted after port | Missing (deleted) |
| `.claude-plugin/marketplace.json` | Version manifest | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins table | Modified |
| `.claude/settings.json` | Enabled plugins list | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog | Modified |
| `tests/publish/smoke-clean-dist.sh` | Publish smoke test | Modified |
| `tests/publish/test-dist-transforms.mjs` | Dist transform test | Modified |
| `tests/plugins/test-save-pdf.sh` | PDF test | Modified |

## How it works

**Carry-over port.** Skills `documenting-plans`, `markdown-to-html` (with its assets, reference, and scripts subdirectories), `plan-status`, and `deep-grill` were copied from `plan-interview` into `plan-agent` preserving directory shape. The `plan-documenter` agent and commands `documenting-plans.md`, `plan-maintenance.md`, `markdown-to-html.md`, `plan-status.md`, and `deep-grill.md` were likewise ported. Dropped skills (`plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans`) have no counterpart in `plan-agent` and were not carried over.

**Namespace rewrite.** Every `plan-interview:` skill invocation, command reference, and intra-plugin path in the copied files was rewritten to `plan-agent:`. The only remaining `plan-interview` mentions in `kit/plugins/plan-agent/` are the CHANGELOG 4.0.0 migration note and the README migration map — both are history, not live handoffs.

**Bulk mode folded.** `update-plan-status` offered a bulk directory/all flag that overlapped with `plan-status`. That mode was folded into `plan-status/SKILL.md` as a `--all` flag, and `commands/update-plan-status.md` was not carried into `plan-agent`.

**ExitPlanMode hook merged.** `plan-interview/hooks.json` carried a `PostToolUse` matcher that fired a nudge when the user exited plan mode. The matcher was added to `plan-agent/hooks.json` with its message updated to reference `plan-agent`'s built-in Step 5b interview instead of the former cross-plugin skill.

**Internal handoffs repointed.** `finalize-plan/SKILL.md` was updated so its `plan-interview:plan-status` reference became `plan-agent:plan-status`. `review-plan/SKILL.md` was updated to point at the now-local `deep-grill` skill.

**De-registration and deletion.** The `plan-interview` plugin object was removed from `.claude-plugin/marketplace.json`, `plan-agent` was bumped to 4.0.0 (MAJOR: a plugin is absorbed and the `plan-interview` namespace is removed), and `kit/plugins/plan-interview/` was deleted. The version is recoverable from git history.

**Test and config updates.** `tests/publish/smoke-clean-dist.sh` dropped `plan-interview` from its PLUGINS array and corrected the 13-dir count to 12. `tests/publish/test-dist-transforms.mjs` repointed its `plan-interview` README assertion to the standard `/plugin install <name>@agentics-kit` line. `tests/plugins/test-save-pdf.sh` had its origin comment updated. `.claude/settings.json` had `plan-interview@agentics-kit` removed from `enabledPlugins`. The plan also touched `tests/plugins/test-command-delegation.sh` and cross-references in `kit/plugins/README.md`, `product-plans/`, and `social-media-tools/write-guide` that were not in the original file list but were necessary for correctness.

## How to use it

Previously installed as two separate plugins; now install only `plan-agent`:

```text
/plugin install plan-agent@agentics-kit
```

Command mapping from the old `plan-interview:` namespace:

| Old command | New command |
| --- | --- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

The `plan-interview`, `plan-to-html`, `plan-hygiene`, and `review-rename-plans` skills were dropped; `plan-agent`'s built-in interview, `review-plan` team, and `validate-plan-filename` hook cover their use cases.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `864c144` | 2026-07-17 | refactor(plugins): merge plan-interview into plan-agent 4.0.0 (#426) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent](plans/merge-plan-interview-into-plan-agent.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 4.0.0 entry with migration map
