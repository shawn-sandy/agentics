# Non-interactive Mode Reference

When `$ARGUMENTS` contains `--background`, skip all user interaction and run unattended.
Read this reference at the start of any phase that would otherwise call `AskUserQuestion`
or pause for copy approval.

---

## Flags

All flags use `--flag=value` equals-form to survive URL and path tokenization.

| Flag | Values | Notes |
|------|--------|-------|
| `--background` | (presence) | Master switch; activates this mode |
| `--platform=<v>` | `linkedin` \| `twitter` \| `bluesky` \| `all` | Default: `all` |
| `--tone=<v>` | `professional` \| `casual` \| `punchy` \| `conversational` | Optional; omit for `all` |
| `--source=<v>` | URL or absolute path | Required for `share-blog`, `share-github`, `share-video` |
| `--objective=<text>` | Free text | Used by `share-selection`; inferred if absent |
| `--code-file=<path>` | Absolute path under `~/.claude/tmp/` | Required for `share-selection` |

---

## Skip Rules

Apply every rule when `--background` is present.

1. **AskUserQuestion calls** — Do not call `AskUserQuestion` for any input. Resolve values
   from flags or smart defaults below. If a **required** value is absent after parsing (e.g.
   `share-blog` dispatched with no `--source`), emit:
   ```
   SOCIAL-SHARE: ERROR skill=<name> reason=missing required flag --<flag>
   ```
   Then **STOP**.

2. **Copy-approval gate** — Do not present copy in a fenced block and pause. Draft the copy
   and proceed directly to Populate without waiting.

3. **Security-scrub WARN** — Do not ask user to confirm. Auto-proceed; append a
   `⚠ WARN — <reason>` note to the `SOCIAL-SHARE: DONE` output line. `BLOCKED` still
   hard-STOPs.

4. **Long-file disambiguation** (`share-selection`) — Do not ask which region. Use the first
   80 lines of the file at `--code-file`, or the explicitly passed line range if one was
   embedded in the dispatch prompt.

5. **Video 4xx fallback** (`share-video`) — Do not ask for title or channel. Set
   `VIDEO_TITLE=""`, `CHANNEL=""`, `thumbnail_url=""` and continue.

6. **Reuse check** — Skip the interactive reuse offer. Always generate a fresh card.

---

## Smart Defaults

- `--platform` absent → use `all`.
- `--tone` absent + single platform → use that platform's default from `references/platforms.md`
  (LinkedIn → Professional, Twitter/X → Punchy, Bluesky → Conversational).
- `--tone` absent + `--platform=all` → omit tone; each variant uses its platform default.

---

## Completion Line

### Card-generating skills

After the Deliver phase, emit exactly:

```
SOCIAL-SHARE: DONE skill=<skill-name> platform=<resolved-platform> png=<$SAVE_PATH_PNG> html=<$SAVE_PATH>
```

If `$SAVE_PATH_PNG` is empty (Playwright unavailable), report `png=` as an empty string.

### File-producing skills

Skills that write a single output file instead of a card (e.g. `media-library` catalog
dump) use a generic form:

```
SOCIAL-SHARE: DONE skill=<skill-name> output=<absolute-path-to-output-file>
```

### Digest chain

`share-scan` (invoked by `agent-digest` / `/digest-bg`) predates this contract and uses
its own flags (`--days`, `--base`, `--max`, `--codebase`) and completion message:

```
Digest complete: .claude/digests/<filename> (<N> entries)
```

This is intentional — do not reformat it to the card line.

### Error line (all skills)

On STOP due to missing flag or BLOCKED scrub, emit instead:

```
SOCIAL-SHARE: ERROR skill=<skill-name> reason=<one-line description>
```

Do **not** post to any platform — output is copy + image only.
