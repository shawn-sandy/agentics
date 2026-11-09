# Add verification standards

> Adds a verification authoring rule to plugin-patterns, a rubric warning to skill-reviewer, an auto-discovering test runner, and fixes two broken baselines — standardizing how verification is defined and tested across all plugins.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added verification authoring rule to `.claude/rules/plugin-patterns.md`: every skill gate must include a concrete assertion, not just a prose description.
- Added rubric warning to skill-reviewer: skills without a verification gate are flagged as incomplete.
- Created `tests/run-all.sh`: auto-discovers and runs every `test-*.sh` in `tests/`; 74 passed, 4 skipped on first run.
- Fixed `plan-phases.mjs` baseline comparison: was comparing against wrong commit, now compares against `origin/main`.
- Fixed `build-dist.mjs` to exit non-zero on any bundling error (was silently succeeding on partial failures).
- Bumped skill-reviewer to 2.5.2 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/rules/plugin-patterns.md` | Authoring rule | Modified |
| `kit/plugins/skill-reviewer/` | Rubric warning | Modified |
| `tests/run-all.sh` | Test runner | Created |
| `tests/test-verification-gate-rule.sh` | Verification gate test | Created |
| `kit/plugins/plan-agent/scripts/plan-phases.mjs` | Baseline fix | Modified |
| `scripts/build-dist.mjs` | Build script fix | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The authoring rule change makes verification gates a first-class part of skill authoring: a new skill that lacks a gate will be flagged by skill-reviewer immediately, before it ships. The rubric warning surfaces this in review, not just in the authoring guide.

The auto-discovering test runner means adding a new `test-*.sh` file automatically includes it in CI without editing a manifest. The 4 skipped tests were skipped because their required tooling wasn't configured in the test environment, not because of code failures — the runner distinguishes `SKIP (not configured)` from `PASS` and `FAIL`.

The `plan-phases.mjs` baseline fix prevents false-positive drift failures on feature branches: comparing against the parent commit means a 10-commit branch reports drift from commit 9, not from `main`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
