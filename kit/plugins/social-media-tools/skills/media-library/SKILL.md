---
name: media-library
description: "Builds and opens a filterable HTML gallery of saved social cards. Scans docs/media/social/ and generates a filterable index page. Use when asked to browse the media library or view saved posts."
allowed-tools: Bash, Read, Write, AskUserQuestion, ToolSearch, ExitPlanMode
---

# media-library

Generate an interactive HTML page listing all saved social media posts, then open it in the browser.

## Overview

Every card-generating skill saves populated HTML to `docs/media/social/`. This skill scans that directory, builds a filterable HTML page with clickable links to every card, and opens it in the browser.

---

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Scan for saved posts

```bash
MEDIA_DIR="${PWD}/docs/media/social"
# Newest-first by the trailing -YYYY-MM-DD in each filename, NOT by mtime.
# (git checkout resets mtimes, so `ls -t` order is meaningless.)
MEDIA_FILES=$(find "$MEDIA_DIR" -maxdepth 1 -name "*.html" ! -name "index.html" 2>/dev/null \
  | sed -E 's/.*-([0-9]{4}-[0-9]{2}-[0-9]{2})\.html$/\1\t&/' \
  | sort -rk1,1 | cut -f2-)
```

If `docs/media/social/` does not exist or contains no `.html` files, tell the user:
> "No saved posts found in `docs/media/social/`. Run a sharing skill to generate your first post."

**STOP.**

---

## Step 2 — Locate plugin assets

Find the `templates/` directory to derive `$PLUGIN_DIR`:

```bash
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find "$PWD" -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Derive:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
```

If no directory is found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Step 3 — Build the HTML page

1. **Read the gallery template** from `$PLUGIN_DIR/templates/gallery.html`.

2. **Build `{{GALLERY_ENTRIES}}`** — for each card file (most recent first), parse the filename
   (`{type}-{slug}-{YYYY-MM-DD}.html`) and generate one card entry:

   ```html
   <div class="gallery-card-wrap">
   <a class="gallery-card" href="{BASENAME}" data-type="{TYPE}" data-topic="{TOPIC}">
     <div class="thumb-container">
       <img src="{BASENAME_PNG}" alt="{TOPIC}" onerror="showFallback(this)">
       <span class="thumb-fallback" style="display:none">{TYPE}</span>
     </div>
     <div class="card-info">
       <div class="card-info-top">
         <span class="type-badge type-{TYPE}">{TYPE}</span>
         <span class="card-date">{DATE}</span>
       </div>
       <span class="card-topic">{TOPIC}</span>
       <span class="card-file">{BASENAME}</span>
     </div>
   </a>
   <button type="button" class="open-img-link" data-img="{BASENAME_PNG}" data-topic="{TOPIC}" aria-label="View image: {TOPIC}">View image</button>
   </div>
   ```

   Only include the `.open-img-link` button when a matching `.png` file exists alongside the `.html` card (test with `-f "$MEDIA_DIR/${BASENAME_PNG}"`). Omit the button element entirely for cards without a screenshot to avoid dead controls.

   Where:
   - `{BASENAME}` = filename without path (e.g., `diff-add-copy-button-2026-05-27.html`)
   - `{BASENAME_PNG}` = same with `.png` extension
   - `{TYPE}` = first segment of filename (e.g., `diff`, `feature`, `blog`)
   - `{TOPIC}` = middle segments with hyphens replaced by spaces, title-cased (e.g., "Add Copy Button")
   - `{DATE}` = last segment before `.html` (e.g., `2026-05-27`)

3. **Substitute variables** in the template:
   - `{{GALLERY_ENTRIES}}` → the concatenated `<a>` blocks
   - `{{CARD_COUNT}}` → total number of cards
   - `{{GENERATED_AT}}` → current date and time (e.g., `2026-05-27 14:30`)
   - `{{HREF_HOME}}`, `{{HREF_PLANS}}`, `{{HREF_PROTOTYPES}}`, `{{HREF_ARTIFACTS}}`, `{{HREF_SOCIAL}}` → each tab's target index, relative to `docs/media/social/` (this gallery's own output directory): `../../index.html`, `../../plans/index.html`, `../../prototypes/index.html`, `../../artifacts/index.html`, and `index.html`. If the project sets `plansDirectory` to something other than `docs/plans`, point the Plans tab at that directory's `index.html` instead — the other three collections are fixed
   - `{{COUNT_PLANS}}`, `{{COUNT_PROTOTYPES}}`, `{{COUNT_ARTIFACTS}}`, `{{COUNT_SOCIAL}}` → the number of `*.html` files other than `index.html` in the plans directory (the resolved `plansDirectory`, default `docs/plans`), `docs/prototypes`, `docs/artifacts`, and `docs/media/social`. Count them on disk rather than reading the sibling `index.html` files — the four galleries are generated independently and any of them may be stale. A missing directory counts 0
   - `{{CUR_SOCIAL}}` → `aria-current="page"`; `{{CUR_HOME}}`, `{{CUR_PLANS}}`, `{{CUR_PROTOTYPES}}`, `{{CUR_ARTIFACTS}}` → the empty string. Exactly one tab is marked current

   The href, count, and current-tab groups feed the topbar this gallery shares with the plan-agent galleries. Leaving a `{{...}}` placeholder unsubstituted renders it as literal text in the nav.

4. **Write** the populated HTML to `docs/media/social/index.html`.

---

## Step 4 — Verify the index

Confirm the written index is complete and renders one card per file that Step 2 actually parsed.

Set `SOURCE_COUNT` to the number of cards Step 2 emitted — **not** the raw line count of `$MEDIA_FILES` — so a file that was deliberately skipped is not reported as a missing card.

```bash
SOURCE_COUNT=<number of cards emitted in Step 2>
python3 - "$MEDIA_DIR/index.html" "$SOURCE_COUNT" <<'EOF'
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
print(f"OK: {c.cards} cards from {expected} files" if c.cards == expected
      else f"MISMATCH: index has {c.cards} cards but {expected} files were parsed")
sys.exit(0 if c.cards == expected else 1)
EOF
```

If the command exits non-zero, report the failure to the user — naming the index path, the card count, and the parsed count — and **STOP** instead of opening the gallery.

---

## Step 5 — Open in browser

```bash
GALLERY_PATH=$(realpath "docs/media/social/index.html" 2>/dev/null || echo "${PWD}/docs/media/social/index.html")
open "$GALLERY_PATH" 2>/dev/null || xdg-open "$GALLERY_PATH" 2>/dev/null || true
```

Tell the user: "Media library generated at `docs/media/social/index.html` with {count} cards — opened in your browser. Click any card to view it."

---

## Step 6 — Optional follow-up

If the user asks to view copy text from a specific card after seeing the library:

1. `Read` the chosen HTML file
2. Extract the text content of every `<textarea class="post-copy-text">…</textarea>`, noting each one's preceding `<p class="copy-label">` label
3. Present each in its own fenced code block, headed by its platform label:

````
**[platform label]**
```
[extracted post copy text]
```
````

4. Tell the user which skill generated it (inferred from card type):
   - `diff`, `feature`, `quote` → `share-code`
   - `blog` → `share-blog`
   - `video` → `share-video`
   - `snippet` → `share-github`
   - `project` → `share-project`
   - `session` → `share-session`

---

## Step 7 — Stop

**STOP.** Do not invoke any other skills or run git commands after delivering.
