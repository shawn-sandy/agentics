# Annotating the hunks and building the page

Loaded by `diff-artifact` Steps 3, 4, and the size half of Step 5.

## Step 3 — Annotate the hunks

Read the changed files for context where the diff alone is ambiguous, then write
one note per meaningful hunk. Each note gets a severity:

> **Scrub coverage.** Step 2 scanned the *diff*. Reading surrounding file context
> here can pull in text the diff never contained, so anything quoted from a file
> is outside that scan. Quote sparingly, and note that Step 5 rescans the
> rendered page — that second gate, not this one, is what covers annotations.

| Severity | Meaning |
|----------|---------|
| `critical` | Reviewer must look here — correctness, security, data loss |
| `warn` | Worth a second opinion — edge cases, unclear intent |
| `note` | Context only — renames, formatting, mechanical churn |

Explain the *reasoning*, not the syntax. "Guards against the empty-array case
that crashed the importer" is a note; "adds an if statement" is noise.

**Cap-and-summarize.** Artifacts are capped at 16 MiB rendered. Annotate at most
**20 files** and **8 hunks per file**. Every file beyond that budget renders as a
one-line summary row in the sidebar and body (`path — +12/−3, not annotated`)
rather than a full diff. Tell the user in the final report how many files were
summarized rather than annotated, so a truncated review is never mistaken for a
complete one.

## Step 4 — Page requirements

Load the `artifact-design` skill first to calibrate design investment, then
`Write` one self-contained `.html` file to the scratchpad. Requirements:

- **Self-contained** — a strict CSP blocks every external request. Inline all
  CSS; no CDN links, no web fonts, no remote images, no fetch.
- **Single page** — in-page anchors only (`#file-3`); relative links break.
- **Sticky file sidebar** — every changed file with add/del counts, anchored to
  its section. Summarized-only files appear here too, visibly marked.
- **Severity legend** — pair every color with a text label. Color alone fails
  colorblind readers; the label is what carries the meaning.
- **Adaptive theme** — `@media (prefers-color-scheme: dark)` for both palettes.
- **Escape diff content** — `&`, `<`, `>` in code become entities. An unescaped
  diff of HTML silently destroys the page.
- **Title** — read `${CLAUDE_PLUGIN_ROOT}/references/titles.md` and set the
  `<title>` by its rules. The diff is in context here; the subject is the theme
  the changed files share, never the user's phrasing of the request.
- Write the page content only (no `<!doctype>`/`<html>`/`<head>`/`<body>` — those
  are added at publish time).

## Step 5 — Size half of the rendered-page gate

The file/hunk budget bounds how many hunks render, but a single generated file can
carry one enormous hunk, so the budget alone does not enforce the cap. Measure the
page and shrink it until it fits:

```bash
CAP=$((16 * 1024 * 1024))   # 16 MiB rendered-artifact limit
while [ "$(wc -c < "$SCRATCH_HTML")" -ge "$CAP" ]; do
  # Demote the largest annotated file to a one-line summary row, re-render, re-measure.
  echo "Page over 16 MiB — demoting the largest annotated file to a summary row"
done
```

Count every demotion here on top of the Step 3 budget, and report the total.
