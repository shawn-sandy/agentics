---
type: task
intent: Add an implementation-only mode to the tdd-loop and tdd-fix skills so they leave work uncommitted and open no PR, letting build hand off to ship-autonomous without a guard STOP
techniques: Clarity/directness, XML context tags, CoT scaffolding, Output format
created: 2026-08-18
---

# Task: Tdd Implementation Mode

<context>
Repo: shawn-sandy/agentics, a Claude Code plugin marketplace. Plugin sources live
under `kit/plugins/<name>/`.

This is sub-feature 1 of the feature doc at `docs/features/composable-skill-chain.md`.
Read that doc first — it carries the grounded current-state findings this task
depends on.

**The problem.** `plan-agent`'s `build` skill implements a plan and deliberately
ends with a dirty working tree (`build/SKILL.md:93-98`). `git-agent`'s
`ship-autonomous` requires a dirty tree — its preflight treats a *clean* tree as
the BLOCKED case, "Nothing to ship — working tree is clean". Those two compose
today. `code-testing-agent` cannot sit between them, because both its skills
terminate the chain:

- `tdd-loop/SKILL.md:46` — STOPs on a dirty tree, which is exactly what `build` hands it
- `tdd-loop/SKILL.md:59` — STOPs on `main` / `master`
- `tdd-loop/SKILL.md:137` — Step 3 commits the tests via `commit-agent`
- `tdd-loop/SKILL.md:264` — Step 6 commits the implementation via `commit-agent`; line 272 states the branch ends with "exactly two feature commits"
- `tdd-loop/SKILL.md:277` — Step 7 opens its own PR
- `tdd-loop/SKILL.md:285` — "Do not chain this skill with `ship-autonomous` in the same session. Both access `gh pr checks` and may interleave state unpredictably."
- `tdd-fix/SKILL.md:89` — Step 7 commits via `commit-agent`
- `tdd-fix/SKILL.md:96` — Step 8 opens a PR via `pr-agent`

The commit steps are the blocker that outlasts the others: relax the guards and
skip the PR, and the tree is still clean, which `ship-autonomous` refuses.

**Files in scope.** `kit/plugins/code-testing-agent/skills/tdd-loop/SKILL.md`
(300 lines) and `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` (107
lines).

**Repo constraints.** Any edit under `kit/plugins/<name>/` requires a version
bump for that plugin in `.claude-plugin/marketplace.json` (`code-testing-agent`
is at 3.4.4) plus an entry in `kit/plugins/code-testing-agent/CHANGELOG.md`.
`version` belongs only in `marketplace.json` — never add it to a relative-path
`plugin.json`. Verify with
`git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`.
</context>

<thinking>
Work through this in order. The first step can invalidate the whole task, so it
comes before any text is written.

1. Read the commit and PR that introduced `tdd-loop/SKILL.md:285` and establish
   why the prohibition exists. If the reason is limited to `gh pr checks`
   contention, an implementation-only run never touches that command and the
   prohibition can be scoped to the default mode. If the reason is broader,
   **stop and report** — the approach is invalid and no amount of mode text
   fixes it.
2. Decide how the mode is selected and how it reaches both skills. The feature
   doc deliberately leaves this open; it is this plan's call. Whatever the
   selector, the default — mode not requested — must behave exactly as today.
3. Work out how one behaviour lands in two files without drifting. `tdd-loop`
   and `tdd-fix` both need identical guard and terminal-step handling, and the
   feature doc flags drift as a live risk.
4. Check: after a mode run, is `git status --porcelain` non-empty, and was no
   `test:`, `feat:`, or `fix:` commit created? If either fails, the chain still
   dead-ends and the work is not done.
</thinking>

Add an implementation-only mode to `tdd-loop` and `tdd-fix`. In that mode both
skills must tolerate a dirty working tree, make no commit, open no PR, and still
require a feature branch. Scope the `tdd-loop:285` chaining prohibition to the
default mode. Leave every default-mode behaviour byte-identical to today.

Treat the no-commit requirement as the load-bearing half. Relaxing the guards
and suppressing the PR without also suppressing the commits produces a mode that
looks correct and still breaks the chain.

<constraints>
- Do not write the chain-execution test — that is sub-feature 2, a separate plan
  that depends on this one.
- Do not modify `plan-agent` or `git-agent` skills. Every blocker is inside the
  two `code-testing-agent` files.
- Do not re-open `implementation-plan`'s plans-only constraint, add a
  `plan-then-handoff` mode to it, or build a wrapper orchestration command. All
  three are explicitly out of scope in the feature doc.
- Do not retire `tdd-loop` in favour of `tdd-fix`. Both ship today.
</constraints>

Success is measurable, not narrative. The plan is done when:

- After a mode run, `git status --porcelain` is non-empty and no `test:`/`feat:`/`fix:` commit was created
- Existing `code-testing-agent` suites pass unchanged when the mode is not requested
- The `main`/`master` STOP still fires in the new mode
- The line-285 prohibition remains in force for the default mode and says so in the source text

Output requirements:
- Format: edits to the two SKILL.md files, plus the `marketplace.json` version bump and CHANGELOG entry
- Length: the minimum text that closes the seam — these are instruction files, and every added line is one more thing for the model reading them to reconcile
- Tone: imperative and specific, matching the existing SKILL.md voice
