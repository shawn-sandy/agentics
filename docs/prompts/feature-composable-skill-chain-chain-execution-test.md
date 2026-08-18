---
type: task
intent: Write a test that actually executes the build to tdd to ship-autonomous chain and fails when the chain is broken, solving execution isolation rather than asserting by grep
techniques: Clarity/directness, XML context tags, CoT scaffolding, Output format
created: 2026-08-18
---

# Task: Chain Execution Test

<context>
Repo: shawn-sandy/agentics, a Claude Code plugin marketplace. Tests live in
`tests/plugins/`, are bash, and run via `tests/run-all.sh`.

This is sub-feature 2 of the feature doc at `docs/features/composable-skill-chain.md`.
**It depends on sub-feature 1** (`docs/prompts/feature-composable-skill-chain-tdd-implementation-mode.md`),
which adds an implementation-only mode to `tdd-loop` and `tdd-fix`. That mode
must exist before this test can assert on it.

**What the chain is.** `plan-agent:build` implements a plan and leaves the tree
dirty. `code-testing-agent`'s tdd skills run in implementation-only mode —
no commit, no PR — preserving that dirty tree. `git-agent:ship-autonomous` then
requires a dirty tree and ships it.

**Why this test exists.** PR #414 shipped a completely broken chain with all 8
checks green. Its test grepped strings in a markdown command file; it could not
execute a chain, so it could not notice the chain did not work.

**There is no model to copy, and this is the central difficulty.**
`tests/plugins/test-proposal-prompt-pipeline.sh` is the repo's closest analogue
and is worth reading for how it names and scopes an objective-verification test
across a chain's seams. But it asserts entirely with `grep -qF` against SKILL.md
text and executes nothing. Every existing pipeline test in this repo works that
way. Copying that approach reproduces exactly the failure this task exists to
prevent.

**The isolation problem.** Executing the real chain means `gh` credentials, live
check state, and a PR created per run — orphaned on every retry. This is
plausibly why no executable chain test exists in the repo today. Solving it is
the substance of this task.
</context>

<thinking>
Work through this in order — the isolation decision gates everything downstream.

1. Read `tests/plugins/test-proposal-prompt-pipeline.sh` and one or two other
   `tests/plugins/*.sh` files to learn the repo's test conventions: how they are
   invoked, how they report failures, how `tests/run-all.sh` discovers them.
   Take the conventions; reject the grep-based assertion strategy.
2. Decide the isolation strategy before writing any assertion. Two candidates:
   a disposable throwaway repository the test creates and tears down, or stubbed
   `gh` calls with the surrounding chain still genuinely executing. Name the
   tradeoff you are accepting — a stub that fakes too much becomes a grep test
   wearing a costume.
3. Establish what "the chain ran" is observed by, concretely. The chain's
   observable states are: tree dirty after `build`, still dirty and commit-free
   after the tdd mode run, and a PR URL from `ship-autonomous`.
4. Check: if someone reverts sub-feature 1's mode changes, does this test go
   red? If it can still pass against a broken chain, it has the PR #414 defect
   and is not finished.
</thinking>

Write a test that executes the `build` → tdd → `ship-autonomous` chain and fails
when the chain is broken. Solve execution isolation first, then assert.

At minimum the test must observe, by running the chain rather than by reading
skill text:

- The working tree is non-empty (`git status --porcelain`) after the tdd mode run
- No `test:`, `feat:`, or `fix:` commit was created by the tdd mode run
- The `main`/`master` STOP still fires in the new mode
- The run reaches a PR URL

<constraints>
- Do not assert by grepping SKILL.md files. That is the defect being fixed. If
  a particular property genuinely cannot be observed by execution, assert what
  you can and record the limitation explicitly rather than substituting a grep
  and calling it covered.
- Do not modify the tdd skills. That is sub-feature 1's plan; this test asserts
  against what it built.
- Do not create PRs against `shawn-sandy/agentics` itself from a test run.
- Clean up any temp directories the test creates.
- Whether these suites run on PRs at all is issue #408's scope, not this task's.
</constraints>

If isolation cannot be solved at acceptable cost, say so plainly and propose the
narrowest honest alternative. A recorded limitation is a real outcome. A grep
test relabelled as an execution test is not — it is how this problem was shipped
the first time.

Output requirements:
- Format: one bash test under `tests/plugins/`, wired into `tests/run-all.sh`, following the conventions of the files already there
- Length: as short as the isolation strategy allows
- Tone: imperative and specific; every assertion must fail if the behaviour regresses, with no tautologies and no assertions locked to exact wording
