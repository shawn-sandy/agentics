---
name: github-code-share
description: "Fetches a GitHub file and generates social media copy. Creates a syntax-highlighted card image for LinkedIn, Twitter/X, or Bluesky. Use when asked to share a code snippet or file from a GitHub repository."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, WebFetch, Skill, SendUserFile, Glob
---

# github-code-share

Fetch a specific file or snippet from a public GitHub repository, security-scrub it,
draft platform-aware copy, and generate a syntax-highlighted dark-mode card image.

**Public repositories only.** A 4xx from the raw URL means the repo is private or
the path is wrong — stop with a clear error.

## Quick Reference

| Phase | Action |
|-------|--------|
| 1 — Parse URL | Extract owner/repo/branch/path + parse `#L` fragment before any WebFetch |
| 1c — Reuse check | Scan `docs/media/social/` for existing snippet posts; offer reuse |
| 2 — Fetch Raw Code | WebFetch raw URL; extract line range; cap at 80 lines |
| 3 — Security Scrub | Write to temp file; call security-scrub skill with explicit args |
| 4 — Draft Copy | Write platform-aware copy; store as `POST_COPY_TEXT_RAW` |
| 5 — Populate Template | HTML-escape code; fill `snippet-card.html`; add `{{POST_COPY_TEXT}}`; save to `docs/media/social/` |
| 6 — Deliver | Copy in fenced block + PNG card + saved path |

---

## Phase 1 — Parse GitHub URL

### Accepted URL forms

- `https://github.com/{owner}/{repo}/blob/{branch}/{path}` — standard file view
- `https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` — raw URL (skip conversion in Phase 2)

### Parse the URL fragment FIRST — before any WebFetch call

URL fragments (`#L10-L25`) are never sent to servers. Extract them from the URL
string before doing anything else:

1. If the URL contains `#L`: split on `#`, parse the right side:
   - `L10` → `LINE_START=10`, `LINE_END=10` (single line)
   - `L10-L25` → `LINE_START=10`, `LINE_END=25`
2. Store `LINE_START` / `LINE_END` (or leave unset if no fragment).
3. **Strip the `#...` fragment** from the URL — do not include it in any subsequent step.

### Extract URL components

From the (fragment-stripped) URL, extract:
- `OWNER` — repository owner
- `REPO` — repository name
- `BRANCH` — branch or commit SHA
- `FILE_PATH` — file path relative to repo root

Derive:
- `FILENAME` = basename of `FILE_PATH` (e.g., `auth.ts`)
- `REPO_SLUG` = `OWNER/REPO`
- `LANGUAGE` and `LANGUAGE_COLOR` from file extension — look up in `references/language-map.md`
- `HLJS_CLASS` = lowercase language alias for highlight.js (e.g., `typescript`, `python`); for C#: `csharp`; for C++: `cpp`; for Shell: `bash`

Use `AskUserQuestion` to collect:
- `PLATFORM` — LinkedIn, Twitter/X, or Bluesky
- `HOOK_ANGLE` (optional) — e.g. "focus on the error handling pattern"

---

## Phase 1c — Reuse Check

After collecting inputs, check for existing saved snippet posts:

```bash
MEDIA_DIR="${PWD}/docs/media/social"
existing=$(ls "$MEDIA_DIR"/snippet-*.html 2>/dev/null | sort -r | head -5)
```

If `$existing` is non-empty, show the list and use `AskUserQuestion` to ask:
> "Found existing snippet post(s). Reuse one or generate a new one?"

If user picks **reuse**: extract post text from `<textarea class="post-copy-text" id="post-copy">…</textarea>`, present it, show file path, **STOP.**

---

## Phase 2 — Fetch Raw Code

### Deferred tool bootstrap

`WebFetch` is a deferred tool — its schema is not loaded at session start.

```
Use ToolSearch with select:WebFetch first (silent, no user output), then call WebFetch.
```

### Fetch

- If input was `github.com/.../blob/...`: convert to raw URL:
  `https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}/{FILE_PATH}`
- If input was already `raw.githubusercontent.com/...`: use as-is.

Call `WebFetch` on the raw URL.

**4xx response:** output exactly:
> "This repository may be private or the file path is incorrect. This skill only supports public repositories."

Then **STOP**.

### Extract lines

- If `LINE_START` / `LINE_END` are set: extract exactly those lines (1-indexed).
- If no line range: use lines 1–80. Tell the user:
  > "Showing lines 1–80. To share a specific range, add `#L10-L25` to the GitHub URL."

---

## Phase 3 — Security Scrub

`security-scrub` operates on files via `Grep`, not inline text. Write the extracted
snippet to a temp file first using the `Write` tool:

```
Write to: ~/.claude/tmp/scrub-input.txt
Content: the extracted code snippet (plain text, no HTML escaping yet)
```

Then invoke:
```
Skill(skill: "code-share:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Parse the returned `SCRUB RESULT` block:
- `SCRUB RESULT: BLOCKED` **or** `ALLOWLIST verdict: BLOCKED` → report masked findings to user. **STOP.**
- `SCRUB RESULT: WARN` → surface the warning. Ask user to confirm with `AskUserQuestion` before continuing.
- `SCRUB RESULT: PASS` → continue silently.

---

## Phase 4 — Draft Copy

Read the code snippet (now confirmed PASS/WARN) and understand what it does before drafting.

| Platform | Max | Structure |
|----------|-----|-----------|
| LinkedIn | 1,500 chars | Context ("Here's [LANGUAGE] code from [OWNER/REPO] that...") + what it does + key design decision or insight + CTA with link + 2–4 hashtags |
| Twitter/X | 280 chars | "[LANGUAGE] snippet worth seeing → [what it does in one phrase] — [GitHub URL]" |
| Bluesky | 300 chars | Similar brevity to Twitter; name the repo |

Present the draft in a fenced code block labelled with the platform. Wait for approval.

Store all platform variants as `POST_COPY_TEXT_RAW` (join with `\n---\n`). Used in Phase 5 for the copy panel.

---

## Phase 5 — Populate Template

### Locate TEMPLATES_DIR

Same three-path probe as `code-share`:
```bash
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Set `TEMPLATE_FILE=$TEMPLATES_DIR/snippet-card.html`. If not found, output the
"Templates not found" message and **STOP**.

### HTML-escape the code — MANDATORY

Unescaped code will break the card's HTML rendering. Apply in this order:

1. `&` → `&amp;`  ← must be first (prevents double-escaping)
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

Store the result as `CODE_LINES_ESCAPED`.

### Substitute variables

| Template variable | Value |
|-------------------|-------|
| `{{FILENAME}}` | `FILENAME` (HTML-escaped) |
| `{{LANGUAGE}}` | `LANGUAGE` display name (HTML-escaped) |
| `{{LANGUAGE_COLOR}}` | `LANGUAGE_COLOR` hex (from language-map.md only) |
| `{{CODE_LINES}}` | `CODE_LINES_ESCAPED` |
| `{{LINE_RANGE}}` | e.g., `"L10–L25"` or `"lines 1–80"` |
| `{{REPO_SLUG}}` | `"OWNER/REPO"` (HTML-escaped) |
| `{{GITHUB_URL}}` | Fragment-stripped original URL |

For the `<code>` element's `class` attribute, use `HLJS_CLASS` (lowercase):
`<code class="language-typescript">` — set by the template's `{{LANGUAGE}}` substitution;
the template uses `language-{{LANGUAGE}}` but the skill should pass the lowercase hljs alias,
not the display name (i.e., pass `"typescript"` not `"TypeScript"`).

### Substitute `{{POST_COPY_TEXT}}`

Apply textarea-safe escaping to `POST_COPY_TEXT_RAW` (in this order): `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`. Store as `POST_COPY_TEXT` and include in template substitution.

Write to `~/.claude/tmp/github-code-share-card.html`.

### Persistent save to docs/media/social/

```bash
MEDIA_DIR="${PWD}/docs/media/social"
mkdir -p "$MEDIA_DIR"
SLUG=$(echo "$FILENAME" | tr '[:upper:]' '[:lower:]' | \
       sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SAVE_PATH="$MEDIA_DIR/snippet-${SLUG}-${DATE}.html"
# Write the same populated HTML to $SAVE_PATH using the Write tool
```

### Screenshot pipeline

1. `python3 $PLUGIN_DIR/scripts/find_free_port.py` → `$PORT`
2. Start `python3 -m http.server $PORT` from `~/.claude/tmp/`, capture `SERVER_PID`
3. ToolSearch for Playwright tools → navigate → wait → screenshot to `~/.claude/tmp/github-code-share-card.png`
4. Kill server

---

## Phase 6 — Deliver

1. `## [Platform] Copy` heading
2. Copy in fenced code block with character count `[NNN / max]`
3. Attach `~/.claude/tmp/github-code-share-card.png` via `SendUserFile`
4. Saved HTML path: `docs/media/social/snippet-{slug}-{date}.html`
5. Note: "Open the saved HTML in a browser to view the card and use the **Copy post** button."

**STOP.**
