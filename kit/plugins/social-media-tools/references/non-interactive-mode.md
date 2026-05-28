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
| `--source=<v>` | URL or absolute path | Required for `blog-share`, `github-code-share`, `video-share` |
| `--objective=<text>` | Free text | Used by `selection-share`; inferred if absent |
| `--code-file=<path>` | Absolute path under `~/.claude/tmp/` | Required for `selection-share` |

---

## Skip Rules

Apply every rule when `--background` is present.

1. **AskUserQuestion calls** — Do not call `AskUserQuestion` for any input. Resolve values
   from flags or smart defaults below. If a **required** value is absent after parsing (e.g.
   `blog-share` dispatched with no `--source`), emit:
   ```
   SOCIAL-SHARE: ERROR skill=<name> reason=missing required flag --<flag>
   ```
   Then **STOP**.

2. **Copy-approval gate** — Do not present copy in a fenced block and pause. Draft the copy
   and proceed directly to Populate without waiting.

3. **Security-scrub WARN** — Do not ask user to confirm. Auto-proceed; append a
   `⚠ WARN — <reason>` note to the `SOCIAL-SHARE: DONE` output line. `BLOCKED` still
   hard-STOPs.

4. **Long-file disambiguation** (`selection-share`) — Do not ask which region. Use the first
   80 lines of the file at `--code-file`, or the explicitly passed line range if one was
   embedded in the dispatch prompt.

5. **Video 4xx fallback** (`video-share`) — Do not ask for title or channel. Set
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

After the Deliver phase, emit exactly:

```
SOCIAL-SHARE: DONE skill=<skill-name> platform=<resolved-platform> png=<$SAVE_PATH_PNG> html=<$SAVE_PATH>
```

If `$SAVE_PATH_PNG` is empty (Playwright unavailable), report `png=` as an empty string.

On STOP due to missing flag or BLOCKED scrub, emit instead:

```
SOCIAL-SHARE: ERROR skill=<skill-name> reason=<one-line description>
```

Do **not** post to any platform — output is copy + image only.
