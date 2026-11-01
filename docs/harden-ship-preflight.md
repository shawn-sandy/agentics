# Harden ship pre-flight against environment blockers

> Pre-flight now runs every guard before reporting, adds worktree env-parity and browser-availability checks, names headless defaults, and classifies external blockers in CI triage.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrote pre-flight to run all guards before reporting — a session with multiple blockers now gets one table with every failure and its remediation command rather than separate spin-ups per blocker.
- Added a worktree env-parity check: when running inside a linked worktree, pre-flight compares `.env*` files against the main checkout and reports missing ones with the exact `cp` command (never copies automatically, since env files hold secrets).
- Added a browser-availability probe in Step 2.5: when `preview_start` is unreachable the skill states `UNVERIFIED — no browser` in session output and carries that marker forward to the PR body (adopting the `wcag-compliance-reviewer` 1.5.2 convention).
- Updated `pr-agent` Step 5 body template to include the `UNVERIFIED — no browser` line in the Test Plan section when the invoking skill reports it.
- Gave every pre-flight `AskUserQuestion` a named headless default (the uncommitted-plan-files gate defaults to `abort`) so `claude -p` sessions do not stall or improvise.
- Applied the run-all-then-report contract and env-parity check to `ship/SKILL.md` Step 1 so both `ship` and `ship-autonomous` entry points are consistent.
- Added an `external-blocker` class to `ci-autofix.md`, ordered first in the table, covering expired tokens, billing/quota blocks, and all-jobs-failed-with-empty-logs — these do not advance the three-attempt autofix cap.
- Added `tests/plugins/test-ship-preflight.sh` asserting all contracts across the four changed files.
- Bumped git-agent to 4.17.0 and documented the pre-flight table, env check, and external-blocker class in the README and CHANGELOG.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Pre-flight guard definitions and run-all-then-report contract | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill entry point with its own pre-flight copy | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Ship's guard commands reference (new; added because SKILL.md is word-capped) | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR body template Step 5 carrying the UNVERIFIED marker | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | CI failure classification table with external-blocker class | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation for pre-flight, env check, and external-blocker | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.17.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version 4.16.1 → 4.17.0 | Modified |
| `tests/plugins/test-ship-preflight.sh` | Content assertions across all four changed files | Created |

## How it works

Pre-flight in both `ship` and `ship-autonomous` previously halted at the first failing guard, meaning a session with three separate blockers (unauthenticated `gh`, dirty tree, missing worktree `.env`) required three separate spin-ups. The fix reorganises `preflight-and-verify.md` and `ship/SKILL.md` Step 1 so every guard runs first and results accumulate into one PASS/FAIL/BLOCKED table — the skill still halts on any BLOCKED row, but now it knows all of them at once.

The worktree env-parity check is gated on `git rev-parse --git-dir` differing from `git rev-parse --git-common-dir` (the condition that indicates a linked worktree). When true, it compares `.env*` files present in the main checkout against those in the current worktree, and for each missing file emits a BLOCKED row with the exact `cp` command. The file is never copied automatically — env files hold secrets and silent copying is the wrong default even when copying is the right action. This check addresses two recorded phantom bugs traced to missing worktree env files.

The browser-availability probe was added to Step 2.5: before the preview block, the skill establishes whether `preview_start` is reachable. When it is not, it emits `UNVERIFIED — no browser` in session output and carries that string forward as the verification result. `pr-agent`'s Step 5 body template was updated to include this marker in the Test Plan section when reported, so the claim reaches the reviewer rather than being silently absent from a PR body that otherwise reads as verified.

The `ci-autofix.md` classification table gained an `external-blocker` class as its first row. Its signatures cover billing, quota, and spending-limit messages; `Bad credentials`; token-expiry text; and the billing-block case where no log text exists at all (detected via `gh run view <id> --json jobs` showing all jobs failing fast with empty `--log-failed` output). An external-blocker classification does not advance the three-attempt autofix cap, preventing correct code from being mutated in response to an infrastructure failure.

`test-ship-preflight.sh` asserts all text contracts across the four changed files: both pre-flight surfaces describe a single combined report, both carry the `--git-common-dir`-gated env check, the browser probe names `UNVERIFIED — no browser`, `pr-agent` Step 5 carries the marker through to the PR, each `AskUserQuestion` names a headless default, and `ci-autofix.md` lists `external-blocker` ahead of `lint`.

## How to use it

The changes are active whenever `ship` or `ship-autonomous` runs. No invocation change is required. Key behaviours to expect:

- **Multiple blockers**: pre-flight reports all failures in one table before halting.
- **Worktree env gap**: in a linked worktree, a missing `.env` file appears as a BLOCKED row with the `cp` command to resolve it. Fixing it and re-invoking will show remaining blockers.
- **No browser**: `UNVERIFIED — no browser` appears in session output and in the PR's Test Plan section. This is not an error — it documents a limitation honestly.
- **CI failures**: `external-blocker` classifications are reported verbatim without consuming an autofix attempt.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `5e1b3c2a` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `9277c9f4` | 2026-09-18 | feat(git-agent): commit and ship paths handle lint-gate blocks (4.21.0) (#635) |
| `56a2ea36` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |
| `da54ec10` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
- Related: [kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md](../kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md)
