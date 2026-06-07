---
name: share-github
description: "Fetches a GitHub file and generates a syntax-highlighted social card with copy. Scrubs, fills snippet-card.html, and screenshots via Playwright. Use when asked to share a code snippet from GitHub."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, WebFetch, Skill, SendUserFile, Glob
---

# share-github

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

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
[ -n "${CLAUDE_PLUGIN_ROOT}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/templates" ] && \
  echo "${CLAUDE_PLUGIN_ROOT}/templates"
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

Use `AskUserQuestion` to collect:
- `PLATFORM` — see **Platform Options** in `$PLUGIN_DIR/references/platforms.md`
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
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line (the gate runs inside `security-scrub`):
- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 4.
- `GATE RESULT: APPROVED` → proceed to Phase 4.
- Missing or unrecognized `GATE RESULT` → **STOP** and report an error (treat as gate failure).

---

## Phase 4 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, the **Instructional Voice**
doctrine, **Learn-More CTA** rule, **Default Per-Platform Copy Formats**, and **Draft Copy —
Standard Procedure**.

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from this code (a pattern, technique, or design principle).
The code is evidence for the lesson, not the headline.

Content-specific guidance for this skill:

- **LinkedIn**: Context ("Here's a [LANGUAGE] pattern from [OWNER/REPO] that…") → the teachable takeaway → what makes it applicable → learn-more CTA with link
- **Twitter/X**: "[LANGUAGE] pattern worth learning → [the teachable principle] — [GitHub URL]"
- **Bluesky**: Similar brevity to Twitter; lead with the takeaway; name the repo
- **Substack**: What this code teaches + the principle you can apply + link

Read the code snippet before drafting.

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

Write the populated HTML to `~/.claude/tmp/share-github-card.html`:

```bash
mkdir -p ~/.claude/tmp
TEMP_HTML=share-github-card.html
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
