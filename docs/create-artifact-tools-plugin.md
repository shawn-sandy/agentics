# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Teams get live, shareable claude.ai pages for the three things they review most — code diffs, working sessions, and implementation plans — without leaving Cl...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Scaffold `kit/plugins/artifact-tools/` with `.claude-plugin/plugin.json` (name, description, author, license, keyword...
- Author `skills/diff-artifact/SKILL.md`: resolve the diff source (current branch vs the default branch by default; a c...
- Author `skills/session-artifact/SKILL.md` plus a bundled `scripts/export_session.py` (copied from social-media-tools'...
- Author `skills/plan-artifact/SKILL.md`: accept a plan `.html` path (plan-agent output is already self-contained and C...
- Register `artifact-tools` in `.claude-plugin/marketplace.json` at version 1.0.0 (source `git-subdir`, path `kit/plugi...
- Write `tests/plugins/test-artifact-tools.sh` following the existing `test-save-artifact.sh` pattern: assert plugin.js...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | plugin manifest; name, description, keywords, homepage; n... | Created |
| `kit/plugins/artifact-tools/README.md` | overview, features, installation, usage, structure | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.0.0 entry | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | annotated diff walkthrough artifact | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | session recap artifact with learnings | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | bundled transcript extractor, copied from social-media-to... | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | publish and republish plan HTML | Created |
| `.claude-plugin/marketplace.json` | register artifact-tools at 1.0.0 | Modified |
| `tests/plugins/test-artifact-tools.sh` | structural smoke test | Created |

## How it works

Ship a new `artifact-tools` plugin in `kit/plugins/` with three skills — `diff-artifact`, `session-artifact`, and `plan-artifact` — that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages, with a scrub gate before every publish and a local-HTML fallback when publishing is unavailable.

Claude Code artifacts (per the official docs at code.claude.com/docs/en/artifacts) are self-contained pages published to a private claude.ai URL that update in place on republish. They carry hard constraints the skills must respect: a strict Content Security Policy (no external requests — everything inlined), a 16 MiB rendered-size cap, single-page only (in-page anchors, no relative links), and `.html`/`.md` sources — Markdown renders as styled HTML at the lowest token cost. Publishing requires ...

The implementation proceeded through these steps: Scaffold `kit/plugins/artifact-tools/` with `.claude-plugin/plugin.json` (name, description, author, license, keyword...; Author `skills/diff-artifact/SKILL.md`: resolve the diff source (current branch vs the default branch by default; a c...; Author `skills/session-artifact/SKILL.md` plus a bundled `scripts/export_session.py` (copied from social-media-tools'...; Author `skills/plan-artifact/SKILL.md`: accept a plan `.html` path (plan-agent output is already self-contained and C...; Register `artifact-tools` in `.claude-plugin/marketplace.json` at version 1.0.0 (source `git-subdir`, path `kit/plugi....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/392
