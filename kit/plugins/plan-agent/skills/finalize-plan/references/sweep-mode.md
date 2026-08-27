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

**An artifact-published plan has no HTML at all**, so the scan above cannot see it — it is a spec whose rendered view lives on claude.ai. Sweeping only what happens to be on disk would silently skip exactly the plans whose staleness is public. Add them by their spec:

```bash
artifact_candidates=$(
  for spec in "$PLANS_DIR"/*.md; do
    [ -e "$spec" ] || continue
    [ -e "${spec%.md}.html" ] && continue
    grep -q '^# Plan:' "$spec" || continue
    fm=$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} NR>1' "$spec")
    printf '%s\n' "$fm" | grep -qE '^artifact-url: *https?://[^/ ]' || continue
    printf '%s\n' "$fm" | grep -qE '^status: *(todo|in-progress) *$' \
      && printf '%s\n' "$spec"
  done || true
)
```

Three guards, each closing a different way this scan goes wrong:

- **`done || true`** — the loop's exit status is the last command it ran, so a directory whose final spec does not match would abort the whole sweep under `set -e`, silently and precisely in the common case where there is nothing to sweep. The HTML scan carries its own `|| true` for the same reason.
- **`grep -q '^# Plan:'`** — without it a non-spec `.md` carrying those two frontmatter keys becomes a candidate, and S4 resolves its edit mode through Step 1, which is instructed to **STOP** on a `.md` with no `# Plan:` heading. That halts the sweep partway, leaving earlier plans written and later ones untouched.
- **The `awk` frontmatter extract** — match `status:` and `artifact-url:` **only inside the frontmatter block**, never over the whole file. A plan that documents plan-agent's own keys in its body (a bare `status: todo` line in `## Steps`) would otherwise be swept as unfinished while its frontmatter says `completed` — not hypothetical in a repo whose plans are about plan-agent. The `awk` prints lines after the opening `---` and stops at the closing one, so it also reads far less than a whole-file grep.

The `[^/ ]` after `//` requires a **host**, matching the rule `implementation-plan` Step 7b and `publish-hub` already state: a bare `https://` is a truncated value, not a page to republish to, and passing it to `Artifact` claims a new URL instead of updating the shared one.

The sibling-`.html` test is what separates the two lists, so no plan appears in both. A spec with no `status:` key at all is not a candidate here — an unstatused spec is `plan-status` territory, not a plan whose completion went unrecorded. The `status:` match is the canonical unquoted form the renderer and every plan-agent skill write.

Concatenate the two lists into `candidates` — everything downstream (S2, S3, S4) says "each candidate" and means this combined list, not the HTML scan alone:

```bash
candidates=$(printf '%s\n%s\n' "$candidates" "$artifact_candidates" | grep -v '^$' || true)
```

If it is empty, report `"All plans in <PLANS_DIR> are already marked completed."` and **STOP**.

### S2 — Score each candidate (cheap pass)

For each candidate, run **Step 2** (read plan, extract signals) and **Step 3a**'s Glob/Grep token checks only. Do **not** run Step 3b per-criterion verification or the Step 3c objective test yet — those are expensive and run only on plans the user actually selects.

Sweep scoring is non-interactive: if a candidate yields no extractable tokens, skip Step 3a's no-token `AskUserQuestion` entirely — score the plan as `0% evidence (no signals)` and keep it in the table. All user decisions happen in S3.

### S3 — Present candidates and batch-confirm

Output one table sorted by evidence score, highest first:

```
| Plan                        | Status      | Evidence | Criteria checked |
|-----------------------------|-------------|----------|------------------|
| add-dark-mode-toggle.html   | in-progress | 5/5      | 2/5              |
| ship-search-filters.md (artifact) | in-progress | 4/5 | 3/6            |
| fix-login-redirect.html     | todo        | 3/7      | 0/4              |
```

An artifact candidate is a `.md` path — it has no HTML — so name it as the spec and mark it `(artifact)`. Both lists go in one table, sorted together by evidence.

Plans at **80%+ evidence** are the "done but not marked" candidates; call them out.

Ask via a single `AskUserQuestion` with two questions:

1. `"Which plans should be finalized?"` — `multiSelect: true`, one option per candidate labelled `<filename> (<evidence>)`. List the 80%+ candidates first.
2. `"How should acceptance criteria be checked?"` — Options: `Only auto-check verified criteria (Recommended)` / `Check all criteria`

If no plans are selected, **STOP**.

### S4 — Finalize each selected plan

For each selected plan in turn, run **Step 3b**, **Step 3c**, and **Step 5** — but *not* Step 5f — (in the plan's edit mode), applying the criteria mode chosen in S3 to every plan — do not re-prompt per plan; the S3 answers replace Step 4's per-plan confirmation. Print a one-line result per plan as you go (final status, criteria checked, objective-test result).

**Record each artifact plan's republish outcome as you go.** Step 5e publishes to the spec's `artifact-url:`; note per plan whether that call succeeded, because S5 reports the failures and nothing else captures them. A failed republish never aborts the sweep and never rolls back the spec write — the spec is correct on disk either way, and the next run republishes. **Step 5f is deliberately excluded from the loop** — run it once for the whole sweep after the loop, so the linked tickets are confirmed in a single question rather than one per plan. Running it inside the loop as well would prompt per plan and then act a second time on the same tickets.

### S5 — Deliver

Send all updated plan files in one `SendUserFile` call (for spec-mode plans, both the `.md` and the re-rendered `.html`). An artifact-published plan has no `.html` to send — send its `.md` and give the artifact URL, which is where its updated view actually lives. Report a summary table: per plan, the final status (`completed` or `in-progress` via the downgrade rule), criteria verified/checked, and objective-test result. List any plans left `in-progress` and their unchecked criteria, and name any plan whose republish failed — its spec is correct and its shared page is not.

**STOP.** Do not commit, push, or start any implementation work.
