---
status: completed
type: feature
created: 2026-07-16
workflow: false
effort: medium
glance: The feature-request-to-PR pipeline exists but is scattered across skills you invoke by hand in the right order. This adds one command for the front half — plan and implement — then hands off to ship-autonomous, which already owns verification, the PR, and the merge gate. We'll know it worked when a single invocation carries an objective to a PR waiting on your approval.
---

# Plan: One command from feature request to a green PR — then hand back the keys

## Objective

Add a `/git-agent:autonomous-pr` command that chains plan authoring and
implementation, then hands off to `ship-autonomous` — which verifies, opens
the PR, watches CI, and gates the merge on the user's approval.

## Context

The autonomous pipeline is ~85% built already and spread across skills that
each work well alone:

- `plan-agent:implementation-plan` — authors the plan
- `code-testing-agent:tdd-loop` — implements against tests
- `git-agent:ship-autonomous` — branch, commit, PR, CI subscribe/poll,
  bounded autofix (3 attempts per check), review-comment handling

What's missing is the seam between them. A user wanting the full flow has to
invoke five skills by hand and remember the order. Two beats are genuinely
absent: **browser verification** before the PR opens, and an explicit
**stop-at-green handoff**.

**Scope discipline — this is one command file, not a plugin.** The command
orchestrates skills that already exist. Every temptation to reimplement CI
polling, autofix classification, or commit-message generation inside this
command is a temptation to duplicate `ship-autonomous`. Resist it; invoke it.

**The stop-at-green boundary is the point, not a limitation.** Merging to
`main` is irreversible and branch deletion is destructive — both require
explicit approval under the global git-safety rule ("'Merge it' does NOT
authorize `--delete-branch`"). The user chose stop-at-green deliberately.

One correction to the original request: it asked for verification "via
preview_eval", but no such tool exists. The real mechanism is the Browser pane
— `preview_start`, then `read_console_messages` / `read_page` / a screenshot.

### Scope revision — PR #413 landed mid-implementation

Both "missing beats" above were filled on `main` by
[#413](https://github.com/shawn-sandy/agentics/pull/413) (`git-agent` 4.1.0)
while this plan was being implemented, and filled better:

- **Browser verification** → `ship-autonomous` **Step 2.5** runs the project's
  tests, previews via `.claude/launch.json`, blocks on console/server errors,
  and screenshots light *and* dark themes.
- **Stop-at-green** → `ship-autonomous` **Step 8** re-confirms green,
  re-fetches the live review decision and unresolved-thread count, gates the
  merge behind `AskUserQuestion`, pins `--match-head-commit`, and requires a
  separate approval for branch deletion.

The user's stated requirement is therefore already satisfied by
`ship-autonomous` alone. What remains unique to this command is the **front
half**: chaining `implementation-plan` → `tdd-loop` ahead of the ship, plus
`create-issue` for out-of-scope findings.

Steps 1–3 below were revised accordingly: the command's own browser-verify
phase and its never-merge prohibition were **deleted**, not kept — a second
verification phase would be a worse copy of Step 2.5, and a hard never-merge
rule would contradict Step 8, leaving two files disagreeing about who owns the
merge decision. The version bump moved 4.1.0 → **4.2.0**, since #413 took 4.1.0.

## Files

- `kit/plugins/git-agent/commands/autonomous-pr.md` (new) — the command; ~50 lines of orchestration
- `tests/plugins/test-autonomous-pr.sh` (new) — smoke test pinning the no-duplication and no-merge boundaries
- `.claude-plugin/marketplace.json` (modified) — git-agent 4.1.0 → 4.2.0
- `kit/plugins/git-agent/CHANGELOG.md` (modified) — v4.2.0 entry
- `kit/plugins/git-agent/README.md` (modified) — document the new command
- `CLAUDE.md` (modified) — extend the git-agent row in the plugin table

## Steps

1. [x] Write `kit/plugins/git-agent/commands/autonomous-pr.md` with frontmatter (`description`, one sentence) and a numbered body covering the six phases: plan via `plan-agent:implementation-plan`, implement via `code-testing-agent:tdd-loop` where testable, browser-verify, ship via `git-agent:ship-autonomous`, file out-of-scope findings via `git-agent:create-issue`, then stop. Each phase invokes an existing skill by name — no reimplemented logic. Why: the whole value is the seam between skills that already work; anything reimplemented here becomes a second copy to maintain and drift. Verify: `wc -l < kit/plugins/git-agent/commands/autonomous-pr.md` is under 80, and `grep -c 'ship-autonomous\|implementation-plan\|tdd-loop\|create-issue'` returns 4 or more.
2. [x] **Revised after #413 — phase deleted rather than written.** The command has no browser-verification phase; `ship-autonomous` Step 2.5 owns verification and does it more thoroughly (tests, console/server errors blocking, both themes). Why: a second verification phase would be a strictly worse copy that drifts from the one that matters — the laziest correct move was to delete the phase, not write it. Verify: `grep -q 'preview_start' kit/plugins/git-agent/commands/autonomous-pr.md` finds nothing, and the test's check 6 fails if it ever reappears.
3. [x] **Revised after #413 — prohibition delegated, not written.** The command hands the merge decision to `ship-autonomous` Step 8, which already gates it behind `AskUserQuestion`. The command states only that it never merges *itself* and must not front-run or answer Step 8's prompt. Why: a hard never-merge rule here would contradict Step 8, leaving two files disagreeing about who owns the merge — worse than either answer alone. The bot-loop note also moved to #413's own closing policy. Verify: the command file contains no `gh pr merge` and no `--delete-branch` (test checks 7 and 8), while Step 8 remains the single merge gate.
4. [x] Bump `git-agent` to **`4.2.0`** in `.claude-plugin/marketplace.json` (MINOR — new command), and add no `version` key to `plugin.json`. Why: a new command is a MINOR bump, and #413 already took 4.1.0 on main — the original 4.0.1 → 4.1.0 bump would have collided rather than superseded. For relative-path plugins a `version` in `plugin.json` silently overrides the marketplace value. Verify: the marketplace query prints `['4.2.0']`, higher than main's `4.1.0`, and `grep -c version kit/plugins/git-agent/.claude-plugin/plugin.json` returns 0.
5. [x] Write `tests/plugins/test-autonomous-pr.sh` following the existing shell-test pattern (`set -euo pipefail`, `ROOT=`, numbered checks, `FAILURES` counter, exit 1 on any failure). Eight checks: file exists; `description` frontmatter; invokes `implementation-plan`, `tdd-loop`, and `ship-autonomous`; contains no `preview_start` (verification is delegated); and contains no `gh pr merge` or `--delete-branch`. Why: checks 1–5 catch a broken file, but 6–8 have teeth — they pin the two boundaries this design rests on, that the command doesn't duplicate Step 2.5's verification and doesn't reach around Step 8's merge gate. Verify: `bash tests/plugins/test-autonomous-pr.sh` exits 0; appending a real `gh pr merge --squash --delete-branch` makes it exit 1 (confirmed against the pre-trim version — checks 4 and 5 both fired).
6. [x] Update the three docs surfaces: a `v4.1.0` entry in `kit/plugins/git-agent/CHANGELOG.md` matching the existing heading format, the command documented in `kit/plugins/git-agent/README.md`, and the git-agent row in the root `CLAUDE.md` plugin table extended to name `autonomous-pr` and its stop-at-green behavior. Why: the CLAUDE.md table is how this command gets discovered in future sessions — an undocumented command is one nobody invokes. Verify: `grep -q 'autonomous-pr' CLAUDE.md kit/plugins/git-agent/README.md kit/plugins/git-agent/CHANGELOG.md` succeeds for all three.

## Tests

Tier 2 — This plan doesn't change application code
- Objective: proves the command file exists, is well-formed, and cannot merge or delete a branch. File: `tests/plugins/test-autonomous-pr.sh`; Type: smoke; Asserts: the command file parses with a `description` in frontmatter, references `ship-autonomous` rather than reimplementing it, and contains no `gh pr merge` or `--delete-branch` — pinning the stop-at-green boundary the user chose; Run: `bash tests/plugins/test-autonomous-pr.sh`

## Acceptance Criteria

- [x] `/git-agent:autonomous-pr` is invocable and its body chains plan → implement → hand off to ship-autonomous → file out-of-scope issues
- [x] The command file contains no `gh pr merge`, no `--delete-branch`, and no `preview_start`
- [x] The command has no browser-verification phase of its own — `ship-autonomous` Step 2.5 owns it (test check 6)
- [x] The command invokes `git-agent:ship-autonomous` rather than reimplementing CI polling or autofix
- [x] The merge gate is `ship-autonomous` Step 8; the command never merges itself and must not front-run or answer that prompt
- [x] Bot-loop restraint is inherited from `ship-autonomous`'s own closing policy (added by #413) rather than restated here
- [x] `git-agent` is `4.2.0` in `marketplace.json` — higher than main's `4.1.0` — and `plugin.json` has no `version` key
- [x] `bash tests/plugins/test-autonomous-pr.sh` exits 0
- [x] The command is documented in the git-agent README, CHANGELOG, and the root CLAUDE.md plugin table
- [x] No new plugin, skill, or agent was created — the diff adds exactly two new source files (`commands/autonomous-pr.md` and `tests/plugins/test-autonomous-pr.sh`), plus the plan pair this repo commits alongside every plugin change

## Verification

Walk it as a user would, on a throwaway feature request in this repo:

1. Invoke `/git-agent:autonomous-pr <small objective>` and confirm it authors a
   plan, implements it, and opens a PR without asking you to invoke any other
   skill by hand.
2. Confirm the browser-verification phase is skipped for a non-previewable
   change (a markdown-only edit) and runs for a previewable one (a `docs/` HTML
   change) — the gate works in both directions, not just the skip direction.
3. Let CI run to green and confirm the flow **stops** — it posts the PR URL and
   asks whether to merge. Nothing is merged, no branch is deleted, and the
   branch still exists on the remote.
4. Answer "keep iterating" and confirm it returns to watching rather than
   exiting or merging.
5. Run `bash tests/plugins/test-autonomous-pr.sh` — exits 0. Then append
   `gh pr merge --squash` to the command file and re-run: it must exit 1. Revert.
6. Confirm `git diff --stat` shows exactly two new files and four modified ones
   — no new plugin directory, no new skill, no new agent.

## Next Steps

- Wire the new smoke test into PR CI
  `tests/plugins/` scripts aren't run by any workflow today — there's an existing plan (`docs/plans/wire-plugin-tests-into-ci.html`, PR #408/#411) covering exactly this. The new test inherits whatever that lands, so nothing to do here beyond confirming it gets picked up.
  ```text
  Read docs/plans/wire-plugin-tests-into-ci.html and confirm that the CI wiring it describes will pick up tests/plugins/test-autonomous-pr.sh automatically (e.g. via a glob over tests/plugins/*.sh) rather than needing the new test added to an explicit list. If it needs an explicit entry, add it and open a PR.
  ```

- Let the user opt into auto-merge per invocation
  Wish list. A `--merge-when-green` flag would let the user pre-authorize the merge for a single invocation, keeping stop-at-green as the default. Needs care: the global git-safety rule requires explicit approval, so the flag itself would have to count as that approval — a question worth settling before building.
  ```text
  The /git-agent:autonomous-pr command currently always stops at CI-green and asks the user before merging. Evaluate adding an opt-in --merge-when-green flag that pre-authorizes the squash-merge for that single invocation. Before implementing, settle the governance question: does passing the flag constitute the "explicit user approval" that ~/.claude/CLAUDE.md's git-safety rule requires for merges, or does that rule demand approval at the moment of merge regardless? Recommend one answer with reasoning. If the flag is justified, implement it — but keep --delete-branch out of scope entirely, since the same rule names branch deletion separately.
  ```

- Extend the chain to GitLab
  Wish list. `ship-autonomous` is `gh`-only; `create-issue` already detects host from the git remote. A GitLab path would need `glab` equivalents for CI polling and PR events.
  ```text
  The git-agent plugin's ship-autonomous skill and the new autonomous-pr command are GitHub-only (they shell out to `gh`). The create-issue skill already auto-detects GitHub vs GitLab from the git remote. Assess what it would take to give ship-autonomous a GitLab path using `glab`: identify each `gh` call, name the `glab` equivalent, and flag anything with no equivalent (notably PR-activity subscription, which appears GitHub-MCP-specific). Report the gaps before writing code.
  ```

## Resources

- `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` — the skill this command delegates its entire ship phase to; read it before touching the command's phase 4, since anything you're tempted to write there probably already exists in its Steps 5–7.
- `~/.claude/rules/review-bot-loops.md` — why the flow must not treat every re-fired bot review as binding; documents a real 12-round loop that cost an order of magnitude more than the work under review.
- `tests/plugins/test-step8-review-option.sh` — the shell-test pattern the new test follows (ROOT resolution, numbered checks, FAILURES counter).
