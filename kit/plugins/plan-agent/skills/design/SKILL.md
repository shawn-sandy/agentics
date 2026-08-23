---
name: design
model: opus
description: "Generates a design canvas from a plan. Derives one artboard per user-facing step and links the published canvas back into the plan spec. Use when asked to design or mock up a plan."
allowed-tools: Skill, Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode
---

## Plan Agent — Design

Turn a completed HTML plan — or a raw idea, a screenshot, or a Figma file — into
a published design canvas: one artboard per user-facing step, laid out on a
single pan/zoom surface the user refines by hand. The plan's Markdown spec then
carries the canvas URL and the artboard directory, so plan and design stay
linked in both directions.

## Overview

Generates a design canvas from a plan. Derives one artboard per user-facing step
and links the published canvas back into the plan spec. This skill owns only the
derivation — which steps earn an artboard, and what each one is called — plus the
write-back into the spec. Authoring and publishing belong to the built-in
`design` skill, invoked in Step 4.

## Invocation & Arguments

Two activation paths, both driven by this one `SKILL.md`:

- **Command:** `/plan-agent:design <plan.html | one-line idea | image path | figma-url>`
  — `$ARGUMENTS` carries the input.
- **Model invocation (ambient):** auto-activates on intent like "design this
  plan" or "mock up the screens for …". `$ARGUMENTS` is empty; derive the input
  from the triggering message or recent context.

## Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Produce no plan document — execute the workflow directly.

## Step 1 — Resolve the input

Read `$ARGUMENTS` (or the conversation-derived text on the model path):

- If the **first token ends in `.html`**, treat it as a **plan path**. Reduce it
  to its basename for safety, then resolve it under the plans directory
  (configured `plansDirectory`, else `docs/plans/`). Read the file. The
  `<plan-slug>` used throughout is that basename without its extension.
- If the **first token ends in an image extension** (`.png`, `.jpg`, `.jpeg`,
  `.gif`, `.webp`, `.svg`), treat it as an **image path** — a screenshot or
  mockup of the UI to design against.
- If the **first token is a `figma.com` URL** (or the user names a Figma file /
  pastes a Figma link), treat it as a **design path**.
- Otherwise the whole argument string is a **raw idea**.

**After resolving a plan**, scan it for the UI signal keywords listed in Step 2.
If none are present, print exactly one line saying the plan shows no UI signals
and that the artboards will be structural — architecture or flow sketches — then
**proceed**. Never refuse: a canvas of boxes-and-arrows for a data pipeline is a
legitimate use, and a plan with no button in it still has a shape worth drawing.

## Step 2 — Derive the artboards

One artboard per **user-facing step**, uncapped. Do not sample, cap, or
"pick the interesting ones" — the drift check compares the full set.

**The user-facing filter.** A step is user-facing when its ACTION text — the
prose before the `Why:` clause — contains, case-insensitively, at least one of
these UI signal keywords:

React, Vue, Svelte, Angular, `.tsx`, `.jsx`, `.css`, `.html`, `className`,
`style`, Tailwind, button, modal, form, dialog, dropdown, page, component.

This is the same list `skills/review-plan/SKILL.md` Step 3b uses to decide
whether to spawn the UI reviewers — one definition, read from there, never a
second copy that drifts.

A step with no such keyword is **housekeeping** — a version bump, a test file, a
README edit — and produces **no artboard**. The drift check applies the identical
filter, so a housekeeping step is never reported as uncovered; adding an artboard
for one is noise, not coverage.

**The slug rule.** A step's slug is derived from its ACTION text: lowercase it,
strip inline code backticks and Markdown link syntax, replace every run of
non-alphanumeric characters with `-`, collapse repeats, trim leading and
trailing `-`, then keep the **first 6 hyphen-separated words**. The artboard file
for that step is `docs/designs/<plan-slug>/<step-slug>.dc.html`. A step is
covered when an artboard basename, minus its `.dc.html` suffix, equals its slug.
`hooks/check-design-drift.py` is the executable definition of both rules — when
in doubt, read it rather than re-derive.

**No plan steps to work from** — a raw idea, an image, or a Figma file — means
there is nothing to slug. Derive the artboards from the distinct screens the
input implies instead (one per screen, named by what the screen does), and skip
the Step 5 write-back entirely.

## Step 3 — Echo the artboard list back

Before anything is written, list the derived artboard slugs and the step each one
came from, so a wrong reading is caught while it is still free to fix. Name the
steps you classified as housekeeping in one line as well — a step silently
dropped looks identical to a step never read. Adjust if corrected, then proceed.

## Step 4 — Delegate authoring and publishing

Invoke `Skill(skill: "design", args: "<the artboard brief>")` — the **built-in
Claude Code design skill**. Brief it with the artboard list from Step 3, the
purpose of each artboard, and any domain nouns, data shapes, or copy the plan
already fixes.

**That skill owns the artboard file format, its seeding helper, its version
pin, and its capability roster. Reproduce none of them here.** This skill's job
ends at deciding *which* artboards exist and *what each is called*; everything
about how one is built and published is the built-in skill's, and a second copy
of those rules in this file goes stale the first time it changes upstream.

Tell it to write its working files under `docs/designs/<plan-slug>/`, naming each
artboard by its Step 2 slug so the drift check can pair artboard to step. Capture
the published canvas Artifact URL it returns — Step 5 writes that URL, and only
that URL, into the spec.

## Step 5 — Link the plan back (plan path only)

**Plan path only:** skip this entire step for idea, image, and Figma inputs,
which have no owning plan.

Resolve the spec by swapping the resolved plan `.html` for `.md` under the plans
directory (`docs/plans/<plan-slug>.md`).

- **If that `.md` does not exist:** skip the write-back, still deliver the
  canvas, and print exactly one line telling the user to run
  `node <path-to-plan-agent-plugin>/scripts/extract-plan-spec.mjs PLAN.html > PLAN.md`
  (substituting the real plan filename — the shell reads `<` as a redirection,
  so it cannot be a placeholder here) first if they want the link. Most
  committed plans are legacy HTML with no spec sibling; materializing one as a
  side effect would rewrite a plan the user never asked us to touch.
- **If it exists:** `Edit` its YAML frontmatter to carry both keys, adding them
  when absent and replacing the existing values when present:

  ```yaml
  design: https://claude.ai/public/artifacts/<id>
  design-dir: docs/designs/<plan-slug>
  ```

- **Both values stay on one line each.** The frontmatter parser is a naive line
  scanner: an embedded newline or a bare `---` truncates the block and corrupts
  `status` and `created` for every consumer that re-scans it.
- **Only an `http://` or `https://` URL is accepted** for `design:`. The renderer
  silently drops anything else — no anchor, no meta tag, no error — so a
  non-http(s) value reads as "the write-back failed" with nothing to debug.
  Never write one. `design-dir:` is repo-relative with no trailing slash.
- Re-render the plan HTML afterwards so the header link and the gallery chip
  appear: `node scripts/build-plan-html.mjs docs/plans/<plan-slug>.md`. (The
  `PostToolUse` hook normally does this on the spec write; run it explicitly if
  the hook is disabled.)

## Step 6 — Index and report

- The `PostToolUse` hook auto-rebuilds `docs/designs/index.html` on the artboard
  write. If it did not run (e.g. hook disabled), run
  `plan-agent-designs-index` — it ships with this plugin in `bin/`, which Claude
  Code puts on the Bash tool's `PATH`, and defaults to the current directory.
  Invoke it by **bare name**: never by path, and never with a `${VAR}`-style
  path, which the Bash tool rejects outright before permissions are consulted.
- Report the **canvas URL**, the **artboard list** (slug plus the step it
  covers), and the spec path if Step 5 wrote to one.
- Report **what to validate**: whether each artboard reads as the step it claims
  to cover, whether the flow between them holds, and whether any step you
  classified as housekeeping actually has a surface a user will see.
