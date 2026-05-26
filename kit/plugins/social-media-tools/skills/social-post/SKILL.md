---
name: code-share
description: "Use when the user wants to create, draft, or generate a social media post (LinkedIn, Twitter/X, Bluesky) with a styled visual card. Also triggers on: 'write a LinkedIn post', 'tweet about this', 'social card for this change', 'post about this release'. Generates platform-aware copy and a dark-mode card image via Playwright screenshot."
version: 0.1.0
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, SendUserFile
---

# Social Post

Draft platform-aware social media copy and generate a styled dark-mode visual card image for LinkedIn, Twitter/X, or Bluesky.

## Quick Reference

| Phase | Action |
|-------|--------|
| 1 — Clarify | Ask for platform/tone if missing |
| 2 — Draft | Write platform-aware copy |
| 3 — Pick template | Heuristic: diff → diff-card, feature → feature-card, insight → quote-card |
| 4 — Populate | Substitute `{{VARIABLES}}` in the chosen template |
| 5 — Screenshot | Serve HTML locally, Playwright screenshot to PNG |
| 6 — Deliver | Present copy in fenced block + attach PNG |

---

## Phase 1 — Clarify

If the user has not supplied **platform**, **content context**, and **tone**, use `AskUserQuestion` to collect them before proceeding. Batch all questions in a single call.

Required inputs:
- **Platform**: LinkedIn, Twitter/X, or Bluesky
- **Content type** (auto-detect first; ask only if ambiguous):
  - Diff / rule change / config update → `diff-card`
  - Release / feature announcement / version bump → `feature-card`
  - Insight / opinion / quote / thought leadership → `quote-card`
- **Tone**: Professional (default for LinkedIn), Casual, Punchy (default for Twitter/X and Bluesky)

If explicit arguments are provided (e.g., `/code-share linkedin diff`), skip this phase entirely.

---

## Phase 2 — Draft Copy

Write platform-aware copy following these rules:

| Platform | Max Length | Style |
|----------|-----------|-------|
| LinkedIn | 1,500 chars | Narrative paragraphs; story arc (hook → insight → CTA); 2–4 hashtags at end |
| Twitter/X | 280 chars | One punchy sentence or a tight two-liner; no hashtag bloat |
| Bluesky | 300 chars | Conversational, same brevity as Twitter |

Present the drafted copy to the user in a fenced code block labeled with the platform name. Do **not** proceed to Phase 3 until the copy is shown.

---

## Phase 3 — Pick Template

Select the card template using the content-type heuristic from Phase 1:

- `diff-card.html` — for code changes, rule updates, config diffs, PR descriptions
- `feature-card.html` — for releases, new features, version announcements, changelogs
- `quote-card.html` — for insights, opinions, pull quotes, thought leadership

### Locate the templates directory

Run the following to find the templates, trying common install locations in order:

```bash
find ~/devbox/agentics/kit/plugins/social-media-tools/templates -name "*.html" 2>/dev/null | head -1 \
  || find ~/.claude -path "*/social-media-tools/templates/*.html" 2>/dev/null | head -1 \
  || find / -path "*/social-media-tools/templates/diff-card.html" 2>/dev/null 2>&1 | head -1
```

Extract the templates directory from the result. If no template is found, write it from the embedded spec in the **Template Specs** section below before continuing.

---

## Phase 4 — Populate Template

Read the chosen template file. Replace every `{{VARIABLE}}` placeholder with content derived from the user's context and the copy drafted in Phase 2. Variable reference for each template:

### diff-card.html variables

| Variable | Description |
|----------|-------------|
| `{{FILENAME}}` | File path or rule name being changed (e.g., `plan-mode.md`) |
| `{{BADGE}}` | Short label shown top-right (e.g., `v3.4.1`, `feat`, `fix`) |
| `{{HUNK_1_HEADER}}` | Hunk header text (e.g., `@@ Workflow §3 @@`) |
| `{{HUNK_1_ROWS}}` | HTML `<tr>` rows — see row format below |
| `{{HUNK_2_HEADER}}` | Second hunk header (omit second hunk block if unused) |
| `{{HUNK_2_ROWS}}` | HTML `<tr>` rows for second hunk |
| `{{STAT_ADD}}` | Addition count integer (e.g., `12`) |
| `{{STAT_DEL}}` | Deletion count integer (e.g., `3`) |
| `{{WORKFLOW_SUMMARY}}` | One-line summary shown in the footer stat bar |

Diff row format (use `add`, `del`, or `ctx` class on `<tr>`):
```html
<tr class="add"><td class="ln">+</td><td class="code">  added line content here</td></tr>
<tr class="del"><td class="ln">-</td><td class="code">  removed line content here</td></tr>
<tr class="ctx"><td class="ln"> </td><td class="code">  context line here</td></tr>
```

Use `<span class="hl-add">text</span>` or `<span class="hl-del">text</span>` inside `<td class="code">` for inline highlights on the specific words that changed.

### feature-card.html variables

| Variable | Description |
|----------|-------------|
| `{{TITLE}}` | Main headline (e.g., `social-media-tools plugin v0.1.0`) |
| `{{SUBTITLE}}` | Supporting line (e.g., `Now in the agentics marketplace`) |
| `{{BADGE}}` | Short label for top badge and footer (e.g., `New Plugin`) |
| `{{BULLETS}}` | HTML `<li>` elements — one per key feature, no wrapping `<ul>` needed |
| `{{FOOTER_NOTE}}` | Footer right side (e.g., `github.com/shawn-sandy/agentics`) |

Bullet format:
```html
<li>Draft LinkedIn, Twitter/X, and Bluesky copy in one command</li>
<li>Generates styled dark-mode visual cards via Playwright</li>
```

### quote-card.html variables

| Variable | Description |
|----------|-------------|
| `{{CONTEXT}}` | Small tag line at top (e.g., `Developer Insight`, `Claude Code`) |
| `{{QUOTE}}` | The pull quote — no surrounding quotes needed, template adds them |
| `{{ATTRIBUTION}}` | Author or source (e.g., `Shawn Sandy`, `@shawnsandy`) |

After substitution, write the populated HTML to:
```
~/.claude/tmp/social-media-tools-card.html
```

Create `~/.claude/tmp/` if it does not exist:
```bash
mkdir -p ~/.claude/tmp
```

---

## Phase 5 — Screenshot

### Step 5a — Find a free port

Locate the plugin scripts directory (same approach as Phase 3, replace `templates` with `scripts`), then run:

```bash
python3 <plugin-dir>/scripts/find_free_port.py
```

Capture the integer printed to stdout as `PORT`.

### Step 5b — Start HTTP server

```bash
cd ~/.claude/tmp && python3 -m http.server PORT &
echo $!
```

Capture the PID.

### Step 5c — Take Playwright screenshot

Load Playwright tools via ToolSearch:
```
select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_wait_for
```

Then:
1. Navigate to `http://localhost:<PORT>/social-media-tools-card.html`
2. Wait for `networkidle` or 2000ms
3. Take a full-page screenshot and write PNG bytes to `~/.claude/tmp/social-media-tools-card.png`

### Step 5d — Kill the server

```bash
kill <PID> 2>/dev/null || true
```

### Step 5e — Fallback

If Playwright MCP tools are unavailable or screenshot fails, notify the user:
> "Screenshot could not be generated. The populated HTML is at `~/.claude/tmp/social-media-tools-card.html` — open it in a browser and screenshot manually."

---

## Phase 6 — Deliver

Present in this exact order:

1. **Platform label** as a markdown heading (e.g., `## LinkedIn Copy`)
2. The copy in a fenced code block
3. Character count: `[NNN / 1500 chars]` — warn inline if over limit
4. If screenshot succeeded: attach `~/.claude/tmp/social-media-tools-card.png` via `SendUserFile`
5. HTML path for reference: `~/.claude/tmp/social-media-tools-card.html`

---

## Template Specs (fallback — write these if templates not found on disk)

If the templates directory cannot be located in Phase 3, write the following files to `~/.claude/tmp/social-media-tools-templates/` and use that path instead.

### diff-card.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>{{FILENAME}}</title>
<style>
:root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--text:#e6edf3;--muted:#8b949e;--add-bg:rgba(46,160,67,.15);--del-bg:rgba(248,81,73,.15);--add-fg:#3fb950;--del-fg:#f85149;--ctx-fg:#8b949e;--hunk-bg:#1c2d3f;--hunk-fg:#79c0ff;--badge-bg:#1f6feb;--badge-fg:#fff;--accent:#388bfd}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,-apple-system,sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:32px}
.card{width:760px;background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,.5)}
.card-header{display:flex;align-items:center;justify-content:space-between;padding:16px 20px;border-bottom:1px solid var(--border);background:var(--bg)}
.filename{font-family:'SF Mono','Fira Code',monospace;font-size:13px;color:var(--text);opacity:.9}
.badge{background:var(--badge-bg);color:var(--badge-fg);font-size:11px;font-weight:600;padding:2px 10px;border-radius:20px;letter-spacing:.3px}
.diff-table{width:100%;border-collapse:collapse;font-family:'SF Mono','Fira Code','Cascadia Code',monospace;font-size:12.5px;line-height:1.6}
.hunk-header{background:var(--hunk-bg);color:var(--hunk-fg);padding:4px 12px;font-size:11px;font-style:italic}
tr.add{background:var(--add-bg)}tr.del{background:var(--del-bg)}tr.ctx{background:transparent}
td.ln{width:20px;padding:0 8px 0 16px;color:var(--muted);user-select:none;font-size:11px}
tr.add td.ln{color:var(--add-fg)}tr.del td.ln{color:var(--del-fg)}
td.code{padding:1px 12px 1px 0;color:var(--text);white-space:pre}
tr.add td.code{color:var(--add-fg)}tr.del td.code{color:var(--del-fg)}tr.ctx td.code{color:var(--ctx-fg)}
.hl-add{background:rgba(46,160,67,.35);border-radius:2px;padding:0 2px}
.hl-del{background:rgba(248,81,73,.35);border-radius:2px;padding:0 2px}
.stat-bar{display:flex;align-items:center;justify-content:space-between;padding:12px 20px;border-top:1px solid var(--border);background:var(--bg)}
.stat-pills{display:flex;gap:8px}
.pill-add{font-size:11px;font-weight:600;padding:2px 10px;border-radius:20px;background:rgba(46,160,67,.15);color:var(--add-fg);border:1px solid rgba(46,160,67,.3)}
.pill-del{font-size:11px;font-weight:600;padding:2px 10px;border-radius:20px;background:rgba(248,81,73,.15);color:var(--del-fg);border:1px solid rgba(248,81,73,.3)}
.summary{font-size:11px;color:var(--muted);font-style:italic}
</style>
</head>
<body>
<div class="card">
  <div class="card-header">
    <span class="filename">{{FILENAME}}</span>
    <span class="badge">{{BADGE}}</span>
  </div>
  <table class="diff-table"><tbody>
    <tr><td colspan="2" class="hunk-header">{{HUNK_1_HEADER}}</td></tr>
    {{HUNK_1_ROWS}}
    <tr><td colspan="2" class="hunk-header">{{HUNK_2_HEADER}}</td></tr>
    {{HUNK_2_ROWS}}
  </tbody></table>
  <div class="stat-bar">
    <div class="stat-pills">
      <span class="pill-add">+{{STAT_ADD}}</span>
      <span class="pill-del">-{{STAT_DEL}}</span>
    </div>
    <span class="summary">{{WORKFLOW_SUMMARY}}</span>
  </div>
</div>
</body>
</html>
```

### feature-card.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>{{TITLE}}</title>
<style>
:root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--text:#e6edf3;--muted:#8b949e;--accent:#388bfd;--badge-bg:#1f6feb;--badge-fg:#fff;--bullet-accent:#3fb950}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,-apple-system,sans-serif;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:32px}
.card{width:680px;background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,.5)}
.card-header{padding:28px 32px 20px;border-bottom:1px solid var(--border);background:linear-gradient(135deg,#161b22 0%,#1c2d3f 100%)}
.badge{display:inline-block;background:var(--badge-bg);color:var(--badge-fg);font-size:11px;font-weight:600;padding:2px 12px;border-radius:20px;margin-bottom:14px;letter-spacing:.4px}
h1{font-size:22px;font-weight:700;color:var(--text);line-height:1.3;margin-bottom:6px}
.subtitle{font-size:14px;color:var(--muted);line-height:1.5}
.bullets{padding:20px 32px;list-style:none;display:flex;flex-direction:column;gap:12px}
.bullets li{display:flex;align-items:flex-start;gap:12px;font-size:14px;color:var(--text);padding:10px 14px;background:rgba(56,139,253,.05);border-left:3px solid var(--bullet-accent);border-radius:0 6px 6px 0;line-height:1.5}
.bullets li::before{content:'→';color:var(--bullet-accent);flex-shrink:0;margin-top:1px;font-weight:600}
.card-footer{display:flex;align-items:center;justify-content:space-between;padding:14px 32px;border-top:1px solid var(--border);background:var(--bg)}
.footer-note{font-size:11px;color:var(--muted)}
.footer-badge{font-size:11px;color:var(--accent);font-weight:500}
</style>
</head>
<body>
<div class="card">
  <div class="card-header">
    <div class="badge">{{BADGE}}</div>
    <h1>{{TITLE}}</h1>
    <p class="subtitle">{{SUBTITLE}}</p>
  </div>
  <ul class="bullets">{{BULLETS}}</ul>
  <div class="card-footer">
    <span class="footer-note">{{FOOTER_NOTE}}</span>
    <span class="footer-badge">{{BADGE}}</span>
  </div>
</div>
</body>
</html>
```

### quote-card.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Quote Card</title>
<style>
:root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--text:#e6edf3;--muted:#8b949e;--accent:#388bfd;--quote-mark:#1f6feb}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,Georgia,serif;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:32px}
.card{width:600px;background:var(--surface);border:1px solid var(--border);border-radius:12px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,.5);text-align:center}
.context-tag{display:inline-block;font-size:11px;text-transform:uppercase;letter-spacing:1.5px;color:var(--accent);padding:16px 32px 0;font-family:'Segoe UI',system-ui,sans-serif;font-weight:600}
.quote-body{padding:32px 48px}
.quote-mark{font-size:72px;line-height:.8;color:var(--quote-mark);opacity:.6;font-family:Georgia,serif;display:block;margin-bottom:8px}
blockquote{font-size:20px;font-weight:400;line-height:1.65;color:var(--text);font-style:italic}
.divider{width:40px;height:2px;background:var(--accent);margin:16px auto;border-radius:1px}
.attribution{padding:0 48px 28px;font-size:13px;color:var(--muted);font-family:'Segoe UI',system-ui,sans-serif}
.attribution::before{content:'— '}
</style>
</head>
<body>
<div class="card">
  <span class="context-tag">{{CONTEXT}}</span>
  <div class="quote-body">
    <span class="quote-mark">"</span>
    <blockquote>{{QUOTE}}</blockquote>
  </div>
  <div class="divider"></div>
  <p class="attribution">{{ATTRIBUTION}}</p>
</div>
</body>
</html>
```
