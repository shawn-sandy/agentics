# Give the HTML-generating and publishing skills a check they can run

> Nine skills generate HTML or publish it to a live URL and then report success without ever looking at the output, so a blank artifact is indistinguishable from a good one from inside the session that made it. This gives each one a check it can run, and covers every check with a suite that proves it fails on bad output.

<!-- generated:start -->

**Status:** Shipped 2026-07-19 **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added render assertion (fetch-back via `WebFetch` + marker check) to all four `artifact-tools` skills: `plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`; added `WebFetch` to each skill's `allowed-tools`.
- Added card-count assertion to `plan-agent:plans-library` and `social-media-tools:media-library`: after writing `index.html`, confirms the card count matches the number of source files scanned.
- Added explanatory one-line note to `plan-agent:plans-open` recording that its check lives in `plans-library`.
- Added diff-back and parse-check to `memory-tools:agentic-memory-doctor` and `memory-tools:path-rules-advisor`: after rewriting CLAUDE.md or a rules file, shows the diff and asserts the file still parses.
- Added `tests/plugins/test-generator-skills-verify-output.sh`, `tests/plugins/test-index-card-count.mjs`, `tests/plugins/test-memory-doctor-guard.sh`, `tests/plugins/test-artifact-render-check.sh`.
- Bumped artifact-tools, plan-agent, social-media-tools, and memory-tools (MINOR each).

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
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Diff-back and parse-check | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Diff-back and parse-check | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Objective smoke test | Created |
| `tests/plugins/test-index-card-count.mjs` | Card-count unit test | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Memory guard integration test | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E publish + fetch-back | Created |
| `.claude-plugin/marketplace.json` | Four plugin MINOR bumps | Modified |

## How it works

Three verification patterns cover the nine skills:

- **Artifact fetch-back**: after each `artifact-tools` publish, fetches the returned URL with `WebFetch` and asserts the page contains an expected marker (plan title, diff's first filename, session date). A blank artifact or a wrong URL fails the assertion before the skill reports success.

- **Card-count assertion**: `plans-library` and `media-library` count the HTML cards in the generated `index.html` against the number of source files scanned. Silent card loss (an index that writes successfully with half the content missing) is now caught at build time.

- **Diff-back + parse**: the memory-tools skills that rewrite CLAUDE.md or rules files show the resulting diff and assert the file still parses with valid frontmatter and a non-empty body, before reporting done.

Each check is exercised by a suite that proves it fails on bad output — a check that never fails is indistinguishable from no check.

## How to use it

The verification steps fire automatically as the final step of each skill's workflow. No invocation change is needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-19 | feat: add output verification to 9 HTML-generating and publishing skills (artifact-tools, plan-agent, social-media-tools, memory-tools MINOR bumps) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
