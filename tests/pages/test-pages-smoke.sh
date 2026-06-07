#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:?Usage: $0 <base-url>}"
BASE_URL="${BASE_URL%/}"
MAX_RETRIES=5
RETRY_DELAY=15
FAILURES=0

retry_curl() {
  local url="$1"
  local attempt
  for attempt in $(seq 1 "$MAX_RETRIES"); do
    local status
    status=$(curl -sL -o /dev/null -w '%{http_code}' "$url") || true
    if [ "$status" = "200" ]; then
      return 0
    fi
    if [ "$attempt" -lt "$MAX_RETRIES" ]; then
      echo "  attempt $attempt/$MAX_RETRIES: got $status, retrying in ${RETRY_DELAY}s..."
      sleep "$RETRY_DELAY"
    fi
  done
  echo "  FAIL: $url returned $status after $MAX_RETRIES attempts"
  return 1
}

echo "=== Pages Smoke Test ==="
echo "Base URL: $BASE_URL"
echo ""

echo "1. Root URL returns 200 (follows redirect)..."
retry_curl "$BASE_URL/" || FAILURES=$((FAILURES + 1))

echo "2. Plans gallery contains 'Plans Library'..."
body=$(curl -sL "$BASE_URL/plans/")
if echo "$body" | grep -q "Plans Library"; then
  echo "  PASS"
else
  echo "  FAIL: 'Plans Library' not found in gallery page"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Every plan file is reachable..."
plan_dir="$(cd "$(dirname "$0")/../.." && pwd)/docs/plans"
plan_count=0
plan_fail=0
for f in "$plan_dir"/*.html; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  [ "$name" = "index.html" ] && continue
  plan_count=$((plan_count + 1))
  if ! retry_curl "$BASE_URL/plans/$name"; then
    plan_fail=$((plan_fail + 1))
  fi
done
echo "  Checked $plan_count plans, $plan_fail failed"
FAILURES=$((FAILURES + plan_fail))

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
else
  echo "FAILED ($FAILURES failures)"
  exit 1
fi
