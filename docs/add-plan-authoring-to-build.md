# Let `build` author a plan when none is specified

> Replaces the dead end in `/plan-agent:build` with a full proposal-to-implementation chain, so a bare build command can author and execute a plan without re-invoking anything.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Added `Step 1b` chain entry to `build/SKILL.md`: a bare `/plan-agent:build` with no existing plan now enters a proposal → implementation-plan → build pipeline instead of stopping with a routing message.
- Split Step 1's three no-plan branches so only the empty-discovery path reaches the chain; mistyped paths and legacy HTML-only plans still stop with descriptive messages.
- Changed discovery from a silent pickup to an explicit offer, shown only when no objective is supplied; the offer caps at three candidates and states how many were suppressed.
- Widened the argument grammar to `[<plan path>] [<objective>] [--dir <path>]` and added `Skill` to `allowed-tools`.
- Scoped the chain to the slash command only — `/plan-agent:build <objective>` enters the chain; ambient model-invocation keeps its existing route-away contract.
- Pinned `model: opus` in `build/SKILL.md` frontmatter so the source-writing stage has a deterministic model after chained planning skills override it.
- Ensured every non-implementing Step 8 choice (`Exit`, `Run as workflow`) terminates the outer chain, not just the inner skill.
- Extended `tests/plugins/test-build-skill.sh` with 9 new checks covering the chain entry, discovery offer, hoisted guard, grammar rule, stop branches, and command-only scoping.
- Bumped plan-agent to **5.0.0** (MAJOR) in `.claude-plugin/marketplace.json`; added CHANGELOG entry and updated CLAUDE.md.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions — chain entry, discovery offer, argument grammar, model pin | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation — `build` row and section | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test — 9 new checks | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — MAJOR version bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `CLAUDE.md` | Root plugin table — `build` clause | Modified |

## How it works

`build/SKILL.md` Step 1 resolves a plan from an argument, the IDE, `plansDirectory`, or discovery. The change added a lettered sub-step, **Step 1b**, that fires when no plan is found. Step 1b first runs a discovery offer (when no objective was given), then asks a proposal-versus-direct gate, and then delegates entirely to `plan-agent:build-proposal` + `plan-agent:implementation-plan` — no implementation steps are restated inside `build` itself.

Discovery was changed from a silent pickup to a three-candidate offer with an explicit "author a new plan" escape. When an objective is supplied (the slash-command path), discovery is skipped entirely because unrelated specs are noise. The offer requires `AskUserQuestion`; when that tool is unavailable, the skill stops and reports rather than silently adopting a candidate.

The dirty-tree precondition was hoisted before Step 1b so it runs before any chain stage is entered. Left in its original position it would have fired after a full proposal loop had already run, prompting about uncommitted files at the worst possible moment.

The chain is deliberately command-only. `/plan-agent:build a todo app` reads the objective from `$ARGUMENTS`; the same words typed as plain text do not enter the chain because `build` is an overloaded verb and any ambient trigger wide enough to catch it also catches CI and compile requests. The model-invocation path retains its original route-away instruction.

After the chain, two defects caught in post-ship testing were fixed: (1) `Implement now` at Step 8 would have re-entered the already-finished build; (2) a Tier 0 proposal that produces no document left the chain calling `implementation-plan` with a non-existent path. Both were corrected and guarded by additional test checks.

## How to use it

**Skill:** activates on "implements a plan" or via the slash command `/plan-agent:build`.

```
# Enter the chain with an objective
/plan-agent:build add a health check endpoint

# Let discovery offer existing todo plans
/plan-agent:build

# Implement an already-existing plan directly
/plan-agent:build docs/plans/my-feature.md
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
- Related: `docs/proposals/chain-plan-authoring-into-build.md` — the proposal this plan executes
