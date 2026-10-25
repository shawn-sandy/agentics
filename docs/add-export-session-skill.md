# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` (v2.14.0) that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-export-session-skill](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and `scripts/export_session.py`
- The Python script parses JSONL, keeps user/assistant turns, skips sidechains, tool results, and harness-injected messages, and writes `<date>-<slug>.md` with YAML frontmatter
- No standalone `session-tools` plugin remains — folded into `social-media-tools`
- Bumped `social-media-tools` to `2.14.0` with CHANGELOG entry and README update
- SKILL.md uses `${CLAUDE_PLUGIN_ROOT}` for the script path

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Transcript converter | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — social-media-tools 2.14.0 | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Release history — 2.14.0 entry | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin docs | Modified |

## How it works

The `export-session` skill locates the current session's JSONL transcript under `~/.claude/projects/<slug>/`. It delegates conversion to the bundled `export_session.py` script, which parses the JSONL line-by-line and keeps only genuine conversational turns (user and assistant roles). The script filters out sidechains, tool results, and harness-injected system messages (matching `<system-reminder>`, `<local-command-*>`, and `<command-*>` patterns) that would clutter the exported document.

The output is a Markdown file named `<date>-<slug>.md` placed in `{plansDirectory}/sessions/`. It includes YAML frontmatter with `type: session-export` plus the session metadata, followed by the cleaned conversation turns with speaker labels and timestamps.

Using a Python script keeps large transcripts — which can exceed 100,000 tokens — entirely out of Claude's context. The skill itself only invokes the script and reports the output path.

## How to use it

```
/social-media-tools:export-session      # export the current session to docs/plans/sessions/
```

Activation trigger: described in SKILL.md frontmatter. Requires `${CLAUDE_PLUGIN_ROOT}` to resolve the script path, which is set automatically when the plugin is loaded.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill](plans/add-export-session-skill.md)
