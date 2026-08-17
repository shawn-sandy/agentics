---
name: save-artifact
description: "Saves an HTML Artifact page to the local artifacts inbox. Copies a local .html or fetches a claude.ai artifact URL, scrubs, then publishes. Use when asked to save or share an artifact or its URL."
allowed-tools: Bash, Read, Write, Glob, WebFetch, Skill, AskUserQuestion, ToolSearch, ExitPlanMode
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

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Resolve the source artifact

The source is the `.html` file to save. Resolve it in this order:

1. **Artifact URL** — if the user gave a `https://claude.ai/code/artifact/<uuid>`
   URL, fetch it with `WebFetch`, prompt: *"Return the page's raw HTML
   verbatim."* Use `WebFetch` and nothing else — a shell fetch such as `curl`
   gets the SPA shell or a Cloudflare 403, because only `WebFetch` carries the
   claude.ai login. Then:

   - The response opens with a one-line `[Artifact <uuid> "<title>" — ...]`
     header. Discard it, but keep the `<uuid>` and `<title>` — both are used
     for the filename below.
   - Drop the `<!-- frame-runtime -->…<!-- /frame-runtime -->` block in
     `<head>`. It is claude.ai's iframe plumbing, not part of the artifact, and
     it `import`s `/_runtime/*.js` paths that resolve on claude.ai and nowhere
     else. Removing it is what makes the saved copy self-contained; keeping it
     would also mean transcribing ~25 KB of minified script by hand.
   - `Write` what remains — from `<!doctype` through `</html>` — to
     `<scratchpad>/<slug>.html`. `<slug>` is the `<title>` kebab-cased; if the
     page has no `<title>`, or the title is generic enough to collide (`report`,
     `untitled`, `demo`), append the first 8 characters of the `<uuid>` so two
     saved artifacts stay distinguishable in the gallery.

   Use that file as `$SRC`. **A failed fetch does not look like an error.** For
   a deleted or unshared artifact you get a plain sentence
   (`artifact not found — it may have been deleted...`), and for a malformed URL
   `WebFetch` silently falls back to ordinary page-summary mode and answers in
   prose. Neither contains `<!doctype`. Treat the absence of `<!doctype` as the
   failure signal, say what happened, and stop — never save a partial page.
2. **Explicit path** — if the user gave a path to an `.html` file, use it.
3. **In-chat artifact** — if the artifact was just generated in this
   conversation and does not exist on disk (the common "stash the artifact I
   just built" case), materialize it first: `Write` the artifact's full HTML
   to a temporary file (e.g. `<scratchpad>/<slug>.html`) and use that file as
   the source.
4. **Ask** — otherwise, look for candidate `.html` files with
   `Glob` (e.g. `docs/**/*.html`, `*.html`) and ask the user which to save via
   `AskUserQuestion`. Never guess silently.

Store the resolved path as `$SRC`. If `$SRC` does not exist, tell the user and
stop.

## Step 1b — Security scrub (blocking gate)

Before copying anything, run the scrub on `$SRC`. Step 4 publishes into
`docs/artifacts/`, which the user commits and GitHub Pages serves publicly — a
secret in the page becomes a public secret.

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at $SRC for secrets before saving and publishing.")
```

Check the returned `GATE RESULT` line (the gate runs inside `security-scrub`):

- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not copy,
  do not publish.
- `GATE RESULT: APPROVED` → proceed to Step 2.
- Missing or unrecognized `GATE RESULT` → **STOP** and report an error (treat as
  gate failure). Never fall through to the copy on an unread result.

This gate matters most for the URL branch: a fetched artifact is remote content,
and it need not be the user's own (claude.ai artifacts can be shared with an
account), so nobody in this session has necessarily read the page before it is
published.

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
committed `docs/artifacts/` tree and rebuild `docs/artifacts/index.html`. The
script always exits 0, so its exit status says nothing about whether the
publish landed — verify the outputs instead: the published copy (same basename
as the Step 3 target) must exist under `docs/artifacts/`, and the gallery index
must exist and have changed. The block below captures a checksum of the index
before the run and compares it after. If `plan-agent` is not installed the save
still succeeds (the inbox copy is kept).

Locate the bundled script the same way `setup-sites` does (versioned cache,
direct install, or `--plugin-dir` load), then run it with the project root:

```bash
BUILD_ARTIFACTS=$( { \
  find ~/.claude/plugins -path "*/plan-agent/*/hooks/build-artifacts-index.sh" -type f 2>/dev/null | sort -rV; \
  find ~/.claude/plugins -path "*/plan-agent/hooks/build-artifacts-index.sh"   -type f 2>/dev/null; \
  find "$PWD"            -path "*/plan-agent/hooks/build-artifacts-index.sh"   -type f 2>/dev/null; \
} | head -1 )
if [ -n "$BUILD_ARTIFACTS" ]; then
  idx="docs/artifacts/index.html"
  before="$(cksum "$idx" 2>/dev/null || echo missing)"
  bash "$BUILD_ARTIFACTS" "$PWD"
  after="$(cksum "$idx" 2>/dev/null || echo missing)"
  if [ -f "docs/artifacts/$(basename "$target")" ] && [ -f "$idx" ] && [ "$after" != "$before" ]; then
    echo "Published artifact to docs/artifacts/"
  else
    echo "saved to inbox, publish did not land — rerun build-artifacts-index.sh"
  fi
else
  echo "plan-agent not found — artifact saved to .claude/artifacts/ but not yet published"
fi
```

## Step 5 — Report

Report according to what Step 4 verified — never claim a publish that was not
confirmed:

- **Verified published** — Step 4 printed the success line after confirming the
  published copy and the changed gallery index exist. Tell the user the inbox
  path (`$target`) and the published copy under `docs/artifacts/`, and remind
  them to commit the `docs/artifacts/` changes (the inbox itself is gitignored).
- **Inbox only** — Step 4 reported the publish did not land, or `plan-agent`
  was not found. Tell the user the artifact is saved at `$target` but **not
  published**, and that `build-artifacts-index.sh` still needs to run before
  there is anything under `docs/artifacts/` to commit.
