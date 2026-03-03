# Changelog

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
