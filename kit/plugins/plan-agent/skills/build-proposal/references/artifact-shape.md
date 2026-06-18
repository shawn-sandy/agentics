# The proposal-artifact shape (canonical)

The structure a decision-complete proposal converges on. Write
`<resolved-dir>/<slug>.md` in this order. **Tier 1** keeps the short subset
(Context · Core finding · recommendation · Open questions); **Tier 2** uses the
full shape and deepens it over rounds. Never emit empty sections — add a section
only when it carries grounded content.

## Section order

1. **Front-matter** — YAML: `status` (lifecycle `proposal` → `plan` once it
   hands off), `type` (`feature` | `design` | `refactor` | `chore`), `created`
   (`YYYY-MM-DD`), `repo-name`. Add `modified:` when a later round updates it.
2. **Title + framing note** — `# Proposal: <one-line idea>`, followed by a block
   quote that states *this is a proposal for review, not an execution plan* and
   names what is grounded vs. what is decided.
3. **TL;DR** *(Tier 2)* — 3–5 lines: the core finding and the recommended path,
   readable on its own.
4. **Context** — the idea and why it is on the table; what already exists that it
   touches. Ground the "what exists" in real files/specs, not memory.
5. **Core finding** — the **one** central insight, called out as a block quote.
   This is the load-bearing sentence: how the idea relates to what exists. Not a
   summary, not a survey.
6. **Side-by-side / comparison** — the idea vs. the existing approach in a table
   (dimension × idea × ours). This is where the core finding is made concrete.
7. **Locked & resolved decisions** — what is settled, **dated**. Split "settled
   before this draft" from "resolved in the `<date>` review". Every
   `AskUserQuestion` answer lands here (and propagates to the sections it
   touches).
8. **Workstreams / options** — the distinct strands of work, each self-contained.
   One per non-overlapping concern.
9. **Risks & tensions** — honestly stated, including what is hard, what could
   fail to converge, and where the design is under strain.
10. **Open questions** — **decisions only**. Facts must be resolved by research
    before they leave this section. If an item is still a missing fact, it
    belongs back in research, not here.
11. **Roadmap** — phased, dependency-ordered, each phase sized **S / M / L**.
    Tier 1 may collapse this to a single recommendation line.
12. **Appendices** — the grounded artifacts that make claims testable: mapping
    tables, worked examples, I/O contracts, inventories. Each appendix should be
    a candidate future execution-plan input.
13. **Next step** — the handoff line: convert to an execution plan via
    `/plan-agent:implementation-plan <resolved-dir>/<slug>.md`. The proposal
    stops here.

## Skeleton

```markdown
---
status: proposal
type: feature
created: YYYY-MM-DD
repo-name: <repo>
---

# Proposal: <one-line idea>

> This is a proposal for review, not an execution plan. It captures
> <what was grounded> and proposes <the path>. The load-bearing decisions are
> resolved (see Locked decisions); execution is handed off (see Next step).

## TL;DR
<3–5 lines: core finding + recommended path.>

## Context
<The idea, why now, and the existing thing it touches — grounded in real sources.>

## Core finding
> <The one central insight, as a block quote.>

## Side-by-side
| Dimension | The idea | Our current approach |
|---|---|---|
| … | … | … |

## Locked & resolved decisions
Settled before this draft:
1. **<decision>.** <consequence>

Resolved in the <YYYY-MM-DD> review:
2. **<decision>.** <rationale + what it propagates to>

## Workstreams
### A — <name>
<scope, seam, grounding>

## Risks & tensions
- **<risk>.** <why, and the mitigation or stop-condition>

## Open questions (decisions only)
- <a genuine human decision, not a missing fact>

## Roadmap
| Phase | Work | Size | Depends on |
|---|---|---|---|
| 1 | … | S | — |

## Appendix A — <grounded artifact>
<mapping table / worked example / I/O contract>

## Next step
Convert to an execution plan: `/plan-agent:implementation-plan docs/proposals/<slug>.md`
```

See [example-design-md-spec-alignment.md](example-design-md-spec-alignment.md)
(Tier 2, multi-round) and
[example-proposal-builder-skill.md](example-proposal-builder-skill.md)
(the recursive case) for full worked instances of this shape.
