# Harden ship pre-flight against environment blockers

> Makes ship and ship-autonomous pre-flight report every blocker at once in one table, adds worktree env-parity and browser-availability checks, gives each pre-flight prompt a named headless default, and adds an `external-blocker` CI class so billing blocks are never autofixed as code defects.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrote `preflight-and-verify.md` Step 1 so all guards run before anything is reported, producing one PASS/FAIL/BLOCKED table with a remediation command per failing row
- Added the worktree env-parity check to the table: when in a linked worktree, compares `.env*` files in the main checkout against the current worktree and reports missing files with their exact `cp` commands (never copies automatically)
- Added the browser-availability probe to Step 2.5: states `UNVERIFIED — no browser` in session output when the browser MCP is absent instead of silently skipping verification
- Added a marker line to `pr-agent/SKILL.md` Step 5's body template so the `UNVERIFIED — no browser` string reaches the PR Test Plan section when reported
- Added a named headless default to every `AskUserQuestion` in the pre-flight path; uncommitted-plan-files gate defaults to `abort`
- Applied the same run-all-then-report contract and env-parity check to `ship/SKILL.md` Step 1 (its own copy of the guards)
- Created `ship/references/preflight-guards.md` to carry the full guard-command table without pushing `ship/SKILL.md` past its 600-word progressive-disclosure ceiling
- Added `external-blocker` as the first class in `ci-autofix.md`: billing, quota, spending limit, bad credentials, token expiry, or all-jobs-failed-with-empty-logs — reported verbatim, no autofix, attempt cap does not advance
- Documented empty-log detection for the billing-block case using `gh run view --json jobs`
- Added `tests/plugins/test-ship-preflight.sh` with content assertions across all four changed files
- Bumped `git-agent` to 4.17.0 with CHANGELOG entry and README update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Autonomous ship pre-flight — run-all-then-report, env parity, browser probe, headless defaults | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill — same run-all-then-report contract and env-parity check | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Ship pre-flight guards reference — full table format and commands for the word-capped core | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR-agent skill — Step 5 body template carries the `UNVERIFIED — no browser` marker line | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | CI autofix reference — `external-blocker` class added first in table | Modified |
| `kit/plugins/git-agent/README.md` | README — documents pre-flight table, env check, and external-blocker class | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — 4.17.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — git-agent bumped from 4.16.1 to 4.17.0 | Modified |
| `tests/plugins/test-ship-preflight.sh` | Test — content assertions across four files | Created |

## How it works

The 2026-08-14 usage report attributed roughly a quarter of all `not_achieved` sessions to pre-flight. Five or more `ship-autonomous` invocations halted at Step 1 on failed `gh auth` — the guards were correct to halt, but each blocker cost a full session spin-up because pre-flight stopped at the first failure. A session with an unauthenticated `gh`, a dirty tree, and a missing worktree `.env` therefore cost three separate spin-ups before the user could ship. The fix rewrites the ordering without changing the halt: all guards run, every result is collected into one table with its remediation command, and the skill stops on any BLOCKED row knowing all of them.

The worktree env-parity check addresses a specific phantom-bug pattern recorded twice in the report. A linked worktree created with `git worktree add` does not inherit gitignored files, so `.env` files from the main checkout are absent. When a subsequent session runs tests or a dev server from the worktree, the missing config presents as a code defect in whatever was last edited. Detection is two commands (`git rev-parse --git-dir` vs `--git-common-dir` to confirm a linked worktree, then a comparison of `.env*` filenames); the remediation is a `cp` command per missing file, written into the table but never executed. The file holds secrets, so silent copying is the wrong default even when copying is the right action.

Browser verification was degrading silently before this change. Step 2.5's browser block had no availability probe, so when the browser MCP was unavailable in a headless session, the verification steps were simply skipped — but the commit and PR body still read as though the change had been verified. The fix adopts the convention already established in `wcag-compliance-reviewer` 1.5.2: write `UNVERIFIED — no browser` rather than omit the claim. The marker must also reach the PR body. `ship-autonomous` delegates commits to `commit-agent` (a single `-m` git commit with a 72-character cap, no body) and PR creation to `pr-agent`. The only reachable surface where a reviewer would see the marker is `pr-agent`'s Test Plan section, so one line was added to `pr-agent/SKILL.md` Step 5's body template.

Pre-flight prompts had no headless default before this change. Under `claude -p` the `AskUserQuestion` tool is unavailable, and an unstated fallback means the skill improvises at exactly the gate that exists to stop it. Every `AskUserQuestion` in the pre-flight path now names its default. The uncommitted-plan-files gate defaults to `abort`, matching the conservative posture of the existing merge gate (which already states it does not apply in headless mode and reports instead of asking).

The CI triage table in `ci-autofix.md` classified `lint`, `typecheck`, `peer-deps`, and "ask the user" — nothing for failures that are not the code's fault. An expired `CLAUDE_CODE_OAUTH_TOKEN` or a billing block would burn autofix attempts against correct code. The `external-blocker` class, placed first in the table, covers billing, quota, spending limits, bad credentials, token expiry, and the billing-block edge case where no signature string exists at all (all jobs failed in seconds with empty `--log-failed` output, detected via `gh run view --json jobs`). External blockers are reported verbatim and do not advance the three-attempt autofix cap.

The `preflight-guards.md` reference file for `ship` was an unplanned addition. `ship/SKILL.md` is at its 600-word progressive-disclosure ceiling (asserted by `tests/plugins/test-skill-split-git-social.sh`) and the full guard-command table did not fit. The core carries the guard statements; the reference file carries the commands. A skill can only bundle files under its own directory, so the reference lives at `ship/references/preflight-guards.md`.

The test at `tests/plugins/test-ship-preflight.sh` makes the text contracts across four files observable. The `pr-agent` assertion is specifically what stops the marker requirement from passing the test while never reaching a PR: deleting the marker rule from `pr-agent/SKILL.md` turns exactly that one check red, proving the rule is where `gh pr create` will write it.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `9277c9f` | 2026-09-18 | feat(git-agent): commit and ship paths handle lint-gate blocks (4.21.0) (#635) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
