# Add Verification Standards

> Make verification self-enforcing: authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly on a missing plugin.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added a "The verification gate" section to `.claude/rules/plugin-patterns.md` requiring that mutating skills define done as artifact plus check, and that structured-output skills ship one worked example; named `settings-restore` Step 7, `completion-gates.md`, and `memory-tools` as canonical references
- Added a Warning-level Verification gate check to `skill-reviewer`'s `references/audit-steps.md` Dimension 3 rubric, capping Dimension 3 at 1 point for any mutating or measuring skill that lacks a gate; added the gate-per-mutation-type table to `best-practices.md`
- Created `tests/plugins/test-verification-gate-rule.sh` with eight retention checks over the rule file, the rubric, and best-practices, plus a positive canary to prevent vacuous passes
- Created `tests/run-all.sh` as a single entry point that globs every `test-*.sh`, `test-*.mjs`, and `*.test.mjs` under `tests/` — new test files are picked up automatically with no CI wiring required; the runner ships with four documented skips (claude-CLI harness, deployed-URL smoke, needs-built-dist)
- Fixed the stale render baseline in `tests/plugins/test-plan-phases.mjs` — the `BASELINE_SHA256` was derived from pre-9.1.0 CSS and had been failing on `main` since the 9.1.0 design retune (#537)
- Made `scripts/build-dist.mjs` set `process.exitCode = 1` when a manifest-registered plugin's source directory is missing, instead of printing an ERROR row and exiting 0
- Bumped skill-reviewer from `2.5.1` to `2.5.2` with a changelog entry
- Wired `tests/run-all.sh` into `.github/workflows/check-plugin-versions.yml`, replacing the 20 hand-enumerated test steps

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/rules/plugin-patterns.md` | Authoring rule with verification gate section | Modified |
| `kit/plugins/skill-reviewer/references/audit-steps.md` | Rubric with Warning-level gate check | Modified |
| `kit/plugins/skill-reviewer/references/best-practices.md` | Gate-per-mutation-type table | Modified |
| `tests/plugins/test-verification-gate-rule.sh` | Retention test for the rule, rubric, and best-practices | Created |
| `tests/run-all.sh` | Universal test runner with documented skip list | Created |
| `tests/plugins/test-plan-phases.mjs` | Re-derived SHA-256 baseline for 9.1.0 design | Modified |
| `scripts/build-dist.mjs` | Non-zero exit on missing registered plugin | Modified |
| `.claude-plugin/marketplace.json` | skill-reviewer 2.5.2 version bump | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Changelog entry for 2.5.2 | Modified |

## How it works

This plan was Tier 3 — the leverage point — of the same agent-prompting audit that produced the verification-gates and security-scrub fixes. Tiers 1 and 2 repaired nine skills that could declare success on broken output; this tier asked why they shipped that way and fixed the systemic causes.

The authoring rule in `plugin-patterns.md` is the primary prevention mechanism. Before this change, the verification gate standard existed only as folklore in the skills that happened to implement it well. The new section states the requirement explicitly: any skill that mutates files, git state, or a remote must end with a step that verifies the change landed, and any skill with structured output must include at least one filled worked example. The canonical implementations (`settings-restore` Step 7, `completion-gates.md`) are named so authors have concrete models.

The rubric change ensures that skill-reviewer catches the gap during code review. A file-mutating skill with no verification gate could previously score 10/10. The new Warning-level check caps Dimension 3 at 1 point when the gate is absent, making the gap visible in any audit run rather than relying on the reviewer noticing it manually.

The retention test (`test-verification-gate-rule.sh`) holds the rule, the rubric row, and the best-practices section together with a single bash grep suite. Its design mirrors `test-exitplanmode-guard.sh`: a positive canary string is checked first so a pattern that matches everything would still fail. Deleting any of the three required phrases causes the test to fail, making it impossible to quietly remove the standard.

`tests/run-all.sh` addressed the most concrete pre-existing gap: 49 of 77 test files ran in no CI workflow. CI hand-enumerated about 20 test steps; adding a new suite required editing the workflow file. The runner globs `tests/**/test-*.{sh,mjs}` and `tests/**/*.test.mjs`, so new suites are picked up automatically. The skip list at the top of the file documents exactly why each of the four skipped files is excluded — the runner itself is the documentation of CI coverage.

The build-dist fix closed a silent failure mode: a plugin whose source directory had been deleted could be registered in `marketplace.json` and the build would produce a dist with a hole in it, exit 0, and log an ERROR row that was easy to overlook. Setting `process.exitCode = 1` makes the failure surfaceable in CI and locally.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
- Audit source: <https://shumer.dev/prompting-ai-agents>
- Related: [add-verification-gates.md](add-verification-gates.md) (Tier 2)
- Related: [add-worked-examples.md](add-worked-examples.md) (Tier 4)
