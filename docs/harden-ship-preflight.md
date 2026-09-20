# Harden ship pre-flight against environment blockers

> Ship pre-flight stops at the first failing guard, so a session with three blockers costs three full spin-ups — and it never checks the one that has caused tw...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Rewrite `references/preflight-and-verify.md` Step 1 so every guard runs before anything is reported: clean tree, uncommitted plan files, detached HEAD, `gh auth status`, and the two new checks below, collected into one PASS/FAIL/BLOCKED table with a verbatim remediation command per failing row. Keep every existing halt condition — the skill still stops on any BLOCKED row, it just stops knowing all of them.
- Add the worktree env-parity check to that table: skip unless `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`, then compare the `.env*` files present in the main checkout against those in this worktree and report any that are missing, with the exact `cp` command per file. Never copy.
- Add the browser-availability probe to Step 2.5: before the preview block, establish whether `preview_start` is reachable. When it is not, skip the browser steps, state `UNVERIFIED — no browser` in the session output, and carry that string forward as the verification result the PR body must report.
- Add one line to `skills/pr-agent/SKILL.md` Step 5's body template: when the invoking skill reports a verification marker, the Test Plan section carries it verbatim; when it reports none, the section is unchanged.
- Give each pre-flight `AskUserQuestion` a named headless default and say so in one line, matching `plan-agent` `build`'s wording — the uncommitted-plan-files gate defaults to `abort`.
- Apply the run-all-then-report contract and the env-parity check to `skills/ship/SKILL.md` Step 1, which carries its own copy of the guards rather than sharing the reference file.
- Add an `external-blocker` row to the `references/ci-autofix.md` classification table, ordered above the autofixable classes: signatures `billing`, `quota`, `spending limit`, `Bad credentials`, `refusing to allow`, token-expiry text, or every job failing with no test output. Its action is to report the failure verbatim as an external blocker, with no autofix and no increment of the three-attempt cap.
- Document the empty-log detection for the billing case, where no signature string exists to match: `gh run view <id> --json jobs` and treat all-jobs-failed with sub-minute durations and empty `--log-failed` output as `external-blocker`.
- Add `tests/plugins/test-ship-preflight.sh` asserting: both pre-flight surfaces describe a single combined report, both carry the env-parity check gated on `--git-common-dir`, the browser probe names `UNVERIFIED — no browser`, `pr-agent`'s Step 5 body template carries the marker line, every `AskUserQuestion` in the pre-flight path has a named headless default, and `ci-autofix.md` lists `external-blocker` ahead of `lint`.
- Bump git-agent to 4.17.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and document the pre-flight table, the env check, and the external-blocker class in the README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md` | run-all-then-report, env parity, browser probe, headless defaults | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | same run-all-then-report contract and env-parity check in its own Step 1 | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | ship's own copy of the table format and guard commands; the core carries the guard statements but is capped at 600 words by tests/plugins/test-skill-split-git-social.sh, and a skill can only bundle files under its own directory | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Step 5's body template carries the `UNVERIFIED — no browser` line when the caller reports it | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md` | `external-blocker` class, placed first in the table | Modified |
| `kit/plugins/git-agent/README.md` | document the pre-flight table, the env check, and the external-blocker class | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.17.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.16.1 to 4.17.0 | Modified |
| `tests/plugins/test-ship-preflight.sh` | content assertions over both pre-flight surfaces and the CI table | Created |

## How it works

Make `ship` and `ship-autonomous` pre-flight run every guard before reporting, add worktree env-parity and browser-availability checks, give each pre-flight prompt a named headless default, and add an `external-blocker` class to CI triage so an expired token or billing block is never autofixed as a code defect.

The 2026-08-14 usage report attributes roughly a quarter of all `not_achieved` sessions to pre-flight: *"Five-plus ship-autonomous invocations halted at Step 1 on failed `gh auth`, so nothing was committed or PR'd and the sessions were a total loss."* The report treats the halts as correct behaviour, and they are — the guards did their job. What is wrong is the cost of learning about them.

The implementation proceeded through the following steps: Rewrite `references/preflight-and-verify.md` Step 1 so every guard runs before anything is reported: clean tree, uncommitted plan files, detached HEAD, `gh auth status`, and the two new checks below, collected into one PASS/FAIL/BLOCKED table with a verbatim remediation command per failing row. Keep every existing halt condition — the skill still stops on any BLOCKED row, it just stops knowing all of them. Why: the guards are already correct and the report treats their halts as acceptable outcomes; the cost being paid is one session spin-up per blocker, and that is entirely in the ordering. Verify: a repo with both an unauthenticated `gh` and a dirty tree produces one table naming both, and the skill mutates nothing.; Add the worktree env-parity check to that table: skip unless `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`, then compare the `.env*` files present in the main checkout against those in this worktree and report any that are missing, with the exact `cp` command per file. Never copy. Why: this is the blocker with two recorded phantom bugs behind it, and it presents as a code defect in the last file edited, which is the most expensive way to learn about it — but the file holds secrets, so detection is the deliverable and copying stays the user's action. Verify: in a linked worktree whose main checkout has a `.env` the worktree lacks, the row reads BLOCKED and quotes the `cp` command; in a non-worktree checkout the row is absent entirely.; Add the browser-availability probe to Step 2.5: before the preview block, establish whether `preview_start` is reachable. When it is not, skip the browser steps, state `UNVERIFIED — no browser` in the session output, and carry that string forward as the verification result the PR body must report. Why: a silently skipped verification step produces a PR that reads as verified, which is the failure mode the report describes, and this repo already chose the honest-marker convention in `wcag-compliance-reviewer` 1.5.2. Verify: with the browser MCP unavailable, the skill states `UNVERIFIED — no browser` and continues to commit; with it available, the phrase is absent and the preview checks run.; Add one line to `skills/pr-agent/SKILL.md` Step 5's body template: when the invoking skill reports a verification marker, the Test Plan section carries it verbatim; when it reports none, the section is unchanged. Why: Step 3 can only produce the string — `pr-agent` is what writes the PR body, so without this line the marker never reaches the surface where a reviewer would see it, and the acceptance criterion would be unmeetable from inside this plan's scope. Verify: a `ship-autonomous` run with no browser produces a PR whose Test Plan section contains `UNVERIFIED — no browser`; a `pr-agent` invocation with no marker reported produces the existing template unchanged.; Give each pre-flight `AskUserQuestion` a named headless default and say so in one line, matching `plan-agent` `build`'s wording — the uncommitted-plan-files gate defaults to `abort`. Why: under `claude -p` the tool is unavailable, and an unstated fallback means the skill improvises at exactly the gate that exists to stop it. Verify: the file names a default for every `AskUserQuestion` it raises, and the plan-files gate's default is `abort`.; Apply the run-all-then-report contract and the env-parity check to `skills/ship/SKILL.md` Step 1, which carries its own copy of the guards rather than sharing the reference file. Why: `ship` is the entry point used when the user does not want CI watching, so leaving it on first-failure semantics means the fix only lands for half the callers. Verify: both files describe one report containing every blocker, and neither says "stop on the first failure"..

- Acceptance criterion 4, first clause ("a `ship-autonomous` run with no browser produces a PR whose Test Plan section contains `UNVERIFIED — no browser`") — **verified as a text contract at its point of use, not by an executed no-browser run.** A browser MCP is present in the implementing session, so the

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
