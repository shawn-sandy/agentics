# Phases 3 and 4 — the generic XML layers and the drafting rules

The `proposal` type's own layer mapping stays in the skill core: it is the one
that carries grounded evidence downstream, and a pass-through rule behind a link
is a rule that may never load. Everything below covers the four author-facing
types.

## Phase 3 — map interview answers to XML layers

Apply only the layers the Phase 1 technique matrix selected for this type. Skip
any layer whose type is not in that matrix.

- **Role assignment** (system + creative): wrap the persona/role answer in
  `<role>...</role>`
- **Instructions and constraints** (system only): wrap instructions in
  `<instructions>...</instructions>`, constraints in
  `<constraints>...</constraints>`
- **Context block** (task + creative): wrap background and audience context in
  `<context>...</context>`
- **Examples** (task): prepare an `<example>...</example>` slot with a
  placeholder from the interview answer
- **Thinking/CoT** (task + analytical): add a `<thinking>...</thinking>`
  scaffold before the main instruction
- **Document grounding** (analytical): add a
  `<document>{{DOCUMENT_CONTENT}}</document>` wrapper and a quote-extraction
  instruction
- **Self-check** (analytical): add a final "Before responding, verify..." clause

## Phase 4 — resolving the template

Read the template with the Read tool, resolving the path as
`${CLAUDE_PLUGIN_ROOT}/skills/prompt/references/<type>-prompt-template.md`.
If `${CLAUDE_PLUGIN_ROOT}` is unavailable, fall back to a Glob search:
`Glob("**/plan-agent/skills/prompt/references/<type>-prompt-template.md")`.

Substitute every `{{PLACEHOLDER}}` with the structured content from Phase 3, the
interview answers from Phase 2, and the intent from Phase 1. Remove placeholder
lines whose technique the matrix did not select — for example, drop the
`<thinking>` block from a creative prompt rather than leaving it empty.

## Phase 4 — writing rules

From Anthropic's best practices:

- Use positive framing — "Do X", not "Don't do Y" — per "Be direct about the
  desired output"
- Lead with the most important instruction
- Be specific about output format: length, structure, tone
- Every instruction should be actionable and unambiguous
