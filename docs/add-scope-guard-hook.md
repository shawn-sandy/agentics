# Add a scope-guard hook for repo-wide formatters and bare stash pops

> Ship `git-agent/hooks/scope-guard.py`, a PreToolUse hook that blocks repo-wide formatter runs and index-less `git stash pop` before they execute, with package-script resolution to catch commands like `npm run fix:all`.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/hooks/scope-guard.py` — a PreToolUse hook with two blocking patterns: repo-wide formatter/linter runs (resolved through package scripts) and bare `git stash pop`/`git stash apply` with no stash reference
- Added package-script resolution that walks up to the git root to find the nearest `package.json` and resolves `npm`/`pnpm`/`yarn`/`bun` script invocations before pattern matching — catching `npm run fix:all` where the script is `prettier --write .`
- Registered the hook as a second command in `git-agent/hooks.json`'s existing `PreToolUse` Bash matcher (alongside `lint-before-commit.py`)
- Added `tests/plugins/test-scope-guard.sh` covering block/pass, script resolution, opt-out, non-Bash payloads, and false-positive prevention
- Documented both rules, the `.claude/no-scope-guard` opt-out, the desktop-app caveat (plugin hooks not registered in desktop sessions), and a `lint-gate.json` test-command example in the README
- Bumped git-agent version in `.claude-plugin/marketplace.json` with a CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | PreToolUse guard hook | Created |
| `tests/plugins/test-scope-guard.sh` | Test suite | Created |
| `kit/plugins/git-agent/hooks.json` | Added second command to Bash matcher | Modified |
| `kit/plugins/git-agent/README.md` | Rules, opt-out, desktop caveat, lint-gate example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump | Modified |

## How it works

The hook at `hooks/scope-guard.py` reads the PreToolUse JSON payload from stdin and exits 0 immediately for any non-`Bash` tool call, for any command whose first token is not a runner, formatter, or `git`, and for any command carrying none of the trigger tokens (`--write`, `--fix`, `stash`, or a package-runner prefix). This fast-bail prevents the hook from blocking `git commit -m "message mentioning fix:all"` or a `grep` that happens to mention a blocked pattern.

For package-runner commands (`npm`, `pnpm`, `yarn`, `bun`), the hook strips an optional `run` token and treats the next token as the script name, then walks up from the payload's `cwd` to the git root reading the first `package.json` that declares that script. The resolved script value — not the typed command — is what the formatter rule matches against. This covers both `npm run fix:all` and `yarn fix:all`, since stripping the optional `run` token makes both spellings equivalent.

The formatter rule blocks when the resolved command invokes a formatter or linter with `--write` or `--fix` and either no path operand or `.` as the operand. Commands naming any explicit path (`prettier --write src/`, `eslint --fix kit/plugins/git-agent`) pass through. The stash rule blocks `git stash pop` and `git stash apply` with no stash reference, and the block message quotes `git stash list` as the first remediation step.

Blocks exit 2 (the PreToolUse contract for returning a message to the model as actionable feedback) with a stderr message naming the command, the rule, and the safe alternative. A `.claude/no-scope-guard` file at the repo root disables every rule, mirroring the `.claude/no-lint-gate` escape hatch from `lint-before-commit.py`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
- Related: [kit/plugins/git-agent/hooks/scope-guard.py](../kit/plugins/git-agent/hooks/scope-guard.py)
- Related: [kit/plugins/git-agent/hooks/lint-before-commit.py](../kit/plugins/git-agent/hooks/lint-before-commit.py)
