# Make the commit lint gate trustworthy in every repo it lands in

> Fixes four defects in git-agent's `lint-before-commit.py`: blocks only on newly-introduced failures (baseline comparison), resolves the nearest package in a monorepo, recognizes Python/Go/Rust projects, and registers its hook via a manifest key that was never present.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [fix-lint-gate-defects](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- **Nearest-package resolution**: the hook now walks up from the commit's cwd to the git root and lints the first directory whose manifest declares a matching script — fixing monorepos that were silently linting the root instead of the touched package
- **Ecosystem detection**: built-in support for `pyproject.toml` (ruff/flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), with the same could-not-run guards as the Node path
- **Config override**: `.claude/lint-gate.json` replaces built-in detection entirely when present
- **Baseline comparison**: two detached worktrees (HEAD and the staged index) let the gate block only on lint failures introduced by the current commit, not pre-existing ones
- **Hook registration fix**: added explicit `"hooks"` key to `plugin.json` for git-agent, plan-agent, and skill-reviewer — the gate had never run for any installed user
- Extended `tests/plugins/test-lint-before-commit.sh` to cover all four fixes; total check count rose above 38
- Bumped `git-agent` to 4.14.0; patch bumps for plan-agent and skill-reviewer

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | Hook — gate rewrite | Modified |
| `kit/plugins/git-agent/hooks.json` | Hook timeout raised for baseline run | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Manifest — explicit `hooks` key | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | Manifest — explicit `hooks` key | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | Manifest — explicit `hooks` key | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — version bumps | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs — ecosystems, config, baseline | Modified |
| `tests/plugins/test-lint-before-commit.sh` | Smoke test — all four defect fixes | Modified |

## How it works

All four defects were measured directly in session — none inferred.

**Hook registration** was the root cause of the gate never running at all. A controlled A/B showed that the `hooks.json` at the plugin root was never read; only `hooks/hooks.json` is auto-discovered. Adding `"hooks": "./hooks.json"` to each plugin's manifest moves the count from `Hooks (0)` to `Hooks (2)` as reported by `claude plugin details`.

**Pre-existing failures** blocked unrelated commits because the hook ran the host repo's full lint on the working tree. The fix materializes two detached worktrees — one at HEAD, one at the staged index — symlinks the host's dependency directory into both, runs the check in each, and blocks only on records present in the index run but absent at HEAD. When the baseline worktree cannot be created, the gate falls back to whole-project blocking rather than silently passing.

**Monorepo linting** was fixed by walking from the commit's cwd up to the git root and using the first directory whose `package.json` (or ecosystem manifest) declares a matching script. The walk stops at the git root and never escapes to a parent directory.

**Non-Node ecosystems** are detected from `pyproject.toml`, `go.mod`, and `Cargo.toml`. A `.claude/lint-gate.json` config file overrides all built-in detection when present, covering stacks not handled natively. Every could-not-run path — missing deps, exit 127, timeout, unusable baseline — either exits 0 or falls back to whole-project blocking.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects](plans/fix-lint-gate-defects.md)
