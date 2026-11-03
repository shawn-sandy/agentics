# Make the commit lint gate trustworthy in every repo it lands in

> Fix four defects in git-agent's `lint-before-commit.py`: pre-existing failures blocked unrelated commits, monorepos linted the wrong package, non-Node projects got no gate at all, and the hook never registered for any user on any surface.

<!-- generated:start -->

**Status:** Shipped 2026-08-10 **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Rewrote `lint-before-commit.py` with nearest-package resolution, multi-ecosystem detection (Node/Python/Go/Rust), `.claude/lint-gate.json` config override, and index-vs-HEAD baseline comparison
- Raised the hook timeout in `hooks.json` from 200s to 480s to cover two lint runs plus worktree materialization
- Added explicit `"hooks": "./hooks.json"` key to the `plugin.json` manifests of `git-agent`, `plan-agent`, and `skill-reviewer` — the fix that makes hooks register at all
- Bumped `git-agent` to 4.14.0 and `plan-agent`, `skill-reviewer` by a patch level in `.claude-plugin/marketplace.json`
- Added CHANGELOG entries for all three plugins
- Documented ecosystems, the config file, and baseline behavior in the git-agent README
- Extended `tests/plugins/test-lint-before-commit.sh` from 38 checks to more than 38

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | Rewritten gate | Modified |
| `kit/plugins/git-agent/hooks.json` | Timeout raised to 480s | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | `hooks` key added | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | `hooks` key added | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | `hooks` key added | Modified |
| `.claude-plugin/marketplace.json` | Version bumps for three plugins | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.14.0 gate rewrite entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Patch entry for hook registration | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Patch entry for hook registration | Modified |
| `kit/plugins/git-agent/README.md` | Ecosystems, config file, baseline docs | Modified |
| `tests/plugins/test-lint-before-commit.sh` | Extended test suite | Modified |

## How it works

**Hook registration (the root cause for all users).** `git-agent`, `plan-agent`, and `skill-reviewer` kept `hooks.json` at the plugin root with no `hooks` key in `plugin.json`. The plugins reference documents exactly one auto-discovered path, `hooks/hooks.json`. A controlled A/B confirmed the root file is never opened: identical deliberately-corrupt JSON at `hooks.json` passes `claude plugin validate` without comment, while the same JSON at `hooks/hooks.json` produces an "Invalid JSON syntax" error. Adding `"hooks": "./hooks.json"` to the manifest changed `claude plugin details git-agent` from `Hooks (0)` to `Hooks (2)  UserPromptSubmit, PreToolUse`. The lint gate had never run for any installed user on any surface.

**Nearest-package resolution.** The previous implementation called `git rev-parse --show-toplevel` and read only the root `package.json`. A commit from `sub/pkg/` ran the root lint script and the nested package's own script never executed. The rewrite walks up from the payload's cwd to the git root and uses the first directory whose manifest declares a matching script, with the git root as the walk's hard ceiling.

**Multi-ecosystem detection.** Detection was `package.json` → `scripts.lint`, then `scripts.typecheck`. Python, Go, and Rust projects were silent no-ops. The rewrite adds built-in detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), each reusing the same nearest-manifest walk and could-not-run guards as the Node path. A `.claude/lint-gate.json` config override names the repo's own check commands and, when present, replaces built-in detection entirely.

**Index-vs-HEAD baseline comparison.** The previous gate ran the whole project lint and blocked on any non-zero exit, including failures the current commit did not introduce. The fix materializes two detached worktrees — one at HEAD, one at the staged index — symlinks the host repo's dependency directory into both, runs the resolved check in each, normalizes both outputs to digit-masked `file:line:message` multisets, and blocks only on records present in the index run and absent at HEAD. Unstaged edits do not affect the verdict. If worktrees cannot be created the gate falls back to whole-project blocking with a message, never silently passes.

The timeout budget was recalculated: 120s primary lint + 60s baseline lint + 30s worktree materialization = well inside the 480s hook timeout. A baseline timeout degrades to whole-project blocking.

`plan-interview` was not edited; it had already been folded into `plan-agent` 4.0.0 and is not in this marketplace. Three plugins were bumped rather than the four mentioned in the plan.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `e77d957` | 2026-09-02 | test(git-agent): stop a real ruff shadowing the flake8 fallback case (#616) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
