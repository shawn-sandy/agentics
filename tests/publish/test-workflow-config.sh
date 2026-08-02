#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.." && pwd)"

fail() {
  echo "FAIL: $1"
  exit 1
}

WORKFLOW="$ROOT/.github/workflows/publish-dist.yml"

# Check workflow file exists
[ -f "$WORKFLOW" ] || fail ".github/workflows/publish-dist.yml does not exist"

# grep checks
grep -q "0 6" "$WORKFLOW" || fail "cron schedule '0 6' not found in publish-dist.yml"
grep -q "workflow_dispatch" "$WORKFLOW" || fail "'workflow_dispatch' not found in publish-dist.yml"
grep -q "DIST_REPO_TOKEN" "$WORKFLOW" || fail "'DIST_REPO_TOKEN' not found in publish-dist.yml"
grep -q "DIST_REPO_URL" "$WORKFLOW" || fail "'DIST_REPO_URL' not found in publish-dist.yml"
grep -q "Build dist" "$WORKFLOW" || fail "'Build dist' step not found in publish-dist.yml"
grep -q "Verify no leaks" "$WORKFLOW" || fail "'Verify no leaks' step not found in publish-dist.yml"
grep -q "test-no-ignored-plugin-files.sh" "$WORKFLOW" || fail "the git-ignored plugin file guard is not wired into publish-dist.yml"
grep -q "Publish to agentics-kit" "$WORKFLOW" || fail "'Publish to agentics-kit' step not found in publish-dist.yml"

echo "PASS: publish-dist.yml structure verified"
