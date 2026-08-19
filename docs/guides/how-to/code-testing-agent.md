# How do I... code-testing-agent

Covers the test lifecycle: suggesting tests tied to real behavior, auditing an existing suite, running scoped tests, and driving red-green TDD loops.

Install: `/plugin install code-testing-agent@agentics-kit`

## code-testing-agent

Analyzes code and suggests purpose-driven tests for the behavior it actually has, then offers to write the files.

- **Command** — `/code-testing-agent:code-testing-agent [file path, function, or pasted code]`
- **Say it instead** — "what tests is this file missing?"
- **What happens** — Resolves the target (explicit path, pasted code, conversation context, or `git diff --name-only HEAD~1`), looks for an implementation plan in `docs/plans/` or `~/.claude/plans/`, detects the framework and coverage target, then lists each suggestion as What / Why / How / Where. If you say yes it writes the test files and runs them.
- **Watch out** — It fixes its own broken test files for at most 3 iterations before hard-stopping; a test that fails because the source really is wrong is reported as a behavior-gap finding, never weakened to force a pass.

## reviewing-tests

Audits existing tests against the source they cover and reports gaps, redundancy, and misaligned assertions.

- **Command** — `/code-testing-agent:reviewing-tests [test file path]`
- **Say it instead** — "audit the tests for the auth module"
- **What happens** — Resolves the test files, locates and reads the source under test, hunts for design intent in a plan or commit log, then reviews each test and offers to apply fixes plus new P1 gap tests. Applied fixes are re-run scoped to the touched files before it reports.
- **Watch out** — If its edits break the suite it retries 3 times, then reverts the breaking edits and says so rather than claiming success; it does not propose whole new suites — that is `code-testing-agent`.

## running-tests

Detects the test framework per changed file and runs only the tests that match.

- **Command** — `/code-testing-agent:running-tests [file path]`
- **Say it instead** — "run the tests for what I changed"
- **What happens** — Takes an explicit path or `git diff --name-only HEAD`, pairs each source file with its test file, detects the framework from config files (nearest-ancestor wins in a monorepo), and prints a results table of pass/fail/error counts plus stderr on failure.
- **Watch out** — Runs are scoped to the resolved test files, never the full suite, and it stops immediately when the diff is empty and you gave no path; source files with no test get a file-level advisory only.

## tdd-fix

Fixes a described bug by writing a failing test first, then looping until it goes green.

- **Command** — `/code-testing-agent:tdd-fix <bug description>`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Parses symptom, expected behavior, and affected files from your message, appends one failing test, then loops hypothesis-edit-rerun up to 10 times, logging each round. On green it sweeps the full suite, then hands off to `commit-agent` (`fix:` prefix) and `pr-agent`, ending with a PR URL.
- **Watch out** — Three hard stops with no commit and no PR: the new test passes on the red phase, the loop hits 10 iterations, or the regression sweep breaks a previously passing test.

## tdd-loop

Implements a new feature test-first, looping red-green-refactor until every acceptance criterion passes.

- **Command** — `/code-testing-agent:tdd-loop <feature description with numbered acceptance criteria>`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Writes and commits a failing suite covering every criterion, loops up to 20 implementation rounds, runs typecheck and lint (up to 5 gate-fix rounds), commits the implementation as a separate `feat:` commit, and opens a PR.
- **Watch out** — Pre-flight stops the run on a dirty working tree, a detached HEAD, or `main`/`master`, and it refuses to start without an enumerable list of acceptance criteria; the implementation loop is forbidden from asking you anything mid-run.
