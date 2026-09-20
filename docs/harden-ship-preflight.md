# Harden ship pre-flight against environment blockers

> Ship pre-flight stops at the first failing guard, so a session with three blockers costs three full spin-ups — and it never checks the one that has caused tw...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrite `references/preflight-and-verify.md` Step 1 so every guard runs before anything is reported: clean tree, unco...
- Add the worktree env-parity check to that table: skip unless `git rev-parse --git-dir` differs from `git rev-parse --...
- Add the browser-availability probe to Step 2.5: before the preview block, establish whether `preview_start` is reacha...
- Add one line to `skills/pr-agent/SKILL.md` Step 5's body template: when the invoking skill reports a verification mar...
- Give each pre-flight `AskUserQuestion` a named headless default and say so in one line, matching `plan-agent` `build`...
- Apply the run-all-then-report contract and the env-parity check to `skills/ship/SKILL.md` Step 1, which carries its o...
- Add an `external-blocker` row to the `references/ci-autofix.md` classification table, ordered above the autofixable c...
- Document the empty-log detection for the billing case, where no signature string exists to match: `gh run view <id> -...
- Add `tests/plugins/test-ship-preflight.sh` asserting: both pre-flight surfaces describe a single combined report, bot...
- Bump git-agent to 4.17.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and document the pre-flight t...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | run-all-then-report, env parity, browser probe, headless ... | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | same run-all-then-report contract and env-parity check in... | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | ship's own copy of the table format and guard commands; t... | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Step 5's body template carries the `UNVERIFIED — no brows... | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | `external-blocker` class, placed first in the table | Modified |
| `kit/plugins/git-agent/README.md` | document the pre-flight table, the env check, and the ext... | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.17.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.16.1 to 4.17.0 | Modified |
| `tests/plugins/test-ship-preflight.sh` | content assertions over both pre-flight surfaces and the ... | Created |

## How it works

Make `ship` and `ship-autonomous` pre-flight run every guard before reporting, add worktree env-parity and browser-availability checks, give each pre-flight prompt a named headless default, and add an `external-blocker` class to CI triage so an expired token or billing block is never autofixed as a code defect.

The 2026-08-14 usage report attributes roughly a quarter of all `not_achieved` sessions to pre-flight: *"Five-plus ship-autonomous invocations halted at Step 1 on failed `gh auth`, so nothing was committed or PR'd and the sessions were a total loss."* The report treats the halts as correct behaviour, and they are —

The implementation proceeded through these steps: Rewrite `references/preflight-and-verify.md` Step 1 so every guard runs before anything is reported: clean tree, unco...; Add the worktree env-parity check to that table: skip unless `git rev-parse --git-dir` differs from `git rev-parse --...; Add the browser-availability probe to Step 2.5: before the preview block, establish whether `preview_start` is reacha...; Add one line to `skills/pr-agent/SKILL.md` Step 5's body template: when the invoking skill reports a verification mar...; Give each pre-flight `AskUserQuestion` a named headless default and say so in one line, matching `plan-agent` `build`....

- Acceptance criterion 4, first clause ("a `ship-autonomous` run with no browser produces a PR whose Test Plan section contains `UNVERIFIED — no browser`") — **verified as a text contract at its point of use, not by an executed

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
