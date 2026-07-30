---
name: diff-artifact
description: "Publishes an annotated diff walkthrough as a claude.ai artifact. Scrubs for secrets, then builds a self-contained page with per-hunk reviewer notes. Use when asked to publish or share a diff."
allowed-tools: Bash, Read, Write, Skill, Artifact, WebFetch, AskUserQuestion, ToolSearch, ExitPlanMode
---

# diff-artifact

## Overview

A raw `git diff` tells a reviewer what moved, never what matters. This skill
writes a note against each meaningful hunk and publishes the result to claude.ai
as one self-contained page with a sticky file sidebar and severity labels.
Publishing sends code to an external service, so the `security-scrub` gate runs
**before** any publish and a `BLOCKED` verdict is a hard stop.

References, under `${CLAUDE_PLUGIN_ROOT}/references/`: `diff-sources.md` (Step 1),
`diff-page.md` (Steps 3–5), `diff-publishing.md` (Steps 6–7), `titles.md` (shared
`<title>` rules).

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Resolve the diff source

Follow `references/diff-sources.md`: branch by default, range for
`abc123..def456`, PR for `#42` or a PR URL. PR mode degrades to a branch diff
rather than failing. An empty diff is nothing to publish; say so and stop.

## Step 2 — Scrub before anything else (blocking gate)

Write the diff to a scratch file and run `social-media-tools:security-scrub` over
it via the `Skill` tool. This gate is **blocking, not advisory**: publishing is
external sharing.

- `GATE RESULT: BLOCKED` → **hard stop.** Do not publish, do not write the page,
  do not offer an override. Report the masked findings and stop.
- `GATE RESULT: CANCELLED` → the user declined. Stop.
- `GATE RESULT: APPROVED` → continue to Step 3.

If `security-scrub` is unavailable (social-media-tools not installed), never skip
the gate silently. Say the scan could not run and ask via `AskUserQuestion`
whether to continue unscanned.

## Step 3 — Annotate the hunks

Read `references/diff-page.md` now and follow its Step 3, including its
scrub-coverage warning: annotations are covered by the Step 5 rescan, not Step 2.

## Step 4 — Build the page

Follow the page requirements in `references/diff-page.md` and the
`${CLAUDE_PLUGIN_ROOT}/references/titles.md` title rules.

## Step 5 — Gate the rendered page (size, then scrub)

Both checks run on the **rendered HTML**, not on the inputs.

**Size.** Run the measure-and-shrink loop in `references/diff-page.md`, counting
every demotion on top of the Step 3 budget.

**Scrub.** Rescan the finished page with `social-media-tools:security-scrub`.
Step 2 covered the diff; this covers what the page publishes: annotations, quoted
context, titles. Step 2's verdicts and blocking behaviour apply unchanged.

## Step 6 — Save the durable copy

Per `references/diff-publishing.md`: write the page into `.claude/artifacts/`
**before publishing**, keyed by what the diff *is*, never by date.

## Step 7 — Publish, then record the URL

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.

Then follow `references/diff-publishing.md`: reuse any recorded URL so the page
updates in place, publish with the favicon `🔍`, record the URL back on success,
take its fallback on failure. Never report a URL a publish did not return.

## Step 8 — Verify the page rendered

Runs only after a successful publish. `WebFetch` is a deferred tool: use
`ToolSearch` with `select:WebFetch` first.

Fetch the returned URL and confirm the page contains the first changed filename
from the diff. A returned URL is not evidence it rendered: a blank artifact
returns one too.

If that filename is absent, report the failure **with the URL** and do not report
the publish as successful.
