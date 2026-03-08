# Changelog

## [2.1.1] - 2026-03-06

### Fixed

- Optimized skill description for improved trigger accuracy: now describes the structured 6-dimension checklist, complexity rating system, and automatic file resolution
- Removed self-referential "use this skill -- not built-in" language in favor of content-rich description
- Added informal trigger phrases ("take a look at this", "anything wrong with this code")
- Expanded scope exclusions to include accessibility audits
- Updated README to reflect all six review dimensions and the Breaking Changes output section
- Updated marketplace.json description to include complexity rating

## [2.1.0] - 2026-03-05

### Added

- Breaking Changes & Regressions checklist section (section 6) covering: public API surface, shared/internal contracts, data & config contracts, regression risk, and call site assessment
- Breaking Changes & Regressions output section in Review Format, placed between Complexity Rating and Critical Issues
- No-duplicate guidance: breaking changes listed in the new section are omitted from Critical Issues
- No-git-context fallback: when git history is unavailable, assess API surface visually from reviewed code only
- DB schema checks marked conditional: apply only when reviewing migration files or schema definitions
- Detection approach uses question-based guidance consistent with the rest of the checklist
- Example breaking change entry added to the Example Review section
- Updated frontmatter description to trigger on "detect breaking changes", "check if this change breaks anything", and "could this cause a regression" intents
- Added `breaking-changes` and `regressions` tags to marketplace.json entry

## [2.0.0] - 2026-03-03

### Changed

- BREAKING CHANGE: skill renamed from `code-review` to `code-review-agent` to avoid conflict with Anthropic's built-in `code-review` skill
- Skill directory renamed: `skills/code-review/` → `skills/code-review-agent/`

## [1.2.0] - 2026-03-03

### Added

- Code complexity rating (Low/Medium/High/Very High) to Review Checklist (#5)
- Complexity Rating section in Review Format output (after Summary)
- Rating guide table with signals for each level
- Multi-file guidance: per-file rating, aggregate only when reviewing 3+ files
- Small-file handling: trivially simple files noted as Low without full breakdown
- Scope clarification: complexity covers code-level coupling, not architecture
- Updated frontmatter description to include complexity
- Updated example review to demonstrate complexity output
- Added "complexity" keyword to plugin.json

## [1.1.0] - 2026-03-03

### Added

- Adaptive file resolution (Step 0): supports explicit path, git status, branch diff, and fallback prompt
- Table of contents

### Fixed

- Description rewritten to third person with scope exclusion
- Second-person "your review" corrected to "the review"
- Freedom level statement added to opening paragraph
