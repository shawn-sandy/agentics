# Add local merge gate

> Adds `scripts/verify.sh` as a local pre-merge gate with typecheck, lint, unit, e2e, and marketplace stages, a `verified-change` skill, a `bin/install-verify-gate` installer, and a re-entry guard to prevent recursive invocation.

<!-- generated:start -->

**Status:** Shipped 2026-08-21 **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Created `scripts/verify.sh`: runs typecheck, lint, unit, e2e, and marketplace validation stages in sequence; exits non-zero on any failure.
- Created `code-testing-agent:verified-change` skill: wraps verify.sh with context about which files changed and which stages are relevant.
- Created `bin/install-verify-gate`: installs verify.sh as a git pre-push hook.
- Added `.claude/skills/verified-change/` as a directory copy of the plugin skill (for repos without the plugin installed).
- Created `tests/test-verify-gate.sh` and `tests/test-verified-change-skill.sh`.
- Added merge-gate rule to `CLAUDE.md`.
- Added re-entry guard: `VERIFY_GATE_ACTIVE` env var prevents recursive invocations.
- Mutation check uses `cmp -s` instead of `git diff` to avoid false positives from diff format changes.
- Bumped code-testing-agent to 3.6.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/verify.sh` | Verification script | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Verified-change skill | Created |
| `bin/install-verify-gate` | Gate installer | Created |
| `.claude/skills/verified-change/` | Directory copy | Created |
| `tests/test-verify-gate.sh` | Gate tests | Created |
| `tests/test-verified-change-skill.sh` | Skill tests | Created |
| `CLAUDE.md` | Merge-gate rule | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

`verify.sh` runs five stages in sequence: typecheck (tsc --noEmit), lint (eslint or configured linter), unit tests, e2e tests (when configured), and marketplace validation (`node scripts/check-plugin-versions.mjs`). Each stage prints PASS or FAIL with its output. The script exits 0 only when all stages pass.

The re-entry guard (`VERIFY_GATE_ACTIVE=1`) prevents the verify.sh pre-push hook from triggering itself when verify.sh runs git commands internally (e.g., `git fetch origin` in the marketplace stage). Without the guard, the hook would recurse until the stack overflowed.

The mutation check uses `cmp -s` (silent binary comparison) instead of `git diff`. `git diff` can return false positives on files that are semantically identical but differ in line endings, trailing whitespace, or diff algorithm output. `cmp -s` is a direct byte comparison: two files are either identical or not.

## How to use it

```
/code-testing-agent:verified-change
bash bin/install-verify-gate   # install as pre-push hook
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
