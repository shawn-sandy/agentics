---
name: complete-plan
description: "Marks an HTML plan completed: checks codebase evidence, ticks all acceptance criteria, and updates all status elements. Use via /plan-agent:complete-plan."
disable-model-invocation: true
argument-hint: "[plan-filename.html] [--dir <path>]"
allowed-tools: Read, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, SendUserFile
---

# complete-plan

Mark a plan as done: inspect the codebase for implementation evidence, confirm with the user, then write all three HTML status representations to `completed` and tick every acceptance-criteria checkbox.

---

## Exit plan mode

`ExitPlanMode` is a deferred tool — load it before calling.  
Use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

**Error handling:** If `ExitPlanMode` returns `"You are not in plan mode"`, treat that as success and continue immediately.

---

## Step 1 — Resolve the plan file

Parse `$ARGUMENTS`:

1. If `$ARGUMENTS` contains a token ending in `.html`, use that as the plan filename. Reduce to basename only (strip any leading path components). Resolve against these roots in order until the file is found:
   a. `--dir` value (if passed)
   b. `plansDirectory` from `.claude/settings.json` (project then global `~/.claude/settings.json`)
   c. `docs/plans/` under `$PWD`
2. If `$ARGUMENTS` is empty, find the most recently modified `.html` file (excluding `index.html`) under the resolved plans directory:
   ```bash
   find "$PLANS_DIR" -maxdepth 1 -name "*.html" ! -name "index.html" -print0 \
     | xargs -0 ls -t 2>/dev/null | head -1
   ```
3. If no file is found, tell the user: `"No HTML plan found. Pass a filename: /plan-agent:complete-plan my-plan.html"` and **STOP**.

Announce: `"Reviewing plan for completion: <resolved-path>"`

---

## Step 2 — Read the plan and extract signals

Read the HTML file. Extract:

**Acceptance criteria:** Collect the text of every `<input type="checkbox">` item. Note how many are currently checked (have the `checked` attribute) vs unchecked.

**Implementation tokens:** Scan the HTML (excluding `<style>` and `<script>` blocks) for text inside `<code>` elements that looks like file paths or named identifiers — same heuristic as `plan-interview:plan-status` Step 4:
- File paths: contain `/` or end in a known extension (`.ts`, `.tsx`, `.md`, `.json`, `.py`, `.js`, `.css`, `.scss`)
- Named identifiers: PascalCase, camelCase, or kebab-case names

**Current status:** Read `<meta name="plan-status" content="...">` and the `data-status` attribute on `<html>`.

---

## Step 3 — Analyze codebase for implementation evidence

### 3a — Token-level evidence

For each extracted token, run two checks in parallel:
1. `Glob` — does it match a file path under `$PWD`?
2. `Grep` — does it appear as an identifier in the codebase?

If no tokens were found, skip analysis and ask the user via `AskUserQuestion`:
> "No extractable implementation signals found in this plan. Do you still want to mark it as completed?"
- Options: `Yes, mark completed` / `No, cancel`
- If the user cancels, **STOP**.

Score:
- 0% found → status evidence = `todo` (warn the user)
- 1–79% found → status evidence = `in-progress`
- 80%+ found → status evidence = `completed`

### 3b — Per-criterion verification

For each acceptance-criteria checkbox item, determine whether the criterion is satisfied:
1. Extract the text of each criterion.
2. Identify implementation tokens (file paths, identifiers, CLI flags) mentioned in or implied by that criterion.
3. Cross-reference the tokens against the evidence collected in Step 3a — a criterion is **verified** if all its key tokens were found, or if the criterion describes a verifiable state. For state-based criteria, run the relevant command rather than just checking for file existence (e.g. "No TypeScript errors" → run `tsc --noEmit`; "Tests pass" → run the project's test command and confirm it exits 0; "No lint errors" → run the linter). If the command fails, the criterion is `unverified`.
4. Mark each criterion as `verified` or `unverified`.

---

## Step 4 — Present findings and confirm

Output a summary table:

```
| Field           | Value                              |
|-----------------|------------------------------------|
| File            | docs/plans/my-feature.html         |
| Current status  | in-progress                        |
| Evidence        | 4/5 tokens found in codebase       |
| Criteria        | 3 verified / 5 total               |
| Checkboxes      | 2 already checked / 5 total        |
```

List which tokens were found (with file/grep match) and which were missing.

**Per-criterion breakdown:** For each acceptance criterion, show its verification status:
- `[verified]` — evidence found or condition confirmed
- `[unverified]` — no supporting evidence found

If evidence score is below 80%, include a warning:
> "Implementation evidence is below 80% — the plan may not be fully done. Proceeding will mark it completed anyway."

If any criteria are unverified, include a second warning listing them:
> "The following acceptance criteria could not be verified:
> 1. <criterion text>
> 2. <criterion text>
> Proceeding will check them off anyway unless you choose to leave them unchecked."

Ask via `AskUserQuestion`:
> "Mark this plan as completed?"
- Options: `Yes, check all criteria and mark completed` / `Yes, but leave unverified criteria unchecked` / `No, cancel`

If the user cancels, **STOP**.
If the user chooses to leave unverified criteria unchecked, record that choice for Step 5b.

---

## Step 5 — Write the completions

Use `Edit` to apply all of the following changes to the plan HTML file in sequence. Read the file once before any edit to confirm current content.

### 5a — Status representations (all three must update together)

**`<html>` attribute:**
```
data-status="todo"        →  data-status="completed"
data-status="in-progress" →  data-status="completed"
```

**`<meta>` tag:**
```
<meta name="plan-status" content="todo">        →  <meta name="plan-status" content="completed">
<meta name="plan-status" content="in-progress"> →  <meta name="plan-status" content="completed">
```

**Visible badge** — find the element that displays the status badge text (typically `.status-badge`, `.plan-status-badge`, or `data-plan-status`). Replace its text with `completed`. If the element carries a class like `status-todo` or `status-in-progress`, replace it with `status-completed`.

### 5b — Acceptance-criteria checkboxes

Check off acceptance criteria based on the user's choice in Step 4:

**If the user chose `Yes, check all criteria and mark completed`:**
For every unchecked `<input type="checkbox">` inside the acceptance-criteria section, add the `checked` attribute:
```
<input type="checkbox">           →  <input type="checkbox" checked>
<input type="checkbox" disabled>  →  <input type="checkbox" checked disabled>
```

**If the user chose `Yes, but leave unverified criteria unchecked`:**
Only check off criteria that were marked `verified` in Step 3b. Leave `unverified` criteria unchecked — if an unverified criterion is already checked (from a prior manual check), leave it as-is (do not uncheck it). If any criteria remain unchecked after this step, override the status set in Step 5a: edit all three representations (`<html data-status>`, `<meta name="plan-status">`, and the visible badge text/class) from `completed` to `in-progress`.

Do not remove or alter any surrounding markup.

### 5c — Step cards

For every `.step-card` element that does not already have the `completed` class, add it:
```
class="step-card"     →  class="step-card completed"
class="step-card ..."  →  class="step-card completed ..."
```

Also update the step chip text from `todo` to `done` for each step card you mark completed:
```
<span class="step-chip">todo</span>  →  <span class="step-chip">done</span>
```

---

## Step 6 — Deliver

Send the updated plan file to the user via `SendUserFile`.

Report one of:
- If all criteria were verified and checked: `"Plan marked completed: <filename> — all N acceptance criteria verified and checked, status updated to completed."`
- If the user chose "check all" but some criteria were unverified: `"Plan marked completed: <filename> — all criteria checked (N verified, K unverified), status updated to completed."` List the unverified criteria so the user is aware.
- If unverified criteria were left unchecked: `"Plan updated: <filename> — N/M acceptance criteria verified and checked, K criteria left unchecked, status set to in-progress."` List the unchecked criteria so the user knows what remains.

**STOP.** Do not commit, push, or start any implementation work.
