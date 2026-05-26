# Template Variable Reference

All templates live in `kit/plugins/social-media-tools/templates/`. Each HTML file has a comment block at the top listing its variables and an example.

---

## diff-card.html

| Variable | Description |
|----------|-------------|
| `{{FILENAME}}` | File path or rule name being changed (e.g., `plan-mode.md`) |
| `{{BADGE}}` | Short label shown top-right (e.g., `v3.4.1`, `feat`, `fix`) |
| `{{HUNK_1_HEADER}}` | First hunk header text (e.g., `@@ Workflow §3 @@`) |
| `{{HUNK_1_ROWS}}` | HTML `<tr>` rows for the first hunk — see row format below |
| `{{HUNK_2_HEADER}}` | Second hunk header — omit entire second hunk `<tr>` block if unused |
| `{{HUNK_2_ROWS}}` | HTML `<tr>` rows for the second hunk |
| `{{STAT_ADD}}` | Addition count integer (e.g., `12`) |
| `{{STAT_DEL}}` | Deletion count integer (e.g., `3`) |
| `{{WORKFLOW_SUMMARY}}` | One-line summary shown in the footer stat bar |

### Row format

```html
<tr class="add"><td class="ln">+</td><td class="code">  added line content</td></tr>
<tr class="del"><td class="ln">-</td><td class="code">  removed line content</td></tr>
<tr class="ctx"><td class="ln"> </td><td class="code">  context line</td></tr>
```

Inline highlights inside `<td class="code">`:

```html
<span class="hl-add">added word</span>
<span class="hl-del">removed word</span>
```

---

## feature-card.html

| Variable | Description |
|----------|-------------|
| `{{TITLE}}` | Main headline (e.g., `code-share plugin v0.1.0`) |
| `{{SUBTITLE}}` | Supporting line (e.g., `Now in the agentics marketplace`) |
| `{{BADGE}}` | Short label for top badge and footer (e.g., `New Plugin`) |
| `{{BULLETS}}` | HTML `<li>` elements — one per key feature, no wrapping `<ul>` needed |
| `{{FOOTER_NOTE}}` | Footer left side (e.g., `github.com/shawn-sandy/agentics`) |

### Bullet format

```html
<li>Draft LinkedIn, Twitter/X, and Bluesky copy in one command</li>
<li>Generates styled dark-mode visual cards via Playwright</li>
```

---

## quote-card.html

| Variable | Description |
|----------|-------------|
| `{{CONTEXT}}` | Small tag line at top (e.g., `Developer Insight`, `Claude Code`) |
| `{{QUOTE}}` | The pull quote — no surrounding quotes needed; template adds them |
| `{{ATTRIBUTION}}` | Author or source (e.g., `Shawn Sandy`, `@shawnsandy`) |
