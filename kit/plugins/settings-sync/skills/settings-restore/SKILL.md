---
name: settings-restore
description: "Restores Claude Code settings from a backup repo or clone URL. Clones on a new machine, then confirms before overwriting ~/.claude/. Use when the user asks to restore settings or set up a new machine."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, ToolSearch, ExitPlanMode
argument-hint: "[repo-path-or-url]"
---

# Settings Restore

Restore Claude Code user settings from a dedicated backup git repository.
Accepts a local repo path or a clone URL — the URL form bootstraps a **new
machine**, where no local copy exists yet. Asks which machine's branch to
restore, pulls it, shows a diff summary, and copies files back to `~/.claude/`
after user confirmation — keeping this machine's own permission rules.

## When not to use

- To back up settings to a repo — use `settings-backup` instead.
- To compare settings without making changes.

## Reference

Load `references/file-manifest.md` from the plugin root for the complete list
of files to restore, opt-in targets, and exclusions.

## Steps

### Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

### Step 1 — Resolve the backup source

The source may be a **local path** or a **remote URL**. On a new machine there
is no local repo yet — the URL form is the bootstrap path.

Determine the source using this priority order:

1. **Argument**: if the user provided a path or URL (via `$ARGUMENTS` or in
   their message), use it. Expand `~` for paths.
2. **Config file**: read `~/.claude/settings-sync.json`. If it exists and
   contains a `"repoPath"` key, use that value.
3. **Interactive prompt**: use `AskUserQuestion` to ask for the backup repo —
   accepting either a local path or a clone URL.

If nothing can be resolved, output an error and **STOP**.

**If the value is a URL** (starts with `https://`, `git@`, `ssh://`, or
`http://`), clone it to `~/.claude-settings-backup` and use that as the repo
path.

**First, derive `<safe-url>` — before anything is displayed or logged.** A clone
URL may carry credentials in its userinfo, and every branch below can emit a
diagnostic naming the URL. Redact once, here, and use `<safe-url>` in **all**
user-facing text and `.sync-log` entries; keep the original solely as the
argument to `git clone`.

Take the authority — the text after `//` up to the next `/`, `?`, or `#` — and
if it contains `@`, replace everything before its last `@` with `***`. Scope the
replacement to the authority so a later `@` in a path or query is untouched:

```text
https://alice:ghp_ABC123@github.com/you/backup.git  ->  https://***@github.com/you/backup.git
https://github.com/you/backup.git                   ->  unchanged (no userinfo)
https://github.com/you/repo.git?ref=a@b             ->  unchanged (@ is not in the authority)
```

Then clone:

```bash
git clone "<url>" "$HOME/.claude-settings-backup"
```

**Reject plaintext `http://` by default.** Restored `hooks/` scripts are
executed by Claude Code on next start, so an unencrypted clone is a
code-injection path, not merely an eavesdropping one. Warn and require explicit
confirmation via `AskUserQuestion` before cloning over `http://`; **STOP** if
the user declines.

If `~/.claude-settings-backup` already exists:

- It is a git repo whose `origin` matches the URL → reuse it; Step 2 pulls.
- It is a git repo with a **different** origin, or not a repo at all → output:
  "`~/.claude-settings-backup` already exists and is not a clone of
  `<safe-url>`. Remove it or pass a different local path." and **STOP**. Never
  overwrite it.

If the clone fails (auth, network, bad URL), report git's error and **STOP** —
but scrub it first. Git echoes the URL back inside its own error text,
credentials included, so apply the same redaction to that text before showing
or logging it.

**If the value is a local path**, verify it is a git repo:
`git -C "<repo-path>" rev-parse --is-inside-work-tree`. If it fails, output:

> "No backup repo at `<repo-path>`. Pass the clone URL of your backup repo
> instead (e.g. `https://github.com/you/claude-settings-backup.git`) and it
> will be cloned to `~/.claude-settings-backup`."

Then **STOP**. Do **not** suggest running `settings-backup` — on a machine with
no settings yet it would only back up an empty config to a new branch.

**Path safety:** always quote the resolved repo path in all shell commands
(git, rsync, cp, rm) to handle spaces and special characters.

### Step 2 — Choose the machine and pull latest

Since 1.3.0, `settings-backup` writes each machine to its own
`machines/<name>` branch. A 1.2 repo has only the branch it always had.

**List machine branches.** Fetches `origin` when there is one — an offline
fetch only warns — then prints every machine with a branch, local or on
`origin`, newest backup first, one name per line. Branch names come from the
remote and the chosen one becomes shell text, so names outside the machine
pattern are never listed:

```bash
if git -C "<repo-path>" remote get-url origin >/dev/null 2>&1; then
  git -C "<repo-path>" fetch --quiet origin || echo "Could not fetch origin — listing local refs only." >&2
fi
git -C "<repo-path>" for-each-ref --sort=-committerdate --format='%(refname)' \
  refs/remotes/origin/machines refs/heads/machines |
  sed 's#^refs/remotes/origin/machines/##; s#^refs/heads/machines/##' |
  LC_ALL=C grep -E '^[a-z0-9][a-z0-9-]{0,62}$' | awk '!seen[$0]++'
```

**If it prints nothing**, this is a 1.2 repo — pull the checked-out branch as
before. If a remote exists, run `git -C "<repo-path>" pull --ff-only`.

- If pull fails, warn: "Could not pull latest — remote may have diverged.
  Restoring from local copy. Run `git -C "<repo-path>" pull` manually to sync."
  Continue with the local state.

**If it prints names**, ask with `AskUserQuestion` which machine to restore
from. Recommend this machine's own `"machine"` from
`~/.claude/settings-sync.json` when it is set and listed, otherwise the first
(newest) name. Offer up to four names; Other covers the rest. Never offer the
legacy `master` branch — it holds whichever machine last pushed under 1.2,
the overwritten state per-machine branches exist to escape.

**Check out the chosen machine.** Substitute the answer for `<machine-name>`
(an answer containing `'` is never a valid name — reject it without running
the block). The block rejects any name outside `^[a-z0-9][a-z0-9-]{0,62}$`
before git runs, switches to `machines/<name>` — creating a tracking branch
when only `origin` has it — and pulls:

```bash
name='<machine-name>'
[[ "$name" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || { echo "Invalid machine name: '$name'" >&2; exit 1; }
git -C "<repo-path>" switch "machines/$name" || exit 1
if git -C "<repo-path>" remote get-url origin >/dev/null 2>&1; then
  git -C "<repo-path>" pull --ff-only ||
    echo "Could not pull latest — restoring from the local copy of machines/$name." >&2
fi
```

A non-zero exit (an invalid name, or a switch git refused — a dirty working
tree, say) means **STOP** and show the block's message.

### Step 3 — Build the file list from the repo

Restore what the backup actually contains — not a fixed list. Backup captures
whatever the manifest resolved to on the source machine, and that set grows;
a hardcoded list here would silently strand the extras.

**List the repo root.** Restore every entry there except these control files,
which belong to the repo and never to `~/.claude/`:

- `.git/`
- `.gitignore`
- `.sync-log`
- `.settings-sync-meta.json`

Every entry maps to the same name under `~/.claude/`:
`<repo-path>/<entry>` → `~/.claude/<entry>`.

**Validate every entry before it is used as a path.** These names come from the
repo, and Step 6 feeds them to `rm -rf` and `rsync --delete`. Accept an entry
only if it is a plain relative name — no `/`, no `..`, not starting with `-`
(which `rsync` and `rm` would read as an option). Skip and report anything else
rather than expanding the destructive operation outside `~/.claude/`.

Do **not** drive this list from `filesIncluded` in `.settings-sync-meta.json`.
That array records what the last backup run copied, which is a subset of the
repo whenever anything was added by hand or by an older version — those entries
would never come back. Read the meta file only for provenance (hostname,
timestamp, Claude version) to show in the preview.

**Conditional target.** `settings.local.json` is restored **only** if
`~/.claude/settings-sync.json` exists and sets `"includeLocalSettings": true` —
even when it appears in `filesIncluded` or the repo root. On a new machine that
config file does not exist yet, so the default is to skip it.

Track which entries exist in the repo and which are missing.

### Step 4 — Generate diff summary

For each file/directory that exists in the repo, compare against the local
`~/.claude/` target:

**Files** — compare each file:
- **New**: exists in repo but not locally → label as `+ added`
- **Modified**: exists in both, content differs (`diff -q`) → label as `~ modified`
- **Unchanged**: exists in both, content matches → label as `= unchanged`
- **Deleted**: exists locally but **not** in backup → label as `- deleted`

`settings.json` is compared against the output of Step 6's **Keep this
machine's permissions.** block, not the repo copy — that output is what gets
written, so a backup differing only in those kept keys shows `= unchanged`.
Run the block here only to compare (`diff -q <(…block…) ~/.claude/settings.json`);
write nothing under `~/.claude/` until Step 6, so a Cancel leaves no file. If
the block exits non-zero, show `! settings.json (<its error> — will not be
restored)`; Step 6 then records it as FAILED and leaves the local file alone.
When the backup's `permissions` or `autoMode` differ from what is kept, say so
on that line — `(keeps this machine's permissions: 12 allow, 2 deny; the
backup's 40 allow, 5 deny are not applied)` — so the user sees, before
confirming, that the source machine's rules (deny rules included) will not
arrive. This matters most on a new machine where installing this plugin
already created a `settings.json` without any `permissions`.

**Directories** — list local and repo files, then classify each:
- Use `find` on both the repo subdir and the local `~/.claude/` subdir to get
  complete file lists, then compare to derive added/modified/unchanged/deleted
  counts. (`diff -rq` alone misses unchanged files and local-only deletions.)
- Summarize as: `rules/ — 5 files (1 new, 1 modified, 2 unchanged, 1 deleted)`

Present the summary:

```
Restore preview:
  Machine: beta (branch machines/beta)
  + settings.json (new)
  ~ CLAUDE.md (modified)
  = keybindings.json (unchanged)
  ~ rules/ — 5 files (1 new, 1 modified, 2 unchanged, 1 deleted)
  + commands/ — 2 files (2 new)
  skills/ — not in backup (skipped)
```

Here and in the Step 9 report, a 1.2 repo names the checked-out branch
instead: `Machine: none (1.2 repo, branch master)`.

**Important:** the `--delete` flag (rsync) and `rm -rf` (cp fallback) mean that
for **every directory in the Step 3 list**, local files not present in the
backup are removed. Derive the deleted entries from that same list — never from
a fixed set of directory names, or a directory added to the backup later
(`hooks/` among them) would be wiped without ever appearing in the preview.
Always surface these as `- deleted` so the user knows what will be lost.

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

Work through the list built in Step 3, treating each entry as a file or a
directory — except `settings.json`, which is never copied whole (below).

**If rsync is available:**

```bash
# file entry
rsync -aL "<repo-path>/<file>" "$HOME/.claude/<file>"
# directory entry — trailing slashes and --delete mirror the backup exactly
rsync -aL --delete "<repo-path>/<dir>/" "$HOME/.claude/<dir>/"
```

**If rsync is not available (cp fallback):**

For each file target: `cp -fL "<repo-path>/<file>" "$HOME/.claude/<file>"`.
For each directory target, remove then replace to mirror rsync `--delete`:

```bash
rm -rf "$HOME/.claude/<dir>" && cp -aL "<repo-path>/<dir>" "$HOME/.claude/<dir>"
```

Quote both sides. `~` does not expand inside quotes, so use `$HOME` for the
destination.

Restore executable bits as stored — `hooks/` scripts are invoked directly by
Claude Code and are inert without them (`-a` preserves this on both paths).

If the `cp` fails after `rm -rf`, report the error immediately — the user can
re-run restore to recover from the backup repo.

Skip any source that does not exist in the repo — do not error.

**`settings.json` keeps this machine's `permissions` and `autoMode`.** Only
those two keys carry machine-specific home paths — another machine's allow
rules name its own `/Users/<name>/...`; every other key, hooks included, is
portable. The cost is deliberate: once a machine has its own `settings.json`,
permission rules (deny rules included) never travel by restore.

**Keep this machine's permissions.** Prints the backup's `settings.json` with
`permissions` and `autoMode` taken from this machine's file, and dropped where
this machine has none. With no local `settings.json` (a new machine) it prints
the backup file unchanged. Invalid JSON in either file, or no `jq`, exits
non-zero:

```bash
mine="$HOME/.claude/settings.json"
if [ ! -e "$mine" ]; then
  cat "<repo-path>/settings.json"
elif ! command -v jq >/dev/null 2>&1; then
  echo "jq not found — install it to restore settings.json." >&2
  false
else
  jq -e --slurpfile here "$mine" '
    reduce ("permissions", "autoMode") as $k (.;
      if ($here[0] | has($k)) then .[$k] = $here[0][$k] else del(.[$k]) end)
  ' "<repo-path>/settings.json"
fi
```

Write its output to `"$HOME/.claude/.settings.json.restore"` and, on exit 0,
copy that file to `"$HOME/.claude/settings.json.new"` and `mv` the copy onto
`"$HOME/.claude/settings.json"` — one atomic replace, so a crash never leaves a
half-written file — keeping `.settings.json.restore` for Step 7. On a non-zero exit, delete the temp file, leave the local file
untouched, and record `FAILED: settings.json (<the block's error>)` — never
fall back to copying the backup file, which would silently drop this machine's
rules.

If `includeLocalSettings` is true and `settings.local.json` exists in the repo,
copy it as well.

If the user chose "Restore new and modified only", skip files/directories where
the diff status was `unchanged`.

### Step 7 — Verify the restore

The copy is not the result — verify it. A failed rsync entry, a `cp` error
that scrolled past, or a lost executable bit leaves a partial restore that
would otherwise be reported as complete.

Re-run the Step 4 comparison for **every entry that was restored** (skip
entries the user excluded in Step 5):

- **Files** — compare against the repo copy with `diff -q`. Anything other
  than identical → `FAILED: <entry>`.
- **`settings.json`** — `diff -q` the restored file against
  `"$HOME/.claude/.settings.json.restore"`, then delete that temp file. It was
  computed from this machine's file *before* the write, so a wholesale copy of
  the backup that lost this machine's rules compares different. Never re-run
  the block for this: run over the restored file, it reads back whatever rules
  that file now holds and would verify the very loss it should catch. The repo
  copy is no reference either — it still holds the source machine's rules.
- **Directories** — repeat the same `find`-based comparison from Step 4.
  Every file must now classify as `unchanged` — any added, modified, or
  deleted remainder → `FAILED: <entry>`, listing the differing paths.

**Executable bits.** If `hooks/` was restored, verify no script lost its
execute bit. Measure against the backup, not against a blanket rule — a hook
run through an interpreter (`python3 hook.py`) is legitimately non-executable
and must not be reported:

```bash
src="<repo-path>/hooks"
find -L "$src" -type f -perm -u+x | while IFS= read -r f; do
  rel="${f#"$src"/}"
  [ -x "$HOME/.claude/hooks/$rel" ] || echo "$rel"
done
```

Empty output passes. Every path it prints is
`FAILED: hooks/<file> (lost execute bit — executable in the backup, not
locally; a non-executable hook is silently inert)`.

Collect the results:

- **Verified** — entries that now compare identical (and, for `hooks/`, kept
  the execute bits the backup has).
- **FAILED** — everything else, each with a one-line reason.

Step 9 reports only these verified results — never the planned list from
Step 3 or the preview counts from Step 4. If anything is FAILED, the restore
is **incomplete** and the report must say so.

### Step 8 — Save config

If `~/.claude/settings-sync.json` does not exist or `repoPath` differs, write
it:

```json
{
  "repoPath": "/absolute/path/to/repo",
  "includeLocalSettings": false
}
```

Preserve any existing keys.

Never add a `"machine"` key — an existing one is this machine's own and is
preserved like any other key. That name picks the branch `settings-backup`
pushes to; a new machine that inherited the source machine's name would push
to that machine's branch.

**Switch back to this machine's branch.** Step 2 checked out the chosen
machine's branch, and the clone must not stay there: anything that commits to
whatever is checked out — a scheduled 1.2 backup, a hand-written session-end
script — would push this machine's settings over the other machine's backup.
One real restore did exactly that. Return the clone to the branch it claimed
(`git config settings-sync.branch`, set by this machine's first 1.3.0 backup).
A clone that claims nothing has never backed up and stays put, so its first
backup still starts from the restored machine's history.

```bash
own="$(git -C "<repo-path>" config --get settings-sync.branch)"
if [ -n "$own" ] && [ "$(git -C "<repo-path>" symbolic-ref -q --short HEAD)" != "$own" ]; then
  git -C "<repo-path>" switch -q "$own" || exit 1
fi
```

A non-zero exit leaves the clone on the restored machine's branch: say so in
the Step 9 report, with the command to run before the next backup —
`git -C "<repo-path>" switch <own branch>`. The files in `~/.claude/` are
already restored either way.

### Step 9 — Report

This step is reached only through Step 7 — every count and list below comes
from its verified results, never from the Step 3 list or the Step 4 preview.

If Step 7 recorded any FAILED entries, lead with them and say the restore is
incomplete:

```
Restore INCOMPLETE — verification failed for <n> of <total> entries.
  Machine: <name> (branch machines/<name>)
  FAILED: <entry> (<reason>)
  Verified: <count> files (<list>)
  Skipped (not in backup): <list or "none">
  Skipped (unchanged): <list or "none">

Re-run restore to retry the failed entries — the backup repo is unchanged.
```

Otherwise output:

```
Settings restored and verified from <repo-path>.
  Machine: <name> (branch machines/<name>)
  Verified: <count> files (<list>)
  Skipped (not in backup): <list or "none">
  Skipped (unchanged): <list or "none">

NOTE: Restored settings take effect after restarting Claude Code.
Restart your session or run `claude` again to pick up the changes.
```

If the repo was cloned in Step 1, name the clone location so the user knows
where it landed.

On a **new machine**, add:

```
Plugins are not part of the backup — settings.json carries `enabledPlugins`
and `extraKnownMarketplaces`, so Claude Code reinstalls them on next start.
```

**STOP after this step.**
