# Saving and Delivery Reference

This file covers two phases used by every card-generating skill.

**Required variables** (set by the calling skill):

*For Persistent Save:*
- `$FILE_PREFIX` — filename type prefix (e.g., `diff`, `snippet`, `video`, `blog`, `project`)
- `$SLUG_INPUT` — primary subject string to slugify (e.g., `$PRIMARY_SUBJECT`, `$FILENAME`, `$VIDEO_TITLE`)
- `$TEMP_HTML` — basename of the card HTML in `~/.claude/tmp/` (used in fallback path message)

*For Deliver (set by Persistent Save below):*
- `$SAVE_PATH` — absolute path to the saved HTML
- `$SAVE_PATH_PNG` — absolute path to the saved PNG (derived from `$SAVE_PATH`)
- `$PLATFORM` — selected platform (for the heading; `All sites` uses a combined heading)

---

## Persistent Save

After writing the populated HTML to `~/.claude/tmp/`, save the same HTML to
`docs/media/social/` and derive the PNG path:

```bash
MEDIA_DIR="${PWD}/docs/media/social"
mkdir -p "$MEDIA_DIR"

SLUG=$(echo "$SLUG_INPUT" | tr '[:upper:]' '[:lower:]' | \
       sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SAVE_PATH="$MEDIA_DIR/${FILE_PREFIX}-${SLUG}-${DATE}.html"
SAVE_PATH_PNG="${SAVE_PATH%.html}.png"
# Write the same populated HTML to $SAVE_PATH using the Write tool
```

The saved HTML is identical to the `~/.claude/tmp/` version — it includes the copy panel
with the full post text. `$SAVE_PATH` and `$SAVE_PATH_PNG` are now set for the rendering
pipeline and deliver phases.

---

## Deliver

Execute after the rendering pipeline completes:

1. **Platform label** as a markdown heading (e.g., `## LinkedIn Copy`). For **All sites**,
   use `## Copy — all sites` with three labeled sub-blocks (LinkedIn, Twitter/X, Bluesky).
2. Copy in a fenced code block — one block per platform for All sites.
3. Character count `[NNN / max chars]` per block — warn if over limit (1,500 / 280 / 300).
4. Attach `$SAVE_PATH_PNG` via `SendUserFile` (if screenshot succeeded).
5. Saved HTML path: `$SAVE_PATH`

**STOP.** Do not run further git commands, open browsers, or take any action beyond
delivering the copy and card image.
