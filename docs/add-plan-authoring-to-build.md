# Let `build` author a plan when none is specified

> Replaces `plan-agent:build`'s no-plan dead end with an entry into the existing proposal → plan → review → implement pipeline, reachable only from the `/plan-agent:build <objective>` slash command.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Added `Step 1b` to `build/SKILL.md` — the no-plan chain: objective check → proposal-vs-direct gate → `plan-agent:build-proposal` → `plan-agent:implementation-plan` → resolve spec by path.
- Hoisted the dirty-working-tree precondition ahead of all chain stages so it fires before any plan authoring begins.
- Changed discovery from a silent pickup to an offer: presents up to three newest `status: todo` candidates plus `None of these — author a new plan`; suppressed count stated; skipped entirely when an objective is supplied.
- Widened argument grammar to `[<plan path>] [<objective>] [--dir <path>]` with a leading-token heuristic: no `.md`/`.html` suffix and no `/` means objective, not path.
- Added `Skill` to `allowed-tools` and `model: opus` to frontmatter.
- Scoped the chain to the slash command only — ambient activation (model-invocation path) still requires an existing plan.
- Both non-implementing Step 8 choices (`Exit — I'll implement later` and `Run as workflow`) terminate the outer chain.
- `AskUserQuestion` unavailability fallback specified: stop and report rather than silently auto-resolve.
- Bumped plan-agent from 4.4.0 to 5.0.0 (MAJOR — argument format and discovery behavior changed).
- Extended `tests/plugins/test-build-skill.sh` with 9 new checks (18 total).
- Updated `kit/plugins/plan-agent/README.md`, `CHANGELOG.md`, and root `CLAUDE.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Core build skill | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test (extended to 18 checks) | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 5.0.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 5.0.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | build row and section updated | Modified |
| `CLAUDE.md` | build clause updated | Modified |

## How it works

**The chain is command-only.** `/plan-agent:build <objective>` passes the objective as `$ARGUMENTS`. The model-invocation path has no `$ARGUMENTS`, so the chain is never entered from ambient routing. This is deliberate: `build` is overloaded enough that a trigger wide enough for `build a todo app` also catches `build fails on CI` and `rebuild the index`.

**Discovery is an offer, not a pickup.** Without an objective, `build` shows up to three newest `status: todo` candidates plus `None of these — author a new plan`. With an objective, discovery is skipped entirely — unrelated specs in the repo are noise, and `AskUserQuestion` caps at four options anyway.

**Step 1b chains into existing skills, restating nothing.** The no-plan chain calls `plan-agent:build-proposal` (for the proposal path) or `plan-agent:implementation-plan` (for the direct path) by name. It does not reimplement their gates. `implementation-plan`'s Step 8 menu drives the execution decision; the outer chain terminates on `Exit` or `Run as workflow`.

**The dirty-tree guard is hoisted.** It runs before any chain stage — plan authoring writes files, and an unclean tree should surface before a proposal loop not after it. Plan artifacts (the spec `.md` and rendered `.html`) are explicitly excluded so the guard does not re-fire on the Step 8 callback when `implementation-plan` writes back.

**`model: opus` is pinned.** A skill's model override applies for the rest of the turn and does not unwind when the skill ends. Pinning ensures the source-writing stage of a chained run uses a deterministic model regardless of which planning skill last ran.

**Abandoned chains leave artifacts in place.** If the chain is abandoned between stages (tool error, session drop, user backing out), the proposal file is left uncommitted and `build` reports its path rather than cleaning up.

## How to use it

```
/plan-agent:build add a health check endpoint
```

Bare invocation (resume interrupted work):
```
/plan-agent:build
```

Pass a specific plan:
```
/plan-agent:build docs/plans/my-plan.md
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
