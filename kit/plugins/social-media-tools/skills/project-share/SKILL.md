---
name: project-share
description: "Generates platform-aware social posts and dark-mode cards for a project by topic: features, bugs, changes, or release. Use when the user wants to announce features, highlight bug fixes, share what's changed, or post a release update for LinkedIn, Twitter/X, or Bluesky."
allowed-tools: Bash, Read, Write, Glob, Grep, AskUserQuestion, ToolSearch, SendUserFile, Skill
---

# project-share

Generate social media copy and a styled dark-mode card image for a project based on a topic — features, bugs, changes, or release. Extracts project metadata and topic-relevant content from git history, CHANGELOG, README, and manifest files.

## Quick Reference

| Phase | Action |
|-------|--------|
| 1 — Inputs | Parse topic, platform, path from `$ARGUMENTS`; ask for missing ones |
| 2 — Metadata | Extract project name, version, description from manifest files |
| 3 — Content | Extract topic-relevant commits, changelog entries, README sections |
| 4 — Scrub | Security-scrub extracted content via `security-scrub` skill |
| 5 — Draft | Write platform-aware copy |
| 6 — Card | Populate template, save to disk, screenshot via Playwright |
| 7 — Deliver | Present copy + card image + saved path |

---

## Phase 1 — Parse Inputs

Parse `$ARGUMENTS`:

- `--topic <value>` — one of: `features`, `bugs`, `changes`, `release` (required)
- `--platform <value>` — one of: `LinkedIn`, `Twitter/X`, `Bluesky` (required; ask if absent)
- `--path <dir>` — project root to analyze (default: `$PWD`)
- `--days=N` — how far back to look in git history (default: `30`)

If `--topic` is missing, use `AskUserQuestion`:
> "What would you like to share about this project?"
> Options: `features` (new capabilities added), `bugs` (resolved issues), `changes` (what changed recently), `release` (version announcement)

If `--platform` is missing, ask it in the **same** `AskUserQuestion` call.

Set `PATH_ROOT` = `--path` value, or `$PWD` if omitted.
Set `DAYS` = `--days` value, or `30` if omitted.

---

## Phase 2 — Extract Project Metadata

From `$PATH_ROOT`, extract `PROJECT_NAME`, `PROJECT_VERSION`, and `PROJECT_DESCRIPTION`.

Try these files in order; stop at the first successful match for each field:

```bash
# Node.js
cat "$PATH_ROOT/package.json" 2>/dev/null | grep -E '"name"|"version"|"description"' | head -3

# Python
cat "$PATH_ROOT/pyproject.toml" 2>/dev/null | grep -E '^name |^version |^description ' | head -3
cat "$PATH_ROOT/setup.cfg" 2>/dev/null | grep -E '^name|^version' | head -2

# Rust
cat "$PATH_ROOT/Cargo.toml" 2>/dev/null | grep -E '^name|^version|^description' | head -3

# Go
head -3 "$PATH_ROOT/go.mod" 2>/dev/null
```

If no manifest provides a name, use the last path segment of `$PATH_ROOT` as `PROJECT_NAME`.
If no manifest provides a version, use `"latest"` as `PROJECT_VERSION`.
If no description found in manifests, read the first non-heading, non-empty paragraph from `README.md` as `PROJECT_DESCRIPTION`.

---

## Phase 3 — Extract Topic Content

Read `references/topics.md` (adjacent to this SKILL.md) for the full extraction patterns and card-type assignments.

### features

```bash
git -C "$PATH_ROOT" log --oneline --after="${DAYS} days ago" \
    --format="%s" 2>/dev/null | grep -iE "^feat(\(|:)" | head -10

grep -A 20 "^## Features\|^### Features" "$PATH_ROOT/README.md" 2>/dev/null | head -20
head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```

Card template: `feature-card.html` — Badge: `New Features`

### bugs

```bash
git -C "$PATH_ROOT" log --oneline --after="${DAYS} days ago" \
    --format="%s" 2>/dev/null | grep -iE "^fix(\(|:)" | head -10

head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```

Card template: `diff-card.html` — Badge: `Bug Fix`

### changes

```bash
git -C "$PATH_ROOT" log --oneline --after="7 days ago" \
    --format="%s" 2>/dev/null | head -15

git -C "$PATH_ROOT" diff --stat HEAD~5..HEAD 2>/dev/null | head -20
head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```

Card template: `diff-card.html` — Badge: `What's Changed`

### release

```bash
git -C "$PATH_ROOT" tag --sort=-version:refname 2>/dev/null | head -1
head -60 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```

Card template: `feature-card.html` — Badge: `v$PROJECT_VERSION` (or latest git tag if different)

If no release data found (no tags, no CHANGELOG, no version field), inform the user and STOP.

---

## Phase 4 — Security Scrub

Combine the extracted content from Phase 3 into a single string. Invoke the `security-scrub` skill on it.

- `SCRUB RESULT: BLOCKED` → inform the user, show the masked content, and STOP.
- `SCRUB RESULT: WARN` → continue, but label the output with `⚠ WARN — <reason>`.

---

## Phase 5 — Draft Copy

Use the extracted content and tone guide from `references/topics.md` to write platform-aware copy.

| Platform | Max Length | Style |
|----------|-----------|-------|
| LinkedIn | 1,500 chars | Story arc (hook → what changed → why it matters → CTA); 2–4 hashtags at end |
| Twitter/X | 280 chars | One punchy line; lead with the most impactful item |
| Bluesky | 300 chars | Conversational; same brevity as Twitter/X |

**Copy structure by topic:**

- `features`: Hook with the top feature. LinkedIn: story arc. Short platforms: strongest feature + emoji.
- `bugs`: Lead with the pain point fixed. LinkedIn: problem → solution → impact. Short: `#bugfix: [broken] → [fixed]`.
- `changes`: Lead with the most significant change. LinkedIn: what changed + why. Short: top 2 changes.
- `release`: Lead with version number + headline. LinkedIn: full highlights. Short: `🚀 [name] v[N] is out — [tagline]`.

Present the drafted copy in a fenced code block labeled with the platform name.

Store all platform variants as `POST_COPY_TEXT_RAW` (join with `\n---\n` between platforms).

---

## Phase 6 — Generate Card

### 6a — Locate templates

```bash
# 1. Local dev checkout
ls ~/devbox/agentics/kit/plugins/social-media-tools/templates 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"

# 2. Claude Code plugin install dir
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1

# 3. Plugin cache dir (marketplace install)
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Set `PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")`.

If not found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and STOP.

### 6b — Populate template

Apply textarea-safe escaping to `POST_COPY_TEXT_RAW` before substitution (`&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`) and store as `POST_COPY_TEXT`.

**feature-card.html variables:**

| Variable | Value |
|----------|-------|
| `{{TITLE}}` | `$PROJECT_NAME — [topic headline]` (e.g. "my-app — New Features") |
| `{{SUBTITLE}}` | `$PROJECT_DESCRIPTION` (one sentence) |
| `{{BADGE}}` | Badge text from Phase 3 |
| `{{BULLETS}}` | Top 3–5 items as `<li>text</li>` elements |
| `{{FOOTER_NOTE}}` | Repo URL or `$PATH_ROOT` |
| `{{POST_COPY_TEXT}}` | Escaped copy |

**diff-card.html variables:**

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
| `{{POST_COPY_TEXT}}` | Escaped copy |

### 6c — Save

```bash
mkdir -p ~/.claude/tmp
MEDIA_DIR="${PWD}/docs/media/social"
mkdir -p "$MEDIA_DIR"

SLUG=$(echo "$PROJECT_NAME-$TOPIC" | tr '[:upper:]' '[:lower:]' | \
       sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
SAVE_PATH="$MEDIA_DIR/project-${SLUG}-${DATE}.html"
```

Write the populated HTML to `~/.claude/tmp/project-share-card.html` and to `$SAVE_PATH`.

### 6d — Screenshot

1. Get free port: `python3 "$PLUGIN_DIR/scripts/find_free_port.py"` → `$PORT`
2. Start server: `cd ~/.claude/tmp && python3 -m http.server $PORT & SERVER_PID=$!; echo "PID:$SERVER_PID"`
3. Load Playwright via ToolSearch: `select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_wait_for`
4. Navigate to `http://localhost:$PORT/project-share-card.html`
5. Wait `networkidle` or 2000ms, then screenshot to `~/.claude/tmp/project-share-card.png`
6. Kill server: `kill $SERVER_PID 2>/dev/null || true`

Fallback: if Playwright is unavailable, tell the user:
> "Screenshot could not be generated. The populated HTML is at `~/.claude/tmp/project-share-card.html` — open it in a browser to screenshot manually."

---

## Phase 7 — Deliver

1. **Platform label** as a markdown heading (e.g., `## LinkedIn Copy`)
2. Copy in a fenced code block
3. Character count: `[NNN / max chars]` — warn if over limit
4. Attach `~/.claude/tmp/project-share-card.png` via `SendUserFile` (if screenshot succeeded)
5. Saved path: `docs/media/social/project-{slug}-{date}.html`
6. Note: "Open the saved HTML in a browser to view the card and use the **Copy post** button."

**STOP.** Do not run further git commands, open browsers, or take any action beyond delivering the copy and card.
