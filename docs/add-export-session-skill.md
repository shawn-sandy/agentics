# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` (v2.14.0) that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-export-session-skill](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- New skill directory `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and `scripts/export_session.py`
- Python converter that parses session JSONL, keeps user and assistant turns, strips `<system-reminder>`, `<local-command-*>`, and `<command-*>` harness noise, and writes `<date>-<slug>.md` with YAML frontmatter
- Standalone `session-tools` plugin removed — functionality consolidated into `social-media-tools`
- `social-media-tools` bumped to `2.14.0` with CHANGELOG entry, README update, and root CLAUDE.md table updated

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill contract — invocation, script path via `${CLAUDE_PLUGIN_ROOT}`, allowed-tools | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Transcript converter — JSONL parser and Markdown writer | Created |
| `.claude-plugin/marketplace.json` | `social-media-tools` 2.14.0, standalone `session-tools` plugin removed | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | `[2.14.0]` entry | Modified |
| `kit/plugins/social-media-tools/README.md` | `export-session` skill listed | Modified |
| `CLAUDE.md` | Root plugin table updated | Modified |

## How it works

Session transcripts stored at `~/.claude/projects/<slug>/<id>.jsonl` are mixed raw JSONL: user turns, assistant turns, tool call records, tool results, and harness-injected metadata all land in the same file with no visual separation. Reading one directly in Claude's context is impractical for any non-trivial session.

The skill delegates to `export_session.py`, referenced via `${CLAUDE_PLUGIN_ROOT}` so the path resolves regardless of where the plugin is loaded from. Using a script keeps the full JSONL content out of Claude's context window even for very long sessions.

The parser iterates JSONL records and keeps only messages with `role: user` or `role: assistant`. Within those records, tool result content and harness-injected tags — `<system-reminder>`, `<local-command-stdout>`, `<local-command-stderr>`, `<command-thinking>` — are stripped. What remains is the visible conversation.

Output is written to `{plansDirectory}/sessions/<date>-<slug>.md`. The file opens with YAML frontmatter including `type: session-export`, the session date, and the project slug, making it indexable by other plan-agent tooling that looks for the `type:` key.

`social-media-tools` was already the natural home for session-derived content: the `share-session` skill lives in the same plugin and operates over the same JSONL source. Consolidating here removed the standalone `session-tools` plugin entirely rather than leaving a two-plugin split.

## How to use it

```text
/social-media-tools:export-session
```

Converts the current project's most recent session transcript to Markdown and writes it to `docs/plans/sessions/<date>-<slug>.md`. The output file has `type: session-export` frontmatter and is readable as a conversation log stripped of harness noise.

To convert a specific transcript directly:

```bash
python3 kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py \
  ~/.claude/projects/<slug>/<id>.jsonl \
  docs/plans/sessions/
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill](plans/add-export-session-skill.md)
