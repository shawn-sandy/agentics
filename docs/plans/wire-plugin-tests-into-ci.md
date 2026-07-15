---
status: todo
type: fix
created: 2026-07-15
issue: https://github.com/shawn-sandy/agentics/issues/408
effort: high
glance: A red smoke test sat under an all-green PR because nothing runs tests/plugins/ on pull requests — this wires every suite into PR CI and makes the check actually block a merge, after first fixing the two suites that are red on main by construction.
---

# Plan: Wire tests/plugins/ into PR CI and fix the version guards blocking it

## Objective

Make every suite in `tests/plugins/` run on every pull request and actually
block a merge when it fails — which takes both a new workflow and a required
status check in the repo's branch ruleset — and fix the two plan-agent version
guards that fail on a clean `main`, which currently make that wiring
impossible.

## Context

This closes [#408](https://github.com/shawn-sandy/agentics/issues/408) and its
blocker [#409](https://github.com/shawn-sandy/agentics/issues/409) in one
change, because #408 cannot land alone: enabling PR CI while two suites are
red on `main` would fail every incoming pull request on arrival.

The gap was proven on PR #405: a `marketplace.json` version bump broke
`tests/plugins/test-artifact-tools.sh`, yet all seven PR checks stayed green —
only a review bot running the file by hand caught it. Today the only workflow
touching `tests/` is `publish-dist.yml`, which runs a hand-picked 4 of the 19
suites on a nightly cron, never on pull requests. The other 15 run nowhere.

The two suites red on `main` are `test-build-proposal.sh` (check 12) and
`test-setup-sites.sh` (check 10). Each asserts the plan-agent version in
`marketplace.json` is strictly *above* `origin/main` — true only on a branch
that bumps plan-agent, false everywhere else including `main` itself. The fix
replaces that branch-dependent comparison with the invariant PRs #405 and
#407 independently converged on for artifact-tools: the marketplace version
must equal the newest release heading in the plugin's CHANGELOG. One format
trap: plan-agent's CHANGELOG headings are `## 3.0.0 — Title (date)`, not the
`## [1.2.0]` bracketed form artifact-tools uses, so the heading regex must
accept both. One preservation duty: each guard also asserts the plugin
description mentions its skill (`build-proposal` / `setup-sites`) — those
assertions stay.

`publish-dist.yml` keeps its own pre-publish test steps untouched; it gates
publishing, not merging, and is out of scope here. That leaves four suites
running in both places (the nightly publish gate and the new PR gate) while
`tests/publish/` stays PR-invisible — deliberate, not an oversight.

**A workflow alone does not block anything.** A check that reports red still
lets a pull request merge unless it is marked required. This repo protects
`main` with two active rulesets (`main` and `main-branch`), and neither carries
a `required_status_checks` rule — they enforce only `deletion`,
`non_fast_forward`, `copilot_code_review`, and `pull_request`. Note the legacy
branch-protection API reports `main` as unprotected (`gh api
repos/shawn-sandy/agentics/branches/main/protection` returns 404), which is
misleading: rulesets supersede it, and adding classic branch protection here
would create a third, competing mechanism. Step 6 therefore adds the required
check to the existing ruleset.

Two risks come with that gate. Open pull requests (#384 and #266 today) predate
the workflow file, so GitHub will never run it for them; once the check is
required they stick at "Expected — waiting for status to be reported" until
their authors merge `main` in. And enforcement is a repo setting, not a commit,
so the rollback for a misfiring check is an admin removing the ruleset rule —
not a revert of this work.

One more property worth recording: `.claude-plugin/marketplace.json` has a
custom merge driver that keeps the higher semver, but GitHub's web merge button
does not run local merge drivers, and no driver covers `CHANGELOG.md` at all.
Concurrent version bumps therefore surface as visible conflicts rather than
silent bad merges. The CHANGELOG-agreement guard is less race-prone than the
`origin/main` comparison it replaces — but a careless conflict resolution can
still land a mismatch, which is caught only once the check is genuinely
required.

## Files

- scripts/check-changelog-version.mjs (new) — shared helper asserting a plugin's marketplace version equals its newest CHANGELOG heading, accepting both heading forms
- tests/plugins/test-build-proposal.sh (modified) — replace the above-origin/main version check with a call to the shared helper, preserving the file's FAILURES-counter idiom and its build-proposal description assertion
- tests/plugins/test-setup-sites.sh (modified) — same replacement, preserving the setup-sites description assertion
- tests/plugins/test-artifact-tools.sh (modified) — swap its inline copy of the same invariant for the shared helper
- scripts/run-plugin-tests.sh (new) — the run-all glob loop, invoked identically by CI and by hand
- .github/workflows/plugin-tests.yml (new) — PR-triggered workflow calling scripts/run-plugin-tests.sh
- tests/plugins/test-plugin-ci-wiring.sh (new) — objective-verification test covering the workflow's shape and both guards' pass and fail paths
- tests/fixtures/changelog-formats/ (new) — two minimal CHANGELOG fixtures, bracketed and unbracketed, proving both heading forms parse
- README.md (modified) — add the plugin-tests.yml row to the CI/CD table

## Steps

1. Write scripts/check-changelog-version.mjs taking a plugin name, reading its version from .claude-plugin/marketplace.json and the newest release heading from kit/plugins/<name>/CHANGELOG.md, and exiting non-zero when they disagree — with a heading regex accepting both the bracketed `## [1.2.0]` form artifact-tools uses and the unbracketed `## 3.0.0 — Title (date)` form plan-agent uses Why: this invariant is about to exist in three suites, each with its own regex and its own special-casing of that format difference; one tested helper absorbs the variance instead of three copies drifting apart Verify: `node scripts/check-changelog-version.mjs plan-agent` and `... artifact-tools` both exit 0 against the current tree, and each exits non-zero against the matching fixture in tests/fixtures/changelog-formats/ built to disagree.
2. Add tests/fixtures/changelog-formats/ containing one minimal CHANGELOG in each heading form, plus the marketplace snippets they pair with — one pair agreeing, one pair disagreeing Why: only the unbracketed form is exercised by the two guards this plan touches, so the bracketed branch of the shared regex would ship with no coverage at all; fixtures also give the negative path something stable to assert against without mutating tracked files Verify: `ls tests/fixtures/changelog-formats/` shows both forms, and the helper reports agreement for the agreeing pair and disagreement for the other.
3. Replace check 12 in tests/plugins/test-build-proposal.sh and check 10 in tests/plugins/test-setup-sites.sh with a call to the shared helper, and swap test-artifact-tools.sh's inline copy for the same call — preserving each file's own idiom (the `echo "N. ..."` + FAILURES counter in the first two, `fail()`/`ok()` in artifact-tools) and every existing description assertion (`build-proposal`, `setup-sites`) Why: the above-origin/main comparison is only true on branches that bump plan-agent, so both suites fail on main and on every unrelated PR; importing artifact-tools' hard-exit style into counter-style files would silently change how their remaining checks report Verify: all three suites exit 0 on the clean tree, `git grep -l "origin/main" tests/plugins/` returns nothing, and each suite's check count is unchanged from before the edit.
4. Write scripts/run-plugin-tests.sh running every `tests/plugins/*.sh` via bash and every `tests/plugins/*.mjs` via node, counting failures rather than stopping at the first, printing each failing suite by name, and exiting non-zero if any failed Why: CI and a developer must run the identical command or "green locally" stops predicting green in CI — and run-all reporting shows the full damage in one run instead of one failure per push Verify: `bash scripts/run-plugin-tests.sh` exits 0 listing every suite as passing, and exits non-zero naming exactly the offender when a deliberately-failing dummy suite is dropped into tests/plugins/ (removed after).
5. Create .github/workflows/plugin-tests.yml with `name: plugin-tests`, a `pull_request` trigger, `permissions: contents: read`, actions/checkout@v4, actions/setup-node@v4 (node 20, matching publish-dist.yml), `timeout-minutes: 20`, a `concurrency` group keyed to the PR ref with `cancel-in-progress: true`, and a single step invoking `bash scripts/run-plugin-tests.sh` Why: the explicit name is what makes the check appear as `plugin-tests` — the string step 7 marks required and Verification looks for — while every other workflow here declares its own least-privilege `permissions` block, and a read-only PR trigger against untrusted branches is the last place to inherit defaults; 20 minutes leaves headroom for a suite list designed to grow by glob Verify: `actionlint .github/workflows/plugin-tests.yml` passes (fall back to a plain YAML parse if actionlint is unavailable), and the file contains no hand-listed suite paths.
6. Add tests/plugins/test-plugin-ci-wiring.sh asserting the workflow exists with its `pull_request` trigger, `name: plugin-tests`, `permissions`, `timeout-minutes`, and `concurrency`; that it delegates to scripts/run-plugin-tests.sh rather than hand-listing suites; that run-plugin-tests.sh picks up a temporary dummy suite dropped into tests/plugins/ and still reports a deliberately-failing one by name while running the rest; and that the shared helper exits non-zero on the disagreeing fixture Why: every one of those is a stated acceptance criterion that would otherwise be proven once by hand and never again — a future edit could drop the trigger, weaken the guard to always-exit-0, or reintroduce a hand-maintained list, and nothing would notice Verify: `bash tests/plugins/test-plugin-ci-wiring.sh` exits 0, and it is picked up automatically by run-plugin-tests.sh since it lives in tests/plugins/.
7. Add the plugin-tests.yml row to README.md's CI/CD table (line ~1012), matching the existing `Workflow | Trigger | Purpose` shape Why: that table documents every workflow in .github/workflows/, and CLAUDE.md requires docs updated alongside the change — a workflow absent from it is the kind of drift the table exists to prevent Verify: the table lists plugin-tests.yml with its pull_request trigger, and the row count matches the number of files in .github/workflows/.
8. Run `bash scripts/run-plugin-tests.sh` and confirm all 21 suites (19 existing, plus the wiring test, plus any added here) exit 0 Why: this is the exact command CI will run, so a green sweep here is what keeps the workflow's first outing from painting the PR red on arrival Verify: the script exits 0 and its summary names every suite as passing.
9. After the workflow has run green once on this pull request, add `plugin-tests` as a required status check to the existing `main` ruleset via `gh api repos/shawn-sandy/agentics/rulesets/13160559` (or ruleset 14869592 — confirm which is authoritative first), adding a `required_status_checks` rule; then merge `main` into the two open pull requests (#384, #266) so they can report the new check Why: without this the objective is unmet — the workflow reports a badge and nothing blocks a merge; adding it only after a green run avoids blocking every PR on an unproven check, and the two open PRs predate the workflow file so GitHub will never run it for them, leaving them stuck at "waiting for status to be reported" until they sync Verify: `gh api repos/shawn-sandy/agentics/rulesets/13160559 --jq '[.rules[].type]'` includes `required_status_checks`, and a pull request with a deliberately failing suite shows a blocked merge button.

## Tests

Tier 1 — Steps create two executable scripts (scripts/check-changelog-version.mjs and scripts/run-plugin-tests.sh) that CI and three suites depend on
- Objective: every tests/plugins/ suite runs on a pull request and a failing one is reported without halting the rest. File: tests/plugins/test-plugin-ci-wiring.sh; Type: smoke; Asserts: plugin-tests.yml carries name/pull_request/permissions/timeout/concurrency and delegates to run-plugin-tests.sh with no hand-listed suites; a dummy suite dropped into tests/plugins/ is picked up with no workflow edit; a deliberately-failing dummy is named while the remaining suites still run and the script exits non-zero; Run: bash tests/plugins/test-plugin-ci-wiring.sh
- Unit: shared CHANGELOG-version helper. File: tests/plugins/test-changelog-version-helper.mjs; Targets: scripts/check-changelog-version.mjs; Key cases: bracketed `## [1.2.0]` heading agrees, unbracketed `## 3.0.0 — Title (date)` heading agrees, disagreeing version exits non-zero, missing CHANGELOG exits non-zero with a named reason
- Integration: rewritten guards call the shared helper. File: tests/plugins/test-plugin-ci-wiring.sh; Targets: test-build-proposal.sh, test-setup-sites.sh, test-artifact-tools.sh against the helper; Key cases: all three exit 0 on the clean tree, each exits non-zero against the disagreeing fixture, each preserves its own description assertion and check count

## Acceptance Criteria

- [ ] `bash tests/plugins/test-build-proposal.sh` exits 0 on a clean checkout of main
- [ ] `bash tests/plugins/test-setup-sites.sh` exits 0 on a clean checkout of main
- [ ] All three guards exit non-zero against a fixture whose marketplace version disagrees with its newest CHANGELOG heading, asserted by a committed test rather than a manual mutation
- [ ] The shared helper parses both the bracketed and unbracketed CHANGELOG heading forms, each proven by a fixture
- [ ] All three guards still assert their plugin description mentions build-proposal / setup-sites, and each suite's check count is unchanged
- [ ] `git grep -l "origin/main" tests/plugins/` returns nothing
- [ ] .github/workflows/plugin-tests.yml declares name: plugin-tests, a pull_request trigger, permissions: contents: read, timeout-minutes, and a concurrency group with cancel-in-progress
- [ ] The workflow delegates to scripts/run-plugin-tests.sh and contains no hand-listed suite paths
- [ ] A deliberately-failing suite is reported by name while the remaining suites still run, and the script exits non-zero — asserted by a committed test
- [ ] A file dropped into tests/plugins/ matching *.sh or *.mjs is executed with no workflow edit, asserted behaviourally rather than by grepping the YAML
- [ ] README.md's CI/CD table has a plugin-tests.yml row
- [ ] `plugin-tests` is a required status check in the main ruleset, and a pull request with a failing suite shows a blocked merge button

## Verification

Open a pull request containing this change and confirm a check named
`plugin-tests` appears in its check list and concludes green — that single
observation proves the trigger fires, the runner script finds every suite, and
all of them pass on a GitHub runner rather than only on a laptop.

Then prove the gate actually gates, which is the part a green check cannot
show. With `plugin-tests` marked required on the `main` ruleset, push a commit
that deliberately breaks one suite and confirm two things on the pull request:
the check goes red naming that suite, and the merge button is blocked rather
than merely decorated. Revert the commit and confirm the button unblocks. A
plan that stopped at "the check is green" would have shipped a badge, not a
gate.

Finally, confirm `git grep -l "origin/main" tests/plugins/` returns nothing —
the branch-dependent comparison is gone, so no suite needs fetch history to
pass — and run `bash scripts/run-plugin-tests.sh` locally to confirm it reports
the same result CI did, since a divergence between those two is what makes a
green local run stop meaning anything.

## Next Steps

- Migrate publish-dist.yml's hand-picked test list to the same glob
  The nightly publish gate still lists 4 suites by hand; now that a glob pattern is proven in plugin-tests.yml, the same loop would keep the publish gate in sync automatically.
  ```text
  In the shawn-sandy/agentics repo, edit .github/workflows/publish-dist.yml:
  replace the four hand-listed tests/plugins/ steps (test-prototype-portability.sh,
  test-build-prototypes-index.sh, test-prototype-persistence.mjs,
  test-save-artifact.sh) with the same glob loops used in
  .github/workflows/plugin-tests.yml (for t in tests/plugins/*.sh; do bash "$t" || exit 1; done
  and the node equivalent for *.mjs). Keep the tests/publish/ steps unchanged.
  Verify with a workflow_dispatch run.
  ```
- Extend the CHANGELOG-agreement invariant to every plugin
  Once scripts/check-changelog-version.mjs exists, only three plugins call it; the other ten have no version guard at all, and the helper is already parameterized by plugin name.
  ```text
  In the shawn-sandy/agentics repo, add tests/plugins/test-marketplace-changelog-sync.sh
  that calls scripts/check-changelog-version.mjs for every plugin entry in
  .claude-plugin/marketplace.json that has a kit/plugins/<name>/CHANGELOG.md,
  reporting each plugin checked and failing if any disagree. The helper already
  accepts both the "## X.Y.Z" and "## [X.Y.Z]" heading forms. It will be picked
  up automatically by scripts/run-plugin-tests.sh with no workflow edit.
  ```
- Add a CI-vs-local drift guard for the runner script
  scripts/run-plugin-tests.sh only keeps its CI/local parity promise while the workflow actually calls it and nothing else; today that is asserted by one grep in the wiring test.
  ```text
  In the shawn-sandy/agentics repo, strengthen tests/plugins/test-plugin-ci-wiring.sh
  so it parses .github/workflows/plugin-tests.yml and asserts that every run: step
  in the job invokes scripts/run-plugin-tests.sh and that no step contains an
  inline bash/node loop over tests/plugins/. This prevents a future edit from
  reintroducing suite-running logic in the YAML that diverges from what
  developers run locally.
  ```
