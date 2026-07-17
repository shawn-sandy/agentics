#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.." && pwd)"

fail() {
  echo "FAIL: $1"
  exit 1
}

# Check dist/ exists
[ -d "$ROOT/dist" ] || fail "dist/ directory does not exist"

# Check all 12 plugin dirs
PLUGINS=(
  artifact-tools
  team-defaults
  memory-tools
  code-review
  wcag-compliance-reviewer
  skill-reviewer
  code-testing-agent
  git-agent
  product-plans
  settings-sync
  social-media-tools
  plan-agent
)

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
