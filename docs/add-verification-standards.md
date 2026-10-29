# Add Verification Standards

> Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Authoring rule — (`.claude/rules/plugin-patterns.md`): new "The verification gate" section — mutating skills define done as artifact + check, structured output ships one worked example; names memory-tools, completion-gates.md, and settings-restore Step 7 as canonical.
- Rubric — (`skill-reviewer/.../references/audit-steps.md` Dimension 3 + `best-practices.md`): Warning-level Verification gate check; absence in a mutating/measuring skill caps Dimension 3 at 1 pt; best-practices gains the gate-per-mutation-type table.
- Retention test — (`tests/plugins/test-verification-gate-rule.sh`): holds the rule text, the rubric row, and the best-practices section together, with a positive canary — same pattern as `test-exitplanmode-guard.sh`.
- Test runner — (`tests/run-all.sh` + `check-plugin-versions.yml` + `.claude/rules/testing.md`): globs every `test-*.{sh,mjs}` / `*.test.mjs` under `tests/`, four documented skips (claude-CLI harness ×2, deployed-URL smoke, needs-built-dist); CI's 20 hand-enumerated steps replaced by the runner plus one explicit claude-CLI-gated step.
- Fix the stale render baseline — (`tests/plugins/test-plan-phases.mjs`): re-derive `BASELINE_SHA256` for the deliberate 9.1.0 design retune (#537), which changed the shared CSS without updating the 8.5.1-era baseline — the check had been failing on main since.
- Dist builder — (`scripts/build-dist.mjs`): a manifest-registered plugin whose source directory is missing now sets `process.exitCode = 1` instead of printing an ERROR row and exiting 0; header documents `--publish` as implemented.
- Bump skill-reviewer — 2.5.1 → 2.5.2 with a changelog entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/plugins/test-verification-gate-rule.sh` | Test suite | Modified |
| `skill-reviewer/.../references/audit-steps.md` | Documentation | Modified |
| `best-practices.md` | Documentation | Modified |
| `test-exitplanmode-guard.sh` | Shell script | Modified |
| `tests/run-all.sh` | Test suite | Modified |
| `check-plugin-versions.yml` | Source file | Modified |
| `tests/plugins/test-plan-phases.mjs` | Test suite | Modified |
| `scripts/build-dist.mjs` | Implementation (JavaScript) | Modified |

## How it works

Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

Tier 3 — the leverage point — of the agent-prompting audit run against <https://shumer.dev/prompting-ai-agents>. Tiers 1–2 fixed nine shipped skills that could declare success on broken output; this tier fixes why they shipped that way: neither authoring rule required a verification gate or a worked example, the skill-quality rubric never scored them, 49 of 77 test files ran in no CI workflow, and the dist builder exited 0 on a missing plugin. No follow-up question needed: each step names its file and its check.

The implementation proceeded through the following steps: Authoring rule — (`.claude/rules/plugin-patterns.md`): new "The verification gate" section — mutating skills define done as artifact + check, structured output ships one worked example; names memory-tools, completion-gates.md, and settings-restore Step 7 as canonical.; Rubric — (`skill-reviewer/.../references/audit-steps.md` Dimension 3 + `best-practices.md`): Warning-level Verification gate check; absence in a mutating/measuring skill caps Dimension 3 at 1 pt; best-practices gains the gate-per-mutation-type table.; Retention test — (`tests/plugins/test-verification-gate-rule.sh`): holds the rule text, the rubric row, and the best-practices section together, with a positive canary — same pattern as `test-exitplanmode-guard.sh`.; Test runner — (`tests/run-all.sh` + `check-plugin-versions.yml` + `.claude/rules/testing.md`): globs every `test-*.{sh,mjs}` / `*.test.mjs` under `tests/`, four documented skips (claude-CLI harness ×2, deployed-URL smoke, needs-built-dist); CI's 20 hand-enumerated steps replaced by the runner plus one explicit claude-CLI-gated step.; Fix the stale render baseline — (`tests/plugins/test-plan-phases.mjs`): re-derive `BASELINE_SHA256` for the deliberate 9.1.0 design retune (#537), which changed the shared CSS without updating the 8.5.1-era baseline — the check had been failing on main since.; Dist builder — (`scripts/build-dist.mjs`): a manifest-registered plugin whose source directory is missing now sets `process.exitCode = 1` instead of printing an ERROR row and exiting 0; header documents `--publish` as implemented.; Bump skill-reviewer — 2.5.1 → 2.5.2 with a changelog entry..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
