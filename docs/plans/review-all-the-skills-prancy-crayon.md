# Plan: Grant Social-Media-Tools Plugin Bash Permissions

## Context

The `social-media-tools` plugin (`kit/plugins/social-media-tools`) contains 8 skills that generate social media copy and dark-mode card images. Each skill runs a series of Bash commands across its multi-phase workflow (git content discovery → template rendering → Python HTTP server → Playwright screenshot → teardown).

All skills already declare `Bash` in their `allowed-tools` frontmatter — so the tool itself is approved. The gap is that specific Bash commands are not in the project's `permissions.allow` list, which causes Claude Code to prompt the user mid-run for each unapproved command (especially for network-facing operations like starting an HTTP server and process management like `kill`).

**No SKILL.md changes are needed.** The fix is entirely in `.claude/settings.json`.

---

## File to Modify

**`.claude/settings.json`** — add 19 entries to `permissions.allow`, grouped by command family.

---

## Permissions to Add

The following patterns cover every Bash command used across all 8 skills. They are grouped by purpose in the allow array.

### 1 — Git content discovery (code-share, scan-for-shares, project-share)

```
"Bash(git diff*)"           — git diff HEAD~1 --stat, git diff --stat HEAD~5..HEAD
"Bash(git log*)"            — git log --oneline -5, git log --oneline --after=...
"Bash(git show*)"           — git show --stat --format="" [hash], git show -U3 [hash]
"Bash(git tag*)"            — git tag --sort=-version:refname
"Bash(git rev-parse*)"      — git rev-parse --git-dir
"Bash(git -C*)"             — git -C "$PATH_ROOT" log/tag/diff ... (project-share)
```

### 2 — Template and media-library file discovery (all card-generating skills)

```
"Bash(find ~/.claude*)"     — find ~/.claude/plugins .../social-media-tools/templates ...
"Bash(ls ~/devbox*)"        — local dev template check: ls ~/devbox/agentics/.../templates
"Bash(ls */docs/media/social*)"   — reuse check globs: ls .../diff-*.html, snippet-*.html, etc.
"Bash(ls -t */docs/media/social*)" — media-library listing: ls -t .../social/*.html
```

### 3 — Directory creation (all card-generating skills, scan-for-shares)

```
"Bash(mkdir -p ~/.claude/tmp)"           — temp card HTML/PNG files
"Bash(mkdir -p */docs/media/social)"     — persistent save directory
"Bash(mkdir -p .claude/digests)"         — scan-for-shares digest output
```

### 4 — Path and date utilities (all skills)

```
"Bash(realpath *)"     — resolve relative paths in blog-share, media-library
"Bash(dirname *)"      — derive PLUGIN_DIR from TEMPLATES_DIR
"Bash(date +%Y-%m-%d)" — build save-file date component
```

### 5 — Screenshot server pipeline (code-share, blog-share, video-share, github-code-share, project-share)

```
"Bash(python3 */find_free_port.py)"            — port allocation helper script
"Bash(cd ~/.claude/tmp && python3 -m http.server*)" — compound server start + PID capture
```

The compound command matches: `cd ~/.claude/tmp && python3 -m http.server 8080 & SERVER_PID=$!; echo "PID:$SERVER_PID"` (the `*` glob absorbs port, background operator, and PID echo).

### 6 — Server teardown (all card-generating skills)

```
"Bash(kill*)"   — kill $SERVER_PID 2>/dev/null || true
```

---

## Summary of Changes to `.claude/settings.json`

Insert 19 new entries into the existing `permissions.allow` array, after the 5 existing entries. The existing entries are unchanged.

```json
// New entries — social-media-tools plugin
"Bash(git diff*)",
"Bash(git log*)",
"Bash(git show*)",
"Bash(git tag*)",
"Bash(git rev-parse*)",
"Bash(git -C*)",
"Bash(find ~/.claude*)",
"Bash(ls ~/devbox*)",
"Bash(ls */docs/media/social*)",
"Bash(ls -t */docs/media/social*)",
"Bash(mkdir -p ~/.claude/tmp)",
"Bash(mkdir -p */docs/media/social)",
"Bash(mkdir -p .claude/digests)",
"Bash(realpath *)",
"Bash(dirname *)",
"Bash(date +%Y-%m-%d)",
"Bash(python3 */find_free_port.py)",
"Bash(cd ~/.claude/tmp && python3 -m http.server*)",
"Bash(kill*)"
```

---

## Skills Reviewed (no changes required)

| Skill | `allowed-tools` complete? | Notes |
|-------|--------------------------|-------|
| `code-share` | ✓ | Has `Bash, ToolSearch, AskUserQuestion, Read, Write, SendUserFile, Glob` |
| `blog-share` | ✓ | Has `Bash, ToolSearch, WebFetch, AskUserQuestion, Read, Write, SendUserFile, Glob` |
| `video-share` | ✓ | Has `Bash, ToolSearch, WebFetch, AskUserQuestion, Read, Write, SendUserFile, Glob` |
| `github-code-share` | ✓ | Has `Bash, ToolSearch, WebFetch, Skill, AskUserQuestion, Read, Write, SendUserFile, Glob` |
| `scan-for-shares` | ✓ | Has `Bash, Read, Grep, Glob, AskUserQuestion, Write, Skill` |
| `security-scrub` | ✓ | Has `Bash, Read, Grep` |
| `media-library` | ✓ | Has `Bash, Read, AskUserQuestion` |
| `project-share` | ✓ | Has `Bash, Read, Write, Glob, Grep, AskUserQuestion, ToolSearch, SendUserFile, Skill` |

All deferred tools (`WebFetch`, Playwright MCP tools) are correctly bootstrapped via `ToolSearch` in each skill that uses them. No frontmatter changes needed.

---

## Verification

After applying the change:

1. Load the plugin: `claude --plugin-dir ./kit/plugins/social-media-tools`
2. Trigger `code-share` with a recent commit in a git repo — confirm no permission prompts appear through all 6 phases
3. Trigger `blog-share` with a URL — confirm WebFetch, server start, and kill run silently
4. Trigger `media-library` — confirm `ls -t` runs without prompt
5. Trigger `scan-for-shares` — confirm git history scan and `.claude/digests/` creation run silently
6. Trigger `project-share --topic features` — confirm `git -C` and metadata extraction run without prompts

---

## Branch

`claude/vigilant-heisenberg-oY1O7`
