# Prove merge readiness locally, without GitHub Actions

> Ships a portable `scripts/verify.sh` merge gate and a `verified-change` skill that enforces test-first, mutation-checked changes — addressing the GitHub Actions billing-block problem where red CI proves nothing and green CI never arrives.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Created `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` — an auto-detecting, portable merge gate running typecheck → lint → unit → e2e in that order, printing `SKIP (not configured)` for absent stages, failing fast at the first real failure, and preventing re-entry via a `VERIFY_GATE_ACTIVE` marker.
- Created `scripts/verify.sh` — a byte-identical dogfood copy in the agentics repo, held in lockstep by a parity test.
- Created `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` — the six-step verified-change loop: write test, mutation-check it, restore, implement, iterate on the gate (8-attempt bound), report failing assertion and diff if still failing after the bound.
- Created `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` — mutation catalogue by change type and the `cmp -s`-based restore protocol with `trap` and scratchpad cleanup.
- Created `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` — a filled VERIFICATION section example (no placeholder brackets).
- Copied the full skill directory (SKILL.md + references/) to `.claude/skills/verified-change/` for worktree and Desktop visibility.
- Created `kit/plugins/code-testing-agent/skills/verified-change/assets/install-verify-gate.sh` and a `bin/` exec wrapper so the gate can be installed into any repo without `${CLAUDE_PLUGIN_ROOT}` expansion issues.
- Created test fixtures `tests/fixtures/verify-gate-bare/` and `tests/fixtures/verify-gate-failing/` (neither named `test-*.sh`/`test-*.mjs`/`*.test.mjs`, so `tests/run-all.sh` does not pick them up).
- Created `tests/test-verify-gate.sh` (skip ordering, fail-fast, re-entry termination) and `tests/plugins/test-verified-change-skill.sh` (frontmatter, parity, CLAUDE.md rule).
- Added the merge-gate rule to `CLAUDE.md`.
- Bumped `code-testing-agent` from `3.5.2` to `3.6.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Skill instructions — six-step verified-change loop | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` | Portable gate template | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/install-verify-gate.sh` | Installer for other repos | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` | Mutation catalogue and restore protocol | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` | Filled VERIFICATION example | Created |
| `scripts/verify.sh` | Agentics dogfood copy (parity-tested) | Created |
| `.claude/skills/verified-change/` | Project-local copy for worktrees and Desktop | Created |
| `tests/test-verify-gate.sh` | Gate objective test | Created |
| `tests/plugins/test-verified-change-skill.sh` | Skill structure and parity test | Created |
| `tests/fixtures/verify-gate-bare/` | No-toolchain fixture | Created |
| `tests/fixtures/verify-gate-failing/` | Failing-unit-stage fixture | Created |
| `.claude-plugin/marketplace.json` | code-testing-agent 3.6.0 | Modified |
| `CLAUDE.md` | Merge-gate rule | Modified |

## How it works

The core design decision is auto-detection instead of generation: `verify.sh` detects what a project has at runtime (`$PWD`-relative, never `$0`-relative) rather than being generated per-project. This means one file serves every project, but detection must be honest about what it skips — hence `SKIP (not configured)` rather than silent success.

The re-entry guard (`VERIFY_GATE_ACTIVE`) solves a subtle recursion: if the gate runs inside a fixture project and detects `tests/run-all.sh` as the unit stage, it would re-invoke `run-all.sh`, which would re-run `tests/test-verify-gate.sh`, which would re-invoke the gate. The `VERIFY_GATE_ACTIVE` marker hard-exits on re-entry. The objective test clears the marker with `env -u VERIFY_GATE_ACTIVE` for the one invocation that needs to prove re-entry is blocked.

The parity mechanism (deliberate byte-identical duplication) solves the distribution problem. `${CLAUDE_PLUGIN_ROOT}` in a documented Bash command is unrunnable — Claude Code's Bash tool rejects variable expansions before permission rules are consulted. The `bin/install-verify-gate` exec wrapper copies the gate without any `${...}` in the documented command. The same parity logic applies to the project-local SKILL.md copy: a `diff -r` parity test fails if either drifts.

The mutation-check protocol uses `cmp -s` against a scratchpad copy (with a `trap` for interrupt safety), explicitly not `git diff --quiet`. `scripts/verify.sh` is untracked until committed, so `git diff` would report clean over an unrestored mutation — the plan's completion report notes this was caught by the dogfood step.

## How to use it

`verified-change` is activated by its description in the `code-testing-agent` plugin. The gate is run directly:

```bash
bash scripts/verify.sh              # run the local merge gate in the current repo
```

To install it in another repo:
```bash
bash kit/plugins/code-testing-agent/skills/verified-change/assets/install-verify-gate.sh
# or via the bin wrapper
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
- Related: `kit/plugins/code-testing-agent/skills/tdd-loop/SKILL.md` — adjacent skill for new features
- Related: `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` — restore protocol
