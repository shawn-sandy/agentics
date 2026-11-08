# Harden ship pre-flight against environment blockers

> Make ship and ship-autonomous pre-flight run every guard before reporting, add worktree env-parity and browser-availability checks, give each pre-flight prompt a named headless default, and add an external-blocker class to CI triage.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrote `references/preflight-and-verify.md` Step 1 so all guards run before anything is reported — clean tree, uncommitted plan files, detached HEAD, `gh auth status`, env-parity, and browser probe all collected into one PASS/FAIL/BLOCKED table.
- Added a worktree env-parity check that compares `.env*` files in the main checkout against those in the linked worktree and reports missing files with exact `cp` commands, without copying (env files hold secrets).
- Added a browser-availability probe: when `preview_start` is unreachable, the skill states `UNVERIFIED — no browser` in session output and carries that string to the PR body's Test Plan section via `pr-agent/SKILL.md` Step 5.
- Gave every pre-flight `AskUserQuestion` a named headless default (uncommitted-plan-files gate defaults to `abort`), matching `plan-agent build`'s wording.
- Applied the same run-all-then-report contract to `skills/ship/SKILL.md` Step 1.
- Added an `external-blocker` row to `references/ci-autofix.md` ordered above autofixable classes, covering billing, quota, spending-limit signatures, and all-jobs-failed-with-empty-logs; the attempt cap does not advance for it.
- Shipped `tests/plugins/test-ship-preflight.sh` asserting all contracts.
- Bumped `git-agent` to `4.17.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry and README update.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | Pre-flight reference: run-all-then-report, env parity, browser probe, headless defaults | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill: same run-all-then-report contract and env-parity check | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Ship-specific guard commands reference (new, to stay within 600-word core limit) | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Step 5 body template carries `UNVERIFIED — no browser` marker line | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | `external-blocker` class, placed first in classification table | Modified |
| `tests/plugins/test-ship-preflight.sh` | Content-assertion test for all pre-flight contracts | Created |

## How it works

Pre-flight previously halted at the first failing guard, so a session with three blockers (unauthenticated `gh`, dirty tree, missing worktree `.env`) cost three separate spin-ups. The fix runs all guards and collects results into one PASS/FAIL/BLOCKED table per row with a remediation command. The halt still happens — only the reporting order changed.

Two new guards were added to the table. The worktree env-parity check runs only in a linked worktree (`git rev-parse --git-dir` differs from `--git-common-dir`), compares `.env*` files against the main checkout, and reports missing ones with the exact `cp` command. It never copies automatically because env files hold secrets. The browser-availability probe calls `preview_start` before the preview block; when it fails the skill sets `UNVERIFIED — no browser` and continues to commit, carrying that string forward to the PR body.

The `UNVERIFIED — no browser` marker arrives in a PR via `pr-agent/SKILL.md` Step 5's body template: when the invoking skill reports a verification marker, the Test Plan section carries it verbatim; otherwise the section is unchanged. This ensures the marker is visible to reviewers rather than lost in session scrollback.

Each pre-flight `AskUserQuestion` now names a headless default so the skill can run under `claude -p` without stalling. The uncommitted-plan-files gate defaults to `abort` — the safest choice — mirroring the pattern already established in `plan-agent build`.

`references/ci-autofix.md` gained an `external-blocker` class as the first row in the classification table. It matches billing, quota, spending-limit messages, Bad credentials, token-expiry strings, and the all-jobs-failed-with-empty-logs condition. The three-attempt autofix cap does not advance for this class, so an infrastructure failure that blocks all jobs never burns autofix attempts on correct code.

`tests/plugins/test-ship-preflight.sh` asserts the combined-report contract, the `--git-common-dir`-gated env check, the `UNVERIFIED — no browser` probe, the `pr-agent` marker line, every `AskUserQuestion` naming a default, and `ci-autofix.md` listing `external-blocker` above `lint`.

## How to use it

The changes are transparent to callers. `/git-agent:ship` and `/git-agent:ship-autonomous` both run the extended pre-flight automatically.

When a pre-flight run finds multiple blockers it now reports all of them in one table, each with its remediation command, then halts. Fix all reported blockers and re-invoke — a second run will not discover a third blocker that was hidden behind the first two.

When a worktree `.env` is missing, the table shows the exact `cp` command to run; the skill does not copy the file automatically.

When no browser MCP is available, the PR body's Test Plan section will contain `UNVERIFIED — no browser` rather than a silent omission.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |
| `4f72700` | 2026-08-27 | feat(git-agent): add a context guard to ship-autonomous (#608) |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `eab3545` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `9277c9f` | 2026-09-18 | feat(git-agent): commit and ship paths handle lint-gate blocks (4.21.0) (#635) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
