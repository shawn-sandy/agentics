# Building against a design canvas

Loaded from Step 2, and **only** when the spec's frontmatter carries a
`design-dir:` key. A spec without one implements exactly as it always did — no
extra read, no behaviour change of any kind.

## What the key names

`design-dir:` is a repo-relative directory (`docs/designs/<plan-slug>`) holding
the `.dc.html` artboards `/plan-agent:design` derived from this plan. Its
sibling key `design:` is the published canvas's artifact URL, which the renderer
turns into the plan header's **View design** link. Read the local artboards, not
the published canvas: the directory is what is guaranteed present offline, and
it is what `check-design-drift.py` compares against.

## The rule

Before writing any code, list `*.dc.html` in that directory and read each one.

Each artboard's basename is the slug of the step it covers — lowercase the
step's action text, non-alphanumeric runs become `-`, keep the first six words.
`check-design-drift.py` is the executable definition of that slug; the skill and
the hook must agree on it or every canvas reads as drift.

Then:

- **A step with a matching artboard is built to match it.** The artboard is the
  target, not a suggestion — layout, hierarchy, labels, and states come from it.
  Where the artboard and the step's prose disagree, the artboard is the newer
  intent: say so in one line and follow the artboard.
- **A step with no artboard is unaffected.** Housekeeping steps — a version
  bump, a test file, a README edit — have no user-facing surface and never had
  an artboard. Their absence is the design working, not a gap to fill.

Never edit an artboard to match what you built. The canvas is the spec, and a
person editing it in the GUI is the feature working; rewriting it from the
implementation destroys the only record of the intent.
