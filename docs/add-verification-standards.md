# Add verification standards to authoring rules, rubric, and CI

> Makes verification self-enforcing: authoring rules require verification gates and worked examples, the skill-quality rubric scores them, CI runs all 74 test files automatically via a new `tests/run-all.sh` runner, and the dist builder fails loudly on a missing plugin.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added "The verification gate" section to `.claude/rules/plugin-patterns.md`: mutating skills define done as artifact + check, structured output ships one worked example; canonical examples named.
- Updated `skill-reviewer/references/audit-steps.md` Dimension 3: Warning-level Verification gate check; absence in a mutating/measuring skill caps Dimension 3 at 1 pt. Updated `best-practices.md` with the gate-per-mutation-type table.
- Added `tests/plugins/test-verification-gate-rule.sh` — eight retention checks holding the rule text, the rubric row, and the best-practices section together with a positive canary.
- Added `tests/run-all.sh` — globs every `test-*.{sh,mjs}` and `*.test.mjs` under `tests/`, four documented skips (claude-CLI harness ×2, deployed-URL smoke, needs-built-dist). CI's 20 hand-enumerated steps replaced by the runner plus one explicit claude-CLI-gated step.
- Fixed stale render baseline in `tests/plugins/test-plan-phases.mjs` (re-derived `BASELINE_SHA256` for the 9.1.0 design retune from PR #537, which had been failing on main since).
- Updated `scripts/build-dist.mjs`: a manifest-registered plugin whose source directory is missing now sets `process.exitCode = 1` instead of printing an ERROR row and exiting 0.
- Bumped `skill-reviewer` from `2.5.1` to `2.5.2`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `.claude/rules/plugin-patterns.md` | Authoring rules | Modified |
| `kit/plugins/skill-reviewer/references/audit-steps.md` | Skill rubric | Modified |
| `kit/plugins/skill-reviewer/references/best-practices.md` | Best practices reference | Modified |
| `tests/plugins/test-verification-gate-rule.sh` | Retention test | Created |
| `tests/run-all.sh` | Test runner | Created |
| `.github/workflows/check-plugin-versions.yml` | CI workflow | Modified |
| `.claude/rules/testing.md` | Testing rules | Modified |
| `tests/plugins/test-plan-phases.mjs` | Phase smoke test | Modified |
| `scripts/build-dist.mjs` | Dist builder | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

The Tier 3 leverage point from the agent-prompting audit: Tiers 1–2 patched nine individual skills that could declare success on broken output, but neither the authoring rule nor the reviewer rubric ever required a verification gate, so the same gap would reopen on every new skill. This plan closes the systemic gap.

The `test-verification-gate-rule.sh` retention test greps for the rule text, the rubric row, and the best-practices section together, following the pattern of `test-exitplanmode-guard.sh`. Deleting any of the three phrases fails the build.

The `tests/run-all.sh` runner replaced 20 hand-enumerated CI steps — meaning 49 of 77 test files had been running in no CI workflow. New test files added to `tests/` are now automatically picked up without any workflow edit.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
