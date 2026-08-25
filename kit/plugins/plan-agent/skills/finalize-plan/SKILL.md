---
name: finalize-plan
model: sonnet
description: "Marks a plan as completed. Verifies codebase evidence, ticks acceptance criteria, and re-renders the HTML; --all sweeps unmarked plans. Use via /plan-agent:finalize-plan."
disable-model-invocation: true
argument-hint: "[plan-file.md|.html] [--all] [--dir <path>]"
allowed-tools: Read, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, Artifact, SendUserFile
---

# finalize-plan

Mark a plan as done: inspect the codebase for implementation evidence, confirm with the user, then write the completion state. The **Markdown spec is the source of truth**: when the plan has a sibling `<stem>.md` spec, all edits go to the spec — frontmatter `status`, `- [x]` criteria flips, `[x]` step markers, a `## Completion Report` section — and the HTML is re-rendered from it with `build-plan-html.mjs`. Only legacy plans without a spec are edited as HTML directly.

## References

- `references/resolve-and-modes.md` — Step 1's argument parsing, plans-directory precedence, and spec-versus-legacy edit mode
- `references/sweep-mode.md` — the whole `--all` sweep, S1 through S5
- `references/evidence-analysis.md` — Step 2's signals, Step 3's 3a–3c evidence, Step 4's findings table
- `references/write-completions.md` — Step 5's spec and legacy writes, Step 5f's ticket update, Step 6's delivery

---

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Resolve the plan file and edit mode

Read `references/resolve-and-modes.md` and follow its Step 1: parse `$ARGUMENTS`, resolve the plan file against `--dir` / `plansDirectory` / `docs/plans/`, and determine spec or legacy edit mode.

**`--all` routes elsewhere:** if `$ARGUMENTS` contains `--all`, skip single-file resolution and follow `references/sweep-mode.md` — its S1–S5 replace Steps 2–6 as the top-level flow, invoking those steps per plan.

## Step 2 — Read the plan and extract signals

Per `references/evidence-analysis.md` Step 2: acceptance criteria, implementation tokens, current status — from the spec in spec mode, from the HTML in legacy mode, reconciling any drift.

## Step 3 — Analyze codebase for implementation evidence

Per `references/evidence-analysis.md` Step 3: token-level `Glob`/`Grep` scoring (3a), per-criterion verification (3b), and the objective-verification test run (3c).

## Step 4 — Present findings and confirm

Per `references/evidence-analysis.md` Step 4: print the findings table, the objective-test result, the per-criterion breakdown and warnings, then ask whether to mark the plan completed. Cancel means **STOP**.

## Step 5 — Write the completions

Read `references/write-completions.md` and follow its Step 5 — `### Spec mode` edits `<stem>.md` (5a0–5d) and re-renders (5e); `### Legacy mode` does the HTML attribute surgery.

**Phase gate (5a0):** a spec whose `## Steps` carries `### Phase: <name>` headings never reaches `status: completed` while any phase still holds an unmarked step. Leave it `in-progress` and name each unfinished phase in the `## Completion Report` instead. `build` stops at its first phase boundary by design, so this is the difference between a plan that finished and one that checkpointed. Unphased specs are unaffected.

## Step 5f — Update the linked tracking ticket

Per `references/write-completions.md` Step 5f: validate the ticket URL, write the summary to a file, then close or comment based on the final status. A CLI failure never blocks completion.

## Step 6 — Deliver

Per `references/write-completions.md` Step 6: `SendUserFile` the updated plan file(s) and report the matching completion line.

**STOP.** Do not commit, push, or start any implementation work.
