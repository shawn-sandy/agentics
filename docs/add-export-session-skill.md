# Add export-session Skill

> Ships an `export-session` skill in `social-media-tools` that converts raw session JSONL transcripts into readable Markdown files under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/SKILL.md` — the skill contract that resolves the output directory, locates the transcript, and invokes the bundled script.
- Created `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` — Python converter that parses JSONL, keeps user/assistant turns, strips sidechains, tool results, and harness-injected messages (`<system-reminder>`, `<local-command-*>`, `<command-*>`), and writes `<date>-<slug>.md` with YAML frontmatter.
- A `bin/` wrapper (`social-export-session`) exposes the script on `PATH` so the skill can invoke it without shell variable expansion in the Bash tool.
- Output files carry frontmatter with `session-id`, `date`, `source`, and `type: session-export`.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry and README update.
- No standalone `session-tools` plugin remains.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill contract — resolution and invocation workflow | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | JSONL-to-Markdown converter | Created |
| `.claude-plugin/marketplace.json` | `social-media-tools` bumped to `2.14.0` | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | `2.14.0` entry | Modified |
| `kit/plugins/social-media-tools/README.md` | `export-session` skill entry | Modified |

## How it works

Session transcripts in `~/.claude/projects/<slug>/<id>.jsonl` hold useful reference material but are unreadable: they mix assistant turns with tool call/result pairs, sidechain records, and harness-injected system reminders. Reading them directly into Claude's context would both pollute output with noise and consume context that should go to the exported content.

The skill avoids this by keeping all transcript parsing out of Claude's context. Step 3 in the SKILL.md invokes `social-export-session` (the `bin/` wrapper for `export_session.py`) as a Bash command with two literal arguments — the transcript path and the output directory. The Bash tool refuses commands containing shell variable interpolation, so the skill resolves both paths in the preceding steps and passes them as concrete strings.

The Python script reads the JSONL line-by-line. It keeps only records where `role` is `user` or `assistant` and `type` is `message`. Sidechain records (identifiable by their `isSidechain` flag), tool-use and tool-result content blocks, and messages whose text begins with recognized harness injection markers are all discarded. The remaining turns are written in sequence as `## Human` / `## Claude` headers with their text content.

The output filename is derived from the transcript's session date and a slug computed from the first user message. YAML frontmatter includes `session-id`, `date`, `source` (the transcript filename only — not the full path, to avoid embedding local usernames or project paths), and `type: session-export`, enabling downstream indexing.

The skill auto-discovers the most recent transcript for the current project when none is specified, using `ls -t` on the project's JSONL directory. Worktree support is included: when the standard path does not exist, it lists `~/.claude/projects/` and selects the entry matching the main repo path.

## How to use it

`/social-media-tools:export-session` converts the current session or a named transcript.

```text
/social-media-tools:export-session
/social-media-tools:export-session ~/.claude/projects/my-project/abc123.jsonl
```

The converted file is written to `{plansDirectory}/sessions/` (defaulting to `docs/plans/sessions/`) and the skill reports the output path.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
