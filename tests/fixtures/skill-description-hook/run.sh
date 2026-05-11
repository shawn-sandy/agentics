#!/usr/bin/env sh
# Test harness for measure-description.sh
# Run from anywhere: sh tests/fixtures/skill-description-hook/run.sh

set -e

FIXTURES="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$FIXTURES/../../../kit/plugins/skill-reviewer" && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/measure-description.sh"

PASS=0
FAIL=0

assert() {
  label="$1"
  file="$2"
  expected_prefix="$3"
  expected_count="$4"  # optional: numeric char count that must appear in output

  # Clear any stale dedup state for this file so tests are independent
  state="/tmp/skill-desc-hook-$(printf '%s' "$file" | shasum -a 256 | cut -d' ' -f1).hash"
  rm -f "$state"

  actual=$("$SCRIPT" "$file" 2>&1)

  prefix_ok=0
  echo "$actual" | grep -q "^${expected_prefix}" && prefix_ok=1

  count_ok=1
  if [ -n "$expected_count" ]; then
    echo "$actual" | grep -q "${expected_count}" || count_ok=0
  fi

  if [ "$prefix_ok" -eq 1 ] && [ "$count_ok" -eq 1 ]; then
    printf 'PASS: %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$label"
    printf '  expected prefix: %s\n' "$expected_prefix"
    [ -n "$expected_count" ] && printf '  expected count:  %s\n' "$expected_count"
    printf '  actual output:   %s\n' "$actual"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== measure-description.sh test harness ==="
echo "Script: $SCRIPT"
echo ""

assert "boundary OK (160 chars)"       "$FIXTURES/desc-160.md"      "OK:"      "160"
assert "one over budget (161 chars)"   "$FIXTURES/desc-161.md"      "WARNING:" "161"
assert "well over budget (200 chars)"  "$FIXTURES/desc-200.md"      "WARNING:" "200"
assert "missing description"           "$FIXTURES/desc-missing.md"  "ERROR:"
assert "multi-line description"        "$FIXTURES/desc-multiline.md" "WARNING:"

echo ""
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
