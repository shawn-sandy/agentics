# Merge plan-interview into plan-agent

> Folds the plan-interview plugin into plan-agent v4.0.0, carrying over five unique capabilities (documenting-plans, markdown-to-html, plan-status, deep-grill, ExitPlanMode hook) and deleting plan-interview from the marketplace and the filesystem.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied the carry-over skills (`documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`), the `plan-documenter` agent, and six commands into `kit/plugins/plan-agent/`
- Rewrote every `plan-interview:` namespace reference in the copied files to `plan-agent:`
- Merged `update-plan-status`'s bulk mode into `plan-status` as a directory/all flag; deleted the standalone command
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json`
- Repointed `finalize-plan` and `review-plan` internal handoffs to the now-local skills
- De-registered `plan-interview` from `marketplace.json`; bumped `plan-agent` to 4.0.0
- Deleted `kit/plugins/plan-interview/` in full
- Added a Removed Plugins row to `.claude/rules/marketplace.md`
- Removed the `plan-interview` row from `CLAUDE.md` (13 plugins → 12)
- Removed `plan-interview@agentics-kit` from `.claude/settings.json` `enabledPlugins`
- Updated the three affected test files and rewrote `kit/plugins/plan-agent/CHANGELOG.md` with a 4.0.0 migration mapping table
- Updated `kit/plugins/plan-agent/README.md` to replace the Optional plan-interview pairing section

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/` | Destination for carried-over components | Modified |
| `kit/plugins/plan-interview/` | Source plugin — removed after porting | Deleted |
| `.claude-plugin/marketplace.json` | De-register plan-interview; bump plan-agent to 4.0.0 | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins row for plan-interview | Modified |
| `.claude/settings.json` | Drop plan-interview from enabledPlugins | Modified |
| `CLAUDE.md` | Plugin table 13 → 12 rows | Modified |
| `kit/plugins/plan-agent/README.md` | Replace plan-interview pairing section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry with migration map | Modified |
| `tests/publish/smoke-clean-dist.sh` | Drop plan-interview from roster | Modified |
| `tests/publish/test-dist-transforms.mjs` | Remove plan-interview README block | Modified |
| `tests/plugins/test-save-pdf.sh` | Update origin comment | Modified |

## How it works

The marketplace previously shipped two planning plugins that operated as one system split by file format: `plan-agent` handled structured plan authoring while `plan-interview` layered documentation, maintenance, and status-tracking on top. The decision-complete proposal locked three decisions: full merge into plan-agent v4.0.0, de-register and delete plan-interview (source recoverable from git history), and plan-agent wins every overlap — only unique capabilities are ported.

The five carried-over components were: `documenting-plans` (skill, command, and `plan-documenter` agent), `plan-maintenance` (command), `markdown-to-html` (skill, command, and assets), `plan-status` (skill and command, as legacy `.md` support), and `deep-grill` (skill and command — kept for its node-by-node decision walk, a mode the `review-plan` team does not cover). The ExitPlanMode nudge hook was merged into `plan-agent/hooks.json` as a new PostToolUse matcher rewording its message to point at the built-in Step 5b interview.

Dropped components — `plan-interview`, `plan-to-html`, `plan-hygiene`, and `review-rename-plans` — were not carried over because plan-agent's own interview, `review-plan` team, and `validate-plan-filename` hook cover their roles.

Two deviations from the reference plan were recorded in the finalization notes. First, `tests/plugins/test-command-delegation.sh` and cross-references in `kit/plugins/README.md`, `product-plans/`, and `social-media-tools/` also hardcoded plan-interview paths; all were repointed to plan-agent. Historical CHANGELOG entries were left intact as accurate history. Second, the `test-dist-transforms.mjs` assertion for the `marketplace add` line unique to plan-interview's README was repointed to plan-agent's standard install line rather than deleted, since that line exists on all surviving plugins.

The MAJOR version bump (3.x → 4.0.0) reflects that a plugin namespace was absorbed and plan-interview's command surface is removed. Users migrating from plan-interview can find the full `/plan-interview:* → /plan-agent:*` command mapping in `kit/plugins/plan-agent/CHANGELOG.md`.

## How to use it

The formerly separate `plan-interview` commands are now available under the `plan-agent` namespace:

- `/plan-agent:documenting-plans` — document a completed plan
- `/plan-agent:markdown-to-html` — render a Markdown plan to HTML
- `/plan-agent:plan-status` — check or update plan status; pass `--all` for bulk updates
- `/plan-agent:plan-maintenance` — run maintenance tasks on a plan
- `/plan-agent:deep-grill` — node-by-node decision walk for a proposal or plan

Uninstall `plan-interview@agentics-kit` and ensure `plan-agent >= 4.0.0`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/423
- Proposal: [docs/proposals/merge-plan-interview-into-plan-agent.md](proposals/merge-plan-interview-into-plan-agent.md)
