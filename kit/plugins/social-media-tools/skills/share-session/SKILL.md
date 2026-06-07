---
name: share-session
description: "Generates a session recap card. Reads session JSONL and git history to produce a narrative plus highlights card. Use when asked to share a session recap or what you worked on today."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, SendUserFile, Glob, Skill
---

# share-session

Summarize **what the current Claude Code session accomplished** — a short narrative plus the
key things built, fixed, or changed — into a dark-mode recap card for any supported platform
(see `$PLUGIN_DIR/references/platforms.md`). Token usage, duration, and commit/file counts
ride along as a compact stats strip. **Tokens only — no dollar amounts.**

The content summary is the hero of the card; the usage metrics are supporting detail.

This skill is **session-driven**: it reads the live session JSONL for token counts and content
signals and uses git history for activity context. No code selection required.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Gather | Run `session_usage.py`, derive git stats, **build `NARRATIVE` + `ACCOMPLISHMENTS`** |
| 1c — Reuse check | Scan `docs/media/social/` for existing posts; offer reuse |
| 2 — Scrub | `security-scrub` the **full content summary** (BLOCKED = hard stop) |
| 3 — Draft | Write content-first, tokens-only platform-aware copy |
| 4 — Populate | Read `session-card.html`, substitute `{{VARIABLES}}` |
| 4b — Save | Persistent save to `docs/media/social/` |
| 5 — Screenshot | Serve HTML locally, Playwright screenshot |
| 6 — Deliver | Present copy + attach PNG + show saved path |

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
[ -n "${CLAUDE_PLUGIN_ROOT}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/templates" ] && \
  echo "${CLAUDE_PLUGIN_ROOT}/templates"
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
- Content signals (for Phase 1e): `USER_PROMPTS[]`, `ASSISTANT_SNIPPETS[]`, `TOOL_USE_COUNTS`,
  `FILES_TOUCHED[]`, `FILES_TOUCHED_COUNT`. Interactive mode may ignore these and summarize
  from its own context (see Phase 1e).

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

### 1e — Build the content summary (the hero of the card)

This is the most important step. Produce two values:

- `NARRATIVE` — 1–2 sentences (≤ 240 chars) describing what the session was about and what got
  done. Be specific (feature names, files, fixes), not generic ("did some work").
- `ACCOMPLISHMENTS` — 3–5 short bullet strings (each ≤ 90 chars) naming concrete things built,
  fixed, or changed.

Author `NARRATIVE` and `ACCOMPLISHMENTS` **directly from your own conversation memory**. You already know what happened; do not rely on the JSONL for content. Use `FILES_TOUCHED`/`TOOL_USE_COUNTS` only as corroborating detail. Prefer concrete outcomes over process narration.

Define `SUMMARY_RAW` for the security scrub (Phase 2) as `NARRATIVE` followed by each
accomplishment bullet on its own line.

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=session
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Security Scrub

The content summary now draws on many messages (especially in background mode, where it is
synthesized from `USER_PROMPTS`/`ASSISTANT_SNIPPETS`/`FILES_TOUCHED`) — so it is far more likely
to surface secrets, paths, or env names than the old first-prompt echo. Scrub the **entire**
narrative + accomplishments, not a single line.

Write `SUMMARY_RAW` (the `NARRATIVE` plus every `ACCOMPLISHMENT` bullet, one per line) to a temp
file:

```
Write to: ~/.claude/tmp/scrub-input.txt
Content: SUMMARY_RAW (plain text, no HTML escaping yet)
```

Then invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line (the gate runs inside `security-scrub`):
- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 3.
- `GATE RESULT: APPROVED` → proceed to Phase 3.
- Missing or unrecognized `GATE RESULT` → **STOP** and report an error (treat as gate failure).

---

## Phase 3 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Instructional Voice** doctrine, **Learn-More CTA** rule, **Default Per-Platform Copy
Formats**, and **Draft Copy — Standard Procedure**.

**Never include dollar amounts or cost figures — tokens only.**

Ask for `PLATFORM` and `TONE` in a single `AskUserQuestion` if not already in `$ARGUMENTS`.

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from this session's work (a technique, workflow pattern, or
development principle). Accomplishments and metrics are supporting evidence for the lesson,
not the headline.

Content-specific guidance for this skill:

- **LinkedIn**: Hook on the lesson ("Here's a technique for X I used in a Claude Code
  session…") → 2–3 things learned or patterns applied → *then* one supporting stat line
  (N commits · N files · ~X tokens · Y% cache hit) → learn-more CTA
- **Twitter/X**: One punchy takeaway or technique learned; a single stat only if it fits
- **Bluesky**: Conversational, lesson-first brevity
- **Substack**: Reflect on what you learned and the technique worth sharing; stats as
  supporting detail

The token/duration/cache figures are a single trailing stat line, never the focus.

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
| `{{NARRATIVE}}` | `NARRATIVE` (HTML-escaped; 1–2 sentences, ≤240 chars) |
| `{{ACCOMPLISHMENTS}}` | One `<li>…</li>` per accomplishment — HTML-escape each bullet's **text**, then wrap in `<li>` (the `<li>` tags stay literal). No wrapping `<ul>`. Mirrors `feature-card.html`'s `{{BULLETS}}`. |
| `{{TOTAL_TOKENS}}` | Total tokens formatted with commas (HTML-escaped) |
| `{{CACHE_HIT_RATE}}` | Cache hit rate (e.g. `44.2%`) (HTML-escaped) |
| `{{DURATION}}` | Duration in minutes (e.g. `47 min`; `0 min` if unknown) (HTML-escaped) |
| `{{FILES_CHANGED}}` | Files changed integer (HTML-escaped) |
| `{{COMMITS}}` | Commits count integer (HTML-escaped) |
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
