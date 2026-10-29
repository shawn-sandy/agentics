# settings-sync

Back up and restore Claude Code user settings to a dedicated git repo.
Routine-compatible for automated backups.

## Features

- **settings-backup** — copies settings to a git repo, commits, and pushes, each
  machine to its own `machines/<name>` branch
- **settings-restore** — asks which machine to restore from, then restores its
  settings locally while keeping this machine's `permissions` and `autoMode`

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
| `agents/` | Included |
| `output-styles/` | Included |
| `scripts/` | Included |
| `reference/` | Included |
| `settings.local.json` | Opt-in |

Auto-generated files (sessions, caches, plugins, telemetry) are excluded.

## Installation

### Via Marketplace (recommended)

```bash
/plugin marketplace add shawn-sandy/agentics
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

A fresh machine has neither this plugin nor a local backup repo. Install the
plugin first (both commands under [Installation](#installation)), then pass
the **clone URL**:

```
restore my claude settings from https://github.com/you/claude-settings-backup.git
```

The repo is cloned to `~/.claude-settings-backup`, and the path is saved to
`~/.claude/settings-sync.json` for subsequent runs. Restart Claude Code
afterwards — plugins reinstall themselves from the `enabledPlugins` and
`extraKnownMarketplaces` entries in the restored `settings.json`.

Restore first, then back up. A first backup on a new machine creates that
machine's own branch, so it can no longer overwrite another machine's backup —
but run before a restore it would only save an empty config.

### Multiple machines

One backup repo holds every machine, one branch each:

- **Backup** writes to `machines/<machine>`, where `<machine>` is the
  `"machine"` key in `~/.claude/settings-sync.json`. With no key, the first run
  derives it from `hostname -s` (`Shawns-MacBook-Pro-2` becomes
  `shawns-macbook-pro-2`) and saves it, so a later macOS rename does not move
  the backup. Rename a machine by editing that key; it must match
  `^[a-z0-9][a-z0-9-]{0,62}$`. Each branch has one writer — the clone that
  created it, recorded in that clone's `git config settings-sync.branch` — so
  pushes never conflict and the backup never pulls or merges. If the branch
  already exists but this clone did not create it, or a push is rejected
  anyway, two machines share a name: the run stops and asks you to give one a
  distinct `"machine"`. If you re-cloned the backup repo on the same machine,
  the message prints the one `git config` command that claims the branch
  again.
- **Restore** lists the machines that have backed up (newest first) and asks
  which one to restore, recommending this machine's own name. A repo with no
  `machines/*` branch restores the checked-out branch, as 1.2 did, apart from
  the `settings.json` merge below. After copying, restore switches the clone
  back to this machine's own branch, so a backup that commits to whatever is
  checked out — a hand-written session-end script, say — never writes the
  machine you restored from.
- **Restore keeps this machine's `permissions` and `autoMode`.** In the two
  machines' backups this was designed from, those were the only `settings.json`
  keys holding machine-specific home paths (yours may also have them in keys
  such as `env` or `statusLine`, which restore takes from the backup), so restore
  takes every other key from the backup and these two from the local file — a
  key this machine lacks stays absent. A machine with no `settings.json` gets
  the backup's file unchanged. The merge needs `jq` (shipped at `/usr/bin/jq`
  on macOS 15 and later); without it, or with invalid JSON on either side,
  `settings.json` is skipped and left untouched rather than copied whole.
  Permission rules, deny rules included, therefore never travel by restore once
  a machine has its own `settings.json` — and installing this plugin on a new
  machine usually creates one (for `enabledPlugins`), so the source machine's
  rules do not arrive there either. The restore preview says how many rules it
  keeps and how many it does not apply.

To keep two Macs in step, change settings on one (the primary) and let it back
up; on the other, run `settings-restore` and pick the primary's machine. The
secondary keeps its own permission rules and its own branch.

**Upgrading from 1.2.** Update the plugin on every machine. Each machine's
first 1.3.0 backup creates and pushes its own branch — carrying any commits a
rejected 1.2 push left unpushed — even when nothing changed. `master` stays as
frozen 1.2 history; nothing deletes or rewrites it. A machine still on 1.2 keeps
writing `master` until it updates.

### Routine (automated backup)

Schedule a daily backup using `/schedule`, then choose **Create** and provide
the prompt:

```
Back up my Claude settings to ~/dotfiles/claude-settings
```

The backup skill runs without prompts when the repo path is configured in
`~/.claude/settings-sync.json`.

## Configuration

After first use, the repo path and machine name are stored in
`~/.claude/settings-sync.json`:

```json
{
  "repoPath": "/Users/you/dotfiles/claude-settings",
  "includeLocalSettings": false,
  "machine": "shawns-macbook-pro-2"
}
```

Set `"includeLocalSettings": true` to include `settings.local.json` in backups.
`"machine"` names this machine's backup branch, `machines/<machine>`. The file
itself is never backed up, and restore never writes `"machine"` — either would
hand a new machine another machine's branch.

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

Steps: resolve repo path and machine name, validate/init git repo, switch to
`machines/<machine>`, untrack already-ignored files, scan for secrets, copy
files, commit only when something changed, push the machine branch on every
run.

Handles missing files gracefully. Uses rsync with cp fallback. A no-change run
is logged locally to `.sync-log` (gitignored) and never committed, so the
repo's history shows only real settings changes.

### settings-restore (Skill)

Activates when the user asks to restore, import, or recover their settings.

Steps: resolve the source (local path or clone URL), clone if needed, choose
the machine to restore and check out its branch, build the file list from the
backup repo root (minus control files), generate a file-level diff summary,
confirm with user, copy files (merging `settings.json` so this machine keeps
its `permissions` and `autoMode`), verify, report.

Always interactive — requires user confirmation before overwriting.
Warns that changes take effect after restarting Claude Code.
