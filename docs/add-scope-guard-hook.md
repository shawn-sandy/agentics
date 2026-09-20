# Add a scope-guard hook for repo-wide formatters and bare stash pops

> One `npm run fix:all` reformatted about 190 untouched files and needed a guarded revert; one bare `git stash pop` restored an unrelated stash and created con...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Write `hooks/scope-guard.py` reading the PreToolUse payload from stdin and exiting 0 immediately for any payload that is not a `Bash` tool call, for any command whose text contains none of the trigger tokens (`--write`, `--fix`, `stash`, or a package-runner prefix), and for any command whose first token is not itself a runner, formatter, or `git` — so a pattern appearing inside a `git commit -m` message, a `grep`, or an `echo` never matches.
- Implement package-script resolution: for a command whose first token is `npm`, `pnpm`, `yarn`, or `bun`, **strip an optional `run` token** and treat the next token as the script name, then walk up from the payload's cwd to the git root, read the first manifest declaring that script, and match against the script's value rather than the typed command. A missing manifest, unreadable JSON, or absent script resolves to the typed text and never blocks on its own.
- Implement the formatter rule: block when the resolved command invokes a formatter or linter with `--write` or `--fix` and either no path operand or `.` as the operand. A command naming any other path — `prettier --write src/`, `eslint --fix kit/plugins/git-agent` — passes.
- Implement the stash rule: block `git stash pop` and `git stash apply` with no stash reference, and pass when an explicit `stash@{N}` or index is given. The block message quotes `git stash list` as the first step.
- Emit blocks as exit 2 with a stderr message naming the command, the rule, and the safe alternative, and add the `.claude/no-scope-guard` opt-out checked at the repo root before any rule runs.
- Register the hook as a second command in the existing `PreToolUse` `Bash` matcher in `hooks.json` with a short timeout, leaving `lint-before-commit.py` and its 480s budget unchanged.
- Add `tests/plugins/test-scope-guard.sh` covering: both blocked patterns, each pattern's passing counterpart, script resolution both ways, the opt-out, the non-Bash payload, and the no-trigger-token fast bail — reusing the fixture helpers from `test-lint-before-commit.sh`.
- Document in the README: the two rules, the `.claude/no-scope-guard` opt-out, the desktop-app caveat that plugin hooks do not register there, and a `.claude/lint-gate.json` example naming a test command (`{"commands": ["npm run lint", "npm test"]}`) with a note that the gate compares against `HEAD` so a pre-existing failure never blocks.
- Bump git-agent in `.claude-plugin/marketplace.json` — 4.18.0 if `harden-ship-preflight` has landed at 4.17.0, otherwise 4.17.0 — and add the CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | the PreToolUse guard | Created |
| `kit/plugins/git-agent/hooks.json` | second command in the existing Bash matcher | Modified |
| `kit/plugins/git-agent/README.md` | the guard, its opt-out, the desktop caveat, and the lint-gate test-command example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | version entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump | Modified |
| `tests/plugins/test-scope-guard.sh` | block, pass, and fast-bail assertions | Created |

## How it works

Ship `git-agent/hooks/scope-guard.py`, a PreToolUse hook that blocks repo-wide formatter runs and index-less `git stash pop` before they execute, and document that the existing lint gate's `.claude/lint-gate.json` can name a test command.

The 2026-08-14 usage report records the two most expensive single incidents in the period, both from commands whose blast radius exceeded their intent: a repo-wide `npm run fix:all` that *"reformatted ~190 untouched files, requiring a guarded revert"*, and *"a bare `git stash pop` [that] restored an unrelated stash and created conflicts requiring recovery."* It also notes 47

The implementation proceeded through the following steps: Write `hooks/scope-guard.py` reading the PreToolUse payload from stdin and exiting 0 immediately for any payload that is not a `Bash` tool call, for any command whose text contains none of the trigger tokens (`--write`, `--fix`, `stash`, or a package-runner prefix), and for any command whose first token is not itself a runner, formatter, or `git` — so a pattern appearing inside a `git commit -m` message, a `grep`, or an `echo` never matches. Why: this hook runs on every Bash call in every repo that installs git-agent, so the cheap bail is a correctness constraint on the common path; and the first-token rule is what stops the observed false positive where a commit message merely describing a blocked command was refused. Verify: a payload for a non-Bash tool and a payload for `ls -la` each exit 0 having opened no file; `git commit -m "fixes npm run fix:all"` and `grep -r "prettier --write ." docs/` both exit 0.; Implement package-script resolution: for a command whose first token is `npm`, `pnpm`, `yarn`, or `bun`, **strip an optional `run` token** and treat the next token as the script name, then walk up from the payload's cwd to the git root, read the first manifest declaring that script, and match against the script's value rather than the typed command. A missing manifest, unreadable JSON, or absent script resolves to the typed text and never blocks on its own. Why: `npm run fix:all` is the command that caused the incident and carries none of the dangerous text itself, and every runner accepts both spellings — `yarn fix:all` and `yarn run fix:all` are the same invocation, and this repo's own `lint-before-commit.py` uses the `yarn run` form — so enumerating spellings leaves a bypass for whichever ones the list missed. Verify: a fixture whose `package.json` defines `"fix:all": "prettier --write ."` blocks on all eight forms (`npm run`, `pnpm run`, `yarn run`, `bun run` and each without `run`), and the same fixture with that script removed exits 0 for all eight.; Implement the formatter rule: block when the resolved command invokes a formatter or linter with `--write` or `--fix` and either no path operand or `.` as the operand. A command naming any other path — `prettier --write src/`, `eslint --fix kit/plugins/git-agent` — passes. Why: the constraint is blast radius, not the tool; formatting the files you touched is the documented correct action and must stay frictionless or the guard gets switched off. Verify: `prettier --write .` and `eslint --fix` block; `prettier --write src/app.ts` and `npx prettier --write kit/` exit 0.; Implement the stash rule: block `git stash pop` and `git stash apply` with no stash reference, and pass when an explicit `stash@{N}` or index is given. The block message quotes `git stash list` as the first step. Why: the recorded failure was a bare pop restoring an unrelated stash, and the remediation is a listing, not an abstinence — the message has to name the safe form or the user just re-runs it. Verify: `git stash pop` blocks and the message contains `git stash list`; `git stash pop stash@{2}` exits 0.; Emit blocks as exit 2 with a stderr message naming the command, the rule, and the safe alternative, and add the `.claude/no-scope-guard` opt-out checked at the repo root before any rule runs. Why: exit 2 is the PreToolUse contract that returns the message to the model as actionable feedback rather than a bare failure, and the opt-out mirrors `.claude/no-lint-gate` so a user who knows both files knows both escape hatches. Verify: a blocked command exits 2 with the alternative quoted in stderr; the same command with `.claude/no-scope-guard` present exits 0 silently.; Register the hook as a second command in the existing `PreToolUse` `Bash` matcher in `hooks.json` with a short timeout, leaving `lint-before-commit.py` and its 480s budget unchanged. Why: the matcher and the manifest `hooks` key are already correct, so this is one array entry, and the guard must not inherit a timeout sized for a lint baseline run. Verify: `claude plugin details git-agent` reports the same hook events as before with the added command present, and a `git commit` payload still reaches the lint gate..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
