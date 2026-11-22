# Harden ship pre-flight

> Ship pre-flight stopped at the first failing guard, so a session with three blockers cost three full spin-ups. This makes pre-flight report every blocker at once, adds worktree env-parity and browser-availability checks, names headless defaults for each gate, and teaches CI triage that a billing block is not a code defect.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrote `skills/ship-autonomous/references/preflight-and-verify.md` Step 1: every guard (clean tree, uncommitted plan files, detached HEAD, `gh auth status`, env parity, browser availability) now runs before anything is reported; results are collected into one PASS/FAIL/BLOCKED table with a verbatim remediation command per failing row.
- Added worktree env-parity check: when `git rev-parse --git-dir` differs from `--git-common-dir` (linked worktree), compares `.env*` files in the main checkout against the worktree and reports missing files with exact `cp` commands; never copies automatically.
- Added browser-availability probe to Step 2.5: when the browser MCP is absent, states `UNVERIFIED — no browser` in session output and carries the string forward to the PR body via `pr-agent`.
- Added one line to `skills/pr-agent/SKILL.md` Step 5's body template: when the invoking skill reports a verification marker, the Test Plan section carries it verbatim.
- Gave each pre-flight `AskUserQuestion` a named headless default; the uncommitted-plan-files gate defaults to `abort`.
- Applied the run-all-then-report contract to `skills/ship/SKILL.md` Step 1 (ship's own copy of the guards).
- Added a new `references/preflight-guards.md` for ship to hold the full guard commands without pushing `ship/SKILL.md` past its 600-word ceiling.
- Added `external-blocker` class to `references/ci-autofix.md`: signatures `billing`, `quota`, `spending limit`, `Bad credentials`, token-expiry text, and all-jobs-failed-with-empty-logs; the class is ordered first in the table and never advances the three-attempt autofix cap.
- Added `tests/plugins/test-ship-preflight.sh`: asserts both pre-flight surfaces describe a single combined report, the env-parity check is gated on `--git-common-dir`, the browser probe names `UNVERIFIED — no browser`, `pr-agent` Step 5 carries the marker line, every `AskUserQuestion` names a headless default, and `ci-autofix.md` lists `external-blocker` above `lint`.
- Bumped git-agent to 4.17.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Run-all, env parity, browser probe, headless defaults | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Run-all contract + env parity | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Guard commands for ship | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Verification marker line in Test Plan | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | external-blocker class | Modified |
| `kit/plugins/git-agent/README.md` | Pre-flight table, env check, external-blocker | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.17.0 entry | Modified |
| `tests/plugins/test-ship-preflight.sh` | Pre-flight content assertions | Created |
| `.claude-plugin/marketplace.json` | git-agent → 4.17.0 | Modified |

## How it works

**Run-all-then-report**: Guards are now collected before any are acted on. The skill still halts on a BLOCKED row; it just halts knowing all of them, so a user with three blockers sees all three in one table with one spin-up.

**Env parity**: Linked worktrees don't inherit `.env` files from the main checkout (they're gitignored). The check runs `diff` between the main checkout's `.env*` files and the worktree's, reports missing ones with `cp` commands, and never copies automatically — the file holds secrets.

**Browser probe**: When the browser MCP is absent, the skill logs `UNVERIFIED — no browser` rather than silently skipping the preview block. The string is passed to `pr-agent`, which writes it into the PR's Test Plan section so reviewers know the state.

**CI external-blocker**: An expired token or quota block produces no test output. The rule keys on all-jobs-failed + empty `--log-failed` output as the billing-block signature; the attempt cap is not advanced so correct code is not rewritten.

## How to use it

No invocation change needed. The improvements apply automatically for anyone with git-agent 4.17.0+ installed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-14 | fix(git-agent): harden ship pre-flight — run-all report, env parity, browser probe, external-blocker CI class (4.17.0) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
