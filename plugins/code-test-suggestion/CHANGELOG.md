# Changelog

## [2.0.0] - 2026-03-01

### Removed

- **BREAKING:** Removed `suggest-tests` command (`/code-test-suggestion:suggest-tests`)
- **BREAKING:** Removed `review-tests` command (`/code-test-suggestion:review-tests`)
- Removed `commands/` directory

### Note

Both workflows remain fully available as auto-activated skills. Say "suggest tests for ..." or "review my tests" to trigger them.

## [1.1.0] - 2026-03-01

### Added

- New skill: `test-review` — reviews existing tests for quality, coverage gaps, and alignment with code behavior and developer intent
- 7-step review workflow: identify tests → locate source code → search for plan → analyze source → detect infrastructure → review tests across 9 dimensions → offer to apply fixes
- Review dimensions: behavior vs implementation, test naming, assertion focus, coverage gaps, mock hygiene, test fragility, setup/teardown isolation, plan alignment, coverage target progress
- Reference file: test-quality-checklist.md with detailed heuristics for each review dimension, anti-patterns, and language-specific review patterns
- Command: `/code-test-suggestion:review-tests [test-file-path]` for explicit invocation

## [1.0.0] - 2026-03-01

### Added

- Initial release: 6-step code test suggestion skill
- Step 1: Identifies target code from explicit paths, conversation context, or recent git changes
- Step 2: Searches for implementation plans in docs/plans/, ~/.claude/plans/, commit messages, and inline comments to understand developer intent
- Step 3: Analyzes code for behavioral summary, critical paths, integration points, implicit contracts, and fragility areas
- Step 4: Detects project test framework and learns existing test patterns from nearby test files
- Step 5: Suggests prioritized tests with rationale — each tied to specific code behavior, organized by Priority 1 (critical behavior), Priority 2 (error handling/edge cases), and Priority 3 (integration contracts)
- Step 6: Offers to write complete test files using detected project conventions
- Reference file: test-analysis-guide.md with detailed heuristics for code analysis, language-specific patterns (TypeScript/JS, Python, Go, Rust), and mock strategy guidance
- Command: `/code-test-suggestion:suggest-tests [file-path]` for explicit invocation
- Coverage-aware: Step 4d detects project coverage targets from jest.config, pyproject.toml, .nycrc, codecov.yml; Step 5 includes Coverage Assessment section and `[coverage-only]` tagged tests for trivial code needed to meet the target
