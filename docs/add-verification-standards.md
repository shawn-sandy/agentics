# Add Verification Standards

> Five skills closed the verification gap individually; this tier makes verification self-enforcing — the authoring rule requires it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added "The verification gate" section to `.claude/rules/plugin-patterns.md`: mutating skills define done as artifact + check; structured output ships one worked example; names memory-tools, `completion-gates.md`, and settings-restore Step 7 as canonical.
- Updated `skill-reviewer/.../references/audit-steps.md` Dimension 3: Warning-level Verification gate check; absence in a mutating/measuring skill caps Dimension 3 at 1 pt.
- Added `tests/plugins/test-verification-gate-rule.sh`: eight retention checks over the rule file, the rubric, and best-practices, with a positive canary.
- Added `tests/run-all.sh`: globs every `test-*.{sh,mjs}` / `*.test.mjs` under `tests/`; four documented skips (claude-CLI harness ×2, deployed-URL smoke, needs-built-dist); replaces CI's 20 hand-enumerated steps with the runner plus one explicit step.
- Fixed stale render baseline in `tests/plugins/test-plan-phases.mjs` (re-derived for the 9.1.0 design retune #537).
- Updated `scripts/build-dist.mjs`: a manifest-registered plugin whose source directory is missing now sets `process.exitCode = 1` instead of exiting 0 silently.
- Updated `.claude/rules/testing.md` with the auto-discovery pattern.
- Bumped skill-reviewer 2.5.1 → 2.5.2.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/rules/plugin-patterns.md` | Verification gate rule | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Rubric Dimension 3 | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Gate-per-mutation table | Modified |
| `tests/plugins/test-verification-gate-rule.sh` | Retention test | Created |
| `tests/run-all.sh` | Auto-discovering test runner | Created |
| `.github/workflows/check-plugin-versions.yml` | CI uses runner | Modified |
| `.claude/rules/testing.md` | Auto-discovery pattern | Modified |
| `tests/plugins/test-plan-phases.mjs` | Stale baseline fix | Modified |
| `scripts/build-dist.mjs` | Non-zero exit on plugin error | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.5.2 entry | Modified |
| `.claude-plugin/marketplace.json` | skill-reviewer 2.5.1 → 2.5.2 | Modified |

## How it works

The verification standard is now self-enforcing at three levels:

1. **Authoring rule**: `plugin-patterns.md` explicitly requires a verification gate in every mutating skill and a worked example in every skill with structured output. A new test retains these requirements so they cannot be silently removed.

2. **Reviewer score**: `audit-steps.md` Dimension 3 caps at 1 pt when a mutating skill has no verification gate, so a gap in a shipped skill reduces its score visibly.

3. **CI runner**: `tests/run-all.sh` auto-discovers all test files matching `test-*.{sh,mjs}` / `*.test.mjs`, so a new test file joins CI automatically with no workflow edit. 49 of 77 test files previously ran in no CI workflow.

The dist builder exit-1 fix ensures a misconfigured plugin (source directory missing) fails loudly at build time rather than silently shipping without that plugin.

## How to use it

The standards are automatically applied during authoring and review. To run the full test suite:

```bash
bash tests/run-all.sh
```

Output: N passed, 0 failed, 4 skipped (the four documented skip categories).

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `ab2f7693` | 2026-08-17 | chore: verification standards — authoring rule, rubric, test runner, dist exit (skill-reviewer 2.5.2) (#569) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
