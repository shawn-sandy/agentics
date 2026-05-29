---
name: social-share
description: "Social media share router — classifies content type and runs the right skill. Use when asked to share what you're working on or post code, a blog, video, or project update."
allowed-tools: Bash, Read, Write, Skill
---

# social-share

Route a natural-language share request to the right social media workflow.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Classify | Identify content type using first-match-wins rules |
| 2 — Capture | For code selections: write code to a temp file before dispatching |
| 3 — Defaults | Resolve `--platform` and any extra flags |
| 4 — Dispatch | Invoke target skill directly via `Skill(...)` |

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

## Phase 1 — Classify

Evaluate rules **top-to-bottom; first match wins.** Do not ask the user anything.

| # | Condition on `$ARGUMENTS` or session context | Target | Extra flags |
|---|----------------------------------------------|--------|-------------|
| 1 | URL matching `github\.com/.*/blob/` or `raw\.githubusercontent\.com/` | `share-github` | `--source=<url>` |
| 2 | URL matching `youtube\.com`, `youtu\.be`, or `vimeo\.com` | `share-video` | `--source=<url>` |
| 3 | Any other `https?://` URL **or** a path ending `.md`/`.mdx`/`.markdown` | `share-blog` | `--source=<url-or-path>` |
| 4 | Fenced code block (` ``` `) present in the message, or IDE context includes a highlighted selection or open code file | `share-selection` | `--code-file=` + `--objective=` (see Phase 2) |
| 5 | Matches: `launch`, `release`, `shipped`, `announcing`, `went live`, or `v\d` | `share-project` | `--topic=release` |
| 6 | Matches: `progress`, `update`, `working on`, `lately`, `this week`, `building` | `share-project` | `--topic=features` |
| 7 | Matches: `browse`, `library`, `saved posts`, `prior post`, `media library`, `my posts` | `media-library` | *(none)* |
| 8 | Matches: `my session`, `session recap`, `session summary`, `session stats`, `tokens today`, `usage today`, `this session`, `what I worked on`, `what I did today`, or standalone `session` | `share-session` | *(none)* |
| 9 | **Fallback A** — git diff has changes: `git rev-parse --git-dir 2>/dev/null && git diff HEAD~1 --stat 2>/dev/null \| grep -c .` returns a positive integer | `share-code` | *(none)* |
| 10 | **Fallback B** — nothing else matched | `share-project` | `--topic=changes` |

If **no rule 1–8 matched** and no git repository exists and no source URL/code was provided: output
`social-share: nothing to share — no git repository and no source provided.` and **STOP**.

Set `TARGET_SKILL` and `EXTRA_FLAGS` from the matching row before continuing.

---

## Phase 2 — Capture Code (share-selection only)

If rule 4 matched:

1. Extract `CODE_RAW` from the matched source:
   - Fenced block in the message: use its contents.
   - IDE-provided highlighted lines or open file path: read the file.

2. Infer `OBJECTIVE` from the user's prompt (e.g. "highlight the perf win" → `"highlight the performance win"`). If not inferable from the prompt, use `"demonstrate this code"`.

3. Write `CODE_RAW` to a temp file:

```bash
mkdir -p ~/.claude/tmp
```

Write the raw code content to `~/.claude/tmp/social-share-selection.txt`.

4. Set `EXTRA_FLAGS="--code-file=~/.claude/tmp/social-share-selection.txt --objective=<OBJECTIVE>"`.

---

## Phase 3 — Resolve Defaults

Set `PLATFORM=all` unless the user specified a platform in `$ARGUMENTS`:
- Detect phrases like "post to twitter", "share on LinkedIn", "for Bluesky" → map to the
  corresponding `--platform=<value>`.

Build `DISPATCH_FLAGS`:

```
--platform=<PLATFORM> <EXTRA_FLAGS>
```

For `share-project`, also include `--topic=<value>` from Phase 1:

```
--topic=<value> --platform=<PLATFORM>
```

---

## Phase 4 — Dispatch

Invoke the target skill directly:

```
Skill(skill: "social-media-tools:<TARGET_SKILL>", args: "<DISPATCH_FLAGS>")
```

Wait for the skill to complete and report its output to the user.
