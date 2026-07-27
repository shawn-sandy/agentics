---
status: proposal
type: feature
created: 2026-07-27
modified: 2026-07-27
repo-name: agentics
---

# Proposal: let `plan-agent:build` author a plan when none exists, instead of stopping

> This is a proposal for review, not an execution plan. It captures what was
> grounded by reading the four `plan-agent` skills, the two in-repo chaining
> precedents, and the Claude Code skills reference. The load-bearing decisions
> are resolved (see Locked decisions); execution is handed off (see Next step).

## TL;DR

`build` currently dead-ends when no plan is specified — or worse, silently adopts
whatever stale spec discovery turns up. The fix is small
because the pipeline it would need — proposal → plan → review → implement —
already exists, wired top-down through each skill's own handoff. `build` becomes
a second entry point to that pipeline rather than a new copy of it: roughly 25
lines in one file, plus one new `Skill()` call to close the only un-automated
seam. Two findings complicate it: the chain crosses about ten interactive gates
in the best case and twenty in the worst, and skill `model:` overrides bleed
forward across a chained turn so the implementation stage inherits the reviewer's
model.

## Context

Bare `/plan-agent:build` resolves a plan three ways
([kit/plugins/plan-agent/skills/build/SKILL.md:69-80](../../kit/plugins/plan-agent/skills/build/SKILL.md#L69)):
an explicit path, discovery over `todo`/`in-progress` specs in the plans
directory, or an `.html` argument reduced to its sibling spec. All three failure
branches stop. The skill body additionally instructs that with no plan file it
"stop and route to `/plan-agent:implementation-plan <objective>`"
([SKILL.md:30-32](../../kit/plugins/plan-agent/skills/build/SKILL.md#L30)) — the
user re-invokes by hand.

The request is that **whenever no plan is specified**, `build` runs the proposal →
plan → review → implement sequence rather than handing back a prompt. The trigger
is the absent argument, not an empty plans directory: a bare `/plan-agent:build`
today silently adopts whichever single `todo` spec discovery happens to find, so
a stale plan lying in `docs/plans/` can win over the objective the user just
stated. Discovery therefore becomes an offer rather than a pickup (decision 5).

What already exists that this touches:

- `build-proposal` converges and prints a handoff instruction telling the user to
  run `implementation-plan`
  ([build-proposal/SKILL.md:198-214](../../kit/plugins/plan-agent/skills/build-proposal/SKILL.md#L198)).
- `implementation-plan` ends at a Step 8 menu that invokes
  `Skill("plan-agent:review-plan")` and `Skill("plan-agent:build")` directly
  ([implementation-plan/SKILL.md:387-479](../../kit/plugins/plan-agent/skills/implementation-plan/SKILL.md#L387)).
- `review-plan` hard-stops without Agent Teams ≥ 2.1.32 plus
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
  ([review-plan/SKILL.md:57-66](../../kit/plugins/plan-agent/skills/review-plan/SKILL.md#L57)); Step 8
  already degrades gracefully around that.

## Core finding

> The pipeline is already built, top-down — `build-proposal` → `implementation-plan`
> → `review-plan` → `build`. This is not a request to construct a pipeline; it is
> a request to let `build` enter the one that exists, and only one seam in it
> (proposal → plan) is still a printed prompt rather than a `Skill()` call.

## Side-by-side

| Dimension | The idea (chained `build`) | Current approach |
|---|---|---|
| Entry point | `build` with an objective and no plan | `build-proposal` or `implementation-plan` with an objective |
| Stage sequencing | Reuses each skill's existing handoff | Same handoffs, entered from the top |
| Proposal → plan seam | A `Skill()` call `build` must make | A prompt the user pastes |
| Plan → review → build seam | Unchanged; already `Skill()` calls | Already `Skill()` calls |
| Who writes source files | `build` only, unchanged | `build` only |
| User-visible cost | One command, then ~10-20 gates in one turn | Three commands, gates spread across turns |

## Locked & resolved decisions

Settled before this draft:

1. **`build` remains the only skill that writes source files.**
   `implementation-plan`'s Scope Constraint
   ([SKILL.md:116-130](../../kit/plugins/plan-agent/skills/implementation-plan/SKILL.md#L116)) stays in
   force. The chain changes direction of travel through the authoring/
   implementation seam, not the seam itself.
2. **The markdown spec stays the source of truth.** Every progress mark is a spec
   edit plus a re-render; nothing in the chain hand-edits HTML.

Resolved in the 2026-07-27 review:

3. **Option A — delegate to the existing head.** `build`'s no-plan branch invokes
   `build-proposal` / `implementation-plan` and control returns through the Step 8
   menu already in place. Rejected: option B (`build` sequences the stages itself,
   requiring a new suppress-menu flag on `implementation-plan` and a re-entrancy
   guard, touching three skills) and option C (a fourth skill owning the pipeline).
   Propagates to Workstreams A and D, and to the "description overlap" risk, which
   A accepts rather than fixes.
4. **The proposal stage is gated by one question, not unconditional.**
   `build` asks "start from a proposal, or go straight to plan authoring?" before
   entering the chain. Rationale: `build-proposal`'s own triage says a Tier 0 idea
   should never enter the loop and exits by answering directly without producing a
   document ([build-proposal/SKILL.md:66-74](../../kit/plugins/plan-agent/skills/build-proposal/SKILL.md#L66)),
   which would leave the chain holding nothing. Propagates to Workstream A step 2.
5. **The trigger is "no plan argument", and discovery offers rather than
   auto-uses.** With no path argument, discovery still runs, but its result is
   presented as a choice — `implement <found spec>` / `author a new plan` — instead
   of being adopted silently. Nothing found goes straight to the chain. Rejected:
   skipping discovery entirely (loses the resume path for an interrupted build)
   and chaining only when discovery is empty (leaves the stale-plan pickup in
   place). Propagates to Workstream A step 0, Workstream B's discovery bullet, and
   Appendices A, B, and D.

## Workstreams

### A — Chain entry in `build`

The argument grammar grows from `[<plan path>] [--dir <path>]` to
`[<plan path>] [<objective>] [--dir <path>]`. A leading token counts as an
objective only when it has no `.md`/`.html` suffix and no `/`; anything
path-shaped keeps today's hard stop.

A new Step 1b runs whenever **no plan argument was given** and an objective is
available (from arguments, conversation, or one `AskUserQuestion`):

0. Discovery result becomes an offer, not a pickup. Candidates found →
   `AskUserQuestion` listing them plus `None of these — author a new plan`;
   choosing a candidate resolves it and jumps to Step 2, skipping the chain.
   Nothing found → continue.
1. Gate: `Start from a proposal` / `Straight to plan authoring`.
2. Proposal path — `Skill("plan-agent:build-proposal", "<objective>")`, then
   close the seam with
   `Skill("plan-agent:implementation-plan", "author an execution plan from the proposal at <path>")`.
   **Objective-led, never a bare `.md` first token**, or `implementation-plan`'s
   conversion mode fires and yields a plan with no actionable steps
   ([implementation-plan/SKILL.md:99-112](../../kit/plugins/plan-agent/skills/implementation-plan/SKILL.md#L99)).
   A Tier 0 exit returns no document: say so and fall through to the direct path.
3. Direct path — `Skill("plan-agent:implementation-plan", "<objective>")`. Review
   is reached through that skill's Step 8 menu; nothing new is needed for it.
4. On return, **resolve the spec the chain just produced by its path** — not by
   re-running discovery, which would now re-ask step 0 about the plan just
   authored — then let the existing preconditions decide. See Appendix A.

`Skill` joins `allowed-tools`.

### B — Guard placement

- **Hoist the dirty-tree check** out of Step 1 preconditions
  ([build/SKILL.md:88](../../kit/plugins/plan-agent/skills/build/SKILL.md#L88)) to chain start.
  Today it would fire *after* a full proposal loop and plan interview.
  `git-agent:ship-autonomous` runs every pre-flight guard before any mutation
  ([ship-autonomous/SKILL.md:22-70](../../kit/plugins/git-agent/skills/ship-autonomous/SKILL.md#L22)) —
  follow that.
- **Only one of the three no-plan branches chains.** A named-but-missing path must
  keep stopping (typo protection); an HTML-only legacy plan means a plan exists
  and needs a spec reconstructed, not a new plan authored. See Appendix B.
- **Discovery always asks on the no-argument path.** Today it asks only on a
  multi-match and auto-uses a single match. Per decision 5 both cases now present
  the same question, grown by a `None of these — author a new plan` option. An
  explicit path argument still resolves silently — the offer exists because the
  user named no plan, so there is nothing to override.

### C — Model and effort continuity

`build` declares no `model:`; its siblings declare `claude-fable-5`
(`implementation-plan`, `build-proposal`) and `opus` (`review-plan`). Per the
skills reference, the override "applies for the rest of the current turn" and does
not revert when the skill completes. A chained run is one turn, so the
implementation stage inherits the last planning stage's model. See Appendix C for
the trace. The mitigation is to give `build` an explicit `model:` so it
re-asserts on activation.

### D — Collateral

`build`'s description ("Implements a plan file that already exists") is its
ambient-routing contract and must widen. `marketplace.json` needs a MINOR bump for
`plan-agent`, `CHANGELOG.md` an entry, and the `build` line in `CLAUDE.md` an
update.

## Risks & tensions

- **The gate count.** The chain crosses roughly ten interactive stops at floor and
  north of twenty for a Tier 2 proposal with a complex UI plan and full finding
  triage (Appendix D). "One command from idea to implemented" is really one
  command that starts a long interview. Unlike `ship-autonomous`, none of the
  waiting is on external events that could be handed back across turns.
  Stop-condition: if the inventory in Appendix D reads as unacceptable, this
  reopens decision 3 in favour of B or C with a suppressed-gate profile.
- **The in-repo precedent points the other way.** `ship-autonomous` is the only
  comparable multi-stage pipeline here, it declares `Skill` in `allowed-tools`,
  and it **never calls it** — every stage is reimplemented inline despite
  `git-agent` shipping `commit-agent`, `pr-agent`, and `merge`. It carries eight
  of its own `AskUserQuestion` gates, which a delegated skill would not let it
  place. The repo's other precedent, `social-media-tools:social-share`, delegates
  but is a pure router: classify, dispatch once, report. A chained `build` would
  be the first skill here to both delegate and sequence.
- **Decision 5 taxes the resume path.** Turning the single-match pickup into an
  offer adds one gate to the most common existing use — resuming an interrupted
  build — to fix a failure that only bites when a stale spec is lying around.
  Stop-condition: if the offer proves annoying in practice, the cheaper variant is
  to auto-use a spec that already carries `[x]` step markers (demonstrably
  in-flight work) and offer only on an untouched `todo` spec.
- **Ambient-routing overlap.** A `build` whose description covers plan authoring
  competes with `implementation-plan` for the same triggers. Option A accepts this
  rather than fixing it; option C was the variant that avoided it.
- **`--dir` must not be forwarded to the proposal stage.** `build` resolves
  `--dir` as the plans directory; `build-proposal` resolves its own
  `planAgent.proposalsDirectory`, default `docs/proposals/`
  ([build-proposal/SKILL.md:76-107](../../kit/plugins/plan-agent/skills/build-proposal/SKILL.md#L76)).
  Forwarding would drop a proposal into the plans directory, where the gallery
  hook and `validate-plan-filename` would trip over a file that is not a spec.
- **Divergence from `finalize-plan`.** It duplicates `build`'s completion rules
  and the two are required to stay consistent
  ([build/SKILL.md:174-176](../../kit/plugins/plan-agent/skills/build/SKILL.md#L174)). A chained run
  must not create a plan state it cannot interpret.

## Open questions (decisions only)

- Does the Appendix D gate inventory justify reopening decision 3? A is cheapest;
  suppressing the redundant gates is what pulls B's flags back in.
- For an HTML-only legacy plan, should `build` offer to reconstruct a spec from
  the HTML, or keep stopping? Reconstruction is a separate capability, not part of
  this chain.
- Which explicit `model:` should `build` declare to stop the bleed — and should
  `effort:` be pinned alongside it?
- Should the proposal gate be remembered per-session, or asked on every chained
  entry?

## Roadmap

| Phase | Work | Size | Depends on |
|---|---|---|---|
| 1 | Workstream B — guard placement and the three no-plan branches | S | — |
| 2 | Workstream A — argument grammar and Step 1b chain entry | M | 1 |
| 3 | Workstream C — explicit `model:` on `build` | S | — |
| 4 | Workstream D — description, version bump, CHANGELOG, CLAUDE.md | S | 2 |

Phase 1 is worth doing on its own merits: hoisting the dirty-tree guard and
distinguishing the three no-plan branches improves `build` whether or not the
chain lands.

## Appendix A — Why re-resolving the spec on return handles re-entrancy

Under option A the outer `build` hands off, and control returns through
`implementation-plan`'s Step 8 menu, whose `Implement now` invokes
`Skill("plan-agent:build", "<spec path>")`. An *inner* `build` may therefore have
already implemented the plan. Re-resolving the produced spec **by path** on return
— not by re-running discovery, which under decision 5 would ask the user about the
plan they just watched being authored — resolves every case using preconditions
that already exist:

| What happened inside | Spec state on return | Existing rule that fires | Outcome |
|---|---|---|---|
| Inner `build` ran to completion | `status: completed` | Completed-plan precondition ([build/SKILL.md:84](../../kit/plugins/plan-agent/skills/build/SKILL.md#L84)) | Stops and asks before redoing work |
| User chose Review, then Exit | `todo`, steps unmarked | Single-match discovery | Step 2 proceeds normally |
| Inner `build` stopped partway | Some steps `[x]` | Resume-from-first-unmarked ([build/SKILL.md:86](../../kit/plugins/plan-agent/skills/build/SKILL.md#L86)) | Picks up where it left off |

No new branches, no recursion guard, no flags. Resumability falls out for free: a
chain that dies after the plan is written leaves a `todo`/`in-progress` spec that
a plain re-run of `/plan-agent:build` offers to resume.

## Appendix B — The three no-plan branches

| Branch | Source | Today | Proposed |
|---|---|---|---|
| Named path not found | [build/SKILL.md:72-73](../../kit/plugins/plan-agent/skills/build/SKILL.md#L72) | Stop, listing paths tried | Unchanged — chaining here authors a plan because of a typo |
| Discovery empty | [build/SKILL.md:78](../../kit/plugins/plan-agent/skills/build/SKILL.md#L78) | Stop | Chain entry (Step 1b) |
| `.html` with no sibling spec | [build/SKILL.md:79-80](../../kit/plugins/plan-agent/skills/build/SKILL.md#L79) | Stop | Open question — a plan exists; the gap is a spec, not a plan |
| Discovery single match | [build/SKILL.md:77](../../kit/plugins/plan-agent/skills/build/SKILL.md#L77) | Auto-uses it silently | Offered, with `None of these — author a new plan` (decision 5) |
| Discovery multi-match | [build/SKILL.md:77](../../kit/plugins/plan-agent/skills/build/SKILL.md#L77) | Ask which | Same question, plus `None of these — author a new plan` |

## Appendix C — Model bleed trace

The skills reference documents `model` as: "Model to use when this skill is
active. The override applies for the rest of the current turn and is not saved to
settings; the session model resumes on your next prompt."

| Stage | Declared `model:` | Active model after the stage activates |
|---|---|---|
| `build` (outer) | none | session model |
| `build-proposal` | `claude-fable-5` | `claude-fable-5` |
| `implementation-plan` | `claude-fable-5` | `claude-fable-5` |
| `review-plan` | `opus` | `opus` |
| `build` (inner, writes source) | none | **`opus` — inherited, not chosen** |

Because the override persists for the rest of the turn rather than unwinding, the
source-writing stage runs on whichever model the last planning stage declared.
Declaring an explicit `model:` on `build` makes it re-assert on activation. The
same reasoning applies to `effort:`.

## Appendix D — Gate inventory for one chained run

| Stage | Gates |
|---|---|
| `build` entry | discovery offer (when candidates exist), objective (if absent), dirty tree (if dirty), proposal-vs-direct |
| `build-proposal` | Step 1 clarify, Step 5 decisions (per round), Step 6 commit-this-round offer |
| `implementation-plan` | Step 1 clarify, Step 5 align, Step 5b interview (1-3 rounds), post-interview apply, Step 8 issue + next-step, review foreground/background |
| `review-plan` | output mode, walkthrough gate, per-finding triage (batched 4 per call) |
| `build` (inner) | unverified criteria, verification failure |

Floor is about ten interactive stops. The redundant ones are identifiable:
entering through `build` has already answered Step 8's next-step question,
`review-plan`'s output-mode question has a usable default, and the proposal's
per-round commit offer is noise mid-chain. Suppressing them requires flags on
sibling skills, which is the boundary between options A and B.

## Next step

Convert to an execution plan:
`/plan-agent:implementation-plan author an execution plan from the proposal at docs/proposals/chain-plan-authoring-into-build.md`
