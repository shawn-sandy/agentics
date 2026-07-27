---
session-id: "7be3f0e7-92fe-4840-919f-585568d54d47"
date: 2026-07-27
source: "7be3f0e7-92fe-4840-919f-585568d54d47.jsonl"
type: session-export
title: "Chaining plan authoring into the build skill"
team-artifact-url: https://claude.ai/code/artifact/748b1f1f-077c-4015-a9f8-7d61c3678468
---

# Chaining plan authoring into the build skill

## At a glance

| | |
|---|---|
| Changes shipped | 3 documents (1 proposal, 1 plan spec, 1 render) |
| Files touched | 3, all new, all under `docs/` |
| Decisions made | 8, each with rejected alternatives |
| Open items | 6 |
| Commit | `3c37605` |

The session started as a question — what does the `build` skill do when you give
it no plan? — and ended with a committed, reviewed implementation plan for
changing that answer. No product code changed. What shipped is the design: a
proposal recording the decisions, and a 12-step plan that has already survived a
five-reviewer panel and two rounds of scope correction.

The headline finding came early and shaped everything after it: the pipeline the
work needed already existed, wired in the opposite direction. The task was never
"build a pipeline" — it was "let one skill enter the pipeline that is already
there."

## What changed

### A design proposal for the no-plan chain

**Who it affects:** teammates deciding whether this work should happen.
**What is different now:** `docs/proposals/chain-plan-authoring-into-build.md`
records the load-bearing decisions with dates, the options rejected, and four
appendices grounding the claims — including a trace of a real defect in how
skills inherit models.
**How to reach it:** `docs/proposals/chain-plan-authoring-into-build.md`

### A 12-step implementation plan

**Who it affects:** whoever implements this next.
**What is different now:** `docs/plans/add-plan-authoring-to-build.md` carries 12
steps, 14 acceptance criteria, a Tier 1 test section, and an embedded review
record. Status is `todo` — nothing is implemented.
**How to reach it:** `/plan-agent:build docs/plans/add-plan-authoring-to-build.md`

### A reviewed and twice-narrowed scope

**Who it affects:** nobody yet — this is plan content, not shipped behavior.
**What is different now:** a five-reviewer panel produced three confirmed
high-severity findings, all verified against source before being accepted. Two
later rounds narrowed the design: first fixing a fatal flaw an integration
scenario exposed, then scoping the whole feature to the slash command.
**How to reach it:** the Review Record section inside the plan spec.

## How it works now

The central realization of the session, in one picture. The pipeline already ran
top-down; the proposed change adds one entry arrow, not a new pipeline.

<pre class="mermaid">
graph LR
  BP["build-proposal"] -->|"printed prompt<br/>user pastes"| IP["implementation-plan"]
  IP -->|"Skill() call"| RP["review-plan"]
  IP -->|"Skill() call"| B["build<br/>(writes source)"]
  RP -.->|"returns to menu"| IP
  B -.->|"proposed:<br/>new entry"| BP
  style B fill:#e8f0fe,stroke:#1a73e8,stroke-width:2px
  style BP fill:#fff4e5,stroke:#f59e0b
</pre>

*Look at the dashed arrow from `build` back up to `build-proposal` — that is the
entire proposed addition. Everything else already exists.*

What a command-only run does, after both scope narrowings:

<pre class="mermaid">
flowchart TD
  A["/plan-agent:build a todo app"] --> B{"Plan path given?"}
  B -->|"yes, found"| Z["Implement it"]
  B -->|"yes, missing"| S1["Stop — name paths tried"]
  B -->|"no"| C{"Objective given?"}
  C -->|"yes"| D["Skip discovery entirely"]
  C -->|"no"| E["Offer up to 3 found plans<br/>+ author a new one"]
  D --> F{"Start from a proposal?"}
  F -->|"yes"| G["build-proposal"]
  F -->|"no"| H["implementation-plan"]
  G --> H
  H --> I{"Step 8 menu"}
  I -->|"Exit"| S2["Stop — plan stays todo"]
  I -->|"Implement"| Z
</pre>

*The two `Stop` boxes are deliberate: a mistyped path must not author a plan, and
choosing Exit must not implement anyway.*

## Before and after

| Rule | Before | After (planned) |
|---|---|---|
| No plan argument, none found | Stops, tells you to run another command | Enters proposal to plan to review chain |
| No plan argument, one found | Silently adopts it | Offers it, plus "author a new plan" |
| No plan argument, many found | Asks which | Offers at most 3, states how many were hidden |
| Objective supplied | Not possible — no objective input | Discovery skipped entirely; objective wins |
| Mistyped plan path | Stops, names paths tried | Unchanged, deliberately |
| Plain text "build a todo app" | Requires an existing plan; routes away | Unchanged, deliberately |
| Model used to write source | Session model | Pinned, so it stops inheriting the reviewer's |
| Version bump for this change | n/a | MAJOR, not MINOR |

## Decisions

**Delegate to the existing pipeline head, rather than sequencing stages inside
`build`.** The handoffs already exist; re-implementing them would need a new
suppress-menu flag on a sibling skill plus a re-entrancy guard across three
files. *Rejected:* `build` owning the chain (touches three skills, duplicates
sequencing); a fourth skill owning the pipeline (cleanest separation, but a whole
new skill to avoid ~25 lines).

**Gate the proposal stage behind one question.** The proposal skill triages a
small idea by answering directly and producing no document, which would leave the
chain holding nothing. *Rejected:* always delegating and letting it self-triage;
skipping the proposal stage entirely.

**Trigger on an absent plan argument, and make discovery offer rather than
adopt.** A stale spec in the plans directory could otherwise win over the
objective the user just stated. *Rejected:* skipping discovery entirely (loses
resume-after-interruption); chaining only when the directory is empty (leaves the
silent pickup in place).

**Let "Exit" terminate the whole chain.** Exit is the only point where the user is
asked about implementing, so treating it as declining just the inner skill's
offer would implement work they declined seconds earlier. *Rejected:* the narrow
reading, which the proposal originally documented; asking again on return.

**Pin an explicit model on `build`.** Kept even after a reviewer argued against
it. *Rejected:* reverting to inherit, and documenting the defect instead of
fixing it — the reviewer's cost and access objections are recorded as a known
tradeoff rather than acted on.

**Assert tests section-scoped, not file-wide.** The existing test file documents a
file-wide grep passing against a mutation that deleted all five rules it guarded.
*Rejected:* file-wide greps; a structural parser heavier than anything else in
the test directory.

**Bump MAJOR, not MINOR.** The repo's own rule classifies argument-format changes
as MAJOR, and the automated version check only enforces "greater than main," so it
would not have caught the undersized bump. *Rejected:* MINOR, as originally
planned.

**Scope the chain to the slash command only.** The objective becomes a command
parameter rather than a trigger phrase. *Rejected:* a narrow ambient trigger
scoped to creation intent; a wide ambient trigger with runtime disambiguation.

## Learnings

**A skill's model override does not unwind.** It applies for the rest of the
turn, so in a chained run the stage that writes source files inherits whichever
model the last planning skill declared — not the one anyone chose. Found by
reading the reference rather than assuming.

**The repo's only comparable pipeline chose inline over delegation.** The
autonomous ship skill declares the delegation tool in its allowed-tools and never
calls it, reimplementing every stage instead. That is a real counter-argument to
the approach chosen here, and it is recorded rather than explained away.

**Question menus cap at four options.** An unbounded "which plan did you mean?"
offer could not have rendered at all in this repo, which carries a dozen
candidate plans. The design specified a question the interface cannot display.

**A relevance problem can be deleted instead of solved.** Rather than matching an
objective against existing plans by subject, the fix was to notice that an
objective and a discovery offer are mutually exclusive signals. The step got
shorter.

**A confirmed review finding can be un-confirmed by a later scope change.** A
reviewer flagged a line of prose as stale and contradictory; it was verified
against source and accepted. The command-only narrowing then made that same line
correct and load-bearing, flipping its acceptance criterion from "must be absent"
to "must be present."

**Writing into the rendered HTML would have been discarded.** The review skill's
own instructions say to apply edits to the HTML by selector. In this plugin the
spec is the source of truth and the next render overwrites the HTML, so the
edits went to the spec instead.

## Open items

- ~~**The proposal contradicts the plan and was committed that way.**~~ *Resolved
  in review.* Appendix A had the outer skill proceed after Exit while step 7 of
  the plan overrode it. Automated review pushed on the point, so the appendix now
  documents path-based resolution plus an explicit Exit rule covering both `Exit`
  and `Run as workflow`, and names the reading it supersedes.
- **The plan is unimplemented.** Status `todo`, 12 steps, nothing applied.
- **Whether to pin effort alongside model.** The override behavior is documented
  as identical, but no failure has been observed from it.
- **Whether the ten-gate floor justifies revisiting the delegation approach.**
  Captured as a paste-ready follow-up prompt in the plan.
- **What "inherit" actually re-reads** — the session model, or the turn's current
  override. Sidestepped by pinning explicitly.
- **Spec reconstruction for legacy HTML-only plans.** Deliberately left stopping;
  captured as a follow-up prompt.

## Files touched

**Proposals**
- `docs/proposals/chain-plan-authoring-into-build.md` — new. Decision record with
  four appendices; revised once when the trigger was corrected.

**Plans**
- `docs/plans/add-plan-authoring-to-build.md` — new. The 12-step spec and source
  of truth. Renamed mid-session when a filename hook rejected the first name.
- `docs/plans/add-plan-authoring-to-build.html` — new. Generated render; never
  hand-edited.

## Glossary

- **Skill** — a Markdown instruction file a coding agent loads on demand, either
  when the user types its slash command or when its description matches what the
  user asked for.
- **Ambient activation** — a skill loading because its description matched free
  text, as opposed to the user typing its command.
- **Slash command** — explicitly invoking a skill by name, with arguments.
- **Spec and render** — the Markdown file is the source of truth; the HTML beside
  it is generated from it and is safe to overwrite.
- **Plan status** — `todo`, `in-progress`, or `completed`, recorded in the plan's
  frontmatter.
- **Acceptance criterion** — a short statement that is verifiably true or false,
  describing the result rather than the work.
- **Tier 1 / Tier 2** — whether a plan changes runtime source (Tier 1) or only
  documents and metadata (Tier 2). Tier 1 requires more test coverage.
- **Objective-verification test** — the one test that asserts the plan's stated
  goal was actually accomplished.
- **MAJOR / MINOR** — semantic version bumps. MAJOR signals a breaking change to
  anyone already using the thing.
- **Re-entrancy** — a component being entered again while an earlier entry is
  still in progress; here, a skill that calls a chain which calls back into it.
- **Worktree** — a second working copy of a repository checked out to a different
  branch in a separate directory.
