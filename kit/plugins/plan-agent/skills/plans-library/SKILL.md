---
name: plans-library
description: "Builds and opens a filterable HTML gallery of all plans in the plans directory. Scans HTML plans, parses metadata, and writes index.html. Use when asked to browse plans or view plan history."
allowed-tools: Bash, Read, Write, ToolSearch, ExitPlanMode
---

# plans-library

Scan every HTML plan in the plans directory, parse each plan's metadata, populate the gallery template, write `index.html`, and open it in the browser.

---

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Resolve the plans directory

Read `plansDirectory` following Claude Code's settings precedence — project-local `.claude/settings.local.json`, then project `.claude/settings.json`, then global `~/.claude/settings.json`; the first that sets it wins. Fall back to `${PWD}/docs/plans` if none do.

```bash
PLANS_DIR=$(python3 - <<'EOF'
import json, os, sys
# Claude settings precedence: project-local → project → user-global
candidates = (
    os.path.join(os.getcwd(), '.claude', 'settings.local.json'),
    os.path.join(os.getcwd(), '.claude', 'settings.json'),
    os.path.join(os.path.expanduser('~'), '.claude', 'settings.json'),
)
for path in candidates:
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

If the directory does not exist, or contains no `.html` files (other than `index.html`) at the top level, tell the user:

> "No HTML plans found in `<PLANS_DIR>`. Run `/plan-agent:implementation-plan` to create your first plan."

**STOP.** (Saved artifacts have their own gallery at `docs/artifacts/`, built by `build-artifacts-index.sh` — they are not part of the plans library.)

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

Collect all `.html` files in `PLANS_DIR`, excluding `index.html`. The `-maxdepth 1` flag prevents recursion into `archive/`, `artifacts/`, or any other subdirectory — saved artifacts have their own gallery (`docs/artifacts/`) and never appear here. Capture the result in `PLAN_FILES`.

```bash
PLAN_FILES=$(find "$PLANS_DIR" -maxdepth 1 -name "*.html" ! -name "index.html" 2>/dev/null | sort)
```

> Do **not** sort by filesystem modification time (`ls -t`). A `git clone`/`checkout` resets every file's mtime to checkout time, so mtime order is meaningless. The gallery's newest-first order is established in Step 4 from each plan's `plan-created` metadata, not from the filesystem.

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
    'effort':  meta('plan-effort', '').lower(),
    'created': meta('plan-created', ''),
    'title':   get_title(),
    # One class="step-card" per step, plus " completed" on each finished one.
    # The lookahead keeps step-card-header out of the total.
    'steps_total': len(re.findall(r'class="step-card(?=[" ])', content)),
    'steps_done':  len(re.findall(r'class="step-card completed"', content)),
}))
EOF
done <<< "$PLAN_FILES"
```

Parse the JSON output with `json.loads()` into a list of entries. **Sort the list newest-first by `created` descending** (compare the `YYYY-MM-DD` strings; entries with an empty `created` sort last, then break ties by `title` ascending). Then, from each entry in sorted order, generate one `<a>` block:

```html
<a class="gallery-card" href="{BASENAME}"
   data-status="{STATUS}" data-type="{TYPE}" data-effort="{EFFORT}" data-month="{MONTH}" data-title="{TITLE_LOWER}" data-steps-done="{STEPS_DONE}" data-steps-total="{STEPS_TOTAL}">
  <span class="glyph" aria-hidden="true">{GLYPH}</span><span class="sr-only">{STATUS_DISPLAY}</span>
  <span class="r-title">{TITLE}</span>
  <span class="r-meta">{TYPE}{EFFORT_TEXT}{PROTO_TEXT}</span>
  <span class="r-date">{CREATED}</span>
  <span class="r-steps">{STEPS_DONE} / {STEPS_TOTAL} steps</span>   <!-- in-progress plans with steps ONLY; omit this line entirely otherwise -->
</a>
```

Three constraints on this markup come from `scripts/merge-plans-index.mjs`, the merge driver for the generated index: keep `<a class="gallery-card"` as the leading attribute pair with nothing else in that class attribute, emit no nested `<a>`, and wrap the rows in no `<li>` or container of any kind. The driver splices over everything between the first and last card, so anything sitting between them is destroyed by the first concurrent merge.

Where:
- `{BASENAME}` = filename without path (e.g. `add-dark-mode-toggle.html`), used directly as the link target
- `{STATUS}` = `plan-status` value, lowercased (e.g. `todo`, `in-progress`, `completed`)
- `{STATUS_DISPLAY}` = `{STATUS}` with hyphens replaced by spaces (e.g. `in progress`); `unstatused` when empty. This is the visually-hidden text that carries the status the glyph shows visually — never drop it, and never replace it with an `aria-label` on the anchor, which would override the row's own visible text
- `{GLYPH}` = `&#10003;` when `{STATUS}` is `completed`, `&#9675;` otherwise
- `{MONTH}` = first 7 characters of `{CREATED}` (`YYYY-MM`), or `""` — the gallery script builds month headings from it at load time
- `{TYPE}` = `plan-type` value, lowercased (e.g. `feature`, `fix`)
- `{EFFORT}` = `plan-effort` value, lowercased (`low` | `medium` | `high`). When empty (no `plan-effort` tag), set `data-effort=""` — a no-effort plan passes every effort filter
- `{EFFORT_TEXT}` = `" &middot; <span class=\"hi\">high</span>"` when `{EFFORT}` is `high`, `" &middot; {EFFORT}"` for any other non-empty effort, and `""` when empty
- `{PROTO_TEXT}` = `" &middot; <span class=\"proto-chip\">proto</span>"` when the plan carries a `plan-prototype` meta tag, `""` otherwise. A span, never an `<a>` — the row is already one anchor
- `{TITLE_LOWER}` = title lowercased (used by search filter)
- `{TITLE}` = title text (strip a leading `"Plan: "` prefix if present)
- `{CREATED}` = `plan-created` value (e.g. `2026-05-30`); emit an empty `<span class="r-date">` if absent so the row keeps its columns
- `{STEPS_TOTAL}` / `{STEPS_DONE}` = number of `class="step-card"` and `class="step-card completed"` occurrences in the plan's own HTML. Match `class="step-card` followed by a quote or a space so `step-card-header` is not counted as a step. Emit the whole `<span class="r-steps">` line **only** when `{STATUS}` is `in-progress` and `{STEPS_TOTAL}` is non-zero; the gallery script draws the progress bar beside this text from the two data attributes, and the text itself is what survives with JavaScript off

**HTML-escape** all values before inserting: replace `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&#39;`.

---

## Step 5 — Populate and write the gallery

1. **Get the current timestamp:**

```bash
GENERATED_AT=$(date '+%Y-%m-%d %H:%M')
```

2. **Read the gallery template** from `$TEMPLATES_DIR/plans-gallery.html`.

3. **Substitute** in the template:
   - `{{GALLERY_TITLE}}` → `Plans` (the shared template also serves the Artifacts gallery, which substitutes `Artifacts`)
   - `{{GALLERY_SUB}}` → `&mdash; in flight first, then newest. Search matches titles.`
   - `{{GALLERY_ENTRIES}}` → concatenated `<a>` blocks from Step 4
   - `{{PLAN_COUNT}}` → total number of plan cards rendered
   - `{{GENERATED_AT}}` → value of `$GENERATED_AT`
   - `{{HREF_HOME}}`, `{{HREF_PLANS}}`, `{{HREF_PROTOTYPES}}`, `{{HREF_ARTIFACTS}}`, `{{HREF_SOCIAL}}` → each tab's target index, relative to `$PLANS_DIR` (the directory this index is written to). With the default layout that is `../index.html`, `index.html`, `../prototypes/index.html`, `../artifacts/index.html`, and `../media/social/index.html` — compute them rather than hard-coding, since `plansDirectory` is configurable and the depth moves with it
   - `{{COUNT_PLANS}}`, `{{COUNT_PROTOTYPES}}`, `{{COUNT_ARTIFACTS}}`, `{{COUNT_SOCIAL}}` → the number of `*.html` files other than `index.html` in `$PLANS_DIR`, `docs/prototypes`, `docs/artifacts`, and `docs/media/social`. `{{COUNT_PLANS}}` is the number of cards this run actually rendered. Count them on disk rather than reading the sibling `index.html` files — the four galleries are generated independently and any of them may be stale. A missing directory counts 0
   - `{{CUR_PLANS}}` → `aria-current="page"`; `{{CUR_HOME}}`, `{{CUR_PROTOTYPES}}`, `{{CUR_ARTIFACTS}}`, `{{CUR_SOCIAL}}` → the empty string. Exactly one tab is marked current

4. **Write** the result to `$PLANS_DIR/index.html`.

---

## Step 6 — Verify the index

Confirm the written index is complete and renders one card per plan that Step 4 actually parsed.

Set `SOURCE_COUNT` to the number of entries Step 4 emitted — **not** the raw line count of `$PLAN_FILES`. Step 4 skips any plan it cannot read, so comparing against the raw file list reports a mismatch for a file that was deliberately skipped. If Step 4 skipped anything, name those files when reporting.

```bash
SOURCE_COUNT=<number of entries parsed in Step 4>
python3 - "$PLANS_DIR/index.html" "$SOURCE_COUNT" <<'EOF'
import sys
from html.parser import HTMLParser

path, expected = sys.argv[1], int(sys.argv[2])
html = open(path, encoding='utf-8').read()

class Counter(HTMLParser):
    cards = 0
    def handle_starttag(self, tag, attrs):
        if tag == 'a' and 'gallery-card' in dict(attrs).get('class', '').split():
            self.cards += 1

c = Counter()
c.feed(html)
if not html.rstrip().endswith('</html>'):
    sys.exit(f"TRUNCATED: {path} does not end with </html>")
print(f"OK: {c.cards} cards from {expected} plans" if c.cards == expected
      else f"MISMATCH: index has {c.cards} cards but {expected} plans were parsed")
sys.exit(0 if c.cards == expected else 1)
EOF
```

If the command exits non-zero, report the failure to the user — naming the index path, the card count, the parsed count, and any plans Step 4 skipped — and **STOP** instead of opening the gallery.

---

## Step 7 — Open in browser

```bash
GALLERY_PATH=$(realpath "$PLANS_DIR/index.html" 2>/dev/null || echo "$PLANS_DIR/index.html")
open "$GALLERY_PATH" 2>/dev/null || xdg-open "$GALLERY_PATH" 2>/dev/null || true
```

Tell the user:
> "Plans library generated at `<PLANS_DIR>/index.html` with {count} plans — opened in your browser. Click any card to open it."

---

## Step 8 — Stop

**STOP.** Do not run git commands or invoke other skills after delivering the gallery.
