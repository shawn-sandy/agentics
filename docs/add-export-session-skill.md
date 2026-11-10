# Add export-session skill to social-media-tools

> Session transcripts are unreadable raw JSONL; this adds an `export-session` skill to the `social-media-tools` plugin that converts them into clean Markdown reference files.

<!-- generated:start -->

**Status:** Shipped 2026-07-02 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/` with `SKILL.md` and `scripts/export_session.py`.
- The bundled Python script parses JSONL transcripts, keeps user/assistant turns (with `tool_use` blocks rendered as inline `*[tool: <name>]*` markers), skips tool-result-only user records and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`, and strings starting with `<task-notification`), and writes `<date>-<slug>-<session-id[:8]>.md` with YAML frontmatter under `{plansDirectory}/sessions/`.
- Skill uses `${CLAUDE_PLUGIN_ROOT}` (later converted to a `bin/` wrapper as `social-export-session`) to invoke the script without loading the transcript into Claude's context.
- No standalone `session-tools` plugin remains — the skill folded into `social-media-tools` which already owns session-derived content via `share-session`.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry.
- Added `export-session` to the plugin README and root `CLAUDE.md` table.

> See [CHANGELOG v2.22.0](../kit/plugins/social-media-tools/CHANGELOG.md) for the `bin/` wrapper fix that replaced the original `${CLAUDE_PLUGIN_ROOT}` invocation.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill instructions — workflow, script invocation, output path | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Python converter — JSONL → clean Markdown with frontmatter | Created |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Changelog — 2.14.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — social-media-tools version 2.14.0 | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin README — export-session feature entry | Modified |

## How it works

The skill resolves the output directory from `plansDirectory` in `.claude/settings.json` (defaulting to `docs/plans`), then appends `/sessions` as the output subdirectory.

**Transcript resolution** tries the user's explicit path or session ID first. If none is given, it finds the most recent `.jsonl` file under `~/.claude/projects/<project-slug>/`. When a worktree path doesn't match a project directory, it lists `~/.claude/projects/` and picks the entry matching the main repo path.

**Conversion** is deliberately off-loaded to the bundled Python script (`social-export-session`) so large transcripts never enter Claude's context. The script walks the JSONL line-by-line, selecting `user` and `assistant` role entries. Tool-result-only user records (records whose content consists entirely of `tool_result` blocks) are skipped. For assistant messages, `tool_use` blocks are retained as inline `*[tool: <name>]*` markers rather than dropped, so the reader can see which tools were called. Harness-injected noise — `<system-reminder>`, `<local-command-*>`, `<command-*>`, and strings starting with `<task-notification` — is stripped. The output filename is `<date>-<slug>-<session-id[:8]>.md` with YAML frontmatter including `type: session-export`, the session ID, and a `date: <YYYY-MM-DD>` field.

The skill itself calls the script via Bash and reports the output path. The `allow-tools: Bash, Read` declaration ensures no permission prompt interrupts the run.

**Note:** the initial `${CLAUDE_PLUGIN_ROOT}` invocation in the script path was later replaced by a `bin/` wrapper in v2.22.0, because Claude Code's Bash tool refuses commands whose text contains variable expansions that the harness cannot resolve at permission-check time.

## How to use it

**Activation:** the skill triggers on phrases like "export session", "archive a session", or "export or archive a session".

```text
# Export the current project's most recent session
/social-media-tools:export-session

# Export a specific session by path
/social-media-tools:export-session ~/.claude/projects/my-project/abc123.jsonl
```

Output appears under `docs/plans/sessions/<date>-<slug>-<session-id[:8]>.md` (or the configured `plansDirectory/sessions/`). The session ID prefix (up to eight characters) helps distinguish filenames when two sessions start with the same first user message, but does not guarantee uniqueness.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `11765e1` | 2026-07-02 | feat(social-media-tools): add export-session skill (2.14.0) (#368) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |
| `1ea0a36` | 2026-07-27 | fix(docs): make session-record links relative to their directory (#472) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
- Changelog: [social-media-tools CHANGELOG](../kit/plugins/social-media-tools/CHANGELOG.md)
