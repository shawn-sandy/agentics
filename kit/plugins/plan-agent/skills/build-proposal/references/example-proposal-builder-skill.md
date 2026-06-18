---
status: proposal
type: feature
created: 2026-06-14
repo-name: acss-plugins
---

> **Trimmed worked exemplar — build-proposal recursive regression corpus.**
> Source: <https://github.com/shawn-sandy/agentic-acss-plugins/blob/claude/design-md-spec-alignment-sitq7t/docs/proposals/proposal-builder-skill.md>
> @ `f47f5d6b540d894f907be55a02b15effd13ba52e` (2026-06-14).
> Trimmed to front-matter + core finding + locked decisions + one appendix; the
> full proposal is ~240 lines. This is the **recursive case**: a proposal that
> proposes the very skill build-proposal implements. Sections retained verbatim.

# Proposal: a `proposal-builder` skill — turn a half-formed idea into a decision-complete proposal

> This proposal codifies the workflow this very session used — taking "look at
> design.md and align our components" from a vague prompt to a decision-complete
> proposal plus execution plans — into a reusable skill. The session is the
> worked example; every principle maps to a concrete moment in it.

## The problem (the core finding)

A lot of valuable work starts as a half-formed idea: *"compare X to how we do
it,"* *"should we adopt Y,"* *"how would we…"*. The failure modes are
predictable:

- **Speculation over grounding** — answering from memory instead of fetching the
  real spec, reading the real code, or measuring the real numbers.
- **Surveying instead of deciding** — listing options forever without separating
  what's a *fact to look up* from what's a *decision for the human*.
- **Decisions that evaporate** — choices get made in chat, then never recorded or
  propagated into the artifact, so the next round re-litigates them.
- **One-shot reports** — a wall of text that can't be deepened, corrected, or
  turned into action.

> The skill is a **thinking partner** that avoids these: it researches to
> ground, distinguishes facts from decisions, drives the human-in-the-loop
> decision cadence, and produces a single living proposal artifact that deepens
> each round and converges on something buildable.

## Resolved decisions (2026-06-14 review)

1. **Name: `proposal-builder`.** Invoked as `/proposal-builder <idea>`.
   *(In the agentics marketplace this shipped as `build-proposal`, invoked
   `/plan-agent:build-proposal`.)*
2. **Placement: the agentics marketplace** (domain-general — a shared
   marketplace is the right home, not a project-local or personal skill).
3. **Artifact location: a dedicated `docs/proposals/` dir**, distinct from
   `docs/plans/` execution plans. The skill writes proposals there in whatever
   project it runs.
4. **Handoff: stops at the decision-complete proposal** and hands off to the
   planning layer — it does not author execution plans itself (workflow step 7).

## Appendix — Relationship to existing capabilities (why this isn't redundant)

`proposal-builder` is the **upstream, human-in-the-loop, idea→proposal** layer.
It sits between "raw idea" and "implementation plan," and it *composes with*
existing tools rather than replacing them:

| Capability | What it does | How `proposal-builder` differs / composes |
|---|---|---|
| **`deep-research` skill** | One-shot, web-centric, adversarially-verified cited report on a topic | Adds **codebase grounding**, a **human decision cadence**, and a **living proposal artifact** that converges on something buildable. It can **delegate its web-research phase to `deep-research`**, then layer on the rest. |
| **`Plan` agent / execution-plan format** | Produces an implementation plan assuming the *what* is decided | Is **upstream** — decides the *what/whether*, then **hands the decided proposal to** the planning layer for the *how*. Seam: proposal-builder = "should we + what"; Plan = "how." |
| **Plan mode (`EnterPlanMode`)** | A harness gate for proposing a code change before acting | Different axis — that gates *edits*; proposal-builder develops *ideas*. They co-exist. |
| **`AskUserQuestion`** | Asks the user a structured question | A **tool proposal-builder orchestrates** at step 4, not a competitor. |

The unique value is the **combination**: codebase + web grounding, an explicit
facts-vs-decisions discipline with the human in the loop, and a committed
artifact that deepens and converges — none of the above do all three.

## Next step

On approval, author the skill **for the agentics marketplace** — with the
right-sizing triage, the 8-step workflow, the artifact-shape template, and the
principles table — using this very document (and its siblings) as the skill's
canonical worked examples.
