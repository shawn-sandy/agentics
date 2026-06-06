# Topic Extraction Patterns

Reference data for the `share-project` skill. Each section defines the card template, badge label, platform tone, and git/file extraction commands for a topic.

---

## Topic Overview

| Topic | Card Template | Badge | Use For |
|-------|--------------|-------|---------|
| `features` | `feature-card.html` | `New Features` | New capabilities shipped in the last N days |
| `bugs` | `diff-card.html` | `Bug Fix` | Resolved issues and fixes |
| `changes` | `diff-card.html` | `What's Changed` | General recent activity |
| `release` | `feature-card.html` | `v{VERSION}` | Version announcement |

---

## Tone Guide

| Topic | LinkedIn | Twitter/X | Bluesky |
|-------|----------|-----------|---------|
| `features` | Lesson arc: technique behind the feature → what readers can apply → learn-more | Punchy takeaway — the technique behind the strongest feature | "Here's a technique from [feature]" |
| `bugs` | Root-cause lesson: what went wrong → the principle that fixes it → what readers can apply | `#bugfix lesson: [root cause] → [principle]` | Brief and instructive |
| `changes` | "Here's what we learned building [project]" + bulleted techniques | Top 2 lessons in 280 chars | "Here's what we learned 👇" |
| `release` | Key development principle the release embodies → technique highlights → learn-more | `🚀 [name] v[N] — key technique: [lesson]` | Same brevity as Twitter/X |

The closing CTA above is a topic-matched **learn-more** CTA tied to the project/topic
(e.g. "more `<project>` breakdowns on my feed — follow along to keep learning") — varied
each post, never a generic "follow me"; on Twitter/Bluesky the **takeaway wins** — drop
the learn-more line when budget is tight. See the Learn-More CTA rule in
`$PLUGIN_DIR/references/platforms.md`.

---

## Extraction Commands

All commands use `git -C "$PATH_ROOT"` so they work when the analyzed project is not `$PWD`.

### features

```bash
# Feature commits via conventional commit prefix
git -C "$PATH_ROOT" log --oneline --after="${DAYS} days ago" \
    --format="%s" 2>/dev/null | grep -iE "^feat(\(|:)" | head -10

# README Features section
grep -A 20 "^## Features\|^### Features\|^## What's New" \
    "$PATH_ROOT/README.md" 2>/dev/null | head -25

# CHANGELOG features block (latest version)
grep -A 30 "^## v\|^## \[" "$PATH_ROOT/CHANGELOG.md" 2>/dev/null | \
    grep -A 20 "[Ff]eature\|[Aa]dded\|[Nn]ew" | head -20
```

### bugs

```bash
# Fix commits via conventional commit prefix
git -C "$PATH_ROOT" log --oneline --after="${DAYS} days ago" \
    --format="%s" 2>/dev/null | grep -iE "^fix(\(|:)" | head -10

# CHANGELOG bug fix block (latest version)
grep -A 30 "^## v\|^## \[" "$PATH_ROOT/CHANGELOG.md" 2>/dev/null | \
    grep -A 20 "[Ff]ix\|[Bb]ug\|[Pp]atch\|[Rr]esolved" | head -20
```

### changes

```bash
# All recent commits (7 days for changes to stay current)
git -C "$PATH_ROOT" log --oneline --after="7 days ago" \
    --format="%s" 2>/dev/null | head -15

# Diff stats summary
git -C "$PATH_ROOT" diff --stat HEAD~5..HEAD 2>/dev/null | head -20

# CHANGELOG top section (typically covers latest release)
head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```

### release

```bash
# Latest semver tag
git -C "$PATH_ROOT" tag --sort=-version:refname 2>/dev/null | head -1

# Version from manifest (first match wins)
cat "$PATH_ROOT/package.json" 2>/dev/null | grep '"version"' | head -1
cat "$PATH_ROOT/pyproject.toml" 2>/dev/null | grep '^version' | head -1
cat "$PATH_ROOT/Cargo.toml" 2>/dev/null | grep '^version' | head -1

# Full CHANGELOG top section for release notes
head -80 "$PATH_ROOT/CHANGELOG.md" 2>/dev/null
```

---

## Project Metadata Priority

Extract `PROJECT_NAME`, `PROJECT_VERSION`, `PROJECT_DESCRIPTION` in this order:

| Priority | Source | Fields |
|----------|--------|--------|
| 1 | `package.json` | `name`, `version`, `description` |
| 2 | `pyproject.toml` | `[project] name`, `version`, `description` |
| 3 | `Cargo.toml` | `[package] name`, `version`, `description` |
| 4 | `go.mod` | module name (first line), N/A for version/description |
| 5 | `README.md` | First H1 as name; first non-heading paragraph as description |
| 6 | `$PATH_ROOT` basename | Last path segment as name (last resort) |

If version is not found anywhere: use `"latest"` as placeholder.

---

## Card Population Reference

### feature-card.html — variables for features / release topics

| Variable | Source |
|----------|--------|
| `{{TITLE}}` | `$PROJECT_NAME — [topic headline]` |
| `{{SUBTITLE}}` | `$PROJECT_DESCRIPTION` (one sentence, truncated to 120 chars if needed) |
| `{{BADGE}}` | `New Features` or `v$PROJECT_VERSION` |
| `{{BULLETS}}` | Top 3–5 items as `<li>item text</li>` (no wrapping `<ul>`) |
| `{{FOOTER_NOTE}}` | Repo URL or last 2 path segments of `$PATH_ROOT` |
| `{{COPY_PANELS}}` | Copy panel HTML — one panel (single site) or three per-site panels (All sites); see `$PLUGIN_DIR/references/copy-panels.md` |

### diff-card.html — variables for bugs / changes topics

| Variable | Source |
|----------|--------|
| `{{FILENAME}}` | `$PROJECT_NAME / $TOPIC` |
| `{{BADGE}}` | `Bug Fix` or `What's Changed` |
| `{{HUNK_1_HEADER}}` | `@@ Recent $TOPIC @@` |
| `{{HUNK_1_ROWS}}` | Top items as `<tr class="add"><td class="ln">+</td><td class="code"> item</td></tr>` |
| `{{HUNK_2_HEADER}}` | *(empty — omit second hunk)* |
| `{{HUNK_2_ROWS}}` | *(empty)* |
| `{{STAT_ADD}}` | Count of items listed |
| `{{STAT_DEL}}` | `0` |
| `{{WORKFLOW_SUMMARY}}` | `Last $DAYS days · $PROJECT_NAME` |
| `{{COPY_PANELS}}` | Copy panel HTML — one panel, or three for All sites |
