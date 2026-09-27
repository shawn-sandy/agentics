# Add export-session skill to social-media-tools

> Ships an `export-session` skill in `social-media-tools` (v2.14.0) that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and a bundled converter script
- `SKILL.md` resolves the output directory from `plansDirectory` in `.claude/settings.json` (falls back to `docs/plans`)
- Skill auto-discovers the most recent session transcript for the current project from `~/.claude/projects/`
- Bundled `social-export-session` bin wrapper invokes the Python script so large transcripts never enter Claude's context
- Script extracts user/Claude turns, skips tool results, sidechains, and system-injected messages, writes `<date>-<slug>.md` with YAML frontmatter (`session-id`, `date`, `source`, `type: session-export`)
- `social-media-tools` bumped to `2.14.0` in marketplace with CHANGELOG entry and README updates
- No standalone `session-tools` plugin remains in `kit/plugins/` or `marketplace.json`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill definition — workflow, directory resolution, transcript discovery | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Python converter — parses JSONL, filters turns, writes Markdown | Created |
| `.claude-plugin/marketplace.json` | `social-media-tools` version bumped to `2.14.0` | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | `2.14.0` entry for `export-session` | Modified |
| `kit/plugins/social-media-tools/README.md` | Skill listed in skills table and structure | Modified |

## How it works

Session transcripts are stored as JSONL files at `~/.claude/projects/<project-slug>/<session-id>.jsonl`. Each line is either a conversation turn or a harness record. Raw JSONL is unreadable for reference or education because harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>` blocks) are interspersed with the actual conversation.

The skill resolves the output directory by reading `plansDirectory` from `.claude/settings.json`, falling back to `docs/plans`. The target directory is always `<plansDirectory>/sessions`. If no transcript path is provided, the skill discovers the most recent transcript for the current project by running `ls -t` on `~/.claude/projects/<project-slug>/`. For worktree sessions where the directory name doesn't match, the skill lists `~/.claude/projects/` and matches by the main repo path.

The conversion is delegated entirely to the `social-export-session` bin wrapper (backed by `scripts/export_session.py`) — the JSONL file is never loaded into Claude's context. The Python script reads the JSONL line by line, keeps only `user` and `assistant` role turns, and strips harness-injected content. The output file is named `<date>-<slug>.md` and carries YAML frontmatter with `session-id`, `date`, `source`, and `type: session-export`.

The `type: session-export` frontmatter tag makes these files indexable as a distinct category — the Next Steps in the plan describe a future enhancement to surface them in the plans gallery.

## How to use it

```text
# Export the most recent session for this project
/social-media-tools:export-session

# Export a specific session by path
/social-media-tools:export-session ~/.claude/projects/my-project/abc123.jsonl

# Export a specific session by ID
/social-media-tools:export-session abc123
```

Exports are written to `<plansDirectory>/sessions/<date>-<slug>.md` and are plain Markdown with frontmatter, ready to read or convert further.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
