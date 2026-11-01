# Add a scope-guard hook for repo-wide formatters and bare stash pops

> Ship `scope-guard.py`, a PreToolUse hook in git-agent that blocks repo-wide formatter runs and index-less `git stash pop` before they execute.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/hooks/scope-guard.py`, a PreToolUse hook that blocks two blast-radius patterns: repo-wide formatter/linter runs (directly typed or via a package script) and bare `git stash pop`/`apply` with no explicit stash reference.
- Implemented package-script resolution: the hook walks up from the payload's cwd to the git root, reads the nearest `package.json`, and resolves `npm`/`pnpm`/`yarn`/`bun` script invocations before matching — covering both `yarn fix:all` and `yarn run fix:all` spellings.
- Added fast-bail logic so the hook exits 0 immediately for non-Bash payloads, commands with no trigger tokens, and blocked patterns appearing inside commit messages, grep arguments, or echoes.
- Added `.claude/no-scope-guard` opt-out flag checked at the repo root before any rule runs.
- Registered the hook as a second command in `hooks.json`'s existing `PreToolUse` Bash matcher, alongside `lint-before-commit.py`.
- Added `tests/plugins/test-scope-guard.sh` covering block, pass, script resolution, opt-out, non-Bash payload, and fast-bail cases.
- Documented both rules, the opt-out, the desktop-app caveat (plugin hooks don't register in desktop sessions), and a `lint-gate.json` test-command example in the git-agent README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | PreToolUse guard hook | Created |
| `kit/plugins/git-agent/hooks.json` | Added second command to Bash matcher | Modified |
| `kit/plugins/git-agent/README.md` | Rules, opt-out, desktop caveat, lint-gate example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump | Modified |
| `tests/plugins/test-scope-guard.sh` | Block, pass, and fast-bail assertions | Created |

## How it works

On every Bash tool call, the hook reads the PreToolUse JSON payload from stdin. It first checks if the tool name is `Bash` — any other tool exits 0 immediately. Then it checks if the command text contains any trigger token (`--write`, `--fix`, `stash`, or a package-runner prefix); if not, it exits 0 without reading any file.

For package-runner invocations (`npm`, `pnpm`, `yarn`, `bun`), the hook strips an optional `run` token and treats the next token as the script name. It walks upward from the command's `cwd` to the git root, reading the first `package.json` that declares that script, and substitutes the script's value as the effective command. A missing manifest, unreadable JSON, or absent script falls back to the typed text and never blocks.

The first-token rule prevents false positives: if the command's first token is not itself a runner, formatter, or `git`, the hook exits 0. This stops a `git commit -m "...fix:all..."` from triggering the formatter rule because `fix:all` appears in the message text.

Blocks exit 2 with a stderr message naming the command, the rule triggered, and the safe alternative. For the formatter rule, the safe alternative is a path-scoped invocation. For the stash rule, the message quotes `git stash list` as the first step. Exit 2 is the PreToolUse contract that returns the message to the model as actionable feedback.

The hook is CLI-only enforcement — plugin `hooks.json` files do not register in Claude Code desktop sessions, so the `CLAUDE.md` rules remain the desktop fallback.

## How to use it

The hook activates automatically when git-agent is installed in a CLI session. No configuration is required.

To opt out for a specific repo, create `.claude/no-scope-guard` at the repo root:
```bash
touch .claude/no-scope-guard
```

To add a test command to the lint gate (documented separately):
```json
// .claude/lint-gate.json
{"commands": ["npm run lint", "npm test"]}
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
- Related: `kit/plugins/git-agent/hooks/lint-before-commit.py` — the existing hook whose fast-bail and manifest-walk patterns scope-guard reuses
