# Add a scope-guard hook for repo-wide formatters and bare stash pops

> Ships `git-agent/hooks/scope-guard.py`, a PreToolUse hook that blocks repo-wide formatter runs (including npm script invocations that resolve to one) and bare `git stash pop` commands before they execute.

<!-- generated:start -->

**Status:** Shipped 2026-08-14  **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/hooks/scope-guard.py` — PreToolUse guard with two rules: (1) blocks formatters/linters invoked with `--write`/`--fix` and no path or `.` as the path, whether typed directly or resolved through a package script; (2) blocks `git stash pop`/`apply` with no explicit stash reference.
- Implemented package-script resolution: strips an optional `run` token, walks up from the cwd to the git root, reads the first `package.json` declaring the script, and matches against the script's value — catching `npm run fix:all` even though it carries none of the dangerous text itself.
- Added fast-bail for non-Bash payloads and commands with no trigger tokens; first-token rule prevents `git commit -m "...fix:all..."` from falsely matching.
- Added `.claude/no-scope-guard` opt-out at the repo root; blocks exit 2 with the rule and safe alternative on stderr.
- Registered as a second command in the existing `PreToolUse` Bash matcher in `hooks.json` with a short timeout.
- Added `tests/plugins/test-scope-guard.sh` covering both blocked patterns, scoped counterparts, script resolution for all eight runner spellings, opt-out, non-Bash payloads, and fast-bail.
- Updated README with both rules, both escape hatches, the desktop-app caveat (plugin hooks not registered in desktop sessions), and a `.claude/lint-gate.json` test-command example.
- Bumped `git-agent` to a new version in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/hooks/scope-guard.py` | PreToolUse guard | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-scope-guard.sh` | Smoke test | Created |

## How it works

The hook's fast path exits 0 immediately for any non-Bash payload, any command whose first token is not a runner/formatter/`git`, and any command with no trigger tokens — so `git commit -m "...fix:all..."` and `grep -r "prettier --write ."` pass without reading any file.

For npm/pnpm/yarn/bun invocations the hook strips an optional `run` token and resolves the script name against the nearest `package.json` in the upward walk to the git root. This catches the actual incident pattern (`npm run fix:all` expanding to `prettier --write .`) while leaving scoped invocations (`prettier --write src/`) untouched. All eight runner spellings (`npm`/`pnpm`/`yarn`/`bun` × with/without `run`) resolve identically.

The stash rule blocks `git stash pop` and `git stash apply` with no explicit `stash@{N}` reference and includes `git stash list` in its block message, pointing to the safe form.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
