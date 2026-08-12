# settings-sync

Back up and restore Claude Code user settings to a dedicated git repo.
Routine-compatible for automated backups.

## Features

- **settings-backup** — copies settings to a git repo, commits, and pushes
- **settings-restore** — pulls from a backup repo and restores settings locally

### What gets backed up

| Target | Default |
|--------|---------|
| `settings.json` | Included |
| `CLAUDE.md` | Included |
| `keybindings.json` | Included |
| `rules/` | Included |
| `commands/` | Included |
| `skills/` | Included |
| `hooks/` | Included |
| `settings.local.json` | Opt-in |

Auto-generated files (sessions, caches, plugins, telemetry) are excluded.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install settings-sync@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/settings-sync
```

## Usage

This plugin is skills-only — there are no slash commands. Both skills are
auto-activated when your message matches their trigger description. You can
also pass a repo path inline as an argument.

### settings-backup (Skill — auto-activated)

Triggers when you ask to back up, save, or sync your Claude Code settings.

```
back up my claude settings to ~/dotfiles/claude-settings
```

Or with a previously configured repo:

```
back up my claude settings
```

You can pass the repo path inline:

```
back up my claude settings [repo-path]
```

### settings-restore (Skill — auto-activated)

Triggers when you ask to restore or import your Claude Code settings.

```
restore my claude settings from ~/dotfiles/claude-settings
```

You can pass the repo path or a clone URL inline:

```
restore my claude settings [repo-path-or-url]
```

Always interactive — requires user confirmation before overwriting local files.

### Setting up a new machine

There is no local backup repo on a fresh machine, so pass the **clone URL**:

```
restore my claude settings from https://github.com/you/claude-settings-backup.git
```

The repo is cloned to `~/.claude-settings-backup`, and the path is saved to
`~/.claude/settings-sync.json` for subsequent runs. Restart Claude Code
afterwards — plugins reinstall themselves from the `enabledPlugins` and
`extraKnownMarketplaces` entries in the restored `settings.json`.

Do **not** run `settings-backup` first on a new machine. It would copy the
empty local config over your backup and push it.

### Routine (automated backup)

Schedule a daily backup using `/schedule`, then choose **Create** and provide
the prompt:

```
Back up my Claude settings to ~/dotfiles/claude-settings
```

The backup skill runs without prompts when the repo path is configured in
`~/.claude/settings-sync.json`.

## Configuration

After first use, the repo path is stored in `~/.claude/settings-sync.json`:

```json
{
  "repoPath": "/Users/you/dotfiles/claude-settings",
  "includeLocalSettings": false
}
```

Set `"includeLocalSettings": true` to include `settings.local.json` in backups.

## Plugin Structure

```
settings-sync/
  .claude-plugin/
    plugin.json
  skills/
    settings-backup/
      SKILL.md
    settings-restore/
      SKILL.md
  references/
    file-manifest.md
  README.md
  CHANGELOG.md
```

## Components

### settings-backup (Skill)

Activates when the user asks to back up, save, or sync their settings.

Steps: resolve repo path, validate/init git repo, scan for secrets (first run),
copy files, write metadata, commit, push.

Handles missing files gracefully. Uses rsync with cp fallback. Logs no-change
runs to `.sync-log` for audit trail.

### settings-restore (Skill)

Activates when the user asks to restore, import, or recover their settings.

Steps: resolve the source (local path or clone URL), clone if needed, pull
latest, build the file list from the backup repo root (minus control files),
generate a file-level diff summary, confirm with user, copy files, report.

Always interactive — requires user confirmation before overwriting.
Warns that changes take effect after restarting Claude Code.
