---
status: completed
type: fix
created: 2026-08-10
modified: 2026-08-10
issue: https://github.com/shawn-sandy/agentics/issues/543
effort: high
workflow: never
glance: The commit lint gate currently blocks on lint errors you did not cause, lints the wrong package in a monorepo, and ignores every non-Node project — and in the desktop app it never runs at all. This plan makes the gate block only on newly-introduced failures, resolve the nearest package, understand Python/Go/Rust, and actually register its hook.
---

# Plan: Make the commit lint gate trustworthy in every repo it lands in

## Objective

Fix the four defects in git-agent's `lint-before-commit.py` gate so it blocks
only on failures the current commit introduces, lints the package the commit
actually touches, recognizes non-Node projects, and registers its hook in the
Claude Code desktop app.

## Context

The gate ships as a `PreToolUse` hook on `Bash` and fires in every repo that
installs git-agent, so each defect is an every-project defect rather than an
agentics one. All four were measured this session, not inferred.

**Pre-existing failures block unrelated commits.** The hook runs the host
repo's whole `scripts.lint`. Walk into a repo with 40 errors you did not
write and every commit is blocked until you fix them or create
`.claude/no-lint-gate`. Four approaches were weighed: passing staged paths as
script arguments (cheap, but `eslint .` ignores appended paths); parsing
output for staged filenames (no extra runtime, but needs per-linter format
guesses); documenting the limitation only; and comparing against a baseline.
Baseline comparison was chosen because it is the only option that is correct
regardless of which linter the host repo uses. It costs a second lint run on
the failing path — see the timeout arithmetic in Step 6, which is the real
constraint, not the wall-clock cost.

**Monorepos lint the wrong package.** `repo_root()` resolves
`git rev-parse --show-toplevel` and then reads only the root `package.json`.
Confirmed by experiment: a commit issued from `sub/pkg/` ran the *root* lint
script and the nested package's own script never executed. Where the root has
no `scripts.lint`, the gate is silently off no matter what sub-packages
define.

**Non-Node projects get no gate.** Detection is `package.json` →
`scripts.lint`, then `scripts.typecheck`. A Python, Go, or Rust project is a
silent no-op regardless of the linters it has configured.

**The hook does not register — anywhere, not just the desktop app.**
git-agent, plan-agent, and skill-reviewer all keep `hooks.json` at the plugin
root with no `hooks` key in `plugin.json`. That location was assumed to be
auto-discovered; it is not. The plugins reference lists exactly one
auto-discovered path, `hooks/hooks.json`.

**Probe reading (recorded 2026-08-10, no desktop restart required).** Two
controlled A/Bs, each varying one thing:

1. *Is the root path read at all?* Identical deliberately-corrupt JSON was
   placed at `hooks/hooks.json` in one scratch plugin and at `hooks.json` in
   another. `claude plugin validate` rejects the first — "Invalid JSON syntax
   … At runtime this breaks the entire plugin load" — and passes the second
   without comment. The root file is never opened. Adding the manifest key
   does not change the validator's behaviour, because the validator checks the
   conventional path rather than resolving the manifest field.
2. *Does the manifest key fix it?* Run against the **installed** git-agent
   4.13.0 in `~/.claude/plugins/cache/`, using `claude plugin details` — the
   runtime's own component inventory — as the readout. Control, exactly as
   shipped: `Hooks (0)`. Treatment, same files plus
   `"hooks": "./hooks.json"`: `Hooks (2)  UserPromptSubmit, PreToolUse`. The
   installed manifest was restored byte-identically afterwards.

So the declaration style is the whole cause, and the consequence is larger
than "the desktop app": **the lint gate has never run for any installed user
on any surface.** `ponytail`, whose manifest names a non-standard hooks
filename, was the correct control all along. The desktop app additionally
drops plugin hooks for its own separate reason, so a desktop session is not a
valid test surface for this fix either way.

**Risk: the baseline run inherits the fresh-clone problem.** A temp worktree
checked out at HEAD has no `node_modules`, so lint there fails on a missing
binary and would look like "HEAD was already broken", silently passing every
real failure. Step 6 mitigates by symlinking the host repo's dependency
directory into both worktrees and by treating an unusable baseline as *fall
back to today's whole-project blocking*, never as *skip the gate*. The
symlink carries one accepted limitation: a dependency change staged in the
commit is not reflected in the HEAD side, so a failure caused purely by a
dependency bump reads as pre-existing.

**The comparison is pinned to the index, not the working tree.** Comparing a
live working tree against HEAD races against your own edits and against any
other agent writing during the hook's run. Both sides are therefore
materialized as detached worktrees — one at HEAD, one at the staged index —
which also changes what the gate checks: it now checks what is being
committed rather than what happens to be on disk. Unstaged edits stop being
linted. For the `commit-agent` path this is a no-op, since Step 2 of that
skill runs `git add -A`.

**Landing shape.** The rewrite touches every existing safety invariant, so it
lands as four commits behind one PR — nearest-package, ecosystems, config,
baseline — each with the full test file green before the next begins.

## Files

- kit/plugins/git-agent/hooks/lint-before-commit.py (modified) — nearest-package resolution, ecosystem detection, config override, baseline comparison
- kit/plugins/git-agent/hooks.json (modified) — hook timeout raised to cover the baseline run
- kit/plugins/git-agent/.claude-plugin/plugin.json (modified) — explicit `hooks` key
- kit/plugins/plan-agent/.claude-plugin/plugin.json (modified) — explicit `hooks` key
- kit/plugins/skill-reviewer/.claude-plugin/plugin.json (modified) — explicit `hooks` key
- .claude-plugin/marketplace.json (modified) — version bumps for the three surviving plugins
- kit/plugins/plan-agent/CHANGELOG.md (modified) — entry for the hook-registration fix
- kit/plugins/skill-reviewer/CHANGELOG.md (modified) — entry for the hook-registration fix
- kit/plugins/git-agent/CHANGELOG.md (modified) — entry for the gate rewrite
- kit/plugins/git-agent/README.md (modified) — document ecosystems, config file, baseline behavior
- tests/plugins/test-lint-before-commit.sh (modified) — new sections for all four fixes

## Steps

1. [x] Re-arm the A/B hook probe from `scratchpad/hook-probe.py` (git-agent as control with a `SessionStart` echo only, plan-agent as treatment with the echo plus `"hooks": "./hooks.json"`), restart the desktop app, and record which banner appears. Why: the manifest edits in Step 2 are a guess until the experiment distinguishes declaration style from every other explanation, and a wrong guess masks the real cause. Verify: the next desktop session prints `HOOKPROBE git-agent CONTROL fired`, `HOOKPROBE plan-agent TREATMENT fired`, both, or neither — write the observed result into this plan's Context before continuing.
2. [x] Apply the probe's verdict — if only TREATMENT fired, add `"hooks": "./hooks.json"` to the `.claude-plugin/plugin.json` of git-agent, plan-agent, skill-reviewer, and plan-interview; if CONTROL also fired, skip the manifest edits and instead record the real cause in Context. Why: the fix is one key in four manifests only in the declaration-style branch, and shipping it in the other branch changes four plugins for no reason. Verify: after a further restart, `git-agent`'s `merge-shorthand` hook fires on the literal prompt `merge?` in a desktop session.
3. [x] Replace the root-only `package.json` lookup with nearest-package resolution — walk up from the payload's cwd to the git root and use the first directory whose manifest declares a matching script, keeping the git root as the walk's hard ceiling. Why: a commit from `sub/pkg/` must lint `sub/pkg`, and the walk must not escape the repository into a parent directory's unrelated manifest. Verify: the existing `sub/pkg` fixture blocks with the nested script's marker in the output, and the root script's marker is absent.
4. [x] Add built-in ecosystem detection for `pyproject.toml` (ruff, then flake8), `go.mod` (`go vet`), and `Cargo.toml` (`cargo clippy`), reusing the same nearest-manifest walk and the same could-not-run guards as the Node path. Why: the gate is currently a silent no-op in three common stacks, and each needs the exit-127 and missing-toolchain guards or a fresh clone starts refusing commits. Verify: a fixture repo per ecosystem with a deliberately failing linter exits 2, and the same fixture with the toolchain absent exits 0.
5. [x] Add a `.claude/lint-gate.json` config override that names a repo's own check commands and, when present, replaces built-in detection entirely rather than adding to it. Why: built-in detection cannot cover every stack, and "config wins outright" is the only precedence a reader can predict without tracing the code. Verify: a fixture repo whose config names a failing command exits 2 while its `package.json` lint script passes, proving detection was skipped rather than merged.
6. [x] Implement index-versus-HEAD comparison — materialize two detached worktrees, one at HEAD and one at the staged index, symlink the host repo's dependency directory into both, run the resolved check in each, normalize both outputs to sets of `file:line:message` records relative to their own roots, and block only on records present in the index run and absent at HEAD; fall back to today's whole-project block with a message saying the baseline was unavailable, and re-budget `PER_CHECK_TIMEOUT` against `hooks.json` so two checks plus their baselines stay inside the declared hook timeout. Why: this is the only defect whose fix can silently pass real failures if it degrades wrong, so the fallback direction, the race-free index pinning, and the timeout arithmetic are part of the fix rather than polish. Verify: a fixture with a pre-existing failure allows an unrelated commit, the same fixture with a newly-added staged failure exits 2, an unstaged failure does not block, and a fixture whose worktrees cannot be created still exits 2 with the fallback message.
7. [x] Extend `tests/plugins/test-lint-before-commit.sh` with sections covering nearest-package resolution, each new ecosystem, the config override, baseline pass and block, the baseline-unavailable fallback, and a check pinning that the commit regex bails before any filesystem probing — keeping the existing `make_repo`/`fire`/`check_rc` helpers and all 38 current checks passing. Why: every existing safety invariant is a check in this file, and a rewrite this broad regresses one of them silently otherwise; the ordering check exists because the hook runs on every Bash call in every repo and new detection must never move ahead of the cheap bail. Verify: `bash tests/plugins/test-lint-before-commit.sh` reports zero failures with a total check count above 38.
8. [x] Bump `git-agent` to 4.14.0 and `plan-agent`, `skill-reviewer`, `plan-interview` by a patch level in `.claude-plugin/marketplace.json`, add the git-agent CHANGELOG entry, and document the ecosystems, the config file, and the baseline behavior in the git-agent README. Why: the repo's CI guard fails any PR whose touched plugins do not exceed the base branch version, and an undocumented config file is a config file nobody uses. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code

- Objective: a pre-existing lint failure no longer blocks an unrelated commit, while a newly-introduced one still does. File: tests/plugins/test-lint-before-commit.sh; Type: smoke; Asserts: the baseline fixture exits 0 when HEAD was already failing and exits 2 when the staged index adds a new failure; Run: bash tests/plugins/test-lint-before-commit.sh
- Unit: index pinning and fast-path ordering. File: tests/plugins/test-lint-before-commit.sh; Targets: worktree materialization and the commit-regex bail; Key cases: an unstaged failure does not block, a staged failure does, and a non-commit Bash payload reads no manifest or config file
- Unit: nearest-package resolution. File: tests/plugins/test-lint-before-commit.sh; Targets: the manifest walk; Key cases: commit from a nested package uses the nested script, commit from the root uses the root script, the walk stops at the git root, a nested package without a matching script falls through per the chosen precedence
- Unit: ecosystem detection. File: tests/plugins/test-lint-before-commit.sh; Targets: detection and runner selection; Key cases: pyproject/go.mod/Cargo.toml each block on a failing linter, each exits 0 when the toolchain is missing, and package.json still wins where both are present
- Unit: config override. File: tests/plugins/test-lint-before-commit.sh; Targets: `.claude/lint-gate.json` parsing; Key cases: config command beats built-in detection, malformed config is a silent no-op, `.claude/no-lint-gate` still overrides the config
- Integration: existing invariants survive the rewrite. File: tests/plugins/test-lint-before-commit.sh; Targets: the whole hook; Key cases: all 38 current checks — exit 127, missing deps, no package.json, `-C` retargeting, `git log --grep commit` near-miss, and the opt-out marker

## Acceptance Criteria

- [x] A repo whose HEAD already fails lint accepts a commit that introduces no new lint failures.
- [x] The same repo rejects a commit that introduces a new lint failure, with the new failure named in the block message.
- [x] The verdict is computed from the staged index, so an unstaged edit neither blocks a commit nor changes the result.
- [x] The commit regex bails before any filesystem probing, so a non-commit Bash call touches no manifest, config, or worktree.
- [x] A commit issued from a monorepo subdirectory runs that package's check, not the repository root's.
- [x] A failing Python, Go, or Rust project blocks the commit; the same project without its toolchain installed does not.
- [x] A `.claude/lint-gate.json` command takes precedence over built-in detection, and `.claude/no-lint-gate` still disables everything.
- [x] Every could-not-run path — missing deps, exit 127, timeout, no manifest, unusable baseline — either exits 0 or falls back to whole-project blocking, and never silently passes a real failure.
- [x] `bash tests/plugins/test-lint-before-commit.sh` reports zero failures with more than 38 checks.
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 after the version bumps.
- [x] The desktop hook question is resolved by a recorded probe reading, not by assumption.

## Verification

Run `bash tests/plugins/test-lint-before-commit.sh` and confirm zero failures
with a check count above 38. Then run
`git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`
and confirm exit 0.

End-to-end, build a scratch monorepo outside this repository with a root
package that passes lint, a nested `packages/api` whose lint fails on a
pre-existing error, and dependencies installed. Fire the hook with a
`git commit` payload whose cwd is `packages/api` and confirm exit 0 — the
failure pre-existed. Add a new lint error to a file in `packages/api`, fire
the same payload, and confirm exit 2 with only the new error quoted in the
block message and the root package's script never invoked.

Finally, confirm the gate registers at all — the precondition for every other
guarantee here. The planned check (type `merge?` in a desktop session) was
replaced by a stronger one that needs no restart and no desktop: run
`claude plugin details git-agent` and read the component inventory. Shipped
layout reports `Hooks (0)`; the same files with the manifest key report
`Hooks (2)  UserPromptSubmit, PreToolUse`. This supersedes the desktop check
in both directions — it observes registration directly rather than inferring
it from a hook's side effect, and the desktop app drops plugin hooks for a
separate reason, so it could never have confirmed this fix.

## Completion Report

- Hook registration — verified by a controlled A/B on the installed plugin (`Hooks (0)` → `Hooks (2)`), not by the planned desktop-restart probe, which is neither necessary nor valid for this defect
- Steps 1 and 2 merged in practice — the probe and the manifest edits landed together once the first A/B showed the root path is never read; the plan's branch where CONTROL also fires did not occur
- `plan-interview` manifest — not edited; the plugin was folded into `plan-agent` 4.0.0 and is not in this marketplace, so three plugins were bumped rather than four
- Output normalization (Unresolved Question 1) — resolved without per-tool JSON formats: records are digit-masked, path-stripped lines compared as a multiset, so a record is new only when its count rises
- Baseline cost ceiling (Unresolved Question 2) — resolved as 120s primary / 60s baseline / 30s materialization, inside a hook timeout raised 200s → 480s; a baseline timeout degrades to whole-project blocking
- Two repo tests skipped — `test-imperative-pruning.sh` and `test-skill-behavior-baselines.sh` drive the live `claude` CLI against recorded model-behavior baselines for five SKILL.md files untouched by this change; the other 45 suites pass
- Post-merge check outstanding — the gate cannot run for installed users until this version ships and is reinstalled; nothing in this branch can advance that

## Unresolved Questions

- Output normalization across linters

  ```text
  In the agentics repo, the lint gate at
  kit/plugins/git-agent/hooks/lint-before-commit.py needs to compare a
  linter's output before and after a change to decide whether a failure is
  new. Investigate how to normalize output into comparable
  `file:line:message` records across eslint, tsc, ruff, go vet, and cargo
  clippy — including whether to prefer each tool's machine-readable format
  (eslint --format json, ruff --output-format json, cargo clippy --message-format json)
  over text parsing, and what to do when a project's lint script wraps the
  tool so no format flag can be injected. Recommend one approach with a
  fallback for the unwrappable case, and say explicitly what the gate should
  do when normalization fails.
  ```

- Baseline cost ceiling

  ```text
  In the agentics repo, kit/plugins/git-agent/hooks/lint-before-commit.py is a
  PreToolUse hook whose total runtime is bounded by the timeout declared in
  kit/plugins/git-agent/hooks.json (currently 200s, with PER_CHECK_TIMEOUT at
  90s for each of two checks). A planned change adds a second baseline lint
  run per failing check, which can double the worst case past the ceiling.
  Recommend a concrete budget: the hook timeout, the per-check timeout, and
  whether the baseline run should get a smaller budget than the primary run.
  Say what the gate should do when the baseline times out but the primary run
  already failed.
  ```

## Next Steps

- Extend the gate to run the host repo's tests, not just lint

  ```text
  In the agentics repo, kit/plugins/git-agent/hooks/lint-before-commit.py
  gates commits on the host project's lint and typecheck scripts. Evaluate
  whether a test gate belongs in the same hook or a separate one, given tests
  are far slower than lint and the hook runs on every Bash call in every
  repo. If you recommend adding it, implement it behind an explicit opt-in
  (not opt-out), bump the git-agent version in .claude-plugin/marketplace.json,
  add a CHANGELOG entry, and extend tests/plugins/test-lint-before-commit.sh.
  Verify with `bash tests/plugins/test-lint-before-commit.sh` reporting zero
  failures before reporting done.
  ```

- Lint every workspace package a commit touches

  ```text
  In the agentics repo, kit/plugins/git-agent/hooks/lint-before-commit.py
  resolves a single nearest package to lint. For a commit that stages files
  across several workspace packages, that checks only one of them. Implement
  multi-package resolution: determine every package containing a staged file
  and run each one's check, aggregating failures into one block message.
  Keep the existing could-not-run guards and the total runtime inside the
  hook timeout declared in kit/plugins/git-agent/hooks.json. Bump the
  git-agent version in .claude-plugin/marketplace.json, add a CHANGELOG
  entry, and extend tests/plugins/test-lint-before-commit.sh. Verify with
  `bash tests/plugins/test-lint-before-commit.sh` reporting zero failures.
  ```

## Resources

- kit/plugins/git-agent/hooks/lint-before-commit.py — the gate being fixed
- kit/plugins/git-agent/CHANGELOG.md v4.7.0 — the original design rationale for a hook over a skill instruction
- tests/plugins/test-lint-before-commit.sh — the 38-check harness the rewrite must keep green
- scratchpad/hook-probe.py — the A/B desktop hook probe, written and reverted this session
