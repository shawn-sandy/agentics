#!/usr/bin/env bash
# Idempotent registration of the marketplace.json merge driver.
# Safe to run repeatedly — git config set is idempotent.
# Called automatically by the Claude Code SessionStart hook.
# Manual: bash scripts/setup-merge-driver.sh

set -euo pipefail

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

TOPLEVEL="$(git rev-parse --show-toplevel)"
DRIVER_SCRIPT="${TOPLEVEL}/scripts/merge-marketplace.mjs"

git config merge.mkt-version.name "marketplace.json version-aware merge"
git config merge.mkt-version.driver "node \"${DRIVER_SCRIPT}\" %O %A %B"
