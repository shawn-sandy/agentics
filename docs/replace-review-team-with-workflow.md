# Take plan review off the experimental flag

> Replaces `review-plan`'s Agent Teams engine with a Workflow-tool script, removing the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` hard stop, and adds an adversarial verify pass so high-severity findings are refuted before they become plan edits.

<!-- generated:start -->

**Status:** Shipped 2026-09-01  **Plan:** [replace-review-team-with-workflow](plans/replace-review-team-with-workflow.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs`: a Workflow script with a Review phase (ten `plan-reviewer-*` agents via `agentType`) and a Verify phase (adversarial refutation of `high`/`critical` findings via `parallel()`)
- Rewrote SKILL.md Step 3 as a Workflow-availability check, replacing the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` version-and-flag gate; added `Workflow` to the skill's `allowed-tools` frontmatter
- Collapsed SKILL.md Steps 4–5 into one step that `Read`s `references/review-workflow.mjs` and passes its contents as Workflow's inline `script`
- Rewrote SKILL.md Step 6 to consume typed workflow findings directly into the "Inline Edits to Apply" table; added a Verdict column to `references/output-template.md`
- Deleted `references/role-prompts.md`, now orphaned since reviewer lenses come from `agentType`
- Added `Workflow` to `tools:` in `agents/agent-review-plan.md`
- Created `tests/review-plan-workflow.test.mjs`
- Bumped plan-agent to 9.12.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` | Workflow script — reviewer pipeline, verify stage | Created |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill — new Step 3, collapsed Steps 4–5, typed Step 6 | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` | Role prompts — orphaned by agentType reuse | Deleted |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Template — Verdict column added | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Agent — `Workflow` added to tools | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — reference-file listing updated | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 9.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 9.12.0 | Modified |
| `tests/review-plan-workflow.test.mjs` | Smoke test — structural assertions | Created |

## How it works

`review-plan` runs a ten-reviewer panel to improve plans in place. Its previous engine required `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and Claude Code 2.1.32+. Step 3 was an unconditional hard stop for any user who had not set that flag, making the plugin's most expensive feature effectively dark by default.

The Workflow tool addresses all four problems at once: it needs no feature flag, its `schema` option forces subagents through a `StructuredOutput` tool so findings arrive validated rather than as prose, its `parallel()` resolves a failed agent to `null` rather than throwing (replacing hand-rolled respawn logic with `.filter(Boolean)`), and its `pipeline()` gives a Verify stage that runs as soon as each reviewer finishes — so the slowest chain, not the sum of both stages, determines wall-clock time.

The script reuses the ten `plan-reviewer-*` agents this plugin already ships via `agent()`'s `agentType` parameter, so no agent prompts were rewritten. The Verify stage deliberately omits `agentType` to run as a generic skeptic — a verifier wearing the reviewer's persona would be checking its own work.

By default only `high` and `critical` findings are routed to the Verify stage, keeping the agent count near 18 rather than ~50. A `--deep` token in `args` lifts the severity filter. A `log()` line always names how many findings passed through unverified so bounded coverage does not silently appear as full coverage.

Findings arrive as typed objects carrying `target`, `action`, `content`, `rationale`, `severity`, and `verdict`. The skill's Step 6 reads these directly into the "Inline Edits to Apply" table, eliminating the prose-round-trip where findings were being silently dropped. The output template's findings table gained a Verdict column so the user can see which findings survived refutation and which were never checked.

The Workflow tool's opt-in rule explicitly accepts "a skill whose instructions tell you to call Workflow," which is what makes a plugin skill calling it legitimate.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [replace-review-team-with-workflow](plans/replace-review-team-with-workflow.md)
