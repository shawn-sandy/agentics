# Give the HTML-generating and publishing skills a check they can run

> Adds runnable output checks to nine skills that generate or publish HTML without one, closing each skill's verification loop and covering every check with a test suite that proves it fails on bad output.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added a fetch-back render assertion to all four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`): each skill now fetches its published artifact URL with `WebFetch` and asserts an expected content marker before declaring success, and each declares `WebFetch` in `allowed-tools:` to prevent permission prompts during unattended runs.
- Added an index card-count assertion to `plan-agent:plans-library` and `social-media-tools:media-library`: after writing `index.html` each skill confirms the file parses and its card count matches the number of source files scanned (preventing silent card loss without detecting it at build time).
- Added a one-line exemption note to `plan-agent:plans-open` explaining that its output check lives in `plans-library`, so future audits do not re-flag it as a gap.
- Added a diff-back check to both `memory-tools` skills (`agentic-memory-doctor`, `path-rules-advisor`): after rewriting `CLAUDE.md` or a rules file each skill shows the resulting diff, asserts valid frontmatter where applicable, and asserts a non-empty body — the highest blast-radius write in the repo now has a guard.
- Added four test suites to `tests/plugins/` covering each of the three new check types, with each suite asserting the negative case (the check fires on bad output) rather than only the positive.
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` with MINOR version bumps in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Plan publish skill — fetch-back assertion added | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Diff publish skill — fetch-back assertion added | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap skill — fetch-back assertion added | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Prompt publish skill — fetch-back assertion added | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Gallery builder — card-count assertion added | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | Gallery opener — exemption note added | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Social gallery builder — card-count assertion added | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | CLAUDE.md rewriter — diff-back + parse check added | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Rules file rewriter — diff-back + parse check added | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Smoke test: every touched SKILL.md carries a post-write assertion and all four artifact-tools skills declare `WebFetch` | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test: card-count comparison logic in isolation | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test: memory guard against fixture CLAUDE.md files | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test: publish, fetch-back, and assert flow for plan-artifact | Created |
| `.claude-plugin/marketplace.json` | Version bumps for the four touched plugins | Modified |

## How it works

A recurring audit of the 13 marketplace plugins found nine skills that write or publish output without ever reading it back. The sharpest case was the four `artifact-tools` skills: they publish to outward-facing `claude.ai` URLs and return a URL, but none fetched that URL to verify the content rendered. A published artifact that renders blank is indistinguishable from a good one from inside the session that published it.

The fix for the four artifact-tools skills follows the same shape: after the `Artifact` tool call returns a URL, the skill calls `WebFetch` on that URL and asserts the page contains a content marker — the plan title, the diff's first filename, or the session date depending on the skill. A mismatch reports failure with the URL rather than reporting success. `WebFetch` is added to each skill's `allowed-tools:` so the check cannot stall on a permission prompt mid-unattended-run.

`plans-library` and `media-library` have a different failure mode: they can silently drop cards — an index that writes successfully but contains only half the source plans. The fix adds a post-write assertion that parses the written `index.html` and counts its cards against the number of source files the skill scanned. A mismatch reports the discrepancy before declaring done.

Both `memory-tools` skills rewrite `CLAUDE.md` or rules files that govern every future session. Their failure mode is a corrupted file that degrades every subsequent conversation without leaving an obvious error. The fix shows a diff after the write and asserts the file still parses with valid frontmatter and a non-empty body. A failed assertion stops the skill and instructs a restore.

`plans-open` opens an existing gallery and generates nothing, so adding a check would be verification theater. The plan instead adds a one-line note to its `SKILL.md` recording the exemption, so future audits treat it as intentional rather than failing on it.

The four test suites all assert the negative case. A check that never fails is indistinguishable from no check. `test-generator-skills-verify-output.sh` greps every touched `SKILL.md` for its assertion text. `test-index-card-count.mjs` exercises the count comparison with three fixtures: N cards from N sources passes, N-1 cards from N sources fails, empty directory produces empty index and passes. `test-memory-doctor-guard.sh` runs the guard against valid and malformed fixture files, confirming the latter is left untouched. `test-artifact-render-check.sh` covers the publish-and-fetch-back flow end to end.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
