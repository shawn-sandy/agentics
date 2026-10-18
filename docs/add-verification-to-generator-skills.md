# Give the HTML-generating and publishing skills a check they can run

> Adds a runnable output check to nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done", and covers them with suites in the existing `tests/plugins/` harness.

<!-- generated:start -->

**Status:** Shipped 2026-07-19  **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added render assertions to the four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`): each now fetches its published URL back with `WebFetch` and asserts a marker (plan title, diff filename, session date) before reporting success. Added `WebFetch` to each skill's `allowed-tools:` frontmatter.
- Added index card-count assertions to `plans-library` and `media-library`: after writing `index.html`, each confirms card count matches the number of source files scanned.
- Added a one-line note to `plans-open/SKILL.md` recording that its output check lives in `plans-library` (intentionally exempt from its own check).
- Added diff-back and parse checks to `agentic-memory-doctor` and `path-rules-advisor`: after rewriting CLAUDE.md or a rules file, each shows the resulting diff and asserts valid frontmatter and non-empty body.
- Added four new suites to `tests/plugins/`: `test-generator-skills-verify-output.sh` (smoke), `test-index-card-count.mjs` (unit), `test-memory-doctor-guard.sh` (integration), `test-artifact-render-check.sh` (E2E).
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` with CHANGELOG entries.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test | Created |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |

## How it works

The four `artifact-tools` skills publish to outward-facing claude.ai URLs — the sharpest verification gap because a blank artifact is indistinguishable from a good one from inside the session that published it. The `WebFetch` render check fetches the URL the Artifact tool returned and asserts a content marker; `WebFetch` was also added to `allowed-tools:` in each skill so the check cannot stall on a permission prompt.

The memory-tools check has the highest blast radius in the repo: `agentic-memory-doctor` and `path-rules-advisor` rewrite CLAUDE.md or rules files that configure every future session. The diff-back check shows the actual change and confirms the file still parses before reporting success.

The index card-count check for `plans-library` and `media-library` catches silent card loss — the failure mode where the index writes successfully but drops plans due to a glob or filter error.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
