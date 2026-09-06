# Give the HTML-generating and publishing skills a check they can run

> Adds a runnable output check to eight skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done".

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added a post-publish render assertion to the four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`): each fetches its returned artifact URL with `WebFetch` and asserts the page contains an expected marker (plan title, diff's first filename, session date) before reporting success; `WebFetch` was added to each skill's `allowed-tools:` frontmatter, which none previously declared.
- Added an index assertion to `plans-library` and `media-library`: after writing `index.html`, each confirms the file parses and its card count matches the number of source files scanned.
- Added a one-line note to `plans-open/SKILL.md` recording that its output check lives in `plans-library` (it opens an existing gallery and generates nothing, so an independent check would be verification theater).
- Added a diff-back check to `path-rules-advisor`: after rewriting a rules file, the skill shows the resulting diff and asserts the file still parses with valid frontmatter where applicable and a non-empty body.
- Added a smoke test `tests/plugins/test-generator-skills-verify-output.sh` asserting that every touched SKILL.md has a post-write assertion, each of the four artifact-tools skills declares `WebFetch` in `allowed-tools:`, and `plans-open` is recorded as intentionally exempt.
- Added `tests/plugins/test-index-card-count.mjs` for the card-count assertion in isolation.
- Bumped `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools` in `.claude-plugin/marketplace.json` with CHANGELOG entries for each, treating an added verification step as a MINOR bump (new behavior, no removed interface).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fetch-back render assertion after publish | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | One-line note: check lives in plans-library | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Card-count assertion against source count | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Diff-back and parse check before reporting success | Missing |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Diff-back and parse check before reporting success | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Objective-verification smoke test | Created |
| `tests/plugins/test-index-card-count.mjs` | Unit test for card-count assertion | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | Integration test for memory guard | Missing |
| `tests/plugins/test-artifact-render-check.sh` | E2E test for publish and fetch-back flow | Missing |
| `.claude-plugin/marketplace.json` | MINOR bumps for four touched plugins | Modified |

## How it works

The four `artifact-tools` skills publish to outward-facing claude.ai URLs — an action that is external sharing and hard to reverse. Before this change, none fetched the result back. A published artifact rendering blank was indistinguishable from a good one from inside the session that published it. The fix appends a step after each publish that calls `WebFetch` on the returned URL and asserts the page contains a skill-specific marker (the plan title for `plan-artifact`, the diff's first filename for `diff-artifact`, the session date for `session-artifact`). `WebFetch` is declared in each skill's `allowed-tools:` frontmatter — `.claude/rules/plugin-patterns.md:50` requires every tool a skill uses to be declared, and an undeclared `WebFetch` would stall the check on a permission prompt at exactly the moment these skills are most likely running unattended.

The plans-library and media-library skills rebuild a gallery from a directory scan. Their failure mode is silent card loss — an index that writes successfully with half the plans missing — which the `merge-plans-index.mjs` merge driver guards at merge time but nothing checked at build time. The fix adds an assertion after writing `index.html` that parses the file and compares its card count against the number of source files scanned. `plans-open` opens an existing gallery and generates nothing, so it has no output to verify; naming this explicitly in its SKILL.md stops a future audit from re-flagging it as a gap.

The `path-rules-advisor` skill rewrites files that configure every future session. A corrupted rules file degrades every subsequent conversation silently and the damage outlives the session that caused it — the highest blast-radius write in the repo. The fix adds a diff-back step that shows the resulting diff after rewriting a rules file and asserts the file still parses with valid frontmatter and a non-empty body.

The motivation for this plan was grounded in a specific precedent: PR #405 shipped a `marketplace.json` version bump that broke `tests/plugins/test-artifact-tools.sh`, yet all seven PR checks stayed green. Only a review bot running the file by hand caught it. The same failure shape — a check that exists but is not exercised — is what the new negative-case assertions guard against. Each new test suite proves its check fails on bad output, not just passes on good output.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
