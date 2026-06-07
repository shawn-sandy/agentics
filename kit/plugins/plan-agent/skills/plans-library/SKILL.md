---
name: plans-library
description: "Builds and opens a filterable HTML gallery of all plans in the plans directory. Scans HTML plans, parses metadata, and writes index.html. Use when asked to browse plans or view plan history."
allowed-tools: Bash, Read, Write, ToolSearch, ExitPlanMode
---

# plans-library

Scan every HTML plan in the plans directory, parse each plan's metadata, populate the gallery template, write `index.html`, and open it in the browser.

---

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Step 1 — Resolve the plans directory

Read `plansDirectory` from `.claude/settings.json` (project first, then global `~/.claude/settings.json`). Fall back to `${PWD}/docs/plans` if neither file sets it.

```bash
PLANS_DIR=$(python3 - <<'EOF'
import json, os, sys
project = os.path.join(os.getcwd(), '.claude', 'settings.json')
global_ = os.path.join(os.path.expanduser('~'), '.claude', 'settings.json')
for path in (project, global_):
    try:
        v = json.load(open(path)).get('plansDirectory', '').strip()
        if v:
            print(v); sys.exit(0)
    except Exception:
        pass
print(os.path.join(os.getcwd(), 'docs', 'plans'))
EOF
)
```

If the directory does not exist or contains no `.html` files (other than `index.html`), tell the user:

> "No HTML plans found in `<PLANS_DIR>`. Run `/plan-agent:implementation-plan` to create your first plan."

**STOP.**

---

## Step 2 — Locate plugin templates directory

The plugin may be installed as a versioned cached copy (e.g. `…/plan-agent/0.11.0/templates`) or loaded directly (e.g. `…/plan-agent/templates`). Both patterns must be tried:

```bash
TEMPLATES_DIR=$( { \
  find ~/.claude/plugins -path "*/plan-agent/*/templates" -type d 2>/dev/null | sort -rV; \
  find ~/.claude/plugins -path "*/plan-agent/templates"   -type d 2>/dev/null; \
  find "$PWD"            -path "*/plan-agent/templates"   -type d 2>/dev/null; \
} | head -1 )
```

If `TEMPLATES_DIR` is empty, output:
"Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Step 3 — Scan plan files

Collect all `.html` files in `PLANS_DIR`, excluding `index.html`. The `-maxdepth 1` flag prevents recursion into `archive/` or any other subdirectory. Sort newest-modified first and capture the result in `PLAN_FILES`.

```bash
PLAN_FILES=$(find "$PLANS_DIR" -maxdepth 1 -name "*.html" ! -name "index.html" -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null)
```

---

## Step 4 — Build `{{GALLERY_ENTRIES}}`

Iterate over each file `$f` from `$PLAN_FILES` (one path per line). For each, parse its metadata using Python 3. Output is JSON to safely handle titles that contain `|` or other special characters:

```bash
while IFS= read -r f; do
python3 - "$f" <<'EOF'
import re, sys, os, json

f = sys.argv[1]
try:
    content = open(f, encoding='utf-8', errors='replace').read()
except Exception:
    sys.exit(0)

def meta(name, fallback=''):
    m = re.search(r'<meta\s+name="' + name + r'"\s+content="([^"]*)"', content)
    return m.group(1).strip() if m else fallback

def get_title():
    m = re.search(r'<title>(?:Plan:\s*)?([^<]+)</title>', content, re.I)
    return m.group(1).strip() if m else os.path.basename(f)

print(json.dumps({
    'status':  meta('plan-status', 'todo'),
    'type':    meta('plan-type',   'untyped'),
    'created': meta('plan-created', ''),
    'title':   get_title(),
}))
EOF
done <<< "$PLAN_FILES"
```

Parse the JSON output with `json.loads()`. From each result, generate one `<a>` block:

```html
<a class="gallery-card" href="{BASENAME}"
   data-status="{STATUS}" data-type="{TYPE}" data-title="{TITLE_LOWER}">
  <div class="card-badges">
    <span class="status-chip status-{STATUS}">{STATUS_DISPLAY}</span>
    <span class="type-chip type-{TYPE}">{TYPE}</span>
  </div>
  <div class="card-title">{TITLE}</div>
  <div class="card-meta">
    <span class="card-date">{CREATED}</span>
    <span class="card-file">{BASENAME}</span>
  </div>
</a>
```

Where:
- `{BASENAME}` = filename without path (e.g. `add-dark-mode-toggle.html`)
- `{STATUS}` = `plan-status` value, lowercased (e.g. `todo`, `in-progress`, `completed`)
- `{STATUS_DISPLAY}` = `{STATUS}` with hyphens replaced by spaces (e.g. `in progress`)
- `{TYPE}` = `plan-type` value, lowercased (e.g. `feature`, `fix`)
- `{TITLE_LOWER}` = title lowercased (used by search filter)
- `{TITLE}` = title text (strip a leading `"Plan: "` prefix if present)
- `{CREATED}` = `plan-created` value (e.g. `2026-05-30`); omit the `<span class="card-date">` if empty

**HTML-escape** all values before inserting: replace `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&#39;`.

---

## Step 5 — Populate and write the gallery

1. **Get the current timestamp:**

```bash
GENERATED_AT=$(date '+%Y-%m-%d %H:%M')
```

2. **Read the gallery template** from `$TEMPLATES_DIR/plans-gallery.html`.

3. **Substitute** in the template:
   - `{{GALLERY_ENTRIES}}` → concatenated `<a>` blocks from Step 4
   - `{{PLAN_COUNT}}` → total number of plans found
   - `{{GENERATED_AT}}` → value of `$GENERATED_AT`

4. **Write** the result to `$PLANS_DIR/index.html`.

---

## Step 6 — Open in browser

```bash
GALLERY_PATH=$(realpath "$PLANS_DIR/index.html" 2>/dev/null || echo "$PLANS_DIR/index.html")
open "$GALLERY_PATH" 2>/dev/null || xdg-open "$GALLERY_PATH" 2>/dev/null || true
```

Tell the user:
> "Plans library generated at `<PLANS_DIR>/index.html` with {count} plans — opened in your browser. Click any card to open that plan."

---

## Step 7 — Stop

**STOP.** Do not run git commands or invoke other skills after delivering the gallery.
