# Changelog

## [1.0.1] - 2026-05-07

### Changed

- Collapsed `code-simplifier` skill description from multi-line YAML block to single-line inline string; "Use when..." trigger now first for reliable auto-activation

## [1.0.0] - 2026-04-30

### Added

- Initial release of code-simplifier plugin
- `code-simplifier` skill with plan-mode refactoring workflow (analyze, plan,
  review, apply)
- `agent-code-simplifier` background agent for delegated structural analysis
  from other agents or automated workflows
- Nine-category smell checklist: dead code, excessive complexity, god
  classes/functions, duplicated logic, coupling/cohesion, primitive
  obsession/feature envy, parameter lists, naming/consistency, performance
  anti-patterns
- Smell severity rating system (Clean / Minor Issues / Needs Refactoring /
  Major Refactoring Needed)
- Automatic plan file creation in project plans directory with prioritized
  refactoring steps
- Plan + apply workflow: enters plan mode for analysis, exits and applies
  changes after developer approval
- Confidence-based filtering in background agent
- Project-scoped agent memory for learning recurring patterns
