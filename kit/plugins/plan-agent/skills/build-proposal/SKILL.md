---
name: build-proposal
model: claude-fable-5
description: "Turns a vague idea into a decision-complete proposal. Researches web and codebase, separating established facts from open decisions. Use when the user floats an idea or asks should-we."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, WebSearch, WebFetch, Skill, Agent, Artifact
argument-hint: "<idea> [--dir <path>] [--tier 0|1|2]"
---

# Plan Agent — Build Proposal

A **thinking partner** that turns a vague-but-promising idea into a
decision-complete proposal. It grounds every claim in real sources, keeps a
hard line between *facts to look up* and *decisions for the human*, drives the
human decision cadence, and converges on a single living **saved prompt** —
`docs/prompts/proposal-<slug>.md`, authored by delegating to
`plan-agent:prompt` — that deepens each round and is copy-pasteable into
the planning layer.

It is a **loop, not a pipeline** — the human steers it with "keep gathering,"
answers to questions, and "let's build it."

## Scope Constraint — Proposals Only

**This skill decides *should-we + what*. It does not implement, and it does not
author the execution plan.**

- The deliverable is a saved proposal prompt under the resolved prompts
  directory, plus the deprecated legacy copy (see *Artifact resolution*).
- Do not write source code, configs, migrations, or the implementation plan.
- Use `Read`, `Glob`, `Grep`, `Bash`, `Agent`, `WebSearch`, `WebFetch` for
  read-only research only.
- At convergence the skill **stops** and hands off to the planning layer
  (`/plan-agent:implementation-plan`). The seam: build-proposal owns
  *should-we + what*; planning owns *how*.

If the idea sounds like "fix X" or "build Y now," it is likely Tier 0 — answer
or route it directly (see the triage), do not spin up the loop.

## Invocation & Arguments

Two activation paths:

- **Command:** `/plan-agent:build-proposal <idea> [flags]` — `$ARGUMENTS`
  carries the idea and any flags.
- **Model invocation (ambient):** Claude auto-activates when the user floats an
  idea, asks a "should-we / how-would-we" question, or asks to compare an
  external approach to theirs and align. `$ARGUMENTS` is empty; derive the idea
  from the triggering message or recent conversation. If the idea is too vague
  to restate in one line, ask once via `AskUserQuestion` ("What's the idea you
  want a proposal for?") and stop if still empty.

Parse `$ARGUMENTS` (or the conversation-derived text on the model path):

- **`<idea>` (required):** all text that is not a flag. This is the raw idea.
- **`--dir <path>`** — override the **prompts** directory, where the
  authoritative artifact lands (see *Artifact resolution*). It follows the
  authoritative artifact, so since 6.0.0 it no longer names the proposals
  directory.
- **`--tier 0|1|2`** — force a tier instead of inferring one in Step 1. Rarely
  needed; the triage normally picks the tier and escalates/de-escalates as
  research reveals scope.

Echo the restated idea and the chosen tier after Step 1 — then confirm them
with the human at Step 1b before any research starts.

## Right-sizing triage (the scale-down gate)

Step 1 first picks a **tier**, so a small idea never gets a 10-section doc.
Scale the loop and the artifact to match:

| Tier | Signal | Response |
|---|---|---|
| **0 — Answer** | Single fact, known answer, or a well-specified task | Answer directly or route to the right skill; **do not invoke the loop** (e.g. "what version is plan-agent?", "fix this null check"). |
| **1 — Lightweight** | A small, well-scoped idea touching one surface | One research pass; a short prompt from the slot subset `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{OPEN_QUESTIONS}}`, `{{CORE_INSTRUCTION}}`; skip appendices and roadmap. Often a single round. |
| **2 — Full** | Broad/ambiguous idea, external + internal surface, real decisions to make | The full 8-step loop and every slot the research grounds, deepened over multiple rounds. |

**Tier 0 writes no artifact of either kind** — not a prompt, not a legacy copy.
Downstream depends on this: `build`'s Step 1b falls through to direct plan
authoring precisely when the proposal stage produces nothing, so a Tier 0 run
that wrote a file would silently break that chain.

**Tier 1 omits the unpopulated slots rather than emitting them empty.** A
heading with nothing under it is volume, not depth, and reads to the planning
layer as a section that was considered and came back blank.

The tier is a starting estimate, not a cage — **escalate Tier 1 → 2** if
research reveals more surface, and **stop early** if a Tier 2 idea collapses to
a clear answer. Name the tier out loud; it sets the human's expectations for
depth and pace.

## Artifact resolution

Two artifacts, one authoritative. Derive the `<slug>` once from the idea as a
`verb-target` kebab-case name (e.g. `adopt-design-md`,
`compare-state-libraries`) and use it for both.

| Artifact | Path | Status |
|---|---|---|
| **Saved prompt** | `<prompts-dir>/proposal-<slug>.md` | **authoritative** |
| Legacy proposal doc | `<proposals-dir>/<slug>.md` | deprecated, removed in 6.1.0 |

**The prompt filename carries no date.** `proposal-<slug>.md` —
never `proposal-<slug>-<YYYY-MM-DD>.md`: the file is a living document that deepens
over rounds, and a dated name would resolve to a different path the moment a
loop crosses midnight, forking the document in two. The slug is the identity;
`created:` and `modified:` carry the dates.

**Prompts directory** (first match wins), then `mkdir -p` it before the first
write:

1. `--dir <path>` if provided.
2. `promptsDirectory` via Claude Code's settings precedence — project-local
   `.claude/settings.local.json`, then project `.claude/settings.json`, then
   global `~/.claude/settings.json`. Same key `prompt` and
   `artifact-tools:prompt-artifact` read, so all three agree on where prompts
   live.
3. `${PWD}/docs/prompts/` otherwise.

**Legacy proposals directory** — resolved the same way but from
`planAgent.proposalsDirectory`, falling back to `${PWD}/docs/proposals/`. It is
never overridden by `--dir`: the flag follows the authoritative artifact.

The runnable resolver for both is in
[references/artifact-resolution.md](references/artifact-resolution.md) — read it
at Step 6, when a directory is actually needed.

## Workflow

Follow these steps. Treat them as a loop the human steers, not a one-shot run.

### Step 0 — Self-bootstrap (exit plan mode)

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

### Step 1 — Frame

Restate the idea in **one line** and name the domain(s) it touches. Pick the
**tier** from the triage above (or honor `--tier`). If the idea is
underspecified, ask **2–3 clarifying questions** via `AskUserQuestion` *before*
researching; if it is already clear, proceed. Do not add friction to a
well-specified idea. If the tier is **0**, answer or route directly and stop —
do not author a proposal.

**Restate; do not enrich.** The one-liner may compress and it may name the
surface, but every goal, motive, and success condition in it must be one the
human actually stated. Adding a plausible downstream purpose they never
mentioned — a reason the thing is wanted, a decision the result will feed — is
the failure this step exists to prevent, because the whole loop then researches
that invention. If a motive seems missing, it is a clarifying question, not a
blank to fill.

### Step 1b — Confirm the ask (the gate)

**Tier 1 and 2 only.** Tier 0 has already answered and stopped; there is
nothing to confirm.

Present the framed ask — the one-line objective, the domains, and the tier —
then call `AskUserQuestion` with two options:

- **Looks right** — proceed to Step 2.
- **Refine it** — the human corrects the objective, scope, or tier.

On **Refine it**, redraft from their correction and ask again. Bound it at
**two** refine rounds; if the third pass still misses, use their latest wording
as the objective **verbatim** and move on — past that point they are faster at
saying it than you are at guessing it. **Exhausting the bound is a pass, not a
pending question:** the human's own words are the objective at that point, so
the gate is settled and Step 2 proceeds. Do not ask a fourth time, and do not
stall waiting for a "Looks right" the bound has already stood in for.

**Nothing in Step 2 may start before this gate is settled** — by "Looks right,"
or by the refine bound above resolving to the human's verbatim wording. Never
put the restatement and the first research tool call in the **same message** —
the framing then scrolls by as narration while the fan-out is already running.
Research spends subagents and web fetches against this objective, so a misread
here is paid in full and surfaces at Step 3 or later.

Announcing the tier is not the gate, and neither is asking whether to proceed.
Ask whether **the restated objective is what they meant**.

### Step 2 — Fan out research, in parallel

Identify the **external** sources (web/docs, the actual upstream spec/repo) and
**internal** sources (this codebase) the idea touches, and gather them
**concurrently**. Ground every claim in a real source; never speculate from
memory.

- **External:** delegate the web-research phase to the `deep-research` skill
  when it is available and the idea warrants a deep, cited sweep —
  `Skill(skill: "deep-research", args: "<the question>")`. **deep-research is
  optional, not a hard dependency.** When it is unavailable, or the idea needs
  only a quick fact check, fall back to `WebSearch` + `WebFetch` directly.
- **Internal:** spawn `Agent` subagents (`Explore` for read-only breadth, or
  `general-purpose`) to map the codebase in parallel, preserving main-thread
  context. Read the real files, schemas, and configs the idea concerns.
- **Quantify, don't hand-wave** — measure the real surface (counts, file lists,
  call sites) rather than estimating.

**Get the codebase agent in flight before the first fetch, and never wait on
it.** Either shape works: batch the `Agent` and the first
`WebFetch`/`WebSearch`/`deep-research` call as separate tool calls in **one
message**, or dispatch the `Agent` first and let it run in the background while
external research proceeds. **Never pass `run_in_background: false` to the
codebase agent** — a blocking dispatch followed by twenty inline greps and a
late first fetch is the serial path with a subagent bolted on: full delegation
cost, no overlap.

"Never wait on it" governs the dispatch, not the result: **collect the agent's
findings before Step 3 synthesizes.** If the dispatch failed or returned
nothing, say the internal research is incomplete and drop any claim that rested
on it — a synthesis that quietly omits the codebase half reads exactly like one
that covered it.

### Step 3 — Synthesize the core finding

Don't dump what you read — state the **central insight**: how the idea relates
to what already exists, as a side-by-side comparison. Surface the load-bearing
realization, not a survey. This becomes the proposal's *Core finding* block
quote and *Side-by-side* table.

### Step 4 — Separate facts from decisions

Maintain two lists: what is now **known** (facts resolved by research) vs. what
is genuinely the **human's call** (decisions). If the remaining unknowns are
still *facts*, loop back to Step 2 ("keep gathering"). Only when the remaining
unknowns are **decisions, not missing facts**, proceed. **Signal convergence
explicitly** — say so when the open items are decisions, not facts.

### Step 5 — Resolve decisions with the human

Use `AskUserQuestion`, **recommendation-first**: label the best option
"(Recommended)" with its rationale — never a bare menu. After each answer,
**record it in the artifact and propagate its consequences** to every section it
touches (Locked decisions + each affected Workstream, Open question, Roadmap
item). Decision drift is the main failure mode; the propagate-on-answer rule is
load-bearing.

### Step 6 — Author the artifacts (dual-write)

Assemble the round's content in the **canonical shape** — see
[references/artifact-shape.md](references/artifact-shape.md) for the section
order and the section-to-slot mapping. Scale to the tier. Then write **both**
artifacts, prompt first.

**1. The saved prompt (authoritative).** Delegate to `prompt` rather than
hand-authoring the file:

```
Skill(skill: "plan-agent:prompt", args: "proposal --out <prompts-dir>/proposal-<slug>.md --answers-gathered <the assembled proposal content>")
```

- **`--out` is not optional.** `Skill()` has no documented return value, so this
  skill cannot read back where the file landed; and `prompt`'s own Phase 7
  would otherwise resolve its own directory and derive its own 3–5 word intent
  slug — a different path from the `verb-target` one derived above. Passing the
  path explicitly makes both sides agree by construction, so the path handed off
  in Step 8 is byte-identical to the file actually written. Never derive the path
  independently on both sides and hope they match.
- **`--answers-gathered`** skips `prompt`'s own interview. Step 5 already
  resolved every decision with the human; re-interviewing would ask them again
  for answers this skill is holding.
- `prompt` records `status:` (`gathering` until Step 8 declares
  convergence, then `converged`), `modified:`, and `generated-sha:`, and on
  round two rewrites that same file **in place** — no `-2` variant. It asks
  before overwriting a body that was hand-edited since it last wrote.

**2. The legacy proposal doc (deprecated).** Also write
`<proposals-dir>/<slug>.md` in the canonical shape, leading with this banner
directly under the H1:

```markdown
> **Deprecated.** The authoritative artifact is the saved prompt at
> `<prompts-dir>/proposal-<slug>.md`. This copy is written for one deprecation
> release (plan-agent 6.0.0) and is removed in 6.1.0. Edit the prompt, not this
> file.
```

The prompt is the deliverable; chat is scaffolding. When the project is a git
repo, offer to **commit each meaningful round** so the artifacts, not the chat,
are the record.

### Step 7 — Deepen on request

Each "continue / keep going" adds a **distinct layer** — tooling surface, worked
examples, appendices, roadmap, a diagram — grounded in new sources, never
padding. The reviewer test for any new section: *could it be a future
execution-plan input?* If not, it is volume, not depth.

### Step 8 — Converge and hand off

When the proposal is **decision-complete** (open items are decisions the human
has now made, facts are grounded, the roadmap is sized), set the prompt's
`status:` to `converged` and **stop**. Do not author the execution plan. Hand the
saved prompt to the planning layer for a **full planning pass** — not a 1:1
conversion:

> The proposal is decision-complete at `<prompts-dir>/proposal-<slug>.md`. To
> turn it into an execution plan, run:
> `/plan-agent:implementation-plan <objective> --from-prompt <prompts-dir>/proposal-<slug>.md`

Report the prompt path — the same one passed to `prompt` via `--out` in
Step 6, byte-for-byte. Never report the legacy copy as the deliverable.

**Always offer the artifact.** Before handing off, ask once via
`AskUserQuestion` whether to publish the converged proposal as a shareable
claude.ai artifact. On yes, load the `artifact-design` skill first to calibrate
the page, then build it from the proposal's canonical sections and publish with
the `Artifact` tool:

```
Skill(skill: "artifact-design")
Artifact(file_path: "<the page you wrote>", favicon: ..., description: ...)
```

Ask on **every** converged run. A blanket "no more questions," "don't ask me
anything," or `--answers-gathered` covers the *proposal's* decisions, not this
one, and never suppresses the offer — publishing is the only step here the
human cannot undo by editing a file. On no, hand off as normal. Never publish
without an explicit yes.

**A failed publish does not cost the handoff.** Report the error and continue
to the handoff below — the proposal saved in Step 6 is the deliverable, and the
page was optional. Do not retry silently, and do not let it swallow the paths
the human is waiting on.

**Pass the path behind `--from-prompt`, never as a positional token.** A
proposal carries Workstreams and a Roadmap, not a `Steps`/`Changes` section, so
handing `implementation-plan` a positional `.md` token triggers its **conversion
mode** (which skips clarify/align/interview and maps sections 1:1) and produces a
plan with no actionable steps. Leading with objective text is *not* sufficient
protection: that scan takes the first `.md`-suffixed positional token anywhere in
the string, not just the first one. A flag value is not a positional token, and
`--from-prompt` is mutually exclusive with conversion mode — a positional `.md`
alongside it is rejected as ambiguous rather than silently converted. Those two
rules together are what make this a guarantee rather than a convention; the flag
alone would not be, since an objective can carry an `.md` of its own. It selects
**prompt-source mode** — the full workflow, where the skill explores the
proposal, drafts real steps (the *how*), and authors tests. Still lead with the
objective: it is what the plan is about, and what type inference reads. Reaffirm
the seam: this skill decided *should-we + what*; planning owns *how*.

## Operating principles & relationship to existing capabilities

The ten guardrails that make the loop converge (ground every claim, quantify,
separate facts from decisions, recommendation-first questions, record &
propagate, iterative deepening, parallel fan-out, surface incidental findings,
commit each round, signal convergence) and how this skill composes with
`deep-research`, `implementation-plan` / the `Plan` agent, and
`AskUserQuestion` live in
[references/operating-principles.md](references/operating-principles.md). Read
it before running a Tier 2 loop.

## Worked exemplars (built-in regression corpus)

Authoring a proposal must reproduce shapes like these. Two trimmed, real
proposals ship flat under `references/`:

- [references/example-design-md-spec-alignment.md](references/example-design-md-spec-alignment.md)
  — a **Tier 2** exemplar (multi-round deepening, locked decisions, appendix).
- [references/example-proposal-builder-skill.md](references/example-proposal-builder-skill.md)
  — the **recursive** exemplar (a proposal proposing this very skill).

If a generated proposal can't match these shapes, the loop ran too shallow.

## Writing Style

Direct, imperative, developer-friendly — real names (file paths, function
names, CLI flags, measured counts), lists over prose, one idea per item. The
**Core finding** is a single load-bearing sentence, not a summary. **Open
questions** hold *decisions only* — facts must be resolved by research first. No
emojis in the generated markdown.
