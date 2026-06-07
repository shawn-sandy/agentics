---
name: share-project
description: "Generates social posts and dark-mode cards for project updates. Reads git, CHANGELOG, and README then screenshots via Playwright. Use when announcing features, bugs, or releases on social media."
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

If not found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

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
`DEFAULT_HASHTAGS`, `FOCUS_AREAS`, `AUDIENCE`, `PROJECT_IDENTITY` (name + tagline),
and `AVOID_PATTERNS` from the parsed sections. These serve as defaults — explicit
`$ARGUMENTS` always override them.

---

## Phase 1 — Parse Inputs

Parse `$ARGUMENTS`:

- `--topic <value>` — one of: `features`, `bugs`, `changes`, `release` (required)
- `--platform <value>` — see **Platform Options** in `$PLUGIN_DIR/references/platforms.md` (optional if `DEFAULT_PLATFORM` loaded from SOCIAL.md)
- `--path <dir>` — project root to analyze (default: `$PWD`)
- `--days=N` — how far back to look in git history (default: `30`)

If `--topic` is missing, use `AskUserQuestion`:
> "What would you like to share about this project?"
> Options: `features`, `bugs`, `changes`, `release`

If `--platform` is missing and `DEFAULT_PLATFORM` is set from SOCIAL.md, use it.
Otherwise ask in the **same** `AskUserQuestion` call.

Set `PATH_ROOT` = `--path` value or `$PWD`. Set `DAYS` = `--days` value or `30`.

When `PROJECT_IDENTITY` is set from SOCIAL.md, use its name and tagline as
defaults for `PROJECT_NAME` and `PROJECT_DESCRIPTION` in Phase 2 (manifest
values still override if present).

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

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Instructional Voice** doctrine, **Learn-More CTA** rule, **Default Per-Platform Copy
Formats**, and **Draft Copy — Standard Procedure**.
For per-topic tone guide, read `references/topics.md`.

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from this project update (a technique, design decision, or
development principle). Features, fixes, and releases are evidence for the lesson,
not the headline.

When SOCIAL.md was loaded:
- Use `DEFAULT_TONE` as the baseline tone (user overrides still take priority)
- Append `DEFAULT_HASHTAGS` per platform rules
- Use `FOCUS_AREAS` to shape which extracted items get top billing in the copy
- Use `AUDIENCE` to calibrate vocabulary and level of technical detail

**Copy structure by topic:**
- `features`: Lead with the technique or principle behind the top feature. LinkedIn: lesson arc. Short: teachable pattern + emoji.
- `bugs`: Lead with the root-cause lesson. LinkedIn: what went wrong → the principle that fixes it → what readers can apply. Short: `#bugfix lesson: [root cause] → [principle]`.
- `changes`: Lead with the most instructive change and the design decision behind it. LinkedIn: what changed + the technique worth knowing. Short: top 2 lessons.
- `release`: Lead with the key development principle the release embodies. LinkedIn: technique highlights. Short: `🚀 [name] v[N] — [key lesson]`.

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
