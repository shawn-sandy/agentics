# Add export-session skill to social-media-tools

> Adds an `export-session` skill to the `social-media-tools` plugin that converts a Claude Code session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/`.

<!-- generated:start -->

**Status:** Shipped 2026-07-02 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created the `export-session` skill at `kit/plugins/social-media-tools/skills/export-session/` with a `SKILL.md` and a bundled `scripts/export_session.py` converter (Why: the skill lives in social-media-tools because the plugin already owns session-derived content via `share-session`).
- The Python script parses a session JSONL, retains user and assistant turns, strips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and writes a `<date>-<slug>.md` file with YAML frontmatter (`session-id`, `date`, `source`, `type: session-export`).
- The skill resolves `plansDirectory` from `.claude/settings.json` (falling back to `docs/plans`) and outputs into a `sessions/` subdirectory, so exports land alongside plans without cluttering the root plans list.
- Removed any standalone `session-tools` plugin from `kit/plugins/` and `marketplace.json` — the skill is folded into `social-media-tools`.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry (new skill = minor bump).

> See [CHANGELOG v2.14.0](../kit/plugins/social-media-tools/CHANGELOG.md#v2140--2026-07-02--export-session-session-transcripts-to-markdown) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions — workflow for resolving output dir, locating transcript, running converter, and reporting | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Converter script — JSONL → Markdown with frontmatter, filters harness noise | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — `social-media-tools` version bumped to `2.14.0` | Modified |

## How it works

The skill follows a four-step workflow defined in `SKILL.md`:

**Step 1 — Resolve output directory.** The skill reads `plansDirectory` from `.claude/settings.json` using Claude Code settings precedence (project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`). It falls back to `docs/plans` if the key is unset. Output goes to `<plansDirectory>/sessions/`.

**Step 2 — Locate the session transcript.** If the user passed a `.jsonl` file path or a session ID, the skill uses it directly (session IDs resolve to `~/.claude/projects/<project-slug>/<session-id>.jsonl`). Otherwise it defaults to the most recent transcript for the current project via `ls -t ~/.claude/projects/"$(pwd | sed 's|[/.]|-|g')"/*.jsonl | head -1`. If that directory does not exist (e.g. running from a git worktree), it falls back to listing `~/.claude/projects/` and matching the main repo path.

**Step 3 — Convert.** The skill delegates to the bundled script using `${CLAUDE_PLUGIN_ROOT}` so the path stays portable regardless of where the plugin directory is mounted:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/export-session/scripts/export_session.py" <transcript.jsonl> <plansDirectory>/sessions
```

The script keeps only `role: user` and `role: assistant` content blocks, skips sidechain entries, and drops any text matching harness-injected XML patterns. The output filename is `<date>-<slug>.md` where the slug is derived from the session ID. YAML frontmatter includes `session-id`, `date`, `source` (basename of the input file), and `type: session-export` so the output is machine-identifiable for later indexing.

**Step 4 — Report.** The skill shows the user the written file path and its title extracted from the first user turn. For multiple sessions the skill repeats Step 3 per transcript.

## How to use it

`export-session` is model-invocable via its description. Trigger it by command or by asking naturally:

```
/export-session                                          # export most recent session for this project
/export-session <session-id>                            # export a specific session by ID
/export-session ~/.claude/projects/.../session.jsonl    # export by explicit transcript path
```

Or by saying: "export this session as Markdown", "save the current session to docs", "archive this session".

Exported files land in `{plansDirectory}/sessions/` (default: `docs/plans/sessions/`) and can be reused as reference material, ingested into the plans gallery, or shared via `share-session`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d07c389` | 2026-07-21 | feat(git-agent): add lint gate before commit (#448) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
- Changelog: [social-media-tools v2.14.0](../kit/plugins/social-media-tools/CHANGELOG.md#v2140--2026-07-02--export-session-session-transcripts-to-markdown)
