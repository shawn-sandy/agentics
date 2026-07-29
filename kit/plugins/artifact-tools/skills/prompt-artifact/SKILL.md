---
name: prompt-artifact
description: "Publishes saved prompts as claude.ai artifacts. Copies raw prompt text verbatim; publishes one prompt or the whole filterable library. Use when asked to publish or share a prompt."
allowed-tools: Bash, Read, Write, Edit, Glob, Skill, Artifact, WebFetch, AskUserQuestion, ToolSearch, ExitPlanMode
---

# prompt-artifact

Publish a prompt saved by `plan-agent:write-prompt` to claude.ai as a page whose
whole job is to hand the raw prompt back — one prompt by default, or the entire
prompt library with `--library`.

## Overview

A saved prompt is only worth anything when it reaches a text box somewhere else.
This skill publishes prompts as pages built around a copy button that returns the
prompt **verbatim** — no entities, no re-indentation, no smart quotes. A copy
that pastes back escaped is not a cosmetic bug; it is the skill failing at its
only job.

Both modes republish to the same URL on later runs, so a shared link keeps
showing the current prompt instead of rotting.

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Resolve the mode

Settle this before touching the filesystem:

| Arguments contain | Mode | Publishes |
|-------------------|------|-----------|
| `--library` (anywhere) | **library** | one gallery page covering every saved prompt |
| anything else — a `.md` path, or nothing | **single** | one prompt page |

## Step 2 — Resolve the prompts directory

Match `write-prompt`'s resolution exactly, or the two skills disagree about where
prompts live and this one publishes a stale or empty set. First match wins:

```bash
PROMPTS_DIR=$(python3 - <<'EOF'
import json, os, subprocess, sys
# 1. promptsDirectory from settings: project, then user-global
for path in (os.path.join(os.getcwd(), '.claude', 'settings.json'),
             os.path.join(os.path.expanduser('~'), '.claude', 'settings.json')):
    try:
        v = json.load(open(path)).get('promptsDirectory', '').strip()
        if v:
            print(v.rstrip('/')); sys.exit(0)
    except Exception:
        pass
# 2. git root + docs/prompts
try:
    root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'],
                                   stderr=subprocess.DEVNULL, text=True).strip()
    print(os.path.join(root, 'docs', 'prompts')); sys.exit(0)
except Exception:
    pass
# 3. cwd-relative
print(os.path.join(os.getcwd(), 'docs', 'prompts'))
EOF
)
```

## Step 3 — Resolve the prompt(s)

**Single mode.** Take the `.md` path if the user gave one. If not, `Glob`
`$PROMPTS_DIR/*.md` and ask via `AskUserQuestion`. Never guess — publishing the
wrong prompt is a silent error the user only finds after sharing the link.

Read the frontmatter: `type`, `intent`, `techniques`, `created`, and
`artifact-url:`. The body below the frontmatter's closing `---` is the prompt;
the H1 is the title.

**Read the keys you need and ignore the rest.** `type: proposal` prompts also
carry `status:`, `modified:`, and `generated-sha:`; more keys will follow. An
unrecognized key is not an error and must never abort the read or blank a card —
render `modified:` beside `created:` in the metadata row when present, and drop
anything else silently.

**Library mode.** `Glob` `$PROMPTS_DIR/*.md`. If nothing matches, tell the user:

> "No saved prompts found in `<PROMPTS_DIR>`. Run `/plan-agent:write-prompt` to
> create your first one."

**STOP.** Never publish an empty gallery — a page announcing nothing still costs
a URL and reads as a broken deliverable.

## Step 4 — Scrub before publishing (blocking gate)

Run `social-media-tools:security-scrub` over the prompt body (single mode) or
every prompt body (library mode) via the `Skill` tool. Prompts quote schemas,
endpoints, and sample payloads, so they leak more readily than their prose
suggests.

- `GATE RESULT: BLOCKED` → **hard stop.** No publish, no override. Report the
  masked findings and stop.
- `GATE RESULT: CANCELLED` → the user declined. Stop.
- `GATE RESULT: APPROVED` → continue.

In library mode a finding in **any** prompt stops the whole publish, and the
report names the offending file. Do not quietly drop that prompt and ship the
rest — the user would get a gallery that silently omits work, and the leak stays
unfixed on disk.

If `security-scrub` is unavailable, say the scan could not run and ask via
`AskUserQuestion` before continuing — never skip the gate silently.

## Step 5 — Build the page

Load the `artifact-design` skill first to calibrate design investment, then
`Write` one self-contained `.html` file to the scratchpad.

Both modes:

- **Self-contained** — a strict CSP blocks every external request. Inline all
  CSS and JS; no CDN links, no web fonts, no remote images, no fetch.
- **Theme-aware** — `@media (prefers-color-scheme: dark)` for the default
  signal, plus `:root[data-theme="dark"]` / `:root[data-theme="light"]`
  overrides so the viewer's theme toggle wins in both directions.
- **Escape every value read from the `.md`** — not just the prompt body. Prompts
  are full of XML tags (`<context>`, `<instructions>`), and so are the titles and
  intents describing them: a prompt titled `# Summarize <document>` breaks the
  page from the `<title>`, the card heading, or a `data-type` attribute just as
  surely as from the `<pre>`. Escape `&`, `<`, `>` in text, and additionally `"`
  and `'` in anything interpolated into an attribute:

  | Value | Lands in |
  |-------|----------|
  | H1 title | `<title>`, card heading |
  | `intent` | card body text |
  | `techniques`, `created` | metadata row |
  | `type` | chip text **and** `data-type="…"` |
  | prompt body | `<pre>` |

  Escaping the body alone leaves the other five as injection points.
- **Set a `<title>` per `${CLAUDE_PLUGIN_ROOT}/references/titles.md`** — read it
  first. A prompt's H1 is usually already a bare subject and can stand as the
  title; the derived subject is the prompt's *goal*, not the text of the prompt
  itself. In library mode the subject is the collection (`Prompt library`), not
  any one prompt. Write the page content only (no `<!doctype>`/`<html>`/`<head>`
  /`<body>` — those are added at publish time).

**Single mode** renders the H1 as the title, a metadata row (`type`,
`techniques`, `created`), and the prompt in one `<pre>` block with its copy
button.

**Library mode** renders one card per prompt — title, `type` chip, `intent`,
`created` — with the full body expandable in place (`<details>` needs no JS) and
its own copy button per card. Filter chips by `type` (`task`, `system`,
`creative`, `analytical`, `proposal`) hide and show cards via inlined JS; carry
the value on `data-type` and follow `plans-library`'s card and filter idiom
rather than inventing a second one. A type with no saved prompts still gets its
chip — an absent chip reads as a broken filter, an empty one reads as an empty
category. Sort newest-first by `created` (`YYYY-MM-DD` strings compare
correctly), empty `created` last, ties broken by title ascending.

`proposal` bodies run several hundred lines — roughly 3x anything else in the
directory. The existing `<details>` collapse already keeps them out of the way
until opened; give the `<pre>` `overflow-x: auto` so a wide markdown table
scrolls inside its own card instead of widening the page. The page body must
never scroll horizontally at mobile width. No type-specific CSS beyond that.

### The copy button

Copy from the DOM, not from a duplicated copy of the text:

```html
<pre id="p1">{{ESCAPED_PROMPT}}</pre>
<button data-copy="p1">Copy</button>
<script>
document.querySelectorAll('[data-copy]').forEach(function (b) {
  b.addEventListener('click', function () {
    var pre = document.getElementById(b.dataset.copy);
    var ok = function () {
      b.textContent = 'Copied';
      setTimeout(function () { b.textContent = 'Copy'; }, 1500);
    };
    // Clipboard API missing or denied: select the text so Cmd/Ctrl-C still works.
    var manual = function () {
      var r = document.createRange();
      r.selectNodeContents(pre);
      var sel = getSelection();
      sel.removeAllRanges();
      sel.addRange(r);
      b.textContent = 'Selected — press Cmd/Ctrl-C';
    };
    if (!navigator.clipboard) { manual(); return; }
    navigator.clipboard.writeText(pre.textContent).then(ok, manual);
  });
});
</script>
```

`textContent` returns the entities already decoded, so the escaping from Step 5
round-trips back to the exact source text. Three things break that guarantee:

- **No newline after `<pre>`.** The HTML parser drops one immediately following
  the open tag, and the copied prompt loses its first line break.
- **No prettifying the `<pre>`.** Indenting it to match surrounding markup
  indents every copied line with it.
- **Never leave `writeText` unhandled.** It rejects on a denied permission, and
  is absent outside a secure context — which is exactly the Step 8 fallback page
  opened over `file://`. An unhandled rejection makes the button do nothing at
  all, silently, on the one path where the page is the only deliverable. Hence
  the rejection handler above: selecting the `<pre>` contents leaves the user one
  keystroke from the same result, and copies the same verbatim text.

## Step 6 — Publish, then record the URL

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.

Publish with a one-sentence `description` and the favicon `📝` — keep the favicon
and `<title>` stable across republishes, since users find the tab by its icon.

Where the URL is recorded differs by mode:

| Mode | URL lives in | First publish | Republish |
|------|--------------|---------------|-----------|
| single | the prompt `.md`'s frontmatter | publish fresh, then `Edit` in `artifact-url:` | pass `artifact-url:` to `Artifact`'s `url` |
| library | `$PROMPTS_DIR/.artifact-url` | publish fresh, then write the file | pass its contents to `Artifact`'s `url` |

The gallery has no single source `.md` to hold frontmatter, hence the sidecar:

```bash
SIDECAR="$PROMPTS_DIR/.artifact-url"
[ -f "$SIDECAR" ] && LIBRARY_URL=$(cat "$SIDECAR")   # republish
# after a successful first publish:
printf '%s\n' "$URL" > "$SIDECAR"
```

**Commit the sidecar.** This repo already treats a recorded artifact URL as
shared state — `session-artifact` saves its recap under `{plansDirectory}` for
exactly this reason. Ignoring the sidecar would give every clone its own gallery
URL, which is the rot the stable-URL design exists to prevent. It is not covered
by any existing `.gitignore` rule, so no change is needed there.

Skipping the record step is the quiet failure mode in both modes: the publish
looks fine, and the *next* session mints a second page while the link you shared
goes stale.

## Step 7 — Verify the page rendered

Runs only after a successful publish. `WebFetch` is a deferred tool: use `ToolSearch` with `select:WebFetch` first.

Fetch the returned URL and confirm the fetched page contains the prompt's H1
title (single mode) or every published prompt's title (library mode). A returned
URL is not evidence the page rendered — a blank artifact returns a URL too, and
in library mode a page missing a card is the failure this catches.

If a title is absent, report the failure **with the URL** so the user can open
it, and do not report the publish as successful.

## Step 8 — Fallback

If publishing fails (no claude.ai login, or publishing unavailable), the scratchpad
copy is not a deliverable — it is temporary. Write the page to `.claude/artifacts/`
so something durable survives, keyed by what the page *is*, never by date:

```bash
mkdir -p .claude/artifacts
# single: prompt-<basename>.html | library: prompt-library.html
cp "$SCRATCH_HTML" ".claude/artifacts/prompt-${key}.html"
```

Say plainly that publishing did not happen and why, report the local path, and
offer `social-media-tools:save-artifact` — it publishes into the repo's GitHub
Pages artifacts gallery.

Never report a URL that was not returned by a successful publish.
