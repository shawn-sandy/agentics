# session-tools

Export Claude Code session transcripts to Markdown so they can serve as reference and educational material.

## Skills

- **export-session** — converts a session JSONL transcript (`~/.claude/projects/<project-slug>/<session-id>.jsonl`) into `{plansDirectory}/sessions/<date>-<slug>.md`. Extracts user/Claude turns, marks tool calls as one-liners, and filters harness noise (system reminders, sidechains, tool results). Trigger with `/export-session` or by asking to export/save/archive a session as Markdown.

## Install

```bash
/plugin install session-tools@agentics-kit
```

Or load locally:

```bash
claude --plugin-dir ./kit/plugins/session-tools
```
