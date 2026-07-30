---
name: share-selection
description: "Turns selected or pasted code into a platform-aware social card. Scrubs, picks a template, and screenshots via Playwright. Use when asked to share, post, or tweet highlighted or pasted code."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, SendUserFile, Glob, Skill
---

# share-selection

Turn code the user **selected, highlighted, opened, or pasted** into platform-aware social copy
and a dark-mode card image (platforms: `$PLUGIN_DIR/references/platforms.md`), shaped by the
user's objective. **Selection-driven** — it never scans git history; that is `code-share`'s job.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Find `templates/`, derive `PLUGIN_DIR` |
| 1 — Capture | Code + objective |
| 1c — Reuse | Classify card type, scan `docs/media/social/` |
| 2 — Scrub | Run `security-scrub` |
| 3 — Draft | Copy serving the objective |
| 4 — Template | diff-card or snippet-card |
| 5 — Populate | Substitute `{{VARIABLES}}` |
| 5b — Save | Save to `docs/media/social/` |
| 6 — Screenshot | Playwright screenshot |
| 7 — Deliver | Copy + PNG + path |

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Phase 0 — Locate Plugin Assets

Run the locate block in `references/card-population.md` (bundled with this skill) to set
`TEMPLATES_DIR` and `PLUGIN_DIR`. None found → say "Templates not found. Install the plugin
or load it with `--plugin-dir`." and **STOP**.

## Phase 1 — Capture Selection + Objective

Read `references/selection-sources.md` (bundled with this skill) first — source precedence,
guards, `OBJECTIVE`/`TONE`/`PLATFORM` capture
(`$PLUGIN_DIR/references/platforms.md`), Phase 3's framings.

Guards — they decide whether anything renders:

- **Non-code file** (binary, image, lockfile, minified bundle) — do **not** render; ask for a code file or paste. **STOP.**
- **Long file** — `snippet-card` caps at ~80 lines; ask which region (background: first 80). Never truncate silently.
- **No code found** — ask for a paste or selection; never fall back to git history.

## Phase 1c — Reuse Check

Classify first, look up second — never a provisional prefix. Run **Classify `CODE_RAW`** in
`references/card-population.md` to set `CARD_TYPE` and `FILE_PREFIX=$CARD_TYPE`, then read
`$PLUGIN_DIR/references/reuse-check.md` and follow its procedure. Looking up a diff post under
`snippet-` misses it and creates a duplicate.

## Phase 2 — Security Scrub

Selected/pasted code is untrusted and about to be published. Write `CODE_RAW` unescaped
to `~/.claude/tmp/scrub-input.txt`, then invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line (the gate runs inside `security-scrub`):
- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 3.
- `GATE RESULT: APPROVED` → proceed. Missing or unrecognized → **STOP**, report gate failure.

## Phase 3 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` — limits, tone, Instructional Voice, Learn-More CTA,
the takeaway-first doctrine, per-platform copy formats, standard procedure. Draft copy
**serving `OBJECTIVE`** within each platform's limit and tone, per
`references/selection-sources.md`'s framings.

## Phase 4 — Pick Template

`CARD_TYPE` is already set (Phase 1c) — do not reclassify. Resolve
`TEMPLATE_FILE`/`TEMP_HTML`/`SLUG_INPUT` per `references/card-population.md`.

## Phase 5 — Populate Template

Read `TEMPLATE_FILE`, then follow `references/card-population.md` — **mandatory** escape order and
both variable tables. Plugin-level support:

- `$PLUGIN_DIR/references/variables.md` — snippet-card variables
- `$PLUGIN_DIR/references/copy-panels.md` — `{{COPY_PANELS}}` markup
- `$PLUGIN_DIR/references/language-map.md` — `LANGUAGE`, `LANGUAGE_COLOR`
- `$PLUGIN_DIR/references/variables.md` — diff-card hunk rows, stats

Write the populated HTML to `~/.claude/tmp/share-selection-card.html`.

## Phase 5b — Persistent Save

Variables already set: `FILE_PREFIX`, `SLUG_INPUT`, `TEMP_HTML`. Read
`$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

## Phase 6 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow it.

## Phase 7 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.
