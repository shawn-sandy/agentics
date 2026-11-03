# Replace Agent Teams with a Workflow engine for plan review

> Removes the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` hard stop from review-plan and replaces it with a `review-workflow.mjs` Workflow script that runs ten plan-reviewer agents through a pipeline with an adversarial verify stage.

<!-- generated:start -->

**Status:** Shipped 2026-09-01  **Plan:** [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
**Type:** refactor

## What shipped

- Removed the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` hard stop from `review-plan/SKILL.md`.
- Added `review-workflow.mjs` — a `Workflow` script using `pipeline()` over the ten `plan-reviewer-*` agents; uses `FINDINGS` schema (`{assessment, findings[{target, action, content, rationale, severity}]}`) and `VERDICT` schema (`{refuted boolean, reason}`).
- Verify stage refutes only `high`/`critical` findings by default; passes `--deep` to refute all findings.
- Added a `log()` line stating how many findings passed through unverified.
- Deleted `references/role-prompts.md` (orphaned by `agentType` reuse).
- Added `Workflow` to the allowed-tools list and `agent-review-plan.md` tools.
- Added `tests/review-plan-workflow.test.mjs`.
- Bumped plan-agent to `9.12.0` in `.claude-plugin/marketplace.json`.
- Live verification: 2-reviewer smoke test run `wf_356f54f2-3aa`, 5 agents, 288 seconds.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/review-plan/review-workflow.mjs` | Workflow script | Created |
| `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` | Role prompts | Deleted |
| `kit/plugins/plan-agent/skills/review-plan/agent-review-plan.md` | Agent review | Modified |
| `tests/review-plan-workflow.test.mjs` | Workflow test | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

The prior `review-plan` skill gated itself behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, which was never promoted to stable. Any user without the flag saw a hard stop instead of a review. The refactor replaces the flag-gated team with a Workflow script that runs unconditionally.

The `pipeline()` call in `review-workflow.mjs` fans out to all ten `plan-reviewer-*` agents in parallel. Each agent returns a `FINDINGS` object. The verify stage then runs adversarial verification on `high` and `critical` findings only (by default), asking a separate agent to try to refute each one. Only findings that survive verification are included in the final output.

The `--deep` flag lowers the threshold to all findings. The `log()` line after verification records how many findings were passed through without adversarial scrutiny, so the caller knows the confidence level of the final report.

`Date.now()` is forbidden inside Workflow scripts (non-determinism), so the timestamp for the review report remains in the main session Step 7, outside the workflow boundary.

`role-prompts.md` was deleted because the refactor reuses `agentType` directives instead of manually injecting role prompts, making the file orphaned dead code.

The 2-reviewer smoke test (`wf_356f54f2-3aa`) ran 5 agents in 288 seconds and produced a structurally valid output, confirming the pipeline wiring before the full 10-reviewer configuration was committed.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |

<!-- generated:end -->

## References

- Plan: [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
