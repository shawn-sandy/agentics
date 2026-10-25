# Add a scope-guard hook for repo-wide formatters and bare stash pops

> Ships `git-agent/hooks/scope-guard.py`, a `PreToolUse` hook that blocks repo-wide formatter runs and index-less `git stash pop` before they execute, and documents that the existing lint gate's `lint-gate.json` can name a test command.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-scope-guard-hook](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/hooks/scope-guard.py` — `PreToolUse` hook intercepting Bash tool calls
- Blocks repo-wide formatter runs (e.g., `prettier --write .`, `eslint --fix .`) before they execute, surfacing a diff-scoped alternative
- Blocks `git stash pop` without an explicit stash ref when the index has uncommitted changes that would be overwritten
- Added test command documentation to `lint-gate.json` format
- Wired in `git-agent/hooks.json` with a `PreToolUse` entry
- Bumped `git-agent` with CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | Hook script — PreToolUse formatter and stash guard | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — PreToolUse entry | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — git-agent bump | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history | Modified |

## How it works

Repo-wide formatter runs (`prettier --write .`, `eslint --fix .`, `black .`) touch every file in the repository, not just the files changed by the current commit. When a Claude session has a PR open, this silently inflates the diff with formatting-only changes across unrelated files, making review harder and merging more likely to conflict.

The scope-guard hook intercepts these calls in the `PreToolUse` event before the Bash tool runs. It detects formatter invocations by matching known CLI names with glob-pattern arguments (`.`, `src/`, `**/*`) and blocks execution with an explanation. The message suggests the diff-scoped alternative: running the formatter only on staged files via `git diff --name-only --cached | xargs prettier --write`.

`git stash pop` without an explicit ref is equally dangerous when the index has uncommitted changes — the pop can silently overwrite them without a merge conflict marker. The hook blocks bare `git stash pop` calls and suggests `git stash pop stash@{0}` with the explicit ref.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook](plans/add-scope-guard-hook.md)
