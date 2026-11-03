# Add the approach gate to build-proposal

> Inserts a `Step 4b — Choose the approach` gate into `build-proposal/SKILL.md` so that, once research has settled the facts, the skill presents candidate solutions for selection and writes the proposal around the chosen one.

<!-- generated:start -->

**Status:** Shipped 2026-09-13  **Plan:** [add-proposal-approach-gate](plans/add-proposal-approach-gate.md)
**Type:** feature

## What shipped

- Added Step 4b to `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` between research completion and proposal writing
- Step 4b presents 2–4 candidate approaches via `AskUserQuestion`, each with a one-line rationale; the user selects one and the proposal is written around the chosen approach
- Research steps that don't settle the approach are marked as inconclusive rather than silently picking a default
- Bumped `plan-agent` with CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Skill — Step 4b approach selection gate | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |

## How it works

A proposal that does not acknowledge alternative approaches is a hidden decision. Before this change, `build-proposal` ran research and immediately wrote the proposal — the approach was implicitly whatever the research suggested first. This left the user unable to steer the proposal toward a different implementation strategy without re-running the whole skill.

Step 4b fires after Step 4 (research) settles the facts. The skill synthesizes the candidate approaches that research uncovered (typically 2–4), assigns each a one-line rationale, and presents them via `AskUserQuestion`. The user's selection becomes the anchor for Step 5 (proposal writing): the proposal is written around the chosen approach, with the alternatives mentioned briefly in a Rejected Approaches section.

When research doesn't clearly distinguish approaches (undifferentiated options), Step 4b notes this and proceeds with the best-evidenced option rather than manufacturing a false choice.

## How to use it

The approach gate fires automatically during `/plan-agent:build-proposal`. After the research phase completes, Claude presents the candidate approaches and waits for selection before writing the proposal.

```
/plan-agent:build-proposal <topic>    # research → approach selection → proposal
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `4e9f21a` | 2026-09-13 | feat(plan-agent): add approach gate to build-proposal |

<!-- generated:end -->

## References

- Plan: [add-proposal-approach-gate](plans/add-proposal-approach-gate.md)
