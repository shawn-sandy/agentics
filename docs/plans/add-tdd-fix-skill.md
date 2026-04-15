# Plan: tdd-fix skill (add, register, demo)

## Context

The user wants a new skill that wraps a test-driven bug-fix loop: given a bug
description, write a failing test that reproduces it, then iterate (run tests
→ analyze → edit → re-run) until green or until a hard cap of 10 iterations
is reached. On success, run the full suite for regressions, commit with a
`fix:` prefix, and open a PR. Each iteration's hypothesis must be logged.

The skill belongs inside the existing `code-testing-agent` plugin
alongside `running-tests` and `reviewing-tests` — it is fundamentally
test-centric, and co-locating it lets the loop delegate to `running-tests`
instead of re-implementing test-framework detection. Commit and PR steps
delegate to the existing `git-agent` skills (`commit-agent`, `pr-agent`),
mirroring the composition pattern already used by `git-agent/ship`.

This repo has no runnable application test suite — only empty
plugin-validation fixtures. To honor the user's "use it to fix a currently
failing test" instruction, the plan seeds a minimal, self-contained bash
fixture under `tests/demo/` with a deliberate one-character bug. This gives
the skill a real failing test to run against without dragging in a heavy
test harness this repo doesn't otherwise need.

## Objective

1. Author `tdd-fix` as a new skill inside the `code-testing-agent` plugin.
2. Register it by bumping the plugin's version in `marketplace.json` and
   adding a CHANGELOG entry.
3. Seed a tiny, intentionally-broken bash test fixture so the skill has a
   real failing test to demonstrate against.
4. Activate the skill (plugin marketplace refresh) and run it end-to-end
   against the seeded failing test.

## Critical Files

| Path | Action |
|------|--------|
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | **Create** — the new skill |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | **Edit** — add `[3.2.0]` entry |
| `.claude-plugin/marketplace.json` | **Edit** — bump `code-testing-agent` version `3.1.0` → `3.2.0` and append `tdd` / `bug-fix` tags |
| `tests/demo/calculator.sh` | **Create** — trivial bash module with one bug |
| `tests/demo/calculator.test.sh` | **Create** — shell-based test that currently fails |
| `tests/demo/run.sh` | **Create** — minimal runner invoked by the skill |
| `tests/demo/README.md` | **Create** — one paragraph explaining the fixture's purpose |
| `docs/plans/cached-marinating-pebble.md` | **Commit** — this plan file |

No changes to `kit/plugins/code-testing-agent/.claude-plugin/plugin.json`
(it intentionally omits `version` per the repo's relative-path convention).

## Reusable Components (referenced, not duplicated)

- `kit/plugins/code-testing-agent/skills/running-tests/SKILL.md` — framework
  detection + scoped test execution. The loop calls this in Step 3.
- `kit/plugins/git-agent/skills/commit-agent/SKILL.md` — used in Step 7 for
  the final `fix:` commit (skill provides conventional-commit formatting).
- `kit/plugins/git-agent/skills/pr-agent/SKILL.md` — used in Step 8 to push
  and open the PR. Already handles platform detection (gh vs glab).
- `kit/plugins/git-agent/skills/ship/SKILL.md` — reference implementation
  for orchestrating commit+PR composition.

## Steps

1. **Create the skill directory and file.**
   `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md`. Use the
   canonical frontmatter from `.claude/rules/plugin-patterns.md`:
   ```yaml
   ---
   name: tdd-fix
   description: Use when the user asks to reproduce a bug with a failing test
     then fix it in a test-driven loop, "TDD fix", "write a red test then
     make it green", or wants an autonomous red-green cycle capped at N
     iterations. Does not design tests from scratch — use code-testing-agent
     for that.
   allowed-tools: Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
   ---
   ```
   *Why:* Frontmatter drives activation; the description mirrors the
   "Use when …" convention already used by every other skill in this repo
   and the `allowed-tools` list is the minimum needed to read code, write
   a test, edit a fix, run tests via Bash, and log iteration state.

2. **Draft the skill body with an explicit 10-step workflow.** The body
   must enumerate (clearly labeled as Step 0 … Step 9):
   - **Step 0 — Create progress todos** (`TodoWrite`).
   - **Step 1 — Parse bug description.** Extract symptom, affected file(s),
     expected vs actual behavior from the invocation message. If missing,
     `AskUserQuestion`.
   - **Step 2 — Write a failing test.** Locate the matching test file
     (Glob by convention — `*.test.*`, `test_*.py`, `*_test.go`, etc.).
     Append a new case that reproduces the bug. Do **not** edit production
     code yet. *Why:* TDD red phase — prove the bug before fixing it.
   - **Step 3 — Enter the loop, max 10 iterations.** For each iteration
     `i` in `1..10`:
     1. Run the scoped test via Bash (delegating to the patterns in
        `running-tests/references/test-runner-guide.md`).
     2. If the test **passes** on iteration 1, stop with a warning: the
        test did not actually reproduce the bug; ask the user.
     3. Parse failure output (stderr + exit code). Form a **hypothesis**
        as a single sentence ("operator in `add()` is subtraction, not
        addition").
     4. Append to an in-memory log: `{iteration, hypothesis, diff-summary,
        result}`. Show the log incrementally to the user.
     5. Edit the suspected production file (`Edit` tool, not `Write`).
     6. Re-run the scoped test. If green, exit the loop.
   - **Step 4 — Hard cap behavior.** If iteration 10 completes with the
     test still failing, print the full iteration log, stop, and **do
     not** commit or open a PR. Tell the user the loop exhausted and
     surface the last three hypotheses. *Why:* User chose "Hard stop at
     10, no PR on failure" during planning — avoids noisy `wip:` commits.
   - **Step 5 — Regression sweep.** Once green, run the **full** suite
     (no scope filter). If any previously-passing test now fails, stop:
     report the regressions, keep changes on disk, and let the user
     decide. Do not commit.
   - **Step 6 — Summarize the fix.** Print a summary block: the bug
     description, the final hypothesis that worked, files changed, and
     iteration count.
   - **Step 7 — Commit via `commit-agent`.** Invoke the `commit-agent`
     skill. Pre-seed the commit message scope with the `fix:` type and a
     description built from the summary. *Why:* Delegating keeps the
     conventional-commit formatting and pre-commit-hook behavior
     consistent with the rest of the marketplace.
   - **Step 8 — Open a PR via `pr-agent`.** Invoke the `pr-agent` skill.
     Its body should reference the iteration log as the PR description's
     "How it was found" section.
   - **Step 9 — Stop.** Mirror the `ship` skill's explicit stop rule — do
     not analyze further, do not run tests again, do not suggest cleanup.

3. **Embed an iteration-log template in the skill.** Include a small
   markdown table skeleton in the SKILL.md so Claude renders the log
   identically each run:
   ```
   | # | Hypothesis | Change | Result |
   |---|------------|--------|--------|
   ```
   *Why:* Consistent output makes iteration history diffable in PR
   descriptions.

4. **Bump the plugin version and update tags.** Edit
   `.claude-plugin/marketplace.json`: change `code-testing-agent` version
   from `"3.1.0"` to `"3.2.0"` and add `"tdd"` and `"bug-fix"` to the
   `tags` array. *Why:* Adding a skill is a MINOR bump per
   `.claude/rules/marketplace.md`; plugin.json intentionally has no
   `version` field for relative-path plugins.

5. **Add a `[3.2.0]` entry to `kit/plugins/code-testing-agent/CHANGELOG.md`.**
   Format matches existing entries: date (`2026-04-14`), `### Added`
   section naming the `tdd-fix` skill and one-line summary. *Why:* The
   `agentic-plugin-dev:plugin-manager` skill expects parallel updates
   across `marketplace.json` + `CHANGELOG.md`.

6. **Seed the failing-test fixture.** Create four files under
   `tests/demo/`:
   - `calculator.sh` — defines `add() { echo $(($1 - $2)); }` (the `-` is
     the intentional bug).
   - `calculator.test.sh` — sources `calculator.sh` and asserts
     `add 2 3 == 5`. Exits non-zero if not.
   - `run.sh` — loops over `*.test.sh` and exits with the worst status.
   - `README.md` — one paragraph: "Intentionally-broken fixture used by
     `tdd-fix` demos. Do not delete without updating the skill's
     reference docs."
   Make each script `chmod +x`. *Why:* A deterministic, zero-dependency
   failing test the skill can actually run against. Any richer harness
   would exceed scope.

7. **Activate and invoke the skill.**
   - `/plugin marketplace update agentics` (or re-add) to pick up the
     version bump.
   - Invoke with a bug description such as: *"tdd-fix: the `add`
     function in tests/demo/calculator.sh returns the difference
     instead of the sum. Reproduce with a failing test and fix it."*
   - Observe the loop execute against the seeded fixture. Expected
     outcome: iteration 1 reproduces the bug (assertion failure:
     `-1 != 5`), iteration 2 patches `-` to `+`, test passes, full
     suite passes, commit + PR are created.

## Verification

End-to-end sanity check after the skill is written but before invoking it:

1. **Lint the skill.** Run the `skill-reviewer:reviewing-skills` skill
   against `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md`. Must
   report no errors. Run `skill-reviewer:auditing-allowed-tools` to
   confirm the declared `allowed-tools` is minimal but sufficient.
2. **Validate manifest JSON.** The repo's `.claude/settings.json` already
   auto-validates `marketplace.json` after every Write/Edit; confirm no
   parse errors.
3. **Validate the fixture in isolation.** Run `bash tests/demo/run.sh`
   manually — it should exit **non-zero** before the skill runs.
4. **Activate the plugin.** `/plugin marketplace update agentics` then
   confirm `tdd-fix` appears in `/plugin:code-testing-agent` skill list.
5. **Run the skill against the fixture.** Verify:
   - Iteration log appears and grows incrementally.
   - Loop terminates with green before iteration 10.
   - Full-suite regression step runs (re-invokes `run.sh`).
   - A `fix:` commit is created on a feature branch (not `main`).
   - A PR is opened (or the user is prompted for platform/auth if CLIs
     aren't configured).
6. **Run `bash tests/demo/run.sh` again after the fix.** Must exit `0`.

## Next Steps (out of scope)

- *Not this plan:* add a real top-level test runner for the broader
  marketplace (e.g. `bats-core` or a Node-based validator). The `tests/demo/`
  fixture is demonstrative, not structural.
- *Not this plan:* make `tdd-fix` support parallel hypothesis testing or
  AI-guided bisecting — keep the first version linear.
- *Not this plan:* wire `tdd-fix` into the `ship` skill as a pre-ship
  gate.
