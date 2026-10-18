# Fix four defects in the lint-before-commit hook

> Patches `lint-before-commit.py` to fix pre-existing-failure blocking, wrong-package linting in monorepos, missing non-Node gate support, and the hook never registering due to a missing manifest key.

<!-- generated:start -->

**Status:** Shipped 2026-08-10  **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Patched `kit/plugins/git-agent/hooks/lint-before-commit.py` with four fixes:
  1. **Pre-existing failure baseline**: compares index state against HEAD in two detached worktrees with symlinked deps instead of running lint cold, so a pre-existing failure no longer blocks an unrelated commit.
  2. **Monorepo package resolution**: walks up from `cwd` to the git root to find the nearest `package.json`, ensuring the correct package is linted instead of the root.
  3. **Non-Node project support**: added detection for `pyproject.toml` (ruff then flake8), `go.mod` (go vet), and `Cargo.toml` (cargo clippy) so the gate fires on Python, Go, and Rust repos.
  4. **Hook registration**: added `"hooks": "./hooks.json"` to `git-agent`, `plan-agent`, and `skill-reviewer` `plugin.json` manifests — confirmed by A/B probe that root-level `hooks.json` is never read without the manifest key.
- Raised hook timeout from 200 s to 480 s; added `PER_CHECK_TIMEOUT` constant for the baseline budget.
- Extended `tests/plugins/test-lint-before-commit.sh` from 38+ to 50+ checks.
- Updated `README.md` with the corrected registration instructions.
- Bumped `git-agent` to `4.14.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | PreToolUse hook | Modified |
| `kit/plugins/git-agent/hooks/hooks.json` | Hook manifest | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `tests/plugins/test-lint-before-commit.sh` | Smoke test | Modified |

## How it works

**Pre-existing baseline**: the hook creates two temporary worktrees from the same commit, runs lint in the first (HEAD state), captures exit code and output, then runs lint in the second (with the index applied as a patch). A failure that appears in both runs is pre-existing and is silently ignored; a failure that appears only in the index run is reported as new.

**Monorepo walk**: starting from the process `cwd`, the hook walks parent directories until it finds a `package.json` with a `scripts.lint` field or reaches the git root. This ensures `packages/web/` lints against `packages/web/package.json`, not the root workspace manifest.

**Non-Node detection**: after the Node path fails (no `package.json` with a lint script), the hook checks for `pyproject.toml`, `go.mod`, and `Cargo.toml` in order. Each has a two-stage fallback (e.g., ruff then flake8 for Python) so the gate degrades gracefully when only one linter is installed.

**Registration probe**: the A/B probe placed a `hooks.json` at the repo root alongside a `plugin.json` without the `"hooks"` key, confirmed the hook never fired, then added the key and confirmed it fired. This established that the manifest key is required and the root-level file is not read by the runtime.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
