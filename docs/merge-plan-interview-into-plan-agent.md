# Merge plan-interview into plan-agent

> Folded the plan-interview plugin into plan-agent v4.0.0, carrying over only unique capabilities, then de-registered and deleted plan-interview from the marketplace.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
**Type:** refactor

## What shipped

- Copied five carried-over skill directories (`documenting-plans`, `markdown-to-html`, `plan-status`, `deep-grill`, and the related assets) plus six commands and the `plan-documenter` agent from `plan-interview` into `plan-agent`, preserving directory shape.
- Rewrote every `plan-interview:` namespace reference and intra-plugin path in the copied files to `plan-agent:` across skill bodies, command bodies, the agent, and cross-links.
- Folded `update-plan-status`'s bulk mode into the moved `plan-status` skill as a directory/all flag, then deleted the standalone `update-plan-status` command.
- Merged the ExitPlanMode nudge hook from `plan-interview/hooks.json` into `plan-agent/hooks.json` as a new PostToolUse matcher pointing at plan-agent's built-in Step 5b interview.
- Repointed `finalize-plan` and `review-plan` internal handoffs to the now-local skills (eliminating cross-plugin calls to the deleted `plan-interview:`).
- De-registered `plan-interview` from `.claude-plugin/marketplace.json`, bumped `plan-agent` to 4.0.0, and extended its description and tags to cover the absorbed capabilities.
- Deleted the `kit/plugins/plan-interview/` directory in full (source recoverable from git history).
- Added a Removed Plugins row to `.claude/rules/marketplace.md`; removed `plan-interview@agentics-kit` from `.claude/settings.json` `enabledPlugins`; updated `CLAUDE.md` to show 12 plugins.
- Updated three test files: removed `plan-interview` from the `smoke-clean-dist.sh` roster, repointed (not deleted) the transform assertion in `test-dist-transforms.mjs`, and updated the origin comment in `test-save-pdf.sh`.
- Added a 4.0.0 entry to `kit/plugins/plan-agent/CHANGELOG.md` with a plan-interview-to-plan-agent migration mapping table; replaced the "Optional plan-interview pairing" section in `plan-agent/README.md` with the merged skill list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/` | Destination plugin — absorbed carried-over components | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Ported skill — plan documentation generator | Created |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Ported skill — markdown to HTML renderer | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Ported skill — plan status with bulk flag | Created |
| `kit/plugins/plan-agent/skills/deep-grill/SKILL.md` | Ported skill — node-by-node decision walk | Created |
| `kit/plugins/plan-agent/agents/plan-documenter.md` | Ported agent — plan documentation orchestrator | Created |
| `kit/plugins/plan-agent/hooks.json` | Plugin hooks — ExitPlanMode nudge matcher added | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history — 4.0.0 migration map entry | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation — merged skill surface | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 4.0.0, plan-interview removed | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins table — plan-interview row | Modified |
| `.claude/settings.json` | Enabled plugins — plan-interview removed | Modified |
| `CLAUDE.md` | Project docs — plugin count 13 → 12, plan-interview row removed | Modified |
| `tests/publish/smoke-clean-dist.sh` | Smoke test — plan-interview removed from PLUGINS roster | Modified |
| `tests/publish/test-dist-transforms.mjs` | Transform test — plan-interview assertion repointed to plan-agent | Modified |
| `tests/plugins/test-save-pdf.sh` | PDF test — origin comment updated | Modified |

## How it works

The marketplace shipped two planning plugins that operated as one system split by file format. `plan-interview` handled interviewing, documentation, markdown-to-HTML conversion, plan status, deep review, and maintenance; `plan-agent` handled implementation-plan authoring, building, review, and finalization. A decision-complete proposal established three rules: full merge into `plan-agent` v4.0.0, de-register and delete `plan-interview` (recoverable from git), and plan-agent wins every overlap seam.

Step 1 copied the carry-over components preserving directory shape. The four skills with no plan-agent counterpart — `documenting-plans`, `markdown-to-html`, `plan-status`, and `deep-grill` — were copied with their full subtrees (assets, reference files, scripts). The `plan-documenter` agent and six commands were copied alongside. The dropped components — `plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans` — were not carried over, since plan-agent's built-in interview, `review-plan` team, and `validate-plan-filename` hook already covered them.

Step 2 rewrote every `plan-interview:` namespace reference in the copied files to `plan-agent:`. This covered invocation strings in skill bodies, command `$ARGUMENTS` delegations, the `plan-documenter` agent, and cross-links between moved skills. The only permitted survivors were intentional migration notes in the CHANGELOG.

`update-plan-status`'s bulk mode (run status across a directory or all plans) was folded into the `plan-status` skill as a `--dir`/`--all` flag, and the standalone `update-plan-status` command was deleted. One command became zero external commands plus one flag on an existing skill.

The ExitPlanMode nudge hook — a PostToolUse matcher that fired after plan mode exits to suggest next steps — was merged from `plan-interview/hooks.json` into `plan-agent/hooks.json`. The rewording pointed its message at plan-agent's built-in Step 5b interview rather than the now-deleted plan-interview skill.

Steps 5 and 11 repointed internal cross-plugin calls. `finalize-plan/SKILL.md`'s reference to `plan-interview:plan-status` became `plan-agent:plan-status`; `review-plan/SKILL.md`'s conversational stress-test note pointed at the local skill. Test files were updated: `smoke-clean-dist.sh` dropped plan-interview from its PLUGINS array and changed its 13-dir comment to 12; `test-dist-transforms.mjs` repointed (rather than dropped) its assertion to the `/plugin install` line that plan-agent shares with all surviving plugins.

One deviation from the reference plan was noted in the finalization notes: the plan's Step 11 named three test files, but `tests/plugins/test-command-delegation.sh` also hard-referenced moved command paths, and live cross-references existed in `kit/plugins/README.md`, `product-plans/`, and `social-media-tools/`. All were repointed to `plan-agent`; historical CHANGELOG entries were left intact as accurate history.

## How to use it

Skills and commands that previously lived under `plan-interview:` now resolve under `plan-agent:`:

| Old invocation | New invocation |
| -------------- | -------------- |
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |

Users who had `plan-interview@agentics-kit` installed should uninstall it and ensure `plan-agent >= 4.0.0` is installed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [merge-plan-interview-into-plan-agent.md](plans/merge-plan-interview-into-plan-agent.md)
- Related docs: [`kit/plugins/plan-agent/CHANGELOG.md`](../kit/plugins/plan-agent/CHANGELOG.md)
- Related proposal: [`docs/proposals/merge-plan-interview-into-plan-agent.md`](proposals/merge-plan-interview-into-plan-agent.md)
