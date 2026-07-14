---
name: session-artifact
description: "Publishes a session recap as a claude.ai artifact. Extracts transcript turns into a Summary, Decisions, and Learnings recap, scrubs it, then publishes. Use when asked to share a session recap."
allowed-tools: Bash, Read, Write, Edit, Skill, Artifact, AskUserQuestion, ToolSearch, ExitPlanMode
---

# session-artifact

Turn a Claude Code session into a recap page a teammate can actually review —
what was decided, what was learned, and what was touched — published to
claude.ai as a live artifact.

## Overview

A transcript is a log; a recap is a deliverable. This skill extracts the session's
turns with a bundled script, writes them up in reviewer-first order, scrubs the
result, saves it under `{plansDirectory}/sessions/`, and publishes the Markdown
directly — Markdown sources render as styled pages at the lowest token cost.

The extractor is bundled rather than borrowed from `social-media-tools`, so this
plugin works standalone with no install-order dependency.

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** —
skip this step entirely when not in plan mode. When calling: use `ToolSearch`
with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

## Step 1 — Locate the transcript

- If the user passed a `.jsonl` path or a session ID, use it (session IDs live at
  `~/.claude/projects/<project-slug>/<session-id>.jsonl`).
- Otherwise take the newest transcript for this project:

  ```bash
  ls -t ~/.claude/projects/"$(pwd | sed 's|[/.]|-|g')"/*.jsonl 2>/dev/null | head -1
  ```

- If that directory does not exist (common when running from a **worktree** —
  the slug is derived from the worktree path, not the main repo), list
  `~/.claude/projects/`, pick the entry matching the main repo path, and take its
  newest `.jsonl`.

Never publish a transcript from another project unless the user points at it
explicitly.

## Step 2 — Extract the turns

Run the bundled script. **Do not read the JSONL into context yourself** — a
transcript is far larger than the recap and reading it wastes the context the
recap needs:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/session-artifact/scripts/export_session.py" <transcript.jsonl> <output-dir>
```

It skips tool results, sidechains, and system reminders, writes
`<date>-<slug>-<id>.md` with frontmatter, and prints the path. Read that file —
it is the source for the recap, not the final deliverable.

## Step 3 — Write the recap (reviewer-first order)

Rewrite the extracted turns into these sections, in this order. A reviewer reads
top-down and stops when they have what they need, so the answer goes first:

1. **Summary** — what happened, in a few sentences. Lead with the outcome.
2. **Decisions** — each decision *with its rationale*. A decision without its
   why is unreviewable — the reader cannot tell whether it still holds.
3. **Learnings** — approaches tried and abandoned, and gotchas discovered. This
   is the section that saves the next person a day; never drop it, and if the
   session genuinely produced none, say so rather than omitting the heading.
4. **Files touched** — paths with a one-line note on what changed in each.

Keep the frontmatter the script wrote and add `title:`. Write the result to
`{plansDirectory}/sessions/` (read `plansDirectory` from `.claude/settings.json`,
falling back to `docs/plans`). Saving it there — rather than the scratchpad —
is what lets the `artifact-url:` be committed and survive for a later republish.

## Step 4 — Scrub before publishing (blocking gate)

Run `social-media-tools:security-scrub` over the recap file via the `Skill` tool.
Sessions quote command output and file contents, so they leak more readily than
curated prose.

- `GATE RESULT: BLOCKED` → **hard stop.** No publish, no override. Report the
  masked findings and stop.
- `GATE RESULT: CANCELLED` → the user declined. Stop.
- `GATE RESULT: APPROVED` → continue.

If `security-scrub` is unavailable, say the scan could not run and ask via
`AskUserQuestion` before continuing — never skip the gate silently.

## Step 5 — Publish and record the URL

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.
Publish the saved `.md` path with a one-sentence `description` and the favicon
`📋` (keep it stable across republishes).

**On success**, write the returned URL back into the file's frontmatter as
`artifact-url:` so a later session republishes to the same page:

```yaml
---
session-id: "..."
date: 2026-07-14
type: session-export
artifact-url: https://claude.ai/public/artifacts/...
---
```

On a republish, read `artifact-url:` first and pass it to `Artifact`'s `url`
parameter. Without it, a new session mints a new page and the shared link rots.

**On publish failure**, the saved Markdown file *is* the deliverable — report its
path plainly and note that publishing did not happen and why. Commit it and the
recap still reaches the team.
