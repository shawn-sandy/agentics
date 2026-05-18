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
| `settings.local.json` | Opt-in |

Auto-generated files (sessions, caches, plugins, telemetry) are excluded.

## Installation

```bash
# From marketplace
/plugin marketplace add shawn-sandy/agentics
/plugin install settings-sync@agentics-kit

# Local testing
claude --plugin-dir ./kit/plugins/settings-sync
```

## Usage

### Backup

```
back up my claude settings to ~/dotfiles/claude-settings
```

Or with a previously configured repo:

```
back up my claude settings
```

### Restore

```
restore my claude settings from ~/dotfiles/claude-settings
```

### Routine (automated backup)

Schedule a daily backup:

```
/schedule — "Back up my Claude settings to ~/dotfiles/claude-settings"
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

Activates when the user asks to back up, save, export, or sync their settings.

Steps: resolve repo path, validate/init git repo, scan for secrets (first run),
copy files, write metadata, commit, push.

Handles missing files gracefully. Uses rsync with cp fallback. Logs no-change
runs to `.sync-log` for audit trail.

### settings-restore (Skill)

Activates when the user asks to restore, import, or recover their settings.

Steps: resolve repo path, pull latest, generate file-level diff summary,
confirm with user, copy files, report.

Always interactive — requires user confirmation before overwriting.
Warns that changes take effect after restarting Claude Code.
