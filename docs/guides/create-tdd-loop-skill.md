<!-- generated:start -->
# tdd-loop skill

**Plugin:** `code-testing-agent` · **Shipped:** 2026-05-08 · **Version:** 3.3.0

**Plan:** [docs/plans/create-tdd-loop-skill.md](../docs/plans/create-tdd-loop-skill.md)

---

## What it does

`tdd-loop` is an autonomous test-first feature development skill for the `code-testing-agent` plugin. Given a feature description and acceptance criteria, it:

1. Writes a comprehensive failing test suite (red phase) and commits it as `test:`
2. Enters a bounded autonomous loop — form hypothesis, edit production code, re-run tests — up to **20 iterations**
3. Runs typecheck and lint on green, with a separate **5-iteration** gate-fix budget
4. Commits the implementation as `feat:` and opens a PR

The two-commit pattern (`test:` then `feat:`) is the defining characteristic: reviewers can confirm that the tests were written before any production code.

## Activation

The skill auto-activates when the user says anything matching:

> "TDD a feature", "write tests first then implement", "red-green-refactor loop", "autonomously build something test-first"

Explicit invocation: `/code-testing-agent:tdd-loop <feature description>`

## Workflow (8 steps)

| Step | Action | Notes |
|------|--------|-------|
| 0 | Pre-flight: dirty-tree check, branch guard (refuses `main`/`master`), plan-mode check | Hard stops — must fix before proceeding |
| 1 | Parse feature spec, extract acceptance criteria, detect test framework | Uses `running-tests` heuristics; one `AskUserQuestion` allowed if framework unknown |
| 2 | Write failing test suite | All tests must fail — passes before any production code = STOP |
| 3 | Commit tests via `commit-agent` skill | `test:` prefix; HARD STOP — no production code yet |
| 4 | Autonomous implementation loop (max 20) | Hypothesis → edit → re-run; no user questions, no plan mode |
| 5 | Quality gates: typecheck + lint + full regression sweep (max 5 fix iterations) | Failures enter separate gate-fix loop |
| 6 | Commit implementation via `commit-agent` skill | `feat:` prefix |
| 7 | Open PR via `pr-agent` skill | PR body includes full TDD iteration log |
| 8 | Stop | No CI polling, no follow-up suggestions |

## Guardrails

### EARLY_GREEN

If all tests pass after a single edit in iteration 1, the skill stops and requires human review. This guards against tests that are too lenient or a feature that was already partially implemented.

### Test-edit escape hatch

One test correction is allowed per loop run (e.g., a typo in an assertion discovered during implementation). The iteration is logged with `(test edited: <reason>)` and **counts as 2** against the 20-cap. A second edit attempt triggers a hard stop.

### Forbidden inside the loop

`.skip`, `xfail`, `@ts-ignore`, `as any`, deleting tests, mocking the unit under test, modifying test assertions (except via the escape hatch), calling `AskUserQuestion`, entering plan mode, creating commits.

### Hard cap

If iteration 20 ends with failing tests: prints the full iteration log and stops. No commit, no PR. The partial code stays on disk for manual inspection — the skill never auto-reverts.

## Iteration log format

Every loop run emits a markdown table using the schema from `references/tdd-log-format.md`:

```
| #  | Phase | Hypothesis                             | Files Touched | Failing Before | Failing After |
|----|-------|----------------------------------------|---------------|----------------|---------------|
| 1  | impl  | Need role=tablist on container element | src/Tabs.tsx  | 9              | 7             |
| g1 | gate  | tsc: implicit any on TabProps.tabs     | src/Tabs.tsx  | typecheck:2    | typecheck:0   |
```

- `impl` rows: numbered `1`, `2`, … — test-edit rows get `*` suffix (e.g., `5*`)
- `gate` rows: numbered `g1`, `g2`, …
- This schema is shared; `tdd-fix` will adopt it in a follow-up

The full table is included in the PR body under `## TDD iterations`.

## Demo

Contributors can scaffold a working demo project and see the exact invocation to use:

```bash
bash examples/demo-tdd-loop.sh
```

This creates `examples/tabs-demo/` — an isolated React + Vitest project with a WAI-ARIA Tabs acceptance spec in its README. The script prints the `/code-testing-agent:tdd-loop` invocation after setup. Clean up with `--clean`.

The demo project is not committed to the repo; it's generated on demand.

## Relationship to `tdd-fix`

| Skill | Use case | Iteration cap | Starts with |
|-------|----------|--------------|-------------|
| `tdd-fix` | Fix a known bug | 10 impl | Failing test for the bug |
| `tdd-loop` | Build a new feature | 20 impl + 5 gate | Feature description → full test suite |

The two skills share the iteration log schema (`references/tdd-log-format.md`).

## CHANGELOG reference

See [`kit/plugins/code-testing-agent/CHANGELOG.md`](../kit/plugins/code-testing-agent/CHANGELOG.md) — `[3.3.0] - 2026-05-08` for the full feature list shipped in this release.

<!-- generated:end -->
