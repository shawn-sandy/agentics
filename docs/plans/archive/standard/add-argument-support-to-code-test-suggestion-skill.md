---
status: in-progress
created: 2026-03-01
---

# Plan: Add Argument Support to code-test-suggestion Skill

## Context

The `code-test-suggestion` skill currently relies on natural language extraction in Step 1 to determine which code to analyze. Users can mention a file in their message, but the skill has no explicit argument-handling logic for:
- A specific file path passed directly (e.g., "suggest tests for `src/auth.ts`")
- A specific function/method name (e.g., "test the `validateToken` function in auth.ts")

The goal is to make Step 1 smarter: parse the invocation message for a file path argument and/or a function/method name argument, prioritize those over heuristics, and fall back to git history only when no argument is present.

## Files to Modify

1. `plugins/code-test-suggestion/skills/code-test-suggestion/SKILL.md` — update Step 1
2. `plugins/code-test-suggestion/.claude-plugin/plugin.json` — bump version to `2.1.0`
3. `.claude-plugin/marketplace.json` — sync version to `2.1.0`
4. `plugins/code-test-suggestion/CHANGELOG.md` — add `[2.1.0]` entry

## Changes

### 1. Update Step 1 in SKILL.md

Replace the current Step 1 section with the expanded version below. The key additions are:

**New priority order (6 levels):**

1. **File path argument** — Parse the invocation message for a file path pattern (quoted path, backtick path, or a token ending in a known code extension like `.ts`, `.js`, `.py`, `.go`, `.rs`, `.rb`, `.java`, `.cs`). If found, resolve the path relative to `$PWD` and confirm it exists before proceeding.

2. **Function/method argument** — Parse for a function or method name alongside the file path (e.g., "test the `validateToken` function", "suggest tests for the `render` method"). If found, scope the analysis in Step 3 to that function/method only; note this to the user.

3. **Pasted code** — If the user pasted a code block directly in their message, use it. Treat it as an anonymous file; note that coverage assessment will be limited.

4. **Conversation context** — If a file was recently created, edited, or discussed in this session, use that. (Unchanged from current behavior.)

5. **Recent changes** — Run `git diff --name-only HEAD~1` (or `git diff --name-only --cached` for staged changes). Exclude test files, config files, and lock files. Present the list and ask the user to confirm. (Unchanged from current behavior.)

6. **Ask if unclear** — "Which code would you like me to suggest tests for? Please provide a file path or paste the code." (Unchanged from current behavior.)

**Argument parsing rules (new, explicit):**

- A file path may appear:
  - In backticks: `` `src/auth.ts` ``
  - In quotes: `"src/auth.ts"` or `'src/auth.ts'`
  - As a bare token that looks like a path: `src/auth.ts` or `./lib/utils.js`
  - After keywords: "for", "in", "analyze", "review", "of"
- A function/method name may appear after: "function", "method", "the `name`", "called `name`"
- If a file path is found but the file does not exist, stop and report the error to the user before continuing. Do not fall through to git.
- If a function name is given without a file path, still require a file path from levels 3–6 before scoping to that function.

**Scope reporting (updated):**

After resolving, report clearly:
- File(s) to be analyzed
- Function/method scope, if any (e.g., "Scoping analysis to `validateToken` function only.")
- Whether the analysis is full-file or function-scoped

### 2. Version bump to 2.1.0

- `plugin.json`: `"version": "2.1.0"`
- `marketplace.json`: update `code-test-suggestion` entry `"version"` to `"2.1.0"`

### 3. CHANGELOG.md entry

```markdown
## [2.1.0] - 2026-03-01

### Added
- Step 1 now parses invocation message for explicit file path and function/method arguments
- File paths (backtick, quoted, or bare tokens with known extensions) are prioritized over git inspection
- Function/method scoping: when a function name is provided, analysis in Step 3 is limited to that function
- Error reporting when a provided file path does not exist (no silent fallback)
```

## Verification

1. Load the plugin: `claude --plugin-dir ~/devbox/agentics/plugins/code-test-suggestion`
2. Test file path argument: say "suggest tests for `src/someFile.ts`" — skill should immediately identify that file without asking
3. Test function scope: say "suggest tests for the `myFunc` function in `src/someFile.ts`" — skill should report it will scope to `myFunc`
4. Test fallback: say "suggest tests" with no path — skill should check git history and present changed files
5. Test invalid path: say "suggest tests for `src/nonexistent.ts`" — skill should stop and report the file was not found

## Version Bump Details

| Location | Field | Old | New |
|----------|-------|-----|-----|
| `plugins/code-test-suggestion/.claude-plugin/plugin.json` | `version` | `2.0.0` | `2.1.0` |
| `.claude-plugin/marketplace.json` (code-test-suggestion entry) | `version` | `2.0.0` | `2.1.0` |
