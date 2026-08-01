# Reading the plan, gathering evidence, and confirming

Loaded at Step 2. Covers Steps 2, 3 (3a-3c), and 4.

## Step 2 — Read the plan and extract signals

**Spec mode:** Read `<stem>.md`. Extract:

- **Acceptance criteria:** every bullet under `## Acceptance Criteria`. A criterion is already checked iff its bullet is `- [x]`; `- [ ]` and plain `- ` bullets are unchecked. Note the checked/unchecked counts.
- **Implementation tokens:** file paths and named identifiers in backtick code spans and the `## Files` entries — file paths contain `/` or end in a known extension (`.ts`, `.tsx`, `.md`, `.json`, `.py`, `.js`, `.mjs`, `.css`, `.scss`); named identifiers are PascalCase, camelCase, or kebab-case names.
- **Current status:** the `status:` frontmatter key (missing = `todo`).
- **Reconcile drift:** also read `<stem>.html` — if any `#criteria-list` checkbox carries `checked` but its spec bullet is unchecked (progress written to the HTML before the md-first flows), treat that criterion as already checked and flip its spec bullet to `- [x]` as part of Step 5, whatever the criteria mode.

**Legacy mode:** Read the HTML file. Extract:

- **Acceptance criteria:** the text of every `<input type="checkbox">` item inside the `#criteria-list` element only (never the `#completion-list` checklist), noting which carry the `checked` attribute.
- **Implementation tokens:** text inside `<code>` elements (excluding `<style>`/`<script>` blocks), same path/identifier heuristic as above.
- **Current status:** `<meta name="plan-status" content="...">` and the `data-status` attribute on `<html>`.

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

For each acceptance criterion, determine whether it is satisfied:
1. Extract the text of each criterion.
2. Identify implementation tokens (file paths, identifiers, CLI flags) mentioned in or implied by that criterion.
3. First check if the criterion's tokens were already found in Step 3a's evidence. For any tokens not covered by 3a, run `Glob` and `Grep` directly against the codebase to avoid false negatives. A criterion is **verified** if all its key tokens were found, or if the criterion describes a verifiable state. For state-based criteria, run the relevant command rather than just checking for file existence (e.g. "No TypeScript errors" → run `tsc --noEmit`; "Tests pass" → run the project's test command and confirm it exits 0; "No lint errors" → run the linter). If the command fails, the criterion is `unverified`.
4. Mark each criterion as `verified` or `unverified`.

### 3c — Objective-verification test (end-to-end signal)

Locate the objective-verification test and extract its **Run** field — the test-runner command authored at plan time. In spec mode it is the first bullet of the `## Tests` section; in legacy mode it is the `.objective-test-card` in the plan's Tests section. This test asserts the plan's *stated objective* actually works in the running application, so it is the strongest end-to-end completion signal, complementing the per-token and per-criterion evidence above.

- If a **Run** command is present, execute it and capture the exit status:
  - Exit 0 → objective test = `pass`
  - Non-zero → objective test = `fail`
- If no objective test or no **Run** command is found (older plans predate the
  always-runnable rule), derive one from the plan's Objective and Verification
  sections — a test-runner invocation for code plans, a plain shell command
  (`grep -q '<expected>' <file>`, `test -f <path>`) for docs/metadata plans —
  and run it. Report it as derived so the user can see what was checked. Only
  when no objective can be reduced to a command → objective test = `n/a`.

Do not auto-fix here — `finalize-plan` only inspects and confirms. Carry the result into Step 4 so the user sees it before deciding whether to mark the plan completed.

---

## Step 4 — Present findings and confirm

Output a summary table:

```
| Field           | Value                              |
|-----------------|------------------------------------|
| File            | docs/plans/my-feature.md           |
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
If the user chooses to only auto-check verified criteria, record that choice for Step 5.
