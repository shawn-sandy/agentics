# Merge plan-interview into plan-agent

> Fold plan-interview's unique capabilities into plan-agent v4.0.0, de-register and delete the source plugin, and update all repo touchpoints — consolidating two planning plugins into one.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied the five unique capabilities from `plan-interview` into `plan-agent`: skills `documenting-plans`, `markdown-to-html`, `plan-status`, and `deep-grill`; the `plan-documenter` agent; and commands `documenting-plans`, `plan-maintenance`, `markdown-to-html`, `plan-status`, `update-plan-status`, and `deep-grill` (bulk mode for `update-plan-status` folded into `plan-status` as a directory/all flag; the standalone command deleted).
- Rewrote every `plan-interview:` namespace reference in copied files to `plan-agent:`, including skill bodies, command bodies, agent cross-links, and internal handoffs in `finalize-plan` and `review-plan`.
- Merged the `ExitPlanMode` nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json` as a new `PostToolUse` matcher.
- De-registered `plan-interview` from `marketplace.json`, bumped `plan-agent` to `4.0.0`, and added tags covering the absorbed capabilities.
- Deleted `kit/plugins/plan-interview/` in full (recoverable from git history).
- Added a Removed Plugins row to `.claude/rules/marketplace.md` and updated `CLAUDE.md` to show 12 plugins with no `plan-interview` row.
- Removed `plan-interview@agentics-kit` from `enabledPlugins` in `.claude/settings.json`.
- Repointed three test files and additional cross-references found during execution (beyond the plan's listed scope) in `tests/plugins/test-command-delegation.sh`, `kit/plugins/README.md`, `product-plans/`, and `social-media-tools/`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Ported documenting-plans skill | Created |
| `kit/plugins/plan-agent/skills/deep-grill/SKILL.md` | Ported deep-grill skill | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Ported plan-status skill (with bulk flag) | Created |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Ported markdown-to-html skill | Created |
| `kit/plugins/plan-agent/commands/documenting-plans.md` | Ported command | Created |
| `kit/plugins/plan-agent/commands/plan-maintenance.md` | Ported command | Created |
| `kit/plugins/plan-agent/commands/plan-status.md` | Ported command | Created |
| `kit/plugins/plan-agent/commands/deep-grill.md` | Ported command | Created |
| `kit/plugins/plan-agent/hooks.json` | ExitPlanMode nudge hook merged in | Modified |
| `kit/plugins/plan-interview/` | Entire plugin directory | Deleted |
| `.claude-plugin/marketplace.json` | Removed plan-interview; plan-agent → 4.0.0 | Modified |
| `.claude/settings.json` | Removed plan-interview from enabledPlugins | Modified |
| `CLAUDE.md` | Plugin table 13 → 12 rows | Modified |
| `kit/plugins/plan-agent/README.md` | Replaced plan-interview pairing section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry with migration map | Modified |
| `kit/plugins/README.md` | Removed plan-interview row from marketplace table | Modified |
| `tests/plugins/test-command-delegation.sh` | Repointed plan-interview command references | Modified |
| `tests/publish/smoke-clean-dist.sh` | Repointed plan-interview references | Modified |
| `tests/publish/test-dist-transforms.mjs` | Repointed plan-interview install-line assertion | Modified |
| `kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` | Removed plan-interview cross-reference | Modified |
| `kit/plugins/social-media-tools/skills/write-guide/SKILL.md` | Removed plan-interview cross-reference | Modified |

## How it works

`plan-interview` and `plan-agent` had been operating as complementary halves of one planning system: `plan-agent` authored plans (the interview, implementation, finalization loop) while `plan-interview` provided post-authorship capabilities (documenting, status tracking, markdown-to-HTML conversion, maintenance, and the deep-grill decision review). The decision to merge was made upstream in a proposal that locked three ground rules: full merge into `plan-agent` v4.0.0, delete the source plugin, and `plan-agent` wins every overlap.

Step 1 ported the carry-over components preserving their directory structure inside `kit/plugins/plan-agent/`. The dropped components — `plan-interview` (the interview skill itself), `plan-to-html`, `plan-hygiene`, and `review-rename-plans` — were omitted because `plan-agent`'s built-in interview, `review-plan` team, and `validate-plan-filename` hook already cover them.

Step 3 folded `update-plan-status`'s bulk mode into the moved `plan-status` skill as a directory/all flag, then deleted the standalone command to avoid two commands doing the same job.

The `ExitPlanMode` nudge hook was unique to `plan-interview` and survived by merging into `plan-agent/hooks.json` as a new `PostToolUse` matcher. It now points at `plan-agent`'s built-in Step 5b interview.

Two deviations from the original plan were recorded: the scope extended beyond the three named test files because `tests/plugins/test-command-delegation.sh` also referenced the moved command paths, and `test-dist-transforms.mjs`'s assertion was repointed to the surviving `/plugin install <name>@agentics-kit` line rather than dropped.

## How to use it

Skills previously invoked as `/plan-interview:<skill>` are now `/plan-agent:<skill>`. Migration map:

| Old command | New command |
| ----------- | ----------- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

`plan-interview`, `plan-to-html`, `plan-hygiene`, and `review-rename-plans` were dropped; their functions are covered by `plan-agent`'s built-in interview, `review-plan` team, and `validate-plan-filename` hook.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
