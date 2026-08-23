# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` (v2.14.0) that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and `scripts/export_session.py`
- Skill resolves output directory from `plansDirectory` in `.claude/settings.json`, falls back to `docs/plans/sessions`
- Python script parses JSONL line-by-line, filters to user/assistant turns, strips harness-injected messages and tool-result-only records, and writes `<date>-<slug>.md` with YAML frontmatter
- Bundled bin/ wrapper (`social-export-session`) exposes the script on the Bash tool's `PATH` without requiring `${VAR}` substitution in commands
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry
- Removed the standalone `session-tools` plugin from the marketplace so session export lives in one place

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill contract — workflow steps and invocation | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Converter — JSONL to Markdown with frontmatter | Created |
| `.claude-plugin/marketplace.json` | Plugin version registry — social-media-tools bumped to `2.14.0` | Modified |

## How it works

Session transcripts live at `~/.claude/projects/<slug>/<session-id>.jsonl`. Each line is a JSON record carrying harness metadata, sidechain records, tool calls, tool results, and the actual user/assistant conversation turns — mixed together. The raw JSONL is unusable as reference material without filtering.

The skill's workflow has three stages. First it resolves the output directory: it reads `plansDirectory` from `.claude/settings.json` and appends `/sessions`, falling back to `docs/plans/sessions` if the setting is absent. Second it locates the transcript: if the user passed a `.jsonl` path or session ID it uses that directly, otherwise it lists the project's transcript directory and picks the most recent file.

Third, it delegates conversion to the bundled `social-export-session` bin/ wrapper rather than reading the JSONL into Claude's context. The wrapper calls `export_session.py` with two positional arguments (transcript path and output directory). The bin/ pattern exists because the Bash tool refuses commands containing `${VAR}` or `$VAR` shell variable references, so the script path and arguments must be literal strings.

The Python script (`export_session.py`) processes the JSONL record-by-record. It skips any record whose `isSidechain` flag is true, and any record whose `type` is not `user` or `assistant`. Within user records it additionally skips messages whose content is composed entirely of `tool_result` blocks — these are intermediate tool outputs, not user-authored text. It also discards text that begins with `<system-reminder>`, `<command-`, `<local-command-`, or `<task-notification` — harness-injected context that should never appear in a readable export.

The output file is named `<date>-<slug>.md`, where the date comes from the first record's timestamp and the slug is derived from the first user message. The file opens with YAML frontmatter carrying `session-id`, `date`, `source`, and `type: session-export`, followed by one Markdown section per conversation turn.

The `type: session-export` frontmatter tag is the hook for future indexing: the plans gallery can identify exported sessions as a distinct category without inspecting content.

## How to use it

```bash
# Load the plugin and run the skill
claude --plugin-dir ./kit/plugins/social-media-tools
/export-session

# Export a specific transcript by path
/export-session ~/.claude/projects/my-project/abc123.jsonl

# Export by session ID (resolves to ~/.claude/projects/<slug>/<id>.jsonl)
/export-session abc123def456
```

The skill prints the written file path. Exported files appear under `docs/plans/sessions/` (or the configured `plansDirectory/sessions`) with frontmatter identifying them as `type: session-export`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
- Related docs: `kit/plugins/social-media-tools/skills/export-session/SKILL.md`
