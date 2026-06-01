---
name: complete-plan
description: "Reviews an HTML plan for completion evidence, checks all acceptance criteria, and sets status to completed. Use via /plan-agent:complete-plan to close out a finished plan."
disable-model-invocation: true
argument-hint: "[plan-filename.html]"
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

**Implementation tokens:** Scan the HTML (excluding `<style>` and `<script>` blocks) for inline backtick-quoted tokens that look like file paths or named identifiers — same heuristic as `plan-interview:plan-status` Step 4:
- File paths: contain `/` or end in a known extension (`.ts`, `.tsx`, `.md`, `.json`, `.py`, `.js`, `.css`, `.scss`)
- Named identifiers: PascalCase, camelCase, or kebab-case names

**Current status:** Read `<meta name="plan-status" content="...">` and the `data-status` attribute on `<html>`.

---

## Step 3 — Analyze codebase for implementation evidence

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

---

## Step 4 — Present findings and confirm

Output a summary table:

```
| Field           | Value                              |
|-----------------|------------------------------------|
| File            | docs/plans/my-feature.html         |
| Current status  | in-progress                        |
| Evidence        | 4/5 tokens found in codebase       |
| Checkboxes      | 2 checked / 5 total                |
```

List which tokens were found (with file/grep match) and which were missing.

If evidence score is below 80%, include a warning:
> "Implementation evidence is below 80% — the plan may not be fully done. Proceeding will mark it completed anyway."

Ask via `AskUserQuestion`:
> "Mark this plan as completed? This will check all acceptance-criteria boxes and update the status badge."
- Options: `Yes, mark completed` / `No, cancel`

If the user cancels, **STOP**.

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

For every unchecked `<input type="checkbox">` inside the acceptance-criteria section, add the `checked` attribute:
```
<input type="checkbox">           →  <input type="checkbox" checked>
<input type="checkbox" disabled>  →  <input type="checkbox" checked disabled>
```

Do not remove or alter any surrounding markup.

### 5c — Step cards

For every `.step-card` element that does not already have the `completed` class, add it:
```
class="step-card"     →  class="step-card completed"
class="step-card ..."  →  class="step-card completed ..."
```

The step chip text (`<span class="step-chip">todo</span>`) updates visually via CSS when the `completed` class is present — do not change the chip text in the HTML.

---

## Step 6 — Deliver

Send the updated plan file to the user via `SendUserFile`.

Report:
> "Plan marked completed: `<filename>` — all acceptance criteria checked, status updated to `completed`."

**STOP.** Do not commit, push, or start any implementation work.
