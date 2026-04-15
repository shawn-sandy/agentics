# Plan: Run tdd-fix on tests/demo/calculator.sh add() bug

## Context

The `add()` function in `tests/demo/calculator.sh:6-8` uses subtraction
(`$(($1 - $2))`) instead of addition, returning the difference of its
arguments. This is a canned bug set up to exercise the new `tdd-fix` skill
at `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md`. The user wants
the skill to reproduce the bug with a failing test and drive it to green.

Note: the red test is already staged at `tests/demo/calculator.test.sh:28-31`
with the `# tdd-fix: reproducing ...` marker, so Step 2 of the skill need
only *verify* the existing red test, not append a new one.

## Objective

Execute the `tdd-fix` skill end-to-end against the calculator bug and land
the fix via its built-in commit + PR steps.

## Steps

1. **Exit plan mode** — `tdd-fix` is a write-heavy skill; per
   `.claude/rules/plan-mode.md` it must not run inside plan mode.
2. **Invoke the skill** — `Skill` tool with
   `skill: "code-testing-agent:tdd-fix"` (or the installed equivalent).
3. **Let the skill run its 9 steps** —
   - Step 1: parse bug description (already supplied in user prompt).
   - Step 2: verify `tests/demo/calculator.test.sh:28-31` reproduces the
     bug (run `bash tests/demo/calculator.test.sh`; expect FAIL on add
     assertions). If the existing tagged assertions already cover the
     symptom, skip appending new ones.
   - Step 3: red→green loop, maximum 10 iterations. Expected change:
     `tests/demo/calculator.sh:7` operator `-` → `+`.
   - Step 5: regression sweep via `bash tests/demo/run.sh`.
   - Steps 6–8: summary, commit (`fix(tests/demo): ...`), and PR.

## Critical Files

- `tests/demo/calculator.sh` — the one-line fix target (line 7).
- `tests/demo/calculator.test.sh` — already contains the red assertions.
- `tests/demo/run.sh` — full-suite runner for the regression sweep.
- `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` — skill contract.

## Verification

- `bash tests/demo/calculator.test.sh` — before fix: add assertions fail;
  after fix: 5/5 pass.
- `bash tests/demo/run.sh` — overall runner returns exit 0.
- `git log -1` after skill run shows a `fix(...)` commit.

## Next Steps (out of scope)

- Consider whether `tdd-fix` should detect a pre-existing tagged red test
  and skip append-in-Step-2 rather than risk duplicating assertions.
