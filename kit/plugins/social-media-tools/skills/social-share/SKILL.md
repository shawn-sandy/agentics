---
name: social-share
description: "Social media share router — classifies content type and runs the right skill. Dispatches to the right share-* skill based on content type. Use when asked to share what you're working on."
allowed-tools: Bash, Read, Write, Skill, ToolSearch, ExitPlanMode
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
| 4 — Dispatch | Exit plan mode silently; invoke target skill directly via `Skill(...)` |

---

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

If not found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 0b — Load Project Sharing Config

Check for a `SOCIAL.md` at the project root (see `$PLUGIN_DIR/references/social-config.md`
for format details):

```bash
SOCIAL_CONFIG=""
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -f "$PWD/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$PWD/SOCIAL.md"
elif [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$GIT_ROOT/SOCIAL.md"
fi
```

If `SOCIAL_CONFIG` is non-empty, `Read` it silently. Extract:

- `DEFAULT_PLATFORM` from `## Defaults` → `Platform:` line
- `DEFAULT_TONE` from `## Defaults` → `Tone:` line
- `FOCUS_AREAS` from `## Focus` bullet list
- `AUDIENCE` from `## Audience` section

These values inform the router's platform resolution in Phase 3. Downstream
skills also load `SOCIAL.md` independently via their own Phase 0b, so the
router does not need to forward all fields — only `--platform` is passed
as a dispatch flag.

---

## Phase 1 — Classify

Evaluate rules **top-to-bottom; first match wins.** Do not ask the user anything.

| # | Condition on `$ARGUMENTS` or session context | Target | Extra flags |
|---|----------------------------------------------|--------|-------------|
| 1 | URL matching `github\.com/.*/blob/` or `raw\.githubusercontent\.com/` | `share-github` | `--source=<url>` |
| 2 | URL matching `youtube\.com`, `youtu\.be`, or `vimeo\.com` | `share-video` | `--source=<url>` |
| 3 | Any other `https?://` URL **or** a path ending `.md`/`.mdx`/`.markdown` | `share-blog` | `--source=<url-or-path>` |
| 4 | File path ending `.tsx` or `.jsx` in the message/arguments, or IDE context's highlighted selection or open file is a `.tsx`/`.jsx` file, or a pasted fenced block is tagged `tsx`/`jsx` — **and** the source defines a React component (a function/class component, or a default/named export that returns JSX). Non-component `.tsx`/`.jsx` — tests (`*.test.*`/`*.spec.*`), Storybook stories (`*.stories.*`), route modules, hooks-only or utility files, arbitrary JSX fragments — does **not** match and falls through to rule 5 (`share-selection`) | `share-react` | `--source=<path>` when a concrete path is known; otherwise *(none)* — `share-react` captures selection/paste itself |
| 5 | Fenced code block (` ``` `) present in the message, or IDE context includes a highlighted selection or open code file | `share-selection` | `--code-file=` + `--objective=` (see Phase 2) |
| 6 | Matches: `launch`, `release`, `shipped`, `announcing`, `went live`, or `v\d` | `share-project` | `--topic=release` |
| 7 | Matches: `progress`, `update`, `working on`, `lately`, `this week`, `building` | `share-project` | `--topic=features` |
| 8 | Matches: `browse`, `library`, `saved posts`, `prior post`, `media library`, `my posts`, `gallery`, `view shares` | `media-library` | *(none)* |
| 9 | Matches: `explain`, `how does`, `how do`, `how it works`, `what is`, `what does`, `describe` — **unless** the phrase also contains `my session`, `session recap`, `session summary`, `session stats`, `this session`, `what I worked on`, `what I did`, `tokens today`, or `usage today` (those fall through to rule 10) | `share-explanation` | `EXTRA_FLAGS` = `$ARGUMENTS` with only the `--platform=...` token removed; all other text and flags (including `--tone`, the query text, etc.) are forwarded as-is. Phase 3 then prepends `--platform=<PLATFORM>` to avoid duplicates. |
| 10 | Matches: `my session`, `session recap`, `session summary`, `session stats`, `tokens today`, `usage today`, `this session`, `what I worked on`, `what I did today`, or standalone `session` | `share-session` | *(none)* |
| 11 | **Fallback A** — git diff has changes: `git rev-parse --git-dir 2>/dev/null && git diff HEAD~1 --stat 2>/dev/null \| grep -c .` returns a positive integer | `share-code` | *(none)* |
| 12 | **Fallback B** — nothing else matched | `share-project` | `--topic=changes` |

If **no rule 1–10 matched** and no git repository exists and no source URL/code was provided: output
`social-share: nothing to share — no git repository and no source provided.` and **STOP**.

Set `TARGET_SKILL` and `EXTRA_FLAGS` from the matching row before continuing.

---

## Phase 2 — Capture Code (share-selection only)

If rule 5 matched:

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

Set `PLATFORM` using this priority:
1. Explicit platform in `$ARGUMENTS` (e.g. "post to twitter" → `twitter`)
2. `DEFAULT_PLATFORM` from `SOCIAL.md` (if loaded in Phase 0b)
3. `all` (fallback)

For the canonical platform name list, see `$PLUGIN_DIR/references/platforms.md`.
- Detect phrases naming any supported platform (e.g. "post to twitter", "share on LinkedIn",
  "for Bluesky", "on Substack", "Substack note") → map to the corresponding `--platform=<value>`.

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
