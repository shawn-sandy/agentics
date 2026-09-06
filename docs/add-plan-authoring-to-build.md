# Let `build` author a plan when none is specified

> Replaces `plan-agent:build`'s no-plan dead end with an entry into the existing proposal→plan→review→implement pipeline, and stops discovery from silently adopting a stale spec when no plan argument is supplied.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Hoisted the dirty-working-tree precondition to run before any chain stage in `build/SKILL.md` (previously it fired only after a full proposal loop, at exactly the wrong moment).
- Split the three no-plan branches so only the empty-discovery case enters the chain; named-but-missing-path and HTML-with-no-sibling-spec still stop with their existing messages.
- Changed discovery from a silent pickup to an explicit offer, shown only when no objective was supplied, capped at three candidates plus "None of these — author a new plan", with the suppressed count stated.
- Widened the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`; added `Skill` to `allowed-tools`; documented what happens to a slash-bearing objective (misparse named, not silent).
- Added a new Step 1b with the full chain: objective prompt when entering bare, proposal-vs-direct gate, `Skill(skill: "plan-agent:build-proposal")` → `Skill(skill: "plan-agent:implementation-plan")` call pair, return-by-path resolution, and an abandonment contract (proposal file left in place with its path reported).
- Made every non-implementing Step 8 choice terminate the outer chain: `Exit — I'll implement later` stops with the plan at `status: todo`; `Run as workflow` stops after the workflow prompt, with no in-session build racing the emitted workflow.
- Added `model: opus` to `build/SKILL.md` frontmatter to prevent a chained run from inheriting whichever model the last planning skill declared.
- Scoped the chain to the slash command only: `$ARGUMENTS` carries the objective; the model-invocation ambient path retains its route-away contract unchanged.
- Updated `kit/plugins/plan-agent/README.md` to remove "implements an existing plan" language and add an objective-only usage example.
- Bumped `plan-agent` by one MAJOR version in `marketplace.json` (argument format + discovery behaviour change) with a CHANGELOG entry and CLAUDE.md update.
- Extended `tests/plugins/test-build-skill.sh` with checks covering the chain entry, discovery offer, hoisted guard, Exit-terminates-chain, pinned model, grammar rule, surviving stop branches, and command-only scoping.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill contract — chain entry, discovery offer, hoisted guard, grammar | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation — build row and section rewritten | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test — 18-check suite including new chain assertions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace MAJOR version bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes — chain entry described | Modified |
| `CLAUDE.md` | Root plugin table — build clause updated | Modified |

## How it works

**Guard hoisting.** The dirty-working-tree check was moved to the top of the skill, before Step 1's branch logic, so it fires regardless of which path is taken. Previously it sat inside the preconditions block and only reached execution after a proposal loop and plan interview had already run — an unusable prompt position.

**Branch surgery.** Step 1 retains three branches for no-plan scenarios. Only the empty-discovery branch (no plan argument, no candidates found or user selects "None of these") routes to the chain. The named-but-missing-path branch still stops and lists the resolution attempts; the HTML-with-no-sibling-spec branch still stops with its reconstruction message. This prevents a typo from triggering a full proposal loop.

**Discovery as an offer.** When no objective is supplied and candidates exist, the skill presents up to three candidates ranked newest-`created:` first, plus an author-a-new-plan option, and states how many additional candidates were suppressed. When an objective is present, discovery is skipped entirely — the user has already said what they want, and unrelated `todo` specs would be noise. This removes the `AskUserQuestion` four-option cap problem that an unbounded discovery offer would hit.

**Chain entry (Step 1b).** If the bare-`build` path reaches "None of these" or no candidates exist, Step 1b asks for an objective before anything else (both the proposal gate and delegated skills are meaningless without one). It then asks whether to go through `build-proposal` first or straight to `implementation-plan`. The proposal path invokes `build-proposal`, then `implementation-plan` with the proposal path as input; the direct path invokes `implementation-plan` with the objective alone. The return path re-resolves the produced spec by path rather than re-running discovery.

**Step 8 termination contract.** `implementation-plan`'s Step 8 menu has three non-implementing choices. All now terminate the outer chain: `Exit` leaves the plan at `status: todo` with no source files written; `Run as workflow` stops after `implementation-plan` has emitted the workflow prompt, with no in-session build starting alongside it. The third Appendix A resume row (`Implement now`) similarly reports the nested result and stops rather than re-entering the preconditions.

**Model pin.** `model: opus` in `build/SKILL.md` frontmatter re-asserts the model on every activation. A chained run would otherwise leave the source-writing stage on whichever model `review-plan` or `implementation-plan` last set, because skill model overrides persist for the rest of the turn.

**Command-only scoping.** The chain is reachable only from the `/plan-agent:build` slash command, where the objective arrives as `$ARGUMENTS`. The ambient model-invocation path has no `$ARGUMENTS`, so it cannot enter the chain and retains its existing route-away instruction. The `description` frontmatter line is byte-identical to `main` — keeping `build` from claiming free-text "build X" requests.

**Test coverage.** `test-build-skill.sh` grew from nine to eighteen checks. The new checks use `sed` to scope sections before grepping — the same pattern check 6 established — to prevent a file-wide grep passing against a mutation that deleted all rules and appended a decoy paragraph. Reverting any of the eight covered steps individually turns the suite red naming that check.

## How to use it

Activation trigger: `/plan-agent:build` (slash command only)

```
# Author a new plan, then implement it
/plan-agent:build add a health check endpoint

# Resume the most recently modified plan
/plan-agent:build

# Implement a specific existing plan
/plan-agent:build docs/plans/my-feature.md
```

A bare `/plan-agent:build` with no argument shows up to three recent `todo` plans and an author-a-new-plan option. Supplying an objective skips discovery and goes straight to the proposal-vs-direct gate. An objective containing a leading slash (e.g. `A/B testing for checkout`) stops with a message naming the misparse and offering a reworded form.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `b208ab0` | 2026-09-04 | fix(plan-agent): stop the prototype store handing render() shapes it cannot walk (9.13.2) (#620) |
| `b8cfa1f` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `37cc607` | 2026-08-30 | docs(plan-agent): reconcile skill total and dispatch hook count (9.10.2) (#612) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `88a686a` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `6d6bfeb` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |
| `be304fd` | 2026-08-26 | feat(plan-agent): publish-hub — bundle a plan and its related HTML into one hub artifact (9.8.0) (#603) |
| `4147530` | 2026-08-26 | fix(plan-agent): stop artifact-mode renders leaking local paths (9.7.1) (#602) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `daa72b9` | 2026-08-23 | build-feature: add product content, stories, metrics, rollout, and publishing (#593) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `620ffa8` | 2026-08-19 | docs: sync READMEs with marketplace; fix the dead version-guard hook (#581) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `d7598ad` | 2026-08-17 | fix: screenshot output verification and plan Context completeness (#571) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
