---
name: build
description: "Implements a plan file that already exists. Walks its steps, ticks the spec, re-renders, and runs the completion gates. Use when asked to implement an existing plan."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode
argument-hint: "[<plan.md|plan.html>] [--dir <path>]"
---

# Plan Agent — Build

## Overview

Implements a plan file that already exists — the execution half of
`implementation-plan`, which authors a plan and stops. Walks the steps, ticks
the spec, re-renders, and runs the completion gates.

**The markdown spec is the source of truth.** Every progress mark is a spec
edit followed by a re-render: `[x]` step markers, `- [x]` criteria, `status:`,
`## Completion Report`. Never `checked` attributes in the HTML, never a JS
toggle, never browser-only persistence — a user ticking a box in the preview
browser changes only their local DOM, and the next re-render discards it.
Unchecking is the same rule in reverse: flip the bullet back to `- [ ]` in the
spec.

## Invocation & Arguments

- **Command:** `/plan-agent:build [<plan path>] [--dir <path>]` — `$ARGUMENTS`
  carries an optional plan path (`.md` spec or `.html`; an `.html` resolves to
  its sibling `.md`) and an optional plans-directory override.
- **Model invocation:** activates on "implement the plan at …", "build the plan
  in <file>". Requires a plan that **already exists** — if there is no plan
  file, stop and route to `/plan-agent:implementation-plan <objective>` rather
  than authoring one here.

## Step 0 — Exit plan mode

This skill writes source files. Bootstrap out of plan mode first: use
`ToolSearch` with `select:ExitPlanMode`, then call `ExitPlanMode`. Silent, no
plan document.

## Re-render (subroutine — referenced by every step below)

```bash
RENDERER="${CLAUDE_PLUGIN_ROOT}/scripts/build-plan-html.mjs"
[ -f "$RENDERER" ] || RENDERER="scripts/build-plan-html.mjs"
node "$RENDERER" "<stem>.md" -o "<stem>.html"
```

`<stem>` is the resolved plan's path without its extension, fixed in Step 1
(the subroutine is defined here but never runs before Step 1 resolves it).
Run this after **every** batch of spec edits — status changes included — and
always as the final action. A non-zero exit that names a missing or malformed
section means the spec edit broke the format: fix the markdown and re-run,
never hand-edit the HTML to compensate. Any other failure — `MODULE_NOT_FOUND`,
a missing renderer, a node crash — is an environment problem, not a spec
problem: report it and stop rather than rewriting a valid spec. The plugin's
`render-plan-html.py` hook also re-renders on each spec write; run the command
explicitly anyway so a parse failure surfaces here instead of silently.

## Step 1 — Resolve the plan

Resolve the plans directory the way sibling skills do: `--dir` if given, else
the `planAgent.plansDirectory` / `plansDirectory` setting (project-local
`.claude/settings.local.json` → project `.claude/settings.json` →
`~/.claude/settings.json`), else `docs/plans/`.

1. `$ARGUMENTS` names a path → use it **as given** if that file exists
   (absolute paths and `--dir tmp/plans` plans resolve here). Otherwise retry
   its basename under the resolved plans directory. Still nothing → say which
   paths were tried and stop; do not fall through to discovery and implement a
   different plan.
2. No path argument → list `.md` specs in the resolved plans directory whose
   frontmatter `status:` is `todo` or `in-progress`, newest `created:` first
   (missing or tied `created:` → fall back to file mtime). **Never descend into
   `archive/`.** One match: use it. Several, or any ambiguity in the ordering:
   ask via `AskUserQuestion`. None: say so and stop.
3. An `.html` argument resolves to its sibling `<stem>.md`. No sibling spec
   (legacy HTML-only plan) → stop and say so; this skill edits specs, not HTML.

**Preconditions — check before writing anything:**

- Spec already `status: completed` → stop and ask via `AskUserQuestion`
  whether to re-implement; do not silently redo finished work.
- Steps already carrying `[x]` → resume from the first unmarked step rather
  than re-applying completed ones.
- Dirty working tree → report the uncommitted files and ask whether to
  proceed, so the plan's changes stay separable from pre-existing work.

Echo the resolved spec path, `<stem>`, and objective before starting.

## Step 2 — Implement

Set the spec's `status:` to `in-progress` and re-render, then work through each
step sequentially — apply the changes, verify each step, and mark progress in
the spec as you go (insert the `[x]` marker after the finished step's number;
the re-render flips the card and chip).

## Step 3 — Acceptance criteria gate (mandatory)

1. Read each criterion from the spec's `## Acceptance Criteria` bullets.
2. Verify each one — run the relevant command or inspect the changed files.
3. Flip a bullet to `- [x]` only after confirming it; flip back to `- [ ]` to
   undo. Spec edits only (see the source-of-truth rule above).
4. If any criterion cannot be verified, list the unverified items via
   `AskUserQuestion` ("Mark them as done anyway?" — `Yes, check them off` /
   `No, leave unchecked`). Criteria checked off this way are **not verified**:
   record each one as a `## Completion Report` bullet naming the criterion and
   that it was accepted unverified.
5. Every criterion checked → continue to Step 4. Any left unchecked → set
   `status: in-progress`, record each unchecked criterion as a
   `## Completion Report` bullet, and re-render (which stamps the status into
   all three HTML representations). Then **continue to Step 4 anyway** — the
   objective still has to be verified, and its result belongs in the same
   report. An unchecked criterion blocks `completed`, not the rest of the run.

**Do not set `status: completed` here** — that happens in Step 5, after
end-to-end verification. Writing it now would advertise a completed plan on
the gallery for the whole duration of Step 4's fix loop.

## Step 4 — End-to-end verification gate (mandatory)

Confirms the *objective* works, not just that criteria are met.

1. Read the plan's Verification and Tests sections.
2. Run the objective-verification test via its authored **Run** command; run
   the other test entries via the project's test runner against their **File**
   paths (those cards carry no per-card run command by design — a missing one
   is not a defect). No detectable runner → run only the objective test and say
   so. The objective test's **Run** command always exists and always runs —
   Tier 2 included, where it is a plain shell command (`grep -q`, `test -f`).
   If the spec somehow has no **Run**, author one now against the objective,
   re-render, then run it; never fall back to inspection alone.
3. Confirm the objective test passes and every verification step holds.
4. **On failure — fix and re-verify (bounded loop):** diagnose, fix the source
   files, re-run from sub-step 2, up to 3 times. Still failing → STOP and ask
   via `AskUserQuestion` ("End-to-end verification is still failing after 3
   fix attempts: <summary>. How do you want to proceed?") with `Keep trying` /
   `Mark in-progress and stop` / `Mark completed anyway`. Set status per the
   chosen option; for either "Mark" option add a Completion Report bullet
   naming the failing check and reason.
5. Proceed only once verification holds — or the user explicitly chose to
   proceed anyway. Report the outcome briefly.

## Step 5 — Completion checklist gate (mandatory)

1. Decide the final status:
   - Steps 3 and 4 both held (every criterion `- [x]`, end-to-end verification
     passing) → `completed`.
   - The user answered `Mark completed anyway` at Step 4.4 → `completed`. Their
     explicit override stands; do not walk it back here.
   - Anything else → `in-progress`. This is a legitimate terminal state, not a
     failure to repair.
2. Write a `## Completion Report` section (after `## Acceptance Criteria`)
   listing every gap: one `- <exact step/criterion> — <reason>` bullet each,
   never a generic "some steps incomplete". It carries the Step 3.4 bullets
   (criteria accepted unverified), the Step 3.5 bullets (criteria left
   unchecked), and the Step 4.4 bullet (failing check) — **an unverified or
   overridden item is a permanent record, not a gap to clear.** Delete the
   section only when a later run genuinely verifies every item in it; the
   default "No items to report" sentence then returns on the next re-render.
3. Re-render, then confirm the HTML matches the spec. **When the status is
   `completed`**, the derived state must show all `.step-card` elements
   completed, all criteria inputs `checked`, the three status representations
   `completed`, cc1–cc3 checked, and `completion-checklist` carrying
   `all-complete`. When it is `in-progress`, the derived state must instead
   reflect exactly what the spec says — partial progress is the correct render,
   not a defect to fix.
4. If the derived state disagrees with the spec, fix the **spec**, never the
   HTML — and never by promoting `status:` to satisfy the check. The status is
   an output of sub-step 1, not a knob for making sub-step 3 pass.

`/plan-agent:finalize-plan` applies the same completion rules to a plan
implemented outside this skill, including an auto-check-verified-only mode and
its HTML-drift reconciliation. Keep the two consistent when either changes.

## Step 6 — Report and hand off

State what was implemented, what verification ran, and the final status. Then
stop: leave the source changes, the updated spec, and the re-rendered HTML in
the working tree. Commit only if the user asks — and confirm the branch is not
a protected one (`main`/`master`) before doing so.
