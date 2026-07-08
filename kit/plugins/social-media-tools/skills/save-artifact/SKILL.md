---
name: save-artifact
description: "Saves an HTML Artifact page to the local artifacts inbox for sharing. Copies a chosen .html into .claude/artifacts with a dated name, then publishes it to the deployed artifacts gallery. Use when asked to save or share an artifact."
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion, ToolSearch, ExitPlanMode
---

# save-artifact

Copy an HTML Artifact page into the local artifacts inbox at `.claude/artifacts/`
under a dated filename, then publish it to the deployed artifacts gallery, so a
page you just built can be handed off and shared in one step.

## Overview

Claude's Artifact tool produces self-contained HTML pages, but each lives only
in the chat session. This skill copies one into `.claude/artifacts/` with a
`<name>-YYYY-MM-DD.html` filename, then runs `plan-agent`'s
`build-artifacts-index.sh` to publish it into the deployed `docs/artifacts/`
tree and rebuild the standalone Artifacts gallery.

`.claude/artifacts/` is a gitignored local inbox; the durable, committable copy
is the one published under `docs/artifacts/` (which GitHub Pages serves). This
keeps saved artifacts out of the plans tree — they get their own gallery,
separate from implementation plans.

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** —
skip this step entirely when not in plan mode. When calling: use `ToolSearch`
with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

## Step 1 — Resolve the source artifact

The source is the `.html` file to save. Resolve it in this order:

1. **Explicit path** — if the user gave a path to an `.html` file, use it.
2. **In-chat artifact** — if the artifact was just generated in this
   conversation and does not exist on disk (the common "stash the artifact I
   just built" case), materialize it first: `Write` the artifact's full HTML
   to a temporary file (e.g. `<scratchpad>/<slug>.html`) and use that file as
   the source.
3. **Ask** — otherwise, look for candidate `.html` files with
   `Glob` (e.g. `docs/**/*.html`, `*.html`) and ask the user which to save via
   `AskUserQuestion`. Never guess silently.

Store the resolved path as `$SRC`. If `$SRC` does not exist, tell the user and
stop.

## Step 2 — Resolve the destination

The destination is a fixed local inbox, `.claude/artifacts/`, under the project
root. There is no `plansDirectory` lookup — artifacts no longer live in the plans
tree; the publish step (Step 4) copies them into `docs/artifacts/`.

```bash
DEST=".claude/artifacts"
mkdir -p "$DEST" || { echo "Error: could not create $DEST" >&2; exit 1; }
```

Paths are resolved relative to the current working directory, which is the
project root the skill is invoked from (same convention as the sibling
`export-session` skill).

## Step 3 — Copy under a dated, collision-safe name

```bash
SRC="<resolved source path>"
base=$(basename "$SRC" .html)
day=$(date +%F)
target="$DEST/${base}-${day}.html"
n=2
while [ -e "$target" ]; do
  target="$DEST/${base}-${day}-${n}.html"
  n=$((n + 1))
done
cp "$SRC" "$target" || { echo "Error: copy failed — nothing saved" >&2; exit 1; }
echo "Saved artifact → $target"
```

## Step 4 — Publish to the artifacts gallery

The copy above lands in the gitignored inbox and is not yet deployed. Run
`plan-agent`'s `build-artifacts-index.sh` to copy every inbox artifact into the
committed `docs/artifacts/` tree and rebuild `docs/artifacts/index.html`. This is
best-effort: the script always exits 0, and if `plan-agent` is not installed the
save still succeeds (the inbox copy is kept).

Locate the bundled script the same way `setup-sites` does (versioned cache,
direct install, or `--plugin-dir` load), then run it with the project root:

```bash
BUILD_ARTIFACTS=$( { \
  find ~/.claude/plugins -path "*/plan-agent/*/hooks/build-artifacts-index.sh" -type f 2>/dev/null | sort -rV; \
  find ~/.claude/plugins -path "*/plan-agent/hooks/build-artifacts-index.sh"   -type f 2>/dev/null; \
  find "$PWD"            -path "*/plan-agent/hooks/build-artifacts-index.sh"   -type f 2>/dev/null; \
} | head -1 )
if [ -n "$BUILD_ARTIFACTS" ]; then
  bash "$BUILD_ARTIFACTS" "$PWD" && echo "Published artifact to docs/artifacts/"
else
  echo "plan-agent not found — artifact saved to .claude/artifacts/ but not yet published"
fi
```

## Step 5 — Report

Tell the user the inbox path (`$target`) and the published copy under
`docs/artifacts/`. Remind them to commit the `docs/artifacts/` changes (the
inbox itself is gitignored). Note whether the gallery was published (Step 4) or
`plan-agent` was not found and publishing still needs to run.
