# Create the artifact-tools plugin

> Ships the `artifact-tools` plugin with three skills — `diff-artifact`, `session-artifact`, and `plan-artifact` — that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages, with a scrub gate before every publish and a local-HTML fallback.

<!-- generated:start -->

**Status:** Shipped 2026-07-14  **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/` with `.claude-plugin/plugin.json` (no `version` key), `README.md`, and `CHANGELOG.md`.
- Added `skills/diff-artifact/SKILL.md`: resolves the diff source (branch, commit range, or PR), runs `social-media-tools:security-scrub` as a blocking gate, builds one self-contained annotated-diff HTML page (sticky sidebar, per-hunk margin annotations, severity coding, adaptive light/dark theme, cap-and-summarize policy), publishes via the `Artifact` tool, records the URL as `artifact-url:`, falls back to local HTML + `save-artifact` on publish failure.
- Added `skills/session-artifact/SKILL.md` + `scripts/export_session.py` (bundled transcript extractor, copied from `social-media-tools` for zero install-order dependency): locates the session transcript, extracts turns, writes a reviewer-first recap (Summary, Decisions, Learnings, Files touched), scrubs, saves to `{plansDirectory}/sessions/`, and publishes the `.md` directly as an artifact.
- Added `skills/plan-artifact/SKILL.md`: accepts a plan `.html` path, reads `artifact-url:` from the sibling `.md` spec for stable republish, writes the URL back on first publish.
- Registered `artifact-tools` at `1.0.0` in `.claude-plugin/marketplace.json` (category: `development`).
- Added `tests/plugins/test-artifact-tools.sh`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill instructions | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Transcript extractor | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Skill instructions | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Created |

## How it works

A publish is external sharing, so every skill runs `social-media-tools:security-scrub` as a blocking gate before any artifact is created. The scrub must pass — there is no override.

The republish mechanic is what makes artifact links stable across sessions: each skill records the Artifact tool's returned URL as `artifact-url:` in the source file's frontmatter. On a subsequent run the skill reads that key and passes it as the `url` parameter, updating the existing page rather than minting a new one.

The CSP constraint means all content must be inlined. For diffs this means a cap-and-summarize policy: files beyond the per-file annotation budget render as summary rows so the total page stays under the 16 MiB artifact limit.

## How to use it

```
/artifact-tools:diff-artifact              # current branch vs default
/artifact-tools:session-artifact           # latest session transcript
/artifact-tools:plan-artifact docs/plans/my-feature.html
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
