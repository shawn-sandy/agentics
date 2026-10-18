# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/`.

<!-- generated:start -->

**Status:** Shipped 2026-07-02  **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/social-media-tools/skills/export-session/SKILL.md` — a new skill that exports session transcripts as Markdown.
- Bundled `scripts/export_session.py` inside the skill directory to parse JSONL transcripts, strip harness noise (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and write `<date>-<slug>.md` with YAML frontmatter under `{plansDirectory}/sessions/`.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry, README update, and root `CLAUDE.md` table row.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Transcript converter script | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin documentation | Modified |

## How it works

Raw session transcripts (`~/.claude/projects/<slug>/<id>.jsonl`) contain useful engineering history but are unreadable as JSONL mixed with harness records. The `export-session` skill delegates the conversion to a bundled Python script, keeping large transcripts out of Claude's context window.

`export_session.py` reads the JSONL file line by line, keeping only user and assistant turns and dropping sidechains, tool results, and harness-injected messages. The output file is named `<date>-<slug>.md` and written under `{plansDirectory}/sessions/` with YAML frontmatter including `type: session-export`.

The skill uses `${CLAUDE_PLUGIN_ROOT}` to resolve the bundled script path so it works regardless of where the plugin is installed.

## How to use it

Activate with the `export-session` skill description trigger, or load the plugin with `claude --plugin-dir ./kit/plugins/social-media-tools` and invoke `/export-session`. The output file appears under `docs/plans/sessions/`.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
