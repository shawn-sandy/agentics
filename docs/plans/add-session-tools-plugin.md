---
status: completed
type: feature
created: 2026-07-02
modified: 2026-07-02
repo-name: agentics
---

# Plan: Add session-tools plugin with export-session skill

## Context

Session transcripts (`~/.claude/projects/<slug>/<id>.jsonl`) hold useful reference and educational material but are unreadable raw JSONL mixed with harness records. The user asked for a skill that exports sessions as Markdown into `{plansDirectory}/sessions`, packaged as a marketplace plugin.

## Objective

Ship a `session-tools` plugin (v0.1.0) whose `export-session` skill converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

## Steps

1. Create `kit/plugins/session-tools/` with `.claude-plugin/plugin.json`, `README.md`, `CHANGELOG.md`, and `skills/export-session/` (SKILL.md + `scripts/export_session.py`). — *Why:* standard plugin layout so the marketplace can serve it. *Verify:* `/validate-plugin session-tools` structure checks pass; `jq empty` on plugin.json.
2. The script parses the JSONL, keeps user/assistant turns, skips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and writes `<date>-<slug>.md` with YAML frontmatter. — *Why:* a script keeps huge transcripts out of Claude's context. *Verify:* run against a real transcript; output has frontmatter, clean turns, no harness noise.
3. Register `session-tools` at `0.1.0` in `.claude-plugin/marketplace.json` and bump the marketplace to `4.1.0`; update the CLAUDE.md plugin table. — *Why:* new plugin = minor bump per versioning rules. *Verify:* `jq empty` passes; table shows 12 plugins.

## Tests

> Tier: 2 (non-code plan — plugin markdown/JSON plus a bundled utility script exercised by a smoke run)

### Objective-Verification Test

- **File:** manual smoke run (no project test runner covers plugins)
- **Type:** smoke test
- **Asserts:** `export_session.py <real transcript> <outdir>` writes a Markdown file with `type: session-export` frontmatter and user/Claude turns, free of harness noise
- **Run:** `python3 kit/plugins/session-tools/skills/export-session/scripts/export_session.py $(ls -t ~/.claude/projects/-Users-shawnsandy-devbox-agentics/*.jsonl | head -1) /tmp/sessions-test`

## Acceptance Criteria

- [x] `kit/plugins/session-tools/` exists with plugin.json, README, CHANGELOG, and the export-session skill
- [x] `marketplace.json` lists `session-tools` at `0.1.0`; marketplace version is `4.1.0`
- [x] Script converts a real transcript into clean Markdown with frontmatter
- [x] SKILL.md uses `${CLAUDE_PLUGIN_ROOT}` for the script path and declares `allowed-tools`

## Verification

Load the plugin (`claude --plugin-dir ./kit/plugins/session-tools`), run `/export-session`, and confirm a Markdown file appears under `docs/plans/sessions/` with readable conversation turns.

## Next Steps *(optional)*

- Index exported sessions into the plans gallery:
  ```text
  Update the plan-agent plans-library skill (or its rebuild hook) in ~/devbox/agentics so Markdown files under docs/plans/sessions/ with frontmatter `type: session-export` appear in the gallery as a "Sessions" category. Report the files changed.
  ```
