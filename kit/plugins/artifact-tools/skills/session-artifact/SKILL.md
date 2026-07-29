---
name: session-artifact
description: "Publishes a session recap as a claude.ai artifact. Extracts transcript turns into a Summary, Decisions, and Learnings recap, scrubs it, then publishes. Use when asked to share a session recap."
allowed-tools: Bash, Read, Write, Edit, Skill, Artifact, WebFetch, AskUserQuestion, ToolSearch, ExitPlanMode
---

# session-artifact

Turn a Claude Code session into a recap page a teammate can actually review —
what was decided, what was learned, and what was touched — published to
claude.ai as a live artifact.

## Overview

A transcript is a log; a recap is a deliverable. This skill extracts the session's
turns with a bundled script, writes them up in reviewer-first order, scrubs the
result, saves it under `{plansDirectory}/sessions/`, and publishes an HTML
rendering of it.

The `.md` is the committed record and the thing to edit; the HTML is the render
that carries the `<title>`. Publishing the `.md` directly is cheaper and wrong —
it yields a page titled after the filename with the frontmatter visible as body
text (see `${CLAUDE_PLUGIN_ROOT}/references/titles.md`).

The extractor is bundled rather than borrowed from `social-media-tools`, so this
plugin works standalone with no install-order dependency.

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

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

Keep the frontmatter the script wrote. It contains a fallback `title:` derived
from the session's first turn — refine it against
`${CLAUDE_PLUGIN_ROOT}/references/titles.md` (read it first). You have read the
whole session by this point and the script had only one turn, so the subject you
can name is better than the one it guessed. Write the result to
`{plansDirectory}/sessions/` (read `plansDirectory` from `.claude/settings.json`,
falling back to `docs/plans`). Saving it there — rather than the scratchpad —
is what lets the `artifact-url:` be committed and survive for a later republish.

**Do not reuse the extractor's filename.** It carries the session id, and repos
that enforce a `verb-target` plan-filename convention reject it — the write
lands and a hook then blocks, leaving you to rename mid-run. Name the record
`<verb>-<target>-session.md` after the work the session did (for example
`add-team-recap-command-session.md`), and locate an existing record by its
frontmatter rather than by guessing the name an earlier run chose:

```bash
grep -rl 'session-id: "<session-id>"' <plansDirectory>/sessions/ 2>/dev/null
```

A hit is the record to update — read its republish key from that file and write
back to the same one. No hit means this session has no record yet; create one.

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

## Step 5 — Render the recap to HTML

Render the recap you just wrote into one self-contained HTML file in the
scratchpad. This is a render, not a rewrite — same recap, same sections, same
order:

- **`<title>`** — the frontmatter `title:`, verbatim. This is the whole reason
  the step exists; a `.md` source cannot carry it.
- **Drop the frontmatter block.** It is metadata for the `.md` record, not page
  copy. Published as Markdown it renders as a visible heading of raw YAML.
- Keep the `.md` under `{plansDirectory}/sessions/` as the committed record. The
  HTML is disposable — a later republish re-renders it.

## Step 6 — Publish and record the URL

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.
Publish the **HTML** path with a one-sentence `description` and the favicon
`📋` (keep it stable across republishes).

**On success**, write the returned URL back into the **`.md` record's**
frontmatter as `artifact-url:` so a later session republishes to the same page.
The HTML is disposable and cannot hold this:

```yaml
---
session-id: "..."
date: 2026-07-14
type: session-export
artifact-url: https://claude.ai/public/artifacts/...
---
```

On a republish, read `artifact-url:` from the `.md` first and pass it to
`Artifact`'s `url` parameter. **This is required on every republish, not just
cross-session ones** — a differing `file_path` always claims a new URL, and the
re-rendered HTML lands on a fresh scratchpad path each run. Skip `url` and the
shared link rots.

**On publish failure**, the saved Markdown file *is* the deliverable — report its
path plainly and note that publishing did not happen and why. Commit it and the
recap still reaches the team.

## Step 7 — Verify the page rendered

Runs only after a successful publish. `WebFetch` is a deferred tool: use
`ToolSearch` with `select:WebFetch` first.

Fetch the returned URL and confirm the fetched page contains the recap `title:`
from the `.md` record's frontmatter — not the `date:`, which Step 5 drops with
the rest of the frontmatter block. A returned URL is not evidence the page
rendered: a blank artifact returns a URL too.

If the title is absent, report the failure **with the URL** so the user can open
it, and do not report the publish as successful.
