# Plan: Add `running-tests` Skill to `skill-reviewer` Plugin

**Rename this file to:** `add-running-tests-skill-to-skill-reviewer.md`

## Context

The `skill-reviewer` plugin (v1.3.0) currently contains two skills: `reviewing-skills` (audits SKILL.md files) and `planning-skills` (scaffolds new skills). The user wants a third skill that runs tests for changed files, verifies they pass, detects missing tests, and advises the user to create them. This is a MINOR addition (new skill, no breaking changes) — version bumps from 1.3.0 → 1.4.0.

---

## Steps

### 1. Create `skills/running-tests/SKILL.md`

File: `plugins/skill-reviewer/skills/running-tests/SKILL.md`

Frontmatter:

```yaml
---
name: running-tests
description: Identifies changed files, finds related test files, detects the test framework, runs tests, and reports pass/fail/error results. Use when the user asks to "run tests for my changes", "check if tests pass", "test this file", "verify my changes don't break tests", or "are there missing tests". Also checks for missing test files and advises on what to create. Does not review test quality or suggest tests from scratch — use reviewing-tests for that.
---
```

Body outline (Adaptive + Sequential, Freedom level: Flexible):

- **Step 0** — Create TodoWrite progress todos (5 items: identify, find, detect, run, report)
- **Step 1** — Identify changed files: explicit path → `git diff --name-only HEAD` → conversation context → ask; skip binaries/lock files/generated files; **if `git diff` returns empty output, short-circuit with "No changed files detected — provide a file path directly" and stop**
- **Step 2** — Find related test files: for each changed file use naming conventions from `references/test-runner-guide.md`; produce a resolved pairs table (source → test file or "not found")
- **Step 3** — Detect test framework: inspect `package.json`, `pytest.ini`, `pyproject.toml`, `go.mod`, `Cargo.toml`, Makefile; use signal table from `references/test-runner-guide.md`; in monorepos with multiple frameworks, use the **nearest ancestor config file** to the changed file as the tie-breaker; ask user if still ambiguous
- **Step 4** — Run tests via Bash: use per-framework command template from `references/test-runner-guide.md` scoped to resolved test files; capture exit code; surface stderr on failure
- **Step 5** — Report results and advise on missing tests: pass/fail/error counts table; list all "not found" source files with the **conventional test file path** the user should create (file-level advisory only — no function-level parsing)

---

### 2. Create `skills/running-tests/references/test-runner-guide.md`

File: `plugins/skill-reviewer/skills/running-tests/references/test-runner-guide.md`

Five sections:

1. **Test File Naming Conventions** — table keyed by source extension → conventional test file patterns → directories to search (covers TS/JS, Python, Go, Rust, Ruby)
2. **Framework Detection Signals + Run Commands** — table of config file/dependency key → detected framework → run command template (Jest, Vitest, pytest, Go test, cargo test, Mocha, npm test fallback)
3. **Result Parsing Patterns** — per-framework signals for pass/fail/error (used in Step 5 reporting)
4. **Missing Test Advisory Templates** — per-language file-level message templates for advising users what file to create
5. **Monorepo Tie-breaking Rule** — when multiple framework config files are detected, use the nearest ancestor config file relative to the changed source file

---

### 3. Bump plugin version and update description: 1.3.0 → 1.4.0

File: `plugins/skill-reviewer/.claude-plugin/plugin.json`

- Change `"version": "1.3.0"` → `"version": "1.4.0"`
- Update `"description"` to reflect the new skill: `"Review and plan Claude Code skills, and run tests for changed files — audit SKILL.md files, scaffold new skills, and verify test coverage"`

---

### 4. Bump marketplace version: 1.3.0 → 1.4.0

File: `.claude-plugin/marketplace.json`

- In the `skill-reviewer` entry (line 65), change `"version": "1.3.0"` → `"version": "1.4.0"`
- Also add `"running-tests"` to the `tags` array

---

### 5. Prepend CHANGELOG entry

File: `plugins/skill-reviewer/CHANGELOG.md`

Prepend above `## [1.3.0]`:

```markdown
## [1.4.0] - 2026-03-03

### Added

- **`running-tests` skill** — Adaptive skill that identifies changed files (via git or user input), finds related test files using naming conventions, detects the test framework, runs tests via Bash, and reports pass/fail/error counts
- **Missing test detection** — identifies source files with no test file and provides conventional test file path suggestions (file-level advisory)
- **`references/test-runner-guide.md`** — per-framework lookup tables for naming conventions, detection signals, run commands, result parsing, and missing test advisory templates

---
```

---

### 6. Update README.md

File: `plugins/skill-reviewer/README.md`

- Add `running-tests/` to the plugin structure tree
- Expand "two skills" to "three skills" in the overview
- Add a `### Skill: running-tests` component section

---

## Critical Files

| Action | File |
|--------|------|
| Create | `plugins/skill-reviewer/skills/running-tests/SKILL.md` |
| Create | `plugins/skill-reviewer/skills/running-tests/references/test-runner-guide.md` |
| Edit | `plugins/skill-reviewer/.claude-plugin/plugin.json` |
| Edit | `.claude-plugin/marketplace.json` |
| Edit | `plugins/skill-reviewer/CHANGELOG.md` |
| Edit | `plugins/skill-reviewer/README.md` |

---

## Verification

1. Version sync check:
   ```bash
   grep -r '"version"' plugins/skill-reviewer/.claude-plugin/ .claude-plugin/marketplace.json
   ```
   Both must show `"1.4.0"`.

2. Load the plugin locally and trigger the skill:
   ```bash
   claude --plugin-dir ~/devbox/agentics/plugins/skill-reviewer
   ```
   Then ask: "run the tests for my changes" or "are there missing tests?"

3. Confirm the skill activates (not `reviewing-tests` or `planning-skills`) and runs through all 5 steps.

4. Verify no collision with `reviewing-tests` skill (code-test-suggestion plugin) by asking "review my tests" — that should activate the other skill, not `running-tests`.

---

## Interview Summary

### Key Decisions Confirmed
- **Skill name**: `running-tests` — gerund form, no collision with `reviewing-tests` in `code-test-suggestion`
- **Design pattern**: Adaptive + Sequential — detects framework per changed file, then runs scoped commands
- **Progressive disclosure**: workflow in SKILL.md body, reference data in `references/test-runner-guide.md`
- **Version bump**: MINOR (1.3.0 → 1.4.0), updates required in both `plugin.json` and `marketplace.json`
- **Advisory scope**: file-level only — no function-level parsing required

### Plan Naming
| Element | Current | Issue | Suggested |
|---------|---------|-------|-----------|
| Filename | `delightful-stirring-lovelace.md` | Random — unrelated to content | `add-running-tests-skill-to-skill-reviewer.md` |
| H1 Heading | `# Plan: Add \`running-tests\` Skill to \`skill-reviewer\` Plugin` | Pass | — |

### Open Risks & Concerns
1. **Test environment prerequisites** — Tests may fail due to missing env vars, DB connections, or seeding; not the skill's fault but could confuse users
2. **Plugin identity mismatch** — `skill-reviewer` is branded as a SKILL.md tool; a test runner is general dev tooling and may confuse marketplace browsing

### Amendments Applied to Plan
1. **Empty-state handling** added to Step 1 — short-circuits with a clear message when `git diff` returns no output
2. **Advisory scoped to file-level only** in Step 5 — removed function-level parsing (no implementation mechanism existed)
3. **`plugin.json` description update** added to Step 3 — reflects the plugin's expanded scope
4. **Monorepo tie-breaking rule** added to Step 3 and `test-runner-guide.md` Section 5 — nearest ancestor config file wins
