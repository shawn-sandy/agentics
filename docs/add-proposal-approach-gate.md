# Add the approach gate to build-proposal

> Inserts a `Step 4b — Choose the approach` gate into `build-proposal` so that, once research has settled the facts, the skill presents candidate solutions for selection and writes the proposal around the selected one.

<!-- generated:start -->

**Status:** Shipped 2026-09-13  **Plan:** [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
**Type:** feature

## What shipped

- Inserted `### Step 4b — Choose the approach (the second gate)` into `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` after Step 4: one recommendation-first `AskUserQuestion` with two to four candidates including the baseline "keep the current approach," the pick recorded as the first Locked decision naming what it was chosen over, rejected candidates kept in the Side-by-side table, Steps 5 and 6 scoped to the pick.
- Adjusted Step 3 to draft candidate solutions alongside the core finding; Step 5 to ask only the questions the chosen approach raises; the tier section to state that Step 4b fires at Tier 1 and Tier 2; and the guardrail count sentence to read eleven.
- Updated `references/artifact-shape.md`: Side-by-side now compares candidates including the baseline column; Locked decisions opens with the approach pick; Tier 1 note updated.
- Updated `references/operating-principles.md`: added principle 11 "Choose the approach before authoring"; updated the AskUserQuestion row to name Step 4b.
- Updated `kit/plugins/plan-agent/README.md` (loop bullet and Step 4b bullet in build-proposal section), root `README.md` (build-proposal row), and `docs/guides/how-to/plan-agent.md` ("What happens" bullet).
- Added check 16 to `tests/plugins/test-build-proposal.sh` pinning the gate contract.
- Bumped plan-agent to 9.18.0 in `.claude-plugin/marketplace.json`; added 9.18.0 CHANGELOG entry; regenerated root README Plugin Reference Table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Step 4b inserted; Steps 3, 5, tier table, guardrail count adjusted | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Candidate comparison columns; Locked decisions pick; Tier 1 note | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/operating-principles.md` | Principle 11; AskUserQuestion row; heading count | Modified |
| `kit/plugins/plan-agent/README.md` | build-proposal section updated | Modified |
| `README.md` | Plugin Reference Table (regenerated); build-proposal row | Modified |
| `docs/guides/how-to/plan-agent.md` | "What happens" bullet | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.18.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.18.0 | Modified |
| `tests/plugins/test-build-proposal.sh` | Check 16 — approach gate contract | Modified |

## How it works

Before this change, `build-proposal` ran an 8-step loop (Frame, Confirm, Research, Synthesize, Separate, Resolve, Author, Deepen, Converge) where Step 3 collapsed research into a single core finding and Step 5 asked per-decision questions. The human never picked between whole candidate solutions — the proposal that Step 6 authored was built around whichever approach the synthesis happened to favour.

The gate is a lettered sub-step following the `Step 1b` precedent rather than a ninth numbered step (which would have failed the existing check 6 assertion on exactly eight `### Step [1-8] —` headings).

At Step 4b, the skill presents two to four candidates in one recommendation-first `AskUserQuestion`. The baseline "keep the current approach" is always one candidate, so the menu never collapses to a single option. The pick is recorded as the first entry in `{{LOCKED_DECISIONS}}` and names what it was chosen over. Rejected candidates stay visible in the Side-by-side comparison table so the rationale is documented.

At Tier 1 (the saved prompt), the pick rides in the existing `{{LOCKED_DECISIONS}}` and `{{COMPARISON_TABLE}}` slots and as the closing line of `{{CONTEXT}}`, so no new prompt slot was needed and the two existing prompt slot tests are unaffected.

Step 5's per-decision questions are now scoped to the chosen approach — only questions that apply to the pick are asked. This keeps the interview focused rather than asking about trade-offs that belong to rejected candidates.

## How to use it

The gate fires automatically at Tier 1 and Tier 2 runs of `/plan-agent:build-proposal`. After research completes, the skill presents the candidate solutions before drafting any proposal content.

```
/plan-agent:build-proposal                       # triggers research → Step 4b approach gate → proposal
/plan-agent:build-proposal add caching           # explicit objective passed through
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `a2b4016` | 2026-09-13 | feat(plan-agent): build-proposal chooses an approach before it authors (9.18.0) (#634) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — v9.18.0 entry
