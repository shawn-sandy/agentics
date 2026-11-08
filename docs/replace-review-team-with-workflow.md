# Take plan review off the experimental flag

> Replace `review-plan`'s Agent Teams engine with a Workflow-tool script, removing the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` hard stop, and adding an adversarial verify pass so high-severity findings are refuted before they become plan edits.

<!-- generated:start -->

**Status:** Shipped 2026-09-01  **Plan:** [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` — a Workflow script with a `Review` phase (10 reviewer agents via `agentType`) and a `Verify` phase (refutation of high/critical findings via `parallel()`).
- Rewrote SKILL.md Step 3 from a version-and-flag gate to a Workflow-availability probe, and added `Workflow` to `allowed-tools`.
- Collapsed Steps 4 and 5 into one step that `Read`s the script and passes its contents inline to the `Workflow` tool (avoiding `${CLAUDE_PLUGIN_ROOT}` expansion issues).
- Added a `verdict` column to `references/output-template.md`'s findings table and rewrote Step 6 to consume typed objects rather than parsed prose.
- Deleted `references/role-prompts.md` (orphaned by `agentType` reuse); updated README and added `Workflow` to `agents/agent-review-plan.md`'s `tools:`.
- Bumped plan-agent to 9.12.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` | Workflow script — `meta`, `FINDINGS` schema, `VERDICT` schema, `pipeline()` over reviewers with `Verify` stage | Created |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill instructions — Step 3 becomes availability check; Steps 4–5 collapse; `Workflow` in `allowed-tools` | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` | Reviewer prompts — orphaned by `agentType` reuse | Deleted |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Synthesis template — `verdict` column added to findings table | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Background agent — `Workflow` added to `tools:` | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README — reference-file listing updated | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 9.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 9.11.0 → 9.12.0 | Modified |
| `tests/review-plan-workflow.test.mjs` | Static assertions — parses script as workflow body, checks SKILL.md tokens | Created |

## How it works

Before this change, `review-plan` required `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and Claude Code 2.1.32+. Step 3 was an unconditional hard stop for anyone who had not set that flag. The feature was dark for most users.

The Workflow tool addresses the structural problems directly. It needs no feature flag. Its `schema` option forces subagents through a `StructuredOutput` tool so findings arrive validated (not parsed from prose). Failed agents resolve to `null` via `parallel()` rather than throwing, replacing hand-rolled respawn logic with `.filter(Boolean)`. And `pipeline()` enables a Verify stage that runs as soon as each reviewer's findings are ready.

The `review-workflow.mjs` script exports a pure-literal `meta` object with `phases: [{title: 'Review'}, {title: 'Verify'}]`. The `FINDINGS` schema defines a top-level `{assessment, findings}` object; each finding carries `target`, `action`, `content`, `rationale`, and `severity` (critical/high/medium/low). The `VERDICT` schema carries `refuted` boolean plus `reason`. Reviewers are resolved via `agentType` pointing at the ten shipped `plan-reviewer-*` agents, so none were rewritten. By default only `high` and `critical` findings are refuted (keeping the stage near 18 agents rather than ~50); a `--deep` flag lifts the filter. A `log()` line names how many findings passed through unverified.

The Workflow tool's opt-in rule explicitly accepts "a skill whose instructions tell you to call Workflow," which is what makes this invocation legitimate. The skill `Read`s the script contents and passes them inline to avoid the `${CLAUDE_PLUGIN_ROOT}` expansion that makes path-based invocations fail in this repo.

The Verify stage uses a generic skeptic (no `agentType`) rather than the reviewer's own lens, ensuring independence. The timestamp for `## Team Review (YYYY-MM-DD HH:MM UTC)` stays in the main session's Step 7, since `Date.now()` and `new Date()` throw inside a workflow script.

> See [CHANGELOG v9.12.0](kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## How to use it

`review-plan` now works with no flags set:

```bash
# Full 10-reviewer review (no experimental flag required)
/plan-agent:review-plan docs/plans/my-plan.md

# Deep review — every finding refuted, not just high/critical
/plan-agent:review-plan --deep docs/plans/my-plan.md
```

The workflow progress is visible in `/workflows`. Returned findings carry `severity` and `verdict` fields. The unverified-count log line appears in narrator output.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `5764be8` | 2026-11-05 | fix(plan-agent): drop gallery tabs whose page does not exist (9.22.1) (#670) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `58f14cd` | 2026-10-30 | feat(design-system-tools): add customize-design and align-design-md skills (0.3.0) (#666) |
| `cc28a20` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `2f8b101` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `174d0ef` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `86412c3` | 2026-10-26 | fix(git-agent): finish post-merge-cleanup inside an app session's worktree (4.23.1) (#657) |
| `82227d6` | 2026-10-20 | feat(mcp-tools): add plugin with fix-playwright-mcp skill (0.1.0) (#655) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `052d88c` | 2026-10-08 | refactor(git-agent): commit-agent pushes without asking (4.23.0) (#646) |
| `6a6cf33` | 2026-09-28 | feat(design-system-tools): add plugin with from-design-md skill (0.1.0) (#643) |
| `3056b57` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |

<!-- generated:end -->

## References

- Plan: [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 9.12.0 entry
