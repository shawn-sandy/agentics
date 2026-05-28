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
select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_wait_for
```

Then:
1. Navigate to `http://localhost:$PORT/$TEMP_HTML`
2. Wait for `networkidle` or 2000ms
3. Call `browser_take_screenshot` with `path: $SAVE_PATH_PNG` and `selector: ".card"` to capture only the card element and write directly to disk

## Step 4 — Kill server

```bash
kill $SERVER_PID 2>/dev/null || true
```

## Fallback

If Playwright tools are unavailable or the screenshot fails, tell the user:
> "Screenshot could not be generated. The populated HTML is at `~/.claude/tmp/$TEMP_HTML` — open it in a browser to screenshot manually."
