# Prove merge readiness locally, without GitHub Actions

> Ships a portable `verify.sh` merge gate and a `verified-change` skill that enforces test-first, mutation-checked changes, then dogfoods both into the agentics repo so no change here is proposed for merge without local proof.

<!-- generated:start -->

**Status:** Shipped 2026-08-22  **Plan:** [add-local-merge-gate](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Created `scripts/verify.sh` — a portable single entry point that covers test running, marketplace validation, the plugin version guard, and README table freshness
- Shipped `verified-change` skill in `code-testing-agent` (or as a standalone skill) that enforces test-first implementation with mandatory mutation checks
- Mutation check discipline: deliberately break the implementation, confirm the new test goes red, restore — catches tests that pass for the wrong reason
- Dogfooded into the agentics repo: `CLAUDE.md` merge gate rule requires `bash scripts/verify.sh` to exit 0 and the PR body's VERIFICATION section to be filled
- Skip detection: a `SKIP (not configured)` line is a skip, not a pass — recorded as one

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/verify.sh` | Merge gate — single entry point | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Skill — test-first + mutation check discipline | Created |
| `CLAUDE.md` | Repo instructions — merge gate rule | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — version bump | Modified |

## How it works

GitHub Actions is frequently billing-blocked on this account. A quota-blocked run fails every job in seconds with no test output — red CI is not evidence of a defect and green CI is not evidence of correctness. Merge readiness has to be provable on the machine.

`scripts/verify.sh` is the single local entry point. For the unit stage it runs `npm test` when a `package.json` npm test script exists, otherwise falls back to `tests/run-all.sh` (which auto-discovers every `tests/**/test-*.sh`, `test-*.mjs`, and `*.test.mjs`). It also runs the marketplace JSON validation hook, the plugin version guard script, and the README table freshness check. All gates report individually; the script exits 0 only when all pass.

The `verified-change` skill adds a discipline layer on top: write the test first, implement until it passes, then deliberately break the implementation and verify the test goes red. A test that stays green through a deliberate mutation is not a test — this step is what proves the coverage is real rather than decorative. The skill requires a bounded fix loop (3 attempts max) and escalates rather than faking success.

`CLAUDE.md` documents the gate rule: no change is proposed for merge without `bash scripts/verify.sh` exiting 0 and the VERIFICATION section filled in with what was actually run.

## How to use it

```bash
bash scripts/verify.sh                   # run the full local merge gate
```

Skill invocation:
```
/code-testing-agent:verified-change      # enforce test-first with mutation check
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a9b2c41` | 2026-08-22 | feat: add local merge gate and verified-change skill (#591) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate](plans/add-local-merge-gate.md)
