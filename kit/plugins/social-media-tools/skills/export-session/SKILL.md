---
name: export-session
description: Exports a Claude Code session transcript to Markdown in the plans directory. Converts session JSONL into readable reference material. Use when the user asks to export, save, or archive a session as Markdown.
allowed-tools: Bash, Read
---

# Export Session

Convert a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/`.

## Workflow

1. **Resolve the output directory.** Read `plansDirectory` from `.claude/settings.json` (fall back to `docs/plans` if unset). Output dir is `<plansDirectory>/sessions`.

2. **Locate the session transcript.**
   - If the user passed a `.jsonl` path or a session ID, use it (session IDs resolve to `~/.claude/projects/<project-slug>/<session-id>.jsonl`).
   - Otherwise default to the most recent transcript for this project:

     ```bash
     ls -t ~/.claude/projects/"$(pwd | sed 's|[/.]|-|g')"/*.jsonl 2>/dev/null | head -1
     ```

     If that directory doesn't exist (e.g. running from a worktree), list `~/.claude/projects/` and pick the entry matching the main repo path, then take its newest `.jsonl`.

3. **Convert.** Run the bundled script — do not read the JSONL into context yourself:

   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/skills/export-session/scripts/export_session.py" <transcript.jsonl> <plansDirectory>/sessions
   ```

   The script extracts user/Claude turns (skipping tool results, sidechains, and system reminders), writes `<date>-<slug>.md` with YAML frontmatter, and prints the output path.

4. **Report.** Show the user the written file path and its title. If they asked to export multiple sessions, repeat step 3 per transcript.

## Notes

- Exports are plain Markdown with frontmatter (`session-id`, `date`, `source`, `type: session-export`) so they can be indexed or converted later.
- Never export transcripts from other projects unless the user explicitly points at them.
