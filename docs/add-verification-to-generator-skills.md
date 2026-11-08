# Give the HTML-generating and publishing skills a check they can run

> Add a runnable output check to nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done".

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added render assertions to the four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`): after each publish, the skill fetches the returned artifact URL with `WebFetch` and asserts the page contains an expected marker (plan title, diff's first filename, session date), reporting failure with the URL on mismatch; added `WebFetch` to each skill's `allowed-tools:` frontmatter
- Added index assertions to `plan-agent:plans-library` and `social-media-tools:media-library`: after writing `index.html`, each confirms the file parses and its card count matches the number of source files scanned
- Added a one-line note to `plan-agent:plans-open` recording that its output check lives in `plans-library` (it opens an existing gallery and generates nothing)
- Added diff-back and parse checks to `memory-tools:agentic-memory-doctor` and `path-rules-advisor`: after rewriting CLAUDE.md or a rules file, each shows the resulting diff and asserts valid frontmatter and a non-empty body
- Added four new test suites under `tests/plugins/`: `test-generator-skills-verify-output.sh`, `test-index-card-count.mjs`, `test-memory-doctor-guard.sh`, `test-artifact-render-check.sh`
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` with MINOR version bumps and CHANGELOG entries

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Fetch-back render assertion | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Fetch-back render assertion | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Fetch-back render assertion | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fetch-back render assertion | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card-count assertion | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Exempt note | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Card-count assertion | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Diff-back and parse check | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Diff-back and parse check | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test for all nine | Created |
| `tests/plugins/test-index-card-count.mjs` | Card-count unit test | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Memory guard integration test | Created |
| `tests/plugins/test-artifact-render-check.sh` | Publish + fetch-back E2E test | Created |
| `.claude-plugin/marketplace.json` | Four plugin MINOR version bumps | Modified |

## How it works

The four `artifact-tools` skills share the same fix shape: after the publish call returns a URL, the skill fetches that URL with `WebFetch` and searches the response for a marker specific to the content type (the plan title, the diff's first filename, the session date). A mismatch reports the failure with the URL rather than declaring success. `WebFetch` was added to all four `allowed-tools:` frontmatter entries so the new check never stalls on a permission prompt — particularly important since these skills are most likely to run unattended.

The gallery skills (`plans-library`, `media-library`) received a card-count assertion: after writing `index.html`, each counts the gallery cards in the output file and compares against the number of source files scanned. Silent card loss — writing a gallery that includes only half the plans — is exactly the failure mode the `merge-plans-index.mjs` driver prevents at merge time but nothing previously checked at build time.

For the memory tools, the blast radius of a corrupted CLAUDE.md is highest of any write in the repo — it degrades every subsequent conversation and the damage outlives the session. The diff-back check shows the write's diff and asserts the file still parses with valid frontmatter and a non-empty body before reporting success; pointing `agentic-memory-doctor` at a fixture with malformed frontmatter makes it report rather than write.

Each new test suite follows the existing `tests/plugins/` conventions. The objective tests assert that each skill's check fires on bad output (not merely passes on good output), following PR #405's precedent where green CI masked a red test.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
- Audit context: [add-verification-gates.md](add-verification-gates.md)
- Retention test: [tests/plugins/test-generator-skills-verify-output.sh](../tests/plugins/test-generator-skills-verify-output.sh)
