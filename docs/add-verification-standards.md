# Add Verification Standards

> Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added a "The verification gate" section to `.claude/rules/plugin-patterns.md` requiring that mutating skills define done as artifact plus check, and that structured-output skills ship one worked example (with `memory-tools`, `completion-gates.md`, and `settings-restore` Step 7 as canonical references).
- Extended `skill-reviewer`'s `references/audit-steps.md` Dimension 3 with a Warning-level verification gate check; absence in a mutating or measuring skill caps Dimension 3 at 1 point; `best-practices.md` gained a gate-per-mutation-type reference table.
- Created `tests/plugins/test-verification-gate-rule.sh` as a retention test holding the rule text, the rubric row, and the best-practices section together with a positive canary.
- Replaced CI's 20 hand-enumerated test steps in `check-plugin-versions.yml` with a new `tests/run-all.sh` runner that globs every `test-*.{sh,mjs}` and `*.test.mjs` under `tests/`, with four documented skips (claude CLI harness ×2, deployed-URL smoke, needs-built-dist).
- Fixed `tests/plugins/test-plan-phases.mjs` by re-deriving the `BASELINE_SHA256` for the deliberate 9.1.0 design retune (PR #537), which had left the baseline check failing on `main` since that merge.
- Updated `scripts/build-dist.mjs` to set `process.exitCode = 1` when a manifest-registered plugin's source directory is missing, instead of printing an ERROR row and exiting 0.
- Bumped `skill-reviewer` from 2.5.1 to 2.5.2 with a changelog entry.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `.claude/rules/plugin-patterns.md` | Authoring rules with verification gate section | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Rubric with Dimension 3 verification gate check | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Best practices with gate-per-mutation-type table | Modified |
| `tests/plugins/test-verification-gate-rule.sh` | Retention test for rule, rubric, and best-practices | Created |
| `tests/run-all.sh` | Universal test runner globbing all test files | Created |
| `.github/workflows/check-plugin-versions.yml` | CI wired to use the runner | Modified |
| `tests/plugins/test-plan-phases.mjs` | Baseline re-derived for 9.1.0 retune | Modified |
| `scripts/build-dist.mjs` | Exits non-zero on missing registered plugin | Modified |
| `.claude-plugin/marketplace.json` | skill-reviewer bumped to 2.5.2 | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.5.2 entry | Modified |

## How it works

This chore is the leverage-point tier of the agent-prompting audit: rather than fixing individual skills, it changes the system so bad skills can't be authored or shipped silently.

The authoring rule change in `plugin-patterns.md` establishes the verification gate as a first-class requirement rather than folklore. Any skill that mutates files, git state, or remote services must end with a step that re-reads or re-runs the output and confirms success. Structured-output skills (those that emit JSON, HTML, or a structured document) must include one filled worked example alongside their placeholder schema.

The rubric change makes the gate a scoring criterion. Before this change, a file-mutating skill with no verification gate could score 10/10 in `skill-reviewer`. After, absence of a gate in a mutating skill caps Dimension 3 at 1 point, making the score reflect the real quality gap.

The retention test `test-verification-gate-rule.sh` is the enforcement mechanism: it greps for the exact rule text, the rubric row, and the best-practices section, and a positive canary ensures it can't pass vacuously. Deleting any of the three phrases makes the test fail. This means a future edit that accidentally removes the standard is caught immediately.

The `tests/run-all.sh` runner solved a gap identified by the audit: 49 of 77 test files ran in no workflow. The runner globs `tests/**/test-*.{sh,mjs}` and `tests/**/*.test.mjs`, runs everything except four documented skips, and exits non-zero on any failure. CI now invokes this runner, so every new test file in the `tests/` tree is automatically wired in without any workflow edit.

The `build-dist.mjs` fix closes a silent failure mode: a plugin registered in `marketplace.json` whose `kit/plugins/<name>/` directory has been deleted would previously produce an ERROR row in stdout and exit 0, allowing a dist to ship without the plugin. After this fix it sets `process.exitCode = 1`, making the build step fail visibly.

## How to use it

New plugin authors: read `.claude/rules/plugin-patterns.md` before writing a SKILL.md. Every mutating skill (one that writes files, pushes to git, or publishes to a remote URL) must end with a verification step. Every structured-output skill must include a worked example.

To run the full test suite locally:
```bash
bash tests/run-all.sh
```

Expected output: `74 passed, 0 failed, 4 skipped` (counts may grow as new tests are added).

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
