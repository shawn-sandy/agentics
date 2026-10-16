# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Ships a new `artifact-tools` plugin with three skills — `diff-artifact`, `session-artifact`, and `plan-artifact` — that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages.

<!-- generated:start -->

**Status:** Shipped 2026-07-14 **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/` with `.claude-plugin/plugin.json` (no `version` key), `README.md`, and `CHANGELOG.md`.
- Authored `skills/diff-artifact/SKILL.md`: resolves diff source, runs `security-scrub` as a blocking gate, builds a self-contained annotated-diff HTML page (sticky sidebar, per-hunk annotations, adaptive light/dark theme, severity labels), publishes via the `Artifact` tool, records the returned URL as `artifact-url:`.
- Authored `skills/session-artifact/SKILL.md` plus a bundled `scripts/export_session.py` (copied from `social-media-tools` for standalone operation): locates session transcript, extracts turns, scrubs, saves under `{plansDirectory}/sessions/`, and publishes the Markdown as an artifact.
- Authored `skills/plan-artifact/SKILL.md`: reads `artifact-url:` from sibling `.md` spec's frontmatter for stable republishing; falls back to first-publish when absent.
- Registered `artifact-tools` at version `1.0.0` in `.claude-plugin/marketplace.json`.
- Added `tests/plugins/test-artifact-tools.sh` structural smoke test.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Diff skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Transcript extractor | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Plan skill | Created |
| `kit/plugins/artifact-tools/README.md` | Documentation | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Version history | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Created |

## How it works

The central design decision: updating an artifact from a later session requires the artifact's URL. Without it, a new session mints a new page every time. Each skill therefore writes the returned URL into the source file's frontmatter as `artifact-url:`, so any future session can republish to the same link.

`diff-artifact` is the one skill that generates content nothing else in the kit produced — an annotated diff walkthrough. It caps large diffs with a summarize policy so the 16 MiB artifact limit is never exceeded. The security-scrub check is blocking (not advisory) because a diff published to a claude.ai URL is external sharing.

`session-artifact` bundles its own `export_session.py` rather than requiring `social-media-tools` to be installed, trading a small code duplication for zero cross-plugin coupling.

`plan-artifact` is deliberately thin: plan HTML is already self-contained and CSP-compliant, so the skill is a publish wrapper whose sole value is stable URLs across sessions.

## How to use it

```
/artifact-tools:diff-artifact                         # publish current branch diff
/artifact-tools:session-artifact                      # publish newest session recap
/artifact-tools:plan-artifact docs/plans/my-plan.html # publish or republish a plan
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
- Changelog: [artifact-tools CHANGELOG v1.0.0](../kit/plugins/artifact-tools/CHANGELOG.md)
- Related: [Claude Code artifacts documentation](https://code.claude.com/docs/en/artifacts)
