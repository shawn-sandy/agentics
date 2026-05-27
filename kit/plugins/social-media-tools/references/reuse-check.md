# Reuse Check Reference

Execute this procedure after card type and platform are known but before generating any
new content.

**Required variable** (set by the calling skill before reading this file):

- `$FILE_PREFIX` — the filename type prefix to scan (e.g., `diff`, `feature`, `quote`,
  `snippet`, `video`, `blog`, `project`)

---

## Procedure

```bash
MEDIA_DIR="${PWD}/docs/media/social"
existing=$(ls "$MEDIA_DIR"/${FILE_PREFIX}-*.html 2>/dev/null | sort -r | head -5)
```

If `$existing` is non-empty, show the list and use `AskUserQuestion` to ask:
> "Found existing {FILE_PREFIX} post(s). Reuse one or generate a new one?"
> Options: "Reuse existing" (list filenames) | "Generate new"

If user picks **reuse**:
1. Read the chosen file
2. Extract the post text from every `<textarea class="post-copy-text">…</textarea>` — one
   for a single-site card, three for an All-sites card
3. Present each extracted text in a fenced code block labeled with its preceding `copy-label`
   (platform)
4. Tell the user: "Saved HTML is at `{path}` — open in a browser to view the card and copy
   the post."
5. **STOP.** Do not generate a new card.
