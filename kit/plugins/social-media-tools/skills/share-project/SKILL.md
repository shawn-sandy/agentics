---
name: share-project
description: "Generates platform-aware social posts and dark-mode cards for project updates by topic. Use when announcing features, bugs, changes, or releases on social media."
allowed-tools: Bash, Read, Write, Glob, Grep, AskUserQuestion, ToolSearch, ExitPlanMode, SendUserFile, Skill
disable-model-invocation: true
---

# share-project

Generate social media copy and a styled dark-mode card image for a project based on a
topic — features, bugs, changes, or release. Extracts project metadata and topic-relevant
content from git history, CHANGELOG, README, and manifest files.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Inputs | Parse topic, platform, path from `$ARGUMENTS`; ask for missing ones |
| 1c — Reuse check | Scan `docs/media/social/` for existing project posts; offer reuse |
| 2 — Metadata | Extract project name, version, description from manifest files |
| 3 — Content | Extract topic-relevant commits, changelog entries, README sections |
| 4 — Scrub | Security-scrub extracted content via `security-scrub` skill |
| 5 — Draft | Write platform-aware copy |
| 6 — Card | Populate template, save to disk, screenshot via Playwright |
| 7 — Deliver | Present copy + card image + saved path |

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

If not found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Parse Inputs

Parse `$ARGUMENTS`:

- `--topic <value>` — one of: `features`, `bugs`, `changes`, `release` (required)
- `--platform <value>` — see **Platform Options** in `$PLUGIN_DIR/references/platforms.md` (required)
- `--path <dir>` — project root to analyze (default: `$PWD`)
- `--days=N` — how far back to look in git history (default: `30`)

If `--topic` is missing, use `AskUserQuestion`:
> "What would you like to share about this project?"
> Options: `features`, `bugs`, `changes`, `release`

If `--platform` is missing, ask it in the **same** `AskUserQuestion` call.

Set `PATH_ROOT` = `--path` value or `$PWD`. Set `DAYS` = `--days` value or `30`.

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=project
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Extract Project Metadata

From `$PATH_ROOT`, extract `PROJECT_NAME`, `PROJECT_VERSION`, and `PROJECT_DESCRIPTION`.

```bash
cat "$PATH_ROOT/package.json" 2>/dev/null | grep -E '"name"|"version"|"description"' | head -3
cat "$PATH_ROOT/pyproject.toml" 2>/dev/null | grep -E '^name |^version |^description ' | head -3
cat "$PATH_ROOT/setup.cfg" 2>/dev/null | grep -E '^name|^version' | head -2
cat "$PATH_ROOT/Cargo.toml" 2>/dev/null | grep -E '^name|^version|^description' | head -3
head -3 "$PATH_ROOT/go.mod" 2>/dev/null
```

Fallbacks: no name → last segment of `$PATH_ROOT`; no version → `"latest"`; no description → first paragraph of `README.md`.

---

## Phase 3 — Extract Topic Content

Read `references/topics.md` for full extraction patterns and card-type assignments.

### features
```bash
git -C "$PATH_ROOT" log --oneline --after="${DAYS} days ago" --format="%s" 2>/dev/null | grep -iE "^feat(\(|:)" | head -10
grep -A 20 "^## Features\|^### Features" "$PATH_ROOT/README.md" 2>/dev/null | head -20
head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```
Card: `feature-card.html` — Badge: `New Features`

### bugs
```bash
git -C "$PATH_ROOT" log --oneline --after="${DAYS} days ago" --format="%s" 2>/dev/null | grep -iE "^fix(\(|:)" | head -10
head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```
Card: `diff-card.html` — Badge: `Bug Fix`

### changes
```bash
git -C "$PATH_ROOT" log --oneline --after="7 days ago" --format="%s" 2>/dev/null | head -15
git -C "$PATH_ROOT" diff --stat HEAD~5..HEAD 2>/dev/null | head -20
head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```
Card: `diff-card.html` — Badge: `What's Changed`

### release
```bash
git -C "$PATH_ROOT" tag --sort=-version:refname 2>/dev/null | head -1
head -60 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```
Card: `feature-card.html` — Badge: `v$PROJECT_VERSION` (or latest git tag if different)

If no release data found, inform the user and STOP.

---

## Phase 4 — Security Scrub

Combine extracted content and invoke `security-scrub`:

- `SCRUB RESULT: BLOCKED` → show masked content, STOP.
- `SCRUB RESULT: WARN` → continue with `⚠ WARN — <reason>` label.

---

## Phase 5 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults,
**Default Per-Platform Copy Formats**, and **Draft Copy — Standard Procedure**.
For per-topic tone guide, read `references/topics.md`.

**Copy structure by topic:**
- `features`: Hook with the top feature. LinkedIn: story arc. Short: strongest feature + emoji.
- `bugs`: Lead with pain point fixed. LinkedIn: problem → solution → impact. Short: `#bugfix: [broken] → [fixed]`.
- `changes`: Lead with most significant change. LinkedIn: what changed + why. Short: top 2 changes.
- `release`: Lead with version + headline. LinkedIn: full highlights. Short: `🚀 [name] v[N] — [tagline]`.

---

## Phase 6 — Generate Card

### 6a — Variable assignments

Set before populating:

**feature-card.html** (topics: features, release):

| Variable | Value |
|----------|-------|
| `{{TITLE}}` | `$PROJECT_NAME — [topic headline]` |
| `{{SUBTITLE}}` | `$PROJECT_DESCRIPTION` (one sentence) |
| `{{BADGE}}` | Badge text from Phase 3 |
| `{{BULLETS}}` | Top 3–5 items as `<li>text</li>` |
| `{{FOOTER_NOTE}}` | Repo URL or `$PATH_ROOT` |
| `{{COPY_PANELS}}` | See `$PLUGIN_DIR/references/copy-panels.md` |

**diff-card.html** (topics: bugs, changes):

| Variable | Value |
|----------|-------|
| `{{FILENAME}}` | `$PROJECT_NAME / [topic]` |
| `{{BADGE}}` | Badge text from Phase 3 |
| `{{HUNK_1_HEADER}}` | `@@ Recent $TOPIC @@` |
| `{{HUNK_1_ROWS}}` | Top items as `<tr class="add"><td class="ln">+</td><td class="code"> {item}</td></tr>` |
| `{{HUNK_2_HEADER}}` | *(empty string)* |
| `{{HUNK_2_ROWS}}` | *(empty string)* |
| `{{STAT_ADD}}` | Count of items |
| `{{STAT_DEL}}` | `0` |
| `{{WORKFLOW_SUMMARY}}` | `Last $DAYS days · $PROJECT_NAME` |
| `{{COPY_PANELS}}` | See `$PLUGIN_DIR/references/copy-panels.md` |

### 6b — Populate and write

For `{{COPY_PANELS}}` markup and escaping, read `$PLUGIN_DIR/references/copy-panels.md`.

Write the populated HTML to `~/.claude/tmp/share-project-card.html`:

```bash
mkdir -p ~/.claude/tmp
TEMP_HTML=share-project-card.html
FILE_PREFIX=project
SLUG_INPUT=$PROJECT_NAME-$TOPIC
```

### 6c — Persistent Save

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

### 6d — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 7 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.
