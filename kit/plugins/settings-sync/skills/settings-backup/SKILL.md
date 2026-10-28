---
name: settings-backup
description: "Backs up Claude Code user settings to a git repo. Commits and pushes config files unattended; routine-compatible. Use when the user asks to back up or sync their Claude Code settings."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, ToolSearch, ExitPlanMode
argument-hint: "[repo-path]"
---

# Settings Backup

Back up Claude Code user settings to a dedicated git repository. Copies
user-authored configuration files, commits, and pushes. Designed to run
unattended as a Claude routine when the repo path is configured.

## When not to use

- To restore settings from a backup — use `settings-restore` instead.
- To compare local vs backed-up settings without changing anything.

## Reference

Load `references/file-manifest.md` from the plugin root for the complete list
of files to back up, opt-in targets, and exclusions.

## Steps

### Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

### Step 1 — Resolve the backup repo path

Determine the target repo using this priority order:

1. **Argument**: if the user provided a path (via `$ARGUMENTS` or in their
   message), expand `~` and use it directly.
2. **Config file**: read `~/.claude/settings-sync.json`. If it exists and
   contains a `"repoPath"` key, use that value.
3. **Interactive prompt**: if neither is available, use `AskUserQuestion` to ask
   the user for the repo path. If `AskUserQuestion` is unavailable (routine /
   unattended context), output: "No repo path configured. Set `repoPath` in
   `~/.claude/settings-sync.json` or pass a path argument." and **STOP**.

Once resolved, expand `~` to the full home directory path and confirm the
directory exists. If it does not exist:

- **Interactive**: ask the user if they'd like to create it with `mkdir -p`.
- **Routine / unattended**: output: "Repo directory does not exist:
  `<repo-path>`. Create it manually or update `repoPath` in
  `~/.claude/settings-sync.json`." and **STOP**.

**Path safety:** always quote the resolved repo path in all shell commands
(git, rsync, cp, rm) to handle spaces and special characters.

After resolving, persist the path to `~/.claude/settings-sync.json`:

```json
{
  "repoPath": "/absolute/path/to/repo",
  "includeLocalSettings": false
}
```

If the file already exists, update `repoPath` only — preserve other keys.

**Resolve the machine name.** Each machine backs up to its own branch,
`machines/<machine-name>`, so no two machines ever write the same branch. The
name is the `"machine"` key in `~/.claude/settings-sync.json`; with no key it
is derived once from `hostname -s` — lowercased, each run of other characters
turned into one `-`, outer `-` trimmed. The live hostname is not stable: macOS
renames a Mac over a name clash (`Shawn's MacBook Pro (2)`), so a derived name
is frozen in the file. The name ends up in a git ref and in shell commands and
the file is hand-editable, so the block rejects anything outside
`^[a-z0-9][a-z0-9-]{0,62}$` before any git command runs.

```bash
cfg="$HOME/.claude/settings-sync.json"
if grep -q '"machine"[[:space:]]*:' "$cfg" 2>/dev/null; then
  name="$(sed -n 's/.*"machine"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -n 1)"
else
  name="$(hostname -s | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz' \
    | sed 's/[^abcdefghijklmnopqrstuvwxyz0123456789-][^abcdefghijklmnopqrstuvwxyz0123456789-]*/-/g; s/^--*//; s/--*$//')"
fi
case "$name" in
  ''|-*|*[!abcdefghijklmnopqrstuvwxyz0123456789-]*) ok=no ;;
  *) ok=yes ;;
esac
if [ "$ok" = no ] || [ "${#name}" -gt 63 ]; then
  echo "Invalid machine name '$name'. Set \"machine\" in $cfg to lowercase letters, digits, and hyphens (at most 63, not starting with -)." >&2
  exit 1
fi
echo "$name"
```

A non-zero exit is a **STOP**. Otherwise the printed name is `<machine-name>`
for every later block. When `settings-sync.json` had no `"machine"` key, add
the printed name beside `repoPath` under the same preserve-other-keys rule —
silently, never as a question, so routines and interactive runs behave the
same. Renaming a machine is an edit to that file.

### Step 2 — Validate and initialize the repo

Run `git -C <repo-path> rev-parse --is-inside-work-tree`.

- If it fails, ask the user if they want to initialize a new repo with
  `git init <repo-path>`. On confirmation, run `git init`.
- If the directory is already a git repo, continue.

**Switch to the machine branch.** Every later block writes to whatever is
checked out, so this runs first. It never pulls, fast-forwards, or rebases
`machines/<machine-name>`: the branch has one writer, so a remote that is ahead
means a second writer, and merging it would hide the collision. That one
writer is the clone that created the branch, recorded in the clone's own
`git config settings-sync.branch`. A branch that already exists — on `origin`,
or locally because a restore checked it out — but was not created by this
clone belongs to another machine with the same name, so the block stops before
anything is committed. A new branch starts from the current `HEAD`, which
carries any commits a rejected 1.2 push left behind and, on a restored
machine, the source machine's history. An offline fetch is not an error.

```bash
repo="<repo-path>"
branch="machines/<machine-name>"
if git -C "$repo" remote get-url origin >/dev/null 2>&1; then
  git -C "$repo" fetch -q origin || echo "fetch failed — continuing with local refs" >&2
fi
if [ "$(git -C "$repo" config --get settings-sync.branch)" != "$branch" ]; then
  if git -C "$repo" rev-parse -q --verify "refs/heads/$branch" >/dev/null \
    || git -C "$repo" rev-parse -q --verify "refs/remotes/origin/$branch" >/dev/null; then
    echo "$branch already exists, but this clone did not create it — another machine may back up as '<machine-name>'. Set a distinct \"machine\" in ~/.claude/settings-sync.json. Only if this clone belongs to that machine (a re-cloned or reinstalled backup repo, or a name changed back), claim the branch with: git -C \"$repo\" config settings-sync.branch $branch" >&2
    exit 1
  fi
fi
if [ "$(git -C "$repo" symbolic-ref -q --short HEAD)" != "$branch" ]; then
  if git -C "$repo" rev-parse -q --verify "refs/heads/$branch" >/dev/null; then
    git -C "$repo" switch -q "$branch"
  elif git -C "$repo" rev-parse -q --verify "refs/remotes/origin/$branch" >/dev/null; then
    git -C "$repo" switch -q -c "$branch" --track "origin/$branch"
  else
    git -C "$repo" switch -q -c "$branch"
  fi || exit 1
fi
git -C "$repo" config settings-sync.branch "$branch"
```

A non-zero exit is a **STOP** with the block's or git's message: a name
another machine already uses, or a switch git refused (a working tree left
dirty by an interrupted run, with files the target branch would overwrite) —
never discard files someone may have added by hand. A clone that claimed its
branch can still be checked out elsewhere by a restore; the next backup
switches back to it.

**Ignore rules and already-tracked files.** The block below makes sure the
repo root `.gitignore` carries every rule in its list — creating the file if
missing, appending any individual rule it lacks — and then untracks whatever
those rules already cover. Checking only that `.gitignore` exists is not
enough: every repo created before `hooks/` became a target has one without
`__pycache__/`, and an ignore rule never untracks a file that is already in
git, so the `.pyc` files committed before the rule arrived kept riding along on
every run. `git rm --cached` drops only the index entry; the working file
stays on disk, and `--force` only skips the up-to-date check so a file someone
hand-staged in the backup repo is untracked too.

```bash
repo="<repo-path>"
touch "$repo/.gitignore"
[ -n "$(tail -c1 "$repo/.gitignore")" ] && echo >> "$repo/.gitignore"
for rule in .DS_Store '*.swp' '*.swo' '*~' '.*.swp' __pycache__/ .sync-log; do
  grep -qxF -- "$rule" "$repo/.gitignore" || echo "$rule" >> "$repo/.gitignore"
done
if git -C "$repo" ls-files -ci --exclude-standard | grep -q .; then
  git -C "$repo" ls-files -ci --exclude-standard -z | xargs -0 git -C "$repo" rm --cached --force --quiet --
fi
```

`.sync-log` is ignored because it is a local audit trail: Step 6 appends a
line to it on every no-change run, and committing that line would turn each of
those runs into a commit of its own.

### Step 3 — Read config and build the file list

Read `~/.claude/settings-sync.json` to check for `"includeLocalSettings"`.

Build the list of sources from the file manifest:

**Always included (skip silently if missing):**
- `~/.claude/settings.json`
- `~/.claude/CLAUDE.md`
- `~/.claude/keybindings.json`
- `~/.claude/rules/`
- `~/.claude/commands/`
- `~/.claude/skills/`
- `~/.claude/hooks/`
- `~/.claude/agents/`
- `~/.claude/output-styles/`
- `~/.claude/scripts/`
- `~/.claude/reference/`

**Conditionally included:**
- `~/.claude/settings.local.json` — only if `"includeLocalSettings": true`

For each source, check if it exists before attempting to copy. Track which
sources were found and which were skipped.

### Step 4 — Secret scan (every backup)

Run this scan on **every** backup, not just the first. A token added to
`settings.json` (or a hook script) after the initial commit would otherwise be
pushed unattended on every subsequent routine run with no scan and no warning.
The scan is a fast grep over a handful of text files — the cost is negligible.

Scan every source in the Step 3 file list (files directly, directories
recursively) for common secret patterns:

- `sk-` (API keys — covers `sk-ant-…` Anthropic keys and `sk_live_` Stripe keys)
- `ghp_`, `ghs_`, `gho_`, `github_pat_` (GitHub tokens)
- `glpat-` (GitLab tokens)
- `AKIA` (AWS access keys)
- `AIza` (Google API keys)
- `xoxb-`, `xoxp-` (Slack tokens)
- `hooks.slack.com/services/` (Slack webhook URLs)
- Strings that look like base64-encoded secrets (40+ chars of `[A-Za-z0-9+/=]`)

If any matches are found, warn the user:

> "Found potential secrets in <file> (patterns: sk-, ghp_). If this
> repo has a public remote, these could be exposed. Continue with backup?"

Use `AskUserQuestion` with options: "Continue", "Skip the flagged files",
"Cancel backup". **In routine mode** (no interactive prompts), log the warning
to `.sync-log` **with the matched pattern and file path** so the exposure is
discoverable later, then continue — the user accepted the risk by scheduling
the routine.

### Step 5 — Copy files to the repo

**Copy the targets.** One block copies every Step 3 source that exists. With
rsync, `-aL` follows symlinks and `--delete` is scoped to each target
subdirectory, never the repo root; without it, `cp` runs after an `rm -rf` of
the target subdirectory so deleted source files do not linger. A target —
file or folder — that does not exist locally is removed from the repo so the
backup reflects the current local state; a machine branch starts from another
branch's tree, and without this it would keep that branch's folders.
`settings.local.json` counts as missing unless `includeLocalSettings` is on.
Every path is quoted, and the loops run over literal word lists: the Bash tool
is zsh on macOS, where `for f in $files` does not split a string and the whole
block would silently copy nothing.

```bash
repo="<repo-path>"
if grep -q '"includeLocalSettings"[[:space:]]*:[[:space:]]*true' "$HOME/.claude/settings-sync.json" 2>/dev/null; then
  local_settings=yes
else
  local_settings=no
fi
if command -v rsync >/dev/null 2>&1; then has_rsync=yes; else has_rsync=no; fi
for f in settings.json CLAUDE.md keybindings.json settings.local.json; do
  if [ -f "$HOME/.claude/$f" ] && { [ "$f" != settings.local.json ] || [ "$local_settings" = yes ]; }; then
    if [ "$has_rsync" = yes ]; then rsync -aL "$HOME/.claude/$f" "$repo/$f"; else cp -fL "$HOME/.claude/$f" "$repo/$f"; fi
  elif [ -f "$repo/$f" ]; then
    rm "$repo/$f"
  fi
done
for d in rules commands skills hooks agents output-styles scripts reference; do
  if [ -d "$HOME/.claude/$d" ]; then
    if [ "$has_rsync" = yes ]; then rsync -aL --delete "$HOME/.claude/$d/" "$repo/$d/"; else rm -rf "$repo/$d" && cp -aL "$HOME/.claude/$d" "$repo/$d"; fi
  elif [ -e "$repo/$d" ]; then
    rm -rf "$repo/$d"
  fi
done
```

A symlinked skill folder (one the skills CLI installed elsewhere and linked
into `~/.claude/skills/`) is copied as a real folder. It still works after a
restore; only the CLI's link to it is lost.

**Entries that are not targets.** The repo root may hold entries that no
Step 3 source produced — left behind by an older version of this skill, or
added by hand. Nothing above removes them, and `settings-restore` copies every
root entry it finds, so a stale `plans/` comes back on every new machine until
someone notices. List them:

```bash
for p in "<repo-path>"/* "<repo-path>"/.*; do
  [ -e "$p" ] || continue
  e="$(basename "$p")"
  case " . .. .git .gitignore .sync-log .settings-sync-meta.json settings.json CLAUDE.md keybindings.json settings.local.json rules commands skills hooks agents output-styles scripts reference " in
    *" $e "*) ;;
    *) echo "$e" ;;
  esac
done
```

Do **not** delete them — a hand-added entry is deliberate. Carry the list to
Step 7 so the user can remove each one from the repo or add it to the
manifest.

### Step 6 — Commit only real changes

**Commit only real changes.** Stage everything, then ask git whether anything
is actually staged before writing a single byte of metadata. The old order —
write a fresh timestamp into `.settings-sync-meta.json`, then check for
changes — made every run a commit: 4,477 of one real repo's 4,601 commits
changed nothing but that timestamp, and `git log` could no longer show when a
setting changed. Now a no-change run appends one line to the local, gitignored
`.sync-log` and touches nothing git tracks. A real change writes the metadata
(hostname, UTC timestamp, `claude --version`, and the top-level entries the
backup holds, each JSON-escaped so a stray root entry with a quote in its name
cannot corrupt the file) and commits it together with the copied files.

```bash
repo="<repo-path>"
json_escape() { sed 's/\\/\\\\/g; s/"/\\"/g'; }
git -C "$repo" add -A
if git -C "$repo" diff --cached --quiet; then
  printf '[%s] no changes — backup skipped (hostname: %s)\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(hostname)" >> "$repo/.sync-log"
  echo no-change
else
  {
    printf '{\n  "hostname": "%s",\n  "timestamp": "%s",\n  "claudeVersion": "%s",\n  "filesIncluded": [\n' \
      "$(hostname | json_escape)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$({ claude --version 2>/dev/null || echo unknown; } | json_escape)"
    git -C "$repo" ls-files -z | tr '\0' '\n' | cut -d/ -f1 | grep -vx -e .gitignore -e .settings-sync-meta.json | sort -u \
      | json_escape | awk 'NR > 1 { printf ",\n" } { printf "    \"%s\"", $0 } END { print "" }'
    printf '  ]\n}\n'
  } > "$repo/.settings-sync-meta.json"
  git -C "$repo" add .settings-sync-meta.json \
    && git -C "$repo" commit -q -m "backup: Claude settings $(date +%Y-%m-%d\ %H:%M)" \
    && echo committed
fi
```

After `no-change`, output: "No settings changes since last backup. Logged
locally to .sync-log (not committed)." — and push anyway.

**Push the machine branch.** This runs after both `committed` and
`no-change`. A machine's first 1.3.0 run is often a no-change run, and its
branch — carrying any commits a rejected 1.2 push stranded — still has to reach
`origin`; when nothing is ahead, the push is a no-op. A rejection on a branch
only this machine writes means another clone or machine uses the same name, so
the block names that collision instead of offering a pull.

```bash
repo="<repo-path>"
branch="machines/<machine-name>"
if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
  echo no-remote
elif git -C "$repo" push -q -u origin "$branch"; then
  echo pushed
elif git -C "$repo" fetch -q origin "$branch" 2>/dev/null \
  && ! git -C "$repo" merge-base --is-ancestor FETCH_HEAD "$branch"; then
  echo "Push rejected: origin's $branch has commits this clone never made. Either another clone or machine backs up as '<machine-name>' — set a distinct \"machine\" in ~/.claude/settings-sync.json on one of them — or the branch was edited elsewhere (on github.com, or from another clone). Only in that second case, and only if no other machine uses this name, realign this clone once: git -C \"$repo\" fetch origin && git -C \"$repo\" reset --hard origin/$branch" >&2
  exit 1
else
  echo "Push of $branch failed — see git's message above." >&2
  exit 1
fi
```

A non-zero exit is a **STOP** with the block's message. Never pull, rebase,
force-push, or rename the machine to get past it: merging would restart the
overwrite this branch layout exists to prevent, and a silent rename would
leave the other machine's restore pointing at a branch that stopped updating.
The realign command in the message is the user's to run, after they confirm
the branch was edited on purpose: it drops this clone's unpushed backup
commits, and the next backup copies this machine's settings again on top of
the edited branch.

### Step 7 — Report

Output a summary:

```
Settings backup complete.
  Repo: <repo-path>
  Machine: <machine-name>
  Branch: machines/<machine-name>
  Files backed up: <count> (<list of names>)
  Skipped (not found): <list or "none">
  Not a backup target (left in repo): <list or "none">
  Commit: <short hash> — <commit message>, or "none — no changes"
  Pushed: yes/no remote/failed
```

**STOP after this step.**
