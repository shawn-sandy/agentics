# Let `build` author a plan when none is specified

> Today a bare /plan-agent:build either dead-ends or silently adopts whatever stale spec it finds; after this it offers what it found and, when you want someth...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Hoist the dirty-working-tree precondition out of the Step 1 preconditions block in kit/plugins/plan-agent/skills/buil...
- Split Step 1's three no-plan branches so only the empty-discovery branch reaches the chain: keep the named-but-missin...
- Change discovery from a pickup to an offer, and run the offer **only when no objective was supplied**: with an object...
- Widen the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`, treating a leading token as an objective...
- State in the Invocation section that Step 1b is reachable **only from the slash command**: the objective is a command...
- Add a new Step 1b to build/SKILL.md carrying the chain: an objective check that runs first — when no objective was su...
- Make every non-implementing Step 8 choice terminate the outer chain, not just one: `Exit — I'll implement later` stop...
- Add `model: opus` to build/SKILL.md's frontmatter.
- Leave the `description` frontmatter unchanged, and rewrite only the Overview's "the execution half of `implementation...
- Update kit/plugins/plan-agent/README.md: the `build` row in the component table, which reads "implements an existing...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | chain entry, discovery offer, hoisted guard, frontmatter | Modified |
| `kit/plugins/plan-agent/README.md` | the `build` row and section both describe the old no-chai... | Modified |
| `tests/plugins/test-build-skill.sh` | checks covering the new behaviour | Modified |
| `.claude-plugin/marketplace.json` | plan-agent MAJOR version bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | entry for the new activation path | Modified |
| `CLAUDE.md` | the `build` clause in the plugin table | Modified |

## How it works

Replace `plan-agent:build`'s no-plan dead end with an entry into the plan pipeline that already exists — proposal, plan, review, implement — and stop discovery from silently adopting a stale spec when the user named no plan.

`build` resolves a plan three ways and every failure branch stops, with the body instructing the user to go run `/plan-agent:implementation-plan` by hand. The pipeline that instruction points at is already wired top-down: `build-proposal` hands off to `implementation-plan`, whose Step 8 menu invokes `review-plan` and `build` as real `Skill()` calls. Only the proposal-to-plan seam is still a printed prompt rather than a call, so this work is a second entry point into an existing pipeline rather t...

The implementation proceeded through these steps: Hoist the dirty-working-tree precondition out of the Step 1 preconditions block in kit/plugins/plan-agent/skills/buil...; Split Step 1's three no-plan branches so only the empty-discovery branch reaches the chain: keep the named-but-missin...; Change discovery from a pickup to an offer, and run the offer **only when no objective was supplied**: with an object...; Widen the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`, treating a leading token as an objective ...; State in the Invocation section that Step 1b is reachable **only from the slash command**: the objective is a command....

Verified by execution: `bash tests/plugins/test-build-skill.sh` exits 0 with all 18 checks PASS; each of steps 1-4 and 6-8, plus the check-18 fallback rule, individually reverted turns it red naming its own check;

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
