# Give the HTML-generating and Publishing Skills a Check They Can Run

> Add a runnable output check to nine skills that generate or publish HTML without one, and cover each check with a suite that proves it fails on bad output.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added fetch-back render assertions to all four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) — after each publish, the skill fetches the returned URL with `WebFetch` and asserts the page contains an expected marker (plan title, diff filename, session date)
- Added `WebFetch` to the `allowed-tools` frontmatter of all four artifact-tools skills so the new check cannot stall on a permission prompt
- Added card-count assertions to `plan-agent:plans-library` and `social-media-tools:media-library` — after writing `index.html`, the skill confirms the card count matches the number of source files scanned
- Added a one-line exemption note to `plan-agent:plans-open` explaining that its output check lives in `plans-library` (it opens an existing gallery and generates nothing)
- Added diff-back and parse checks to both `memory-tools` skills (`agentic-memory-doctor` and `path-rules-advisor`) — after rewriting CLAUDE.md or a rules file, the skill shows the resulting diff and asserts the file still has valid frontmatter and a non-empty body
- Created four test suites in `tests/plugins/`: `test-generator-skills-verify-output.sh` (smoke, retention checks over every touched SKILL.md), `test-index-card-count.mjs` (unit, card-count comparison logic), `test-memory-doctor-guard.sh` (integration, memory guard against fixture files), `test-artifact-render-check.sh` (E2E, publish and fetch-back flow)
- Bumped MINOR versions for `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` with changelog entries

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Exemption note pointing to plans-library | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-management/SKILL.md` | Diff-back and parse check before reporting success | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Diff-back and parse check before reporting success | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test for all nine skills | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test for card-count comparison logic | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test for memory guard | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test for publish and fetch-back flow | Created |
| `.claude-plugin/marketplace.json` | MINOR bumps for four plugins | Modified |

## How it works

A survey of the 13 marketplace plugins on 2026-07-16 read all 59 SKILL.md files and identified nine that wrote a file or published a URL and then asserted success without verifying the output. The survey distinguished this from read-only advisory skills, which have nothing to verify — only skills that write something whose correctness is not self-evident were in scope.

The four `artifact-tools` skills were the sharpest case. They publish to outward-facing `claude.ai` URLs and none previously fetched the result back. A published artifact that renders blank is indistinguishable from a correct one from inside the publishing session. Each skill now appends a step after the `Artifact` publish call that reads the returned URL with `WebFetch` and asserts the page body contains a marker unique to that skill's output: the plan title for `plan-artifact`, the diff's first filename for `diff-artifact`, the session date for `session-artifact`. A mismatch reports the URL and the expected marker rather than reporting success.

Adding `WebFetch` to `allowed-tools` was a necessary part of the artifact-tools fix, not an optional improvement. `.claude/rules/plugin-patterns.md` requires every tool a skill uses to be declared; an undeclared `WebFetch` would stall the new check on a permission prompt at exactly the moment these skills are most likely running unattended.

The gallery-rebuilding skills (`plans-library`, `media-library`) have a different failure mode: silent card loss. An index can write successfully with half the plans missing — the `merge-plans-index.mjs` driver prevents this at merge time, but nothing checked it at build time. The card-count assertion counts the source files scanned during the gallery rebuild and compares it to the actual `<article>` cards in the written HTML; a mismatch reports both counts so the gap is immediately visible.

The memory-tools skills (`agentic-memory-doctor`, `path-rules-advisor`) rewrite CLAUDE.md or rules files — the file that configures every future session. A corrupted CLAUDE.md degrades every subsequent conversation silently, and the damage outlives the session that caused it. The diff-back check shows the resulting diff before reporting success, and the parse check asserts the file still has valid frontmatter (where applicable) and a non-empty body. Malformed frontmatter causes the skill to report rather than write.

Each new check is paired with a test that exercises the negative case — a check that never fails is indistinguishable from no check. The E2E test for artifact-render-check publishes an empty-body artifact and asserts the skill reports failure. The card-count unit test removes one card and asserts the count mismatch is caught. The memory-doctor integration test points the guard at a fixture with malformed frontmatter and asserts the file is left untouched.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
- Related: [add-verification-gates.md](add-verification-gates.md) (verification gates for non-HTML skills)
- Related: [add-verification-standards.md](add-verification-standards.md) (authoring rule enforcement)
