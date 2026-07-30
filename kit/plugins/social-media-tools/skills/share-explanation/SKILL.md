---
name: share-explanation
description: "Explains how any project file, component, or concept works. Reads source files, synthesizes principles, and generates a social card. Use when the user asks how something works or to explain it."
allowed-tools: Bash, Read, Glob, Grep, Write, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, SendUserFile
model: opus
---

# share-explanation

Answer **"how does X work"** questions about any file, component, function, or concept in this
project by reading the actual source, then deliver it the way every share-* skill does:
scrub → copy → card → save.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Derive `TEMPLATES_DIR` and `PLUGIN_DIR` |
| 0b — Config | Load `SOCIAL.md` defaults |
| 1 — Parse | Target and flags from `$ARGUMENTS` |
| 2 — Locate files | Five-tier target lookup |
| 3 — Synthesize | Read files, build explanation |
| 4 — Scrub | `security-scrub` (BLOCKED = hard stop) |
| 5 — Draft | Platform-aware social copy |
| 5b — Reuse | Check `docs/media/social/` for an existing post |
| 6 — Populate | Select template, substitute `{{VARIABLES}}` |
| 6b — Save | Persistent save to `docs/media/social/` |
| 7 — Screenshot | Serve HTML, Playwright screenshot |
| 8 — Deliver | Explanation + copy + PNG + saved path |

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Phase 0 — Locate Plugin Assets

Read `references/bootstrap.md` (bundled with this skill) — its Phase 0 sets `TEMPLATES_DIR` and
`PLUGIN_DIR`, and **STOPS** when neither resolves.

## Phase 0b — Load Project Sharing Config

Follow Phase 0b of `references/bootstrap.md` — `SOCIAL.md` lookup, `DEFAULT_PLATFORM`,
`DEFAULT_TONE`.

## Phase 1 — Parse `$ARGUMENTS`

Follow Phase 1 of `references/target-resolution.md` (bundled with this skill) — sets
`TARGET_RAW`, `PLATFORM`, `TONE`.

## Phase 2 — Identify Target and Locate Files

Run the five-tier lookup in `references/target-resolution.md` to set `TARGET_TYPE`,
`TARGET_NAME`, and `PRIMARY_FILE` or `SOURCE_FILES`; it **STOPS** when nothing matches.

## Phase 3 — Read Files and Synthesize

Read `references/synthesis-structure.md` (bundled with this skill) for the reading rules and
per-target-type section structures; build `EXPLANATION_RAW`.

## Phase 4 — Security Scrub

Write `EXPLANATION_RAW` to `~/.claude/tmp/scrub-input.txt` (`mkdir -p` that dir first), then
invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line:
- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 5.
- `GATE RESULT: APPROVED` → proceed to Phase 5.
- Missing or unrecognized result → **STOP** and report error (treat as gate failure).

## Phase 5 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Instructional Voice** doctrine, **Learn-More CTA** rule, and **Default Per-Platform
Copy Formats**.

Read `references/copy-drafting.md` (bundled with this skill) for `PLATFORM`/`TONE` resolution,
the takeaway-first rule, and per-platform content guidance.

## Phase 5b — Reuse Check

With `TARGET_NAME`, `PLATFORM`, and `FILE_PREFIX=explain` resolved, read
`$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

## Phase 6 — Populate Template

Read `$PLUGIN_DIR/references/variables.md` for the variable reference and
`$PLUGIN_DIR/references/copy-panels.md` for `{{COPY_PANELS}}` markup and escaping.

Read `references/card-population.md` (bundled with this skill) for template selection, the
mandatory escape order, and the variable tables. It sets `SLUG_INPUT` and `TEMP_HTML`.

## Phase 6b — Persistent Save

Variables: `FILE_PREFIX=explain`, `SLUG_INPUT`, `TEMP_HTML=explain-share-card.html`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

## Phase 7 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

## Phase 8 — Deliver

Present the explanation in a fenced block labeled `## Explanation`, the social copy in a
separate block labeled `## Copy`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section: attach the PNG,
report the saved path.
