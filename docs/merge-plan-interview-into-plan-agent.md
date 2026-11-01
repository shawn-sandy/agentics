# Merge plan-interview into plan-agent

> plan-interview was folded into plan-agent v4.0.0: unique capabilities were ported, every redundant overlap was dropped, and the plan-interview plugin was de-registered and deleted.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied `documenting-plans`, `markdown-to-html`, `plan-status`, and `deep-grill` skills plus the `plan-documenter` agent and associated commands from `plan-interview` into `plan-agent`, preserving directory shape.
- Rewrote all `plan-interview:` namespace references in ported files to `plan-agent:`.
- Folded `update-plan-status`'s bulk mode into the moved `plan-status` skill as a directory/all flag; deleted the standalone `update-plan-status` command.
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json` as a new PostToolUse matcher.
- Repointed plan-agent's internal handoffs (`finalize-plan`, `review-plan`) to the now-local skills.
- De-registered plan-interview from `marketplace.json`, bumped plan-agent to 4.0.0, and updated description and tags.
- Deleted `kit/plugins/plan-interview/` in full (source recoverable from git history).
- Added the plan-interview Removed Plugins row to `.claude/rules/marketplace.md`.
- Updated `CLAUDE.md` to 12 plugins with no plan-interview row.
- Removed `plan-interview@agentics-kit` from `enabledPlugins` in `.claude/settings.json`.
- Updated three test files and added a 4.0.0 CHANGELOG entry with a migration mapping table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/` | Destination for all ported components | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Ported from plan-interview | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Ported from plan-interview, with bulk flag | Created |
| `kit/plugins/plan-agent/skills/deep-grill/SKILL.md` | Ported from plan-interview | Created |
| `kit/plugins/plan-agent/hooks.json` | ExitPlanMode nudge hook added | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry with migration map | Modified |
| `kit/plugins/plan-agent/README.md` | Replaced plan-interview pairing section | Modified |
| `.claude-plugin/marketplace.json` | plan-interview removed; plan-agent → 4.0.0 | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins row for plan-interview | Modified |
| `.claude/settings.json` | plan-interview removed from enabledPlugins | Modified |
| `CLAUDE.md` | Plugin table 13 → 12 rows | Modified |
| `tests/publish/smoke-clean-dist.sh` | plan-interview dropped from PLUGINS array | Modified |
| `tests/publish/test-dist-transforms.mjs` | plan-interview transform block replaced | Modified |
| `tests/plugins/test-save-pdf.sh` | Origin comment updated | Modified |

## How it works

The marketplace shipped two planning plugins operating as one system split by file format. `plan-interview` held the `documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`, `plan-maintenance` skills and the ExitPlanMode nudge hook, while `plan-agent` held the authoring and build surface. The decision to merge was locked in the proposal at `docs/proposals/merge-plan-interview-into-plan-agent.md`: full merge into `plan-agent` v4.0.0, with plan-agent winning every overlap.

The porting pass copied each unique capability under the same directory shape it had in plan-interview, then rewrote every `plan-interview:` namespace reference in the copied files to `plan-agent:`. The only surviving `plan-interview` mentions are the CHANGELOG 4.0.0 migration note (old→new mapping table) and the README migration map — both are documentation, not live invocations.

`update-plan-status` was a standalone command in plan-interview for bulk status updates. Rather than porting it separately, its bulk-mode logic was folded into the moved `plan-status` skill as a `--directory`/`--all` flag. `plan-agent:plan-status` now handles both single-plan and bulk flows.

The ExitPlanMode nudge hook survived as a new PostToolUse matcher in `plan-agent/hooks.json`. It fires after a user exits plan mode and points at plan-agent's built-in Step 5b interview rather than the now-deleted plan-interview one. The hook is validated by `python3 -c "import json; json.load(open('kit/plugins/plan-agent/hooks.json'))"`.

The four dropped components (`plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans`) were not carried over — plan-agent's built-in interview, `review-plan` team, and `validate-plan-filename` hook cover them. Plan-agent's CHANGELOG 4.0.0 entry includes the full old→new mapping table for installed users to migrate.

The finalization notes record two deviations: scope expanded beyond the listed files (some test and cross-reference files needed updating), and one test assertion was repointed rather than deleted. Both are documented in the plan.

## How to use it

Commands previously under `plan-interview:` are now available under `plan-agent:`:

| Old | New |
| --- | --- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

Uninstall `plan-interview@agentics-kit` and ensure `plan-agent >= 4.0.0`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392f` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `58f14cd9` | 2026-10-30 | feat(design-system-tools): add customize-design and align-design-md skills (0.3.0) (#666) |
| `cc28a20d` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `2f8b101b` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `174d0efc` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `82227d62` | 2026-10-20 | feat(mcp-tools): add plugin with fix-playwright-mcp skill (0.1.0) (#655) |
| `1c315692` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/423
