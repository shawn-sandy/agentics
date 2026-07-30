---
name: share-session
description: "Generates a session recap card. Reads session JSONL and git history to produce a narrative plus highlights card. Use when asked to share a session recap or what you worked on today."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, SendUserFile, Glob, Skill
---

# share-session

Summarize **what the current Claude Code session accomplished** — a short narrative plus the
key things built, fixed, or changed — into a dark-mode recap card for any platform in
`$PLUGIN_DIR/references/platforms.md`. Token usage, duration, and commit/file counts
ride along as a compact stats strip: the content summary is the hero, the metrics supporting
detail. **Tokens only — no dollar amounts.**

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Derive `TEMPLATES_DIR` and `PLUGIN_DIR` |
| 1 — Gather | Session usage, git stats, `NARRATIVE` + `ACCOMPLISHMENTS` |
| 1c — Reuse check | Offer reuse of existing posts |
| 2 — Scrub | `security-scrub` the full summary (BLOCKED = hard stop) |
| 3 — Draft | Content-first, tokens-only platform copy |
| 4 — Populate | Substitute `{{VARIABLES}}` in `session-card.html` |
| 4b — Save | Save to `docs/media/social/` |
| 5 — Screenshot | Serve locally, Playwright screenshot |
| 6 — Deliver | Copy + PNG + saved path |

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

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

If none found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Gather Session Data

Read `references/session-data.md` (bundled with this skill) and run Phases 1a–1e in order —
`$ARGUMENTS` flags, `session_usage.py`, git stats, display values, `NARRATIVE` /
`ACCOMPLISHMENTS` / `SUMMARY_RAW`.

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=session
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow it.

---

## Phase 2 — Security Scrub

Scrub the **entire** narrative + accomplishments, not a single line. Write `SUMMARY_RAW` to
`~/.claude/tmp/scrub-input.txt` as plain text — no HTML escaping yet — then invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line from `security-scrub`:
- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed.
- `GATE RESULT: APPROVED` → proceed to Phase 3.
- Missing or unrecognized `GATE RESULT` → **STOP** and report an error (treat as gate failure).

---

## Phase 3 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults,
**Instructional Voice**, **Learn-More CTA**, **Default Per-Platform Copy Formats**, and
**Draft Copy — Standard Procedure**.

Ask for `PLATFORM` and `TONE` in a single `AskUserQuestion` if not already in `$ARGUMENTS`.

Read `references/draft-copy.md` (bundled with this skill) for the takeaway-first rule and
this skill's per-platform recap formats.

---

## Phase 4 — Populate Template

```bash
TEMPLATE_FILE=$TEMPLATES_DIR/session-card.html
TEMP_HTML=session-share-card.html
SLUG_INPUT="session-$TODAY"
```

Read `TEMPLATE_FILE`, then `references/card-population.md` (bundled with this skill) for the
mandatory escape order and variable table. Also read
`$PLUGIN_DIR/references/variables.md` (shared variables) and
`$PLUGIN_DIR/references/copy-panels.md` (`{{COPY_PANELS}}` markup and escaping).

Write the populated HTML to `~/.claude/tmp/session-share-card.html` (`mkdir -p ~/.claude/tmp` first).

---

## Phase 4b — Persistent Save

Already set: `FILE_PREFIX=session`, `SLUG_INPUT`, `TEMP_HTML=session-share-card.html`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

---

## Phase 5 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow it end to end.

---

## Phase 6 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.
