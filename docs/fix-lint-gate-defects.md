# Make the commit lint gate trustworthy in every repo it lands in

> Fixes four defects in `git-agent`'s `lint-before-commit.py` hook: pre-existing failures blocking unrelated commits, monorepos linting the wrong package, non-Node projects getting no gate, and the hook never registering due to a manifest path issue.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Fixed hook registration: added `"hooks": "./hooks.json"` to `git-agent`, `plan-agent`, and `skill-reviewer` plugin manifests. Verified via A/B on the installed plugin (`Hooks (0)` → `Hooks (2)`). The lint gate had never run for any installed user on any surface.
- Added nearest-package resolution to `lint-before-commit.py`: walks up from the commit's `cwd` to the git root and uses the first directory whose manifest declares a matching script.
- Added built-in ecosystem detection for `pyproject.toml` (ruff then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), with the same nearest-manifest walk and exit-127 guards.
- Added `.claude/lint-gate.json` config override that replaces built-in detection entirely when present.
- Added index-versus-HEAD baseline comparison: two detached worktrees (one at HEAD, one at the staged index) with symlinked dependency directories; the gate blocks only on records present in the index run and absent at HEAD.
- Raised the hook timeout from 200s to 480s to cover two lint runs and their baselines.
- Extended `tests/plugins/test-lint-before-commit.sh` past 38 checks.
- Bumped git-agent to 4.14.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | Lint hook | Modified |
| `kit/plugins/git-agent/hooks.json` | Hook timeout | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Hooks manifest key | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | Hooks manifest key | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | Hooks manifest key | Modified |
| `.claude-plugin/marketplace.json` | Version bumps | Modified |
| `tests/plugins/test-lint-before-commit.sh` | Extended test suite | Modified |

## How it works

The most impactful fix was the manifest registration: `plugin.json` at the repo root is never auto-discovered; only `hooks/hooks.json` is. Adding `"hooks": "./hooks.json"` to each plugin's manifest was the only path to registration.

The baseline comparison is the conceptually hardest fix. A running hook cannot simply lint staged files by passing them as arguments — many linters ignore appended paths. Instead, the hook materializes two detached worktrees: one checked out at HEAD, one at the staged index. Both get the host repo's dependency directory symlinked in so lint doesn't fail on missing binaries. Each worktree runs the resolved check and outputs are normalized to sets of `file:line:message` records (digit-masked, path-stripped lines compared as a multiset). The gate fires only when a record appears in the index run and was absent at HEAD.

If the baseline worktree can't be created or the baseline lint fails with exit 127, the hook falls back to whole-project blocking (the pre-fix behavior) with an explanatory message — it never silently passes a real failure.

The nearest-package walk, ecosystem detection, and config override all use the same fast-path bail: the commit regex is checked before any filesystem probing, so a non-commit Bash call (like a shell command) never touches a manifest or spins up a worktree.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e77d957a` | 2026-09-02 | test(git-agent): stop a real ruff shadowing the flake8 fallback case (#616) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
