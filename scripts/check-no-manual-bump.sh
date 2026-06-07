#!/usr/bin/env bash
# check-no-manual-bump.sh — Rejects PRs that manually bump plugin versions
#
# Version bumps are handled automatically by CI after merge to main.
# This guard ensures no one accidentally bumps versions in their branch,
# which would conflict with the CI-assigned version.
#
# USAGE:
#   ./scripts/check-no-manual-bump.sh [registry-file] [base-branch]
#
# DEFAULTS:
#   registry-file  .claude-plugin/marketplace.json
#   base-branch    main
#
# ENVIRONMENT OVERRIDES (take precedence over positional args):
#   VERSION_GUARD_REGISTRY     — path to JSON registry file
#   VERSION_GUARD_BASE_BRANCH  — branch to compare against (default: main)
#   VERSION_GUARD_NO_FETCH=1   — skip git fetch; use cached origin state

set -euo pipefail

REGISTRY="${VERSION_GUARD_REGISTRY:-${1:-.claude-plugin/marketplace.json}}"
BASE_BRANCH="${VERSION_GUARD_BASE_BRANCH:-${2:-main}}"
NO_FETCH="${VERSION_GUARD_NO_FETCH:-0}"
REMOTE_BASE="origin/${BASE_BRANCH}"

# ── Prerequisites ─────────────────────────────────────────────────────────────

if [[ ! -f "$REGISTRY" ]]; then
  echo "INFO: Registry not found ($REGISTRY) — skipping guard."
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not found in PATH." >&2
  exit 1
fi

# ── Fetch base branch ────────────────────────────────────────────────────────

if [[ "$NO_FETCH" != "1" ]]; then
  if ! git fetch origin "$BASE_BRANCH" --quiet 2>/dev/null; then
    echo "WARNING: Could not fetch $REMOTE_BASE — skipping guard."
    exit 0
  fi
fi

BASE_REGISTRY=$(git show "${REMOTE_BASE}:${REGISTRY}" 2>/dev/null || echo "")
if [[ -z "$BASE_REGISTRY" ]]; then
  echo "INFO: Registry not found on $BASE_BRANCH — nothing to compare."
  exit 0
fi

# ── Compare plugin versions ──────────────────────────────────────────────────

ERRORS=0

while IFS='|' read -r name branch_ver; do
  [[ -z "$name" ]] && continue

  base_ver=$(echo "$BASE_REGISTRY" | jq -r --arg n "$name" \
    '.plugins[] | select(.name==$n) | .version' 2>/dev/null || echo "")

  # New plugin — initial version is expected
  if [[ -z "$base_ver" ]]; then
    echo "OK: $name (new plugin, version $branch_ver)"
    continue
  fi

  if [[ "$branch_ver" != "$base_ver" ]]; then
    echo "ERROR: $name — manual version bump detected ($base_ver → $branch_ver)" >&2
    echo "       Version bumps are handled automatically by CI after merge." >&2
    echo "       Revert the version change in $REGISTRY and re-push." >&2
    ERRORS=$((ERRORS+1))
  fi

done < <(jq -r '.plugins[] | "\(.name)|\(.version)"' "$REGISTRY")

# ── Check top-level marketplace version ───────────────────────────────────────

BRANCH_MKT_VER=$(jq -r '.version' "$REGISTRY" 2>/dev/null || echo "")
BASE_MKT_VER=$(echo "$BASE_REGISTRY" | jq -r '.version' 2>/dev/null || echo "")

if [[ -n "$BRANCH_MKT_VER" && -n "$BASE_MKT_VER" && "$BRANCH_MKT_VER" != "$BASE_MKT_VER" ]]; then
  echo "ERROR: Marketplace version manually bumped ($BASE_MKT_VER → $BRANCH_MKT_VER)" >&2
  echo "       This is handled automatically by CI after merge." >&2
  ERRORS=$((ERRORS+1))
fi

# ── Result ────────────────────────────────────────────────────────────────────

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "Version guard FAILED — $ERRORS manual bump(s) detected."
  echo ""
  echo "  Version bumps are now CI-only. To fix:"
  echo "  1. Revert version changes in $REGISTRY"
  echo "  2. Keep your plugin source changes as-is"
  echo "  3. Use conventional commit messages (fix/feat/feat!) to signal bump type"
  echo "  4. CI will apply the correct version after merge to $BASE_BRANCH"
  exit 1
fi

echo "Version guard PASSED — no manual version bumps detected."
exit 0
