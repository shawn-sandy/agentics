# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` that converts a Claude Code session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-07-02 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and a bundled `scripts/export_session.py` converter.
- The Python script parses the JSONL transcript, keeps only `user` and `assistant` turns, strips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and writes `<date>-<slug>-<session-id-prefix>.md` with YAML frontmatter containing `session-id`, `date`, `source`, and `type: session-export`. The script handles huge transcripts out of context — Claude only invokes the script rather than reading JSONL lines directly.
- Skill resolves the output directory from `plansDirectory` in Claude Code settings (falls back to `docs/plans`); output lands at `<plansDirectory>/sessions/`.
- `social-media-tools` bumped to `2.14.0` in `.claude-plugin/marketplace.json`, with a `CHANGELOG.md` entry, README skill listing, and root `CLAUDE.md` table update.
- No standalone `session-tools` plugin was left behind — the skill was folded directly into `social-media-tools` which already owns session-derived content via `share-session`.

> See [CHANGELOG v2.14.0](../kit/plugins/social-media-tools/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions — workflow, resolver, script invocation | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Converter script — parses JSONL, filters harness noise, writes Markdown | Created |
| `kit/plugins/social-media-tools/README.md` | Plugin docs — `export-session` skill listing | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Release history — 2.14.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — `social-media-tools` version to 2.14.0 | Modified |
| `CLAUDE.md` | Repo overview — `export-session` mentioned in plugin table row | Modified |

## How it works

The skill starts by resolving the output directory: it reads `plansDirectory` from the Claude Code settings precedence chain (project-local → project → global), falling back to `docs/plans` if the key is absent. Output files land at `<plansDirectory>/sessions/`.

Transcript location follows a priority order: a user-supplied `.jsonl` path or session ID takes precedence; otherwise the skill lists `~/.claude/projects/<project-slug>/` and picks the newest file. Worktree detection is included — when the current working directory doesn't match a project slug, the skill lists `~/.claude/projects/` and selects the entry closest to the main repo path.

Conversion is entirely handled by the bundled `export_session.py` script, invoked via the `${CLAUDE_PLUGIN_ROOT}` env variable so the path is portable regardless of how the plugin was loaded. The script reads the raw JSONL line by line, retains only `user` and `assistant` role entries, and applies a filter to drop tool-result blocks, sidechain messages, and harness-injected system messages. The output Markdown carries `session-id`, `date`, `source`, and `type: session-export` frontmatter, followed by the cleaned conversation turns.

The output filename is `<YYYY-MM-DD>-<session-slug>-<session-id-prefix>.md` (the 8-character session ID prefix makes filenames collision-proof across sessions of the same date), placed under the resolved sessions subdirectory. The skill prints the generated output path on completion.

## How to use it

The skill activates when the user asks to export, save, or archive a session as Markdown (description trigger). It can also be invoked via command:

```
# Auto-detect most recent transcript for this project
/social-media-tools:export-session          (if a command wrapper exists)

# Or simply ask Claude:
"Export the current session to Markdown"
"Save this session as a reference doc"
"Archive today's session"
```

The skill reads `plansDirectory` from settings — set it in `.claude/settings.json` to control where sessions land:

```json
{ "plansDirectory": "docs/plans" }
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `11765e1` | 2026-07-02 | feat(social-media-tools): add export-session skill (2.14.0) (#368) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
- Changelog: [kit/plugins/social-media-tools/CHANGELOG.md](../kit/plugins/social-media-tools/CHANGELOG.md)
