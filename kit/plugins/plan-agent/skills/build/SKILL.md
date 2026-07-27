---
name: build
description: "Implements a plan file that already exists. Walks its steps, ticks the spec, re-renders, and runs the completion gates. Use when asked to implement an existing plan."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode
argument-hint: "[<plan.md|plan.html>] [<objective>] [--dir <path>]"
model: opus
---

# Plan Agent — Build

## Overview

Implements a plan and runs it to done — walks the steps, ticks the spec,
re-renders, and runs the completion gates. Given a plan, that is all it does.
Run as `/plan-agent:build` with no plan named, the command form first enters the
authoring chain in Step 1b — proposal, plan, review — and implements what comes
back. Ambient activation keeps the narrower contract: it requires a plan that
already exists and routes elsewhere when there is none.

**The markdown spec is the source of truth.** Every progress mark is a spec
edit followed by a re-render: `[x]` step markers, `- [x]` criteria, `status:`,
`## Completion Report`. Never `checked` attributes in the HTML, never a JS
toggle, never browser-only persistence — a user ticking a box in the preview
browser changes only their local DOM, and the next re-render discards it.
Unchecking is the same rule in reverse: flip the bullet back to `- [ ]` in the
spec.

## Invocation & Arguments

- **Command:** `/plan-agent:build [<plan path>] [<objective>] [--dir <path>]` —
  `$ARGUMENTS` carries an optional plan path (`.md` spec or `.html`; an `.html`
  resolves to its sibling `.md`), an optional free-text objective, and an
  optional plans-directory override.
- **Parse flags first.** Strip `--dir <path>` and any other recognized option
  with its value out of `$ARGUMENTS` before classifying anything. The test below
  applies to the **first positional token**, never to a flag: `--dir tmp/plans`
  alone leaves no positional token at all, which is a bare `build` and takes the
  discovery offer, not an objective named `--dir`.
- **Objective versus path.** The test applies to that **first positional token
  only**: it is an objective unless that token carries an `.md`/`.html` suffix
  or a `/`.
  Anything path-shaped hits the Step 1 stop rather than being read as prose. A
  slash later in the string is harmless — `add A/B testing support` leads with
  `add` and parses as an objective — but a slash in the *first* token misreads
  the whole objective as a path (`A/B testing for checkout`), so that stop
  message must name the misparse: "read `A/B testing for checkout` as a plan
  path; reword it if you meant an objective". Never a bare list of paths tried,
  which would leave the user with no idea their objective was read as a
  filename.
- **The Step 1b chain is reachable only from the slash command.** The objective
  is a command parameter read from `$ARGUMENTS`. `/plan-agent:build a todo app`
  enters the chain; the same words typed as plain text do not.
- **Model invocation:** activates on "implement the plan at …", "build the plan
  in <file>". Requires a plan that **already exists** — if there is no plan
  file, stop and route to `/plan-agent:implementation-plan <objective>` rather
  than authoring one here. **This is the model path's contract and it is
  unchanged:** `$ARGUMENTS` is empty here, so there is no objective to chain on
  and Step 1b is never entered.

## Step 0 — Exit plan mode

This skill writes source files, so it cannot run inside plan mode.
`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** —
skip this step entirely when not in plan mode, which is the common case for a
standalone `/plan-agent:build` on an existing plan. When calling: use
`ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`
silently. Either way, produce no plan document — execute the workflow directly.

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

**Pre-flight guard — runs before anything else, chain included:**

- Dirty working tree → report the uncommitted files and ask whether to
  proceed, so the plan's changes stay separable from pre-existing work. This
  runs **ahead of Step 1b**, not after it: a chained run crosses a proposal loop
  and a plan interview before it writes a line of source, and asking about
  uncommitted files at the end of that is the worst possible moment.
  `git-agent:ship-autonomous` runs every pre-flight guard before any mutation;
  this matches.
- **Plan artifacts are never pre-existing work.** Exclude the resolved plan's
  own spec and rendered HTML, and any proposal this chain wrote, from the dirty
  report. Without that exclusion the Step 8 `Implement now` callback re-enters
  this skill with the just-authored plan sitting uncommitted, so the guard fires
  at exactly the post-interview moment the hoist exists to avoid — and in a
  headless run the unavailable-question rule below would stop the chain
  outright. When those artifacts are the only changes, the tree is clean for
  this purpose: proceed silently.

**When `AskUserQuestion` is unavailable** — a headless or otherwise
non-interactive run — every gate in this skill **stops and reports the choice it
would have offered**, listing the options. This covers the discovery offer, the
objective prompt, the proposal-versus-direct gate, and the preconditions.
**Never resolve a gate by picking for the user.** A lone discovery candidate
adopted because it was the only one is exactly the silent pickup the offer
exists to prevent, and a proposal-versus-direct gate answered by default commits
the user to an authoring branch they never chose.

Resolve the plans directory the way sibling skills do: `--dir` if given, else
the `planAgent.plansDirectory` / `plansDirectory` setting (project-local
`.claude/settings.local.json` → project `.claude/settings.json` →
`~/.claude/settings.json`), else `docs/plans/`.

1. `$ARGUMENTS` names a path → use it **as given** if that file exists
   (absolute paths and `--dir tmp/plans` plans resolve here). Otherwise retry
   its basename under the resolved plans directory. Still nothing → say which
   paths were tried, add the misparse note above when the token was a
   slash-bearing objective, and **stop**. Do not fall through to discovery and
   implement a different plan, and do not enter Step 1b: chaining on a mistyped
   filename would author a whole plan because of a typo.
2. No path argument → **the only branch that reaches Step 1b.**
   - **An objective was supplied** → skip discovery entirely and go to
     Step 1b. The user has already said what they want, so unrelated `todo`
     specs are noise: discovery selects on `status:` alone with no notion of
     subject, and offering a dozen unrelated plans in answer to "a todo app"
     is worse than not asking.
   - **No objective** → discovery, and it is an **offer, never a silent
     pickup**: list `.md` specs in the resolved plans directory whose
     frontmatter `status:` is `todo` or `in-progress`, newest `created:` first
     (missing or tied `created:` → fall back to file mtime). **Never descend
     into `archive/`.** Present **at most the top three** candidates plus
     `None of these — author a new plan` via `AskUserQuestion`, and state how
     many were suppressed when there are more (`AskUserQuestion` caps at four
     options, so an unbounded offer cannot render at all). This holds for a
     single match too — one candidate is still offered, not adopted. No
     candidates at all → go straight to Step 1b. `None of these` → Step 1b.
3. An `.html` argument resolves to its sibling `<stem>.md`. No sibling spec
   (legacy HTML-only plan) → stop and say so; this skill edits specs, not HTML.
   Do not enter Step 1b: a plan exists and needs its spec reconstructed, not a
   new plan authored on top of it.

**Preconditions — check before writing anything:**

- Spec already `status: completed` → stop and ask via `AskUserQuestion`
  whether to re-implement; do not silently redo finished work.
- Steps already carrying `[x]` → resume from the first unmarked step rather
  than re-applying completed ones.

Echo the resolved spec path, `<stem>`, and objective before starting.

## Step 1b — Author a plan first (the no-plan chain)

Reached only from Step 1's no-path branch, and only via the slash command. Every
stage is delegated to the skill that already owns it — nothing here re-implements
proposal writing, plan authoring, or review. Control returns through
`implementation-plan`'s Step 8 menu.

1. **Objective check — first, before anything else.** No objective was supplied
   (the bare-`build` path, including arriving here through
   `None of these — author a new plan`) → ask for one with `AskUserQuestion`.
   Both the gate below and the delegated skills are meaningless with an empty
   objective, so never invoke one without it.
2. **Proposal-versus-direct gate**, asked on **every** chained entry via
   `AskUserQuestion` ("No plan specified. How do you want to author one?"):
   - `Start with a proposal` — settle should-we and what first.
   - `Straight to plan authoring` — go directly to `implementation-plan`.
   This is a question rather than a default because `build-proposal` triages a
   Tier 0 idea by answering it directly and producing no document, which would
   leave the chain holding nothing to plan from.
3. **Proposal path.** Invoke
   `Skill(skill: "plan-agent:build-proposal", args: "<objective>")`. Do **not**
   forward `--dir` — that skill resolves its own proposals directory. When it
   converges, invoke `Skill(skill: "plan-agent:implementation-plan", args:
   "author an execution plan from the proposal at <proposal path> --dir <path>")`
   — **`--dir` is forwarded here**, unlike to `build-proposal`: it names where
   the *plan* goes, so omitting it would write the spec to the default directory
   and then fail to resolve it on return. Lead with
   objective text naming the proposal path, never a bare `.md` first token,
   which would drop `implementation-plan` into conversion mode and produce a
   plan whose steps restate proposal headings instead of naming real actions.
   **No proposal written → fall through to the direct path.** `build-proposal`
   triages a Tier 0 idea by answering it directly and producing no document, so
   there is nothing to plan from. Say so in one line and continue at step 4 with
   the original objective; never call `implementation-plan` with an empty or
   guessed proposal path.
4. **Direct path.** Invoke
   `Skill(skill: "plan-agent:implementation-plan", args: "<objective>")`,
   forwarding `--dir <path>` when it was given.
5. **Return path.** Re-resolve the produced spec **by path** — the one
   `implementation-plan` reports — never by re-running discovery, which would
   ask the user about the plan they just watched being authored. Then:
   - `Implement now` → **stop and report.** `Skill()` is synchronous, so by the
     time control reaches here Step 8 has already invoked this skill with the
     spec path and that nested run has reached its own terminal state — through
     the gates, or via `Mark in-progress and stop` at its Step 4.4. Report that
     outcome and the plan's path. Do **not** re-enter Steps 1-2: the
     completed-plan precondition would ask whether to redo work that just
     finished, and resume-from-first-unmarked would restart a run the user
     deliberately stopped. The nested build's result **is** this chain's result.
   - `Exit — I'll implement later` → **stop.** Report the produced plan's path,
     leave it at `status: todo`, and write no source files. Step 8 is the only
     point at which the user is asked how to execute, so this answer declines
     the work itself, not merely the inner skill's offer.
   - `Run as workflow` → **stop.** `implementation-plan` has already emitted the
     workflow prompt and set `status: in-progress`; report the plan's path and
     do not start an in-session build racing the workflow the user launched.
6. **Abandonment contract.** If the chain is abandoned between stages — a tool
   error, a session drop, or the user backing out after a proposal is written
   but before a plan exists — leave the proposal file in place uncommitted and
   report its path. Never clean it up.

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
