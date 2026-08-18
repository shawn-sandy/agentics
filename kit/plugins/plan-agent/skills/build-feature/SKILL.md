---
name: build-feature
model: claude-fable-5
description: "Turns a feature idea into a team feature doc that splits into plans. Recommends sized, dependency-ordered sub-features. Use when asked for a feature doc or to break a feature into plans."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, WebSearch, WebFetch, Skill, Agent
argument-hint: "<feature idea> [--dir <path>] [--tier 0|1|2]"
---

# Plan Agent — Build Feature

Turns a committed feature idea into a **team-readable feature doc** —
`docs/features/<slug>.md` — covering the product aspects (context, problem and
users, goals, scope, UX notes, risks) and ending in the load-bearing section: a
**recommended breakdown into smaller sub-feature plans**, each sized, ordered
by dependency, and carrying a paste-ready planning prompt.

It is the sibling of `build-proposal` and reuses its loop: frame, confirm,
research in parallel, separate facts from decisions, converge. The seam
differs — a proposal answers *should we?*; a feature doc answers *what are we
building, and how does it split into plans?* If the user is still asking
should-we, route to `/plan-agent:build-proposal` instead.

## Scope Constraint — Feature Docs Only

**This skill shapes the feature and recommends its split. It does not
implement, and it does not generate the plans.**

- The deliverables are the feature doc plus, at convergence, one saved prompt
  per sub-feature (see *Artifact resolution*).
- Do not write source code, configs, or plan documents. `Read`, `Glob`,
  `Grep`, `Bash`, `Agent`, `WebSearch`, `WebFetch` are for read-only research.
- Every sub-feature hands off through its paste-ready prompt — plan
  generation stays a user-initiated step, exactly like `build-proposal`'s
  hand-off seam.

## Invocation & Arguments

Two activation paths:

- **Command:** `/plan-agent:build-feature <feature idea> [flags]` —
  `$ARGUMENTS` carries the idea and any flags.
- **Model invocation (ambient):** Claude auto-activates when the user asks for
  a feature doc, asks to break a feature into plans, or describes a committed
  feature that needs shaping before planning. `$ARGUMENTS` is empty; derive
  the idea from the triggering message. If it is too vague to restate in one
  line, ask once via `AskUserQuestion` ("What feature should the doc cover?")
  and stop if still empty.

Parse `$ARGUMENTS` (or the conversation-derived text):

- **`<feature idea>` (required):** all text that is not a flag.
- **`--dir <path>`** — override the **features** directory, where the team
  deliverable lands. The prompts directory resolves independently (see
  *Artifact resolution*); the flag follows the primary artifact.
- **`--tier 0|1|2`** — force a tier instead of inferring one in Step 1.

## Right-sizing triage (the scale-down gate)

Step 1 first picks a **tier**, so a plan-sized feature never gets a
ten-section doc:

| Tier | Signal | Response |
|---|---|---|
| **0 — Plan-sized** | Single surface, already clear, would yield one plan | Say so and hand the user the exact command `/plan-agent:implementation-plan <idea>` to run — **write no artifact of either kind** and stop. The feature-doc layer adds nothing to a feature that is already one plan. |
| **1 — Focused** | One domain, two or three likely sub-features | One research pass; the short shape (Context, Goals, Scope, Risks, Sub-feature breakdown). Often a single round. |
| **2 — Full** | Multiple domains or user-facing surfaces, real product decisions open | The full shape from [references/feature-doc-shape.md](references/feature-doc-shape.md), deepened over rounds. |

The tier is a starting estimate — escalate 1 → 2 if research reveals more
surface, and collapse to Tier 0 if the "feature" turns out to be one plan.
Name the tier out loud.

## Artifact resolution

Derive the `<slug>` once from the feature name as a kebab-case noun
(`bulk-export`, `dark-mode`) and use it everywhere.

| Artifact | Path | Written |
|---|---|---|
| **Feature doc** | `<features-dir>/<slug>.md` | every round, in place |
| Sub-feature prompts | `<prompts-dir>/feature-<slug>-<sub-slug>.md` | **only at convergence** (Step 8) |

**Features directory** (first match wins), then `mkdir -p` before the first
write:

1. `--dir <path>` if provided.
2. `planAgent.featuresDirectory` via Claude Code's settings precedence —
   project-local `.claude/settings.local.json`, then project
   `.claude/settings.json`, then global `~/.claude/settings.json`.
3. `${PWD}/docs/features/` otherwise.

**Prompts directory** — resolved the same way but from `promptsDirectory`
(the key `prompt` and `build-proposal` already read), falling back to
`${PWD}/docs/prompts/`. Never overridden by `--dir`.

## Workflow

Treat the steps as a loop the human steers, not a one-shot run.

### Step 0 — Self-bootstrap (exit plan mode)

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

### Step 1 — Frame

Restate the feature in **one line** and name the domain(s) it touches. Pick
the **tier** (or honor `--tier`). If the idea is underspecified, ask 2–3
clarifying questions via `AskUserQuestion` *before* researching. If the tier
is **0**, route per the triage table and stop.

**Restate; do not enrich.** Every goal and motive in the one-liner must be one
the human actually stated. A missing motive is a clarifying question, not a
blank to fill.

### Step 1b — Confirm the ask (the gate)

**Tier 1 and 2 only.** Present the framed feature — one-liner, domains, tier —
then `AskUserQuestion` with two options: **Looks right** (proceed) or
**Refine it** (redraft from the correction and ask again). Bound refines at
**two** rounds; past that, adopt the human's latest wording verbatim and
proceed — the gate is then settled, not pending. Nothing in Step 2 starts
before this gate settles, and the restatement never shares a message with the
first research call.

### Step 2 — Fan out research, in parallel

Identify the **external** sources (competitor behavior, upstream specs, docs)
and **internal** sources (this codebase) the feature touches, and gather them
concurrently. Ground every claim; never speculate from memory.

- **Internal:** spawn `Agent` subagents (`Explore` for breadth) to map the
  code the feature lands in. Get the codebase agent in flight **before** the
  first web fetch and never block on its dispatch — but collect its findings
  before Step 3 synthesizes, and say so if they never arrived.
- **External:** `WebSearch` + `WebFetch` for the facts the doc will cite; when
  the `deep-research` skill is available and the feature warrants a cited
  sweep, delegate to it — it is optional, not a hard dependency; fall back to
  direct fetches otherwise.
- **Quantify** — real counts, file lists, call sites, not estimates.

**No `Agent` available?** Some sessions withhold it. Do the internal sweep
yourself with `Glob`/`Grep`/`Read`, sequentially — the parallelism is an
optimization, the grounding is the requirement. Say in the round's report that
research ran sequentially, so a reader knows the breadth came from one pass
rather than several. Never let a missing tool become a reason to synthesize
from memory.

### Step 3 — Synthesize the feature's shape

State how the feature relates to what exists: what is already there to build
on, what is genuinely new, and **where the seams are** — the natural fault
lines that become sub-features. The seams drive the breakdown, so surface
them explicitly.

### Step 4 — Separate facts from decisions

Two lists: **known** (facts research resolved) vs. the **human's call**
(scope cuts, priority, UX direction). Unresolved facts loop back to Step 2.
Proceed only when the open items are decisions, and say so explicitly.

### Step 5 — Resolve decisions with the human

`AskUserQuestion`, **recommendation-first** — the best option labeled
"(Recommended)" with its rationale, never a bare menu. After each answer,
record it in the doc and propagate its consequences to every section it
touches, the sub-feature breakdown included.

### Step 6 — Author the feature doc

Assemble the round's content in the canonical shape —
[references/feature-doc-shape.md](references/feature-doc-shape.md) — scaled
to the tier, and write `<features-dir>/<slug>.md`, updating it **in place**
each round. Never emit empty sections. Do not write sub-feature prompts yet:
the breakdown may still merge or split, and prompts written per round go
stale by convergence. When the project is a git repo, offer to commit each
meaningful round.

**Open every precedent before citing it.** A breakdown entry that points a
sub-feature at an existing file — "models `X`", "follows the pattern in `Y`",
"extends `Z`" — is making a claim about what that file does, and the future
plan will inherit it unchecked. Read the file and confirm it does what you are
about to say it does. Step 2's *ground every claim* is easy to lose here: the
citation is written two steps later, from memory of a filename that sounded
right. A precedent that turns out not to hold is worth more than one that
does — say so in the entry, because the sub-feature then has no model to copy
and is almost certainly bigger than it looks.

### Step 7 — Deepen on request

Each "keep going" adds a distinct grounded layer — a competitor teardown, a
worked user flow, a data-model sketch. The reviewer test for any addition:
*would a sub-feature's future plan cite it?* If not, it is volume, not depth.

### Step 8 — Converge and hand off

When the doc is decision-complete and the breakdown is settled — every
sub-feature named, sized S/M/L, dependency-ordered, none still in question —
write the **per-sub-feature saved prompts**, one per sub-feature, by
delegating to `prompt`:

```
Skill(skill: "plan-agent:prompt", args: "task --out <prompts-dir>/feature-<slug>-<sub-slug>.md --answers-gathered <that sub-feature's breakdown entry, plus the doc's Goals & success metrics, Scope, UX & accessibility notes, and Risks verbatim, plus the feature doc's path>")
```

- **The leading `task` token is not optional.** `prompt` skips its
  type-confirmation gate whenever `--answers-gathered` is present — that is
  the unattended-caller path — so an unpinned type is *inferred* with nobody
  to catch a miss, and a sub-feature worded analytically or creatively would
  select the wrong technique matrix and template. Sub-feature prompts are
  always implementation work, so pin `task`, exactly as `build-proposal` pins
  its own type.
- **`--out` is not optional** — passing the path makes both sides agree by
  construction, so the paths cited in the doc's breakdown are byte-identical
  to the files written.
- **Carry the feature-wide constraints into every prompt.** The breakdown
  entry alone is not enough: the paste-ready command hands
  `implementation-plan` this prompt and a one-line objective, never the
  feature doc, so goals, scope cuts, UX and accessibility requirements, and
  risks are unrecoverable downstream unless they travel inside the prompt.
  Include the doc's path too, so a reader can go back to the source.
- **`--answers-gathered`** skips `prompt`'s interview; Steps 4–5 already
  resolved every decision. This is `prompt`'s standard authoring path — no
  `proposal` type, no changes to the `prompt` skill.

**Verify every prompt file before declaring convergence.** `Skill()` has no
documented return value, so a failed or partial delegation is silent. After
the invocations, confirm each `--out` path exists and holds that
sub-feature's content. Any missing or empty file → leave `status: gathering`,
name the sub-features whose prompts did not land, and stop; a doc marked
`converged` while citing a path that was never written is worse than one
still marked in progress, because the breakdown reads as ready to hand off.

Once every prompt is verified, update the doc's breakdown so each sub-feature
cites its prompt path, set the doc's `status:` to `converged`, and **stop**. Report the doc path and
each prompt path. The doc's breakdown carries a paste-ready
`/plan-agent:implementation-plan` command per sub-feature — running them, in
dependency order, is the user's step, not this skill's.

## Writing Style

Direct, imperative, developer-friendly — real names, measured counts, lists
over prose. Goals are measurable, scope cuts are explicit, and the breakdown
holds **sub-features only** — wish-list items go to the doc's out-of-scope
list, labeled as such. No emojis in the generated markdown.
