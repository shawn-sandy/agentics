---
name: verified-change
description: "Changes working code under a local merge gate. Writes the test first, mutation-checks it, then loops until the gate is green. Use when the user asks to prove a change is merge-ready locally."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, TodoWrite, ToolSearch, ExitPlanMode
---

## Overview

Changes working code under a local merge gate. Writes the test first,
mutation-checks it, then loops until the gate is green.

A hosted CI run that is billing-blocked fails every job in seconds with no test
output. Red proves nothing and green never arrives, so merge readiness has to
be provable on this machine. This skill is that proof: a test written before
the change, broken on purpose to confirm it can fail, then a bounded loop
against `scripts/verify.sh` and a written record of what was actually run.

> **Freedom level: Strict** — Follow these steps in order. The mutation check
> in Step 2 is not optional; a test that was never seen to fail is not evidence.

## When not to use

For a brand-new feature where the code does not exist yet, use `tdd-loop` — red
is free there and needs no mutation. Use this skill when the code already works
and red has to be manufactured.

**Trust boundary:** the gate runs whatever tooling the target repo declares, so
running it inside a repo you have not read is arbitrary code execution. Use it
on repos you already trust.

## Step 0: Pre-flight

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Confirm the gate exists at `scripts/verify.sh`. If it does not, install it from
the repo root. Installed as a plugin, the wrapper is already on `PATH`:

```bash
install-verify-gate
```

If that reports `command not found`, this is the project-local copy of the
skill, which ships no `bin/`. Call the bundled asset directly instead:

```bash
bash .claude/skills/verified-change/assets/install-verify-gate.sh
```

Then run the gate once, before changing anything, and read the output:

```bash
bash scripts/verify.sh
```

A gate that is already red is a pre-existing failure, not yours. Report it and
stop; fixing it is a separate change with its own test.

Open a TodoWrite list with the seven steps below.

## Step 1: Write the test first

Write the assertion that fails if the change regresses — before touching the
implementation. Name the behaviour, not the implementation detail: an assertion
locked to exact wording or to a private helper's name fails on a rename and
passes on a real regression.

Run it. It should already be green, because the code currently works. That is
expected, and it is exactly why Step 2 exists.

## Step 2: Mutation-check the test

A test written against working code can pass for the wrong reason, and nothing
finds out until production. So break the implementation on purpose and confirm
the new test goes red.

Read `references/mutation-check.md` for the catalogue of mutations by change
type and the safe break-and-restore protocol. The protocol is load-bearing:
copy the file to a scratchpad, install a `trap` that restores on every exit
path including interrupt, mutate, run the scoped test, restore, and prove the
restore with `cmp -s` against the copy.

If the test stays green through the mutation, it is not a test. Rewrite it and
mutate again. Do not proceed on a test that has never been seen to fail.

## Step 3: Restore and confirm

Restore from the scratchpad copy and prove it:

```bash
cmp -s "$SCRATCH/<file>" <file> && echo restored
```

Use `cmp`, not `git diff --quiet`. A file this change created is untracked, and
`git diff` ignores untracked files entirely — it would report clean over an
unrestored mutation. Delete the scratchpad copy only after the `cmp` passes.

If the restore fails, **STOP** and tell the user which file is still mutated
and where the good copy is. Do not keep working over a broken tree.

## Step 4: Implement

Make the change. Keep it to the smallest diff that makes the Step 1 assertion
meaningful, and leave adjacent problems alone — mention them in one line.

## Step 5: Loop on the gate (max 8 attempts)

Run the gate, read the first failure, fix it, run again. Do not pause to ask
between attempts; the loop is the work.

```bash
bash scripts/verify.sh
```

The gate stops at the first failing stage, so there is exactly one thing to
read each round. Absent tooling reports `SKIP (not configured)` rather than a
silent pass — a SKIP is not a green stage, and the VERIFICATION section records
it as a skip.

At **8 attempts**, stop. Do not report success, and do not keep going. Report:

- the failing assertion, quoted from the gate's own output
- the last diff attempted
- what has been ruled out, so the next person does not retry it

## Step 6: Browser-verify UI changes

Only for changes a browser renders. Skip it otherwise and say so.

Verify the real rendered page — never a Storybook iframe, which stalls — at
**390px** and **1280px**, in **both** light and dark themes, and run axe
against each. Record measured evidence, not impressions: computed styles,
element boxes, the axe violation count. A screenshot proves a screenshot was
taken; it does not prove the contrast ratio.

Both themes are required because a contrast regression usually lands in only
one of them.

## Step 7: Emit the VERIFICATION section

Write the record, then hand it off — paste it into the PR body, or give it to
`git-agent:pr-agent`, which is not modified by this skill.

`references/verification-section.md` holds one filled example: every gate with
its real result, the mutation applied with its observed failure output, and the
evidence paths. Copy that shape. Every line must be something that was actually
run — a VERIFICATION section listing a command nobody executed is worse than no
section, because it reads as proof.

## Verify your own output

Before declaring done, re-read the emitted section and confirm each claim
against the terminal:

1. Every command quoted appears in this session's output with that exit status.
2. The mutation line names a real mutation and quotes the failure it produced.
3. Every SKIP is recorded as a SKIP, not folded into "all checks passed".

If any of the three fails, fix the section — do not ship it.
