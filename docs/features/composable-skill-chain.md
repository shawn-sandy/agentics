---
status: gathering
type: feature
created: 2026-08-18
repo-name: agentics
---

# Feature: Composable plan → test → ship skill chain

> This is a feature doc for the team, not an execution plan. The current-state
> findings below are grounded in the skill sources on `main` at `ec3abc2`; the
> direction (implementation-only mode) and the Tier 1 scope are decisions taken
> with the requester, not conclusions research forced.

## Context

Issue [#415](https://github.com/shawn-sandy/agentics/issues/415) recorded that
`plan-agent`, `code-testing-agent`, and `git-agent` skills cannot be chained,
after [PR #414](https://github.com/shawn-sandy/agentics/pull/414) attempted
`implementation-plan` → `tdd-loop` → `ship-autonomous` and was closed. The
issue closes with "No action required — this is a record, not a request."

**Three of the issue's four structural claims no longer hold.** The plugins
were restructured after it was filed:

| #415 claim | Status | Evidence |
|---|---|---|
| `implementation-plan` commits, leaving nothing to ship | Dead | `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md:170-185` — "This skill produces a plan document. It does not implement anything." Step 8 hands off to `build`, "which owns every source-file write". No `git commit` call site in the file. |
| The commit step is at `implementation-plan` line 479 | Stale reference | File is now 605 lines; line 479 is browser-verification setup. |
| `ship-autonomous` blocks on the clean tree planning leaves behind | Inverted | `build/SKILL.md:93-98` ends by design with a dirty tree: "leave the source changes, the updated spec, and the re-rendered HTML in the working tree. Commit only if the user asks." `ship-autonomous` preflight treats a *clean* tree as the BLOCKED case. |
| `tdd-loop` forbids chaining with `ship-autonomous` | Holds verbatim | `tdd-loop/SKILL.md:285` — "Do not chain this skill with `ship-autonomous` in the same session. Both access `gh pr checks` and may interleave state unpredictably." |

**What already composes.** `build` ends dirty and `ship-autonomous` requires
dirty, so those two now fit by construction. `ship-autonomous`'s preflight also
already carries an **Uncommitted plan files** gate
(`references/preflight-and-verify.md:53-70`) offering `include` / `stash` /
`abort`, with `abort` as the headless default — plan-aware shipping partly
landed already.

**What does not.** `code-testing-agent` in the middle position. Four blockers,
all in `tdd-loop/SKILL.md` unless noted:

- Line 46 — STOPs on a dirty tree, which is exactly what `build` hands it.
- Line 59 — STOPs on `main` / `master`.
- Lines 137 and 264 (and `tdd-fix/SKILL.md:89`) — commits via `commit-agent`.
  `tdd-loop` commits **twice**, tests then implementation; line 272 states the
  branch ends with "exactly two feature commits". This is the blocker that
  outlasts the others: relaxing the guards and skipping the PR still leaves a
  **clean** tree, which is precisely the state `ship-autonomous` refuses with
  "Nothing to ship".
- Line 277 (and `tdd-fix/SKILL.md:96`) — opens its own PR, making a downstream
  shipper redundant.
- Line 285 — the explicit prohibition above.

## Goals and success metrics

| Goal | Measurable signal |
|---|---|
| A single session can run `build` → tdd → `ship-autonomous` without a guard STOP | The chain-execution test (sub-feature 2) runs the three skills in sequence and reaches a PR URL, in CI, not by grep |
| The mode hands `ship-autonomous` a tree it will accept | After a mode run, `git status --porcelain` is non-empty and no `test:`/`feat:`/`fix:` commit was created; the chain test asserts both |
| The new mode cannot silently degrade the standalone tdd path | Existing `code-testing-agent` suites pass unchanged when the mode is not requested |
| The chain is never able to land on a protected branch | Feature-branch requirement is retained in the new mode; a test asserts the STOP on `main` still fires |
| The line-285 prohibition is lifted only where it is actually safe | The prohibition remains for the default mode and is scoped to it in the source text |

## Scope

**In**

- An implementation-only mode for `tdd-loop` that tolerates a dirty tree, makes
  no commit, opens no PR, and still requires a feature branch. Leaving the work
  uncommitted is the load-bearing half — without it the chain still dead-ends.
- The same mode for `tdd-fix`, which terminates the chain the same way today:
  it commits at `tdd-fix/SKILL.md:89`, then opens a PR at `:96`. Under the mode
  it does neither.
- Scoping the `tdd-loop:285` prohibition to the default mode, since an
  implementation-only run never touches `gh pr checks`.
- One executable chain test, modeled on the existing
  `tests/plugins/test-proposal-prompt-pipeline.sh`.

**Out**

- Re-litigating `implementation-plan`'s plans-only constraint — resolved; it is
  no longer a blocker.
- A `plan-then-handoff` mode for `implementation-plan` (issue option b) —
  obsolete, `build` already leaves the tree dirty.
- A wrapper orchestration command like PR #414's `/git-agent:autonomous-pr` —
  deferred. Fix the seam before adding a driver over it.
- Whether these suites run on PRs at all — real, but it is issue
  [#408](https://github.com/shawn-sandy/agentics/issues/408)'s scope, not this
  feature's.
- Retiring `tdd-loop` in favour of `tdd-fix` — both ship today; consolidation is
  a separate call.

## Risks and tensions

Retained at Tier 1 because the feature turns on the first item.

- **The line-285 prohibition may be load-bearing beyond `gh pr checks`.** The
  stated reason is state interleaving on that one command, which an
  implementation-only run avoids. If the real reason is broader, the mode does
  not make the chain safe. Confirm by reading the commit and PR that introduced
  line 285 before writing the mode.
- **Two skills, one behaviour.** `tdd-loop` (300 lines) and `tdd-fix` (107) both
  need the mode. They will drift unless the guard text has one source.
- **A passing test proved nothing once already.** PR #414 passed all 8 checks
  while the feature was fully broken, because the test grepped strings in a
  markdown file. Sub-feature 2 is the mitigation, which is why it is scoped in
  rather than noted.

## Sub-feature breakdown

Dependency-ordered. Prompt files are written at convergence (Step 8) and are
not cited here while `status: gathering`.

### 1. tdd-implementation-mode (M) — depends on: none

The mode is one seam: every blocker is a guard or terminal step inside the two
tdd skills, and none of them requires touching `plan-agent` or `git-agent`.

Touches seven sites. In `tdd-loop/SKILL.md`: lines 44-62 (tree and branch
guards), 137 (Step 3 commit), 264 (Step 6 commit), 277 (Step 7 Open PR), 285
(the prohibition). In `tdd-fix/SKILL.md`: 89 (Step 7 commit), 96 (Step 8 Open
PR).

Sized at the top of M — one domain, roughly six steps, no schema or data
migration. Per the sizing guide an L would need a hidden seam checked first;
the candidate split here is "relax the guards" versus "suppress the terminal
commit and PR steps", and it is not a real seam: ship either half alone and the
chain still dead-ends, so they cannot be planned independently.

### 2. chain-execution-test (S) — depends on: tdd-implementation-mode

Separate plan because it is harness work, not skill authoring, and because it
must be able to fail against a broken mode — which means it cannot be written
by whoever is mid-way through writing the mode.

Models `tests/plugins/test-proposal-prompt-pipeline.sh`, which already exercises
the `build-proposal` → `prompt` chain end-to-end.

## Next step

Converge this doc (write the two sub-feature prompts), then run each
sub-feature's paste-ready `/plan-agent:implementation-plan` command in
dependency order. The feature doc stops here.
