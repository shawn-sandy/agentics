# Add the approach gate to build-proposal

> Inserts a Step 4b gate into `build-proposal` that presents two to four candidate solutions before authoring begins, so proposals are built around an approach the user explicitly chose rather than one the synthesis happened to favour.

<!-- generated:start -->

**Status:** Shipped 2026-09-13  **Plan:** [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
**Type:** feature

## What shipped

- Inserted `### Step 4b — Choose the approach (the second gate)` into `build-proposal/SKILL.md` between Step 4 and Step 5: one recommendation-first `AskUserQuestion` with two to four candidates (always including the *keep the current approach* baseline), the pick recorded as the first Locked decision naming what it was chosen over, and Steps 5 and 6 scoped to the chosen approach.
- Adjusted Step 3 to draft candidate solutions alongside the core finding, Step 5 to ask only questions the chosen approach raises, the tier section to fire Step 4b at Tier 1 and Tier 2, and the guardrail count to eleven.
- Updated `references/artifact-shape.md`: Side-by-side table now compares candidates by dimension with the baseline column, Locked decisions opens with the pick.
- Updated `references/operating-principles.md`: principle 11 *Choose the approach before authoring*, AskUserQuestion row names Step 4b.
- Extended `tests/plugins/test-build-proposal.sh` with check 16 pinning the gate.
- Updated plugin README, root README Plugin Reference Table (regenerated), and `docs/guides/how-to/plan-agent.md`.
- Bumped `plan-agent` to `9.18.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Artifact shape reference | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/operating-principles.md` | Principles reference | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `README.md` | Root Plugin Reference Table | Modified |
| `docs/guides/how-to/plan-agent.md` | How-to guide | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-build-proposal.sh` | Smoke test | Modified |

## How it works

Before this change, `build-proposal` collapsed research into a single core finding at Step 3, then asked per-decision questions at Step 5 — nowhere did the user pick between whole approaches. The synthesis simply favoured whichever solution it converged on.

Step 4b inserts a selection gate after the facts are settled and before any proposal content is authored. Step 3 now drafts two to four candidate solutions alongside the core finding; Step 4b presents them in one recommendation-first `AskUserQuestion`. The baseline *keep the current approach* is always one candidate, so the menu never collapses to a single option and needs no escape hatch.

The chosen approach becomes the first Locked decision, naming what it was chosen over. Rejected candidates remain in the Side-by-side table for reference. Step 5 then asks only the questions the chosen approach raises, and Step 6 authors from the pick rather than from whatever the synthesis happened to favour.

At Tier 1 (no `LOCKED_DECISIONS`/`COMPARISON_TABLE` slots), the pick is appended as the closing line of `{{CONTEXT}}`, so the saved prompt still carries the decision in any tier.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `a2b4016` | 2026-09-13 | feat(plan-agent): build-proposal chooses an approach before it authors (9.18.0) (#634) |

<!-- generated:end -->

## References

- Plan: [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
