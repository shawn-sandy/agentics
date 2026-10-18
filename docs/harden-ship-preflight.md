# Harden ship pre-flight against environment blockers

> Fixes ship pre-flight to report every blocker at once, adds worktree env-parity and browser-availability checks, names headless defaults for each prompt, and classifies billing/quota failures as non-code external blockers.

<!-- generated:start -->

**Status:** Shipped 2026-08-14  **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Updated `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` — reordered Step 1 guards to run all checks before reporting (clean tree, uncommitted plan files, detached HEAD, `gh auth status`, env parity, browser availability), collecting results into one PASS/FAIL/BLOCKED table; added worktree env-parity check (gated on `--git-common-dir`); added browser-availability probe with `UNVERIFIED — no browser` marker; added named headless defaults for each `AskUserQuestion` call.
- Added `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` — a reference file carrying the guard command table so `ship/SKILL.md` stays under the 600-word test ceiling while sharing the same guard contract.
- Updated `kit/plugins/git-agent/skills/ship/SKILL.md` Step 1 — applied the run-all-then-report contract and the env-parity check.
- Updated `kit/plugins/git-agent/skills/pr-agent/SKILL.md` Step 5 — body template carries the `UNVERIFIED — no browser` marker when the invoking skill reports it.
- Updated `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` — added `external-blocker` as the first classification row, covering billing/quota blocks, token expiry, Bad credentials, and all-jobs-failed-with-empty-logs; the three-attempt cap does not advance for this class.
- Added `tests/plugins/test-ship-preflight.sh` — asserts the combined-report contract, env-parity check, browser marker, pr-agent template, headless defaults, and `external-blocker` table ordering.
- Updated `kit/plugins/git-agent/README.md`, `CHANGELOG.md`, and bumped to `4.17.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Pre-flight reference | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Guard command table | Created |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | CI classification table | Modified |
| `tests/plugins/test-ship-preflight.sh` | Pre-flight smoke test | Created |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

Pre-flight previously halted on the first failing guard, requiring one session spin-up per blocker. The fix runs every guard, collects results into a single PASS/FAIL/BLOCKED table with a remediation command per failing row, and only halts after all checks complete. Every existing halt condition is preserved — the skill still stops on any BLOCKED row; it just stops knowing all of them.

The worktree env-parity check detects when `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir` (indicating a linked worktree), then compares `.env*` files in the main checkout against those in the current worktree, reporting any that are missing with the exact `cp` command per file. The file is never copied automatically — detection is the deliverable, and copying a secrets file silently is the wrong default.

The browser-availability probe tries `preview_start` before the Step 2.5 preview block. When unavailable, it records `UNVERIFIED — no browser` in the session output and forwards that marker to `pr-agent`, which includes it verbatim in the PR body's Test Plan section. This follows the `wcag-compliance-reviewer` 1.5.2 convention: an honest marker beats a silently skipped claim.

The `external-blocker` CI classification catches the billing-quota pattern where every GitHub Actions job fails in under 5 seconds with no test output (or empty `--log-failed`). Rather than burning autofix attempts against correct code, the class reports the failure verbatim and does not advance the three-attempt cap.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
