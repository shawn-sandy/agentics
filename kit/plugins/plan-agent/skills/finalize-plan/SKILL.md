---
name: finalize-plan
description: "Marks an HTML plan as completed. Inspects codebase evidence, confirms with the user, and ticks every acceptance-criteria checkbox. Use via /plan-agent:finalize-plan."
disable-model-invocation: true
argument-hint: "[plan-filename.html] [--dir <path>]"
allowed-tools: Read, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, SendUserFile
---

# finalize-plan

Mark a plan as done: inspect the codebase for implementation evidence, confirm with the user, then write all three HTML status representations to `completed` and tick every acceptance-criteria checkbox.

---

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Step 1 — Resolve the plan file

Parse `$ARGUMENTS`:

1. If `$ARGUMENTS` contains a token ending in `.html`, use that as the plan filename. Reduce to basename only (strip any leading path components). Resolve against these roots in order until the file is found:
   a. `--dir` value (if passed)
   b. `plansDirectory` via Claude Code's settings precedence — project-local `.claude/settings.local.json`, then project `.claude/settings.json`, then global `~/.claude/settings.json`
   c. `docs/plans/` under `$PWD`
2. If `$ARGUMENTS` is empty, resolve the plans directory (honor `--dir` if passed; otherwise the same precedence as root b), then find the most recently modified `.html` file (excluding `index.html`) under it:
```bash
PLANS_DIR=$(python3 - <<'EOF'
import json, os, sys
# Claude settings precedence: project-local → project → user-global
candidates = (
    os.path.join(os.getcwd(), '.claude', 'settings.local.json'),
    os.path.join(os.getcwd(), '.claude', 'settings.json'),
    os.path.join(os.path.expanduser('~'), '.claude', 'settings.json'),
)
for path in candidates:
    try:
        v = json.load(open(path)).get('plansDirectory', '').strip()
        if v:
            print(v); sys.exit(0)
    except Exception:
        pass
print(os.path.join(os.getcwd(), 'docs', 'plans'))
EOF
)
find "$PLANS_DIR" -maxdepth 1 -name "*.html" ! -name "index.html" -print0 \
  | xargs -0 ls -t 2>/dev/null | head -1
```
3. If no file is found, tell the user: `"No HTML plan found. Pass a filename: /plan-agent:finalize-plan my-plan.html"` and **STOP**.

Announce: `"Reviewing plan for completion: <resolved-path>"`

---

## Step 2 — Read the plan and extract signals

Read the HTML file. Extract:

**Acceptance criteria:** Collect the text of every `<input type="checkbox">` item inside the `#criteria-list` element only. Do not include checkboxes from other sections (e.g., the `#completion-list` completion checklist). Note how many are currently checked (have the `checked` attribute) vs unchecked.

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
3. First check if the criterion's tokens were already found in Step 3a's evidence. For any tokens not covered by 3a (e.g. tokens that appear only in criteria text, not in `<code>` elements), run `Glob` and `Grep` directly against the codebase to avoid false negatives. A criterion is **verified** if all its key tokens were found, or if the criterion describes a verifiable state. For state-based criteria, run the relevant command rather than just checking for file existence (e.g. "No TypeScript errors" → run `tsc --noEmit`; "Tests pass" → run the project's test command and confirm it exits 0; "No lint errors" → run the linter). If the command fails, the criterion is `unverified`.
4. Mark each criterion as `verified` or `unverified`.

### 3c — Objective-verification test (end-to-end signal)

Locate the `.objective-test-card` in the plan's Tests section and extract its **Run** field — the test-runner command authored at plan time. This test asserts the plan's *stated objective* actually works in the running application, so it is the strongest end-to-end completion signal, complementing the per-token and per-criterion evidence above.

- If a **Run** command is present, execute it and capture the exit status:
  - Exit 0 → objective test = `pass`
  - Non-zero → objective test = `fail`
- If no `.objective-test-card` or no **Run** command is found → objective test = `n/a`.

Do not auto-fix here — `finalize-plan` only inspects and confirms. Carry the result into Step 4 so the user sees it before deciding whether to mark the plan completed.

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
| Objective test  | pass (npm test -- objective)       |
```

List which tokens were found (with file/grep match) and which were missing.

**Objective test (end-to-end):** Show the result from Step 3c — `pass`, `fail`, or `n/a`. If it failed, include a warning before the completion prompt:
> "The objective-verification test failed (`<run command>`). The plan's stated goal may not actually work end-to-end. Proceeding will mark it completed anyway."

**Per-criterion breakdown:** For each acceptance criterion, show its verification status:
- `[verified]` — evidence found or condition confirmed
- `[unverified]` — no supporting evidence found

If evidence score is below 80%, include a warning:
> "Implementation evidence is below 80% — the plan may not be fully done. Proceeding will mark it completed anyway."

If any criteria are unverified, include a second warning listing them:
> "The following acceptance criteria could not be verified:
> 1. <criterion text>
> 2. <criterion text>
> Proceeding will check them off anyway unless you choose to only auto-check verified criteria."

Ask via `AskUserQuestion`:
> "Mark this plan as completed?"
- Options: `Yes, check all criteria and mark completed` / `Yes, but only auto-check verified criteria` / `No, cancel`

If the user cancels, **STOP**.
If the user chooses to only auto-check verified criteria, record that choice for Step 5b.

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

**If the user chose `Yes, but only auto-check verified criteria`:**
Only add the `checked` attribute to criteria that were marked `verified` in Step 3b. Do not modify unverified criteria — leave their current checked state unchanged (already-checked items stay checked; unchecked items stay unchecked). If any criteria remain unchecked after this step, override the status set in Step 5a: edit all three representations (`<html data-status>`, `<meta name="plan-status">`, and the visible badge text/class) from `completed` to `in-progress`.

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

### 5d — Completion checklist

If the `#completion-list` section does not exist in the plan HTML, skip this sub-step.

Check off the three completion-checklist checkboxes based on the current plan state:

- `cc1` (all steps done): Always check — step cards are always marked completed by finalize-plan in 5c.
  ```
  <input type="checkbox" id="cc1" disabled>  →  <input type="checkbox" id="cc1" disabled checked>
  ```
- `cc2` (acceptance criteria): Check only if **all** acceptance-criteria checkboxes are checked after 5b. If the user chose "only auto-check verified criteria" and some remain unchecked, leave `cc2` **unchecked**.
  ```
  <input type="checkbox" id="cc2" disabled>  →  <input type="checkbox" id="cc2" disabled checked>
  ```
- `cc3` (status updated): Check only if the **final** status after all overrides (including 5b's potential downgrade to `in-progress`) is `completed`. Read the current `<meta name="plan-status" content="…">` value — if it is `completed`, check cc3; if it is `in-progress` (because 5b left criteria unchecked and downgraded the status), leave cc3 **unchecked**.
  ```
  <input type="checkbox" id="cc3" disabled>  →  <input type="checkbox" id="cc3" disabled checked>
  ```

When all three checkboxes are checked, add the `all-complete` class:
```
class="completion-checklist"  →  class="completion-checklist all-complete"
```

### 5e — Completion report

If the `#completion-report` section does not exist in the plan HTML, skip this sub-step.

Populate the Completion Report based on the findings from Steps 3a and 3b:

**If all criteria were verified and all steps marked done:** Leave the existing `<p class="report-empty">No items to report — all requirements met.</p>` text unchanged.

**If any criteria were marked `unverified` and left unchecked (user chose "auto-check verified only"):** Replace the `<p class="report-empty">…</p>` element with a `<dl class="report-list">` listing each unverified criterion:
```html
<dl class="report-list">
  <dt>[Criterion text]</dt>
  <dd>[Verification failure reason — e.g., "No matching file found in codebase", "tsc --noEmit exited with code 1", "Identifier not found in grep search"]</dd>
</dl>
```

**If the token-level evidence score was below 80%:** Add a report entry noting the evidence gap:
```html
<dt>Implementation evidence gap</dt>
<dd>3/5 tokens found — missing: AuthProvider, useAuth</dd>
```

**If the objective-verification test failed in Step 3c:** Add a report entry naming the test and its run command:
```html
<dt>Objective-verification test failed</dt>
<dd>npm test -- objective exited with code 1 — the plan's stated goal is not confirmed end-to-end</dd>
```

Each `<dt>` must name the specific criterion or token, not a generic summary.

---

## Step 6 — Deliver

Send the updated plan file to the user via `SendUserFile`.

Report one of:
- If all criteria were verified and checked: `"Plan marked completed: <filename> — all N acceptance criteria verified and checked, status updated to completed."`
- If the user chose "check all" but some criteria were unverified: `"Plan marked completed: <filename> — all criteria checked (N verified, K unverified), status updated to completed."` List the unverified criteria so the user is aware.
- If unverified criteria were left unchecked: `"Plan updated: <filename> — N/M acceptance criteria verified and checked, K criteria left unchecked, status set to in-progress."` List the unchecked criteria so the user knows what remains.

**STOP.** Do not commit, push, or start any implementation work.
