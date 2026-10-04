# Prove merge readiness locally, without GitHub Actions

> Ships a portable `verify.sh` merge gate and a `verified-change` skill that enforces test-first, mutation-checked changes — then dogfoods both into the agentics repo so no change is proposed for merge without local proof.

<!-- generated:start -->

**Status:** Shipped 2026-08-22  **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Added `scripts/verify.sh` — a portable, auto-detecting merge gate that runs typecheck, lint, unit, and e2e stages in order, printing either a real result or `SKIP (not configured)` per stage, and failing fast on the first real failure.
- Added `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` — byte-identical to `scripts/verify.sh`, held in lockstep by a parity test.
- Added `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` — a six-step loop: write the test, mutation-check it, restore, implement, iterate up to 8 attempts, then stop and report.
- Added `kit/plugins/code-testing-agent/bin/install-verify-gate` — an executable wrapper that copies the gate into a target repo, since `${CLAUDE_PLUGIN_ROOT}` in a documented Bash command is unrunnable by Claude Code's Bash tool.
- Added `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` — mutation catalogue and safe restore protocol using `cmp -s` against a scratchpad copy under a `trap` that restores on any exit.
- Added `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` — a filled VERIFICATION section example with real commands and exit statuses.
- Added `.claude/skills/verified-change/` — project-local copy of the skill directory (SKILL.md and both references files), byte-identical to the plugin copy.
- Added `tests/test-verify-gate.sh` — objective test asserting skip behavior, stage ordering, and fail-fast exit codes.
- Added `tests/plugins/test-verified-change-skill.sh` — skill structure, description budget, plan-mode guard, and copy parity assertions.
- Added `tests/fixtures/verify-gate-bare/` and `tests/fixtures/verify-gate-failing/` — runnable project fixtures for the gate tests.
- Bumped `code-testing-agent` from `3.5.2` to `3.6.0` in `.claude-plugin/marketplace.json`; added skill to plugin README and CHANGELOG.
- Added the merge-gate rule to `CLAUDE.md`: merging is never proposed until `bash scripts/verify.sh` exits 0 locally and the PR body's VERIFICATION section is filled in.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/verify.sh` | Local merge gate | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Skill instructions | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` | Gate template | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` | Mutation protocol reference | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` | Filled VERIFICATION example | Created |
| `kit/plugins/code-testing-agent/bin/install-verify-gate` | Installation wrapper | Created |
| `.claude/skills/verified-change/SKILL.md` | Project-local skill copy | Created |
| `tests/test-verify-gate.sh` | Objective smoke test | Created |
| `tests/plugins/test-verified-change-skill.sh` | Skill structure test | Created |
| `tests/fixtures/verify-gate-bare/.gitkeep` | Bare project fixture | Created |
| `tests/fixtures/verify-gate-bare/README.md` | Bare project fixture | Created |
| `tests/fixtures/verify-gate-failing/.gitkeep` | Failing project fixture | Created |
| `tests/fixtures/verify-gate-failing/README.md` | Failing project fixture | Created |
| `tests/fixtures/verify-gate-failing/package.json` | Failing unit stage | Created |
| `tests/fixtures/README.md` | Fixture documentation | Modified |
| `tests/plugins/test-exitplanmode-guard.sh` | Skill guard registry | Modified |
| `kit/plugins/code-testing-agent/README.md` | Plugin README | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | Changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `README.md` | Root plugin reference table | Modified |
| `CLAUDE.md` | Merge gate rule | Modified |

## How it works

GitHub Actions is frequently billing-blocked on this account, meaning CI results are unreliable evidence of correctness. The gate addresses this by making merge readiness provable on the local machine.

`scripts/verify.sh` opens with `set -euo pipefail` and detects its own toolchain against `$PWD` — never against `$(dirname "$0")`. This distinction matters: a gate that resolved roots from `$0` would, when invoked from inside `tests/fixtures/verify-gate-bare/`, still find agentics' `.claude-plugin/marketplace.json`, re-enter `tests/run-all.sh`, and recurse indefinitely. The `VERIFY_GATE_ACTIVE` environment marker hard-exits on re-entry. Stage detection is auto-detecting: typecheck runs if a `tsconfig.json` exists, lint if an ESLint config exists, unit if a `package.json test` script exists, e2e if a Playwright config exists. When `.claude-plugin/marketplace.json` is present, three additional marketplace stages run. Every absent stage prints `SKIP (not configured)` and the gate continues; every present stage that fails stops the gate immediately.

The `verified-change` skill wraps the gate with a mutation-check discipline. The six-step loop: write the test (RED), mutate the implementation to verify the test catches a real failure, restore from a scratchpad copy (never `git stash`, never `git checkout --`, which would destroy untracked files), implement the change, run the gate iterating up to 8 attempts, then report. The restore proof uses `cmp -s` against the scratchpad copy under a `trap` that runs on any exit including interrupt. `git diff --quiet` is explicitly forbidden as the restore check because the files this plan creates are untracked until committed, and `git diff` silently passes on untracked files.

Two deliberate duplicates are managed by parity tests rather than generation: `scripts/verify.sh` is byte-identical to `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh`, and `.claude/skills/verified-change/` is byte-identical to `kit/plugins/code-testing-agent/skills/verified-change/`. The project-local copy serves worktrees pinned to older plugin versions and Desktop, where plugin snapshots lag. `tests/plugins/test-verified-change-skill.sh` fails if either copy drifts.

The two test fixtures are named to avoid being picked up by `tests/run-all.sh`'s `find tests -name 'test-*.sh'` discovery (no file in either fixture matches `test-*.sh`, `test-*.mjs`, or `*.test.mjs`). The bare fixture exercises every SKIP path; the failing fixture exercises fail-fast exit behavior.

## How to use it

Run the gate from the repo root before proposing a merge:

```bash
bash scripts/verify.sh
```

It will print an explicit result or `SKIP (not configured)` for every stage and exit 0 only when all present stages pass.

Install the gate in any other repo:

```bash
/code-testing-agent:install-verify-gate
```

Or use the `verified-change` skill to run a mutation-checked change cycle:

```text
/code-testing-agent:verified-change
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |
| `0818be0` | 2026-08-21 | docs(plans): plan a local merge gate independent of GitHub Actions (#592) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
