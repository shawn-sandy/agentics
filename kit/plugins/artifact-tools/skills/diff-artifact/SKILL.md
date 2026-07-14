---
name: diff-artifact
description: "Publishes an annotated diff walkthrough as a claude.ai artifact. Scrubs for secrets, then builds a self-contained page with per-hunk reviewer notes. Use when asked to publish or share a diff."
allowed-tools: Bash, Read, Write, Skill, Artifact, AskUserQuestion, ToolSearch, ExitPlanMode
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
If `gh` is missing, unauthenticated, or the remote is not GitHub, do not fail —
say so plainly and fall back to branch mode:

```bash
if ! gh auth status >/dev/null 2>&1; then
  echo "gh unavailable or not authenticated — falling back to branch mode"
fi
```

If the diff is empty, tell the user there is nothing to publish and stop.

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
- Set a `<title>`; write the page content only (no `<!doctype>`/`<html>`/`<head>`
  /`<body>` — those are added at publish time).

## Step 5 — Publish

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.

Publish with the scratch file path, a one-sentence `description`, and a stable
`favicon` (use `🔍`). Keep the favicon identical across republishes of the same
diff — users find the tab by its icon.

## Step 6 — Record the URL, or fall back

**On success:** save the page into the `.claude/artifacts/` inbox with the
returned URL recorded as an HTML comment on the first line, so a later session
can republish to the same page instead of minting a new one:

```bash
mkdir -p .claude/artifacts
target=".claude/artifacts/diff-$(git rev-parse --abbrev-ref HEAD | tr '/' '-')-$(date +%F).html"
{ echo "<!-- artifact-url: $URL -->"; cat "$SCRATCH_HTML"; } > "$target"
```

Report the claude.ai URL and the local path.

**On publish failure** (no claude.ai login, or publishing unavailable): this is
not an edge case — sharing beyond the author needs Team/Enterprise, so on Pro
and Max the fallback *is* how the page reaches teammates. Keep the local HTML,
say plainly that publishing did not happen and why, and offer
`social-media-tools:save-artifact` to publish it into the repo's GitHub Pages
artifacts gallery instead.

## Republishing

If the inbox already holds a page for this branch with an `artifact-url:`
comment, pass that URL to `Artifact`'s `url` parameter to update the same page.
Without it, every session mints a new URL and the link you shared goes stale.
