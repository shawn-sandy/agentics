# Add `running-tests` Skill to `skill-reviewer` Plugin

> Adds a `running-tests` skill to `skill-reviewer` that identifies changed files, finds related test files, detects the test framework, runs tests, and reports pass/fail/error results alongside missing-test advisories.

<!-- generated:start -->

**Status:** Shipped 2026-03-03   **Plan:** [add-running-tests-skill-to-skill-reviewer.md](plans/add-running-tests-skill-to-skill-reviewer.md)   **Type:** feature

## What shipped

- New `kit/plugins/skill-reviewer/skills/running-tests/SKILL.md` — 5-step adaptive + sequential skill: identify changed files, find related test files, detect test framework, run tests, report results.
- New `kit/plugins/skill-reviewer/skills/running-tests/references/test-runner-guide.md` — per-framework lookup tables for naming conventions, detection signals, run commands, result parsing, and missing test advisory templates.
- Empty-state guard in Step 1: if `git diff` returns no output, the skill short-circuits with "No changed files detected — provide a file path directly."
- Missing test detection: Step 5 lists source files with no test file found, providing the conventional test file path the user should create (file-level advisory only, no function-level parsing).
- Monorepo tie-breaking: nearest ancestor config file wins when multiple framework configs are present.
- `skill-reviewer` plugin bumped from `1.3.0` → `1.4.0`.

> See [CHANGELOG v1.4.0](../kit/plugins/skill-reviewer/CHANGELOG.md#140---2026-03-03) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/skill-reviewer/skills/running-tests/SKILL.md` | Skill instructions — running-tests | Created |
| `kit/plugins/skill-reviewer/skills/running-tests/references/test-runner-guide.md` | Framework detection + run command lookup tables | Created |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Plugin changelog | Modified |
| `kit/plugins/skill-reviewer/README.md` | Plugin documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 1.3.0 → 1.4.0 | Modified |

## How it works

Step 1 resolves which files to test: first an explicit path from the user's message, then `git diff --name-only HEAD`, then conversation context, then a user prompt. Binary files, lock files, and generated files are skipped. If `git diff` returns empty output the skill stops immediately rather than silently running against nothing.

Step 2 pairs each changed source file with its test file using naming conventions from `references/test-runner-guide.md`. For TypeScript/JavaScript, `src/foo.ts` → `src/foo.test.ts` or `__tests__/foo.test.ts`. The output is a resolved pairs table: source file → test file path or "not found".

Step 3 detects the test framework by inspecting config files and package manifests: `jest.config.*` or `"jest"` in `package.json` scripts → Jest; `vitest.config.*` or `"vitest"` → Vitest; `pytest.ini` or `pyproject.toml` with `[tool.pytest]` → pytest; `go.mod` → `go test`; `Cargo.toml` → `cargo test`. In monorepos, the nearest ancestor config file to the changed source file takes precedence.

Step 4 runs the framework-specific command scoped to the resolved test files, captures the exit code, and surfaces stderr on failure.

Step 5 reports pass/fail/error counts in a table and lists all "not found" source files alongside their conventional test file paths as a creation advisory.

## How to use it

**Skill activation** — triggers on "run the tests for my changes", "check if tests pass", "are there missing tests":

```bash
claude --plugin-dir ./kit/plugins/skill-reviewer
```

Then: "run tests for my changes" or "test this file: src/parser.ts"

**Report format:**

```
| File | Test File | Result |
|------|-----------|--------|
| src/parser.ts | src/parser.test.ts | ✓ Pass |
| src/utils.ts | (not found) | — |

Missing tests: src/utils.ts → create src/utils.test.ts
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [add-running-tests-skill-to-skill-reviewer.md](plans/add-running-tests-skill-to-skill-reviewer.md)
- Changelog: [CHANGELOG v1.4.0](../kit/plugins/skill-reviewer/CHANGELOG.md#140---2026-03-03)
