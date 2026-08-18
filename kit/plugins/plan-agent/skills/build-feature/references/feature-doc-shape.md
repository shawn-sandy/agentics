# The feature-doc shape (canonical)

The structure a converged feature doc lands on. Write
`<features-dir>/<slug>.md` in this order. **Tier 1** keeps the short subset
(Context · Goals & success metrics · Scope · Risks & tensions · Sub-feature
breakdown); **Tier 2** uses the full shape and deepens it over rounds. Never
emit empty sections — add a section only when it carries grounded content.

**Risks is in the Tier 1 subset on purpose.** It is the only section that can
say the feature might not work — that an assumption is load-bearing, or that
research could invalidate the split. Drop it and a short doc can only argue
for its own conclusion, which is the failure mode a small feature is *most*
prone to, not least. If a Tier 1 feature genuinely carries no risk worth
naming, that is itself a finding: say so in one line rather than omitting the
section silently.

## Section order

1. **Front-matter** — YAML: `status` (`gathering` while the loop runs,
   `converged` at Step 8), `type: feature`, `created` (`YYYY-MM-DD`),
   `repo-name`. Add `modified:` when a later round updates it.
2. **Title + framing note** — `# Feature: <one-line name>`, followed by a
   block quote stating *this is a feature doc for the team, not an execution
   plan* and naming what is grounded vs. what is decided.
3. **TL;DR** *(Tier 2)* — 3–5 lines: what the feature is, who it serves, and
   the recommended first sub-feature to plan.
4. **Context** — why this feature, why now, and what already exists that it
   builds on. Ground the "what exists" in real files and measured counts.
5. **Problem & users** — who the feature serves and the concrete jobs or
   pains it addresses. Real user situations, not personas-by-template.
6. **Goals & success metrics** — each goal paired with a measurable signal.
   A goal without a metric is a wish; move it to out-of-scope or sharpen it.
7. **Scope** — two lists: **In** and **Out**. Every Out item names why
   (deferred, covered elsewhere, wish list). Explicit cuts are the section's
   job; an empty Out list means the scoping conversation has not happened.
8. **UX & accessibility notes** *(Tier 2, user-facing features)* — the flows,
   states (error/loading/empty), and accessibility constraints
   (keyboard, screen reader, contrast) the sub-feature plans must honor.
9. **Risks & tensions** — what is hard, what could invalidate the split, and
   the load-bearing assumptions with how each gets confirmed.
10. **Open questions** — **decisions only**, and only while `status:
    gathering`. Facts belong back in research; at convergence this section is
    empty and removed.
11. **Sub-feature breakdown** — the load-bearing section; format below.
12. **Next step** — the handoff line: run each sub-feature's paste-ready
    prompt with `/plan-agent:implementation-plan`, in dependency order. The
    feature doc stops here.

## The breakdown entry format

One entry per sub-feature, in dependency order — an entry never depends on a
later one. Each carries, in this order:

- **Name** — kebab-case `<sub-slug>`, unique within the feature.
- **Rationale** — one sentence: why this is its own plan (a seam from
  Step 3), not an arbitrary slice.
- **Size** — S / M / L, judged by surface touched, not optimism.
- **Depends on** — earlier sub-feature names, or `none`.
- **Prompt file** — `<prompts-dir>/feature-<slug>-<sub-slug>.md` (written at
  Step 8; cite the path only once the file exists). Each prompt carries the
  doc's Goals, Scope, UX & accessibility notes, and Risks alongside the entry
  — the paste-ready command below passes the prompt, never the doc, so
  constraints left out here are lost to every downstream plan.
- **Paste-ready prompt** — a fenced block the user runs verbatim.

## Entry skeleton

````markdown
### <n>. <sub-slug> (S|M|L) — depends on: <names|none>

<Rationale sentence.>

Prompt file: `docs/prompts/feature-<slug>-<sub-slug>.md`

```text
/plan-agent:implementation-plan <one-line sub-feature objective> --from-prompt docs/prompts/feature-<slug>-<sub-slug>.md
```
````

The paste-ready command leads with the sub-feature's objective (what type
inference and the plan title read) and passes the saved prompt behind
`--from-prompt` — never as a positional token, which would trigger
`implementation-plan`'s conversion mode and 1:1-map a doc that has no Steps
section. The outer fence around the prompt is four backticks because the
prompt itself contains a fenced block.

## Sizing guide

- **S** — one surface, no schema or API changes; a plan of 1–3 steps.
- **M** — one domain end-to-end (UI + logic, or API + storage); 3–6 steps.
- **L** — crosses domains or migrates data; 6+ steps. An L entry is a smell:
  check for a hidden seam before accepting it — most L sub-features are two
  M ones whose boundary was not looked for.
