# Give the HTML-generating and publishing skills a check they can run

> Adds a runnable output check to the nine skills that generate or publish HTML without one, closing each skill's verification loop instead of leaving "looks done" as the only signal.

<!-- generated:start -->

**Status:** Shipped 2026-07-19 **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added fetch-back render assertions to all four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) after each publish; added `WebFetch` to each skill's `allowed-tools:`.
- Added index card-count assertions to `plans-library` and `media-library` that compare card count against source file count after writing `index.html`.
- Added a one-line note to `plans-open/SKILL.md` recording that its output check lives in `plans-library`.
- Added diff-back and parse checks to `agentic-memory-doctor` and `path-rules-advisor` after each CLAUDE.md or rules file rewrite.
- Added four new test suites: `test-generator-skills-verify-output.sh`, `test-index-card-count.mjs`, `test-memory-doctor-guard.sh`, `test-artifact-render-check.sh`.
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` versions.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/*/SKILL.md` (4 files) | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test | Created |

## How it works

The gap: skills that write a file then assert success without opening it. Nine were confirmed by reading the files (not a keyword scan). The four artifact-tools skills were the sharpest case — publishing to a live URL with no fetch-back meant a blank artifact was indistinguishable from a good one.

The artifact-tools checks use `WebFetch` to fetch the returned artifact URL and assert an expected marker (plan title, diff's first filename, session date) is present. `WebFetch` was also added to each skill's `allowed-tools:` since an undeclared tool stalls with a permission prompt.

The index checks compare the card count in the generated `index.html` against the number of source files scanned — catching silent card loss, the exact failure mode the `merge-plans-index.mjs` driver prevents at merge time but nothing checked at build time.

The memory-tools checks show the resulting diff and assert valid frontmatter and a non-empty body before reporting success — guarding the file that configures every future session.

The `test-generator-skills-verify-output.sh` smoke test asserts each touched SKILL.md has a post-write assertion, confirming the gap cannot silently reopen.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
