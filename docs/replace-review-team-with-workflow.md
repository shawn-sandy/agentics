# Take plan review off the experimental flag

> Replaced `review-plan`'s Agent Teams engine with a Workflow-tool script, removing the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` hard stop and adding an adversarial verify pass for high-severity findings.

<!-- generated:start -->

**Status:** Shipped 2026-09-01  **Plan:** [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` — a Workflow script with two phases: Review (ten `plan-reviewer-*` agents running in parallel via `pipeline()`) and Verify (skeptic agents refuting high/critical findings via `parallel()`).
- Rewrote `review-plan` SKILL.md Step 3 from an `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` version-and-flag gate to a Workflow-availability probe, and added `Workflow` to `allowed-tools`.
- Collapsed Steps 4–5 into one step that `Read`s the workflow script and passes its contents inline to `Workflow`, avoiding the `${CLAUDE_PLUGIN_ROOT}` expansion trap.
- Extended the synthesis step (Step 6) to consume typed findings directly into the "Inline Edits to Apply" table (previously, findings arrived as free text requiring manual re-parsing).
- Added a `verdict` column to `references/output-template.md`.
- Deleted `references/role-prompts.md` (orphaned — the workflow reuses the shipped `plan-reviewer-*` agents via `agentType` rather than re-authoring their prompts).
- Added `Workflow` to `agents/agent-review-plan.md` `tools:` (the background-agent invocation path).
- Added `tests/review-plan-workflow.test.mjs` with static assertions and a parse of the workflow script body.
- Bumped plan-agent to 9.12.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` | Workflow script — reviewer pipeline + refutation stage | Created |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill — engine swap, allowed-tools updated | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Template — verdict column added | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` | Reference file — orphaned, deleted | Missing |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Agent — Workflow added to tools | Modified |
| `tests/review-plan-workflow.test.mjs` | Test — static assertions on the new engine | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 9.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 9.12.0 | Modified |

## How it works

The original engine required `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` plus Claude Code 2.1.32+. Since most users never set this flag, the plugin's ten-reviewer panel was effectively dark for everyone. The Workflow tool needs no feature flag and its availability is probed at runtime rather than hard-coding a version number.

The workflow script uses `pipeline()` to pipe each reviewer's findings directly to a skeptic in the Verify phase as soon as they finish, rather than waiting for all reviewers to complete. This means the slowest chain determines wall-clock time, not the sum of all phases. By default, only `high` and `critical` findings are routed through the verify pass (roughly 18 agents per review instead of ~50); `--deep` lifts the filter.

Findings arrive as typed data via the `schema` option (`{assessment, findings}` with `target`, `action`, `content`, `rationale`, `severity` per finding), eliminating the prose round-trip where findings were previously re-parsed and sometimes silently dropped.

The reviewer lenses are the shipped `plan-reviewer-*` agents, reused via `agentType` rather than re-authored prompts — which is why `role-prompts.md` became orphaned and was deleted. The verify pass deliberately omits `agentType` so skeptics run as generic agents, providing independent refutation rather than the reviewer checking their own work.

A `log()` line in the script names how many findings passed through unverified, so the review never silently reads as full coverage when it was not.

## How to use it

```bash
/plan-agent:review-plan docs/plans/my-plan.md
# With exhaustive verification of all findings:
/plan-agent:review-plan docs/plans/my-plan.md --deep
```

The skill activates when a user asks to review, improve, or stress-test a plan. After running, the Workflow panel shows two phases (Review, Verify) with per-reviewer and per-verifier agents. Step 6 synthesizes typed findings into an edit table with Verdict column showing which passed refutation.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `43a7fd92` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `88a686a9` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
