# Selection sources, guards, and objective

Phase 1 of `share-selection` in full. This skill shares a specific piece of code the user
points at — it never falls back to git history.

## Source the code (first match wins)

1. **Highlighted lines** — if the user highlighted lines in their IDE (provided via context),
   use exactly those lines. Set `LINE_RANGE` to the highlighted range (e.g. `"L42–L58"`).
2. **Selected / open file** — if a file is selected or open in the IDE (path provided via
   context) with no specific lines highlighted, read the file and use its contents. Take
   `FILENAME` and the language from the real path/extension.
3. **Pasted code** — if the user pasted a fenced code block in their message, use its
   contents. Take the language from the fence tag (e.g. ```` ```python ````) when present.

Capture for later phases: the code text (`CODE_RAW`), a filename/path hint, a language hint,
and a line range when known.

## Selected-file guards

- **Non-code file** (binary, image, lockfile such as `package-lock.json`/`*.lock`, minified
  bundle, or anything that isn't human-readable source): do **not** render it. Tell the user
  what was selected and ask them to pick a code file or paste a snippet instead. **STOP.**
- **Long file** — `snippet-card` caps at ~80 lines (Phase 5). *(Interactive mode)* If the
  source exceeds 80 lines, use `AskUserQuestion` to ask which region to feature (a line range,
  function, or section), then use only that range. Do **not** silently truncate or render the
  whole file. *(Background mode)* use the first 80 lines without asking.

## No code found

If none of the three sources yields code, ask the user to paste or select the code to share.
Do **not** fall back to git history.

## Objective

Determine `OBJECTIVE` — what the user wants the post to accomplish or emphasize:

- **Infer** it from the user's prompt when stated (e.g. "share this and stress the perf win"
  → `OBJECTIVE = "highlight the performance win"`).
- **Ask** only if absent: include a short free-text **objective** input ("What should this
  post accomplish or emphasize?") in the same `AskUserQuestion` that collects `PLATFORM`
  (see **Platform Options** in `$PLUGIN_DIR/references/platforms.md`) and `TONE`.

## How `OBJECTIVE` frames the copy per platform (Phase 3)

Draft copy that **serves `OBJECTIVE`** within each platform's limit and the chosen tone:

- **LinkedIn**: Context ("Here's a [LANGUAGE] pattern that…") → the teachable takeaway the
  objective calls for → what makes it applicable → learn-more CTA
- **Twitter/X**: One punchy takeaway framing the snippet around the lesson
- **Bluesky**: Conversational; lead with the takeaway; name the creator
- **Substack**: Why this pattern is worth learning + the teachable principle
