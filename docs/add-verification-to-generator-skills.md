# Give the HTML-generating and publishing skills a check they can run

> Add a runnable output check to the nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done."

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added a render-assertion step to the four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`): after publishing, each fetches the returned URL with `WebFetch` and asserts the page contains an expected marker (plan title, diff's first filename, or session date) before reporting success. Added `WebFetch` to each skill's `allowed-tools:` frontmatter.
- Added an index assertion to `plans-library` and `media-library` that confirms the written `index.html` parses and its card count matches the number of source files scanned.
- Added a one-line note to `plans-open/SKILL.md` recording that its check lives in `plans-library` (intentionally exempt).
- Added diff-back and parse checks to `agentic-memory-doctor` and `path-rules-advisor` that show the resulting diff and assert valid frontmatter and a non-empty body before reporting success.
- Added `tests/plugins/test-generator-skills-verify-output.sh` (smoke), `tests/plugins/test-index-card-count.mjs` (unit), `tests/plugins/test-memory-doctor-guard.sh` (integration), and `tests/plugins/test-artifact-render-check.sh` (E2E).
- Bumped artifact-tools, plan-agent, social-media-tools, and memory-tools with MINOR version bumps and CHANGELOG entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Fetch-back render assertion + WebFetch | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Fetch-back render assertion + WebFetch | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Fetch-back render assertion + WebFetch | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fetch-back render assertion + WebFetch | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card-count assertion | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Intentional-exempt note | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Card-count assertion | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Diff-back and parse check | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Diff-back and parse check | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test for all nine skills | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test for card-count assertion | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test for memory guard | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test for publish and fetch-back | Created |
| `.claude-plugin/marketplace.json` | MINOR bumps for four plugins | Modified |

## How it works

The four artifact-tools skills all publish to outward-facing claude.ai URLs — a hard-to-reverse action. None previously fetched the result back. `WebFetch` can read `claude.ai/code/artifact/{uuid}` URLs via the user's login, so adding a fetch-back assertion needed no new dependencies. The `allowed-tools:` frontmatter requirement is from `plugin-patterns.md` rule — an undeclared `WebFetch` would stall on a permission prompt exactly when these skills are most likely running unattended.

The card-count assertion for `plans-library` and `media-library` catches the silent failure mode: an index that writes successfully but with half the plans missing. The assertion compares the number of `<div class="card">` (or equivalent) elements in the written HTML against the count of source files scanned in the same run.

The memory-tools check is the highest blast-radius write in the kit: CLAUDE.md configures every future session, so a corrupted rewrite degrades silently across all subsequent conversations. The diff-back check shows the diff before reporting success, and the parse check confirms valid frontmatter and a non-empty body.

The test files each exercise the negative case — bad output triggers a failure report — not just the happy path. This is the plan's central assertion: a check that never fails is indistinguishable from no check.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
- Related: [add-verification-gates.md](add-verification-gates.md) — applied gates to the five highest-blast-radius skills
- Related: [add-verification-standards.md](add-verification-standards.md) — made gates an authoring standard in `plugin-patterns.md`
