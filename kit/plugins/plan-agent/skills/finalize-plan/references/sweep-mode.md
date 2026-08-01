# Sweep mode

Loaded when `$ARGUMENTS` contains `--all`. Covers S1 through S5.

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

For each selected plan in turn, run **Step 3b**, **Step 3c**, and **Step 5** — but *not* Step 5f — (in the plan's edit mode), applying the criteria mode chosen in S3 to every plan — do not re-prompt per plan; the S3 answers replace Step 4's per-plan confirmation. Print a one-line result per plan as you go (final status, criteria checked, objective-test result). **Step 5f is deliberately excluded from the loop** — run it once for the whole sweep after the loop, so the linked tickets are confirmed in a single question rather than one per plan. Running it inside the loop as well would prompt per plan and then act a second time on the same tickets.

### S5 — Deliver

Send all updated plan files in one `SendUserFile` call (for spec-mode plans, both the `.md` and the re-rendered `.html`). Report a summary table: per plan, the final status (`completed` or `in-progress` via the downgrade rule), criteria verified/checked, and objective-test result. List any plans left `in-progress` and their unchecked criteria.

**STOP.** Do not commit, push, or start any implementation work.
