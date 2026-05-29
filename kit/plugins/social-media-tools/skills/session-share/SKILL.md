---
name: session-share
description: "Session recap card with token usage and activity for social posts. Use when asked to share my session, session recap, usage today, or tokens this session."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, SendUserFile, Glob, Skill
---

# session-share

Summarize the current Claude Code session — token usage (input, output, cache), duration,
model, files changed, commits, and a one-line narrative — into a dark-mode session recap
card for LinkedIn, Twitter/X, or Bluesky. **Tokens only — no dollar amounts.**

This skill is **session-driven**: it reads the live session JSONL for token counts and uses
git history for activity context. No code selection required.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Gather | Run `session_usage.py`, derive git stats and `SUMMARY` |
| 1c — Reuse check | Scan `docs/media/social/` for existing posts; offer reuse |
| 2 — Scrub | `security-scrub` the `SUMMARY` text (BLOCKED = hard stop) |
| 3 — Draft | Write tokens-only platform-aware copy |
| 4 — Populate | Read `session-card.html`, substitute `{{VARIABLES}}` |
| 4b — Save | Persistent save to `docs/media/social/` |
| 5 — Screenshot | Serve HTML locally, Playwright screenshot |
| 6 — Deliver | Present copy + attach PNG + show saved path |

## Non-interactive mode

When `$ARGUMENTS` contains `--background`: read `$PLUGIN_DIR/references/non-interactive-mode.md`
and follow all skip rules. Do not pause for user input at any point.

Skill-specific flags (used here; not in the shared non-interactive reference):

| Flag | Values | Notes |
|------|--------|-------|
| `--session=<id\|path>` | Session ID or absolute `.jsonl` path | Passed directly to `session_usage.py` |

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Derive:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
```

If no directory is found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Gather Session Data

### 1a — Parse `$ARGUMENTS`

Check for optional flags and capture:

- `SESSION_FLAG` — the `--session=<value>` flag string if present (pass verbatim to `session_usage.py`)
- `PLATFORM` — from `--platform=<v>`; keep empty if absent
- `TONE` — from `--tone=<v>`; keep empty if absent
- `BG_MODE` — `true` if `--background` is present

### 1b — Run `session_usage.py`

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

### 1c — Derive Git Stats

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

### 1d — Build display values

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

`SUMMARY_RAW` = `FIRST_USER_PROMPT` from `USAGE_JSON`, truncated to 160 chars. If empty, use
`"Claude Code session"`.

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=session
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Security Scrub

The `SUMMARY_RAW` text (derived from the first user prompt) may contain sensitive context.
Write it to a temp file:

```
Write to: ~/.claude/tmp/scrub-input.txt
Content: SUMMARY_RAW (plain text, no HTML escaping yet)
```

Then invoke:

```
Skill(skill: "code-share:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Parse the returned `SCRUB RESULT` block:
- `BLOCKED` → report masked findings, **STOP.**
- `WARN` → *(Interactive mode)* surface the warning, ask the user to confirm before continuing; *(background mode)* auto-proceed per `non-interactive-mode.md`.
- `PASS` → continue silently.

---

## Phase 3 — Draft Copy

For character limits, tone defaults, and the **Follow CTA** rule, read
`$PLUGIN_DIR/references/platforms.md`.

**Never include dollar amounts or cost figures — tokens only.**

*(Interactive mode only — see Non-interactive mode above when `--background` is set.)*
Ask for `PLATFORM` and `TONE` in a single `AskUserQuestion` if not already in `$ARGUMENTS`.

Draft copy that leads with session activity and token highlights:

- **LinkedIn**: Hook ("Just wrapped a session where…") → total token count → cache hit rate
  insight → activity summary (N commits, N files) → what was built (from `SUMMARY_RAW`) →
  follow CTA; 2–4 hashtags
- **Twitter/X**: One punchy line with total tokens and what was built; no hashtag bloat
- **Bluesky**: Conversational, same brevity as Twitter

Close with a topic-matched **follow** CTA tied to the session topic — never generic; on
Twitter/Bluesky include only if it fits the character budget.

*(Interactive mode only — present drafted copy per platform in a fenced block and wait for
approval; proceed directly to Phase 4 in `--background` mode.)*

---

## Phase 4 — Populate Template

```bash
TEMPLATE_FILE=$TEMPLATES_DIR/session-card.html
TEMP_HTML=session-share-card.html
SLUG_INPUT="session-$TODAY"
```

Read `TEMPLATE_FILE`. For the variable reference, read `$PLUGIN_DIR/references/variables.md`.
For `{{COPY_PANELS}}` markup and escaping, read `$PLUGIN_DIR/references/copy-panels.md`.

### HTML-escape all values — MANDATORY

Apply to every substituted string in this exact order:

1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

| Template variable | Value |
|-------------------|-------|
| `{{TITLE}}` | `TITLE` (HTML-escaped; e.g. `session recap · 2026-05-28`) |
| `{{MODEL}}` | `MODEL` (HTML-escaped; e.g. `sonnet-4-6`) |
| `{{TOTAL_TOKENS}}` | Total tokens formatted with commas (HTML-escaped) |
| `{{INPUT_TOKENS}}` | Input tokens formatted with commas (HTML-escaped) |
| `{{OUTPUT_TOKENS}}` | Output tokens formatted with commas (HTML-escaped) |
| `{{CACHE_READ}}` | Cache-read tokens formatted with commas (HTML-escaped) |
| `{{CACHE_HIT_RATE}}` | Cache hit rate (e.g. `44.2%`) (HTML-escaped) |
| `{{DURATION}}` | Duration in minutes (e.g. `47 min`; `0 min` if unknown) (HTML-escaped) |
| `{{FILES_CHANGED}}` | Files changed integer (HTML-escaped) |
| `{{COMMITS}}` | Commits count integer (HTML-escaped) |
| `{{SUMMARY}}` | `SUMMARY_RAW` truncated to 160 chars (HTML-escaped) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

Write the populated HTML to `~/.claude/tmp/session-share-card.html`:

```bash
mkdir -p ~/.claude/tmp
```

---

## Phase 4b — Persistent Save

Variables already set: `FILE_PREFIX=session`, `SLUG_INPUT`, `TEMP_HTML=session-share-card.html`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

---

## Phase 5 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 6 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.

After delivering, emit the machine-parseable completion line:

```
SOCIAL-SHARE: DONE skill=session-share platform=<resolved-platform> png=<$SAVE_PATH_PNG> html=<$SAVE_PATH>
```

On any hard STOP (missing session, BLOCKED scrub), emit instead:

```
SOCIAL-SHARE: ERROR skill=session-share reason=<one-line description>
```
