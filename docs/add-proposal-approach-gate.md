# Add the approach gate to build-proposal

> `build-proposal` researched an idea, synthesized one core finding, and went straight to per-decision questions, so the proposal it authored was written around an approach the human never chose from a menu. This adds a Step 4b gate that lays out two to four candidate solutions, records the pick as the first locked decision, and authors only the chosen one.

<!-- generated:start -->

**Status:** Shipped 2026-09-13 **Plan:** [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
**Type:** feature

## What shipped

- Inserted `### Step 4b — Choose the approach (the second gate)` into `skills/build-proposal/SKILL.md` after Step 4: one recommendation-first `AskUserQuestion` with two to four candidates including the baseline "keep the current approach"; the pick recorded as the first Locked decision; rejected candidates kept in the Side-by-side; Steps 5 and 6 scoped to the chosen approach; Tier 1 placement rule; Other-answer rule.
- Adjusted Step 3 to draft candidate solutions alongside the core finding; Step 5 to ask only questions the chosen approach raises; tier table note; guardrail count to eleven.
- Updated `references/artifact-shape.md`: Side-by-side is now dimension × candidate with the baseline column; Locked decisions opens with the pick; Tier 1 note updated.
- Updated `references/operating-principles.md`: principle 11 "Choose the approach before authoring"; heading count; `AskUserQuestion` row names Step 4b.
- Updated plugin README, root README, and `docs/guides/how-to/plan-agent.md`.
- Added check 16 to `tests/plugins/test-build-proposal.sh` pinning the gate.
- Bumped plan-agent 9.17.2 → 9.18.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Step 4b gate | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Candidate comparison shape | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/operating-principles.md` | Principle 11 | Modified |
| `kit/plugins/plan-agent/README.md` | build-proposal section | Modified |
| `README.md` | Plugin Reference Table regenerated | Modified |
| `docs/guides/how-to/plan-agent.md` | "What happens" bullet | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.18.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.17.2 → 9.18.0 | Modified |
| `tests/plugins/test-build-proposal.sh` | Check 16 for Step 4b | Modified |

## How it works

After research settles the facts (Step 4), the skill presents two to four candidate solutions in one recommendation-first `AskUserQuestion`. The baseline "keep the current approach" is always one candidate, so the menu never collapses to a single option. The pick is recorded as the first Locked decision in the proposal, naming what it was chosen over. Rejected candidates stay in the Side-by-side comparison table so a reader can understand the tradeoffs.

Steps 5 and 6 are then scoped to the chosen approach only — no questions about paths not taken. At Tier 1, which omits both the Locked decisions table and the Side-by-side, the pick rides as the closing line of `{{CONTEXT}}` with no slot change. The proposal prompt's existing slots (`{{LOCKED_DECISIONS}}`, `{{COMPARISON_TABLE}}`) are unchanged.

## How to use it

```
/plan-agent:build-proposal
```

The gate fires automatically at Tier 1 and Tier 2. At Tier 3 and above, the slot carries the pick. Pass an approach description to skip the interactive question on a re-run.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a2b40163` | 2026-09-13 | feat(plan-agent): approach gate in build-proposal — choose before authoring (9.18.0) |

<!-- generated:end -->

## References

- Plan: [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
