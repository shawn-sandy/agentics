# Phase 2 — the type-specific question sets

One set applies per run: the type classified in Phase 1. Read only that set.

Every question is grounded in Anthropic's "Add context to improve performance"
principle, and each names the technique it feeds so a dropped answer shows up as
a hollow slot rather than a silent omission. The `_why_` question in each set is
not filler — it is the one that separates a prompt that states a task from a
prompt that states a task's purpose.

The `proposal` type has no set here. It arrives via `--answers-gathered` from
`plan-agent:build-proposal`, which resolved every decision with the human in its
own Step 5.

## system

- What is the assistant's persona, name, or role? (feeds Role technique)
- What tone and boundaries should it have — e.g. formal, concise, never discuss
  X? (feeds Constraints)
- _Why_ is this assistant being built — what user need or business problem does
  it solve? (feeds motivation context)

## task

- What is the input the model will receive, and what should the output look
  like? (feeds Clarity + Output Format)
- Are there edge cases or failure modes the prompt must handle explicitly?
  (feeds CoT scaffolding)
- _Why_ is this task being automated — what would a bad output look like? (feeds
  motivation/context)

## creative

- What style, voice, or tone should the output have — any reference works?
  (feeds Role + Tone)
- Who is the intended audience and what emotional response should the writing
  evoke? (feeds Context)
- What length and structure should the output have — a single paragraph,
  multiple stanzas, a scene? (feeds Output Format)
- _Why_ this piece — what makes it worth creating right now? (feeds motivation)

## analytical

- What documents, data sources, or content will be passed to the model? (feeds
  Long-context patterns)
- What is the desired analysis depth — surface summary vs. deep comparison?
  (feeds CoT + Output Format)
- _Why_ does this analysis matter — what decision or action does it support?
  (feeds motivation)
