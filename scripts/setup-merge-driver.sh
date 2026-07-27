#!/usr/bin/env bash
# Idempotent registration of the repo's custom merge drivers:
#   mkt-version — .claude-plugin/marketplace.json (scripts/merge-marketplace.mjs)
#   plans-index — docs/plans/index.html and docs/artifacts/index.html
#                                                 (scripts/merge-plans-index.mjs)
# Safe to run repeatedly — git config set is idempotent.
# Called automatically by the Claude Code SessionStart hook.
# Manual: bash scripts/setup-merge-driver.sh

set -euo pipefail

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

# Register driver paths against the MAIN worktree, not the current one —
# .git/config is shared across worktrees, and a path into a temporary
# .claude/worktrees/ checkout dangles once that worktree is removed.
MAIN_WORKTREE="$(git worktree list --porcelain | head -n 1 | sed 's/^worktree //')"
[ -d "$MAIN_WORKTREE" ] || MAIN_WORKTREE="$(git rev-parse --show-toplevel)"

MKT_DRIVER="${MAIN_WORKTREE}/scripts/merge-marketplace.mjs"
INDEX_DRIVER="${MAIN_WORKTREE}/scripts/merge-plans-index.mjs"

git config merge.mkt-version.name "marketplace.json version-aware merge"
git config merge.mkt-version.driver "node \"${MKT_DRIVER}\" %O %A %B"

git config merge.plans-index.name "gallery index union merge (plans + artifacts)"
git config merge.plans-index.driver "node \"${INDEX_DRIVER}\" %O %A %B"
