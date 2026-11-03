# Harden ship pre-flight against environment blockers

> Makes `ship` and `ship-autonomous` pre-flight run every guard before reporting, adds worktree env-parity and browser-availability checks, gives each pre-flight prompt a headless default, and adds an `external-blocker` CI class so expired credentials and billing blocks are never autofixed as code defects.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [harden-ship-preflight](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrote `ship-autonomous/references/preflight-and-verify.md` and `ship/SKILL.md` Step 1 to run every guard before reporting, collecting all blockers into one PASS/FAIL/BLOCKED table with a verbatim remediation command per row
- Added worktree env-parity check: when the checkout is a linked worktree, compares `.env*` files in the main checkout against those in the worktree and reports any missing ones with the exact `cp` command — never copies automatically
- Added browser-availability probe to Step 2.5: when `preview_start` is unreachable, states `UNVERIFIED — no browser` in session output and carries the marker forward to the PR body via `pr-agent`
- Added headless defaults to every `AskUserQuestion` in the pre-flight path; uncommitted-plan-files gate defaults to `abort`
- Added `external-blocker` CI class to `ci-autofix.md` (billing, quota, spending limit, bad credentials, token expiry, all-jobs-failed-with-empty-log): reported verbatim with no autofix and no increment of the three-attempt cap
- Created `tests/plugins/test-ship-preflight.sh` asserting all new contracts across all four changed files
- Bumped git-agent to 4.17.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Reference — run-all-then-report, env parity, browser probe | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill — run-all-then-report, env parity | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Reference — ship guard commands | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill — UNVERIFIED marker in body template | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | Reference — external-blocker class | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — git-agent 4.17.0 | Modified |
| `tests/plugins/test-ship-preflight.sh` | Smoke test | Created |

## How it works

The 2026-08-14 usage report attributed roughly a quarter of all `not_achieved` sessions to pre-flight: five-plus `ship-autonomous` invocations halted at Step 1 on failed `gh auth`, so nothing was committed or PR'd and the sessions were a total loss. The guards were correct; the cost was three separate spin-ups to learn about three simultaneous blockers.

Running all guards first and collecting results into one table collapses that to one spin-up. Nothing about the halt itself changes — any BLOCKED row still stops the skill.

The worktree env-parity check addresses two recorded phantom bugs: a Clerk sign-in regression and a missing nav button, both root-caused to a linked worktree missing its `.env` after `git worktree add`. Detection is two commands; the file is never copied automatically because it holds secrets.

Browser verification was previously silently skipped when the MCP was absent, leaving PR bodies that read as verified. The probe adopts the `UNVERIFIED — no browser` convention established in `wcag-compliance-reviewer` 1.5.2. The marker travels from the session output into `pr-agent`'s Step 5 body template so a reviewer sees it in the PR.

The `external-blocker` CI class addresses recurring sessions spent autofixing correct code against an expired `CLAUDE_CODE_OAUTH_TOKEN` or a billing block. The observable signature — all jobs failing in seconds with empty `--log-failed` output — is stated explicitly alongside the string-based signatures. The attempt cap does not advance for external blockers.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight](plans/harden-ship-preflight.md)
