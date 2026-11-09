# Add Verification Standards

> Make verification self-enforcing — the authoring rules require it, the skill-reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Added a "The verification gate" section to `.claude/rules/plugin-patterns.md` requiring that mutating skills define done as artifact + check, and that structured-output skills ship one worked example. Named `memory-tools`, `completion-gates.md`, and `settings-restore` Step 7 as canonical implementations.
- Added a Warning-level Verification Gate check to `skill-reviewer/references/audit-steps.md` Dimension 3, capping dimension scores at 1 pt when a mutating or measuring skill lacks a gate.
- Added `tests/plugins/test-verification-gate-rule.sh` with eight retention checks over the rule file, rubric row, and best-practices section — same structure as `test-exitplanmode-guard.sh`.
- Added `tests/run-all.sh` that globs every `test-*.{sh,mjs}` and `*.test.mjs` under `tests/`, replacing CI's 20 hand-enumerated test steps with a single runner plus a documented skip list (four files requiring a live claude CLI or deployed URL).
- Fixed a stale render baseline in `tests/plugins/test-plan-phases.mjs` (the 9.1.0 design retune had changed shared CSS without updating the 8.5.1-era SHA256 baseline, breaking the test on main since #537).
- Made `scripts/build-dist.mjs` set `process.exitCode = 1` when a marketplace-registered plugin's source directory is missing, instead of printing an ERROR row and exiting 0.
- Bumped skill-reviewer from 2.5.1 to 2.5.2 with a changelog entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/rules/plugin-patterns.md` | "The verification gate" section | Modified |
| `tests/plugins/test-verification-gate-rule.sh` | Retention test for the new rules | Created |
| `tests/run-all.sh` | Unified test runner replacing 20 CI steps | Created |
| `tests/plugins/test-plan-phases.mjs` | Stale baseline fix | Modified |
| `scripts/build-dist.mjs` | Exit 1 on missing plugin source | Modified |
| `.claude-plugin/marketplace.json` | skill-reviewer 2.5.2 | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.5.2 entry | Modified |

## How it works

The plan's central insight was that verification gates were missing not because authors forgot them but because the authoring rules never required them. The skill-reviewer rubric didn't score them. CI didn't run most test files. And the dist builder exited 0 on missing plugins, so gaps could ship silently.

The authoring rule change makes the standard explicit: any skill that mutates the filesystem, git state, or a remote must end with a verification step that re-reads the output, and any skill that emits structured output ships one filled worked example rather than bracket-placeholder schemas. The canonical implementations give authors concrete patterns to copy rather than reinvent.

The rubric change promotes the gate from folklore to a scored requirement. Dimension 3 (verification) now caps at 1 out of 3 points if a mutating or measuring skill lacks a gate — the same penalty structure that Dimension 2 uses for missing the plan-mode guard.

The retention test (`test-verification-gate-rule.sh`) holds the three files together with grep assertions, using a positive canary to prevent vacuous passes. The test itself runs in CI under `run-all.sh`.

The test runner replaced 20 hand-enumerated job steps with a glob. This matters because adding a test file no longer requires a workflow edit — CI picks it up automatically. The documented skip list names the four files that require a live `claude` CLI or a deployed URL, so they stay present in the repo without breaking the runner.

The dist builder fix closes a silent failure path: a plugin whose source directory had been deleted would previously build a dist without that plugin and exit 0, so marketplace consumers would install a broken set.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `cc28a20d` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `d9fdb0ba` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `28c3d704` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
- Related: [add-verification-gates.md](add-verification-gates.md) — Tier 2 of the same audit; applied gates to the five highest-impact skills
- Rule: `.claude/rules/plugin-patterns.md` — contains the "The verification gate" section
- Test runner: `tests/run-all.sh`
