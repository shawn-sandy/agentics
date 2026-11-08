# Add export-session skill to social-media-tools

> Ships an `export-session` skill in the `social-media-tools` plugin (v2.14.0) that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and `scripts/export_session.py`
- Python script parses JSONL transcripts: keeps user/assistant turns, skips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and writes `<date>-<slug>.md` with YAML frontmatter
- `social-media-tools` bumped to `2.14.0` in `.claude-plugin/marketplace.json`
- Standalone `session-tools` plugin removed (folded into social-media-tools)
- Skill listed in plugin README and root `CLAUDE.md` table
- CHANGELOG entry added

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions — export-session activation and script invocation | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Converter — JSONL transcript parser, Markdown writer | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — social-media-tools 2.14.0, session-tools removed | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Release notes — 2.14.0 entry | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin documentation — export-session skill listed | Modified |

## How it works

Session transcripts at `~/.claude/projects/<slug>/<id>.jsonl` contain raw JSONL mixed with harness records — tool calls, system reminders, and injection markers — that make them unreadable as prose. The Python converter script handles the transformation outside Claude's context window, which is critical for large transcripts that would otherwise blow the context budget.

The script reads the JSONL line by line, keeping only `role: user` and `role: assistant` turns, and strips harness-injected content by matching known tag patterns (`<system-reminder>`, `<local-command-*>`, `<command-*>`). Sidechains (sub-agent turns embedded in a session) are skipped by detecting the sidechain marker in the JSONL structure.

Output is a Markdown file named `<date>-<slug>.md` with YAML frontmatter (`type: session-export`, source path, timestamp) followed by alternating User/Claude blocks. The file lands under `{plansDirectory}/sessions/`, making it discoverable by the plans gallery and other plan-agent skills.

The `SKILL.md` uses `${CLAUDE_PLUGIN_ROOT}` to reference the script, so the path resolves correctly regardless of where the plugin is installed. The `allowed-tools` list covers `Bash` for invoking the script.

## How to use it

The skill activates on "export session" or similar phrases:

```
/export-session                          # export most recent session
```

The skill runs `export_session.py` against the most recent session JSONL and writes a Markdown file to `{plansDirectory}/sessions/`. It prints the output path on completion.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
