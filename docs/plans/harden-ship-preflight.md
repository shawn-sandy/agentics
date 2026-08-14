---
status: todo
type: fix
created: 2026-08-14
glance: Ship pre-flight stops at the first failing guard, so a session with three blockers costs three full spin-ups — and it never checks the one that has caused two phantom bugs, a linked worktree missing its .env. This makes pre-flight report every blocker at once, adds the env-parity and browser-availability checks, names a headless default for each prompt, and teaches CI triage that a billing block is not a code defect.
effort: medium
workflow: never
---

# Plan: Harden ship pre-flight against environment blockers

## Objective

Make `ship` and `ship-autonomous` pre-flight run every guard before reporting,
add worktree env-parity and browser-availability checks, give each pre-flight
prompt a named headless default, and add an `external-blocker` class to CI
triage so an expired token or billing block is never autofixed as a code
defect.

## Context

The 2026-08-14 usage report attributes roughly a quarter of all `not_achieved`
sessions to pre-flight: *"Five-plus ship-autonomous invocations halted at Step 1
on failed `gh auth`, so nothing was committed or PR'd and the sessions were a
total loss."* The report treats the halts as correct behaviour, and they are —
the guards did their job. What is wrong is the cost of learning about them.

**Pre-flight stops at the first failure.** `skills/ship/SKILL.md` Step 1 says
so explicitly, and the `ship-autonomous` reference is written the same way:
each check `STOP`s on its own. A session with an unauthenticated `gh`, a dirty
tree, and a missing worktree `.env` therefore costs three separate spin-ups —
fix one, re-invoke, discover the next. Running all guards and reporting one
table with every blocker and its remediation collapses that to one, and
changes nothing about the halt itself.

**Automatic re-auth is deliberately not added.** The report suggests teaching
the skill to attempt re-auth rather than report. The standing rule in this
user's `CLAUDE.md` is the opposite — *"Report blockers verbatim and stop; do
not attempt workarounds or guess at a re-auth"* — and re-auth is an interactive
browser flow that cannot succeed unattended anyway. The blocker stays a
blocker; only the round-trip count changes.

**A linked worktree missing its `.env` has caused two phantom bugs.** The
report records a Clerk sign-in regression root-caused to a missing worktree
`.env` rather than the CSS change that appeared to cause it, and notes the same
culprit behind an earlier phantom "missing nav button" bug. Gitignored env
files do not travel with `git worktree add`, so every worktree starts without
them and the failure presents as a code defect in whatever was edited last.
Detection is two commands; the file is never copied automatically, because it
holds secrets and a silent copy is the wrong default even when copying is the
right action.

**Browser verification degrades silently.** Step 2.5's browser block has no
availability probe, so when the MCP is absent in a headless or non-interactive
session the step is simply skipped — and the commit and PR body still read as
though the change was verified. The report names this directly: *"Browser MCP
were unavailable in non-interactive sessions, so ... visual verification
[was] silently downgraded to documented assumptions."* `wcag-compliance-reviewer`
already settled the convention in 1.5.2 — write `UNVERIFIED — no browser`
rather than omit the claim — and this adopts it.

**Pre-flight prompts have no headless default.** The uncommitted-plan-files
gate calls `AskUserQuestion` with three options and no stated fallback, so
under `claude -p` it stalls or improvises. `plan-agent` already solved this in
`build`: *"Headless, take each gate's named default and log it."* The merge
gate needs no change — `agents/agent-merge.md` already states that Step 3's
`AskUserQuestion` does not apply and that anything not green is reported
instead.

**CI triage has no non-defect class.** `references/ci-autofix.md` classifies
`lint`, `typecheck`, `peer-deps`, and *ask the user*. Nothing represents a
failure that is not the code's fault, so an expired `CLAUDE_CODE_OAUTH_TOKEN`
or a billing block burns autofix attempts against correct code. The report
names the token as recurring friction, and the same rule is already written
into `plan-agent`'s red-green-verify guidance: *"A failing GitHub Actions check
is not a code defect until proven one."* git-agent is the plugin that acts on
CI failures and is the one place it is missing.

**Scope.** Reference-file and skill-body edits plus a content test. No hooks,
no scripts, no behaviour that runs outside a skill invocation.

## Files

- kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md (modified) — run-all-then-report, env parity, browser probe, headless defaults
- kit/plugins/git-agent/skills/ship/SKILL.md (modified) — same run-all-then-report contract and env-parity check in its own Step 1
- kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md (modified) — `external-blocker` class, placed first in the table
- kit/plugins/git-agent/README.md (modified) — document the pre-flight table, the env check, and the external-blocker class
- kit/plugins/git-agent/CHANGELOG.md (modified) — 4.17.0 entry
- .claude-plugin/marketplace.json (modified) — git-agent 4.16.1 to 4.17.0
- tests/plugins/test-ship-preflight.sh (new) — content assertions over both pre-flight surfaces and the CI table

## Steps

1. Rewrite `references/preflight-and-verify.md` Step 1 so every guard runs before anything is reported: clean tree, uncommitted plan files, detached HEAD, `gh auth status`, and the two new checks below, collected into one PASS/FAIL/BLOCKED table with a verbatim remediation command per failing row. Keep every existing halt condition — the skill still stops on any BLOCKED row, it just stops knowing all of them. Why: the guards are already correct and the report treats their halts as acceptable outcomes; the cost being paid is one session spin-up per blocker, and that is entirely in the ordering. Verify: a repo with both an unauthenticated `gh` and a dirty tree produces one table naming both, and the skill mutates nothing.
2. Add the worktree env-parity check to that table: skip unless `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`, then compare the `.env*` files present in the main checkout against those in this worktree and report any that are missing, with the exact `cp` command per file. Never copy. Why: this is the blocker with two recorded phantom bugs behind it, and it presents as a code defect in the last file edited, which is the most expensive way to learn about it — but the file holds secrets, so detection is the deliverable and copying stays the user's action. Verify: in a linked worktree whose main checkout has a `.env` the worktree lacks, the row reads BLOCKED and quotes the `cp` command; in a non-worktree checkout the row is absent entirely.
3. Add the browser-availability probe to Step 2.5: before the preview block, establish whether `preview_start` is reachable. When it is not, skip the browser steps and record `UNVERIFIED — no browser` as a line the commit body and PR body must carry. Why: a silently skipped verification step produces a PR that reads as verified, which is the failure mode the report describes, and this repo already chose the honest-marker convention in `wcag-compliance-reviewer` 1.5.2. Verify: with the browser MCP unavailable, the skill states `UNVERIFIED — no browser`, continues to commit, and the phrase appears in the commit body; with it available, the phrase is absent and the preview checks run.
4. Give each pre-flight `AskUserQuestion` a named headless default and say so in one line, matching `plan-agent` `build`'s wording — the uncommitted-plan-files gate defaults to `abort`. Why: under `claude -p` the tool is unavailable, and an unstated fallback means the skill improvises at exactly the gate that exists to stop it. Verify: the file names a default for every `AskUserQuestion` it raises, and the plan-files gate's default is `abort`.
5. Apply the run-all-then-report contract and the env-parity check to `skills/ship/SKILL.md` Step 1, which carries its own copy of the guards rather than sharing the reference file. Why: `ship` is the entry point used when the user does not want CI watching, so leaving it on first-failure semantics means the fix only lands for half the callers. Verify: both files describe one report containing every blocker, and neither says "stop on the first failure".
6. Add an `external-blocker` row to the `references/ci-autofix.md` classification table, ordered above the autofixable classes: signatures `billing`, `quota`, `spending limit`, `Bad credentials`, `refusing to allow`, token-expiry text, or every job failing with no test output. Its action is to report the failure verbatim as an external blocker, with no autofix and no increment of the three-attempt cap. Why: an infrastructure failure fixed as a code defect changes correct code and re-fires CI for another round, and this repo already applies the rule inside `plan-agent`'s planning guidance while the plugin that acts on CI lacks it. Verify: the table's first data row is `external-blocker`, and the file states that the attempt cap does not advance for it.
7. Document the empty-log detection for the billing case, where no signature string exists to match: `gh run view <id> --json jobs` and treat all-jobs-failed with sub-minute durations and empty `--log-failed` output as `external-blocker`. Why: a quota block produces no log text at all, so a signature-only table would classify the most common instance as "anything else" and send it to the user as an unknown. Verify: the file carries the `gh run view --json jobs` command and states the all-failed-fast-and-empty condition.
8. Add `tests/plugins/test-ship-preflight.sh` asserting: both pre-flight surfaces describe a single combined report, both carry the env-parity check gated on `--git-common-dir`, the browser probe names `UNVERIFIED — no browser`, every `AskUserQuestion` in the pre-flight path has a named headless default, and `ci-autofix.md` lists `external-blocker` ahead of `lint`. Why: these are text contracts across three files that drift independently, and this repo's other cross-file skill invariants are held the same way. Verify: `bash tests/plugins/test-ship-preflight.sh` reports zero failures, and removing any one clause from any of the three files turns exactly one check red.
9. Bump git-agent to 4.17.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and document the pre-flight table, the env check, and the external-blocker class in the README. Why: the CI guard fails any PR whose touched plugin does not exceed the base branch version, and the env check is the kind of behaviour a user needs to read about before it blocks their ship. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 2 — This plan changes skill instructions and reference files, not application source

- Objective: pre-flight reports every blocker in one pass, including the worktree env gap, and CI triage refuses to autofix an infrastructure failure. File: tests/plugins/test-ship-preflight.sh; Type: smoke; Asserts: both pre-flight surfaces describe a single combined PASS/FAIL/BLOCKED report and carry the `--git-common-dir`-gated env check, the browser probe names `UNVERIFIED — no browser`, each pre-flight `AskUserQuestion` names a headless default, and `ci-autofix.md` lists `external-blocker` above `lint` and states the attempt cap does not advance for it; Run: bash tests/plugins/test-ship-preflight.sh

## Acceptance Criteria

- [ ] A pre-flight run with more than one blocker reports all of them in one table, each with its remediation command, and still halts.
- [ ] The pre-flight table includes a worktree env-parity row that is present only in a linked worktree and never copies a file.
- [ ] Step 2.5 probes browser availability and records `UNVERIFIED — no browser` in the commit and PR body when the browser is absent, rather than skipping silently.
- [ ] Every `AskUserQuestion` in the pre-flight path names its headless default, and the uncommitted-plan-files gate defaults to `abort`.
- [ ] `skills/ship/SKILL.md` Step 1 and `references/preflight-and-verify.md` describe the same run-all-then-report contract, and neither halts on the first failing guard.
- [ ] `ci-autofix.md` classifies expired credentials, billing and quota blocks, and all-jobs-failed-with-empty-logs as `external-blocker`, reported verbatim with no autofix.
- [ ] An `external-blocker` classification does not advance the three-attempt autofix cap.
- [ ] No automatic re-auth, stash, or env-file copy is introduced anywhere in this change.
- [ ] `bash tests/plugins/test-ship-preflight.sh` reports zero failures.
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Verification

Run `bash tests/plugins/test-ship-preflight.sh` and confirm zero failures, then
`git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` and
confirm exit 0. Run the full plugin suite and confirm no other git-agent test
regressed.

End-to-end, create a scratch repo outside this repository with a committed
`.gitignore` covering `.env`, a `.env` file at the main checkout, and a linked
worktree added via `git worktree add`. From the worktree, with an uncommitted
change present, invoke `ship` and confirm the run produces one report naming
the missing `.env` with its `cp` command, halts, and leaves the tree untouched
— then confirm that fixing only the env and re-invoking surfaces any remaining
blocker rather than a fresh single-blocker stop.

For the CI class, take a real failed run from a billing-blocked workflow —
`gh run list --json databaseId,conclusion` on a repo where one exists — and
confirm `gh run view <id> --log-failed` returns no test output while
`--json jobs` shows every job failed within seconds, which is the condition
Step 7 keys on. Record the observed durations in the CHANGELOG entry so the
threshold is measured rather than assumed.

## Next Steps

- Share one pre-flight definition between ship and ship-autonomous

  ```text
  In the agentics repo, kit/plugins/git-agent/skills/ship/SKILL.md Step 1 and
  kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md
  each carry their own copy of the pre-flight guards, so every change has to
  land twice. Evaluate whether ship should reference the ship-autonomous
  reference file directly, whether the guards should move to a shared
  references/ file both skills point at, or whether the duplication is worth
  keeping because the two skills' guard sets legitimately differ. Note that a
  skill can only bundle files under its own directory. If you recommend
  consolidating, implement it, bump the git-agent version in
  .claude-plugin/marketplace.json, add a CHANGELOG entry, and keep
  tests/plugins/test-ship-preflight.sh green.
  ```

## Resources

- kit/plugins/git-agent/skills/ship-autonomous/references/preflight-and-verify.md — the guards being reordered
- kit/plugins/git-agent/skills/ship-autonomous/references/ci-autofix.md — the classification table gaining a class
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/red-green-verify.md — the billing-block rule already written for plans
- kit/plugins/wcag-compliance-reviewer/CHANGELOG.md v1.5.2 — the `UNVERIFIED — no browser` convention being adopted
- ~/.claude/usage-data/report-2026-08-14-071004.html — the pre-flight and token-expiry entries motivating this plan
