# Prove merge readiness locally, without GitHub Actions

> Ships a portable `scripts/verify.sh` merge gate and a `verified-change` skill that enforces test-first, mutation-checked changes — dogfooded into the agentics repo so no change is proposed for merge without local proof.

<!-- generated:start -->

**Status:** Shipped 2026-08-22 **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Created `scripts/verify.sh` — an auto-detecting portable merge gate that runs typecheck, lint, unit, and e2e stages in order, printing `SKIP (not configured)` for any absent tooling and exiting non-zero at the first real failure.
- Added `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` — a six-step skill that writes the test first, mutation-checks it, then loops against `scripts/verify.sh` up to 8 attempts before reporting failure.
- Added `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` — the plugin's copy of the gate (byte-identical to `scripts/verify.sh`), held in sync by a parity test.
- Added `kit/plugins/code-testing-agent/bin/install-verify-gate` — an executable wrapper that copies `assets/verify.sh` into any target repo's `scripts/`, since `${CLAUDE_PLUGIN_ROOT}` in a documented Bash command is unrunnable.
- Copied the full `verified-change` skill directory to `.claude/skills/verified-change/` for use in worktrees pinned to older plugin versions and in Desktop.
- Added `references/mutation-check.md` — mutation catalogue and safe break-and-restore protocol using `cmp -s` and a shell `trap`.
- Added `references/verification-section.md` — a filled VERIFICATION example (not a bracket-placeholder schema).
- Created `tests/fixtures/verify-gate-bare/` and `tests/fixtures/verify-gate-failing/` — fixture projects for testing gate behavior.
- Added `tests/test-verify-gate.sh` and `tests/plugins/test-verified-change-skill.sh` — objective and parity tests.
- Added the merge-gate rule to `CLAUDE.md`: merging is never proposed until `bash scripts/verify.sh` exits 0 and the PR body's VERIFICATION section is filled.
- Bumped `code-testing-agent` from 3.5.2 to 3.6.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/verify.sh` | Agentics dogfood copy of the gate | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Six-step verified-change loop | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` | Plugin copy of the gate template | Created |
| `kit/plugins/code-testing-agent/bin/install-verify-gate` | Gate installer wrapper | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` | Mutation catalogue and restore protocol | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` | Filled VERIFICATION example | Created |
| `.claude/skills/verified-change/` | Project-local skill copy (full directory) | Created |
| `tests/fixtures/verify-gate-bare/` | No-toolchain fixture (exercises SKIP paths) | Created |
| `tests/fixtures/verify-gate-failing/` | Failing-unit fixture (exercises fail-fast) | Created |
| `tests/test-verify-gate.sh` | Objective gate test | Created |
| `tests/plugins/test-verified-change-skill.sh` | Skill structure and parity test | Created |
| `CLAUDE.md` | Merge-gate rule added | Modified |
| `.claude-plugin/marketplace.json` | code-testing-agent bumped to 3.6.0 | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | 3.6.0 entry | Modified |
| `kit/plugins/code-testing-agent/README.md` | New skill documented | Modified |

## How it works

**The gate is auto-detecting, not generated.** `scripts/verify.sh` resolves every stage against `$PWD` rather than `$0`. It runs typecheck (tsconfig present), lint (ESLint config or `.shellcheckrc`), unit (`package.json` test script or `tests/run-all.sh`), and e2e (Playwright config), printing either a result or `SKIP (not configured)` for each. For repos with `.claude-plugin/marketplace.json` it also runs marketplace validation, the plugin version guard, and README table freshness as additional stages.

**Re-entry guard prevents recursion.** The gate exports `VERIFY_GATE_ACTIVE=1` on entry and hard-exits with a named error if it is already set. This is load-bearing: the objective test invokes the gate inside a fixture, and that fixture's detection would otherwise find agentics' own `marketplace.json` and re-enter `tests/run-all.sh` — unbounded recursion. The test clears the marker with `env -u VERIFY_GATE_ACTIVE` for its own invocation.

**Byte-identical duplicates are the distribution mechanism.** `scripts/verify.sh` and `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` are deliberately identical. `tests/plugins/test-verified-change-skill.sh` fails the build if they diverge. The same parity test covers the project-local copy in `.claude/skills/verified-change/`.

**The mutation check closes the "test written after the fact" gap.** The `verified-change` skill requires copying the target file to a scratchpad, installing a `trap` to restore on any exit including interrupt, mutating the implementation, confirming the test goes red, restoring from the copy, and proving restoration with `cmp -s` — not `git diff --quiet`, which ignores untracked files and would pass vacuously on a file this plan itself created.

**The VERIFICATION section is written evidence.** The skill emits a filled VERIFICATION section with every gate's real result, the mutation applied, its observed failure output, and screenshot paths for UI changes.

## How to use it

Install the gate in any repo:
```bash
install-verify-gate        # if loaded as the code-testing-agent plugin
# or
bash .claude/skills/verified-change/assets/install-verify-gate.sh
```

Run the gate:
```bash
bash scripts/verify.sh
```

Use the skill for a change to working code:
```
/code-testing-agent:verified-change
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |
| `0818be0` | 2026-08-21 | docs(plans): plan a local merge gate independent of GitHub Actions (#592) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
