#!/usr/bin/env bash
# run.sh — test runner for tests/demo/
# Executes all *.test.sh files and exits non-zero if any fail.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERALL=0

for test_file in "$SCRIPT_DIR"/*.test.sh; do
  echo "--- $test_file ---"
  bash "$test_file"
  status=$?
  if [ $status -ne 0 ]; then
    echo "FAILED: $test_file (exit $status)"
    OVERALL=1
  fi
  echo ""
done

if [ $OVERALL -eq 0 ]; then
  echo "All tests passed."
else
  echo "One or more tests failed."
fi

exit $OVERALL
