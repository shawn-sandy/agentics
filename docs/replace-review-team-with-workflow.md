# Take plan review off the experimental flag

> `review-plan` was dark for anyone who never set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Swapping the engine to a Workflow script removed that gate, returned findings as typed data instead of prose the lead had to re-read, and added a refutation pass before a finding could edit anyone's plan.

<!-- generated:start -->

**Status:** Shipped 2026-09-01 **Plan:** [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs`: a Workflow script with a pure-literal `export const meta` (phases: Review + Verify), a `FINDINGS` schema (`target`, `action`, `content`, `rationale`, `severity`), a `VERDICT` schema (`refuted`, `reason`), and a `pipeline()` over ten reviewer lenses — the first stage calls `agent(prompt, {agentType, phase: 'Review', schema: FINDINGS, label})`, the second refutes findings with `severity` of `high` or `critical` via `parallel()`.
- Added a `--deep` flag that lifts the severity filter so every finding is refuted; a `log()` line names how many findings passed through unverified so silent truncation cannot read as full coverage.
- Rewrote `review-plan` SKILL.md Step 3 as a Workflow-availability probe, eliminating the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` hard stop; added `Workflow` to `allowed-tools`.
- Collapsed Steps 4–5 into one step that `Read`s `references/review-workflow.mjs` and passes its contents as Workflow's inline `script`, dropping the hand-rolled respawn-once prose.
- Rewrote Step 6 so synthesis consumes the workflow's returned typed objects directly into the "Inline Edits to Apply" table; added a Verdict column to `references/output-template.md`.
- Deleted `references/role-prompts.md` (orphaned by `agentType` reuse); updated README.md's reference-file listing.
- Added `Workflow` to `tools:` in `agents/agent-review-plan.md` so the background agent path keeps working.
- Added `tests/review-plan-workflow.test.mjs` asserting SKILL.md contains no `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` token, documents a `Workflow` call, `references/review-workflow.mjs` parses as a workflow body, and `references/role-prompts.md` is absent.
- Bumped plan-agent to 9.12.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` | Workflow script: reviewer pipeline, findings schema, refutation stage | Created |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Availability check, Steps 4–5 collapsed, Workflow in allowed-tools | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` | Orphaned by agentType reuse | Deleted |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Verdict column added | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Workflow added to tools | Modified |
| `kit/plugins/plan-agent/README.md` | Reference-file listing updated | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 9.12.0 | Modified |
| `tests/review-plan-workflow.test.mjs` | Static assertions + workflow-body parse | Created |

## How it works

**Off the experimental flag**: Step 3 probes for the `Workflow` tool with a capability check rather than asserting a minimum Claude Code version. A capability check answers the only question that matters and stays correct as availability changes.

**`agentType` reuse**: `agent()` accepts `agentType`, resolved from the same registry as the `Agent` tool. The ten `plan-reviewer-*` agents the plugin already ships are reused as-is, which is why `role-prompts.md` was deleted — it was no longer needed.

**Pipeline concurrency**: `pipeline()` starts verifying one reviewer's findings while others are still reviewing, so wall-clock time is the slowest single chain rather than the sum of both stages. By default only `high` and `critical` findings are refuted, keeping the run near 18 agents rather than 50.

**Typed findings**: Findings arrive as validated objects through the `schema` option; the prose round-trip where findings were being dropped is gone.

**Live-run verification**: Exercised as a 2-reviewer smoke test (run `wf_356f54f2-3aa`, 5 agents, 0 errors, 288s). `agentType` resolved the shipped agents, findings returned typed with `severity`, the filter routed 3 of 6 findings to skeptics, all 3 were refuted with substantive reasons.

## How to use it

```text
/plan-agent:review-plan docs/plans/<slug>.md
```

No feature flag required. The `--deep` flag verifies every finding. The narrator output includes a line naming how many findings passed through unverified.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-09-01 | refactor(plan-agent): replace Agent Teams with Workflow engine in review-plan, add refutation pass (9.12.0) |

<!-- generated:end -->

## References

- Plan: [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
