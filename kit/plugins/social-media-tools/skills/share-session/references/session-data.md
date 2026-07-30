# Session Data Gathering (Phase 1)

Bundled reference for `share-session`. This skill is **session-driven**: it reads the live
session JSONL for token counts and content signals and uses git history for activity context.
Phases 1a–1e produce every value the later phases substitute. Run them in order; `PLUGIN_DIR`
is already set by Phase 0.

## 1a — Parse `$ARGUMENTS`

Check for optional flags and capture:

- `SESSION_FLAG` — the `--session=<value>` flag string if present (pass verbatim to `session_usage.py`)
- `PLATFORM` — from `--platform=<v>`; keep empty if absent
- `TONE` — from `--tone=<v>`; keep empty if absent

## 1b — Run `session_usage.py`

```bash
python3 "$PLUGIN_DIR/scripts/session_usage.py" $SESSION_FLAG
```

Capture the JSON output as `USAGE_JSON`. If the script exits non-zero or the JSON contains
`"error"`, tell the user:
> "Could not locate the session transcript. Set `$CLAUDE_CODE_SESSION_ID` or pass `--session=<path>` explicitly."

**STOP.**

Extract from `USAGE_JSON`:
- `SESSION_ID`, `TOTAL_TOKENS`, `INPUT_TOKENS`, `OUTPUT_TOKENS`, `CACHE_READ`, `CACHE_HIT_RATE`
- `DURATION_MINUTES`, `FIRST_TIMESTAMP_ISO`, `MODELS[]`, `FIRST_USER_PROMPT`
- Content signals (for Phase 1e): `USER_PROMPTS[]`, `ASSISTANT_SNIPPETS[]`, `TOOL_USE_COUNTS`,
  `FILES_TOUCHED[]`, `FILES_TOUCHED_COUNT`. Interactive mode may ignore these and summarize
  from its own context (see Phase 1e).

## 1c — Derive Git Stats

Use `FIRST_TIMESTAMP_ISO` to bound the git log query to the session window:

```bash
SINCE="${FIRST_TIMESTAMP_ISO:-}"
# Fall back to 2 hours ago if timestamp is empty
if [ -z "$SINCE" ]; then
  SINCE=$(date -v-2H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date --date='2 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
fi

if [ -n "$SINCE" ]; then
  COMMITS=$(git log --oneline --after="$SINCE" 2>/dev/null | wc -l | tr -d ' ')
  FILES_CHANGED=$(git log --format="" --name-only --after="$SINCE" 2>/dev/null | sort -u | grep -vc "^$" 2>/dev/null || echo 0)
else
  COMMITS=0
  FILES_CHANGED=0
fi
```

Default both to `0` when git is unavailable.

## 1d — Build display values

```bash
# Use first model; strip the "claude-" prefix for the badge
MODEL=$(echo "$MODELS_0" | sed 's/^claude-//')  # e.g. "sonnet-4-6"

# Format as YYYY-MM-DD using today's date
TODAY=$(date '+%Y-%m-%d')
TITLE="session recap · $TODAY"
```

Format token integers with commas (e.g. `42180` → `42,180`):

```bash
python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
for k in ['total_tokens','input_tokens','output_tokens','cache_read']:
    print(k, f'{d[k]:,}')
print('cache_hit_rate', f\"{d['cache_hit_rate']}%\")
print('duration', f\"{int(d['duration_minutes'])} min\" if d['duration_minutes'] else '0 min')
" <<< "$USAGE_JSON"
```

## 1e — Build the content summary (the hero of the card)

This is the most important step. Produce two values:

- `NARRATIVE` — 1–2 sentences (≤ 240 chars) describing what the session was about and what got
  done. Be specific (feature names, files, fixes), not generic ("did some work").
- `ACCOMPLISHMENTS` — 3–5 short bullet strings (each ≤ 90 chars) naming concrete things built,
  fixed, or changed.

Author `NARRATIVE` and `ACCOMPLISHMENTS` **directly from your own conversation memory**. You already know what happened; do not rely on the JSONL for content. Use `FILES_TOUCHED`/`TOOL_USE_COUNTS` only as corroborating detail. Prefer concrete outcomes over process narration.

Define `SUMMARY_RAW` for the security scrub (Phase 2) as `NARRATIVE` followed by each
accomplishment bullet on its own line.

Why Phase 2 scrubs all of it: the content summary now draws on many messages (especially in
background mode, where it is synthesized from `USER_PROMPTS`/`ASSISTANT_SNIPPETS`/`FILES_TOUCHED`)
— so it is far more likely to surface secrets, paths, or env names than the old first-prompt echo.
