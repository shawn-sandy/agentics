# Rendering Pipeline Reference

Execute this procedure after the Persistent Save section of `saving-and-delivery.md`
(which sets `$SAVE_PATH_PNG`).

**Required variables** (set by the calling skill before reading this file):

- `$PLUGIN_DIR` — plugin root (set in Phase 0: Locate plugin assets)
- `$TEMP_HTML` — basename of the card HTML in `~/.claude/tmp/` (e.g., `code-share-card.html`)
- `$SAVE_PATH_PNG` — absolute path for the screenshot output (set by saving-and-delivery.md)

---

## Step 1 — Get a free port

```bash
python3 "$PLUGIN_DIR/scripts/find_free_port.py"
```

Capture the printed integer as `$PORT`.

## Step 2 — Start HTTP server

Run as a single compound command so `$!` is in scope:

```bash
cd ~/.claude/tmp && python3 -m http.server $PORT & SERVER_PID=$!; echo "PID:$SERVER_PID"
```

Parse the `PID:N` line to capture `SERVER_PID`.

## Step 3 — Playwright screenshot

Load tools via ToolSearch:
```
select:mcp__plugin_playwright_playwright__browser_resize,mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_wait_for,mcp__plugin_playwright_playwright__browser_snapshot
```

Then:
1. Resize the viewport to at least 1280×900 with `browser_resize` before navigating — card templates use `min(1024px, 100%)` so they need the viewport to be at least 1024px wide to render at full width.
2. Navigate to `http://localhost:$PORT/$TEMP_HTML`
3. Wait for `networkidle` or 2000ms
4. Call `browser_snapshot` to verify the page is fully rendered and to collect DOM element references. Look for a `ref` matching the `.card` element and capture it as `$CARD_REF` if the snapshot returns one. Note: card templates use a plain `<div class="card">` with no semantic role, so the snapshot may not expose a named ref for it.
5. Call `browser_take_screenshot` with `filename: $SAVE_PATH_PNG` and one of:
   - `target: $CARD_REF` (the ref from step 4) if the snapshot returned a ref for the card element, **or**
   - `target: ".card"` (CSS selector) if no ref was found.
   
   Do **not** pass `fullPage: true` — that overrides element targeting and captures the entire page.

**Why the snapshot step is required:** `browser_take_screenshot`'s `target` accepts either an element `ref` from a prior `browser_snapshot` or a CSS selector. CSS selector-only targeting is unreliable without a prior snapshot — the tool may fall back to a full-viewport capture if the element is not yet fully rendered and bound in the DOM. The `browser_snapshot` step ensures the page is loaded before capture, regardless of whether you use the returned ref or a CSS selector for `target`.

## Step 4 — Kill server

```bash
kill $SERVER_PID 2>/dev/null || true
```

## Step 5 — Verify screenshot output

Confirm the capture actually produced a real image before Phase 6 (Deliver)
treats the card as done — a blank or truncated PNG still counts as a
successful tool call.

```bash
SIZE=$(wc -c < "$SAVE_PATH_PNG" 2>/dev/null | tr -d ' ')
```

- File missing, or `$SIZE` empty or `0` → capture failed outright. Go to **Fallback**.
- `$SIZE` below `5000` (5KB) → likely blank or empty. A solid-color capture
  compresses to a few KB; a populated card with text and a gradient does not.
  Go to **Fallback**.
  <!-- ponytail: byte-count heuristic, not pixel inspection — a legitimately
  sparse card could trip this. Raise the threshold or sample actual pixels if
  false positives show up. -->
- Otherwise → proceed to Phase 6.

## Fallback

If Playwright tools are unavailable, the screenshot fails, or Step 5's
verification fails, tell the user:
> "Screenshot could not be generated. The populated HTML is at `~/.claude/tmp/$TEMP_HTML` — open it in a browser to screenshot manually."
