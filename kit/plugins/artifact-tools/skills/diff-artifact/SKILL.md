---
name: diff-artifact
description: "Publishes an annotated diff walkthrough as a claude.ai artifact. Scrubs for secrets, then builds a self-contained page with per-hunk reviewer notes. Use when asked to publish or share a diff."
allowed-tools: Bash, Read, Write, Skill, Artifact, WebFetch, AskUserQuestion, ToolSearch, ExitPlanMode
---

# diff-artifact

Turn a branch diff, commit range, or pull request into a single annotated
walkthrough page published to claude.ai — the reviewer sees not just what
changed, but why each hunk changed and what to look at first.

## Overview

A raw `git diff` tells a reviewer what moved; it never tells them what matters.
This skill reads the diff, writes a reviewer note against each meaningful hunk,
and publishes the result as one self-contained artifact page with a sticky
file sidebar, severity labels, and adaptive light/dark theming.

Publishing sends code to an external service, so the `security-scrub` gate runs
**before** any publish and a `BLOCKED` verdict is a hard stop.

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** —
skip this step entirely when not in plan mode. When calling: use `ToolSearch`
with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

## Step 1 — Resolve the diff source

Pick the first mode that matches the user's argument:

| Mode | Trigger | Command |
|------|---------|---------|
| **Branch** (default) | no argument | `git diff <default-branch>...HEAD` |
| **Range** | `abc123..def456` | `git diff <range>` |
| **PR** | `#42` or a PR URL | `gh pr diff 42` |

Resolve the default branch rather than assuming `main`:

```bash
DEFAULT_BRANCH=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
git diff "${DEFAULT_BRANCH}...HEAD"
```

**PR-mode degradation.** PR mode needs both the `gh` CLI and a GitHub remote.
When either is missing, do not fail and do not merely report it — say so plainly
and **actually produce the branch diff**. Every degradation path must still end
with a diff on disk:

```bash
DIFF_FILE="<scratchpad>/diff.patch"

use_pr=0
if [ -n "${PR:-}" ]; then
  if gh auth status >/dev/null 2>&1 &&
     git remote get-url origin 2>/dev/null | grep -qi 'github\.com'; then
    use_pr=1
  else
    echo "PR mode unavailable (gh missing/unauthenticated, or origin is not GitHub) — using branch mode"
  fi
fi

if [ "$use_pr" = 1 ]; then
  gh pr diff "$PR" > "$DIFF_FILE" || { echo "gh pr diff failed — using branch mode"; use_pr=0; }
fi
[ "$use_pr" = 1 ] || git diff "${DEFAULT_BRANCH}...HEAD" > "$DIFF_FILE"
```

If `$DIFF_FILE` is empty, tell the user there is nothing to publish and stop.

## Step 2 — Scrub before anything else (blocking gate)

Write the diff to a scratch file and run the scrub over it via the `Skill` tool
(`social-media-tools:security-scrub`). This gate is **blocking, not advisory** —
publishing is external sharing.

- `GATE RESULT: BLOCKED` → **hard stop.** Do not publish, do not write the page,
  do not offer an override. Report the masked findings and stop.
- `GATE RESULT: CANCELLED` → the user declined. Stop.
- `GATE RESULT: APPROVED` → continue to Step 3.

If `security-scrub` is unavailable (social-media-tools not installed), do not
silently skip the gate — tell the user the scan could not run and ask via
`AskUserQuestion` whether to continue with an unscanned diff.

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

## Step 4 — Build the page

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

## Step 5 — Gate the rendered page (size, then scrub)

Both checks run on the **rendered HTML**, not on the inputs.

**Size.** The file/hunk budget bounds how many hunks render, but a single
generated file can carry one enormous hunk, so the budget alone does not enforce
the cap. Measure the page and shrink it until it fits:

```bash
CAP=$((16 * 1024 * 1024))   # 16 MiB rendered-artifact limit
while [ "$(wc -c < "$SCRATCH_HTML")" -ge "$CAP" ]; do
  # Demote the largest annotated file to a one-line summary row, re-render, re-measure.
  echo "Page over 16 MiB — demoting the largest annotated file to a summary row"
done
```

Count every demotion here on top of the Step 3 budget, and report the total.

**Scrub.** Rescan the finished page with `social-media-tools:security-scrub`.
Step 2 covered the diff; this covers everything the page actually publishes —
annotations, quoted file context, titles. Same verdicts, same blocking behaviour:
`BLOCKED` is a hard stop with no override, `CANCELLED` stops, only `APPROVED`
proceeds.

## Step 6 — Save the durable copy

Write the page to the `.claude/artifacts/` inbox **before publishing** — the
scratchpad is temporary, so a page that only ever lived there is not a fallback.
The URL is recorded later, only if a publish actually succeeds.

Key the filename by what the diff *is*, never by date. A date in the key means
tomorrow's run of the same branch misses today's `artifact-url:` and silently
mints a second page:

```bash
mkdir -p .claude/artifacts
# Deterministic key: pr-42 | range-abc123-def456 | branch-<slug>
case "$MODE" in
  pr)     key="pr-${PR}" ;;
  range)  key="range-$(echo "$RANGE" | tr '.' '-')" ;;
  *)      key="branch-$(git rev-parse --abbrev-ref HEAD | tr '/' '-')" ;;
esac
target=".claude/artifacts/diff-${key}.html"
cp "$SCRATCH_HTML" "$target"
```

## Step 7 — Publish, then record the URL

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.

Before publishing, read `$target`'s first line: if it carries an
`<!-- artifact-url: ... -->` comment from an earlier run, pass that URL to
`Artifact`'s `url` parameter so the same page updates. Without it every session
mints a new URL and the link you already shared goes stale.

Publish `$target` with a one-sentence `description` and the favicon `🔍`, kept
identical across republishes — users find the tab by its icon.

**On success**, record the URL into the durable copy so later sessions find it:

```bash
tmp=$(mktemp)
{ echo "<!-- artifact-url: $URL -->"; grep -v '^<!-- artifact-url:' "$target"; } > "$tmp"
mv "$tmp" "$target"
```

Report the claude.ai URL, the local path, and how many files were summarized or
demoted — a truncated review must never read as a complete one.

**On publish failure** (no claude.ai login, or publishing unavailable): this is
not an edge case — sharing beyond the author needs Team/Enterprise, so on Pro
and Max the fallback *is* how the page reaches teammates. `$target` already
holds the page, with no `artifact-url:` line since nothing was published. Say
plainly that publishing did not happen and why, give the path, and offer
`social-media-tools:save-artifact` to publish it into the repo's GitHub Pages
artifacts gallery instead. Never report a URL that a publish did not return.

## Step 8 — Verify the page rendered

Runs only after a successful publish. `WebFetch` is a deferred tool: use
`ToolSearch` with `select:WebFetch` first.

Fetch the returned URL and confirm the fetched page contains the first changed
filename from the diff. A returned URL is not evidence the page rendered — a
blank artifact returns a URL too.

If that filename is absent, report the failure **with the URL** so the user can
open it, and do not report the publish as successful.
