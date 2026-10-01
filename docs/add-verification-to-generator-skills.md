# Give the HTML-generating and publishing skills a check they can run

> Nine skills generate HTML or publish it to a live URL and then report success without ever looking at the output, so a blank artifact is indistinguishable fr...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Add a render assertion to the four `artifact-tools` skills by appending a step after each publish that fetches the returned artifact URL with `WebFetch` and asserts the page contains an expected marker (the plan title, the diff's first filename, the session date), reporting the failure with the URL on mismatch rather than reporting success — and add `WebFetch` to each of the four skills' `allowed-tools:` frontmatter, which none currently declares.
- Add an index assertion to `plans-library` and `media-library` that, after writing `index.html`, confirms the file parses and its card count matches the number of source files scanned.
- Leave `plans-open` functionally alone but add a one-line note to its SKILL.md recording that its output check lives in `plans-library`.
- Add a diff-back check to `agentic-memory-doctor` and `path-rules-advisor` that, after rewriting CLAUDE.md or a rules file, shows the resulting diff and asserts the file still parses with valid frontmatter where applicable and a non-empty body.
- Add suites to `tests/plugins/` for steps 1, 2, and 4 following the existing naming and shape, with each asserting that the skill's check fires on bad output rather than merely passing on good output.
- Bump `version` in `.claude-plugin/marketplace.json` for `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools`, adding a `kit/plugins/<name>/CHANGELOG.md` entry for each and treating an added verification step as a MINOR bump since it is new behavior with no removed interface.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | card-count assertion against source count | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | one-line note on why its check lives in plans-library | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | card-count assertion against source count | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | diff-back and parse check before reporting success | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | diff-back and parse check before reporting success | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | the objective-verification test | Created |
| `tests/plugins/test-index-card-count.mjs` | unit test for the card-count assertion | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | integration test for the memory guard | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test for the publish and fetch-back flow | Created |
| `.claude-plugin/marketplace.json` | MINOR bumps for the four plugins touched | Modified |

## How it works

Add a runnable output check to the nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done", and cover them with suites in the existing `tests/plugins/` harness.

Claude Code's best-practices guide opens with its strongest claim: "Claude stops when the work looks done. Without a check it can run, 'looks done' is the only signal available, and you become the verification loop: every mistake waits for you to notice it." A survey of the 13 marketplace plugins on 2026-07-16 read all 59 SKILL.md files and found roughly two dozen with no check step. That aggregate is approximate and deliberately not load-bearing here: it came from a keyword scan, which cannot distinguish a check from a passing mention of the word — `media-library` scanned as "checked" purely because line 87 uses "screenshot" as a noun, when in fact it has no check at all. Treat the count as a rough signal and the nine skills named below, each confirmed by reading the file, as the actual scope. Most unchecked skills are fine — a read-only advisory skill has nothing to verify. The gap that matters is skills that write a file and then assert success without opening it. Nine qualify: the four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) each publish a claude.ai artifact with no check; `plan-agent:plans-library` writes `docs/plans/index.html` with no check; `plan-agent:plans-open` opens the gallery with no check; `social-media-tools:media-library` writes `docs/media/social/index.html` with no check; and both `memory-tools` skills (`agentic-memory-doctor`, `path-rules-advisor`) rewrite CLAUDE.md or rules files with no check. The four `artifact-tools` skills are the sharpest case. They publish to a URL — an outward-facing, hard-to-reverse action — and none fetches the result back. A published artifact that renders blank is indistinguishable from a good one from inside the session that published it. This gap is not theoretical here. PR #405 shipped a `marketplace.json` version bump that broke `tests/plugins/test-artifact-tools.sh`, and all seven PR checks stayed green; only a review bot running the file by hand caught it. That is the same failure shape one layer down. Two pieces of substrate already exist and this plan builds on them rather than around them. First, `tests/plugins/` has 19 suites, including `test-build-plan-html.mjs`, `test-build-prototypes-index.sh`, and `test-artifact-titles.mjs`, so the harness and its conventions are established and new suites simply join it. Second, `docs/plans/wire-plugin-tests-into-ci.md` (status todo, issue #408) is already wiring `tests/plugins/` into PR CI and making the check block merges — so this plan touches no CI at all, and suites added here inherit that wiring for free once #408 lands. Ordering is not a blocker in either direction. The user's global CLAUDE.md already requires in-browser verification across light and dark themes before opening a PR. The skills that generate the HTML do not do it. This plan closes the distance between the standing rule and the tooling.

The implementation proceeded through the following steps: Add a render assertion to the four `artifact-tools` skills by appending a step after each publish that fetches the returned artifact URL with `WebFetch` and asserts the page contains an expected marker (the plan title, the diff's first filename, the session date), reporting the failure with the URL on mismatch rather than reporting success — and add `WebFetch` to each of the four skills' `allowed-tools:` frontmatter, which none currently declares.; Add an index assertion to `plans-library` and `media-library` that, after writing `index.html`, confirms the file parses and its card count matches the number of source files scanned.; Leave `plans-open` functionally alone but add a one-line note to its SKILL.md recording that its output check lives in `plans-library`.; Add a diff-back check to `agentic-memory-doctor` and `path-rules-advisor` that, after rewriting CLAUDE.md or a rules file, shows the resulting diff and asserts the file still parses with valid frontmatter where applicable and a non-empty body.; Add suites to `tests/plugins/` for steps 1, 2, and 4 following the existing naming and shape, with each asserting that the skill's check fires on bad output rather than merely passing on good output.; Bump `version` in `.claude-plugin/marketplace.json` for `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools`, adding a `kit/plugins/<name>/CHANGELOG.md` entry for each and treating an added verification step as a MINOR bump since it is new behavior with no removed interface..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
