# Changelog

## [1.5.0] - 2026-03-14

### Added

- PostToolUse hook on `ExitPlanMode` — prompts user to run plan-interview after exiting plan mode

## [1.4.0] - 2026-03-10

### Added

- New `plan-hygiene` command — batch scans plan directories for randomly-named files and renames them to descriptive kebab-case names based on content headings
- Rules section in README with copyable pre-commit plan hygiene rule

## [1.3.0] - 2026-02-26

### Added

- New `review-rename-plans` command — reviews plan filenames against their content and offers to rename files whose names don't match their intent, with support for single-file and batch modes

## [1.2.0] - 2026-02-26

### Added

- Plan name validation in Step 2 — checks whether the filename and H1 heading are descriptive and aligned with the plan's content, suggests better names when they are random or generic, and offers to rename the file

## [1.1.0] - 2026-02-24

### Added

- Add TodoWrite progress tracking (Step 0) to both `SKILL.md` and command file — creates todos for all interview steps upfront and marks each complete as it finishes

## [1.0.0] - Initial release

- Structured multi-round plan interview skill and command
- Rounds covering technical trade-offs, UI/UX, accessibility, and edge cases
- Out-of-scope concern detection and complexity check
- Option to append interview summary to the plan file
