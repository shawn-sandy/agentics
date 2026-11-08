# Make the commit lint gate trustworthy in every repo it lands in

> Fixes four defects in git-agent's `lint-before-commit.py` gate: pre-existing failures blocking unrelated commits, monorepos linting the wrong package, non-Node projects getting no gate, and the hook never registering at all.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- **Hook registration**: Added the explicit `"hooks": "./hooks.json"` key to `plugin.json` for git-agent, plan-agent, and skill-reviewer. A controlled A/B on the installed plugin confirmed the root-path `hooks.json` was never read (`Hooks (0)` → `Hooks (2)` after the manifest key).
- **Baseline comparison**: `lint-before-commit.py` now materializes two detached worktrees — one at HEAD, one at the staged index — symlinks the host repo's dependency directory into both, runs the resolved check in each, normalizes both outputs to `file:line:message` multisets, and blocks only on records present in the index run and absent at HEAD. Falls back to whole-project blocking when the baseline is unavailable.
- **Nearest-package resolution**: The hook walks up from the commit's cwd to the git root and uses the first directory whose `package.json` declares a matching script, never the root unconditionally.
- **Ecosystem detection**: Built-in detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), each with the same exit-127 and missing-toolchain guards as the Node path.
- **Config override**: `.claude/lint-gate.json` replaces built-in detection entirely when present (config wins outright).
- **Timeout rebudget**: `hooks.json` timeout raised from 200s to 480s to accommodate two checks (primary + baseline) with a 30s materialization margin.
- Extended `tests/plugins/test-lint-before-commit.sh` from 38 to 50+ checks covering all four fixes.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | Gate rewrite: nearest-package, ecosystems, config, baseline | Modified |
| `kit/plugins/git-agent/hooks.json` | Timeout raised to 480s | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Explicit `"hooks"` key | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | Explicit `"hooks"` key | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | Explicit `"hooks"` key | Modified |
| `.claude-plugin/marketplace.json` | Version bumps for three plugins | Modified |
| `tests/plugins/test-lint-before-commit.sh` | Extended to 50+ checks | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.14.0 gate-rewrite entry | Modified |

## How it works

The hook registration defect was the root cause for all users: the conventional auto-discovered path is `hooks/hooks.json` (inside the plugin's `hooks/` directory), not `hooks.json` at the plugin root. All three affected plugins declared their hooks at the root path. Adding `"hooks": "./hooks.json"` to each `plugin.json` activates the manifest-resolution path, which reads the declared path regardless of convention.

Baseline comparison solves the pre-existing-failure problem without requiring per-linter format knowledge. Output normalization uses digit masking and path stripping to produce comparable line sets; a failure is "new" only when its count rises from HEAD to the staged index. The fallback direction — unavailable baseline degrades to whole-project blocking rather than passing — ensures the gate never silently passes a real failure. Unstaged edits are excluded from the check because both sides are materialized from git state (HEAD and the staged index), not the working tree.

Nearest-package resolution walks from the commit cwd to the git root using `git rev-parse --show-toplevel` as the ceiling. The first directory whose manifest declares a `scripts.lint` or `scripts.typecheck` wins; the walk does not escape the repository.

Output normalization resolves the two open questions from the plan: per-tool JSON format flags were not injected (the host script may wrap the tool); instead, records are digit-masked and path-stripped before comparison as multisets.

> See [CHANGELOG v4.14.0](../kit/plugins/git-agent/CHANGELOG.md) for the authoritative feature list.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e77d957` | 2026-09-02 | test(git-agent): stop a real ruff shadowing the flake8 fallback case (#616) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
- Related: [kit/plugins/git-agent/CHANGELOG.md](../kit/plugins/git-agent/CHANGELOG.md)
- Related: [kit/plugins/git-agent/hooks/lint-before-commit.py](../kit/plugins/git-agent/hooks/lint-before-commit.py)
