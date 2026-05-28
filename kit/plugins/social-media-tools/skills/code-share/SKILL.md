---
name: code-share
description: "Generates social media copy and a dark-mode card image. Formats code changes into platform-ready posts for LinkedIn, Twitter/X, or Bluesky. Use when asked to post or share a code change."
allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, SendUserFile, Glob
---

# code-share

Draft platform-aware social media copy and generate a styled dark-mode card image for LinkedIn, Twitter/X, or Bluesky.

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

## Non-interactive mode

When `$ARGUMENTS` contains `--background`: read `$PLUGIN_DIR/references/non-interactive-mode.md`
and follow all skip rules. Do not pause for user input at any point.

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
*(Interactive mode only — see Non-interactive mode above when `--background` is set.)*
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

For character limits, tone defaults, and the **Follow CTA** rule, read `$PLUGIN_DIR/references/platforms.md`.

- **LinkedIn**: Narrative paragraphs; story arc (hook → insight → CTA); 2–4 hashtags at end
- **Twitter/X**: One punchy sentence or a tight two-liner; no hashtag bloat
- **Bluesky**: Conversational, same brevity as Twitter

The closing CTA is a topic-matched **follow** CTA (e.g. "follow for more `<language>`/`<topic>` like this") — varied each time, never a generic "follow me"; on Twitter/Bluesky include it only if it fits the limit. See the Follow CTA rule.

Draft all three platform variants in the chosen tone. *(Interactive mode only — present the drafted copy in a fenced code block labeled with the platform name and wait for approval; in `--background` mode proceed directly to Phase 3.)*

- **Single site:** store all variants joined with `\n---\n` as `POST_COPY_TEXT_RAW`
- **All sites:** keep each variant separate (`LINKEDIN_COPY`, `TWITTER_COPY`, `BLUESKY_COPY`)

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
