---
name: github-code-share
description: "Fetches a GitHub file and generates social media copy. Creates a syntax-highlighted card for LinkedIn, Twitter/X, or Bluesky. Use when asked to share a code snippet from a GitHub repository."
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
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Parse URL | Extract owner/repo/branch/path + parse `#L` fragment before any WebFetch |
| 1c — Reuse check | Scan `docs/media/social/` for existing snippet posts; offer reuse |
| 2 — Fetch Raw Code | WebFetch raw URL; extract line range; cap at 80 lines |
| 3 — Security Scrub | Write to temp file; call security-scrub skill with explicit args |
| 4 — Draft Copy | Write platform-aware copy |
| 5 — Populate Template | HTML-escape code; fill `snippet-card.html`; save to `docs/media/social/` |
| 6 — Deliver | Copy in fenced block + PNG card + saved path |

## Non-interactive mode

When `$ARGUMENTS` contains `--background`: read `$PLUGIN_DIR/references/non-interactive-mode.md`
and follow all skip rules. Do not pause for user input at any point.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Derive:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
```

If not found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Parse GitHub URL

### Accepted URL forms

- `https://github.com/{owner}/{repo}/blob/{branch}/{path}` — standard file view
- `https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` — raw URL

### Parse the URL fragment FIRST — before any WebFetch call

1. If the URL contains `#L`: split on `#`, parse the right side:
   - `L10` → `LINE_START=10`, `LINE_END=10`
   - `L10-L25` → `LINE_START=10`, `LINE_END=25`
2. **Strip the `#...` fragment** from the URL — do not include it in any subsequent step.

### Extract URL components

- `OWNER`, `REPO`, `BRANCH`, `FILE_PATH`
- `FILENAME` = basename of `FILE_PATH`
- `REPO_SLUG` = `OWNER/REPO`
- `LANGUAGE` and `LANGUAGE_COLOR` from file extension — look up in `$PLUGIN_DIR/references/language-map.md`
- `HLJS_CLASS` = lowercase language alias (e.g., `typescript`, `python`; C# → `csharp`; C++ → `cpp`; Shell → `bash`)

*(Interactive mode only — see Non-interactive mode above when `--background` is set.)*
Use `AskUserQuestion` to collect:
- `PLATFORM` — LinkedIn, Twitter/X, Bluesky, or **All sites**
- `HOOK_ANGLE` (optional)

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=snippet
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Fetch Raw Code

### Deferred tool bootstrap

```
Use ToolSearch with select:WebFetch first (silent, no user output), then call WebFetch.
```

- If input was `github.com/.../blob/...`: convert to raw URL:
  `https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}/{FILE_PATH}`
- If input was `raw.githubusercontent.com/...`: use as-is.

Call `WebFetch` on the raw URL. Store the response body as `RAW_CONTENT`.

**4xx response:**
> "This repository may be private or the file path is incorrect. This skill only supports public repositories."
Then **STOP**.

Extract lines from `RAW_CONTENT`: if `LINE_START`/`LINE_END` set, use those (1-indexed); otherwise use lines 1–80.

---

## Phase 3 — Security Scrub

Write the extracted snippet to a temp file:

```
Write to: ~/.claude/tmp/scrub-input.txt
Content: the extracted code snippet (plain text, no HTML escaping yet)
```

Then invoke:
```
Skill(skill: "code-share:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Parse the returned `SCRUB RESULT` block:
- `BLOCKED` → report masked findings, **STOP.**
- `WARN` → *(Interactive mode)* surface the warning, ask user to confirm before continuing; *(background mode)* auto-proceed per `non-interactive-mode.md`.
- `PASS` → continue silently.

---

## Phase 4 — Draft Copy

For character limits and the **Follow CTA** rule, read `$PLUGIN_DIR/references/platforms.md`.

- **LinkedIn**: Context ("Here's [LANGUAGE] code from [OWNER/REPO] that...") + what it does + key design decision or insight + CTA with link + 2–4 hashtags
- **Twitter/X**: "[LANGUAGE] snippet worth seeing → [what it does in one phrase] — [GitHub URL]"
- **Bluesky**: Similar brevity to Twitter; name the repo

Close with a topic-matched **follow** CTA (tied to the `LANGUAGE`/repo subject) — varied each time, never a generic "follow me"; on Twitter/Bluesky include it only if it fits the limit.

Read the code snippet before drafting. *(Interactive mode only — present in a fenced code block labelled with the platform and wait for approval; in `--background` mode proceed directly to Phase 5.)*

- **Single site:** store as `POST_COPY_TEXT_RAW`
- **All sites:** keep separate (`LINKEDIN_COPY`, `TWITTER_COPY`, `BLUESKY_COPY`)

---

## Phase 5 — Populate Template

### HTML-escape the code — MANDATORY

Apply in this exact order:
1. `&` → `&amp;` ← must be first (prevents double-escaping)
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

Store the result as `CODE_LINES_ESCAPED`.

### Substitute variables

For variable reference, read `$PLUGIN_DIR/references/variables.md`.

| Template variable | Value |
|-------------------|-------|
| `{{FILENAME}}` | `FILENAME` (HTML-escaped) |
| `{{LANGUAGE}}` | `HLJS_CLASS` (lowercase alias, e.g. `typescript`) |
| `{{LANGUAGE_COLOR}}` | `LANGUAGE_COLOR` hex (from `$PLUGIN_DIR/references/language-map.md` only) |
| `{{CODE_LINES}}` | `CODE_LINES_ESCAPED` |
| `{{LINE_RANGE}}` | e.g., `"L10–L25"` or `"lines 1–80"` |
| `{{REPO_SLUG}}` | `"OWNER/REPO"` (HTML-escaped) |
| `{{GITHUB_URL}}` | Fragment-stripped original URL |

### COPY_PANELS

Read `$PLUGIN_DIR/references/copy-panels.md` for markup and escaping rules.

Write the populated HTML to `~/.claude/tmp/github-code-share-card.html`:

```bash
mkdir -p ~/.claude/tmp
TEMP_HTML=github-code-share-card.html
FILE_PREFIX=snippet
SLUG_INPUT=$FILENAME
```

### Persistent Save

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

### Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 6 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.
