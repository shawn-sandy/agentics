---
name: prompt-artifact
description: "Publishes saved prompts as claude.ai artifacts. Copies raw prompt text verbatim; publishes one prompt or the whole filterable library. Use when asked to publish or share a prompt."
allowed-tools: Bash, Read, Write, Edit, Glob, Skill, Artifact, WebFetch, AskUserQuestion, ToolSearch, ExitPlanMode
---

# prompt-artifact

## Overview

Publish a prompt saved by `plan-agent:prompt` to claude.ai: one by default,
the whole library with `--library`. The page is built around a copy button
returning the prompt **verbatim** — no entities, no re-indentation, no smart
quotes. A copy that pastes back escaped is the skill failing at its only job.
Both modes republish to one URL, so a shared link never rots.

References, under `${CLAUDE_PLUGIN_ROOT}/references/`: `prompt-resolution.md`
(Steps 1–3), `prompt-page.md` (Step 5), `prompt-publishing.md` (Steps 6, 8),
`titles.md` (shared `<title>` rules).

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Resolve the mode

`--library` anywhere in the arguments means **library** mode, anything else
**single**. Settle it before touching the disk.

## Step 2 — Resolve the prompts directory

Run the `PROMPTS_DIR` resolver in `references/prompt-resolution.md` verbatim: it
matches `prompt`'s precedence, and diverging publishes the wrong directory.

## Step 3 — Resolve the prompt(s)

Follow `references/prompt-resolution.md`: never guess, ask. Read the keys you
need, drop unrecognized ones silently.

In library mode, if `Glob` matches nothing, tell the user:

> "No saved prompts found in `<PROMPTS_DIR>`. Run `/plan-agent:prompt` to
> create your first one."

**STOP.** Never publish an empty gallery: a page announcing nothing still costs a
URL and reads as a broken deliverable.

## Step 4 — Scrub before publishing (blocking gate)

Run `social-media-tools:security-scrub` via the `Skill` tool over the prompt body
(single) or every prompt body (library). Prompts quote schemas, endpoints, and
payloads, and leak more readily than their prose suggests.

- `GATE RESULT: BLOCKED` → **hard stop.** No publish, no override. Report the
  masked findings and stop.
- `GATE RESULT: CANCELLED` → the user declined. Stop.
- `GATE RESULT: APPROVED` → continue.

In library mode a finding in **any** prompt stops the whole publish, and the
report names the offending file. Never drop it and ship the rest: the gallery
would silently omit work and the leak would stay on disk.

If `security-scrub` is unavailable, say the scan could not run and ask via
`AskUserQuestion` first. Never skip the gate silently.

## Step 5 — Build the page

Follow `references/prompt-page.md`: self-contained and theme-aware rules, the
six-value escaping table, per-mode layouts, the copy button's three failure modes.
Title per `${CLAUDE_PLUGIN_ROOT}/references/titles.md`.

## Step 6 — Publish, then record the URL

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.

Then follow `references/prompt-publishing.md`: favicon `📝`, plus the per-mode URL
record. Skipping it is the quiet failure — the publish looks fine and the next
session mints a second page.

## Step 7 — Verify the page rendered

Runs only after a successful publish. `WebFetch` is a deferred tool: use
`ToolSearch` with `select:WebFetch` first.

Fetch the returned URL and confirm the page contains the prompt's H1 title
(single) or every published title (library). A returned URL is not evidence it
rendered: a blank artifact returns one too, and a library page missing a card is
the failure this catches.

If a title is absent, report the failure **with the URL** and do not report the
publish as successful.

## Step 8 — Fallback

If publishing fails, the scratchpad copy is not a deliverable. Take the
`.claude/artifacts/` fallback in `references/prompt-publishing.md`, keyed by what
the page *is*, never by date.
