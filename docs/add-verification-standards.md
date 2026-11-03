# Add Verification Standards

> Makes verification self-enforcing — authoring rules require it, the skill reviewer scores it, CI runs every test automatically, and the dist build fails loudly when a plugin source is missing.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-verification-standards](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added "The verification gate" section to `.claude/rules/plugin-patterns.md` — mutating skills define done as artifact + check; structured output ships one worked example; canonical implementations named
- Added Warning-level Verification gate check to `skill-reviewer/.../references/audit-steps.md` Dimension 3; absence in a mutating/measuring skill caps Dimension 3 at 1 pt
- Created `tests/plugins/test-verification-gate-rule.sh` — holds rule text, rubric row, and best-practices section together with a positive canary
- Rewrote `tests/run-all.sh` and `check-plugin-versions.yml`: globs every `test-*.{sh,mjs}` / `*.test.mjs` under `tests/`, four documented skips; CI replaced 20 hand-enumerated steps with the auto-discovering runner
- Fixed stale baseline SHA256 in `tests/plugins/test-plan-phases.mjs` (9.1.0 design retune had been failing on main since PR #537)
- Fixed `scripts/build-dist.mjs`: missing plugin source now sets `process.exitCode = 1` instead of printing ERROR and exiting 0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/rules/plugin-patterns.md` | Authoring rule — verification gate standard | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Rubric — Dimension 3 verification gate check | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Best practices — gate-per-mutation-type table | Modified |
| `tests/plugins/test-verification-gate-rule.sh` | Retention test — rule + rubric + best-practices | Created |
| `tests/run-all.sh` | Test runner — auto-discovering, 4 documented skips | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — runs auto-discovering runner | Modified |
| `tests/plugins/test-plan-phases.mjs` | Smoke test — fixed stale SHA256 baseline | Modified |
| `scripts/build-dist.mjs` | Build script — non-zero exit on missing plugin | Modified |

## How it works

49 of 77 test files ran in no CI workflow before this change — they existed but were never executed. The root cause was a hand-enumerated step list in CI that required manual additions whenever a new test was written. The auto-discovering runner (`tests/run-all.sh`) fixes this by globbing for `test-*.{sh,mjs}` and `*.test.mjs` anywhere under `tests/`, with four explicitly documented skips (two claude-CLI harness tests, one deployed-URL smoke, one needs-built-dist). New tests are automatically included with no wiring step.

The authoring rule and rubric changes close the cultural root cause: neither required a verification gate before, so skills shipped without one and scored fine. The rule is now explicit (artifact + check = done; structured output ships a worked example), and the rubric deducts from Dimension 3 when it's absent.

The retention test holds all three changes together: deleting the rule text, rubric row, or best-practices section causes the test to fail. This is the same pattern as `test-exitplanmode-guard.sh`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards](plans/add-verification-standards.md)
