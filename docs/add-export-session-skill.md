# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` that converts a Claude Code session JSONL transcript into readable Markdown under `{plansDirectory}/sessions/`.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and `scripts/export_session.py`.
- The Python script parses session JSONL, keeps user/assistant turns, skips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and writes `<date>-<slug>.md` with YAML frontmatter.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` (new skill = minor), added a CHANGELOG entry, and listed the skill in the plugin README and root CLAUDE.md table.
- Removed the standalone `session-tools` plugin from `kit/plugins/` and `marketplace.json`, consolidating session handling into `social-media-tools`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Transcript parser script | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — social-media-tools 2.14.0 | Modified |

## How it works

Session JSONL files in `~/.claude/projects/<slug>/` contain a mix of user turns, assistant turns, tool calls, tool results, and harness-injected system messages. Reading this raw format directly would flood Claude's context with irrelevant harness noise.

The skill delegates the heavy lifting to `scripts/export_session.py`, which the SKILL.md references via `${CLAUDE_PLUGIN_ROOT}` so the path resolves regardless of working directory. The script reads the JSONL line by line, filters to `user` and `assistant` roles only, and further strips messages whose content includes harness markers like `<system-reminder>` or `<local-command-*>`. Each kept turn is rendered as Markdown with a role header.

The output file is named `<date>-<slug>.md`, placed under `{plansDirectory}/sessions/` (defaulting to `docs/plans/sessions/`), and includes YAML frontmatter with `type: session-export` so tools that index the plans directory can categorize it separately from implementation plans.

The consolidation into `social-media-tools` rather than a standalone plugin follows the config-layer placement rule: session-derived content (the plugin already owns `share-session`) belongs in one plugin rather than two.

## How to use it

`export-session` is activated by its description: "Exports a Claude Code session transcript to Markdown. Converts session JSONL into readable reference material in the plans directory."

```
/social-media-tools:export-session                   # export the most recent session
```

The skill can also be invoked directly via the bundled script:
```bash
python3 kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py \
  <path-to-transcript.jsonl> <output-dir>
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
