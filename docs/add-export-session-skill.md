# Add export-session skill to social-media-tools

> Ships an `export-session` skill in the `social-media-tools` plugin that converts a raw session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/social-media-tools/skills/export-session/SKILL.md` — the skill definition using `${CLAUDE_PLUGIN_ROOT}` to reference the bundled script and declaring `allowed-tools`.
- Created `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` — a Python script that parses a session JSONL, filters to user and assistant turns, strips harness noise, and writes a dated Markdown file with YAML frontmatter.
- Removed any standalone `session-tools` plugin from `kit/plugins/` and `marketplace.json`, folding the capability into `social-media-tools` which already owns session-derived content.
- Bumped `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry and README update.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/export-session/SKILL.md` | Skill definition — invocation contract and script path | Created |
| `kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py` | Converter — JSONL parser and Markdown writer | Created |
| `.claude-plugin/marketplace.json` | Marketplace version bump to 2.14.0 | Modified |

## How it works

**Placement.** The skill lives under `social-media-tools` rather than as a standalone plugin because `social-media-tools` already manages session-derived content through `share-session`. Consolidating avoids a separate plugin load for a closely related capability and keeps session output discovery in one place.

**Script-based conversion.** The converter is a bundled Python script (`export_session.py`) rather than inline SKILL.md instructions. This keeps large transcript files out of Claude's context window — an important constraint because session JSONL files can be hundreds of megabytes of mixed harness records and conversation turns.

**Filtering.** The script parses each line of the JSONL, retaining only `user` and `assistant` role entries. It skips tool results, sidechains, and harness-injected messages identified by XML-style tags: `<system-reminder>`, `<local-command-*>`, and `<command-*>`. This produces a clean turn-by-turn conversation without harness noise.

**Output format.** The script writes `<date>-<slug>.md` under the output directory. Each file begins with YAML frontmatter including `type: session-export` — a discoverable marker for downstream tools that index exported sessions.

**Invocation.** SKILL.md declares the script path using `${CLAUDE_PLUGIN_ROOT}` so the skill resolves correctly regardless of where the plugin directory is installed. The `allowed-tools` frontmatter restricts what the skill can invoke.

## How to use it

Activation trigger: `/social-media-tools:export-session`

```
# Export the most recent session to the plans sessions directory
/social-media-tools:export-session

# Run the script directly against a specific transcript
python3 kit/plugins/social-media-tools/skills/export-session/scripts/export_session.py \
  ~/.claude/projects/<slug>/<id>.jsonl \
  docs/plans/sessions/
```

The skill writes the Markdown file to `{plansDirectory}/sessions/` with the filename pattern `<date>-<slug>.md` and YAML frontmatter. The output includes clean user and Claude turns, stripped of harness records.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
