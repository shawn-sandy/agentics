---
name: save-artifact
description: "Saves an HTML Artifact page to the plans directory for sharing. Copies a chosen .html into {plansDirectory}/artifacts with a dated name. Use when asked to save or share an artifact."
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion, ToolSearch, ExitPlanMode
---

# save-artifact

Copy an HTML Artifact page into the plans directory's `artifacts/` folder under
a dated filename, so a page you just built can be handed off and shared in one
step.

## Overview

Claude's Artifact tool produces self-contained HTML pages, but each lives only
in the chat session. This skill copies one into `{plansDirectory}/artifacts/`
with a `<name>-YYYY-MM-DD.html` filename and reports the saved path.

Saving into the plans directory (a repo path such as `docs/plans/`) keeps the
artifact durable and committable alongside the project — unlike the installed
plugin cache, which is wiped on every plugin reinstall or update.

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

Resolve `plansDirectory` following Claude Code's settings precedence — project-local
`.claude/settings.local.json`, then project `.claude/settings.json`, then global
`~/.claude/settings.json`; the first that sets it wins. Fall back to `docs/plans` if
none do. This matches how the `plans-library` skill resolves the directory, so the
saved artifact always lands in the same `artifacts/` folder the plans gallery scans.
The destination is `<plansDirectory>/artifacts`.

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
print('docs/plans')
EOF
)
DEST="$PLANS_DIR/artifacts"
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

## Step 4 — Report

Tell the user the saved path (`$target`) so they can share it. Since it lives
under the plans directory, remind them to commit it with the repo to keep it.
