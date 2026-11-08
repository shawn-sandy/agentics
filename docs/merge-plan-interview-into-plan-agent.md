# Merge plan-interview into plan-agent

> Fold the plan-interview plugin into plan-agent v4.0.0, carrying over only the capabilities plan-agent lacked, then de-register and delete plan-interview.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied `documenting-plans`, `markdown-to-html`, `plan-status`, and `deep-grill` skills (plus commands and `plan-documenter` agent) from `plan-interview` into `plan-agent`, preserving directory shape.
- Repointed all `plan-interview:` namespace references and intra-plugin paths to `plan-agent:` in the copied files.
- Folded `update-plan-status`'s bulk mode into the moved `plan-status` skill as a directory/all flag; deleted the standalone command.
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json` as a new `PostToolUse` matcher.
- Repointed `finalize-plan/SKILL.md` and `review-plan/SKILL.md` internal handoffs to the now-local skills.
- De-registered `plan-interview` from `marketplace.json`; bumped `plan-agent` to `4.0.0`.
- Deleted `kit/plugins/plan-interview/` in full (recoverable from git history).
- Added a Removed Plugins row to `.claude/rules/marketplace.md`.
- Updated `CLAUDE.md` from 13 to 12 plugins; removed `plan-interview` from `.claude/settings.json` `enabledPlugins`.
- Repointed three test files; added `4.0.0` CHANGELOG entry with migration mapping table.

> See [CHANGELOG v4.0.0](../kit/plugins/plan-agent/CHANGELOG.md) for the migration map.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/` | Destination for all carried-over components | Modified |
| `kit/plugins/plan-interview/` | Source plugin — deleted after migration | Deleted |
| `.claude-plugin/marketplace.json` | De-registered plan-interview; plan-agent bumped to 4.0.0 | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins table row for plan-interview | Modified |
| `.claude/settings.json` | Removed plan-interview from enabledPlugins | Modified |
| `CLAUDE.md` | Plugin table reduced from 13 to 12 rows | Modified |
| `kit/plugins/plan-agent/README.md` | Replaced plan-interview pairing section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry with plan-interview→plan-agent migration map | Modified |
| `tests/publish/smoke-clean-dist.sh` | Dropped plan-interview from plugin roster | Modified |
| `tests/publish/test-dist-transforms.mjs` | Repointed plan-interview README transform assertion | Modified |
| `tests/plugins/test-save-pdf.sh` | Updated origin comment | Modified |

## How it works

The marketplace shipped two planning plugins that operated as one system split by file format: `plan-interview` authored and maintained Markdown plans; `plan-agent` built and tracked them. The proposal locked three decisions: full merge, de-register and delete, and plan-agent wins every overlap seam.

Carry-over components were chosen by what plan-agent lacked entirely: `documenting-plans` (generates prose docs from completed plans), `markdown-to-html` (renders Markdown specs to plan HTML), `plan-status` (checks and flips plan completion state), and `deep-grill` (node-by-node decision walk, distinct from the review-plan team). Dropped were `plan-interview`, `plan-to-html`, `plan-hygiene`, and `review-rename-plans` — each already covered by plan-agent's built-in interview, `review-plan` team, `validate-plan-filename` hook, and renderer respectively.

Directory shape was preserved during the copy so skill resolution paths stayed consistent. Every `plan-interview:` namespace reference was repointed to `plan-agent:` in skill bodies, command bodies, the `plan-documenter` agent, and cross-links; the only remaining `plan-interview` mentions are CHANGELOG migration notes.

`update-plan-status`'s bulk mode was folded into `plan-status` as a directory/all flag before the standalone command was deleted, keeping one skill with a flag rather than two commands doing the same job.

The ExitPlanMode nudge hook was migrated into `plan-agent/hooks.json` as a `PostToolUse` matcher referencing the built-in Step 5b interview — the last unique capability from `plan-interview/hooks.json`.

Two deviations from the reference plan were noted in the finalization report: scope extended to fix live cross-references in `kit/plugins/README.md`, `product-plans/`, and `social-media-tools/` that pointed at moved command paths; and `test-dist-transforms.mjs`'s assertion was repointed rather than deleted since plan-agent installs via the same `/plugin install <name>@agentics-kit` pattern.

## How to use it

Commands that were `plan-interview:*` are now `plan-agent:*`:

| Old command | New command |
| ----------- | ----------- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

Uninstall `plan-interview@agentics-kit` and ensure `plan-agent >= 4.0.0`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `3056b57` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `5764be8` | 2026-11-05 | fix(plan-agent): drop gallery tabs whose page does not exist (9.22.1) (#670) |

_Showing 10 of 20+ commits — run `git log` for the full history._

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
- Related: [.claude/rules/removed-plugins.md](../.claude/rules/removed-plugins.md)
