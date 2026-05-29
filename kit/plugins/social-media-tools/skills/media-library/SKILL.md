---
name: media-library
description: "Browses saved social media cards and generates a visual gallery page. Lists cards by type and date for copy reuse. Use when the user asks to browse the media library, view shares, or open the gallery."
allowed-tools: Bash, Read, Write, AskUserQuestion, ToolSearch, ExitPlanMode
---

# media-library

Browse, search, and reuse saved social media posts from `docs/media/social/`.

## Overview

Every time a card-generating skill runs (share-code, share-blog, share-video, share-github), it saves the populated HTML — including the post copy — to `docs/media/social/`. This skill lets developers:
1. See what posts have already been created
2. Retrieve the copy text for reposting
3. Know which tool to use to regenerate or update a card

---

## Exit plan mode

`ExitPlanMode` is a deferred tool whose schema must be loaded before it can be called.
Use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`. Both steps
happen silently with no user-visible output. This is a no-op when plan mode is already off.

---

## Step 1 — List saved posts

```bash
MEDIA_DIR="${PWD}/docs/media/social"
MEDIA_FILES=$(ls -t "$MEDIA_DIR"/*.html 2>/dev/null | grep -v '/index\.html$')
```

If `docs/media/social/` does not exist or contains no `.html` files, tell the user:
> "No saved posts found in `docs/media/social/`. Run a sharing skill to generate your first post."

**STOP.**

---

## Step 2 — Parse and display

For each HTML file path (e.g., `docs/media/social/diff-add-copy-button-2026-05-27.html`), parse the filename:

```
{type}-{slug}-{YYYY-MM-DD}.html
```

| Field | Example |
|-------|---------|
| Type | `diff`, `feature`, `quote`, `blog`, `snippet`, `video`, `project`, `session` |
| Topic | `add-copy-button` (slug, replace hyphens with spaces) |
| Date | `2026-05-27` |

Display as a markdown table (most recent first, max 20 rows):

```
| # | Date       | Type     | Topic                      | File |
|---|------------|----------|----------------------------|------|
| 1 | 2026-05-27 | diff     | add copy button            | docs/media/social/diff-add-copy-button-2026-05-27.html |
| 2 | 2026-05-26 | feature  | v0-3-0 release             | docs/media/social/feature-v0-3-0-release-2026-05-26.html |
```

---

## Step 3 — Interactive action *(Interactive mode only)*

Use `AskUserQuestion` to ask what the user wants to do:

> "What would you like to do with these saved posts?"
>
> Options:
> - **View a post** — Show the post copy text from a saved file
> - **Open in browser** — Show the file path to open manually
> - **View gallery** — Generate a visual gallery page and open it
> - **Done** — No action needed

### View a post

Ask the user which number they want (or accept a filename). Then:

1. `Read` the chosen HTML file
2. Extract the text content of every `<textarea class="post-copy-text">…</textarea>` — one for a single-site card, three for an All-sites card — noting each one's preceding `<p class="copy-label">` label
3. Present each in its own fenced code block, headed by its platform label:

````
**[platform label]**
```
[extracted post copy text]
```
````

4. Tell the user which skill was used to generate it (inferred from card type in filename):
   - `diff`, `feature`, `quote` → `share-code`
   - `blog` → `share-blog`
   - `video` → `share-video`
   - `snippet` → `share-github`
   - `project` → `share-project`
   - `session` → `share-session`

### Open in browser

Resolve the absolute path and open it in the user's default browser:

```bash
ABS_PATH=$(realpath "docs/media/social/{filename}.html" 2>/dev/null || echo "${PWD}/docs/media/social/{filename}.html")
open "$ABS_PATH" 2>/dev/null || xdg-open "$ABS_PATH" 2>/dev/null || true
```

Tell the user: "Opened `{abs_path}` in your browser."

### View gallery

Generate a visual HTML gallery page from the saved cards:

1. **Locate plugin assets** — find `templates/` directory to derive `$PLUGIN_DIR`:
   ```bash
   TEMPLATES_DIR=$(find "$PWD" -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1)
   PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
   ```

2. **List card files** — collect all `.html` files in `docs/media/social/` excluding `index.html`:
   ```bash
   MEDIA_DIR="${PWD}/docs/media/social"
   CARD_FILES=$(ls -t "$MEDIA_DIR"/*.html 2>/dev/null | grep -v '/index\.html$')
   ```

3. **Read the gallery template** from `$PLUGIN_DIR/templates/gallery.html`.

4. **Build `{{GALLERY_ENTRIES}}`** — for each card file (most recent first), parse the filename
   (`{type}-{slug}-{YYYY-MM-DD}.html`) and generate one `<a>` block:

   ```html
   <a class="gallery-card" href="{BASENAME}">
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
     </div>
   </a>
   ```

   Where:
   - `{BASENAME}` = filename without path (e.g., `diff-add-copy-button-2026-05-27.html`)
   - `{BASENAME_PNG}` = same with `.png` extension
   - `{TYPE}` = first segment of filename (e.g., `diff`, `feature`, `blog`)
   - `{TOPIC}` = middle segments with hyphens replaced by spaces, title-cased (e.g., "Add Copy Button")
   - `{DATE}` = last segment before `.html` (e.g., `2026-05-27`)

5. **Substitute variables** in the template:
   - `{{GALLERY_ENTRIES}}` → the concatenated `<a>` blocks
   - `{{CARD_COUNT}}` → total number of cards
   - `{{GENERATED_AT}}` → current date and time (e.g., `2026-05-27 14:30`)

6. **Write** the populated HTML to `docs/media/social/index.html`.

7. **Open** in the user's default browser:
   ```bash
   GALLERY_PATH=$(realpath "docs/media/social/index.html" 2>/dev/null || echo "${PWD}/docs/media/social/index.html")
   open "$GALLERY_PATH" 2>/dev/null || xdg-open "$GALLERY_PATH" 2>/dev/null || true
   ```

8. Tell the user: "Gallery generated at `docs/media/social/index.html` with {count} cards."

---

## Step 4 — Stop

**STOP.** Do not invoke any other skills or run git commands after delivering.
