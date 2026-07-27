---
status: todo
type: feature
created: 2026-07-27
workflow: false
glance: Today a bare /plan-agent:build either dead-ends or silently adopts whatever stale spec it finds; after this it offers what it found and, when you want something new, walks proposal to plan to review to implementation without you re-invoking anything. Done when tests/plugins/test-build-skill.sh passes with the new checks and a no-argument run in a repo with no plans reaches the proposal gate instead of stopping.
---

# Plan: Let `build` author a plan when none is specified

## Objective

Replace `plan-agent:build`'s no-plan dead end with an entry into the plan pipeline that already exists — proposal, plan, review, implement — and stop discovery from silently adopting a stale spec when the user named no plan.

## Context

`build` resolves a plan three ways and every failure branch stops, with the body instructing the user to go run `/plan-agent:implementation-plan` by hand. The pipeline that instruction points at is already wired top-down: `build-proposal` hands off to `implementation-plan`, whose Step 8 menu invokes `review-plan` and `build` as real `Skill()` calls. Only the proposal-to-plan seam is still a printed prompt rather than a call, so this work is a second entry point into an existing pipeline rather than a new one.

The design decisions were settled in `docs/proposals/chain-plan-authoring-into-build.md`. Three matter here. **Option A** — delegate to the existing head and let control return through the Step 8 menu — was chosen over having `build` sequence the stages itself, which would need a new suppress-menu flag on `implementation-plan` plus a re-entrancy guard across three skills. **The proposal stage is gated by one question**, because `build-proposal` triages a Tier 0 idea by answering directly and producing no document, which would leave the chain holding nothing. **The trigger is an absent plan argument, not an empty plans directory**, and discovery therefore offers its result instead of adopting it.

**The chain is reachable only from the slash command.** `/plan-agent:build a todo app` treats the objective as a command parameter and enters the chain; the same words typed as plain text do not. Ambient activation keeps exactly the behaviour it has today — it requires a plan that already exists and routes elsewhere when there is none. This is a deliberate narrowing: `build` is the most overloaded verb in software, and any ambient trigger wide enough to catch "build a todo app" also catches "build fails on CI", "build the docker image", and "rebuild the index", none of which belong in a proposal loop. Making the objective a parameter removes that whole failure class instead of trying to word around it, and it keeps `build` from competing with `implementation-plan` for free-text routing.

The objective still forces the discovery skip in step 3: whether it arrives as a parameter or not, an objective means unrelated `todo` specs are noise.

One risk is accepted rather than solved: the chained run crosses roughly ten interactive gates at floor, and suppressing the redundant ones requires flags on sibling skills, which is the boundary this plan deliberately does not cross.

One risk is solved here: skill `model:` overrides apply for the rest of the turn and do not unwind when the skill finishes, so a chained run would leave the source-writing stage on whichever model the last planning skill declared. Step 8 fixes that.

## Files

- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — chain entry, discovery offer, hoisted guard, frontmatter
- kit/plugins/plan-agent/README.md (modified) — the `build` row and section both describe the old no-chain behaviour
- tests/plugins/test-build-skill.sh (modified) — checks covering the new behaviour
- .claude-plugin/marketplace.json (modified) — plan-agent MAJOR version bump
- kit/plugins/plan-agent/CHANGELOG.md (modified) — entry for the new activation path
- CLAUDE.md (modified) — the `build` clause in the plugin table

## Steps

1. Hoist the dirty-working-tree precondition out of the Step 1 preconditions block in kit/plugins/plan-agent/skills/build/SKILL.md so it runs before any chain stage is invoked. Why: left where it is, it fires only after a full proposal loop and plan interview have already run, asking about uncommitted files at the worst possible moment — `git-agent:ship-autonomous` runs every pre-flight guard before any mutation and this should match. Verify: the dirty-tree paragraph appears above the Step 1b chain entry in the file, and the completed-plan and resume-from-unmarked preconditions are still present and unmoved.
2. Split Step 1's three no-plan branches so only the empty-discovery branch reaches the chain: keep the named-but-missing-path branch stopping with the paths it tried, and keep the HTML-with-no-sibling-spec branch stopping with its existing message. Why: chaining on a mistyped filename would author a whole plan because of a typo, and an HTML-only legacy plan is a plan that needs a spec reconstructed rather than a new plan authored on top of it. Verify: reading Step 1 top to bottom shows exactly one branch routing to Step 1b, and the other two still end in a stop.
3. Change discovery from a pickup to an offer, and run the offer **only when no objective was supplied**: with an objective present, skip discovery entirely and go to Step 1b, because the user has already said what they want and unrelated `todo` specs are noise. When the offer does run, rank candidates newest-`created:` first, show at most the top three plus `None of these — author a new plan`, and say how many were suppressed. Why: discovery selects on `status:` alone with no notion of subject, so in a repo carrying ten `todo` specs an objective like "a todo app" would be answered with a menu of unrelated plans — and `AskUserQuestion` caps at four options, so the unbounded offer cannot render at all; gating on objective-absence removes the relevance problem rather than trying to solve it, leaving the offer for the case it was designed for, a bare `build` resuming interrupted work. Verify: Step 1 states the objective-present skip before describing the offer, the offer names its three-candidate cap, and the explicit-path branch is untouched.
4. Widen the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`, treating a leading token as an objective only when it has no `.md` or `.html` suffix and no `/`, and add `Skill` to the `allowed-tools` frontmatter line. Why: `build` has no objective input today, and authoring a plan needs one — while a path-shaped token must keep hitting the stop from step 2 rather than being read as prose; note that the no-slash rule misreads an objective containing one (`add A/B testing support`) as a path, so the stop message must name the misparse rather than only listing paths tried. Verify: `grep -m1 '^allowed-tools:' kit/plugins/plan-agent/skills/build/SKILL.md` includes `Skill`, the argument-hint frontmatter shows the objective slot, and the rule states what happens to a slash-bearing objective.
5. State in the Invocation section that Step 1b is reachable **only from the slash command**: the objective is a command parameter read from `$ARGUMENTS`, and the model-invocation path keeps its current contract — it requires a plan that already exists and routes to `/plan-agent:implementation-plan` when there is none, never entering the chain. Why: `$ARGUMENTS` is empty on the model path, so an ambient chain would have to infer an objective from conversation, and the trigger word `build` is overloaded enough that inference would pull in compile and CI requests; scoping the chain to the command makes the objective explicit by construction and leaves ambient routing untouched, so no existing invocation changes meaning. Verify: the Invocation section says the chain is command-only, and the Model-invocation bullet still carries its route-away instruction.
6. Add a new Step 1b to build/SKILL.md carrying the chain: the proposal-versus-direct gate asked on every chained entry, a proposal path that invokes `build-proposal` then `implementation-plan` with objective-led text naming the proposal path, a direct path that invokes `implementation-plan` with the objective, and a return path that re-resolves the produced spec by path. Why: leading with a bare `.md` token would drop `implementation-plan` into conversion mode and produce a plan with no actionable steps, and re-running discovery on return would ask the user about the plan they just watched being authored; `--dir` must not be forwarded to `build-proposal`, which resolves its own proposals directory. Verify: the step names both `Skill(skill: "plan-agent:build-proposal"` and `Skill(skill: "plan-agent:implementation-plan"`, and its return path says the spec is resolved by path rather than by discovery. The step must also state the abandonment contract: if the chain is abandoned between stages — a tool error, a session drop, or the user backing out after a proposal is written but before a plan exists — the proposal file is left in place uncommitted and `build` reports its path rather than cleaning it up.
7. Make `Exit — I'll implement later` at `implementation-plan`'s Step 8 terminate the outer chain: the return path in Step 1b reports the produced plan's path, leaves `status: todo`, and stops without implementing. Why: Exit is the only point at which the user is asked about implementing, so treating it as declining just the inner skill's offer would implement work they explicitly declined a moment earlier — this overrides the proposal's Appendix A, which as written has the outer `build` proceed. Verify: Step 1b's return path names the Exit case and says it stops, and the three resume cases from Appendix A are still handled.
8. Add `model: opus` to build/SKILL.md's frontmatter. Why: a skill's model override applies for the rest of the turn and does not unwind when the skill ends, so a chained run would leave the source-writing stage on whatever `review-plan` or `implementation-plan` last set; pinning it makes `build` re-assert on activation and gives the stage that writes source files a deterministic model. Verify: `grep -c '^model: opus$' kit/plugins/plan-agent/skills/build/SKILL.md` returns 1.
9. Leave the `description` frontmatter unchanged, and rewrite only the Overview's "the execution half of `implementation-plan`, which authors a plan and stops" so it says the command form can author through the chain while ambient activation still requires an existing plan. Scope — do not delete — the Model-invocation bullet's "Requires a plan that **already exists** — if there is no plan file, stop and route to `/plan-agent:implementation-plan <objective>`"; add that this applies to the model path only. Why: the description governs ambient routing, and since the chain is command-only there is nothing new to advertise — leaving it narrow is what keeps `build` from claiming free-text "build X" requests and colliding with compile and CI phrasing. The route-away instruction is not stale prose but the ambient contract itself, so it must survive; only the Overview, which describes the skill as a whole, is now wrong. Verify: `grep -c 'stop and route to' kit/plugins/plan-agent/skills/build/SKILL.md` returns 1, `git diff` shows the `description:` line untouched, and the Overview names the command-versus-ambient split.
10. Update kit/plugins/plan-agent/README.md: the `build` row in the component table, which reads "implements an existing plan and runs its gates", and the `build` section body, which opens "Implements a plan that already exists", plus its usage examples so at least one shows a no-plan invocation. Why: the README is the plugin's published documentation and describes exactly the dead end this plan removes, so shipping without it leaves the user-facing docs contradicting the skill. Verify: `grep -c 'a plan that already exists' kit/plugins/plan-agent/README.md` returns 0, and the usage block shows an objective-only invocation.
11. Bump the plan-agent `version` in .claude-plugin/marketplace.json by one **major**, add a CHANGELOG.md entry under kit/plugins/plan-agent/, and update the `build` clause in the root CLAUDE.md plugin table. Why: `.claude/rules/marketplace.md` classifies "changing argument format or activation behavior" as MAJOR, and step 4 changes the argument format while step 3 changes what an existing no-argument invocation does — ambient activation is deliberately unchanged, so the argument grammar and the discovery behaviour are what carry the bump; a MINOR would understate a breaking change to a published plugin. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and the new version's major component is exactly one greater than the value on `main`.
12. Extend tests/plugins/test-build-skill.sh with numbered checks asserting the chain entry, the discovery offer, the hoisted guard, the Exit-terminates-chain rule, the pinned model, step 4's objective-versus-path grammar rule, step 2's two surviving stop branches, and step 5's command-only scoping alongside the retained route-away instruction, following the existing `FAILURES` counter convention and check 6's section-scoped pattern: `sed` the owning section, squeeze newlines, then grep within it. Why: every behaviour above is prose in a hard-wrapped markdown file, and check 6's own comment records a file-wide grep passing against a mutation that deleted all five rules it guarded and appended a decoy paragraph; the grammar rule and the stop branches are what keep a typo from authoring a whole plan, so leaving them unasserted guards the new path while abandoning the old one. Verify: `bash tests/plugins/test-build-skill.sh` exits 0, and reverting any one of steps 1, 2, 3, 4, 6, 7, or 8 makes it exit 1 naming that check.

## Acceptance Criteria

- [ ] `bash tests/plugins/test-build-skill.sh` exits 0 with the new checks included
- [ ] A bare `/plan-agent:build` in a repo with no plan specs reaches the proposal-versus-direct gate instead of stopping
- [ ] A bare `/plan-agent:build` in a repo with exactly one `todo` spec offers that spec plus an author-a-new-plan option, rather than adopting it silently
- [ ] `/plan-agent:build a todo app` reaches the proposal-versus-direct gate, in a repo that already holds unrelated `todo` specs
- [ ] Typing `build a todo app` as plain text, with no command, does not enter the chain — ambient activation still requires an existing plan
- [ ] With an objective supplied, no discovery offer is shown regardless of how many `todo` specs exist; with none supplied and more than three candidates, at most three are offered and the suppressed count is stated
- [ ] `/plan-agent:build docs/plans/does-not-exist.md` still stops and names the paths it tried
- [ ] Choosing `Exit — I'll implement later` at the chained `implementation-plan`'s Step 8 leaves the plan at `status: todo` with no source files written
- [ ] `grep -m1 '^allowed-tools:' kit/plugins/plan-agent/skills/build/SKILL.md` contains `Skill`, and the file carries exactly one `model: opus` line
- [ ] `grep -c 'stop and route to' kit/plugins/plan-agent/skills/build/SKILL.md` returns 1 — the ambient route-away contract survives, scoped to the model path
- [ ] The `description:` frontmatter line is byte-identical to `main`
- [ ] `grep -c 'a plan that already exists' kit/plugins/plan-agent/README.md` returns 0
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0, and the plan-agent version is a MAJOR bump over `main`
- [ ] The `build` clause in CLAUDE.md and the plan-agent CHANGELOG both describe the no-plan chain

## Tests

Tier 1 — This plan changes shipped skill behaviour and an executable test script

The objective test is **static, not behavioural**: it asserts the chain is authored correctly in build/SKILL.md, not that it executes correctly at runtime. No harness in this repo can drive a skill's interactive gates, so acceptance criteria 2, 3, and 5 are proved only by the manual walkthrough in Verification. Treat the gap as known rather than covered.

- Objective: a bare `build` with no plan argument enters the chain instead of dead-ending. File: tests/plugins/test-build-skill.sh; Type: smoke (static); Asserts: build/SKILL.md carries the Step 1b chain entry with both delegating Skill calls, presents discovery as an offer, places the dirty-tree guard ahead of the chain, terminates on Exit, pins model opus, keeps both stop branches, and no longer instructs the model to route away when no plan exists; Run: bash tests/plugins/test-build-skill.sh
- Unit: plugin version regression guard. File: scripts/check-plugin-versions.mjs; Targets: plan-agent entry in .claude-plugin/marketplace.json; Key cases: version strictly greater than origin/main, valid semver, single source of truth in marketplace.json

## Verification

Run `bash tests/plugins/test-build-skill.sh` and confirm it exits 0 with the new checks reported as PASS alongside the nine existing ones. Then confirm the checks are load-bearing rather than decorative: temporarily delete the Step 1b heading from build/SKILL.md, re-run, and confirm the script exits 1 naming that check, then restore the file.

Exercise the headline scenario in this repo, not a scratch one, because it is the case the design nearly failed: with a dozen unrelated `todo` specs present, run `/plan-agent:build a todo app`. Confirm it shows no discovery offer at all and reaches the proposal-versus-direct gate. Then type `build a todo app` as plain text with no command and confirm it does not enter the chain — ambient activation must still require an existing plan and route away without one. Then run a bare `/plan-agent:build` with no objective and confirm the offer appears capped at three candidates with the suppressed count stated.

Exercise the objective end-to-end in a scratch directory with an empty plans directory. Invoke `/plan-agent:build add a health check endpoint` and confirm it asks the proposal-versus-direct question rather than stopping with a routing message. Answer `Straight to plan authoring` and confirm `implementation-plan` opens with that objective — not in conversion mode, which would be visible as a plan whose steps restate proposal headings instead of naming real actions. Then repeat in a directory holding exactly one `todo` spec and confirm that spec is offered with an author-a-new-plan option rather than being adopted silently. Run the chain once more and answer `Exit — I'll implement later` at the Step 8 menu; confirm the run stops with the plan at `status: todo` and `git status --porcelain` showing no source files written. Finally invoke `/plan-agent:build add A/B testing support` and confirm the slash-bearing objective either reaches the chain or stops with a message naming the misparse — never a bare list of paths tried, which would leave the user with no idea their objective was read as a filename.

Finally run `BASE_REF=main node scripts/check-plugin-versions.mjs` and confirm it exits 0, proving the marketplace bump landed and did not regress against main.

## Unresolved Questions

- Should `effort:` be pinned alongside `model:` in step 8? The turn-scoped override behaviour is documented as the same, so a chained run inherits the reviewer's effort level too, but no failure has been observed from it yet.
- Does the roughly ten-gate floor of a chained run justify revisiting option A in favour of suppression flags on sibling skills? Captured as the second Next Steps prompt.
- Does `model: inherit` re-read the session model or the turn's current override? Step 7 pins `opus` precisely so this does not need answering first, but the answer would allow a less opinionated fix later.

## Review Record

Five-reviewer plan-review team, 2026-07-27 (architecture, completeness, testability, risk, conventions). No UI signals, so the UX and accessibility reviewers were not spawned. Verdict: approve with changes. Conventions returned clean. Recorded here rather than as an HTML `<details>` block because the spec is the source of truth and the next re-render would discard anything written into the HTML.

Applied:

- Stale body prose in build/SKILL.md — the Overview line and the Model-invocation bullet still instructed the model to stop and route away when no plan exists, which step 8 originally left in place while rewriting only the frontmatter description. Now step 9. (completeness, high; verified against build/SKILL.md lines 29-32)
- README.md was absent from Files and every step while documenting the removed dead end in two places. Now step 10 and a Files entry. (completeness, high; verified against README.md lines 25 and 341)
- Version bump was MINOR; `.claude/rules/marketplace.md` classifies argument-format and activation-behaviour changes as MAJOR, and steps 3, 4, and 8 do all three. Now step 11. (completeness + risk, high; verified against marketplace.md line 55)
- Test coverage omitted step 4's grammar rule and step 2's two stop branches — the checks guarded the new path while abandoning the old one. Now step 12. (testability + completeness, medium)
- The objective test's scope is now labelled static rather than behavioural, with acceptance criteria 2, 3, and 5 named as manual-only. (testability, medium)
- A slash-bearing objective misparses as a path; step 4 now requires the stop message to name the misparse, and Verification exercises it. (risk, low)
- Abandoned-chain contract added to step 6: a proposal written before an abort is left in place and its path reported. (risk, low)

Integration scenario, 2026-07-27 — `build a todo app` typed as plain text, chain expected when no matching plan exists. Exposed three defects the review team had not reached, all folded in:

- Discovery had no relevance filter and selected on `status:` alone, so in this repo the scenario would have answered "a todo app" with a menu of a dozen unrelated specs — and `AskUserQuestion` caps at four options, so the offer could not render at all. Resolved by gating the offer on objective-absence and capping it at three candidates. Now step 3.
- The scenario as originally posed was ambient, which would have rested the whole feature on the `description` that step 9 treated as collateral — and `build` is overloaded enough that a trigger catching `build a todo app` would also swallow `build fails on CI`. Superseded by the scope narrowing below.
- The model-invocation path supplies no `$ARGUMENTS`, and the grammar rule was written only for the command path. Now step 5.

Scope narrowing, 2026-07-27 — the chain is reachable **only from the `/plan-agent:build` slash command**, with the objective as a command parameter rather than a trigger phrase:

- Step 5 inverted: it now states the chain is command-only and that the model-invocation path keeps its existing route-away contract, instead of documenting an ambient objective-derivation path.
- Step 9 shrank to almost nothing: the `description` is left byte-identical, because with no ambient chain there is nothing new to advertise. Only the Overview line — which describes the skill as a whole — is rewritten.
- **A review finding was partly reversed.** The completeness reviewer flagged the "stop and route to `/plan-agent:implementation-plan`" bullet as stale prose that would contradict the chain. Under command-only scoping it is not stale: it is the ambient contract, and it must survive. The acceptance criterion flipped from `grep -c` returning 0 to returning 1.
- Step 11's rationale narrowed: the MAJOR bump now rests on the argument-format change (step 4) and the discovery-behaviour change (step 3) alone, since activation behaviour is deliberately unchanged.
- The overloaded-verb problem and the ambient-overlap risk with `implementation-plan` both disappear rather than being mitigated — neither is now reachable.

Not applied:

- Reverting `model: opus` to `inherit` or dropping the pin. The risk reviewer is right that it taxes every trivial resume and hard-fails without opus access, but the pin was an explicit interview decision. The tradeoff is recorded here rather than reversed. (risk, medium)

Noted, not actioned:

- Appendix A's completed-plan and resume-from-unmarked return rows remain covered only by step 7's verify line, not by a dedicated check. (architecture, low)
- The ambient-routing overlap between `build` and `implementation-plan` stays accepted rather than mitigated, per the proposal. (architecture + risk, medium)

## Resources

- docs/proposals/chain-plan-authoring-into-build.md — the proposal this plan executes, carrying the dated locked decisions and the gate inventory
- https://code.claude.com/docs/en/skills — skill frontmatter reference; the source for the `model:` turn-scoped override behaviour behind step 8
- tests/plugins/test-build-skill.sh — the existing nine-check smoke test that step 12 extends
- kit/plugins/git-agent/skills/ship-autonomous/SKILL.md — the guards-before-mutation precedent behind step 1

## Next Steps

- Reconstruct a spec from a legacy HTML-only plan
  Closes the third no-plan branch that step 2 deliberately leaves stopping.
  ```text
  In the agentics repo, add a spec-reconstruction path to
  kit/plugins/plan-agent/skills/build/SKILL.md: when the user passes a .html
  plan that has no sibling .md spec, offer to derive a spec from the rendered
  HTML using scripts/extract-plan-spec.mjs, write it beside the HTML, re-render
  with scripts/build-plan-html.mjs, and continue implementing. Keep the current
  stop as the decline path. Add a check to tests/plugins/test-build-skill.sh,
  bump the plan-agent minor version in .claude-plugin/marketplace.json, and add
  a CHANGELOG entry under kit/plugins/plan-agent/. Verify with
  `bash tests/plugins/test-build-skill.sh` exiting 0 before reporting done.
  ```
- Cut the gate count of a chained build run
  Wish list — this is the option B design the proposal deliberately deferred.
  ```text
  In the agentics repo, reduce the interactive gate count when
  kit/plugins/plan-agent/skills/build/SKILL.md drives a chained run. Add a
  suppress-menu flag to kit/plugins/plan-agent/skills/implementation-plan/SKILL.md
  so its Step 8 next-step question is skipped when the caller has already
  committed to implementing, and have build pass it. Leave the tracking-issue
  question intact. Bump the plan-agent minor version in
  .claude-plugin/marketplace.json, add a CHANGELOG entry, and add a check to
  tests/plugins/test-build-skill.sh asserting the flag is both documented and
  passed. Verify with `bash tests/plugins/test-build-skill.sh` exiting 0 before
  reporting done.
  ```
