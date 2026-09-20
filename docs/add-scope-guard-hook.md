# Add a scope-guard hook for repo-wide formatters and bare stash pops

> One `npm run fix:all` reformatted about 190 untouched files and needed a guarded revert; one bare `git stash pop` restored an unrelated stash and created con...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Write `hooks/scope-guard.py` reading the PreToolUse payload from stdin and exiting 0 immediately for any payload that...
- Implement package-script resolution: for a command whose first token is `npm`, `pnpm`, `yarn`, or `bun`, **strip an o...
- Implement the formatter rule: block when the resolved command invokes a formatter or linter with `--write` or `--fix`...
- Implement the stash rule: block `git stash pop` and `git stash apply` with no stash reference, and pass when an expli...
- Emit blocks as exit 2 with a stderr message naming the command, the rule, and the safe alternative, and add the `.cla...
- Register the hook as a second command in the existing `PreToolUse` `Bash` matcher in `hooks.json` with a short timeou...
- Add `tests/plugins/test-scope-guard.sh` covering: both blocked patterns, each pattern's passing counterpart, script r...
- Document in the README: the two rules, the `.claude/no-scope-guard` opt-out, the desktop-app caveat that plugin hooks...
- Bump git-agent in `.claude-plugin/marketplace.json` — 4.18.0 if `harden-ship-preflight` has landed at 4.17.0, otherwi...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | the PreToolUse guard | Created |
| `kit/plugins/git-agent/hooks.json` | second command in the existing Bash matcher | Modified |
| `kit/plugins/git-agent/README.md` | the guard, its opt-out, the desktop caveat, and the lint-... | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | version entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump | Modified |
| `tests/plugins/test-scope-guard.sh` | block, pass, and fast-bail assertions | Created |

## How it works

Ship `git-agent/hooks/scope-guard.py`, a PreToolUse hook that blocks repo-wide formatter runs and index-less `git stash pop` before they execute, and document that the existing lint gate's `.claude/lint-gate.json` can name a test command.

The 2026-08-14 usage report records the two most expensive single incidents in the period, both from commands whose blast radius exceeded their intent: a repo-wide `npm run fix:all` that *"reformatted ~190 untouched files, requiring a guarded revert"*, and *"a bare `git stash pop` [that] restored an unrelated

The implementation proceeded through these steps: Write `hooks/scope-guard.py` reading the PreToolUse payload from stdin and exiting 0 immediately for any payload that...; Implement package-script resolution: for a command whose first token is `npm`, `pnpm`, `yarn`, or `bun`, **strip an o...; Implement the formatter rule: block when the resolved command invokes a formatter or linter with `--write` or `--fix`...; Implement the stash rule: block `git stash pop` and `git stash apply` with no stash reference, and pass when an expli...; Emit blocks as exit 2 with a stderr message naming the command, the rule, and the safe alternative, and add the `.cla....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
