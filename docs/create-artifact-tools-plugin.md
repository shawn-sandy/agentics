# Create the artifact-tools plugin

> Three skills that turn Claude session output — diffs, session logs, and plan renders — into shareable HTML artifacts published to claude.ai.

<!-- generated:start -->

**Status:** Shipped 2026-07-14 **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/`: the initial plugin with three skills.
- `diff-artifact`: renders a git diff as a syntax-highlighted HTML page and publishes it as a Claude artifact; supports side-by-side and unified views.
- `session-artifact`: exports the current session log as a formatted HTML artifact; bundled `scripts/export_session.py` enables standalone CLI use outside Claude Code.
- `plan-artifact`: renders a plan document (spec or completed plan) as a styled HTML artifact with phase cards and status indicators.
- CSP-compliant HTML output: no inline event handlers, all styles inlined, 16 MiB cap enforced; each artifact carries an `artifact-url:` frontmatter key so republish calls can target the same URL.
- `plugin.json` without a `version` key (version lives only in marketplace.json); initial `README.md` and `CHANGELOG.md`.
- Registered in `.claude-plugin/marketplace.json` at 1.0.0 (category `productivity`, tags `artifact`, `diff`, `session`, `plan`).
- Added `tests/plugins/test-artifact-tools.sh`: smoke tests for all three skills.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Manifest (no version key) | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Diff render skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session export skill | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Plan render skill | Created |
| `kit/plugins/artifact-tools/scripts/export_session.py` | Standalone session exporter | Created |
| `kit/plugins/artifact-tools/README.md` | Plugin overview | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.0.0 entry | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test suite | Created |
| `.claude-plugin/marketplace.json` | artifact-tools 1.0.0 | Modified |

## How it works

Each skill publishes its output via the Artifact tool. The `artifact-url:` frontmatter key is written to the source document after the first publish; subsequent runs read it and pass `url:` to Artifact so the same link is reused. This means sharing the URL before work is done still reaches the final version.

CSP compliance is enforced by the skill instructions: no `onclick=`, no external script tags, all styling inlined. The 16 MiB cap is checked before the Artifact call; oversized sessions are truncated with a note.

`export_session.py` reads the Claude Code session JSON from `~/.claude/projects/` and writes the same HTML the skill produces, so the artifact can be generated from a terminal without an active Claude Code session.

## How to use it

```
/plugin install artifact-tools@agentics-kit
```

Then invoke any of the three skills:

```
/artifact-tools:diff-artifact
/artifact-tools:session-artifact
/artifact-tools:plan-artifact docs/plans/<slug>.md
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-14 | feat: create artifact-tools plugin — diff-artifact, session-artifact, plan-artifact (1.0.0) (#392) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
