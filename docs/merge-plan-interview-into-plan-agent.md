# Merge plan-interview into plan-agent

> Folds the plan-interview plugin into plan-agent v4.0.0, carrying over five unique capabilities and dropping every redundant overlap, then de-registers and deletes the source plugin with source recoverable from git history.

<!-- generated:start -->

**Status:** Shipped 2026-07-17 **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied `documenting-plans`, `markdown-to-html` (with assets, reference, scripts), `plan-status`, and `deep-grill` skills plus the `plan-documenter` agent and five commands into `kit/plugins/plan-agent/`, preserving directory shape (carries over only capabilities plan-agent lacked entirely; `deep-grill` kept for its node-by-node decision walk, distinct from the review-plan team).
- Rewritten every `plan-interview:` namespace reference and intra-plugin path in the copied files to `plan-agent:`, except intentional CHANGELOG migration notes.
- Folded `update-plan-status`'s bulk mode into the moved `plan-status` skill as a directory/all flag, then deleted the standalone `update-plan-status` command.
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json` as a new `PostToolUse` matcher referencing the built-in Step 5b interview.
- De-registered `plan-interview` from `marketplace.json`, bumped plan-agent to 4.0.0 (MAJOR: plugin absorbed, namespace removed), and extended plan-agent's description and tags.
- Deleted `kit/plugins/plan-interview/` in full; source recoverable from git history.
- Added a Removed Plugins row to `.claude/rules/removed-plugins.md` and updated `CLAUDE.md` (13 → 12 plugins), `.claude/settings.json` (removed from `enabledPlugins`), and the three test files.
- Added a 4.0.0 CHANGELOG entry with a plan-interview-to-plan-agent migration mapping table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Carried over from plan-interview | Created |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Carried over from plan-interview | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Carried over from plan-interview; bulk flag added | Created |
| `kit/plugins/plan-agent/skills/deep-grill/SKILL.md` | Carried over from plan-interview | Created |
| `kit/plugins/plan-agent/` | Destination for all carried-over components | Modified |
| `kit/plugins/plan-interview/` | Deleted after unique parts ported | Missing |
| `.claude-plugin/marketplace.json` | De-registers plan-interview; plan-agent → 4.0.0 | Modified |
| `.claude/rules/removed-plugins.md` | plan-interview row added | Modified |
| `.claude/settings.json` | plan-interview removed from enabledPlugins | Modified |
| `CLAUDE.md` | Plugin table 13 → 12 rows | Modified |
| `kit/plugins/plan-agent/README.md` | Replaces plan-interview pairing section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.0.0 entry with migration map | Modified |
| `tests/publish/smoke-clean-dist.sh` | plan-interview dropped from roster; 13-dir comment → 12 | Modified |
| `tests/publish/test-dist-transforms.mjs` | plan-interview README block repointed | Modified |
| `tests/plugins/test-save-pdf.sh` | Line-7 origin comment updated | Modified |

## How it works

The marketplace shipped two planning plugins operating as one system split by file format. The decision to merge locked three choices: full absorption into plan-agent v4.0.0 (MAJOR bump); de-register plus delete plan-interview (source recoverable from git history); and plan-agent wins every overlap — only capabilities plan-agent lacked entirely were ported.

The carry-over set was four skills: `documenting-plans` (skill, command, `plan-documenter` agent), `markdown-to-html` (skill, command, assets, reference, scripts), `plan-status` (skill, command, as legacy `.md` support), and `deep-grill` (skill, command — kept for its node-by-node decision walk). The dropped components — `plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans` — overlapped with plan-agent's built-in interview, `review-plan` team, `validate-plan-filename` hook, and plan-agent's own conversion path.

Namespace rewriting touched every skill body, command body, the plan-documenter agent, and cross-links between moved skills. The CHANGELOG migration note and the README migration map intentionally retain `plan-interview:` as historical documentation; those are the only remaining occurrences under `kit/plugins/plan-agent/`.

The `update-plan-status` command was absorbed into `plan-status` as a bulk flag rather than kept as a separate command. One status skill with a `--all` or directory argument covers the same surface with less surface area.

The ExitPlanMode nudge hook was the only hook unique to plan-interview. It fires when a user exits plan mode and prompts them to run the built-in Step 5b interview before proceeding. Merging it into `plan-agent/hooks.json` as a new `PostToolUse` matcher preserved the behavior without a separate hook file.

Test scope expanded beyond the plan's listed files: `tests/plugins/test-command-delegation.sh` hard-referenced moved command paths; `kit/plugins/README.md`, `product-plans/` (README and `plan-review-agents` SKILL), and `social-media-tools/` (`write-guide`) carried live cross-references. All were repointed. Historical CHANGELOG entries were left intact as accurate history.

## How to use it

Commands previously invoked as `/plan-interview:*` are now invoked as `/plan-agent:*`:

| Old | New |
| --- | --- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `864c144` | 2026-07-17 | refactor(plugins): merge plan-interview into plan-agent 4.0.0 (#426) |
| `b0bd7ad` | 2026-06-07 | feat(plan-interview): add Save as PDF button to HTML plans (#272) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
