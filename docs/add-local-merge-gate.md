# Prove merge readiness locally, without GitHub Actions

> Ships a portable `verify.sh` merge gate and a `verified-change` skill that enforces test-first, mutation-checked changes — because billing-blocked CI is not evidence of correctness.

<!-- generated:start -->

**Status:** Shipped 2026-08-21  **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Added `scripts/verify.sh` — a portable auto-detecting gate that runs typecheck, lint, unit (via `tests/run-all.sh`), and e2e in order, skipping each stage when its tooling is absent, failing fast on the first real failure.
- Added `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` — the canonical gate template, byte-identical to the repo copy.
- Added `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` — a six-step loop: write the test, mutation-check it, restore, implement, iterate on `scripts/verify.sh`, then report the failing assertion rather than success.
- Added `references/mutation-check.md` — mutation catalogue with `cmp -s` restore protocol, `trap` for interrupt safety, and scratchpad cleanup.
- Added `references/verification-section.md` — one filled VERIFICATION section as a worked example.
- Added `kit/plugins/code-testing-agent/bin/install-verify-gate` — executable wrapper to copy the gate into any repo (bypasses `${CLAUDE_PLUGIN_ROOT}` shell-expansion limitation).
- Copied the entire skill directory to `.claude/skills/verified-change/` for worktree and Desktop visibility; parity tests keep both copies byte-identical.
- Added `tests/test-verify-gate.sh` and `tests/plugins/test-verified-change-skill.sh`.
- Bumped `code-testing-agent` to `3.6.0`; added merge-gate rule to `CLAUDE.md`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `scripts/verify.sh` | Repo merge gate | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` | Gate template | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Skill instructions | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` | Mutation protocol | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` | Worked example | Created |
| `kit/plugins/code-testing-agent/bin/install-verify-gate` | Install wrapper | Created |
| `.claude/skills/verified-change/` | Project-local copy | Created |
| `tests/test-verify-gate.sh` | Gate smoke test | Created |
| `tests/plugins/test-verified-change-skill.sh` | Skill structure test | Created |
| `tests/fixtures/verify-gate-bare/` | No-toolchain fixture | Created |
| `tests/fixtures/verify-gate-failing/` | Failing-unit fixture | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `CLAUDE.md` | Merge gate rule | Modified |

## How it works

The gate auto-detects stage tooling at runtime relative to `$PWD` (never `$0`), so the same script serves this repo and any other without a generator. A `VERIFY_GATE_ACTIVE` marker prevents re-entry when `tests/run-all.sh` invokes the gate from inside a fixture. Stages print `SKIP (not configured)` for absent tooling and `FAIL` for the first real failure, with no later stages running.

The mutation check in `verified-change` uses `cmp -s` against a scratchpad copy to prove restoration — `git diff --quiet` would silently pass on untracked files (like a newly created `scripts/verify.sh`). A `trap` restores the file on any exit path including interrupt, and the scratchpad copy is deleted after a proven restore.

The three marketplace stages (marketplace validation, version guard, README freshness) run when `.claude-plugin/marketplace.json` is detected, making the gate specific enough for this repo while remaining portable — detection is the extension point.

## How to use it

Run `bash scripts/verify.sh` from the repo root before any merge. Use `kit/plugins/code-testing-agent/bin/install-verify-gate` to copy the gate into other repos. Invoke `/code-testing-agent:verified-change` when making a change to working code (as opposed to `tdd-loop`, which is for new features where red is free).

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |
| `0818be0` | 2026-08-21 | docs(plans): plan a local merge gate independent of GitHub Actions (#592) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
