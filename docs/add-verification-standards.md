# Add Verification Standards

> Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added "The verification gate" section to `.claude/rules/plugin-patterns.md` requiring that mutating skills define done as artifact + check and structured-output skills ship one worked example; named `memory-tools`, `completion-gates.md`, and `settings-restore` Step 7 as canonical implementations
- Added a Warning-level Verification gate check to `skill-reviewer`'s `references/audit-steps.md` Dimension 3 and updated `best-practices.md` with a gate-per-mutation-type table — absence in a mutating or measuring skill caps Dimension 3 at 1 pt
- Added `tests/plugins/test-verification-gate-rule.sh` with 8 retention checks holding the rule text, the rubric row, and the best-practices section together; deleting any of the three phrases fails the test
- Added `tests/run-all.sh` globbing every `test-*.{sh,mjs}` and `*.test.mjs` under `tests/`; wired into `check-plugin-versions.yml` CI replacing 20 hand-enumerated steps; documented 4 skips (claude-CLI harness ×2, deployed-URL smoke, needs-built-dist)
- Fixed `tests/plugins/test-plan-phases.mjs` stale baseline SHA256 (derivable for the 9.1.0 design retune #537 that changed shared CSS without updating the 8.5.1-era baseline)
- Fixed `scripts/build-dist.mjs` to exit non-zero when a manifest-registered plugin's source directory is missing (previously logged an ERROR row and exited 0)
- Bumped `skill-reviewer` from 2.5.1 to 2.5.2 with a CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/rules/plugin-patterns.md` | "The verification gate" section added | Modified |
| `kit/plugins/skill-reviewer/references/audit-steps.md` | Dimension 3 Warning-level check | Modified |
| `kit/plugins/skill-reviewer/references/best-practices.md` | Gate-per-mutation-type table | Modified |
| `tests/plugins/test-verification-gate-rule.sh` | Retention test | Created |
| `tests/run-all.sh` | Universal test runner | Created |
| `.github/workflows/check-plugin-versions.yml` | CI step replaced by runner | Modified |
| `.claude/rules/testing.md` | Runner skip list documented | Modified |
| `tests/plugins/test-plan-phases.mjs` | Baseline SHA256 re-derived | Modified |
| `scripts/build-dist.mjs` | Error path sets non-zero exit | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.5.2 entry | Modified |
| `.claude-plugin/marketplace.json` | skill-reviewer 2.5.2 | Modified |

## How it works

Tier 3 addressed the structural cause of the Tier 1–2 gaps: the authoring rules never required a verification gate, so the rubric never penalised its absence, 49 of 77 test files ran in no CI workflow, and the dist builder silently succeeded on a missing plugin.

The authoring rule in `plugin-patterns.md` establishes two requirements with canonical implementations to copy rather than reinvent: a mutating skill must define done as artifact + check (the same shape `memory-tools` and `settings-restore` Step 7 already use), and a structured-output skill must ship one worked example (a filled instance, not a bracket-placeholder schema).

The rubric change makes the gate scoreable. A skill missing a verification gate is now a Warning-level finding in Dimension 3, and its absence caps that dimension at 1 point. This means a file-mutating skill with no gate can no longer score 10/10.

The retention test (`test-verification-gate-rule.sh`) holds all three files together with a positive canary, following the same pattern as `test-exitplanmode-guard.sh`. Deleting any of the three phrases the test greps for fails the build.

The universal runner (`tests/run-all.sh`) globs all test files under `tests/` by pattern, runs them in one sweep, and documents four explicit skips. CI was updated to invoke the runner rather than enumerating test steps by hand, so a new test file added anywhere under `tests/` automatically runs in every future PR.

The dist builder fix closes the silent-failure mode where a plugin registered in `marketplace.json` with a missing source directory produced a dist that silently excluded the plugin while exiting 0.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
- Audit source: <https://shumer.dev/prompting-ai-agents>
- Related plans: [add-verification-gates.md](add-verification-gates.md), [add-worked-examples.md](add-worked-examples.md)
- Retention test: [tests/plugins/test-verification-gate-rule.sh](../tests/plugins/test-verification-gate-rule.sh)
