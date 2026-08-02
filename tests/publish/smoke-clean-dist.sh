#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.." && pwd)"

fail() {
  echo "FAIL: $1"
  exit 1
}

# Check dist/ exists
[ -d "$ROOT/dist" ] || fail "dist/ directory does not exist"

# Every plugin the shipped manifest advertises must have a directory beside it.
#
# This list used to be hardcoded, and it drifted: `content-tools` was added to
# the marketplace and never added here, so for its whole life the dist smoke
# test asserted nothing about it. A hand-maintained copy of `plugins[]` is a
# second source of truth that only ever goes stale in the direction that hides
# a packaging bug — a plugin missing from BOTH the list and dist/ passes.
#
# Deriving from dist's own manifest inverts that: build-dist.mjs copies one
# directory per `plugins[]` entry, so a copy that silently fails leaves the
# entry advertised with nothing behind it, which is exactly the bug this
# checks for, and a newly added plugin is covered the day it lands.
DIST_MANIFEST="$ROOT/dist/.claude-plugin/marketplace.json"
[ -f "$DIST_MANIFEST" ] || fail "dist/.claude-plugin/marketplace.json missing"

# `mapfile` would be tidier but is bash 4+; macOS ships bash 3.2, so this
# would pass on the ubuntu runner and die on every dev machine.
PLUGINS=()
while IFS= read -r name; do
  [ -n "$name" ] && PLUGINS+=("$name")
done < <(node -e '
  const m = require(process.argv[1]);
  console.log(m.plugins.map((p) => p.name).join("\n"));
' "$DIST_MANIFEST")

# A truncated manifest would make the loop below vacuously pass, so the count
# is pinned against the repo manifest rather than merely asserted non-empty.
REPO_COUNT="$(node -e '
  const m = require(process.argv[1]);
  console.log(m.plugins.length);
' "$ROOT/.claude-plugin/marketplace.json")"

[ "${#PLUGINS[@]}" -eq "$REPO_COUNT" ] || fail \
  "dist manifest lists ${#PLUGINS[@]} plugins, repo manifest lists $REPO_COUNT"

for plugin in "${PLUGINS[@]}"; do
  [ -d "$ROOT/dist/kit/plugins/$plugin" ] || fail "dist/kit/plugins/$plugin directory missing"
done

# Check dist/.claude-plugin/marketplace.json exists
[ -f "$ROOT/dist/.claude-plugin/marketplace.json" ] || fail "dist/.claude-plugin/marketplace.json missing"

# Check no banned paths
BANNED=(docs CLAUDE.md SOCIAL.md scripts tests .github)
for banned in "${BANNED[@]}"; do
  [ ! -e "$ROOT/dist/$banned" ] || fail "banned path found in dist/: $banned"
done

# Check zero .png files
PNG_COUNT=$(find "$ROOT/dist" -name "*.png" | wc -l | tr -d ' ')
[ "$PNG_COUNT" -eq 0 ] || fail "found $PNG_COUNT .png file(s) in dist/"

echo "PASS: dist/ clean"
