# Proposal Prompt Template

Used by `prompt` for the **proposal** prompt type — the artifact
`plan-agent:build-proposal` converges on.

Techniques applied: Long-context grounding · XML structure (`<context>`,
`<finding>`, `<decisions>`) · Comparison tables · Positive framing · Output
format

The slots map 1:1 onto the canonical proposal sections documented in
`build-proposal/references/artifact-shape.md`. Omit any slot the round has no
grounded content for — **never emit an empty heading**. Tier 1 populates only
`{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{OPEN_QUESTIONS}}`, and
`{{CORE_INSTRUCTION}}`.

---

## Template

```text
<tldr>
{{TLDR}}
</tldr>

<context>
{{CONTEXT}}
</context>

<finding>
{{CORE_FINDING}}
</finding>

<comparison>
{{COMPARISON_TABLE}}
</comparison>

<decisions>
Locked and resolved — treat these as settled; do not reopen them:
{{LOCKED_DECISIONS}}
</decisions>

<workstreams>
{{WORKSTREAMS}}
</workstreams>

<risks>
{{RISKS}}
</risks>

<open-questions>
Decisions still owned by the human — surface them, do not answer them:
{{OPEN_QUESTIONS}}
</open-questions>

<roadmap>
{{ROADMAP}}
</roadmap>

<appendices>
{{APPENDICES}}
</appendices>

{{CORE_INSTRUCTION}}
```

---

## Placeholder Guide

| Placeholder | Source | Example |
|-------------|--------|---------|
| TLDR | Proposal TL;DR section (Tier 2 only) | "Adopt DESIGN.md as the spec surface; the two formats already agree on 9 of 11 fields." |
| CONTEXT | Proposal Context section | "The repo ships two token formats. This asks whether one can be derived from the other rather than maintained twice." |
| CORE_FINDING | Proposal Core finding block quote — one load-bearing sentence | "DESIGN.md is not a competing format; it is the same token set with a human-readable header." |
| COMPARISON_TABLE | Proposal Side-by-side table, passed through as markdown | "\| Dimension \| The idea \| Ours \|" |
| LOCKED_DECISIONS | Proposal Locked & resolved decisions, dated | "1. **Keep both formats for one release.** Consumers migrate on their own schedule." |
| WORKSTREAMS | Proposal Workstreams, one per non-overlapping concern | "**WS1 — Generator.** Emit DESIGN.md from the existing token JSON." |
| RISKS | Proposal Risks & tensions | "**Drift between the two files.** Mitigated by generating one from the other." |
| OPEN_QUESTIONS | Proposal Open questions — decisions only, never missing facts | "Should the deprecated format warn on read, or stay silent until removal?" |
| ROADMAP | Proposal Roadmap, phased and S/M/L sized | "\| Phase \| Work \| Size \| Depends on \|" |
| APPENDICES | Every proposal appendix, concatenated and passed through verbatim | "Appendix A — field-by-field mapping table" |
| CORE_INSTRUCTION | Proposal Next step section — the handoff becomes the instruction | "Author an execution plan that delivers WS1 and WS2. Draft real steps; do not restate the headings above." |

---

## Assembled Example

```text
<tldr>
DESIGN.md and the token JSON are the same 11 fields in two encodings. Generate
the former from the latter and delete the hand-maintained copy.
</tldr>

<context>
The repo ships design tokens twice: `tokens.json` (consumed by the build) and
`DESIGN.md` (read by humans and by the acss-kit theme skills). Both are edited
by hand. Three of the last five token PRs updated one and forgot the other.
</context>

<finding>
DESIGN.md is not a competing format — it is the same token set plus a
human-readable header, so one file can be generated from the other rather than
kept in sync.
</finding>

<comparison>
| Dimension | Generate DESIGN.md | Keep both by hand |
|---|---|---|
| Drift | Impossible by construction | Observed in 3 of the last 5 PRs |
| Review surface | One file | Two files, diffed separately |
| Migration cost | One generator script | Zero |
</comparison>

<decisions>
Locked and resolved — treat these as settled; do not reopen them:
1. **`tokens.json` is the source of truth.** DESIGN.md becomes generated output.
2. **The generator ships with the build, not as a separate CLI.** One fewer
   thing to install, and it cannot be skipped.
3. **Generated DESIGN.md carries a "do not edit" banner.** Hand edits are the
   failure mode the change exists to remove.
</decisions>

<workstreams>
**WS1 — Generator.** Emit DESIGN.md from `tokens.json`, banner included. Small.
**WS2 — Wire into the build.** Regenerate on every token change; fail the build
when the checked-in file differs from the generated one.
**WS3 — Remove the hand-edit path.** Delete the manual section from the
contributor docs and point it at the generator.
</workstreams>

<risks>
**Generated output churns the diff.** Stable key ordering keeps the diff to the
tokens that actually changed.
**Downstream tools read DESIGN.md's prose header.** The generator reproduces the
header verbatim from a template rather than synthesizing it.
</risks>

<open-questions>
Decisions still owned by the human — surface them, do not answer them:
- Should the build fail on a stale DESIGN.md, or regenerate it in place and
  commit? Failing is louder; regenerating is quieter but hides the mistake.
</open-questions>

<roadmap>
| Phase | Work | Size | Depends on |
|---|---|---|---|
| 1 | WS1 generator | S | — |
| 2 | WS2 build wiring | M | 1 |
| 3 | WS3 docs cleanup | S | 2 |
</roadmap>

<appendices>
Appendix A — field-by-field mapping

| tokens.json key | DESIGN.md heading | Notes |
|---|---|---|
| `color.*` | `## Color` | flattened to one row per role |
| `space.*` | `## Spacing` | baseline emitted as a prose line |
</appendices>

Author an execution plan that delivers WS1 through WS3 in roadmap order. Draft
real, actionable steps naming the files each one touches — do not restate the
headings above as steps. Treat the locked decisions as settled inputs, and carry
the open question into the plan's unresolved-questions section rather than
answering it.
```
