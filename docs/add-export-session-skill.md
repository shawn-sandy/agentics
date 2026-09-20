# Add export-session skill to social-media-tools

> Ship an `export-session` skill in the `social-media-tools` plugin (v2.14.0) that converts a session JSONL transcript into a readable Markdown file under `{pl...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-export-session-skill.md](plans/add-export-session-skill.md)
**Type:** feature

## What shipped

- Create `kit/plugins/social-media-tools/skills/export-session/` (SKILL.md + `scripts/export_session.py`). — *
- The script parses the JSONL, keeps user/assistant turns, skips sidechains, tool results, and harness-injected message...
- Bump `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` (new skill = minor), add a CHANGELOG entry...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Ship an `export-session` skill in the `social-media-tools` plugin (v2.14.0) that converts a session JSONL transcript into a readable Markdown file under `{plansDirectory}/sessions/` via a bundled Python script.

Session transcripts (`~/.claude/projects/<slug>/<id>.jsonl`) hold useful reference and educational material but are unreadable raw JSONL mixed with harness records. The user asked for a skill that exports sessions as Markdown into `{plansDirectory}/sessions`. It was first shipped as a standalone `session-tools` plugin, then folded into `social-media-tools` (which already owns session-derived content via `share-session`).

The implementation proceeded through these steps: Create `kit/plugins/social-media-tools/skills/export-session/` (SKILL.md + `scripts/export_session.py`). — *Why:* ski...; The script parses the JSONL, keeps user/assistant turns, skips sidechains, tool results, and harness-injected message...; Bump `social-media-tools` to `2.14.0` in `.claude-plugin/marketplace.json` (new skill = minor), add a CHANGELOG entry....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-export-session-skill.md](plans/add-export-session-skill.md)
