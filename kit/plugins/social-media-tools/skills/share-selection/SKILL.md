---
name: share-selection
description: "Turns selected or pasted code into a platform-aware social card. Scrubs, picks a template, and screenshots via Playwright. Use when asked to share, post, or tweet highlighted or pasted code."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, SendUserFile, Glob, Skill
---

# share-selection

Turn code the user **selected, highlighted, opened, or pasted** into platform-aware social
media copy and a styled dark-mode card image for any supported platform (see
`$PLUGIN_DIR/references/platforms.md`) — with the copy shaped by the user's stated objective.

This skill is **selection-driven**: it shares a specific piece of code the user points at. It
does **not** scan git history — that is `code-share`'s job.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Capture | Detect selected/open/pasted code + the post objective |
| 1c — Reuse check | Scan `docs/media/social/` for existing posts; offer reuse |
| 2 — Scrub | Run `security-scrub` on the code before sharing |
| 3 — Draft | Write platform-aware copy that serves the objective |
| 4 — Pick template | diff-like → diff-card, otherwise snippet-card |
| 5 — Populate | Read template, substitute `{{VARIABLES}}` including `{{COPY_PANELS}}` |
| 5b — Save | Persistent save to `docs/media/social/` |
| 6 — Screenshot | Serve HTML locally, Playwright screenshot |
| 7 — Deliver | Present copy + attach PNG + show saved path |

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

If no directory is found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Capture Selection + Objective

### Source the code (first match wins)

1. **Highlighted lines** — if the user highlighted lines in their IDE (provided via context),
   use exactly those lines. Set `LINE_RANGE` to the highlighted range (e.g. `"L42–L58"`).
2. **Selected / open file** — if a file is selected or open in the IDE (path provided via
   context) with no specific lines highlighted, read the file and use its contents. Take
   `FILENAME` and the language from the real path/extension.
3. **Pasted code** — if the user pasted a fenced code block in their message, use its
   contents. Take the language from the fence tag (e.g. ```` ```python ````) when present.

Capture for later phases: the code text (`CODE_RAW`), a filename/path hint, a language hint,
and a line range when known.

### Selected-file guards

- **Non-code file** (binary, image, lockfile such as `package-lock.json`/`*.lock`, minified
  bundle, or anything that isn't human-readable source): do **not** render it. Tell the user
  what was selected and ask them to pick a code file or paste a snippet instead. **STOP.**
- **Long file** — `snippet-card` caps at ~80 lines (Phase 5). *(Interactive mode)* If the
  source exceeds 80 lines, use `AskUserQuestion` to ask which region to feature (a line range,
  function, or section), then use only that range. Do **not** silently truncate or render the
  whole file. *(Background mode)* use the first 80 lines without asking.

### No code found

If none of the three sources yields code, ask the user to paste or select the code to share.
Do **not** fall back to git history.

### Objective

Determine `OBJECTIVE` — what the user wants the post to accomplish or emphasize:

- **Infer** it from the user's prompt when stated (e.g. "share this and stress the perf win"
  → `OBJECTIVE = "highlight the performance win"`).
- **Ask** only if absent: include a short free-text **objective** input ("What should this
  post accomplish or emphasize?") in the same `AskUserQuestion` that collects `PLATFORM`
  (see **Platform Options** in `$PLUGIN_DIR/references/platforms.md`) and `TONE`.

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=<snippet or diff>   # set after Phase 4's template decision; default snippet
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Security Scrub

Selected/pasted code is untrusted and about to be published. Write it to a temp file:

```
Write to: ~/.claude/tmp/scrub-input.txt
Content: CODE_RAW (plain text, no HTML escaping yet)
```

Then invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line (the gate runs inside `security-scrub`):
- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 3.
- `GATE RESULT: APPROVED` → proceed to Phase 3.
- Missing or unrecognized `GATE RESULT` → **STOP** and report an error (treat as gate failure).

---

## Phase 3 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Instructional Voice** doctrine, **Learn-More CTA** rule, **Default Per-Platform Copy
Formats**, and **Draft Copy — Standard Procedure**.

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from this code (a pattern, technique, or design principle).
The snippet is evidence for the lesson, not the headline.

Draft copy that **serves `OBJECTIVE`** within each platform's limit and the chosen tone:

- **LinkedIn**: Context ("Here's a [LANGUAGE] pattern that…") → the teachable takeaway the
  objective calls for → what makes it applicable → learn-more CTA
- **Twitter/X**: One punchy takeaway framing the snippet around the lesson
- **Bluesky**: Conversational; lead with the takeaway; name the creator
- **Substack**: Why this pattern is worth learning + the teachable principle

---

## Phase 4 — Pick Template

Inspect `CODE_RAW`:

- **Diff-like** — most lines start with `+` / `-`, it contains `@@ … @@` hunk headers, or it
  was pasted in a ```` ```diff ```` fence → use `diff-card.html`, `FILE_PREFIX=diff`.
- **Otherwise** → use `snippet-card.html`, `FILE_PREFIX=snippet`.

```bash
CARD_TYPE=<diff or snippet>
TEMPLATE_FILE=$TEMPLATES_DIR/${CARD_TYPE}-card.html
TEMP_HTML=share-selection-card.html
SLUG_INPUT=<FILENAME or a short title for the snippet>
```

---

## Phase 5 — Populate Template

Read `TEMPLATE_FILE`. For the variable reference, read `$PLUGIN_DIR/references/variables.md`.
For `{{COPY_PANELS}}` markup and escaping, read `$PLUGIN_DIR/references/copy-panels.md`.

### HTML-escape the code — MANDATORY

Apply to the code content in this exact order, storing the result as `CODE_LINES_ESCAPED`:

1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

### snippet-card variables

Derive `LANGUAGE` (lowercase hljs alias) and `LANGUAGE_COLOR` (hex) from the file
extension or fence tag via `$PLUGIN_DIR/references/language-map.md`.

| Template variable | Value |
|-------------------|-------|
| `{{FILENAME}}` | Basename of the selected file (HTML-escaped); else `snippet.<ext>` / `snippet.txt` |
| `{{LANGUAGE}}` | Lowercase hljs alias (e.g. `typescript`, `python`, `csharp`, `cpp`, `bash`) |
| `{{LANGUAGE_COLOR}}` | Hex from `references/language-map.md` only |
| `{{CODE_LINES}}` | `CODE_LINES_ESCAPED` |
| `{{LINE_RANGE}}` | Highlighted/selected range (e.g. `"L42–L58"`); else `"selected lines"` |
| `{{REPO_SLUG}}` | Local repo slug from `git remote get-url origin` parsed to `owner/repo`; fallback the repo directory name; else empty string |
| `{{GITHUB_URL}}` | Empty string for local selections (footer link renders blank) |

### diff-card variables

Convert `CODE_RAW` into hunk rows and fill the diff-card variables per the **diff-card.html**
section of `$PLUGIN_DIR/references/variables.md` (row format, `{{STAT_ADD}}`/`{{STAT_DEL}}`,
`{{COPY_PANELS}}`). `{{FILENAME}}` is the selected file name or a short title.

Write the populated HTML to `~/.claude/tmp/share-selection-card.html`:

```bash
mkdir -p ~/.claude/tmp
```

---

## Phase 5b — Persistent Save

Variables already set: `FILE_PREFIX`, `SLUG_INPUT`, `TEMP_HTML`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

---

## Phase 6 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 7 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.
