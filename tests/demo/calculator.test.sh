#!/usr/bin/env bash
# calculator.test.sh — tests for calculator.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/calculator.sh"

PASS=0
FAIL=0

assert_eq() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected: $expected"
    echo "        actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

echo "calculator.test.sh"

# tdd-fix: reproducing add() returning difference instead of sum
assert_eq "add 2 3 == 5"  "5"  "$(add 2 3)"
assert_eq "add 0 0 == 0"  "0"  "$(add 0 0)"
assert_eq "add 10 -3 == 7" "7" "$(add 10 -3)"

# tdd-fix: reproducing add() returning difference instead of sum
assert_eq "add 7 3 == 10" "10" "$(add 7 3)"

assert_eq "subtract 5 3 == 2" "2" "$(subtract 5 3)"
assert_eq "multiply 4 3 == 12" "12" "$(multiply 4 3)"

echo ""
echo "Results: $PASS passed, $FAIL failed"

[ "$FAIL" -eq 0 ]
