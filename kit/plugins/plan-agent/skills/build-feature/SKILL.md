---
name: build-feature
model: claude-fable-5
description: "Turns a feature idea into a product feature doc for the team. Adds stories, acceptance criteria, metrics, rollout, and a sized sub-feature breakdown. Use when scoping a feature to build."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, WebSearch, WebFetch, Skill, Agent, Artifact
argument-hint: "<feature idea> [--dir <path>] [--tier 0|1|2] [--publish|--no-publish]"
---

# Plan Agent — Build Feature

Turns a committed feature idea into a **product feature doc** —
`<features-dir>/<slug>.md` — carrying what a team needs to build and ship the
thing: context, problem and users, **user stories with acceptance criteria**,
goals with measured baselines, scope cuts, UX notes, **release and rollout**,
risks, and a **breakdown into sized, dependency-ordered sub-features**, each
with paste-ready handoffs to planning, prototyping, and design.

At convergence the doc can be **published as a shareable claude.ai artifact**
that republishes to the same URL every round, so the team watches one link
fill in instead of chasing markdown in a branch.

It is the sibling of `build-proposal` and reuses its loop: frame, confirm,
research in parallel, separate facts from decisions, converge. The seam
differs — a proposal answers *should we?*; a feature doc answers *what are we
building, for whom, how do we know it worked, and how does it split?* If the
user is still asking should-we, route to `/plan-agent:build-proposal` instead.

## Scope Constraint — Feature Docs Only

**This skill shapes the feature and recommends its split. It does not
implement, and it does not generate the plans.**

- The deliverables are the feature doc, one saved prompt per sub-feature at
  convergence, and — on an explicit yes — a published artifact.
- Do not write source code, configs, or plan documents. `Read`, `Glob`,
  `Grep`, `Bash`, `Agent`, `WebSearch`, `WebFetch` are for read-only research.
- Every sub-feature hands off through paste-ready commands — plan, prototype,
  and design generation all stay user-initiated, exactly like
  `build-proposal`'s hand-off seam.
- A mixed request ("spec this feature and build it") still ends at the
  feature doc: deliver it, stop, and wait for the user's explicit approval
  before any plan is generated or any implementation begins — the original
  request is never that approval.
- **Publishing is never automatic.** It is the only step here the human
  cannot undo by editing a file. Step 9 asks, every time.

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
- **`--publish` / `--no-publish`** — pre-answer Step 9's question.
  `--no-publish` skips the offer silently. `--publish` is consent to publish
  *this* run's converged doc; it does not skip the render or the verification,
  and it does not carry to a later run.

## Right-sizing triage (the scale-down gate)

Step 1 first picks a **tier**, so a plan-sized feature never gets a
fourteen-section doc:

| Tier | Signal | Response |
|---|---|---|
| **0 — Plan-sized** | Single surface, already clear, would yield one plan | Write the **one-page doc** (Context, Problem & users, Stories, Scope, Risks, Next step — no breakdown, no prompts), then hand the user a paste-ready `/plan-agent:implementation-plan <objective> --from-prompt <features-dir>/<slug>.md`. **Lead with the objective and pass the doc behind `--from-prompt`; never as a positional token, and never labelled in prose** — `implementation-plan` takes the first *positional* `.md` as a conversion source and 1:1-maps it, and a `feature doc:` label does not make the path non-positional. The flag's value is excluded by rule, so the doc arrives as context. Tier 0 writes no prompt, so that doc is the only carrier for its stories, scope cuts, and risks. The split adds nothing to a one-plan feature; the stories and scope cuts still do. |
| **1 — Focused** | One domain, two or three likely sub-features | One research pass; the Tier 1 subset. Often a single round. |
| **2 — Full** | Multiple domains or user-facing surfaces, real product decisions open | The full shape from [references/feature-doc-shape.md](references/feature-doc-shape.md), deepened over rounds. |

The tier is a starting estimate — escalate 1 → 2 if research reveals more
surface, and collapse to Tier 0 if the "feature" turns out to be one plan.
Name the tier out loud.

**Tier 0 writes a doc but no prompts.** The prompt files exist to carry
feature-wide constraints into a *split*; with one plan there is nothing to
split, and the paste-ready command hands the planner the doc directly.

## Artifact resolution

Derive the `<slug>` once from the feature name as a kebab-case noun
(`bulk-export`, `dark-mode`) and use it everywhere.

| Artifact | Path | Written |
|---|---|---|
| **Feature doc** | `<features-dir>/<slug>.md` | every round, in place |
| Sub-feature prompts | `<prompts-dir>/feature-<slug>-<sub-slug>.md` | **only at convergence** (Step 8), Tier 1+ |
| Rendered page | `<features-dir>/<slug>.html` | only when publishing (Step 9) |
| Published artifact | claude.ai URL, recorded as `artifact-url:` in the doc's front-matter | only on an explicit yes (Step 9) |

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

The rendered page is a sibling of the doc — same directory, same basename —
so a reader who has one can find the other.

## Workflow

Treat the steps as a loop the human steers, not a one-shot run.

### Step 0 — Self-bootstrap (exit plan mode)

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

### Step 1 — Frame

Restate the feature in **one line** and name the domain(s) it touches. Pick
the **tier** (or honor `--tier`). If the idea is underspecified, ask 2–3
clarifying questions via `AskUserQuestion` *before* researching.

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
- **Baselines are research, not estimates.** Every metric's current value gets
  looked up — a query, a dashboard, a log count. A baseline nobody could find
  is written `unmeasured`, which then becomes a sub-feature that adds the
  instrumentation. Never fill the cell with a plausible number.
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

**Write the stories before the seams harden.** A seam that no user story
crosses is an engineering convenience, and a story no seam delivers is scope
the split forgot. Drafting stories here — not at Step 6 — is what keeps the
breakdown answerable to the product, and it is the check the old
engineering-first ordering had no way to run.

### Step 4 — Separate facts from decisions

Two lists: **known** (facts research resolved) vs. the **human's call**
(scope cuts, priority, UX direction, rollout shape, who owns it). Unresolved
facts loop back to Step 2. Proceed only when the open items are decisions, and
say so explicitly.

### Step 5 — Resolve decisions with the human

`AskUserQuestion`, **recommendation-first** — the best option labeled
"(Recommended)" with its rationale, never a bare menu. After each answer,
record it in the doc and propagate its consequences to every section it
touches: the stories, the acceptance criteria, the rollout table, and the
sub-feature breakdown included.

Owner, target, and flag are decisions, not facts — ask for them rather than
inventing them. `unscheduled` and `none` are legitimate answers; a guessed
date is not.

### Step 6 — Author the feature doc

Assemble the round's content in the canonical shape —
[references/feature-doc-shape.md](references/feature-doc-shape.md) — scaled
to the tier, and write `<features-dir>/<slug>.md`, updating it **in place**
each round. Never emit empty sections. Do not write sub-feature prompts yet:
the breakdown may still merge or split, and prompts written per round go
stale by convergence. When the project is a git repo, offer to commit each
meaningful round.

**Reconcile stories against the breakdown every round.** Each story names its
`Delivered by:` sub-feature and each entry names what it `Satisfies` — the two
must agree, and a round that changes the split without re-checking them leaves
a doc that reads consistent and is not. A story with no deliverer is scope
that will be missed; an entry no story claims is scope nobody asked for. Both
are findings worth stating, not silent cleanups.

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
worked user flow, a data-model sketch, a measured baseline that was
`unmeasured` last round. The reviewer test for any addition: *would a
sub-feature's future plan cite it, or would a reviewer accept the feature
because of it?* If neither, it is volume, not depth.

### Step 8 — Converge and hand off

When the doc is decision-complete and the breakdown is settled — every
sub-feature named, sized S/M/L, dependency-ordered, every story claimed by an
entry, none still in question — write the **per-sub-feature saved prompts**,
one per sub-feature, by delegating to `prompt`:

```
Skill(skill: "plan-agent:prompt", args: "task --out <prompts-dir>/feature-<slug>-<sub-slug>.md --answers-gathered <that sub-feature's breakdown entry, plus the stories and acceptance criteria it satisfies, plus the doc's Goals & success metrics, Scope, UX & accessibility notes, Release & rollout, and Risks verbatim, plus the feature doc's path>")
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
  feature doc, so acceptance criteria, goals, scope cuts, UX & accessibility
  notes, rollout constraints, and risks are unrecoverable downstream unless
  they travel inside the prompt. The acceptance criteria matter most — they
  are what the plan's own tests get written against. Include the doc's path
  too, so a reader can go back to the source.
- **`--answers-gathered`** skips `prompt`'s interview; Steps 4–5 already
  resolved every decision. This is `prompt`'s standard authoring path — no
  `proposal` type, no changes to the `prompt` skill.

**Tier 0 skips the prompts entirely** and hands the planner the doc behind
`--from-prompt` (see the tier table — never as a positional token). Go
straight to the handoff line.

**Verify every prompt file before declaring convergence.** `Skill()` has no
documented return value, so a failed or partial delegation is silent. After
the invocations, confirm each `--out` path exists and holds that
sub-feature's content. Any missing or empty file → leave `status: gathering`,
name the sub-features whose prompts did not land, and stop; a doc marked
`converged` while citing a path that was never written is worse than one
still marked in progress, because the breakdown reads as ready to hand off.

Once every prompt is verified, update the doc's breakdown so each sub-feature
cites its prompt path and its handoff commands, set the doc's `status:` to
`converged`, then go to Step 9. Report the doc path and each prompt path.
Running the handoff commands, in dependency order, is the user's step, not
this skill's.

### Step 9 — Offer the artifact

**Ask on every converged run**, unless `--no-publish` was passed. A blanket
"no more questions", "don't ask me anything", or `--answers-gathered` covers
the *feature's* decisions, not this one, and never suppresses the offer.
`--publish` is the only thing that pre-answers it. Never publish without an
explicit yes.

On yes, four moves in order:

1. **Render.** `Skill(skill: "plan-agent:markdown-to-html", args: "<features-dir>/<slug>.md")`
   — doc mode, self-contained HTML, sibling path. **Publishing the `.md`
   directly is a bug, not a shortcut:** the renderer does not parse
   front-matter, so a markdown source cannot set its own `<title>` and the tab
   falls back to the filename, extension included. The page must exist first.
2. **Publish.** `Artifact` is a deferred tool — `ToolSearch` with
   `select:Artifact` before the first call.

   ```
   Artifact(file_path: "<features-dir>/<slug>.html", favicon: "🧩", description: "<one sentence>")
   ```

   If the doc's front-matter already carries `artifact-url:`, pass it as
   `Artifact`'s `url` so the **same page** updates. Keep the title and favicon
   stable across republishes — they are how the team finds the tab again.
3. **Verify.** `WebFetch` the returned URL and confirm the page contains the
   feature's title. A returned URL is not evidence the page rendered — a blank
   artifact returns a URL too. If the title is absent, report the failure
   **with the URL** and do not call the publish successful.
4. **Record.** On a first publish, `Edit` the doc's front-matter to add the
   returned `artifact-url:`. Skip this and the next round silently mints a
   second link, which is the whole thing this step exists to prevent.

Then tell the user the loop plainly: edit the doc, re-run this skill, and the
same URL shows the current version — no new link, no re-share.

**A failed publish does not cost the handoff.** `Artifact` is unavailable in
some sessions (no claude.ai login, or publishing switched off), and
`markdown-to-html` can fail on its own. Say plainly that publishing did not
happen and why, then report the doc and prompt paths as normal — they were the
deliverable before the offer and they still are. Do not retry silently. Never
report a URL that was not returned by a successful publish.

## Writing Style

Direct, imperative, developer-friendly — real names, measured counts, lists
over prose. Stories name a real user type and a real outcome, acceptance
criteria are observable and binary, goals carry baselines, scope cuts are
explicit, and the breakdown holds **sub-features only** — wish-list items go
to the doc's out-of-scope list, labeled as such. No emojis in the generated
markdown; the artifact's favicon is not markdown.
