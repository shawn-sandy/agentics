---
status: todo
type: chore
created: 2026-05-29
repo-name: claude-settings-backup
---

# Plan: Back up Claude Code settings to git

## Context

The `settings-sync:settings-backup` skill was triggered automatically by a Stop
hook at session end. It copies user-authored Claude Code config into a dedicated
git repo, commits, and pushes. This is a write-heavy routine (file copies + git
commit + push); per the global rule, write-operation skills execute directly
rather than producing a multi-step plan — so this record exists only because the
harness forced plan mode for the Stop hook.

## Observed state (read-only)

- Config: `~/.claude/settings-sync.json` → `repoPath: /Users/shawnsandy/claude-settings-backup`, `includeLocalSettings: false`.
- Backup repo exists, is a git repo on branch `master`, remote `github.com/shawn-sandy/claude-settings-backup.git`, has prior commits (not a first backup → no secret scan required).
- Sources present locally: `settings.json`, `CLAUDE.md`, `rules/`, `commands/`, `skills/`.
- Absent locally: `keybindings.json` (skip), `settings.local.json` (opt-out via `includeLocalSettings: false`).

## Steps

1. Copy the five present sources into the repo (rsync if available; single files without `--delete`, directories with `--delete`). Remove `keybindings.json` from the repo if it exists there but not locally. — *Why:* mirror current local state. *Verify:* `git -C <repo> status --porcelain` reflects only intended changes.
2. Write `.settings-sync-meta.json` (hostname, UTC timestamp, claude version, files included). — *Why:* backup provenance. *Verify:* file present and valid JSON.
3. Stage, commit on a `backup/<date-time>` branch, fast-forward merge into `master`, delete the branch; push to origin. If no changes, append to `.sync-log` instead. — *Why:* clean linear history. *Verify:* push succeeds; report short hash + message.

## Verification

- `git -C /Users/shawnsandy/claude-settings-backup log --oneline -1` shows the new backup commit.
- `git -C /Users/shawnsandy/claude-settings-backup status` is clean and ahead/in-sync with origin.
