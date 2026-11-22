# Add local merge gate and verified-change skill

> `scripts/verify.sh` is a portable, auto-detecting merge gate that proves local merge readiness without depending on GitHub Actions CI; `verified-change` is a `code-testing-agent` skill that enforces test-first, mutation-checked changes and runs the gate before declaring a change done.

<!-- generated:start -->

**Status:** Shipped 2026-08-22 **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Added `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` — a portable gate that auto-detects typecheck, lint, unit, and e2e stages, skipping each absent stage with `SKIP (not configured)`, and additionally runs `tests/run-all.sh`, `node scripts/check-plugin-versions.mjs`, and `node scripts/build-readme-table.mjs --check` when it detects `.claude-plugin/marketplace.json`.
- Added `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` with a six-step mutation-check loop: write the test, mutation-check it, restore, implement, iterate up to 8 attempts, then stop and report.
- Added `references/mutation-check.md` (safe copy-mutate-restore-verify protocol using `cmp -s`, not `git diff --quiet`) and `references/verification-section.md` (a filled VERIFICATION example).
- Added `kit/plugins/code-testing-agent/bin/install-verify-gate` — an executable wrapper that copies `assets/verify.sh` into a target repo's `scripts/`, refusing to overwrite without `--force`.
- Copied the finished skill directory (including both `references/` files) to `.claude/skills/verified-change/` for worktree and Desktop visibility.
- Added `scripts/verify.sh` as the agentics dogfood copy (byte-identical to the plugin's `assets/verify.sh`).
- Added `tests/fixtures/verify-gate-bare/` and `tests/fixtures/verify-gate-failing/` and `tests/test-verify-gate.sh`.
- Added `tests/plugins/test-verified-change-skill.sh` asserting parity between the plugin copy, project-local copy, and `scripts/verify.sh`.
- Bumped `code-testing-agent` from 3.5.2 to 3.6.0 and added the merge-gate rule to `CLAUDE.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` | Portable gate template | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Skill instructions | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` | Mutation catalogue and restore protocol | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` | Filled VERIFICATION example | Created |
| `kit/plugins/code-testing-agent/bin/install-verify-gate` | Gate installer wrapper | Created |
| `scripts/verify.sh` | Agentics dogfood copy | Created |
| `.claude/skills/verified-change/` | Project-local copy (whole directory) | Created |
| `tests/fixtures/verify-gate-bare/` | No-toolchain fixture | Created |
| `tests/fixtures/verify-gate-failing/` | Failing-unit fixture | Created |
| `tests/test-verify-gate.sh` | Gate objective test | Created |
| `tests/plugins/test-verified-change-skill.sh` | Skill structure and parity test | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | Guard registration | Modified |
| `kit/plugins/code-testing-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `CLAUDE.md` | Merge-gate rule | Modified |

## How it works

`scripts/verify.sh` auto-detects stages relative to `$PWD`, never relative to `$0`. Detection of typecheck (tsconfig), lint (eslint config, .shellcheckrc), unit (package.json test, tests/run-all.sh), and e2e (playwright config) is PWD-relative to prevent a gate invoked from a fixture from re-entering the agentics suite. A `VERIFY_GATE_ACTIVE` environment marker blocks re-entry, and `set -euo pipefail` with a hard exit on re-entry ensures the gate terminates rather than recursing. The marketplace stages (run-all.sh, version guard, README freshness) run only when `.claude-plugin/marketplace.json` is detected in `$PWD`.

The `verified-change` skill closes the test-quality gap: a test written after the implementation can pass for the wrong reason. The mutation protocol copies the target file to the scratchpad, mutates it in place, runs the scoped test (expecting failure), restores from the copy under a `trap` that fires on any exit path, then proves restoration with `cmp -s` — not `git diff --quiet`, which is vacuous for untracked files. After restore, the scratchpad copy is deleted.

Parity between the three copies of the gate (`assets/verify.sh`, `scripts/verify.sh`, `.claude/skills/verified-change/assets/verify.sh`) is enforced by `tests/plugins/test-verified-change-skill.sh`, making a silently forked copy impossible to ship.

## How to use it

```bash
bash scripts/verify.sh
```

Run from the repo root before proposing a merge. The gate exits 0 when every detected stage passes; exits non-zero at the first failure, naming the stage.

```
/code-testing-agent:verified-change
```

Activated by description match. Guides through the full mutation-check loop and runs the gate at the end. Use for changes to working code (as opposed to `tdd-loop`, which is for new features).

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `fd41fec1` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
