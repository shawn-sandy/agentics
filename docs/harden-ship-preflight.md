# Harden ship pre-flight against environment blockers

> Makes `ship` and `ship-autonomous` run every pre-flight guard before reporting, adds worktree env-parity and browser-availability checks, gives each prompt a headless default, and adds an `external-blocker` CI class so expired tokens and billing blocks are never autofixed as code defects.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrote `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` Step 1 so every guard runs before anything is reported: clean tree, uncommitted plan files, detached HEAD, `gh auth status`, worktree env parity, and browser availability are all collected into one PASS/FAIL/BLOCKED table with a verbatim remediation command per failing row. No guard stops the sweep.
- Added the worktree env-parity check: skips unless `git rev-parse --git-dir` differs from `--git-common-dir`; when in a linked worktree, compares `.env*` files in the main checkout against those in the worktree and reports any missing with the exact `cp` command. Never copies.
- Added the browser-availability probe to Step 2.5: when `preview_start` is unreachable the skill states `UNVERIFIED — no browser` in the session output and carries that string to the PR body rather than silently skipping browser verification.
- Added one line to `kit/plugins/git-agent/skills/pr-agent/SKILL.md` Step 5's PR body template: when the invoking skill reports a verification marker, the Test Plan section carries it verbatim.
- Applied the run-all-then-report contract and env-parity check to `kit/plugins/git-agent/skills/ship/SKILL.md` Step 1, which carries its own copy of the guards.
- Created `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` (not in the original file list): `ship/SKILL.md` is capped at 600 words by `tests/plugins/test-skill-split-git-social.sh`, so the full guard command table moved to this reference file.
- Added every pre-flight `AskUserQuestion` call a named headless default; the uncommitted-plan-files gate defaults to `abort`.
- Added an `external-blocker` class to `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md`, placed first in the table: billing, quota, spending-limit, bad-credentials, token-expiry, and all-jobs-failed-with-empty-logs signatures. The class is never autofixed and never advances the three-attempt cap. The empty-log detection uses `gh run view <id> --json jobs` and treats all-jobs-failed with empty `--log-failed` output as `external-blocker`.
- Added `tests/plugins/test-ship-preflight.sh` asserting all the above as text contracts across four files.
- Bumped git-agent from 4.16.1 to 4.17.0 in `.claude-plugin/marketplace.json` and added the CHANGELOG entry and README documentation.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Run-all-then-report, env parity, browser probe, headless defaults | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Same run-all-then-report contract and env-parity check | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | ship's guard command table (moved here from SKILL.md body) | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Step 5 body template carries `UNVERIFIED — no browser` marker | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | `external-blocker` class added first in table | Modified |
| `kit/plugins/git-agent/README.md` | Pre-flight table, env check, and external-blocker class documented | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.17.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.16.1 → 4.17.0 | Modified |
| `tests/plugins/test-ship-preflight.sh` | Content assertions over both pre-flight surfaces and the CI table | Created |

## How it works

The change was motivated by a usage report attributing roughly a quarter of `not_achieved` sessions to pre-flight halts: multiple `ship-autonomous` invocations stalling at Step 1 on failed `gh auth`, with nothing committed or PR'd and each requiring a separate spin-up to discover. The guards were correct; the cost was in discovering them one per session.

The run-all-then-report change is simple: instead of each guard carrying a `STOP` when it fails, all guards run first and results collect into one table. The skill still halts on any BLOCKED row — it just halts knowing every blocker at once and presenting one remediation command per row. The halt direction is unchanged; only the discovery round-trip count changes.

The worktree env-parity check addresses two recorded phantom bugs: a Clerk sign-in regression and a missing-nav-button bug, both root-caused to a linked worktree missing its `.env` rather than the code change that appeared to cause them. Gitignored env files do not travel with `git worktree add`. The check detects by comparing the main checkout's `.env*` files against the worktree's and reporting any that are missing with the exact `cp` command. The file is never copied automatically, because it holds secrets and a silent copy is the wrong default even when copying is the right action.

The browser-availability probe closes a silent-downgrade gap. When the browser MCP is absent in a headless or non-interactive session, Step 2.5 had previously skipped browser steps silently — and the commit and PR body still read as though the change was verified. The fix adopts the convention already established in `wcag-compliance-reviewer` 1.5.2: state `UNVERIFIED — no browser` explicitly rather than omitting the claim. The `pr-agent` change is what makes this visible to a reviewer: without it the marker is produced in the session output but never reaches the PR body.

The `external-blocker` CI class closes a gap in `ci-autofix.md` that existed despite the same rule being written in `plan-agent`'s red-green-verify guidance. A billing-blocked GitHub Actions run fails every job in seconds with no test output; classifying it as a code defect causes the autofix loop to burn attempts and modify correct code. The empty-log detection (`gh run view --json jobs` + all-jobs-failed-fast + empty `--log-failed`) was measured on the repo's actual failed runs rather than assumed from duration thresholds.

The Completion Report notes: the no-browser acceptance criterion was verified as a text contract at its point of use, not by an executed headless run (a browser MCP was present in the implementing session). The end-to-end worktree scratch-repo rehearsal was also not executed (driving a `disable-model-invocation` skill end-to-end requires a separate interactive session).

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `56a2ea3` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
