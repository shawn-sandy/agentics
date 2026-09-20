# Make the commit lint gate trustworthy in every repo it lands in

> The commit lint gate currently blocks on lint errors you did not cause, lints the wrong package in a monorepo, and ignores every non-Node project — and in th...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Re-arm the A/B hook probe from `scratchpad/hook-probe.py` (git-agent as control with a `SessionStart` echo only, plan...
- Apply the probe's verdict — if only TREATMENT fired, add `"hooks": "./hooks.json"` to the `.claude-plugin/plugin.json...
- Replace the root-only `package.json` lookup with nearest-package resolution — walk up from the payload's cwd to the g...
- Add built-in ecosystem detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`ca...
- Add a `.claude/lint-gate.json` config override that names a repo's own check commands and, when present, replaces bui...
- Implement index-versus-HEAD comparison — materialize two detached worktrees, one at HEAD and one at the staged index,...
- Extend `tests/plugins/test-lint-before-commit.sh` with sections covering nearest-package resolution, each new ecosyst...
- Bump `git-agent` to 4.14.0 and `plan-agent`, `skill-reviewer`, `plan-interview` by a patch level in `.claude-plugin/m...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | nearest-package resolution, ecosystem detection, config o... | Modified |
| `kit/plugins/git-agent/hooks.json` | hook timeout raised to cover the baseline run | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | explicit `hooks` key | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | explicit `hooks` key | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | explicit `hooks` key | Modified |
| `.claude-plugin/marketplace.json` | version bumps for the three surviving plugins | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | entry for the hook-registration fix | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | entry for the hook-registration fix | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | entry for the gate rewrite | Modified |
| `kit/plugins/git-agent/README.md` | document ecosystems, config file, baseline behavior | Modified |
| `tests/plugins/test-lint-before-commit.sh` | new sections for all four fixes | Modified |

## How it works

Fix the four defects in git-agent's `lint-before-commit.py` gate so it blocks only on failures the current commit introduces, lints the package the commit actually touches, recognizes non-Node projects, and registers its hook in the Claude Code desktop app.

The gate ships as a `PreToolUse` hook on `Bash` and fires in every repo that installs git-agent, so each defect is an every-project defect rather than an agentics one. All four were measured this session, not inferred. **Pre-existing failures block unrelated commits.** The hook runs the host

The implementation proceeded through these steps: Re-arm the A/B hook probe from `scratchpad/hook-probe.py` (git-agent as control with a `SessionStart` echo only, plan...; Apply the probe's verdict — if only TREATMENT fired, add `"hooks": "./hooks.json"` to the `.claude-plugin/plugin.json...; Replace the root-only `package.json` lookup with nearest-package resolution — walk up from the payload's cwd to the g...; Add built-in ecosystem detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`ca...; Add a `.claude/lint-gate.json` config override that names a repo's own check commands and, when present, replaces bui....

- Hook registration — verified by a controlled A/B on the installed plugin (`Hooks (0)` → `Hooks (2)`), not by the planned desktop-restart probe, which is neither necessary nor valid for this defect - Steps 1 and 2 merged in practice — the probe and the manifest edits landed together once the first 

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/543
