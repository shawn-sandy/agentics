#!/usr/bin/env bash
# check-version-bump.sh — Plugin version conflict guard
#
# Prevents version conflicts on PRs by verifying that any plugin whose source
# files changed on this branch has a version bump above the base branch.
#
# USAGE:
#   ./scripts/check-version-bump.sh [registry-file] [base-branch]
#
# DEFAULTS:
#   registry-file  .claude-plugin/marketplace.json
#   base-branch    main
#
# ENVIRONMENT OVERRIDES (take precedence over positional args):
#   VERSION_GUARD_REGISTRY     — path to JSON registry file
#   VERSION_GUARD_BASE_BRANCH  — branch to compare against (default: main)
#   VERSION_GUARD_NO_FETCH=1   — skip git fetch; use cached origin state (faster)
#
# PORTABILITY — adapting to other registry schemas:
#   Override VERSION_GUARD_PLUGINS_JQ to match your file's structure.
#   The expression must output lines of "name|version|source-path":
#
#     export VERSION_GUARD_PLUGINS_JQ='.packages[] | "\(.name)|\(.version)|\(.path)"'
#     ./scripts/check-version-bump.sh package-registry.json
#
# INSTALL AS PRE-PUSH HOOK:
#   cp scripts/check-version-bump.sh .git/hooks/pre-push
#   chmod +x .git/hooks/pre-push

set -euo pipefail

REGISTRY="${VERSION_GUARD_REGISTRY:-${1:-.claude-plugin/marketplace.json}}"
BASE_BRANCH="${VERSION_GUARD_BASE_BRANCH:-${2:-main}}"
NO_FETCH="${VERSION_GUARD_NO_FETCH:-0}"
DEFAULT_JQ='.plugins[] | "\(.name)|\(.version)|\(.source.path // "")"'
PLUGINS_JQ="${VERSION_GUARD_PLUGINS_JQ:-$DEFAULT_JQ}"
REMOTE_BASE="origin/${BASE_BRANCH}"

# ── Semver comparison (X.Y.Z, cross-platform) ─────────────────────────────────

semver_compare() {
  local v1="$1" v2="$2"
  if [[ ! "$v1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ ! "$v2" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "WARNING: invalid semver format (expected X.Y.Z): '$v1' vs '$v2'" >&2
    echo "invalid"
    return 0
  fi
  local IFS='.'
  read -ra a <<< "$v1"
  read -ra b <<< "$v2"
  for i in 0 1 2; do
    local ai="${a[$i]:-0}" bi="${b[$i]:-0}"
    if (( ai > bi )); then echo "gt"; return; fi
    if (( ai < bi )); then echo "lt"; return; fi
  done
  echo "eq"
}

# ── Prerequisites ─────────────────────────────────────────────────────────────

if [[ ! -f "$REGISTRY" ]]; then
  echo "INFO: Registry not found ($REGISTRY) — skipping version guard."
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not found in PATH." >&2
  exit 1
fi

# ── Fetch base branch ─────────────────────────────────────────────────────────

if [[ "$NO_FETCH" != "1" ]]; then
  if ! git fetch origin "$BASE_BRANCH" --quiet 2>/dev/null; then
    echo "WARNING: Could not fetch $REMOTE_BASE — skipping version guard."
    exit 0
  fi
fi

BASE_REGISTRY=$(git show "${REMOTE_BASE}:${REGISTRY}" 2>/dev/null || echo "")
if [[ -z "$BASE_REGISTRY" ]]; then
  echo "INFO: Registry not found on $BASE_BRANCH — nothing to compare against."
  exit 0
fi

# ── Changed files on this branch ──────────────────────────────────────────────

CHANGED=$(git diff --name-only "${REMOTE_BASE}...HEAD" 2>/dev/null || \
          git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null || echo "")

if [[ -z "$CHANGED" ]]; then
  echo "OK: No file changes detected."
  exit 0
fi

# ── Compare plugin versions ───────────────────────────────────────────────────

ERRORS=0
CHECKED=0

while IFS='|' read -r name local_ver src_path; do
  [[ -z "$name" ]] && continue

  base_ver=$(echo "$BASE_REGISTRY" | jq -r --arg n "$name" \
    '.plugins[] | select(.name==$n) | .version' 2>/dev/null || echo "")

  # New plugin — no conflict possible
  if [[ -z "$base_ver" ]]; then
    echo "OK: $name (new, version $local_ver)"
    continue
  fi

  cmp=$(semver_compare "$local_ver" "$base_ver")

  # Skip plugins with unrecognised version formats
  if [[ "$cmp" == "invalid" ]]; then
    echo "WARNING: $name — skipping (invalid version format: branch=$local_ver, $BASE_BRANCH=$base_ver)" >&2
    continue
  fi

  # Version regressed — always an error (branch is stale vs main)
  if [[ "$cmp" == "lt" ]]; then
    echo "ERROR: $name — version regressed (branch: $local_ver, $BASE_BRANCH: $base_ver)" >&2
    echo "       Rebase on $BASE_BRANCH, then bump version above $base_ver in $REGISTRY" >&2
    ERRORS=$((ERRORS+1))
    CHECKED=$((CHECKED+1))
    continue
  fi

  # Version unchanged — only a problem if plugin source files changed.
  # Use bash pattern matching to avoid regex metacharacter issues with src_path.
  if [[ "$cmp" == "eq" ]] && [[ -n "$src_path" ]]; then
    if [[ "$CHANGED" == *"${src_path}/"* ]]; then
      echo "ERROR: $name — version not bumped (still $local_ver on both branch and $BASE_BRANCH)" >&2
      echo "       Files changed under $src_path/ — bump version in $REGISTRY" >&2
      echo "       See .claude/rules/marketplace.md for versioning conventions." >&2
      ERRORS=$((ERRORS+1))
      CHECKED=$((CHECKED+1))
    fi
    continue
  fi

  # Version bumped correctly
  if [[ "$cmp" == "gt" ]]; then
    echo "OK: $name  $base_ver → $local_ver"
    CHECKED=$((CHECKED+1))
  fi

done < <(jq -r "$PLUGINS_JQ" "$REGISTRY")

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "Version guard FAILED — $ERRORS plugin(s) need attention."
  exit 1
fi

if [[ $CHECKED -gt 0 ]]; then
  echo "Version guard PASSED — all modified plugins have valid version bumps."
else
  echo "OK: No plugin source changes requiring a version bump."
fi
exit 0
