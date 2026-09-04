# Give the HTML-generating and publishing skills a check they can run

> Add a runnable output check to the nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done".

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-verification-to-generator-skills](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added fetch-back render assertions to all four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) plus `WebFetch` in each skill's `allowed-tools:` frontmatter.
- Added index card-count assertions to `plans-library` and `media-library` that confirm the generated gallery card count matches the number of source files scanned.
- Added a one-line intentional-exemption note to `plans-open` explaining that its output check lives in `plans-library`.
- Added diff-back and parse checks to `agentic-memory-doctor` and `path-rules-advisor` so CLAUDE.md and rules-file rewrites are verified before reporting success.
- Wrote four new test suites in `tests/plugins/` covering each check type, each asserting failure on bad output as well as success on good.
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` with MINOR version bumps.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | One-line intentional-exemption note | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Diff-back and parse check before reporting success | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Diff-back and parse check before reporting success | Missing |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test: every touched SKILL.md has a post-write assertion | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test for card-count assertion logic | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test for memory-doctor diff/parse guard | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test for publish, fetch-back, and assert flow | Created |
| `.claude-plugin/marketplace.json` | MINOR bumps for the four plugins touched | Modified |

## How it works

A survey of all 59 SKILL.md files across the 13 marketplace plugins on 2026-07-16 identified nine skills that write a file or publish a URL and then report success without examining their output. The four `artifact-tools` skills were the sharpest case — publishing to a claude.ai URL is an outward-facing, hard-to-reverse action, and a published artifact that renders blank was indistinguishable from a good one inside the session that made it.

The four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) each received a post-publish step that fetches the returned artifact URL with `WebFetch` and asserts the page contains an expected marker — the plan title, the diff's first filename, or the session date. On mismatch the skill reports the failure with the URL rather than reporting success. `WebFetch` was added to each skill's `allowed-tools:` frontmatter because `.claude/rules/plugin-patterns.md:50` requires every tool a skill uses to be declared, and an undeclared tool stalls on a permission prompt exactly when these skills are most likely running unattended.

`plans-library` and `media-library` both rebuild a gallery from a directory scan. Their silent failure mode is card loss — an index that writes with half the plans missing. An index card-count assertion was added to each: after writing `index.html`, the skill confirms the file parses and its card count matches the number of source files scanned. Mismatches are reported by count.

`plans-open` opens an existing gallery and generates nothing. A check would be verification theater. A one-line note was added to its SKILL.md recording explicitly that its output check lives in `plans-library`, so future audits treat it as intentionally exempt rather than a gap.

`agentic-memory-doctor` and `path-rules-advisor` rewrite CLAUDE.md or rules files — the highest blast-radius writes in the repo, because a corrupted CLAUDE.md degrades every subsequent session and the damage outlives the session that caused it. Both skills received a diff-back check that shows the resulting diff and asserts the file still parses with valid frontmatter where applicable and a non-empty body, reporting rather than writing when a fixture has malformed frontmatter.

Four suites were added to `tests/plugins/` following the existing naming and shape. Each asserts that the new check fires on bad output: `test-generator-skills-verify-output.sh` checks every touched SKILL.md for a post-write assertion and that `plans-open` is recorded as exempt; `test-index-card-count.mjs` exercises the count comparison logic in isolation; `test-memory-doctor-guard.sh` confirms valid frontmatter is diffed and malformed frontmatter is reported untouched; and `test-artifact-render-check.sh` covers the full publish/fetch-back/assert flow for `plan-artifact`.

## How to use it

The checks run automatically as part of normal skill execution. No user action is required beyond invoking the affected skills as before. To run the test suites:

```bash
bash tests/plugins/test-generator-skills-verify-output.sh
node tests/plugins/test-index-card-count.mjs
bash tests/plugins/test-memory-doctor-guard.sh
bash tests/plugins/test-artifact-render-check.sh
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `622594d` | 2026-07-19 | feat(plugins): give HTML-generating and publishing skills a runnable output check (#431) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills](plans/add-verification-to-generator-skills.md)
