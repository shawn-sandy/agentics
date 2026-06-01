---
name: share-code
description: "Generates platform-aware social copy and a dark-mode card image for code changes. Use when asked to post or share a code change."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, ExitPlanMode, SendUserFile, Glob
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
| 2 — Draft | Write platform-aware copy |
| 3 — Pick template | diff → diff-card, feature → feature-card, insight → quote-card |
| 4 — Populate | Read template, substitute `{{VARIABLES}}` including `{{COPY_PANELS}}` |
| 4b — Save | Persistent save to `docs/media/social/` |
| 5 — Screenshot | Serve HTML locally, Playwright screenshot |
| 6 — Deliver | Present copy + attach PNG + show saved path |

## Exit plan mode

`ExitPlanMode` is a deferred tool whose schema must be loaded before it can be called.
Use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`. Both steps
happen silently with no user-visible output. Only call `ExitPlanMode` if currently in plan mode — skip this step entirely if plan mode is already off.

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

## Phase 1 — Clarify

Run silently:

```bash
git diff HEAD~1 --stat 2>/dev/null | head -20
git log --oneline -5 2>/dev/null
head -30 CHANGELOG.md 2>/dev/null
```

- Non-empty diff stat → auto-select `diff-card`
- Commit with `feat:` prefix or version bump → auto-select `feature-card`
- Context found: summarise in one sentence, ask only **platform** and **tone**
- No context: ask all three inputs via `AskUserQuestion`

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=<detected-card-type>   # diff, feature, or quote
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Follow CTA** rule, **Default Per-Platform Copy Formats**, and **Draft Copy — Standard
Procedure** (present → approve → store variants).

---

## Phase 3 — Pick Template

- `diff-card.html` — code changes, rule updates, config diffs, PR descriptions
- `feature-card.html` — releases, new features, version announcements, changelogs
- `quote-card.html` — insights, opinions, pull quotes, thought leadership

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
