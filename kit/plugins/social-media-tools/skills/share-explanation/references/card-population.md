# Card Population Reference

Template selection, the mandatory HTML-escape order, and the per-template variable tables.
Phase 6 of `share-explanation`.

## Select template based on target type

- `TARGET_TYPE=skill` or `TARGET_TYPE=command` → use `feature-card.html`
- `TARGET_TYPE=file` or `TARGET_TYPE=function` → use `feature-card.html`
- `TARGET_TYPE=concept` → use `quote-card.html`

```bash
TEMPLATE_FILE=$TEMPLATES_DIR/<selected-template>
TEMP_HTML=explain-share-card.html
TODAY=$(date '+%Y-%m-%d')
# Normalize TARGET_NAME (or TARGET_RAW for concept targets) through the same slug pipeline
TARGET_SLUG="$(printf '%s' "${TARGET_NAME:-$TARGET_RAW}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//' | cut -c1-30)"
SLUG_INPUT="explain-${TARGET_SLUG}-${TODAY}"
```

`SLUG_INPUT` and `TEMP_HTML` carry forward into Phase 6b's persistent save.

## HTML-escape all values — MANDATORY

Apply in this exact order:

1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

## feature-card.html substitutions

| Template variable | Value |
|-------------------|-------|
| `{{TITLE}}` | `TARGET_NAME` (HTML-escaped; e.g. `share-session`) |
| `{{SUBTITLE}}` | Core Purpose sentence, ≤100 chars (HTML-escaped) |
| `{{BULLETS}}` | One `<li>…</li>` per Workflow Phase — HTML-escape each phase's **text**, wrap in `<li>`. No wrapping `<ul>`. |
| `{{BADGE}}` | `TARGET_TYPE` (HTML-escaped; `skill` or `command`) |
| `{{FOOTER_NOTE}}` | Invocation syntax (HTML-escaped; e.g. `/social-media-tools:share-session [--platform=]`) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `$PLUGIN_DIR/references/copy-panels.md` |

## quote-card.html substitutions

| Template variable | Value |
|-------------------|-------|
| `{{QUOTE}}` | Most important Key Pattern principle, ≤200 chars (HTML-escaped) |
| `{{ATTRIBUTION}}` | Plugin or project name (HTML-escaped; e.g. `social-media-tools`) |
| `{{CONTEXT}}` | Pattern category (HTML-escaped; e.g. `Security pattern`, `Bootstrap pattern`) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `$PLUGIN_DIR/references/copy-panels.md` |

## Output

Write the populated HTML to `~/.claude/tmp/explain-share-card.html`.
