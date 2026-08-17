---
name: share-code
description: "Generates social copy and a dark-mode card image for code changes. Detects changes from git, picks a template, and screenshots via Playwright. Use when asked to share a code change."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, SendUserFile, Glob, Skill
---

# share-code

Draft platform-aware social media copy and generate a styled dark-mode card image for any
supported platform (see `$PLUGIN_DIR/references/platforms.md`).

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Clarify | Auto-detect from git; ask platform + tone |
| 1c — Reuse check | Scan `docs/media/social/` for existing posts; offer reuse |
| 1d — Scrub | Run `security-scrub` on the extracted git content |
| 2 — Draft | Write platform-aware copy |
| 3 — Pick template | diff → diff-card, feature → feature-card, insight → quote-card |
| 4 — Populate | Read template, substitute `{{VARIABLES}}` including `{{COPY_PANELS}}` |
| 4b — Save | Persistent save to `docs/media/social/` |
| 5 — Screenshot | Serve HTML locally, Playwright screenshot |
| 6 — Deliver | Present copy + attach PNG + show saved path |

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

If no directory is found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 0b — Load Project Sharing Config

Check for `SOCIAL.md` (see `$PLUGIN_DIR/references/social-config.md`):

```bash
SOCIAL_CONFIG=""
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -f "$PWD/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$PWD/SOCIAL.md"
elif [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$GIT_ROOT/SOCIAL.md"
fi
```

If found, `Read` it silently. Extract `DEFAULT_PLATFORM`, `DEFAULT_TONE`,
`DEFAULT_HASHTAGS`, `FOCUS_AREAS`, and `AUDIENCE` from the parsed sections.
These serve as defaults — user input in `$ARGUMENTS` always overrides them.

---

## Phase 1 — Clarify

Run silently:

```bash
git diff HEAD~1 --stat 2>/dev/null | head -20
git log --oneline -5 2>/dev/null
head -30 CHANGELOG.md 2>/dev/null
```

- Non-empty diff stat → auto-select `diff-card`
- Commit with `feat:` prefix or version bump → auto-select `feature-card`
- Context found: summarise in one sentence, ask only **platform** and **tone** (pre-select
  `DEFAULT_PLATFORM` and `DEFAULT_TONE` from SOCIAL.md if available)
- No context: ask all three inputs via `AskUserQuestion`
- When `FOCUS_AREAS` are set, use them to pick the most relevant commit or
  change as the card's angle
- When `AUDIENCE` is set, use it to calibrate vocabulary and detail level
- When `DEFAULT_HASHTAGS` are set, append them per platform rules in Phase 2

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=<detected-card-type>   # diff, feature, or quote
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 1d — Security Scrub

The diff hunks, commit subjects, and changelog excerpts gathered in Phase 1 are
about to be published on a card. Write them to the scrub input file:

```bash
mkdir -p ~/.claude/tmp
git diff HEAD~1 > ~/.claude/tmp/scrub-input.txt 2>/dev/null
git log --oneline -5 >> ~/.claude/tmp/scrub-input.txt 2>/dev/null
head -30 CHANGELOG.md >> ~/.claude/tmp/scrub-input.txt 2>/dev/null
```

Then invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line (the gate runs inside `security-scrub`):

- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 2.
- `GATE RESULT: APPROVED` → proceed. Missing or unrecognized → **STOP**, report gate failure.

---

## Phase 2 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Instructional Voice** doctrine, **Learn-More CTA** rule, **Default Per-Platform Copy
Formats**, and **Draft Copy — Standard Procedure** (present → approve → store variants).

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from this code change (a pattern, technique, pitfall avoided,
or design principle). The diff or feature is evidence for the lesson, not the headline.

---

## Phase 3 — Pick Template

- `diff-card.html` — code changes, rule updates, config diffs, PR descriptions
- `feature-card.html` — releases, new features, version announcements, changelogs
- `quote-card.html` — insights, opinions, pull quotes, teachable principles

```bash
CARD_TYPE=<chosen>          # diff, feature, or quote
TEMPLATE_FILE=$TEMPLATES_DIR/${CARD_TYPE}-card.html
TEMP_HTML=code-share-card.html
FILE_PREFIX=$CARD_TYPE
SLUG_INPUT=<commit subject, filename, or feature title>
```

---

## Phase 4 — Populate Template

Read `TEMPLATE_FILE`. For variable reference, read `$PLUGIN_DIR/references/variables.md`.

For `{{COPY_PANELS}}` markup and escaping rules, read `$PLUGIN_DIR/references/copy-panels.md`.

Write the populated HTML to `~/.claude/tmp/code-share-card.html`:

```bash
mkdir -p ~/.claude/tmp
```

---

## Phase 4b — Persistent Save

Variables set in Phase 3: `FILE_PREFIX`, `SLUG_INPUT`, `TEMP_HTML`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

---

## Phase 5 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 6 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.
