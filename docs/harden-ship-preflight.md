# Harden ship pre-flight against environment blockers

> Ship pre-flight stops at the first failing guard, so a session with three blockers costs three full spin-ups — and it never checks the one that has caused two phantom bugs, a linked worktree missing its .env.

<!-- generated:start -->

**Status:** Shipped 2026-08-14  **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrote `ship-autonomous/references/preflight-and-verify.md` Step 1 to run every guard before reporting, collecting results into one PASS/FAIL/BLOCKED table with a verbatim remediation command per row (replacing stop-on-first-failure semantics).
- Added a worktree env-parity check that detects `.env*` files present in the main checkout but missing from a linked worktree — the cause of two recorded phantom bugs — and emits the exact `cp` command per missing file without ever copying automatically.
- Added a browser-availability probe to Step 2.5: when `preview_start` is unreachable, the skill states `UNVERIFIED — no browser` in session output and carries that string forward so the PR body can surface it.
- Added one line to `pr-agent/SKILL.md` Step 5's body template so the Test Plan section carries the `UNVERIFIED — no browser` marker verbatim when reported.
- Gave each pre-flight `AskUserQuestion` a named headless default (the uncommitted-plan-files gate defaults to `abort`) so the skill behaves predictably under `claude -p`.
- Applied the same run-all-then-report contract and env-parity check to `skills/ship/SKILL.md` Step 1 (the interactive entry point).
- Added an `external-blocker` class to `ci-autofix.md` covering billing blocks, quota exhaustion, expired credentials, and all-jobs-failed-with-empty-log-output — classified first in the table with no autofix and no advancement of the three-attempt cap.
- Created `skills/ship/references/preflight-guards.md` (not in the original file list) to hold the full guard table because `ship/SKILL.md` is capped at 600 words by `test-skill-split-git-social.sh`.
- Added `tests/plugins/test-ship-preflight.sh` asserting all contracts across all four files.
- Bumped git-agent to 4.17.0 with changelog and README entries.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Ship-autonomous pre-flight — run-all-then-report, env parity, browser probe, headless defaults | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill — run-all-then-report, env-parity check | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Ship guard table reference (added, not originally listed) | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR agent — UNVERIFIED marker in Step 5 body template | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | CI autofix reference — external-blocker class | Modified |
| `kit/plugins/git-agent/README.md` | Plugin README — pre-flight table, env check, external-blocker | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — 4.17.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — git-agent 4.16.1 → 4.17.0 | Modified |
| `tests/plugins/test-ship-preflight.sh` | Objective test — eight content assertions across four files | Created |

## How it works

The original pre-flight in `preflight-and-verify.md` ran guards sequentially and stopped at the first `BLOCKED` row. A session with an unauthenticated `gh`, a dirty tree, and a missing worktree `.env` required three separate spin-ups to discover all three blockers. The rewrite collects every guard result before reporting: the skill still halts on any BLOCKED row, but it halts knowing all of them, reducing a multi-blocker session to one round trip.

The worktree env-parity check addresses a specific two-incident failure pattern. A linked worktree created with `git worktree add` does not carry gitignored files from the main checkout, so every worktree starts without `.env*` files. The check fires only when `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir` (i.e. the current directory is a linked worktree). It compares `.env*` files in the main checkout against those in the worktree and lists any that are missing, together with the exact `cp` command to fix each one. No file is ever copied automatically because env files hold secrets.

The browser probe in Step 2.5 checks whether `preview_start` is reachable before running the preview block. When it is not, the skill writes `UNVERIFIED — no browser` to session output and passes that string to any calling skill. `pr-agent/SKILL.md` Step 5 carries a new rule: when the invoking skill reports the string, it is copied verbatim into the Test Plan section of the PR body. This follows the convention established in `wcag-compliance-reviewer` 1.5.2 — write an honest marker rather than silently omit the claim.

The `external-blocker` class in `ci-autofix.md` solves a specific failure loop: an expired `CLAUDE_CODE_OAUTH_TOKEN` or a billing-blocked workflow produces no test output and no fixable code, but the old table sent it to the "ask the user" row, which then burned autofix attempts. The new class matches by log signatures (`billing`, `quota`, `Bad credentials`, `refusing to allow`, token-expiry text) or by the empty-log condition (all jobs failed within seconds with no `--log-failed` output). Duration was tested as a discriminator on 300 real runs and found non-discriminating; the empty log is load-bearing and duration is corroboration only. The attempt cap does not advance for this class.

`tests/plugins/test-ship-preflight.sh` asserts eight specific text contracts: both pre-flight surfaces describe a single combined report, both carry the `--git-common-dir`-gated env check, the browser probe names `UNVERIFIED — no browser`, `pr-agent`'s Step 5 template carries the marker line, every `AskUserQuestion` names a headless default, and `ci-autofix.md` lists `external-blocker` above `lint` with the cap-advance statement.

## How to use it

No configuration changes required. After updating git-agent, `ship` and `ship-autonomous` pre-flights collect all blockers before reporting. When working from a linked worktree, the pre-flight reports missing `.env*` files with the copy command to fix them.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
