# Prove merge readiness locally, without GitHub Actions

> Ships a portable `verify.sh` merge gate and a `verified-change` skill that enforces test-first, mutation-checked changes — dogfooded into the agentics repo so no change is proposed for merge without local proof.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- `scripts/verify.sh` — portable merge gate that auto-detects typecheck, lint, unit, and e2e stages in `$PWD` order, prints `SKIP (not configured)` for absent stages, exits non-zero at the first real failure without running later stages; re-entry marker (`VERIFY_GATE_ACTIVE`) prevents unbounded recursion when invoked from inside a fixture
- `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` — the plugin's byte-identical template of the above
- `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` — six-step verified-change loop: write test → mutation-check it → restore → implement → iterate on `scripts/verify.sh` (up to 8 attempts) → report with the failing assertion and last diff tried
- `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` — mutation catalogue and safe restore protocol using `cmp -s` against a scratchpad copy (not `git diff --quiet`, which is vacuous for untracked files)
- `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` — one filled VERIFICATION example (not a bracket-placeholder schema)
- `kit/plugins/code-testing-agent/bin/install-verify-gate` — executable wrapper that copies `assets/verify.sh` into a target repo (solves the `${CLAUDE_PLUGIN_ROOT}` expansion problem in Bash tool)
- `.claude/skills/verified-change/` — project-local copy of SKILL.md and both references files; parity-tested as a directory with `diff -r`
- `tests/fixtures/verify-gate-bare/` and `tests/fixtures/verify-gate-failing/` — test fixtures; named to avoid auto-discovery by `tests/run-all.sh`
- `tests/test-verify-gate.sh` — objective test: skip ordering, fail-fast, re-entry termination
- `tests/plugins/test-verified-change-skill.sh` — skill structure, parity assertions, CLAUDE.md rule check
- `code-testing-agent` bumped to `3.6.0` in `.claude-plugin/marketplace.json`
- Merge-gate rule added to `CLAUDE.md`: merging is not proposed until `bash scripts/verify.sh` exits 0 and VERIFICATION is filled in

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/verify.sh` | Merge gate — auto-detecting, portable, re-entry-safe | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | Skill instructions — six-step verified-change loop | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` | Gate template — byte-identical to scripts/verify.sh | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` | Reference — catalogue and cmp-s restore protocol | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` | Reference — filled VERIFICATION example | Created |
| `kit/plugins/code-testing-agent/bin/install-verify-gate` | Wrapper — copies assets/verify.sh without ${...} expansion | Created |
| `.claude/skills/verified-change/` | Project-local copy — SKILL.md + both references, parity-tested | Created |
| `tests/test-verify-gate.sh` | Objective test — skip order, fail-fast, re-entry | Created |
| `tests/plugins/test-verified-change-skill.sh` | Skill test — structure, parity, CLAUDE.md rule | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — code-testing-agent 3.6.0 | Modified |
| `CLAUDE.md` | Project rules — merge-gate rule added | Modified |

## How it works

The gate resolves every stage detection against `$PWD`, not `$(dirname "$0")`. This is what allows the same file to serve agentics (which has `.claude-plugin/marketplace.json`) and a Vite app (which has `package.json`) without a generator. It also prevents the recursion bug: a gate that resolved from `$0` would, when invoked from inside `tests/fixtures/verify-gate-bare/`, still find agentics' marketplace.json, re-enter `tests/run-all.sh`, re-run `test-verify-gate.sh`, and re-invoke the gate. The `VERIFY_GATE_ACTIVE` marker is a belt-and-braces guard that hard-exits non-zero on re-entry regardless of path resolution.

The mutation-check protocol in `references/mutation-check.md` uses `cmp -s` against a scratchpad copy, not `git diff --quiet`. The critical reason: `scripts/verify.sh` is a new file and is untracked until committed, so `git diff` would report clean over an unrestored mutation. The scratchpad copy is deleted after a proven restore; a `trap` restores on any exit path including interrupt.

The `install-verify-gate` wrapper exists because seven other plugins in this marketplace already encountered the same problem: `${CLAUDE_PLUGIN_ROOT}` in a documented `Bash` command is unrunnable, because the Bash tool rejects any command containing `${...}` expansion before permission rules are consulted.

The project-local copy at `.claude/skills/verified-change/` serves worktrees (which pin older plugin versions) and Desktop sessions (which load frozen claude.ai snapshots). The copy includes both `references/` files, not just `SKILL.md`, because the references are linked from SKILL.md and both dangling paths defeat the reason for having the local copy.

## How to use it

```bash
bash scripts/verify.sh                   # run the merge gate from the repo root
```

Output: one result or `SKIP (not configured)` per stage (typecheck → lint → unit → e2e), plus three marketplace stages when `.claude-plugin/marketplace.json` is detected. Exits non-zero at the first real failure.

To install in another repo:

```bash
kit/plugins/code-testing-agent/bin/install-verify-gate
```

The `verified-change` skill activates when making changes to existing working code:

```
/code-testing-agent:verified-change     # run the verified-change loop
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
