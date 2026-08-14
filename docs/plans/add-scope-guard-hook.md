---
status: todo
type: feature
created: 2026-08-14
glance: One `npm run fix:all` reformatted about 190 untouched files and needed a guarded revert; one bare `git stash pop` restored an unrelated stash and created conflicts. Both are prevented by a rule that lives only in a personal CLAUDE.md. This ships the rule as a PreToolUse hook in git-agent — resolving npm scripts so `fix:all` is actually caught — and documents the existing lint gate's config as a test gate.
effort: medium
workflow: never
---

# Plan: Add a scope-guard hook for repo-wide formatters and bare stash pops

## Objective

Ship `git-agent/hooks/scope-guard.py`, a PreToolUse hook that blocks
repo-wide formatter runs and index-less `git stash pop` before they execute,
and document that the existing lint gate's `.claude/lint-gate.json` can name a
test command.

## Context

The 2026-08-14 usage report records the two most expensive single incidents in
the period, both from commands whose blast radius exceeded their intent: a
repo-wide `npm run fix:all` that *"reformatted ~190 untouched files, requiring
a guarded revert"*, and *"a bare `git stash pop` [that] restored an unrelated
stash and created conflicts requiring recovery."* It also notes 47
`user_rejected_action` events clustering on destructive commands — meaning the
enforcement mechanism today is a human at the permission prompt.

**The rule exists but is not shipped.** Both constraints are already written in
this user's global `CLAUDE.md`, under Formatting & Scope and Git. That governs
this user and nobody who installs these plugins, and it is advice a model can
weigh rather than a gate it cannot pass. A hook is the difference between a
prompt and a program.

**A user-level hook already covers part of this, with three gaps.**
`~/.claude/hooks/block-repo-wide-format.py` was written on 2026-08-14 and
blocks three literal patterns: `<runner> run fix:all`, `prettier|biome --write .`,
and `eslint|biome --fix .`. It is the right idea, and it settles the `yarn run`
question — its own pattern already spells the runner alternation with an
explicit `run`. Three gaps remain, and they are why this plan is still worth
landing:

1. **No script resolution.** It matches the literal string `fix:all`, so
   `npm run format` where `format` is `prettier --write .` passes untouched.
   The incident command happened to be named `fix:all`; the next one will not
   be.
2. **`run` is mandatory in its first pattern.** `yarn fix:all` — the bare form
   every runner accepts — does not match. Stripping an optional `run` token
   covers both spellings without enumerating either.
3. **It fires on non-executing mentions.** It inspects the raw command text, so
   `git commit -m "...fix:all..."` is blocked even though nothing runs. This
   was observed while authoring this plan: a commit whose *message* described
   the pattern was refused. A guard that blocks talking about a command is a
   guard that gets disabled.

It is also user-level, so it does not travel to anyone installing git-agent —
the original reason for shipping it in a plugin stands unchanged.

**It belongs in git-agent because the wiring already exists.** git-agent
registers a `PreToolUse` hook on `Bash` for `lint-before-commit.py`, and its
manifest carries the explicit `"hooks": "./hooks.json"` key added in 4.14.0
after a controlled A/B showed the root-level file is otherwise never read. A
second command in the same matcher costs one new file and no new registration.
The alternative — a new plugin for two guards — is a marketplace entry, a
README, a version line, and a CHANGELOG for 80 lines of Python.

**A literal-text match would miss the actual incident.** The report's own
suggested hook greps the raw command for `fix:all`. The command that caused the
damage was `npm run fix:all`, whose expansion lives in `package.json` — and the
general case, `npm run format` where the script is `prettier --write .`, has no
matching text at all. The hook therefore resolves `npm`/`pnpm`/`yarn`/`bun`
script invocations against the nearest manifest before matching, reusing the
upward walk `lint-before-commit.py` already implements. Without that step the
guard would pass the exact command it exists to stop.

Resolution strips an optional `run` token rather than enumerating invocation
spellings. Every runner accepts both — `yarn fix:all` and `yarn run fix:all`
are the same command, and `lint-before-commit.py` already normalizes Yarn to
`yarn run` at its `RUNNERS` table — so a list of literal forms leaves a bypass
for whichever spelling it omitted.

**Two patterns, not five.** Only the two with recorded incidents are blocked:

- a formatter or linter invoked with `--write` or `--fix` and no path argument,
  or with `.` as its path, whether typed directly or reached through a package
  script;
- `git stash pop` or `git stash apply` with no explicit stash reference.

`rm`, `curl`, `git reset --hard`, and `git checkout -- .` are deliberately
excluded. `rm` and `curl` are already denied outright at the permission layer
for this user, and the rest have no measured incident here. A guard that fires
on safe commands gets disabled within a week, which costs more than the two it
was catching.

**The desktop app will not run it.** Plugin `hooks.json` files are not
registered in Claude Code desktop sessions — measured across 627 hook
executions, where zero came from any plugin. This guard is therefore CLI-only
enforcement, and the `CLAUDE.md` rules remain the desktop fallback rather than
being retired when it ships. That belongs in the README next to the hook, so
nobody debugs a hook that was never wired.

**The lint gate is already a test gate and nobody knows.** Separately,
`lint-before-commit.py` accepts arbitrary commands through
`.claude/lint-gate.json` `{"commands": [...]}`, compares against `HEAD` so
pre-existing failures never block, and is documented in the README only as a
lint mechanism. The report's *"defects caught by CI and review bots instead of
locally"* finding — 100 `buggy_code` frictions against 95 `code_review_response`
sessions — needs no new machinery to address, only a documented example. It
ships here because it edits the same README section as the new hook.

## Files

- kit/plugins/git-agent/hooks/scope-guard.py (new) — the PreToolUse guard
- kit/plugins/git-agent/hooks.json (modified) — second command in the existing Bash matcher
- kit/plugins/git-agent/README.md (modified) — the guard, its opt-out, the desktop caveat, and the lint-gate test-command example
- kit/plugins/git-agent/CHANGELOG.md (modified) — version entry
- .claude-plugin/marketplace.json (modified) — git-agent version bump
- tests/plugins/test-scope-guard.sh (new) — block, pass, and fast-bail assertions

## Steps

1. Write `hooks/scope-guard.py` reading the PreToolUse payload from stdin and exiting 0 immediately for any payload that is not a `Bash` tool call, for any command whose text contains none of the trigger tokens (`--write`, `--fix`, `stash`, or a package-runner prefix), and for any command whose first token is not itself a runner, formatter, or `git` — so a pattern appearing inside a `git commit -m` message, a `grep`, or an `echo` never matches. Why: this hook runs on every Bash call in every repo that installs git-agent, so the cheap bail is a correctness constraint on the common path; and the first-token rule is what stops the observed false positive where a commit message merely describing a blocked command was refused. Verify: a payload for a non-Bash tool and a payload for `ls -la` each exit 0 having opened no file; `git commit -m "fixes npm run fix:all"` and `grep -r "prettier --write ." docs/` both exit 0.
2. Implement package-script resolution: for a command whose first token is `npm`, `pnpm`, `yarn`, or `bun`, **strip an optional `run` token** and treat the next token as the script name, then walk up from the payload's cwd to the git root, read the first manifest declaring that script, and match against the script's value rather than the typed command. A missing manifest, unreadable JSON, or absent script resolves to the typed text and never blocks on its own. Why: `npm run fix:all` is the command that caused the incident and carries none of the dangerous text itself, and every runner accepts both spellings — `yarn fix:all` and `yarn run fix:all` are the same invocation, and this repo's own `lint-before-commit.py` uses the `yarn run` form — so enumerating spellings leaves a bypass for whichever ones the list missed. Verify: a fixture whose `package.json` defines `"fix:all": "prettier --write ."` blocks on all eight forms (`npm run`, `pnpm run`, `yarn run`, `bun run` and each without `run`), and the same fixture with that script removed exits 0 for all eight.
3. Implement the formatter rule: block when the resolved command invokes a formatter or linter with `--write` or `--fix` and either no path operand or `.` as the operand. A command naming any other path — `prettier --write src/`, `eslint --fix kit/plugins/git-agent` — passes. Why: the constraint is blast radius, not the tool; formatting the files you touched is the documented correct action and must stay frictionless or the guard gets switched off. Verify: `prettier --write .` and `eslint --fix` block; `prettier --write src/app.ts` and `npx prettier --write kit/` exit 0.
4. Implement the stash rule: block `git stash pop` and `git stash apply` with no stash reference, and pass when an explicit `stash@{N}` or index is given. The block message quotes `git stash list` as the first step. Why: the recorded failure was a bare pop restoring an unrelated stash, and the remediation is a listing, not an abstinence — the message has to name the safe form or the user just re-runs it. Verify: `git stash pop` blocks and the message contains `git stash list`; `git stash pop stash@{2}` exits 0.
5. Emit blocks as exit 2 with a stderr message naming the command, the rule, and the safe alternative, and add the `.claude/no-scope-guard` opt-out checked at the repo root before any rule runs. Why: exit 2 is the PreToolUse contract that returns the message to the model as actionable feedback rather than a bare failure, and the opt-out mirrors `.claude/no-lint-gate` so a user who knows both files knows both escape hatches. Verify: a blocked command exits 2 with the alternative quoted in stderr; the same command with `.claude/no-scope-guard` present exits 0 silently.
6. Register the hook as a second command in the existing `PreToolUse` `Bash` matcher in `hooks.json` with a short timeout, leaving `lint-before-commit.py` and its 480s budget unchanged. Why: the matcher and the manifest `hooks` key are already correct, so this is one array entry, and the guard must not inherit a timeout sized for a lint baseline run. Verify: `claude plugin details git-agent` reports the same hook events as before with the added command present, and a `git commit` payload still reaches the lint gate.
7. Add `tests/plugins/test-scope-guard.sh` covering: both blocked patterns, each pattern's passing counterpart, script resolution both ways, the opt-out, the non-Bash payload, and the no-trigger-token fast bail — reusing the fixture helpers from `test-lint-before-commit.sh`. Why: every clause here is either a block that could over-fire or a pass that could under-fire, and an over-firing guard is the failure mode that gets the whole hook deleted. Verify: `bash tests/plugins/test-scope-guard.sh` reports zero failures, and commenting out either rule turns exactly its own checks red.
8. Document in the README: the two rules, the `.claude/no-scope-guard` opt-out, the desktop-app caveat that plugin hooks do not register there, and a `.claude/lint-gate.json` example naming a test command (`{"commands": ["npm run lint", "npm test"]}`) with a note that the gate compares against `HEAD` so a pre-existing failure never blocks. Why: an undocumented guard reads as a bug the first time it fires, and the lint gate's test capability already exists and is costing review round-trips purely for want of an example. Verify: the README section names both rules, both escape hatches, the desktop caveat, and the test-command example.
9. Bump git-agent in `.claude-plugin/marketplace.json` — 4.18.0 if `harden-ship-preflight` has landed at 4.17.0, otherwise 4.17.0 — and add the CHANGELOG entry. Why: the CI guard fails any PR whose touched plugin does not exceed the base branch version, and these two plans touch the same plugin from different branches. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan adds application code

- Objective: a repo-wide formatter reached through an npm script, and a bare `git stash pop`, are both blocked before executing, while their scoped equivalents run untouched. File: tests/plugins/test-scope-guard.sh; Type: smoke; Asserts: `npm run fix:all` resolving to `prettier --write .` exits 2, `prettier --write src/app.ts` exits 0, `git stash pop` exits 2 with `git stash list` in the message, and `git stash pop stash@{1}` exits 0; Run: bash tests/plugins/test-scope-guard.sh
- Unit: fast bail and non-executing mentions. File: tests/plugins/test-scope-guard.sh; Targets: the payload, token, and first-token pre-checks; Key cases: a non-Bash payload exits 0, a command with no trigger token exits 0, `git commit -m` and `echo`/`grep` carrying a blocked pattern in their text exit 0, and none of these read a manifest or the opt-out file
- Unit: script resolution. File: tests/plugins/test-scope-guard.sh; Targets: the manifest walk and the optional-`run` strip; Key cases: all eight runner spellings (`npm`/`pnpm`/`yarn`/`bun`, each with and without `run`) resolve the same script, nearest manifest wins over the root, a missing script resolves to the typed text, malformed JSON never blocks, and the walk stops at the git root
- Unit: formatter rule boundaries. File: tests/plugins/test-scope-guard.sh; Targets: path-operand detection; Key cases: `.` blocks, no operand blocks, an explicit path passes, a `--check`-only invocation passes, and a path containing a dot in its name is not mistaken for `.`
- Unit: opt-out and message contract. File: tests/plugins/test-scope-guard.sh; Targets: the exit paths; Key cases: `.claude/no-scope-guard` disables every rule, and each block writes the rule and its safe alternative to stderr with exit 2

## Acceptance Criteria

- [ ] `npm run fix:all` is blocked when its script resolves to a repo-wide formatter, and the block message names the scoped alternative.
- [ ] The same block applies to all eight runner spellings — `npm`/`pnpm`/`yarn`/`bun`, each with and without an explicit `run` token.
- [ ] A formatter invoked with an explicit path is never blocked.
- [ ] A bare `git stash pop` or `git stash apply` is blocked, and the message names `git stash list`; an explicit `stash@{N}` passes.
- [ ] No rule blocks `rm`, `curl`, `git reset`, or `git checkout` — the guard's scope is exactly the two documented patterns.
- [ ] A non-Bash payload, and a Bash command carrying no trigger token, exit 0 without reading any file.
- [ ] A blocked pattern appearing inside a `git commit -m` message, an `echo`, or a `grep` argument is not blocked — only an actual invocation is.
- [ ] `.claude/no-scope-guard` at the repo root disables every rule.
- [ ] Blocks exit 2 with the rule and the safe alternative on stderr.
- [ ] `lint-before-commit.py` still fires on `git commit` with its existing timeout unchanged.
- [ ] The README documents both rules, both escape hatches, the desktop-app caveat, and a `.claude/lint-gate.json` test-command example.
- [ ] `bash tests/plugins/test-scope-guard.sh` reports zero failures.
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Verification

Run `bash tests/plugins/test-scope-guard.sh` and
`bash tests/plugins/test-lint-before-commit.sh`, confirming zero failures in
both — the second proves the new array entry did not disturb the existing gate.
Then `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`
and confirm exit 0.

End-to-end, confirm registration directly rather than inferring it from a side
effect: run `claude plugin details git-agent` and read the component inventory,
confirming the `PreToolUse` entry now carries two commands. Then, in a terminal
CLI session with the plugin loaded, run `npm run fix:all` in a scratch repo
whose script is `prettier --write .` and confirm the tool call is refused with
the guard's message rather than executing — and that `npx prettier --write
src/` in the same repo runs normally.

Do not use a desktop session as the test surface: plugin hooks are not
registered there, so a silent pass proves nothing about this hook.

## Next Steps

- Extend the guard to codemods and bulk rewrites

  ```text
  In the agentics repo, kit/plugins/git-agent/hooks/scope-guard.py blocks
  repo-wide formatter runs and index-less git stash pops. Evaluate whether
  bulk rewrite tools — jscodeshift, ast-grep --rewrite, sed -i over a glob,
  codemod runners — belong under the same guard, and what the passing form of
  each looks like so a scoped invocation stays frictionless. Only add rules
  with a concrete failure the repo can point at; a guard that fires on safe
  commands gets disabled. If you add any, bump the git-agent version in
  .claude-plugin/marketplace.json, add a CHANGELOG entry, and extend
  tests/plugins/test-scope-guard.sh. Verify with
  `bash tests/plugins/test-scope-guard.sh` reporting zero failures.
  ```

## Resources

- ~/.claude/hooks/block-repo-wide-format.py — the user-level hook this supersedes; its pattern list is the starting point, its three gaps are the reason for this plan
- kit/plugins/git-agent/hooks/lint-before-commit.py — the fast-bail pattern, the manifest walk, and the opt-out convention being reused
- kit/plugins/git-agent/hooks.json — the existing PreToolUse Bash matcher
- docs/plans/fix-lint-gate-defects.md — the A/B that established plugins need an explicit `hooks` manifest key
- tests/plugins/test-lint-before-commit.sh — the fixture helpers the new test reuses
- ~/.claude/usage-data/report-2026-08-14-071004.html — the formatter and stash incidents motivating this plan
