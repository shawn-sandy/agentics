# Add export-session skill to social-media-tools

> `export-session` converts a raw Claude Code session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-27 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and `scripts/export_session.py`.
- The script parses JSONL transcripts, retains user/assistant turns, and skips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`).
- Output is written as `<date>-<slug>.md` with YAML frontmatter (`type: session-export`).
- Removed the standalone `session-tools` plugin; `social-media-tools` is now the single owner.
- Bumped `social-media-tools` to `2.14.0` with CHANGELOG entry and updated README and root `CLAUDE.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Converter script | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin documentation | Modified |

## How it works

`export_session.py` reads a JSONL transcript line by line. It filters to `user` and `assistant` roles, strips harness-specific noise (`<system-reminder>`, `<local-command-*>`, `<command-*>` XML blocks), and writes the remaining turns to Markdown.

The output file is named `<date>-<slug>.md` where the date comes from the transcript's first message and the slug is derived from the project path. YAML frontmatter records `type: session-export`, the original transcript path, and the session date, making the exported files discoverable by the plans gallery.

The skill uses `${CLAUDE_PLUGIN_ROOT}` to locate the script, ensuring the path resolves correctly regardless of where Claude Code is invoked from.

## How to use it

```
/social-media-tools:export-session
```

Exports the current or most-recent session transcript to `{plansDirectory}/sessions/`. Activated by description match on session export requests.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `87285986` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
