---
status: todo
type: feature
created: 2026-08-21
effort: high
workflow: never
glance: CI on this account is frequently billing-blocked, so a red check proves nothing and a green one never arrives. This builds a merge gate that runs entirely on the local machine and a skill that refuses to call a change done until that gate is green and the evidence is written down. We will know it worked when bash scripts/verify.sh exits 0 here and the same script, unmodified, correctly skips absent stages in a bare project.
issue: https://github.com/shawn-sandy/agentics/issues/591
---

# Plan: Prove merge readiness locally, without GitHub Actions

## Objective

Ship a portable `verify.sh` merge gate and a `verified-change` skill that
enforces test-first, mutation-checked changes, then dogfood both into the
agentics repo so no change here is proposed for merge without local proof.

## Context

GitHub Actions is frequently billing-blocked on this account. A quota-blocked
run fails every job in seconds with no test output, which means red CI is not
evidence of a defect and green CI is not evidence of correctness — it is
evidence of nothing at all. Merge readiness has to be provable on the machine.

The repo already has most of a local gate and does not know it.
`tests/run-all.sh` auto-discovers every `tests/**/test-*.sh`, `test-*.mjs`, and
`*.test.mjs` and runs them, so new tests need no wiring. What is missing is a
single entry point that also covers the non-test gates (marketplace validation,
the plugin version guard, README table freshness), and a discipline that makes
running it non-optional.

The second half of the problem is test quality, not test presence. A test
written after the implementation can pass for the wrong reason and nobody
finds out until production. The mutation check closes that: deliberately break
the implementation, confirm the new test goes red, restore. A test that stays
green through a mutation is not a test.

This repo has no `package.json`, no `tsconfig`, no ESLint config, and no
Playwright. A gate hardcoding typecheck/lint/unit/e2e would be three no-ops
and one real stage here, so the script auto-detects instead — which is also
what makes one file serve every project rather than needing a generator.

`code-testing-agent` already ships `tdd-loop`, whose RED phase depends on the
production code not existing yet. That shape does not fit a change to code
that already works, which is the gap `verified-change` fills.

## Decisions

- The skill lives in `code-testing-agent`, not a new plugin and not `git-agent` — the verified-change loop is a testing discipline, and that plugin already owns `tdd-loop`, `tdd-fix`, and `running-tests`.
- `verified-change` sits beside `tdd-loop` rather than replacing or extending it — `tdd-loop` is for new features where red is free; `verified-change` is for changes to working code where red must be manufactured by mutation.
- One auto-detecting `verify.sh` serves every project, so there is no generator — "generate the gate" is a file copy, and the detection happens at run time.
- The plugin skill is the source of truth and agentics also carries a project-local copy at `.claude/skills/verified-change/SKILL.md`, because worktrees pin older plugin versions and Desktop loads frozen claude.ai snapshots; a parity test prevents the copy from rotting.
- The mutation check restores from a scratchpad copy, never `git stash` and never `git checkout --`, so it survives a dirty tree without destroying uncommitted work; restoration is proven with `cmp -s` against that copy — not `git diff --quiet`, which ignores untracked files and would therefore pass on an unrestored mutation of a file this plan has not committed yet.
- `scripts/verify.sh` and the plugin's `assets/verify.sh` are a deliberate byte-identical duplicate, held together by a parity test rather than by generation, for the same reason the `SKILL.md` copy exists: the consuming environments cannot reach the plugin root reliably. Every future gate change is therefore a two-file edit, and the parity test is what makes forgetting the second one loud.
- `verified-change` emits the VERIFICATION markdown and hands it off; `git-agent:pr-agent` is not modified, so only one plugin version bumps.
- Steps are grouped RED/GREEN/VERIFY because the work touches source and `tests/run-all.sh` exists to run red against. There is no SHIP phase — "apply this to my current branch" asked for the work to land in the tree, not for a commit and PR.

## Steps

### Phase: RED

1. Create `tests/fixtures/verify-gate-bare/` holding a project with no toolchain at all — a tracked `.gitkeep` and a one-line `README.md`, since git does not commit an empty directory and a fresh clone would otherwise fail the objective test — and `tests/fixtures/verify-gate-failing/` holding one whose unit stage is a `package.json` `test` script that exits 1 with no dependencies to install; name no file in either fixture `test-*.sh`, `test-*.mjs`, or `*.test.mjs`, because `tests/run-all.sh` discovers with a bare `find tests -name 'test-*.sh'` that has no `tests/fixtures/` exclusion and would run the deliberately-failing fixture as a real suite member Why: the gate's two interesting behaviours are skipping what is absent and failing fast on what breaks, and both need a project to run against that is not agentics itself — and a fixture that the repo's own runner picks up would make acceptance criterion "run-all reports 0 failed" unsatisfiable by construction Verify: `ls -a tests/fixtures/verify-gate-bare tests/fixtures/verify-gate-failing` lists both with their tracked placeholder files, `find tests/fixtures/verify-gate-bare tests/fixtures/verify-gate-failing \( -name 'test-*.sh' -o -name 'test-*.mjs' -o -name '*.test.mjs' \)` prints nothing, `bash tests/run-all.sh` reports the same failed count as before the fixtures existed, and neither contains a `tsconfig.json`, an ESLint config, or a Playwright config. Also add both fixtures to `tests/fixtures/README.md`, noting they deliberately depart from the "fixtures model structure, not working behavior" line in `.claude/rules/testing.md` because a gate can only be exercised against a runnable project.
2. Write `tests/test-verify-gate.sh` asserting that running the gate in the bare fixture prints a `SKIP (not configured)` line for each of typecheck, lint, unit, and e2e **in that printed order**, and exits 0; that running it in the failing fixture exits non-zero naming the failed stage; and that no stage after the failed one runs — invoking the gate in every case as `(cd "$FIXTURE" && bash "$ROOT/scripts/verify.sh")` so detection is exercised against the fixture's working directory rather than the repo root Why: this is the objective-verification test — it is the thing that fails if the gate stops being a gate, and asserting the order is what makes "fails fast" mean something rather than just "eventually exits non-zero" Verify: `bash tests/test-verify-gate.sh` exits non-zero with a missing-file error naming `scripts/verify.sh`, which is red for the right reason.
3. Write `tests/plugins/test-verified-change-skill.sh` asserting the skill's frontmatter carries `name` and a description within the 200-char budget whose first sentence is within 80, that the file contains the plan-mode guard line verbatim, that `.claude/skills/verified-change/SKILL.md` is byte-identical to the plugin copy, that `scripts/verify.sh` is byte-identical to the plugin's `assets/verify.sh`, and that `CLAUDE.md` contains the merge-gate rule; also register `verified-change` in the hardcoded skill list inside `tests/plugins/test-exitplanmode-guard.sh` so the guard is enforced by the same repo-wide test that enforces it for every other mutating skill Why: the parity assertions are the only thing standing between a deliberate duplicate and a silently forked copy — the 200/80 description assertions are a fast local signal only, since `tests/plugins/test-description-budget.sh` already sweeps every shipped `SKILL.md`, so do not treat them as this test's reason to exist Verify: `bash tests/plugins/test-verified-change-skill.sh` exits non-zero listing every absent file, not erroring on a bad path, and `bash tests/plugins/test-exitplanmode-guard.sh` exits non-zero naming the missing `verified-change` guard.

### Phase: GREEN

4. Write `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` running typecheck, lint, unit, then e2e in that order, each stage detecting its own tooling and printing either a result or `SKIP (not configured)`, exiting non-zero at the first real failure without running later stages, and additionally running `tests/run-all.sh`, `node scripts/check-plugin-versions.mjs`, and `node scripts/build-readme-table.mjs --check` when it detects a `.claude-plugin/marketplace.json`. Resolve **every** detection against `$PWD`, never against `$(dirname "$0")` — the repo's own scripts set `ROOT` from `$0` (`tests/run-all.sh` line 1), and a gate that did the same would, while running inside `tests/fixtures/verify-gate-bare/`, still find agentics' `.claude-plugin/marketplace.json`, re-enter `tests/run-all.sh`, which re-runs `tests/test-verify-gate.sh`, which re-invokes the gate: unbounded recursion on the objective test. Belt-and-braces, export a `VERIFY_GATE_ACTIVE` marker on entry and hard-exit non-zero with a named re-entry error if it is already set. Have the lint stage also detect `shellcheck` (the deliverable is itself shell), run detected tooling by its plain name without prepending `node_modules/.bin` to `PATH`, and open the script with `set -euo pipefail` and quoted expansions throughout Why: one auto-detecting file is what lets the same gate serve agentics and a Vite app without a generator — but only if "auto-detect" means the project it was pointed at, and a gate that executes whatever tooling a clone happens to declare is arbitrary code execution against an untrusted repo (CWE-829), so the SKILL.md must state it is for repos you already trust Verify: `bash tests/test-verify-gate.sh` still fails, but now on assertion content rather than on the missing file; `(cd tests/fixtures/verify-gate-bare && bash "$PWD/../../../scripts/verify.sh")` terminates rather than recursing, and `shellcheck scripts/verify.sh` reports no errors once the file exists.
5. Copy the template to `scripts/verify.sh`, mark it executable, and add `kit/plugins/code-testing-agent/bin/install-verify-gate` — an executable wrapper that copies the plugin's `assets/verify.sh` into the target repo's `scripts/`, refusing to overwrite an existing file without `--force` Why: the dogfood copy is what the CLAUDE.md rule will point at, and the wrapper is how the gate reaches any *other* repo — Claude Code's Bash tool rejects any command containing `${...}` expansion before permission rules are consulted, so a documented `cp "${CLAUDE_PLUGIN_ROOT}/skills/verified-change/assets/verify.sh" scripts/` can never run for anyone; seven plugins in this marketplace already ship a `bin/` wrapper for exactly this reason Verify: `bash scripts/verify.sh` runs to completion and its output contains at least one `SKIP (not configured)` line and at least one real stage result; `install-verify-gate` run from a scratch directory produces a byte-identical `scripts/verify.sh` there and exits non-zero without `--force` when one already exists.
6. Write `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` with the six-step loop — write the test, mutation-check it, restore, implement, iterate on `scripts/verify.sh` without pausing to ask up to a hard bound of 8 attempts, then stop and report the failing assertion, the last diff tried, and what was ruled out rather than reporting success, and browser-verify UI changes at 390px and 1280px in **both** light and dark themes with an axe run against the real rendered page (never a Storybook iframe), recording measured evidence — computed styles, element boxes, the axe violation count — because a screenshot alone is not evidence — carrying the plan-mode guard verbatim, a `When not to use` line pointing at `tdd-loop` for new features, and an `allowed-tools` list covering every tool it calls Why: the loop is the deliverable; the gate is only the thing it runs Verify: `bash tests/plugins/test-verified-change-skill.sh` advances past the frontmatter and guard assertions to the parity assertions.
7. Write `references/mutation-check.md` giving a mutation catalogue by change type and the safe break-and-restore protocol — copy the file to the scratchpad, mutate in place, run the scoped test, restore from the copy, then prove restoration with `cmp -s "$SCRATCH/<file>" "<file>"` and hard-stop if it fails, install a shell `trap` that restores on any exit path including interrupt, and delete the scratchpad copy after a proven restore Why: a mutation check that cannot prove it restored the file is a way to lose work — and `git diff --quiet <path>` is a *vacuous* proof for the file this plan mutates, because `scripts/verify.sh` is new and untracked until it is committed, and `git diff` ignores untracked files entirely, so an unrestored mutation would report clean; `cmp` is true whether the file is tracked or not, and leaving working-tree source in the scratchpad after the loop puts it outside both the repo and its `.gitignore` Verify: the file states the `cmp -s` proof, the `trap`, the scratchpad cleanup, and an explicit STOP path, notes the untracked-file caveat that rules `git diff --quiet` out as the primary check, and matches the verification-gate pattern in `.claude/rules/plugin-patterns.md`.
8. Write `references/verification-section.md` containing one filled VERIFICATION section — every gate with its real result, the mutation applied with its observed failure output, and the screenshot paths — as a worked example rather than a bracket schema Why: `.claude/rules/plugin-patterns.md` requires a filled instance for any skill emitting structured output Verify: the file contains no `<placeholder>` brackets and shows a real command with a real exit status.
9. Copy the finished skill directory — `SKILL.md` **and** both `references/` files — to `.claude/skills/verified-change/`, and extend the step-3 parity test to cover the references as well as `SKILL.md` Why: a project-local skill stays visible in worktrees pinned to an older plugin version and in Desktop, where plugin snapshots lag — but byte-identical parity means the copied `SKILL.md` carries the same relative `references/mutation-check.md` and `references/verification-section.md` links, and copying `SKILL.md` alone leaves both dangling in exactly the environments this copy exists to serve Verify: `diff -r kit/plugins/code-testing-agent/skills/verified-change .claude/skills/verified-change` prints nothing, and every `references/` path named in the project-local `SKILL.md` resolves to a file beside it.
10. Bump `code-testing-agent` from 3.5.2 to 3.6.0 in `.claude-plugin/marketplace.json`, add the skill to the plugin README and CHANGELOG, and regenerate the root README table with `node scripts/build-readme-table.mjs` Why: any edit under `kit/plugins/<name>/` fails the version guard without a bump, and the root table is generated output that must never be hand-edited Verify: `node scripts/build-readme-table.mjs --check` exits 0 and `BASE_REF=main node scripts/check-plugin-versions.mjs` reports the bump.
11. Add the merge-gate rule to `CLAUDE.md` stating that merging is never proposed until `bash scripts/verify.sh` is green locally and the PR body's VERIFICATION section is filled in, and that a billing-blocked CI run is not evidence either way Why: the rule is what makes the gate binding rather than available — with the honest limitation, stated in the rule itself, that a sentence in `CLAUDE.md` is honoured, not enforced; the pre-push hook and the `git-agent:merge` refusal in Next Steps are what would enforce it Verify: `bash tests/plugins/test-verified-change-skill.sh` exits 0 with every assertion passing.

### Phase: VERIFY

12. Run `bash tests/run-all.sh` Why: the two new tests must pass alongside the existing 77 without regressing any of them Verify: the runner's final line reports 0 failed and the two new test paths appear in the PASS list.
13. Run `bash scripts/verify.sh` in agentics and read its full output Why: a gate that passes its own unit tests but does not actually run here is not a gate Verify: it exits 0, prints `SKIP (not configured)` for typecheck, lint, and e2e, and prints real results for the unit stage and the three marketplace stages.
14. Run `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` Why: the script reads `origin/main` directly, so a stale remote-tracking ref compares against the wrong base and passes a bump that CI will reject Verify: it exits 0 and names `code-testing-agent 3.5.2 -> 3.6.0`.
15. Mutation-check the gate itself by breaking the failure propagation in `scripts/verify.sh` so a failing stage returns 0, confirming `tests/test-verify-gate.sh` goes red, then restoring from the scratchpad copy under a `trap` that also restores on interrupt Why: the plan builds a mutation check, so its own objective test has to survive one — and this is the dogfood that proves the protocol in step 7 works Verify: the mutated run of `bash tests/test-verify-gate.sh` exits non-zero naming the fail-fast assertion, and after restore `cmp -s "$SCRATCH/verify.sh" scripts/verify.sh` exits 0 and the test passes again. Do not substitute `git diff --quiet scripts/verify.sh` here: the file is untracked until this branch is committed, so that check would pass on an unrestored mutation and the dogfood would prove nothing.

## Files

- tests/fixtures/verify-gate-bare/ (new) — project with no toolchain, exercises every SKIP path
- tests/fixtures/verify-gate-failing/ (new) — project whose unit stage exits 1, exercises fail-fast
- tests/test-verify-gate.sh (new) — objective test for skip behaviour, ordering, and exit codes
- tests/plugins/test-verified-change-skill.sh (new) — skill structure, budgets, guard, and copy parity
- kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh (new) — the portable gate template
- kit/plugins/code-testing-agent/skills/verified-change/SKILL.md (new) — the six-step verified-change loop
- kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md (new) — mutation catalogue and safe restore protocol
- kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md (new) — one filled VERIFICATION example
- kit/plugins/code-testing-agent/bin/install-verify-gate (new) — executable wrapper that copies assets/verify.sh into a target repo, since `${CLAUDE_PLUGIN_ROOT}` in a documented Bash command is unrunnable
- tests/fixtures/README.md (modified) — document the two new fixtures and their deliberate departure from the structure-only fixture policy
- tests/plugins/test-exitplanmode-guard.sh (modified) — register verified-change in the hardcoded guard list
- kit/plugins/code-testing-agent/README.md (modified) — document the new skill
- kit/plugins/code-testing-agent/CHANGELOG.md (modified) — 3.6.0 entry
- .claude-plugin/marketplace.json (modified) — bump code-testing-agent to 3.6.0
- README.md (generated) — regenerated Plugin Reference Table
- scripts/verify.sh (new) — agentics' dogfood copy of the gate
- .claude/skills/verified-change/ (new) — project-local copy of SKILL.md *and* both references files, parity-tested as a directory
- CLAUDE.md (modified) — the merge-gate rule

## Tests

Tier 1 — This plan changes application code
- Objective: the gate skips absent stages and fails fast on a broken one. File: tests/test-verify-gate.sh; Type: smoke; Asserts: the bare fixture prints `SKIP (not configured)` for typecheck, lint, unit, and e2e in that order and exits 0, the failing fixture exits non-zero naming the failed stage, no stage after the failure runs, and a gate invoked from inside a fixture terminates instead of re-entering `tests/run-all.sh`; Run: bash tests/test-verify-gate.sh
- Unit: skill structure and copy parity. File: tests/plugins/test-verified-change-skill.sh; Targets: verified-change SKILL.md, its two copies, and the CLAUDE.md rule; Key cases: description within the 200/80 budget, plan-mode guard verbatim, plugin SKILL.md identical to the project-local copy, assets/verify.sh identical to scripts/verify.sh, CLAUDE.md contains the rule
- Integration: the whole suite still runs. File: tests/run-all.sh; Targets: auto-discovery of the two new tests; Key cases: both new files appear in the PASS list and the run reports 0 failed

## Acceptance Criteria

- [ ] `bash scripts/verify.sh` exits 0 in agentics and prints an explicit result or SKIP line for every stage
- [ ] The same script, unmodified, prints four SKIP lines and exits 0 in a project with no toolchain
- [ ] A failing stage makes the gate exit non-zero and stops it from running later stages
- [ ] `bash tests/run-all.sh` reports 0 failed with both new tests in the PASS list
- [ ] `.claude/skills/verified-change/SKILL.md` is byte-identical to the plugin copy and a test fails if they diverge
- [ ] `scripts/verify.sh` is byte-identical to the plugin's `assets/verify.sh` and a test fails if they diverge
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with code-testing-agent at 3.6.0
- [ ] `node scripts/build-readme-table.mjs --check` exits 0
- [ ] `CLAUDE.md` states that merging is not proposed until the gate is green and VERIFICATION is filled in
- [ ] The skill's own objective test survives a deliberate mutation of the gate's failure propagation
- [ ] The gate detects every stage relative to the directory it is invoked from, so running it inside `tests/fixtures/verify-gate-bare/` terminates instead of re-entering `tests/run-all.sh`
- [ ] `find tests/fixtures/verify-gate-bare tests/fixtures/verify-gate-failing \( -name 'test-*.sh' -o -name 'test-*.mjs' -o -name '*.test.mjs' \)` prints nothing, so `tests/run-all.sh` never picks the failing fixture up as a suite member
- [ ] The mutation-restore proof is `cmp -s` against the scratchpad copy and fails loudly on an unrestored file even when that file is untracked
- [ ] `kit/plugins/code-testing-agent/bin/install-verify-gate` copies the gate into a scratch repo without any `${...}` expansion in the documented command
- [ ] `diff -r kit/plugins/code-testing-agent/skills/verified-change .claude/skills/verified-change` prints nothing, references included

## Verification

Run `bash scripts/verify.sh` from the repo root. It must exit 0, print
`SKIP (not configured)` for typecheck, lint, and Playwright e2e, and print
real pass output for the unit stage (`tests/run-all.sh`) and the three
marketplace stages. Then run `bash tests/run-all.sh` directly and confirm the
final line reports 0 failed with `tests/test-verify-gate.sh` and
`tests/plugins/test-verified-change-skill.sh` both in the PASS list.

Prove the gate is not vacuous. Copy `scripts/verify.sh` to the scratchpad,
edit the failing-stage branch to return 0 instead of propagating the failure,
and run `bash tests/test-verify-gate.sh` — it must exit non-zero naming the
fail-fast assertion. Restore from the scratchpad copy and confirm
`cmp -s "$SCRATCH/verify.sh" scripts/verify.sh` exits 0 and the test passes
again. Use `cmp`, not `git diff --quiet`: the gate is untracked until this
branch is committed and `git diff` ignores untracked files, so that check
would report clean over an unrestored mutation. A gate whose test stays green
through the mutation has not been verified; it has only been run.

Prove the gate does not re-enter itself. From the repo root run
`(cd tests/fixtures/verify-gate-bare && bash "$OLDPWD/scripts/verify.sh")` and
confirm it terminates with four SKIP lines rather than picking up agentics'
`.claude-plugin/marketplace.json` and recursing back through
`tests/run-all.sh` into `tests/test-verify-gate.sh`.

Revert path if the gate proves wrong: delete `scripts/verify.sh`, the two
`tests/fixtures/verify-gate-*` directories, `tests/test-verify-gate.sh`,
`tests/plugins/test-verified-change-skill.sh`, and `.claude/skills/verified-change/`;
drop the `CLAUDE.md` rule; revert the marketplace bump to 3.5.2 and
regenerate the README table. Nothing in this plan changes existing runtime
behaviour, so the revert is a delete plus one regeneration.

Finally, confirm the marketplace stays consistent: `git fetch origin &&
BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 naming
`code-testing-agent 3.5.2 -> 3.6.0`, and `node scripts/build-readme-table.mjs
--check` exits 0.

## Next Steps

- Wire the gate into git-agent's merge readiness check
  Right now CLAUDE.md states the rule and a human or agent honours it; pr-agent and merge do not enforce it.
  ```text
  In the agentics repo, teach kit/plugins/git-agent/skills/merge/SKILL.md to
  refuse a merge when scripts/verify.sh exists in the repo and either has not
  been run green in this session or the PR body has no filled VERIFICATION
  section. Bump git-agent's minor version in .claude-plugin/marketplace.json,
  add a CHANGELOG entry, and add a test under tests/plugins/ asserting the
  refusal path. Verify with bash tests/run-all.sh reporting 0 failed.
  ```
- Add a pre-push hook that runs the gate
  Makes the gate hard to skip rather than merely documented.
  ```text
  In the agentics repo, add a git pre-push hook that runs bash scripts/verify.sh
  and blocks the push on a non-zero exit, plus a documented escape hatch for
  work-in-progress branches. Install it from a script under scripts/ rather than
  committing into .git/. Add a test under tests/ asserting the hook blocks on a
  failing gate. Verify with bash tests/run-all.sh reporting 0 failed.
  ```

## Resources

- `.claude/rules/plugin-patterns.md` — the plan-mode guard, verification gate, and description budget rules every new skill must satisfy
- `.claude/rules/testing.md` — auto-discovery conventions for `tests/**` and the fixture policy
- `tests/run-all.sh` — the existing local gate this plan wraps rather than replaces
- `kit/plugins/code-testing-agent/skills/tdd-loop/SKILL.md` — the adjacent skill whose RED phase does not fit changes to working code

## Team Review (2026-08-21 19:11 UTC)

Ten review lenses — architecture, completeness, testability, risk, conventions,
product, security, plus UX, accessibility, and frontend (UI signals detected:
Playwright e2e stage, browser verification at mobile/desktop widths, screenshot
evidence). Run in background mode: the walkthrough gate was bypassed and every
proposed edit was applied.

Note on execution: the reviewer roles were run by the lead in sequence rather
than as parallel teammates — this invocation had no agent-spawning tool
available. Every finding below is grounded in a file actually read in this
repo, named inline.

### Executive Summary

Sound with revisions. The plan is unusually well-specified — real file paths,
per-step verify lines, falsifiable criteria, and an objective test that is
genuinely objective. Three defects would have made it fail on its own terms,
and all three are now fixed in the spec:

1. **The restore proof was vacuous.** `git diff --quiet scripts/verify.sh`
   ignores untracked files, and `scripts/verify.sh` is created by this plan.
   The mutation dogfood in step 15 would have reported a clean restore over an
   unrestored mutation. Now `cmp -s` against the scratchpad copy.
2. **The failing fixture would have been run as a real test.**
   `tests/run-all.sh` discovers with a bare `find tests -name 'test-*.sh'` and
   has no `tests/fixtures/` exclusion, so a fixture file named `test-*.sh`
   would land in the suite and make "run-all reports 0 failed" unsatisfiable.
   Now constrained by name plus a `find` assertion.
3. **Stage detection could recurse.** Every script in this repo resolves its
   root from `$0` (`tests/run-all.sh` line 1). A gate doing the same would,
   from inside a fixture, still find agentics' `marketplace.json`, re-enter
   `run-all.sh`, re-run `test-verify-gate.sh`, and re-invoke itself. Detection
   is now pinned to `$PWD` with a re-entry marker.

### Role-by-Role Findings

#### Architecture

Fit: sound — the skill belongs in `code-testing-agent` beside `tdd-loop`, and
the auto-detect-instead-of-generate call is right for a repo with no
`package.json`. Two concerns: (high) nothing carried `assets/verify.sh` into a
project other than agentics, and `${CLAUDE_PLUGIN_ROOT}` in a documented Bash
command is unrunnable — seven plugins here already ship a `bin/` wrapper for
this; step 5 now adds `install-verify-gate`. (medium) the marketplace stages
are an agentics-shaped special case inside a file sold as portable; acceptable
at three stages, but a `.verifyrc`/`verify.local.sh` extension hook is the
shape to reach for before a fourth accretes.

#### Completeness

Step 9 copied `SKILL.md` alone, leaving the project-local copy's
`references/` links dangling in exactly the worktree and Desktop environments
the copy exists to serve — now a directory copy with `diff -r` parity. Files
list omitted `tests/fixtures/README.md` and the guard-test registration; both
added. Fixture contents were unspecified (empty dirs are not committed by git;
the failing fixture's failure mechanism was never named) — both pinned down in
step 1.

#### Testability

Coverage is strong for a plan of this size. Gaps closed: the objective test
asserted "no stage after the failure runs" but never the *printed order* of
the four stages; and it never fixed the invocation form, so it could have
tested the gate against the repo root instead of the fixture. Remaining
accepted gap: no test covers a failing *marketplace* stage (only the unit
stage) — worth a third fixture later, not blocking. The 200/80 description
assertions duplicate `tests/plugins/test-description-budget.sh`, which already
sweeps every shipped `SKILL.md`; kept as a fast local signal, demoted in the
step's why.

#### Risk

Risk level: medium, concentrated entirely in the mutation loop. The untracked
`git diff` hole (above) is the critical one. Secondary: a crash mid-mutation
leaves a broken gate in the tree with no restore — now a `trap`. Tertiary:
scratchpad copies of working-tree source outliving the loop — now deleted
after a proven restore.

#### Conventions

Good fit. Fixture names match the existing `verify-gate-*` style, root-level
`tests/test-*.sh` has precedent (`test-checkbox-portability.sh`). One real
tension: `.claude/rules/testing.md` says fixtures model plugin *structure*,
not working behavior, and these two are runnable projects. That departure is
justified — you cannot exercise a gate against a structure — but it needed
saying in `tests/fixtures/README.md`, which step 1 now does. Also flagged:
step 11's why smuggled an 8-iteration loop policy into a `CLAUDE.md` step; the
bound moved to step 6, where the loop actually lives.

#### Product

Value fit: worth building as scoped. The user problem is concrete and
evidenced (billing-blocked CI proves nothing either way), success criteria are
falsifiable rather than restated tasks, and Next Steps correctly holds the
enforcement work out of scope. One unstated assumption made explicit: a
sentence in `CLAUDE.md` is honoured, not enforced — the plan now says so in
step 11 rather than letting a reader infer a hard gate. Added a revert path to
Verification; there was none.

#### Security

Exposure: low, but not none. `verify.sh` executes whatever tooling a project
declares, so running it in an untrusted clone is arbitrary code execution
(CWE-829, OWASP A08) — the SKILL.md must state it is for repos you already
trust, and the gate must not implicitly prepend `node_modules/.bin` to `PATH`.
`set -euo pipefail` with quoted expansions is required for a script that will
run in paths it did not choose. Added a `shellcheck` detection to the lint
stage, since the deliverable is itself shell. No secrets, no network, no authz
surface.

#### UX

User fit: the operator experience is the deliverable here, and "SKIP (not
configured)" is the right affordance — it distinguishes absent from passing,
which is the whole failure mode of hardcoded gates. Concern (medium): "browser-verify
UI changes at mobile and desktop widths" named no widths and no evidence
standard, so two runs would not be comparable. Step 6 now pins 390px and
1280px and requires measured evidence.

#### Accessibility

A11y compliance: the plan emitted screenshot paths as UI evidence with no
accessibility check at all. Step 6 now requires an axe run against the real
rendered page — never a Storybook iframe, which stalls — with the violation
count recorded in the VERIFICATION section. Both themes are required, since a
contrast regression typically lands in only one.

#### Frontend

Implementation fit: no components, no state, no bundle — the frontend surface
is the e2e stage's detection logic. One concern (medium, not applied as an
edit): Playwright detection should distinguish "no config" from "config
present, browsers not installed"; the second should SKIP with a distinct
message rather than failing the gate on a missing `npx playwright install`.
Recorded for the implementer to handle inside step 4's detection.

### Agreements & Conflicts

Confirmed concerns — raised independently by more than one lens:

- **Restore proof** — Risk and Testability both landed on `git diff --quiet`
  being unable to see the file it is asked about.
- **Fixture/runner collision** — Completeness and Conventions both reached it,
  from opposite directions (missing fixture spec, fixture policy).
- **Distribution of the gate** — Architecture and Product both noted the plan
  had no path from the plugin to a second repo.

No conflicts. The one tradeoff worth naming: Architecture prefers an extension
hook over marketplace stages baked into the portable file, while the plan's
"no generator, one file" decision prefers the baked-in form. Resolution: keep
the current shape at three stages, revisit at four — recorded in Decisions, not
changed.

### Highest-Risk Issues

1. Vacuous `git diff --quiet` restore proof on an untracked file (Risk) —
   fixed, `cmp -s` + `trap`.
2. Failing fixture auto-discovered by `tests/run-all.sh` (Completeness) —
   fixed, naming constraint + `find` assertion + criterion.
3. `$0`-relative detection causing unbounded gate recursion (Architecture) —
   fixed, `$PWD` detection + `VERIFY_GATE_ACTIVE` marker + criterion.
4. Project-local copy with dangling `references/` links (Completeness) —
   fixed, directory copy + `diff -r`.
5. No path to install the gate outside agentics (Architecture) — fixed,
   `bin/install-verify-gate`.

### Triage Outcome

Walkthrough skipped: background mode. All proposed edits applied.

**Applied**

- Steps 1, 2, 3, 4, 5, 6, 7, 9, 11, 15 — why/verify and action text.
- Decisions — `cmp -s` correction; new bullet naming the `verify.sh`
  duplication tradeoff.
- Files — `bin/install-verify-gate`, `tests/fixtures/README.md`,
  `tests/plugins/test-exitplanmode-guard.sh`; project-local entry widened to
  the directory.
- Tests — objective-test asserts widened with order and re-entry.
- Acceptance Criteria — five appended.
- Verification — `cmp` correction, re-entry proof, revert path.

**Recorded, not applied**

- Playwright "config present, browsers absent" SKIP branch (Frontend) — belongs
  in step 4's detection at implementation time.
- Third fixture for a failing marketplace stage (Testability) — follow-up.
- `.verifyrc` extension hook for project-specific stages (Architecture) —
  revisit at a fourth repo-specific stage.
