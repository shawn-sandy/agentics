# Add scope-guard PreToolUse hook to git-agent

> Adds a `scope-guard.py` PreToolUse hook to git-agent that blocks two specific anti-patterns — running a repo-wide formatter and bare stash pop — before they execute, with a `.claude/no-scope-guard` opt-out and a note that the hook is CLI-only.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/hooks/scope-guard.py` as a PreToolUse hook.
- Blocks two rules: (1) running a repo-wide formatter when only specific files were changed, (2) bare `git stash pop` without a stash reference.
- Package script resolution strips the optional `run` token before matching.
- Fast bail when the Bash command doesn't match known trigger patterns.
- `.claude/no-scope-guard` file opt-out for repos that need different behavior.
- Claude Code desktop app does not register plugin hooks (CLI-only feature).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | PreToolUse hook | Created |
| `kit/plugins/git-agent/plugin.json` | Plugin manifest | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |

## How it works

The scope-guard hook fires before any Bash tool call and checks the command against two patterns:

1. **Repo-wide formatter**: a `format` or `prettier --write` call targeting `.` or `**` when `git diff --name-only HEAD` shows only a few specific files. Running a repo-wide formatter when you only changed 2 files reformats unrelated code, creating noise in the diff and potential merge conflicts.

2. **Bare stash pop**: `git stash pop` without a stash reference can silently apply the wrong stash if there are multiple stashes. The hook requires `git stash pop stash@{0}` or similar explicit form.

Package script resolution handles the common case where the command is `npm run format` or `yarn format` — both are recognized as potentially repo-wide formatters.

The fast bail ensures the hook adds minimal latency for non-matching commands: it exits immediately when the command can't possibly match either trigger.

The `.claude/no-scope-guard` opt-out allows projects with legitimate repo-wide formatter workflows (e.g., a project where all formatting is always intentionally global) to disable the hook without changing the plugin.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
