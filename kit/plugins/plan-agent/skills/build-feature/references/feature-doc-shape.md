# The product-feature-doc shape (canonical)

The structure a converged feature doc lands on. Write
`<features-dir>/<slug>.md` in this order. Never emit empty sections — add a
section only when it carries grounded content.

## What each tier keeps

| Tier | Sections |
|---|---|
| **0 — Plan-sized** | Context · Problem & users · User stories & acceptance criteria · Scope · Risks & tensions · Next step. **No breakdown** — a one-plan feature has nothing to split — and no sub-feature prompts. |
| **1 — Focused** | Tier 0, plus Goals & success metrics · Release & rollout · Sub-feature breakdown. |
| **2 — Full** | Every section, deepened over rounds. |

**Tier 0 still writes a doc.** It is one plan's worth of build, but it is still
a feature the team has to understand, staff, and accept. The stories and the
scope cuts are the part a plan cannot carry — the plan says *how*, and nobody
downstream re-derives *for whom* and *why not the other thing*. What Tier 0
drops is the breakdown, not the product content.

**Risks is in every tier on purpose.** It is the only section that can say the
feature might not work — that an assumption is load-bearing, or that research
could invalidate the split. Drop it and a short doc can only argue for its own
conclusion, which is the failure mode a small feature is *most* prone to, not
least. If a Tier 0 feature genuinely carries no risk worth naming, that is
itself a finding: say so in one line rather than omitting the section silently.

## Section order

1. **Front-matter** — YAML: `status` (`gathering` while the loop runs,
   `converged` at Step 8), `type: feature`, `created` (`YYYY-MM-DD`),
   `repo-name`. Add `modified:` when a later round updates it, and
   `artifact-url:` once the doc has been published (Step 9 owns that key).
2. **Title + framing note** — `# Feature: <one-line name>`, followed by a
   block quote stating *this is a product feature doc for the team, not an
   execution plan* and naming what is grounded vs. what is decided.
3. **TL;DR** *(Tier 2)* — 3–5 lines: what the feature is, who it serves, and
   the recommended first sub-feature to plan.
4. **Context** — why this feature, why now, and what already exists that it
   builds on. Ground the "what exists" in real files and measured counts.
5. **Problem & users** — who the feature serves and the concrete jobs or
   pains it addresses. Real user situations, not personas-by-template. Name
   each distinct user type once; the stories below refer back to these names.
6. **User stories & acceptance criteria** — format below. The section a
   product feature is judged on, and the one an execution plan cannot
   reconstruct from a list of files.
7. **Goals & success metrics** — the table below. A goal without a baseline is
   a wish; sharpen it or move it to out-of-scope.
8. **Scope** — two lists: **In** and **Out**. Every Out item names why
   (deferred, covered elsewhere, wish list). Explicit cuts are the section's
   job; an empty Out list means the scoping conversation has not happened.
9. **UX & accessibility notes** *(Tier 2, user-facing features)* — the flows,
   states (error/loading/empty), and accessibility constraints
   (keyboard, screen reader, contrast) the sub-feature plans must honor.
10. **Release & rollout** *(Tier 1+)* — the table below. Who owns it, how it
    reaches users, and how it gets turned off.
11. **Risks & tensions** — what is hard, what could invalidate the split, and
    the load-bearing assumptions with how each gets confirmed.
12. **Open questions** — **decisions only**, and only while `status:
    gathering`. Facts belong back in research; at convergence this section is
    empty and removed.
13. **Sub-feature breakdown** *(Tier 1+)* — the load-bearing section for
    splitting; format below.
14. **Next step** — the handoff line. Tier 0: one paste-ready
    `/plan-agent:implementation-plan <objective> --from-prompt <features-dir>/<slug>.md`
    — the doc goes behind the flag, never as a positional token, which would
    be read as a conversion source. Tier 1+: run each sub-feature's paste-ready
    commands, in dependency order. The feature doc stops here.

## User stories & acceptance criteria

One entry per story, grouped under the user type from *Problem & users*. A
story that no sub-feature delivers is out of scope — move it or cut it.

```markdown
### As a <user type>, I want <capability> so that <outcome>

- [ ] <acceptance criterion — observable, binary, no adverbs>
- [ ] <criterion covering the failure or empty path>

Delivered by: <sub-slug> | (Tier 0: this plan)
```

**Criteria are observable and binary.** "Loads quickly" is not a criterion;
"first row renders within 400ms on a cold cache" is. Each story carries at
least one criterion for the unhappy path — empty, error, or unauthorized —
because that is the half a plan silently drops.

**`Delivered by:` is the traceability link.** Every story names the
sub-feature that satisfies it, and every sub-feature in the breakdown is named
by at least one story. A sub-feature no story points at is either
infrastructure the stories depend on (say so) or scope nobody asked for.

## Goals & success metrics

| Goal | Metric | Baseline | Target | Source |
|---|---|---|---|---|
| <what improves> | <the measured signal> | <value today, or `unmeasured`> | <value that means success> | <where the number comes from> |

**`Baseline` may be `unmeasured` — it may not be blank.** An unmeasured
baseline is a real finding: it means the first sub-feature has to add the
instrumentation, and that belongs in the breakdown. Guessing a baseline to
fill the cell is worse than admitting there isn't one, because the target then
gets judged against a number nobody measured.

**`Source` names a real place** — a dashboard, a table, a log query, an
analytics event. "We'll know" is not a source.

## Release & rollout

| Field | Content |
|---|---|
| **Owner** | The person accountable for the feature landing, not the whole team. |
| **Target** | A release, a milestone, or `unscheduled`. Never a guessed date. |
| **Flag** | The flag or config gating it, or `none` with why it needs no gate. |
| **Phases** | How it reaches users — internal, then beta, then general; or all at once, stated as a choice. |
| **Rollback** | What turning it off actually does, including anything already-migrated data makes irreversible. |
| **Depends on** | Other teams, vendors, or migrations that gate the launch. `none` if it is self-contained. |

**Rollback is the row that earns the section.** A flag that hides the UI but
leaves a schema migration in place is not a rollback, and the only moment
anyone will notice is during the incident. Say what stays behind.

## The breakdown entry format

*(Tier 1+.)* One entry per sub-feature, in dependency order — an entry never
depends on a later one. Each carries, in this order:

- **Name** — kebab-case `<sub-slug>`, unique within the feature.
- **Rationale** — one sentence: why this is its own plan (a seam from
  Step 3), not an arbitrary slice.
- **Size** — S / M / L, judged by surface touched, not optimism.
- **Depends on** — earlier sub-feature names, or `none`.
- **Satisfies** — the story headings from section 6 this entry delivers. The
  reverse of each story's `Delivered by:`; the two must agree.
- **Prompt file** — `<prompts-dir>/feature-<slug>-<sub-slug>.md` (written at
  Step 8; cite the path only once the file exists). Each prompt carries the
  doc's stories and acceptance criteria, Goals, Scope, UX & accessibility
  notes, and Risks alongside the entry — the paste-ready command below passes
  the prompt, never the doc, so constraints left out here are lost to every
  downstream plan.
- **Handoffs** — the paste-ready commands, in a fenced block the user runs
  verbatim. Every entry gets the plan command. Entries with UI surface also
  get the prototype and design commands.

## Entry skeleton

````markdown
### <n>. <sub-slug> (S|M|L) — depends on: <names|none>

<Rationale sentence.>

Satisfies: <story heading>, <story heading>
Prompt file: `docs/prompts/feature-<slug>-<sub-slug>.md`

```text
/plan-agent:implementation-plan <one-line sub-feature objective> --from-prompt docs/prompts/feature-<slug>-<sub-slug>.md
```

UI surface — click the flow or shape the design first:

```text
/plan-agent:prototype <one-line sub-feature objective> --from-prompt docs/prompts/feature-<slug>-<sub-slug>.md
```

```text
/impeccable:impeccable Design <one-line sub-feature objective>. Stories and acceptance criteria: docs/features/<slug>.md
```
````

**Emit the prototype and design commands only for entries with UI surface.** A
migration, an endpoint, or a schema change has nothing to click and nothing to
design; three commands under an entry that needs one is noise, and noise is
how a reader learns to skip the section. Judge by whether the entry changes
something a user sees.

**The design command passes the doc path, not the prompt.** Design reads
stories, users, and accessibility constraints — the doc has all three in the
shape a designer reads. The prompt is assembled for a planning agent and
flattens them into instructions.

The plan and prototype commands lead with the sub-feature's objective (what
type inference and the title read) and pass the saved prompt behind
`--from-prompt` — never as a positional token, which would trigger
`implementation-plan`'s conversion mode and 1:1-map a doc that has no Steps
section. The outer fence around the entry is four backticks because the entry
contains fenced blocks.

## Sizing guide

- **S** — one surface, no schema or API changes; a plan of 1–3 steps.
- **M** — one domain end-to-end (UI + logic, or API + storage); 3–6 steps.
- **L** — crosses domains or migrates data; 6+ steps. An L entry is a smell:
  check for a hidden seam before accepting it — most L sub-features are two
  M ones whose boundary was not looked for.
