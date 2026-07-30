# Card population — locating templates, template pick, escape order, variables

Phases 0, 4, and 5 of `share-selection` in full.

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

If no directory is found: output "Templates not found. Install the plugin or load it with
`--plugin-dir`." and **STOP**.

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
| `{{LANGUAGE_COLOR}}` | Hex from `$PLUGIN_DIR/references/language-map.md` only |
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
