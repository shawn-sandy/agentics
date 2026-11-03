# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-07-02 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with a `SKILL.md` and a bundled `scripts/export_session.py` converter.
- The Python script parses session JSONL, keeps user/assistant turns, skips harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`) and sidechains, and writes `<date>-<slug>.md` with YAML frontmatter.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry.
- Listed the skill in the plugin README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Transcript converter | Created |
| `kit/plugins/social-media-tools/README.md` | Plugin documentation | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

Session transcripts are raw JSONL mixing harness records with actual conversation turns, making them unreadable without filtering. The bundled Python script handles the filtering so large transcripts never enter Claude's context window.

The script reads the JSONL file passed as an argument, iterates each line, keeps only `user` and `assistant` role messages, strips harness-injected content patterns, and writes a Markdown file with frontmatter including `type: session-export` and the session slug derived from the source filename.

The SKILL.md uses `${CLAUDE_PLUGIN_ROOT}` to reference the script's path portably across machines and declares `allowed-tools` to prevent permission prompts when the script is run.

## How to use it

The skill activates when the user asks to export, save, or convert a session transcript. Invoke it explicitly as:

```
/social-media-tools:export-session
```

The skill locates the most recent project transcript (or accepts an explicit path), runs the bundled converter, and writes the Markdown file to `{plansDirectory}/sessions/`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
- Changelog: [social-media-tools CHANGELOG v2.14.0](../kit/plugins/social-media-tools/CHANGELOG.md)
