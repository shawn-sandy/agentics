# Card Population (Phase 4)

Bundled reference for `share-session`. Applies to `session-card.html`, already resolved as
`TEMPLATE_FILE` by Phase 4.

## HTML-escape all values — MANDATORY

Apply to every substituted string in this exact order:

1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

## `session-card.html` variable table

| Template variable | Value |
|-------------------|-------|
| `{{TITLE}}` | `TITLE` (HTML-escaped; e.g. `session recap · 2026-05-28`) |
| `{{MODEL}}` | `MODEL` (HTML-escaped; e.g. `sonnet-4-6`) |
| `{{NARRATIVE}}` | `NARRATIVE` (HTML-escaped; 1–2 sentences, ≤240 chars) |
| `{{ACCOMPLISHMENTS}}` | One `<li>…</li>` per accomplishment — HTML-escape each bullet's **text**, then wrap in `<li>` (the `<li>` tags stay literal). No wrapping `<ul>`. Mirrors `feature-card.html`'s `{{BULLETS}}`. |
| `{{TOTAL_TOKENS}}` | Total tokens formatted with commas (HTML-escaped) |
| `{{CACHE_HIT_RATE}}` | Cache hit rate (e.g. `44.2%`) (HTML-escaped) |
| `{{DURATION}}` | Duration in minutes (e.g. `47 min`; `0 min` if unknown) (HTML-escaped) |
| `{{FILES_CHANGED}}` | Files changed integer (HTML-escaped) |
| `{{COMMITS}}` | Commits count integer (HTML-escaped) |
| `{{COPY_PANELS}}` | Copy panel HTML — see the plugin-level `copy-panels.md` reference linked from Phase 4 |

**Never render a dollar amount or cost figure anywhere on the card — tokens only.**
