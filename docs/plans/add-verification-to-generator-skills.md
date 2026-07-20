---
status: completed
type: feature
created: 2026-07-16
modified: 2026-07-19
repo-name: agentics
effort: medium
glance: Nine skills generate HTML or publish it to a live URL and then report success without ever looking at the output, so a blank artifact is indistinguishable from a good one from inside the session that made it. This gives each one a check it can run, and covers every check with a suite that proves it fails on bad output.
---

# Plan: Give the HTML-generating and publishing skills a check they can run

## Objective

Add a runnable output check to the nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done", and cover them with suites in the existing `tests/plugins/` harness.

## Context

Claude Code's best-practices guide opens with its strongest claim: "Claude stops when the work looks done. Without a check it can run, 'looks done' is the only signal available, and you become the verification loop: every mistake waits for you to notice it."

A survey of the 13 marketplace plugins on 2026-07-16 read all 59 SKILL.md files and found roughly two dozen with no check step. That aggregate is approximate and deliberately not load-bearing here: it came from a keyword scan, which cannot distinguish a check from a passing mention of the word — `media-library` scanned as "checked" purely because line 87 uses "screenshot" as a noun, when in fact it has no check at all. Treat the count as a rough signal and the nine skills named below, each confirmed by reading the file, as the actual scope.

Most unchecked skills are fine — a read-only advisory skill has nothing to verify. The gap that matters is skills that write a file and then assert success without opening it. Nine qualify: the four `artifact-tools` skills (`plan-artifact`, `diff-artifact`, `session-artifact`, `prompt-artifact`) each publish a claude.ai artifact with no check; `plan-agent:plans-library` writes `docs/plans/index.html` with no check; `plan-agent:plans-open` opens the gallery with no check; `social-media-tools:media-library` writes `docs/media/social/index.html` with no check; and both `memory-tools` skills (`agentic-memory-doctor`, `path-rules-advisor`) rewrite CLAUDE.md or rules files with no check.

The four `artifact-tools` skills are the sharpest case. They publish to a URL — an outward-facing, hard-to-reverse action — and none fetches the result back. A published artifact that renders blank is indistinguishable from a good one from inside the session that published it.

This gap is not theoretical here. PR #405 shipped a `marketplace.json` version bump that broke `tests/plugins/test-artifact-tools.sh`, and all seven PR checks stayed green; only a review bot running the file by hand caught it. That is the same failure shape one layer down.

Two pieces of substrate already exist and this plan builds on them rather than around them. First, `tests/plugins/` has 19 suites, including `test-build-plan-html.mjs`, `test-build-prototypes-index.sh`, and `test-artifact-titles.mjs`, so the harness and its conventions are established and new suites simply join it. Second, `docs/plans/wire-plugin-tests-into-ci.md` (status todo, issue #408) is already wiring `tests/plugins/` into PR CI and making the check block merges — so this plan touches no CI at all, and suites added here inherit that wiring for free once #408 lands. Ordering is not a blocker in either direction.

The user's global CLAUDE.md already requires in-browser verification across light and dark themes before opening a PR. The skills that generate the HTML do not do it. This plan closes the distance between the standing rule and the tooling.

## Files

- `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` (modified) — fetch-back render assertion after publish
- `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` (modified) — fetch-back render assertion after publish
- `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` (modified) — fetch-back render assertion after publish
- `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` (modified) — fetch-back render assertion after publish
- `kit/plugins/plan-agent/skills/plans-library/SKILL.md` (modified) — card-count assertion against source count
- `kit/plugins/plan-agent/skills/plans-open/SKILL.md` (modified) — one-line note on why its check lives in plans-library
- `kit/plugins/social-media-tools/skills/media-library/SKILL.md` (modified) — card-count assertion against source count
- `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` (modified) — diff-back and parse check before reporting success
- `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` (modified) — diff-back and parse check before reporting success
- `tests/plugins/test-generator-skills-verify-output.sh` (new) — the objective-verification test
- `tests/plugins/test-index-card-count.mjs` (new) — unit test for the card-count assertion
- `tests/plugins/test-memory-doctor-guard.sh` (new) — integration test for the memory guard
- `tests/plugins/test-artifact-render-check.sh` (new) — E2E test for the publish and fetch-back flow
- `.claude-plugin/marketplace.json` (modified) — MINOR bumps for the four plugins touched

## Steps

1. Add a render assertion to the four `artifact-tools` skills by appending a step after each publish that fetches the returned artifact URL with `WebFetch` and asserts the page contains an expected marker (the plan title, the diff's first filename, the session date), reporting the failure with the URL on mismatch rather than reporting success — and add `WebFetch` to each of the four skills' `allowed-tools:` frontmatter, which none currently declares. Why: these publish to an outward-facing URL and are the only skills here whose output the user cannot see locally, and `WebFetch` can already read `claude.ai/code/artifact/{uuid}` URLs via the user's login, so the check needs no new dependency — but `.claude/rules/plugin-patterns.md:50` requires every tool a skill uses to be declared, and an undeclared `WebFetch` would stall the new check on a permission prompt at exactly the moment these skills are most likely running unattended. Verify: `grep -l WebFetch kit/plugins/artifact-tools/skills/*/SKILL.md` lists all four; publishing a known-good plan through `plan-artifact` reports the fetched marker with no permission prompt; and publishing HTML whose body is a single empty `div` makes the skill report failure instead of success.
2. Add an index assertion to `plans-library` and `media-library` that, after writing `index.html`, confirms the file parses and its card count matches the number of source files scanned. Why: these rebuild a gallery from a directory scan and their failure mode is silent card loss — an index that writes successfully with half the plans missing — which is exactly what the `merge-plans-index.mjs` driver exists to prevent at merge time but nothing checks at build time. Verify: running `plans-library` against `docs/plans/` reports a card count equal to `ls docs/plans/*.html | grep -v index | wc -l`, and hand-deleting a card from the generated index makes a re-run report the mismatch.
3. Leave `plans-open` functionally alone but add a one-line note to its SKILL.md recording that its output check lives in `plans-library`. Why: it opens an existing gallery and generates nothing, so it has no output to verify and adding a check would be verification theater — but naming this explicitly stops a future audit from re-flagging it as a gap. Verify: `plans-open`'s SKILL.md carries the note, and the audit test from step 5 treats it as intentionally exempt rather than failing on it.
4. Add a diff-back check to `agentic-memory-doctor` and `path-rules-advisor` that, after rewriting CLAUDE.md or a rules file, shows the resulting diff and asserts the file still parses with valid frontmatter where applicable and a non-empty body. Why: these rewrite the file that configures every future session, so a corrupted CLAUDE.md degrades every subsequent conversation silently and the damage outlives the session that caused it, making this the highest blast-radius write in the repo. Verify: running `agentic-memory-doctor` against a CLAUDE.md with valid frontmatter prints a diff and confirms the parse, and pointing it at a fixture with malformed frontmatter makes it report rather than write.
5. Add suites to `tests/plugins/` for steps 1, 2, and 4 following the existing naming and shape, with each asserting that the skill's check fires on bad output rather than merely passing on good output. Why: a check that never fails is indistinguishable from no check, so the negative case is the test worth having — and PR #405's green-CI-over-red-test is the precedent for why the assertion itself must be exercised. Verify: each new suite passes, and temporarily inverting one assertion makes its suite fail.
6. Bump `version` in `.claude-plugin/marketplace.json` for `artifact-tools`, `plan-agent`, `social-media-tools`, and `memory-tools`, adding a `kit/plugins/<name>/CHANGELOG.md` entry for each and treating an added verification step as a MINOR bump since it is new behavior with no removed interface. Why: `scripts/check-plugin-versions.mjs` fails any PR that changes a plugin without raising its marketplace version. Verify: `node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code (it modifies SKILL.md workflow files and adds executable suites)
- Objective: each of the eight skills this plan touches contains a check step that runs after its write or publish step, which is the plan's stated objective, so the gap cannot silently reopen. File: `tests/plugins/test-generator-skills-verify-output.sh`; Type: smoke; Asserts: every touched SKILL.md has a post-write assertion, each of the four artifact-tools skills declares `WebFetch` in `allowed-tools:`, and `plans-open` is recorded as intentionally exempt; Run: `bash tests/plugins/test-generator-skills-verify-output.sh`
- Unit: the card-count assertion from step 2, in isolation. File: `tests/plugins/test-index-card-count.mjs`; Targets: the count comparison logic; Key cases: an index with N cards from N sources passes, an index with N-1 cards from N sources fails, an empty source directory produces an empty index and passes
- Integration: the memory guard against fixture CLAUDE.md files. File: `tests/plugins/test-memory-doctor-guard.sh`; Targets: `agentic-memory-doctor`; Key cases: valid frontmatter is rewritten and diffed, malformed frontmatter is reported and the file is left untouched
- E2E: the full publish, fetch-back, and assert flow. File: `tests/plugins/test-artifact-render-check.sh`; Targets: `plan-artifact`; Key cases: a published plan's marker is found, an empty-body artifact is reported as a failure rather than a success

## Acceptance Criteria

- [ ] Each of the four `artifact-tools` skills fetches its published URL back and asserts a marker before reporting success
- [ ] Each of the four declares `WebFetch` in `allowed-tools:`, so the new check cannot stall on a permission prompt
- [ ] `plans-library` and `media-library` assert card count against source count
- [ ] `plans-open` carries a note explaining why it has no check of its own
- [ ] Both `memory-tools` skills diff and parse-check their output before reporting success
- [ ] Every new check is exercised by a suite that proves it fails on bad output
- [ ] All new suites live in `tests/plugins/` and follow existing conventions
- [ ] No CI workflow file is modified by this plan
- [ ] `node scripts/check-plugin-versions.mjs` exits 0

## Verification

Run the full `tests/plugins/` suite and confirm all pass, old and new. Then, for each of the three new checks, break the output deliberately — an empty artifact body, a hand-deleted index card, a malformed CLAUDE.md frontmatter — and confirm the skill reports the failure rather than reporting success; this is the plan's real end-to-end proof, because the objective is a check that catches things and only the negative case demonstrates that. Publish a real plan via `plan-artifact` and open the returned URL in a browser in both light and dark themes, per the standing global rule. Confirm `node scripts/check-plugin-versions.mjs` exits 0. Finally confirm `git diff --name-only` touches no file under `.github/workflows/`, since CI wiring belongs to the wire-plugin-tests-into-ci plan.

## Next Steps

- Audit the remaining unchecked skills and classify which genuinely need a check
  This plan covered the 9 that generate or publish HTML; roughly 15 others scan as unchecked, but the scan is unreliable and each needs reading.
  ```text
  In the agentics repo, a keyword scan of the 13 marketplace plugins' 59 SKILL.md
  files flags ~23 as having no verification step, but the scan is unreliable in both
  directions — it counts a passing mention of "screenshot" as a check. The
  add-verification-to-generator-skills plan covered the 9 that generate or publish
  HTML. Read (do not grep) the ~15 others — build-proposal, code-review-agent,
  deep-grill, export-session, plan-status, plan-to-html, planning-skills,
  reviewing-skills, save-artifact, security-scrub, settings-backup, share-scan,
  social-share, sync-rules, tdd-loop — and classify each as (a) genuinely needs a check —
  it writes something whose correctness is not self-evident, (b) read-only advisory,
  no check possible or needed, or (c) its check correctly lives in a skill it
  delegates to. Report the classification as a table. Only propose work for
  category (a), and for each name the specific check and what bad output it would
  catch. Do not add checks to category (b) — a check that cannot fail is noise.
  ```

- Consider promoting the artifact render-check from a skill step to a Stop hook
  Publishing is hard to reverse, and the best-practices doc frames a Stop hook as the deterministic version of an advisory SKILL.md step.
  ```text
  In the agentics repo, the artifact-tools skills publish to outward-facing
  claude.ai URLs. The Claude Code best-practices doc describes a Stop hook as the
  deterministic version of a verification gate — it blocks the turn from ending
  until a check script passes, versus a SKILL.md instruction which is advisory.
  Assess whether the artifact-tools render-check should be promoted from a SKILL.md
  step to a Stop hook, given that publishing is hard to reverse. Weigh it against
  the cost: the hook fires on every turn, not just publishing turns. Recommend
  hook, skill-step, or both, with reasoning.
  ```
