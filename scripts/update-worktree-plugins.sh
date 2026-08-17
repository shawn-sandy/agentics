#!/usr/bin/env bash
# Update a project-scoped plugin pin in every worktree of this repo.
#
#   bash scripts/update-worktree-plugins.sh [plugin@marketplace] [--dry-run]
#
# Default plugin id: git-agent@agentics-kit
#
# Why this exists: `.claude/settings.json` is checked in and lists
# `enabledPlugins`, so every worktree is a distinct projectPath that resolves
# the plugin once, at first session, and pins that version in
# ~/.claude/plugins/installed_plugins.json. Nothing re-resolves it, and a
# project-scoped row shadows the user-scoped one — so a newly published skill
# stays invisible in older worktrees. `claude plugin update` has no --cwd and no
# bulk form, hence the loop.
#
# DANGER, and the reason for the has-a-row guard below: run
# `claude plugin update --scope project` from a directory with NO project-scoped
# row and it does not no-op. It silently updates some OTHER project's row —
# observed 2026-08-16 updating a worktree of an unrelated repo. So only
# directories that already own a row are ever entered.
#
# No version comparison here on purpose. The "latest" version cannot be read
# from a working-tree marketplace.json: worktrees check out different refs, so
# the main checkout's copy is whatever branch it happens to sit on (observed
# reporting 4.11.0 for a plugin at 4.19.0). `claude plugin update` resolves
# against the marketplace clone and prints "already at the latest version" when
# there is nothing to do, so it is the authority.
#
# Restart required: a session already open in an updated directory keeps the
# version it loaded at startup.

set -euo pipefail

PLUGIN="git-agent@agentics-kit"
DRY_RUN=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "Unknown flag: $arg" >&2; exit 2 ;;
    *) PLUGIN="$arg" ;;
  esac
done

INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
[ -f "$INSTALLED" ] || { echo "No $INSTALLED — nothing to update." >&2; exit 0; }

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
  echo "Not inside a git worktree." >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Live worktrees of THIS repo. Membership is by resolved path identity, not a
# substring match, so a similarly-named checkout elsewhere is never swept in.
git worktree list --porcelain | awk '/^worktree /{print $2}' > "$TMP/live.txt"

python3 - "$INSTALLED" "$PLUGIN" "$TMP/live.txt" > "$TMP/todo.txt" <<'PY'
import json, os, sys

installed, plugin, live_file = sys.argv[1:4]

live = {os.path.realpath(p.strip()) for p in open(live_file) if p.strip()}
rows = json.load(open(installed)).get("plugins", {}).get(plugin, [])

for e in rows:
    path = e.get("projectPath") or ""
    # The guard: only a directory that already owns a project row is entered.
    # An orphaned row (directory deleted) has no cwd to resolve against and is
    # skipped — clearing one needs `claude plugin uninstall` at that scope.
    if e.get("scope") != "project" or not path or not os.path.isdir(path):
        continue
    if os.path.realpath(path) in live:
        print("%s\t%s" % (e.get("version", "?"), path))
PY

COUNT="$(wc -l < "$TMP/todo.txt" | tr -d ' ')"

if [ "$COUNT" -eq 0 ]; then
  echo "No live worktree of this repo has a project-scoped pin for $PLUGIN."
  exit 0
fi

echo "$PLUGIN — $COUNT worktree(s) with a project pin:"
while IFS=$'\t' read -r version path; do
  [ -n "${path:-}" ] || continue
  printf '  %-8s %s\n' "$version" "$path"
done < "$TMP/todo.txt"
echo

if [ -n "$DRY_RUN" ]; then
  echo "Dry run — nothing changed."
  exit 0
fi

FAILED=0
while IFS=$'\t' read -r version path; do
  [ -n "${path:-}" ] || continue
  echo "=== $(basename "$path")"
  if ! (cd "$path" && claude plugin update "$PLUGIN" --scope project 2>&1 | sed 's/^/  /'); then
    echo "  FAILED — left at $version"
    FAILED=$((FAILED + 1))
  fi
done < "$TMP/todo.txt"

echo
if [ "$FAILED" -gt 0 ]; then
  echo "$FAILED worktree(s) failed to update." >&2
  exit 1
fi
echo "Done. Restart any open session in an updated worktree to apply."
