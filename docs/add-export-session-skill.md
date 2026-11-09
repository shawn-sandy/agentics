# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` v2.14.0 that converts a Claude session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/`.

<!-- generated:start -->

**Status:** Shipped 2026-07-02  **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and a bundled Python converter script.
- The `export_session.py` script parses session JSONL, keeps only human/assistant turns, skips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and writes a dated `<date>-<slug>.md` file with YAML frontmatter under `{plansDirectory}/sessions/`.
- Session processing happens entirely in the Python script, keeping large transcripts out of Claude's context window.
- The skill uses `${CLAUDE_PLUGIN_ROOT}` for the script path and declares `allowed-tools` in its frontmatter.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` (new skill = minor), added a CHANGELOG entry, and listed the skill in the plugin README and root `CLAUDE.md` table.
- No standalone `session-tools` plugin remains in `kit/plugins/` or `marketplace.json`; the functionality is consolidated under `social-media-tools` which already owns session-derived content via `share-session`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Converter script | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin README | Modified |
| `CLAUDE.md` | Root plugin table | Modified |

## How it works

Session transcripts are stored as JSONL files at `~/.claude/projects/<slug>/<id>.jsonl`. Each line is a JSON record that may represent a user turn, an assistant turn, a tool call, a tool result, a sidechain branch, or a harness-injected message. Reading these raw requires filtering out a significant amount of noise before the conversation is legible.

`export_session.py` handles this filtering by iterating through the JSONL line-by-line, emitting only records whose `type` is `human` or `assistant` and whose content does not match any of the harness injection patterns (`<system-reminder>`, `<local-command-*>`, `<command-*>`). Tool call and result records, which interleave with assistant turns in the raw format, are also skipped. The result is a clean back-and-forth conversation.

The output file is written to `{plansDirectory}/sessions/` as `<YYYY-MM-DD>-<slug>.md` with YAML frontmatter including `type: session-export`, the source path, and the export timestamp. This makes the file discoverable by any tool that indexes the plans directory, and the `type` field allows the plans gallery to categorize session exports separately from plan files.

The skill's `SKILL.md` uses `${CLAUDE_PLUGIN_ROOT}` to reference the script, which means the path is portable to any machine where the plugin is installed — the harness expands `${CLAUDE_PLUGIN_ROOT}` to the actual plugin installation directory at runtime.

## How to use it

```text
/social-media-tools:export-session
```

Invoke the skill to export the current session's transcript. The skill calls `export_session.py` with the current session's JSONL path and writes the Markdown file to the configured plans sessions directory.

For a manual test run against an existing transcript:

```bash
python3 kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py \
  $(ls -t ~/.claude/projects/<slug>/*.jsonl | head -1) \
  /tmp/sessions-test
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
