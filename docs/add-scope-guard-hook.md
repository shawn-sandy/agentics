# Add a scope-guard hook for repo-wide formatters and bare stash pops

> One `npm run fix:all` reformatted about 190 untouched files and needed a guarded revert; one bare `git stash pop` restored an unrelated stash and created conflicts. Both are prevented by a PreToolUse hook in git-agent that resolves npm scripts so `fix:all` is actually caught.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/hooks/scope-guard.py`: PreToolUse hook blocking repo-wide formatter runs and index-less `git stash pop`; resolves npm/pnpm/yarn/bun scripts against the nearest `package.json` before matching; strips an optional `run` token to handle both `yarn fix:all` and `yarn run fix:all`; exits 0 immediately for non-Bash payloads, non-triggering commands, and patterns inside commit messages/grep/echo arguments.
- Registered `scope-guard.py` as a second command in the existing `PreToolUse` Bash matcher in `hooks.json` with a short timeout; `lint-before-commit.py` and its 480s budget are unchanged.
- Added `.claude/no-scope-guard` opt-out checked at the repo root before any rule runs.
- Added `tests/plugins/test-scope-guard.sh`: blocked patterns, passing counterparts, all eight runner spellings, opt-out, non-Bash payload, fast-bail path.
- Documented both rules, both escape hatches, desktop-app caveat (plugin hooks do not register in Claude Code desktop sessions), and `.claude/lint-gate.json` test-command example in `README.md`.
- Bumped git-agent 4.17.0 → 4.18.0 (contingent on `harden-ship-preflight` landing first).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | PreToolUse guard | Created |
| `kit/plugins/git-agent/hooks.json` | Second command in Bash matcher | Modified |
| `kit/plugins/git-agent/README.md` | Rules, opt-out, desktop caveat, test-gate example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.18.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent → 4.18.0 | Modified |
| `tests/plugins/test-scope-guard.sh` | Block, pass, and fast-bail assertions | Created |

## How it works

Two patterns with recorded incidents are blocked:

1. **Formatter rule**: a formatter or linter invoked with `--write` or `--fix` and either no path operand or `.` as the operand — whether typed directly or reached through a package script. `prettier --write src/app.ts` passes; `prettier --write .` blocks.

2. **Stash rule**: `git stash pop` or `git stash apply` with no stash reference. `git stash pop stash@{2}` passes; bare `git stash pop` blocks with a message quoting `git stash list` as the first step.

Package script resolution: for `npm run fix:all`, the hook walks up from the cwd to the git root, reads the nearest `package.json`, and matches the script's value (`prettier --write .`) rather than the typed command. The optional `run` token is stripped so both `yarn fix:all` and `yarn run fix:all` resolve the same way. A missing manifest or absent script resolves to the typed text and never blocks on its own.

Blocks exit 2 with the rule and the safe alternative on stderr so the model receives actionable feedback.

## How to use it

The hook fires automatically in CLI sessions when git-agent is installed. Create `.claude/no-scope-guard` at the repo root to disable all rules for a session. The desktop app does not register plugin hooks — the existing `CLAUDE.md` rules remain the desktop fallback.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `744f6e14` | 2026-08-14 | feat(git-agent): scope-guard hook — block repo-wide formatters and bare stash pops (4.18.0) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
