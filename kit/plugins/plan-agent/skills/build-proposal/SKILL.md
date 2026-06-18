---
name: build-proposal
model: opus
description: "Turns a vague idea into a decision-complete proposal — researches web + codebase, separates facts from decisions — use when the user floats an idea, asks should-we, or wants to compare and align."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, WebSearch, WebFetch, Skill, Agent
argument-hint: "<idea> [--dir <path>] [--tier 0|1|2]"
---

# Plan Agent — Build Proposal

A **thinking partner** that turns a vague-but-promising idea into a
decision-complete proposal. It grounds every claim in real sources, keeps a
hard line between *facts to look up* and *decisions for the human*, drives the
human decision cadence, and writes a single living `docs/proposals/<slug>.md`
that deepens each round and converges on something buildable.

It is a **loop, not a pipeline** — the human steers it with "keep gathering,"
answers to questions, and "let's build it."

## Scope Constraint — Proposals Only

**This skill decides *should-we + what*. It does not implement, and it does not
author the execution plan.**

- The deliverable is a proposal document under the resolved proposals directory.
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
- **`--dir <path>`** — override the artifact directory (see *Artifact directory
  resolution*).
- **`--tier 0|1|2`** — force a tier instead of inferring one in Step 1. Rarely
  needed; the triage normally picks the tier and escalates/de-escalates as
  research reveals scope.

Echo the restated idea and the chosen tier after Step 1.

## Right-sizing triage (the scale-down gate)

Step 1 first picks a **tier**, so a small idea never gets a 10-section doc.
Scale the loop and the artifact to match:

| Tier | Signal | Response |
|---|---|---|
| **0 — Answer** | Single fact, known answer, or a well-specified task | Answer directly or route to the right skill; **do not invoke the loop** (e.g. "what version is plan-agent?", "fix this null check"). |
| **1 — Lightweight** | A small, well-scoped idea touching one surface | One research pass; a short proposal (Context · core finding · recommendation · open questions); skip appendices and roadmap. Often a single round. |
| **2 — Full** | Broad/ambiguous idea, external + internal surface, real decisions to make | The full 8-step loop and the canonical artifact shape, deepened over multiple rounds. |

The tier is a starting estimate, not a cage — **escalate Tier 1 → 2** if
research reveals more surface, and **stop early** if a Tier 2 idea collapses to
a clear answer. Name the tier out loud; it sets the human's expectations for
depth and pace.

## Artifact directory resolution

Resolve the proposals directory in this order, then `mkdir -p` it before the
first write — mirroring how `implementation-plan` resolves `plansDirectory`:

1. `--dir <path>` if provided.
2. `planAgent.proposalsDirectory` from `.claude/settings.json` (project first,
   then global `~/.claude/settings.json`).
3. `docs/proposals/` if the repo has a `docs/` directory.
4. The default Claude user proposals folder otherwise.

```bash
# Resolve proposalsDirectory (project settings first, then global), else docs/proposals
python3 - <<'PY'
import json, os
for p in (".claude/settings.json", os.path.expanduser("~/.claude/settings.json")):
    try:
        v = (json.load(open(p)).get("planAgent", {}).get("proposalsDirectory") or "").strip()
        if v:
            print(v); break
    except FileNotFoundError:
        continue
else:
    print("docs/proposals")
PY
```

Derive the `<slug>` from the idea as a `verb-target` kebab-case name (e.g.
`adopt-design-md`, `compare-state-libraries`). Write to
`<resolved-dir>/<slug>.md`.

## Workflow

Follow these steps. Treat them as a loop the human steers, not a one-shot run.

### Step 0 — Self-bootstrap (exit plan mode)

**If currently in plan mode**, call `ExitPlanMode` first and silently — writing
the proposal file is a filesystem mutation that cannot proceed inside harness
plan mode. Skip this step entirely when not in plan mode. `ExitPlanMode` is a
**deferred tool**: use `ToolSearch` with `select:ExitPlanMode` first, then call
`ExitPlanMode`. `WebSearch` and `WebFetch` are deferred too — load them with
`ToolSearch` `select:WebSearch,WebFetch` before first use in Step 2.

### Step 1 — Frame

Restate the idea in **one line** and name the domain(s) it touches. Pick the
**tier** from the triage above (or honor `--tier`). If the idea is
underspecified, ask **2–3 clarifying questions** via `AskUserQuestion` *before*
researching; if it is already clear, proceed. Do not add friction to a
well-specified idea. If the tier is **0**, answer or route directly and stop —
do not author a proposal.

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

Launch the first external fetch and the first codebase agent **together** in a
single turn so they run concurrently.

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

### Step 6 — Author the proposal artifact

Write or append to `<resolved-dir>/<slug>.md` in the **canonical shape** — see
[references/artifact-shape.md](references/artifact-shape.md) for the full
template and section order. Scale the sections to the tier (Tier 1 keeps the
short subset; Tier 2 uses the full shape). The document is the deliverable; chat
is scaffolding. When the project is a git repo, offer to **commit each
meaningful round** so the doc, not the chat, is the record.

### Step 7 — Deepen on request

Each "continue / keep going" adds a **distinct layer** — tooling surface, worked
examples, appendices, roadmap, a diagram — grounded in new sources, never
padding. The reviewer test for any new section: *could it be a future
execution-plan input?* If not, it is volume, not depth.

### Step 8 — Converge and hand off

When the proposal is **decision-complete** (open items are decisions the human
has now made, facts are grounded, the roadmap is sized), **stop**. Do not author
the execution plan. Hand the proposal to the planning layer for a **full
planning pass** — not a 1:1 conversion:

> The proposal is decision-complete at `<resolved-dir>/<slug>.md`. To turn it
> into an execution plan, run:
> `/plan-agent:implementation-plan author an execution plan from the proposal at <resolved-dir>/<slug>.md`

**Lead with the objective, not a bare `.md` path.** A proposal carries
Workstreams and a Roadmap, not a `Steps`/`Changes` section, so handing
`implementation-plan` a bare `.md` first token would trigger its **conversion
mode** (which skips clarify/align/interview and maps sections 1:1) and produce a
plan with no actionable steps. Leading with objective text keeps it in its
**full workflow** — it explores the proposal, drafts real steps (the *how*), and
authors tests. Reaffirm the seam: this skill decided *should-we + what*;
planning owns *how*.

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
