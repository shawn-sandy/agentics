# Make the commit lint gate trustworthy in every repo it lands in

> The commit lint gate currently blocks on lint errors you did not cause, lints the wrong package in a monorepo, and ignores every non-Node project — and in th...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Re-arm the A/B hook probe from `scratchpad/hook-probe.py` (git-agent as control with a `SessionStart` echo only, plan-agent as treatment with the echo plus `"hooks": "./hooks.json"`), restart the desktop app, and record which banner appears.
- Apply the probe's verdict — if only TREATMENT fired, add `"hooks": "./hooks.json"` to the `.claude-plugin/plugin.json` of git-agent, plan-agent, skill-reviewer, and plan-interview; if CONTROL also fired, skip the manifest edits and instead record the real cause in Context.
- Replace the root-only `package.json` lookup with nearest-package resolution — walk up from the payload's cwd to the git root and use the first directory whose manifest declares a matching script, keeping the git root as the walk's hard ceiling.
- Add built-in ecosystem detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), reusing the same nearest-manifest walk and the same could-not-run guards as the Node path.
- Add a `.claude/lint-gate.json` config override that names a repo's own check commands and, when present, replaces built-in detection entirely rather than adding to it.
- Implement index-versus-HEAD comparison — materialize two detached worktrees, one at HEAD and one at the staged index, symlink the host repo's dependency directory into both, run the resolved check in each, normalize both outputs to sets of `file:line:message` records relative to their own roots, and block only on records present in the index run and absent at HEAD; fall back to today's whole-project block with a message saying the baseline was unavailable, and re-budget `PER_CHECK_TIMEOUT` against `hooks.json` so two checks plus their baselines stay inside the declared hook timeout.
- Extend `tests/plugins/test-lint-before-commit.sh` with sections covering nearest-package resolution, each new ecosystem, the config override, baseline pass and block, the baseline-unavailable fallback, and a check pinning that the commit regex bails before any filesystem probing — keeping the existing `make_repo`/`fire`/`check_rc` helpers and all 38 current checks passing.
- Bump `git-agent` to 4.14.0 and `plan-agent`, `skill-reviewer`, `plan-interview` by a patch level in `.claude-plugin/marketplace.json`, add the git-agent CHANGELOG entry, and document the ecosystems, the config file, and the baseline behavior in the git-agent README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | nearest-package resolution, ecosystem detection, config override, baseline comparison | Modified |
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

The gate ships as a `PreToolUse` hook on `Bash` and fires in every repo that installs git-agent, so each defect is an every-project defect rather than an agentics one. All four were measured this session, not inferred. **Pre-existing failures block unrelated commits.** The hook runs the host repo's whole `scripts.lint`. Walk into a repo with 40 errors you did not

The implementation proceeded through the following steps: Re-arm the A/B hook probe from `scratchpad/hook-probe.py` (git-agent as control with a `SessionStart` echo only, plan-agent as treatment with the echo plus `"hooks": "./hooks.json"`), restart the desktop app, and record which banner appears. Why: the manifest edits in Step 2 are a guess until the experiment distinguishes declaration style from every other explanation, and a wrong guess masks the real cause. Verify: the next desktop session prints `HOOKPROBE git-agent CONTROL fired`, `HOOKPROBE plan-agent TREATMENT fired`, both, or neither — write the observed result into this plan's Context before continuing.; Apply the probe's verdict — if only TREATMENT fired, add `"hooks": "./hooks.json"` to the `.claude-plugin/plugin.json` of git-agent, plan-agent, skill-reviewer, and plan-interview; if CONTROL also fired, skip the manifest edits and instead record the real cause in Context. Why: the fix is one key in four manifests only in the declaration-style branch, and shipping it in the other branch changes four plugins for no reason. Verify: after a further restart, `git-agent`'s `merge-shorthand` hook fires on the literal prompt `merge?` in a desktop session.; Replace the root-only `package.json` lookup with nearest-package resolution — walk up from the payload's cwd to the git root and use the first directory whose manifest declares a matching script, keeping the git root as the walk's hard ceiling. Why: a commit from `sub/pkg/` must lint `sub/pkg`, and the walk must not escape the repository into a parent directory's unrelated manifest. Verify: the existing `sub/pkg` fixture blocks with the nested script's marker in the output, and the root script's marker is absent.; Add built-in ecosystem detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), reusing the same nearest-manifest walk and the same could-not-run guards as the Node path. Why: the gate is currently a silent no-op in three common stacks, and each needs the exit-127 and missing-toolchain guards or a fresh clone starts refusing commits. Verify: a fixture repo per ecosystem with a deliberately failing linter exits 2, and the same fixture with the toolchain absent exits 0.; Add a `.claude/lint-gate.json` config override that names a repo's own check commands and, when present, replaces built-in detection entirely rather than adding to it. Why: built-in detection cannot cover every stack, and "config wins outright" is the only precedence a reader can predict without tracing the code. Verify: a fixture repo whose config names a failing command exits 2 while its `package.json` lint script passes, proving detection was skipped rather than merged.; Implement index-versus-HEAD comparison — materialize two detached worktrees, one at HEAD and one at the staged index, symlink the host repo's dependency directory into both, run the resolved check in each, normalize both outputs to sets of `file:line:message` records relative to their own roots, and block only on records present in the index run and absent at HEAD; fall back to today's whole-project block with a message saying the baseline was unavailable, and re-budget `PER_CHECK_TIMEOUT` against `hooks.json` so two checks plus their baselines stay inside the declared hook timeout. Why: this is the only defect whose fix can silently pass real failures if it degrades wrong, so the fallback direction, the race-free index pinning, and the timeout arithmetic are part of the fix rather than polish. Verify: a fixture with a pre-existing failure allows an unrelated commit, the same fixture with a newly-added staged failure exits 2, an unstaged failure does not block, and a fixture whose worktrees cannot be created still exits 2 with the fallback message..

- Hook registration — verified by a controlled A/B on the installed plugin (`Hooks (0)` → `Hooks (2)`), not by the planned desktop-restart probe, which is neither necessary nor valid for this defect - Steps 1 and 2 merged in practice — the probe and the manifest edits landed together once the first A/B showed the root path is never read; the plan's branch where CONTROL also fires did not occur - `plan-interview` manifest — not edited; the plugin was folded into `plan-agent` 4.0.0 and is not in this marketplace, so three plugins were bumped rather than four - Output normalization (Unresolved Question 1) — resolved without per-tool JSON formats: records are digit-masked, path-stripped lines compared as a multiset, so a record is new only when its count rises

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/543
