---
name: social-share
description: "Social media share router — classifies content type and runs the right skill in the background. Use when asked to share what you're working on or post code, a blog, video, or project update."
allowed-tools: Bash, Read, Write, Agent, ToolSearch, ExitPlanMode
---

# social-share

Route a natural-language share request to the right social media workflow and run it in the
background so you can keep working.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 1 — Classify | Identify content type using first-match-wins rules |
| 2 — Capture | For code selections: write code to a temp file before dispatching |
| 3 — Defaults | Resolve `--platform` and any extra flags |
| 4 — Dispatch | Exit plan mode silently; invoke `agent-social-share` in the background; ack |

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
| 8 | **Fallback A** — git diff has changes: `git rev-parse --git-dir 2>/dev/null && git diff HEAD~1 --stat 2>/dev/null \| grep -c .` returns a positive integer | `share-code` | *(none)* |
| 9 | **Fallback B** — nothing else matched | `share-project` | `--topic=changes` |

If no git repository exists **and** no source URL/code was provided: output
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
--platform=<PLATFORM> --background <EXTRA_FLAGS>
```

For `share-project`, also include `--topic=<value>` from Phase 1:

```
--topic=<value> --platform=<PLATFORM> --background
```

---

## Phase 4 — Dispatch

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode` first, then call
`ExitPlanMode`. Both steps happen silently with no user-visible output. This is a no-op when
plan mode is already off.

Invoke the `Agent` tool with:
- `subagent_type: "agent-social-share"`
- `run_in_background: true`
- `description: "Background social share"`
- `prompt`: a self-contained instruction embedding `TARGET_SKILL` and `DISPATCH_FLAGS`. Example:

  ```
  Run the social share workflow.
  Target skill: <TARGET_SKILL>
  Invoke: Skill(skill: "social-media-tools:<TARGET_SKILL>", args: "<DISPATCH_FLAGS>")
  Report the output path when done.
  ```

Output a single-line ack:

```
Background share started (<TARGET_SKILL>). You will be notified when the card is ready.
```

Do not poll, sleep, or check progress. The agent will proactively report when done.
