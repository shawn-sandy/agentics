# Let `build` author a plan when none is specified

> Replaces `plan-agent:build`'s no-plan dead end with an entry into the existing proposal → plan → review → implement pipeline, and stops discovery from silently adopting a stale spec when no plan argument was given.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-plan-authoring-to-build](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- `/plan-agent:build <objective>` (command form only) now enters the plan-authoring chain when no plan file is found — delegating to `build-proposal` then `implementation-plan` rather than printing a dead-end message
- Discovery changed from a silent pickup to an offer: at most three `todo`/`in-progress` candidates are presented plus a "None of these — author a new plan" option; offering is skipped entirely when an objective is supplied
- Dirty-working-tree precondition hoisted to run before any chain stage is invoked
- Named-but-missing and HTML-without-sibling-spec branches kept as explicit stops
- `Skill` added to `allowed-tools`; `model: opus` pinned in frontmatter
- `Exit — I'll implement later` and `Run as workflow` at the chained `implementation-plan`'s Step 8 both terminate the outer chain without starting a build
- `plan-agent` bumped MAJOR to `5.0.0`; README, CHANGELOG, and CLAUDE.md plugin table updated
- `tests/plugins/test-build-skill.sh` extended from 9 to 18 checks

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Chain entry, discovery offer, hoisted guard, `model: opus`, updated argument grammar, Invocation section | Modified |
| `kit/plugins/plan-agent/README.md` | `build` row and section body updated; usage examples show objective-only invocation | Modified |
| `tests/plugins/test-build-skill.sh` | Extended: chain entry, discovery offer, hoisted guard, Exit/workflow termination, pinned model, grammar rule, stop branches, command-only scoping | Modified |
| `.claude-plugin/marketplace.json` | `plan-agent` MAJOR bump (4.x → 5.0.0) | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Entry for the new chain-authoring activation path | Modified |
| `CLAUDE.md` | `build` clause in plugin table | Modified |

## How it works

`build/SKILL.md` previously ended every no-plan branch with a stop message directing the user to run `/plan-agent:implementation-plan` by hand. The pipeline that message pointed at — `build-proposal` → `implementation-plan` → `review-plan` → `build` — was already wired top-down. This plan wires the entry seam.

The dirty-working-tree precondition was hoisted out of the Step 1 preconditions block and placed above all chain logic. Previously it fired only after a full proposal loop and plan interview had completed, surfacing an uncommitted-files prompt at the worst possible moment. Hoisted, it matches the guards-before-mutation pattern used by `ship-autonomous`.

Step 1 now branches on three distinct conditions. The named-but-missing-path branch stops and names the resolution paths it tried. The HTML-with-no-sibling-spec branch stops with its existing message. Only the empty-discovery branch proceeds to Step 1b — the chain entry.

Discovery was changed from a pickup (take whatever was found) to an offer (show it and ask). When an objective is supplied via `$ARGUMENTS`, discovery is skipped entirely: with an explicit goal, unrelated `todo` specs are noise, and `AskUserQuestion`'s four-option cap cannot render an unbounded candidate list anyway. When no objective is present and candidates exist, at most three are shown ranked newest-created-first, plus "None of these — author a new plan", and any suppressed count is stated.

Step 1b carries the chain itself. When no objective is in scope yet (bare `build` that reached "None of these"), an `AskUserQuestion` asks for one before anything else. Then a proposal-versus-direct gate asks whether to run `build-proposal` first or go straight to `implementation-plan`. The proposal path invokes `Skill(skill: "plan-agent:build-proposal")` then passes the produced proposal path to `Skill(skill: "plan-agent:implementation-plan")`. The direct path invokes `implementation-plan` with the objective alone. The return path re-resolves the produced spec by its path rather than re-running discovery. A Tier-0 idea answered directly by `build-proposal` with no document written falls through to the direct path with the original objective.

The chain is reachable only from the slash command: `$ARGUMENTS` is empty on the model-invocation path, so ambient `build <text>` keeps its existing contract — it requires a plan that already exists and routes away without one. This is deliberate: `build` is overloaded enough that any ambient trigger catching "build a todo app" would also catch "build fails on CI".

`model: opus` is pinned in frontmatter so the skill re-asserts the model on activation. Without this pin, a chained run would inherit whatever model `review-plan` or `implementation-plan` last declared, leaving the source-writing stage on a non-deterministic model.

Non-implementing Step 8 choices in the chained `implementation-plan` both terminate the outer chain. `Exit — I'll implement later` leaves the plan at `status: todo` with no source files written. `Run as workflow` stops because the workflow prompt has already been emitted — proceeding would start an in-session build racing the workflow the user just launched. This overrides a clause in the proposal's Appendix A.

The test suite was extended with checks 10 through 18, asserting the chain entry, the discovery offer, the hoisted guard, the Exit-and-workflow termination rule, the pinned model, the objective-versus-path grammar rule, the two surviving stop branches, and the command-only scoping alongside the retained model-path route-away instruction. Reverting any of steps 1, 2, 3, 4, 6, 7, or 8 individually causes the suite to exit 1 naming that check.

## How to use it

Command form — enters the chain when no existing plan is found:

```text
/plan-agent:build a health check endpoint
/plan-agent:build add retry logic to the API client
```

Bare invocation — offers up to three existing `todo` specs or the option to author a new plan:

```text
/plan-agent:build
```

Existing-plan invocations are unchanged:

```text
/plan-agent:build docs/plans/my-plan.md
```

Ambient (model-invocation) activation still requires an existing plan and routes to `/plan-agent:implementation-plan` when there is none.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `8622210` | 2026-07-27 | feat(plan-agent): let build author a plan when none is specified (#470) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build](plans/add-plan-authoring-to-build.md)
- Proposal: `docs/proposals/chain-plan-authoring-into-build.md`
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 5.0.0
