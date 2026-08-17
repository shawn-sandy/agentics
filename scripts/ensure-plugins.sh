#!/usr/bin/env bash
# Install every agentics-kit marketplace plugin for this user, if missing.
#
#   bash scripts/ensure-plugins.sh
#
# Why this exists: a fresh container — Claude Code on the web, a codespace, a
# new machine — starts with an empty plugin store. The `enabledPlugins` block
# in `.claude/settings.json` only enables plugins that are already installed;
# it does not clone the marketplace or install anything. So a remote session
# comes up with none of the kit available, and every `/plan-agent:*`,
# `/git-agent:*`, and friend silently does not exist. This closes that gap.
#
# Called automatically by the Claude Code SessionStart hook. A copy lives at
# ~/.claude/hooks/ensure-agentics-plugins.sh for sessions outside this repo;
# this file is the canonical one, so edit here and re-copy.
#
# Restart required: a session already open when this runs loaded its skill
# registry at startup and will not see the new plugins until the next session.

set -uo pipefail

MARKETPLACE="agentics-kit"
SOURCE_REPO="shawn-sandy/agentics"
STATE="${HOME}/.claude/plugins/installed_plugins.json"
CACHE="${HOME}/.claude/plugins/marketplaces/${MARKETPLACE}"

command -v claude > /dev/null 2>&1 || exit 0

# Clone the marketplace only when it is absent. `marketplace add` is a cheap
# no-op once added, but it still hits the network, and this runs on every
# session start.
[ -d "$CACHE" ] || claude plugin marketplace add "$SOURCE_REPO" > /dev/null 2>&1

# Plugin ids come from the marketplace itself rather than a hardcoded list, so
# a plugin published later is picked up without touching this script. Both the
# installed and available sections of the JSON carry "<name>@<marketplace>"
# ids; grep unions them and installed_plugins.json below decides which are new.
# Removed plugins are not listed as available, so they are never resurrected.
ids="$(claude plugin list --available --json 2> /dev/null \
  | grep -o "\"[a-z0-9-]*@${MARKETPLACE}\"" | tr -d '"' | sort -u)"
[ -n "$ids" ] || exit 0

installed=0
for id in $ids; do
  grep -q "\"${id}\"" "$STATE" 2> /dev/null && continue
  # Default user scope on purpose. A project-scoped row shadows the user one
  # and pins a version per directory — see scripts/update-worktree-plugins.sh.
  claude plugin install "$id" > /dev/null 2>&1 && installed=$((installed + 1))
done

if [ "$installed" -gt 0 ]; then
  echo "OK: installed ${installed} ${MARKETPLACE} plugin(s) — restart the session to load them"
fi
exit 0
