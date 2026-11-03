# Let `build` author a plan when none is specified

> Replaces `plan-agent:build`'s no-plan dead end with an entry into the existing plan pipeline (proposal → plan → review → implement) and stops discovery from silently adopting a stale spec when the user named no plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-plan-authoring-to-build](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Hoisted the dirty-working-tree precondition before any chain stage in `build/SKILL.md`
- Split Step 1's three no-plan branches: only the empty-discovery branch reaches the chain; named-but-missing-path and HTML-with-no-spec branches still stop
- Changed discovery from silent adoption to an offer (newest-created first, top 3 + "None of these") gated on absent objective
- Widened argument grammar to `[<plan path>] [<objective>] [--dir <path>]` with objective-vs-path disambiguation rule
- Added Step 1b chain: `build-proposal` → `implementation-plan` → re-resolve spec by path; scoped to slash command only (objective is a `$ARGUMENTS` parameter)
- All non-implementing Step 8 choices terminate the outer chain (Exit, Run as workflow)
- Added `model: opus` to `build/SKILL.md` frontmatter
- Updated README, CHANGELOG, CLAUDE.md; bumped `plan-agent` by one MAJOR to next version
- Extended `tests/plugins/test-build-skill.sh` with numbered checks for all new behaviours

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill — chain entry, discovery offer, argument grammar, model pin | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — build row and section updated | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test — chain, discovery, grammar, Exit/workflow termination | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent MAJOR bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — chain entry | Modified |
| `CLAUDE.md` | Repo index — build clause updated | Modified |

## How it works

Before this change, `/plan-agent:build` with no plan file printed a message telling the user to run `/plan-agent:implementation-plan` by hand. The pipeline that instruction pointed at was already wired top-down — `build-proposal` hands off to `implementation-plan`, whose Step 8 menu invokes `review-plan` and `build` as real `Skill()` calls. Only the proposal-to-plan seam remained a printed prompt.

The chain activates only from the slash command, where the objective is an explicit `$ARGUMENTS` parameter. Plain-text "build a todo app" continues using ambient routing unchanged — the trigger word `build` is overloaded enough that inference would pull in compile and CI requests.

When a slash command has no objective and discovery finds candidates, it offers the top three newest plans plus "None of these — author a new plan" via `AskUserQuestion`. When an objective is present, discovery is skipped entirely (unrelated specs are noise), and the chain goes straight to the proposal-vs-direct gate.

The abandonment contract is explicit: if the chain is abandoned between stages (tool error, session drop, user backing out), the proposal file is left in place uncommitted and `build` reports its path rather than cleaning it up.

`model: opus` is pinned in frontmatter because a skill's model override applies for the rest of the turn and does not unwind when the skill ends — pinning `build` re-asserts on activation and gives the source-writing stage a deterministic model.

## How to use it

```
/plan-agent:build a todo app             # enters chain: proposal → plan → review → implement
/plan-agent:build                         # offers discovered plans or enters chain
/plan-agent:build docs/plans/my-plan.md  # existing plan, unchanged path
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build](plans/add-plan-authoring-to-build.md)
- Proposal: `docs/proposals/chain-plan-authoring-into-build.md`
