---
name: finalize-plan
model: sonnet
description: "Marks a plan as completed. Inspects codebase evidence, confirms with the user, ticks acceptance criteria in the Markdown spec, and re-renders the HTML; --all sweeps done-but-unmarked plans. Use via /plan-agent:finalize-plan."
disable-model-invocation: true
argument-hint: "[plan-file.md|.html] [--all] [--dir <path>]"
allowed-tools: Read, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, SendUserFile
---

# finalize-plan

Mark a plan as done: inspect the codebase for implementation evidence, confirm with the user, then write the completion state. The **Markdown spec is the source of truth**: when the plan has a sibling `<stem>.md` spec, all edits go to the spec — frontmatter `status`, `- [x]` criteria flips, `[x]` step markers, a `## Completion Report` section — and the HTML is re-rendered from it with `build-plan-html.mjs`. Only legacy plans without a spec are edited as HTML directly.

---

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Step 1 — Resolve the plan file and edit mode

Parse `$ARGUMENTS`:

0. If `$ARGUMENTS` contains `--all`, skip single-file resolution entirely and follow **Sweep mode (`--all`)** below. Sweep mode replaces the single-plan sequence of Steps 2–6 as the top-level flow, invoking those steps per candidate/selected plan as its S2 and S4 sub-steps direct.
1. If `$ARGUMENTS` contains a token ending in `.html` or `.md`, use that as the plan filename. Reduce to basename only (strip any leading path components). Resolve against these roots in order until the file is found:
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
3. If no file is found, tell the user: `"No plan found. Pass a filename: /plan-agent:finalize-plan my-plan.md"` and **STOP**.

**Determine the edit mode** from the resolved stem (`<plans-dir>/<name>` without extension):

- **Spec mode** — `<stem>.md` exists and its first markdown heading (after any YAML frontmatter block) is `# Plan:`. The spec is what you edit; `<stem>.html` is regenerated from it in Step 5.
- **Legacy mode** — no such spec (or the `.md` beside the plan is not a spec). Edit `<stem>.html` attributes directly, as before the markdown-first pipeline.

If the user passed a `.md` file that is not a plan spec (no `# Plan:` heading), say so and **STOP** — old-style markdown plans are `plan-interview:plan-status` territory, not finalize-plan's.

Announce: `"Reviewing plan for completion: <resolved-path> (<spec|legacy> mode)"`

---

## Sweep mode (`--all`)

Find plans that are implemented but never marked completed, and finalize them in one batch. Reuses the single-plan steps below — only discovery, confirmation, and delivery differ.

### S1 — Discover candidates

Resolve `PLANS_DIR` exactly as in Step 1 (honor `--dir`, then the settings precedence, then `docs/plans/`). Then list every plan not yet marked completed:

```bash
candidates=$(
  grep -lE 'name="plan-status" content="(todo|in-progress)"' "$PLANS_DIR"/*.html 2>/dev/null \
    | grep -v '/index\.html$' || true
)
```

`grep -l` returns only files carrying a real `plan-status` meta tag whose value is `todo` or `in-progress`. Non-plan HTML artifacts in the same directory (review reports, galleries — anything without the tag) are never candidates. Never descend into `archive/`. The `|| true` keeps the no-match case non-fatal — `grep` exits non-zero when nothing matches, and that must not abort the sweep. Discovery reads the rendered HTML for every plan (spec-backed or legacy) because the meta tag is always present; the per-plan edit mode is determined in S4 exactly as in Step 1.

If `$candidates` is empty, report `"All plans in <PLANS_DIR> are already marked completed."` and **STOP**.

### S2 — Score each candidate (cheap pass)

For each candidate, run **Step 2** (read plan, extract signals) and **Step 3a**'s Glob/Grep token checks only. Do **not** run Step 3b per-criterion verification or the Step 3c objective test yet — those are expensive and run only on plans the user actually selects.

Sweep scoring is non-interactive: if a candidate yields no extractable tokens, skip Step 3a's no-token `AskUserQuestion` entirely — score the plan as `0% evidence (no signals)` and keep it in the table. All user decisions happen in S3.

### S3 — Present candidates and batch-confirm

Output one table sorted by evidence score, highest first:

```
| Plan                        | Status      | Evidence | Criteria checked |
|-----------------------------|-------------|----------|------------------|
| add-dark-mode-toggle.html   | in-progress | 5/5      | 2/5              |
| fix-login-redirect.html     | todo        | 3/7      | 0/4              |
```

Plans at **80%+ evidence** are the "done but not marked" candidates; call them out.

Ask via a single `AskUserQuestion` with two questions:

1. `"Which plans should be finalized?"` — `multiSelect: true`, one option per candidate labelled `<filename> (<evidence>)`. List the 80%+ candidates first.
2. `"How should acceptance criteria be checked?"` — Options: `Only auto-check verified criteria (Recommended)` / `Check all criteria`

If no plans are selected, **STOP**.

### S4 — Finalize each selected plan

For each selected plan in turn, run **Step 3b**, **Step 3c**, and **Step 5** (all sub-steps, in the plan's edit mode), applying the criteria mode chosen in S3 to every plan — do not re-prompt per plan; the S3 answers replace Step 4's per-plan confirmation. Print a one-line result per plan as you go (final status, criteria checked, objective-test result).

### S5 — Deliver

Send all updated plan files in one `SendUserFile` call (for spec-mode plans, both the `.md` and the re-rendered `.html`). Report a summary table: per plan, the final status (`completed` or `in-progress` via the downgrade rule), criteria verified/checked, and objective-test result. List any plans left `in-progress` and their unchecked criteria.

**STOP.** Do not commit, push, or start any implementation work.

---

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
- If no objective test or no **Run** command is found → objective test = `n/a`.

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

---

## Step 5 — Write the completions

### Spec mode (the normal path)

Edit `<stem>.md` only — never the HTML. The renderer derives everything the old HTML surgery wrote by hand: the three status representations (`<html data-status>`, the `plan-status` meta tag, the visible badge), criteria `checked` attributes, `.step-card completed` classes and `done` chips, the completion checklist (cc1–cc3 plus `all-complete`), and the Completion Report markup.

**5a — Status frontmatter.** Set `status: completed` in the YAML frontmatter (add the key, or the whole frontmatter block, if absent).

**5b — Acceptance criteria.** Flip bullets under `## Acceptance Criteria` to `- [x] <text>`:
- User chose **check all**: flip every bullet.
- User chose **only auto-check verified**: flip only criteria marked `verified` in Step 3b (plus any flagged by Step 2's drift reconciliation). Leave the rest as `- [ ] <text>` (normalize plain `- ` bullets to `- [ ]` so the remaining work is visible). **Downgrade rule:** if any criterion remains unchecked, set `status: in-progress` in 5a instead of `completed`.

**5c — Steps.** Mark every step done by inserting the marker after the number: `1. <action>…` → `1. [x] <action>…` (skip steps that already carry `[x]`).

**5d — Completion report.** If every criterion was verified and checked and the objective test did not fail, remove any existing `## Completion Report` section and add nothing. Otherwise write (or replace) the section — one `- <item> — <reason>` bullet per finding, the em dash separating item from reason:

```markdown
## Completion Report

- <unverified criterion text> — No matching file found in codebase
- Implementation evidence gap — 3/5 tokens found; missing: AuthProvider, useAuth
- Objective-verification test failed — npm test -- objective exited with code 1
```

Each item names the specific criterion, token gap, or test — never a generic summary. Place the section after `## Acceptance Criteria`.

**5e — Re-render.** Regenerate the HTML from the spec and confirm it succeeded:

```bash
RENDERER="${CLAUDE_PLUGIN_ROOT}/scripts/build-plan-html.mjs"
[ -f "$RENDERER" ] || RENDERER="scripts/build-plan-html.mjs"
node "$RENDERER" "<stem>.md" -o "<stem>.html"
```

Exit 1 means the spec edit broke the format — fix the reported problem in the markdown and re-run. Never hand-edit the HTML to compensate. (The plugin's `render-plan-html.py` hook also re-renders on every spec write, but run the script explicitly so a failure surfaces here, not silently.)

### Legacy mode (no spec — HTML attribute surgery)

Use `Edit` on the plan HTML file. Read the file once before any edit.

**5a — Status representations (all three must update together):** the `<html>` attribute (`data-status="todo|in-progress"` → `data-status="completed"`), the `<meta name="plan-status">` tag (same value change), and the visible badge (typically `.status-badge`, `.plan-status-badge`, or `data-plan-status` — replace its text with `completed` and any `status-todo`/`status-in-progress` class with `status-completed`).

**5b — Acceptance-criteria checkboxes:** add the `checked` attribute to `#criteria-list` inputs per the user's Step 4 choice — every unchecked input for "check all", or only `verified` criteria for "auto-check verified" (leave the others' state unchanged). If any criteria remain unchecked, apply the downgrade rule: set all three status representations to `in-progress`.

**5c — Step cards:** add the `completed` class to every `.step-card` that lacks it, and flip each such card's chip text: `<span class="step-chip">todo</span>` → `<span class="step-chip">done</span>`.

**5d — Completion checklist:** if `#completion-list` exists, add `checked` to `cc1` (steps are always completed by 5c); to `cc2` only if **all** criteria are checked after 5b; to `cc3` only if the **final** status after the downgrade rule is `completed`. When all three are checked, add the `all-complete` class to the `completion-checklist` div.

**5e — Completion report:** if `#completion-report` exists and anything fell short (unverified criteria left unchecked, evidence below 80%, objective test failed), replace the `<p class="report-empty">…</p>` element with a `<dl class="report-list">` of `<dt>` (specific criterion/token/test) + `<dd>` (reason) entries; otherwise leave the report untouched.

Do not remove or alter any surrounding markup.

---

## Step 6 — Deliver

Send the updated plan file(s) to the user via `SendUserFile` — in spec mode both the `.md` spec and the re-rendered `.html`.

Report one of:
- If all criteria were verified and checked: `"Plan marked completed: <filename> — all N acceptance criteria verified and checked, status updated to completed."`
- If the user chose "check all" but some criteria were unverified: `"Plan marked completed: <filename> — all criteria checked (N verified, K unverified), status updated to completed."` List the unverified criteria so the user is aware.
- If unverified criteria were left unchecked: `"Plan updated: <filename> — N/M acceptance criteria verified and checked, K criteria left unchecked, status set to in-progress."` List the unchecked criteria so the user knows what remains.

**STOP.** Do not commit, push, or start any implementation work.
