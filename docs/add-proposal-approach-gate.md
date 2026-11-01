# Add the approach gate to build-proposal

> Inserts a `Step 4b — Choose the approach` gate into `build-proposal` so that, once research has settled the facts, the skill presents candidate solutions for selection and authors the proposal around the chosen one.

<!-- generated:start -->

**Status:** Shipped 2026-09-13  **Plan:** [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
**Type:** feature

## What shipped

- Added `### Step 4b — Choose the approach (the second gate)` to `build-proposal/SKILL.md` after Step 4: one recommendation-first `AskUserQuestion` with two to four candidates (always including the baseline "keep the current approach"), the pick recorded as the first Locked decision naming what it was chosen over, rejected candidates kept in the Side-by-side, Steps 5 and 6 scoped to the pick.
- Adjusted Step 3 to draft candidate solutions alongside the core finding; adjusted Step 5 to ask only the questions the chosen approach raises; updated the tier table note and guardrail count (now eleven).
- Updated `references/artifact-shape.md`: Side-by-side compares candidates (dimension by candidate, with baseline column); Locked decisions opens with the pick; Tier 1 note updated.
- Updated `references/operating-principles.md`: principle 11 *Choose the approach before authoring*; AskUserQuestion row names Step 4b; heading count updated.
- Updated the plugin README `build-proposal` section, root README `build-proposal` row, and `docs/guides/how-to/plan-agent.md` "What happens" bullet.
- Added check 16 to `tests/plugins/test-build-proposal.sh` pinning the gate, principle, and artifact-shape changes.
- Bumped plan-agent to **9.18.0** in `.claude-plugin/marketplace.json`; added CHANGELOG entry; regenerated root README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Skill — Step 4b, adjusted Steps 3 and 5, guardrail count | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Reference — candidate Side-by-side, Locked decisions pick, Tier 1 note | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/operating-principles.md` | Reference — principle 11, AskUserQuestion row | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `README.md` | Root Plugin Reference Table (regenerated) | Modified |
| `docs/guides/how-to/plan-agent.md` | How-to guide — build-proposal bullet | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history — 9.18.0 | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — 9.17.2 → 9.18.0 | Modified |
| `tests/plugins/test-build-proposal.sh` | Smoke test — check 16 | Modified |

## How it works

Before this change, `build-proposal`'s eight-step loop collapsed research into a single core finding (Step 3) and then immediately asked per-decision questions (Step 5). The proposal was written around whichever solution the synthesis favoured — the user had no opportunity to choose between approaches before authoring began.

Step 4b sits between the synthesis and the per-decision questions. Step 3 now drafts candidate solutions alongside the core finding. Step 4b presents them in a single `AskUserQuestion` call in recommendation-first order, always including the baseline. The selected approach is recorded as the first Locked decision (naming what it was chosen over), and the rejected candidates are preserved in the Side-by-side comparison table. Step 5 then asks only the questions relevant to the chosen approach.

The gate fires at Tier 1 and Tier 2. At Tier 1 (which omits the saved prompt's `{{LOCKED_DECISIONS}}` and `{{COMPARISON_TABLE}}` slots), the pick rides as the closing line of `{{CONTEXT}}`. This avoids touching the saved prompt's slot list, which two existing test files pin.

The `tests/plugins/test-build-proposal.sh` check 6 asserts exactly eight `### Step [1-8] —` headings. The gate is a lettered sub-step (`4b`), following the existing `Step 1b` precedent, so it does not change that count.

## How to use it

**Skill:** activates on "write a proposal" or via `/plan-agent:build-proposal`.

```
/plan-agent:build-proposal add multi-tenancy to the auth service
```

At Step 4b, the skill presents 2–4 candidate approaches (always including "keep current approach" as the baseline) and waits for a selection before authoring any proposal content.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `a2b40163` | 2026-09-13 | feat(plan-agent): build-proposal chooses an approach before it authors (9.18.0) (#634) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-proposal-approach-gate.md](plans/add-proposal-approach-gate.md)
