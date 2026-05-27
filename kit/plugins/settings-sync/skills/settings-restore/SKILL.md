---
name: settings-restore
description: "Restores Claude Code settings from a backup git repo. Pulls the latest config to ~/.claude/ with a confirmation step before overwriting. Use when the user asks to restore or import settings."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
argument-hint: "[repo-path]"
---

# Settings Restore

Restore Claude Code user settings from a dedicated backup git repository.
Pulls latest changes, shows a diff summary, and copies files back to
`~/.claude/` after user confirmation.

## When not to use

- To back up settings to a repo — use `settings-backup` instead.
- To compare settings without making changes.

## Reference

Load `references/file-manifest.md` from the plugin root for the complete list
of files to restore, opt-in targets, and exclusions.

## Steps

### Step 1 — Resolve the backup repo path

Determine the source repo using this priority order:

1. **Argument**: if the user provided a path (via `$ARGUMENTS` or in their
   message), expand `~` and use it directly.
2. **Config file**: read `~/.claude/settings-sync.json`. If it exists and
   contains a `"repoPath"` key, use that value.
3. **Interactive prompt**: use `AskUserQuestion` to ask the user for the repo
   path.

If no path can be resolved, output an error and **STOP**.

Verify the directory exists and is a git repo:
`git -C <repo-path> rev-parse --is-inside-work-tree`. If it fails, output:
"Not a git repo: `<repo-path>`. Run settings-backup first to initialize." and
**STOP**.

**Path safety:** always quote the resolved repo path in all shell commands
(git, rsync, cp, rm) to handle spaces and special characters.

### Step 2 — Pull latest from remote

Check if a remote exists: `git -C "<repo-path>" remote get-url origin 2>/dev/null`.

If a remote exists, run `git -C <repo-path> pull --ff-only`.

- If pull fails, warn: "Could not pull latest — remote may have diverged.
  Restoring from local copy. Run `git -C <repo-path> pull` manually to sync."
  Continue with the local state.

### Step 3 — Read config and build the file list

Read `~/.claude/settings-sync.json` to check for `"includeLocalSettings"`.

Build the list of files to restore from the repo. For each target in the
manifest, check if it exists in `<repo-path>`:

**Always restored (skip if not in repo):**
- `<repo-path>/settings.json` → `~/.claude/settings.json`
- `<repo-path>/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `<repo-path>/keybindings.json` → `~/.claude/keybindings.json`
- `<repo-path>/rules/` → `~/.claude/rules/`
- `<repo-path>/commands/` → `~/.claude/commands/`
- `<repo-path>/skills/` → `~/.claude/skills/`

**Conditionally restored:**
- `<repo-path>/settings.local.json` → `~/.claude/settings.local.json` — only
  if `"includeLocalSettings": true`

Track which files exist in the repo and which are missing.

### Step 4 — Generate diff summary

For each file/directory that exists in the repo, compare against the local
`~/.claude/` target:

**Files** — compare each file:
- **New**: exists in repo but not locally → label as `+ added`
- **Modified**: exists in both, content differs (`diff -q`) → label as `~ modified`
- **Unchanged**: exists in both, content matches → label as `= unchanged`
- **Deleted**: exists locally but **not** in backup → label as `- deleted`

**Directories** — list local and repo files, then classify each:
- Use `find` on both the repo subdir and the local `~/.claude/` subdir to get
  complete file lists, then compare to derive added/modified/unchanged/deleted
  counts. (`diff -rq` alone misses unchanged files and local-only deletions.)
- Summarize as: `rules/ — 5 files (1 new, 1 modified, 2 unchanged, 1 deleted)`

Present the summary:

```
Restore preview:
  + settings.json (new)
  ~ CLAUDE.md (modified)
  = keybindings.json (unchanged)
  ~ rules/ — 5 files (1 new, 1 modified, 2 unchanged, 1 deleted)
  + commands/ — 2 files (2 new)
  skills/ — not in backup (skipped)
```

**Important:** the `--delete` flag (rsync) and `rm -rf` (cp fallback) mean
files that exist locally in `rules/`, `commands/`, or `skills/` but are **not**
in the backup will be removed. Always surface these as `- deleted` in the
preview so the user knows what will be lost.

### Step 5 — Confirm with user

Use `AskUserQuestion`:

> "Restore these settings to `~/.claude/`? This will overwrite existing files
> and delete local files not present in the backup (see deleted items above)."

Options:
- "Restore all" — proceed with full restore
- "Restore new and modified only" — skip files marked as `unchanged`
- "Cancel" — abort without changes

**This step is always interactive.** If running in a context where prompting is
not possible, output: "Restore requires interactive confirmation. Run this
skill manually." and **STOP**.

### Step 6 — Copy files from repo to ~/.claude/

Ensure `~/.claude/` exists: `mkdir -p ~/.claude`.

Determine the copy method:

```bash
command -v rsync >/dev/null 2>&1
```

**If rsync is available:**

```bash
rsync -aL <repo-path>/settings.json ~/.claude/settings.json
rsync -aL <repo-path>/CLAUDE.md ~/.claude/CLAUDE.md
rsync -aL <repo-path>/keybindings.json ~/.claude/keybindings.json
rsync -aL --delete <repo-path>/rules/ ~/.claude/rules/
rsync -aL --delete <repo-path>/commands/ ~/.claude/commands/
rsync -aL --delete <repo-path>/skills/ ~/.claude/skills/
```

**If rsync is not available (cp fallback):**

For each file target: `cp -fL <repo-path>/<file> ~/.claude/<file>`.
For each directory target, remove then replace to mirror rsync `--delete`:

```bash
rm -rf ~/.claude/<dir> && cp -aL <repo-path>/<dir> ~/.claude/<dir>
```

If the `cp` fails after `rm -rf`, report the error immediately — the user can
re-run restore to recover from the backup repo.

Skip any source that does not exist in the repo — do not error.

If `includeLocalSettings` is true and `settings.local.json` exists in the repo,
copy it as well.

If the user chose "Restore new and modified only", skip files/directories where
the diff status was `unchanged`.

### Step 7 — Save config

If `~/.claude/settings-sync.json` does not exist or `repoPath` differs, write
it:

```json
{
  "repoPath": "/absolute/path/to/repo",
  "includeLocalSettings": false
}
```

Preserve any existing keys.

### Step 8 — Report

Output a summary:

```
Settings restored from <repo-path>.
  Restored: <count> files (<list>)
  Skipped (not in backup): <list or "none">
  Skipped (unchanged): <list or "none">

NOTE: Restored settings take effect after restarting Claude Code.
Restart your session or run `claude` again to pick up the changes.
```

**STOP after this step.**
