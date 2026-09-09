---
name: build
description: "Implements a plan file that already exists. Walks its steps, ticks the spec, re-renders, and runs the completion gates. Use when asked to implement an existing plan."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, Artifact, Agent
argument-hint: "[<plan.md|plan.html>] [<objective>] [--type feature|fix|refactor|docs|chore] [--dir <path>] [--sequential] [--workflow] [--max <n>] [--worker-model <alias>]"
model: opus
---

# Plan Agent — Build

## Overview

**The markdown spec is the source of truth.** Every progress mark is a spec
edit plus a re-render: `[x]` step markers, `- [x]` criteria, `status:`,
`## Completion Report`. Never `checked` attributes in the HTML, never a JS
toggle, never browser-only persistence.

## References

- `references/invocation.md` — flags, argument precedence
- `references/resolve-plan.md` — Steps 0-1
- `references/author-plan-chain.md` — Step 1b
- `references/phase-checkpoints.md` — phased specs
- `references/dispatch-lanes.md` — laned specs
- `references/design-spec.md` — design canvas
- `references/completion-gates.md` — Steps 3-5
- `references/re-render.md` — non-zero exit

## Invocation & Arguments

Read `references/invocation.md` before parsing `$ARGUMENTS`.

## Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Per `references/resolve-plan.md`.

## Re-render (subroutine)

Sibling exists — overwrite it. No sibling is an artifact plan: render to the
scratchpad and republish to its `artifact-url:`; never create the sibling.

```bash
plan-agent-render "<stem>.md" -o "<stem>.html"
plan-agent-render "<stem>.md" -o "$SCRATCHPAD/<stem>.html"
```

Bare name; `bin/` is on `PATH`. Run after **every** batch of spec edits.
Non-zero exit means the spec broke the format: fix the markdown,
never hand-edit the HTML to compensate.

## Step 1 — Resolve the plan

Read `references/resolve-plan.md` now and follow its Step 1. A missing path stops:
never implement a different plan, and do not enter Step 1b.
Headless, take each gate's named default and log it.
Already `status: completed` → ask; do not silently redo finished work.

## Step 1b — Author a plan first (the no-plan chain)

Reached only from Step 1's no-path branch: read
`references/author-plan-chain.md` and follow it. An abandoned chain leaves both
artifacts uncommitted: **Never clean either one up.**

## Step 2 — Implement

Set the spec's `status:` to `in-progress` and re-render, then branch on the
plan's shape:

- **Fewer than 2 `### Lane:` headings, `workflow: never`, or `--sequential`**
  — work through each step sequentially — apply the changes, verify each
  step, and mark progress in the spec as you go (insert the `[x]` marker
  after the finished step's number; the re-render flips the card and chip).
- **2 or more lanes** — follow `references/dispatch-lanes.md` (`--max`,
  `--worker-model`). `workflow: always`, `--workflow`, or 6+ lanes takes its
  Workflow engine section. In manual permission mode print once, before the
  first dispatch: *Worker permission prompts will bubble to this session; the
  docs recommend pre-approving tools.* Never fall back to sequential on
  permission mode alone.

**Visual spec** (`design-dir:` in the frontmatter): follow
`references/design-spec.md` before writing code.

**Phased spec** (`### Phase: <name>` headings in `## Steps`): follow
`references/phase-checkpoints.md`. It **stops at each boundary by default**;
`--continue` overrides. Unphased specs never stop.

## Step 3 — Acceptance criteria gate (mandatory)

Per `references/completion-gates.md` Step 3.

## Step 4 — End-to-end verification gate (mandatory)

Per `references/completion-gates.md` Step 4.

## Step 5 — Completion checklist gate (mandatory)

Per `references/completion-gates.md` Step 5. Fix the **spec**, never the HTML —
and never by promoting `status:` to satisfy the check.

## Step 6 — Report and hand off

Report what was implemented, what ran, and the final status, then stop. A
sequential run leaves everything uncommitted; a laned run leaves it committed
on the plan branch, unpushed. Commit or push only if the user asks, and never
on `main`/`master`.
