# Let `build` author a plan when none is specified

> Replaces `plan-agent:build`'s no-plan dead end with an entry into the proposal → plan → review → implement pipeline, and stops discovery from silently adopting a stale spec when the user named no plan.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Hoisted the dirty-working-tree precondition in `build/SKILL.md` to run before any chain stage, preventing the guard from firing mid-pipeline after a full proposal loop.
- Split Step 1's three no-plan branches: only the empty-discovery branch enters the chain; named-but-missing-path and HTML-with-no-sibling-spec branches still stop with their existing messages.
- Changed discovery from a silent pickup to an explicit offer: shows at most three candidates ranked newest-first plus "None of these — author a new plan", stating how many were suppressed. Discovery is skipped entirely when an objective is supplied.
- Widened the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`, added `Skill` to `allowed-tools`, and added `model: opus` to frontmatter so the model is deterministic across a chained run.
- Added Step 1b: the chain entry that invokes `build-proposal` → `implementation-plan`, with an objective prompt for the bare-build path, a return path that resolves the produced spec by path, and a full abandonment contract.
- Made every non-implementing Step 8 choice (`Exit`, `Run as workflow`) terminate the outer chain rather than proceeding.
- Updated `kit/plugins/plan-agent/README.md` to remove all references to the old dead end.
- Bumped `plan-agent` by one MAJOR in `.claude-plugin/marketplace.json` (argument format and discovery behavior changed), added a CHANGELOG entry, and updated the `build` clause in root `CLAUDE.md`.
- Extended `tests/plugins/test-build-skill.sh` with numbered checks for the chain entry, discovery offer, hoisted guard, Exit-terminates-chain rule, pinned model, objective-vs-path grammar, the two surviving stop branches, and command-only scoping.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `CLAUDE.md` | Root plugin table | Modified |

## How it works

`plan-agent:build` previously had three resolution paths — named plan path, discovery of a single existing spec, or a dead end with an instruction to run `/plan-agent:implementation-plan` manually. The pipeline that instruction pointed to was already fully wired top-down (`build-proposal` → `implementation-plan` → `review-plan` → `build`), so the missing piece was just a second entry point.

The design makes the chain reachable **only from the slash command** with the objective as a command parameter read from `$ARGUMENTS`. This narrows the trigger to an explicit invocation and avoids the overloaded-verb problem: plain-text "build a todo app" still matches compile and CI requests, but `/plan-agent:build a todo app` is unambiguous. Ambient activation is deliberately unchanged.

Discovery is now an offer, not a pickup. When a bare `/plan-agent:build` is invoked with no objective, the skill shows at most three candidates ranked newest-`created:` first plus an author-a-new-plan option, stating how many were suppressed. `AskUserQuestion` caps at four options, so the cap is also what keeps the offer renderable in any repo size. When an objective is supplied, discovery is skipped entirely — unrelated existing specs are noise, and the user has already said what they want.

The chain in Step 1b: check for an objective (ask for one if the bare-build path arrived via "None of these"), gate on proposal-vs-direct, invoke `build-proposal` → `implementation-plan` via `Skill()`, resolve the produced spec by path, and return. Non-implementing Step 8 choices terminate the outer chain — `Exit` leaves the plan at `status: todo`, `Run as workflow` leaves the workflow prompt as the terminal output. This prevents `build` from implementing work the user just routed elsewhere.

`model: opus` in frontmatter ensures a deterministic model across the chained run: a skill's `model:` override applies for the rest of the turn and does not unwind when the skill ends, so without the pin the source-writing stage would inherit whatever model the last planning skill declared.

The MAJOR version bump reflects that the argument format changed (objective slot added) and the no-argument discovery behavior changed (silent pickup → explicit offer), per the marketplace versioning rule in `.claude/rules/marketplace.md`.

## How to use it

```text
/plan-agent:build add a health check endpoint
/plan-agent:build
```

Pass an objective to go straight to the proposal-vs-direct gate. A bare invocation shows existing `todo` specs as candidates. Either path reaches the full proposal → plan → implement pipeline.

Plain-text `build ...` without the slash command still requires an existing plan and routes to `/plan-agent:implementation-plan` when there is none — ambient activation is unchanged.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
