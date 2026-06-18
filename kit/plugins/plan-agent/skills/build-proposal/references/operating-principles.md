# Operating principles & relationship to existing capabilities

## The ten operating principles

The guardrails that make the loop **converge** instead of gathering forever or
sprawling into volume. Each is a rule the workflow steps enforce.

1. **Ground every claim in a real source.** Fetch the real spec, read the real
   file, load the real schema — never answer from memory. If a claim has no
   source, it is a hypothesis, not a finding.
2. **Quantify; don't hand-wave.** Measure the real surface — counts, file lists,
   call sites — instead of estimating. "~163 declaration sites across 15
   components" beats "a lot of places."
3. **Separate facts from decisions.** Keep two lists: what is now *known* vs.
   what is genuinely the *human's call*. Missing facts loop back to research;
   only decisions go to the human.
4. **Recommendation-first questions.** Every `AskUserQuestion` labels the best
   option "(Recommended)" with its rationale — never a bare menu. The human
   confirms or overrides a recommendation, not picks blind.
5. **Record decisions and propagate.** After every answer, write it into Locked
   decisions *and* update every section it touches (workstreams, open questions,
   roadmap). Decision drift is the primary failure mode.
6. **Iterative deepening in distinct layers.** Each "keep going" adds a *new*
   layer (tooling surface, worked examples, appendices, roadmap, diagram)
   grounded in new sources — never padding. Reviewer test: could the new section
   be a future execution-plan input?
7. **Parallel fan-out; spawn agents for breadth.** Launch external and internal
   research concurrently — `WebSearch`/`WebFetch` (or `deep-research`) for the
   outside, `Agent` (`Explore`/`general-purpose`) for codebase breadth — to
   preserve main-thread context.
8. **Surface incidental findings.** Research routinely catches real bugs and
   drift (a token missing from a schema, hardcoded state, doc-drift items).
   Record them even when they are off the main thread.
9. **Commit the artifact each round.** In a git repo, offer to commit each
   meaningful round. The doc is the record; chat is scaffolding that evaporates.
10. **Signal convergence explicitly.** State out loud when "the remaining
    unknowns are decisions, not missing facts." That sentence is the loop's stop
    condition.

## Relationship to existing capabilities

build-proposal is the **upstream, human-in-the-loop, idea → proposal** layer. It
sits between "raw idea" and "implementation plan" and *composes with* existing
tools rather than replacing them.

| Capability | What it does | How build-proposal composes |
|---|---|---|
| **`deep-research` skill** | One-shot, web-centric, adversarially-verified cited report on a topic | **Optional delegate** for the web-research phase via `Skill(skill: "deep-research", …)`. **Not a hard dependency** — when it is unavailable or the idea needs only a quick check, fall back to `WebSearch` + `WebFetch` for the web and `Agent` (`Explore`) for codebase breadth. deep-research answers "what's true about X"; build-proposal answers "should we, and what exactly." |
| **`implementation-plan` skill / `Plan` agent** | Produces an execution plan (steps, files, trade-offs) assuming the *what* is decided | **Downstream handoff.** build-proposal decides the *what / whether* and stops at the decision-complete proposal, then hands it to `/plan-agent:implementation-plan` for a **full planning pass** — led with an objective (e.g. `author an execution plan from the proposal at <path>`), **not** a bare `.md` token. A bare `.md` token would trigger 1:1 conversion mode, which maps `Changes/Steps` → step cards; a proposal has only `Workstreams`/`Roadmap`, so conversion would yield a stepless plan. Leading with the objective keeps the full workflow that drafts real steps. **The seam: build-proposal owns "should-we + what"; planning owns "how."** |
| **Plan mode (`EnterPlanMode`)** | A harness gate for proposing a code change before acting | Different axis — that gates *edits*; build-proposal develops *ideas*. They co-exist: a proposal may run, then later implementation work enters plan mode. |
| **`AskUserQuestion`** | Asks the user a structured question | A **tool build-proposal orchestrates** at Step 5 (recommendation-first), not a competitor. |

The unique value is the **combination**: codebase + web grounding, an explicit
facts-vs-decisions discipline with the human in the loop, and a committed
artifact that deepens and converges — no single tool above does all three.
