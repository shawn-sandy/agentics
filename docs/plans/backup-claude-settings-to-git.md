---
status: todo
type: chore
created: 2026-05-29
repo-name: claude-settings-backup
---

# Plan: Back up Claude Code settings to git

## Context

The `/settings-sync:settings-backup` skill was invoked (Stop-hook routine). It is a
write-operation skill — it copies user-authored Claude config into a dedicated git
repo, commits, and pushes. The global rule says write skills should execute directly
rather than plan, so this plan exists only to bootstrap out of the harness-forced plan
mode; once approved, the skill steps run directly.

Pre-flight (read-only) facts already gathered:

- **Repo:** `/Users/shawnsandy/claude-settings-backup` (exists, valid git repo)
- **Branch:** `master`
- **Remote:** `https://github.com/shawn-sandy/claude-settings-backup.git`
- **Has prior commits:** yes (`1f8b317`) → first-backup secret scan is skipped
- **Local settings:** excluded (`includeLocalSettings: false`)

## Objective

Sync the current `~/.claude` config files/dirs into the backup repo, commit on a dated
branch, fast-forward into `master`, and push to origin.

## Steps

1. **Copy default targets** into the repo (rsync `-aL`, `--delete` only on dirs):
   `settings.json`, `CLAUDE.md`, `keybindings.json` (files); `rules/`, `commands/`,
   `skills/` (dirs). Skip any missing source; prune repo copies of locally-deleted files.
   - *Verify:* `git -C <repo> status --porcelain` reflects only intended changes.

2. **Write `.settings-sync-meta.json`** (hostname, UTC timestamp, claude version, file list).
   - *Verify:* file present and valid JSON in repo root.

3. **Commit + fast-forward + push.** Create `backup/<date-time>` branch, commit, checkout
   `master`, `merge --ff-only`, delete the branch, then `git push`.
   - *Verify:* `git -C <repo> log --oneline -1` shows the new backup commit; push succeeds.
   - If no changes: append a `.sync-log` entry and report "no changes".

## Acceptance Criteria

- [ ] All existing default targets copied into the repo.
- [ ] `.settings-sync-meta.json` updated.
- [ ] Backup committed on `master` and pushed to origin (or "no changes" logged).
- [ ] No dangling `backup/*` branch left behind.

## Verification

`git -C /Users/shawnsandy/claude-settings-backup log --oneline -3` shows the new
`backup:` commit at the tip of `master`, and `git status` is clean. `git push` reports
the remote updated (or already up to date).
