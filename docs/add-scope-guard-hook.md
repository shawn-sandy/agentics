# Add a scope-guard hook for repo-wide formatters and bare stash pops

> Shipped `git-agent/hooks/scope-guard.py`, a PreToolUse hook that blocks repo-wide formatter runs and index-less `git stash pop` before they execute, with package-script resolution so `npm run fix:all` is caught even when the dangerous text is hidden in `package.json`.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/hooks/scope-guard.py`, a PreToolUse hook with: a fast-bail path for non-Bash payloads and commands with no trigger tokens; package-script resolution that strips an optional `run` token and walks up from cwd to git root to resolve the script value from the nearest `package.json`; a formatter rule that blocks `--write`/`--fix` with no path operand or `.` as the operand; a stash rule that blocks `git stash pop`/`apply` with no explicit `stash@{N}` reference; and a `.claude/no-scope-guard` opt-out at the repo root.
- Registered the hook as a second command in the existing `PreToolUse` Bash matcher in `kit/plugins/git-agent/hooks.json` with a short timeout, leaving `lint-before-commit.py` and its 480s budget unchanged.
- Added `tests/plugins/test-scope-guard.sh` covering all block/pass/fast-bail cases, script resolution across all eight runner spellings, the opt-out, and non-executing mentions.
- Updated `kit/plugins/git-agent/README.md` with both rules, both escape hatches, the desktop-app caveat (plugin hooks do not register in desktop sessions), and a `.claude/lint-gate.json` test-command example.
- Bumped git-agent version and added a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | PreToolUse guard for repo-wide formatters and bare stash pops | Created |
| `kit/plugins/git-agent/hooks.json` | Second command in existing Bash matcher | Modified |
| `kit/plugins/git-agent/README.md` | Guard docs, opt-out, desktop caveat, lint-gate test-command example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump | Modified |
| `tests/plugins/test-scope-guard.sh` | Block, pass, fast-bail, and resolution assertions | Created |

## How it works

The guard addresses two specific incidents recorded in the 2026-08-14 usage report: a `npm run fix:all` that reformatted ~190 untouched files (requiring a guarded revert), and a bare `git stash pop` that restored an unrelated stash and created conflicts. A user-level hook already existed at `~/.claude/hooks/block-repo-wide-format.py` but had three gaps: no script resolution (so `npm run format` where the script is `prettier --write .` passed untouched), `run` was mandatory in its first pattern (so `yarn fix:all` bypassed it), and it fired on non-executing mentions in commit messages.

The fast-bail path runs first on every Bash call. The hook exits 0 immediately for non-Bash tool calls, for commands whose first token is not a runner/formatter/`git`, and for commands with no trigger tokens (`--write`, `--fix`, `stash`, or a package-runner prefix). This last check is what stops `git commit -m "fixes npm run fix:all"` from being refused — the commit message carries the pattern but the command does not execute a formatter.

Package-script resolution handles the incident command. For `npm`/`pnpm`/`yarn`/`bun` invocations, the hook strips an optional `run` token (covering both `yarn fix:all` and `yarn run fix:all`) and treats the next token as the script name. It then walks up from the payload's `cwd` to the git root, reads the first `package.json` declaring that script, and matches against the script's value. A missing manifest, unreadable JSON, or absent script resolves to the typed text and never blocks on its own.

The formatter rule blocks when the resolved command invokes a formatter or linter with `--write` or `--fix` and either no path operand or `.` as the operand. An explicit path — `prettier --write src/app.ts` — passes. The stash rule blocks bare `git stash pop` and `git stash apply` and prints `git stash list` in the block message (the actual remediation step). An explicit `stash@{N}` or integer index passes. Both rules are skipped entirely when `.claude/no-scope-guard` exists at the repo root.

The hook is CLI-only enforcement: plugin `hooks.json` files are not registered in Claude Code desktop sessions. The `CLAUDE.md` rules remain the desktop fallback. This caveat is documented in the README next to the hook.

The README change bundled the lint-gate documentation improvement: `lint-before-commit.py` already accepts arbitrary commands via `.claude/lint-gate.json` `{"commands": [...]}` and compares against `HEAD` so pre-existing failures never block — but it was documented only as a lint mechanism. An example naming a test command (`{"commands": ["npm run lint", "npm test"]}`) was added.

## How to use it

The guard activates automatically when git-agent is loaded (CLI sessions only; not desktop).

**Formatter rule:** Running `npm run fix:all` (or any of the eight runner/`run` spellings) is blocked when the script resolves to a repo-wide formatter. Running `prettier --write src/` passes.

**Stash rule:** `git stash pop` is blocked. `git stash pop stash@{2}` passes. The block message quotes `git stash list` as the first step.

**Opt-out:** Create `.claude/no-scope-guard` at the repo root to disable both rules.

**Lint gate as test gate:** Add `{"commands": ["npm run lint", "npm test"]}` to `.claude/lint-gate.json` to run tests before every commit (failures against `HEAD` never block).

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
