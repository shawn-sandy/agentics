---
name: save-artifact
description: "Saves an HTML Artifact page to the plugin's artifacts folder for sharing. Copies a chosen .html into ${CLAUDE_PLUGIN_ROOT}/artifacts with a dated name. Use when asked to save or share an artifact."
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion, ToolSearch, ExitPlanMode
---

# save-artifact

Copy an HTML Artifact page into the plugin's `artifacts/` folder under a dated
filename, so a page you just built can be handed off and shared in one step.

## Overview

Claude's Artifact tool produces self-contained HTML pages, but each lives only
in the chat session. This skill copies one into
`${CLAUDE_PLUGIN_ROOT}/artifacts/` with a `<name>-YYYY-MM-DD.html` filename and
reports the saved path.

> **Note on durability.** `${CLAUDE_PLUGIN_ROOT}` resolves to the *installed*
> plugin cache. That directory is wiped when the plugin is reinstalled or
> updated, so files saved here are not durable and are not committed with any
> repo. Save copies you need to keep somewhere else.

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

```bash
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo "Error: CLAUDE_PLUGIN_ROOT is not set — run this skill from within the installed social-media-tools plugin." >&2
  exit 1
fi
DEST="${CLAUDE_PLUGIN_ROOT}/artifacts"
mkdir -p "$DEST" || { echo "Error: could not create $DEST" >&2; exit 1; }
```

If the variable is unset, stop with the error above — do not fall back to
another directory.

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

## Step 4 — Report

Tell the user the saved path (`$target`) so they can share it. Mention the
durability note from the Overview if the artifact is something they intend to
keep long-term.
