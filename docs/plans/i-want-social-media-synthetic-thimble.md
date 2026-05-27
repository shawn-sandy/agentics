---
status: planned
type: enhancement
plugin: code-share (kit/plugins/social-media-tools)
created: 2026-05-27
---

# Add Persistent HTML Storage and Reuse to code-share

## Context

The `code-share` plugin generates dark-mode HTML cards for social media posts but saves them only to `~/.claude/tmp/` — ephemeral, cleared between sessions. Developers lose generated posts and must rebuild identical content from scratch. There is no library to browse prior work or reuse an existing card.

This plan adds:
1. **Persistent save** to `docs/media/social/` (git-tracked) after each card is generated
2. **Reuse detection** — checks for matching existing posts before generating
3. **Copy button** in saved HTML — a visible "Copy post" panel with clipboard JS
4. **`media-library` skill** — browse, search, and reuse saved posts

## Approach

### 1. Add Copy Panel to All 6 HTML Templates

Append a `.copy-panel` section to the bottom of each template, below the existing visual card. The panel:

- Shows the full social media post text in a `<textarea readonly class="post-copy-text">`
- Has a prominently visible **"Copy post"** button using `navigator.clipboard.writeText()`
- Falls back to `document.execCommand('copy')` for older browsers
- Briefly shows "Copied ✓" for 2 seconds on success

New variable added to every template: **`{{POST_COPY_TEXT}}`**

When screenshotting via Playwright, target only the `.card` element (not the copy panel), keeping the PNG clean:
```
page.locator('.card').screenshot({ path: '...' })
```

Templates to modify (all in `kit/plugins/social-media-tools/templates/`):
- `diff-card.html`
- `feature-card.html`
- `quote-card.html`
- `blog-card.html`
- `snippet-card.html`
- `video-card.html`

Copy panel HTML pattern — **no external libraries, pure native browser APIs** (appended after the `.card` div, before `</body>`):
```html
<div class="copy-panel">
  <p class="copy-label">Social media post</p>
  <textarea readonly class="post-copy-text" id="post-copy">{{POST_COPY_TEXT}}</textarea>
  <button class="copy-btn" onclick="
    var t = document.getElementById('post-copy'), btn = this;
    if (navigator.clipboard) {
      navigator.clipboard.writeText(t.value).then(function() {
        btn.textContent = 'Copied ✓';
        setTimeout(function() { btn.textContent = 'Copy post'; }, 2000);
      });
    } else {
      t.select();
      document.execCommand('copy');
      btn.textContent = 'Copied ✓';
      setTimeout(function() { btn.textContent = 'Copy post'; }, 2000);
    }
  ">Copy post</button>
</div>
```

- `navigator.clipboard.writeText()` — native Clipboard API (all modern browsers, no library needed)
- `document.execCommand('copy')` — native fallback (older browsers, also built-in)
- No clipboard.js, no CDN, no external dependencies

Minimal CSS for the panel (added to each template's `<style>` block):
```css
.copy-panel {
  max-width: 680px; margin: 16px auto 0; padding: 16px;
  background: #161b22; border: 1px solid #30363d; border-radius: 8px;
}
.copy-label { color: #8b949e; font-size: 12px; margin: 0 0 8px; }
.post-copy-text {
  width: 100%; min-height: 80px; background: #0d1117; color: #e6edf3;
  border: 1px solid #30363d; border-radius: 6px; padding: 8px;
  font-family: inherit; font-size: 13px; resize: vertical; box-sizing: border-box;
}
.copy-btn {
  margin-top: 8px; padding: 6px 16px; background: #238636; color: #fff;
  border: none; border-radius: 6px; cursor: pointer; font-size: 13px;
}
.copy-btn:hover { background: #2ea043; }
```

### 2. Add Persistent Save + Reuse Check to Each Skill

Insert two sub-phases into the workflow of each skill, between "Populate template" (Phase 4) and "Screenshot" (Phase 5):

**Phase 4a — Reuse check (run first, before generating):**

At the start of each skill run, before any generation:
```bash
MEDIA_DIR="${PWD}/docs/media/social"
existing=$(ls "$MEDIA_DIR"/{card-type}-*.html 2>/dev/null | sort -r | head -5)
```
If `$existing` is non-empty, show the file list and ask:
> "Found N existing {type} post(s). Reuse one, or generate a new one?"

If user picks "reuse", open the file path and show the `{{POST_COPY_TEXT}}` content extracted from the file. Stop.

**Phase 4b — Persistent save (after populating the template):**

After writing the populated HTML to `~/.claude/tmp/`:
```bash
mkdir -p "${PWD}/docs/media/social"
SLUG=$(echo "$TITLE_OR_FILENAME" | tr '[:upper:]' '[:lower:]' | \
       sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-\|-$//g' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SAVE_PATH="${PWD}/docs/media/social/{card-type}-${SLUG}-${DATE}.html"
# Write the same populated HTML (which already contains {{POST_COPY_TEXT}} filled in)
```

The `POST_COPY_TEXT` value for each skill is the full drafted post copy from Phase 2 (all platform variants joined with `\n---\n` as a separator).

**`{{POST_COPY_TEXT}}` escaping rule:** Place value inside a `<textarea>`, so escape only `<` → `&lt;` and `>` → `&gt;` (NOT `&amp;` first, since textarea content is literal text — this differs from inline HTML injection).

Skills to modify:
- `kit/plugins/social-media-tools/skills/code-share/SKILL.md`
- `kit/plugins/social-media-tools/skills/blog-share/SKILL.md`
- `kit/plugins/social-media-tools/skills/video-share/SKILL.md`
- `kit/plugins/social-media-tools/skills/github-code-share/SKILL.md`

Each skill also surfaces the saved path at the end of its "Deliver" phase:
> "Saved to `docs/media/social/{card-type}-{slug}-{date}.html`"

### 3. Update `scan-for-shares` Skill

`scan-for-shares` builds digest files (`.claude/digests/code-digest-YYYY-MM-DD.md`) listing shareable commits/code. It should be made aware of the media library so that:

1. **Before scoring candidates**, check `docs/media/social/` for files whose slug matches the commit subject or filename. Matching logic: tokenize the commit message → slugify → `grep -l` against filenames in `docs/media/social/`.
2. **In the digest output**, tag already-shared entries with a `[SAVED]` badge and include the file path so developers know not to reshare stale content:
   ```
   - [SAVED: docs/media/social/diff-add-copy-button-2026-05-15.html] feat: add clipboard copy button
   ```
3. **In background mode** (`agent-digest`), auto-skip candidates that already have a saved post (score threshold still applies; SAVED entries are surfaced as "already shared" rather than excluded entirely).

File to modify: `kit/plugins/social-media-tools/skills/scan-for-shares/SKILL.md`

`security-scrub` has no HTML output and needs no changes.

### 4. New `media-library` Skill

Create `kit/plugins/social-media-tools/skills/media-library/SKILL.md`.

**Frontmatter:**
```yaml
name: media-library
description: >
  Browse and reuse saved social media HTML posts from docs/media/social/.
  Use when the user asks to "show saved posts", "browse media library", or "find a post I wrote about".
allowed-tools: Bash, Read
```

**Workflow:**
1. `ls -t "${PWD}/docs/media/social/"*.html 2>/dev/null` — list most-recent-first
2. Parse each filename: `{type}-{slug}-{date}.html` → extract fields
3. Display a markdown table: **Date | Type | Topic | Path**
4. Ask: "Open a file, regenerate a post, or done?"
5. **Open**: Show full `SAVE_PATH` and instruct "Open in browser to view + copy"
6. **Regenerate**: Read `POST_COPY_TEXT` from `<textarea class="post-copy-text">…</textarea>` in the file, display it, and suggest the correct skill invocation

### 4. Update Variable Reference

Add `{{POST_COPY_TEXT}}` documentation to:
`kit/plugins/social-media-tools/skills/code-share/references/variables.md`

```
### POST_COPY_TEXT (all card types)
Type: string
Source: Drafted post copy from Phase 2 — all platform variants joined with "\n---\n"
Escaping: Textarea-safe only — escape < and > but NOT & (unlike inline HTML variables)
Example:
  **LinkedIn**
  Here's what changed in auth.ts — …
  ---
  **Twitter/X**
  Cleaner auth in one refactor → …
```

### 5. Version Bump

In `.claude-plugin/marketplace.json`, bump `code-share` by a **MINOR** version (new skill + new save feature).

Add CHANGELOG entry to `kit/plugins/social-media-tools/CHANGELOG.md`:
```
## vX.Y.Z — 2026-05-27
### Added
- Persistent save to `docs/media/social/` after each card is generated
- Copy panel in all 6 HTML templates with clipboard copy button
- Reuse detection: shows existing posts before generating
- `media-library` skill: browse and reuse saved social media posts
```

## Critical Files

| File | Change |
|------|--------|
| `templates/*.html` (×6) | Add `.copy-panel` section + `{{POST_COPY_TEXT}}` variable |
| `skills/code-share/SKILL.md` | Add Phase 4a/4b; pass `POST_COPY_TEXT`; update screenshot to `.card` selector |
| `skills/blog-share/SKILL.md` | Same as above |
| `skills/video-share/SKILL.md` | Same as above |
| `skills/github-code-share/SKILL.md` | Same as above |
| `skills/scan-for-shares/SKILL.md` | Cross-reference `docs/media/social/`; tag already-saved entries `[SAVED]` |
| `skills/media-library/SKILL.md` | **New file** |
| `skills/code-share/references/variables.md` | Document `POST_COPY_TEXT` |
| `.claude-plugin/marketplace.json` | Bump `code-share` version (MINOR) |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Add version entry |

## Verification

1. Run a sharing skill: "write a LinkedIn post about my latest commit"
2. Confirm `docs/media/social/` is created with a timestamped HTML file
3. Open the HTML in a browser — verify copy panel shows the post text and "Copy post" button is visible
4. Click "Copy post" — clipboard should contain the post text; button shows "Copied ✓"
5. Run the same skill again — reuse detection should surface the prior file and ask whether to reuse
6. Say "show saved posts" or "browse media library" — `media-library` skill should list saved files in a table
7. Verify the PNG screenshot still shows only the card (clean, no copy panel)
8. Commit `docs/media/social/*.html` and confirm it appears in git history (git-tracked)
