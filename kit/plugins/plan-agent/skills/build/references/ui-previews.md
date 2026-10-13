# Building against UI previews

Loaded from Step 2, and **only** when the spec has a `## Previews` section. A
spec without one implements exactly as it always did — no extra read, no
behaviour change of any kind.

## What a preview is

Each `## Previews` item is one self-contained HTML document the plan's author
wrote under `implementation-plan`'s `guidelines/ui-previews.md`: a label, an
optional `(step N)` or `(steps N, M)` tag naming the steps that build it, a
description citing the project tokens it copied, and the fenced `html` block.
Read the previews in the spec, not on the rendered page: the spec is the source,
and the page only frames it.

## The rule

Before writing code for a tagged step, read its preview.

- **A preview is the structure target.** Structure, states, and copy come from
  it — which elements exist and in what order, every state it lays out side by
  side, and the labels, messages, and button text, word for word. It is the
  target, not a suggestion.
- **The project's real tokens and components win on visual detail.** A preview
  is hand-written HTML and CSS approximating the project's UI. Build with the
  project's own components and token variables, never with the preview's hex
  values or class names; where the real component's spacing, radius, or colour
  differs from the preview, the real component is right and there is nothing
  to report.
- **Where step prose and the preview disagree** on structure, states, or copy,
  say so in one line and follow the preview.
- **An untagged preview** belongs to no single step. Read it as context for the
  surface it names.
- **A step with no preview is unaffected.** Housekeeping steps have no surface,
  and their missing preview is the plan working, not a gap to fill.

Never edit a preview to match what you built. It is the record of the agreed
intent and the thing the end-to-end gate checks against; rewriting it from the
implementation turns a failing check into a passing one without fixing
anything. A preview that cannot be built as drawn is a question for the user,
not an edit.

## At the end-to-end gate

Step 4 (`references/completion-gates.md`) also checks the previews: every state
a preview shows — default, hover or focus, disabled, error, empty, loading,
whichever it draws — must exist in the built UI. Drive the built UI into each
one and confirm it. A state with no built counterpart fails the gate like any
other failing check.
