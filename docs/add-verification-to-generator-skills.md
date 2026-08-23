# Give the HTML-generating and publishing skills a check they can run

> Nine skills that generate or publish HTML without a verification step each received a runnable output check, covered by new test suites that prove the check fails on bad output.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added a fetch-back render assertion to all four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) — after publishing, each fetches the returned URL via `WebFetch` and asserts a content marker before reporting success.
- Declared `WebFetch` in the `allowed-tools:` frontmatter of all four artifact-tools skills, so the new check cannot stall on a permission prompt when running unattended.
- Added a card-count assertion to `plans-library` and `media-library` — after writing `index.html`, each confirms the card count matches the number of source files scanned.
- Added a one-line note to `plans-open` recording that its output check lives in `plans-library`, so future audits treat it as intentionally exempt rather than a gap.
- Added a diff-back and parse check to `path-rules-advisor` — after rewriting a rules file, the skill shows the diff and asserts valid frontmatter and a non-empty body before reporting success. (`agentic-memory-doctor` was listed in the plan but its SKILL.md was not found at the expected path; it may have been removed or relocated.)
- Created four new test suites in `tests/plugins/` covering the artifact render-check, index card-count, memory guard, and a smoke test asserting all touched skills carry a post-write assertion.
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` in `.claude-plugin/marketplace.json` with matching CHANGELOG entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Skill instructions — fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill instructions — fetch-back render assertion after publish, WebFetch declared | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions — fetch-back render assertion after publish, WebFetch declared | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill instructions — fetch-back render assertion after publish, WebFetch declared | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Skill instructions — card-count assertion against source count | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Skill instructions — note that output check lives in plans-library | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Skill instructions — card-count assertion against source count | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill instructions — diff-back and parse check before reporting success | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Skill instructions — diff-back and parse check (not found at expected path) | Missing |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test — asserts all touched skills carry a post-write assertion | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test — card-count comparison logic for plans-library and media-library | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test — diff-back guard for rules-file rewrites | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test — publish and fetch-back flow for artifact skills | Created |
| `.claude-plugin/marketplace.json` | Marketplace manifest — MINOR version bumps for four plugins | Modified |

## How it works

The gap this plan addressed: skills that write or publish something and then report success without inspecting the output. The sharpest case was the four `artifact-tools` skills, which publish to outward-facing `claude.ai` URLs that cannot be easily undone. A blank artifact page was indistinguishable from a good one from inside the publishing session.

The fix for the four artifact-tools skills follows the same pattern: after the `Artifact` tool returns a URL, the skill fetches it back using `WebFetch` and asserts a content marker specific to what was published — the plan title for `plan-artifact`, the diff's first filename for `diff-artifact`, the session date for `session-artifact`. A mismatch reports the failure with the URL rather than declaring success. Because `WebFetch` is not declared in the original `allowed-tools:` for these skills, a permission prompt would stall the check precisely when these skills are most likely running unattended — so the declaration was added alongside the step.

The gallery-building skills (`plans-library` and `media-library`) have a different failure mode: silent card loss. A gallery that rebuilds successfully with half the entries missing is worse than a failure, because the rebuild itself provides false assurance. The fix is a count comparison: after writing `index.html`, the skill counts the card elements in the output and compares against the number of source files it scanned. A count mismatch is a hard failure.

`plans-open` opens an existing gallery and generates nothing of its own, so it has no output to verify. Adding a spurious check would be verification theater. The plan chose instead to add a one-line note to `plans-open`'s SKILL.md naming this explicitly, so future audits see "intentionally exempt" rather than "forgotten".

The `path-rules-advisor` skill (and the planned `agentic-memory-doctor`) rewrite the files that configure every future session. A corrupted `CLAUDE.md` or rules file degrades silently across all subsequent conversations — making this the highest blast-radius write in the repo. The fix is a diff-back check: after the rewrite, the skill shows the resulting diff and asserts the file still has valid frontmatter (where applicable) and a non-empty body before reporting success.

Each new check is paired with a test suite that exercises the negative case — an empty artifact body, a hand-deleted index card, malformed rules-file frontmatter. A check that never fails is indistinguishable from no check at all.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `8641b56` | 2026-08-04 | fix(plan-agent): plans-library delegates to the gallery generator (8.5.1) (#525) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
- Related docs: `kit/plugins/artifact-tools/CHANGELOG.md`, `kit/plugins/plan-agent/CHANGELOG.md`
