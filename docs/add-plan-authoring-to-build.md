# Let build author a plan when none is specified

> `/plan-agent:build` with an objective argument now chains into the existing proposal → plan → review pipeline instead of dead-ending; discovery presents candidates as an offer rather than adopting a spec silently. This was a MAJOR version bump (plan-agent 5.0.0).

<!-- generated:start -->

**Status:** Shipped 2026-07-27 **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Replaced `build`'s no-plan dead end with a Step 1b chain entry that invokes `build-proposal` then `implementation-plan` with an objective-led prompt, or invokes `implementation-plan` directly on the direct path.
- Hoisted the dirty-working-tree precondition above the chain entry so it fires before any planning stage runs.
- Changed discovery from a silent pickup to an offer: shows at most three newest `todo` candidates plus `None of these — author a new plan`; with an objective present, skips discovery entirely.
- Widened the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`; added `Skill` to `allowed-tools`; added `model: opus` to frontmatter.
- Made every non-implementing Step 8 choice (`Exit` and `Run as workflow`) terminate the outer chain.
- Scoped the chain to slash-command only: `$ARGUMENTS` carries the objective, ambient activation keeps its existing route-away contract.
- Updated `kit/plugins/plan-agent/README.md` to remove all "plan that already exists" language.
- Bumped plan-agent to `5.0.0` (MAJOR — argument format and discovery behaviour changed) with matching CHANGELOG and CLAUDE.md entries.
- Extended `tests/plugins/test-build-skill.sh` with 9 new checks covering the chain entry, discovery offer, hoisted guard, Exit-terminates-chain, pinned model, objective-versus-path grammar, two stop branches, and command-only scoping.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration (MAJOR bump) | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `CLAUDE.md` | Plugin table | Modified |

## How it works

The chain is reachable only from the `/plan-agent:build` slash command — `$ARGUMENTS` carries the objective, and the model-invocation path keeps its existing route-away contract. When a bare `build` is invoked with no argument, discovery offers the three newest `todo` candidates plus a `None of these` option; choosing `None of these` prompts for an objective before the chain begins. With an objective present (whether typed or from `None of these`), discovery is skipped entirely and the skill goes directly to the proposal-versus-direct gate.

The chain delegates: `build-proposal` then `implementation-plan` on the proposal path; `implementation-plan` directly on the direct path. The return path resolves the produced spec by its full path rather than by running discovery again, so the skill does not ask about the plan it just watched being authored.

If the user answers `Exit — I'll implement later` or `Run as workflow` at `implementation-plan`'s Step 8 menu, the outer chain terminates at that point rather than starting a parallel in-session build.

## How to use it

```
/plan-agent:build add a health check endpoint
```

With an objective, `build` goes straight to the proposal-versus-direct gate and from there into the full planning pipeline. Without an objective, it offers recent `todo` plans or the option to author a new one.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8622210e` | 2026-07-27 | feat(plan-agent): let build author a plan when none is specified (#470) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
