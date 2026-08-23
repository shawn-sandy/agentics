---
name: build
description: "Implements a plan file that already exists. Walks its steps, ticks the spec, re-renders, and runs the completion gates. Use when asked to implement an existing plan."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode
argument-hint: "[<plan.md|plan.html>] [<objective>] [--type feature|fix|refactor|docs|chore] [--dir <path>]"
model: opus
---

# Plan Agent — Build

## Overview

**The markdown spec is the source of truth.** Every progress mark is a spec
edit followed by a re-render: `[x]` step markers, `- [x]` criteria, `status:`,
`## Completion Report`. Never `checked` attributes in the HTML, never a JS
toggle, never browser-only persistence — a user ticking a box in the preview
browser changes only their local DOM, and the next re-render discards it.
Unchecking is the same rule in reverse: flip the bullet back to `- [ ]` in the
spec.

## References

- `references/invocation.md` — activation, flags, argument precedence
- `references/resolve-plan.md` — Steps 0-1
- `references/author-plan-chain.md` — Step 1b
- `references/phase-checkpoints.md` — Step 2, phased specs
- `references/design-spec.md` — Step 2, specs carrying a design canvas
- `references/completion-gates.md` — Steps 3-5
- `references/re-render.md` — a re-render that exits non-zero

## Invocation & Arguments

Read `references/invocation.md` before parsing `$ARGUMENTS`.

## Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Per `references/resolve-plan.md`.

## Re-render (subroutine)

```bash
plan-agent-render "<stem>.md" -o "<stem>.html"
```

Bare name, never a path — this plugin's `bin/` is on `PATH`. `<stem>` is the
resolved plan's path without its extension, fixed in Step 1. Run after
**every** batch of spec edits, status changes included, and as the final
action. A non-zero exit means the spec edit broke the format: fix the markdown and
re-run, never hand-edit the HTML to compensate. Failure modes:
`references/re-render.md`.

## Step 1 — Resolve the plan

Read `references/resolve-plan.md` now and follow its Step 1. A missing path stops:
never implement a different plan, and do not enter Step 1b.
Headless, take each gate's named default and log it.
Already `status: completed` → ask; do not silently redo finished work.

## Step 1b — Author a plan first (the no-plan chain)

Reached only from Step 1's no-path branch. Read
`references/author-plan-chain.md` and follow it. An abandoned chain leaves both
artifacts uncommitted: **Never clean either one up.**

## Step 2 — Implement

Set the spec's `status:` to `in-progress` and re-render, then work through each
step sequentially — apply the changes, verify each step, and mark progress in
the spec as you go (insert the `[x]` marker after the finished step's number;
the re-render flips the card and chip).

**Visual spec** (`design-dir:` in the frontmatter): follow
`references/design-spec.md` before writing code. Its artboards are what the
user-facing steps are built to match; steps with none are unaffected.

**Phased spec** (`### Phase: <name>` headings in `## Steps`): follow
`references/phase-checkpoints.md`. It **stops at each boundary by default**;
`--continue` overrides. Unphased specs never stop.

## Step 3 — Acceptance criteria gate (mandatory)

Read `references/completion-gates.md` now and run its Step 3.

## Step 4 — End-to-end verification gate (mandatory)

Per `references/completion-gates.md` Step 4.

## Step 5 — Completion checklist gate (mandatory)

Per `references/completion-gates.md` Step 5. Fix the **spec**, never the HTML —
and never by promoting `status:` to satisfy the check.

## Step 6 — Report and hand off

State what was implemented, what verification ran, and the final status. Then
stop: leave the source changes, the updated spec, and the re-rendered HTML in
the working tree. Commit only if the user asks — and confirm the branch is not
a protected one (`main`/`master`) before doing so.
