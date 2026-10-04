# Make the commit lint gate trustworthy in every repo it lands in

> The commit lint gate currently blocks on lint errors you did not cause, lints the wrong package in a monorepo, and ignores every non-Node project — and in the desktop app it never runs at all. This plan makes the gate block only on newly-introduced failures, resolve the nearest package, understand Python/Go/Rust, and actually register its hook.

<!-- generated:start -->

**Status:** Shipped 2026-08-10  **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Fixed hook registration by adding an explicit `"hooks": "./hooks.json"` key to the `.claude-plugin/plugin.json` of `git-agent`, `plan-agent`, and `skill-reviewer` — confirmed by a controlled A/B probe showing `Hooks (0)` → `Hooks (2)` in `claude plugin details`. The gate had never run for any installed user on any surface.
- Replaced root-only `package.json` lookup with nearest-package resolution: walks up from the commit's cwd to the git root and uses the first directory whose manifest declares a matching script, preventing a commit from `sub/pkg/` from running the root lint script.
- Added ecosystem detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), each with the same nearest-manifest walk and could-not-run guards (exit-127, missing toolchain).
- Added `.claude/lint-gate.json` config override: names the repo's own check commands and, when present, replaces built-in detection entirely.
- Implemented index-versus-HEAD comparison using two detached worktrees (one at HEAD, one at the staged index), with dependency-directory symlinking, output normalized to `file:line:message` records, blocking only on records new to the index run; falls back to whole-project blocking when baseline is unavailable.
- Extended `tests/plugins/test-lint-before-commit.sh` with sections for all four fixes, keeping all 38 existing checks passing and raising the total above 38.
- Bumped `git-agent` to 4.14.0, `plan-agent` and `skill-reviewer` by a patch level.
- Updated `git-agent/README.md` to document ecosystems, the config file, and baseline behavior.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | Gate rewrite: nearest-package, ecosystems, config, baseline | Modified |
| `kit/plugins/git-agent/hooks.json` | Timeout raised to 480s to cover baseline run | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Explicit `hooks` key added | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | Explicit `hooks` key added | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | Explicit `hooks` key added | Modified |
| `.claude-plugin/marketplace.json` | Version bumps for three plugins | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Gate rewrite entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Hook registration fix entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Hook registration fix entry | Modified |
| `kit/plugins/git-agent/README.md` | Ecosystems, config file, baseline behavior documented | Modified |
| `tests/plugins/test-lint-before-commit.sh` | Extended with four new fix sections | Modified |

## How it works

The root cause of the registration failure was determined by a controlled A/B probe: deliberately corrupt JSON placed at `hooks/hooks.json` (the conventional path in the official docs) caused `claude plugin validate` to report an error, while the same JSON at `hooks.json` at the plugin root passed without comment. The root path is simply never opened by the runtime. Adding `"hooks": "./hooks.json"` to each plugin's `plugin.json` manifest is the complete fix — confirmed by `claude plugin details git-agent` reporting `Hooks (2)  UserPromptSubmit, PreToolUse` versus the prior `Hooks (0)`.

The nearest-package fix replaces `git rev-parse --show-toplevel` plus a root `package.json` read with a directory walk. Starting from the commit payload's `cwd`, the walk climbs toward the git root and stops at the first directory containing a `package.json` with a `scripts.lint` entry. The git root is the hard ceiling, preventing the walk from escaping into a parent directory's unrelated manifest.

The ecosystem detection follows the same nearest-manifest walk for `pyproject.toml`, `go.mod`, and `Cargo.toml`. Each uses the same could-not-run guards: an exit 127 (binary not found) or a missing toolchain exits 0 rather than 2, so a fresh clone without all linters installed doesn't refuse every commit.

The index-versus-HEAD comparison addresses the most important correctness property: pre-existing failures should not block an unrelated commit. Both sides are materialized as detached worktrees — one at HEAD, one at the staged index — which also pins the comparison to what is being committed, not what happens to be on disk. The host repo's dependency directory is symlinked into both worktrees to prevent `node_modules`-missing failures from looking like pre-existing lint errors. Output from both runs is normalized to `file:line:message` multisets (digits masked, paths stripped relative to their roots), and the gate blocks only on records present in the index run and absent at HEAD. When the baseline worktree cannot be created — disk error, timeout, missing toolchain — the fallback is whole-project blocking with a message, never a silent pass.

The timeout budget was recalculated for two lint runs: 120s primary, 60s baseline, 30s materialization, fitting inside a `hooks.json` timeout raised from 200s to 480s.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
