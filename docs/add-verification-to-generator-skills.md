# Give the HTML-generating and publishing skills a check they can run

> Nine skills generate HTML or publish it to a live URL and then report success without ever looking at the output, so a blank artifact is indistinguishable from a good one from inside the session that made it. This gives each one a check it can run, and covers every check with a suite that proves it fails on bad output.

<!-- generated:start -->

**Status:** Shipped 2026-07-19  **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added render assertions to the four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) — each now fetches its published URL back via `WebFetch` and asserts an expected marker (plan title, diff's first filename, session date) before reporting success; `WebFetch` was added to each skill's `allowed-tools` frontmatter.
- Added a card-count assertion to `plans-library` and `media-library` that, after writing `index.html`, confirms the file parses and its card count matches the number of source files scanned.
- Added a one-line note to `plans-open/SKILL.md` recording that its output check lives in `plans-library`, preventing future audits from re-flagging it as a gap.
- Added a diff-back and parse check to `agentic-memory-doctor` and `path-rules-advisor` so both show the resulting diff and assert valid frontmatter and a non-empty body before reporting success (protecting the highest blast-radius write: the file that configures every future session).
- Created four new test suites: `test-generator-skills-verify-output.sh` (smoke), `test-index-card-count.mjs` (unit), `test-memory-doctor-guard.sh` (integration), `test-artifact-render-check.sh` (E2E).
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` with MINOR version bumps in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Note that check lives in plans-library | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Diff-back and parse check | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Diff-back and parse check | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Objective-verification smoke test | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test for card-count assertion | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test for memory guard | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test for publish and fetch-back flow | Created |
| `.claude-plugin/marketplace.json` | MINOR bumps for four plugins | Modified |

## How it works

The plan's central insight, drawn from the `CLAUDE.md` best-practices guide, is that "looks done" is only a signal if there is a check to run. Nine skills were publishing or writing files and then asserting success based on the absence of an error, not on confirmation that the output was correct.

For the four `artifact-tools` skills, the fix is a fetch-back step after the `Artifact` tool returns a URL. `WebFetch` reads the published page and asserts that a known marker — the plan title for `plan-artifact`, the diff's first filename for `diff-artifact`, the session date for `session-artifact` — appears in the response body. If it does not, the skill reports the URL and the expected marker and stops with a failure message rather than a success message. Adding `WebFetch` to each skill's `allowed-tools` frontmatter ensures the check never stalls on a permission prompt mid-run.

For `plans-library` and `media-library`, the failure mode is silent card loss — an index that writes successfully with fewer cards than source files. The fix counts the source files scanned and compares that number to the card count in the written `index.html`. A mismatch is reported immediately, before the skill declares done.

For `agentic-memory-doctor` and `path-rules-advisor`, the stakes are highest: these rewrite `CLAUDE.md` or a rules file, and a corrupted file degrades every subsequent session. The fix adds a `git diff` (or file diff) step after writing, plus a parse check asserting valid frontmatter where applicable and a non-empty body. Pointing either skill at a fixture with malformed frontmatter makes it report rather than write.

The four test suites each assert the negative case — that the check fires on bad output — rather than just passing on good output. The `test-generator-skills-verify-output.sh` smoke test greps every touched SKILL.md for a post-write assertion and confirms `plans-open` is explicitly recorded as exempt. The unit and integration tests use fixtures to exercise the specific assertion logic in isolation.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
