# Let `build` author a plan when none is specified

> Replaces `plan-agent:build`'s no-plan dead end with an entry into the existing proposal → plan → review → implement pipeline, and stops discovery from silently adopting stale specs.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Added a chain entry (Step 1b) to `build/SKILL.md`: `/plan-agent:build <objective>` invokes `build-proposal` → `implementation-plan` → returns with the produced spec path.
- Changed discovery from a silent pickup to an offer: shows up to 3 candidates plus "None of these — author a new plan"; with an objective present, discovery is skipped entirely.
- Hoisted the dirty-working-tree precondition before any chain stage is invoked.
- Widened the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`, treating a leading token as an objective only when it has no `.md`/`.html` suffix and no `/`.
- Scoped the chain to the slash command only — `$ARGUMENTS` is empty on the model-invocation path, which keeps its existing route-away contract.
- Added `model: opus` to frontmatter; added `Skill` to `allowed-tools`.
- Extended `tests/plugins/test-build-skill.sh` with checks covering the chain entry, discovery offer, hoisted guard, Step 8 exit-terminates-chain, pinned model, objective-vs-path grammar, and the two surviving stop branches.
- Bumped `plan-agent` to `5.0.0` (MAJOR — argument format and activation behavior change) in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `CLAUDE.md` | Root plugin reference table | Modified |

## How it works

The chain is reachable only from the slash command (`/plan-agent:build <objective>`), because `$ARGUMENTS` is empty on the ambient model-invocation path and the overloaded verb "build" would conflict with compile/CI requests if triggered from free text.

With an objective supplied, discovery is skipped and Step 1b runs immediately: a proposal-vs-direct gate asks whether to author through `build-proposal` or go straight to `implementation-plan`, then delegates with the objective, and resolves the produced spec by path on return.

Choosing `Exit` or `Run as workflow` at `implementation-plan`'s Step 8 terminates the outer chain — the outer `build` does not implement work the user just declined or routed to a workflow.

The `model: opus` pin ensures the source-writing stage has a deterministic model regardless of what planning or review skills set during the chain, since model overrides are turn-scoped.

## How to use it

`/plan-agent:build <objective>` — starts a plan authoring pipeline. `/plan-agent:build` alone (no objective) shows up to 3 existing `todo` candidates or enters the chain after asking for an objective.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
