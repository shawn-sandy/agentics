# Make the commit lint gate trustworthy in every repo it lands in

> Fixes four defects in git-agent's `lint-before-commit.py` hook: it now blocks only on newly-introduced failures, resolves the nearest package in a monorepo, recognises Python/Go/Rust projects, and registers its hook correctly.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Rewrote `kit/plugins/git-agent/hooks/lint-before-commit.py` with four substantive changes:
  - **Nearest-package resolution**: walks up from the commit's cwd to the git root and uses the first directory whose manifest declares a matching lint or typecheck script, so a commit from `sub/pkg/` lints `sub/pkg/` rather than the repository root.
  - **Ecosystem detection**: adds built-in support for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), reusing the same nearest-manifest walk with the same exit-127 and missing-toolchain guards as the Node path.
  - **Config override**: a `.claude/lint-gate.json` file at the repo root names the project's own check commands and, when present, replaces built-in detection entirely.
  - **Index-versus-HEAD comparison**: materialises two detached worktrees (one at HEAD, one at the staged index), symlinks the host repo's dependency directory into both, runs the resolved check in each, normalises both outputs to digit-masked path-stripped line sets, and blocks only on records present in the index run and absent at HEAD. Falls back to whole-project blocking when worktrees cannot be created.
- Added `"hooks": "./hooks.json"` to the `.claude-plugin/plugin.json` of `git-agent`, `plan-agent`, and `skill-reviewer` (not `plan-interview`, which had been folded into `plan-agent` 4.0.0). This was the root cause of all hooks never running: the conventional auto-discovered path is `hooks/hooks.json`, not `hooks.json` at the plugin root, so zero hooks had ever fired for installed users.
- Raised the hook timeout in `kit/plugins/git-agent/hooks.json` from 200s to 480s to cover two lint runs (primary + baseline) plus worktree materialisation.
- Extended `tests/plugins/test-lint-before-commit.sh` with new sections covering nearest-package resolution, each new ecosystem, the config override, baseline pass and block, and the baseline-unavailable fallback, keeping all 38 prior checks passing and raising the total above 38.
- Bumped `git-agent` to 4.14.0 and `plan-agent` and `skill-reviewer` by a patch level in `.claude-plugin/marketplace.json`.
- Documented the ecosystems, config file, and baseline behaviour in `kit/plugins/git-agent/README.md` and added CHANGELOG entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | Nearest-package resolution, ecosystem detection, config override, baseline comparison | Modified |
| `kit/plugins/git-agent/hooks.json` | Hook timeout raised to 480s | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Explicit `"hooks": "./hooks.json"` key added | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | Explicit `"hooks": "./hooks.json"` key added | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | Explicit `"hooks": "./hooks.json"` key added | Modified |
| `.claude-plugin/marketplace.json` | Version bumps for three plugins | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.14.0 gate-rewrite entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Hook-registration fix entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Hook-registration fix entry | Modified |
| `kit/plugins/git-agent/README.md` | Ecosystem, config file, and baseline behaviour documented | Modified |
| `tests/plugins/test-lint-before-commit.sh` | New sections for all four fixes; all prior checks kept | Modified |

## How it works

The hook registration fix is the most impactful change, because the lint gate had never fired for any installed user on any surface before this PR. A controlled A/B proved it: identical deliberately-corrupt JSON placed at `hooks/hooks.json` (the auto-discovered path) caused `claude plugin validate` to reject the plugin with "Invalid JSON syntax"; the same file at `hooks.json` (the actual location) was silently accepted. The fix is a single `"hooks": "./hooks.json"` key in each manifest. The result was verified without a desktop restart using `claude plugin details git-agent`: before the fix the component inventory read `Hooks (0)`; after it read `Hooks (2)  UserPromptSubmit, PreToolUse`.

The baseline comparison addresses the pre-existing-failures problem. A repo with 40 pre-existing lint errors blocked every commit until the errors were fixed or a `.claude/no-lint-gate` opt-out was created. The fix materialises two detached worktrees — one at HEAD using `git archive`, one containing the staged index — and compares their lint output sets. A record is "new" only when it appears in the index run but not at HEAD. Both outputs are normalised (digit-masking, path-stripping, multiset comparison) to survive linter output variation. The HEAD worktree symlinks the host's dependency directory to avoid missing-binary failures; if that symlink fails the hook degrades to whole-project blocking rather than silently passing.

Output normalisation was resolved without per-tool JSON formats: lines are digit-masked and path-stripped before being compared as multisets. A record is new only when its count rises between HEAD and the staged index. This works across eslint, ruff, go vet, and cargo clippy output formats without injecting format flags or parsing JSON.

The completion report notes that `plan-interview` was not edited — the plugin had been merged into `plan-agent` 4.0.0 and is no longer in the marketplace.

A follow-on fix (`e77d957`, 2026-09-02) stopped a real `ruff` installation from shadowing the `flake8` fallback test case.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `e77d957` | 2026-09-02 | test(git-agent): stop a real ruff shadowing the flake8 fallback case (#616) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
