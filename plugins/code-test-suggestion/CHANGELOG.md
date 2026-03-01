# Changelog

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
