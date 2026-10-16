# Take Plan Review Off the Experimental Flag

> Plan review currently hides behind an experimental feature flag, so most users who ask for it get a hard stop instead of a review. Swapping the engine to a Workflow script removes that gate, returns findings as typed data instead of prose the lead has to re-read, and adds a refutation pass before a finding is allowed to edit anyone's plan.

<!-- generated:start -->

**Status:** Shipped 2026-09-01  **Plan:** [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
**Type:** refactor

## What shipped

- Replaced `review-plan`'s Agent Teams engine with a Workflow-tool script, removing the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` hard stop at Step 3 and making the feature available to all users.
- Wrote `references/review-workflow.mjs`: a pipeline over the ten `plan-reviewer-*` agents using `agent()` with `agentType`, a typed `FINDINGS` schema (per-finding `target`, `action`, `content`, `rationale`, `severity`), and a two-stage pipeline where the second stage refutes `high` and `critical` findings via `parallel()`.
- Added a `--deep` flag that lifts the severity filter so every finding is refuted, and a `log()` line that names how many findings passed through unverified.
- Rewrote SKILL.md Step 3 as a Workflow-availability probe (capability check, not version number), and added `Workflow` to `allowed-tools`.
- Collapsed SKILL.md Steps 4 and 5 into one step that reads the workflow script inline and passes it to the Workflow tool, avoiding the `${CLAUDE_PLUGIN_ROOT}` expansion trap.
- Rewired Step 6 to consume typed finding objects directly into the Inline Edits table, eliminating the prose round-trip where findings could be silently dropped.
- Added a `verdict` column to `references/output-template.md`'s findings table.
- Deleted `references/role-prompts.md` (orphaned by `agentType` reuse), updated `README.md`, and granted `Workflow` to `agents/agent-review-plan.md`.
- Added `tests/review-plan-workflow.test.mjs` with static assertions; bumped `plan-agent` to 9.12.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` | Workflow script — reviewer pipeline, findings schema, refutation stage | Created |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill definition — Workflow availability check, collapsed steps, `allowed-tools` | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Output template — verdict column in findings table | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Agent definition — `Workflow` added to `tools:` | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — `role-prompts.md` reference removed | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 9.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 9.11.0 → 9.12.0 | Modified |
| `tests/review-plan-workflow.test.mjs` | Test — static assertions for the workflow-based review | Created |

## How it works

`review-plan` is a ten-reviewer panel skill that improves plans in place. Before this change, Step 3 contained an unconditional stop unless `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` was set and Claude Code 2.1.32+ was running — a flag users were never told about. The feature was effectively invisible.

The Workflow tool addresses all four problems at once. It needs no feature flag, only a capability probe. Its `schema` option forces subagents through a `StructuredOutput` tool, so findings arrive as validated objects rather than prose the lead re-parses into a table. Its `parallel()` resolves a failed agent to `null` rather than throwing, replacing the hand-rolled "respawn once, then mark unavailable" logic with a `.filter(Boolean)`. And its `pipeline()` gives a second stage that refutes each high- or critical-severity finding as soon as its reviewer finishes, without waiting for the full first stage.

`review-workflow.mjs` exports a `meta` object with two named phases (`Review` and `Verify`) and a `pipeline()` over the reviewer list. The first stage calls `agent()` with `agentType` pointing at each `plan-reviewer-*` agent this plugin already ships, a `FINDINGS` schema, and a per-reviewer label. The second stage filters to `severity: high` or `severity: critical` and refutes each finding via `parallel()` with a generic skeptic agent — deliberately without `agentType`, so the verifier does not wear the claimant's persona and checks work independently. `log()` names how many findings passed through unverified; `--deep` lifts the filter.

Reviewer agents are reused as-is via `agentType`, which orphaned `references/role-prompts.md` — that file existed only to give agents their reviewing personas, which `agentType` now supplies from the agent registry. SKILL.md was rewritten to `Read` the workflow script at runtime and pass its contents inline as the Workflow `script` parameter. This sidesteps the `${CLAUDE_PLUGIN_ROOT}` expansion that makes path-based Workflow invocations unrunnable in this plugin layout. The timestamp in the `## Team Review` section stays in the main session's Step 7 because `Date.now()` throws inside a Workflow script.

The test `tests/review-plan-workflow.test.mjs` follows the `check(name, cond)` pattern from `tests/review-plan-skill.test.mjs` and asserts the static structure: no `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` token in SKILL.md, `Workflow` documented in `allowed-tools`, the workflow script exists and parses as a valid async function body, and `role-prompts.md` is absent. Live verification was performed as a 2-reviewer smoke test, confirming that `agentType` resolved the shipped agents, findings returned typed with `severity`, the severity filter routed 3 of 6 findings to skeptics, all 3 were refuted and dropped, and the coverage line appeared in the narrator output.

## How to use it

Run `/plan-agent:review-plan <path/to/plan.md>` in any session without setting any environment variables. Step 3 probes for the `Workflow` capability — if present, the review runs; if not, it reports unavailable. Pass `--deep` to refute every finding regardless of severity (approximately 50 agent calls for a ten-reviewer run vs. the default ~18). The returned findings table includes a `verdict` column showing which findings survived refutation and which were unverified.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 43a7fd9 | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |

<!-- generated:end -->

## References

- Plan: [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
